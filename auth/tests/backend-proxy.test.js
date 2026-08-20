const http = require('http');
const { EventEmitter } = require('events');

jest.mock('http', () => ({
  request: jest.fn(),
}));

const { handler } = require('../backend-proxy/handler');

function createMockRequest() {
  const request = new EventEmitter();
  request.write = jest.fn();
  request.end = jest.fn();
  request.setTimeout = jest.fn();
  request.destroy = jest.fn();
  return request;
}

describe('backend-proxy handler', () => {
  beforeEach(() => {
    process.env.BACKEND_URL = 'http://backend.test:3000';
    process.env.GATEWAY_TRUST_SECRET = 'test-trust-secret';
    http.request.mockReset();
  });

  test('forwards request and injects authorizer headers', async () => {
    const response = new EventEmitter();
    response.statusCode = 200;
    response.headers = { 'content-type': 'application/json' };

    const request = createMockRequest();

    http.request.mockImplementation((_url, _options, callback) => {
      callback(response);
      process.nextTick(() => {
        response.emit('data', Buffer.from('{"ok":true}'));
        response.emit('end');
      });
      return request;
    });

    const result = await handler({
      rawPath: '/api/clientes',
      headers: { host: 'localhost:3001', authorization: 'Bearer token' },
      requestContext: {
        http: { method: 'GET', path: '/api/clientes' },
        authorizer: {
          lambda: {
            userId: 'mock-user',
            email: 'admin@example.com',
          },
        },
      },
    });

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body)).toEqual({ ok: true });

    const [, options] = http.request.mock.calls[0];
    expect(options.method).toBe('GET');
    expect(options.headers['x-user-id']).toBe('mock-user');
    expect(options.headers['x-user-email']).toBe('admin@example.com');
    expect(options.headers['x-gateway-trust']).toBe('test-trust-secret');
    expect(options.headers.host).toBeUndefined();
  });

  test('strips forged identity headers before injecting authorizer values', async () => {
    const response = new EventEmitter();
    response.statusCode = 200;
    response.headers = { 'content-type': 'application/json' };

    const request = createMockRequest();

    http.request.mockImplementation((_url, _options, callback) => {
      callback(response);
      process.nextTick(() => {
        response.emit('data', Buffer.from('{}'));
        response.emit('end');
      });
      return request;
    });

    await handler({
      rawPath: '/api/clientes',
      headers: {
        'X-User-Id': 'attacker-id',
        'X-User-Email': 'attacker@example.com',
      },
      requestContext: {
        http: { method: 'GET', path: '/api/clientes' },
        authorizer: {
          lambda: {
            userId: 'mock-user',
            email: 'admin@example.com',
          },
        },
      },
    });

    const [, options] = http.request.mock.calls[0];
    expect(options.headers['x-user-id']).toBe('mock-user');
    expect(options.headers['x-user-email']).toBe('admin@example.com');
  });

  test('returns 502 when backend is unavailable', async () => {
    const request = createMockRequest();

    http.request.mockImplementation(() => {
      process.nextTick(() => request.emit('error', new Error('connect ECONNREFUSED')));
      return request;
    });

    const result = await handler({
      rawPath: '/api/clientes',
      headers: {},
      requestContext: {
        http: { method: 'GET', path: '/api/clientes' },
      },
    });

    expect(result.statusCode).toBe(502);
    expect(JSON.parse(result.body).error).toBe('Backend indisponível');
  });

  test('returns 502 when backend request times out', async () => {
    const request = createMockRequest();
    request.setTimeout = jest.fn((_ms, callback) => {
      process.nextTick(callback);
    });
    request.destroy = jest.fn((error) => {
      request.emit('error', error);
    });

    http.request.mockImplementation(() => request);

    const result = await handler({
      rawPath: '/api/clientes',
      headers: {},
      requestContext: {
        http: { method: 'GET', path: '/api/clientes' },
      },
    });

    expect(result.statusCode).toBe(502);
    expect(JSON.parse(result.body).detail).toBe('Backend request timed out');
    expect(request.destroy).toHaveBeenCalledWith(expect.objectContaining({
      message: 'Backend request timed out',
    }));
  });
});
