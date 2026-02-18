import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

export async function listAbonos(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
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
  const rows = await query<any>(`SELECT * FROM Abonos ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Abonos ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getAbono(id: string) {
  const rows = await query<any>("SELECT TOP 1 * FROM Abonos WHERE Id = @id", { id });
  return rows[0] ?? null;
}

export async function getAbonoDetalle(id: string) {
  const head = await getAbono(id);
  if (!head) return [];
  return query<any>("SELECT * FROM Abonos_Detalle WHERE RECNUM = @recnum ORDER BY Id", { recnum: head.RECNUM });
}

export async function createAbono(body: Record<string, unknown>) {
  return createRow("dbo", "Abonos", body);
}

export async function updateAbono(id: string, body: Record<string, unknown>) {
  return updateRow("dbo", "Abonos", encodeKeyObject({ Id: id }), body);
}

export async function deleteAbono(id: string) {
  return deleteRow("dbo", "Abonos", encodeKeyObject({ Id: id }));
}

export async function createAbonoTx(payload: { abono: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({
    headerTable: "[dbo].[Abonos]",
    detailTable: "[dbo].[Abonos_Detalle]",
    header: payload.abono ?? {},
    details: payload.detalle ?? [],
    linkFields: ["RECNUM", "CODIGO"]
  });
}
