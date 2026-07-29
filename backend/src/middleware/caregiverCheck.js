function caregiverCheck(c, next) {
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  if (user.user_type !== 'caregiver') {
    return c.json({ error: 'هذا الإجراء متاح فقط لمقدمي الرعاية' }, 403);
  }

  return next();
}

module.exports = { caregiverCheck };
