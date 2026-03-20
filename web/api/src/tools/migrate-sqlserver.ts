/**
 * migrate-sqlserver.ts
 *
 * Ejecuta migraciones incrementales de SQL Server para desarrollo local.
 * - Lee archivos .sql de sqlweb/migrations/ ordenados por nombre
 * - Registra cada migración aplicada en dbo._Migrations
 * - Idempotente: salta migraciones ya aplicadas
 * - Conecta al servidor local DELLXEONE31545 / DatqBoxWeb
 *
 * Uso:
 *   npm run db:migrate:sqlserver
 *
 * Variables de entorno (web/api/.env):
 *   SS_SERVER, SS_DATABASE, SS_USER, SS_PASSWORD
 *   o SS_CONNECTION_STRING
 */

import sql from 'mssql';
import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = join(__dirname, '../../sqlweb/migrations');

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

function getConfig(): sql.config {
  if (process.env.SS_CONNECTION_STRING) {
    return { connectionString: process.env.SS_CONNECTION_STRING } as any;
  }
  return {
    server:   process.env.SS_SERVER   ?? 'DELLXEONE31545',
    database: process.env.SS_DATABASE ?? 'DatqBoxWeb',
    user:     process.env.SS_USER     ?? 'sa',
    password: process.env.SS_PASSWORD ?? '1234',
    options: {
      encrypt:                false,
      trustServerCertificate: true,
    },
  };
}

// ────────────────────────────────────────────────────────────────────────────
// Tabla de control
// ────────────────────────────────────────────────────────────────────────────

const CREATE_MIGRATIONS_TABLE = `
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '_Migrations'
  )
  CREATE TABLE dbo._Migrations (
    Id         INT IDENTITY(1,1) PRIMARY KEY,
    Name       NVARCHAR(255)   NOT NULL UNIQUE,
    AppliedAt  DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    DurationMs INT             NOT NULL DEFAULT 0
  );
`;

async function ensureMigrationsTable(pool: sql.ConnectionPool): Promise<void> {
  await pool.request().query(CREATE_MIGRATIONS_TABLE);
}

async function getAppliedMigrations(pool: sql.ConnectionPool): Promise<Set<string>> {
  const res = await pool.request().query<{ Name: string }>(
    `SELECT Name FROM dbo._Migrations ORDER BY Name`
  );
  return new Set(res.recordset.map(r => r.Name));
}

async function recordMigration(
  pool: sql.ConnectionPool,
  name: string,
  durationMs: number,
): Promise<void> {
  await pool.request()
    .input('Name', sql.NVarChar(255), name)
    .input('DurationMs', sql.Int, durationMs)
    .query(
      `IF NOT EXISTS (SELECT 1 FROM dbo._Migrations WHERE Name = @Name)
       INSERT INTO dbo._Migrations (Name, DurationMs) VALUES (@Name, @DurationMs)`
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
    .sort();
}

/**
 * SQL Server no permite múltiples sentencias con BEGIN/COMMIT a nivel de
 * transacción cuando hay DDL como CREATE PROCEDURE. Dividimos por GO.
 */
function splitBatches(sqlContent: string): string[] {
  return sqlContent
    .split(/^\s*GO\s*$/im)
    .map(b => b.trim())
    .filter(b => b.length > 0);
}

// ────────────────────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('');
  console.log('══════════════════════════════════════════════════════');
  console.log('  Zentto — Migraciones SQL Server (local dev)');
  console.log('══════════════════════════════════════════════════════');
  console.log('');

  const config = getConfig();
  console.log(`[INFO] Conectando a ${config.server ?? 'SS'}/${config.database ?? 'DB'}...`);

  let pool: sql.ConnectionPool;
  try {
    pool = await sql.connect(config);
    console.log('[OK]   Conexión establecida.');
  } catch (err) {
    console.error('[ERROR] No se pudo conectar:', (err as Error).message);
    process.exit(1);
  }

  try {
    await ensureMigrationsTable(pool);
    const applied = await getAppliedMigrations(pool);

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
      const content = readFileSync(filePath, 'utf-8');
      const batches = splitBatches(content);
      const start = Date.now();

      process.stdout.write(`[RUN]  ${file} (${batches.length} batches) ... `);

      let failed = false;
      for (const batch of batches) {
        try {
          await pool.request().query(batch);
        } catch (err) {
          const msg = (err as Error).message.split('\n')[0];
          console.log(`✗`);
          console.error(`[ERROR] ${file}: ${msg}`);
          failed = true;
          errorCount++;
          break;
        }
      }

      if (!failed) {
        const durationMs = Date.now() - start;
        await recordMigration(pool, file, durationMs);
        console.log(`✓ (${durationMs}ms)`);
        successCount++;
      } else {
        break; // detener al primer error
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
    await pool.close();
  }
}

main().catch((err) => {
  console.error('[FATAL]', (err as Error).message);
  process.exit(1);
});
