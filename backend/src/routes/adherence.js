const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = new Hono();

router.use('*', authMiddleware);

router.get('/rate', async (c) => {
  try {
    const user = c.get('user');
    const records = await pool.listDoseRecords(user.id);
    const completed = records.filter((record) => record.status === 'TAKEN').length;
    const rate = records.length ? Math.round((completed / records.length) * 100) : 0;
    return c.json({ adherence_rate: rate, completed, total: records.length });
  } catch (error) {
    throw error;
  }
});

module.exports = router;

