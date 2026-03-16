/**
 * Clientes Service - Stored Procedures
 * Usa SPs: usp_Clientes_List, GetByCodigo, Insert, Update, Delete
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

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

/** usp_Clientes_List - Listado paginado con filtros */
export async function listClientesSP(params: ListClientesParams = {}): Promise<ListClientesResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<ClienteRow>(
    "usp_Clientes_List",
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

/** usp_Clientes_GetByCodigo - Obtener cliente por código */
export async function getClienteByCodigoSP(codigo: string): Promise<ClienteRow | null> {
  const rows = await callSp<ClienteRow>(
    "usp_Clientes_GetByCodigo",
    { Codigo: codigo }
  );
  return rows[0] || null;
}

/** usp_Clientes_Insert - Insertar cliente */
export async function insertClienteSP(row: ClienteRow): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Clientes_Insert",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Clientes_Update - Actualizar cliente */
export async function updateClienteSP(codigo: string, row: Partial<ClienteRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Clientes_Update",
    { Codigo: codigo, RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Clientes_Delete - Eliminar cliente */
export async function deleteClienteSP(codigo: string): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Clientes_Delete",
    { Codigo: codigo },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
