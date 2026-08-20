const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const lambdaDir = path.resolve(__dirname, '../../auth');
const jsonwebtokenMarker = path.join(lambdaDir, 'node_modules/jsonwebtoken/package.json');

function readQuery() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return {};
  }
}

const query = readQuery();

try {
  execSync('npm ci --omit=dev', {
    cwd: lambdaDir,
    stdio: ['ignore', 'pipe', 'pipe'],
    encoding: 'utf8',
  });
} catch (error) {
  if (error.stdout) {
    process.stderr.write(error.stdout);
  }
  if (error.stderr) {
    process.stderr.write(error.stderr);
  }
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}

if (!fs.existsSync(jsonwebtokenMarker)) {
  process.stderr.write('jsonwebtoken was not installed under auth/node_modules\n');
  process.exit(1);
}

process.stdout.write(
  JSON.stringify({
    prepared: 'true',
    source_hash: query.source_hash || '',
  }),
);
