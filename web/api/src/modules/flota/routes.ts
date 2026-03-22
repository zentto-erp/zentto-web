/**
 * Rutas de Flota — Control de Vehiculos, Combustible, Mantenimiento, Viajes
 *
 * Montado en /v1/flota
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as svc from "./service.js";
import { emitFuelAccountingEntry, emitMaintenanceAccountingEntry } from "./fleet-contabilidad.service.js";

export const flotaRouter = Router();

// ─── Helper ────────────────────────────────────────────────
function getUserId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

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
    res.json(result);
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
    res.json(result);
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
    res.json(result);
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
    res.json(result);
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
