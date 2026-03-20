/**
 * sp-contracts.test.ts
 *
 * Valida TODOS los stored procedures/funciones de PostgreSQL automáticamente.
 * - No requiere lista manual: escanea pg_proc en tiempo real
 * - Detecta overloads duplicados (causa principal de errores POS)
 * - Verifica tipos BIGINT donde se requiere
 * - Solo lectura (pg_proc) — no modifica datos
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

interface FuncOverload {
  proname: string;
  count: number;
}

interface FuncMeta {
  proname: string;
  argtypes: string[];
  rettype: string;
  proretset: boolean;
}

async function getAllFunctionNames(): Promise<string[]> {
  const res = await pool.query<{ proname: string }>(
    `SELECT DISTINCT proname FROM pg_proc
     WHERE proname LIKE 'usp_%'
     ORDER BY proname`
  );
  return res.rows.map(r => r.proname);
}

async function getFunctionsWithOverloads(): Promise<FuncOverload[]> {
  const res = await pool.query<{ proname: string; count: string }>(
    `SELECT proname, COUNT(*) AS count
     FROM pg_proc
     WHERE proname LIKE 'usp_%'
     GROUP BY proname
     HAVING COUNT(*) > 1
     ORDER BY proname`
  );
  return res.rows.map(r => ({ proname: r.proname, count: Number(r.count) }));
}

async function getFuncMeta(funcName: string): Promise<FuncMeta[]> {
  const res = await pool.query<{
    proname: string;
    argtypes: string;
    rettype: string;
    proretset: boolean;
  }>(
    `SELECT
       p.proname,
       pg_catalog.pg_get_function_arguments(p.oid) AS argtypes,
       pg_catalog.pg_get_function_result(p.oid)    AS rettype,
       p.proretset
     FROM pg_proc p
     WHERE p.proname = $1
     ORDER BY p.oid`,
    [funcName.toLowerCase()]
  );
  return res.rows.map(r => ({
    proname: r.proname,
    argtypes: r.argtypes ? r.argtypes.split(',').map(s => s.trim()) : [],
    rettype: r.rettype ?? '',
    proretset: r.proretset,
  }));
}

// ────────────────────────────────────────────────────────────────────────────
// Test 1: La DB está bootstrapped (sanity check)
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — DB bootstrapped', () => {
  it('debe tener al menos 100 funciones usp_*', async () => {
    const names = await getAllFunctionNames();
    expect(
      names.length,
      `Solo hay ${names.length} funciones — la DB puede no estar inicializada`
    ).toBeGreaterThanOrEqual(100);
    console.log(`  ℹ  Total funciones únicas usp_*: ${names.length}`);
  });

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

// ────────────────────────────────────────────────────────────────────────────
// Test 2: CERO overloads duplicados en TODAS las funciones
// (Este es el test crítico — detecta la causa raíz de los errores POS)
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — sin overloads duplicados (todas las funciones)', () => {
  it('ninguna función usp_* debe tener más de 1 overload', async () => {
    const overloads = await getFunctionsWithOverloads();

    if (overloads.length > 0) {
      const report = overloads
        .map(f => `  - ${f.proname}: ${f.count} overloads`)
        .join('\n');
      console.error(`\n⚠️  Funciones con overloads duplicados:\n${report}\n`);
      console.error(
        `Solución: crear migración en sqlweb-pg/migrations/ con:\n` +
        `  DROP FUNCTION IF EXISTS <nombre>(tipo1, tipo2, ...) CASCADE;\n` +
        `  CREATE OR REPLACE FUNCTION <nombre>(...)\n`
      );
    }

    expect(
      overloads.length,
      `Hay ${overloads.length} función(es) con overloads duplicados:\n` +
      overloads.map(f => `  ${f.proname} (${f.count} versiones)`).join('\n')
    ).toBe(0);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 3: Funciones POS críticas — tipos BIGINT correctos
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — tipos BIGINT en funciones POS', () => {
  const bigintReturnFunctions = [
    'usp_pos_waitticket_create',
    'usp_pos_waitticketline_insert',
    'usp_pos_saleticketline_insert',
  ];

  for (const fn of bigintReturnFunctions) {
    it(`${fn} debe retornar "Resultado" como BIGINT`, async () => {
      const metas = await getFuncMeta(fn);
      if (metas.length === 0) {
        console.warn(`  ⚠  ${fn} no encontrada — omitiendo test de tipo`);
        return; // skip si no existe
      }
      const meta = metas[0];
      expect(
        meta.rettype.toLowerCase(),
        `${fn} retorna "${meta.rettype}" — se esperaba bigint`
      ).toContain('bigint');
    });
  }

  it('usp_pos_waitticketline_insert primer parámetro debe ser bigint', async () => {
    const metas = await getFuncMeta('usp_pos_waitticketline_insert');
    if (metas.length === 0) return;
    const firstArgType = metas[0]?.argtypes[0] ?? '';
    expect(
      firstArgType.toLowerCase(),
      `Primer argumento es "${firstArgType}" — se esperaba bigint`
    ).toContain('bigint');
  });

  it('usp_pos_waitticket_recover p_wait_ticket_id debe ser bigint', async () => {
    const metas = await getFuncMeta('usp_pos_waitticket_recover');
    if (metas.length === 0) return;
    // Tercer parámetro (índice 2) es p_wait_ticket_id
    const thirdArgType = metas[0]?.argtypes[2] ?? '';
    expect(
      thirdArgType.toLowerCase(),
      `Tercer argumento de usp_pos_waitticket_recover es "${thirdArgType}" — se esperaba bigint`
    ).toContain('bigint');
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 4: Funciones de infraestructura obligatorias
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — funciones de infraestructura', () => {
  // Solo las funciones más críticas para que el sistema arranque
  const requiredFunctions = [
    'usp_sec_user_authenticate',
    'usp_cfg_resolvecontext',
    'usp_cfg_fiscal_getconfig',
    'usp_pos_waitticket_create',
    'usp_pos_saleticket_create',
  ];

  for (const fn of requiredFunctions) {
    it(`${fn} debe existir`, async () => {
      const res = await pool.query<{ cnt: string }>(
        `SELECT COUNT(*) AS cnt FROM pg_proc WHERE proname = $1`,
        [fn.toLowerCase()]
      );
      const exists = Number(res.rows[0]?.cnt ?? 0) > 0;
      expect(exists, `La función ${fn} no existe en la base de datos`).toBe(true);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Test 5: Reporte de estado (informativo, siempre pasa)
// ────────────────────────────────────────────────────────────────────────────

describe('SP Contracts — reporte de estado', () => {
  it('muestra resumen de funciones por módulo', async () => {
    const res = await pool.query<{ modulo: string; total: string }>(
      `SELECT
         SPLIT_PART(proname, '_', 2) AS modulo,
         COUNT(DISTINCT proname) AS total
       FROM pg_proc
       WHERE proname LIKE 'usp_%'
       GROUP BY modulo
       ORDER BY total DESC`
    );
    console.log('\n  📊 Funciones por módulo:');
    for (const row of res.rows) {
      console.log(`     ${row.modulo.padEnd(15)} ${row.total}`);
    }
    expect(res.rows.length).toBeGreaterThan(0);
  });
});
