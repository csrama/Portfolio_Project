function caregiverCheck(c, next) {
  const user = c.get('user');

  if (!user) {
    return c.json(
      { error: 'Unauthorized' },
      401
    );
  }

  return next();
}

module.exports = { caregiverCheck };

