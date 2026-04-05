import { callSp, callSpOut, sql } from "../../db/query.js";
import { emitFiscalRecordFromTransaction } from "../fiscal/service.js";
import { CountryCode } from "../fiscal/types.js";
import { emitSaleAccountingEntry, reprocessRestauranteAccounting } from "../contabilidad/integracion.service.js";
import { getActiveScope } from "../_shared/scope.js";
import { getCountryCurrency } from "../_shared/country-currency.js";
import { consumeSupervisorOverride, createSupervisorOverride, validateSupervisorCredentials } from "../_shared/supervisor-override.service.js";

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

function mapOrderStatusToLegacy(status: string | null | undefined) {
  const normalized = String(status ?? "").toUpperCase();
  if (normalized === "OPEN") return "abierto";
  if (normalized === "SENT") return "enviado";
  if (normalized === "CLOSED") return "cerrado";
  if (normalized === "VOIDED") return "anulado";
  return "abierto";
}

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (defaultScopeCache && activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
      countryCode: activeScope.countryCode ?? defaultScopeCache.countryCode,
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
    countryCode: String(row?.countryCode ?? "VE").toUpperCase(),
  };
  if (activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
      countryCode: activeScope.countryCode ?? defaultScopeCache.countryCode,
    };
  }
  return defaultScopeCache;
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

async function resolveProduct(companyId: number, identifier: string) {
  const normalized = String(identifier ?? "").trim();
  if (!normalized) return null;

  const rows = await callSp<any>(
    "usp_POS_ResolveProduct",
    { CompanyId: companyId, Identifier: normalized }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    productId: Number(row.productId),
    productCode: String(row.productCode ?? normalized),
    productName: String(row.productName ?? normalized),
    defaultTaxCode: row.defaultTaxCode ? String(row.defaultTaxCode) : null,
    defaultTaxRate: row.defaultTaxRate !== null && row.defaultTaxRate !== undefined ? Number(row.defaultTaxRate) : null,
  };
}

async function getDiningTableById(scope: DefaultScope, mesaId: number) {
  const rows = await callSp<any>(
    "usp_Rest_DiningTable_GetById",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      MesaId: mesaId,
    }
  );

  return rows[0] ?? null;
}

async function getOpenOrderByTable(scope: DefaultScope, tableNumber: string) {
  const rows = await callSp<any>(
    "usp_Rest_OrderTicket_GetOpenByTable",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      TableNumber: tableNumber,
    }
  );

  return rows[0] ?? null;
}

async function recalcOrderTotals(orderId: number) {
  const scope = await getDefaultScope();
  await callSp("usp_Rest_OrderTicket_RecalcTotals", { CompanyId: scope.companyId, OrderId: orderId });
}

// Mesas
export async function listMesas(ambienteId?: string) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "usp_Rest_DiningTable_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      AmbienteId: ambienteId ?? null,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

