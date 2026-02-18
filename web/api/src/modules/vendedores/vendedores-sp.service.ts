/**
 * Vendedores Service - Stored Procedures
 * Usa SPs: usp_Vendedores_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface VendedorRow {
  Codigo?: string;
  Nombre?: string;
  Comision?: number;
  Direccion?: string;
  Telefonos?: string;
  Email?: string;
  Status?: boolean;
  Tipo?: string;
  clave?: string;
  [key: string]: unknown;
}

export interface ListVendedoresParams {
  search?: string;
  status?: boolean;
  tipo?: string;
  page?: number;
  limit?: number;
}

export interface ListVendedoresResult {
  rows: VendedorRow[];
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

export async function listVendedoresSP(params: ListVendedoresParams = {}): Promise<ListVendedoresResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Status", sql.Bit, params.status ?? null);
  request.input("Tipo", sql.NVarChar(50), params.tipo || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Vendedores_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getVendedorByCodigoSP(codigo: string): Promise<VendedorRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);

  const result = await request.execute("usp_Vendedores_GetByCodigo");
  return result.recordset?.[0] || null;
}

export async function insertVendedorSP(row: VendedorRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Vendedores_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function updateVendedorSP(codigo: string, row: Partial<VendedorRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Vendedores_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteVendedorSP(codigo: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Vendedores_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
