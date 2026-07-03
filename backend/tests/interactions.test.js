process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const request = require('supertest');
const server = require('../src/server');

describe('interactions endpoints', () => {
  afterAll(async () => {
    if (server && typeof server.close === 'function') {
      await new Promise((resolve, reject) => {
        server.close((error) => {
          if (error) {
            reject(error);
            return;
          }
          resolve();
        });
      });
    }
  });

  it('returns matching drug interactions for the supplied generic names', async () => {
    const response = await request(server)
      .post('/interactions/check')
      .send({ generic_names: ['warfarin', 'ibuprofen', 'digoxin'] });

    expect(response.status).toBe(200);
    expect(response.body.checked_pairs).toBe(3);
    expect(response.body.interactions_found).toBeGreaterThan(0);
    expect(response.body.interactions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ ingredient_a: 'ibuprofen', ingredient_b: 'warfarin' })
      ])
    );
  });

  it('rejects requests with fewer than two generic names', async () => {
    const response = await request(server)
      .post('/interactions/check')
      .send({ generic_names: ['warfarin'] });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'Provide at least 2 generic_names to check.' });
  });
});
