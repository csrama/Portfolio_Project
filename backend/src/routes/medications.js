const express = require('express');
const { z } = require('zod');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = express.Router();

const medicationSchema = z.object({
  name: z.string().trim().min(1),
  dosage: z.string().optional(),
  form: z.string().optional(),
  instructions: z.string().optional(),
  total_quantity: z.number().int().positive().optional()
});

router.use(authMiddleware);

router.get('/', async (req, res, next) => {
  try {
    const medications = await pool.listMedications(req.user.id);
    res.json(medications);
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const parsed = medicationSchema.safeParse(req.body || {});
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.issues[0].message });
    }

    const medication = await pool.createMedication({
      ...parsed.data,
      user_id: req.user.id
    });
    res.status(201).json(medication);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

