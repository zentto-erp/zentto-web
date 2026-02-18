import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

export async function listPagos(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};

  if (params.search) {
    where.push("(DOCUMENTO LIKE @search OR NOMBRE LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("CODIGO = @codigo");
    sqlParams.codigo = params.codigo;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM pagos ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM pagos ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getPago(id: string) {
  const rows = await query<any>("SELECT TOP 1 * FROM pagos WHERE id = @id", { id });
  return rows[0] ?? null;
}

export async function getPagoDetalle(id: string) {
  const head = await getPago(id);
  if (!head) return [];
  return query<any>("SELECT * FROM Pagos_Detalle WHERE RECNUM = @recnum ORDER BY Id", { recnum: head.RECNUM });
}

export async function createPago(body: Record<string, unknown>) {
  return createRow("dbo", "pagos", body);
}

export async function updatePago(id: string, body: Record<string, unknown>) {
  return updateRow("dbo", "pagos", encodeKeyObject({ id }), body);
}

export async function deletePago(id: string) {
  return deleteRow("dbo", "pagos", encodeKeyObject({ id }));
}

export async function createPagoTx(payload: { pago: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({
    headerTable: "[dbo].[pagos]",
    detailTable: "[dbo].[Pagos_Detalle]",
    header: payload.pago ?? {},
    details: payload.detalle ?? [],
    linkFields: ["RECNUM", "CODIGO"]
  });
}
