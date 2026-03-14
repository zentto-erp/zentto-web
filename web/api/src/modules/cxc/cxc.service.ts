import sql from "mssql";
import { getPool } from "../../db/mssql.js";
import { query } from "../../db/query.js";

export interface DocumentoAplicar {
  tipoDoc: string;
  numDoc: string;
  montoAplicar: number;
}

export interface FormaPago {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
}

export interface AplicarCobroInput {
  requestId: string;
  codCliente: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: DocumentoAplicar[];
  formasPago: FormaPago[];
}

export interface AplicarCobroResult {
  success: boolean;
  numRecibo?: string;
  message: string;
}

export interface ListDocumentosCxCInput {
  codCliente?: string;
  tipoDoc?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

function buildReceiptNumber(prefix: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  return `${prefix}-${stamp}`;
}

function normalizeCxCEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (value === "PENDIENTE") return "PENDING";
  if (value === "PARCIAL") return "PARTIAL";
  if (value === "PAGADO") return "PAID";
  if (value === "ANULADO") return "VOIDED";
  if (["PENDING", "PARTIAL", "PAID", "VOIDED"].includes(value)) return value;
  return null;
}

export async function aplicarCobro(input: AplicarCobroInput): Promise<AplicarCobroResult> {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const customerRs = await new sql.Request(tx)
      .input("CodCliente", sql.NVarChar(24), input.codCliente)
      .query(`
        SELECT TOP 1 CustomerId
        FROM [master].Customer
        WHERE CustomerCode = @CodCliente
          AND IsDeleted = 0
      `);

    const customerId = Number(customerRs.recordset?.[0]?.CustomerId ?? 0);
    if (!Number.isFinite(customerId) || customerId <= 0) {
      await tx.rollback();
      return { success: false, message: "Cliente no encontrado en esquema canonico" };
    }

    const applyDate = input.fecha ? new Date(input.fecha) : new Date();
    const numRecibo = buildReceiptNumber("RCB");
    let applied = 0;

    for (const item of input.documentos ?? []) {
      const docRs = await new sql.Request(tx)
        .input("CustomerId", sql.BigInt, customerId)
        .input("TipoDoc", sql.NVarChar(20), item.tipoDoc)
        .input("NumDoc", sql.NVarChar(120), item.numDoc)
        .query(`
          SELECT TOP 1
            ReceivableDocumentId,
            PendingAmount,
            TotalAmount
          FROM ar.ReceivableDocument WITH (UPDLOCK, ROWLOCK)
          WHERE CustomerId = @CustomerId
            AND DocumentType = @TipoDoc
            AND DocumentNumber = @NumDoc
            AND Status <> 'VOIDED'
          ORDER BY ReceivableDocumentId DESC
        `);

      const row = docRs.recordset?.[0];
      if (!row) continue;

      const pending = Number(row.PendingAmount ?? 0);
      const applyAmount = Math.min(pending, Number(item.montoAplicar ?? 0));
      if (!Number.isFinite(applyAmount) || applyAmount <= 0) continue;

      await new sql.Request(tx)
        .input("ReceivableDocumentId", sql.BigInt, Number(row.ReceivableDocumentId))
        .input("ApplyDate", sql.Date, applyDate)
        .input("AppliedAmount", sql.Decimal(18, 2), applyAmount)
        .input("PaymentReference", sql.NVarChar(120), `${input.requestId}:${numRecibo}`)
        .query(`
          INSERT INTO ar.ReceivableApplication (
            ReceivableDocumentId,
            ApplyDate,
            AppliedAmount,
            PaymentReference
          )
          VALUES (
            @ReceivableDocumentId,
            @ApplyDate,
            @AppliedAmount,
            @PaymentReference
          )
        `);

      await new sql.Request(tx)
        .input("ReceivableDocumentId", sql.BigInt, Number(row.ReceivableDocumentId))
        .input("AppliedAmount", sql.Decimal(18, 2), applyAmount)
        .query(`
          UPDATE ar.ReceivableDocument
          SET PendingAmount = CASE
                                WHEN PendingAmount - @AppliedAmount < 0 THEN 0
                                ELSE PendingAmount - @AppliedAmount
                              END,
              PaidFlag = CASE
                           WHEN PendingAmount - @AppliedAmount <= 0 THEN 1
                           ELSE 0
                         END,
              Status = CASE
                         WHEN PendingAmount - @AppliedAmount <= 0 THEN 'PAID'
                         WHEN PendingAmount - @AppliedAmount < TotalAmount THEN 'PARTIAL'
                         ELSE 'PENDING'
                       END,
              UpdatedAt = SYSUTCDATETIME()
          WHERE ReceivableDocumentId = @ReceivableDocumentId
        `);

      applied += applyAmount;
    }

    if (applied <= 0) {
      await tx.rollback();
      return { success: false, message: "No hay montos aplicables para cobrar" };
    }

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

    await tx.commit();

    return {
      success: true,
      numRecibo,
      message: "Cobro aplicado en esquema canonico"
    };
  } catch (error: any) {
    try { await tx.rollback(); } catch {}
    return {
      success: false,
      message: `Error aplicando cobro canonico: ${String(error?.message ?? error)}`
    };
  }
}

