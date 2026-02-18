/**
 * Clientes Service - Stored Procedures
 * Usa SPs: usp_Clientes_List, GetByCodigo, Insert, Update, Delete
 */
import { getPool, sql } from "../../db/mssql.js";

export interface ClienteRow {
  CODIGO?: string;
  NOMBRE?: string;
  RIF?: string;
  NIT?: string;
  DIRECCION?: string;
  DIRECCION1?: string;
  SUCURSAL?: string;
  TELEFONO?: string;
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
  [key: string]: unknown;
}

export interface ListClientesParams {
  search?: string;
  estado?: string;
  vendedor?: string;
  page?: number;
  limit?: number;
}

export interface ListClientesResult {
  rows: ClienteRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

/**
 * Convierte objeto a XML para SP
 * <row CODIGO="xxx" NOMBRE="yyy" ... />
 */
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
 * usp_Clientes_List - Listado paginado con filtros
 */
export async function listClientesSP(params: ListClientesParams = {}): Promise<ListClientesResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Estado", sql.NVarChar(20), params.estado || null);
  request.input("Vendedor", sql.NVarChar(60), params.vendedor || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("usp_Clientes_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

/**
 * usp_Clientes_GetByCodigo - Obtener cliente por código
 */
export async function getClienteByCodigoSP(codigo: string): Promise<ClienteRow | null> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(12), codigo);

  const result = await request.execute("usp_Clientes_GetByCodigo");
  return result.recordset?.[0] || null;
}

/**
 * usp_Clientes_Insert - Insertar cliente
 */
export async function insertClienteSP(row: ClienteRow): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Clientes_Insert");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Clientes_Update - Actualizar cliente
 */
export async function updateClienteSP(codigo: string, row: Partial<ClienteRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(12), codigo);
  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Clientes_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

/**
 * usp_Clientes_Delete - Eliminar cliente
 */
export async function deleteClienteSP(codigo: string): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(12), codigo);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Clientes_Delete");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
