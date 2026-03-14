import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";

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
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) req.input(k, v as any);
    }
  }
  const result = await req.query<T>(statement);
  return result.recordset;
}

async function txExec(tx: SqlTx, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) req.input(k, v as any);
    }
  }
  return req.query(statement);
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

function filterByColumns(row: Record<string, unknown>, cols: Set<string>) {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    if (cols.has(k.toUpperCase())) out[k] = v;
  }
  return out;
}

function withAuditFields(row: Record<string, unknown>) {
  return {
    ...row,
    CreatedAt: row.CreatedAt ?? new Date(),
    UpdatedAt: new Date(),
    IsDeleted: row.IsDeleted ?? 0
  };
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
    NUM_DOC: numDoc,
    SERIALTIPO: asString(getValue(documento, "SERIALTIPO"), ""),
    TIPO_OPERACION: tipoOperacion,
    CODIGO: getValue(documento, "CODIGO", "COD_CLIENTE"),
    NOMBRE: getValue(documento, "NOMBRE"),
    RIF: getValue(documento, "RIF"),
    FECHA: fecha,
    FECHA_VENCE: getValue(documento, "FECHA_VENCE"),
    SUBTOTAL: subtotal,
    MONTO_GRA: getValue(documento, "MONTO_GRA"),
    MONTO_EXE: getValue(documento, "MONTO_EXE"),
    IVA: iva,
    ALICUOTA: asNumber(getValue(documento, "ALICUOTA"), 0),
    TOTAL: total,
    DESCUENTO: getValue(documento, "DESCUENTO"),
    ANULADA: asNumber(getValue(documento, "ANULADA"), 0),
    CANCELADA: asString(getValue(documento, "CANCELADA"), cancelada),
    FACTURADA: asString(getValue(documento, "FACTURADA"), "N"),
    ENTREGADA: asString(getValue(documento, "ENTREGADA"), "N"),
    DOC_ORIGEN: docOrigen ?? getValue(documento, "DOC_ORIGEN"),
    TIPO_DOC_ORIGEN: tipoDocOrigen ?? getValue(documento, "TIPO_DOC_ORIGEN"),
    NUM_CONTROL: getValue(documento, "NUM_CONTROL"),
    LEGAL: getValue(documento, "LEGAL"),
    IMPRESA: getValue(documento, "IMPRESA"),
    OBSERV: observ,
    CONCEPTO: getValue(documento, "CONCEPTO"),
    TERMINOS: getValue(documento, "TERMINOS"),
    DESPACHAR: getValue(documento, "DESPACHAR"),
    VENDEDOR: getValue(documento, "VENDEDOR"),
    DEPARTAMENTO: getValue(documento, "DEPARTAMENTO"),
    LOCACION: getValue(documento, "LOCACION"),
    MONEDA: getValue(documento, "MONEDA"),
    TASA_CAMBIO: getValue(documento, "TASA_CAMBIO"),
    COD_USUARIO: getValue(documento, "COD_USUARIO"),
    FECHA_REPORTE: getValue(documento, "FECHA_REPORTE") ?? new Date(),
    COMPUTER: getValue(documento, "COMPUTER"),
    PLACAS: getValue(documento, "PLACAS"),
    KILOMETROS: getValue(documento, "KILOMETROS"),
    PEAJE: getValue(documento, "PEAJE")
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
      NUM_DOC: numDoc,
      TIPO_OPERACION: tipoOperacion,
      RENGLON: i + 1,
      COD_SERV: getValue(d, "COD_SERV", "CODIGO", "REFERENCIA"),
      DESCRIPCION: getValue(d, "DESCRIPCION"),
      COD_ALTERNO: getValue(d, "COD_ALTERNO"),
      CANTIDAD: cantidad,
      PRECIO: precio,
      PRECIO_DESCUENTO: getValue(d, "PRECIO_DESCUENTO"),
      COSTO: getValue(d, "COSTO", "COSTO_REFERENCIA"),
      SUBTOTAL: subtotal,
      DESCUENTO: descuento,
      TOTAL: total,
      ALICUOTA: alicuota,
      MONTO_IVA: asNumber(getValue(d, "MONTO_IVA"), total * (alicuota / 100)),
      ANULADA: asNumber(getValue(d, "ANULADA"), 0),
      RELACIONADA: getValue(d, "RELACIONADA"),
      CO_USUARIO: getValue(d, "CO_USUARIO"),
      FECHA: getValue(d, "FECHA") ?? new Date()
    };
  });
}

