/**
 * Usuarios Service - Stored Procedures
 * Usa SPs: usp_Usuarios_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface UsuarioRow {
  Cod_Usuario?: string;
  Password?: string;
  Nombre?: string;
  Tipo?: string;
  Updates?: boolean;
  Addnews?: boolean;
  Deletes?: boolean;
  Creador?: boolean;
  Cambiar?: boolean;
  PrecioMinimo?: boolean;
  Credito?: boolean;
  [key: string]: unknown;
}

export interface ListUsuariosParams {
  search?: string;
  tipo?: string;
  page?: number;
  limit?: number;
}

export interface ListUsuariosResult {
  rows: UsuarioRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

function rowToXml(row: Record<string, unknown>): string {
  const attrs = Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => {
      // Convert booleans to 1/0 for SQL Server BIT columns
      const val = typeof v === 'boolean' ? (v ? '1' : '0') : String(v);
      const escaped = val
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
      return `${k}="${escaped}"`;
    })
    .join(" ");
  return `<row ${attrs}/>`;
}

export async function listUsuariosSP(params: ListUsuariosParams = {}): Promise<ListUsuariosResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Tipo", sql.NVarChar(50), params.tipo || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Usuarios_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getUsuarioByCodigoSP(codigo: string): Promise<UsuarioRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodUsuario", sql.NVarChar(10), codigo);

  const result = await request.execute("usp_Usuarios_GetByCodigo");
  return result.recordset?.[0] || null;
}

export async function insertUsuarioSP(row: UsuarioRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Usuarios_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function updateUsuarioSP(codigo: string, row: Partial<UsuarioRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodUsuario", sql.NVarChar(10), codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Usuarios_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteUsuarioSP(codigo: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodUsuario", sql.NVarChar(10), codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Usuarios_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
