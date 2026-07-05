const jwt = require('jsonwebtoken');
const { pool } = require('../db/pool');

const offlineChallenges = new Map();

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim() === '') {
    throw new Error('JWT_SECRET is required');
  }
  return secret;
}

function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function createChallenge(provider, identifier) {
  const challengeId = `${provider}:${Date.now()}:${Math.random().toString(36).slice(2, 8)}`;
  const code = generateCode();
  offlineChallenges.set(challengeId, { provider, identifier: identifier.toLowerCase(), code, createdAt: Date.now() });
  return { challengeId, code };
}

function verifyChallenge(challengeId, provider, identifier, code) {
  const challenge = offlineChallenges.get(challengeId);
  if (!challenge) {
    return null;
  }

  if (challenge.provider !== provider || challenge.identifier !== identifier.toLowerCase()) {
    offlineChallenges.delete(challengeId);
    return null;
  }

  if (challenge.code !== String(code)) {
    return null;
  }

  offlineChallenges.delete(challengeId);
  return challenge;
}

async function createOrGetUser({ email, full_name, provider }) {
  const existing = await pool.findUserByEmail(email);
  if (existing) {
    return existing;
  }

  return pool.createUser({
    email,
    full_name: full_name || `${provider} user`,
    password_hash: '',
    user_type: 'general_user'
  });
}

async function issueTokenForUser(user) {
  const { password_hash, ...safeUser } = user;
  const token = jwt.sign({ id: safeUser.id }, getJwtSecret(), { expiresIn: '7d' });
  return { user: safeUser, token };
}

module.exports = {
  createChallenge,
  verifyChallenge,
  createOrGetUser,
  issueTokenForUser,
  getJwtSecret
};
