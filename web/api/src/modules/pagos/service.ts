import sql from "mssql";
import { getPool } from "../../db/mssql.js";
import { query } from "../../db/query.js";

type QueryParams = { search?: string; codigo?: string; page?: string; limit?: string };

type Context = { companyId: number; branchId: number };

type CreateTxPayload = { pago: Record<string, unknown>; detalle: Record<string, unknown>[] };

type ServiceOptions = { currencyCode?: string };

function pickString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function pickNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseAmount(body: Record<string, unknown>): number {
  const amount =
    pickNumber(body.monto) ??
    pickNumber(body.MONTO) ??
    pickNumber(body.importe) ??
    pickNumber(body.IMPORTE) ??
    pickNumber(body.total) ??
    pickNumber(body.TOTAL) ??
    pickNumber(body.pago) ??
    pickNumber(body.PAGO) ??
    0;

  if (amount <= 0) throw new Error("monto_invalido");
  return amount;
}

function parseApplyDate(body: Record<string, unknown>): Date {
  const raw = body.fecha ?? body.FECHA ?? body.applyDate ?? body.ApplyDate;
  if (!raw) return new Date();
  const date = new Date(String(raw));
  if (Number.isNaN(date.getTime())) throw new Error("fecha_invalida");
  return date;
}

function parseReference(body: Record<string, unknown>): string {
  return (
    pickString(body.referencia) ??
    pickString(body.REFERENCIA) ??
    pickString(body.concepto) ??
    pickString(body.Concepto) ??
    pickString(body.PaymentReference) ??
    pickString(body.OBS) ??
    `PAGO-${Date.now()}`
  );
}

function normalizeDocType(body: Record<string, unknown>): string | null {
  return (
    pickString(body.tipoDoc) ??
    pickString(body.TIPO_DOC) ??
    pickString(body.tipo) ??
    pickString(body.TIPO)
  );
}

function toId(value: string): number {
  const id = Number(value);
  if (!Number.isFinite(id) || id <= 0) throw new Error("id_invalido");
  return id;
}

async function getDefaultContext(): Promise<Context> {
  const companyRows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );

  const companyId = Number(companyRows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");

  const branchRows = await query<{ BranchId: number }>(
    `SELECT TOP 1 BranchId
       FROM cfg.Branch
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
      ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId`,
    { companyId }
  );

  const branchId = Number(branchRows[0]?.BranchId ?? 0);
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");

  return { companyId, branchId };
}

async function resolvePayableDocumentId(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>
): Promise<number> {
  const directId =
    pickNumber(body.PayableDocumentId) ??
    pickNumber(body.payableDocumentId) ??
    pickNumber(body.DocumentoId) ??
    pickNumber(body.documentoId) ??
    pickNumber(body.idDocumento) ??
    pickNumber(body.IdDocumento);

  if (directId && directId > 0) return directId;

  const documentNumber =
    pickString(body.documento) ??
    pickString(body.DOCUMENTO) ??
    pickString(body.Num_fact) ??
    pickString(body.numDoc) ??
    pickString(body.NumDoc);

  if (!documentNumber) throw new Error("documento_requerido");

  const supplierCode = pickString(body.codigo) ?? pickString(body.CODIGO) ?? pickString(body.Codigo);
  const documentType = normalizeDocType(body);

  const rs = await new sql.Request(tx)
    .input("CompanyId", sql.Int, context.companyId)
    .input("BranchId", sql.Int, context.branchId)
    .input("DocumentNumber", sql.NVarChar(120), documentNumber)
    .input("SupplierCode", sql.NVarChar(24), supplierCode)
    .input("DocumentType", sql.NVarChar(20), documentType)
    .query(`
      SELECT TOP 1 d.PayableDocumentId
      FROM ap.PayableDocument d
      INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      WHERE d.CompanyId = @CompanyId
        AND d.BranchId = @BranchId
        AND d.DocumentNumber = @DocumentNumber
        AND (@SupplierCode IS NULL OR s.SupplierCode = @SupplierCode)
        AND (@DocumentType IS NULL OR d.DocumentType = @DocumentType)
      ORDER BY d.PayableDocumentId DESC
    `);

  const resolved = Number(rs.recordset?.[0]?.PayableDocumentId ?? 0);
  if (!Number.isFinite(resolved) || resolved <= 0) throw new Error("documento_no_encontrado");
  return resolved;
}

function computeDocStatus(total: number, pending: number) {
  const normalizedPending = Math.max(0, pending);
  if (normalizedPending <= 0) return { status: "PAID", paidFlag: 1 };
  if (normalizedPending < total) return { status: "PARTIAL", paidFlag: 0 };
  return { status: "PENDING", paidFlag: 0 };
}

