const fs = require('fs');
const path = require('path');
const { loadEnvLocal } = require('./load-env');
const { handler } = require('../sign/handler');

loadEnvLocal();

const eventPath = path.join(__dirname, '..', 'events', 'login-event.json');
const event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));

handler(event)
  .then((result) => {
    console.log(JSON.stringify(result, null, 2));
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
