/**
 * Clases Service - Stored Procedures
 * Usa SPs: usp_Clases_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface ClaseRow {
  Codigo?: number;
  Descripcion?: string;
  [key: string]: unknown;
}

export interface ListClasesParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListClasesResult {
  rows: ClaseRow[];
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

export async function listClasesSP(params: ListClasesParams = {}): Promise<ListClasesResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<ClaseRow>("usp_Clases_List",
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

export async function getClaseByCodigoSP(codigo: number): Promise<ClaseRow | null> {
  const rows = await callSp<ClaseRow>("usp_Clases_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertClaseSP(row: Omit<ClaseRow, "Codigo">): Promise<SpResult> {
  const { output } = await callSpOut<ClaseRow>("usp_Clases_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoCodigo: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoCodigo: output.NuevoCodigo as number,
  };
}

export async function updateClaseSP(codigo: number, row: Partial<ClaseRow>): Promise<SpResult> {
  const { output } = await callSpOut<ClaseRow>("usp_Clases_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteClaseSP(codigo: number): Promise<SpResult> {
  const { output } = await callSpOut<ClaseRow>("usp_Clases_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
