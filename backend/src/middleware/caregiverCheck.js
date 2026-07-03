function caregiverCheck(c, next) {
  const user = c.get('user');
  if (!user || user.user_type !== 'caregiver') {
    return c.json({ error: 'Caregiver access required' }, 403);
  }
  return next();
}

module.exports = { caregiverCheck };

