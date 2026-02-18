import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

/** Atributos que aceptan los SP Insert/Update (snapshot Proveedores: CODIGO 10, VENDEDOR 2, FAX, NOTAS, CPOSTAL, LIMITE) */
const SP_ROW_KEYS = [
  "CODIGO", "NOMBRE", "RIF", "NIT", "DIRECCION", "DIRECCION1", "SUCURSAL", "TELEFONO", "FAX",
  "CONTACTO", "VENDEDOR", "ESTADO", "CIUDAD", "CPOSTAL", "EMAIL", "PAGINA_WWW",
  "COD_USUARIO", "LIMITE", "CREDITO", "LISTA_PRECIO", "NOTAS",
] as const;

const BODY_TO_SP: Record<string, string> = {
  LIMITE_CREDITO: "LIMITE",
  COD_POSTAL: "CPOSTAL",
};

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

export type ListProveedoresParams = {
  search?: string;
  estado?: string;
  vendedor?: string;
  page?: string;
  limit?: string;
};

export type ListProveedoresResult = {
  page: number;
  limit: number;
  total: number;
  rows: any[];
  executionMode?: "sp" | "ts_fallback";
};

export async function listProveedores(params: ListProveedoresParams): Promise<ListProveedoresResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Estado", sql.NVarChar(60), params.estado ?? null);
    req.input("Vendedor", sql.NVarChar(2), params.vendedor ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);

    const result = await req.execute("usp_Proveedores_List");
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
    `SELECT * FROM Proveedores ${clause} ORDER BY CODIGO OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Proveedores ${clause}`, sqlParams);
  const total = Number(totalResult[0]?.total ?? 0);

  return { page, limit, total, rows, executionMode: "ts_fallback" };
}

export async function getProveedor(codigo: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(10), codigo);
    const result = await req.execute("usp_Proveedores_GetByCodigo");
    const rows = (result.recordset ?? []) as any[];
    const row = rows[0] ?? null;
    return { row, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const rows = await query<any>("SELECT TOP 1 * FROM Proveedores WHERE CODIGO = @codigo", { codigo });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function createProveedor(body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Proveedores_Insert");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Proveedores_Insert failed");
  } catch {
    // Fallback
  }

  await createRow("dbo", "Proveedores", body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function updateProveedor(codigo: string, body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(10), codigo);
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Proveedores_Update");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Proveedores_Update failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await updateRow("dbo", "Proveedores", key, body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function deleteProveedor(codigo: string): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(10), codigo);
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Proveedores_Delete");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Proveedores_Delete failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await deleteRow("dbo", "Proveedores", key);
  return { ok: true, executionMode: "ts_fallback" };
}
