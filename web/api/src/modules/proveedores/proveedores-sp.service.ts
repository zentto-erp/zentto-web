/**
 * Proveedores Service - Stored Procedures
 * Usa SPs: usp_Proveedores_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

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

/**
 * usp_Proveedores_List - Listado paginado con filtros
 */
export async function listProveedoresSP(params: ListProveedoresParams = {}): Promise<ListProveedoresResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Estado", sql.NVarChar(60), params.estado || null);
  request.input("Vendedor", sql.NVarChar(2), params.vendedor || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Proveedores_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

/**
 * usp_Proveedores_GetByCodigo - Obtener proveedor por código
 */
export async function getProveedorByCodigoSP(codigo: string): Promise<ProveedorRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);

  const result = await request.execute("usp_Proveedores_GetByCodigo");
  return result.recordset?.[0] || null;
}

/**
 * usp_Proveedores_Insert - Insertar proveedor
 */
export async function insertProveedorSP(row: ProveedorRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Proveedores_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Proveedores_Update - Actualizar proveedor
 */
export async function updateProveedorSP(codigo: string, row: Partial<ProveedorRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Proveedores_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Proveedores_Delete - Eliminar proveedor
 */
export async function deleteProveedorSP(codigo: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(10), codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Proveedores_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
