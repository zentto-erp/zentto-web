import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { anularFacturaTx, emitirFacturaTx, getDetalleFactura, getFacturaByNumero, getFacturas } from "../facturas/service.js";
import { createCotizacionTx, getCotizacion, getCotizacionDetalle, listCotizaciones } from "../cotizaciones/service.js";
import { anularPedidoTx, emitirPedidoTx, facturarPedidoTx, getPedido, getPedidoDetalle, listPedidos } from "../pedidos/service.js";
import { notasService } from "../notas/service.js";
import { anularPresupuestoTx, emitirPresupuestoTx, getPresupuesto, getPresupuestoDetalle, listPresupuestos } from "../presupuestos/service.js";

export type TipoOperacionVenta = "FACT" | "PRESUP" | "PEDIDO" | "COTIZ" | "NOTACRED" | "NOTADEB" | "NOTA_ENT";

type SqlTx = sql.Transaction;

const colCache = new Map<string, Set<string>>();

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

async function txQuery<T>(tx: SqlTx, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  const result = await req.query<T>(statement);
  return result.recordset;
}

async function txExec(tx: SqlTx, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  return req.query(statement);
}

async function tableExists(table: string) {
  const rows = await query<{ cnt: number }>("SELECT COUNT(1) AS cnt FROM sys.tables WHERE name = @table", { table });
  return Number(rows[0]?.cnt ?? 0) > 0;
}

async function getColumns(table: string) {
  const key = table.toUpperCase();
  const cached = colCache.get(key);
  if (cached) return cached;
  const rows = await query<{ COLUMN_NAME: string }>(
    `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @table`,
    { table }
  );
  const cols = new Set(rows.map((r) => String(r.COLUMN_NAME).toUpperCase()));
  colCache.set(key, cols);
  return cols;
}

function docNumCol(cols: Set<string>) {
  return cols.has("NUM_DOC") ? "NUM_DOC" : "NUM_FACT";
}

function detailOrderExpr(cols: Set<string>) {
  if (cols.has("RENGLON")) return "ISNULL(RENGLON,0)";
  if (cols.has("ID")) return "ID";
  if (cols.has("ID".toLowerCase().toUpperCase())) return "ID";
  if (cols.has("ID".toLowerCase())) return "Id";
  return "(SELECT 1)";
}

async function hasUnifiedVenta() {
  return (await tableExists("DocumentosVenta")) && (await tableExists("DocumentosVentaDetalle"));
}

async function getColumnsTx(tx: SqlTx, table: string) {
  const key = table.toUpperCase();
  const cached = colCache.get(key);
  if (cached) return cached;
  const rows = await txQuery<{ COLUMN_NAME: string }>(
    tx,
    `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @table`,
    { table }
  );
  const cols = new Set(rows.map((r) => String(r.COLUMN_NAME).toUpperCase()));
  colCache.set(key, cols);
  return cols;
}

function filterByColumns(row: Record<string, unknown>, cols: Set<string>) {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    if (cols.has(k.toUpperCase())) out[k] = v;
  }
  return out;
}

async function insertDynamicTx(tx: SqlTx, table: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row).filter((k) => row[k] !== undefined);
  if (!keys.length) return;
  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");
  const req = new sql.Request(tx);
  for (const k of keys) req.input(`${prefix}_${k}`, row[k] as any);
  await req.query(`INSERT INTO [dbo].[${table}] (${cols}) VALUES (${vals})`);
}

