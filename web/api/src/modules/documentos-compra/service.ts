import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";

export type TipoOperacionCompra = "ORDEN" | "COMPRA";

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

function asString(v: unknown, fallback = "") {
  if (v === null || v === undefined) return fallback;
  return String(v);
}

function asNumber(v: unknown, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
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

async function syncPayableDocumentTx(tx: SqlTx, input: {
  tipoOperacion: TipoOperacionCompra;
  numDoc: string;
  codigoProveedor?: string;
  fecha: Date;
  total: number;
  pending: number;
  observacion?: string;
  codUsuario?: string;
  markVoided?: boolean;
}) {
  if (input.tipoOperacion !== "COMPRA") return;

  const codigoProveedor = asString(input.codigoProveedor).trim();
  if (!codigoProveedor) return;

  const supplierRows = await txQuery<{ SupplierId: number }>(
    tx,
    `SELECT TOP 1 SupplierId
       FROM [master].Supplier
      WHERE SupplierCode = @supplierCode
        AND IsDeleted = 0`,
    { supplierCode: codigoProveedor }
  );

  const supplierId = Number(supplierRows[0]?.SupplierId ?? 0);
  if (!Number.isFinite(supplierId) || supplierId <= 0) return;

  const { companyId, branchId, userId } = await resolveCanonicalContextTx(tx, input.codUsuario);

  const safePending = Math.max(0, input.pending);
  const status = input.markVoided
    ? "VOIDED"
    : safePending <= 0
      ? "PAID"
      : safePending < input.total
        ? "PARTIAL"
        : "PENDING";

  const existing = await txQuery<{ PayableDocumentId: number }>(
    tx,
    `SELECT TOP 1 PayableDocumentId
       FROM ap.PayableDocument
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
      `UPDATE ap.PayableDocument
          SET SupplierId = @supplierId,
              IssueDate = @issueDate,
              DueDate = @dueDate,
              TotalAmount = @totalAmount,
              PendingAmount = @pendingAmount,
              PaidFlag = @paidFlag,
              Status = @status,
              Notes = @notes,
              UpdatedAt = SYSUTCDATETIME(),
              UpdatedByUserId = @updatedByUserId
        WHERE PayableDocumentId = @id`,
      {
        id: existing[0].PayableDocumentId,
        supplierId,
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
      `INSERT INTO ap.PayableDocument
         (CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber, IssueDate, DueDate,
          CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, Notes,
          CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId)
       VALUES
         (@companyId, @branchId, @supplierId, @documentType, @documentNumber, @issueDate, @dueDate,
          'USD', @totalAmount, @pendingAmount, @paidFlag, @status, @notes,
          SYSUTCDATETIME(), SYSUTCDATETIME(), @createdByUserId, @updatedByUserId)`,
      {
        companyId,
        branchId,
        supplierId,
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
    `UPDATE [master].Supplier
        SET TotalBalance = (
              SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ap.PayableDocument
               WHERE SupplierId = @supplierId
                 AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @updatedByUserId
      WHERE SupplierId = @supplierId`,
    { supplierId, updatedByUserId: userId }
  );
}

function mapHeader(tipoOperacion: TipoOperacionCompra, documento: Record<string, unknown>, docOrigen?: string) {
  const numDoc = asString(getValue(documento, "NUM_DOC", "NUM_FACT")).trim();
  const total = asNumber(getValue(documento, "TOTAL"), 0);

  return {
    NUM_DOC: numDoc,
    SERIALTIPO: asString(getValue(documento, "SERIALTIPO"), ""),
    TIPO_OPERACION: tipoOperacion,
    COD_PROVEEDOR: getValue(documento, "COD_PROVEEDOR", "CODIGO", "COD_PROVEEDOR"),
    NOMBRE: getValue(documento, "NOMBRE"),
    RIF: getValue(documento, "RIF"),
    FECHA: getValue(documento, "FECHA") ?? new Date(),
    FECHA_VENCE: getValue(documento, "FECHA_VENCE", "FECHAVENCE"),
    FECHA_RECIBO: getValue(documento, "FECHA_RECIBO", "FECHARECIBO"),
    FECHA_PAGO: getValue(documento, "FECHA_PAGO"),
    HORA: getValue(documento, "HORA"),
    SUBTOTAL: getValue(documento, "SUBTOTAL", "MONTO_GRA", "TOTAL"),
    MONTO_GRA: getValue(documento, "MONTO_GRA"),
    MONTO_EXE: getValue(documento, "MONTO_EXE", "EXENTO"),
    IVA: getValue(documento, "IVA"),
    ALICUOTA: getValue(documento, "ALICUOTA"),
    TOTAL: total,
    EXENTO: getValue(documento, "EXENTO"),
    DESCUENTO: getValue(documento, "DESCUENTO"),
    ANULADA: getValue(documento, "ANULADA") ?? 0,
    CANCELADA: asString(getValue(documento, "CANCELADA"), "N"),
    RECIBIDA: asString(getValue(documento, "RECIBIDA"), "N"),
    LEGAL: getValue(documento, "LEGAL"),
    DOC_ORIGEN: docOrigen ?? getValue(documento, "DOC_ORIGEN", "PEDIDO"),
    NUM_CONTROL: getValue(documento, "NUM_CONTROL"),
    NRO_COMPROBANTE: getValue(documento, "NRO_COMPROBANTE"),
    FECHA_COMPROBANTE: getValue(documento, "FECHA_COMPROBANTE"),
    IVA_RETENIDO: getValue(documento, "IVA_RETENIDO", "IvaRetenido"),
    ISLR: getValue(documento, "ISLR", "ISRL"),
    MONTO_ISLR: getValue(documento, "MONTO_ISLR", "MontoISRL"),
    CODIGO_ISLR: getValue(documento, "CODIGO_ISLR", "CodigoISLR"),
    SUJETO_ISLR: getValue(documento, "SUJETO_ISLR"),
    TASA_RETENCION: getValue(documento, "TASA_RETENCION"),
    IMPORTACION: getValue(documento, "IMPORTACION"),
    IVA_IMPORT: getValue(documento, "IVA_IMPORT", "IVAIMPORT"),
    BASE_IMPORT: getValue(documento, "BASE_IMPORT", "BASEIMPORT"),
    FLETE: getValue(documento, "FLETE"),
    CONCEPTO: getValue(documento, "CONCEPTO"),
    OBSERV: getValue(documento, "OBSERV", "obs"),
    PEDIDO: getValue(documento, "PEDIDO"),
    RECIBIDO: getValue(documento, "RECIBIDO"),
    ALMACEN: getValue(documento, "ALMACEN", "Almacen"),
    MONEDA: getValue(documento, "MONEDA"),
    TASA_CAMBIO: getValue(documento, "TASA_CAMBIO"),
    PRECIO_DOLLAR: getValue(documento, "PRECIO_DOLLAR"),
    COD_USUARIO: getValue(documento, "COD_USUARIO"),
    CO_USUARIO: getValue(documento, "CO_USUARIO"),
    FECHA_REPORTE: getValue(documento, "FECHA_REPORTE") ?? new Date(),
    COMPUTER: getValue(documento, "COMPUTER")
  };
}

function mapDetalle(tipoOperacion: TipoOperacionCompra, numDoc: string, detalle: Record<string, unknown>[]) {
  return detalle.map((d, i) => {
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    const precio = asNumber(getValue(d, "PRECIO", "PRECIO_COSTO"), 0);
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
      CANTIDAD: cantidad,
      PRECIO: precio,
      COSTO: getValue(d, "COSTO", "COSTO_REFERENCIA", "PRECIO_COSTO"),
      SUBTOTAL: subtotal,
      DESCUENTO: descuento,
      TOTAL: total,
      ALICUOTA: alicuota,
      MONTO_IVA: asNumber(getValue(d, "MONTO_IVA"), total * (alicuota / 100)),
      ANULADA: getValue(d, "ANULADA") ?? 0,
      CO_USUARIO: getValue(d, "CO_USUARIO"),
      FECHA: getValue(d, "FECHA") ?? new Date()
    };
  });
}

function mapPagos(tipoOperacion: TipoOperacionCompra, numDoc: string, formasPago: Record<string, unknown>[]) {
  return formasPago.map((fp) => ({
    NUM_DOC: numDoc,
    TIPO_OPERACION: tipoOperacion,
    TIPO_PAGO: getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"),
    BANCO: getValue(fp, "banco", "BANCO"),
    NUMERO: getValue(fp, "numero", "NUMERO", "numCheque"),
    MONTO: asNumber(getValue(fp, "monto", "MONTO"), 0),
    FECHA: getValue(fp, "fecha", "FECHA") ?? new Date(),
    FECHA_VENCE: getValue(fp, "fechaVence", "FECHA_VENCE", "fechaVencimiento"),
    REFERENCIA: getValue(fp, "referencia", "REFERENCIA"),
    CO_USUARIO: getValue(fp, "CO_USUARIO")
  }));
}

async function upsertDocumentoCompraTx(tx: SqlTx, input: {
  tipoOperacion: TipoOperacionCompra;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  docOrigen?: string;
}) {
  const headerRaw = mapHeader(input.tipoOperacion, input.documento, input.docOrigen);
  const numDoc = asString(getValue(headerRaw, "NUM_DOC")).trim();
  if (!numDoc) throw new Error("missing_num_doc");

  const headCols = await getColumnsTx(tx, "DocumentosCompra");
  const detCols = await getColumnsTx(tx, "DocumentosCompraDetalle");
  const pagoCols = await getColumnsTx(tx, "DocumentosCompraPago");

  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosCompraDetalle] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );
  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosCompraPago] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );
  await txExec(
    tx,
    `DELETE FROM [dbo].[DocumentosCompra] WHERE NUM_DOC = @numDoc AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc, tipoOperacion: input.tipoOperacion }
  );

  const headerRow = filterByColumns(withAuditFields(headerRaw), headCols);
  await insertDynamicTx(tx, "DocumentosCompra", headerRow, "h");

  const detalleRows = mapDetalle(input.tipoOperacion, numDoc, input.detalle).map((row) =>
    filterByColumns(withAuditFields(row), detCols)
  );
  for (let i = 0; i < detalleRows.length; i += 1) {
    await insertDynamicTx(tx, "DocumentosCompraDetalle", detalleRows[i], `d${i}`);
  }

  const pagosRows = mapPagos(input.tipoOperacion, numDoc, input.formasPago ?? []).map((row) =>
    filterByColumns(withAuditFields(row), pagoCols)
  );
  for (let i = 0; i < pagosRows.length; i += 1) {
    await insertDynamicTx(tx, "DocumentosCompraPago", pagosRows[i], `p${i}`);
  }

  const total = asNumber(getValue(headerRaw, "TOTAL"), 0);
  const pending = asString(getValue(headerRaw, "CANCELADA"), "N").toUpperCase() === "S" ? 0 : total;

  await syncPayableDocumentTx(tx, {
    tipoOperacion: input.tipoOperacion,
    numDoc,
    codigoProveedor: asString(getValue(headerRaw, "COD_PROVEEDOR"), ""),
    fecha: new Date(getValue(headerRaw, "FECHA") as any ?? new Date()),
    total,
    pending,
    observacion: asString(getValue(headerRaw, "OBSERV"), ""),
    codUsuario: asString(getValue(headerRaw, "COD_USUARIO", "CO_USUARIO"), "")
  });

  return {
    numDoc,
    detalleRows: detalleRows.length,
    formasPagoRows: pagosRows.length,
    pendingAmount: pending
  };
}

export function normalizeTipoOperacionCompra(value?: string): TipoOperacionCompra {
  const raw = String(value || "COMPRA").trim().toUpperCase();
  const v = raw.replace(/[\s\-]/g, "_");
  const map: Record<string, TipoOperacionCompra> = {
    ORDEN: "ORDEN",
    ORDENES: "ORDEN",
    ORDEN_COMPRA: "ORDEN",
    ORDENES_COMPRA: "ORDEN",
    ORDC: "ORDEN",
    OC: "ORDEN",
    COMPRA: "COMPRA",
    COMPRAS: "COMPRA",
    FACT: "COMPRA",
    FACTURA: "COMPRA"
  };

  return map[v] ?? map[raw] ?? "COMPRA";
}

export async function listDocumentosCompra(input: {
  tipoOperacion: TipoOperacionCompra;
  search?: string;
  codigo?: string;
  proveedor?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: string;
  limit?: string;
}) {
  const page = Math.max(Number(input.page || 1), 1);
  const limit = Math.min(Math.max(Number(input.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["TIPO_OPERACION = @tipoOperacion"];
  const params: Record<string, unknown> = { tipoOperacion: input.tipoOperacion };

  if (input.search) {
    where.push("(NUM_DOC LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    params.search = `%${input.search}%`;
  }

  if (input.proveedor || input.codigo) {
    where.push("COD_PROVEEDOR = @proveedor");
    params.proveedor = input.proveedor ?? input.codigo;
  }

  if (input.fechaDesde) {
    where.push("CAST(FECHA AS date) >= @fechaDesde");
    params.fechaDesde = input.fechaDesde;
  }

  if (input.fechaHasta) {
    where.push("CAST(FECHA AS date) <= @fechaHasta");
    params.fechaHasta = input.fechaHasta;
  }

  if (input.estado) {
    const estado = input.estado.trim().toUpperCase();
    if (estado === "ANULADO") where.push("ISNULL(ANULADA,0) = 1");
    if (estado === "PENDIENTE") where.push("ISNULL(CANCELADA,'N') <> 'S' AND ISNULL(ANULADA,0) = 0");
    if (estado === "PAGADO") where.push("ISNULL(CANCELADA,'N') = 'S' AND ISNULL(ANULADA,0) = 0");
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT *
       FROM [dbo].[DocumentosCompra]
       ${clause}
      ORDER BY FECHA DESC, NUM_DOC DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    params
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM [dbo].[DocumentosCompra] ${clause}`,
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

export async function getDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  const rows = await query<any>(
    `SELECT TOP 1 *
       FROM [dbo].[DocumentosCompra]
      WHERE NUM_DOC = @numDoc
        AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc: numFact, tipoOperacion }
  );

  return {
    row: rows[0] ?? null,
    executionMode: "unified" as const
  };
}

export async function getDetalleDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  return query<any>(
    `SELECT *
       FROM [dbo].[DocumentosCompraDetalle]
      WHERE NUM_DOC = @numDoc
        AND TIPO_OPERACION = @tipoOperacion
      ORDER BY ISNULL(RENGLON,0), ID`,
    { numDoc: numFact, tipoOperacion }
  );
}

export async function getIndicadoresDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  const rows = await query<any>(
    `SELECT TOP 1
        NUM_DOC,
        TIPO_OPERACION,
        ISNULL(TOTAL,0) AS total,
        ISNULL(IVA,0) AS iva,
        ISNULL(MONTO_GRA,0) AS montoGravable,
        ISNULL(MONTO_EXE,0) AS montoExento,
        ISNULL(ANULADA,0) AS anulada,
        ISNULL(CANCELADA,'N') AS cancelada
       FROM [dbo].[DocumentosCompra]
      WHERE NUM_DOC = @numDoc
        AND TIPO_OPERACION = @tipoOperacion`,
    { numDoc: numFact, tipoOperacion }
  );

  return rows[0] ?? null;
}

export async function emitirDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const data = await upsertDocumentoCompraTx(tx, {
      tipoOperacion: payload.tipoOperacion,
      documento: payload.documento,
      detalle: payload.detalle,
      formasPago: []
    });

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

export async function anularDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
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
      `SELECT TOP 1 COD_PROVEEDOR, FECHA, TOTAL, OBSERV
         FROM [dbo].[DocumentosCompra]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = @tipoOperacion`,
      { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
    );

    if (!row[0]) throw new Error("documento_no_encontrado");

    await txExec(
      tx,
      `UPDATE [dbo].[DocumentosCompra]
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
      `UPDATE [dbo].[DocumentosCompraDetalle]
          SET ANULADA = 1,
              UpdatedAt = SYSUTCDATETIME()
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = @tipoOperacion`,
      { numDoc: payload.numFact, tipoOperacion: payload.tipoOperacion }
    );

    await syncPayableDocumentTx(tx, {
      tipoOperacion: payload.tipoOperacion,
      numDoc: payload.numFact,
      codigoProveedor: asString(row[0].COD_PROVEEDOR, ""),
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

export async function cerrarOrdenConCompraDocumentoTx(payload: {
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
  const numFactCompra = asString(getValue(payload.compra ?? {}, "NUM_DOC", "NUM_FACT")).trim();
  if (!numFactOrden) throw new Error("missing_num_fact_orden");
  if (!numFactCompra) throw new Error("missing_num_fact_compra");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const ordenRows = await txQuery<any>(
      tx,
      `SELECT TOP 1 *
         FROM [dbo].[DocumentosCompra]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'ORDEN'`,
      { numDoc: numFactOrden }
    );

    const orden = ordenRows[0];
    if (!orden) throw new Error("orden_not_found");
    if (asNumber(orden.ANULADA, 0) === 1) throw new Error("orden_anulada");

    const detalleOrden = await txQuery<any>(
      tx,
      `SELECT *
         FROM [dbo].[DocumentosCompraDetalle]
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'ORDEN'
        ORDER BY ISNULL(RENGLON, 0), ID`,
      { numDoc: numFactOrden }
    );

    if (!detalleOrden.length) throw new Error("orden_sin_detalle");

    const compraDoc: Record<string, unknown> = {
      ...payload.compra,
      NUM_DOC: numFactCompra,
      NUM_FACT: numFactCompra,
      COD_PROVEEDOR: getValue(payload.compra ?? {}, "COD_PROVEEDOR") ?? orden.COD_PROVEEDOR,
      NOMBRE: getValue(payload.compra ?? {}, "NOMBRE") ?? orden.NOMBRE,
      RIF: getValue(payload.compra ?? {}, "RIF") ?? orden.RIF,
      FECHA: getValue(payload.compra ?? {}, "FECHA") ?? new Date(),
      TOTAL: getValue(payload.compra ?? {}, "TOTAL") ?? orden.TOTAL,
      DOC_ORIGEN: numFactOrden,
      COD_USUARIO: getValue(payload.compra ?? {}, "COD_USUARIO") ?? orden.COD_USUARIO ?? "API"
    };

    const compraDetalle = (payload.detalle?.length ? payload.detalle : detalleOrden).map((d) => ({
      COD_SERV: d.COD_SERV,
      DESCRIPCION: d.DESCRIPCION,
      CANTIDAD: d.CANTIDAD,
      PRECIO: d.PRECIO,
      COSTO: d.COSTO,
      SUBTOTAL: d.SUBTOTAL,
      DESCUENTO: d.DESCUENTO,
      TOTAL: d.TOTAL,
      ALICUOTA: d.ALICUOTA,
      MONTO_IVA: d.MONTO_IVA
    }));

    const compraResult = await upsertDocumentoCompraTx(tx, {
      tipoOperacion: "COMPRA",
      documento: compraDoc,
      detalle: compraDetalle,
      formasPago: [],
      docOrigen: numFactOrden
    });

    await txExec(
      tx,
      `UPDATE [dbo].[DocumentosCompra]
          SET RECIBIDA = 'S',
              RECIBIDO = 'S',
              FECHA_REPORTE = GETDATE(),
              UpdatedAt = SYSUTCDATETIME()
        WHERE NUM_DOC = @numDoc
          AND TIPO_OPERACION = 'ORDEN'`,
      { numDoc: numFactOrden }
    );

    await tx.commit();

    return {
      ok: true,
      orden: numFactOrden,
      compra: numFactCompra,
      compraResult: {
        ok: true,
        numFact: compraResult.numDoc,
        detalleRows: compraResult.detalleRows,
        formaPagoRows: compraResult.formasPagoRows,
        saldoPendiente: compraResult.pendingAmount,
        executionMode: "unified"
      }
    };
  } catch (err) {
    try { await tx.rollback(); } catch {}
    throw err;
  }
}
