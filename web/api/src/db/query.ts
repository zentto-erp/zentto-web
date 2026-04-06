/**
 * query.ts — Capa de abstracción BD
 *
 * Conmuta entre SQL Server (mssql) y PostgreSQL (pg) según DB_TYPE en .env.
 * La API es 100% idéntica para el código de negocio:
 *   callSp / callSpOut / callSpTx / query / execute
 */

import { env } from "../config/env.js";
import { sql, getPool } from "./mssql.js";
import { getPgPool } from "./pg.js";
import { getTenantPoolFromContext } from "../context/request-context.js";

/** Pool del tenant actual (context) o default pool (fallback seguro) */
function getActivePgPool() {
  return getTenantPoolFromContext() ?? getPgPool();
}
import { xmlParamToJson } from "../utils/xml.js";

// ── Utilidades de conversión de nombres ───────────────────────────────────────

/**
 * PascalCase → p_snake_case  (respeta acrónimos)
 * CompanyId   → p_company_id
 * TasaUSD     → p_tasa_usd      (USD no se parte en u_s_d)
 * TemplateCode → p_template_code
 * XMLData     → p_xml_data
 */
function toSnakeParam(key: string): string {
  const snake = key
    // 1. Insertar _ entre letra minúscula y mayúscula: "CompanyId" → "Company_Id"
    .replace(/([a-z])([A-Z])/g, "$1_$2")
    // 2. Insertar _ entre secuencia de mayúsculas y mayúscula+minúscula: "XMLData" → "XML_Data"
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1_$2")
    .toLowerCase()
    .replace(/^_/, "");
  return `p_${snake}`;
}

/**
 * p_snake_case → PascalCase
 * p_company_id → CompanyId
 * p_template_code → TemplateCode
 */
function toPascalKey(col: string): string {
  const stripped = col.startsWith("p_") ? col.slice(2) : col;
  return stripped
    .split("_")
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
    .join("");
}

/**
 * Normaliza una fila PG: convierte snake_case / p_snake → PascalCase.
 *
 * Regla: solo normaliza si la columna es todo-minúsculas (snake_case real)
 * o tiene prefijo p_.  Columnas con mezcla de mayúsculas (ej. Cod_Usuario,
 * UserCode) se dejan intactas — ya están en el formato que espera el código.
 */
function normalizePgRow(row: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    const needsNormalize =
      k.startsWith("p_") ||
      (k === k.toLowerCase() && k.includes("_"));
    out[needsNormalize ? toPascalKey(k) : k] = v;
  }
  return out;
}

// ── Adaptación de parámetros XML → JSON para PostgreSQL ──────────────────────

/**
 * SQL Server 2012 usa XML para pasar datos complejos (*Xml params).
 * PostgreSQL usa JSON (*Json params).
 *
 * Esta función convierte automáticamente:
 *   { HeaderXml: '<row Key="v"/>' }  →  { HeaderJson: '{"Key":"v"}' }
 *   { DetailsXml: '<root>...</root>' } → { DetailsJson: '[{...}]' }
 *
 * Los servicios NO necesitan saber qué motor está activo.
 */
function adaptParamsForPg(
  inputs: Record<string, unknown> | undefined
): Record<string, unknown> | undefined {
  if (!inputs) return inputs;
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(inputs)) {
    if (key.endsWith("Xml")) {
      // Renombrar *Xml → *Json, convertir XML → JSON string (o null si valor es null/undefined)
      const jsonKey = key.slice(0, -3) + "Json";
      out[jsonKey] = (typeof value === "string") ? xmlParamToJson(value) : null;
    } else {
      out[key] = value;
    }
  }
  return out;
}

// ── Implementación PostgreSQL ─────────────────────────────────────────────────

async function pgCallSp<T>(
  spName: string,
  inputs?: Record<string, unknown>
): Promise<T[]> {
  const pool = getActivePgPool();

  // Construir: SELECT * FROM spName(p_key1 => $1, p_key2 => $2, ...)
  const adapted = adaptParamsForPg(inputs);
  const entries = adapted ? Object.entries(adapted).filter(([, v]) => v !== undefined) : [];
  const namedArgs = entries
    .map(([key, _], i) => `${toSnakeParam(key)} => $${i + 1}`)
    .join(", ");
  const values = entries.map(([, v]) => v);

  // Strip dbo. prefix: PG no tiene schema dbo, funciones viven en public
  const pgName = spName.replace(/^dbo\./i, '');
  // Sin comillas dobles: PG auto-lowercase el nombre → compatible con callSp('usp_Foo_Bar', ...)
  const sql_text = `SELECT * FROM ${pgName}(${namedArgs})`;

  const result = await pool.query(sql_text, values);
  return result.rows.map(normalizePgRow) as T[];
}