function mapPagosUnified(tipoOperacion: TipoOperacionVenta, numDoc: string, formasPago: Record<string, unknown>[]) {
  return formasPago.map((fp) => ({
    NUM_DOC: numDoc,
    TIPO_OPERACION: tipoOperacion,
    TIPO_PAGO: getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"),
    BANCO: getValue(fp, "banco", "BANCO"),
    NUMERO: getValue(fp, "numero", "NUMERO", "numCheque"),
    MONTO: asNumber(getValue(fp, "monto", "MONTO"), 0),
    MONTO_BS: asNumber(getValue(fp, "montoBs", "MONTO_BS"), asNumber(getValue(fp, "monto", "MONTO"), 0)),
    TASA_CAMBIO: asNumber(getValue(fp, "tasa", "TASA_CAMBIO"), 1),
    FECHA: getValue(fp, "fecha", "FECHA") ?? new Date(),
    FECHA_VENCE: getValue(fp, "fechaVence", "FECHA_VENCE", "fechaVencimiento"),
    REFERENCIA: getValue(fp, "referencia", "REFERENCIA"),
    CO_USUARIO: getValue(fp, "CO_USUARIO")
  }));
}

function calculatePendingAmount(total: number, documento: Record<string, unknown>, formasPago: Record<string, unknown>[] | undefined) {
  const pendienteDoc = asNumber(getValue(documento, "PEND", "SALDO", "SALDO_PENDIENTE"), Number.NaN);
  if (Number.isFinite(pendienteDoc) && pendienteDoc >= 0) {
    return pendienteDoc;
  }

  const totalPagado = (formasPago ?? []).reduce((acc, fp) => {
    const tipo = asString(getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"), "").toUpperCase();
    if (tipo.includes("SALDO")) return acc;
    return acc + asNumber(getValue(fp, "monto", "MONTO"), 0);
  }, 0);

  return Math.max(total - totalPagado, 0);
}

async function resolveCanonicalContextTx(tx: SqlTx, codUsuario?: string) {
  const companyRows = await txQuery<{ CompanyId: number }>(
    tx,
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );

  const companyId = Number(companyRows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) {
    throw new Error("canonical_company_not_found");
  }

  const branchRows = await txQuery<{ BranchId: number }>(
    tx,
    `SELECT TOP 1 BranchId
       FROM cfg.Branch
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
      ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId`,
    { companyId }
  );

  const branchId = Number(branchRows[0]?.BranchId ?? 0);
  if (!Number.isFinite(branchId) || branchId <= 0) {
    throw new Error("canonical_branch_not_found");
  }

  let userId: number | null = null;
  if (codUsuario) {
    const userRows = await txQuery<{ UserId: number }>(
      tx,
      `SELECT TOP 1 UserId
         FROM sec.[User]
        WHERE UserCode = @userCode
          AND IsDeleted = 0`,
      { userCode: codUsuario }
    );
    userId = Number(userRows[0]?.UserId ?? 0) || null;
  }

  return { companyId, branchId, userId };
}

async function syncReceivableDocumentTx(tx: SqlTx, input: {
  tipoOperacion: TipoOperacionVenta;
  numDoc: string;
  codigoCliente?: string;
  fecha: Date;
  total: number;
  pending: number;
  observacion?: string;
  codUsuario?: string;
  markVoided?: boolean;
}) {
  if (!["FACT", "NOTADEB", "NOTACRED"].includes(input.tipoOperacion)) {
    return;
  }

  const codigoCliente = asString(input.codigoCliente).trim();
  if (!codigoCliente) return;

  const customerRows = await txQuery<{ CustomerId: number }>(
    tx,
    `SELECT TOP 1 CustomerId
       FROM [master].Customer
      WHERE CustomerCode = @customerCode
        AND IsDeleted = 0`,
    { customerCode: codigoCliente }
  );

  const customerId = Number(customerRows[0]?.CustomerId ?? 0);
  if (!Number.isFinite(customerId) || customerId <= 0) return;

  const { companyId, branchId, userId } = await resolveCanonicalContextTx(tx, input.codUsuario);

  const safePending = Math.max(0, input.pending);
  const status = input.markVoided
    ? "VOIDED"
    : safePending <= 0
      ? "PAID"
      : safePending < input.total
        ? "PARTIAL"
        : "PENDING";

  const existing = await txQuery<{ ReceivableDocumentId: number }>(
    tx,
    `SELECT TOP 1 ReceivableDocumentId
       FROM ar.ReceivableDocument
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND DocumentType = @documentType
        AND DocumentNumber = @documentNumber`,
    {
      companyId,
      branchId,
      documentType: input.tipoOperacion,
      documentNumber: input.numDoc
    }
  );

  if (existing.length) {
    await txExec(
      tx,
      `UPDATE ar.ReceivableDocument
          SET CustomerId = @customerId,
              IssueDate = @issueDate,
              DueDate = @dueDate,
              TotalAmount = @totalAmount,
              PendingAmount = @pendingAmount,
              PaidFlag = @paidFlag,
              Status = @status,
              Notes = @notes,
              UpdatedAt = SYSUTCDATETIME(),
              UpdatedByUserId = @updatedByUserId
        WHERE ReceivableDocumentId = @id`,
      {
        id: existing[0].ReceivableDocumentId,
        customerId,
        issueDate: input.fecha,
        dueDate: input.fecha,
        totalAmount: input.total,
        pendingAmount: input.markVoided ? 0 : safePending,
        paidFlag: input.markVoided || safePending <= 0 ? 1 : 0,
        status,
        notes: input.observacion,
        updatedByUserId: userId
      }
    );
  } else if (!input.markVoided) {
    await txExec(
      tx,
      `INSERT INTO ar.ReceivableDocument
         (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate,
          CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, Notes,
          CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId)
       VALUES
         (@companyId, @branchId, @customerId, @documentType, @documentNumber, @issueDate, @dueDate,
          'USD', @totalAmount, @pendingAmount, @paidFlag, @status, @notes,
          SYSUTCDATETIME(), SYSUTCDATETIME(), @createdByUserId, @updatedByUserId)`,
      {
        companyId,
        branchId,
        customerId,
        documentType: input.tipoOperacion,
        documentNumber: input.numDoc,
        issueDate: input.fecha,
        dueDate: input.fecha,
        totalAmount: input.total,
        pendingAmount: safePending,
        paidFlag: safePending <= 0 ? 1 : 0,
        status,
        notes: input.observacion,
        createdByUserId: userId,
        updatedByUserId: userId
      }
    );
  }

  await txExec(
    tx,
    `UPDATE [master].Customer
        SET TotalBalance = (
              SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ar.ReceivableDocument
               WHERE CustomerId = @customerId
                 AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @updatedByUserId
      WHERE CustomerId = @customerId`,
    { customerId, updatedByUserId: userId }
  );
}

async function upsertDocumentoVentaTx(tx: SqlTx, input: {
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
  const pagoCols = await getColumnsTx(tx, "DocumentosVentaPago");

  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosVentaDetalle] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );
  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosVentaPago] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );
  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosVenta] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );

  const headerRow = filterByColumns(withAuditFields(headerRaw), headCols);
  await insertDynamicTx(tx, "DocumentosVenta", headerRow, "h");

  const detalleRows = mapDetalleUnified(input.tipoOperacion, numDoc, input.detalle).map((row) =>
    filterByColumns(withAuditFields(row), detCols)
  );
  for (let i = 0; i < detalleRows.length; i += 1) {
    await insertDynamicTx(tx, "DocumentosVentaDetalle", detalleRows[i], `d${i}`);
  }

  const pagosRows = mapPagosUnified(input.tipoOperacion, numDoc, input.formasPago ?? []).map((row) =>
    filterByColumns(withAuditFields(row), pagoCols)
  );
  for (let i = 0; i < pagosRows.length; i += 1) {
    await insertDynamicTx(tx, "DocumentosVentaPago", pagosRows[i], `p${i}`);
  }

  const total = asNumber(getValue(headerRaw, "TOTAL"), 0);
  const pendingAmount = asString(getValue(headerRaw, "CANCELADA"), "N").toUpperCase() === "S"
    ? 0
    : calculatePendingAmount(total, input.documento, input.formasPago);

  await syncReceivableDocumentTx(tx, {
    tipoOperacion: input.tipoOperacion,
    numDoc,
    codigoCliente: asString(getValue(headerRaw, "CODIGO"), ""),
    fecha: new Date(getValue(headerRaw, "FECHA") as any ?? new Date()),
    total,
    pending: pendingAmount,
    observacion: asString(getValue(headerRaw, "OBSERV"), ""),
    codUsuario: asString(getValue(headerRaw, "COD_USUARIO"), "")
  });

  return {
    numDoc,
    detalleRows: detalleRows.length,
    formasPagoRows: pagosRows.length,
    pendingAmount
  };
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
  const cols = await getColumns("DocumentosVenta");
  const orderColumn = cols.has("FECHA") ? "FECHA" : "NUM_DOC";
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
    `SELECT *
       FROM [dbo].[DocumentosVenta]
       ${clause}
      ORDER BY ${orderColumn} DESC, NUM_DOC DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    params
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM [dbo].[DocumentosVenta] ${clause}`,
    params
  );

  return {
    page,
    limit,
    total: Number(totalRows[0]?.total ?? 0),
    rows,
    executionMode: "unified" as const
  };
}

