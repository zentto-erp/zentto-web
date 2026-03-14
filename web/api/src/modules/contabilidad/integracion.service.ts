import { query } from "../../db/query.js";
import { crearAsiento, type AsientoDetalleInput } from "./service.js";
import { getActiveScope } from "../_shared/scope.js";

type SalesModule = "POS" | "RESTAURANTE";

interface ConfigRow {
  Proceso: string;
  Naturaleza: string;
  CuentaContable: string;
  CentroCostoDefault: string | null;
}

interface ExistingAsientoRow {
  asientoId: number;
  numeroAsiento: string | null;
}

interface PosHeaderRow {
  id: number;
  numFactura: string;
  fechaVenta: Date | string | null;
  metodoPago: string | null;
  codUsuario: string | null;
  subtotal: number | null;
  impuestos: number | null;
  total: number | null;
}

interface RestauranteHeaderRow {
  id: number;
  total: number | null;
  fechaCierre: Date | string | null;
  codUsuario: string | null;
}

interface TaxSummaryRow {
  taxRate: number | null;
  baseAmount: number | null;
  taxAmount: number | null;
  totalAmount: number | null;
}

export interface AccountingTaxSummaryItem {
  taxCode?: string;
  taxRate: number;
  baseAmount: number;
  taxAmount: number;
  totalAmount: number;
}

export interface EmitSaleAccountingEntryInput {
  module: SalesModule;
  sourceId: number;
  documentNumber: string;
  issueDate?: Date;
  paymentMethod?: string;
  codUsuario?: string;
  currency?: string;
  exchangeRate?: number;
  concept?: string;
  baseAmount: number;
  taxAmount: number;
  totalAmount: number;
  taxSummary?: AccountingTaxSummaryItem[];
  originDocument?: string;
}

export interface EmitSaleAccountingEntryResult {
  ok: boolean;
  skipped?: boolean;
  reason?: string;
  asientoExistente?: boolean;
  asientoId?: number | null;
  numeroAsiento?: string | null;
  mensaje?: string;
}

export interface ReprocessPosAccountingInput {
  ventaId: number;
  codUsuario?: string;
  countryCode?: "VE" | "ES";
  currency?: string;
  exchangeRate?: number;
}

export interface ReprocessRestauranteAccountingInput {
  pedidoId: number;
  codUsuario?: string;
  countryCode?: "VE" | "ES";
  currency?: string;
  exchangeRate?: number;
  invoiceNumber?: string;
}

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function round4(value: number): number {
  return Math.round((value + Number.EPSILON) * 10000) / 10000;
}

function resolveCurrency(inputCurrency: string | undefined, countryCode?: "VE" | "ES"): string {
  if (inputCurrency && inputCurrency.trim()) return inputCurrency.trim().toUpperCase();
  if (countryCode === "ES") return "EUR";
  return "VES";
}

let defaultScopeCache: { companyId: number; branchId: number } | null = null;