async function pgCallSpOut<T>(
  spName: string,
  inputs?: Record<string, unknown>,
  outputs?: Record<string, unknown>
): Promise<{ rows: T[]; output: Record<string, unknown>; rowsAffected: number[] }> {
  const pool = getActivePgPool();

  const adapted = adaptParamsForPg(inputs);
  const entries = adapted ? Object.entries(adapted).filter(([, v]) => v !== undefined) : [];
  const namedArgs = entries
    .map(([key, _], i) => `${toSnakeParam(key)} => $${i + 1}`)
    .join(", ");
  const values = entries.map(([, v]) => v);

  const pgName = spName.replace(/^dbo\./i, '');
  const sql_text = `SELECT * FROM ${pgName}(${namedArgs})`;

  const result = await pool.query(sql_text, values);
  const firstRow = result.rows[0] ?? {};

  // Las columnas OUT del resultado PG vienen como p_resultado, p_mensaje, etc.
  // Las normalizamos a PascalCase para compatibilidad con el código existente.
  const normalizedRow = normalizePgRow(firstRow as Record<string, unknown>);

  // Separar output params (los que declaró el caller como outputs)
  // Alias map: SQL Server usa Resultado/Mensaje como OUTPUT params,
  // pero las funciones PG retornan ok/mensaje como columnas de TABLE.
  const PG_OUTPUT_ALIASES: Record<string, string[]> = {
    Resultado: ["ok"],
    Mensaje:   ["mensaje"],
  };

  const outputRecord: Record<string, unknown> = {};
  if (outputs) {
    for (const key of Object.keys(outputs)) {
      let val = normalizedRow[key] ?? firstRow[toSnakeParam(key)] ?? undefined;
      // Si no encontramos el valor, buscar aliases PG conocidos
      if (val === undefined) {
        const aliases = PG_OUTPUT_ALIASES[key];
        if (aliases) {
          for (const alias of aliases) {
            val = normalizedRow[alias] ?? firstRow[alias] ?? undefined;
            if (val !== undefined) break;
          }
        }
      }
      outputRecord[key] = val ?? null;
    }
  }

  // El resto de columnas son el recordset de datos
  const rows = result.rows.map(normalizePgRow) as T[];

  return {
    rows,
    output: outputRecord,
    rowsAffected: [result.rowCount ?? 0],
  };
}

// ── API pública (idéntica para ambos motores) ─────────────────────────────────

const usePg = () => env.dbType === "postgres";

/**
 * Ejecuta un stored procedure / función y retorna el recordset.
 */
export async function callSp<T>(
  spName: string,
  inputs?: Record<string, unknown>
): Promise<T[]> {
  if (usePg()) return pgCallSp<T>(spName, inputs);

  // SQL Server
  const pool = await getPool();
  const request = pool.request();
  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }
  const result = await request.execute<T>(spName);
  return result.recordset;
}

/**
 * Ejecuta un SP con parámetros OUTPUT.
 * Los callers acceden a output.Resultado, output.Mensaje (PascalCase — mismo para ambos motores).
 */
export async function callSpOut<T>(
  spName: string,
  inputs?: Record<string, unknown>,
  outputs?: Record<string, any>
): Promise<{ rows: T[]; output: Record<string, unknown>; rowsAffected: number[] }> {
  if (usePg()) return pgCallSpOut<T>(spName, inputs, outputs);

  // SQL Server
  const pool = await getPool();
  const request = pool.request();
  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }
  if (outputs) {
    for (const [key, sqlType] of Object.entries(outputs)) {
      request.output(key, sqlType);
    }
  }
  const result = await request.execute<T>(spName);
  return {
    rows: result.recordset,
    output: result.output,
    rowsAffected: result.rowsAffected,
  };
}

/**
 * Ejecuta un SP dentro de una transacción MSSQL.
 * En modo PG usa el pool directamente (las funciones PG son transaccionales por diseño).
 */
export async function callSpTx<T>(
  tx: sql.Transaction | null,
  spName: string,
  inputs?: Record<string, unknown>
): Promise<T[]> {
  if (usePg()) return pgCallSp<T>(spName, inputs);

  // SQL Server
  const request = tx ? new sql.Request(tx as sql.Transaction) : (await getPool()).request();
  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }
  const result = await request.execute<T>(spName);
  return result.recordset;
}

/**
 * Ejecuta SQL directo parametrizado.
 * ⚠️  En modo PG, reemplaza @Param → $N automáticamente.
 */
export async function query<T>(
  statement: string,
  params?: Record<string, unknown>
): Promise<T[]> {
  if (usePg()) {
    const pool = getActivePgPool();
    const entries = params ? Object.entries(params) : [];
    // Reemplazar @ParamName → $1, $2, ... en orden de aparición
    let pg_sql = statement;
    const values: unknown[] = [];
    for (const [key, value] of entries) {
      const idx = values.length + 1;
      pg_sql = pg_sql.replace(new RegExp(`@${key}\\b`, "g"), `$${idx}`);
      values.push(value);
    }
    const result = await pool.query(pg_sql, values);
    return result.rows.map(normalizePgRow) as T[];
  }

  // SQL Server
  const pool = await getPool();
  const request = pool.request();
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      request.input(key, value as any);
    }
  }
  const result = await request.query<T>(statement);
  return result.recordset;
}

/**
 * Ejecuta SQL directo y retorna rowsAffected + recordset.
 */
export async function execute(
  statement: string,
  params?: Record<string, unknown>
): Promise<{ rowsAffected: number[]; recordset: unknown[] }> {
  if (usePg()) {
    const pool = getActivePgPool();
    const entries = params ? Object.entries(params) : [];
    let pg_sql = statement;
    const values: unknown[] = [];
    for (const [key, value] of entries) {
      const idx = values.length + 1;
      pg_sql = pg_sql.replace(new RegExp(`@${key}\\b`, "g"), `$${idx}`);
      values.push(value);
    }
    const result = await pool.query(pg_sql, values);
    return {
      rowsAffected: [result.rowCount ?? 0],
      recordset: (result.rows ?? []).map(normalizePgRow),
    };
  }

  // SQL Server
  const pool = await getPool();
  const request = pool.request();
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      request.input(key, value as any);
    }
  }
  const result = await request.query(statement);
  return {
    rowsAffected: result.rowsAffected,
    recordset: result.recordset,
  };
}

// Re-exportar sql para que el código que usa `sql.Int`, `sql.NVarChar` etc. no se rompa
export { sql };
export { getPool };
