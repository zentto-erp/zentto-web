import { query } from "../../db/query.js";

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

export async function getMetadata(force = false): Promise<TableMetadata[]> {
  const now = Date.now();
  if (!force && cache && now - cacheAt < CACHE_TTL_MS) {
    return cache;
  }

  const tables = await query<TableRow>(`
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME
  `);

  const columns = await query<ColumnRow>(`
    SELECT
      c.TABLE_SCHEMA,
      c.TABLE_NAME,
      c.COLUMN_NAME,
      c.DATA_TYPE,
      c.IS_NULLABLE,
      CONVERT(int, COLUMNPROPERTY(OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity')) AS is_identity,
      CONVERT(int, COLUMNPROPERTY(OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), c.COLUMN_NAME, 'IsComputed')) AS is_computed
    FROM INFORMATION_SCHEMA.COLUMNS c
    ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME, c.ORDINAL_POSITION
  `);

  const pks = await query<PkRow>(`
    SELECT
      ku.TABLE_SCHEMA,
      ku.TABLE_NAME,
      ku.COLUMN_NAME,
      ku.ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku
      ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
      AND tc.TABLE_SCHEMA = ku.TABLE_SCHEMA
      AND tc.TABLE_NAME = ku.TABLE_NAME
    WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
    ORDER BY ku.TABLE_SCHEMA, ku.TABLE_NAME, ku.ORDINAL_POSITION
  `);

  const pkMap = new Map<string, string[]>();
  for (const pk of pks) {
    const key = `${pk.TABLE_SCHEMA}.${pk.TABLE_NAME}`;
    const arr = pkMap.get(key) ?? [];
    arr.push(pk.COLUMN_NAME);
    pkMap.set(key, arr);
  }

  const colMap = new Map<string, TableColumn[]>();
  for (const col of columns) {
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
  const all = await getMetadata();
  return all.find((m) => m.schema === schema && m.table === table) ?? null;
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
