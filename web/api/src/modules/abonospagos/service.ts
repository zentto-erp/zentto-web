import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listAbonosPagos(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(Num_fact LIKE @search OR Concepto LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.codigo) { where.push("Codigo = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM AbonosPagos ${clause} ORDER BY Fecha DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM AbonosPagos ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
export async function getAbonosPagos(id: string) { const rows = await query<any>("SELECT TOP 1 * FROM AbonosPagos WHERE Id = @id", { id }); return rows[0] ?? null; }
export async function createAbonosPagos(body: Record<string, unknown>) { return createRow("dbo", "AbonosPagos", body); }
export async function updateAbonosPagos(id: string, body: Record<string, unknown>) { return updateRow("dbo", "AbonosPagos", encodeKeyObject({ Id: id }), body); }
export async function deleteAbonosPagos(id: string) { return deleteRow("dbo", "AbonosPagos", encodeKeyObject({ Id: id })); }
