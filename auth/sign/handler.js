const { getConfig } = require('../shared/config');
const { sign } = require('../shared/jwt');

exports.handler = async (event) => {
  let body;

  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Invalid JSON body' }),
    };
  }

  const { email, password } = body;

  if (!email || !password) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email e senha são obrigatórios' }),
    };
  }

  const { authEmail, authPassword } = getConfig();

  if (email !== authEmail || password !== authPassword) {
    return {
      statusCode: 401,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Credenciais inválidas' }),
    };
  }

  const token = sign({ userId: 'mock-user', email });

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token }),
  };
};
