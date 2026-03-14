import { callSp } from "../../db/query.js";

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
