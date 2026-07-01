const express = require('express');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = express.Router();

router.use(authMiddleware);

router.get('/rate', async (req, res, next) => {
  try {
    const records = await pool.listDoseRecords(req.user.id);
    const completed = records.filter((record) => record.status === 'TAKEN').length;
    const rate = records.length ? Math.round((completed / records.length) * 100) : 0;
    res.json({ adherence_rate: rate, completed, total: records.length });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

