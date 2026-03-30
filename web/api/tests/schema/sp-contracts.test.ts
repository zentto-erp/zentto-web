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

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import pg from "pg";
import "dotenv/config";

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

let pool: pg.Pool;

beforeAll(() => {
  pool = process.env.PG_CONNECTION_STRING
    ? new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING })
    : new pg.Pool({
        host: process.env.PG_HOST ?? "127.0.0.1",
        port: Number(process.env.PG_PORT ?? 5432),
        database: process.env.PG_DATABASE ?? "zentto_prod",
        user: process.env.PG_USER ?? "zentto_app",
        password: process.env.PG_PASSWORD ?? "",
        ssl:
          process.env.PG_SSL === "true" ? { rejectUnauthorized: false } : false,
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
    `SELECT DISTINCT p.proname FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE p.proname LIKE 'usp_%'
       AND n.nspname = 'public'
     ORDER BY p.proname`,
  );
  return res.rows.map((r) => r.proname);
}

async function getFunctionsWithOverloads(): Promise<FuncOverload[]> {
  const res = await pool.query<{ proname: string; count: string }>(
    `SELECT p.proname, COUNT(*) AS count
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE p.proname LIKE 'usp_%'
       AND n.nspname = 'public'
     GROUP BY p.proname
     HAVING COUNT(*) > 1
     ORDER BY p.proname`,
  );
  return res.rows.map((r) => ({ proname: r.proname, count: Number(r.count) }));
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
    [funcName.toLowerCase()],
  );
  return res.rows.map((r) => ({
    proname: r.proname,
    argtypes: r.argtypes ? r.argtypes.split(",").map((s) => s.trim()) : [],
    rettype: r.rettype ?? "",
    proretset: r.proretset,
  }));
}

