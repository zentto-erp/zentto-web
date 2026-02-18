/**
 * Tipos Service - Stored Procedures
 * Usa SPs: usp_Tipos_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface TipoRow {
  Codigo?: number;
  Categoria?: string;
  Nombre?: string;
  Co_Usuario?: string;
  [key: string]: unknown;
}

export interface ListTiposParams {
  search?: string;
  categoria?: string;
  page?: number;
  limit?: number;
}

export interface ListTiposResult {
  rows: TipoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
  nuevoCodigo?: number;
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

export async function listTiposSP(params: ListTiposParams = {}): Promise<ListTiposResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Categoria", sql.NVarChar(50), params.categoria || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Tipos_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getTipoByCodigoSP(codigo: number): Promise<TipoRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.Int, codigo);

  const result = await request.execute("usp_Tipos_GetByCodigo");
  return result.recordset?.[0] || null;
}

export async function insertTipoSP(row: Omit<TipoRow, "Codigo">): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));
  request.output("NuevoCodigo", sql.Int);

  await request.execute("usp_Tipos_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
    nuevoCodigo: request.parameters.NuevoCodigo?.value as number,
  };
}

export async function updateTipoSP(codigo: number, row: Partial<TipoRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.Int, codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Tipos_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteTipoSP(codigo: number): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.Int, codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Tipos_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
