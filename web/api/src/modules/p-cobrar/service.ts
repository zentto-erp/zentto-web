import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

async function listCobrarTable(table: "p_cobrar" | "P_Cobrarc", params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(DOCUMENTO LIKE @search OR OBS LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.codigo) { where.push("CODIGO = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM ${table} ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM ${table} ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

async function getCobrarTable(table: "p_cobrar" | "P_Cobrarc", id: string) {
  const rows = await query<any>(`SELECT TOP 1 * FROM ${table} WHERE id = @id`, { id });
  return rows[0] ?? null;
}

export const pCobrarService = {
  list: (p: any) => listCobrarTable("p_cobrar", p),
  get: (id: string) => getCobrarTable("p_cobrar", id),
  create: (b: Record<string, unknown>) => createRow("dbo", "p_cobrar", b),
  update: (id: string, b: Record<string, unknown>) => updateRow("dbo", "p_cobrar", encodeKeyObject({ id }), b),
  delete: (id: string) => deleteRow("dbo", "p_cobrar", encodeKeyObject({ id })),

  listC: (p: any) => listCobrarTable("P_Cobrarc", p),
  getC: (id: string) => getCobrarTable("P_Cobrarc", id),
  createC: (b: Record<string, unknown>) => createRow("dbo", "P_Cobrarc", b),
  updateC: (id: string, b: Record<string, unknown>) => updateRow("dbo", "P_Cobrarc", encodeKeyObject({ id }), b),
  deleteC: (id: string) => deleteRow("dbo", "P_Cobrarc", encodeKeyObject({ id }))
};
