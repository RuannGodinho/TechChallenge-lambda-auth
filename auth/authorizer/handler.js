const { verify } = require('../shared/jwt');

function extractBearerToken(event) {
  const headers = event.headers || {};
  const authHeader = headers.authorization || headers.Authorization;

  if (!authHeader) {
    return null;
  }

  const [scheme, token] = authHeader.split(' ');

  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    return null;
  }

  return token;
}

exports.handler = async (event) => {
  const token = extractBearerToken(event);

  if (!token) {
    return { isAuthorized: false };
  }

  try {
    const payload = verify(token);

    return {
      isAuthorized: true,
      context: {
        userId: String(payload.userId),
        email: String(payload.email),
      },
    };
  } catch {
    return { isAuthorized: false };
  }
};
