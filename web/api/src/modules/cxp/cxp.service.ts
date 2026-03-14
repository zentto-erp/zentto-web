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

export interface AplicarPagoInput {
  requestId: string;
  codProveedor: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: DocumentoAplicar[];
  formasPago: FormaPago[];
}

export interface AplicarPagoResult {
  success: boolean;
  numPago?: string;
  message: string;
}

export interface ListDocumentosCxPInput {
  codProveedor?: string;
  tipoDoc?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

function buildPaymentNumber(prefix: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  return `${prefix}-${stamp}`;
}

function normalizeCxPEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (value === "PENDIENTE") return "PENDING";
  if (value === "PARCIAL") return "PARTIAL";
  if (value === "PAGADO") return "PAID";
  if (value === "ANULADO") return "VOIDED";
  if (["PENDING", "PARTIAL", "PAID", "VOIDED"].includes(value)) return value;
  return null;
}

export async function aplicarPago(input: AplicarPagoInput): Promise<AplicarPagoResult> {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const supplierRs = await new sql.Request(tx)
      .input("CodProveedor", sql.NVarChar(24), input.codProveedor)
      .query(`
        SELECT TOP 1 SupplierId
        FROM [master].Supplier
        WHERE SupplierCode = @CodProveedor
          AND IsDeleted = 0
      `);

    const supplierId = Number(supplierRs.recordset?.[0]?.SupplierId ?? 0);
    if (!Number.isFinite(supplierId) || supplierId <= 0) {
      await tx.rollback();
      return { success: false, message: "Proveedor no encontrado en esquema canonico" };
    }

    const applyDate = input.fecha ? new Date(input.fecha) : new Date();
    const numPago = buildPaymentNumber("PAG");
    let applied = 0;

    for (const item of input.documentos ?? []) {
      const docRs = await new sql.Request(tx)
        .input("SupplierId", sql.BigInt, supplierId)
        .input("TipoDoc", sql.NVarChar(20), item.tipoDoc)
        .input("NumDoc", sql.NVarChar(120), item.numDoc)
        .query(`
          SELECT TOP 1
            PayableDocumentId,
            PendingAmount,
            TotalAmount
          FROM ap.PayableDocument WITH (UPDLOCK, ROWLOCK)
          WHERE SupplierId = @SupplierId
            AND DocumentType = @TipoDoc
            AND DocumentNumber = @NumDoc
            AND Status <> 'VOIDED'
          ORDER BY PayableDocumentId DESC
        `);

      const row = docRs.recordset?.[0];
      if (!row) continue;

      const pending = Number(row.PendingAmount ?? 0);
      const applyAmount = Math.min(pending, Number(item.montoAplicar ?? 0));
      if (!Number.isFinite(applyAmount) || applyAmount <= 0) continue;

      await new sql.Request(tx)
        .input("PayableDocumentId", sql.BigInt, Number(row.PayableDocumentId))
        .input("ApplyDate", sql.Date, applyDate)
        .input("AppliedAmount", sql.Decimal(18, 2), applyAmount)
        .input("PaymentReference", sql.NVarChar(120), `${input.requestId}:${numPago}`)
        .query(`
          INSERT INTO ap.PayableApplication (
            PayableDocumentId,
            ApplyDate,
            AppliedAmount,
            PaymentReference
          )
          VALUES (
            @PayableDocumentId,
            @ApplyDate,
            @AppliedAmount,
            @PaymentReference
          )
        `);

      await new sql.Request(tx)
        .input("PayableDocumentId", sql.BigInt, Number(row.PayableDocumentId))
        .input("AppliedAmount", sql.Decimal(18, 2), applyAmount)
        .query(`
          UPDATE ap.PayableDocument
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
          WHERE PayableDocumentId = @PayableDocumentId
        `);

      applied += applyAmount;
    }

    if (applied <= 0) {
      await tx.rollback();
      return { success: false, message: "No hay montos aplicables para pagar" };
    }

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

    await tx.commit();

    return {
      success: true,
      numPago,
      message: "Pago aplicado en esquema canonico"
    };
  } catch (error: any) {
    try { await tx.rollback(); } catch {}
    return {
      success: false,
      message: `Error aplicando pago canonico: ${String(error?.message ?? error)}`
    };
  }
}

export const aplicarPagoTx = aplicarPago;

export async function listDocumentos(input: ListDocumentosCxPInput) {
  const page = Math.max(1, Number(input.page ?? 1) || 1);
  const limit = Math.min(500, Math.max(1, Number(input.limit ?? 50) || 50));
  const offset = (page - 1) * limit;
  const estado = normalizeCxPEstado(input.estado);

  const params = {
    codProveedor: input.codProveedor || null,
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
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE (@codProveedor IS NULL OR s.SupplierCode = @codProveedor)
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
        s.SupplierCode AS codProveedor,
        d.DocumentType AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate AS fecha,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.Notes AS observacion,
        ROW_NUMBER() OVER (
          ORDER BY d.IssueDate DESC, d.PayableDocumentId DESC
        ) AS rn
      FROM ap.PayableDocument d
      INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      WHERE (@codProveedor IS NULL OR s.SupplierCode = @codProveedor)
        AND (@tipoDoc IS NULL OR d.DocumentType = @tipoDoc)
        AND (@estado IS NULL OR d.Status = @estado)
        AND (@fechaDesde IS NULL OR d.IssueDate >= @fechaDesde)
        AND (@fechaHasta IS NULL OR d.IssueDate <= @fechaHasta)
    )
    SELECT codProveedor, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion
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

export async function getDocumentosPendientes(codProveedor: string) {
  return query<any>(
    `
    SELECT
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.PendingAmount AS pendiente,
      d.TotalAmount AS total
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE s.SupplierCode = @codProveedor
      AND d.PendingAmount > 0
      AND d.Status IN ('PENDING', 'PARTIAL')
    ORDER BY d.IssueDate ASC, d.PayableDocumentId ASC
    `,
    { codProveedor }
  );
}

export async function getSaldoProveedor(codProveedor: string) {
  const rows = await query<any>(
    `
    SELECT
      ISNULL(s.TotalBalance, 0) AS saldoTotal,
      CAST(0 AS DECIMAL(18,2)) AS saldo30,
      CAST(0 AS DECIMAL(18,2)) AS saldo60,
      CAST(0 AS DECIMAL(18,2)) AS saldo90,
      CAST(0 AS DECIMAL(18,2)) AS saldo91
    FROM [master].Supplier s
    WHERE s.SupplierCode = @codProveedor
      AND s.IsDeleted = 0
    `,
    { codProveedor }
  );

  return rows[0] || null;
}
