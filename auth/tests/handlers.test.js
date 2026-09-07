const { EventEmitter } = require('events');
const http = require('http');
const { sign, verify } = require('../shared/jwt');
const { handler: signHandler } = require('../sign/handler');
const { handler: authorizerHandler } = require('../authorizer/handler');

jest.mock('http', () => ({
  request: jest.fn(),
}));

const ACTIVE_CPF = '81788455045';
const INACTIVE_CPF = '52263606068';

function createMockRequest() {
  const request = new EventEmitter();
  request.write = jest.fn();
  request.end = jest.fn();
  request.setTimeout = jest.fn();
  request.destroy = jest.fn();
  return request;
}

function mockLookup({ statusCode, body }) {
  const response = new EventEmitter();
  response.statusCode = statusCode;
  const request = createMockRequest();

  http.request.mockImplementation((_url, _options, callback) => {
    callback(response);
    process.nextTick(() => {
      response.emit('data', Buffer.from(JSON.stringify(body)));
      response.emit('end');
    });
    return request;
  });
}

describe('auth lambda jwt helpers', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.BACKEND_URL = 'http://backend.test:3000';
    process.env.GATEWAY_TRUST_SECRET = 'test-trust-secret';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
  });

  test('sign and verify round-trip', () => {
    const token = sign({ userId: 'client-1', cpf: ACTIVE_CPF, email: 'ruann@gmail.com' });
    const payload = verify(token);

    expect(payload.userId).toBe('client-1');
    expect(payload.cpf).toBe(ACTIVE_CPF);
    expect(payload.email).toBe('ruann@gmail.com');
  });

  test('rejects missing JWT_SECRET when dev defaults are disabled', () => {
    delete process.env.JWT_SECRET;

    expect(() => sign({ userId: 'client-1', cpf: ACTIVE_CPF, email: 'ruann@gmail.com' })).toThrow(
      'Missing required environment variable: JWT_SECRET',
    );
  });
});

describe('auth sign handler', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.BACKEND_URL = 'http://backend.test:3000';
    process.env.GATEWAY_TRUST_SECRET = 'test-trust-secret';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
    http.request.mockReset();
  });

  test('returns token for an active CPF', async () => {
    mockLookup({
      statusCode: 200,
      body: {
        id: 'client-1',
        cpf: ACTIVE_CPF,
        email: 'ruann@gmail.com',
        nome: 'Ruann Godinho',
        status: 'ATIVO',
      },
    });

    const result = await signHandler({
      body: JSON.stringify({ cpf: ACTIVE_CPF }),
    });

    expect(result.statusCode).toBe(200);
    const { token } = JSON.parse(result.body);
    expect(token).toBeDefined();
    expect(verify(token).cpf).toBe(ACTIVE_CPF);
    expect(verify(token).userId).toBe('client-1');
  });

  test('returns 401 when the CPF is not registered', async () => {
    mockLookup({ statusCode: 404, body: { error: 'Cliente não encontrado' } });

    const result = await signHandler({
      body: JSON.stringify({ cpf: ACTIVE_CPF }),
    });

    expect(result.statusCode).toBe(401);
    expect(JSON.parse(result.body).error).toBe('Cliente não encontrado');
  });

  test('returns 403 when the client is inactive', async () => {
    mockLookup({
      statusCode: 200,
      body: {
        id: 'client-2',
        cpf: INACTIVE_CPF,
        email: 'joao@example.com',
        nome: 'João Pereira',
        status: 'INATIVO',
      },
    });

    const result = await signHandler({
      body: JSON.stringify({ cpf: INACTIVE_CPF }),
    });

    expect(result.statusCode).toBe(403);
    expect(JSON.parse(result.body).error).toBe('Cliente inativo');
  });

  test('returns 400 when CPF is missing', async () => {
    const result = await signHandler({
      body: JSON.stringify({}),
    });

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).error).toBe('CPF é obrigatório');
  });

  test('returns 400 when CPF is invalid', async () => {
    const result = await signHandler({
      body: JSON.stringify({ cpf: '11111111111' }),
    });

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).error).toBe('CPF inválido');
  });
});

describe('auth authorizer handler', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.BACKEND_URL = 'http://backend.test:3000';
    process.env.GATEWAY_TRUST_SECRET = 'test-trust-secret';
    delete process.env.ALLOW_DEV_AUTH_DEFAULTS;
  });

  test('authorizes valid bearer token', async () => {
    const token = sign({ userId: 'client-1', cpf: ACTIVE_CPF, email: 'ruann@gmail.com' });

    const result = await authorizerHandler({
      headers: { authorization: `Bearer ${token}` },
    });

    expect(result.isAuthorized).toBe(true);
    expect(result.context.userId).toBe('client-1');
    expect(result.context.cpf).toBe(ACTIVE_CPF);
    expect(result.context.email).toBe('ruann@gmail.com');
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
