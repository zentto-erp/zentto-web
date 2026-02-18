import { execute, query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import {
  getMetadata,
  getTableMetadata,
  quoteIdent,
  safeQualifiedTable,
  type TableMetadata
} from "./metadata.js";

function validPage(value: unknown, fallback: number) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.floor(n);
}

function parseSort(meta: TableMetadata, sort?: string) {
  if (!sort) return meta.primaryKeys[0] ?? meta.columns[0]?.columnName ?? "";
  const clean = sort.replace(/^-/, "");
  const exists = meta.columns.some((c) => c.columnName.toLowerCase() === clean.toLowerCase());
  if (!exists) return meta.primaryKeys[0] ?? meta.columns[0]?.columnName ?? "";
  return meta.columns.find((c) => c.columnName.toLowerCase() === clean.toLowerCase())!.columnName;
}

export async function listTables() {
  const rows = await getMetadata();
  return rows.map((r) => ({
    schema: r.schema,
    table: r.table,
    fullName: r.fullName,
    primaryKeys: r.primaryKeys,
    columns: r.columns.length
  }));
}

export async function describeTable(schema: string, table: string) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) return null;
  return meta;
}

export async function queryTable(input: {
  schema: string;
  table: string;
  page?: number;
  pageSize?: number;
  sort?: string;
  desc?: boolean;
  filters?: Record<string, unknown>;
}) {
  const meta = await getTableMetadata(input.schema, input.table);
  if (!meta) {
    throw new Error("table_not_found");
  }

  const page = validPage(input.page, 1);
  const pageSize = Math.min(validPage(input.pageSize, 50), 500);
  const offset = (page - 1) * pageSize;

  const whereParts: string[] = [];
  const params: Record<string, unknown> = {};

  if (input.filters) {
    for (const [key, value] of Object.entries(input.filters)) {
      const col = meta.columns.find((c) => c.columnName.toLowerCase() === key.toLowerCase());
      if (!col) continue;
      const paramName = `f_${col.columnName}`;
      whereParts.push(`${quoteIdent(col.columnName)} = @${paramName}`);
      params[paramName] = value;
    }
  }

  const whereClause = whereParts.length ? `WHERE ${whereParts.join(" AND ")}` : "";
  const sortCol = parseSort(meta, input.sort);
  const direction = input.desc ? "DESC" : "ASC";
  const tableName = safeQualifiedTable(meta.schema, meta.table);

  const rows = await query<any>(
    `SELECT * FROM ${tableName} ${whereClause} ORDER BY ${quoteIdent(sortCol)} ${direction} OFFSET ${offset} ROWS FETCH NEXT ${pageSize} ROWS ONLY`,
    params
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM ${tableName} ${whereClause}`,
    params
  );

  return {
    schema: meta.schema,
    table: meta.table,
    page,
    pageSize,
    total: Number(totalRows[0]?.total ?? 0),
    rows
  };
}

function decodeKey(meta: TableMetadata, keyEncoded: string) {
  let parsed: Record<string, unknown>;
  try {
    const raw = Buffer.from(keyEncoded, "base64url").toString("utf8");
    parsed = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    throw new Error("invalid_key");
  }

  if (meta.primaryKeys.length === 0) {
    throw new Error("table_without_pk");
  }

  for (const pk of meta.primaryKeys) {
    const exists = Object.keys(parsed).some((k) => k.toLowerCase() === pk.toLowerCase());
    if (!exists) {
      throw new Error(`missing_pk_${pk}`);
    }
  }

  const normalized: Record<string, unknown> = {};
  for (const pk of meta.primaryKeys) {
    const entry = Object.entries(parsed).find(([k]) => k.toLowerCase() === pk.toLowerCase());
    normalized[pk] = entry?.[1];
  }

  return normalized;
}

function whereByPk(meta: TableMetadata, key: Record<string, unknown>) {
  const parts: string[] = [];
  const params: Record<string, unknown> = {};

  for (const pk of meta.primaryKeys) {
    const paramName = `pk_${pk}`;
    parts.push(`${quoteIdent(pk)} = @${paramName}`);
    params[paramName] = key[pk];
  }

  return {
    clause: parts.join(" AND "),
    params
  };
}

export async function getByKey(schema: string, table: string, encodedKey: string) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);
  const where = whereByPk(meta, key);

  const tableName = safeQualifiedTable(meta.schema, meta.table);
  const rows = await query<any>(
    `SELECT * FROM ${tableName} WHERE ${where.clause}`,
    where.params
  );

  return rows[0] ?? null;
}

function writableColumns(meta: TableMetadata) {
  return meta.columns.filter((c) => !c.isComputed && !c.isRowVersion && !c.isIdentity);
}

export async function createRow(schema: string, table: string, body: Record<string, unknown>) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const writable = writableColumns(meta);
  const data: Array<{ column: string; value: unknown }> = [];

  for (const col of writable) {
    const found = Object.entries(body).find(([k]) => k.toLowerCase() === col.columnName.toLowerCase());
    if (found) {
      data.push({ column: col.columnName, value: found[1] });
    }
  }

  if (data.length === 0) {
    throw new Error("no_writable_fields");
  }

  const cols = data.map((d) => quoteIdent(d.column)).join(", ");
  const vals = data.map((d) => `@c_${d.column}`).join(", ");
  const params: Record<string, unknown> = {};
  for (const d of data) {
    params[`c_${d.column}`] = d.value;
  }

  const tableName = safeQualifiedTable(meta.schema, meta.table);
  await execute(`INSERT INTO ${tableName} (${cols}) VALUES (${vals})`, params);

  return { ok: true };
}

export async function updateRow(schema: string, table: string, encodedKey: string, body: Record<string, unknown>) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);
  const where = whereByPk(meta, key);

  const writable = writableColumns(meta);
  const setParts: string[] = [];
  const params: Record<string, unknown> = { ...where.params };

  for (const col of writable) {
    const found = Object.entries(body).find(([k]) => k.toLowerCase() === col.columnName.toLowerCase());
    if (!found) continue;
    const paramName = `u_${col.columnName}`;
    setParts.push(`${quoteIdent(col.columnName)} = @${paramName}`);
    params[paramName] = found[1];
  }

  if (setParts.length === 0) {
    throw new Error("no_writable_fields");
  }

  const tableName = safeQualifiedTable(meta.schema, meta.table);
  const result = await execute(
    `UPDATE ${tableName} SET ${setParts.join(", ")} WHERE ${where.clause}`,
    params
  );

  return { ok: true, rowsAffected: result.rowsAffected?.[0] ?? 0 };
}

export async function deleteRow(schema: string, table: string, encodedKey: string) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);
  const where = whereByPk(meta, key);
  const tableName = safeQualifiedTable(meta.schema, meta.table);

  const result = await execute(
    `DELETE FROM ${tableName} WHERE ${where.clause}`,
    where.params
  );

  return { ok: true, rowsAffected: result.rowsAffected?.[0] ?? 0 };
}

export function encodeKeyObject(key: Record<string, unknown>) {
  return Buffer.from(JSON.stringify(key), "utf8").toString("base64url");
}


const MASTER_TABLE_ALLOWLIST = new Set([
  "CORRELATIVOS",
  "LINEAS",
  "CATEGORIAS",
  "MARCAS",
  "BANCOS",
  "CAJAS",
  "ALMACENES",
  "UNIDADES",
  "TIPODOCUMENTO"
]);

function escapeXml(value: unknown) {
  const s = String(value ?? "");
  return s
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/'/g, "&apos;");
}

function recordToXml(tag: string, row: Record<string, unknown>) {
  const attrs = Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escapeXml(v)}"`)
    .join(" ");
  return `<${tag} ${attrs} />`;
}

