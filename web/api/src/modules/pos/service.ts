import { query } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

interface DefaultScope {
  companyId: number;
  branchId: number;
  countryCode: "VE" | "ES";
}

let defaultScopeCache: DefaultScope | null = null;

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (defaultScopeCache && activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
      countryCode: (activeScope.countryCode ?? defaultScopeCache.countryCode) as "VE" | "ES",
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
      countryCode: (activeScope.countryCode ?? defaultScopeCache.countryCode) as "VE" | "ES",
    };
  }
  return defaultScopeCache;
}

function normalizeRate(value: unknown) {
  const numeric = Number(value ?? 0);
  if (!Number.isFinite(numeric) || numeric < 0) return 0;
  if (numeric > 1) return numeric / 100;
  return numeric;
}

function toPercent(value: unknown) {
  return normalizeRate(value) * 100;
}

function normalizeRange(from?: string, to?: string) {
  const today = new Date();
  const todayIso = today.toISOString().slice(0, 10);
  const fromDate = from && from.trim().length > 0 ? from : todayIso;
  const toDate = to && to.trim().length > 0 ? to : todayIso;
  return { fromDate, toDate };
}

function normalizeCashRegister(code?: string | null) {
  const value = String(code ?? "").trim().toUpperCase();
  return value || null;
}

export async function listProductosPOS(params: {
  search?: string;
  categoria?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(params.page ?? 1, 1);
  const limit = Math.min(Math.max(params.limit ?? 50, 1), 200);
  const offset = (page - 1) * limit;

  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    branchId: scope.branchId,
    offset,
    limit,
  };

  const where: string[] = [
    "CompanyId = @companyId",
    "IsDeleted = 0",
    "IsActive = 1",
    "(StockQty > 0 OR IsService = 1)",
  ];

  if (params.search?.trim()) {
    where.push("(ProductCode LIKE @search OR ProductName LIKE @search)");
    sqlParams.search = `%${params.search.trim()}%`;
  }

  if (params.categoria?.trim()) {
    where.push("CategoryCode = @categoria");
    sqlParams.categoria = params.categoria.trim();
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `
    SELECT
      ProductId AS id,
      ProductCode AS codigo,
      ProductName AS nombre,
      img.PublicUrl AS imagen,
      SalesPrice AS precioDetal,
      StockQty AS existencia,
      CategoryCode AS categoria,
      CASE
        WHEN DefaultTaxRate > 1 THEN DefaultTaxRate
        ELSE DefaultTaxRate * 100
      END AS iva
    FROM [master].Product p
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = p.CompanyId
        AND ei.BranchId = @branchId
        AND ei.EntityType = N'MASTER_PRODUCT'
        AND ei.EntityId = p.ProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    ${clause}
    ORDER BY ProductCode
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM [master].Product
    ${clause}
    `,
    sqlParams
  );

  return {
    page,
    limit,
    total: Number(totalRows[0]?.total ?? 0),
    rows,
    executionMode: "ts_canonical" as const,
  };
}

