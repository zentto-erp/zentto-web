/**
 * Logistica Service
 * SPs: usp_Logistics_Carrier_*, usp_Logistics_Driver_*,
 *       usp_Logistics_GoodsReceipt_*, usp_Logistics_GoodsReturn_*,
 *       usp_Logistics_DeliveryNote_*
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

// ── Carriers ────────────────────────────────────────────────────────────────

export async function listCarriers(params: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Logistics_Carrier_List",
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

export async function upsertCarrier(data: {
  carrierId?: number | null;
  carrierCode: string;
  carrierName: string;
  fiscalId?: string;
  contactName?: string;
  phone?: string;
  email?: string;
  addressLine?: string;
  isActive?: boolean;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_Carrier_Upsert", {
    CompanyId: companyId,
    CarrierId: data.carrierId || null,
    CarrierCode: data.carrierCode,
    CarrierName: data.carrierName,
    FiscalId: data.fiscalId || null,
    ContactName: data.contactName || null,
    Phone: data.phone || null,
    Email: data.email || null,
    AddressLine: data.addressLine || null,
    IsActive: data.isActive ?? true,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Drivers ─────────────────────────────────────────────────────────────────

export async function listDrivers(params: {
  carrierId?: number;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Logistics_Driver_List",
    {
      CompanyId: companyId,
      CarrierId: params.carrierId || null,
      Search: params.search || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function upsertDriver(data: {
  driverId?: number | null;
  carrierId?: number;
  driverCode: string;
  driverName: string;
  fiscalId?: string;
  licenseNumber?: string;
  licenseExpiry?: string;
  phone?: string;
  isActive?: boolean;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_Driver_Upsert", {
    CompanyId: companyId,
    DriverId: data.driverId || null,
    CarrierId: data.carrierId || null,
    DriverCode: data.driverCode,
    DriverName: data.driverName,
    FiscalId: data.fiscalId || null,
    LicenseNumber: data.licenseNumber || null,
    LicenseExpiry: data.licenseExpiry || null,
    Phone: data.phone || null,
    IsActive: data.isActive ?? true,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Goods Receipts ──────────────────────────────────────────────────────────

export async function listGoodsReceipts(params: {
  supplierId?: number;
  status?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId, branchId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Logistics_GoodsReceipt_List",
    {
      CompanyId: companyId,
      BranchId: branchId,
      SupplierId: params.supplierId || null,
      Status: params.status || null,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getGoodsReceipt(goodsReceiptId: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_GoodsReceipt_Get", {
    CompanyId: companyId,
    GoodsReceiptId: goodsReceiptId,
  });
  return rows[0] || null;
}

export async function createGoodsReceipt(data: {
  purchaseDocumentNumber?: string;
  supplierId?: number;
  warehouseId: number;
  receiptDate: string;
  carrierId?: number;
  driverName?: string;
  vehiclePlate?: string;
  notes?: string;
  lines: Array<{
    ProductId: number;
    ExpectedQty?: number;
    ReceivedQty?: number;
    UnitCost?: number;
    LotNumber?: string;
    BinId?: number;
    Notes?: string;
  }>;
  userId?: number;
}) {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Logistics_GoodsReceipt_Create", {
    CompanyId: companyId,
    BranchId: branchId,
    PurchaseDocumentNumber: data.purchaseDocumentNumber || null,
    SupplierId: data.supplierId || null,
    WarehouseId: data.warehouseId,
    ReceiptDate: data.receiptDate,
    CarrierId: data.carrierId || null,
    DriverName: data.driverName || null,
    VehiclePlate: data.vehiclePlate || null,
    Notes: data.notes || null,
    LinesJson: JSON.stringify(data.lines),
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    goodsReceiptId: r?.GoodsReceiptId ? Number(r.GoodsReceiptId) : null,
    receiptNumber: r?.ReceiptNumber ? String(r.ReceiptNumber) : null,
  };
}

export async function approveGoodsReceipt(goodsReceiptId: number, userId?: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_GoodsReceipt_Approve", {
    CompanyId: companyId,
    GoodsReceiptId: goodsReceiptId,
    UserId: userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Goods Returns ───────────────────────────────────────────────────────────

export async function listGoodsReturns(params: {
  status?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId, branchId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Logistics_GoodsReturn_List",
    {
      CompanyId: companyId,
      BranchId: branchId,
      Status: params.status || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function createGoodsReturn(data: {
  goodsReceiptId?: number;
  supplierId?: number;
  warehouseId: number;
  returnDate: string;
  reason?: string;
  lines: Array<{
    ProductId: number;
    Quantity?: number;
    UnitCost?: number;
    LotNumber?: string;
    SerialNumber?: string;
    Notes?: string;
  }>;
  userId?: number;
}) {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Logistics_GoodsReturn_Create", {
    CompanyId: companyId,
    BranchId: branchId,
    GoodsReceiptId: data.goodsReceiptId || null,
    SupplierId: data.supplierId || null,
    WarehouseId: data.warehouseId,
    ReturnDate: data.returnDate,
    Reason: data.reason || null,
    LinesJson: JSON.stringify(data.lines),
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    returnNumber: r?.ReturnNumber ? String(r.ReturnNumber) : null,
  };
}

export async function approveGoodsReturn(goodsReturnId: number, userId?: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_GoodsReturn_Approve", {
    CompanyId: companyId,
    GoodsReturnId: goodsReturnId,
    UserId: userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Delivery Notes ──────────────────────────────────────────────────────────

export async function listDeliveryNotes(params: {
  customerId?: number;
  status?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId, branchId } = requireScope();
  const { page, limit } = paginate(params.page, params.limit);

  const { rows, output } = await callSpOut(
    "usp_Logistics_DeliveryNote_List",
    {
      CompanyId: companyId,
      BranchId: branchId,
      CustomerId: params.customerId || null,
      Status: params.status || null,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows: rows || [], total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getDeliveryNote(deliveryNoteId: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_DeliveryNote_Get", {
    CompanyId: companyId,
    DeliveryNoteId: deliveryNoteId,
  });
  return rows[0] || null;
}

export async function createDeliveryNote(data: {
  salesDocumentNumber?: string;
  customerId?: number;
  warehouseId: number;
  deliveryDate: string;
  carrierId?: number;
  driverId?: number;
  vehiclePlate?: string;
  shipToAddress?: string;
  shipToContact?: string;
  estimatedDelivery?: string;
  lines: Array<{
    ProductId: number;
    Quantity?: number;
    UnitCost?: number;
    LotNumber?: string;
    BinId?: number;
    Notes?: string;
  }>;
  userId?: number;
}) {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Logistics_DeliveryNote_Create", {
    CompanyId: companyId,
    BranchId: branchId,
    SalesDocumentNumber: data.salesDocumentNumber || null,
    CustomerId: data.customerId || null,
    WarehouseId: data.warehouseId,
    DeliveryDate: data.deliveryDate,
    CarrierId: data.carrierId || null,
    DriverId: data.driverId || null,
    VehiclePlate: data.vehiclePlate || null,
    ShipToAddress: data.shipToAddress || null,
    ShipToContact: data.shipToContact || null,
    EstimatedDelivery: data.estimatedDelivery || null,
    LinesJson: JSON.stringify(data.lines),
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    ok: Number(r?.ok ?? 0) === 1,
    mensaje: String(r?.mensaje ?? ""),
    deliveryNoteId: r?.DeliveryNoteId ? Number(r.DeliveryNoteId) : null,
    deliveryNumber: r?.DeliveryNumber ? String(r.DeliveryNumber) : null,
  };
}

export async function dispatchDeliveryNote(deliveryNoteId: number, userId?: number) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_DeliveryNote_Dispatch", {
    CompanyId: companyId,
    DeliveryNoteId: deliveryNoteId,
    UserId: userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}

// ── Dashboard ──────────────────────────────────────────────────────────────

export async function getDashboard() {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Logistics_Dashboard_Get", {
    CompanyId: companyId,
    BranchId: branchId,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return {
    recepcionesPendientes: Number(r?.RecepcionesPendientes ?? 0),
    devolucionesEnProceso: Number(r?.DevolucionesEnProceso ?? 0),
    albaranesEnTransito: Number(r?.AlbaranesEnTransito ?? 0),
    transportistasActivos: Number(r?.TransportistasActivos ?? 0),
  };
}

// ── Analytics ──────────────────────────────────────────────────────────────

export async function getReceiptsByMonth() {
  const { companyId, branchId } = requireScope();
  return callSp("usp_Logistics_Analytics_ReceiptsByMonth", {
    CompanyId: companyId,
    BranchId: branchId,
  });
}

export async function getDeliveryByStatus() {
  const { companyId, branchId } = requireScope();
  return callSp("usp_Logistics_Analytics_DeliveryByStatus", {
    CompanyId: companyId,
    BranchId: branchId,
  });
}

export async function getRecentActivity() {
  const { companyId, branchId } = requireScope();
  return callSp("usp_Logistics_Analytics_RecentActivity", {
    CompanyId: companyId,
    BranchId: branchId,
  });
}

export async function getTrendCards() {
  const { companyId, branchId } = requireScope();
  const rows = await callSp("usp_Logistics_Analytics_TrendCards", {
    CompanyId: companyId,
    BranchId: branchId,
  });
  return rows[0] || null;
}

export async function deliverDeliveryNote(data: {
  deliveryNoteId: number;
  deliveredToName?: string;
  deliverySignature?: string;
  userId?: number;
}) {
  const { companyId } = requireScope();
  const rows = await callSp("usp_Logistics_DeliveryNote_Deliver", {
    CompanyId: companyId,
    DeliveryNoteId: data.deliveryNoteId,
    DeliveredToName: data.deliveredToName || null,
    DeliverySignature: data.deliverySignature || null,
    UserId: data.userId || null,
  });
  const r = rows[0] as Record<string, unknown> | undefined;
  return { ok: Number(r?.ok ?? 0) === 1, mensaje: String(r?.mensaje ?? "") };
}
