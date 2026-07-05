process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const request = require('supertest');
const server = require('../src/server');

describe('offline auth endpoints', () => {
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

  it('creates and verifies an offline OTP challenge', async () => {
    const challengeResponse = await request(server)
      .post('/auth/offline/challenge')
      .send({ provider: 'otp', identifier: 'offline-user@example.com' });

    expect(challengeResponse.status).toBe(200);
    expect(challengeResponse.body).toEqual(
      expect.objectContaining({
        provider: 'otp',
        challengeId: expect.any(String),
        code: expect.any(String)
      })
    );

    const verifyResponse = await request(server)
      .post('/auth/offline/verify')
      .send({
        provider: 'otp',
        identifier: 'offline-user@example.com',
        challengeId: challengeResponse.body.challengeId,
        code: challengeResponse.body.code
      });

    expect(verifyResponse.status).toBe(200);
    expect(verifyResponse.body).toHaveProperty('token');
    expect(verifyResponse.body.user.email).toBe('offline-user@example.com');
  });
});
