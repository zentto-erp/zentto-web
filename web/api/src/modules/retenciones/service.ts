import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

const TABLE = "master.TaxRetention";

export async function listRetenciones(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = ["IsDeleted = 0"];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(RetentionCode LIKE @search OR Description LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.tipo) { where.push("RetentionType = @tipo"); sqlParams.tipo = params.tipo; }
  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<any>(
    `SELECT RetentionId, RetentionCode AS Codigo, Description AS Descripcion, RetentionType AS Tipo,
            RetentionRate AS Porcentaje, CountryCode AS Pais, IsActive
     FROM ${TABLE} ${clause}
     ORDER BY RetentionCode OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM ${TABLE} ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getRetencion(codigo: string) {
  const rows = await query<any>(
    `SELECT RetentionId, RetentionCode AS Codigo, Description AS Descripcion, RetentionType AS Tipo,
            RetentionRate AS Porcentaje, CountryCode AS Pais, IsActive
     FROM ${TABLE} WHERE RetentionCode = @codigo AND IsDeleted = 0`,
    { codigo }
  );
  return rows[0] ?? null;
}

export async function createRetencion(body: Record<string, unknown>) {
  return createRow("master", "TaxRetention", body);
}

export async function updateRetencion(codigo: string, body: Record<string, unknown>) {
  return updateRow("master", "TaxRetention", encodeKeyObject({ RetentionCode: codigo }), body);
}

export async function deleteRetencion(codigo: string) {
  return deleteRow("master", "TaxRetention", encodeKeyObject({ RetentionCode: codigo }));
}
