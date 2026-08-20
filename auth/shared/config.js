const DEV_DEFAULTS = {
  jwtSecret: 'local-dev-secret',
  jwtExpiresIn: '1h',
  authEmail: 'admin@example.com',
  authPassword: 'admin123',
};

function requireEnv(name) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

function getConfig() {
  const allowDevDefaults = process.env.ALLOW_DEV_AUTH_DEFAULTS === 'true';

  if (allowDevDefaults) {
    return {
      jwtSecret: process.env.JWT_SECRET || DEV_DEFAULTS.jwtSecret,
      jwtExpiresIn: process.env.JWT_EXPIRES_IN || DEV_DEFAULTS.jwtExpiresIn,
      authEmail: process.env.AUTH_EMAIL || DEV_DEFAULTS.authEmail,
      authPassword: process.env.AUTH_PASSWORD || DEV_DEFAULTS.authPassword,
    };
  }

  return {
    jwtSecret: requireEnv('JWT_SECRET'),
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '1h',
    authEmail: requireEnv('AUTH_EMAIL'),
    authPassword: requireEnv('AUTH_PASSWORD'),
  };
}

module.exports = { getConfig };
