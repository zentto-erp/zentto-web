/**
 * Unidades Service - Stored Procedures
 * Usa SPs: usp_Unidades_List, GetById, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface UnidadRow {
  Id?: number;
  Unidad?: string;
  Cantidad?: number;
  [key: string]: unknown;
}

export interface ListUnidadesParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListUnidadesResult {
  rows: UnidadRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
  nuevoId?: number;
}

function rowToXml(row: Record<string, unknown>): string {
  const attrs = Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => {
      const escaped = String(v)
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
      return `${k}="${escaped}"`;
    })
    .join(" ");
  return `<row ${attrs}/>`;
}

export async function listUnidadesSP(params: ListUnidadesParams = {}): Promise<ListUnidadesResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Unidades_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getUnidadByIdSP(id: number): Promise<UnidadRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Id", sql.Int, id);

  const result = await request.execute("usp_Unidades_GetById");
  return result.recordset?.[0] || null;
}

export async function insertUnidadSP(row: Omit<UnidadRow, "Id">): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));
  request.output("NuevoId", sql.Int);

  await request.execute("usp_Unidades_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
    nuevoId: request.parameters.NuevoId?.value as number,
  };
}

export async function updateUnidadSP(id: number, row: Partial<UnidadRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Id", sql.Int, id);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Unidades_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteUnidadSP(id: number): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Id", sql.Int, id);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Unidades_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