function mapHeaderUnified(tipoOperacion: TipoOperacionVenta, documento: Record<string, unknown>, docOrigen?: string, tipoDocOrigen?: string) {
  const numDoc = asString(getValue(documento, "NUM_DOC", "NUM_FACT")).trim();
  const fecha = getValue(documento, "FECHA") ?? new Date();
  const total = asNumber(getValue(documento, "TOTAL"), 0);
  const subtotal = asNumber(getValue(documento, "SUBTOTAL"), total);
  const iva = asNumber(getValue(documento, "IVA"), 0);
  const observ = getValue(documento, "OBSERV", "OBSERVACIONES");
  const pago = asString(getValue(documento, "PAGO"), "");
  const cancelada = ["CONTADO", "EFECTIVO", "PAGADA", "S"].includes(pago.toUpperCase()) ? "S" : "N";

  return {
    NUM_FACT: numDoc,
    NUM_DOC: numDoc,
    SERIALTIPO: asString(getValue(documento, "SERIALTIPO"), ""),
    Tipo_Orden: asString(getValue(documento, "Tipo_Orden"), "1"),
    TIPO_OPERACION: tipoOperacion,
    CODIGO: getValue(documento, "CODIGO", "COD_CLIENTE"),
    NOMBRE: getValue(documento, "NOMBRE"),
    RIF: getValue(documento, "RIF"),
    FECHA: fecha,
    SUBTOTAL: subtotal,
    IVA: iva,
    ALICUOTA: asNumber(getValue(documento, "ALICUOTA"), 0),
    TOTAL: total,
    ANULADA: asNumber(getValue(documento, "ANULADA"), 0),
    CANCELADA: asString(getValue(documento, "CANCELADA"), cancelada),
    FACTURADA: asString(getValue(documento, "FACTURADA"), "N"),
    DOC_ORIGEN: docOrigen ?? getValue(documento, "DOC_ORIGEN"),
    TIPO_DOC_ORIGEN: tipoDocOrigen ?? getValue(documento, "TIPO_DOC_ORIGEN"),
    OBSERV: observ,
    CONCEPTO: getValue(documento, "CONCEPTO"),
    COD_USUARIO: getValue(documento, "COD_USUARIO"),
    FECHA_REPORTE: getValue(documento, "FECHA_REPORTE")
  };
}

function mapDetalleUnified(tipoOperacion: TipoOperacionVenta, numDoc: string, detalle: Record<string, unknown>[]) {
  return detalle.map((d, i) => {
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    const precio = asNumber(getValue(d, "PRECIO", "PRECIO_VENTA", "PRECIO_COSTO"), 0);
    const descuento = asNumber(getValue(d, "DESCUENTO"), 0);
    const subtotal = cantidad * precio;
    const total = asNumber(getValue(d, "TOTAL"), subtotal - descuento);
    const alicuota = asNumber(getValue(d, "ALICUOTA"), 0);
    return {
      NUM_FACT: numDoc,
      NUM_DOC: numDoc,
      TIPO_OPERACION: tipoOperacion,
      SERIALTIPO: getValue(d, "SERIALTIPO"),
      Tipo_Orden: getValue(d, "Tipo_Orden"),
      RENGLON: i + 1,
      COD_SERV: getValue(d, "COD_SERV", "CODIGO", "REFERENCIA"),
      DESCRIPCION: getValue(d, "DESCRIPCION"),
      CANTIDAD: cantidad,
      PRECIO: precio,
      SUBTOTAL: subtotal,
      DESCUENTO: descuento,
      TOTAL: total,
      ALICUOTA: alicuota,
      MONTO_IVA: asNumber(getValue(d, "MONTO_IVA"), total * (alicuota / 100)),
      ANULADA: asNumber(getValue(d, "ANULADA"), 0),
      CO_USUARIO: getValue(d, "CO_USUARIO")
    };
  });
}

function mapPagosUnified(tipoOperacion: TipoOperacionVenta, numDoc: string, formasPago: Record<string, unknown>[]) {
  return formasPago.map((fp) => ({
    NUM_DOC: numDoc,
    TIPO_OPERACION: tipoOperacion,
    TIPO_PAGO: getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"),
    BANCO: getValue(fp, "banco", "BANCO"),
    NUMERO: getValue(fp, "numero", "NUMERO", "cheque"),
    MONTO: asNumber(getValue(fp, "monto", "MONTO"), 0),
    MONTO_BS: asNumber(getValue(fp, "montoBs", "MONTO_BS"), asNumber(getValue(fp, "monto", "MONTO"), 0)),
    TASA_CAMBIO: asNumber(getValue(fp, "tasa", "TASA_CAMBIO"), 1),
    FECHA: getValue(fp, "fecha", "FECHA") ?? new Date(),
    FECHA_VENCE: getValue(fp, "fechaVence", "FECHA_VENCE"),
    REFERENCIA: getValue(fp, "referencia", "REFERENCIA"),
    CO_USUARIO: getValue(fp, "CO_USUARIO")
  }));
}

