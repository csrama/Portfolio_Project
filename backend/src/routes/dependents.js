const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');

const router = new Hono();

router.use('*', authMiddleware);

// List all dependents for the current caregiver
router.get('/', async (c) => {
  const user = c.get('user');
  const dependents = await pool.listDependents(user.id);
  return c.json(dependents);
});

// Create a new dependent
router.post('/', caregiverCheck, async (c) => {
  const user = c.get('user');
  const body = await c.req.json();
  
  const dependent = await pool.createDependent({
    caregiver_user_id: user.id,
    full_name: body.full_name,
    date_of_birth: body.date_of_birth,
    relationship: body.relationship,
    profile_image_url: body.profile_image_url,
    medical_conditions: body.medical_conditions
  });
  
  return c.json(dependent, 201);
});

// Get medications for a specific dependent
router.get('/:id/medications', async (c) => {
  const dependentId = c.req.param('id');
  const user = c.get('user');
  
  // In a real app, we'd verify the caregiver owns this dependent here
  const medications = await pool.listMedications(user.id, dependentId);
  return c.json(medications);
});

module.exports = router;

