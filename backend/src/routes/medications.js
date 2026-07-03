const { Hono } = require('hono');
const { z } = require('zod');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const router = new Hono();

const medicationSchema = z.object({
  name: z.string().trim().min(1),
  dosage: z.string().optional(),
  form: z.string().optional(),
  instructions: z.string().optional(),
  total_quantity: z.number().int().positive().optional()
});

router.use('*', authMiddleware);

router.get('/', async (c) => {
  try {
    const user = c.get('user');
    const medications = await pool.listMedications(user.id);
    return c.json(medications);
  } catch (error) {
    throw error;
  }
});

router.post('/', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const parsed = medicationSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0].message }, 400);
    }

    const medication = await pool.createMedication({
      ...parsed.data,
      user_id: user.id
    });
    return c.json(medication, 201);
  } catch (error) {
    throw error;
  }
});

module.exports = router;

