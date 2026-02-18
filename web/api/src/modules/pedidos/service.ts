import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";
import { emitirFacturaTx, type EmitirFacturaPayload } from "../facturas/service.js";

export type ListPedidosParams = { search?: string; codigo?: string; page?: string; limit?: string };
export type ListPedidosResult = { page: number; limit: number; total: number; rows: any[]; executionMode?: "sp" | "ts_fallback" };

export async function listPedidos(params: ListPedidosParams): Promise<ListPedidosResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Codigo", sql.NVarChar(10), params.codigo ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);
    const result = await req.execute("usp_Pedidos_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as any[];
    return { page, limit, total, rows, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("CODIGO = @codigo");
    sqlParams.codigo = params.codigo;
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Pedidos ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Pedidos ${clause}`, sqlParams);
  return { page, limit, total: Number(totalResult[0]?.total ?? 0), rows, executionMode: "ts_fallback" };
}

export async function getPedido(numFact: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("NumFact", sql.NVarChar(20), numFact);
    const result = await req.execute("usp_Pedidos_GetByNumFact");
    const rows = (result.recordset ?? []) as any[];
    return { row: rows[0] ?? null, executionMode: "sp" };
  } catch {
    // Fallback
  }
  const rows = await query<any>("SELECT TOP 1 * FROM Pedidos WHERE NUM_FACT = @numFact", { numFact });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function getPedidoDetalle(numFact: string) {
  return query<any>("SELECT * FROM Detalle_Pedidos WHERE NUM_FACT = @numFact ORDER BY ID", { numFact });
}

export async function createPedido(body: Record<string, unknown>) {
  return createRow("dbo", "Pedidos", body);
}

export async function updatePedido(numFact: string, body: Record<string, unknown>) {
  return updateRow("dbo", "Pedidos", encodeKeyObject({ NUM_FACT: numFact }), body);
}

export async function deletePedido(numFact: string) {
  return deleteRow("dbo", "Pedidos", encodeKeyObject({ NUM_FACT: numFact }));
}

export async function createPedidoTx(payload: { pedido: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({
    headerTable: "[dbo].[Pedidos]",
    detailTable: "[dbo].[Detalle_Pedidos]",
    header: payload.pedido ?? {},
    details: payload.detalle ?? [],
    linkFields: ["NUM_FACT", "SERIALTIPO"]
  });
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

function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
}

function buildInsert(table: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row);
  if (!keys.length) throw new Error("empty_row");
  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");
  return {
    statement: `INSERT INTO ${table} (${cols}) VALUES (${vals})`,
    params: keys.map((k) => ({ key: `${prefix}_${k}`, value: row[k] }))
  };
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

async function getPedidoColumns(tx: sql.Transaction) {
  const rows = await txQuery<{ COLUMN_NAME: string }>(
    tx,
    `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Pedidos'`
  );
  return new Set(rows.map((r) => String(r.COLUMN_NAME).toUpperCase()));
}

async function updatePedidoState(
  tx: sql.Transaction,
  numFact: string,
  patch: Record<string, unknown>
) {
  const cols = await getPedidoColumns(tx);
  const entries = Object.entries(patch).filter(([k]) => cols.has(k.toUpperCase()));
  if (!entries.length) return;
  const sets = entries.map(([k]) => `${quoteIdent(k)} = @u_${k}`).join(", ");
  const params: Record<string, unknown> = { numFact };
  for (const [k, v] of entries) params[`u_${k}`] = v;
  await txExec(tx, `UPDATE [dbo].[Pedidos] SET ${sets} WHERE NUM_FACT = @numFact`, params);
}

