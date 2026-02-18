import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

/** Atributos que aceptan los SP Insert/Update (según snapshot Clientes: CPOSTAL, LIMITE, sin FAX/OBS/PAIS/COD_POSTAL) */
const SP_ROW_KEYS = [
  "CODIGO", "NOMBRE", "RIF", "NIT", "DIRECCION", "DIRECCION1", "SUCURSAL", "TELEFONO",
  "CONTACTO", "VENDEDOR", "ESTADO", "CIUDAD", "CPOSTAL", "EMAIL", "PAGINA_WWW",
  "COD_USUARIO", "LIMITE", "CREDITO", "LISTA_PRECIO",
] as const;

/** Mapeo de nombres que puede enviar el frontend a nombres del SP */
const BODY_TO_SP: Record<string, string> = {
  LIMITE_CREDITO: "LIMITE",
  COD_POSTAL: "CPOSTAL",
};

/** Convierte un objeto a XML <row attr="val" ... /> para SP (solo columnas existentes en Clientes) */
function recordToRowXml(row: Record<string, unknown>): string {
  const escape = (v: unknown): string => {
    if (v === null || v === undefined) return "";
    const s = String(v);
    return s
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/'/g, "&apos;");
  };
  const spRow: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    if (v === undefined || v === null) continue;
    const key = BODY_TO_SP[k] ?? k;
    if (SP_ROW_KEYS.includes(key as (typeof SP_ROW_KEYS)[number])) {
      spRow[key] = v;
    }
  }
  const attrs = Object.entries(spRow)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escape(v)}"`)
    .join(" ");
  return `<row ${attrs} />`;
}

export type ListClientesParams = {
  search?: string;
  estado?: string;
  vendedor?: string;
  page?: string;
  limit?: string;
};

export type ListClientesResult = {
  page: number;
  limit: number;
  total: number;
  rows: any[];
  executionMode?: "sp" | "ts_fallback";
};

export async function listClientes(params: ListClientesParams): Promise<ListClientesResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Estado", sql.NVarChar(20), params.estado ?? null);
    req.input("Vendedor", sql.NVarChar(60), params.vendedor ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);

    const result = await req.execute("usp_Clientes_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as any[];

    return { page, limit, total, rows, executionMode: "sp" };
  } catch {
    // Fallback: query node
  }

  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};

  if (params.search) {
    where.push("(CODIGO LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.estado) {
    where.push("ESTADO = @estado");
    sqlParams.estado = params.estado;
  }
  if (params.vendedor) {
    where.push("VENDEDOR = @vendedor");
    sqlParams.vendedor = params.vendedor;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const rows = await query<any>(
    `SELECT * FROM Clientes ${clause} ORDER BY CODIGO OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Clientes ${clause}`, sqlParams);
  const total = Number(totalResult[0]?.total ?? 0);

  return { page, limit, total, rows, executionMode: "ts_fallback" };
}

export async function getCliente(codigo: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(12), codigo);
    const result = await req.execute("usp_Clientes_GetByCodigo");
    const rows = (result.recordset ?? []) as any[];
    const row = rows[0] ?? null;
    return { row, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const rows = await query<any>("SELECT TOP 1 * FROM Clientes WHERE CODIGO = @codigo", { codigo });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function createCliente(body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Clientes_Insert");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Clientes_Insert failed");
  } catch {
    // Fallback
  }

  await createRow("dbo", "Clientes", body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function updateCliente(codigo: string, body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(12), codigo);
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Clientes_Update");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Clientes_Update failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await updateRow("dbo", "Clientes", key, body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function deleteCliente(codigo: string): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(12), codigo);
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Clientes_Delete");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Clientes_Delete failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await deleteRow("dbo", "Clientes", key);
  return { ok: true, executionMode: "ts_fallback" };
}