export async function getDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  const rows = await query<any>(
    `SELECT TOP 1 *
       FROM [dbo].[DocumentosVenta]
      WHERE NUM_DOC = @numDoc
        AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc: numFact, tipoOperacion }
  );

  return {
    row: rows[0] ?? null,
    executionMode: "unified" as const
  };
}

export async function getDetalleDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  return query<any>(
    `SELECT *
       FROM [dbo].[DocumentosVentaDetalle]
      WHERE NUM_DOC = @numDoc
        AND TIPO_OPERACION = @tipoOperacion
      ORDER BY ISNULL(RENGLON, 0), ID`,
    { numDoc: numFact, tipoOperacion }
  );
}

export async function emitirDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const data = await upsertDocumentoVentaTx(tx, payload);
    await tx.commit();

    return {
      ok: true,
      numFact: data.numDoc,
      detalleRows: data.detalleRows,
      formaPagoRows: data.formasPagoRows,
      saldoPendiente: data.pendingAmount,
      executionMode: "unified"
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}

export async function anularDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const row = await txQuery<any>(
      tx,
      `SELECT TOP 1 CODIGO, FECHA, TOTAL, OBSERV
         FROM [dbo].[DocumentosVenta]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = @tipoOperacion`,
      { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
    );

    if (!row[0]) {
      throw new Error("documento_no_encontrado");
    }

    await txExec(
      tx,
      `UPDATE [dbo].[DocumentosVenta]
          SET ANULADA = 1,
              CANCELADA = 'N',
              FECHA_REPORTE = GETDATE(),
              UpdatedAt = SYSUTCDATETIME(),
              OBSERV = CONCAT(ISNULL(OBSERV,''), CASE WHEN ISNULL(OBSERV,'') = '' THEN '' ELSE ' | ' END, 'ANULADA: ', @motivo)
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = @tipoOperacion`,
      {
        numDoc: payload.numFact,
        tipoOperacion: payload.tipoOperacion,
        motivo: asString(payload.motivo, "sin_motivo")
      }
    );

    await txExec(
      tx,
      `UPDATE [dbo].[DocumentosVentaDetalle]
          SET ANULADA = 1,
              UpdatedAt = SYSUTCDATETIME()
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = @tipoOperacion`,
      { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
    );

    await syncReceivableDocumentTx(tx, {
      tipoOperacion: payload.tipoOperacion,
      numDoc: payload.numFact,
      codigoCliente: asString(row[0].CODIGO, ""),
      fecha: new Date(row[0].FECHA ?? new Date()),
      total: asNumber(row[0].TOTAL, 0),
      pending: 0,
      observacion: asString(row[0].OBSERV, ""),
      codUsuario: payload.codUsuario,
      markVoided: true
    });

    await tx.commit();
    return {
      ok: true,
      numFact: payload.numFact,
      executionMode: "unified" as const
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}

export async function facturarDesdePedidoTx(payload: {
  numFactPedido: string;
  factura: Record<string, unknown>;
  formasPago?: Record<string, unknown>[];
  options?: { generarCxC?: boolean; actualizarSaldosCliente?: boolean };
}) {
  const numFactPedido = asString(payload.numFactPedido).trim();
  const numFactFactura = asString(getValue(payload.factura ?? {}, "NUM_FACT", "NUM_DOC")).trim();
  if (!numFactPedido) throw new Error("missing_num_fact_pedido");
  if (!numFactFactura) throw new Error("missing_num_fact_factura");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const pedidoRows = await txQuery<any>(
      tx,
      `SELECT TOP 1 *
         FROM [dbo].[DocumentosVenta]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'PEDIDO'`,
      { numDoc: numFactPedido }
    );

    const pedido = pedidoRows[0];
    if (!pedido) throw new Error("pedido_not_found");
    if (asNumber(pedido.ANULADA, 0) === 1) throw new Error("pedido_anulado");
    if (asString(pedido.FACTURADA, "N").toUpperCase() === "S") throw new Error("pedido_already_facturado");

    const detallePedido = await txQuery<any>(
      tx,
      `SELECT *
         FROM [dbo].[DocumentosVentaDetalle]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'PEDIDO'
        ORDER BY ISNULL(RENGLON, 0), ID`,
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

    const facturaMirror = await upsertDocumentoVentaTx(tx, {
      tipoOperacion: "FACT",
      documento: facturaDoc,
      detalle: detalleFactura,
      formasPago: payload.formasPago ?? [],
      docOrigen: numFactPedido,
      tipoDocOrigen: "PEDIDO"
    });

    await txExec(
      tx,
      `UPDATE [dbo].[DocumentosVenta]
          SET FACTURADA = 'S',
              FECHA_REPORTE = GETDATE(),
              UpdatedAt = SYSUTCDATETIME()
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'PEDIDO'`,
      { numDoc: numFactPedido }
    );

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
        saldoPendiente: facturaMirror.pendingAmount,
        executionMode: "unified"
      }
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}
