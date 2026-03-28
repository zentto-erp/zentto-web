#!/usr/bin/env node
/**
 * pg2mssql.cjs — Traduce DDL PostgreSQL → T-SQL compatible con SQL Server 2012
 * Lee el baseline de PG y genera el DDL equivalente para SQL Server.
 *
 * Uso: node pg2mssql.cjs
 * Output: 01_ddl_tables.sql
 */
const fs = require('fs');
const path = require('path');

const BASELINE = path.resolve(__dirname, '..', 'migrations', 'postgres', '00001_baseline.sql');
const raw = fs.readFileSync(BASELINE, 'utf8');
const lines = raw.split('\n');

let output = [];
output.push('-- ============================================================');
output.push('-- zentto_dev — DDL canónico para SQL Server 2012');
output.push('-- Generado automáticamente desde 00001_baseline.sql (PG)');
output.push('-- Compatible con SQL Server 2012 (compat level 110)');
output.push('-- Schemas renombrados: master→mstr, sys→zsys');
output.push('-- ============================================================');
output.push('USE zentto_dev;');
output.push('GO');
output.push('');

// ── Collect schemas ─────────────────────────────────────────
const schemas = new Set();
for (const line of lines) {
  const m = line.match(/CREATE SCHEMA IF NOT EXISTS (\w+)/);
  if (m) schemas.add(m[1]);
}
['inv', 'logistics', 'crm', 'mfg', 'fleet'].forEach(s => schemas.add(s));
// Reserved in SQL Server
schemas.delete('sys');  schemas.add('zsys');
schemas.delete('master'); schemas.add('mstr');

output.push('-- SCHEMAS');
for (const s of schemas) {
  output.push(`IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = '${s}')`);
  output.push(`  EXEC('CREATE SCHEMA [${s}]');`);
  output.push('GO');
}
output.push('');

// ── Reserved words that need brackets ───────────────────────
const RESERVED = new Set([
  'User','Order','Index','Key','Value','Name','Level','Type','Status',
  'Action','Condition','Role','Check','Table','Column','View','Function',
  'Procedure','Schema','Plan','Identity','Authorization','Grant','References',
]);

function bracket(name) {
  return RESERVED.has(name) ? `[${name}]` : name;
}

function fixSchema(s) {
  if (s === 'sys') return 'zsys';
  if (s === 'master') return 'mstr';
  return s;
}

