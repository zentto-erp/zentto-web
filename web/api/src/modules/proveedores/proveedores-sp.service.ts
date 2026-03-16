/**
 * Proveedores Service - Stored Procedures
 * Usa SPs: usp_Proveedores_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface ProveedorRow {
  CODIGO?: string;
  NOMBRE?: string;
  RIF?: string;
  NIT?: string;
  DIRECCION?: string;
  DIRECCION1?: string;
  SUCURSAL?: string;
  TELEFONO?: string;
  FAX?: string;
  CONTACTO?: string;
  VENDEDOR?: string;
  ESTADO?: string;
  CIUDAD?: string;
  CPOSTAL?: string;
  EMAIL?: string;
  PAGINA_WWW?: string;
  COD_USUARIO?: string;
  LIMITE?: number;
  CREDITO?: number;
  LISTA_PRECIO?: number;
  NOTAS?: string;
  [key: string]: unknown;
}

export interface ListProveedoresParams {
  search?: string;
  estado?: string;
  vendedor?: string;
  page?: number;
  limit?: number;
}

export interface ListProveedoresResult {
  rows: ProveedorRow[];
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

/** usp_Proveedores_List - Listado paginado con filtros */
export async function listProveedoresSP(params: ListProveedoresParams = {}): Promise<ListProveedoresResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<ProveedorRow>(
    "usp_Proveedores_List",
    {
      Search: params.search || null,
      Estado: params.estado || null,
      Vendedor: params.vendedor || null,
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

/** usp_Proveedores_GetByCodigo - Obtener proveedor por código */
export async function getProveedorByCodigoSP(codigo: string): Promise<ProveedorRow | null> {
  const rows = await callSp<ProveedorRow>(
    "usp_Proveedores_GetByCodigo",
    { Codigo: codigo }
  );
  return rows[0] || null;
}

/** usp_Proveedores_Insert - Insertar proveedor */
export async function insertProveedorSP(row: ProveedorRow): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Proveedores_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Proveedores_Update - Actualizar proveedor */
export async function updateProveedorSP(codigo: string, row: Partial<ProveedorRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Proveedores_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Proveedores_Delete - Eliminar proveedor */
export async function deleteProveedorSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Proveedores_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
