/**
 * Movimientos de Inventario Service - Stored Procedures
 * SPs: usp_Inventario_Movimiento_Insert, _List, Dashboard, LibroInventario
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

// ── Interfaces ──────────────────────────────────────────────

export interface MovimientoRow {
  MovementId: number;
  ProductCode: string;
  ProductName: string;
  MovementType: string;
  MovementDate: string;
  Quantity: number;
  UnitCost: number;
  TotalCost: number;
  DocumentRef: string | null;
  WarehouseFrom: string | null;
  WarehouseTo: string | null;
  Notes: string | null;
  CreatedAt: string;
  CreatedByUserId: number | null;
}

export interface InsertMovimientoParams {
  companyId: number;
  productCode: string;
  movementType: string;
  quantity: number;
  unitCost?: number;
  documentRef?: string;
  warehouseFrom?: string;
  warehouseTo?: string;
  notes?: string;
  userId?: number;
  /** Trazabilidad: tipo de documento origen (POS_TICKET, INVOICE, PURCHASE_ORDER, WORK_ORDER, PHYSICAL_COUNT, MANUAL_ADJUST, RECIPE_SALE, TRANSFER) */
  sourceDocumentType?: string;
  /** Trazabilidad: ID del documento origen */
  sourceDocumentId?: number;
}

export interface KardexRow {
  TotalCount: number;
  MovementId: number;
  LedgerSource: string;
  MovementDate: string;
  MovementTypeNorm: string;
  MovementTypeRaw: string;
  Quantity: number;
  UnitCost: number;
  TotalCost: number;
  SaldoAcumulado: number;
  WarehouseFrom: string | null;
  WarehouseTo: string | null;
  SourceDocumentType: string | null;
  SourceDocumentRef: string | null;
  DocumentRef: string | null;
  Notes: string | null;
  CreatedByUserId: number | null;
}

export interface KardexParams {
  companyId: number;
  productCode: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface ListMovimientosParams {
  companyId: number;
  search?: string;
  productCode?: string;
  movementType?: string;
  warehouseCode?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface ListMovimientosResult {
  rows: MovimientoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface DashboardData {
  TotalArticulos: number;
  BajoStock: number;
  TotalCategorias: number;
  ValorInventario: number;
  MovimientosMes: number;
}

export interface LibroRow {
  CODIGO: string;
  DESCRIPCION: string;
  DescripcionCompleta: string;
  StockInicial: number;
  Entradas: number;
  Salidas: number;
  StockFinal: number;
  CostoUnitario: number;
  Unidad: string | null;
}

export interface LibroParams {
  companyId: number;
  fechaDesde: string;
  fechaHasta: string;
  productCode?: string;
}

export interface SpResult {
  success: boolean;
  message: string;
}

// ── Service functions ───────────────────────────────────────

/** usp_Inventario_Movimiento_Insert */
export async function insertMovimientoSP(params: InsertMovimientoParams): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Inventario_Movimiento_Insert",
    {
      CompanyId: params.companyId,
      ProductCode: params.productCode,
      MovementType: params.movementType,
      Quantity: params.quantity,
      UnitCost: params.unitCost ?? 0,
      DocumentRef: params.documentRef ?? null,
      WarehouseFrom: params.warehouseFrom ?? null,
      WarehouseTo: params.warehouseTo ?? null,
      Notes: params.notes ?? null,
      UserId: params.userId ?? null,
      SourceDocumentType: params.sourceDocumentType ?? null,
      SourceDocumentId: params.sourceDocumentId ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}

/** usp_Inventario_Movimiento_List */
export async function listMovimientosSP(params: ListMovimientosParams): Promise<ListMovimientosResult> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut<MovimientoRow>(
    "usp_Inventario_Movimiento_List",
    {
      CompanyId: params.companyId,
      Search: params.search || null,
      ProductCode: params.productCode || null,
      MovementType: params.movementType || null,
      WarehouseCode: params.warehouseCode || null,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

/** usp_Inventario_Dashboard */
export async function getInventarioDashboardSP(companyId: number): Promise<DashboardData> {
  const rows = await callSp<DashboardData>(
    "usp_Inventario_Dashboard",
    { CompanyId: companyId }
  );
  return rows[0] ?? {
    TotalArticulos: 0,
    BajoStock: 0,
    TotalCategorias: 0,
    ValorInventario: 0,
    MovimientosMes: 0,
  };
}

/** usp_Inventario_LibroInventario */
export async function getLibroInventarioSP(params: LibroParams): Promise<LibroRow[]> {
  return callSp<LibroRow>(
    "usp_Inventario_LibroInventario",
    {
      CompanyId: params.companyId,
      FechaDesde: params.fechaDesde,
      FechaHasta: params.fechaHasta,
      ProductCode: params.productCode || null,
    }
  );
}

/** usp_Inventario_Kardex_Detallado — kardex con saldo acumulado y origen del movimiento */
export async function getKardexDetalladoSP(params: KardexParams): Promise<{ rows: KardexRow[]; total: number; page: number; limit: number }> {
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 100), 500);

  const rows = await callSp<KardexRow>(
    "usp_Inventario_Kardex_Detallado",
    {
      CompanyId: params.companyId,
      ProductCode: params.productCode,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      Page: page,
      Limit: limit,
    }
  );

  const total = Number(rows[0]?.TotalCount ?? 0);
  return { rows: rows || [], total, page, limit };
}
