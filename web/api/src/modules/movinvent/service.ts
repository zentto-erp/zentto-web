import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listMovInvent(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(Codigo LIKE @search OR Product LIKE @search OR Documento LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.tipo) { where.push("Tipo = @tipo"); sqlParams.tipo = params.tipo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM MovInvent ${clause} ORDER BY Fecha DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM MovInvent ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getMovInvent(id: string) { const rows = await query<any>("SELECT TOP 1 * FROM MovInvent WHERE id = @id", { id }); return rows[0] ?? null; }
export async function createMovInvent(body: Record<string, unknown>) { return createRow("dbo", "MovInvent", body); }
export async function updateMovInvent(id: string, body: Record<string, unknown>) { return updateRow("dbo", "MovInvent", encodeKeyObject({ id }), body); }
export async function deleteMovInvent(id: string) { return deleteRow("dbo", "MovInvent", encodeKeyObject({ id })); }

export async function listMovInventMes(params: { periodo?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.periodo) { where.push("Periodo = @periodo"); sqlParams.periodo = params.periodo; }
  if (params.codigo) { where.push("Codigo = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM MovInventMes ${clause} ORDER BY fecha DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM MovInventMes ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
