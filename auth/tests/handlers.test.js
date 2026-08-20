const { sign, verify } = require('../shared/jwt');
const { handler: signHandler } = require('../sign/handler');
const { handler: authorizerHandler } = require('../authorizer/handler');

describe('auth lambda jwt helpers', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.AUTH_EMAIL = 'admin@example.com';
    process.env.AUTH_PASSWORD = 'admin123';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
  });

  test('sign and verify round-trip', () => {
    const token = sign({ userId: 'mock-user', email: 'admin@example.com' });
    const payload = verify(token);

    expect(payload.userId).toBe('mock-user');
    expect(payload.email).toBe('admin@example.com');
  });

  test('rejects missing JWT_SECRET when dev defaults are disabled', () => {
    delete process.env.JWT_SECRET;

    expect(() => sign({ userId: 'mock-user', email: 'admin@example.com' })).toThrow(
      'Missing required environment variable: JWT_SECRET',
    );
  });
});

describe('auth sign handler', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.AUTH_EMAIL = 'admin@example.com';
    process.env.AUTH_PASSWORD = 'admin123';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
  });

  test('returns token for valid credentials', async () => {
    const result = await signHandler({
      body: JSON.stringify({
        email: 'admin@example.com',
        password: 'admin123',
      }),
    });

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body).token).toBeDefined();
  });

  test('returns 401 for invalid credentials', async () => {
    const result = await signHandler({
      body: JSON.stringify({
        email: 'wrong@example.com',
        password: 'badpass',
      }),
    });

    expect(result.statusCode).toBe(401);
    expect(JSON.parse(result.body).error).toBe('Credenciais inválidas');
  });

  test('returns 400 when email or password is missing', async () => {
    const result = await signHandler({
      body: JSON.stringify({ email: 'admin@example.com' }),
    });

    expect(result.statusCode).toBe(400);
  });
});

describe('auth authorizer handler', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
  });

  test('authorizes valid bearer token', async () => {
    const token = sign({ userId: 'mock-user', email: 'admin@example.com' });

    const result = await authorizerHandler({
      headers: { authorization: `Bearer ${token}` },
    });

    expect(result.isAuthorized).toBe(true);
    expect(result.context.userId).toBe('mock-user');
    expect(result.context.email).toBe('admin@example.com');
  });

  test('rejects missing authorization header', async () => {
    const result = await authorizerHandler({ headers: {} });

    expect(result.isAuthorized).toBe(false);
  });

  test('rejects invalid token', async () => {
    const result = await authorizerHandler({
      headers: { authorization: 'Bearer invalid.token.value' },
    });

    expect(result.isAuthorized).toBe(false);
  });
});
