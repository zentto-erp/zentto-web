/**
 * schema-extract.ts
 *
 * Extrae el esquema completo de PostgreSQL y genera archivos SQL organizados.
 * Conecta a la DB (producción via tunnel o local), lee todos los objetos y
 * exporta cada uno en su archivo correspondiente bajo sqlweb-pg/extracted/.
 *
 * Esto permite tener el esquema real en código sin mantenerlo manualmente.
 *
 * Uso:
 *   # 1. Abrir tunnel SSH si es producción:
 *   #    ssh -L 5433:127.0.0.1:5432 root@178.104.56.185
 *   # 2. Ejecutar:
 *   npm run db:schema:extract
 *
 * Variables de entorno (web/api/.env):
 *   PG_HOST, PG_PORT, PG_DATABASE, PG_USER, PG_PASSWORD
 *   o PG_CONNECTION_STRING
 *
 * Salida:
 *   sqlweb-pg/extracted/
 *     00_schemas.sql          → CREATE SCHEMA IF NOT EXISTS ...
 *     01_tables/<schema>_<table>.sql → CREATE TABLE IF NOT EXISTS ...
 *     02_functions/<schema>_<func>.sql → CREATE OR REPLACE FUNCTION ...
 *     03_indexes.sql          → CREATE INDEX IF NOT EXISTS ...
 *     04_triggers.sql         → CREATE TRIGGER ...
 *     05_grants.sql           → GRANT EXECUTE ON ALL FUNCTIONS ...
 *     extracted_at.txt        → timestamp de la extracción
 */

import pg from 'pg';
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, '../../../../sqlweb-pg/extracted');

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

