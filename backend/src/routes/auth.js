const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const { pool } = require('../db/pool');
const router = express.Router();

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

function normalizeUserType(userType) {
  if (!userType) {
    return 'general_user';
  }
  return userType === 'patient' ? 'general_user' : userType;
}

function loginRateLimiter(req, res, next) {
  const forwarded = req.headers['x-forwarded-for'];
  const ip = (Array.isArray(forwarded) ? forwarded[0] : forwarded || req.ip || req.socket.remoteAddress || 'unknown').split(',')[0].trim();
  const email = typeof req.body?.email === 'string' ? req.body.email.toLowerCase() : 'unknown';
  const key = `${ip}:${email}`;
  const now = Date.now();
  const entry = loginAttempts.get(key);

  if (entry && now - entry.firstAttempt < LOGIN_WINDOW_MS) {
    if (entry.count >= MAX_LOGIN_ATTEMPTS) {
      return res.status(429).json({ error: 'Too many login attempts. Please try again later.' });
    }
    entry.count += 1;
  } else {
    loginAttempts.set(key, { count: 1, firstAttempt: now });
  }

  req.loginAttemptKey = key;
  next();
}

router.post('/register', async (req, res, next) => {
  try {
    const parsed = registerSchema.safeParse(req.body || {});
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.issues[0].message });
    }

    const { email, password, full_name, user_type } = parsed.data;

    const existing = await pool.findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'User already exists' });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const user = await pool.createUser({
      email,
      password_hash,
      full_name,
      user_type: normalizeUserType(user_type)
    });

    const token = jwt.sign({ id: user.id }, getJwtSecret(), { expiresIn: '7d' });
    res.status(201).json({ user, token });
  } catch (error) {
    next(error);
  }
});

router.post('/login', loginRateLimiter, async (req, res, next) => {
  try {
    const parsed = loginSchema.safeParse(req.body || {});
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.issues[0].message });
    }

    const { email, password } = parsed.data;
    const user = await pool.findUserByEmail(email);

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const { password_hash, ...safeUser } = user;
    loginAttempts.delete(req.loginAttemptKey);
    const token = jwt.sign({ id: user.id }, getJwtSecret(), { expiresIn: '7d' });
    res.json({ user: safeUser, token });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

