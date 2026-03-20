/**
 * sp-contracts.test.ts
 *
 * Valida que los stored procedures de PostgreSQL cumplan los contratos
 * esperados: existen, no tienen overloads duplicados, y los tipos de
 * retorno son correctos.
 *
 * Lee SOLO metadatos (pg_proc) — no modifica datos.
 * Se ejecuta contra la DB de produccion via SSH tunnel o en CI con
 * variable PG_CONNECTION_STRING.
 *
 * Variables de entorno:
 *   PG_CONNECTION_STRING  o  PG_HOST + PG_PORT + PG_DATABASE + PG_USER + PG_PASSWORD
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import pg from 'pg';
import 'dotenv/config';

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

let pool: pg.Pool;

beforeAll(() => {
  pool = process.env.PG_CONNECTION_STRING
    ? new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING })
    : new pg.Pool({
        host:     process.env.PG_HOST     ?? '127.0.0.1',
        port:     Number(process.env.PG_PORT ?? 5432),
        database: process.env.PG_DATABASE ?? 'zentto_prod',
        user:     process.env.PG_USER     ?? 'zentto_app',
        password: process.env.PG_PASSWORD ?? '',
        ssl:      process.env.PG_SSL === 'true' ? { rejectUnauthorized: false } : false,
      });
});

afterAll(async () => {
  await pool.end();
});

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

/** Cuenta cuántos overloads tiene una función (por nombre, sin importar firma) */
async function countOverloads(funcName: string): Promise<number> {
  const res = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt FROM pg_proc WHERE proname = $1`,
    [funcName.toLowerCase()]
  );
  return Number(res.rows[0]?.cnt ?? 0);
}

/** Obtiene los nombres de las columnas del resultado de la función */
async function getReturnColumns(funcName: string): Promise<{ name: string; type: string }[]> {
  const res = await pool.query<{ attname: string; typname: string }>(
    `SELECT a.attname, t.typname
     FROM pg_proc p
     JOIN pg_type rt ON rt.oid = p.prorettype
     LEFT JOIN pg_attribute a ON a.attrelid = rt.typrelid AND a.attnum > 0
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     WHERE p.proname = $1
       AND rt.typtype = 'c'
     ORDER BY a.attnum`,
    [funcName.toLowerCase()]
  );
  return res.rows.map(r => ({ name: r.attname, type: r.typname }));
}

/** Verifica que la función existe */
async function funcExists(funcName: string): Promise<boolean> {
  const count = await countOverloads(funcName);
  return count > 0;
}

// ────────────────────────────────────────────────────────────────────────────
// Tests: existencia de funciones críticas
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — funciones críticas existen', () => {
  const criticalFunctions = [
    // Auth
    'usp_sec_user_authenticate',
    'usp_sec_user_checkexists',
    'usp_sec_user_getmoduleaccess',
    // POS
    'usp_pos_waitticket_create',
    'usp_pos_waitticketline_insert',
    'usp_pos_waitticket_recover',
    'usp_pos_waitticket_void',
    'usp_pos_waitticket_getheader',
    'usp_pos_waitticketline_getitems',
    'usp_pos_saleticket_create',
    // Config
    'usp_cfg_appsetting_list',
    'usp_cfg_resolvecontext',
    // Fiscal
    'usp_cfg_fiscal_getconfig',
    'usp_cfg_fiscal_upsertconfig',
  ];

  for (const fn of criticalFunctions) {
    it(`${fn} debe existir`, async () => {
      const exists = await funcExists(fn);
      expect(exists, `La función ${fn} no existe en la base de datos`).toBe(true);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Tests: sin overloads duplicados (causa principal de errores POS)
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — sin overloads duplicados', () => {
  const singleOverloadFunctions = [
    'usp_pos_waitticket_create',
    'usp_pos_waitticketline_insert',
    'usp_pos_waitticket_recover',
    'usp_pos_waitticket_void',
    'usp_pos_waitticket_getheader',
    'usp_pos_waitticketline_getitems',
    'usp_pos_saleticket_create',
    'usp_pos_saleticketline_insert',
  ];

  for (const fn of singleOverloadFunctions) {
    it(`${fn} debe tener exactamente 1 overload`, async () => {
      const count = await countOverloads(fn);
      expect(
        count,
        `${fn} tiene ${count} overloads — debería tener exactamente 1. ` +
        `Ejecutar: npm run db:migrate:pg:incremental`
      ).toBe(1);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Tests: tipos de retorno BIGINT donde se requiere
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — tipos BIGINT correctos', () => {
  it('usp_pos_waitticket_create debe retornar "Resultado" como int8 (BIGINT)', async () => {
    const res = await pool.query<{ proretset: boolean; prosrc: string }>(
      `SELECT p.prosrc
       FROM pg_proc p
       WHERE p.proname = 'usp_pos_waitticket_create'
       LIMIT 1`
    );
    expect(res.rows.length).toBe(1);
    // El source debe declarar v_id BIGINT (no INT)
    const src = res.rows[0]?.prosrc ?? '';
    expect(src.toLowerCase()).toContain('bigint');
    expect(src.toLowerCase()).not.toMatch(/\bv_id\s+int\b(?!eger)/i);
  });

  it('usp_pos_waitticketline_insert primer parámetro debe ser bigint', async () => {
    const res = await pool.query<{ proargtypes: string }>(
      `SELECT pg_catalog.format_type(t.oid, NULL) AS argtype
       FROM pg_proc p
       CROSS JOIN LATERAL unnest(p.proargtypes) WITH ORDINALITY AS u(oid, ord)
       JOIN pg_type t ON t.oid = u.oid
       WHERE p.proname = 'usp_pos_waitticketline_insert'
       ORDER BY u.ord
       LIMIT 1`
    );
    expect(res.rows.length).toBe(1);
    expect(res.rows[0]?.argtype).toBe('bigint');
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Tests: tabla de control de migraciones existe
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — infraestructura de migraciones', () => {
  it('tabla public._migrations debe existir', async () => {
    const res = await pool.query<{ exists: boolean }>(
      `SELECT EXISTS (
         SELECT 1 FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name = '_migrations'
       ) AS exists`
    );
    expect(res.rows[0]?.exists).toBe(true);
  });
});
