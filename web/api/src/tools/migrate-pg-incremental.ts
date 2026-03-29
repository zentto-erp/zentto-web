/**
 * migrate-pg-incremental.ts
 *
 * [LEGACY] Ejecuta migraciones incrementales de PostgreSQL sobre sqlweb-pg/migrations.
 * - La ruta can??nica de despliegue es web/api/migrations/postgres (goose)
 * - Este script solo existe para recuperar fixes legacy mientras se absorben
 * - Registra cada migración aplicada en public._migrations
 * - Idempotente: salta migraciones ya aplicadas
 * - Para instalaciones nuevas: ejecutar run_all.sql primero, luego este script
 * - No usar como fuente principal para produccion nueva
 *
 * Uso:
 *   npm run db:migrate:pg:incremental
 *
 * Variables de entorno requeridas:
 *   PG_HOST, PG_PORT, PG_DATABASE, PG_USER, PG_PASSWORD
 *   o PG_CONNECTION_STRING
 */

import pg from 'pg';
import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = join(__dirname, '../../sqlweb-pg/migrations');

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

function createPool(): pg.Pool {
  if (process.env.PG_CONNECTION_STRING) {
    return new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING });
  }
  return new pg.Pool({
    host:     process.env.PG_HOST     ?? '127.0.0.1',
    port:     Number(process.env.PG_PORT ?? 5432),
    database: process.env.PG_DATABASE ?? 'zentto_prod',
    user:     process.env.PG_USER     ?? 'zentto_app',
    password: process.env.PG_PASSWORD ?? '',
    ssl:      process.env.PG_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Tabla de control
// ────────────────────────────────────────────────────────────────────────────

const CREATE_MIGRATIONS_TABLE = `
  CREATE TABLE IF NOT EXISTS public._migrations (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    duration_ms INT         NOT NULL DEFAULT 0,
    checksum   VARCHAR(64)
  );
`;

async function ensureMigrationsTable(client: pg.PoolClient): Promise<void> {
  await client.query(CREATE_MIGRATIONS_TABLE);
}

async function getAppliedMigrations(client: pg.PoolClient): Promise<Set<string>> {
  const res = await client.query<{ name: string }>(`SELECT name FROM public._migrations ORDER BY name`);
  return new Set(res.rows.map(r => r.name));
}

async function recordMigration(
  client: pg.PoolClient,
  name: string,
  durationMs: number,
): Promise<void> {
  await client.query(
    `INSERT INTO public._migrations (name, duration_ms) VALUES ($1, $2) ON CONFLICT (name) DO NOTHING`,
    [name, durationMs],
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Archivos de migración
// ────────────────────────────────────────────────────────────────────────────

function getMigrationFiles(): string[] {
  if (!existsSync(MIGRATIONS_DIR)) {
    console.warn(`[WARN] Directorio de migraciones no encontrado: ${MIGRATIONS_DIR}`);
    return [];
  }
  return readdirSync(MIGRATIONS_DIR)
    .filter(f => f.endsWith('.sql'))
    .sort(); // orden lexicográfico por nombre (ej: 001_, 002_, ...)
}

// ────────────────────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('');
  console.log('══════════════════════════════════════════════════════');
  console.log('  Zentto — Migraciones PostgreSQL Incrementales');
  console.log('══════════════════════════════════════════════════════');
  console.log('');

  const pool = createPool();
  const client = await pool.connect();

  try {
    // Garantizar tabla de control
    await ensureMigrationsTable(client);
    const applied = await getAppliedMigrations(client);

    const files = getMigrationFiles();
    if (files.length === 0) {
      console.log('[INFO] No hay archivos de migración en', MIGRATIONS_DIR);
      return;
    }

    const pending = files.filter(f => !applied.has(f));
    console.log(`[INFO] Migraciones totales: ${files.length} | Aplicadas: ${applied.size} | Pendientes: ${pending.length}`);
    console.log('');

    if (pending.length === 0) {
      console.log('[OK]   Base de datos al día. Nada que aplicar.');
      return;
    }

    let successCount = 0;
    let errorCount = 0;

    for (const file of pending) {
      const filePath = join(MIGRATIONS_DIR, file);
      const sql = readFileSync(filePath, 'utf-8');
      const start = Date.now();

      process.stdout.write(`[RUN]  ${file} ... `);

      try {
        await client.query('BEGIN');
        await client.query(sql);
        const durationMs = Date.now() - start;
        await recordMigration(client, file, durationMs);
        await client.query('COMMIT');
        console.log(`✓ (${durationMs}ms)`);
        successCount++;
      } catch (err) {
        await client.query('ROLLBACK');
        const msg = (err as Error).message.split('\n')[0];
        console.log(`✗`);
        console.error(`[ERROR] ${file}: ${msg}`);
        errorCount++;
        // Detener al primer error — no aplicar migraciones dependientes
        break;
      }
    }

    console.log('');
    console.log('──────────────────────────────────────────────────────');
    console.log(`[DONE] Exitosas: ${successCount} | Errores: ${errorCount}`);
    console.log('══════════════════════════════════════════════════════');
    console.log('');

    if (errorCount > 0) {
      process.exit(1);
    }
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[FATAL]', (err as Error).message);
  process.exit(1);
});
