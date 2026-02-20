import { query } from "../../db/query.js";
import {
  createRow,
  deleteRow,
  encodeKeyObject,
  getByKey,
  updateRow,
} from "../crud/crud.service.js";
import { getTableMetadata, quoteIdent, safeQualifiedTable, type TableMetadata } from "../crud/metadata.js";

type MasterTableConfig = {
  schema: string;
  table: string;
};

export const MASTER_TABLES: Record<string, MasterTableConfig> = {
  correlativo: { schema: "dbo", table: "Correlativo" },
  empresa: { schema: "dbo", table: "Empresa" },
  feriados: { schema: "dbo", table: "Feriados" },
  moneda: { schema: "dbo", table: "Moneda" },
  monedas: { schema: "dbo", table: "Monedas" },
  "tasa-moneda": { schema: "dbo", table: "Tasa_moneda" },
  reportes: { schema: "dbo", table: "QueryReport" },
  "query-reporte": { schema: "dbo", table: "QueryReporte" },
  reportez: { schema: "dbo", table: "ReporteZ" },
  "linea-proveedores": { schema: "dbo", table: "Linea_proveedores" },
};

const STRING_TYPES = new Set([
  "varchar",
  "nvarchar",
  "char",
  "nchar",
  "text",
  "ntext",
]);

function validPage(value: unknown, fallback: number) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.floor(n);
}

function getSortColumn(meta: TableMetadata) {
  return meta.primaryKeys[0] ?? meta.columns[0]?.columnName ?? "";
}

function resolveMasterTable(slug: string): MasterTableConfig | null {
  const key = slug.trim().toLowerCase();
  return MASTER_TABLES[key] ?? null;
}

export function listMasterTables() {
  return Object.entries(MASTER_TABLES).map(([slug, config]) => ({
    slug,
    schema: config.schema,
    table: config.table,
  }));
}

function pkValueFromRaw(meta: TableMetadata, rawKey: string): Record<string, unknown> {
  if (!meta.primaryKeys.length) {
    throw new Error("table_without_pk");
  }
  if (meta.primaryKeys.length > 1) {
    throw new Error("composite_pk_not_supported");
  }
  const pk = meta.primaryKeys[0];
  const pkCol = meta.columns.find((c) => c.columnName.toLowerCase() === pk.toLowerCase());
  const raw = decodeURIComponent(rawKey);

  if (pkCol && ["int", "bigint", "smallint", "tinyint", "decimal", "numeric", "float", "real", "money", "smallmoney"].includes(pkCol.dataType.toLowerCase())) {
    const n = Number(raw);
    if (!Number.isFinite(n)) throw new Error("invalid_pk_value");
    return { [pk]: n };
  }

  return { [pk]: raw };
}

export async function listMaestroRows(slug: string, params: { search?: string; page?: number; limit?: number }) {
  const config = resolveMasterTable(slug);
  if (!config) throw new Error("master_table_not_allowed");

  const meta = await getTableMetadata(config.schema, config.table);
  if (!meta) throw new Error("table_not_found");

  const page = validPage(params.page, 1);
  const limit = Math.min(validPage(params.limit, 50), 500);
  const offset = (page - 1) * limit;

  const whereParts: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  const search = (params.search || "").trim();

  if (search.length > 0) {
    const stringColumns = meta.columns
      .filter((c) => !c.isComputed && !c.isRowVersion)
      .filter((c) => STRING_TYPES.has(c.dataType.toLowerCase()));
    if (stringColumns.length > 0) {
      const likeParts = stringColumns.map((c) => `${quoteIdent(c.columnName)} LIKE @search`);
      whereParts.push(`(${likeParts.join(" OR ")})`);
      sqlParams.search = `%${search}%`;
    }
  }

  const whereClause = whereParts.length > 0 ? `WHERE ${whereParts.join(" AND ")}` : "";
  const sortColumn = getSortColumn(meta);
  const tableName = safeQualifiedTable(meta.schema, meta.table);

  const rows = await query<any>(
    `SELECT * FROM ${tableName} ${whereClause} ORDER BY ${quoteIdent(sortColumn)} ASC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );
  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM ${tableName} ${whereClause}`,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
    table: meta.table,
  };
}

export async function getMaestroRow(slug: string, rawKey: string) {
  const config = resolveMasterTable(slug);
  if (!config) throw new Error("master_table_not_allowed");

  const meta = await getTableMetadata(config.schema, config.table);
  if (!meta) throw new Error("table_not_found");

  const pkValue = pkValueFromRaw(meta, rawKey);
  const encoded = encodeKeyObject(pkValue);
  return getByKey(config.schema, config.table, encoded);
}

export async function createMaestroRow(slug: string, body: Record<string, unknown>) {
  const config = resolveMasterTable(slug);
  if (!config) throw new Error("master_table_not_allowed");
  return createRow(config.schema, config.table, body);
}

export async function updateMaestroRow(slug: string, rawKey: string, body: Record<string, unknown>) {
  const config = resolveMasterTable(slug);
  if (!config) throw new Error("master_table_not_allowed");

  const meta = await getTableMetadata(config.schema, config.table);
  if (!meta) throw new Error("table_not_found");

  const pkValue = pkValueFromRaw(meta, rawKey);
  const encoded = encodeKeyObject(pkValue);
  return updateRow(config.schema, config.table, encoded, body);
}

export async function deleteMaestroRow(slug: string, rawKey: string) {
  const config = resolveMasterTable(slug);
  if (!config) throw new Error("master_table_not_allowed");

  const meta = await getTableMetadata(config.schema, config.table);
  if (!meta) throw new Error("table_not_found");

  const pkValue = pkValueFromRaw(meta, rawKey);
  const encoded = encodeKeyObject(pkValue);
  return deleteRow(config.schema, config.table, encoded);
}