export async function getProductoByCodigo(codigo: string) {
  const scope = await getDefaultScope();
  const value = String(codigo ?? "").trim();
  const rows = await query<any>(
    `
    SELECT TOP 1
      ProductId AS id,
      ProductCode AS codigo,
      ProductName AS nombre,
      img.PublicUrl AS imagen,
      SalesPrice AS precioDetal,
      StockQty AS existencia,
      CategoryCode AS categoria,
      CASE
        WHEN DefaultTaxRate > 1 THEN DefaultTaxRate
        ELSE DefaultTaxRate * 100
      END AS iva
    FROM [master].Product p
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = p.CompanyId
        AND ei.BranchId = @branchId
        AND ei.EntityType = N'MASTER_PRODUCT'
        AND ei.EntityId = p.ProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
        ProductCode = @codigo
        OR CAST(ProductId AS NVARCHAR(40)) = @codigo
      )
    ORDER BY ProductId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      codigo: value,
    }
  );

  return { row: rows[0] ?? null, executionMode: "ts_canonical" as const };
}

export async function searchClientesPOS(search?: string, limit = 20) {
  const scope = await getDefaultScope();
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 200);

  const params: Record<string, unknown> = {
    companyId: scope.companyId,
    limit: safeLimit,
  };

  let where = "WHERE CompanyId = @companyId AND IsDeleted = 0 AND IsActive = 1";
  if (search?.trim()) {
    params.search = `%${search.trim()}%`;
    where += " AND (CustomerCode LIKE @search OR CustomerName LIKE @search OR FiscalId LIKE @search)";
  }

  const rows = await query<any>(
    `
    SELECT TOP (@limit)
      CustomerId AS id,
      CustomerCode AS codigo,
      CustomerName AS nombre,
      FiscalId AS rif,
      Phone AS telefono,
      Email AS email,
      AddressLine AS direccion,
      N'Detal' AS tipoPrecio,
      CreditLimit AS credito
    FROM [master].Customer
    ${where}
    ORDER BY CustomerName
    `,
    params
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function listCategoriasPOS() {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT
      ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)') AS id,
      ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)') AS nombre,
      COUNT(1) AS productCount
    FROM [master].Product
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (StockQty > 0 OR IsService = 1)
    GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)')
    ORDER BY nombre
    `,
    { companyId: scope.companyId }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function listCorrelativosFiscales(params: { cajaId?: string }) {
  const scope = await getDefaultScope();
  const caja = normalizeCashRegister(params.cajaId);

  const rows = await query<any>(
    `
    SELECT
      CASE
        WHEN fc.CashRegisterCode = N'GLOBAL' THEN fc.CorrelativeType
        ELSE fc.CorrelativeType + N'|CAJA:' + fc.CashRegisterCode
      END AS tipo,
      CASE WHEN fc.CashRegisterCode = N'GLOBAL' THEN NULL ELSE fc.CashRegisterCode END AS cajaId,
      fc.SerialFiscal AS serialFiscal,
      fc.CurrentNumber AS correlativoActual,
      fc.Description AS descripcion
    FROM pos.FiscalCorrelative fc
    WHERE fc.CompanyId = @companyId
      AND fc.BranchId = @branchId
      AND fc.IsActive = 1
      AND (@cajaId IS NULL OR fc.CashRegisterCode IN (N'GLOBAL', @cajaId))
    ORDER BY
      CASE WHEN fc.CashRegisterCode = N'GLOBAL' THEN 0 ELSE 1 END,
      fc.CashRegisterCode,
      fc.CorrelativeType
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      cajaId: caja,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function upsertCorrelativoFiscal(params: {
  cajaId?: string;
  serialFiscal: string;
  correlativoActual?: number;
  descripcion?: string;
}) {
  const scope = await getDefaultScope();
  const cajaId = normalizeCashRegister(params.cajaId) ?? "GLOBAL";
  const serialFiscal = String(params.serialFiscal ?? "").trim();
  const correlativoActual = Number.isFinite(Number(params.correlativoActual)) ? Number(params.correlativoActual) : 0;

  await query(
    `
    IF EXISTS (
      SELECT 1
      FROM pos.FiscalCorrelative
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND CorrelativeType = N'FACTURA'
        AND CashRegisterCode = @cajaId
    )
    BEGIN
      UPDATE pos.FiscalCorrelative
      SET SerialFiscal = @serialFiscal,
          CurrentNumber = @correlativoActual,
          Description = @descripcion,
          UpdatedAt = SYSUTCDATETIME(),
          IsActive = 1
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND CorrelativeType = N'FACTURA'
        AND CashRegisterCode = @cajaId;
    END
    ELSE
    BEGIN
      INSERT INTO pos.FiscalCorrelative (
        CompanyId,
        BranchId,
        CorrelativeType,
        CashRegisterCode,
        SerialFiscal,
        CurrentNumber,
        Description,
        IsActive
      )
      VALUES (
        @companyId,
        @branchId,
        N'FACTURA',
        @cajaId,
        @serialFiscal,
        @correlativoActual,
        @descripcion,
        1
      );
    END
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      cajaId,
      serialFiscal,
      correlativoActual,
      descripcion: params.descripcion ?? "",
    }
  );

  return {
    ok: true,
    row: {
      tipo: cajaId === "GLOBAL" ? "FACTURA" : `FACTURA|CAJA:${cajaId}`,
      cajaId: cajaId === "GLOBAL" ? null : cajaId,
      serialFiscal,
      correlativoActual,
      descripcion: params.descripcion ?? "",
    },
  };
}

export async function getPosReportResumen(params: { from?: string; to?: string; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);

  const rows = await query<any>(
    `
    WITH ventas AS (
      SELECT SaleTicketId, TotalAmount
      FROM pos.SaleTicket
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND CAST(SoldAt AS date) BETWEEN @fromDate AND @toDate
        AND (@cajaId IS NULL OR UPPER(CashRegisterCode) = @cajaId)
    ),
    detalle AS (
      SELECT l.ProductCode, l.Quantity
      FROM pos.SaleTicketLine l
      INNER JOIN ventas v ON v.SaleTicketId = l.SaleTicketId
    )
    SELECT
      ISNULL((SELECT SUM(TotalAmount) FROM ventas), 0) AS totalVentas,
      ISNULL((SELECT COUNT(1) FROM ventas), 0) AS transacciones,
      ISNULL((SELECT SUM(Quantity) FROM detalle), 0) AS productosVendidos,
      ISNULL((SELECT COUNT(DISTINCT ProductCode) FROM detalle), 0) AS productosDiferentes,
      CASE
        WHEN (SELECT COUNT(1) FROM ventas) = 0 THEN 0
        ELSE ISNULL((SELECT SUM(TotalAmount) FROM ventas), 0) / NULLIF((SELECT COUNT(1) FROM ventas), 0)
      END AS ticketPromedio
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      fromDate,
      toDate,
      cajaId,
    }
  );

  return {
    from: fromDate,
    to: toDate,
    row: rows[0] ?? {
      totalVentas: 0,
      transacciones: 0,
      productosVendidos: 0,
      productosDiferentes: 0,
      ticketPromedio: 0,
    },
    executionMode: "ts_canonical" as const,
  };
}

export async function listPosReportVentas(params: { from?: string; to?: string; limit?: number; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);
  const limit = Math.min(Math.max(params.limit ?? 200, 1), 500);

  const rows = await query<any>(
    `
    SELECT TOP (${limit})
      v.SaleTicketId AS id,
      v.InvoiceNumber AS numFactura,
      v.SoldAt AS fecha,
      ISNULL(NULLIF(LTRIM(RTRIM(v.CustomerName)), N''), N'Consumidor Final') AS cliente,
      v.CashRegisterCode AS cajaId,
      v.TotalAmount AS total,
      N'Completada' AS estado,
      v.PaymentMethod AS metodoPago,
      v.FiscalPayload AS tramaFiscal,
      corr.SerialFiscal AS serialFiscal,
      corr.CurrentNumber AS correlativoFiscal
    FROM pos.SaleTicket v
    OUTER APPLY (
      SELECT TOP 1
        fc.SerialFiscal,
        fc.CurrentNumber
      FROM pos.FiscalCorrelative fc
      WHERE fc.CompanyId = v.CompanyId
        AND fc.BranchId = v.BranchId
        AND fc.CorrelativeType = N'FACTURA'
        AND fc.IsActive = 1
        AND fc.CashRegisterCode IN (UPPER(v.CashRegisterCode), N'GLOBAL')
      ORDER BY CASE WHEN fc.CashRegisterCode = UPPER(v.CashRegisterCode) THEN 0 ELSE 1 END,
               fc.FiscalCorrelativeId DESC
    ) corr
    WHERE v.CompanyId = @companyId
      AND v.BranchId = @branchId
      AND CAST(v.SoldAt AS date) BETWEEN @fromDate AND @toDate
      AND (@cajaId IS NULL OR UPPER(v.CashRegisterCode) = @cajaId)
    ORDER BY v.SoldAt DESC, v.SaleTicketId DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      fromDate,
      toDate,
      cajaId,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportProductosTop(params: { from?: string; to?: string; limit?: number; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);
  const limit = Math.min(Math.max(params.limit ?? 20, 1), 100);

  const rows = await query<any>(
    `
    SELECT TOP (${limit})
      l.ProductId AS productoId,
      l.ProductCode AS codigo,
      l.ProductName AS nombre,
      SUM(l.Quantity) AS cantidad,
      SUM(l.TotalAmount) AS total
    FROM pos.SaleTicketLine l
    INNER JOIN pos.SaleTicket v ON v.SaleTicketId = l.SaleTicketId
    WHERE v.CompanyId = @companyId
      AND v.BranchId = @branchId
      AND CAST(v.SoldAt AS date) BETWEEN @fromDate AND @toDate
      AND (@cajaId IS NULL OR UPPER(v.CashRegisterCode) = @cajaId)
    GROUP BY l.ProductId, l.ProductCode, l.ProductName
    ORDER BY total DESC, cantidad DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      fromDate,
      toDate,
      cajaId,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportFormasPago(params: { from?: string; to?: string; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);

  const rows = await query<any>(
    `
    SELECT
      ISNULL(NULLIF(LTRIM(RTRIM(v.PaymentMethod)), N''), N'No especificado') AS metodoPago,
      COUNT(1) AS transacciones,
      SUM(v.TotalAmount) AS total
    FROM pos.SaleTicket v
    WHERE v.CompanyId = @companyId
      AND v.BranchId = @branchId
      AND CAST(v.SoldAt AS date) BETWEEN @fromDate AND @toDate
      AND (@cajaId IS NULL OR UPPER(v.CashRegisterCode) = @cajaId)
    GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(v.PaymentMethod)), N''), N'No especificado')
    ORDER BY total DESC
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      fromDate,
      toDate,
      cajaId,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportCajas(params: { from?: string; to?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);

  const rows = await query<any>(
    `
    SELECT
      UPPER(v.CashRegisterCode) AS cajaId,
      COUNT(1) AS transacciones,
      SUM(v.TotalAmount) AS total,
      MAX(ISNULL(corr.SerialFiscal, N'')) AS serialFiscal
    FROM pos.SaleTicket v
    OUTER APPLY (
      SELECT TOP 1 fc.SerialFiscal
      FROM pos.FiscalCorrelative fc
      WHERE fc.CompanyId = v.CompanyId
        AND fc.BranchId = v.BranchId
        AND fc.CorrelativeType = N'FACTURA'
        AND fc.IsActive = 1
        AND fc.CashRegisterCode IN (UPPER(v.CashRegisterCode), N'GLOBAL')
      ORDER BY CASE WHEN fc.CashRegisterCode = UPPER(v.CashRegisterCode) THEN 0 ELSE 1 END,
               fc.FiscalCorrelativeId DESC
    ) corr
    WHERE v.CompanyId = @companyId
      AND v.BranchId = @branchId
      AND CAST(v.SoldAt AS date) BETWEEN @fromDate AND @toDate
    GROUP BY UPPER(v.CashRegisterCode)
    ORDER BY cajaId
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      fromDate,
      toDate,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}
