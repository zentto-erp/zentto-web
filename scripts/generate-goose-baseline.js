#!/usr/bin/env node
/**
 * generate-goose-baseline.js
 *
 * Lee web/api/sqlweb-pg/run_all.sql, resuelve todas las directivas \i
 * recursivamente y genera una migracion baseline de goose para PostgreSQL.
 *
 * Uso: node scripts/generate-goose-baseline.js
 * Salida: web/api/migrations/postgres/00001_baseline.sql
 */

const fs = require('fs');
const path = require('path');

// ── Rutas ────────────────────────────────────────────────────────────
const ROOT = path.resolve(__dirname, '..');
const RUN_ALL = path.join(ROOT, 'web', 'api', 'sqlweb-pg', 'run_all.sql');
const SQLWEB_PG_DIR = path.dirname(RUN_ALL);
const OUT_DIR = path.join(ROOT, 'web', 'api', 'migrations', 'postgres');
const OUT_FILE = path.join(OUT_DIR, '00001_baseline.sql');
const SQLSERVER_DIR = path.join(ROOT, 'web', 'api', 'migrations', 'sqlserver');
const SEED_MANIFESTS = [
  'run-seeds-config.sql',
  'run-seeds-starter.sql',
  'run-seeds-demo.sql',
];
const LEGACY_FUNCTION_BUNDLES = new Set([
  '01_sec.sql',
  '02_cfg.sql',
  '03_hr.sql',
  '04_inventario.sql',
  '05_master.sql',
  '06_doc.sql',
  '07_acct.sql',
  '08_fin.sql',
  '09_pos.sql',
  '10_fiscal.sql',
  '11_pay.sql',
  '12_sys.sql',
  '13_otros.sql',
]);

// ── Regex ────────────────────────────────────────────────────────────
// \x5c = backslash character (avoid escaping issues in regex literals)
const RE_INCLUDE = new RegExp('^\\\\i(?:r)?\\s+(.+)$');
const RE_ECHO = new RegExp('^\\\\echo\\s');
const RE_EMPTY_OR_COMMENT = /^\s*$|^\s*--/;

// ── Helpers ──────────────────────────────────────────────────────────

/**
 * Lee un archivo SQL. Si no existe, devuelve null.
 */
function readSqlFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

/**
 * Parsea un archivo SQL y resuelve \i recursivamente.
 * Devuelve un array de { path, content } en orden de ejecucion.
 */
function resolveIncludes(filePath, baseDir, visited = new Set()) {
  const abs = path.resolve(baseDir, filePath);

  // Prevenir ciclos
  if (visited.has(abs)) return [];
  visited.add(abs);

  const content = readSqlFile(abs);
  if (content === null) {
    return [{ path: abs, content: null }];
  }

  const results = [];
  const lines = content.split(/\r?\n/);
  const currentDir = path.dirname(abs);

  // Acumular lineas que NO son \i ni \echo para el bloque "inline"
  let inlineLines = [];

  function flushInline() {
    const text = inlineLines.join('\n').trim();
    // Solo omitir si TODAS las lineas son vacias o comentarios
    const hasCode = inlineLines.some(l => {
      const t = l.trim();
      return t !== '' && !t.startsWith('--');
    });
    if (text && hasCode) {
      results.push({ path: abs, content: text });
    }
    inlineLines = [];
  }

  for (const line of lines) {
    const trimmed = line.trim();

    // Ignorar \echo
    if (RE_ECHO.test(trimmed)) continue;

    // Resolver \i
    const match = trimmed.match(RE_INCLUDE);
    if (match) {
      flushInline();
      const includePath = match[1].trim();
      const resolved = resolveIncludes(includePath, currentDir, visited);
      results.push(...resolved);
      continue;
    }

    inlineLines.push(line);
  }

  flushInline();
  return results;
}

function isSeedScriptPath(relPath) {
  return /(^|\/)\d+_seed_[^/]+\.sql$/i.test(relPath) || /(^|\/)seed_[^/]+\.sql$/i.test(relPath);
}