export async function executeMasterCrudAction(input: {
  schema: string;
  table: string;
  action: "insert" | "update" | "delete" | "list";
  row?: Record<string, unknown>;
  key?: Record<string, unknown>;
  page?: number;
  pageSize?: number;
}) {
  const table = input.table.trim();
  if (!MASTER_TABLE_ALLOWLIST.has(table.toUpperCase())) {
    throw new Error("master_table_not_allowed");
  }

  const action = input.action;
  const pool = await getPool();

  const spCandidates =
    action === "list"
      ? [`usp_${table}_List`, `sp_${table}_List`]
      : [`usp_${table}_${action[0].toUpperCase()}${action.slice(1)}`, `sp_${table}_${action[0].toUpperCase()}${action.slice(1)}`];

  for (const spName of spCandidates) {
    try {
      const req = pool.request();
      req.input("SchemaName", sql.NVarChar(128), input.schema || "dbo");
      req.input("TableName", sql.NVarChar(128), table);
      if (input.row) req.input("RowXml", sql.NVarChar(sql.MAX), recordToXml("row", input.row));
      if (input.key) req.input("KeyXml", sql.NVarChar(sql.MAX), recordToXml("key", input.key));
      if (input.page) req.input("Page", sql.Int, input.page);
      if (input.pageSize) req.input("PageSize", sql.Int, input.pageSize);

      const result = await req.execute(spName);
      return { ok: true, executionMode: "sp", spName, rows: result.recordset ?? [] };
    } catch {
      // fallback to generic CRUD below
    }
  }

  if (action === "insert") {
    await createRow(input.schema, table, input.row ?? {});
    return { ok: true, executionMode: "ts_fallback" };
  }
  if (action === "update") {
    const key = input.key ?? {};
    await updateRow(input.schema, table, encodeKeyObject(key), input.row ?? {});
    return { ok: true, executionMode: "ts_fallback" };
  }
  if (action === "delete") {
    const key = input.key ?? {};
    await deleteRow(input.schema, table, encodeKeyObject(key));
    return { ok: true, executionMode: "ts_fallback" };
  }

  return queryTable({
    schema: input.schema,
    table,
    page: input.page,
    pageSize: input.pageSize
  });
}
