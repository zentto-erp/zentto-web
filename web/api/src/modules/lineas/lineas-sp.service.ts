/**
 * Lineas Service - Stored Procedures
 * Usa SPs: usp_Lineas_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface LineaRow {
  CODIGO?: number;
  DESCRIPCION?: string;
  [key: string]: unknown;
}

export interface ListLineasParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListLineasResult {
  rows: LineaRow[];
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

export async function listLineasSP(params: ListLineasParams = {}): Promise<ListLineasResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<LineaRow>("usp_Lineas_List",
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

export async function getLineaByCodigoSP(codigo: number): Promise<LineaRow | null> {
  const rows = await callSp<LineaRow>("usp_Lineas_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertLineaSP(row: Omit<LineaRow, "CODIGO">): Promise<SpResult> {
  const { output } = await callSpOut<LineaRow>("usp_Lineas_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoCodigo: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoCodigo: output.NuevoCodigo as number,
  };
}

export async function updateLineaSP(codigo: number, row: Partial<LineaRow>): Promise<SpResult> {
  const { output } = await callSpOut<LineaRow>("usp_Lineas_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteLineaSP(codigo: number): Promise<SpResult> {
  const { output } = await callSpOut<LineaRow>("usp_Lineas_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