async function getDefaultScope(): Promise<{ companyId: number; branchId: number }> {
  const activeScope = getActiveScope();
  if (defaultScopeCache && activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (defaultScopeCache) return defaultScopeCache;

  const rows = await query<{ companyId: number; branchId: number }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId
    WHERE c.CompanyCode = N'DEFAULT'
      AND b.BranchCode = N'MAIN'
    ORDER BY c.CompanyId, b.BranchId
    `
  );

  defaultScopeCache = {
    companyId: Number(rows[0]?.companyId ?? 1),
    branchId: Number(rows[0]?.branchId ?? 1)
  };
  if (activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  return defaultScopeCache;
}

function isBankPayment(paymentMethod?: string): boolean {
  if (!paymentMethod) return false;
  const normalized = paymentMethod.trim().toLowerCase();
  if (!normalized) return false;
  return (
    normalized.includes("tarjeta") ||
    normalized.includes("card") ||
    normalized.includes("transfer") ||
    normalized.includes("debito") ||
    normalized.includes("credito") ||
    normalized.includes("punto") ||
    normalized.includes("banco") ||
    normalized.includes("zelle") ||
    normalized.includes("pago movil")
  );
}

async function hasContabilidadInfra(): Promise<boolean> {
  const rows = await query<{ ok: number }>(
    `
    SELECT CASE WHEN
      OBJECT_ID('acct.Account', 'U') IS NOT NULL
      AND OBJECT_ID('acct.JournalEntry', 'U') IS NOT NULL
      AND OBJECT_ID('acct.JournalEntryLine', 'U') IS NOT NULL
    THEN 1 ELSE 0 END AS ok
    `
  );
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function accountExists(accountCode: string): Promise<boolean> {
  const scope = await getDefaultScope();
  const rows = await query<{ ok: number }>(
    `
    SELECT CASE WHEN EXISTS (
      SELECT 1
      FROM acct.Account
      WHERE CompanyId = @companyId
        AND LTRIM(RTRIM(AccountCode)) = LTRIM(RTRIM(@accountCode))
        AND IsDeleted = 0
    ) THEN 1 ELSE 0 END AS ok
    `,
    {
      companyId: scope.companyId,
      accountCode
    }
  );
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function pickFirstExistingAccount(candidates: Array<string | null | undefined>): Promise<string | null> {
  for (const candidate of candidates) {
    const normalized = String(candidate ?? "").trim();
    if (!normalized) continue;
    if (await accountExists(normalized)) return normalized;
  }
  return null;
}

async function loadConfigRows(module: SalesModule): Promise<ConfigRow[]> {
  const scope = await getDefaultScope();
  const rows = await query<ConfigRow>(
    `
    SELECT
      p.ProcessCode AS Proceso,
      CASE WHEN p.Nature = 'DEBIT' THEN N'DEBE' ELSE N'HABER' END AS Naturaleza,
      a.AccountCode AS CuentaContable,
      CAST(NULL AS NVARCHAR(20)) AS CentroCostoDefault
    FROM acct.AccountingPolicy p
    INNER JOIN acct.Account a ON a.AccountId = p.AccountId
    WHERE p.CompanyId = @companyId
      AND p.ModuleCode = @module
      AND p.IsActive = 1
      AND p.ProcessCode IN ('VENTA_TOTAL', 'VENTA_TOTAL_CAJA', 'VENTA_TOTAL_BANCO', 'VENTA_BASE', 'VENTA_IVA')
    ORDER BY p.PriorityOrder, p.AccountingPolicyId
    `,
    {
      companyId: scope.companyId,
      module
    }
  );
  return rows ?? [];
}

function accountFromConfig(rows: ConfigRow[], process: string, naturaleza?: string): string | null {
  const found = rows.find((row) => {
    if (row.Proceso !== process) return false;
    if (!naturaleza) return true;
    return row.Naturaleza.toUpperCase() === naturaleza.toUpperCase();
  });
  return found?.CuentaContable ? String(found.CuentaContable).trim() : null;
}

function centerCostFromConfig(rows: ConfigRow[]): string | null {
  const found = rows.find((row) => String(row.CentroCostoDefault ?? "").trim() !== "");
  return found?.CentroCostoDefault ? String(found.CentroCostoDefault).trim() : null;
}

async function resolveMapping(module: SalesModule, paymentMethod?: string) {
  const rows = await loadConfigRows(module);
  const bankPayment = isBankPayment(paymentMethod);

  const debitAccount = await pickFirstExistingAccount(
    bankPayment
      ? [
          accountFromConfig(rows, "VENTA_TOTAL_BANCO", "DEBE"),
          accountFromConfig(rows, "VENTA_TOTAL", "DEBE"),
          "1.1.02",
          "1.1.01"
        ]
      : [
          accountFromConfig(rows, "VENTA_TOTAL_CAJA", "DEBE"),
          accountFromConfig(rows, "VENTA_TOTAL", "DEBE"),
          "1.1.01",
          "1.1.02"
        ]
  );

  const salesAccount = await pickFirstExistingAccount([
    accountFromConfig(rows, "VENTA_BASE", "HABER"),
    module === "RESTAURANTE" ? "4.1.03" : "4.1.01",
    "4.1.01"
  ]);

  const vatAccount = await pickFirstExistingAccount([
    accountFromConfig(rows, "VENTA_IVA", "HABER"),
    "2.1.03"
  ]);

  const centerCost = centerCostFromConfig(rows) || "VEN";

  return {
    debitAccount,
    salesAccount,
    vatAccount,
    centerCost
  };
}

async function findExistingAsientoByOrigin(module: SalesModule, originDocument: string): Promise<ExistingAsientoRow | null> {
  const scope = await getDefaultScope();
  const rows = await query<ExistingAsientoRow>(
    `
    SELECT TOP 1
      je.JournalEntryId AS asientoId,
      je.EntryNumber AS numeroAsiento
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @companyId
      AND je.BranchId = @branchId
      AND je.SourceModule = @module
      AND je.SourceDocumentNo = @originDocument
      AND je.IsDeleted = 0
    ORDER BY je.JournalEntryId DESC
    `
    ,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      module,
      originDocument
    }
  );
  return rows[0] ?? null;
}

async function resolveJournalEntryIdBySource(module: SalesModule, originDocument: string): Promise<number | null> {
  const scope = await getDefaultScope();
  const rows = await query<{ journalEntryId: number | null }>(
    `
    SELECT TOP 1
      CAST(je.JournalEntryId AS BIGINT) AS journalEntryId
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @companyId
      AND je.BranchId = @branchId
      AND je.SourceModule = @module
      AND je.SourceDocumentNo = @originDocument
      AND je.IsDeleted = 0
    ORDER BY je.JournalEntryId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      module,
      originDocument
    }
  );
  const journalEntryId = Number(rows[0]?.journalEntryId ?? 0);
  if (!Number.isFinite(journalEntryId) || journalEntryId <= 0) return null;
  return journalEntryId;
}

