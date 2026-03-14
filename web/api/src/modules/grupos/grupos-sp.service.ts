/**
 * Grupos Service - Stored Procedures
 * Usa SPs: usp_Grupos_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface GrupoRow {
  Codigo?: number;
  Descripcion?: string;
  Co_Usuario?: string;
  Porcentaje?: number;
  [key: string]: unknown;
}

export interface ListGruposParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListGruposResult {
  rows: GrupoRow[];
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

export async function listGruposSP(params: ListGruposParams = {}): Promise<ListGruposResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<GrupoRow>("usp_Grupos_List",
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

export async function getGrupoByCodigoSP(codigo: number): Promise<GrupoRow | null> {
  const rows = await callSp<GrupoRow>("usp_Grupos_GetByCodigo", { Codigo: codigo });
  return rows?.[0] || null;
}

export async function insertGrupoSP(row: Omit<GrupoRow, "Codigo">): Promise<SpResult> {
  const { output } = await callSpOut<GrupoRow>("usp_Grupos_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoCodigo: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoCodigo: output.NuevoCodigo as number,
  };
}

export async function updateGrupoSP(codigo: number, row: Partial<GrupoRow>): Promise<SpResult> {
  const { output } = await callSpOut<GrupoRow>("usp_Grupos_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteGrupoSP(codigo: number): Promise<SpResult> {
  const { output } = await callSpOut<GrupoRow>("usp_Grupos_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
