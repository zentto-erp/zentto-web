/**
 * Servicio de Flota — Control de Vehiculos, Combustible, Mantenimiento, Viajes
 *
 * Todas las operaciones van a traves de stored procedures.
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ─── Helpers ──────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

function pag(page?: number, limit?: number) {
  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(Math.max(1, Number(limit) || 50), 500);
  return { page: p, limit: l };
}

// ═══════════════════════════════════════════════════════════════
// VEHICULOS
// ═══════════════════════════════════════════════════════════════

export async function listVehicles(params: {
  status?: string;
  vehicleType?: string;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const { page, limit } = pag(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_Fleet_Vehicle_List",
    {
      CompanyId: companyId,
      Status: params.status?.trim().toUpperCase() || null,
      VehicleType: params.vehicleType?.trim() || null,
      Search: params.search?.trim() || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getVehicle(vehicleId: number) {
  const rows = await callSp<any>("usp_Fleet_Vehicle_Get", { VehicleId: vehicleId });
  return rows[0] ?? null;
}

export async function upsertVehicle(params: {
  vehicleId?: number;
  vehiclePlate: string;
  vin?: string;
  brand: string;
  model: string;
  year: number;
  color?: string;
  vehicleType: string;
  fuelType: string;
  currentMileage: number;
  purchaseDate?: string;
  purchaseCost?: number;
  insurancePolicy?: string;
  insuranceExpiry?: string;
  technicalReviewExpiry?: string;
  permitExpiry?: string;
  assignedDriverId?: number;
  assignedBranchId?: number;
  notes?: string;
  isActive?: boolean;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_Vehicle_Upsert",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId ?? null,
      VehiclePlate: params.vehiclePlate.trim().toUpperCase(),
      VIN: params.vin?.trim() || null,
      Brand: params.brand.trim(),
      Model: params.model.trim(),
      Year: params.year,
      Color: params.color?.trim() || null,
      VehicleType: params.vehicleType.trim(),
      FuelType: params.fuelType.trim(),
      CurrentMileage: params.currentMileage,
      PurchaseDate: params.purchaseDate || null,
      PurchaseCost: params.purchaseCost ?? null,
      InsurancePolicy: params.insurancePolicy?.trim() || null,
      InsuranceExpiry: params.insuranceExpiry || null,
      TechnicalReviewExpiry: params.technicalReviewExpiry || null,
      PermitExpiry: params.permitExpiry || null,
      AssignedDriverId: params.assignedDriverId ?? null,
      AssignedBranchId: params.assignedBranchId ?? null,
      Notes: params.notes?.trim() || null,
      IsActive: params.isActive ?? true,
      UserId: params.userId,
    },
    { Resultado: sql.Int, VehicleIdOut: sql.Int }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    vehicleId: Number(output.VehicleIdOut ?? output.VehicleId ?? 0),
  };
}

// ═══════════════════════════════════════════════════════════════
// COMBUSTIBLE
// ═══════════════════════════════════════════════════════════════

export async function listFuelLogs(params: {
  vehicleId?: number;
  fechaDesde: string;
  fechaHasta: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const { page, limit } = pag(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_Fleet_FuelLog_List",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId ?? null,
      FechaDesde: params.fechaDesde,
      FechaHasta: params.fechaHasta,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function createFuelLog(params: {
  vehicleId: number;
  logDate: string;
  mileage: number;
  fuelType: string;
  liters: number;
  pricePerLiter: number;
  totalCost: number;
  stationName?: string;
  driverId?: number;
  notes?: string;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_FuelLog_Create",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId,
      LogDate: params.logDate,
      Mileage: params.mileage,
      FuelType: params.fuelType.trim(),
      Liters: params.liters,
      PricePerLiter: params.pricePerLiter,
      TotalCost: params.totalCost,
      StationName: params.stationName?.trim() || null,
      DriverId: params.driverId ?? null,
      Notes: params.notes?.trim() || null,
      UserId: params.userId,
    },
    { Resultado: sql.Int, FuelLogId: sql.Int }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    fuelLogId: Number(output.FuelLogId ?? 0),
  };
}

// ═══════════════════════════════════════════════════════════════
// TIPOS DE MANTENIMIENTO
// ═══════════════════════════════════════════════════════════════

export async function listMaintenanceTypes() {
  const { companyId } = scope();
  return callSp<any>("usp_Fleet_MaintenanceType_List", { CompanyId: companyId });
}

export async function upsertMaintenanceType(params: {
  maintenanceTypeId?: number;
  typeCode: string;
  typeName: string;
  category: string;
  defaultIntervalKm?: number;
  defaultIntervalDays?: number;
  isActive?: boolean;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_MaintenanceType_Upsert",
    {
      CompanyId: companyId,
      MaintenanceTypeId: params.maintenanceTypeId ?? null,
      TypeCode: params.typeCode.trim().toUpperCase(),
      TypeName: params.typeName.trim(),
      Category: params.category.trim(),
      DefaultIntervalKm: params.defaultIntervalKm ?? null,
      DefaultIntervalDays: params.defaultIntervalDays ?? null,
      IsActive: params.isActive ?? true,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// ORDENES DE MANTENIMIENTO
// ═══════════════════════════════════════════════════════════════

export async function listMaintenanceOrders(params: {
  vehicleId?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const { page, limit } = pag(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_Fleet_MaintenanceOrder_List",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId ?? null,
      Status: params.status?.trim().toUpperCase() || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getMaintenanceOrder(id: number) {
  const rows = await callSp<any>("usp_Fleet_MaintenanceOrder_Get", { MaintenanceOrderId: id });
  return rows[0] ?? null;
}

export async function createMaintenanceOrder(params: {
  vehicleId: number;
  maintenanceTypeId: number;
  mileageAtService: number;
  scheduledDate: string;
  supplierId?: number;
  estimatedCost: number;
  description: string;
  lines?: Array<{
    description: string;
    partNumber?: string;
    quantity: number;
    unitCost: number;
    lineType?: string;
  }>;
  userId: number;
}) {
  const { companyId, branchId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_MaintenanceOrder_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      VehicleId: params.vehicleId,
      MaintenanceTypeId: params.maintenanceTypeId,
      MileageAtService: params.mileageAtService,
      ScheduledDate: params.scheduledDate,
      SupplierId: params.supplierId ?? null,
      EstimatedCost: params.estimatedCost,
      Description: params.description.trim(),
      LinesJson: params.lines ? JSON.stringify(params.lines) : null,
      UserId: params.userId,
    },
    { Resultado: sql.Int, MaintenanceOrderId: sql.Int, OrderNumber: sql.NVarChar(20) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    maintenanceOrderId: Number(output.MaintenanceOrderId ?? 0),
    orderNumber: String(output.OrderNumber ?? ""),
  };
}

export async function completeMaintenanceOrder(params: {
  maintenanceOrderId: number;
  actualCost: number;
  completedDate: string;
  userId: number;
}) {
  const { output } = await callSpOut(
    "usp_Fleet_MaintenanceOrder_Complete",
    {
      MaintenanceOrderId: params.maintenanceOrderId,
      ActualCost: params.actualCost,
      CompletedDate: params.completedDate,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

export async function cancelMaintenanceOrder(params: {
  maintenanceOrderId: number;
  userId: number;
}) {
  const { output } = await callSpOut(
    "usp_Fleet_MaintenanceOrder_Cancel",
    {
      MaintenanceOrderId: params.maintenanceOrderId,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// VIAJES
// ═══════════════════════════════════════════════════════════════

export async function listTrips(params: {
  vehicleId?: number;
  status?: string;
  fechaDesde: string;
  fechaHasta: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const { page, limit } = pag(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_Fleet_Trip_List",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId ?? null,
      Status: params.status?.trim().toUpperCase() || null,
      FechaDesde: params.fechaDesde,
      FechaHasta: params.fechaHasta,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function createTrip(params: {
  vehicleId: number;
  driverId?: number;
  origin: string;
  destination: string;
  departureDate: string;
  startMileage: number;
  deliveryNoteId?: number;
  notes?: string;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_Trip_Create",
    {
      CompanyId: companyId,
      VehicleId: params.vehicleId,
      DriverId: params.driverId ?? null,
      Origin: params.origin.trim(),
      Destination: params.destination.trim(),
      DepartureDate: params.departureDate,
      StartMileage: params.startMileage,
      DeliveryNoteId: params.deliveryNoteId ?? null,
      Notes: params.notes?.trim() || null,
      UserId: params.userId,
    },
    { Resultado: sql.Int, TripId: sql.Int, TripNumber: sql.NVarChar(20) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    tripId: Number(output.TripId ?? 0),
    tripNumber: String(output.TripNumber ?? ""),
  };
}

export async function completeTrip(params: {
  tripId: number;
  endMileage: number;
  arrivalDate: string;
  fuelUsed?: number;
  userId: number;
}) {
  const { output } = await callSpOut(
    "usp_Fleet_Trip_Complete",
    {
      TripId: params.tripId,
      EndMileage: params.endMileage,
      ArrivalDate: params.arrivalDate,
      FuelUsed: params.fuelUsed ?? null,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENTOS DE VEHICULO
// ═══════════════════════════════════════════════════════════════

export async function listVehicleDocuments(vehicleId: number) {
  return callSp<any>("usp_Fleet_VehicleDocument_List", { VehicleId: vehicleId });
}

export async function upsertVehicleDocument(params: {
  documentId?: number;
  vehicleId: number;
  documentType: string;
  documentNumber?: string;
  issueDate: string;
  expiryDate?: string;
  filePath?: string;
  notes?: string;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Fleet_VehicleDocument_Upsert",
    {
      CompanyId: companyId,
      DocumentId: params.documentId ?? null,
      VehicleId: params.vehicleId,
      DocumentType: params.documentType.trim(),
      DocumentNumber: params.documentNumber?.trim() || null,
      IssueDate: params.issueDate,
      ExpiryDate: params.expiryDate || null,
      FilePath: params.filePath?.trim() || null,
      Notes: params.notes?.trim() || null,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// ALERTAS
// ═══════════════════════════════════════════════════════════════

export async function getAlerts() {
  const { companyId, branchId } = scope();
  const rows = await callSp<any>("usp_Fleet_Alerts_Get", {
    CompanyId: companyId,
    BranchId: branchId ?? null,
  });
  return rows;
}

// ═══════════════════════════════════════════════════════════════
// REPORTES
// ═══════════════════════════════════════════════════════════════

export async function reportFuelMonthly(params: {
  year: number;
  month: number;
}) {
  const { companyId, branchId } = scope();
  const rows = await callSp<any>("usp_Fleet_Report_FuelMonthly", {
    CompanyId: companyId,
    BranchId: branchId ?? null,
    Year: params.year,
    Month: params.month,
  });
  return rows;
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════

export async function getDashboard() {
  const { companyId } = scope();
  const rows = await callSp<any>("usp_Fleet_Dashboard", { CompanyId: companyId });
  return rows[0] ?? null;
}

// ═══════════════════════════════════════════════════════════════
// ANALYTICS
// ═══════════════════════════════════════════════════════════════

export async function getFuelCostByVehicle() {
  const { companyId } = scope();
  return callSp<any>("usp_Fleet_Analytics_FuelCostByVehicle", { CompanyId: companyId });
}

export async function getKmByMonth() {
  const { companyId } = scope();
  return callSp<any>("usp_Fleet_Analytics_KmByMonth", { CompanyId: companyId });
}

export async function getNextMaintenance() {
  const { companyId } = scope();
  return callSp<any>("usp_Fleet_Analytics_NextMaintenance", { CompanyId: companyId });
}

export async function getTrendCards() {
  const { companyId } = scope();
  const rows = await callSp<any>("usp_Fleet_Analytics_TrendCards", { CompanyId: companyId });
  return rows[0] ?? null;
}
