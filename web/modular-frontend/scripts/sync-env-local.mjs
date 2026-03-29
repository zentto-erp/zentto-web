import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');
const appsDir = path.join(rootDir, 'apps');
const sourceFile = path.join(appsDir, 'shell', '.env.local');
const rootEnvFile = path.join(rootDir, '.env.local');

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

if (!fs.existsSync(sourceFile)) {
  fail(`No se encontro el archivo fuente ${sourceFile}`);
}

const sourceContent = fs.readFileSync(sourceFile, 'utf8');
const appNames = fs.readdirSync(appsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort((left, right) => left.localeCompare(right));

fs.writeFileSync(rootEnvFile, sourceContent, 'utf8');
console.log('Sincronizando apps/shell/.env.local -> .env.local y apps/*/.env.local');
console.log('  ✓ raiz');

for (const appName of appNames) {
  const targetFile = path.join(appsDir, appName, '.env.local');
  fs.writeFileSync(targetFile, sourceContent, 'utf8');
  console.log(`  ✓ ${appName}`);
}

console.log('');
console.log('Listo. Todas las micro-apps comparten el mismo .env.local.');
console.log('Edita apps/shell/.env.local y ejecuta npm run env:sync.');