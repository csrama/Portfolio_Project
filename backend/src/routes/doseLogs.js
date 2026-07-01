const express = require('express');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = express.Router();

router.use(authMiddleware);

router.get('/', async (req, res, next) => {
  try {
    const records = await pool.listDoseRecords(req.user.id);
    res.json(records);
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const record = await pool.createDoseRecord({
      ...req.body,
      user_id: req.user.id
    });
    res.status(201).json(record);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id', async (req, res, next) => {
  try {
    const record = await pool.updateDoseRecord(req.params.id, req.body);
    if (!record) {
      return res.status(404).json({ error: 'Dose record not found' });
    }
    res.json(record);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

