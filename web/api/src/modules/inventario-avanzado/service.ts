/**
 * Inventario Avanzado Service
 * SPs: usp_Inv_Warehouse_*, usp_Inv_Zone_*, usp_Inv_Bin_*,
 *       usp_Inv_Lot_*, usp_Inv_Serial_*, usp_Inv_BinStock_*,
 *       usp_Inv_Valuation_*, usp_Inv_Movement_*
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ─────────────────────────────────────────────────────────────────

function requireScope() {
  const scope = getActiveScope();
  if (!scope) throw new Error("Scope de empresa no disponible");
  return scope;
}

function paginate(page?: number, limit?: number) {
  const p = Math.max(1, page ?? 1);
  const l = Math.min(Math.max(1, limit ?? 50), 500);
  return { page: p, limit: l };
}

// ── Warehouses ──────────────────────────────────────────────────────────────

export async function listWarehouses(params: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Inv_Warehouse_List",
    {
      CompanyId: companyId,
      Search: params.search || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getWarehouse(warehouseId: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_Warehouse_Get", {
    CompanyId: companyId,
    WarehouseId: warehouseId,
  });
  return rows[0] || null;
}

export async function upsertWarehouse(data: {
  warehouseId?: number | null;
  warehouseCode: string;
  warehouseName: string;
  addressLine?: string;
  contactName?: string;
  phone?: string;
  isActive?: boolean;
  userId?: number;
}) {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Inv_Warehouse_Upsert", {
    CompanyId: companyId,
    BranchId: branchId,
    WarehouseId: data.warehouseId || null,
    WarehouseCode: data.warehouseCode,
    WarehouseName: data.warehouseName,
    AddressLine: data.addressLine || null,
    ContactName: data.contactName || null,
    Phone: data.phone || null,
    IsActive: data.isActive ?? true,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    warehouseId: r?.WarehouseId ? Number(r.WarehouseId) : null,
  };
}

// ── Zones ───────────────────────────────────────────────────────────────────

export async function listZones(warehouseId: number) {
  const rows = await callSp("usp_Inv_Zone_List", { WarehouseId: warehouseId });
  return rows || [];
}

export async function upsertZone(data: {
  zoneId?: number | null;
  warehouseId: number;
  zoneCode: string;
  zoneName: string;
  zoneType?: string;
  temperature?: string;
  isActive?: boolean;
  userId?: number;
}) {
  const rows = await callSp("usp_Inv_Zone_Upsert", {
    ZoneId: data.zoneId || null,
    WarehouseId: data.warehouseId,
    ZoneCode: data.zoneCode,
    ZoneName: data.zoneName,
    ZoneType: data.zoneType || null,
    Temperature: data.temperature || null,
    IsActive: data.isActive ?? true,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Bins ────────────────────────────────────────────────────────────────────

export async function listBins(zoneId: number) {
  const rows = await callSp("usp_Inv_Bin_List", { ZoneId: zoneId });
  return rows || [];
}

export async function upsertBin(data: {
  binId?: number | null;
  zoneId: number;
  binCode: string;
  binName: string;
  maxWeight?: number;
  maxVolume?: number;
  isActive?: boolean;
  userId?: number;
}) {
  const rows = await callSp("usp_Inv_Bin_Upsert", {
    BinId: data.binId || null,
    ZoneId: data.zoneId,
    BinCode: data.binCode,
    BinName: data.binName,
    MaxWeight: data.maxWeight ?? null,
    MaxVolume: data.maxVolume ?? null,
    IsActive: data.isActive ?? true,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Lots ────────────────────────────────────────────────────────────────────

export async function listLots(params: {
  productId?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Inv_Lot_List",
    {
      CompanyId: companyId,
      ProductId: params.productId || null,
      Status: params.status || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getLot(lotId: number) {
  const rows = await callSp("usp_Inv_Lot_Get", { LotId: lotId });
  return rows[0] || null;
}

export async function createLot(data: {
  productId: number;
  lotNumber: string;
  manufactureDate?: string;
  expiryDate?: string;
  supplierCode?: string;
  purchaseDocumentNumber?: string;
  initialQuantity?: number;
  unitCost?: number;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_Lot_Create", {
    CompanyId: companyId,
    ProductId: data.productId,
    LotNumber: data.lotNumber,
    ManufactureDate: data.manufactureDate || null,
    ExpiryDate: data.expiryDate || null,
    SupplierCode: data.supplierCode || null,
    PurchaseDocumentNumber: data.purchaseDocumentNumber || null,
    InitialQuantity: data.initialQuantity ?? 0,
    UnitCost: data.unitCost ?? null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    lotId: r?.LotId ? Number(r.LotId) : null,
  };
}

// ── Serials ─────────────────────────────────────────────────────────────────

export async function listSerials(params: {
  productId?: number;
  status?: string;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Inv_Serial_List",
    {
      CompanyId: companyId,
      ProductId: params.productId || null,
      Status: params.status || null,
      Search: params.search || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getSerial(serialId: number) {
  const rows = await callSp("usp_Inv_Serial_Get", { SerialId: serialId });
  return rows[0] || null;
}

export async function registerSerial(data: {
  productId: number;
  serialNumber: string;
  lotId?: number;
  warehouseId: number;
  binId?: number;
  purchaseDocumentNumber?: string;
  unitCost?: number;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_Serial_Register", {
    CompanyId: companyId,
    ProductId: data.productId,
    SerialNumber: data.serialNumber,
    LotId: data.lotId || null,
    WarehouseId: data.warehouseId,
    BinId: data.binId || null,
    PurchaseDocumentNumber: data.purchaseDocumentNumber || null,
    UnitCost: data.unitCost ?? null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    serialId: r?.SerialId ? Number(r.SerialId) : null,
  };
}

export async function updateSerialStatus(data: {
  serialId: number;
  status: string;
  salesDocumentNumber?: string;
  customerId?: number;
  userId?: number;
}) {
  const rows = await callSp("usp_Inv_Serial_UpdateStatus", {
    SerialId: data.serialId,
    Status: data.status,
    SalesDocumentNumber: data.salesDocumentNumber || null,
    CustomerId: data.customerId || null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Stock by Bin ────────────────────────────────────────────────────────────

export async function listBinStock(params: {
  warehouseId?: number;
  productId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_BinStock_List", {
    CompanyId: companyId,
    WarehouseId: params.warehouseId || null,
    ProductId: params.productId || null,
  });
  return rows || [];
}

// ── Valuation ───────────────────────────────────────────────────────────────

export async function getValuationMethod(productId: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_Valuation_GetMethod", {
    CompanyId: companyId,
    ProductId: productId,
  });
  return rows[0] || null;
}

export async function setValuationMethod(data: {
  productId: number;
  method: string;
  standardCost?: number;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Inv_Valuation_SetMethod", {
    CompanyId: companyId,
    ProductId: data.productId,
    Method: data.method,
    StandardCost: data.standardCost ?? null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Movements ───────────────────────────────────────────────────────────────

export async function listMovements(params: {
  productId?: number;
  warehouseId?: number;
  movementType?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Inv_Movement_List",
    {
      CompanyId: companyId,
      ProductId: params.productId || null,
      WarehouseId: params.warehouseId || null,
      MovementType: params.movementType || null,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function createMovement(data: {
  productId: number;
  lotId?: number;
  serialId?: number;
  fromWarehouseId?: number;
  toWarehouseId?: number;
  fromBinId?: number;
  toBinId?: number;
  movementType: string;
  quantity: number;
  unitCost?: number;
  sourceDocumentType?: string;
  sourceDocumentNumber?: string;
  notes?: string;
  userId?: number;
}) {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Inv_Movement_Create", {
    CompanyId: companyId,
    BranchId: branchId,
    ProductId: data.productId,
    LotId: data.lotId || null,
    SerialId: data.serialId || null,
    FromWarehouseId: data.fromWarehouseId || null,
    ToWarehouseId: data.toWarehouseId || null,
    FromBinId: data.fromBinId || null,
    ToBinId: data.toBinId || null,
    MovementType: data.movementType,
    Quantity: data.quantity,
    UnitCost: data.unitCost ?? null,
    SourceDocumentType: data.sourceDocumentType || null,
    SourceDocumentNumber: data.sourceDocumentNumber || null,
    Notes: data.notes || null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    movementId: r?.MovementId ? Number(r.MovementId) : null,
  };
}
