import { callSp, callSpOut, sql } from "../../db/query.js";
import { emitFiscalRecordFromTransaction } from "../fiscal/service.js";
import { CountryCode } from "../fiscal/types.js";
import { emitSaleAccountingEntry, reprocessPosAccounting } from "../contabilidad/integracion.service.js";
import { getActiveScope } from "../_shared/scope.js";
import { consumeSupervisorOverride } from "../_shared/supervisor-override.service.js";

interface CartItem {
  productoId: string;
  codigo?: string;
  nombre: string;
  cantidad: number;
  precioUnitario: number;
  descuento?: number;
  iva?: number;
  subtotal: number;
  esAnulacion?: boolean;
  anulaItemId?: string;
  motivoAnulacion?: string;
  supervisorUser?: string;
  supervisorApprovalId?: number;
}

interface DefaultScope {
  companyId: number;
  branchId: number;
  countryCode: CountryCode;
}

interface TaxRateRow {
  taxCode: string;
  rate: number;
  isDefault: boolean;
}

const taxRateCache = new Map<CountryCode, TaxRateRow[]>();
let defaultScopeCache: DefaultScope | null = null;

function round2(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function normalizeRate(raw: unknown): number | null {
  const value = Number(raw);
  if (!Number.isFinite(value) || value < 0) return null;
  if (value > 1) return value / 100;
  return value;
}

function normalizeCashRegister(code?: string | null) {
  const value = String(code ?? "").trim().toUpperCase();
  return value || "MAIN";
}

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (defaultScopeCache && activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
      countryCode: (activeScope.countryCode ?? defaultScopeCache.countryCode) as CountryCode,
    };
  }
  if (defaultScopeCache) return defaultScopeCache;

  const rows = await callSp<{ companyId: number; branchId: number; countryCode: string }>(
    "usp_POS_ResolveDefaultScope"
  );

  const row = rows[0];
  defaultScopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    countryCode: String(row?.countryCode ?? "VE") === "ES" ? "ES" : "VE",
  };
  if (activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
      countryCode: (activeScope.countryCode ?? defaultScopeCache.countryCode) as CountryCode,
    };
  }
  return defaultScopeCache;
}

async function resolveScopeWithOverrides(input: {
  empresaId?: number;
  sucursalId?: number;
  countryCode?: CountryCode;
}) {
  const base = await getDefaultScope();
  return {
    companyId: Number(input.empresaId ?? base.companyId),
    branchId: Number(input.sucursalId ?? base.branchId),
    countryCode: (input.countryCode ?? base.countryCode) as CountryCode,
  };
}

async function resolveUserId(userCode?: string | null) {
  const normalized = String(userCode ?? "").trim();
  if (!normalized) return null;

  const rows = await callSp<{ userId: number }>(
    "usp_POS_ResolveUserId",
    { UserCode: normalized }
  );

  const userId = Number(rows[0]?.userId ?? 0);
  return Number.isFinite(userId) && userId > 0 ? userId : null;
}

async function loadCountryTaxRates(countryCode: CountryCode) {
  const cached = taxRateCache.get(countryCode);
  if (cached) return cached;

  const rows = await callSp<{ taxCode: string; rate: number; isDefault: boolean }>(
    "usp_POS_LoadCountryTaxRates",
    { CountryCode: countryCode }
  );

  const normalized = rows.map((row) => ({
    taxCode: String(row.taxCode),
    rate: Number(row.rate ?? 0),
    isDefault: Boolean(row.isDefault),
  }));

  taxRateCache.set(countryCode, normalized);
  return normalized;
}

async function resolveTaxProfile(countryCode: CountryCode, requestedRate: unknown, requestedTaxCode?: string | null) {
  const rates = await loadCountryTaxRates(countryCode);
  if (rates.length === 0) {
    return { taxCode: "EXENTO", taxRate: 0 };
  }

  const normalizedCode = String(requestedTaxCode ?? "").trim().toUpperCase();
  if (normalizedCode) {
    const byCode = rates.find((row) => row.taxCode.toUpperCase() === normalizedCode);
    if (byCode) {
      return { taxCode: byCode.taxCode, taxRate: Number(byCode.rate ?? 0) };
    }
  }

  const rate = normalizeRate(requestedRate);
  if (rate !== null) {
    let best = rates[0];
    let bestDiff = Math.abs(Number(best.rate ?? 0) - rate);
    for (const row of rates) {
      const diff = Math.abs(Number(row.rate ?? 0) - rate);
      if (diff < bestDiff) {
        best = row;
        bestDiff = diff;
      }
    }
    return { taxCode: best.taxCode, taxRate: Number(best.rate ?? 0) };
  }

  const byDefault = rates.find((row) => row.isDefault) ?? rates[0];
  return { taxCode: byDefault.taxCode, taxRate: Number(byDefault.rate ?? 0) };
}

