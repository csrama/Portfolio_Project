const jwt = require('jsonwebtoken');
const { pool } = require('../db/pool');

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim() === '') {
    throw new Error('JWT_SECRET is required');
  }
  return secret;
}

async function authMiddleware(c, next) {
  const header = c.req.header('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';

  if (!token) {
    return c.json({ error: 'Authentication required' }, 401);
  }

  try {
    const decoded = jwt.verify(token, getJwtSecret());
    const user = await pool.findUserById(decoded.id);

    if (!user) {
      return c.json({ error: 'Invalid token' }, 401);
    }

    c.set('user', user);
    await next();
  } catch (error) {
    return c.json({ error: 'Invalid token' }, 401);
  }
}

module.exports = { authMiddleware };

