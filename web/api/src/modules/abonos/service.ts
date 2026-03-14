import sql from "mssql";
import { getPool } from "../../db/mssql.js";
import { query } from "../../db/query.js";

type QueryParams = { search?: string; codigo?: string; page?: string; limit?: string };

type Context = { companyId: number; branchId: number };

type CreateTxPayload = { abono: Record<string, unknown>; detalle: Record<string, unknown>[] };

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
    pickNumber(body.abono) ??
    pickNumber(body.ABONO) ??
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
    `ABONO-${Date.now()}`
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

async function resolveReceivableDocumentId(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>
): Promise<number> {
  const directId =
    pickNumber(body.ReceivableDocumentId) ??
    pickNumber(body.receivableDocumentId) ??
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

  const customerCode = pickString(body.codigo) ?? pickString(body.CODIGO) ?? pickString(body.Codigo);
  const documentType = normalizeDocType(body);

  const rs = await new sql.Request(tx)
    .input("CompanyId", sql.Int, context.companyId)
    .input("BranchId", sql.Int, context.branchId)
    .input("DocumentNumber", sql.NVarChar(120), documentNumber)
    .input("CustomerCode", sql.NVarChar(24), customerCode)
    .input("DocumentType", sql.NVarChar(20), documentType)
    .query(`
      SELECT TOP 1 d.ReceivableDocumentId
      FROM ar.ReceivableDocument d
      INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
      WHERE d.CompanyId = @CompanyId
        AND d.BranchId = @BranchId
        AND d.DocumentNumber = @DocumentNumber
        AND (@CustomerCode IS NULL OR c.CustomerCode = @CustomerCode)
        AND (@DocumentType IS NULL OR d.DocumentType = @DocumentType)
      ORDER BY d.ReceivableDocumentId DESC
    `);

  const resolved = Number(rs.recordset?.[0]?.ReceivableDocumentId ?? 0);
  if (!Number.isFinite(resolved) || resolved <= 0) throw new Error("documento_no_encontrado");
  return resolved;
}

function computeDocStatus(total: number, pending: number) {
  const normalizedPending = Math.max(0, pending);
  if (normalizedPending <= 0) return { status: "PAID", paidFlag: 1 };
  if (normalizedPending < total) return { status: "PARTIAL", paidFlag: 0 };
  return { status: "PENDING", paidFlag: 0 };
}

async function refreshCustomerBalance(tx: sql.Transaction, customerId: number) {
  await new sql.Request(tx)
    .input("CustomerId", sql.BigInt, customerId)
    .query(`
      UPDATE [master].Customer
      SET TotalBalance = (
            SELECT ISNULL(SUM(PendingAmount), 0)
            FROM ar.ReceivableDocument
            WHERE CustomerId = @CustomerId
              AND Status <> 'VOIDED'
          ),
          UpdatedAt = SYSUTCDATETIME()
      WHERE CustomerId = @CustomerId
    `);
}

