const DEV_DEFAULTS = {
  jwtSecret: 'local-dev-secret',
  jwtExpiresIn: '1h',
  backendUrl: 'http://host.docker.internal:3000',
  gatewayTrustSecret: 'local-trust',
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
      backendUrl: (process.env.BACKEND_URL || DEV_DEFAULTS.backendUrl).replace(/\/$/, ''),
      gatewayTrustSecret: process.env.GATEWAY_TRUST_SECRET || DEV_DEFAULTS.gatewayTrustSecret,
    };
  }

  return {
    jwtSecret: requireEnv('JWT_SECRET'),
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '1h',
    backendUrl: (process.env.BACKEND_URL || requireEnv('BACKEND_URL')).replace(/\/$/, ''),
    gatewayTrustSecret: requireEnv('GATEWAY_TRUST_SECRET'),
  };
}

module.exports = { getConfig };
