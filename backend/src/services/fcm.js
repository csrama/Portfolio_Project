const { pool } = require('../db/pool');

async function sendPushNotification(userId, payload) {
  const notification = await pool.createNotification({
    user_id: userId,
    type: payload.type || 'reminder',
    title: payload.title || 'Medication reminder',
    body: payload.body || 'Please take your medication.',
    data: payload.data || {}
  });
  return notification;
}

async function sendInAppNotification(userId, payload) {
  return sendPushNotification(userId, payload);
}

module.exports = { sendPushNotification, sendInAppNotification };

