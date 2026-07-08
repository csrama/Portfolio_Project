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
const { errorHandler } = require('./middleware/errorHandler');

const app = new Hono();
const PORT = Number(process.env.PORT || (require.main === module ? 3000 : 0));

app.use('*', cors());
app.get('/health', (c) => c.json({ status: 'ok' }));
app.route('/auth', authRoutes);
app.route('/medications', medicationRoutes);
app.route('/schedules', scheduleRoutes);
app.route('/dose-logs', doseLogRoutes);
app.route('/adherence', adherenceRoutes);
app.route('/notifications', notificationRoutes);
app.route('/interactions', interactionRoutes);
app.route('/dependents', dependentRoutes);
app.onError((err, c) => errorHandler(err, c));

const server = serve({ fetch: app.fetch, port: PORT }, () => {
  if (require.main === module) {
    console.log(`Backend listening on port ${PORT}`);
  }
});

module.exports = server;
module.exports.app = app;

