/**
 * Almacen Service - Stored Procedures
 * Usa SPs: usp_Almacen_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface AlmacenRow {
  Codigo?: string;
  Descripcion?: string;
  Tipo?: string;
  [key: string]: unknown;
}

export interface ListAlmacenParams {
  search?: string;
  tipo?: string;
  page?: number;
  limit?: number;
}

export interface ListAlmacenResult {
  rows: AlmacenRow[];
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

export async function listAlmacenSP(params: ListAlmacenParams = {}): Promise<ListAlmacenResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<AlmacenRow>(
    "usp_Almacen_List",
    {
      Search: params.search || null,
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

export async function getAlmacenByCodigoSP(codigo: string): Promise<AlmacenRow | null> {
  const rows = await callSp<AlmacenRow>(
    "usp_Almacen_GetByCodigo",
    { Codigo: codigo }
  );
  return rows[0] || null;
}

export async function insertAlmacenSP(row: AlmacenRow): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Almacen_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function updateAlmacenSP(codigo: string, row: Partial<AlmacenRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Almacen_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function deleteAlmacenSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Almacen_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