async function createAbonoInTx(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>,
  options: ServiceOptions
) {
  const receivableDocumentId = await resolveReceivableDocumentId(tx, context, body);
  const requestedAmount = parseAmount(body);
  const applyDate = parseApplyDate(body);
  const paymentReference = parseReference(body);

  const docRs = await new sql.Request(tx)
    .input("ReceivableDocumentId", sql.BigInt, receivableDocumentId)
    .query(`
      SELECT TOP 1
        d.ReceivableDocumentId,
        d.CustomerId,
        d.PendingAmount,
        d.TotalAmount,
        d.CurrencyCode
      FROM ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK)
      WHERE d.ReceivableDocumentId = @ReceivableDocumentId
    `);

  const doc = docRs.recordset?.[0] as
    | { ReceivableDocumentId: number; CustomerId: number; PendingAmount: number; TotalAmount: number; CurrencyCode: string }
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
    .input("ReceivableDocumentId", sql.BigInt, receivableDocumentId)
    .input("ApplyDate", sql.Date, applyDate)
    .input("AppliedAmount", sql.Decimal(18, 2), appliedAmount)
    .input("PaymentReference", sql.NVarChar(120), paymentReference)
    .query(`
      INSERT INTO ar.ReceivableApplication
        (ReceivableDocumentId, ApplyDate, AppliedAmount, PaymentReference)
      OUTPUT INSERTED.ReceivableApplicationId AS ReceivableApplicationId
      VALUES
        (@ReceivableDocumentId, @ApplyDate, @AppliedAmount, @PaymentReference)
    `);

  const applicationId = Number(insertRs.recordset?.[0]?.ReceivableApplicationId ?? 0);
  if (!Number.isFinite(applicationId) || applicationId <= 0) throw new Error("no_fue_posible_crear_abono");

  const newPending = Math.max(0, pending - appliedAmount);
  const docStatus = computeDocStatus(total, newPending);

  await new sql.Request(tx)
    .input("ReceivableDocumentId", sql.BigInt, receivableDocumentId)
    .input("PendingAmount", sql.Decimal(18, 2), newPending)
    .input("Status", sql.NVarChar(20), docStatus.status)
    .input("PaidFlag", sql.Bit, docStatus.paidFlag)
    .query(`
      UPDATE ar.ReceivableDocument
      SET PendingAmount = @PendingAmount,
          Status = @Status,
          PaidFlag = @PaidFlag,
          UpdatedAt = SYSUTCDATETIME()
      WHERE ReceivableDocumentId = @ReceivableDocumentId
    `);

  await refreshCustomerBalance(tx, Number(doc.CustomerId));

  return {
    ok: true,
    id: applicationId,
    documentoId: receivableDocumentId,
    montoAplicado: appliedAmount,
    executionMode: "canonical" as const
  };
}

