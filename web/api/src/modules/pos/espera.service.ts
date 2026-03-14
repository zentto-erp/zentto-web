import { query } from "../../db/query.js";
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
      AND (
        ProductCode = @identifier
        OR CAST(ProductId AS NVARCHAR(50)) = @identifier
      )
    ORDER BY ProductId DESC
    `,
    { companyId, identifier }
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
    const rows = await query<any>(
      `
      SELECT TOP 1
        CustomerId AS customerId,
        CustomerCode AS customerCode,
        CustomerName AS customerName,
        FiscalId AS fiscalId
      FROM [master].Customer
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
        AND (
          CustomerCode = @idInput
          OR CAST(CustomerId AS NVARCHAR(50)) = @idInput
        )
      ORDER BY CustomerId DESC
      `,
      { companyId, idInput }
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
    const rows = await query<any>(
      `
      SELECT TOP 1
        CustomerId AS customerId,
        CustomerCode AS customerCode,
        CustomerName AS customerName,
        FiscalId AS fiscalId
      FROM [master].Customer
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
        AND FiscalId = @rif
      ORDER BY CustomerId DESC
      `,
      { companyId, rif }
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

  const insertHeader = await query<{ waitTicketId: number }>(
    `
    INSERT INTO pos.WaitTicket (
      CompanyId,
      BranchId,
      CountryCode,
      CashRegisterCode,
      StationName,
      CreatedByUserId,
      CustomerId,
      CustomerCode,
      CustomerName,
      CustomerFiscalId,
      PriceTier,
      Reason,
      NetAmount,
      DiscountAmount,
      TaxAmount,
      TotalAmount,
      Status,
      CreatedAt,
      UpdatedAt
    )
    OUTPUT INSERTED.WaitTicketId AS waitTicketId
    VALUES (
      @companyId,
      @branchId,
      @countryCode,
      @cashRegisterCode,
      @stationName,
      @createdByUserId,
      @customerId,
      @customerCode,
      @customerName,
      @customerFiscalId,
      @priceTier,
      @reason,
      @netAmount,
      @discountAmount,
      @taxAmount,
      @totalAmount,
      N'WAITING',
      SYSUTCDATETIME(),
      SYSUTCDATETIME()
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      countryCode: scope.countryCode,
      cashRegisterCode: normalizeCashRegister(data.cajaId),
      stationName: data.estacionNombre ?? null,
      createdByUserId,
      customerId: customer.customerId,
      customerCode: customer.customerCode,
      customerName: customer.customerName,
      customerFiscalId: customer.fiscalId,
      priceTier: data.tipoPrecio ?? "Detal",
      reason: data.motivo ?? null,
      netAmount,
      discountAmount,
      taxAmount,
      totalAmount,
    }
  );

  const waitTicketId = Number(insertHeader[0]?.waitTicketId ?? 0);
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

    await query(
      `
      INSERT INTO pos.WaitTicketLine (
        WaitTicketId,
        LineNumber,
        CountryCode,
        ProductId,
        ProductCode,
        ProductName,
        Quantity,
        UnitPrice,
        DiscountAmount,
        TaxCode,
        TaxRate,
        NetAmount,
        TaxAmount,
        TotalAmount,
        SupervisorApprovalId,
        LineMetaJson,
        CreatedAt
      )
      VALUES (
        @waitTicketId,
        @lineNumber,
        @countryCode,
        @productId,
        @productCode,
        @productName,
        @quantity,
        @unitPrice,
        @discountAmount,
        @taxCode,
        @taxRate,
        @netAmount,
        @taxAmount,
        @totalAmount,
        @supervisorApprovalId,
        @lineMetaJson,
        SYSUTCDATETIME()
      )
      `,
      {
        waitTicketId,
        lineNumber: line.lineNumber,
        countryCode: scope.countryCode,
        productId: line.productId,
        productCode: line.productCode,
        productName: line.productName,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        discountAmount: line.discountAmount,
        taxCode: line.taxCode,
        taxRate: line.taxRate,
        netAmount: line.netAmount,
        taxAmount: line.taxAmount,
        totalAmount: line.totalAmount,
        supervisorApprovalId: line.supervisorApprovalId,
        lineMetaJson,
      }
    );
  }

  return { ok: true, esperaId: waitTicketId };
}

