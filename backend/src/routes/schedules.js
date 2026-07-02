const express = require('express');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = express.Router();

router.use(authMiddleware);

router.get('/', async (req, res, next) => {
  try {
    const schedules = await pool.listSchedules(req.user.id);
    res.json(schedules);
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const { medication_id, dose_times, start_date, end_date, reminder_enabled } = req.body || {};

    if (medication_id === undefined || medication_id === null) {
      return res.status(400).json({ error: 'medication_id is required' });
    }

    if (start_date === undefined || start_date === null || start_date === '') {
      return res.status(400).json({ error: 'start_date is required' });
    }

    if (!Array.isArray(dose_times) || dose_times.length === 0) {
      return res.status(400).json({ error: 'dose_times must be a non-empty array' });
    }

    const schedule = await pool.createSchedule({
      medication_id,
      dose_times,
      start_date,
      end_date,
      reminder_enabled: reminder_enabled !== false,
      user_id: req.user.id
    });

    res.status(201).json(schedule);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id', async (req, res, next) => {
  try {
    const { dose_times, start_date, end_date, reminder_enabled } = req.body || {};
    const updates = {};

    if (dose_times !== undefined) {
      if (!Array.isArray(dose_times) || dose_times.length === 0) {
        return res.status(400).json({ error: 'dose_times must be a non-empty array' });
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

    const updated = await pool.updateSchedule(req.params.id, updates, req.user.id);
    if (!updated) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    res.json(updated);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const deleted = await pool.deleteSchedule(req.params.id, req.user.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    res.json({ message: 'Schedule deleted successfully' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

