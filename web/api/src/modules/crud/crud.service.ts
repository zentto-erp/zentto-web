import { callSp, callSpOut, sql } from "../../db/query.js";
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
  const sortCol = parseSort(meta, input.sort);
  const direction = input.desc ? "DESC" : "ASC";

  // Build filters JSON (excluding _search which is handled differently)
  const filtersJson: Record<string, unknown> = {};
  const searchValue = input.filters?._search as string | undefined;
  if (input.filters) {
    for (const [key, value] of Object.entries(input.filters)) {
      if (key === '_search') continue;
      const col = meta.columns.find((c) => c.columnName.toLowerCase() === key.toLowerCase());
      if (!col) continue;
      filtersJson[col.columnName] = value;
    }
  }

  const hasFilters = Object.keys(filtersJson).length > 0;

  // Use callSpOut to get both data rows and TotalCount OUTPUT parameter
  const { rows: dataRows, output } = await callSpOut<any>(
    'usp_Sys_GenericList',
    {
      SchemaName: meta.schema,
      TableName: meta.table,
      SortColumn: sortCol,
      SortDir: direction,
      Offset: offset,
      PageSize: pageSize,
      FiltersJson: hasFilters ? JSON.stringify(filtersJson) : null,
    },
    { TotalCount: sql.Int }
  );

  const total = Number(output.TotalCount ?? 0);

  return {
    schema: meta.schema,
    table: meta.table,
    page,
    pageSize,
    total,
    rows: dataRows
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

export async function getByKey(schema: string, table: string, encodedKey: string) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);
  const keyJson = JSON.stringify(key);

  const rows = await callSp<any>('usp_Sys_GenericGetByKey', {
    SchemaName: meta.schema,
    TableName: meta.table,
    KeyJson: keyJson,
  });

  return rows[0] ?? null;
}

function writableColumns(meta: TableMetadata) {
  return meta.columns.filter((c) => !c.isComputed && !c.isRowVersion && !c.isIdentity);
}

export async function createRow(schema: string, table: string, body: Record<string, unknown>) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const writable = writableColumns(meta);
  const data: Record<string, unknown> = {};

  for (const col of writable) {
    const found = Object.entries(body).find(([k]) => k.toLowerCase() === col.columnName.toLowerCase());
    if (found) {
      data[col.columnName] = found[1];
    }
  }

  if (Object.keys(data).length === 0) {
    throw new Error("no_writable_fields");
  }

  await callSp('usp_Sys_GenericInsert', {
    SchemaName: meta.schema,
    TableName: meta.table,
    DataJson: JSON.stringify(data),
  });

  return { ok: true };
}

export async function updateRow(schema: string, table: string, encodedKey: string, body: Record<string, unknown>) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);
  const writable = writableColumns(meta);
  const data: Record<string, unknown> = {};

  for (const col of writable) {
    const found = Object.entries(body).find(([k]) => k.toLowerCase() === col.columnName.toLowerCase());
    if (!found) continue;
    data[col.columnName] = found[1];
  }

  if (Object.keys(data).length === 0) {
    throw new Error("no_writable_fields");
  }

  const result = await callSp<{ rowsAffected: number }>('usp_Sys_GenericUpdate', {
    SchemaName: meta.schema,
    TableName: meta.table,
    KeyJson: JSON.stringify(key),
    DataJson: JSON.stringify(data),
  });

  return { ok: true, rowsAffected: Number(result[0]?.rowsAffected ?? 0) };
}

export async function deleteRow(schema: string, table: string, encodedKey: string) {
  const meta = await getTableMetadata(schema, table);
  if (!meta) throw new Error("table_not_found");

  const key = decodeKey(meta, encodedKey);

  const result = await callSp<{ rowsAffected: number }>('usp_Sys_GenericDelete', {
    SchemaName: meta.schema,
    TableName: meta.table,
    KeyJson: JSON.stringify(key),
  });

  return { ok: true, rowsAffected: Number(result[0]?.rowsAffected ?? 0) };
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

  const spCandidates =
    action === "list"
      ? [`usp_${table}_List`, `sp_${table}_List`]
      : [`usp_${table}_${action[0].toUpperCase()}${action.slice(1)}`, `sp_${table}_${action[0].toUpperCase()}${action.slice(1)}`];

  for (const spName of spCandidates) {
    try {
      const rows = await callSp<any>(spName, {
        SchemaName: input.schema || "dbo",
        TableName: table,
        RowXml: input.row ? recordToXml("row", input.row) : undefined,
        KeyXml: input.key ? recordToXml("key", input.key) : undefined,
        Page: input.page,
        PageSize: input.pageSize,
      });
      return { ok: true, executionMode: "sp", spName, rows };
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
