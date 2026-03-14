/**
 * Tipos Service - Stored Procedures
 * Usa SPs: usp_Tipos_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

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
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<TipoRow>("usp_Tipos_List",
    { Search: params.search || null, Categoria: params.categoria || null, Page: page, Limit: limit },
    { TotalCount: sql.Int }
  );

  return {
    rows: rows || [],
    total: (output.TotalCount as number) || 0,
    page,
    limit,
  };
}

export async function getTipoByCodigoSP(codigo: number): Promise<TipoRow | null> {
  const rows = await callSp<TipoRow>("usp_Tipos_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertTipoSP(row: Omit<TipoRow, "Codigo">): Promise<SpResult> {
  const { output } = await callSpOut<TipoRow>("usp_Tipos_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoCodigo: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoCodigo: output.NuevoCodigo as number,
  };
}

export async function updateTipoSP(codigo: number, row: Partial<TipoRow>): Promise<SpResult> {
  const { output } = await callSpOut<TipoRow>("usp_Tipos_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteTipoSP(codigo: number): Promise<SpResult> {
  const { output } = await callSpOut<TipoRow>("usp_Tipos_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
