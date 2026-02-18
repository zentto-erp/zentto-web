/**
 * Inventario Service - Stored Procedures
 * Usa SPs: usp_Inventario_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface InventarioRow {
  CODIGO?: string;
  Referencia?: string;
  Categoria?: string;
  Marca?: string;
  Tipo?: string;
  Unidad?: string;
  Clase?: string;
  DESCRIPCION?: string;
  EXISTENCIA?: number;
  VENTA?: number;
  MINIMO?: number;
  MAXIMO?: number;
  PRECIO_COMPRA?: number;
  PRECIO_VENTA?: number;
  PORCENTAJE?: number;
  UBICACION?: string;
  Co_Usuario?: string;
  Linea?: string;
  N_PARTE?: string;
  Barra?: string;
  [key: string]: unknown;
}

export interface ListInventarioParams {
  search?: string;
  categoria?: string;
  marca?: string;
  page?: number;
  limit?: number;
}

export interface ListInventarioResult {
  rows: InventarioRow[];
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
 * usp_Inventario_List - Listado paginado con filtros
 */
export async function listInventarioSP(params: ListInventarioParams = {}): Promise<ListInventarioResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Categoria", sql.NVarChar(50), params.categoria || null);
  request.input("Marca", sql.NVarChar(50), params.marca || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Inventario_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

/**
 * usp_Inventario_GetByCodigo - Obtener artículo por código
 */
export async function getInventarioByCodigoSP(codigo: string): Promise<InventarioRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(15), codigo);

  const result = await request.execute("usp_Inventario_GetByCodigo");
  return result.recordset?.[0] || null;
}

/**
 * usp_Inventario_Insert - Insertar artículo
 */
export async function insertInventarioSP(row: InventarioRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Inventario_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Inventario_Update - Actualizar artículo
 */
export async function updateInventarioSP(codigo: string, row: Partial<InventarioRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(15), codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Inventario_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Inventario_Delete - Eliminar artículo
 */
export async function deleteInventarioSP(codigo: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(15), codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Inventario_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
