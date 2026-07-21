require('dotenv').config();
console.log("JWT_SECRET =", process.env.JWT_SECRET);
const { Hono } = require('hono');
const { cors } = require('hono/cors');
const { serve } = require('@hono/node-server');
const authRoutes = require('./routes/auth');
const medicationRoutes = require('./routes/medications');
const scheduleRoutes = require('./routes/schedules');
const doseLogRoutes = require('./routes/doseLogs');
const adherenceRoutes = require('./routes/adherence');
const notificationRoutes = require('./routes/notifications');
const interactionRoutes = require('./routes/interactions');
const dependentRoutes = require('./routes/dependents');
const medicineRoutes = require('./routes/medicines');
const { errorHandler } = require('./middleware/errorHandler');

const { readFileSync } = require('fs');
const { resolve } = require('path');

const app = new Hono();
const PORT = Number(process.env.PORT || (require.main === module ? 3000 : 0));

app.use('*', cors());

// Serve the invite HTML page at /invite
app.get('/invite', async (c) => {
  try {
    const html = readFileSync(resolve(__dirname, '../public/invite.html'), 'utf-8');
    return c.body(html, 200, { 'Content-Type': 'text/html; charset=utf-8' });
  } catch (e) {
    console.error('Failed to read invite.html:', e.message);
    return c.text('صفحة الدعوة غير متوفرة', 500);
  }
});

app.get('/health', (c) => c.json({ status: 'ok' }));
app.route('/auth', authRoutes);
app.route('/medications', medicationRoutes);
app.route('/schedules', scheduleRoutes);
app.route('/dose-logs', doseLogRoutes);
app.route('/adherence', adherenceRoutes);
app.route('/notifications', notificationRoutes);
app.route('/interactions', interactionRoutes);
app.route('/dependents', dependentRoutes);
app.route('/medicines', medicineRoutes);
app.onError((err, c) => errorHandler(err, c));

const server = serve({ fetch: app.fetch, port: PORT }, () => {
  if (require.main === module) {
    console.log(`Backend listening on port ${PORT}`);
  }
});

module.exports = server;
module.exports.app = app;