function createPool(): pg.Pool {
  if (process.env.PG_CONNECTION_STRING) {
    return new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING });
  }
  return new pg.Pool({
    host:     process.env.PG_HOST     ?? '127.0.0.1',
    port:     Number(process.env.PG_PORT ?? 5433), // 5433 = tunnel SSH por defecto
    database: process.env.PG_DATABASE ?? 'zentto_prod',
    user:     process.env.PG_USER     ?? 'zentto_app',
    password: process.env.PG_PASSWORD ?? '',
    ssl:      false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Schemas
// ────────────────────────────────────────────────────────────────────────────

async function extractSchemas(client: pg.PoolClient): Promise<string> {
  const res = await client.query<{ nspname: string }>(
    `SELECT nspname FROM pg_namespace
     WHERE nspname NOT IN ('pg_catalog','information_schema','pg_toast','pg_temp_1','pg_toast_temp_1')
       AND nspname NOT LIKE 'pg_%'
     ORDER BY nspname`
  );
  const lines = [
    `-- ============================================================`,
    `-- 00_schemas.sql — Schemas de la aplicación`,
    `-- Generado por: npm run db:schema:extract`,
    `-- ============================================================`,
    ``,
  ];
  for (const row of res.rows) {
    lines.push(`CREATE SCHEMA IF NOT EXISTS ${row.nspname};`);
  }
  lines.push('');
  return lines.join('\n');
}

// ────────────────────────────────────────────────────────────────────────────
// Tables
// ────────────────────────────────────────────────────────────────────────────

async function extractTables(client: pg.PoolClient): Promise<Map<string, string>> {
  // Obtener todas las tablas de usuario
  const tablesRes = await client.query<{ table_schema: string; table_name: string }>(
    `SELECT table_schema, table_name
     FROM information_schema.tables
     WHERE table_type = 'BASE TABLE'
       AND table_schema NOT IN ('pg_catalog','information_schema')
     ORDER BY table_schema, table_name`
  );

  const result = new Map<string, string>();

  for (const table of tablesRes.rows) {
    const schema = table.table_schema;
    const tableName = table.table_name;
    const key = `${schema}_${tableName}`;

    // Obtener columnas
    const colsRes = await client.query<{
      column_name: string;
      data_type: string;
      character_maximum_length: number | null;
      numeric_precision: number | null;
      numeric_scale: number | null;
      is_nullable: string;
      column_default: string | null;
      is_identity: string;
      identity_generation: string | null;
    }>(
      `SELECT
         c.column_name,
         c.data_type,
         c.character_maximum_length,
         c.numeric_precision,
         c.numeric_scale,
         c.is_nullable,
         c.column_default,
         c.is_identity,
         c.identity_generation
       FROM information_schema.columns c
       WHERE c.table_schema = $1 AND c.table_name = $2
       ORDER BY c.ordinal_position`,
      [schema, tableName]
    );

    // Obtener primary key
    const pkRes = await client.query<{ column_name: string }>(
      `SELECT kcu.column_name
       FROM information_schema.table_constraints tc
       JOIN information_schema.key_column_usage kcu
         ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
       WHERE tc.constraint_type = 'PRIMARY KEY'
         AND tc.table_schema = $1 AND tc.table_name = $2
       ORDER BY kcu.ordinal_position`,
      [schema, tableName]
    );

    const colLines: string[] = [];
    for (const col of colsRes.rows) {
      let typeDef = col.data_type.toUpperCase();
      if (col.character_maximum_length) {
        typeDef += `(${col.character_maximum_length})`;
      } else if (col.numeric_precision && col.numeric_scale !== null) {
        typeDef += `(${col.numeric_precision},${col.numeric_scale})`;
      }

      if (col.is_identity === 'YES') {
        const gen = col.identity_generation === 'ALWAYS' ? 'ALWAYS' : 'BY DEFAULT';
        typeDef = `INT GENERATED ${gen} AS IDENTITY`;
      }

      const nullable = col.is_nullable === 'NO' ? ' NOT NULL' : ' NULL';
      let defaultClause = '';
      if (col.column_default && col.is_identity !== 'YES') {
        defaultClause = ` DEFAULT ${col.column_default}`;
      }

      colLines.push(`  "${col.column_name}" ${typeDef}${nullable}${defaultClause}`);
    }

    const pkCols = pkRes.rows.map(r => `"${r.column_name}"`);
    if (pkCols.length > 0) {
      colLines.push(`  PRIMARY KEY (${pkCols.join(', ')})`);
    }

    const lines = [
      `-- ============================================================`,
      `-- ${schema}."${tableName}"`,
      `-- ============================================================`,
      ``,
      `CREATE TABLE IF NOT EXISTS ${schema}."${tableName}" (`,
      colLines.join(',\n'),
      `);`,
      ``,
    ];

    result.set(key, lines.join('\n'));
  }

  return result;
}

// ────────────────────────────────────────────────────────────────────────────
// Functions / Stored Procedures
// ────────────────────────────────────────────────────────────────────────────

async function extractFunctions(client: pg.PoolClient): Promise<Map<string, string>> {
  const res = await client.query<{
    nspname: string;
    proname: string;
    prosrc: string;
    prolang_name: string;
    proretset: boolean;
    prorettype_name: string;
    proargnames: string[] | null;
    proargtypes_names: string[];
    full_def: string;
  }>(
    `SELECT
       n.nspname,
       p.proname,
       p.prosrc,
       l.lanname AS prolang_name,
       p.proretset,
       rt.typname AS prorettype_name,
       p.proargnames,
       array(
         SELECT pg_catalog.format_type(unnest(p.proargtypes), NULL)
       ) AS proargtypes_names,
       pg_get_functiondef(p.oid) AS full_def
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     JOIN pg_language l ON l.oid = p.prolang
     JOIN pg_type rt ON rt.oid = p.prorettype
     WHERE n.nspname NOT IN ('pg_catalog','information_schema')
       AND l.lanname IN ('plpgsql','sql','c')
     ORDER BY n.nspname, p.proname`
  );

  const result = new Map<string, string>();

  for (const row of res.rows) {
    const key = `${row.nspname}_${row.proname}`;
    const existing = result.get(key);

    const lines = [
      `-- ${row.nspname}.${row.proname}`,
      ``,
      `DROP FUNCTION IF EXISTS ${row.proname}(${row.proargtypes_names.join(', ')}) CASCADE;`,
      ``,
      row.full_def + ';',
      ``,
    ].join('\n');

    if (existing) {
      // Función con múltiples overloads — append
      result.set(key, existing + '\n' + lines);
    } else {
      const header = [
        `-- ============================================================`,
        `-- ${row.nspname}.${row.proname}`,
        `-- ============================================================`,
        ``,
      ].join('\n');
      result.set(key, header + lines);
    }
  }

  return result;
}

// ────────────────────────────────────────────────────────────────────────────
// Indexes
// ────────────────────────────────────────────────────────────────────────────

async function extractIndexes(client: pg.PoolClient): Promise<string> {
  const res = await client.query<{ indexdef: string; schemaname: string; tablename: string; indexname: string }>(
    `SELECT schemaname, tablename, indexname, indexdef
     FROM pg_indexes
     WHERE schemaname NOT IN ('pg_catalog','information_schema')
       AND indexname NOT LIKE '%_pkey'  -- PKs ya incluidas en CREATE TABLE
     ORDER BY schemaname, tablename, indexname`
  );

  const lines = [
    `-- ============================================================`,
    `-- 03_indexes.sql — Índices`,
    `-- ============================================================`,
    ``,
  ];

  for (const row of res.rows) {
    // Convertir a IF NOT EXISTS
    const def = row.indexdef.replace(/^CREATE /, 'CREATE ').replace(
      /^CREATE (UNIQUE )?INDEX /,
      'CREATE $1INDEX IF NOT EXISTS '
    );
    lines.push(def + ';');
  }
  lines.push('');
  return lines.join('\n');
}

// ────────────────────────────────────────────────────────────────────────────
// Escribir archivos
// ────────────────────────────────────────────────────────────────────────────

function writeFile(path: string, content: string): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content, 'utf-8');
}

