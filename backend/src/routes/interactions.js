// backend/src/routes/interactions.js
//
// POST /interactions/check
// Body: { "generic_names": ["warfarin", "ibuprofen", "digoxin"] }
//
// Checks every pair in the given list against drug_interactions.
// Matching is done on generic_name (active ingredient), not brand name,
// so the caller is responsible for resolving each medicine_id -> generic_name
// first (via the medications/medicines join) before calling this endpoint.

const { Hono } = require('hono');
const pool = require('../db/pool');

const interactions = new Hono();

interactions.post('/check', async (c) => {
  const body = await c.req.json();
  const names = (body.generic_names || [])
    .map((n) => String(n).trim().toLowerCase())
    .filter(Boolean);

  if (names.length < 2) {
    return c.json({ error: 'Provide at least 2 generic_names to check.' }, 400);
  }

  // Build every unique pair, stored in canonical (a < b) order to match the table
  const pairs = [];
  for (let i = 0; i < names.length; i++) {
    for (let j = i + 1; j < names.length; j++) {
      const [a, b] = names[i] < names[j] ? [names[i], names[j]] : [names[j], names[i]];
      pairs.push([a, b]);
    }
  }

  const values = pairs.map((_, idx) => `($${idx * 2 + 1}, $${idx * 2 + 2})`).join(', ');
  const params = pairs.flat();

  const query = `
    SELECT di.ingredient_a, di.ingredient_b, di.severity, di.description, di.recommendation
    FROM drug_interactions di
    JOIN (VALUES ${values}) AS pair(a, b)
      ON di.ingredient_a = pair.a AND di.ingredient_b = pair.b
  `;

  try {
    const result = await pool.query(query, params);
    return c.json({
      checked_pairs: pairs.length,
      interactions_found: result.rows.length,
      interactions: result.rows,
    });
  } catch (err) {
    console.error('Interaction check failed:', err);
    return c.json({ error: 'Failed to check interactions.' }, 500);
  }
});

module.exports = interactions;
