/**
 * Usuarios Service - Stored Procedures (CRUD)
 * Usa SPs: usp_Usuarios_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { checkUserLimit } from "../license/license-enforcement.service.js";

export interface UsuarioRow {
  Cod_Usuario?: string;
  Password?: string;
  Nombre?: string;
  Tipo?: string;
  Updates?: boolean;
  Addnews?: boolean;
  Deletes?: boolean;
  Creador?: boolean;
  Cambiar?: boolean;
  PrecioMinimo?: boolean;
  Credito?: boolean;
  [key: string]: unknown;
}

export interface ListUsuariosParams {
  search?: string;
  tipo?: string;
  page?: number;
  limit?: number;
}

export interface ListUsuariosResult {
  rows: UsuarioRow[];
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
      const val = typeof v === 'boolean' ? (v ? '1' : '0') : String(v);
      const escaped = val
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
      return `${k}="${escaped}"`;
    })
    .join(" ");
  return `<row ${attrs}/>`;
}

export async function listUsuariosSP(params: ListUsuariosParams = {}): Promise<ListUsuariosResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<UsuarioRow>(
    "usp_Usuarios_List",
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

export async function getUsuarioByCodigoSP(codigo: string): Promise<UsuarioRow | null> {
  const rows = await callSp<UsuarioRow>(
    "usp_Usuarios_GetByCodigo",
    { CodUsuario: codigo }
  );
  return rows[0] || null;
}

export async function insertUsuarioSP(row: UsuarioRow): Promise<SpResult> {
  // Validar límite de usuarios según licencia
  const limit = await checkUserLimit();
  if (!limit.allowed) {
    return {
      success: false,
      message: `Límite de usuarios alcanzado (plan ${limit.plan}: máx ${limit.max} usuarios)`,
    };
  }

  const { output } = await callSpOut<never>(
    "usp_Usuarios_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function updateUsuarioSP(codigo: string, row: Partial<UsuarioRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Usuarios_Update",
    { CodUsuario: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

export async function deleteUsuarioSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Usuarios_Delete",
    { CodUsuario: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
