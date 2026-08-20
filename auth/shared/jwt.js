const jwt = require('jsonwebtoken');
const { getConfig } = require('./config');

function sign(payload) {
  const { jwtSecret, jwtExpiresIn } = getConfig();
  return jwt.sign(payload, jwtSecret, { expiresIn: jwtExpiresIn });
}

function verify(token) {
  const { jwtSecret } = getConfig();
  return jwt.verify(token, jwtSecret);
}

module.exports = { sign, verify };
