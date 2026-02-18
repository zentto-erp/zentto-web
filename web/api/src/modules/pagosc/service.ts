import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

export async function listPagosC(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(DOCUMENTO LIKE @search OR NOMBRE LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.codigo) { where.push("CODIGO = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Pagosc ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Pagosc ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
export async function getPagoC(id: string) { const rows = await query<any>("SELECT TOP 1 * FROM Pagosc WHERE id = @id", { id }); return rows[0] ?? null; }
export async function getPagoCDetalle(id: string) {
  const head = await getPagoC(id);
  if (!head) return [];
  return query<any>("SELECT * FROM PagosC_Detalle WHERE RECNUM = @recnum ORDER BY Id", { recnum: head.RECNUM });
}
export async function createPagoC(body: Record<string, unknown>) { return createRow("dbo", "Pagosc", body); }
export async function updatePagoC(id: string, body: Record<string, unknown>) { return updateRow("dbo", "Pagosc", encodeKeyObject({ id }), body); }
export async function deletePagoC(id: string) { return deleteRow("dbo", "Pagosc", encodeKeyObject({ id })); }
export async function createPagoCTx(payload: { pago: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({
    headerTable: "[dbo].[Pagosc]",
    detailTable: "[dbo].[PagosC_Detalle]",
    header: payload.pago ?? {},
    details: payload.detalle ?? [],
    linkFields: ["RECNUM", "CODIGO", "Codigo"]
  });
}
