/**
 * Bancos Service - Stored Procedures
 * Usa SPs: usp_Bancos_List, GetByNombre, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface BancoRow {
  Nombre?: string;
  Contacto?: string;
  Direccion?: string;
  Telefonos?: string;
  Co_Usuario?: string;
  [key: string]: unknown;
}

export interface ListBancosParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListBancosResult {
  rows: BancoRow[];
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

export async function listBancosSP(params: ListBancosParams = {}): Promise<ListBancosResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Bancos_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getBancoByNombreSP(nombre: string): Promise<BancoRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nombre", sql.NVarChar(50), nombre);

  const result = await request.execute("usp_Bancos_GetByNombre");
  return result.recordset?.[0] || null;
}

export async function insertBancoSP(row: BancoRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Bancos_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function updateBancoSP(nombre: string, row: Partial<BancoRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nombre", sql.NVarChar(50), nombre);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Bancos_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteBancoSP(nombre: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nombre", sql.NVarChar(50), nombre);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Bancos_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
