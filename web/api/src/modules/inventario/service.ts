import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

const SP_ROW_KEYS = [
  "CODIGO", "Referencia", "Categoria", "Marca", "Tipo", "Unidad", "Clase", "DESCRIPCION",
  "EXISTENCIA", "VENTA", "MINIMO", "MAXIMO", "PRECIO_COMPRA", "PRECIO_VENTA", "PORCENTAJE",
  "UBICACION", "Co_Usuario", "Linea", "N_PARTE", "Barra",
] as const;

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
    if (SP_ROW_KEYS.includes(k as (typeof SP_ROW_KEYS)[number])) {
      spRow[k] = v;
    }
  }
  const attrs = Object.entries(spRow)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escape(v)}"`)
    .join(" ");
  return `<row ${attrs} />`;
}

// Parámetros de filtro para listar artículos
// Linea = departamento (ej: REPUESTOS)
// Categoria, Tipo, Marca, Clase = subdivisiones del artículo
export type ListInventarioParams = {
  search?: string;
  categoria?: string;
  marca?: string;
  linea?: string;
  tipo?: string;
  clase?: string;
  page?: string;
  limit?: string;
};

export type ListInventarioResult = {
  page: number;
  limit: number;
  total: number;
  rows: any[];
  executionMode?: "sp" | "ts_fallback";
};

export async function listInventario(params: ListInventarioParams): Promise<ListInventarioResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Categoria", sql.NVarChar(50), params.categoria ?? null);
    req.input("Marca", sql.NVarChar(50), params.marca ?? null);
    req.input("Linea", sql.NVarChar(30), params.linea ?? null);
    req.input("Tipo", sql.NVarChar(50), params.tipo ?? null);
    req.input("Clase", sql.NVarChar(25), params.clase ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);

    const result = await req.execute("usp_Inventario_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as any[];

    return { page, limit, total, rows, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};

  // Búsqueda libre en todos los campos descriptivos
  if (params.search) {
    where.push("(CODIGO LIKE @search OR Referencia LIKE @search OR DESCRIPCION LIKE @search OR Categoria LIKE @search OR Tipo LIKE @search OR Marca LIKE @search OR Clase LIKE @search OR Linea LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  // Filtros exactos por campo
  if (params.categoria) {
    where.push("Categoria = @categoria");
    sqlParams.categoria = params.categoria;
  }
  if (params.marca) {
    where.push("Marca = @marca");
    sqlParams.marca = params.marca;
  }
  if (params.linea) {
    where.push("Linea = @linea");
    sqlParams.linea = params.linea;
  }
  if (params.tipo) {
    where.push("Tipo = @tipo");
    sqlParams.tipo = params.tipo;
  }
  if (params.clase) {
    where.push("Clase = @clase");
    sqlParams.clase = params.clase;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  // Fallback: calcular DescripcionCompleta en el SELECT
  const descExpr = `LTRIM(RTRIM(
    ISNULL(RTRIM(Categoria), '') +
    CASE WHEN RTRIM(ISNULL(Tipo, '')) <> '' THEN ' ' + RTRIM(Tipo) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(DESCRIPCION) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(Marca, '')) <> '' THEN ' ' + RTRIM(Marca) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(Clase, '')) <> '' THEN ' ' + RTRIM(Clase) ELSE '' END
  )) AS DescripcionCompleta`;

  const rows = await query<any>(
    `SELECT *, ${descExpr} FROM Inventario ${clause} ORDER BY CODIGO OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Inventario ${clause}`, sqlParams);
  const total = Number(totalResult[0]?.total ?? 0);

  return { page, limit, total, rows, executionMode: "ts_fallback" };
}

export async function getInventario(codigo: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(15), codigo);
    const result = await req.execute("usp_Inventario_GetByCodigo");
    const rows = (result.recordset ?? []) as any[];
    const row = rows[0] ?? null;
    return { row, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const rows = await query<any>("SELECT TOP 1 * FROM Inventario WHERE CODIGO = @codigo", { codigo });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function createInventario(body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Inventario_Insert");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Inventario_Insert failed");
  } catch {
    // Fallback
  }

  await createRow("dbo", "Inventario", body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function updateInventario(codigo: string, body: Record<string, unknown>): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(15), codigo);
    req.input("RowXml", sql.NVarChar(sql.MAX), recordToRowXml(body));
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Inventario_Update");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Inventario_Update failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await updateRow("dbo", "Inventario", key, body);
  return { ok: true, executionMode: "ts_fallback" };
}

export async function deleteInventario(codigo: string): Promise<{ ok: boolean; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Codigo", sql.NVarChar(15), codigo);
    req.output("Resultado", sql.Int);
    req.output("Mensaje", sql.NVarChar(500));

    await req.execute("usp_Inventario_Delete");
    const resultado = req.parameters.Resultado?.value as number;
    const mensaje = (req.parameters.Mensaje?.value as string) ?? "";

    if (resultado === 1) {
      return { ok: true, executionMode: "sp" };
    }
    throw new Error(mensaje || "usp_Inventario_Delete failed");
  } catch {
    // Fallback
  }

  const key = encodeKeyObject({ CODIGO: codigo });
  await deleteRow("dbo", "Inventario", key);
  return { ok: true, executionMode: "ts_fallback" };
}