function shouldSkipFunctionBlock(relPath) {
  const normalized = relPath.replace(/\\/g, '/');
  const baseName = path.posix.basename(normalized);

  if (LEGACY_FUNCTION_BUNDLES.has(baseName)) {
    return true;
  }

  if (!normalized.startsWith('includes/sp/')) {
    return false;
  }

  // El bootstrap frio corre goose up y luego run-functions.sql.
  // Dejamos en baseline solo DDL auxiliar requerido por el schema.
  return !/^includes\/sp\/(create_|alter_)/i.test(normalized);
}

function collectSeedManagedPaths() {
  const excluded = new Set();

  for (const manifest of SEED_MANIFESTS) {
    const blocks = resolveIncludes(manifest, SQLWEB_PG_DIR, new Set());

    for (const block of blocks) {
      if (block.content === null) continue;
      excluded.add(path.resolve(block.path));
    }
  }

  return excluded;
}

// ── Main ─────────────────────────────────────────────────────────────

function main() {
  console.log('Generando migracion baseline de goose para PostgreSQL...');
  console.log(`  Fuente: ${RUN_ALL}`);
  console.log(`  Salida:  ${OUT_FILE}`);
  console.log('');

  // Verificar que run_all.sql existe
  if (!fs.existsSync(RUN_ALL)) {
    console.error(`ERROR: No se encontro ${RUN_ALL}`);
    process.exit(1);
  }

  // Crear directorios de salida
  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.mkdirSync(SQLSERVER_DIR, { recursive: true });
  console.log(`  Directorio creado: ${OUT_DIR}`);
  console.log(`  Directorio creado: ${SQLSERVER_DIR}`);

  // Resolver todos los includes
  const blocks = resolveIncludes('run_all.sql', SQLWEB_PG_DIR);
  const seedManagedPaths = collectSeedManagedPaths();

  console.log(`  Bloques resueltos: ${blocks.length}`);
  console.log(`  Bloques excluidos por seeds: ${seedManagedPaths.size}`);

  // Construir el archivo de salida
  const parts = [];

  parts.push('-- +goose Up');
  parts.push('-- Baseline migration: estado completo de la base de datos');
  parts.push(`-- Generado automaticamente desde run_all.sql el ${new Date().toISOString().slice(0, 10)}`);
  parts.push('');

  let missing = 0;
  let included = 0;
  let skipped = 0;

  for (const block of blocks) {
    const relPath = path.relative(SQLWEB_PG_DIR, block.path).replace(/\\/g, '/');

    if (block.content === null) {
      parts.push(`-- MISSING: ${relPath}`);
      parts.push('');
      missing++;
      continue;
    }

    // Saltar bloques vacios o solo comentarios
    const stripped = block.content
      .split(/\r?\n/)
      .filter(l => !RE_EMPTY_OR_COMMENT.test(l.trim()))
      .join('')
      .trim();

    if (!stripped) continue;
    if (seedManagedPaths.has(path.resolve(block.path)) || isSeedScriptPath(relPath)) {
      skipped++;
      continue;
    }
    if (shouldSkipFunctionBlock(relPath)) {
      skipped++;
      continue;
    }

    parts.push(`-- +goose StatementBegin`);
    parts.push(`-- Source: ${relPath}`);
    parts.push(block.content);
    parts.push(`-- +goose StatementEnd`);
    parts.push('');
    included++;
  }

  parts.push('-- +goose Down');
  parts.push('-- No rollback para baseline');
  parts.push('');

  const output = parts.join('\n');
  fs.writeFileSync(OUT_FILE, output, 'utf8');

  const sizeMB = (Buffer.byteLength(output, 'utf8') / 1024 / 1024).toFixed(2);

  console.log('');
  console.log(`  Bloques incluidos: ${included}`);
  console.log(`  Bloques omitidos: ${skipped}`);
  console.log(`  Archivos faltantes: ${missing}`);
  console.log(`  Tamano del archivo: ${sizeMB} MB`);
  console.log(`  Archivo generado: ${OUT_FILE}`);
  console.log('');
  console.log('Listo.');
}

main();