export async function listAbonos(params: QueryParams, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["d.CompanyId = @companyId", "d.BranchId = @branchId"];
  const sqlParams: Record<string, unknown> = { companyId: context.companyId, branchId: context.branchId };

  if (params.search) {
    where.push("(d.DocumentNumber LIKE @search OR c.CustomerName LIKE @search OR ISNULL(a.PaymentReference,'') LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }

  if (params.codigo) {
    where.push("c.CustomerCode = @codigo");
    sqlParams.codigo = params.codigo;
  }

  if (options.currencyCode) {
    where.push("d.CurrencyCode = @currencyCode");
    sqlParams.currencyCode = options.currencyCode;
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT
        a.ReceivableApplicationId AS Id,
        a.ReceivableApplicationId AS ApplicationId,
        d.ReceivableDocumentId AS DocumentoId,
        c.CustomerCode AS CODIGO,
        c.CustomerCode AS Codigo,
        c.CustomerName AS NOMBRE,
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
      FROM ar.ReceivableApplication a
      INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
      INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
      ${clause}
      ORDER BY a.ApplyDate DESC, a.ReceivableApplicationId DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
      FROM ar.ReceivableApplication a
      INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
      INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
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

export async function getAbono(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const context = await getDefaultContext();

  const rows = await query<any>(
    `SELECT TOP 1
        a.ReceivableApplicationId AS Id,
        a.ReceivableApplicationId AS ApplicationId,
        d.ReceivableDocumentId AS DocumentoId,
        c.CustomerCode AS CODIGO,
        c.CustomerCode AS Codigo,
        c.CustomerName AS NOMBRE,
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
      FROM ar.ReceivableApplication a
      INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
      INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
      WHERE a.ReceivableApplicationId = @id
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

export async function getAbonoDetalle(id: string, options: ServiceOptions = {}) {
  const head = await getAbono(id, options);
  return head ? [head] : [];
}

export async function createAbono(body: Record<string, unknown>, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const created = await createAbonoInTx(tx, context, body, options);
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

export async function updateAbono(id: string, body: Record<string, unknown>, options: ServiceOptions = {}) {
  const appId = toId(id);
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const rowRs = await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .query(`
        SELECT TOP 1
          a.ReceivableApplicationId,
          a.ReceivableDocumentId,
          a.AppliedAmount,
          d.PendingAmount,
          d.TotalAmount,
          d.CustomerId,
          d.CurrencyCode
        FROM ar.ReceivableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK) ON d.ReceivableDocumentId = a.ReceivableDocumentId
        WHERE a.ReceivableApplicationId = @ApplicationId
      `);

    const row = rowRs.recordset?.[0] as
      | {
          ReceivableApplicationId: number;
          ReceivableDocumentId: number;
          AppliedAmount: number;
          PendingAmount: number;
          TotalAmount: number;
          CustomerId: number;
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
        UPDATE ar.ReceivableApplication
        SET ApplyDate = COALESCE(@ApplyDate, ApplyDate),
            AppliedAmount = @AppliedAmount,
            PaymentReference = COALESCE(@PaymentReference, PaymentReference)
        WHERE ReceivableApplicationId = @ApplicationId
      `);

    if (delta !== 0) {
      await new sql.Request(tx)
        .input("ReceivableDocumentId", sql.BigInt, Number(row.ReceivableDocumentId))
        .input("PendingAmount", sql.Decimal(18, 2), newPending)
        .input("Status", sql.NVarChar(20), docStatus.status)
        .input("PaidFlag", sql.Bit, docStatus.paidFlag)
        .query(`
          UPDATE ar.ReceivableDocument
          SET PendingAmount = @PendingAmount,
              Status = @Status,
              PaidFlag = @PaidFlag,
              UpdatedAt = SYSUTCDATETIME()
          WHERE ReceivableDocumentId = @ReceivableDocumentId
        `);

      await refreshCustomerBalance(tx, Number(row.CustomerId));
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

export async function deleteAbono(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const rowRs = await new sql.Request(tx)
      .input("ApplicationId", sql.BigInt, appId)
      .query(`
        SELECT TOP 1
          a.ReceivableApplicationId,
          a.ReceivableDocumentId,
          a.AppliedAmount,
          d.PendingAmount,
          d.TotalAmount,
          d.CustomerId,
          d.CurrencyCode
        FROM ar.ReceivableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK) ON d.ReceivableDocumentId = a.ReceivableDocumentId
        WHERE a.ReceivableApplicationId = @ApplicationId
      `);

    const row = rowRs.recordset?.[0] as
      | {
          ReceivableApplicationId: number;
          ReceivableDocumentId: number;
          AppliedAmount: number;
          PendingAmount: number;
          TotalAmount: number;
          CustomerId: number;
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
      .query(`DELETE FROM ar.ReceivableApplication WHERE ReceivableApplicationId = @ApplicationId`);

    await new sql.Request(tx)
      .input("ReceivableDocumentId", sql.BigInt, Number(row.ReceivableDocumentId))
      .input("PendingAmount", sql.Decimal(18, 2), newPending)
      .input("Status", sql.NVarChar(20), docStatus.status)
      .input("PaidFlag", sql.Bit, docStatus.paidFlag)
      .query(`
        UPDATE ar.ReceivableDocument
        SET PendingAmount = @PendingAmount,
            Status = @Status,
            PaidFlag = @PaidFlag,
            UpdatedAt = SYSUTCDATETIME()
        WHERE ReceivableDocumentId = @ReceivableDocumentId
      `);

    await refreshCustomerBalance(tx, Number(row.CustomerId));

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

export async function createAbonoTx(payload: CreateTxPayload, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const base = payload.abono ?? {};
    const details = Array.isArray(payload.detalle) ? payload.detalle : [];
    const entries = details.length > 0 ? details : [base];

    const created: Array<{ ok: boolean; id: number; documentoId: number; montoAplicado: number; executionMode: "canonical" }> = [];

    for (const entry of entries) {
      const merged = { ...base, ...(entry ?? {}) };
      const row = await createAbonoInTx(tx, context, merged, options);
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