// Pedidos
export async function abrirPedido(mesaId: number, clienteNombre?: string, clienteRif?: string, codUsuario?: string) {
  const scope = await getDefaultScope();
  const table = await getDiningTableById(scope, mesaId);
  if (!table) {
    return { ok: false, error: "mesa_not_found", executionMode: "ts_canonical" as const };
  }

  const existing = await getOpenOrderByTable(scope, String(table.tableNumber));
  if (existing) {
    return {
      ok: true,
      pedidoId: Number(existing.id),
      executionMode: "ts_canonical" as const,
      reused: true,
    };
  }

  const openedByUserId = await resolveUserId(codUsuario);

  const { output } = await callSpOut(
    "usp_Rest_OrderTicket_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CountryCode: scope.countryCode,
      TableNumber: String(table.tableNumber),
      OpenedByUserId: openedByUserId,
      CustomerName: clienteNombre ?? null,
      CustomerFiscalId: clienteRif ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const pedidoId = Number(output.Resultado ?? 0);
  if (!Number.isFinite(pedidoId) || pedidoId <= 0) {
    return { ok: false, error: "pedido_not_created", executionMode: "ts_canonical" as const };
  }

  return { ok: true, pedidoId, executionMode: "ts_canonical" as const };
}

export async function agregarItemPedido(params: {
  pedidoId: number;
  productoId: string;
  nombre: string;
  cantidad: number;
  precioUnitario: number;
  iva?: number;
  esCompuesto?: boolean;
  componentes?: string;
  comentarios?: string;
}) {
  const scope = await getDefaultScope();
  const orderRows = await callSp<any>(
    "usp_Rest_OrderTicket_GetById",
    { CompanyId: scope.companyId, PedidoId: params.pedidoId }
  );

  const order = orderRows[0];
  if (!order) {
    return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
  }

  const status = String(order.status ?? "").toUpperCase();
  if (status === "CLOSED" || status === "VOIDED") {
    return { ok: false, error: "pedido_not_open", executionMode: "ts_canonical" as const };
  }

  const countryCode: CountryCode = String(order.countryCode ?? "VE").toUpperCase();
  const product = await resolveProduct(Number(order.companyId), params.productoId);

  const quantity = Number(params.cantidad ?? 0);
  const unitPrice = Number(params.precioUnitario ?? 0);
  const netAmount = round2(quantity * unitPrice);

  const taxProfile = await resolveTaxProfile(
    countryCode,
    params.iva ?? product?.defaultTaxRate,
    product?.defaultTaxCode
  );

  const taxAmount = round2(netAmount * taxProfile.taxRate);
  const totalAmount = round2(netAmount + taxAmount);

  const lineNoRows = await callSp<{ nextLine: number }>(
    "usp_Rest_OrderTicketLine_NextLineNumber",
    { OrderId: Number(order.orderId) }
  );

  const lineNumber = Number(lineNoRows[0]?.nextLine ?? 1);

  const { output } = await callSpOut(
    "usp_Rest_OrderTicketLine_Insert",
    {
      CompanyId: scope.companyId,
      OrderId: Number(order.orderId),
      LineNumber: lineNumber,
      CountryCode: countryCode,
      ProductId: product?.productId ?? null,
      ProductCode: product?.productCode ?? String(params.productoId ?? ""),
      ProductName: product?.productName ?? params.nombre,
      Quantity: quantity,
      UnitPrice: unitPrice,
      TaxCode: taxProfile.taxCode,
      TaxRate: taxProfile.taxRate,
      NetAmount: netAmount,
      TaxAmount: taxAmount,
      TotalAmount: totalAmount,
      Notes: params.comentarios ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  await recalcOrderTotals(Number(order.orderId));

  return {
    ok: true,
    itemId: Number(output.Resultado ?? 0),
    executionMode: "ts_canonical" as const,
  };
}

export async function cancelarItemPedido(params: {
  pedidoId: number;
  itemId: number;
  motivo?: string;
  supervisorUser: string;
  supervisorPassword: string;
  requestedByUser?: string | null;
  biometricBypass?: boolean;
  biometricCredentialId?: string | null;
}) {
  const scope = await getDefaultScope();
  const orderRows = await callSp<any>(
    "usp_Rest_OrderTicket_GetById",
    { CompanyId: scope.companyId, PedidoId: params.pedidoId }
  );

  const order = orderRows[0];
  if (!order) {
    return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
  }

  const status = String(order.status ?? "").toUpperCase();
  if (status === "CLOSED" || status === "VOIDED") {
    return { ok: false, error: "pedido_not_open", executionMode: "ts_canonical" as const };
  }

  const priorVoidRows = await callSp<{ alreadyVoided: number }>(
    "usp_Rest_OrderTicket_CheckPriorVoid",
    { PedidoId: params.pedidoId, ItemId: params.itemId }
  );

  if (priorVoidRows[0]?.alreadyVoided === 1) {
    return { ok: false, error: "item_already_voided", executionMode: "ts_canonical" as const };
  }

  const itemRows = await callSp<any>(
    "usp_Rest_OrderTicketLine_GetById",
    { PedidoId: params.pedidoId, ItemId: params.itemId }
  );

  const item = itemRows[0];
  if (!item) {
    return { ok: false, error: "item_not_found", executionMode: "ts_canonical" as const };
  }

  const supervisorValidation = await validateSupervisorCredentials({
    supervisorUser: params.supervisorUser,
    supervisorPassword: params.supervisorPassword,
    requestedByUser: params.requestedByUser,
    biometricBypass: params.biometricBypass,
    biometricCredentialId: params.biometricCredentialId,
  });

  if (!supervisorValidation.ok) {
    return {
      ok: false,
      error: supervisorValidation.error,
      message: supervisorValidation.message,
      executionMode: "ts_canonical" as const,
    };
  }

  const reason = String(params.motivo ?? "Cliente no desea el producto").trim() || "Cliente no desea el producto";

  const override = await createSupervisorOverride({
    moduleCode: "RESTAURANTE",
    actionCode: "ORDER_LINE_VOID",
    reason,
    supervisorUser: supervisorValidation.supervisorUser,
    requestedByUser: params.requestedByUser,
    companyId: Number(order.companyId ?? 0) || null,
    branchId: Number(order.branchId ?? 0) || null,
    payload: {
      pedidoId: params.pedidoId,
      itemId: params.itemId,
      itemNombre: item.nombre,
      cantidad: Number(item.cantidad ?? 0),
      netAmount: Number(item.netAmount ?? 0),
      taxAmount: Number(item.taxAmount ?? 0),
      totalAmount: Number(item.totalAmount ?? 0),
    },
  });

  const nextLineRows = await callSp<{ nextLine: number }>(
    "usp_Rest_OrderTicketLine_NextLineNumber",
    { OrderId: params.pedidoId }
  );

  const nextLine = Number(nextLineRows[0]?.nextLine ?? 1);
  const voidNotes = [
    `ANULACION_LINEA_REF:${Number(item.itemId ?? 0)}`,
    `OVERRIDE:${override.overrideId}`,
    `SUP:${supervisorValidation.supervisorUser}`,
    `MOTIVO:${reason}`,
  ].join(" | ").slice(0, 600);

  const { output: reversalOut } = await callSpOut(
    "usp_Rest_OrderTicketLine_Insert",
    {
      CompanyId: scope.companyId,
      OrderId: params.pedidoId,
      LineNumber: nextLine,
      CountryCode: String(item.countryCode ?? "VE"),
      ProductId: item.productId ? Number(item.productId) : null,
      ProductCode: String(item.productCode ?? ""),
      ProductName: `ANULACION ${String(item.nombre ?? "")}`.slice(0, 250),
      Quantity: round2(-Number(item.cantidad ?? 0)),
      UnitPrice: round2(Number(item.unitPrice ?? 0)),
      TaxCode: String(item.taxCode ?? "EXENTO"),
      TaxRate: Number(item.taxRate ?? 0),
      NetAmount: round2(-Number(item.netAmount ?? 0)),
      TaxAmount: round2(-Number(item.taxAmount ?? 0)),
      TotalAmount: round2(-Number(item.totalAmount ?? 0)),
      Notes: voidNotes,
      SupervisorApprovalId: override.overrideId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const reversalLineId = Number(reversalOut.Resultado ?? 0);
  if (!Number.isFinite(reversalLineId) || reversalLineId <= 0) {
    return { ok: false, error: "void_line_not_created", executionMode: "ts_canonical" as const };
  }

  await recalcOrderTotals(params.pedidoId);

  await callSp("usp_Rest_OrderTicket_UpdateTimestamp", { CompanyId: scope.companyId, PedidoId: params.pedidoId });

  const consumed = await consumeSupervisorOverride({
    overrideId: override.overrideId,
    moduleCode: "RESTAURANTE",
    actionCode: "ORDER_LINE_VOID",
    consumedByUser: params.requestedByUser,
    sourceDocumentId: params.pedidoId,
    sourceLineId: Number(item.itemId ?? 0),
    reversalLineId,
  });

  if (!consumed.ok) {
    return { ok: false, error: "override_not_available", executionMode: "ts_canonical" as const };
  }

  return {
    ok: true,
    executionMode: "ts_canonical" as const,
    canceledItem: {
      itemId: Number(item.itemId ?? 0),
      nombre: String(item.nombre ?? ""),
      cantidad: Number(item.cantidad ?? 0),
      motivo: params.motivo ? String(params.motivo) : null,
      reversalLineId,
      supervisorUser: supervisorValidation.supervisorUser,
      overrideId: override.overrideId,
    },
  };
}

export async function enviarComanda(pedidoId: number) {
  const scope = await getDefaultScope();
  await callSpOut(
    "usp_Rest_OrderTicket_SendToKitchen",
    { CompanyId: scope.companyId, PedidoId: pedidoId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "ts_canonical" as const };
}

async function inferCountryCodeFromFiscalConfig(empresaId: number, sucursalId: number): Promise<CountryCode> {
  const rows = await callSp<{ countryCode: string }>(
    "usp_Rest_OrderTicket_InferCountryCode",
    { EmpresaId: empresaId, SucursalId: sucursalId }
  );

  return String(rows[0]?.countryCode ?? "VE").toUpperCase();
}

async function getPedidoHeaderForClose(pedidoId: number) {
  const rows = await callSp<any>(
    "usp_Rest_OrderTicket_GetHeaderForClose",
    { PedidoId: pedidoId }
  );

  return rows[0] ?? null;
}

interface RestaurantFiscalBreakdown {
  lines: Array<{
    itemId: number;
    productoId: string;
    nombre: string;
    quantity: number;
    unitPrice: number;
    baseAmount: number;
    taxCode: string;
    taxRate: number;
    taxAmount: number;
    totalAmount: number;
  }>;
  taxSummary: Array<{
    taxCode: string;
    taxRate: number;
    baseAmount: number;
    taxAmount: number;
    totalAmount: number;
  }>;
  baseAmount: number;
  taxAmount: number;
  totalAmount: number;
  sourceTotal: number;
}

async function buildRestaurantFiscalBreakdown(pedidoId: number, sourceTotal: number): Promise<RestaurantFiscalBreakdown> {
  const rows = await callSp<any>(
    "usp_Rest_OrderTicketLine_GetFiscalBreakdown",
    { PedidoId: pedidoId }
  );

  const lines = rows.map((row: any) => ({
    itemId: Number(row.itemId ?? 0),
    productoId: String(row.productoId ?? ""),
    nombre: String(row.nombre ?? ""),
    quantity: Number(row.quantity ?? 0),
    unitPrice: Number(row.unitPrice ?? 0),
    baseAmount: round2(Number(row.baseAmount ?? 0)),
    taxCode: String(row.taxCode ?? "EXENTO"),
    taxRate: Number(row.taxRate ?? 0),
    taxAmount: round2(Number(row.taxAmount ?? 0)),
    totalAmount: round2(Number(row.totalAmount ?? 0)),
  }));

  const baseAmount = round2(lines.reduce((acc: number, line: any) => acc + line.baseAmount, 0));
  const taxAmount = round2(lines.reduce((acc: number, line: any) => acc + line.taxAmount, 0));
  const totalAmount = round2(lines.reduce((acc: number, line: any) => acc + line.totalAmount, 0));

  const summaryMap = new Map<string, { taxCode: string; taxRate: number; baseAmount: number; taxAmount: number; totalAmount: number }>();
  for (const line of lines) {
    const key = `${line.taxCode}|${line.taxRate.toFixed(4)}`;
    const current = summaryMap.get(key) ?? {
      taxCode: line.taxCode,
      taxRate: line.taxRate,
      baseAmount: 0,
      taxAmount: 0,
      totalAmount: 0,
    };
    current.baseAmount = round2(current.baseAmount + line.baseAmount);
    current.taxAmount = round2(current.taxAmount + line.taxAmount);
    current.totalAmount = round2(current.totalAmount + line.totalAmount);
    summaryMap.set(key, current);
  }

  return {
    lines,
    taxSummary: Array.from(summaryMap.values()),
    baseAmount,
    taxAmount,
    totalAmount,
    sourceTotal: round2(sourceTotal),
  };
}

export async function cerrarPedido(params: {
  pedidoId: number;
  empresaId?: number;
  sucursalId?: number;
  countryCode?: CountryCode;
  codUsuario?: string;
  invoiceNumber?: string;
  invoiceDate?: string;
  invoiceTypeHint?: string;
  fiscalPrinterSerial?: string;
  fiscalControlNumber?: string;
  zReportNumber?: number;
  warehouseId?: number;
}) {
  try {
    const pedidoActual = await getPedidoHeaderForClose(params.pedidoId);
    if (!pedidoActual) {
      return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
    }

    const alreadyClosed = String(pedidoActual.estado ?? "").toUpperCase() === "CLOSED";

    const scope = await getDefaultScope();

    if (!alreadyClosed) {
      const closedByUserId = await resolveUserId(params.codUsuario ?? pedidoActual.codUsuario ?? null);
      await callSpOut(
        "usp_Rest_OrderTicket_Close",
        {
          CompanyId: scope.companyId,
          PedidoId: params.pedidoId,
          ClosedByUserId: closedByUserId,
        },
        { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
      );
    }

    // Best-effort: consume recipe ingredients from warehouse
    try {
      const warehouseId = params.warehouseId ?? null;
      if (warehouseId && !alreadyClosed) {
        // Get order lines to know what was sold
        const orderLines = await callSp("usp_Rest_OrderTicketLine_GetByPedido", {
          CompanyId: scope.companyId,
          PedidoId: params.pedidoId,
        });

        for (const line of (orderLines ?? []) as Record<string, unknown>[]) {
          // For each menu item, consume its recipe ingredients
          const recipes = await callSp("usp_Rest_Recipe_GetIngredients", {
            CompanyId: scope.companyId,
            ProductCode: line.productoId ?? line.ProductCode ?? line.productCode,
          });

          for (const ingredient of (recipes ?? []) as Record<string, unknown>[]) {
            const qty = Number(ingredient.Cantidad ?? ingredient.cantidad ?? 0) * Number(line.cantidad ?? line.Quantity ?? line.quantity ?? 1);
            if (qty > 0) {
              await callSp("usp_Inv_Movement_Create", {
                CompanyId: Number(params.empresaId ?? pedidoActual.empresaId ?? 1),
                BranchId: Number(params.sucursalId ?? pedidoActual.sucursalId ?? 1),
                ProductId: null,
                FromWarehouseId: warehouseId,
                MovementType: "SALE_OUT",
                Quantity: qty,
                UnitCost: 0,
                SourceDocumentType: "RESTAURANTE",
                SourceDocumentNumber: String(params.pedidoId),
                Notes: "Consumo ingredientes restaurante",
                UserId: 1,
              });
            }
          }
        }
      }
    } catch { /* never blocks restaurant operation */ }

    const sourceTotal = Number(pedidoActual.total ?? 0);
    const fiscalBreakdown = await buildRestaurantFiscalBreakdown(params.pedidoId, sourceTotal);

    let baseAmount = Number(fiscalBreakdown.baseAmount ?? 0);
    let taxAmount = Number(fiscalBreakdown.taxAmount ?? 0);
    let totalAmount = Number(fiscalBreakdown.totalAmount ?? 0);

    if (totalAmount <= 0 && sourceTotal > 0) {
      baseAmount = sourceTotal;
      taxAmount = 0;
      totalAmount = sourceTotal;
    }

    const empresaId = Number(params.empresaId ?? pedidoActual.empresaId ?? 1);
    const sucursalId = Number(params.sucursalId ?? pedidoActual.sucursalId ?? 1);
    const countryCode = params.countryCode
      ?? (String(pedidoActual.countryCode ?? "").toUpperCase() === "ES" ? "ES" : null)
      ?? (await inferCountryCodeFromFiscalConfig(empresaId, sucursalId));

    const invoiceNumber = String(params.invoiceNumber ?? "").trim() || `REST-${params.pedidoId}`;

    let fiscal: Awaited<ReturnType<typeof emitFiscalRecordFromTransaction>> | { ok: false; reason: string };
    if (alreadyClosed) {
      fiscal = {
        ok: true,
        skipped: true,
        reason: "pedido_already_closed",
      };
    } else {
      try {
        fiscal = await emitFiscalRecordFromTransaction({
          empresaId,
          sucursalId,
          countryCode,
          sourceModule: "RESTAURANTE",
          invoiceId: Number(params.pedidoId),
          invoiceNumber,
          invoiceDate: params.invoiceDate ? new Date(params.invoiceDate) : new Date(),
          invoiceTypeHint: params.invoiceTypeHint,
          recipientId: pedidoActual.clienteRif ? String(pedidoActual.clienteRif) : undefined,
          totalAmount,
          payload: {
            mesaId: pedidoActual.mesaId,
            clienteNombre: pedidoActual.clienteNombre,
            fiscalBreakdown,
          },
          metadata: {
            fiscalPrinterSerial: params.fiscalPrinterSerial,
            fiscalControlNumber: params.fiscalControlNumber,
            zReportNumber: params.zReportNumber,
            sourceTotal,
            calculatedTotal: totalAmount,
            breakdownSource: "order_lines",
          },
        });
      } catch (fiscalError: any) {
        fiscal = {
          ok: false,
          reason: `fiscal_emit_exception:${String(fiscalError?.message ?? fiscalError)}`,
        };
      }
    }

    let contabilidad: Awaited<ReturnType<typeof emitSaleAccountingEntry>>;
    try {
      contabilidad = await emitSaleAccountingEntry({
        module: "RESTAURANTE",
        sourceId: Number(params.pedidoId),
        documentNumber: invoiceNumber,
        issueDate: params.invoiceDate ? new Date(params.invoiceDate) : new Date(),
        paymentMethod: "CAJA",
        codUsuario: params.codUsuario ?? (pedidoActual.codUsuario ? String(pedidoActual.codUsuario) : undefined),
        currency: await getCountryCurrency(countryCode),
        exchangeRate: 1,
        baseAmount,
        taxAmount,
        totalAmount,
        taxSummary: fiscalBreakdown.taxSummary,
      });
    } catch (accountingError: any) {
      contabilidad = {
        ok: false,
        reason: `accounting_emit_exception:${String(accountingError?.message ?? accountingError)}`,
      };
    }

    return { ok: true, executionMode: "ts_canonical" as const, alreadyClosed, fiscal, contabilidad };
  } catch (e: any) {
    return { ok: false, error: e.message, executionMode: "ts_canonical" as const };
  }
}

export async function contabilizarPedidoExistente(params: {
  pedidoId: number;
  codUsuario?: string;
  countryCode?: CountryCode;
  currency?: string;
  exchangeRate?: number;
  invoiceNumber?: string;
}) {
  return reprocessRestauranteAccounting({
    pedidoId: params.pedidoId,
    codUsuario: params.codUsuario,
    countryCode: params.countryCode,
    currency: params.currency,
    exchangeRate: params.exchangeRate,
    invoiceNumber: params.invoiceNumber,
  });
}

export async function getPedidoByMesa(mesaId: number) {
  const scope = await getDefaultScope();
  const table = await getDiningTableById(scope, mesaId);
  if (!table) {
    return { pedido: null, items: [], executionMode: "ts_canonical" as const };
  }

  const pedidos = await callSp<any>(
    "usp_Rest_OrderTicket_GetByMesaHeader",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      TableNumber: String(table.tableNumber),
    }
  );

  const pedido = pedidos[0] ?? null;
  if (!pedido) {
    return { pedido: null, items: [], executionMode: "ts_canonical" as const };
  }

  const itemsRows = await callSp<any>(
    "usp_Rest_OrderTicketLine_GetByPedido",
    { CompanyId: scope.companyId, PedidoId: Number(pedido.id) }
  );

  const legacyEstado = mapOrderStatusToLegacy(String(pedido.estado ?? ""));
  const items = itemsRows.map((item: any) => ({
    ...item,
    estado: legacyEstado,
    enviadoACocina: legacyEstado === "enviado" || legacyEstado === "cerrado",
  }));

  return {
    pedido: {
      id: Number(pedido.id),
      mesaId,
      clienteNombre: pedido.clienteNombre,
      clienteRif: pedido.clienteRif,
      estado: legacyEstado,
      total: Number(pedido.total ?? 0),
    },
    items,
    executionMode: "ts_canonical" as const,
  };
}
