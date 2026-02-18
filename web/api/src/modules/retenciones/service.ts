import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listRetenciones(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(Codigo LIKE @search OR Descripcion LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.tipo) { where.push("Tipos = @tipo"); sqlParams.tipo = params.tipo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Retenciones ${clause} ORDER BY Codigo OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Retenciones ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
export async function getRetencion(codigo: string) { const rows = await query<any>("SELECT TOP 1 * FROM Retenciones WHERE Codigo = @codigo", { codigo }); return rows[0] ?? null; }
export async function createRetencion(body: Record<string, unknown>) { return createRow("dbo", "Retenciones", body); }
export async function updateRetencion(codigo: string, body: Record<string, unknown>) { return updateRow("dbo", "Retenciones", encodeKeyObject({ Codigo: codigo }), body); }
export async function deleteRetencion(codigo: string) { return deleteRow("dbo", "Retenciones", encodeKeyObject({ Codigo: codigo })); }
