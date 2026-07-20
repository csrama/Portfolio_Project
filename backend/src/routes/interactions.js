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
const dbPoolModule = require('../db/pool');

const interactions = new Hono();

const fallbackInteractions = [
  {
    ingredient_a: 'ibuprofen',
    ingredient_b: 'warfarin',
    severity: 'major',
    description: 'NSAIDs increase bleeding risk when combined with warfarin.',
    recommendation: 'Avoid combination; consider acetaminophen for pain relief.'
  },
  {
    ingredient_a: 'digoxin',
    ingredient_b: 'warfarin',
    severity: 'moderate',
    description: 'Warfarin and digoxin both affect coagulation and cardiac rhythm.',
    recommendation: 'Monitor therapy closely and review dosing with a clinician.'
  }
];

function buildPairs(names) {
  const pairs = [];
  for (let i = 0; i < names.length; i += 1) {
    for (let j = i + 1; j < names.length; j += 1) {
      const [a, b] = names[i] < names[j] ? [names[i], names[j]] : [names[j], names[i]];
      pairs.push([a, b]);
    }
  }
  return pairs;
}

function matchFallbackInteractions(pairs) {
  return fallbackInteractions.filter((interaction) => {
    const left = interaction.ingredient_a;
    const right = interaction.ingredient_b;
    return pairs.some(([a, b]) => (a === left && b === right) || (a === right && b === left));
  });
}

interactions.post('/check', async (c) => {
  const body = await c.req.json().catch(() => ({}));
  const rawNames = (body.generic_names || [])
  .map((n) => String(n).trim().toLowerCase())
  .filter(Boolean);

const names = rawNames.map((name) => {
  return name
    .replace(/-alex.*/i, '')
    .replace(/-chemipharm.*/i, '')
    .replace(/-vacsera.*/i, '')
    .replace(/-bioton.*/i, '')
    .replace(/-egyphar.*/i, '')
    .replace(/\d.*$/, '')
    .replace(/\..*$/, '')
    .trim();
});

const uniqueNames = [...new Set(names)];
  const pairs = buildPairs(uniqueNames);
  const values = pairs.map((_, idx) => `($${idx * 2 + 1}, $${idx * 2 + 2})`).join(', ');
  const params = pairs.flat();
  const query = `
    SELECT
      di.ingredient_a,
      di.ingredient_b,
      di.severity,
      di.description,
      di.recommendation,
      di.description_ar,
      di.recommendation_ar
    FROM drug_interactions di
    JOIN (VALUES ${values}) AS pair(a, b)
      ON di.ingredient_a = pair.a
     AND di.ingredient_b = pair.b
`;
  try {
    let result = await dbPoolModule.pool.query(query, params);
    if (dbPoolModule.useMemoryStore) {
      result = { rows: matchFallbackInteractions(pairs) };
    }

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