async function upsertDocumentoVentaUnifiedTx(tx: SqlTx, input: {
  tipoOperacion: TipoOperacionVenta;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  docOrigen?: string;
  tipoDocOrigen?: string;
}) {
  const headerRaw = mapHeaderUnified(input.tipoOperacion, input.documento, input.docOrigen, input.tipoDocOrigen);
  const numDoc = asString(headerRaw.NUM_DOC).trim();
  if (!numDoc) throw new Error("missing_num_doc");

  const headCols = await getColumnsTx(tx, "DocumentosVenta");
  const detCols = await getColumnsTx(tx, "DocumentosVentaDetalle");
  const hasPago = await tableExists("DocumentosVentaPago");
  const pagoCols = hasPago ? await getColumnsTx(tx, "DocumentosVentaPago") : new Set<string>();

  const headNum = docNumCol(headCols);
  const detNum = docNumCol(detCols);
  const detHasTipoOperacion = detCols.has("TIPO_OPERACION");
  const serial = asString(headerRaw.SERIALTIPO, "");
  const tipoOrden = asString(headerRaw.Tipo_Orden, "1");

  if (detHasTipoOperacion) {
    await txExec(tx, `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc AND TIPO_OPERACION = @tipo`, {
      numDoc,
      tipo: input.tipoOperacion
    });
  } else if (detCols.has("SERIALTIPO") && detCols.has("TIPO_ORDEN")) {
    await txExec(
      tx,
      `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc AND SERIALTIPO = @serial AND Tipo_Orden = @tipoOrden`,
      { numDoc, serial, tipoOrden }
    );
  } else {
    await txExec(tx, `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc`, { numDoc });
  }
  if (hasPago) {
    await txExec(tx, "DELETE FROM [dbo].[DocumentosVentaPago] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipo", { numDoc, tipo: input.tipoOperacion });
  }
  await txExec(tx, `DELETE FROM [dbo].[DocumentosVenta] WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = @tipo`, {
    numDoc,
    tipo: input.tipoOperacion
  });

  const header = filterByColumns(headerRaw, headCols);
  await insertDynamicTx(tx, "DocumentosVenta", header, "h");

  const detalleRows = mapDetalleUnified(input.tipoOperacion, numDoc, input.detalle)
    .map((r) => ({ ...r, SERIALTIPO: r.SERIALTIPO ?? serial, Tipo_Orden: r.Tipo_Orden ?? tipoOrden }))
    .map((r) => filterByColumns(r, detCols));
  for (let i = 0; i < detalleRows.length; i += 1) await insertDynamicTx(tx, "DocumentosVentaDetalle", detalleRows[i], `d${i}`);

  if (hasPago && (input.formasPago?.length ?? 0) > 0) {
    const pagos = mapPagosUnified(input.tipoOperacion, numDoc, input.formasPago ?? []).map((r) => filterByColumns(r, pagoCols));
    for (let i = 0; i < pagos.length; i += 1) await insertDynamicTx(tx, "DocumentosVentaPago", pagos[i], `p${i}`);
  }

  return { numDoc, detalleRows: detalleRows.length, formasPagoRows: input.formasPago?.length ?? 0 };
}

