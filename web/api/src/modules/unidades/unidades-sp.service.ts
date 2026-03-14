/**
 * Unidades Service - Stored Procedures
 * Usa SPs: usp_Unidades_List, GetById, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface UnidadRow {
  Id?: number;
  Unidad?: string;
  Cantidad?: number;
  [key: string]: unknown;
}

export interface ListUnidadesParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListUnidadesResult {
  rows: UnidadRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
  nuevoId?: number;
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

export async function listUnidadesSP(params: ListUnidadesParams = {}): Promise<ListUnidadesResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<UnidadRow>("usp_Unidades_List",
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

export async function getUnidadByIdSP(id: number): Promise<UnidadRow | null> {
  const rows = await callSp<UnidadRow>("usp_Unidades_GetById", { Id: id });
  return rows?.[0] || null;
}

export async function insertUnidadSP(row: Omit<UnidadRow, "Id">): Promise<SpResult> {
  const { output } = await callSpOut<UnidadRow>("usp_Unidades_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NuevoId: sql.Int }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
    nuevoId: output.NuevoId as number,
  };
}

export async function updateUnidadSP(id: number, row: Partial<UnidadRow>): Promise<SpResult> {
  const { output } = await callSpOut<UnidadRow>("usp_Unidades_Update",
    { Id: id, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}

export async function deleteUnidadSP(id: number): Promise<SpResult> {
  const { output } = await callSpOut<UnidadRow>("usp_Unidades_Delete",
    { Id: id },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: (output.Resultado as number) === 1,
    message: (output.Mensaje as string) || "OK",
  };
}
