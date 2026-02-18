import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listCuentasPorPagar(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(DOCUMENTO LIKE @search OR OBS LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("CODIGO = @codigo");
    sqlParams.codigo = params.codigo;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM P_Pagar ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM P_Pagar ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getCuentaPorPagar(id: string) {
  const rows = await query<any>("SELECT TOP 1 * FROM P_Pagar WHERE id = @id", { id });
  return rows[0] ?? null;
}

export async function createCuentaPorPagar(body: Record<string, unknown>) {
  return createRow("dbo", "P_Pagar", body);
}

export async function updateCuentaPorPagar(id: string, body: Record<string, unknown>) {
  return updateRow("dbo", "P_Pagar", encodeKeyObject({ id }), body);
}

export async function deleteCuentaPorPagar(id: string) {
  return deleteRow("dbo", "P_Pagar", encodeKeyObject({ id }));
}