async function listDocumentosVentaUnified(input: {
  tipoOperacion: TipoOperacionVenta;
  search?: string;
  codigo?: string;
  page?: string;
  limit?: string;
  from?: string;
  to?: string;
}) {
  const headCols = await getColumns("DocumentosVenta");
  const headNum = docNumCol(headCols);
  const page = Math.max(Number(input.page || 1), 1);
  const limit = Math.min(Math.max(Number(input.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = ["TIPO_OPERACION = @tipoOperacion"];
  const params: Record<string, unknown> = { tipoOperacion: input.tipoOperacion };

  if (input.search) {
    where.push("(NUM_DOC LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    params.search = `%${input.search}%`;
  }
  if (input.codigo) {
    where.push("CODIGO = @codigo");
    params.codigo = input.codigo;
  }
  if (input.from) {
    where.push("CAST(FECHA AS date) >= @fromDate");
    params.fromDate = input.from;
  }
  if (input.to) {
    where.push("CAST(FECHA AS date) <= @toDate");
    params.toDate = input.to;
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<any>(
    `SELECT * FROM [dbo].[DocumentosVenta] ${clause} ORDER BY FECHA DESC, ${quoteIdent(headNum)} DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    params
  );
  const totalRows = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM [dbo].[DocumentosVenta] ${clause}`, params);
  return { page, limit, total: Number(totalRows[0]?.total ?? 0), rows, executionMode: "unified" as const };
}

async function getDocumentoVentaUnified(tipoOperacion: TipoOperacionVenta, numFact: string) {
  const headCols = await getColumns("DocumentosVenta");
  const headNum = docNumCol(headCols);
  const rows = await query<any>(
    `SELECT TOP 1 * FROM [dbo].[DocumentosVenta] WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc: numFact, tipoOperacion }
  );
  return { row: rows[0] ?? null, executionMode: "unified" as const };
}

async function getDetalleDocumentoVentaUnified(tipoOperacion: TipoOperacionVenta, numFact: string) {
  const detCols = await getColumns("DocumentosVentaDetalle");
  const detNum = docNumCol(detCols);
  const hasTipo = detCols.has("TIPO_OPERACION");
  if (hasTipo) {
    return query<any>(
      `SELECT * FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion ORDER BY ${detailOrderExpr(detCols)}`,
      { numDoc: numFact, tipoOperacion }
    );
  }
  return query<any>(
    `SELECT * FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc ORDER BY ${detailOrderExpr(detCols)}`,
    { numDoc: numFact }
  );
}

async function emitirDocumentoVentaUnifiedTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const data = await upsertDocumentoVentaUnifiedTx(tx, payload);
    await tx.commit();
    return {
      ok: true,
      numFact: data.numDoc,
      detalleRows: data.detalleRows,
      formaPagoRows: data.formasPagoRows,
      executionMode: "unified"
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}

async function anularDocumentoVentaUnifiedTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const headCols = await getColumnsTx(tx, "DocumentosVenta");
    const detCols = await getColumnsTx(tx, "DocumentosVentaDetalle");
    const hasPago = await tableExists("DocumentosVentaPago");

    const headNum = docNumCol(headCols);
    const detNum = docNumCol(detCols);
    if (headCols.has("ANULADA")) {
      await txExec(
        tx,
        `UPDATE [dbo].[DocumentosVenta] SET ANULADA = 1, FECHA_REPORTE = GETDATE() WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
        { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
      );
    } else {
      await txExec(tx, `DELETE FROM [dbo].[DocumentosVenta] WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion`, {
        numDoc: payload.numFact,
        tipoOperacion: payload.tipoOperacion
      });
    }

    if (detCols.has("ANULADA")) {
      await txExec(
        tx,
        detCols.has("TIPO_OPERACION")
          ? `UPDATE [dbo].[DocumentosVentaDetalle] SET ANULADA = 1 WHERE ${quoteIdent(detNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion`
          : `UPDATE [dbo].[DocumentosVentaDetalle] SET ANULADA = 1 WHERE ${quoteIdent(detNum)} = @numDoc`,
        { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
      );
    } else {
      await txExec(
        tx,
        detCols.has("TIPO_OPERACION")
          ? `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc AND TIPO_OPERACION = @tipoOperacion`
          : `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc`,
        {
        numDoc: payload.numFact,
        tipoOperacion: payload.tipoOperacion
      });
    }

    if (hasPago) {
      await txExec(tx, "DELETE FROM [dbo].[DocumentosVentaPago] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion", {
        numDoc: payload.numFact,
        tipoOperacion: payload.tipoOperacion
      });
    }

    await tx.commit();
    return { ok: true, numFact: payload.numFact, executionMode: "unified" as const };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}

export function normalizeTipoOperacionVenta(value: string): TipoOperacionVenta {
  const raw = String(value || "").trim().toUpperCase();
  const v = raw.replace(/[\s\-]/g, "_");
  const map: Record<string, TipoOperacionVenta> = {
    FACT: "FACT",
    FACTURA: "FACT",
    FACTURAS: "FACT",
    PRESUP: "PRESUP",
    PRESUPUESTO: "PRESUP",
    PRESUPUESTOS: "PRESUP",
    PEDIDO: "PEDIDO",
    PEDIDOS: "PEDIDO",
    COTIZ: "COTIZ",
    COTIZACION: "COTIZ",
    COTIZACIONES: "COTIZ",
    NOTACRED: "NOTACRED",
    NOTA_CRED: "NOTACRED",
    NOTA_CREDITO: "NOTACRED",
    NOTA_CREDITOS: "NOTACRED",
    NOTADEB: "NOTADEB",
    NOTA_DEB: "NOTADEB",
    NOTA_DEBITO: "NOTADEB",
    NOTA_DEBITOS: "NOTADEB",
    NOTA_ENT: "NOTA_ENT",
    NOTA_ENTREGA: "NOTA_ENT",
    NOTAS_ENTREGA: "NOTA_ENT"
  };
  const normalized = map[v] ?? map[raw];
  if (!normalized) throw new Error("tipo_operacion_invalido");
  return normalized;
}

export async function listDocumentosVenta(input: {
  tipoOperacion: TipoOperacionVenta;
  search?: string;
  codigo?: string;
  page?: string;
  limit?: string;
  from?: string;
  to?: string;
}) {
  if (await hasUnifiedVenta()) {
    return listDocumentosVentaUnified(input);
  }

  switch (input.tipoOperacion) {
    case "FACT":
      return getFacturas({ numFact: undefined, codUsuario: undefined, from: input.from, to: input.to, page: input.page, pageSize: input.limit });
    case "PRESUP":
      return listPresupuestos({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
    case "PEDIDO":
      return listPedidos({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
    case "COTIZ":
      return listCotizaciones({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
    case "NOTACRED":
      return notasService.listCredito({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
    case "NOTADEB":
      return notasService.listDebito({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
    case "NOTA_ENT":
      return notasService.listEntrega({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
  }
}

export async function getDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  if (await hasUnifiedVenta()) {
    return getDocumentoVentaUnified(tipoOperacion, numFact);
  }
  switch (tipoOperacion) {
    case "FACT":
      return getFacturaByNumero(numFact);
    case "PRESUP":
      return { row: await getPresupuesto(numFact), executionMode: undefined };
    case "PEDIDO":
      return { row: await getPedido(numFact), executionMode: undefined };
    case "COTIZ":
      return getCotizacion(numFact);
    case "NOTACRED":
      return { row: await notasService.getCredito(numFact), executionMode: undefined };
    case "NOTADEB":
      return { row: await notasService.getDebito(numFact), executionMode: undefined };
    case "NOTA_ENT":
      return { row: await notasService.getEntrega(numFact), executionMode: undefined };
  }
}

export async function getDetalleDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  if (await hasUnifiedVenta()) {
    return getDetalleDocumentoVentaUnified(tipoOperacion, numFact);
  }
  switch (tipoOperacion) {
    case "FACT":
      return getDetalleFactura(numFact);
    case "PRESUP":
      return getPresupuestoDetalle(numFact);
    case "PEDIDO":
      return getPedidoDetalle(numFact);
    case "COTIZ":
      return getCotizacionDetalle(numFact);
    case "NOTACRED":
      return notasService.getCreditoDetalle(numFact);
    case "NOTADEB":
      return notasService.getDebitoDetalle(numFact);
    case "NOTA_ENT":
      return notasService.getEntregaDetalle(numFact);
  }
}

export async function emitirDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  if (await hasUnifiedVenta()) {
    return emitirDocumentoVentaUnifiedTx(payload);
  }

  switch (payload.tipoOperacion) {
    case "FACT":
      return emitirFacturaTx({ factura: payload.documento, detalle: payload.detalle, formasPago: payload.formasPago ?? [], options: payload.options as any });
    case "PRESUP":
      return emitirPresupuestoTx({ presupuesto: payload.documento, detalle: payload.detalle, formasPago: payload.formasPago ?? [], options: payload.options as any });
    case "PEDIDO":
      return emitirPedidoTx({ pedido: payload.documento, detalle: payload.detalle, options: payload.options as any });
    case "COTIZ":
      return createCotizacionTx({ cotizacion: payload.documento, detalle: payload.detalle });
    case "NOTACRED":
      return notasService.emitirCreditoTx({ nota: payload.documento, detalle: payload.detalle, options: payload.options as any });
    case "NOTADEB":
      return notasService.emitirDebitoTx({ nota: payload.documento, detalle: payload.detalle, options: payload.options as any });
    case "NOTA_ENT":
      return notasService.emitirEntregaTx({ nota: payload.documento, detalle: payload.detalle, options: payload.options as any });
  }
}

export async function anularDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  if (await hasUnifiedVenta()) {
    return anularDocumentoVentaUnifiedTx(payload);
  }

  switch (payload.tipoOperacion) {
    case "FACT":
      return anularFacturaTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
    case "PRESUP":
      return anularPresupuestoTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
    case "PEDIDO":
      return anularPedidoTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo, revertirInventario: true });
    case "COTIZ":
      throw new Error("anular_cotizacion_no_implementado");
    case "NOTACRED":
      return notasService.anularCreditoTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
    case "NOTADEB":
      return notasService.anularDebitoTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
    case "NOTA_ENT":
      return notasService.anularEntregaTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
  }
}

export async function facturarDesdePedidoTx(payload: {
  numFactPedido: string;
  factura: Record<string, unknown>;
  formasPago?: Record<string, unknown>[];
  options?: { generarCxC?: boolean; actualizarSaldosCliente?: boolean };
}) {
  if (!(await hasUnifiedVenta())) {
    return facturarPedidoTx(payload);
  }

  const numFactPedido = asString(payload.numFactPedido).trim();
  const numFactFactura = asString(getValue(payload.factura ?? {}, "NUM_FACT", "NUM_DOC")).trim();
  if (!numFactPedido) throw new Error("missing_num_fact_pedido");
  if (!numFactFactura) throw new Error("missing_num_fact_factura");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const headCols = await getColumnsTx(tx, "DocumentosVenta");
    const detCols = await getColumnsTx(tx, "DocumentosVentaDetalle");
    const headNum = docNumCol(headCols);
    const detNum = docNumCol(detCols);

    const pedidoRows = await txQuery<any>(
      tx,
      `SELECT TOP 1 * FROM [dbo].[DocumentosVenta] WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = 'PEDIDO'`,
      { numDoc: numFactPedido }
    );
    const pedido = pedidoRows[0];
    if (!pedido) throw new Error("pedido_not_found");
    if (asNumber(pedido.ANULADA, 0) === 1) throw new Error("pedido_anulado");
    if (String(pedido.FACTURADA ?? "N").toUpperCase() === "S") throw new Error("pedido_already_facturado");

    const detallePedido = await txQuery<any>(
      tx,
      detCols.has("TIPO_OPERACION")
        ? `SELECT * FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc AND TIPO_OPERACION = 'PEDIDO' ORDER BY ${detailOrderExpr(detCols)}`
        : `SELECT * FROM [dbo].[DocumentosVentaDetalle] WHERE ${quoteIdent(detNum)} = @numDoc ORDER BY ${detailOrderExpr(detCols)}`,
      { numDoc: numFactPedido }
    );
    if (!detallePedido.length) throw new Error("pedido_sin_detalle");

    const facturaDoc: Record<string, unknown> = {
      ...payload.factura,
      NUM_DOC: numFactFactura,
      NUM_FACT: numFactFactura,
      CODIGO: getValue(payload.factura ?? {}, "CODIGO") ?? pedido.CODIGO,
      NOMBRE: getValue(payload.factura ?? {}, "NOMBRE") ?? pedido.NOMBRE,
      RIF: getValue(payload.factura ?? {}, "RIF") ?? pedido.RIF,
      FECHA: getValue(payload.factura ?? {}, "FECHA") ?? new Date(),
      TOTAL: getValue(payload.factura ?? {}, "TOTAL") ?? pedido.TOTAL,
      DOC_ORIGEN: numFactPedido,
      TIPO_DOC_ORIGEN: "PEDIDO",
      COD_USUARIO: getValue(payload.factura ?? {}, "COD_USUARIO") ?? pedido.COD_USUARIO ?? "API"
    };

    const detalleFactura = detallePedido.map((d) => ({
      COD_SERV: d.COD_SERV,
      DESCRIPCION: d.DESCRIPCION,
      CANTIDAD: d.CANTIDAD,
      PRECIO: d.PRECIO,
      SUBTOTAL: d.SUBTOTAL,
      DESCUENTO: d.DESCUENTO,
      TOTAL: d.TOTAL,
      ALICUOTA: d.ALICUOTA,
      MONTO_IVA: d.MONTO_IVA
    }));

    const facturaMirror = await upsertDocumentoVentaUnifiedTx(tx, {
      tipoOperacion: "FACT",
      documento: facturaDoc,
      detalle: detalleFactura,
      formasPago: payload.formasPago ?? [],
      docOrigen: numFactPedido,
      tipoDocOrigen: "PEDIDO"
    });

    const patch: string[] = [];
    if (headCols.has("FACTURADA")) patch.push("FACTURADA = 'S'");
    if (headCols.has("FECHA_REPORTE")) patch.push("FECHA_REPORTE = GETDATE()");
    if (patch.length) {
      await txExec(
        tx,
        `UPDATE [dbo].[DocumentosVenta] SET ${patch.join(", ")} WHERE ${quoteIdent(headNum)} = @numDoc AND TIPO_OPERACION = 'PEDIDO'`,
        { numDoc: numFactPedido }
      );
    }

    await tx.commit();
    return {
      ok: true,
      pedido: numFactPedido,
      factura: numFactFactura,
      inventarioReDescontado: false,
      facturaResult: {
        ok: true,
        numFact: facturaMirror.numDoc,
        detalleRows: facturaMirror.detalleRows,
        formaPagoRows: facturaMirror.formasPagoRows,
        executionMode: "unified"
      }
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}
