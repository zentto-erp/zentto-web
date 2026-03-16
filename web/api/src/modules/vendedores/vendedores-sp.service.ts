/**
 * Vendedores Service - Stored Procedures
 * Usa SPs: usp_Vendedores_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

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
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<VendedorRow>(
    "usp_Vendedores_List",
    {
      Search: params.search || null,
      Status: params.status ?? null,
      Tipo: params.tipo || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getVendedorByCodigoSP(codigo: string): Promise<VendedorRow | null> {
  const rows = await callSp<VendedorRow>(
    "usp_Vendedores_GetByCodigo",
    { Codigo: codigo }
  );
  return rows[0] || null;
}

export async function insertVendedorSP(row: VendedorRow): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Vendedores_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function updateVendedorSP(codigo: string, row: Partial<VendedorRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Vendedores_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function deleteVendedorSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Vendedores_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
