import { callSp } from "../../db/query.js";

export function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
}

/**
 * @deprecated Use callSp with a specific SP instead of building SQL dynamically.
 * Kept for backward compatibility. New code should call SPs directly.
 */
export function buildInsert(tableName: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row);
  if (keys.length === 0) {
    throw new Error("empty_row");
  }

  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");

  return {
    statement: `INSERT INTO ${tableName} (${cols}) VALUES (${vals})`,
    params: keys.map((k) => ({ key: `${prefix}_${k}`, value: row[k] }))
  };
}

/**
 * Inserts a header row and multiple detail rows in a single transaction
 * using the usp_Sys_HeaderDetailTx stored procedure.
 */
export async function runHeaderDetailTx(input: {
  headerTable: string;
  detailTable: string;
  header: Record<string, unknown>;
  details: Record<string, unknown>[];
  linkFields?: string[];
}) {
  const rows = await callSp<{ ok: number; detailRows: number }>(
    'usp_Sys_HeaderDetailTx',
    {
      HeaderTable: input.headerTable,
      DetailTable: input.detailTable,
      HeaderJson: JSON.stringify(input.header),
      DetailsJson: JSON.stringify(input.details),
      LinkFieldsCsv: input.linkFields?.join(',') ?? null,
    }
  );

  return { ok: true, detailRows: Number(rows[0]?.detailRows ?? input.details.length) };
}
