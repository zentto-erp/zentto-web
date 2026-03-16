/**
 * Centro Costo Service - Stored Procedures
 * Usa SPs: usp_CentroCosto_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface CentroCostoRow {
  Codigo?: string;
  Descripcion?: string;
  Presupuestado?: string;
  Saldo_Real?: string;
  [key: string]: unknown;
}

export interface ListCentroCostoParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListCentroCostoResult {
  rows: CentroCostoRow[];
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

export async function listCentroCostoSP(params: ListCentroCostoParams = {}): Promise<ListCentroCostoResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<CentroCostoRow>("usp_CentroCosto_List",
    { Search: params.search || null, Page: page, Limit: limit },
    { TotalCount: sql.Int }
  );

  return {
    rows: rows || [],
    total: (output.TotalCount as number) || 0,
    page,
    limit,
  };
}

export async function getCentroCostoByCodigoSP(codigo: string): Promise<CentroCostoRow | null> {
  const rows = await callSp<CentroCostoRow>("usp_CentroCosto_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertCentroCostoSP(row: CentroCostoRow): Promise<SpResult> {
  const { output } = await callSpOut<CentroCostoRow>("usp_CentroCosto_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function updateCentroCostoSP(codigo: string, row: Partial<CentroCostoRow>): Promise<SpResult> {
  const { output } = await callSpOut<CentroCostoRow>("usp_CentroCosto_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteCentroCostoSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<CentroCostoRow>("usp_CentroCosto_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
