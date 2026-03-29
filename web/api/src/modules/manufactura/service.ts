/**
 * Manufactura Service — Stored Procedures
 *
 * BOMs, Work Centers, Routing, Work Orders
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

interface SpResult {
  success: boolean;
  message: string;
  [key: string]: unknown;
}

function parseSpResult(output: Record<string, unknown>, extra?: string[]): SpResult {
  const r: SpResult = {
    success: Number(output.Resultado ?? output.ok ?? 0) === 1,
    message: String(output.Mensaje ?? output.mensaje ?? "OK"),
  };
  if (extra) {
    for (const k of extra) r[k] = output[k] ?? null;
  }
  return r;
}

// ── BOMs ─────────────────────────────────────────────────────────────────────

export interface ListBOMsParams {
  status?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export async function listBOMs(params: ListBOMsParams = {}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_Mfg_BOM_List",
    {
      CompanyId: companyId,
      Status: params.status ?? null,
      Search: params.search ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int },
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? (rows as any)?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getBOM(bomId: number) {
  const rows = await callSp("usp_Mfg_BOM_Get", { BOMId: bomId });
  return rows[0] || null;
}

export async function createBOM(data: {
  productId: number;
  bomCode: string;
  bomName: string;
  outputQuantity?: number;
  linesJson?: string | null;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_Mfg_BOM_Create",
    {
      CompanyId: companyId,
      ProductId: data.productId,
      BOMCode: data.bomCode,
      BOMName: data.bomName,
      OutputQuantity: data.outputQuantity ?? 1,
      LinesJson: data.linesJson ?? null,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      BOMId: sql.Int,
    },
  );
  return parseSpResult(output, ["BOMId"]);
}

export async function activateBOM(bomId: number, userId: number): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_BOM_Activate",
    { BOMId: bomId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function obsoleteBOM(bomId: number, userId: number): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_BOM_Obsolete",
    { BOMId: bomId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Work Centers ─────────────────────────────────────────────────────────────

export interface ListWorkCentersParams {
  search?: string;
  page?: number;
  limit?: number;
}

export async function listWorkCenters(params: ListWorkCentersParams = {}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_Mfg_WorkCenter_List",
    {
      CompanyId: companyId,
      Search: params.search ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int },
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? (rows as any)?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function upsertWorkCenter(data: {
  workCenterId?: number | null;
  workCenterCode: string;
  workCenterName: string;
  costPerHour?: number;
  capacity?: number;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_Mfg_WorkCenter_Upsert",
    {
      CompanyId: companyId,
      WorkCenterId: data.workCenterId ?? null,
      WorkCenterCode: data.workCenterCode,
      WorkCenterName: data.workCenterName,
      CostPerHour: data.costPerHour ?? 0,
      Capacity: data.capacity ?? 1,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Routing ──────────────────────────────────────────────────────────────────

export async function listRouting(bomId: number) {
  return callSp("usp_Mfg_Routing_List", { BOMId: bomId });
}

export async function upsertRouting(
  bomId: number,
  data: {
    routingId?: number | null;
    operationNumber: number;
    workCenterId: number;
    operationName: string;
    setupTimeMinutes?: number;
    runTimeMinutes?: number;
    notes?: string | null;
    userId: number;
  },
): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_Routing_Upsert",
    {
      BOMId: bomId,
      RoutingId: data.routingId ?? null,
      OperationNumber: data.operationNumber,
      WorkCenterId: data.workCenterId,
      OperationName: data.operationName,
      SetupTimeMinutes: data.setupTimeMinutes ?? 0,
      RunTimeMinutes: data.runTimeMinutes ?? 0,
      Notes: data.notes ?? null,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Work Orders ──────────────────────────────────────────────────────────────

export interface ListWorkOrdersParams {
  status?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export async function listWorkOrders(params: ListWorkOrdersParams = {}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_Mfg_WorkOrder_List",
    {
      CompanyId: companyId,
      Status: params.status ?? null,
      FechaDesde: params.fechaDesde ?? null,
      FechaHasta: params.fechaHasta ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int },
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? (rows as any)?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getWorkOrder(workOrderId: number) {
  const rows = await callSp("usp_Mfg_WorkOrder_Get", { WorkOrderId: workOrderId });
  return rows[0] || null;
}

export async function createWorkOrder(data: {
  bomId: number;
  productId: number;
  plannedQuantity: number;
  plannedStart: string;
  plannedEnd: string;
  priority?: string;
  warehouseId?: number | null;
  notes?: string | null;
  assignedToUserId?: number | null;
  userId: number;
}): Promise<SpResult> {
  const { companyId, branchId } = scope();
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      BOMId: data.bomId,
      ProductId: data.productId,
      PlannedQuantity: data.plannedQuantity,
      PlannedStart: data.plannedStart,
      PlannedEnd: data.plannedEnd,
      Priority: data.priority ?? "MEDIUM",
      WarehouseId: data.warehouseId ?? null,
      Notes: data.notes ?? null,
      AssignedToUserId: data.assignedToUserId ?? null,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      WorkOrderId: sql.Int,
      WorkOrderNumber: sql.NVarChar(30),
    },
  );
  return parseSpResult(output, ["WorkOrderId", "WorkOrderNumber"]);
}

export async function startWorkOrder(workOrderId: number, userId: number): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_Start",
    { WorkOrderId: workOrderId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function consumeMaterial(
  workOrderId: number,
  data: {
    productId: number;
    quantity: number;
    lotNumber?: string | null;
    warehouseId?: number | null;
    userId: number;
  },
): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_ConsumeMaterial",
    {
      WorkOrderId: workOrderId,
      ProductId: data.productId,
      Quantity: data.quantity,
      LotNumber: data.lotNumber ?? null,
      WarehouseId: data.warehouseId ?? null,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function reportOutput(
  workOrderId: number,
  data: {
    quantity: number;
    lotNumber?: string | null;
    warehouseId?: number | null;
    binId?: number | null;
    userId: number;
  },
): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_ReportOutput",
    {
      WorkOrderId: workOrderId,
      Quantity: data.quantity,
      LotNumber: data.lotNumber ?? null,
      WarehouseId: data.warehouseId ?? null,
      BinId: data.binId ?? null,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      OutputId: sql.Int,
    },
  );
  return parseSpResult(output, ["OutputId"]);
}

export async function completeWorkOrder(workOrderId: number, userId: number): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_Complete",
    { WorkOrderId: workOrderId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function cancelWorkOrder(workOrderId: number, userId: number): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Mfg_WorkOrder_Cancel",
    { WorkOrderId: workOrderId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Analytics ──────────────────────────────────────────────────────────────────

export async function getAnalyticsDashboard() {
  const { companyId } = scope();
  const rows = await callSp("usp_Mfg_Analytics_Dashboard", { CompanyId: companyId });
  return rows[0] || null;
}

export async function getProductionByProduct() {
  const { companyId } = scope();
  return callSp("usp_Mfg_Analytics_ProductionByProduct", { CompanyId: companyId });
}

export async function getOrdersByStatus() {
  const { companyId } = scope();
  return callSp("usp_Mfg_Analytics_OrdersByStatus", { CompanyId: companyId });
}

export async function getRecentOrders() {
  const { companyId } = scope();
  return callSp("usp_Mfg_Analytics_RecentOrders", { CompanyId: companyId });
}
