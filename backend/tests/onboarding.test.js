
const request = require('supertest');
const app = require('../src/index');
const server = require('../src/server');
const hederaService = require('../src/services/hedera.service');
const { Pool } = require('pg');
const db = require('../config/database');

// Mock services
jest.mock('pg');
jest.mock('../src/services/hedera.service');


describe('Onboarding Routes', () => {
  afterAll((done) => {
    hederaService.client.close();
    server.close(done);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/v1/onboard', () => {
    it('should create a new account and return 201', async () => {
      const mockAccountId = '0.0.12345';
      const mockUser = { id: 1, identifier: 'test@example.com', account_id: mockAccountId };
      hederaService.createAccount.mockResolvedValue({ accountId: mockAccountId });
      db.query.mockResolvedValue({ rows: [mockUser] });

      const res = await request(app)
        .post('/api/v1/onboard')
        .send({
          publicKey: '302a300506032b6570032100e932b21f7535787183e970f37ea35ef3d21f2a013a2a90cf30303e4d9b1b86a1',
          identifier: 'test@example.com',
        });

      expect(res.statusCode).toEqual(201);
      expect(res.body.data.account.accountId).toEqual(mockAccountId);
      expect(res.body.data.user.identifier).toEqual('test@example.com');
      expect(hederaService.createAccount).toHaveBeenCalledWith('302a300506032b6570032100e932b21f7535787183e970f37ea35ef3d21f2a013a2a90cf30303e4d9b1b86a1');
    });

    it('should return 400 if publicKey is missing', async () => {
      const res = await request(app)
        .post('/api/v1/onboard')
        .send({
          identifier: 'test@example.com',
        });

      expect(res.statusCode).toEqual(400);
    });

    it('should return 400 if identifier is missing', async () => {
      const res = await request(app)
        .post('/api/v1/onboard')
        .send({
          publicKey: '302a300506032b6570032100e932b21f7535787183e970f37ea35ef3d21f2a013a2a90cf30303e4d9b1b86a1',
        });

      expect(res.statusCode).toEqual(400);
    });
  });

  describe('POST /api/v1/verify-attendance', () => {
    it('should verify attendance and return 200', async () => {
      const mockUser = { id: 1, identifier: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] }); // for getUserByIdentifier
      db.query.mockResolvedValueOnce({ rows: [{}] }); // for recordAttendance

      const res = await request(app)
        .post('/api/v1/verify-attendance')
        .send({ identifier: 'test@example.com' });

      expect(res.statusCode).toEqual(200);
    });
  });

  describe('GET /api/v1/metrics/onboarding', () => {
    it('should return onboarding metrics and return 200', async () => {
      const mockMetrics = { new_wallets: '10' };
      db.query.mockResolvedValue({ rows: [mockMetrics] });

      const res = await request(app).get('/api/v1/metrics/onboarding');

      expect(res.statusCode).toEqual(200);
      expect(res.body.data).toEqual({ newWallets: 10, activations: 10 });
    });
  });
});
