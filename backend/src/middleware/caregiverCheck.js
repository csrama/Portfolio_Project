function caregiverCheck(req, res, next) {
  if (!req.user || req.user.user_type !== 'caregiver') {
    return res.status(403).json({ error: 'Caregiver access required' });
  }
  next();
}

module.exports = { caregiverCheck };

