/**
 * Cuentas Service - Stored Procedures
 * Usa SPs: usp_Cuentas_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface CuentaRow {
  COD_CUENTA?: string;
  DESCRIPCION?: string;
  TIPO?: string;
  PRESUPUESTO?: number;
  SALDO?: number;
  COD_USUARIO?: string;
  grupo?: string;
  LINEA?: string;
  USO?: string;
  Nivel?: number;
  Porcentaje?: number;
  [key: string]: unknown;
}

export interface ListCuentasParams {
  search?: string;
  tipo?: string;
  grupo?: string;
  page?: number;
  limit?: number;
}

export interface ListCuentasResult {
  rows: CuentaRow[];
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

export async function listCuentasSP(params: ListCuentasParams = {}): Promise<ListCuentasResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Tipo", sql.NVarChar(50), params.tipo || null);
  request.input("Grupo", sql.NVarChar(50), params.grupo || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Cuentas_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

export async function getCuentaByCodigoSP(codCuenta: string): Promise<CuentaRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodCuenta", sql.NVarChar(50), codCuenta);

  const result = await request.execute("usp_Cuentas_GetByCodigo");
  return result.recordset?.[0] || null;
}

export async function insertCuentaSP(row: CuentaRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Cuentas_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function updateCuentaSP(codCuenta: string, row: Partial<CuentaRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodCuenta", sql.NVarChar(50), codCuenta);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Cuentas_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

export async function deleteCuentaSP(codCuenta: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CodCuenta", sql.NVarChar(50), codCuenta);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Cuentas_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
