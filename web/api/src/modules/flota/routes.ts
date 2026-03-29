/**
 * Rutas de Flota — Control de Vehiculos, Combustible, Mantenimiento, Viajes
 *
 * Montado en /v1/flota
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as svc from "./service.js";
import { emitFuelAccountingEntry, emitMaintenanceAccountingEntry } from "./fleet-contabilidad.service.js";
import { obs } from "../integrations/observability.js";

export const flotaRouter = Router();

// ─── Helpers ────────────────────────────────────────────────
function getUserId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}
function mapRow(row: any, fm: Record<string, string>): any {
  const out: any = {};
  for (const [target, source] of Object.entries(fm)) out[target] = row[source] ?? null;
  return out;
}
function mapRows(rows: any[], fm: Record<string, string>): any[] {
  return (rows || []).map(r => mapRow(r, fm));
}

// Field maps: frontend field → PG column
const vehicleMap: Record<string, string> = {
  VehicleId: "VehicleId", VehiclePlate: "LicensePlate", VIN: "VinNumber",
  Brand: "Brand", Model: "Model", Year: "Year", Color: "Color",
  VehicleType: "VehicleType", FuelType: "FuelType",
  CurrentMileage: "CurrentOdometer", AssignedDriverName: "DefaultDriverId",
  Status: "Status", IsActive: "IsActive", InsuranceExpiry: "InsuranceExpiry",
  Notes: "Notes", CreatedAt: "CreatedAt",
};
const fuelMap: Record<string, string> = {
  FuelLogId: "FuelLogId", VehicleId: "VehicleId", LogDate: "FuelDate",
  VehiclePlate: "LicensePlate", FuelType: "FuelType", Liters: "Quantity",
  UnitPrice: "UnitPrice", TotalCost: "TotalCost", CurrencyCode: "CurrencyCode",
  Mileage: "OdometerReading", IsFullTank: "IsFullTank",
  StationName: "StationName", DriverId: "DriverId", Notes: "Notes",
};
const maintMap: Record<string, string> = {
  MaintenanceOrderId: "MaintenanceOrderId", OrderNumber: "OrderNumber",
  VehicleId: "VehicleId", VehiclePlate: "LicensePlate",
  MaintenanceCategory: "MaintenanceType", Description: "Description",
  ScheduledDate: "ScheduledDate", CompletedDate: "CompletedDate",
  Status: "Status", EstimatedCost: "EstimatedCost", ActualCost: "ActualCost",
  Notes: "Notes",
};
const tripMap: Record<string, string> = {
  TripId: "TripId", TripNumber: "TripNumber", VehicleId: "VehicleId",
  VehiclePlate: "LicensePlate", DriverId: "DriverId", DriverName: "DriverId",
  Origin: "Origin", Destination: "Destination",
  DepartureDate: "DepartedAt", ArrivalDate: "ArrivedAt",
  Distance: "DistanceKm", Status: "Status", Notes: "Notes",
};

// ═══════════════════════════════════════════════════════════════
// VEHICULOS
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/vehiculos
flotaRouter.get("/vehiculos", async (req: Request, res: Response) => {
  try {
    const result = await svc.listVehicles({
      status: req.query.status as string,
      vehicleType: req.query.vehicleType as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, vehicleMap) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/flota/vehiculos/:id
flotaRouter.get("/vehiculos/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.getVehicle(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/vehiculos
const vehicleSchema = z.object({
  vehicleId: z.number().int().optional(),
  vehiclePlate: z.string().min(1),
  vin: z.string().optional(),
  brand: z.string().min(1),
  model: z.string().min(1),
  year: z.number().int().min(1900).max(2100),
  color: z.string().optional(),
  vehicleType: z.string().min(1),
  fuelType: z.string().min(1),
  currentMileage: z.number().min(0),
  purchaseDate: z.string().optional(),
  purchaseCost: z.number().optional(),
  insurancePolicy: z.string().optional(),
  insuranceExpiry: z.string().optional(),
  technicalReviewExpiry: z.string().optional(),
  permitExpiry: z.string().optional(),
  assignedDriverId: z.number().int().optional(),
  assignedBranchId: z.number().int().optional(),
  notes: z.string().optional(),
  isActive: z.boolean().optional(),
});

flotaRouter.post("/vehiculos", async (req: Request, res: Response) => {
  const parsed = vehicleSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.upsertVehicle({ ...parsed.data, userId: getUserId(req) });
    if (result.success) {
      try { obs.event('fleet.vehicle.upserted', { vehicleId: result.vehicleId ?? parsed.data.vehicleId, licensePlate: parsed.data.vehiclePlate, brand: parsed.data.brand, model: parsed.data.model, year: parsed.data.year, vehicleType: parsed.data.vehicleType, module: 'flota', userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId }); } catch { /* never blocks */ }
    }
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// COMBUSTIBLE
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/combustible
flotaRouter.get("/combustible", async (req: Request, res: Response) => {
  try {
    const result = await svc.listFuelLogs({
      vehicleId: req.query.vehicleId ? parseInt(req.query.vehicleId as string) : undefined,
      fechaDesde: (req.query.fechaDesde as string) || "2000-01-01",
      fechaHasta: (req.query.fechaHasta as string) || "2100-12-31",
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, fuelMap) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/combustible
const fuelLogSchema = z.object({
  vehicleId: z.number().int(),
  logDate: z.string().min(1),
  mileage: z.number().min(0),
  fuelType: z.string().min(1),
  liters: z.number().positive(),
  pricePerLiter: z.number().positive(),
  totalCost: z.number().positive(),
  stationName: z.string().optional(),
  driverId: z.number().int().optional(),
  notes: z.string().optional(),
});

flotaRouter.post("/combustible", async (req: Request, res: Response) => {
  const parsed = fuelLogSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createFuelLog({ ...parsed.data, userId: getUserId(req) });
    if (!result.success) return res.status(400).json(result);

    try { obs.event('fleet.fuel.created', { fuelLogId: result.fuelLogId, vehicleId: parsed.data.vehicleId, liters: parsed.data.liters, totalCost: parsed.data.totalCost, fuelType: parsed.data.fuelType, stationName: parsed.data.stationName, module: 'flota', userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId }); } catch { /* never blocks */ }

    // Best-effort: contabilidad (nunca bloquea la operacion principal)
    let contabilidad: { ok: boolean } = { ok: false };
    try {
      const codUsuario = String(getUserId(req));
      contabilidad = await emitFuelAccountingEntry({
        vehiclePlate: "", // plate not available in this flow
        totalCost: parsed.data.totalCost,
        fecha: parsed.data.logDate,
      }, codUsuario);
    } catch { /* never blocks */ }

    res.status(201).json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// TIPOS DE MANTENIMIENTO
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/tipos-mantenimiento
flotaRouter.get("/tipos-mantenimiento", async (_req: Request, res: Response) => {
  try {
    const rows = await svc.listMaintenanceTypes();
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/tipos-mantenimiento
const maintenanceTypeSchema = z.object({
  maintenanceTypeId: z.number().int().optional(),
  typeCode: z.string().min(1),
  typeName: z.string().min(1),
  category: z.string().min(1),
  defaultIntervalKm: z.number().optional(),
  defaultIntervalDays: z.number().int().optional(),
  isActive: z.boolean().optional(),
});

flotaRouter.post("/tipos-mantenimiento", async (req: Request, res: Response) => {
  const parsed = maintenanceTypeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.upsertMaintenanceType({ ...parsed.data, userId: getUserId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// ORDENES DE MANTENIMIENTO
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/mantenimientos
flotaRouter.get("/mantenimientos", async (req: Request, res: Response) => {
  try {
    const result = await svc.listMaintenanceOrders({
      vehicleId: req.query.vehicleId ? parseInt(req.query.vehicleId as string) : undefined,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, maintMap) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/flota/mantenimientos/:id
flotaRouter.get("/mantenimientos/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.getMaintenanceOrder(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/mantenimientos
const maintenanceOrderSchema = z.object({
  vehicleId: z.number().int(),
  maintenanceTypeId: z.number().int(),
  mileageAtService: z.number().min(0),
  scheduledDate: z.string().min(1),
  supplierId: z.number().int().optional(),
  estimatedCost: z.number().min(0),
  description: z.string().min(1),
  lines: z.array(z.object({
    description: z.string().min(1),
    partNumber: z.string().optional(),
    quantity: z.number().positive(),
    unitCost: z.number().min(0),
    lineType: z.string().optional(),
  })).optional(),
});

flotaRouter.post("/mantenimientos", async (req: Request, res: Response) => {
  const parsed = maintenanceOrderSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createMaintenanceOrder({ ...parsed.data, userId: getUserId(req) });
    if (result.success) {
      try { obs.event('fleet.maintenance.created', { maintenanceOrderId: result.maintenanceOrderId, vehicleId: parsed.data.vehicleId, description: parsed.data.description, scheduledDate: parsed.data.scheduledDate, estimatedCost: parsed.data.estimatedCost, module: 'flota', userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId }); } catch { /* never blocks */ }
    }
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/mantenimientos/:id/completar
const completeMaintenanceSchema = z.object({
  actualCost: z.number().min(0),
  completedDate: z.string().min(1),
});

flotaRouter.post("/mantenimientos/:id/completar", async (req: Request, res: Response) => {
  const parsed = completeMaintenanceSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.completeMaintenanceOrder({
      maintenanceOrderId: Number(req.params.id),
      ...parsed.data,
      userId: getUserId(req),
    });
    if (!result.success) return res.status(400).json(result);

    try { obs.audit('fleet.maintenance.completed', { userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, actualCost: parsed.data.actualCost, completedDate: parsed.data.completedDate, module: 'flota', entity: 'MaintenanceOrder', entityId: Number(req.params.id) }); } catch { /* never blocks */ }

    // Best-effort: contabilidad (nunca bloquea la operacion principal)
    let contabilidad: { ok: boolean } = { ok: false };
    try {
      const codUsuario = String(getUserId(req));
      contabilidad = await emitMaintenanceAccountingEntry({
        orderNumber: `MNT-${req.params.id}`,
        vehiclePlate: "",
        actualCost: parsed.data.actualCost,
        fecha: parsed.data.completedDate,
        isPaid: false,
      }, codUsuario);
    } catch { /* never blocks */ }

    res.status(200).json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/mantenimientos/:id/cancelar
flotaRouter.post("/mantenimientos/:id/cancelar", async (req: Request, res: Response) => {
  try {
    const result = await svc.cancelMaintenanceOrder({
      maintenanceOrderId: Number(req.params.id),
      userId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// VIAJES
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/viajes
flotaRouter.get("/viajes", async (req: Request, res: Response) => {
  try {
    const result = await svc.listTrips({
      vehicleId: req.query.vehicleId ? parseInt(req.query.vehicleId as string) : undefined,
      status: req.query.status as string,
      fechaDesde: (req.query.fechaDesde as string) || "2000-01-01",
      fechaHasta: (req.query.fechaHasta as string) || "2100-12-31",
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, tripMap) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/viajes
const tripSchema = z.object({
  vehicleId: z.number().int(),
  driverId: z.number().int().optional(),
  origin: z.string().min(1),
  destination: z.string().min(1),
  departureDate: z.string().min(1),
  startMileage: z.number().min(0),
  deliveryNoteId: z.number().int().optional(),
  notes: z.string().optional(),
});

flotaRouter.post("/viajes", async (req: Request, res: Response) => {
  const parsed = tripSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createTrip({ ...parsed.data, userId: getUserId(req) });
    if (result.success) {
      try { obs.event('fleet.trip.created', { tripId: result.tripId, vehicleId: parsed.data.vehicleId, origin: parsed.data.origin, destination: parsed.data.destination, departureDate: parsed.data.departureDate, module: 'flota', userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId }); } catch { /* never blocks */ }
    }
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/viajes/:id/completar
const completeTripSchema = z.object({
  endMileage: z.number().min(0),
  arrivalDate: z.string().min(1),
  fuelUsed: z.number().optional(),
});

flotaRouter.post("/viajes/:id/completar", async (req: Request, res: Response) => {
  const parsed = completeTripSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.completeTrip({
      tripId: Number(req.params.id),
      ...parsed.data,
      userId: getUserId(req),
    });
    if (result.success) {
      try { obs.audit('fleet.trip.completed', { userId: getUserId(req), userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, endMileage: parsed.data.endMileage, arrivalDate: parsed.data.arrivalDate, module: 'flota', entity: 'Trip', entityId: Number(req.params.id) }); } catch { /* never blocks */ }
    }
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// DOCUMENTOS DE VEHICULO
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/vehiculos/:id/documentos
flotaRouter.get("/vehiculos/:id/documentos", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listVehicleDocuments(Number(req.params.id));
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/flota/vehiculos/:id/documentos
const documentSchema = z.object({
  documentId: z.number().int().optional(),
  documentType: z.string().min(1),
  documentNumber: z.string().optional(),
  issueDate: z.string().min(1),
  expiryDate: z.string().optional(),
  filePath: z.string().optional(),
  notes: z.string().optional(),
});

flotaRouter.post("/vehiculos/:id/documentos", async (req: Request, res: Response) => {
  const parsed = documentSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.upsertVehicleDocument({
      ...parsed.data,
      vehicleId: Number(req.params.id),
      userId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// ALERTAS
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/alertas
flotaRouter.get("/alertas", async (_req: Request, res: Response) => {
  try {
    const rows = await svc.getAlerts();

    // Separar por tipo de alerta y extraer conteos de la primera fila
    const expired = rows.filter((r: any) => r.AlertType === "EXPIRED");
    const expiringSoon = rows.filter((r: any) => r.AlertType === "EXPIRING_SOON");
    const maintenanceOverdue = rows.filter((r: any) => r.AlertType === "MAINTENANCE_OVERDUE");

    const first = rows[0] ?? {};
    const summary = {
      expiredDocsCount: Number(first.ExpiredDocsCount ?? 0),
      expiringSoonDocsCount: Number(first.ExpiringSoonDocsCount ?? 0),
      overdueMaintenanceCount: Number(first.OverdueMaintenanceCount ?? 0),
    };

    res.json({ expired, expiringSoon, maintenanceOverdue, summary });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// REPORTES
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/reportes/combustible-mensual
flotaRouter.get("/reportes/combustible-mensual", async (req: Request, res: Response) => {
  try {
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;

    if (year < 2000 || year > 2100 || month < 1 || month > 12) {
      return res.status(400).json({ error: "invalid_params", message: "Year (2000-2100) and Month (1-12) required" });
    }

    const rows = await svc.reportFuelMonthly({ year, month });
    res.json({ rows, year, month });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════

// GET /v1/flota/dashboard
flotaRouter.get("/dashboard", async (_req: Request, res: Response) => {
  try {
    const result = await svc.getDashboard();
    if (!result) return res.status(404).json({ error: "no_data" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// ANALYTICS
// ═══════════════════════════════════════════════════════════════

flotaRouter.get("/analytics/fuel-by-vehicle", async (_req: Request, res: Response) => {
  try {
    const data = await svc.getFuelCostByVehicle();
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

flotaRouter.get("/analytics/km-by-month", async (_req: Request, res: Response) => {
  try {
    const data = await svc.getKmByMonth();
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

flotaRouter.get("/analytics/next-maintenance", async (_req: Request, res: Response) => {
  try {
    const data = await svc.getNextMaintenance();
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

flotaRouter.get("/analytics/trends", async (_req: Request, res: Response) => {
  try {
    const data = await svc.getTrendCards();
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
