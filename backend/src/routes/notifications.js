const { Hono } = require('hono');
const { authMiddleware } = require('../middleware/auth');
const { sendPushNotification } = require('../services/fcm');
const router = new Hono();

router.use('*', authMiddleware);

router.post('/send', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const notification = await sendPushNotification(user.id, body);
    return c.json(notification, 201);
  } catch (error) {
    throw error;
  }
});

module.exports = router;

