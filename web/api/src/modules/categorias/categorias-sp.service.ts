/**
 * Categorias Service - Stored Procedures
 * Usa SPs: usp_Categorias_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface CategoriaRow {
  Codigo?: number;
  Nombre?: string;
  Co_Usuario?: string;
  [key: string]: unknown;
}

export interface ListCategoriasParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListCategoriasResult {
  rows: CategoriaRow[];
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

export async function listCategoriasSP(params: ListCategoriasParams = {}): Promise<ListCategoriasResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<CategoriaRow>("usp_Categorias_List",
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

export async function getCategoriaByCodigoSP(codigo: number): Promise<CategoriaRow | null> {
  const rows = await callSp<CategoriaRow>("usp_Categorias_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertCategoriaSP(row: Omit<CategoriaRow, "Codigo">): Promise<SpResult> {
  const { output } = await callSpOut<CategoriaRow>("usp_Categorias_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoCodigo: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoCodigo: output.NuevoCodigo as number,
  };
}

export async function updateCategoriaSP(codigo: number, row: Partial<CategoriaRow>): Promise<SpResult> {
  const { output } = await callSpOut<CategoriaRow>("usp_Categorias_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteCategoriaSP(codigo: number): Promise<SpResult> {
  const { output } = await callSpOut<CategoriaRow>("usp_Categorias_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