// ────────────────────────────────────────────────────────────────────────────
// Test 1: La DB está bootstrapped (sanity check)
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — DB bootstrapped", () => {
  it("debe tener al menos 100 funciones usp_*", async () => {
    const names = await getAllFunctionNames();
    expect(
      names.length,
      `Solo hay ${names.length} funciones — la DB puede no estar inicializada`,
    ).toBeGreaterThanOrEqual(100);
    console.log(`  ℹ  Total funciones únicas usp_*: ${names.length}`);
  });

  it("tabla public._migrations debe existir", async () => {
    const res = await pool.query<{ exists: boolean }>(
      `SELECT EXISTS (
         SELECT 1 FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name = '_migrations'
       ) AS exists`,
    );
    expect(res.rows[0]?.exists).toBe(true);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 2: CERO overloads duplicados en TODAS las funciones
// (Este es el test crítico — detecta la causa raíz de los errores POS)
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — sin overloads duplicados (todas las funciones)", () => {
  it("ninguna función usp_* debe tener más de 1 overload", async () => {
    const overloads = await getFunctionsWithOverloads();

    if (overloads.length > 0) {
      const report = overloads
        .map((f) => `  - ${f.proname}: ${f.count} overloads`)
        .join("\n");
      console.error(`\n⚠️  Funciones con overloads duplicados:\n${report}\n`);
      console.error(
        `Solución: crear migración en sqlweb-pg/migrations/ con:\n` +
          `  DROP FUNCTION IF EXISTS <nombre>(tipo1, tipo2, ...) CASCADE;\n` +
          `  DROP FUNCTION IF EXISTS <nombre>(...)\n`,
      );
    }

    expect(
      overloads.length,
      `Hay ${overloads.length} función(es) con overloads duplicados:\n` +
        overloads
          .map((f) => `  ${f.proname} (${f.count} versiones)`)
          .join("\n"),
    ).toBe(0);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 3: Funciones POS críticas — tipos BIGINT correctos
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — tipos BIGINT en funciones POS", () => {
  const bigintReturnFunctions = [
    "usp_pos_waitticket_create",
    "usp_pos_waitticketline_insert",
    "usp_pos_saleticketline_insert",
  ];

  for (const fn of bigintReturnFunctions) {
    it(`${fn} debe retornar "Resultado" como BIGINT`, async () => {
      const metas = await getFuncMeta(fn);
      expect(metas.length, `La función ${fn} no existe en la base de datos`).toBeGreaterThan(0);
      const meta = metas[0];
      expect(
        meta.rettype.toLowerCase(),
        `${fn} retorna "${meta.rettype}" — se esperaba bigint`,
      ).toContain("bigint");
    });
  }

  it("usp_pos_waitticketline_insert primer parámetro debe ser bigint", async () => {
    const metas = await getFuncMeta("usp_pos_waitticketline_insert");
    expect(metas.length, "usp_pos_waitticketline_insert no existe").toBeGreaterThan(0);
    const firstArgType = metas[0]?.argtypes[0] ?? "";
    expect(
      firstArgType.toLowerCase(),
      `Primer argumento es "${firstArgType}" — se esperaba bigint`,
    ).toContain("bigint");
  });

  it("usp_pos_waitticket_recover p_wait_ticket_id debe ser bigint", async () => {
    const metas = await getFuncMeta("usp_pos_waitticket_recover");
    expect(metas.length, "usp_pos_waitticket_recover no existe").toBeGreaterThan(0);
    const thirdArgType = metas[0]?.argtypes[2] ?? "";
    expect(
      thirdArgType.toLowerCase(),
      `Tercer argumento de usp_pos_waitticket_recover es "${thirdArgType}" — se esperaba bigint`,
    ).toContain("bigint");
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 4: Funciones de infraestructura obligatorias
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — funciones de infraestructura", () => {
  const requiredFunctions = [
    // Auth + config (sistema base)
    "usp_sec_user_authenticate",
    "usp_cfg_resolvecontext",
    "usp_cfg_fiscal_getconfig",
    // POS
    "usp_pos_waitticket_create",
    "usp_pos_saleticket_create",
    // Shipping (migración 00020)
    "usp_shipping_customer_register",
    "usp_shipping_customer_login",
    "usp_shipping_shipment_create",
    "usp_shipping_shipment_list",
    "usp_shipping_track",
    // Backups (migraciones 00029/00030)
    "usp_sys_backup_create",
    "usp_sys_backup_complete",
    "usp_sys_backup_fail",
    "usp_sys_backup_list",
    // Resource management (migración 00028)
    "usp_sys_resource_audit",
    "usp_sys_cleanup_scan",
    "usp_sys_cleanup_list",
    "usp_sys_cleanup_process",
    // Módulos de negocio — nombres exactos de pg_proc
    "usp_ar_receivable_list",
    "usp_ap_payable_list",
    "usp_fin_bank_list",
    "usp_bank_account_list",
    "usp_bank_movement_create",
    "usp_acct_account_list",
    "usp_acct_scope_getdefault",
    "usp_doc_salesdocument_list",
    "usp_doc_purchasedocument_list",
    "usp_hr_employee_list",
    "usp_shipping_dashboard",
    "usp_shipping_customs_upsert",
    "usp_sys_backup_tenantinfo",
    "usp_sys_backup_latest_per_tenant",
    // CRM
    "usp_crm_lead_list",
    "usp_crm_activity_list",
    "usp_crm_pipeline_getstages",
    // Manufactura
    "usp_mfg_bom_list",
    "usp_mfg_workorder_list",
    // Flota
    "usp_fleet_vehicle_list",
    // Inventario
    "usp_inv_movement_list",
    // POS
    "usp_pos_saleticketline_insert",
    "usp_pos_waitticketline_insert",
    // Fiscal (migración 00042)
    "usp_fiscal_taxbook_populate",
    "usp_fiscal_taxbook_list",
    "usp_fiscal_taxbook_summary",
    "usp_fiscal_declaration_calculate",
    "usp_fiscal_declaration_list",
    "usp_fiscal_declaration_get",
    "usp_fiscal_declaration_submit",
    "usp_fiscal_declaration_amend",
    "usp_fiscal_withholding_generate",
    "usp_fiscal_withholding_list",
    "usp_fiscal_withholding_get",
    "usp_fiscal_export_taxbook",
    "usp_fiscal_export_declaration",
  ];

  for (const fn of requiredFunctions) {
    it(`${fn} debe existir`, async () => {
      const res = await pool.query<{ cnt: string }>(
        `SELECT COUNT(*) AS cnt FROM pg_proc WHERE proname = $1`,
        [fn.toLowerCase()],
      );
      const exists = Number(res.rows[0]?.cnt ?? 0) > 0;
      expect(exists, `La función ${fn} no existe en la base de datos`).toBe(
        true,
      );
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Test 5: Reporte de estado (informativo, siempre pasa)
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — reporte de estado", () => {
  it("muestra resumen de funciones por módulo", async () => {
    const res = await pool.query<{ modulo: string; total: string }>(
      `SELECT
         SPLIT_PART(proname, '_', 2) AS modulo,
         COUNT(DISTINCT proname) AS total
       FROM pg_proc
       WHERE proname LIKE 'usp_%'
       GROUP BY modulo
       ORDER BY total DESC`,
    );
    console.log("\n  📊 Funciones por módulo:");
    for (const row of res.rows) {
      console.log(`     ${row.modulo.padEnd(15)} ${row.total}`);
    }
    expect(res.rows.length).toBeGreaterThan(0);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 6: Sin TIMESTAMP WITH TIME ZONE — obligatorio, falla si hay problemas
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — sin TIMESTAMP WITH TIME ZONE", () => {
  it("ninguna función usp_* debe usar timestamp with time zone en argumentos o retorno", async () => {
    const res = await pool.query<{
      proname: string;
      args: string;
      ret: string;
    }>(
      `SELECT
         p.proname,
         pg_get_function_arguments(p.oid) AS args,
         pg_get_function_result(p.oid)    AS ret
       FROM pg_proc p
       WHERE p.proname LIKE 'usp_%'
         AND (
           pg_get_function_arguments(p.oid) ILIKE '%timestamp with time zone%'
           OR pg_get_function_result(p.oid) ILIKE '%timestamp with time zone%'
         )
       ORDER BY p.proname`,
    );

    const list = res.rows;

    if (list.length > 0) {
      console.error(
        "\n[SP Contracts] Funciones con TIMESTAMP WITH TIME ZONE (TIMESTAMPTZ) — se esperaba TIMESTAMP sin zona:",
      );
      for (const row of list) {
        const argsHit = /timestamp with time zone/i.test(row.args ?? "")
          ? `ARGS: ${row.args}`
          : "";
        const retHit = /timestamp with time zone/i.test(row.ret ?? "")
          ? `RET:  ${row.ret}`
          : "";
        console.error(`  - ${row.proname}`);
        if (argsHit) console.error(`      ${argsHit}`);
        if (retHit) console.error(`      ${retHit}`);
      }
      console.error(
        "\nSolución: reemplazar TIMESTAMPTZ / TIMESTAMP WITH TIME ZONE por TIMESTAMP en los scripts sqlweb-pg/\n",
      );
    }

    expect(
      list.length,
      `Hay ${list.length} función(es) usando TIMESTAMP WITH TIME ZONE. ` +
        `Todas las fechas deben ser TIMESTAMP (sin zona). ` +
        `Funciones afectadas: ${list.map((r) => r.proname).join(", ")}`,
    ).toBe(0);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 7: Parámetros de entidades principales deben ser BIGINT — obligatorio
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — parámetros de entidades deben ser BIGINT", () => {
  /**
   * Sufijos de columnas BIGINT según el DDL real del proyecto.
   * El matching es case-insensitive y tolerante a snake_case y camelCase.
   * Ejemplos de parámetros que matchean "customerid":
   *   p_customer_id, p_customerid, customerid, customer_id
   */
  const bigintEntitySuffixes: string[] = [
    "customerid",
    "supplierid",
    "employeeid",
    "productid",
    "accountid",
    "journalentryid",
    "waitticketid",
    "saleticketid",
    "bankmovementid",
    "bankaccountid",
    "bankid",
    "movementid",
    "payrollrunid",
    "orderticketid",
    "receivabledocumentid",
    "payabledocumentid",
  ];

  /**
   * Normaliza un nombre de parámetro PostgreSQL a minúsculas sin guiones bajos
   * para compararlo contra los sufijos de la lista.
   * Ejemplos:
   *   "p_customer_id integer" -> "customerid"
   *   "p_sale_ticket_id bigint" -> "saleticketid"
   */
  function normalizeParamName(raw: string): string {
    // raw = 'p_customer_id integer' -> tomar solo el nombre (primer token)
    const name = raw.trim().split(/\s+/)[0] ?? "";
    return name.replace(/^p_/, "").replace(/_/g, "").toLowerCase();
  }

  /**
   * Extrae el tipo de dato de un fragmento de argumento PostgreSQL.
   * Ejemplos:
   *   "p_customer_id integer"  -> "integer"
   *   "p_sale_ticket_id bigint" -> "bigint"
   *   "p_name character varying" -> "character varying"
   */
  function extractParamType(raw: string): string {
    const tokens = raw.trim().split(/\s+/);
    // El nombre es el primer token; el tipo es el resto
    return tokens.slice(1).join(" ").toLowerCase();
  }

  it("todos los parámetros de entidad BIGINT deben declararse como bigint (no integer)", async () => {
    const res = await pool.query<{ proname: string; args: string }>(
      `SELECT p.proname,
              pg_get_function_arguments(p.oid) AS args
       FROM pg_proc p
       WHERE p.proname LIKE 'usp_%'
       ORDER BY p.proname`,
    );

    interface Mismatch {
      func: string;
      param: string;
      actual: string;
      expected: string;
    }

    const mismatches: Mismatch[] = [];

    for (const row of res.rows) {
      if (!row.args) continue;

      // pg_get_function_arguments devuelve una lista separada por comas
      const argFragments = row.args.split(",").map((s) => s.trim());

      for (const fragment of argFragments) {
        if (!fragment) continue;

        const normalized = normalizeParamName(fragment);
        const paramType = extractParamType(fragment);

        // Verifica si el nombre normalizado TERMINA con alguno de los sufijos BIGINT
        const matchedSuffix = bigintEntitySuffixes.find((suffix) =>
          normalized.endsWith(suffix),
        );

        // Excluir IDs externos de terceros (ej: paddle_customer_id es VARCHAR externo, no BIGINT de DB)
        const isExternalId = normalized.startsWith("paddle");

        if (matchedSuffix && !isExternalId && !paramType.includes("bigint")) {
          mismatches.push({
            func: row.proname,
            param: fragment.trim().split(/\s+/)[0] ?? fragment,
            actual: paramType,
            expected: "bigint",
          });
        }
      }
    }

    if (mismatches.length > 0) {
      console.error(
        `\n[SP Contracts] Parámetros de entidad que deberían ser BIGINT pero no lo son (${mismatches.length}):`,
      );
      console.error(
        `  ${"FUNCIÓN".padEnd(50)} ${"PARÁMETRO".padEnd(30)} ${"TIPO ACTUAL".padEnd(20)} TIPO ESPERADO`,
      );
      console.error(`  ${"-".repeat(115)}`);
      for (const m of mismatches) {
        console.error(
          `  ${m.func.padEnd(50)} ${m.param.padEnd(30)} ${m.actual.padEnd(20)} ${m.expected}`,
        );
      }
      console.error(
        "\nSolución: cambiar INTEGER -> BIGINT en los scripts sqlweb-pg/ para los parámetros afectados.\n",
      );
    }

    expect(
      mismatches.length,
      `Hay ${mismatches.length} parámetro(s) de entidad declarados con tipo incorrecto. ` +
        `Se esperaba bigint. Primeros 5 afectados: ` +
        mismatches
          .slice(0, 5)
          .map((m) => `${m.func}.${m.param}(${m.actual})`)
          .join(", "),
    ).toBe(0);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 7b: Columnas de RETURNS TABLE de entidades también deben ser BIGINT
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — columnas de RETURNS TABLE deben ser BIGINT", () => {
  /**
   * Mismos sufijos que Test 7. El matching es case-insensitive y tolerante
   * a snake_case y camelCase en los nombres de columna del RETURNS TABLE.
   * Ejemplos de columnas que matchean "customerid":
   *   "CustomerId", "customer_id", "customerid"
   */
  const bigintEntitySuffixes: string[] = [
    "customerid",
    "supplierid",
    "employeeid",
    "productid",
    "accountid",
    "journalentryid",
    "waitticketid",
    "saleticketid",
    "bankmovementid",
    "bankaccountid",
    "bankid",
    "movementid",
    "payrollrunid",
    "orderticketid",
    "receivabledocumentid",
    "payabledocumentid",
  ];

  /**
   * Parsea el resultado de pg_get_function_result cuando es RETURNS TABLE.
   * Formato: TABLE("ColName" bigint, "OtherCol" integer, ...)
   * Devuelve pares { name: string normalizado, type: string en minúsculas }.
   * El name ya viene sin guiones bajos y en minúsculas para facilitar la
   * comparación con bigintEntitySuffixes.
   */
  function parseReturnsCols(rettype: string): { name: string; type: string }[] {
    if (!rettype.trim().toUpperCase().startsWith("TABLE")) return [];

    // Extraer el interior del TABLE(...)
    const inner = rettype.replace(/^TABLE\s*\(/i, "").replace(/\)\s*$/, "");

    return inner
      .split(",")
      .map((col) => {
        const trimmed = col.trim();
        if (!trimmed) return null;
        // Soporta tanto "ColName" tipo  como  colname tipo
        const m = trimmed.match(/^"?([^"\s]+)"?\s+(.+)$/);
        if (!m) return null;
        return {
          name: m[1].replace(/_/g, "").toLowerCase(),
          type: m[2].trim().toLowerCase(),
        };
      })
      .filter((x): x is { name: string; type: string } => x !== null);
  }

  it("todas las columnas de RETURNS TABLE con sufijo de entidad deben ser bigint (no integer)", async () => {
    const res = await pool.query<{ proname: string; rettype: string }>(
      `SELECT p.proname,
              pg_get_function_result(p.oid) AS rettype
       FROM pg_proc p
       WHERE p.proname LIKE 'usp_%'
         AND pg_get_function_result(p.oid) ILIKE 'TABLE(%'
       ORDER BY p.proname`,
    );

    interface Mismatch {
      func: string;
      column: string;
      actual: string;
      expected: string;
    }

    const mismatches: Mismatch[] = [];

    for (const row of res.rows) {
      if (!row.rettype) continue;

      const cols = parseReturnsCols(row.rettype);

      for (const col of cols) {
        // Verifica si el nombre normalizado TERMINA con alguno de los sufijos BIGINT
        const matchedSuffix = bigintEntitySuffixes.find((suffix) =>
          col.name.endsWith(suffix),
        );

        // Excluir IDs externos de terceros (ej: paddlecustomerid es VARCHAR externo, no BIGINT de DB)
        const isExternalId = col.name.startsWith("paddle");

        if (matchedSuffix && !isExternalId && !col.type.includes("bigint")) {
          mismatches.push({
            func: row.proname,
            column: col.name,
            actual: col.type,
            expected: "bigint",
          });
        }
      }
    }

    if (mismatches.length > 0) {
      console.error(
        `\n[SP Contracts] Columnas de RETURNS TABLE que deberían ser BIGINT pero no lo son (${mismatches.length}):`,
      );
      console.error(
        `  ${"FUNCIÓN".padEnd(50)} ${"COLUMNA RETORNO".padEnd(30)} ${"TIPO ACTUAL".padEnd(20)} TIPO ESPERADO`,
      );
      console.error(`  ${"-".repeat(115)}`);
      for (const m of mismatches) {
        console.error(
          `  ${m.func.padEnd(50)} ${m.column.padEnd(30)} ${m.actual.padEnd(20)} ${m.expected}`,
        );
      }
      console.error(
        "\nSolución: cambiar INTEGER -> BIGINT en las columnas de RETURNS TABLE de los scripts sqlweb-pg/\n",
      );
    }

    expect(
      mismatches.length,
      `Hay ${mismatches.length} columna(s) de RETURNS TABLE con tipo incorrecto. ` +
        `Se esperaba bigint. Primeros 5 afectados: ` +
        mismatches
          .slice(0, 5)
          .map((m) => `${m.func}."${m.column}"(${m.actual})`)
          .join(", "),
    ).toBe(0);
  });
});

// Test 8 eliminado — todas las funciones antes "opcionales" ahora son
// obligatorias en Test 4 (requiredFunctions). 0 skips permitidos.

// ────────────────────────────────────────────────────────────────────────────
// Test 9: Tablas del esquema sys — deben existir tras las migraciones
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — tablas sys de gestión de tenants", () => {
  const requiredSysTables = [
    { schema: "sys", table: "TenantDatabase" },
    { schema: "sys", table: "License" },
    { schema: "sys", table: "TenantBackup" },
    { schema: "sys", table: "TenantResourceLog" },
    { schema: "sys", table: "CleanupQueue" },
    { schema: "cfg", table: "Company" },
  ];

  for (const { schema, table } of requiredSysTables) {
    it(`tabla ${schema}."${table}" debe existir`, async () => {
      const res = await pool.query<{ exists: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_schema = $1 AND table_name = $2
         ) AS exists`,
        [schema, table],
      );
      expect(
        res.rows[0]?.exists,
        `La tabla ${schema}."${table}" no existe — revisar migraciones goose`,
      ).toBe(true);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Test 10: Reporte de inconsistencias TIMESTAMPTZ (informativo, siempre pasa)
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts — reporte TIMESTAMPTZ (informativo)", () => {
  it("imprime funciones con timestamp with time zone como reporte informativo", async () => {
    const res = await pool.query<{
      proname: string;
      args: string;
      ret: string;
    }>(
      `SELECT p.proname,
              pg_get_function_arguments(p.oid) AS args,
              pg_get_function_result(p.oid)    AS ret
       FROM pg_proc p
       WHERE p.proname LIKE 'usp_%'
         AND (
           pg_get_function_arguments(p.oid) ILIKE '%timestamp with time zone%'
           OR pg_get_function_result(p.oid) ILIKE '%timestamp with time zone%'
         )
       ORDER BY p.proname`,
    );

    if (res.rows.length === 0) {
      console.log(
        "\n[SP Contracts] Reporte TIMESTAMPTZ: sin inconsistencias detectadas.",
      );
    } else {
      console.log(
        `\n[SP Contracts] Reporte TIMESTAMPTZ — ${res.rows.length} función(es) con TIMESTAMP WITH TIME ZONE:`,
      );
      console.log(
        `  ${"FUNCIÓN".padEnd(50)} ${"ARGS (fragmento)".padEnd(60)} RETORNO`,
      );
      console.log(`  ${"-".repeat(130)}`);
      for (const row of res.rows) {
        // Trunca cadenas largas para legibilidad en consola
        const argStr =
          (row.args ?? "").length > 58
            ? (row.args ?? "").slice(0, 55) + "..."
            : (row.args ?? "");
        const retStr =
          (row.ret ?? "").length > 40
            ? (row.ret ?? "").slice(0, 37) + "..."
            : (row.ret ?? "");
        console.log(
          `  ${row.proname.padEnd(50)} ${argStr.padEnd(60)} ${retStr}`,
        );
      }
      console.log("");
    }

    // Siempre pasa — es solo informativo
    expect(true).toBe(true);
  });
});
