import { callSp, callSpOut, sql } from "../../db/query.js";
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

  const search = params.search?.trim() ? `%${params.search.trim()}%` : null;
  const categoria = params.categoria?.trim() || null;

  const { rows, output } = await callSpOut<any>(
    "usp_POS_Product_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Search: search,
      Categoria: categoria,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: Number(output.TotalCount ?? 0),
    rows,
    executionMode: "ts_canonical" as const,
  };
}

export async function getProductoByCodigo(codigo: string) {
  const scope = await getDefaultScope();
  const value = String(codigo ?? "").trim();

  const rows = await callSp<any>(
    "usp_POS_Product_GetByCode",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Codigo: value,
    }
  );

  return { row: rows[0] ?? null, executionMode: "ts_canonical" as const };
}

export async function searchClientesPOS(search?: string, limit = 20) {
  const scope = await getDefaultScope();
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 200);

  const searchParam = search?.trim() ? `%${search.trim()}%` : null;

  const rows = await callSp<any>(
    "usp_POS_Customer_Search",
    {
      CompanyId: scope.companyId,
      Search: searchParam,
      Limit: safeLimit,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function listCategoriasPOS() {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "usp_POS_Category_List",
    { CompanyId: scope.companyId }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function listCorrelativosFiscales(params: { cajaId?: string }) {
  const scope = await getDefaultScope();
  const caja = normalizeCashRegister(params.cajaId);

  const rows = await callSp<any>(
    "usp_POS_FiscalCorrelative_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CajaId: caja,
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

  await callSpOut(
    "usp_POS_FiscalCorrelative_Upsert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CajaId: cajaId,
      SerialFiscal: serialFiscal,
      CorrelativoActual: correlativoActual,
      Descripcion: params.descripcion ?? "",
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
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

  const rows = await callSp<any>(
    "usp_POS_Report_Resumen",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FromDate: fromDate,
      ToDate: toDate,
      CajaId: cajaId,
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

  const rows = await callSp<any>(
    "usp_POS_Report_Ventas",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FromDate: fromDate,
      ToDate: toDate,
      CajaId: cajaId,
      Limit: limit,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportProductosTop(params: { from?: string; to?: string; limit?: number; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);
  const limit = Math.min(Math.max(params.limit ?? 20, 1), 100);

  const rows = await callSp<any>(
    "usp_POS_Report_ProductosTop",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FromDate: fromDate,
      ToDate: toDate,
      CajaId: cajaId,
      Limit: limit,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportFormasPago(params: { from?: string; to?: string; cajaId?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);
  const cajaId = normalizeCashRegister(params.cajaId);

  const rows = await callSp<any>(
    "usp_POS_Report_FormasPago",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FromDate: fromDate,
      ToDate: toDate,
      CajaId: cajaId,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}

export async function listPosReportCajas(params: { from?: string; to?: string }) {
  const scope = await getDefaultScope();
  const { fromDate, toDate } = normalizeRange(params.from, params.to);

  const rows = await callSp<any>(
    "usp_POS_Report_Cajas",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FromDate: fromDate,
      ToDate: toDate,
    }
  );

  return { from: fromDate, to: toDate, rows, executionMode: "ts_canonical" as const };
}