async function resolveProduct(companyId: number, item: CartItem) {
  const identifier = String(item.codigo ?? item.productoId ?? "").trim();
  if (!identifier) {
    return {
      productId: null,
      productCode: String(item.productoId ?? ""),
      productName: item.nombre,
      defaultTaxCode: null as string | null,
      defaultTaxRate: null as number | null,
    };
  }

  const rows = await callSp<any>(
    "usp_POS_ResolveProduct",
    { CompanyId: companyId, Identifier: identifier }
  );

  const row = rows[0];
  if (!row) {
    return {
      productId: null,
      productCode: String(item.codigo ?? item.productoId ?? ""),
      productName: item.nombre,
      defaultTaxCode: null as string | null,
      defaultTaxRate: null as number | null,
    };
  }

  return {
    productId: row.productId ? Number(row.productId) : null,
    productCode: String(row.productCode ?? item.codigo ?? item.productoId ?? ""),
    productName: String(row.productName ?? item.nombre),
    defaultTaxCode: row.defaultTaxCode ? String(row.defaultTaxCode) : null,
    defaultTaxRate: row.defaultTaxRate !== null && row.defaultTaxRate !== undefined ? Number(row.defaultTaxRate) : null,
  };
}

async function resolveCustomer(companyId: number, data: {
  clienteId?: string;
  clienteRif?: string;
  clienteNombre?: string;
}) {
  const idInput = String(data.clienteId ?? "").trim();
  if (idInput) {
    const rows = await callSp<any>(
      "usp_POS_ResolveCustomerById",
      { CompanyId: companyId, IdInput: idInput }
    );

    if (rows[0]) {
      return {
        customerId: Number(rows[0].customerId),
        customerCode: String(rows[0].customerCode ?? idInput),
        customerName: String(rows[0].customerName ?? data.clienteNombre ?? "Consumidor Final"),
        fiscalId: String(rows[0].fiscalId ?? data.clienteRif ?? ""),
      };
    }
  }

  const rif = String(data.clienteRif ?? "").trim();
  if (rif) {
    const rows = await callSp<any>(
      "usp_POS_ResolveCustomerByRif",
      { CompanyId: companyId, Rif: rif }
    );

    if (rows[0]) {
      return {
        customerId: Number(rows[0].customerId),
        customerCode: String(rows[0].customerCode ?? ""),
        customerName: String(rows[0].customerName ?? data.clienteNombre ?? "Consumidor Final"),
        fiscalId: String(rows[0].fiscalId ?? rif),
      };
    }
  }

  return {
    customerId: null,
    customerCode: idInput || null,
    customerName: String(data.clienteNombre ?? "Consumidor Final"),
    fiscalId: rif || null,
  };
}

