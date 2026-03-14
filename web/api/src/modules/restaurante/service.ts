import { query } from "../../db/query.js";
import { emitFiscalRecordFromTransaction } from "../fiscal/service.js";
import { CountryCode } from "../fiscal/types.js";
import { emitSaleAccountingEntry, reprocessRestauranteAccounting } from "../contabilidad/integracion.service.js";
import { getActiveScope } from "../_shared/scope.js";
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
      countryCode: (activeScope.countryCode ?? defaultScopeCache.countryCode) as CountryCode,
    };
  }
  if (defaultScopeCache) return defaultScopeCache;

  const rows = await query<{ companyId: number; branchId: number; countryCode: string }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId,
      UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId
    WHERE c.CompanyCode = N'DEFAULT'
      AND b.BranchCode = N'MAIN'
    ORDER BY c.CompanyId, b.BranchId
    `
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

async function resolveUserId(userCode?: string | null) {
  const normalized = String(userCode ?? "").trim();
  if (!normalized) return null;

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@userCode)
      AND IsDeleted = 0
      AND IsActive = 1
    `,
    { userCode: normalized }
  );

  const userId = Number(rows[0]?.userId ?? 0);
  return Number.isFinite(userId) && userId > 0 ? userId : null;
}

async function loadCountryTaxRates(countryCode: CountryCode) {
  const cached = taxRateCache.get(countryCode);
  if (cached) return cached;

  const rows = await query<{ taxCode: string; rate: number; isDefault: boolean }>(
    `
    SELECT
      TaxCode AS taxCode,
      Rate AS rate,
      IsDefault AS isDefault
    FROM fiscal.TaxRate
    WHERE CountryCode = @countryCode
      AND IsActive = 1
    ORDER BY IsDefault DESC, SortOrder, TaxCode
    `,
    { countryCode }
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

  const rows = await query<any>(
    `
    SELECT TOP 1
      ProductId AS productId,
      ProductCode AS productCode,
      ProductName AS productName,
      DefaultTaxCode AS defaultTaxCode,
      DefaultTaxRate AS defaultTaxRate
    FROM [master].Product
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
        ProductCode = @identifier
        OR CAST(ProductId AS NVARCHAR(50)) = @identifier
      )
    ORDER BY ProductId DESC
    `,
    { companyId, identifier: normalized }
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
  const rows = await query<any>(
    `
    SELECT TOP 1
      DiningTableId AS id,
      TableNumber AS tableNumber,
      TableName AS tableName,
      Capacity AS capacity,
      EnvironmentCode AS ambienteId,
      EnvironmentName AS ambiente,
      PositionX AS posicionX,
      PositionY AS posicionY
    FROM rest.DiningTable
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND DiningTableId = @mesaId
      AND IsActive = 1
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      mesaId,
    }
  );

  return rows[0] ?? null;
}

async function getOpenOrderByTable(scope: DefaultScope, tableNumber: string) {
  const rows = await query<any>(
    `
    SELECT TOP 1
      OrderTicketId AS id,
      Status AS status
    FROM rest.OrderTicket
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND TableNumber = @tableNumber
      AND Status IN (N'OPEN', N'SENT')
    ORDER BY OrderTicketId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      tableNumber,
    }
  );

  return rows[0] ?? null;
}

async function recalcOrderTotals(orderId: number) {
  const rows = await query<{ netAmount: number; taxAmount: number; totalAmount: number }>(
    `
    SELECT
      ISNULL(SUM(NetAmount), 0) AS netAmount,
      ISNULL(SUM(TaxAmount), 0) AS taxAmount,
      ISNULL(SUM(TotalAmount), 0) AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @orderId
    `,
    { orderId }
  );

  const totals = rows[0] ?? { netAmount: 0, taxAmount: 0, totalAmount: 0 };

  await query(
    `
    UPDATE rest.OrderTicket
    SET NetAmount = @netAmount,
        TaxAmount = @taxAmount,
        TotalAmount = @totalAmount,
        UpdatedAt = SYSUTCDATETIME()
    WHERE OrderTicketId = @orderId
    `,
    {
      orderId,
      netAmount: round2(Number(totals.netAmount ?? 0)),
      taxAmount: round2(Number(totals.taxAmount ?? 0)),
      totalAmount: round2(Number(totals.totalAmount ?? 0)),
    }
  );
}

// Mesas
export async function listMesas(ambienteId?: string) {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT
      dt.DiningTableId AS id,
      dt.TableNumber AS numero,
      ISNULL(NULLIF(dt.TableName, N''), N'Mesa ' + dt.TableNumber) AS nombre,
      dt.Capacity AS capacidad,
      dt.EnvironmentCode AS ambienteId,
      dt.EnvironmentName AS ambiente,
      dt.PositionX AS posicionX,
      dt.PositionY AS posicionY,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM rest.OrderTicket o
          WHERE o.CompanyId = dt.CompanyId
            AND o.BranchId = dt.BranchId
            AND o.TableNumber = dt.TableNumber
            AND o.Status IN (N'OPEN', N'SENT')
        ) THEN N'ocupada'
        ELSE N'libre'
      END AS estado
    FROM rest.DiningTable dt
    WHERE dt.CompanyId = @companyId
      AND dt.BranchId = @branchId
      AND dt.IsActive = 1
      AND (@ambienteId IS NULL OR dt.EnvironmentCode = @ambienteId)
    ORDER BY dt.EnvironmentCode, TRY_CONVERT(INT, dt.TableNumber), dt.TableNumber
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      ambienteId: ambienteId ?? null,
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

  const insert = await query<{ orderTicketId: number }>(
    `
    INSERT INTO rest.OrderTicket (
      CompanyId,
      BranchId,
      CountryCode,
      TableNumber,
      OpenedByUserId,
      CustomerName,
      CustomerFiscalId,
      Status,
      NetAmount,
      TaxAmount,
      TotalAmount,
      OpenedAt
    )
    OUTPUT INSERTED.OrderTicketId AS orderTicketId
    VALUES (
      @companyId,
      @branchId,
      @countryCode,
      @tableNumber,
      @openedByUserId,
      @customerName,
      @customerFiscalId,
      N'OPEN',
      0,
      0,
      0,
      SYSUTCDATETIME()
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      countryCode: scope.countryCode,
      tableNumber: String(table.tableNumber),
      openedByUserId,
      customerName: clienteNombre ?? null,
      customerFiscalId: clienteRif ?? null,
    }
  );

  const pedidoId = Number(insert[0]?.orderTicketId ?? 0);
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
  const orderRows = await query<any>(
    `
    SELECT TOP 1
      OrderTicketId AS orderId,
      CompanyId AS companyId,
      BranchId AS branchId,
      CountryCode AS countryCode,
      Status AS status
    FROM rest.OrderTicket
    WHERE OrderTicketId = @pedidoId
    `,
    { pedidoId: params.pedidoId }
  );

  const order = orderRows[0];
  if (!order) {
    return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
  }

  const status = String(order.status ?? "").toUpperCase();
  if (status === "CLOSED" || status === "VOIDED") {
    return { ok: false, error: "pedido_not_open", executionMode: "ts_canonical" as const };
  }

  const countryCode: CountryCode = String(order.countryCode ?? "VE").toUpperCase() === "ES" ? "ES" : "VE";
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

  const lineNoRows = await query<{ nextLine: number }>(
    `
    SELECT ISNULL(MAX(LineNumber), 0) + 1 AS nextLine
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @orderId
    `,
    { orderId: Number(order.orderId) }
  );

  const lineNumber = Number(lineNoRows[0]?.nextLine ?? 1);

  const inserted = await query<{ lineId: number }>(
    `
    INSERT INTO rest.OrderTicketLine (
      OrderTicketId,
      LineNumber,
      CountryCode,
      ProductId,
      ProductCode,
      ProductName,
      Quantity,
      UnitPrice,
      TaxCode,
      TaxRate,
      NetAmount,
      TaxAmount,
      TotalAmount,
      Notes
    )
    OUTPUT INSERTED.OrderTicketLineId AS lineId
    VALUES (
      @orderId,
      @lineNumber,
      @countryCode,
      @productId,
      @productCode,
      @productName,
      @quantity,
      @unitPrice,
      @taxCode,
      @taxRate,
      @netAmount,
      @taxAmount,
      @totalAmount,
      @notes
    )
    `,
    {
      orderId: Number(order.orderId),
      lineNumber,
      countryCode,
      productId: product?.productId ?? null,
      productCode: product?.productCode ?? String(params.productoId ?? ""),
      productName: product?.productName ?? params.nombre,
      quantity,
      unitPrice,
      taxCode: taxProfile.taxCode,
      taxRate: taxProfile.taxRate,
      netAmount,
      taxAmount,
      totalAmount,
      notes: params.comentarios ?? null,
    }
  );

  await recalcOrderTotals(Number(order.orderId));

  return {
    ok: true,
    itemId: Number(inserted[0]?.lineId ?? 0),
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
  const orderRows = await query<any>(
    `
    SELECT TOP 1
      OrderTicketId AS orderId,
      CompanyId AS companyId,
      BranchId AS branchId,
      Status AS status
    FROM rest.OrderTicket
    WHERE OrderTicketId = @pedidoId
    `,
    { pedidoId: params.pedidoId }
  );

  const order = orderRows[0];
  if (!order) {
    return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
  }

  const status = String(order.status ?? "").toUpperCase();
  if (status === "CLOSED" || status === "VOIDED") {
    return { ok: false, error: "pedido_not_open", executionMode: "ts_canonical" as const };
  }

  const priorVoidRows = await query<{ alreadyVoided: number }>(
    `
    SELECT TOP 1 1 AS alreadyVoided
    FROM sec.SupervisorOverride
    WHERE ModuleCode = N'RESTAURANTE'
      AND ActionCode = N'ORDER_LINE_VOID'
      AND Status = N'CONSUMED'
      AND SourceDocumentId = @pedidoId
      AND SourceLineId = @itemId
    `,
    { pedidoId: params.pedidoId, itemId: params.itemId }
  );

  if (priorVoidRows[0]?.alreadyVoided === 1) {
    return { ok: false, error: "item_already_voided", executionMode: "ts_canonical" as const };
  }

  const itemRows = await query<any>(
    `
    SELECT TOP 1
      OrderTicketLineId AS itemId,
      LineNumber AS lineNumber,
      CountryCode AS countryCode,
      ProductId AS productId,
      ProductCode AS productCode,
      ProductName AS nombre,
      Quantity AS cantidad,
      UnitPrice AS unitPrice,
      TaxCode AS taxCode,
      TaxRate AS taxRate,
      NetAmount AS netAmount,
      TaxAmount AS taxAmount,
      TotalAmount AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @pedidoId
      AND OrderTicketLineId = @itemId
    `,
    {
      pedidoId: params.pedidoId,
      itemId: params.itemId,
    }
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

  const nextLineRows = await query<{ nextLine: number }>(
    `
    SELECT ISNULL(MAX(LineNumber), 0) + 1 AS nextLine
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @pedidoId
    `,
    { pedidoId: params.pedidoId }
  );

  const nextLine = Number(nextLineRows[0]?.nextLine ?? 1);
  const voidNotes = [
    `ANULACION_LINEA_REF:${Number(item.itemId ?? 0)}`,
    `OVERRIDE:${override.overrideId}`,
    `SUP:${supervisorValidation.supervisorUser}`,
    `MOTIVO:${reason}`,
  ].join(" | ").slice(0, 600);

  const reversalRows = await query<{ reversalLineId: number }>(
    `
    INSERT INTO rest.OrderTicketLine (
      OrderTicketId,
      LineNumber,
      CountryCode,
      ProductId,
      ProductCode,
      ProductName,
      Quantity,
      UnitPrice,
      TaxCode,
      TaxRate,
      NetAmount,
      TaxAmount,
      TotalAmount,
      Notes,
      SupervisorApprovalId,
      CreatedAt,
      UpdatedAt
    )
    OUTPUT INSERTED.OrderTicketLineId AS reversalLineId
    VALUES (
      @pedidoId,
      @lineNumber,
      @countryCode,
      @productId,
      @productCode,
      @productName,
      @quantity,
      @unitPrice,
      @taxCode,
      @taxRate,
      @netAmount,
      @taxAmount,
      @totalAmount,
      @notes,
      @supervisorApprovalId,
      SYSUTCDATETIME(),
      SYSUTCDATETIME()
    )
    `,
    {
      pedidoId: params.pedidoId,
      lineNumber: nextLine,
      countryCode: String(item.countryCode ?? "VE"),
      productId: item.productId ? Number(item.productId) : null,
      productCode: String(item.productCode ?? ""),
      productName: `ANULACION ${String(item.nombre ?? "")}`.slice(0, 250),
      quantity: round2(-Number(item.cantidad ?? 0)),
      unitPrice: round2(Number(item.unitPrice ?? 0)),
      taxCode: String(item.taxCode ?? "EXENTO"),
      taxRate: Number(item.taxRate ?? 0),
      netAmount: round2(-Number(item.netAmount ?? 0)),
      taxAmount: round2(-Number(item.taxAmount ?? 0)),
      totalAmount: round2(-Number(item.totalAmount ?? 0)),
      notes: voidNotes,
      supervisorApprovalId: override.overrideId,
    }
  );

  const reversalLineId = Number(reversalRows[0]?.reversalLineId ?? 0);
  if (!Number.isFinite(reversalLineId) || reversalLineId <= 0) {
    return { ok: false, error: "void_line_not_created", executionMode: "ts_canonical" as const };
  }

  await recalcOrderTotals(params.pedidoId);

  await query(
    `
    UPDATE rest.OrderTicket
    SET UpdatedAt = SYSUTCDATETIME()
    WHERE OrderTicketId = @pedidoId
    `,
    { pedidoId: params.pedidoId }
  );

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
  await query(
    `
    UPDATE rest.OrderTicket
    SET Status = CASE WHEN Status = N'OPEN' THEN N'SENT' ELSE Status END,
        UpdatedAt = SYSUTCDATETIME()
    WHERE OrderTicketId = @pedidoId
    `,
    { pedidoId }
  );

  return { ok: true, executionMode: "ts_canonical" as const };
}

async function inferCountryCodeFromFiscalConfig(empresaId: number, sucursalId: number): Promise<CountryCode> {
  const rows = await query<{ countryCode: string }>(
    `
    SELECT TOP 1 CountryCode AS countryCode
    FROM fiscal.CountryConfig
    WHERE CompanyId = @empresaId
      AND BranchId = @sucursalId
      AND IsActive = 1
    ORDER BY UpdatedAt DESC, CountryConfigId DESC
    `,
    { empresaId, sucursalId }
  );

  return String(rows[0]?.countryCode ?? "VE").toUpperCase() === "ES" ? "ES" : "VE";
}

async function getPedidoHeaderForClose(pedidoId: number) {
  const rows = await query<any>(
    `
    SELECT TOP 1
      o.OrderTicketId AS id,
      o.CompanyId AS empresaId,
      o.BranchId AS sucursalId,
      o.CountryCode AS countryCode,
      dt.DiningTableId AS mesaId,
      o.CustomerName AS clienteNombre,
      o.CustomerFiscalId AS clienteRif,
      o.Status AS estado,
      o.TotalAmount AS total,
      o.ClosedAt AS fechaCierre,
      COALESCE(uClose.UserCode, uOpen.UserCode) AS codUsuario
    FROM rest.OrderTicket o
    LEFT JOIN rest.DiningTable dt
      ON dt.CompanyId = o.CompanyId
     AND dt.BranchId = o.BranchId
     AND dt.TableNumber = o.TableNumber
    LEFT JOIN sec.[User] uOpen ON uOpen.UserId = o.OpenedByUserId
    LEFT JOIN sec.[User] uClose ON uClose.UserId = o.ClosedByUserId
    WHERE o.OrderTicketId = @pedidoId
    ORDER BY o.OrderTicketId DESC
    `,
    { pedidoId }
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
  const rows = await query<any>(
    `
    SELECT
      OrderTicketLineId AS itemId,
      ProductCode AS productoId,
      ProductName AS nombre,
      Quantity AS quantity,
      UnitPrice AS unitPrice,
      NetAmount AS baseAmount,
      TaxCode AS taxCode,
      TaxRate AS taxRate,
      TaxAmount AS taxAmount,
      TotalAmount AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @pedidoId
    ORDER BY LineNumber
    `,
    { pedidoId }
  );

  const lines = rows.map((row) => ({
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

  const baseAmount = round2(lines.reduce((acc, line) => acc + line.baseAmount, 0));
  const taxAmount = round2(lines.reduce((acc, line) => acc + line.taxAmount, 0));
  const totalAmount = round2(lines.reduce((acc, line) => acc + line.totalAmount, 0));

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
}) {
  try {
    const pedidoActual = await getPedidoHeaderForClose(params.pedidoId);
    if (!pedidoActual) {
      return { ok: false, error: "pedido_not_found", executionMode: "ts_canonical" as const };
    }

    const alreadyClosed = String(pedidoActual.estado ?? "").toUpperCase() === "CLOSED";

    if (!alreadyClosed) {
      const closedByUserId = await resolveUserId(params.codUsuario ?? pedidoActual.codUsuario ?? null);
      await query(
        `
        UPDATE rest.OrderTicket
        SET Status = N'CLOSED',
            ClosedByUserId = @closedByUserId,
            ClosedAt = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
        WHERE OrderTicketId = @pedidoId
        `,
        {
          pedidoId: params.pedidoId,
          closedByUserId,
        }
      );
    }

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
        currency: countryCode === "ES" ? "EUR" : "VES",
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

  const pedidos = await query<any>(
    `
    SELECT TOP 1
      OrderTicketId AS id,
      CustomerName AS clienteNombre,
      CustomerFiscalId AS clienteRif,
      Status AS estado,
      TotalAmount AS total
    FROM rest.OrderTicket
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND TableNumber = @tableNumber
      AND Status IN (N'OPEN', N'SENT')
    ORDER BY OrderTicketId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      tableNumber: String(table.tableNumber),
    }
  );

  const pedido = pedidos[0] ?? null;
  if (!pedido) {
    return { pedido: null, items: [], executionMode: "ts_canonical" as const };
  }

  const itemsRows = await query<any>(
    `
    SELECT
      OrderTicketLineId AS id,
      ProductCode AS productoId,
      ProductName AS nombre,
      Quantity AS cantidad,
      UnitPrice AS precioUnitario,
      NetAmount AS subtotal,
      CASE WHEN TaxRate > 1 THEN TaxRate ELSE TaxRate * 100 END AS iva,
      TaxCode AS taxCode,
      TaxAmount AS impuesto,
      TotalAmount AS total
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @pedidoId
    ORDER BY LineNumber
    `,
    { pedidoId: Number(pedido.id) }
  );

  const legacyEstado = mapOrderStatusToLegacy(String(pedido.estado ?? ""));
  const items = itemsRows.map((item) => ({
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
