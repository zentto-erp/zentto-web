#!/usr/bin/env node
/**
 * execute_sps.cjs — Ejecuta SPs del sqlweb/ adaptados para zentto_dev
 * - Cambia USE DatqBoxWeb → USE zentto_dev
 * - Cambia CREATE OR ALTER → IF EXISTS DROP + CREATE (SQL 2012)
 */
const sql = require('mssql');
const fs = require('fs');
const path = require('path');

const config = {
  server: 'DELLXEONE31545',
  database: 'zentto_dev',
  user: 'sa',
  password: '1234',
  options: { encrypt: false, trustServerCertificate: true },
  connectionTimeout: 10000,
  requestTimeout: 120000,
};

const SP_DIR = path.resolve(__dirname, '..', 'sqlweb', 'includes', 'sp');

// Read all .sql files, usp_* first, then sp_*, skip seeds
const allFiles = fs.readdirSync(SP_DIR).filter(f => f.endsWith('.sql') && !f.startsWith('seed_'));
const uspFiles = allFiles.filter(f => f.startsWith('usp_')).sort();
const spFiles = allFiles.filter(f => f.startsWith('sp_')).sort();
const otherFiles = allFiles.filter(f => !f.startsWith('usp_') && !f.startsWith('sp_')).sort();
const SP_FILES = [...uspFiles, ...spFiles, ...otherFiles];

function adaptSqlFor2012(content) {
  let s = content;
  s = s.replace(/USE\s+DatqBoxWeb\s*;/gi, 'USE zentto_dev;');
  s = s.replace(
    /CREATE\s+OR\s+ALTER\s+PROCEDURE\s+([\w.[\]]+)/gi,
    (_, name) => {
      const clean = name.replace(/\[|\]/g, '');
      return `IF OBJECT_ID('${clean}', 'P') IS NOT NULL DROP PROCEDURE ${name};\nGO\nCREATE PROCEDURE ${name}`;
    }
  );
  s = s.replace(
    /CREATE\s+OR\s+ALTER\s+FUNCTION\s+([\w.[\]]+)/gi,
    (_, name) => {
      const clean = name.replace(/\[|\]/g, '');
      return `IF OBJECT_ID('${clean}', 'FN') IS NOT NULL DROP FUNCTION ${name};\nIF OBJECT_ID('${clean}', 'IF') IS NOT NULL DROP FUNCTION ${name};\nIF OBJECT_ID('${clean}', 'TF') IS NOT NULL DROP FUNCTION ${name};\nGO\nCREATE FUNCTION ${name}`;
    }
  );
  return s;
}

async function run() {
  console.log('=== Ejecutando SPs en zentto_dev ===\n');
  const pool = await sql.connect(config);
  let totalOk = 0, totalFail = 0;
  const allErrors = [];

  for (const file of SP_FILES) {
    const filePath = path.join(SP_DIR, file);
    if (!fs.existsSync(filePath)) continue;

    const adapted = adaptSqlFor2012(fs.readFileSync(filePath, 'utf8'));
    const batches = adapted.split(/^GO\s*$/m).filter(b => b.trim());
    let ok = 0, fail = 0;

    for (const batch of batches) {
      const content = batch.replace(/^--[^\n]*\n?/gm, '').trim();
      if (!content || content.startsWith('USE ')) continue;
      if (content.match(/EXEC\('CREATE SCHEMA/)) continue;
      try { await pool.request().query(batch.trim()); ok++; }
      catch (e) {
        fail++;
        const spM = batch.match(/CREATE\s+PROCEDURE\s+([\w.\[\]]+)/i);
        allErrors.push({ file, sp: spM ? spM[1] : file, msg: e.message.substring(0, 150) });
      }
    }

    const status = fail > 0 ? `OK=${ok} FAIL=${fail}` : `OK=${ok}`;
    console.log(`  ${file}: ${status}`);
    totalOk += ok; totalFail += fail;
  }

  console.log(`\nTotal: OK=${totalOk}, FAIL=${totalFail}`);
  if (allErrors.length > 0) {
    console.log(`\nErrores (${allErrors.length}):`);
    const seen = new Set();
    for (const e of allErrors) {
      const key = e.msg.substring(0, 80);
      if (!seen.has(key)) { seen.add(key); console.log(`  ${e.file} → ${e.sp}: ${e.msg}`); }
    }
    if (allErrors.length > seen.size) console.log(`  ... y ${allErrors.length - seen.size} errores similares`);
  }

  const r = await pool.request().query("SELECT COUNT(*) AS cnt FROM sys.procedures WHERE SCHEMA_NAME(schema_id) NOT IN ('sys')");
  console.log(`\nStored Procedures creados: ${r.recordset[0].cnt}`);
  await pool.close();
}

run().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
