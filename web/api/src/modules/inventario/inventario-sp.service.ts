/**
 * Inventario Service - Stored Procedures
 * Usa SPs: usp_Inventario_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1, branchId: s?.branchId ?? 1 };
}

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
  Servicio?: boolean;
  Descripcion?: string;
  PRECIO_VENTA1?: number;
  PRECIO_VENTA2?: number;
  PRECIO_VENTA3?: number;
  COSTO_PROMEDIO?: number;
  Alicuota?: number;
  PLU?: number;
  UbicaFisica?: string;
  Garantia?: string;
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

/** usp_Inventario_List - Listado paginado con filtros */
export async function listInventarioSP(params: ListInventarioParams = {}): Promise<ListInventarioResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<InventarioRow>(
    "usp_Inventario_List",
    {
      CompanyId: scope().companyId,
      Search: params.search || null,
      Categoria: params.categoria || null,
      Marca: params.marca || null,
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

/** usp_Inventario_GetByCodigo - Obtener artículo por código */
export async function getInventarioByCodigoSP(codigo: string): Promise<InventarioRow | null> {
  const rows = await callSp<InventarioRow>(
    "usp_Inventario_GetByCodigo",
    { CompanyId: scope().companyId, Codigo: codigo }
  );
  return rows[0] || null;
}

/** usp_Inventario_Insert - Insertar artículo */
export async function insertInventarioSP(row: InventarioRow): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Inventario_Insert",
    { CompanyId: scope().companyId, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Inventario_Update - Actualizar artículo */
export async function updateInventarioSP(codigo: string, row: Partial<InventarioRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Inventario_Update",
    { CompanyId: scope().companyId, Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Inventario_Delete - Eliminar artículo */
export async function deleteInventarioSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Inventario_Delete",
    { CompanyId: scope().companyId, Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
