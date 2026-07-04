const { Hono } = require('hono');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const { pool } = require('../db/pool');
const router = new Hono();
const { OAuth2Client } = require('google-auth-library');

const registerSchema = z.object({
  email: z.string().trim().email().transform((value) => value.toLowerCase()),
  password: z.string().min(6),
  full_name: z.string().trim().min(1),
  user_type: z.string().optional()
});

const loginSchema = z.object({
  email: z.string().trim().email().transform((value) => value.toLowerCase()),
  password: z.string().min(6)
});

const MAX_LOGIN_ATTEMPTS = 5;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const loginAttempts = new Map();

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim() === '') {
    throw new Error('JWT_SECRET is required');
  }
  return secret;
}
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

function normalizeUserType(userType) {
  if (!userType) {
    return 'general_user';
  }
  return userType === 'patient' ? 'general_user' : userType;
}

async function loginRateLimiter(c, next) {
  const forwarded = c.req.header('x-forwarded-for');
  const ip = (Array.isArray(forwarded) ? forwarded[0] : forwarded || c.req.raw.socket?.remoteAddress || 'unknown').split(',')[0].trim();
  const body = await c.req.json().catch(() => ({}));
  const email = typeof body.email === 'string' ? body.email.toLowerCase() : 'unknown';
  const key = `${ip}:${email}`;
  const now = Date.now();
  const entry = loginAttempts.get(key);

  if (entry && now - entry.firstAttempt < LOGIN_WINDOW_MS) {
    if (entry.count >= MAX_LOGIN_ATTEMPTS) {
      return c.json({ error: 'Too many login attempts. Please try again later.' }, 429);
    }
    entry.count += 1;
  } else {
    loginAttempts.set(key, { count: 1, firstAttempt: now });
  }

  c.set('loginAttemptKey', key);
  await next();
}

router.post('/register', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const parsed = registerSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0].message }, 400);
    }

    const { email, password, full_name, user_type } = parsed.data;

    const existing = await pool.findUserByEmail(email);
    if (existing) {
      return c.json({ error: 'User already exists' }, 409);
    }

    const password_hash = await bcrypt.hash(password, 10);

    const user = await pool.createUser({
      email,
      password_hash,
      full_name,
      user_type: normalizeUserType(user_type)
    });

    const token = jwt.sign({ id: user.id }, getJwtSecret(), { expiresIn: '7d' });
    return c.json({ user, token }, 201);
  } catch (error) {
    throw error;
  }
});

router.post('/login', loginRateLimiter, async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const parsed = loginSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0].message }, 400);
    }

    const { email, password } = parsed.data;
    const user = await pool.findUserByEmail(email);

    if (!user) {
      return c.json({ error: 'Invalid credentials' }, 401);
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return c.json({ error: 'Invalid credentials' }, 401);
    }

    const { password_hash, ...safeUser } = user;
    loginAttempts.delete(c.get('loginAttemptKey'));
    const token = jwt.sign({ id: user.id }, getJwtSecret(), { expiresIn: '7d' });
    return c.json({ user: safeUser, token });
  } catch (error) {
    throw error;
  }
});

router.post('/google', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const { idToken } = body;

    if (!idToken) {
      return c.json({ error: 'Missing Google ID token' }, 400);
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();

    if (!payload) {
      return c.json({ error: 'Invalid Google token' }, 401);
    }

    const email = payload.email.toLowerCase();
    const full_name = payload.name;

    let user = await pool.findUserByEmail(email);

    if (!user) {
      user = await pool.createUser({
        email,
        full_name,
        password_hash: '',
        user_type: 'general_user',
      });
    }

    const { password_hash, ...safeUser } = user;

    const token = jwt.sign(
      { id: safeUser.id },
      getJwtSecret(),
      { expiresIn: '7d' }
    );

    return c.json({
      user: safeUser,
      token,
    });
  } catch (err) {
    console.error(err);
    return c.json(
      { error: 'Google authentication failed' },
      401
    );
  }
});
module.exports = router;