export const aplicarCobroTx = aplicarCobro;

export async function listDocumentos(input: ListDocumentosCxCInput) {
  const page = Math.max(1, Number(input.page ?? 1) || 1);
  const limit = Math.min(500, Math.max(1, Number(input.limit ?? 50) || 50));
  const offset = (page - 1) * limit;
  const estado = normalizeCxCEstado(input.estado);

  const params = {
    codCliente: input.codCliente || null,
    tipoDoc: input.tipoDoc || null,
    estado,
    fechaDesde: input.fechaDesde || null,
    fechaHasta: input.fechaHasta || null,
    offset,
    limit,
  };

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE (@codCliente IS NULL OR c.CustomerCode = @codCliente)
      AND (@tipoDoc IS NULL OR d.DocumentType = @tipoDoc)
      AND (@estado IS NULL OR d.Status = @estado)
      AND (@fechaDesde IS NULL OR d.IssueDate >= @fechaDesde)
      AND (@fechaHasta IS NULL OR d.IssueDate <= @fechaHasta)
    `,
    params
  );

  const rows = await query<any>(
    `
    ;WITH Base AS (
      SELECT
        c.CustomerCode AS codCliente,
        d.DocumentType AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate AS fecha,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.Notes AS observacion,
        ROW_NUMBER() OVER (
          ORDER BY d.IssueDate DESC, d.ReceivableDocumentId DESC
        ) AS rn
      FROM ar.ReceivableDocument d
      INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
      WHERE (@codCliente IS NULL OR c.CustomerCode = @codCliente)
        AND (@tipoDoc IS NULL OR d.DocumentType = @tipoDoc)
        AND (@estado IS NULL OR d.Status = @estado)
        AND (@fechaDesde IS NULL OR d.IssueDate >= @fechaDesde)
        AND (@fechaHasta IS NULL OR d.IssueDate <= @fechaHasta)
    )
    SELECT codCliente, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion
    FROM Base
    WHERE rn BETWEEN (@offset + 1) AND (@offset + @limit)
    ORDER BY rn
    `,
    params
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getDocumentosPendientes(codCliente: string) {
  return query<any>(
    `
    SELECT
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.PendingAmount AS pendiente,
      d.TotalAmount AS total
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE c.CustomerCode = @codCliente
      AND d.PendingAmount > 0
      AND d.Status IN ('PENDING', 'PARTIAL')
    ORDER BY d.IssueDate ASC, d.ReceivableDocumentId ASC
    `,
    { codCliente }
  );
}

export async function getSaldoCliente(codCliente: string) {
  const rows = await query<any>(
    `
    SELECT
      ISNULL(c.TotalBalance, 0) AS saldoTotal,
      CAST(0 AS DECIMAL(18,2)) AS saldo30,
      CAST(0 AS DECIMAL(18,2)) AS saldo60,
      CAST(0 AS DECIMAL(18,2)) AS saldo90,
      CAST(0 AS DECIMAL(18,2)) AS saldo91
    FROM [master].Customer c
    WHERE c.CustomerCode = @codCliente
      AND c.IsDeleted = 0
    `,
    { codCliente }
  );

  return rows[0] || null;
}
