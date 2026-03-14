import { callSpOut, sql } from "../../db/query.js";
import {
  createRow,
  deleteRow,
  encodeKeyObject,
  getByKey,
  updateRow,
} from "../crud/crud.service.js";
import { getTableMetadata, type TableMetadata } from "../crud/metadata.js";

type MasterTableConfig = {
  schema: string;
  table: string;
};

export const MASTER_TABLES: Record<string, MasterTableConfig> = {
  correlativo: { schema: "cfg", table: "DocumentSequence" },
  empresa: { schema: "cfg", table: "CompanyProfile" },
  feriados: { schema: "cfg", table: "Holiday" },
  moneda: { schema: "cfg", table: "Currency" },
  monedas: { schema: "cfg", table: "Currency" },
  "tasa-moneda": { schema: "cfg", table: "ExchangeRateDaily" },
  reportes: { schema: "cfg", table: "ReportTemplate" },
  "query-reporte": { schema: "cfg", table: "ReportTemplate" },
  reportez: { schema: "cfg", table: "ReportTemplate" },
  "linea-proveedores": { schema: "master", table: "SupplierLine" },
};

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
  const sortColumn = getSortColumn(meta);

  const { rows, output } = await callSpOut<any>(
    'usp_Master_Generic_List',
    {
      SchemaName: config.schema,
      TableName: config.table,
      Search: params.search || null,
      SortColumn: sortColumn,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
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
