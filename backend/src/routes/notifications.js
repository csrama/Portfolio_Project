const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { sendPushNotification } = require('../services/fcm');
const router = express.Router();

router.use(authMiddleware);

router.post('/send', async (req, res, next) => {
  try {
    const notification = await sendPushNotification(req.user.id, req.body || {});
    res.status(201).json(notification);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

