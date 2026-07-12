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
  total_quantity: z.number().int().positive().optional(),
  dependent_id: z.union([z.number().int().nullable(), z.number().int().positive().optional()]).optional()
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

router.put('/:id', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const medicationId = c.req.param('id');

    const parsed = medicationSchema.partial().safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0].message }, 400);
    }

    const updated = await pool.updateMedication({
      id: Number(medicationId),
      userId: user.id,
      dependentId: body.dependent_id ?? undefined,
      updates: parsed.data
    });

    if (!updated) {
      return c.json({ error: 'Medication not found' }, 404);
    }

    return c.json(updated);
  } catch (error) {
    throw error;
  }
});

router.delete('/:id', async (c) => {
  try {
    const user = c.get('user');
    const medicationId = c.req.param('id');

    const deleted = await pool.deleteMedication({
      id: Number(medicationId),
      userId: user.id
    });

    if (!deleted) {
      return c.json({ error: 'Medication not found' }, 404);
    }

    return c.json({ ok: true });
  } catch (error) {
    throw error;
  }
});

module.exports = router;

