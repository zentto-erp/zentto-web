import { callSp } from "../../db/query.js";

export type TableColumn = {
  columnName: string;
  dataType: string;
  isNullable: boolean;
  isIdentity: boolean;
  isComputed: boolean;
  isRowVersion: boolean;
};

export type TableMetadata = {
  schema: string;
  table: string;
  fullName: string;
  primaryKeys: string[];
  columns: TableColumn[];
};

type TableRow = {
  TABLE_SCHEMA: string;
  TABLE_NAME: string;
};

type ColumnRow = {
  TABLE_SCHEMA: string;
  TABLE_NAME: string;
  COLUMN_NAME: string;
  DATA_TYPE: string;
  IS_NULLABLE: "YES" | "NO";
  is_identity: number;
  is_computed: number;
};

type PkRow = {
  TABLE_SCHEMA: string;
  TABLE_NAME: string;
  COLUMN_NAME: string;
  ORDINAL_POSITION: number;
};

let cache: TableMetadata[] | null = null;
let cacheAt = 0;
const CACHE_TTL_MS = 60_000;

function normalizeColumnName(name: string) {
  return name.replace(/[\s_]/g, "").toLowerCase();
}

function isExcludedMetadataColumn(name: string) {
  return normalizeColumnName(name) === "upsizets";
}

export async function getMetadata(force = false): Promise<TableMetadata[]> {
  const now = Date.now();
  if (!force && cache && now - cacheAt < CACHE_TTL_MS) {
    return cache;
  }

  const tables = await callSp<TableRow>("usp_Sys_Metadata_Tables");

  const columns = await callSp<ColumnRow>("usp_Sys_Metadata_Columns");

  const pks = await callSp<PkRow>("usp_Sys_Metadata_PrimaryKeys");

  const pkMap = new Map<string, string[]>();
  for (const pk of pks) {
    const key = `${pk.TABLE_SCHEMA}.${pk.TABLE_NAME}`;
    const arr = pkMap.get(key) ?? [];
    arr.push(pk.COLUMN_NAME);
    pkMap.set(key, arr);
  }

  const colMap = new Map<string, TableColumn[]>();
  for (const col of columns) {
    if (isExcludedMetadataColumn(col.COLUMN_NAME)) continue;
    const key = `${col.TABLE_SCHEMA}.${col.TABLE_NAME}`;
    const arr = colMap.get(key) ?? [];
    arr.push({
      columnName: col.COLUMN_NAME,
      dataType: col.DATA_TYPE,
      isNullable: col.IS_NULLABLE === "YES",
      isIdentity: col.is_identity === 1,
      isComputed: col.is_computed === 1,
      isRowVersion: col.DATA_TYPE.toLowerCase() === "timestamp" || col.DATA_TYPE.toLowerCase() === "rowversion"
    });
    colMap.set(key, arr);
  }

  cache = tables.map((t: TableRow) => {
    const key = `${t.TABLE_SCHEMA}.${t.TABLE_NAME}`;
    return {
      schema: t.TABLE_SCHEMA,
      table: t.TABLE_NAME,
      fullName: key,
      primaryKeys: pkMap.get(key) ?? [],
      columns: colMap.get(key) ?? []
    };
  });

  cacheAt = now;
  return cache ?? [];
}

export async function getTableMetadata(schema: string, table: string) {
  let all: TableMetadata[];
  try {
    all = await getMetadata();
  } catch {
    return null;
  }
  const exact = all.find((m) => m.schema === schema && m.table.toLowerCase() === table.toLowerCase());
  if (exact) return exact;
  // "dbo" is the SQL Server default schema — in PostgreSQL, fall back to table-name-only search
  if (schema === "dbo" || schema === "") {
    return all.find((m) => m.table.toLowerCase() === table.toLowerCase()) ?? null;
  }
  return null;
}

export function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
}

export function safeQualifiedTable(schema: string, table: string) {
  return `${quoteIdent(schema)}.${quoteIdent(table)}`;
}

export function clearMetadataCache() {
  cache = null;
  cacheAt = 0;
}
