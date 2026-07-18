process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const request = require('supertest');
const server = require('../src/server');
const { pgPool } = require('../src/db/pool');

describe('auth endpoints', () => {
  const email = `test-user-${Date.now()}@example.com`;

  it('serves the health endpoint', async () => {
    const response = await request(server).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  it('registers a user and returns a token', async () => {
    const response = await request(server)
      .post('/auth/register')
      .send({ email, password: 'secret123', full_name: 'Test User' });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user.email).toBe(email);
  });

  it('rejects duplicate registrations with a conflict response', async () => {
    const duplicateEmail = `duplicate-${Date.now()}@example.com`;

    const firstRegistration = await request(server)
      .post('/auth/register')
      .send({ email: duplicateEmail, password: 'secret123', full_name: 'Duplicate User' });

    const secondRegistration = await request(server)
      .post('/auth/register')
      .send({ email: duplicateEmail, password: 'secret123', full_name: 'Duplicate User' });

    expect(firstRegistration.status).toBe(201);
    expect(secondRegistration.status).toBe(409);
    expect(secondRegistration.body).toEqual({ error: 'User already exists' });
  });

  it('normalizes email casing and uses the general_user default type', async () => {
    const mixedCaseEmail = `mixed-case-${Date.now()}@Example.com`;
    const response = await request(server)
      .post('/auth/register')
      .send({ email: mixedCaseEmail, password: 'secret123', full_name: 'Mixed Case User' });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe(mixedCaseEmail.toLowerCase());
    expect(response.body.user.user_type).toBe('general_user');
  });

  it('logs in and returns token + refreshToken', async () => {
    const response = await request(server)
      .post('/auth/login')
      .send({ email, password: 'secret123' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('refreshToken');
  });

  it('refreshes token and then rejects logout-used refreshToken', async () => {
    const login = await request(server)
      .post('/auth/login')
      .send({ email, password: 'secret123' });

    expect(login.status).toBe(200);
    const refreshToken = login.body.refreshToken;

    const refreshed = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken });

    expect(refreshed.status).toBe(200);
    expect(refreshed.body).toHaveProperty('token');

    const refreshedAgain = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken });

    expect(refreshedAgain.status).toBe(401);
  });

  afterAll(async () => {
    if (pgPool) {
      try {
        await pgPool.query('DELETE FROM users WHERE email = $1', ['test-user@example.com']);
      } catch (error) {
        // Ignore cleanup errors when the database is unavailable.
      }

      try {
        await pgPool.end();
      } catch (error) {
        // Ignore cleanup errors when the database is unavailable.
      }
    }

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
});