export async function listEspera() {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT
      WaitTicketId AS id,
      CashRegisterCode AS cajaId,
      StationName AS estacionNombre,
      CustomerName AS clienteNombre,
      Reason AS motivo,
      TotalAmount AS total,
      CreatedAt AS fechaCreacion
    FROM pos.WaitTicket
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND Status = N'WAITING'
    ORDER BY CreatedAt
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
    }
  );

  return { rows };
}

export async function recuperarEspera(id: number, recuperadoPor?: string, recuperadoEn?: string) {
  const scope = await getDefaultScope();
  const recoveredByUserId = await resolveUserId(recuperadoPor);

  const headerRows = await query<any>(
    `
    SELECT TOP 1
      WaitTicketId AS id,
      CashRegisterCode AS cajaId,
      StationName AS estacionNombre,
      CustomerCode AS clienteId,
      CustomerName AS clienteNombre,
      CustomerFiscalId AS clienteRif,
      PriceTier AS tipoPrecio,
      Reason AS motivo,
      NetAmount AS subtotal,
      TaxAmount AS impuestos,
      TotalAmount AS total,
      Status AS estado,
      CreatedAt AS fechaCreacion
    FROM pos.WaitTicket
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND WaitTicketId = @waitTicketId
    ORDER BY WaitTicketId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      waitTicketId: id,
    }
  );

  const header = headerRows[0];
  if (!header) return { ok: false, error: "not_found" };

  if (String(header.estado ?? "").toUpperCase() === "WAITING") {
    await query(
      `
      UPDATE pos.WaitTicket
      SET Status = N'RECOVERED',
          RecoveredByUserId = @recoveredByUserId,
          RecoveredAtRegister = @recoveredAtRegister,
          RecoveredAt = SYSUTCDATETIME(),
          UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND WaitTicketId = @waitTicketId
      `,
      {
        companyId: scope.companyId,
        branchId: scope.branchId,
        waitTicketId: id,
        recoveredByUserId,
        recoveredAtRegister: normalizeCashRegister(recuperadoEn),
      }
    );
  }

  const items = await query<any>(
    `
    SELECT
      WaitTicketLineId AS id,
      ISNULL(CAST(ProductId AS NVARCHAR(50)), ProductCode) AS productoId,
      ProductCode AS codigo,
      ProductName AS nombre,
      Quantity AS cantidad,
      UnitPrice AS precioUnitario,
      DiscountAmount AS descuento,
      CASE WHEN TaxRate > 1 THEN TaxRate ELSE TaxRate * 100 END AS iva,
      NetAmount AS subtotal,
      TotalAmount AS total,
      SupervisorApprovalId AS supervisorApprovalId,
      LineMetaJson AS lineMetaJson
    FROM pos.WaitTicketLine
    WHERE WaitTicketId = @waitTicketId
    ORDER BY LineNumber
    `,
    { waitTicketId: id }
  );

  return {
    ok: true,
    header,
    items,
  };
}

export async function anularEspera(id: number) {
  const scope = await getDefaultScope();
  await query(
    `
    UPDATE pos.WaitTicket
    SET Status = N'VOIDED',
        UpdatedAt = SYSUTCDATETIME()
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND WaitTicketId = @waitTicketId
      AND Status = N'WAITING'
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      waitTicketId: id,
    }
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

  const inserted = await query<{ saleTicketId: number }>(
    `
    INSERT INTO pos.SaleTicket (
      CompanyId,
      BranchId,
      CountryCode,
      InvoiceNumber,
      CashRegisterCode,
      SoldByUserId,
      CustomerId,
      CustomerCode,
      CustomerName,
      CustomerFiscalId,
      PriceTier,
      PaymentMethod,
      FiscalPayload,
      WaitTicketId,
      NetAmount,
      DiscountAmount,
      TaxAmount,
      TotalAmount,
      SoldAt
    )
    OUTPUT INSERTED.SaleTicketId AS saleTicketId
    VALUES (
      @companyId,
      @branchId,
      @countryCode,
      @invoiceNumber,
      @cashRegisterCode,
      @soldByUserId,
      @customerId,
      @customerCode,
      @customerName,
      @customerFiscalId,
      @priceTier,
      @paymentMethod,
      @fiscalPayload,
      @waitTicketId,
      @netAmount,
      @discountAmount,
      @taxAmount,
      @totalAmount,
      SYSUTCDATETIME()
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      countryCode: scope.countryCode,
      invoiceNumber: data.numFactura,
      cashRegisterCode: normalizeCashRegister(data.cajaId),
      soldByUserId,
      customerId: customer.customerId,
      customerCode: customer.customerCode,
      customerName: customer.customerName,
      customerFiscalId: customer.fiscalId,
      priceTier: data.tipoPrecio ?? "Detal",
      paymentMethod: data.metodoPago ?? null,
      fiscalPayload: data.tramaFiscal ?? null,
      waitTicketId: data.esperaOrigenId ?? null,
      netAmount,
      discountAmount,
      taxAmount,
      totalAmount,
    }
  );

  const ventaId = Number(inserted[0]?.saleTicketId ?? 0);
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

    const insertedLine = await query<{ saleTicketLineId: number }>(
      `
      INSERT INTO pos.SaleTicketLine (
        SaleTicketId,
        LineNumber,
        CountryCode,
        ProductId,
        ProductCode,
        ProductName,
        Quantity,
        UnitPrice,
        DiscountAmount,
        TaxCode,
        TaxRate,
        NetAmount,
        TaxAmount,
        TotalAmount,
        SupervisorApprovalId,
        LineMetaJson
      )
      OUTPUT INSERTED.SaleTicketLineId AS saleTicketLineId
      VALUES (
        @saleTicketId,
        @lineNumber,
        @countryCode,
        @productId,
        @productCode,
        @productName,
        @quantity,
        @unitPrice,
        @discountAmount,
        @taxCode,
        @taxRate,
        @netAmount,
        @taxAmount,
        @totalAmount,
        @supervisorApprovalId,
        @lineMetaJson
      )
      `,
      {
        saleTicketId: ventaId,
        lineNumber: line.lineNumber,
        countryCode: scope.countryCode,
        productId: line.productId,
        productCode: line.productCode,
        productName: line.productName,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        discountAmount: line.discountAmount,
        taxCode: line.taxCode,
        taxRate: line.taxRate,
        netAmount: line.netAmount,
        taxAmount: line.taxAmount,
        totalAmount: line.totalAmount,
        supervisorApprovalId: line.supervisorApprovalId,
        lineMetaJson,
      }
    );

    if (line.isVoid && line.supervisorApprovalId) {
      const saleTicketLineId = Number(insertedLine[0]?.saleTicketLineId ?? 0);
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
    await query(
      `
      UPDATE pos.WaitTicket
      SET Status = N'RECOVERED',
          RecoveredByUserId = @recoveredByUserId,
          RecoveredAtRegister = @recoveredAtRegister,
          RecoveredAt = SYSUTCDATETIME(),
          UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND WaitTicketId = @waitTicketId
      `,
      {
        companyId: scope.companyId,
        branchId: scope.branchId,
        waitTicketId: Number(data.esperaOrigenId),
        recoveredByUserId: soldByUserId,
        recoveredAtRegister: normalizeCashRegister(data.cajaId),
      }
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
