const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = new Hono();

router.use('*', authMiddleware);

router.get('/', async (c) => {
  try {
    const user = c.get('user');
    const records = await pool.listDoseRecords(user.id);
    return c.json(records);
  } catch (error) {
    throw error;
  }
});

router.post('/', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const record = await pool.createDoseRecord({
      ...body,
      user_id: user.id
    });
    return c.json(record, 201);
  } catch (error) {
    throw error;
  }
});

router.patch('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));
    const record = await pool.updateDoseRecord(id, body);
    if (!record) {
      return c.json({ error: 'Dose record not found' }, 404);
    }
    return c.json(record);
  } catch (error) {
    throw error;
  }
});

module.exports = router;

