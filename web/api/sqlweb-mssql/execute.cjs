#!/usr/bin/env node
/**
 * execute.cjs — Bootstrap zentto_dev en SQL Server 2012
 * Drop/recreate BD, crear schemas, ejecutar DDL y seeds.
 *
 * Uso: node execute.cjs
 */
const sql = require('mssql');
const fs = require('fs');
const path = require('path');

const config = {
  server: 'DELLXEONE31545',
  user: 'sa',
  password: '1234',
  options: { encrypt: false, trustServerCertificate: true },
  connectionTimeout: 10000,
  requestTimeout: 120000,
};

const DB_NAME = 'zentto_dev';
const SCHEMAS = [
  'sec','cfg','mstr','acct','ar','ap','pos','rest','fiscal','doc','fin',
  'hr','pay','audit','store','inv','logistics','crm','mfg','fleet','zsys'
];

function executeBatches(pool, sqlText) {
  const batches = sqlText.split(/^GO\s*$/m).filter(b => b.trim());
  let ok = 0, fail = 0;
  const errors = [];
  return (async () => {
    for (const batch of batches) {
      const content = batch.replace(/^--[^\n]*\n?/gm, '').trim();
      if (!content || batch.trim().startsWith('USE ')) { ok++; continue; }
      if (content.match(/^(IF NOT EXISTS.*)?EXEC\('CREATE SCHEMA/)) { ok++; continue; }
      try {
        await pool.request().query(batch.trim());
        ok++;
      } catch (e) {
        fail++;
        const m = batch.match(/OBJECT_ID\('([^']+)'/);
        const ctx = m ? m[1] : content.substring(0, 60).replace(/\n/g, ' ');
        errors.push({ ctx, msg: e.message.substring(0, 200) });
      }
    }
    return { ok, fail, errors, total: batches.length };
  })();
}

async function run() {
  console.log('=== Zentto SQL Server Bootstrap ===\n');

  // Phase 1: Drop/Create database
  console.log('1. Recreando base de datos...');
  const masterPool = await sql.connect({ ...config, database: 'master' });
  await masterPool.request().query(`IF DB_ID('${DB_NAME}') IS NOT NULL ALTER DATABASE ${DB_NAME} SET SINGLE_USER WITH ROLLBACK IMMEDIATE`);
  await masterPool.request().query(`IF DB_ID('${DB_NAME}') IS NOT NULL DROP DATABASE ${DB_NAME}`);
  await masterPool.request().query(`CREATE DATABASE ${DB_NAME}`);
  await masterPool.request().query(`ALTER DATABASE ${DB_NAME} SET COMPATIBILITY_LEVEL = 110`);
  console.log(`   OK: ${DB_NAME} (compat 110)`);
  await masterPool.close();

  // Phase 2: Create schemas
  console.log('\n2. Creando schemas...');
  const pool = await sql.connect({ ...config, database: DB_NAME });
  for (const s of SCHEMAS) {
    try { await pool.request().query(`CREATE SCHEMA [${s}]`); }
    catch (e) { if (!e.message.includes('already exists')) console.log(`   WARN ${s}: ${e.message.substring(0, 60)}`); }
  }
  const schR = await pool.request().query("SELECT name FROM sys.schemas WHERE name NOT LIKE 'db_%' AND name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys') ORDER BY name");
  console.log('   OK: ' + schR.recordset.map(x => x.name).join(', '));

  // Phase 3: Execute DDL
  console.log('\n3. Ejecutando DDL (tablas + índices)...');
  const ddlFile = path.resolve(__dirname, '01_ddl_tables.sql');
  if (!fs.existsSync(ddlFile)) { console.log('   ERROR: 01_ddl_tables.sql no existe. Ejecutar pg2mssql.cjs primero.'); process.exit(1); }
  const ddlResult = await executeBatches(pool, fs.readFileSync(ddlFile, 'utf8'));
  console.log(`   Batches: ${ddlResult.total}, OK: ${ddlResult.ok}, FAIL: ${ddlResult.fail}`);
  if (ddlResult.errors.length > 0) {
    console.log(`\n   Errores (${ddlResult.errors.length}):`);
    ddlResult.errors.forEach(e => console.log(`     ${e.ctx}: ${e.msg}`));
  }

  // Phase 4: Patches (ejecuta todos los 0?_patch_*.sql en orden numerico)
  console.log('\n4. Patches...');
  const patches = fs.readdirSync(__dirname)
    .filter(f => /^0\d_patch_.+\.sql$/i.test(f))
    .sort();
  for (const pf of patches) {
    const full = path.resolve(__dirname, pf);
    const pR = await executeBatches(pool, fs.readFileSync(full, 'utf8'));
    console.log(`   ${pf} -> OK: ${pR.ok}, FAIL: ${pR.fail}`);
    if (pR.errors.length > 0) {
      pR.errors.forEach(e => console.log(`     ${e.ctx}: ${e.msg}`));
    }
  }
  if (patches.length === 0) console.log('   (sin patches)');

  // Phase 5: Seeds
  console.log('\n5. Ejecutando seeds...');
  const seedFile = path.resolve(__dirname, '02_seed_core.sql');
  if (fs.existsSync(seedFile)) {
    const sR = await executeBatches(pool, fs.readFileSync(seedFile, 'utf8'));
    console.log(`   OK: ${sR.ok}, FAIL: ${sR.fail}`);
  }

  // Phase 6: Verify
  console.log('\n6. Verificación...');
  const tR = await pool.request().query("SELECT TABLE_SCHEMA, COUNT(*) AS cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' GROUP BY TABLE_SCHEMA ORDER BY TABLE_SCHEMA");
  let total = 0;
  for (const r of tR.recordset) { console.log(`   ${r.TABLE_SCHEMA}: ${r.cnt}`); total += r.cnt; }
  console.log(`   TOTAL: ${total} tablas`);
  const uR = await pool.request().query("SELECT COUNT(*) AS c FROM sec.[User]");
  const cR = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Company");
  const ctR = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Country");
  const bR = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Branch");
  console.log(`   Users: ${uR.recordset[0].c}, Companies: ${cR.recordset[0].c}, Countries: ${ctR.recordset[0].c}, Branches: ${bR.recordset[0].c}`);

  await pool.close();
  console.log('\n=== Completado ===');
  process.exit(ddlResult.fail > 0 ? 1 : 0);
}

run().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