async function buildCanonicalLines(scope: DefaultScope, items: CartItem[]) {
  const lines: Array<{
    lineNumber: number;
    productId: number | null;
    productCode: string;
    productName: string;
    quantity: number;
    unitPrice: number;
    discountAmount: number;
    taxCode: string;
    taxRate: number;
    netAmount: number;
    taxAmount: number;
    totalAmount: number;
    isVoid: boolean;
    voidOfItemId: string | null;
    voidReason: string | null;
    supervisorUser: string | null;
    supervisorApprovalId: number | null;
  }> = [];

  for (let index = 0; index < items.length; index += 1) {
    const item = items[index];
    const product = await resolveProduct(scope.companyId, item);
    const quantity = Number(item.cantidad ?? 0);
    const unitPrice = Number(item.precioUnitario ?? 0);
    const discountAmount = round2(Number(item.descuento ?? 0));
    const fallbackNet = round2(quantity * unitPrice - discountAmount);
    const netAmount = round2(Number(item.subtotal ?? fallbackNet));

    const tax = await resolveTaxProfile(
      scope.countryCode,
      item.iva ?? product.defaultTaxRate,
      product.defaultTaxCode
    );

    const taxAmount = round2(netAmount * tax.taxRate);
    const totalAmount = round2(netAmount + taxAmount);
    const isVoid = Boolean(item.esAnulacion) || quantity < 0;
    const voidReason = item.motivoAnulacion ? String(item.motivoAnulacion).trim().slice(0, 250) : null;
    const supervisorUser = item.supervisorUser ? String(item.supervisorUser).trim().toUpperCase() : null;
    const supervisorApprovalId = Number(item.supervisorApprovalId ?? 0);

    lines.push({
      lineNumber: index + 1,
      productId: product.productId,
      productCode: product.productCode || String(item.productoId ?? ""),
      productName: product.productName || item.nombre,
      quantity,
      unitPrice,
      discountAmount,
      taxCode: tax.taxCode,
      taxRate: tax.taxRate,
      netAmount,
      taxAmount,
      totalAmount,
      isVoid,
      voidOfItemId: item.anulaItemId ? String(item.anulaItemId).trim() : null,
      voidReason,
      supervisorUser,
      supervisorApprovalId: Number.isFinite(supervisorApprovalId) && supervisorApprovalId > 0 ? supervisorApprovalId : null,
    });
  }

  return lines;
}

export async function crearEspera(data: {
  cajaId: string;
  estacionNombre?: string;
  codUsuario?: string;
  clienteId?: string;
  clienteNombre?: string;
  clienteRif?: string;
  tipoPrecio?: string;
  motivo?: string;
  items: CartItem[];
}) {
  const scope = await getDefaultScope();
  const createdByUserId = await resolveUserId(data.codUsuario);
  const customer = await resolveCustomer(scope.companyId, data);
  const lines = await buildCanonicalLines(scope, data.items);

  const netAmount = round2(lines.reduce((acc, line) => acc + line.netAmount, 0));
  const discountAmount = round2(lines.reduce((acc, line) => acc + line.discountAmount, 0));
  const taxAmount = round2(lines.reduce((acc, line) => acc + line.taxAmount, 0));
  const totalAmount = round2(lines.reduce((acc, line) => acc + line.totalAmount, 0));

  const { output: headerOut } = await callSpOut(
    "usp_POS_WaitTicket_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CountryCode: scope.countryCode,
      CashRegisterCode: normalizeCashRegister(data.cajaId),
      StationName: data.estacionNombre ?? null,
      CreatedByUserId: createdByUserId,
      CustomerId: customer.customerId,
      CustomerCode: customer.customerCode,
      CustomerName: customer.customerName,
      CustomerFiscalId: customer.fiscalId,
      PriceTier: data.tipoPrecio ?? "Detal",
      Reason: data.motivo ?? null,
      NetAmount: netAmount,
      DiscountAmount: discountAmount,
      TaxAmount: taxAmount,
      TotalAmount: totalAmount,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const waitTicketId = Number(headerOut.Resultado ?? 0);
  if (!Number.isFinite(waitTicketId) || waitTicketId <= 0) {
    throw new Error("wait_ticket_not_created");
  }

  for (const line of lines) {
    if (line.isVoid && !line.supervisorApprovalId) {
      throw new Error(`void_line_requires_supervisor_approval:line_${line.lineNumber}`);
    }

    const lineMetaJson = line.isVoid
      ? JSON.stringify({
          isVoid: true,
          reason: line.voidReason,
          supervisorUser: line.supervisorUser,
          voidOfItemId: line.voidOfItemId,
        })
      : null;

    await callSpOut(
      "usp_POS_WaitTicketLine_Insert",
      {
        WaitTicketId: waitTicketId,
        LineNumber: line.lineNumber,
        CountryCode: scope.countryCode,
        ProductId: line.productId,
        ProductCode: line.productCode,
        ProductName: line.productName,
        Quantity: line.quantity,
        UnitPrice: line.unitPrice,
        DiscountAmount: line.discountAmount,
        TaxCode: line.taxCode,
        TaxRate: line.taxRate,
        NetAmount: line.netAmount,
        TaxAmount: line.taxAmount,
        TotalAmount: line.totalAmount,
        SupervisorApprovalId: line.supervisorApprovalId,
        LineMetaJson: lineMetaJson,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );
  }

  return { ok: true, esperaId: waitTicketId };
}

export async function listEspera() {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "usp_POS_WaitTicket_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
    }
  );

  return { rows };
}

