const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = new Hono();

router.use('*', authMiddleware);

router.get('/', async (c) => {
  try {
    const user = c.get('user');
    const schedules = await pool.listSchedules(user.id);
    return c.json(schedules);
  } catch (error) {
    throw error;
  }
});

router.post('/', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const { medication_id, dose_times, start_date, end_date, reminder_enabled } = body;

    if (medication_id === undefined || medication_id === null) {
      return c.json({ error: 'medication_id is required' }, 400);
    }

    if (start_date === undefined || start_date === null || start_date === '') {
      return c.json({ error: 'start_date is required' }, 400);
    }

    if (!Array.isArray(dose_times) || dose_times.length === 0) {
      return c.json({ error: 'dose_times must be a non-empty array' }, 400);
    }

    const schedule = await pool.createSchedule({
      medication_id,
      dose_times,
      start_date,
      end_date,
      reminder_enabled: reminder_enabled !== false,
      user_id: user.id
    });

    return c.json(schedule, 201);
  } catch (error) {
    throw error;
  }
});

router.patch('/:id', async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));
    const { dose_times, start_date, end_date, reminder_enabled } = body;
    const updates = {};

    if (dose_times !== undefined) {
      if (!Array.isArray(dose_times) || dose_times.length === 0) {
        return c.json({ error: 'dose_times must be a non-empty array' }, 400);
      }
      updates.dose_times = dose_times;
    }

    if (start_date !== undefined) {
      updates.start_date = start_date;
    }

    if (end_date !== undefined) {
      updates.end_date = end_date;
    }

    if (reminder_enabled !== undefined) {
      updates.reminder_enabled = reminder_enabled;
    }

    const updated = await pool.updateSchedule(id, updates, user.id);
    if (!updated) {
      return c.json({ error: 'Schedule not found' }, 404);
    }

    return c.json(updated);
  } catch (error) {
    throw error;
  }
});

router.delete('/:id', async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    const deleted = await pool.deleteSchedule(id, user.id);
    if (!deleted) {
      return c.json({ error: 'Schedule not found' }, 404);
    }

    return c.json({ message: 'Schedule deleted successfully' });
  } catch (error) {
    throw error;
  }
});

module.exports = router;

