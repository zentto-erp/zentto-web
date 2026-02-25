import { query } from "../../db/query.js";
import { crearAsiento, type AsientoDetalleInput } from "./service.js";

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
      OBJECT_ID('dbo.usp_Contabilidad_Asiento_Crear', 'P') IS NOT NULL
      AND OBJECT_ID('dbo.AsientoContable', 'U') IS NOT NULL
      AND OBJECT_ID('dbo.AsientoContableDetalle', 'U') IS NOT NULL
      AND OBJECT_ID('dbo.Cuentas', 'U') IS NOT NULL
    THEN 1 ELSE 0 END AS ok
    `
  );
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function accountExists(accountCode: string): Promise<boolean> {
  const rows = await query<{ ok: number }>(
    `
    SELECT CASE WHEN EXISTS (
      SELECT 1 FROM dbo.Cuentas WHERE LTRIM(RTRIM(COD_CUENTA)) = LTRIM(RTRIM(@accountCode))
    ) THEN 1 ELSE 0 END AS ok
    `,
    { accountCode }
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
  const hasConfigRows = await query<{ ok: number }>(
    `
    SELECT CASE WHEN OBJECT_ID('dbo.ConfiguracionContableAuxiliar', 'U') IS NOT NULL
    THEN 1 ELSE 0 END AS ok
    `
  );
  if (Number(hasConfigRows[0]?.ok ?? 0) !== 1) return [];

  const rows = await query<ConfigRow>(
    `
    SELECT
      Proceso,
      Naturaleza,
      CuentaContable,
      CentroCostoDefault
    FROM dbo.ConfiguracionContableAuxiliar
    WHERE Modulo = @module
      AND Activo = 1
      AND Proceso IN ('VENTA_TOTAL', 'VENTA_TOTAL_CAJA', 'VENTA_TOTAL_BANCO', 'VENTA_BASE', 'VENTA_IVA')
    `,
    { module }
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
  const hasOriginTable = await query<{ ok: number }>(
    `
    SELECT CASE WHEN OBJECT_ID('dbo.AsientoOrigenAuxiliar', 'U') IS NOT NULL
    THEN 1 ELSE 0 END AS ok
    `
  );
  if (Number(hasOriginTable[0]?.ok ?? 0) !== 1) return null;

  const rows = await query<ExistingAsientoRow>(
    `
    SELECT TOP 1
      a.Id AS asientoId,
      a.NumeroAsiento AS numeroAsiento
    FROM dbo.AsientoOrigenAuxiliar ao
    INNER JOIN dbo.AsientoContable a ON a.Id = ao.AsientoId
    WHERE ao.OrigenModulo = @module
      AND ao.NumeroDocumento = @originDocument
    ORDER BY ao.Id DESC
    `,
    { module, originDocument }
  );
  return rows[0] ?? null;
}

async function linkSourceToAsiento(module: SalesModule, sourceId: number, asientoId: number): Promise<void> {
  if (module === "POS") {
    await query(
      `
      IF OBJECT_ID('dbo.PosVentas', 'U') IS NOT NULL
         AND COL_LENGTH('dbo.PosVentas', 'AsientoContableId') IS NOT NULL
      BEGIN
        UPDATE dbo.PosVentas
        SET AsientoContableId = @asientoId
        WHERE Id = @sourceId
      END
      `,
      { asientoId, sourceId }
    );
    return;
  }

  await query(
    `
    IF OBJECT_ID('dbo.RestaurantePedidos', 'U') IS NOT NULL
       AND COL_LENGTH('dbo.RestaurantePedidos', 'AsientoContableId') IS NOT NULL
    BEGIN
      UPDATE dbo.RestaurantePedidos
      SET AsientoContableId = @asientoId
      WHERE Id = @sourceId
    END
    `,
    { asientoId, sourceId }
  );
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
      Id AS id,
      NumFactura AS numFactura,
      FechaVenta AS fechaVenta,
      MetodoPago AS metodoPago,
      CodUsuario AS codUsuario,
      Subtotal AS subtotal,
      Impuestos AS impuestos,
      Total AS total
    FROM dbo.PosVentas
    WHERE Id = @ventaId
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
      IVA AS taxRate,
      SUM(Subtotal) AS baseAmount,
      SUM(Subtotal * IVA / 100.0) AS taxAmount,
      SUM(Subtotal + (Subtotal * IVA / 100.0)) AS totalAmount
    FROM dbo.PosVentasDetalle
    WHERE VentaId = @ventaId
    GROUP BY IVA
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
      Id AS id,
      Total AS total,
      FechaCierre AS fechaCierre,
      CodUsuario AS codUsuario
    FROM dbo.RestaurantePedidos
    WHERE Id = @pedidoId
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
      CAST(
        CASE
          WHEN ISNULL(IvaPct, 0) > 1 THEN ISNULL(IvaPct, 0) / 100.0
          ELSE ISNULL(IvaPct, 0)
        END AS DECIMAL(9,4)
      ) AS taxRate,
      SUM(Subtotal) AS baseAmount,
      SUM(
        Subtotal * CASE
          WHEN ISNULL(IvaPct, 0) > 1 THEN ISNULL(IvaPct, 0) / 100.0
          ELSE ISNULL(IvaPct, 0)
        END
      ) AS taxAmount,
      SUM(
        Subtotal + (
          Subtotal * CASE
            WHEN ISNULL(IvaPct, 0) > 1 THEN ISNULL(IvaPct, 0) / 100.0
            ELSE ISNULL(IvaPct, 0)
          END
        )
      ) AS totalAmount
    FROM dbo.RestaurantePedidoItems
    WHERE PedidoId = @pedidoId
    GROUP BY CAST(
      CASE
        WHEN ISNULL(IvaPct, 0) > 1 THEN ISNULL(IvaPct, 0) / 100.0
        ELSE ISNULL(IvaPct, 0)
      END AS DECIMAL(9,4)
    )
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