async function upsertDocumentLink(params: {
  module: SalesModule;
  originDocument: string;
  journalEntryId: number;
}) {
  const scope = await getDefaultScope();
  await query(
    `
    IF NOT EXISTS (
      SELECT 1
      FROM acct.DocumentLink
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND ModuleCode = @module
        AND DocumentType = @documentType
        AND DocumentNumber = @originDocument
    )
    BEGIN
      INSERT INTO acct.DocumentLink (
        CompanyId,
        BranchId,
        ModuleCode,
        DocumentType,
        DocumentNumber,
        NativeDocumentId,
        JournalEntryId
      )
      VALUES (
        @companyId,
        @branchId,
        @module,
        @documentType,
        @originDocument,
        NULL,
        @journalEntryId
      )
    END
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      module: params.module,
      documentType: "VENTA",
      originDocument: params.originDocument,
      journalEntryId: params.journalEntryId
    }
  );
}

async function linkSourceToAsiento(_module: SalesModule, _sourceId: number, _asientoId: number): Promise<void> {
  return;
}

function normalizeTotals(baseAmount: number, taxAmount: number, totalAmount: number) {
  let base = round2(Number(baseAmount || 0));
  let tax = round2(Number(taxAmount || 0));
  let total = round2(Number(totalAmount || 0));

  if (!Number.isFinite(base) || base < 0) base = 0;
  if (!Number.isFinite(tax) || tax < 0) tax = 0;
  if (!Number.isFinite(total) || total < 0) total = 0;

  if (base === 0 && tax === 0 && total > 0) {
    base = total;
  }

  const diff = round2(total - (base + tax));
  if (diff !== 0) {
    base = round2(base + diff);
    if (base < 0) {
      tax = round2(tax + base);
      base = 0;
    }
  }

  if (tax < 0) tax = 0;
  total = round2(base + tax);

  return { base, tax, total };
}

function resolveConcept(module: SalesModule, documentNumber: string): string {
  if (module === "RESTAURANTE") return `Venta restaurante ${documentNumber}`;
  return `Venta POS ${documentNumber}`;
}

function buildOriginDocument(module: SalesModule, sourceId: number, originDocument?: string): string {
  const normalized = String(originDocument ?? "").trim();
  if (normalized) return normalized;
  return `${module}:${sourceId}`;
}

export async function emitSaleAccountingEntry(input: EmitSaleAccountingEntryInput): Promise<EmitSaleAccountingEntryResult> {
  if (!(await hasContabilidadInfra())) {
    return {
      ok: false,
      skipped: true,
      reason: "contabilidad_infra_not_ready"
    };
  }

  const mapping = await resolveMapping(input.module, input.paymentMethod);
  if (!mapping.debitAccount || !mapping.salesAccount) {
    return {
      ok: false,
      skipped: true,
      reason: "contabilidad_accounts_not_configured"
    };
  }

  const normalized = normalizeTotals(input.baseAmount, input.taxAmount, input.totalAmount);
  if (normalized.total <= 0) {
    return {
      ok: false,
      skipped: true,
      reason: "contabilidad_zero_total"
    };
  }

  const originDocument = buildOriginDocument(input.module, input.sourceId, input.originDocument);
  const existing = await findExistingAsientoByOrigin(input.module, originDocument);
  if (existing) {
    await linkSourceToAsiento(input.module, input.sourceId, Number(existing.asientoId));
    return {
      ok: true,
      asientoExistente: true,
      asientoId: Number(existing.asientoId),
      numeroAsiento: existing.numeroAsiento
    };
  }

  const detalle: AsientoDetalleInput[] = [
    {
      codCuenta: mapping.debitAccount,
      descripcion: input.module === "RESTAURANTE" ? "Cobro restaurante" : "Cobro POS",
      centroCosto: mapping.centerCost,
      documento: input.documentNumber,
      debe: normalized.total,
      haber: 0
    },
    {
      codCuenta: mapping.salesAccount,
      descripcion: input.module === "RESTAURANTE" ? "Ingreso por venta restaurante" : "Ingreso por venta POS",
      centroCosto: mapping.centerCost,
      documento: input.documentNumber,
      debe: 0,
      haber: normalized.base
    }
  ];

  if (normalized.tax > 0) {
    detalle.push({
      codCuenta: mapping.vatAccount || "2.1.03",
      descripcion: "IVA por pagar",
      centroCosto: mapping.centerCost,
      documento: input.documentNumber,
      debe: 0,
      haber: normalized.tax
    });
  }

  const asiento = await crearAsiento(
    {
      fecha: (input.issueDate ?? new Date()).toISOString().slice(0, 10),
      tipoAsiento: "DIA",
      referencia: input.documentNumber,
      concepto: input.concept || resolveConcept(input.module, input.documentNumber),
      moneda: resolveCurrency(input.currency, undefined),
      tasa: input.exchangeRate ?? 1,
      origenModulo: input.module,
      origenDocumento: originDocument,
      detalle
    },
    input.codUsuario || "API"
  );

  if (!asiento.ok) {
    return {
      ok: false,
      mensaje: asiento.mensaje,
      reason: "contabilidad_create_failed"
    };
  }

  if (asiento.asientoId) {
    await linkSourceToAsiento(input.module, input.sourceId, Number(asiento.asientoId));
    const journalEntryId = await resolveJournalEntryIdBySource(input.module, originDocument);
    if (journalEntryId) {
      await upsertDocumentLink({
        module: input.module,
        originDocument,
        journalEntryId
      });
    }
  }

  return {
    ok: true,
    asientoId: asiento.asientoId,
    numeroAsiento: asiento.numeroAsiento,
    mensaje: asiento.mensaje
  };
}

function normalizeTaxRate(raw: number | null): number {
  const value = Number(raw ?? 0);
  if (!Number.isFinite(value) || value <= 0) return 0;
  if (value > 1) return round4(value / 100);
  return round4(value);
}

function buildTaxSummary(rows: TaxSummaryRow[]): AccountingTaxSummaryItem[] {
  return rows
    .map((row) => {
      const rate = normalizeTaxRate(row.taxRate ?? 0);
      const base = round2(Number(row.baseAmount ?? 0));
      const tax = round2(Number(row.taxAmount ?? 0));
      const total = round2(Number(row.totalAmount ?? base + tax));
      return {
        taxRate: rate,
        baseAmount: base,
        taxAmount: tax,
        totalAmount: total
      };
    })
    .filter((row) => row.baseAmount > 0 || row.taxAmount > 0);
}

export async function reprocessPosAccounting(input: ReprocessPosAccountingInput): Promise<EmitSaleAccountingEntryResult> {
  const rows = await query<PosHeaderRow>(
    `
    SELECT TOP 1
      v.SaleTicketId AS id,
      v.InvoiceNumber AS numFactura,
      v.SoldAt AS fechaVenta,
      v.PaymentMethod AS metodoPago,
      u.UserCode AS codUsuario,
      v.NetAmount AS subtotal,
      v.TaxAmount AS impuestos,
      v.TotalAmount AS total
    FROM pos.SaleTicket v
    LEFT JOIN sec.[User] u ON u.UserId = v.SoldByUserId
    WHERE v.SaleTicketId = @ventaId
    `,
    { ventaId: input.ventaId }
  );

  const header = rows[0];
  if (!header) {
    return { ok: false, skipped: true, reason: "venta_not_found" };
  }

  const taxRows = await query<TaxSummaryRow>(
    `
    SELECT
      TaxRate AS taxRate,
      SUM(NetAmount) AS baseAmount,
      SUM(TaxAmount) AS taxAmount,
      SUM(TotalAmount) AS totalAmount
    FROM pos.SaleTicketLine
    WHERE SaleTicketId = @ventaId
    GROUP BY TaxRate
    `,
    { ventaId: input.ventaId }
  );

  const taxSummary = buildTaxSummary(taxRows);
  const baseAmount = round2(
    Number(header.subtotal ?? taxSummary.reduce((acc, row) => acc + row.baseAmount, 0))
  );
  const taxAmount = round2(
    Number(header.impuestos ?? taxSummary.reduce((acc, row) => acc + row.taxAmount, 0))
  );
  const totalAmount = round2(
    Number(header.total ?? baseAmount + taxAmount)
  );

  return emitSaleAccountingEntry({
    module: "POS",
    sourceId: Number(header.id),
    documentNumber: String(header.numFactura),
    issueDate: header.fechaVenta ? new Date(header.fechaVenta) : new Date(),
    paymentMethod: header.metodoPago || undefined,
    codUsuario: input.codUsuario || header.codUsuario || "API",
    currency: resolveCurrency(input.currency, input.countryCode),
    exchangeRate: input.exchangeRate ?? 1,
    baseAmount,
    taxAmount,
    totalAmount,
    taxSummary
  });
}

export async function reprocessRestauranteAccounting(
  input: ReprocessRestauranteAccountingInput
): Promise<EmitSaleAccountingEntryResult> {
  const rows = await query<RestauranteHeaderRow>(
    `
    SELECT TOP 1
      o.OrderTicketId AS id,
      o.TotalAmount AS total,
      o.ClosedAt AS fechaCierre,
      COALESCE(uClose.UserCode, uOpen.UserCode) AS codUsuario
    FROM rest.OrderTicket o
    LEFT JOIN sec.[User] uOpen ON uOpen.UserId = o.OpenedByUserId
    LEFT JOIN sec.[User] uClose ON uClose.UserId = o.ClosedByUserId
    WHERE o.OrderTicketId = @pedidoId
    `,
    { pedidoId: input.pedidoId }
  );

  const header = rows[0];
  if (!header) {
    return { ok: false, skipped: true, reason: "pedido_not_found" };
  }

  const taxRows = await query<TaxSummaryRow>(
    `
    SELECT
      TaxRate AS taxRate,
      SUM(NetAmount) AS baseAmount,
      SUM(TaxAmount) AS taxAmount,
      SUM(TotalAmount) AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @pedidoId
    GROUP BY TaxRate
    `,
    { pedidoId: input.pedidoId }
  );

  const taxSummary = buildTaxSummary(taxRows);
  const baseAmount = round2(taxSummary.reduce((acc, row) => acc + row.baseAmount, 0));
  const taxAmount = round2(taxSummary.reduce((acc, row) => acc + row.taxAmount, 0));
  const fallbackTotal = round2(Number(header.total ?? 0));
  const totalAmount = round2(baseAmount + taxAmount > 0 ? baseAmount + taxAmount : fallbackTotal);
  const documentNumber = String(input.invoiceNumber ?? `REST-${input.pedidoId}`);

  return emitSaleAccountingEntry({
    module: "RESTAURANTE",
    sourceId: Number(header.id),
    documentNumber,
    issueDate: header.fechaCierre ? new Date(header.fechaCierre) : new Date(),
    paymentMethod: "CAJA",
    codUsuario: input.codUsuario || header.codUsuario || "API",
    currency: resolveCurrency(input.currency, input.countryCode),
    exchangeRate: input.exchangeRate ?? 1,
    baseAmount,
    taxAmount,
    totalAmount,
    taxSummary
  });
}