export async function recuperarEspera(id: number, recuperadoPor?: string, recuperadoEn?: string) {
  const scope = await getDefaultScope();
  const recoveredByUserId = await resolveUserId(recuperadoPor);

  const headerRows = await callSp<any>(
    "usp_POS_WaitTicket_GetHeader",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      WaitTicketId: id,
    }
  );

  const header = headerRows[0];
  if (!header) return { ok: false, error: "not_found" };

  if (String(header.estado ?? "").toUpperCase() === "WAITING") {
    await callSpOut(
      "usp_POS_WaitTicket_Recover",
      {
        CompanyId: scope.companyId,
        BranchId: scope.branchId,
        WaitTicketId: id,
        RecoveredByUserId: recoveredByUserId,
        RecoveredAtRegister: normalizeCashRegister(recuperadoEn),
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );
  }

  const items = await callSp<any>(
    "usp_POS_WaitTicketLine_GetItems",
    { WaitTicketId: id }
  );

  return {
    ok: true,
    header,
    items,
  };
}

export async function anularEspera(id: number) {
  const scope = await getDefaultScope();

  await callSpOut(
    "usp_POS_WaitTicket_Void",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      WaitTicketId: id,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true };
}

export async function registrarVenta(data: {
  numFactura: string;
  cajaId: string;
  codUsuario?: string;
  clienteId?: string;
  clienteNombre?: string;
  clienteRif?: string;
  tipoPrecio?: string;
  metodoPago?: string;
  tramaFiscal?: string;
  esperaOrigenId?: number;
  empresaId?: number;
  sucursalId?: number;
  countryCode?: CountryCode;
  invoiceTypeHint?: string;
  fiscalPrinterSerial?: string;
  fiscalControlNumber?: string;
  zReportNumber?: number;
  items: CartItem[];
}) {
  const scope = await resolveScopeWithOverrides({
    empresaId: data.empresaId,
    sucursalId: data.sucursalId,
    countryCode: data.countryCode,
  });

  const soldByUserId = await resolveUserId(data.codUsuario);
  const customer = await resolveCustomer(scope.companyId, data);
  const lines = await buildCanonicalLines(scope, data.items);

  const netAmount = round2(lines.reduce((acc, line) => acc + line.netAmount, 0));
  const discountAmount = round2(lines.reduce((acc, line) => acc + line.discountAmount, 0));
  const taxAmount = round2(lines.reduce((acc, line) => acc + line.taxAmount, 0));
  const totalAmount = round2(lines.reduce((acc, line) => acc + line.totalAmount, 0));

  const { output: saleOut } = await callSpOut(
    "usp_POS_SaleTicket_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CountryCode: scope.countryCode,
      InvoiceNumber: data.numFactura,
      CashRegisterCode: normalizeCashRegister(data.cajaId),
      SoldByUserId: soldByUserId,
      CustomerId: customer.customerId,
      CustomerCode: customer.customerCode,
      CustomerName: customer.customerName,
      CustomerFiscalId: customer.fiscalId,
      PriceTier: data.tipoPrecio ?? "Detal",
      PaymentMethod: data.metodoPago ?? null,
      FiscalPayload: data.tramaFiscal ?? null,
      WaitTicketId: data.esperaOrigenId ?? null,
      NetAmount: netAmount,
      DiscountAmount: discountAmount,
      TaxAmount: taxAmount,
      TotalAmount: totalAmount,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const ventaId = Number(saleOut.Resultado ?? 0);
  if (!Number.isFinite(ventaId) || ventaId <= 0) {
    throw new Error("sale_ticket_not_created");
  }

  for (const line of lines) {
    if (line.isVoid && !line.supervisorApprovalId) {
      throw new Error(`void_line_requires_supervisor_approval:line_${line.lineNumber}`);
    }

    const lineMetaJson = line.isVoid
      ? JSON.stringify({
          isVoid: true,
          reason: line.voidReason,
          supervisorUser: line.supervisorUser,
          voidOfItemId: line.voidOfItemId,
        })
      : null;

    const { output: lineOut } = await callSpOut(
      "usp_POS_SaleTicketLine_Insert",
      {
        SaleTicketId: ventaId,
        LineNumber: line.lineNumber,
        CountryCode: scope.countryCode,
        ProductId: line.productId,
        ProductCode: line.productCode,
        ProductName: line.productName,
        Quantity: line.quantity,
        UnitPrice: line.unitPrice,
        DiscountAmount: line.discountAmount,
        TaxCode: line.taxCode,
        TaxRate: line.taxRate,
        NetAmount: line.netAmount,
        TaxAmount: line.taxAmount,
        TotalAmount: line.totalAmount,
        SupervisorApprovalId: line.supervisorApprovalId,
        LineMetaJson: lineMetaJson,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );

    if (line.isVoid && line.supervisorApprovalId) {
      const saleTicketLineId = Number(lineOut.Resultado ?? 0);
      const consumed = await consumeSupervisorOverride({
        overrideId: line.supervisorApprovalId,
        moduleCode: "POS",
        actionCode: "CART_LINE_VOID",
        consumedByUser: data.codUsuario,
        sourceDocumentId: ventaId,
        sourceLineId: saleTicketLineId > 0 ? saleTicketLineId : null,
      });

      if (!consumed.ok) {
        throw new Error(`supervisor_override_not_available:${line.supervisorApprovalId}`);
      }
    }
  }

  if (Number.isFinite(Number(data.esperaOrigenId)) && Number(data.esperaOrigenId) > 0) {
    await callSpOut(
      "usp_POS_WaitTicket_Recover",
      {
        CompanyId: scope.companyId,
        BranchId: scope.branchId,
        WaitTicketId: Number(data.esperaOrigenId),
        RecoveredByUserId: soldByUserId,
        RecoveredAtRegister: normalizeCashRegister(data.cajaId),
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );
  }

  let fiscal: Awaited<ReturnType<typeof emitFiscalRecordFromTransaction>> | { ok: false; reason: string };
  try {
    fiscal = await emitFiscalRecordFromTransaction({
      empresaId: scope.companyId,
      sucursalId: scope.branchId,
      countryCode: scope.countryCode,
      sourceModule: "POS",
      invoiceId: Number(ventaId),
      invoiceNumber: data.numFactura,
      invoiceDate: new Date(),
      invoiceTypeHint: data.invoiceTypeHint,
      recipientId: customer.fiscalId ?? undefined,
      totalAmount,
      payload: {
        cajaId: normalizeCashRegister(data.cajaId),
        metodoPago: data.metodoPago,
        codUsuario: data.codUsuario,
      },
      metadata: {
        fiscalPrinterSerial: data.fiscalPrinterSerial,
        fiscalControlNumber: data.fiscalControlNumber,
        zReportNumber: data.zReportNumber,
        tramaFiscal: data.tramaFiscal,
      },
    });
  } catch (fiscalError: any) {
    fiscal = {
      ok: false,
      reason: `fiscal_emit_exception:${String(fiscalError?.message ?? fiscalError)}`,
    };
  }

  let contabilidad: Awaited<ReturnType<typeof emitSaleAccountingEntry>>;
  try {
    contabilidad = await emitSaleAccountingEntry({
      module: "POS",
      sourceId: Number(ventaId),
      documentNumber: data.numFactura,
      issueDate: new Date(),
      paymentMethod: data.metodoPago,
      codUsuario: data.codUsuario,
      currency: scope.countryCode === "ES" ? "EUR" : "VES",
      exchangeRate: 1,
      baseAmount: netAmount,
      taxAmount,
      totalAmount,
      taxSummary: lines.map((line) => ({
        taxCode: line.taxCode,
        taxRate: line.taxRate,
        baseAmount: line.netAmount,
        taxAmount: line.taxAmount,
        totalAmount: line.totalAmount,
      })),
    });
  } catch (accountingError: any) {
    contabilidad = {
      ok: false,
      reason: `accounting_emit_exception:${String(accountingError?.message ?? accountingError)}`,
    };
  }

  return { ok: true, ventaId, fiscal, contabilidad };
}

export async function contabilizarVentaExistente(params: {
  ventaId: number;
  codUsuario?: string;
  countryCode?: CountryCode;
  currency?: string;
  exchangeRate?: number;
}) {
  return reprocessPosAccounting({
    ventaId: params.ventaId,
    codUsuario: params.codUsuario,
    countryCode: params.countryCode,
    currency: params.currency,
    exchangeRate: params.exchangeRate,
  });
}
