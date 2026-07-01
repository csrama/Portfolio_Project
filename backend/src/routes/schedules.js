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
    const schedule = await pool.createSchedule({
      ...req.body,
      user_id: req.user.id
    });
    res.status(201).json(schedule);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

