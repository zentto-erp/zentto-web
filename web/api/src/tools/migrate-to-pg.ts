/**
 * migrate-to-pg.ts
 * Lee SQL Server → genera seed_live_data.sql para PostgreSQL
 * El archivo generado se guarda en sqlweb-pg/includes/sp/ y se usa en
 * run_all.sql para que cada deploy demo tenga datos reales.
 *
 * Uso: npm run db:migrate:pg
 */

import sql from 'mssql';
import pg from 'pg';
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Configuración SQL Server
// ---------------------------------------------------------------------------

const SS_CONFIG: sql.config = {
  server: 'DELLXEONE31545',
  database: 'DatqBoxWeb',
  user: 'sa',
  password: '1234',
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

// Configuración PostgreSQL (para leer esquema de columnas disponibles)
// Conectar via tunnel SSH: ssh -L 5433:127.0.0.1:5432 root@178.104.56.185
const PG_CONFIG: pg.PoolConfig = {
  host: '127.0.0.1',
  port: 5433,
  user: 'zentto_app',
  password: 'WWjV_KTfG9GaFzSSzxh9uja2-q_NbMeM',
  database: 'zentto_prod',
  ssl: false,
};

// Archivo de salida
const OUTPUT_DIR = join(__dirname, '../../../../web/api/sqlweb-pg/includes/sp');
const OUTPUT_FILE = join(OUTPUT_DIR, 'seed_live_data.sql');

// ---------------------------------------------------------------------------
// Tablas a exportar (orden FK)
// ---------------------------------------------------------------------------

const TABLES: string[] = [
  'cfg.Company',
  'cfg.AppSetting',
  'cfg.Branch',
  'cfg.Warehouse',
  'sec.User',
  'sec.Role',
  'sec.UserRole',
  'sec.UserModuleAccess',
  'master.Category',
  'master.Brand',
  'master.Unit',
  'master.ProductType',
  'master.Customer',
  'master.CustomerAddress',
  'master.CustomerPaymentMethod',
  'master.Supplier',
  'master.Employee',
  'master.Product',
  'master.ProductPrice',
  'master.ProductStock',
  'ar.SalesDocument',
  'ar.SalesDocumentLine',
  'ap.PurchaseDocument',
  'ap.PurchaseDocumentLine',
  'acct.Account',
  'acct.JournalEntry',
  'acct.JournalEntryLine',
];

// Columnas que no se exportan (manejadas por triggers/PG)
const EXCLUDED_COLUMNS = new Set(['RowVer']);

// ---------------------------------------------------------------------------
// Escape de valores para SQL literal
// ---------------------------------------------------------------------------

function escapeValue(value: unknown, colType: sql.ISqlType): string {
  if (value === null || value === undefined) return 'NULL';

  // Buffer → omitir (rowversion), no debería llegar aquí
  if (Buffer.isBuffer(value)) return 'NULL';

  // Booleanos (bit)
  if (colType.type === sql.Bit || (colType as any).declaration === 'bit') {
    return value === true || value === 1 ? 'TRUE' : 'FALSE';
  }

  // Fechas
  if (value instanceof Date) {
    return `'${value.toISOString()}'::timestamp`;
  }

  // Números
  if (typeof value === 'number' || typeof value === 'bigint') {
    return String(value);
  }

  // Strings — escapar comillas simples
  if (typeof value === 'string') {
    const escaped = value.replace(/\\/g, '\\\\').replace(/'/g, "''");
    return `'${escaped}'`;
  }

  // Boolean nativo
  if (typeof value === 'boolean') {
    return value ? 'TRUE' : 'FALSE';
  }

  // Fallback
  return `'${String(value).replace(/'/g, "''")}'`;
}

// ---------------------------------------------------------------------------
// Obtener columnas disponibles en PostgreSQL para una tabla
// ---------------------------------------------------------------------------

async function getPgColumns(pgPool: pg.Pool, schema: string, table: string): Promise<Set<string>> {
  const res = await pgPool.query<{ column_name: string }>(
    `SELECT column_name FROM information_schema.columns
     WHERE table_schema = $1 AND table_name = $2`,
    [schema, table]
  );
  return new Set(res.rows.map(r => r.column_name));
}

// ---------------------------------------------------------------------------
// Genera el bloque SQL para una tabla
// ---------------------------------------------------------------------------

function generateTableSql(
  schema: string,
  table: string,
  rows: sql.IRecordSet<Record<string, unknown>>,
  pgColumns: Set<string>
): string {
  if (rows.length === 0) return `-- ${schema}.${table}: sin datos\n`;

  const columnMeta = rows.columns;
  const lines: string[] = [];

  lines.push(`-- ============================================================`);
  lines.push(`-- ${schema}.${table} (${rows.length} filas)`);
  lines.push(`-- ============================================================`);
  lines.push(`ALTER TABLE ${schema}."${table}" DISABLE TRIGGER ALL;`);
  lines.push('');

  for (const row of rows) {
    const colNames: string[] = [];
    const colValues: string[] = [];
    let hasIdentity = false;

    for (const [colName, colMeta] of Object.entries(columnMeta)) {
      if (EXCLUDED_COLUMNS.has(colName)) continue;
      // Solo incluir columnas que existen en PostgreSQL
      if (!pgColumns.has(colName)) continue;

      const rawValue = row[colName];
      if (Buffer.isBuffer(rawValue)) continue;

      if ((colMeta as any).identity) hasIdentity = true;

      colNames.push(`"${colName}"`);
      colValues.push(escapeValue(rawValue, colMeta));
    }

    if (colNames.length === 0) continue;

    const overriding = hasIdentity ? ' OVERRIDING SYSTEM VALUE' : '';
    lines.push(
      `INSERT INTO ${schema}."${table}" (${colNames.join(', ')})` +
      `${overriding} VALUES (${colValues.join(', ')}) ON CONFLICT DO NOTHING;`
    );
  }

  lines.push('');
  lines.push(`ALTER TABLE ${schema}."${table}" ENABLE TRIGGER ALL;`);

  // Resetear secuencias para columnas GENERATED/IDENTITY
  const identityCols = Object.entries(columnMeta)
    .filter(([name, meta]) => (meta as any).identity && pgColumns.has(name))
    .map(([name]) => name);

  for (const idCol of identityCols) {
    lines.push(
      `SELECT setval(` +
      `pg_get_serial_sequence('${schema}."${table}"', '${idCol}'), ` +
      `COALESCE((SELECT MAX("${idCol}") FROM ${schema}."${table}"), 1), true` +
      `) WHERE pg_get_serial_sequence('${schema}."${table}"', '${idCol}') IS NOT NULL;`
    );
  }

  lines.push('');
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('='.repeat(60));
  console.log('  Exportando SQL Server → seed_live_data.sql');
  console.log('='.repeat(60));

  // Conectar SQL Server
  console.log('[INFO] Conectando a SQL Server...');
  let ssPool: sql.ConnectionPool;
  try {
    ssPool = await sql.connect(SS_CONFIG);
    console.log('[OK]   SQL Server conectado.');
  } catch (err) {
    console.error('[ERROR] No se pudo conectar:', (err as Error).message);
    process.exit(1);
  }

  const header: string[] = [
    `-- ============================================================`,
    `-- seed_live_data.sql`,
    `-- Generado automáticamente desde SQL Server DatqBoxWeb`,
    `-- Fecha: ${new Date().toISOString()}`,
    `-- NO editar manualmente — regenerar con: npm run db:migrate:pg`,
    `-- ============================================================`,
    ``,
    `SET search_path TO public;`,
    ``,
  ];

  // Conectar PostgreSQL para obtener esquema de columnas
  console.log('[INFO] Conectando a PostgreSQL (lectura de esquema)...');
  const pgPool = new pg.Pool(PG_CONFIG);
  try {
    const c = await pgPool.connect(); c.release();
    console.log('[OK]   PostgreSQL conectado.');
  } catch (err) {
    console.error('[ERROR] No se pudo conectar a PG:', (err as Error).message);
    await ssPool.close();
    process.exit(1);
  }

  const blocks: string[] = [];
  let totalRows = 0;
  const summary: string[] = [];

  for (const fullTable of TABLES) {
    const [schema, table] = fullTable.split('.');
    console.log(`[INFO] Leyendo ${fullTable}...`);

    try {
      const [ssResult, pgColumns] = await Promise.all([
        ssPool.request().query<Record<string, unknown>>(`SELECT * FROM [${schema}].[${table}]`),
        getPgColumns(pgPool, schema, table),
      ]);

      const count = ssResult.recordset.length;
      const pgColCount = pgColumns.size;
      console.log(`[OK]   ${fullTable}: ${count} filas SS | ${pgColCount} cols PG`);
      totalRows += count;
      summary.push(`--   ${fullTable.padEnd(40)} ${count} filas`);
      blocks.push(generateTableSql(schema, table, ssResult.recordset, pgColumns));
    } catch (err) {
      const msg = (err as Error).message;
      console.warn(`[WARN] ${fullTable} omitida: ${msg}`);
      summary.push(`--   ${fullTable.padEnd(40)} OMITIDA`);
      blocks.push(`-- OMITIDA: ${fullTable} (${msg})\n`);
    }
  }

  await ssPool.close();
  await pgPool.end();

  // Ensamblar archivo final
  const summaryBlock = [
    `-- Resumen de exportación:`,
    ...summary,
    `-- Total filas: ${totalRows}`,
    ``,
  ];

  const content = [
    ...header,
    ...summaryBlock,
    ...blocks,
    `-- FIN seed_live_data.sql`,
    ``,
  ].join('\n');

  // Escribir archivo
  mkdirSync(OUTPUT_DIR, { recursive: true });
  writeFileSync(OUTPUT_FILE, content, 'utf-8');

  console.log('');
  console.log('='.repeat(60));
  console.log(`[OK]   Archivo generado: ${OUTPUT_FILE}`);
  console.log(`[OK]   Total filas exportadas: ${totalRows}`);
  console.log('='.repeat(60));
  console.log('');
  console.log('Próximos pasos:');
  console.log('  1. Revisar el archivo generado');
  console.log('  2. git add + commit');
  console.log('  3. El deploy aplicará el seed automáticamente via run_all.sql');
}

main().catch((err) => {
  console.error('[ERROR] Fatal:', (err as Error).message);
  process.exit(1);
});
