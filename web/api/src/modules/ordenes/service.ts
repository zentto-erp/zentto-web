import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";
import { emitirCompraTx } from "../compras/service.js";

export async function listOrdenes(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.codigo) { where.push("CODIGO = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Ordenes ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Ordenes ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
export async function getOrden(numFact: string) { const rows = await query<any>("SELECT TOP 1 * FROM Ordenes WHERE NUM_FACT = @numFact", { numFact }); return rows[0] ?? null; }
export async function getOrdenDetalle(numFact: string) { return query<any>("SELECT * FROM Detalle_Ordenes WHERE NUM_FACT = @numFact ORDER BY ID", { numFact }); }
export async function createOrden(body: Record<string, unknown>) { return createRow("dbo", "Ordenes", body); }
export async function updateOrden(numFact: string, body: Record<string, unknown>) { return updateRow("dbo", "Ordenes", encodeKeyObject({ NUM_FACT: numFact }), body); }
export async function deleteOrden(numFact: string) { return deleteRow("dbo", "Ordenes", encodeKeyObject({ NUM_FACT: numFact })); }
export async function createOrdenTx(payload: { orden: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({ headerTable: "[dbo].[Ordenes]", detailTable: "[dbo].[Detalle_Ordenes]", header: payload.orden ?? {}, details: payload.detalle ?? [], linkFields: ["NUM_FACT", "SERIALTIPO"] });
}

function normalizeKey(key: string) {
  return key.trim().toUpperCase();
}

function getValue(row: Record<string, unknown>, ...candidates: string[]) {
  const keys = Object.keys(row);
  for (const candidate of candidates) {
    const k = keys.find((x) => normalizeKey(x) === normalizeKey(candidate));
    if (k) return row[k];
  }
  return undefined;
}

function asNumber(v: unknown, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function asString(v: unknown, fallback = "") {
  if (v === null || v === undefined) return fallback;
  return String(v);
}

async function txQuery<T>(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  const result = await req.query<T>(statement);
  return result.recordset;
}

async function txExec(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  return req.query(statement);
}

async function getOrdenColumns(tx: sql.Transaction) {
  const rows = await txQuery<{ COLUMN_NAME: string }>(
    tx,
    `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Ordenes'`
  );
  return new Set(rows.map((r) => String(r.COLUMN_NAME).toUpperCase()));
}

async function updateOrdenState(tx: sql.Transaction, numFact: string, patch: Record<string, unknown>) {
  const cols = await getOrdenColumns(tx);
  const entries = Object.entries(patch).filter(([k]) => cols.has(k.toUpperCase()));
  if (!entries.length) return;
  const sets = entries.map(([k]) => `[${k.replace(/]/g, "]]")}] = @u_${k}`).join(", ");
  const params: Record<string, unknown> = { numFact };
  for (const [k, v] of entries) params[`u_${k}`] = v;
  await txExec(tx, `UPDATE [dbo].[Ordenes] SET ${sets} WHERE NUM_FACT = @numFact`, params);
}

export async function cerrarOrdenConCompraTx(payload: {
  numFactOrden: string;
  compra: Record<string, unknown>;
  detalle?: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxP?: boolean;
    actualizarSaldosProveedor?: boolean;
  };
}) {
  const numFactOrden = asString(payload.numFactOrden).trim();
  if (!numFactOrden) throw new Error("missing_num_fact_orden");

  const ordenRows = await query<any>("SELECT TOP 1 * FROM [dbo].[Ordenes] WHERE NUM_FACT = @numFact", { numFact: numFactOrden });
  const orden = ordenRows[0];
  if (!orden) throw new Error("orden_not_found");
  if (asNumber(getValue(orden, "ANULADA"), 0) === 1) throw new Error("orden_anulada");
  if (asNumber(getValue(orden, "CERRADA", "FACTURADA"), 0) === 1) throw new Error("orden_ya_cerrada");

  const detalleOrden = await query<any>("SELECT * FROM [dbo].[Detalle_Ordenes] WHERE NUM_FACT = @numFact", { numFact: numFactOrden });
  if (!detalleOrden.length && !(payload.detalle?.length)) throw new Error("orden_sin_detalle");

  const compra = { ...(payload.compra ?? {}) };
  if (!compra.NUM_FACT) throw new Error("missing_num_fact_compra");
  if (!compra.COD_PROVEEDOR) compra.COD_PROVEEDOR = getValue(orden, "CODIGO", "COD_PROVEEDOR");
  if (!compra.NOMBRE) compra.NOMBRE = getValue(orden, "NOMBRE");
  if (!compra.RIF) compra.RIF = getValue(orden, "RIF");
  if (!compra.FECHA) compra.FECHA = new Date().toISOString().slice(0, 10);
  if (!compra.COD_USUARIO) compra.COD_USUARIO = getValue(orden, "COD_USUARIO") ?? "API";
  if (!compra.TIPO) compra.TIPO = getValue(orden, "TIPO") ?? "CONTADO";
  if (!compra.CONCEPTO) compra.CONCEPTO = `Cierre Orden ${numFactOrden}`;

  const detalle = (payload.detalle?.length ? payload.detalle : detalleOrden).map((d) => ({
    CODIGO: asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")),
    REFERENCIA: getValue(d, "REFERENCIA"),
    DESCRIPCION: asString(getValue(d, "DESCRIPCION"), ""),
    CANTIDAD: asNumber(getValue(d, "CANTIDAD"), 0),
    PRECIO_COSTO: asNumber(getValue(d, "PRECIO_COSTO", "PRECIO", "PRECIO_COMPRA"), 0),
    ALICUOTA: asNumber(getValue(d, "ALICUOTA", "Alicuota"), 0)
  }));

  const total = detalle.reduce((acc, d) => acc + asNumber(d.CANTIDAD) * asNumber(d.PRECIO_COSTO), 0);
  if (!asNumber(compra.TOTAL, 0)) compra.TOTAL = total;

  const compraResult = await emitirCompraTx({
    compra,
    detalle,
    options: {
      actualizarInventario: payload.options?.actualizarInventario !== false,
      generarCxP: payload.options?.generarCxP !== false,
      actualizarSaldosProveedor: payload.options?.actualizarSaldosProveedor !== false
    }
  });

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    await updateOrdenState(tx, numFactOrden, {
      CERRADA: 1,
      FACTURADA: 1,
      ESTADO: "CERRADA",
      NUM_FACT_COMPRA: asString(compra.NUM_FACT)
    });
    await tx.commit();
  } catch (err) {
    await tx.rollback();
    throw err;
  }

  return {
    ok: true,
    orden: numFactOrden,
    compra: asString(compra.NUM_FACT),
    compraResult
  };
}
