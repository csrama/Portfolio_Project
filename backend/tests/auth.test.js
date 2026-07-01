const request = require('supertest');
const app = require('../src/server');

describe('auth endpoints', () => {
  it('registers a user and returns a token', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ email: 'test-user@example.com', password: 'secret123', full_name: 'Test User' });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user.email).toBe('test-user@example.com');
  });

  it('logs in and returns a token', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({ email: 'test-user@example.com', password: 'secret123' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });
});