async function refreshSupplierBalance(tx: sql.Transaction, supplierId: number) {
  await new sql.Request(tx)
    .input("SupplierId", sql.BigInt, supplierId)
    .query(`
      UPDATE [master].Supplier
      SET TotalBalance = (
            SELECT ISNULL(SUM(PendingAmount), 0)
            FROM ap.PayableDocument
            WHERE SupplierId = @SupplierId
              AND Status <> 'VOIDED'
          ),
          UpdatedAt = SYSUTCDATETIME()
      WHERE SupplierId = @SupplierId
    `);
}

async function createPagoInTx(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>,
  options: ServiceOptions
) {
  const payableDocumentId = await resolvePayableDocumentId(tx, context, body);
  const requestedAmount = parseAmount(body);
  const applyDate = parseApplyDate(body);
  const paymentReference = parseReference(body);

  const docRs = await new sql.Request(tx)
    .input("PayableDocumentId", sql.BigInt, payableDocumentId)
    .query(`
      SELECT TOP 1
        d.PayableDocumentId,
        d.SupplierId,
        d.PendingAmount,
        d.TotalAmount,
        d.CurrencyCode
      FROM ap.PayableDocument d WITH (UPDLOCK, ROWLOCK)
      WHERE d.PayableDocumentId = @PayableDocumentId
    `);

  const doc = docRs.recordset?.[0] as
    | { PayableDocumentId: number; SupplierId: number; PendingAmount: number; TotalAmount: number; CurrencyCode: string }
    | undefined;

  if (!doc) throw new Error("documento_no_encontrado");

  if (options.currencyCode && String(doc.CurrencyCode).toUpperCase() !== options.currencyCode.toUpperCase()) {
    throw new Error("moneda_no_permitida");
  }

  const pending = Number(doc.PendingAmount ?? 0);
  const total = Number(doc.TotalAmount ?? 0);
  const appliedAmount = Math.min(pending, requestedAmount);

  if (!Number.isFinite(appliedAmount) || appliedAmount <= 0) throw new Error("documento_sin_saldo_pendiente");

  const insertRs = await new sql.Request(tx)
    .input("PayableDocumentId", sql.BigInt, payableDocumentId)
    .input("ApplyDate", sql.Date, applyDate)
    .input("AppliedAmount", sql.Decimal(18, 2), appliedAmount)
    .input("PaymentReference", sql.NVarChar(120), paymentReference)
    .query(`
      INSERT INTO ap.PayableApplication
        (PayableDocumentId, ApplyDate, AppliedAmount, PaymentReference)
      OUTPUT INSERTED.PayableApplicationId AS PayableApplicationId
      VALUES
        (@PayableDocumentId, @ApplyDate, @AppliedAmount, @PaymentReference)
    `);

  const applicationId = Number(insertRs.recordset?.[0]?.PayableApplicationId ?? 0);
  if (!Number.isFinite(applicationId) || applicationId <= 0) throw new Error("no_fue_posible_crear_pago");

  const newPending = Math.max(0, pending - appliedAmount);
  const docStatus = computeDocStatus(total, newPending);

  await new sql.Request(tx)
    .input("PayableDocumentId", sql.BigInt, payableDocumentId)
    .input("PendingAmount", sql.Decimal(18, 2), newPending)
    .input("Status", sql.NVarChar(20), docStatus.status)
    .input("PaidFlag", sql.Bit, docStatus.paidFlag)
    .query(`
      UPDATE ap.PayableDocument
      SET PendingAmount = @PendingAmount,
          Status = @Status,
          PaidFlag = @PaidFlag,
          UpdatedAt = SYSUTCDATETIME()
      WHERE PayableDocumentId = @PayableDocumentId
    `);

  await refreshSupplierBalance(tx, Number(doc.SupplierId));

  return {
    ok: true,
    id: applicationId,
    documentoId: payableDocumentId,
    montoAplicado: appliedAmount,
    executionMode: "canonical" as const
  };
}