export async function emitirPedidoTx(payload: {
  pedido: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: { comprometerInventario?: boolean };
}) {
  const pedido = payload.pedido ?? {};
  const detalle = payload.detalle ?? [];
  const comprometerInventario = payload.options?.comprometerInventario !== false;
  const numFact = asString(getValue(pedido, "NUM_FACT"));
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const reqPedido = new sql.Request(tx);
    const insPedido = buildInsert("[dbo].[Pedidos]", pedido, "ped");
    for (const p of insPedido.params) reqPedido.input(p.key, p.value as any);
    await reqPedido.query(insPedido.statement);

    const byCodigo = new Map<string, number>();
    for (let i = 0; i < detalle.length; i += 1) {
      const row = { ...detalle[i] };
      if (!getValue(row, "NUM_FACT")) row.NUM_FACT = numFact;
      const reqDet = new sql.Request(tx);
      const insDet = buildInsert("[dbo].[Detalle_Pedidos]", row, `det${i}`);
      for (const p of insDet.params) reqDet.input(p.key, p.value as any);
      await reqDet.query(insDet.statement);

      const codigo = asString(getValue(row, "CODIGO", "COD_SERV", "REFERENCIA")).trim();
      const cantidad = asNumber(getValue(row, "CANTIDAD"));
      if (codigo && cantidad > 0) byCodigo.set(codigo, asNumber(byCodigo.get(codigo), 0) + cantidad);
    }

    if (comprometerInventario) {
      for (const [codigo, cantidad] of byCodigo.entries()) {
        const inv = await txQuery<{ EXISTENCIA: number; COSTO_REFERENCIA: number; PRECIO_VENTA: number }>(
          tx,
          "SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, PRECIO_VENTA FROM [dbo].[Inventario] WHERE CODIGO = @codigo",
          { codigo }
        );
        const actual = asNumber(inv[0]?.EXISTENCIA, 0);
        await txExec(
          tx,
          "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) - @cantidad WHERE CODIGO = @codigo",
          { codigo, cantidad }
        );
        await txExec(
          tx,
          `INSERT INTO [dbo].[MovInvent] (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, PRECIO_VENTA)
           VALUES (@codigo, @codigo, @numFact, GETDATE(), @motivo, 'Egreso', @actual, @cantidad, @nueva, @usuario, @pc, @pv)`,
          {
            codigo,
            numFact,
            motivo: `Pedido:${numFact}`,
            actual,
            cantidad,
            nueva: actual - cantidad,
            usuario: asString(getValue(pedido, "COD_USUARIO"), "API"),
            pc: asNumber(inv[0]?.COSTO_REFERENCIA, 0),
            pv: asNumber(inv[0]?.PRECIO_VENTA, 0)
          }
        );
      }
    }

    await updatePedidoState(tx, numFact, {
      FACTURADO: 0,
      ANULADA: 0,
      ESTADO: "PENDIENTE",
      INVENTARIO_COMPROMETIDO: comprometerInventario ? 1 : 0
    });

    await tx.commit();
    return { ok: true, numFact, detalleRows: detalle.length, inventarioComprometido: comprometerInventario };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

export async function anularPedidoTx(input: {
  numFact: string;
  codUsuario?: string;
  motivo?: string;
  revertirInventario?: boolean;
}) {
  const numFact = asString(input.numFact).trim();
  if (!numFact) throw new Error("missing_num_fact");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const pedRows = await txQuery<any>(tx, "SELECT TOP 1 * FROM [dbo].[Pedidos] WHERE NUM_FACT = @numFact", { numFact });
    const pedido = pedRows[0];
    if (!pedido) throw new Error("pedido_not_found");
    if (asNumber(getValue(pedido, "ANULADA"), 0) === 1) throw new Error("pedido_already_anulado");
    if (asNumber(getValue(pedido, "FACTURADO"), 0) === 1) throw new Error("pedido_already_facturado");

    const detalle = await txQuery<any>(tx, "SELECT * FROM [dbo].[Detalle_Pedidos] WHERE NUM_FACT = @numFact", { numFact });

    if (input.revertirInventario !== false) {
      for (const d of detalle) {
        const codigo = asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")).trim();
        const cantidad = asNumber(getValue(d, "CANTIDAD"));
        if (!codigo || cantidad <= 0) continue;
        const inv = await txQuery<{ EXISTENCIA: number; COSTO_REFERENCIA: number; PRECIO_VENTA: number }>(
          tx,
          "SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, PRECIO_VENTA FROM [dbo].[Inventario] WHERE CODIGO = @codigo",
          { codigo }
        );
        const actual = asNumber(inv[0]?.EXISTENCIA, 0);
        await txExec(
          tx,
          "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) + @cantidad WHERE CODIGO = @codigo",
          { codigo, cantidad }
        );
        await txExec(
          tx,
          `INSERT INTO [dbo].[MovInvent] (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, PRECIO_VENTA)
           VALUES (@codigo, @codigo, @numFact, GETDATE(), @motivo, 'Ingreso', @actual, @cantidad, @nueva, @usuario, @pc, @pv)`,
          {
            codigo,
            numFact,
            motivo: input.motivo ? `AnulPedido:${input.motivo}` : `AnulPedido:${numFact}`,
            actual,
            cantidad,
            nueva: actual + cantidad,
            usuario: asString(input.codUsuario, "API"),
            pc: asNumber(inv[0]?.COSTO_REFERENCIA, 0),
            pv: asNumber(inv[0]?.PRECIO_VENTA, 0)
          }
        );
      }
    }

    await updatePedidoState(tx, numFact, {
      ANULADA: 1,
      ESTADO: "ANULADO"
    });

    await tx.commit();
    return { ok: true, numFact, inventarioRevertido: input.revertirInventario !== false };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

export async function facturarPedidoTx(payload: {
  numFactPedido: string;
  factura: Record<string, unknown>;
  formasPago?: Record<string, unknown>[];
  options?: { generarCxC?: boolean; actualizarSaldosCliente?: boolean };
}) {
  const numFactPedido = asString(payload.numFactPedido).trim();
  if (!numFactPedido) throw new Error("missing_num_fact_pedido");

  const pedido = await query<any>("SELECT TOP 1 * FROM [dbo].[Pedidos] WHERE NUM_FACT = @numFact", { numFact: numFactPedido });
  const ped = pedido[0];
  if (!ped) throw new Error("pedido_not_found");
  if (asNumber(getValue(ped, "ANULADA"), 0) === 1) throw new Error("pedido_anulado");
  if (asNumber(getValue(ped, "FACTURADO"), 0) === 1) throw new Error("pedido_already_facturado");

  const detPedido = await query<any>("SELECT * FROM [dbo].[Detalle_Pedidos] WHERE NUM_FACT = @numFact", { numFact: numFactPedido });
  if (!detPedido.length) throw new Error("pedido_sin_detalle");

  const factura = { ...(payload.factura ?? {}) };
  if (!factura.NUM_FACT) throw new Error("missing_num_fact_factura");
  if (!factura.CODIGO) factura.CODIGO = getValue(ped, "CODIGO", "COD_CLIENTE");
  if (!factura.NOMBRE) factura.NOMBRE = getValue(ped, "NOMBRE");
  if (!factura.RIF) factura.RIF = getValue(ped, "RIF");
  if (!factura.FECHA) factura.FECHA = new Date().toISOString().slice(0, 10);
  if (!factura.COD_USUARIO) factura.COD_USUARIO = getValue(ped, "COD_USUARIO") ?? "API";
  if (!factura.OBSERV) factura.OBSERV = `Desde Pedido ${numFactPedido}`;

  const detalleFactura = detPedido.map((d) => {
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    const precio = asNumber(getValue(d, "PRECIO_VENTA", "PRECIO", "PRECIO_COSTO"), 0);
    const alicuota = asNumber(getValue(d, "ALICUOTA", "Alicuota"), 0);
    return {
      COD_SERV: asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")),
      CANTIDAD: cantidad,
      PRECIO: precio,
      ALICUOTA: alicuota,
      TOTAL: cantidad * precio,
      SERIALTIPO: getValue(factura, "SERIALTIPO") ?? getValue(d, "SERIALTIPO") ?? null
    };
  });

  const resultFactura = await emitirFacturaTx({
    factura,
    detalle: detalleFactura,
    formasPago: payload.formasPago ?? [],
    options: {
      actualizarInventario: false,
      generarCxC: payload.options?.generarCxC !== false,
      actualizarSaldosCliente: payload.options?.actualizarSaldosCliente !== false
    }
  } satisfies EmitirFacturaPayload);

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    await updatePedidoState(tx, numFactPedido, {
      FACTURADO: 1,
      ESTADO: "FACTURADO",
      NUM_FACTURA: asString(factura.NUM_FACT)
    });
    await tx.commit();
  } catch (err) {
    await tx.rollback();
    throw err;
  }

  return {
    ok: true,
    pedido: numFactPedido,
    factura: asString(factura.NUM_FACT),
    inventarioReDescontado: false,
    facturaResult: resultFactura
  };
}
