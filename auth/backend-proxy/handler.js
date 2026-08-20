const http = require('http');
const https = require('https');
const { URL } = require('url');

const BACKEND_REQUEST_TIMEOUT_MS = 10_000;

function getBackendBaseUrl() {
  return (process.env.BACKEND_URL || 'http://host.docker.internal:3000').replace(/\/$/, '');
}

const STRIPPED_HEADERS = new Set([
  'host',
  'connection',
  'content-length',
  'x-user-id',
  'x-user-email',
  'x-gateway-trust',
]);

function buildForwardHeaders(event) {
  const headers = { ...(event.headers || {}) };

  for (const name of Object.keys(headers)) {
    if (STRIPPED_HEADERS.has(name.toLowerCase())) {
      delete headers[name];
    }
  }

  const authorizer = event.requestContext?.authorizer?.lambda || {};

  if (authorizer.userId) {
    headers['x-user-id'] = String(authorizer.userId);
  }

  if (authorizer.email) {
    headers['x-user-email'] = String(authorizer.email);
  }

  const trustSecret = process.env.GATEWAY_TRUST_SECRET;
  if (trustSecret) {
    headers['x-gateway-trust'] = trustSecret;
  }

  return headers;
}

function resolveRequestPath(event) {
  if (event.rawPath) {
    return event.rawPath;
  }

  return event.requestContext?.http?.path || '/';
}

function forwardRequest(event) {
  const backendBaseUrl = getBackendBaseUrl();
  const path = resolveRequestPath(event);
  const query = event.rawQueryString ? `?${event.rawQueryString}` : '';
  const targetUrl = new URL(`${backendBaseUrl}${path}${query}`);
  const method = event.requestContext?.http?.method || 'GET';
  const headers = buildForwardHeaders(event);
  const body = event.body
    ? (event.isBase64Encoded ? Buffer.from(event.body, 'base64') : event.body)
    : undefined;

  const client = targetUrl.protocol === 'https:' ? https : http;

  return new Promise((resolve, reject) => {
    const request = client.request(
      targetUrl,
      {
        method,
        headers,
      },
      (response) => {
        const chunks = [];

        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          const responseBody = Buffer.concat(chunks).toString('utf8');
          const responseHeaders = {};

          if (response.headers['content-type']) {
            responseHeaders['Content-Type'] = response.headers['content-type'];
          }

          resolve({
            statusCode: response.statusCode || 502,
            headers: responseHeaders,
            body: responseBody,
          });
        });
      },
    );

    request.setTimeout(BACKEND_REQUEST_TIMEOUT_MS, () => {
      request.destroy(new Error('Backend request timed out'));
    });

    request.on('error', (error) => {
      reject(error);
    });

    if (body) {
      request.write(body);
    }

    request.end();
  });
}

exports.handler = async (event) => {
  try {
    return await forwardRequest(event);
  } catch (error) {
    return {
      statusCode: 502,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        error: 'Backend indisponível',
        detail: error.message,
        hint: 'Inicie a API Express em :3000 com AUTH_MODE=gateway antes do SAM local',
      }),
    };
  }
};
