process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const request = require('supertest');
const app = require('../src/server');

describe('auth endpoints', () => {
  const email = `test-user-${Date.now()}@example.com`;

  it('serves the health endpoint', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  it('registers a user and returns a token', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ email, password: 'secret123', full_name: 'Test User' });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user.email).toBe(email);
  });

  it('normalizes email casing and uses the general_user default type', async () => {
    const mixedCaseEmail = `mixed-case-${Date.now()}@Example.com`;
    const response = await request(app)
      .post('/auth/register')
      .send({ email: mixedCaseEmail, password: 'secret123', full_name: 'Mixed Case User' });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe(mixedCaseEmail.toLowerCase());
    expect(response.body.user.user_type).toBe('general_user');
  });

  it('logs in and returns a token', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({ email, password: 'secret123' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });
});
