const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');

const router = new Hono();

router.use('*', authMiddleware);

// =====================================
// Search medicines
// GET /medicines/search?q=para
// =====================================
router.get('/search', async (c) => {
  try {
    const q = (c.req.query('q') || '').trim();

    if (!q) {
      return c.json([]);
    }

    const result = await pool.query(
      `
      SELECT
        id,
        name_en,
        name_ar,
        dosage,
        category,
        description,
        warnings
      FROM medicines
      WHERE
        LOWER(name_en) LIKE LOWER($1)
        OR LOWER(COALESCE(name_ar,'')) LIKE LOWER($1)
      ORDER BY name_en
      LIMIT 20
      `,
      [`%${q}%`]
    );

    return c.json(result.rows);
  } catch (err) {
    console.error(err);
    return c.json(
      {
        error: 'Failed to search medicines',
      },
      500,
    );
  }
});

module.exports = router;