// ── Translate CREATE TABLE block ────────────────────────────
function translateTableBlock(block) {
  let sql = block.join('\n');

  const tableMatch = sql.match(/CREATE TABLE IF NOT EXISTS\s+(\w+)\."(\w+)"/);
  if (!tableMatch) return null;

  let schema = fixSchema(tableMatch[1]);
  const table = tableMatch[2];
  const tblRef = bracket(table);
  const fullName = `${schema}.${tblRef}`;

  sql = sql.replace(/CREATE TABLE IF NOT EXISTS\s+\w+\."\w+"/, `CREATE TABLE ${fullName}`);

  // Schema renames in body (FKs etc)
  sql = sql.replace(/\bsys\./g, 'zsys.');
  sql = sql.replace(/\bmaster\./g, 'mstr.');

  // Types
  sql = sql.replace(/\bINT\s+GENERATED\s+ALWAYS\s+AS\s+IDENTITY\b/gi, 'INT IDENTITY(1,1)');
  sql = sql.replace(/\bBIGINT\s+GENERATED\s+ALWAYS\s+AS\s+IDENTITY\b/gi, 'BIGINT IDENTITY(1,1)');
  sql = sql.replace(/\bSERIAL\b/g, 'INT IDENTITY(1,1)');
  sql = sql.replace(/\bBOOLEAN\b/g, 'BIT');
  sql = sql.replace(/DEFAULT TRUE/g, 'DEFAULT 1');
  sql = sql.replace(/DEFAULT FALSE/g, 'DEFAULT 0');
  sql = sql.replace(/= TRUE/g, '= 1');
  sql = sql.replace(/= FALSE/g, '= 0');
  sql = sql.replace(/\bTIMESTAMPTZ\b/g, 'DATETIME2(0)');
  sql = sql.replace(/\bTIMESTAMP\b(?!\s*WITH)/g, 'DATETIME2(0)');
  sql = sql.replace(/\bTEXT\b/g, 'NVARCHAR(MAX)');
  sql = sql.replace(/\bVARCHAR\((\d+)\)/g, 'NVARCHAR($1)');
  sql = sql.replace(/\bVARCHAR\b(?!\()/g, 'NVARCHAR(MAX)');
  sql = sql.replace(/\bCHAR\((\d+)\)/g, 'NCHAR($1)');
  sql = sql.replace(/\bNUMERIC\((\d+),(\d+)\)/g, 'DECIMAL($1,$2)');
  sql = sql.replace(/\bNUMERIC\((\d+)\)/g, 'DECIMAL($1)');
  sql = sql.replace(/\bJSONB\b/g, 'NVARCHAR(MAX)');
  sql = sql.replace(/\bJSON\b/g, 'NVARCHAR(MAX)');
  sql = sql.replace(/\bBYTEA\b/g, 'VARBINARY(MAX)');
  sql = sql.replace(/\bTSVECTOR\b/g, 'NVARCHAR(MAX)');

  // PG casts
  sql = sql.replace(/::\s*\w+(\(\d+\))?/g, '');

  // PG functions
  sql = sql.replace(/TO_CHAR\s*\([^,]+,\s*'HH24:MI:SS'\)/g, "CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108)");
  sql = sql.replace(/\bTO_CHAR\s*\(([^,]+),\s*'([^']+)'\)/g, "CONVERT(NVARCHAR(30), $1, 120)");
  sql = sql.replace(/\(NOW\(\) AT TIME ZONE 'UTC'\)/g, 'SYSUTCDATETIME()');
  sql = sql.replace(/NOW\(\) AT TIME ZONE 'UTC'/g, 'SYSUTCDATETIME()');
  sql = sql.replace(/NOW\(\)/g, 'SYSUTCDATETIME()');

  // Identifiers: remove double quotes, bracket reserved
  sql = sql.replace(/"(\w+)"/g, (_, name) => bracket(name));

  // Fix FK references
  sql = sql.replace(/REFERENCES\s+(\w+)\.(\w+)/g, (_, s, t) => {
    return `REFERENCES ${fixSchema(s)}.${bracket(t)}`;
  });

  const result = [];
  result.push(`IF OBJECT_ID('${schema}.${table}', 'U') IS NULL`);
  result.push(sql + ';');
  result.push('GO');
  result.push('');
  return result.join('\n');
}

// ── Translate index ─────────────────────────────────────────
function translateIndex(line) {
  let sql = line;
  const m = sql.match(/CREATE (UNIQUE )?INDEX IF NOT EXISTS\s+"(\w+)"\s+ON\s+(\w+)\."(\w+)"/);
  if (!m) return null;

  const unique = m[1] ? 'UNIQUE ' : '';
  const idxName = m[2];
  let schema = fixSchema(m[3]);

  sql = sql.replace(/CREATE (UNIQUE )?INDEX IF NOT EXISTS\s+"(\w+)"/, `CREATE ${unique}INDEX $2`);
  sql = sql.replace(/ON\s+(\w+)\."(\w+)"/, (_, s, t) => `ON ${fixSchema(s)}.${bracket(t)}`);
  sql = sql.replace(/"(\w+)"/g, (_, name) => bracket(name));
  sql = sql.replace(/= TRUE/g, '= 1').replace(/= FALSE/g, '= 0');
  // Remove PG-specific USING btree/gin/gist
  sql = sql.replace(/\bUSING\s+(btree|gin|gist|hash)\b/gi, '');

  // Skip COALESCE in index columns (not valid in SQL Server)
  if (/COALESCE\(/.test(sql) && !/WHERE/.test(sql.split('COALESCE')[0])) {
    return `-- (skipped: index ${idxName} uses COALESCE in columns)\nGO\n`;
  }

  const result = [];
  result.push(`IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = '${idxName}')`);
  result.push(`  ${sql.replace(/;$/, '')};`);
  result.push('GO');
  result.push('');
  return result.join('\n');
}

// ── Translate ALTER TABLE ADD COLUMN ────────────────────────
function translateAlter(trimmed, lines, i) {
  // Skip legacy/dbo tables
  if (/^ALTER TABLE\s+(public|dbo)\./i.test(trimmed)) return { skip: true, i };

  let sql = trimmed;
  while (!sql.endsWith(';') && i + 1 < lines.length) { i++; sql += ' ' + lines[i].trim(); }

  const tableM = sql.match(/ALTER TABLE\s+(\w+)\."?(\w+)"?/i);
  if (!tableM) return { skip: true, i };

  let schema = fixSchema(tableM[1]);
  const tbl = tableM[2];
  const colPattern = /ADD\s+(?:COLUMN\s+)?(?:IF NOT EXISTS\s+)?"?(\w+)"?\s+([^,;]+)/gi;
  const result = [];
  let m;
  while ((m = colPattern.exec(sql)) !== null) {
    let colName = m[1];
    let colDef = m[2].trim();
    colDef = colDef.replace(/\bBOOLEAN\b/g, 'BIT');
    colDef = colDef.replace(/\bTIMESTAMP\b/g, 'DATETIME2(0)');
    colDef = colDef.replace(/\bTEXT\b/g, 'NVARCHAR(MAX)');
    colDef = colDef.replace(/\bVARCHAR\((\d+)\)/g, 'NVARCHAR($1)');
    colDef = colDef.replace(/\bVARCHAR\b(?!\()/g, 'NVARCHAR(MAX)');
    colDef = colDef.replace(/\bCHAR\((\d+)\)/g, 'NCHAR($1)');
    colDef = colDef.replace(/\bNUMERIC\((\d+),(\d+)\)/g, 'DECIMAL($1,$2)');
    colDef = colDef.replace(/DEFAULT TRUE/g, 'DEFAULT 1');
    colDef = colDef.replace(/DEFAULT FALSE/g, 'DEFAULT 0');
    colDef = colDef.replace(/\(NOW\(\) AT TIME ZONE 'UTC'\)/g, 'SYSUTCDATETIME()');
    colDef = colDef.replace(/NOW\(\)/g, 'SYSUTCDATETIME()');
    const colRef = bracket(colName);
    result.push(`IF COL_LENGTH('${schema}.${tbl}', '${colName}') IS NULL`);
    result.push(`  ALTER TABLE ${schema}.${tbl} ADD ${colRef} ${colDef};`);
    result.push('GO');
  }
  return { lines: result, i };
}

// ── Parse baseline ──────────────────────────────────────────
let inCreateTable = false, tableBlock = [];
let inIndex = false, indexBlock = [];
let inDoBlock = false;
let tableCount = 0, indexCount = 0;

for (let i = 0; i < lines.length; i++) {
  const trimmed = lines[i].trim();

  if (trimmed.startsWith('-- +goose')) continue;
  if (trimmed.startsWith('BEGIN;') || trimmed === 'COMMIT;') continue;
  if (trimmed.startsWith('INSERT INTO')) continue;
  if (trimmed.startsWith('ON CONFLICT')) continue;
  if (trimmed.startsWith('CREATE EXTENSION')) continue;
  if (trimmed.startsWith('CREATE TABLE IF NOT EXISTS public._migrations')) continue;

  // DO $$ blocks
  if (/^DO\s*\$[^$]*\$/.test(trimmed)) {
    if (/END\s*\$[^$]*\$\s*;?\s*$/.test(trimmed)) continue; // single-line
    inDoBlock = true; continue;
  }
  if (inDoBlock) {
    if (/END\s*\$[^$]*\$\s*;?\s*$/.test(trimmed)) inDoBlock = false;
    continue;
  }

  // CREATE TABLE
  if (/^CREATE TABLE IF NOT EXISTS\s+\w+\."/.test(trimmed)) {
    inCreateTable = true; tableBlock = [lines[i]]; continue;
  }
  if (inCreateTable) {
    tableBlock.push(lines[i]);
    if (trimmed === ');') {
      inCreateTable = false;
      const translated = translateTableBlock(tableBlock);
      if (translated) { output.push(translated); tableCount++; }
      tableBlock = [];
    }
    continue;
  }

  // CREATE INDEX (possibly multiline)
  if (/^CREATE (UNIQUE )?INDEX IF NOT EXISTS/.test(trimmed)) {
    if (trimmed.endsWith(';')) {
      const t = translateIndex(trimmed);
      if (t) { output.push(t); indexCount++; }
    } else {
      inIndex = true; indexBlock = [trimmed];
    }
    continue;
  }
  if (inIndex) {
    indexBlock.push(trimmed);
    if (trimmed.endsWith(';')) {
      inIndex = false;
      const t = translateIndex(indexBlock.join(' '));
      if (t) { output.push(t); indexCount++; }
      indexBlock = [];
    }
    continue;
  }

  // ALTER TABLE ADD COLUMN
  if (/^ALTER TABLE\s+\w+\."?\w+"?\s+ADD/i.test(trimmed)) {
    const r = translateAlter(trimmed, lines, i);
    if (!r.skip && r.lines) { output.push(...r.lines); output.push(''); }
    i = r.i || i;
    continue;
  }
}

output.push(`-- Total: ${tableCount} tables, ${indexCount} indexes`);
output.push(`PRINT 'DDL completado: ${tableCount} tablas, ${indexCount} indices';`);
output.push('GO');

// ── Post-processing ─────────────────────────────────────────
let final = output.join('\n');
final = final.replace(/;;\s*$/gm, ';');
// Fix UserCode size mismatch (PG has VARCHAR(10) but User has VARCHAR(40))
final = final.replace(/UserCode\s+NVARCHAR\(10\)/g, 'UserCode          NVARCHAR(40)');

const outPath = path.resolve(__dirname, '01_ddl_tables.sql');
fs.writeFileSync(outPath, final, 'utf8');
console.log(`Generated: ${outPath}`);
console.log(`Tables: ${tableCount}, Indexes: ${indexCount}`);
