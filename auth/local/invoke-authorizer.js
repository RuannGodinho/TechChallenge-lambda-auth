const fs = require('fs');
const path = require('path');
const { loadEnvLocal } = require('./load-env');
const { handler } = require('../authorizer/handler');
const { sign } = require('../shared/jwt');

loadEnvLocal();

const tokenArgIndex = process.argv.indexOf('--token');
const tokenFromArg = tokenArgIndex !== -1 ? process.argv[tokenArgIndex + 1] : null;
const token = tokenFromArg || sign({ userId: 'mock-user', email: 'admin@example.com' });

const eventPath = path.join(__dirname, '..', 'events', 'authorizer-event.json');
const event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));
event.headers.authorization = `Bearer ${token}`;

handler(event)
  .then((result) => {
    console.log(JSON.stringify(result, null, 2));
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
