const express = require('express');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/auth');
const medicationRoutes = require('./routes/medications');
const scheduleRoutes = require('./routes/schedules');
const doseLogRoutes = require('./routes/doseLogs');
const adherenceRoutes = require('./routes/adherence');
const notificationRoutes = require('./routes/notifications');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/auth', authRoutes);
app.use('/medications', medicationRoutes);
app.use('/schedules', scheduleRoutes);
app.use('/dose-logs', doseLogRoutes);
app.use('/adherence', adherenceRoutes);
app.use('/notifications', notificationRoutes);
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Backend listening on port ${PORT}`);
});

module.exports = app;