export async function listPagos(params: QueryParams, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["d.CompanyId = @companyId", "d.BranchId = @branchId"];
  const sqlParams: Record<string, unknown> = { companyId: context.companyId, branchId: context.branchId };

  if (params.search) {
    where.push("(d.DocumentNumber LIKE @search OR s.SupplierName LIKE @search OR ISNULL(a.PaymentReference,'') LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }

  if (params.codigo) {
    where.push("s.SupplierCode = @codigo");
    sqlParams.codigo = params.codigo;
  }

  if (options.currencyCode) {
    where.push("d.CurrencyCode = @currencyCode");
    sqlParams.currencyCode = options.currencyCode;
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT
        a.PayableApplicationId AS Id,
        a.PayableApplicationId AS ApplicationId,
        d.PayableDocumentId AS DocumentoId,
        s.SupplierCode AS CODIGO,
        s.SupplierCode AS Codigo,
        s.SupplierName AS NOMBRE,
        d.DocumentType AS TIPO_DOC,
        d.DocumentType AS TipoDoc,
        d.DocumentNumber AS DOCUMENTO,
        d.DocumentNumber AS Num_fact,
        a.ApplyDate AS FECHA,
        a.ApplyDate AS Fecha,
        a.AppliedAmount AS MONTO,
        a.AppliedAmount AS Monto,
        d.CurrencyCode AS MONEDA,
        a.PaymentReference AS REFERENCIA,
        a.PaymentReference AS Concepto,
        d.PendingAmount AS PENDIENTE,
        d.TotalAmount AS TOTAL,
        d.Status AS ESTADO_DOC
      FROM ap.PayableApplication a
      INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
      INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      ${clause}
      ORDER BY a.ApplyDate DESC, a.PayableApplicationId DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
      FROM ap.PayableApplication a
      INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
      INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      ${clause}`,
    sqlParams
  );

  return {
    page,
    limit,
    total: Number(totalRows[0]?.total ?? 0),
    rows,
    executionMode: "canonical" as const
  };
}

export async function getPago(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const context = await getDefaultContext();

  const rows = await query<any>(
    `SELECT TOP 1
        a.PayableApplicationId AS Id,
        a.PayableApplicationId AS ApplicationId,
        d.PayableDocumentId AS DocumentoId,
        s.SupplierCode AS CODIGO,
        s.SupplierCode AS Codigo,
        s.SupplierName AS NOMBRE,
        d.DocumentType AS TIPO_DOC,
        d.DocumentType AS TipoDoc,
        d.DocumentNumber AS DOCUMENTO,
        d.DocumentNumber AS Num_fact,
        a.ApplyDate AS FECHA,
        a.ApplyDate AS Fecha,
        a.AppliedAmount AS MONTO,
        a.AppliedAmount AS Monto,
        d.CurrencyCode AS MONEDA,
        a.PaymentReference AS REFERENCIA,
        a.PaymentReference AS Concepto,
        d.PendingAmount AS PENDIENTE,
        d.TotalAmount AS TOTAL,
        d.Status AS ESTADO_DOC
      FROM ap.PayableApplication a
      INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
      INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      WHERE a.PayableApplicationId = @id
        AND d.CompanyId = @companyId
        AND d.BranchId = @branchId
        AND (@currencyCode IS NULL OR d.CurrencyCode = @currencyCode)`,
    {
      id: appId,
      companyId: context.companyId,
      branchId: context.branchId,
      currencyCode: options.currencyCode ?? null
    }
  );

  return rows[0] ?? null;
}

export async function getPagoDetalle(id: string, options: ServiceOptions = {}) {
  const head = await getPago(id, options);
  return head ? [head] : [];
}

export async function createPago(body: Record<string, unknown>, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const created = await createPagoInTx(tx, context, body, options);
    await tx.commit();
    return created;
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}

export async function updatePago(id: string, body: Record<string, unknown>, options: ServiceOptions = {}) {
  const appId = toId(id);
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const rowRs = await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .query(`
        SELECT TOP 1
          a.PayableApplicationId,
          a.PayableDocumentId,
          a.AppliedAmount,
          d.PendingAmount,
          d.TotalAmount,
          d.SupplierId,
          d.CurrencyCode
        FROM ap.PayableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ap.PayableDocument d WITH (UPDLOCK, ROWLOCK) ON d.PayableDocumentId = a.PayableDocumentId
        WHERE a.PayableApplicationId = @ApplicationId
      `);

    const row = rowRs.recordset?.[0] as
      | {
          PayableApplicationId: number;
          PayableDocumentId: number;
          AppliedAmount: number;
          PendingAmount: number;
          TotalAmount: number;
          SupplierId: number;
          CurrencyCode: string;
        }
      | undefined;

    if (!row) throw new Error("not_found");

    if (options.currencyCode && String(row.CurrencyCode).toUpperCase() !== options.currencyCode.toUpperCase()) {
      throw new Error("not_found");
    }

    const originalAmount = Number(row.AppliedAmount ?? 0);
    const pending = Number(row.PendingAmount ?? 0);
    const total = Number(row.TotalAmount ?? 0);

    const hasAmountUpdate =
      body.monto !== undefined ||
      body.MONTO !== undefined ||
      body.importe !== undefined ||
      body.IMPORTE !== undefined ||
      body.total !== undefined ||
      body.TOTAL !== undefined;

    const updatedAmount = hasAmountUpdate ? parseAmount(body) : originalAmount;
    const delta = updatedAmount - originalAmount;

    let newPending = pending;
    if (delta > 0) {
      if (pending < delta) throw new Error("saldo_insuficiente_en_documento");
      newPending = pending - delta;
    } else if (delta < 0) {
      newPending = Math.min(total, pending + Math.abs(delta));
    }

    const docStatus = computeDocStatus(total, newPending);

    await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .input("ApplyDate", sql.Date, body.fecha ?? body.FECHA ?? body.applyDate ?? body.ApplyDate ?? null)
      .input("AppliedAmount", sql.Decimal(18, 2), updatedAmount)
      .input("PaymentReference", sql.NVarChar(120), parseReference(body))
      .query(`
        UPDATE ap.PayableApplication
        SET ApplyDate = COALESCE(@ApplyDate, ApplyDate),
            AppliedAmount = @AppliedAmount,
            PaymentReference = COALESCE(@PaymentReference, PaymentReference)
        WHERE PayableApplicationId = @ApplicationId
      `);

    if (delta !== 0) {
      await new sql.Request(tx)
        .input("PayableDocumentId", sql.BigInt, Number(row.PayableDocumentId))
        .input("PendingAmount", sql.Decimal(18, 2), newPending)
        .input("Status", sql.NVarChar(20), docStatus.status)
        .input("PaidFlag", sql.Bit, docStatus.paidFlag)
        .query(`
          UPDATE ap.PayableDocument
          SET PendingAmount = @PendingAmount,
              Status = @Status,
              PaidFlag = @PaidFlag,
              UpdatedAt = SYSUTCDATETIME()
          WHERE PayableDocumentId = @PayableDocumentId
        `);

      await refreshSupplierBalance(tx, Number(row.SupplierId));
    }

    await tx.commit();
    return { ok: true, executionMode: "canonical" as const };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}

export async function deletePago(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const rowRs = await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .query(`
        SELECT TOP 1
          a.PayableApplicationId,
          a.PayableDocumentId,
          a.AppliedAmount,
          d.PendingAmount,
          d.TotalAmount,
          d.SupplierId,
          d.CurrencyCode
        FROM ap.PayableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ap.PayableDocument d WITH (UPDLOCK, ROWLOCK) ON d.PayableDocumentId = a.PayableDocumentId
        WHERE a.PayableApplicationId = @ApplicationId
      `);

    const row = rowRs.recordset?.[0] as
      | {
          PayableApplicationId: number;
          PayableDocumentId: number;
          AppliedAmount: number;
          PendingAmount: number;
          TotalAmount: number;
          SupplierId: number;
          CurrencyCode: string;
        }
      | undefined;

    if (!row) throw new Error("not_found");

    if (options.currencyCode && String(row.CurrencyCode).toUpperCase() !== options.currencyCode.toUpperCase()) {
      throw new Error("not_found");
    }

    const pending = Number(row.PendingAmount ?? 0);
    const total = Number(row.TotalAmount ?? 0);
    const applied = Number(row.AppliedAmount ?? 0);

    const newPending = Math.min(total, pending + applied);
    const docStatus = computeDocStatus(total, newPending);

    await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .query(`DELETE FROM ap.PayableApplication WHERE PayableApplicationId = @ApplicationId`);

    await new sql.Request(tx)
      .input("PayableDocumentId", sql.BigInt, Number(row.PayableDocumentId))
      .input("PendingAmount", sql.Decimal(18, 2), newPending)
      .input("Status", sql.NVarChar(20), docStatus.status)
      .input("PaidFlag", sql.Bit, docStatus.paidFlag)
      .query(`
        UPDATE ap.PayableDocument
        SET PendingAmount = @PendingAmount,
            Status = @Status,
            PaidFlag = @PaidFlag,
            UpdatedAt = SYSUTCDATETIME()
        WHERE PayableDocumentId = @PayableDocumentId
      `);

    await refreshSupplierBalance(tx, Number(row.SupplierId));

    await tx.commit();
    return { ok: true, executionMode: "canonical" as const };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}

export async function createPagoTx(payload: CreateTxPayload, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const base = payload.pago ?? {};
    const details = Array.isArray(payload.detalle) ? payload.detalle : [];
    const entries = details.length > 0 ? details : [base];

    const created: Array<{ ok: boolean; id: number; documentoId: number; montoAplicado: number; executionMode: "canonical" }> = [];

    for (const entry of entries) {
      const merged = { ...base, ...(entry ?? {}) };
      const row = await createPagoInTx(tx, context, merged, options);
      created.push(row);
    }

    await tx.commit();

    return {
      ok: true,
      total: created.length,
      rows: created,
      executionMode: "canonical" as const
    };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}