// ────────────────────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('');
  console.log('══════════════════════════════════════════════════════');
  console.log('  Zentto — Extracción de Esquema PostgreSQL');
  console.log('══════════════════════════════════════════════════════');
  console.log('');

  const pool = createPool();
  const client = await pool.connect();

  const host = process.env.PG_HOST ?? '127.0.0.1';
  const db   = process.env.PG_DATABASE ?? 'zentto_prod';
  console.log(`[INFO] Conectando a ${host}:${process.env.PG_PORT ?? 5433}/${db}...`);

  try {
    // Test connection
    await client.query('SELECT 1');
    console.log('[OK]   Conexión establecida.');
    console.log(`[INFO] Salida: ${OUTPUT_DIR}`);
    console.log('');

    // ── Schemas ──
    process.stdout.write('[RUN]  Extrayendo schemas ... ');
    const schemasSQL = await extractSchemas(client);
    writeFile(join(OUTPUT_DIR, '00_schemas.sql'), schemasSQL);
    console.log('✓');

    // ── Tables ──
    process.stdout.write('[RUN]  Extrayendo tablas ... ');
    const tables = await extractTables(client);
    const tablesDir = join(OUTPUT_DIR, '01_tables');
    for (const [key, sql] of tables) {
      writeFile(join(tablesDir, `${key}.sql`), sql);
    }
    console.log(`✓ (${tables.size} tablas)`);

    // ── Functions ──
    process.stdout.write('[RUN]  Extrayendo funciones ... ');
    const functions = await extractFunctions(client);
    const functionsDir = join(OUTPUT_DIR, '02_functions');
    for (const [key, sql] of functions) {
      writeFile(join(functionsDir, `${key}.sql`), sql);
    }
    console.log(`✓ (${functions.size} funciones)`);

    // ── Indexes ──
    process.stdout.write('[RUN]  Extrayendo índices ... ');
    const indexesSQL = await extractIndexes(client);
    writeFile(join(OUTPUT_DIR, '03_indexes.sql'), indexesSQL);
    console.log('✓');

    // ── Timestamp ──
    writeFile(
      join(OUTPUT_DIR, 'extracted_at.txt'),
      `Extraído: ${new Date().toISOString()}\nDB: ${db}@${host}\n`
    );

    console.log('');
    console.log('══════════════════════════════════════════════════════');
    console.log('[DONE] Esquema extraído en:', OUTPUT_DIR);
    console.log('');
    console.log('Próximos pasos:');
    console.log('  1. Revisar sqlweb-pg/extracted/');
    console.log('  2. Los archivos 01_tables/ y 02_functions/ son la fuente de verdad');
    console.log('  3. Cualquier cambio nuevo va en migrations/postgres/NNNN_descripcion.sql');
    console.log('  4. git add + commit');
    console.log('══════════════════════════════════════════════════════');
    console.log('');

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[FATAL]', (err as Error).message);
  process.exit(1);
});
