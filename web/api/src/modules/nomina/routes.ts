/**
 * Rutas de Nómina
 */
import { Router } from "express";
import { z } from "zod";
import * as nominaService from "./service.js";
import { conceptoLegalRouter } from "./conceptolegal.routes.js";

export const nominaRouter = Router();

// Sub-rutas para ConceptoLegal (tabla existente del usuario)
nominaRouter.use("/", conceptoLegalRouter);

// Esquemas de validación
const conceptoSchema = z.object({
  codigo: z.string().min(1).max(10),
  codigoNomina: z.string().min(1).max(15),
  nombre: z.string().min(1).max(100),
  formula: z.string().max(255).optional(),
  sobre: z.string().max(255).optional(),
  clase: z.string().max(15).optional(),
  tipo: z.enum(["ASIGNACION", "DEDUCCION", "BONO"]).optional(),
  uso: z.string().max(15).optional(),
  bonificable: z.string().length(1).optional(),
  esAntiguedad: z.string().length(1).optional(),
  cuentaContable: z.string().max(50).optional(),
  aplica: z.string().length(1).optional(),
  valorDefecto: z.number().optional(),
});

const procesarEmpleadoSchema = z.object({
  nomina: z.string().min(1),
  cedula: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), // YYYY-MM-DD
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

const procesarNominaSchema = z.object({
  nomina: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  soloActivos: z.boolean().optional(),
});

const vacacionesSchema = z.object({
  vacacionId: z.string().min(1),
  cedula: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaReintegro: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

const liquidacionSchema = z.object({
  liquidacionId: z.string().min(1),
  cedula: z.string().min(1),
  fechaRetiro: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  causaRetiro: z.enum(["RENUNCIA", "DESPIDO", "DESPIDO_JUSTIFICADO"]).optional(),
});

const constanteSchema = z.object({
  codigo: z.string().min(1).max(50),
  nombre: z.string().max(100).optional(),
  valor: z.number().optional(),
  origen: z.string().max(50).optional(),
});

// GET /v1/nomina/conceptos - Listar conceptos
nominaRouter.get("/conceptos", async (req, res) => {
  try {
    const result = await nominaService.listConceptos({
      coNomina: req.query.coNomina as string,
      tipo: req.query.tipo as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/conceptos - Guardar concepto
nominaRouter.post("/conceptos", async (req, res) => {
  const parsed = conceptoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await nominaService.saveConcepto(parsed.data);
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/procesar-empleado - Procesar nómina de un empleado
nominaRouter.post("/procesar-empleado", async (req, res) => {
  const parsed = procesarEmpleadoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.procesarNominaEmpleado({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/procesar - Procesar nómina completa
nominaRouter.post("/procesar", async (req, res) => {
  const parsed = procesarNominaSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.procesarNominaCompleta({
      ...parsed.data,
      codUsuario,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina - Listar nóminas
nominaRouter.get("/", async (req, res) => {
  try {
    const result = await nominaService.listNominas({
      nomina: req.query.nomina as string,
      cedula: req.query.cedula as string,
      fechaDesde: req.query.fechaDesde as string,
      fechaHasta: req.query.fechaHasta as string,
      soloAbiertas: req.query.soloAbiertas === "true",
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/cerrar - Cerrar nómina
nominaRouter.post("/cerrar", async (req, res) => {
  const schema = z.object({
    nomina: z.string().min(1),
    cedula: z.string().optional(),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.cerrarNomina({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/vacaciones/procesar - Procesar vacaciones
nominaRouter.post("/vacaciones/procesar", async (req, res) => {
  const parsed = vacacionesSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.procesarVacaciones({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ─── Solicitudes de Vacaciones ──────────────────────────────

const solicitudSchema = z.object({
  employeeCode: z.string().min(1),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  totalDays: z.number().int().positive(),
  isPartial: z.boolean().default(false),
  notes: z.string().max(500).optional(),
  days: z.array(z.object({
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    dayType: z.string().default("COMPLETO"),
  })).min(1),
});

const rejectSchema = z.object({
  reason: z.string().min(1).max(500),
});

// POST /v1/nomina/vacaciones/solicitar
nominaRouter.post("/vacaciones/solicitar", async (req, res) => {
  const parsed = solicitudSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await nominaService.createVacationRequest(parsed.data);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/vacaciones/solicitudes
nominaRouter.get("/vacaciones/solicitudes", async (req, res) => {
  try {
    const result = await nominaService.listVacationRequests({
      employeeCode: req.query.employeeCode as string,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/vacaciones/solicitudes/:id
nominaRouter.get("/vacaciones/solicitudes/:id", async (req, res) => {
  try {
    const result = await nominaService.getVacationRequest(req.params.id);
    if (!result) return res.status(404).json({ error: "solicitud_not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/nomina/vacaciones/solicitudes/:id/aprobar
nominaRouter.put("/vacaciones/solicitudes/:id/aprobar", async (req, res) => {
  try {
    const approvedBy = (req as any).user?.username || "API";
    const result = await nominaService.approveVacationRequest(req.params.id, approvedBy);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/nomina/vacaciones/solicitudes/:id/rechazar
nominaRouter.put("/vacaciones/solicitudes/:id/rechazar", async (req, res) => {
  const parsed = rejectSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const approvedBy = (req as any).user?.username || "API";
    const result = await nominaService.rejectVacationRequest(req.params.id, approvedBy, parsed.data.reason);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/nomina/vacaciones/solicitudes/:id/cancelar
nominaRouter.put("/vacaciones/solicitudes/:id/cancelar", async (req, res) => {
  try {
    const result = await nominaService.cancelVacationRequest(req.params.id);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/vacaciones/solicitudes/:id/procesar-pago
nominaRouter.post("/vacaciones/solicitudes/:id/procesar-pago", async (req, res) => {
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.processVacationRequestPayment(req.params.id, codUsuario);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/vacaciones/dias-disponibles/:cedula
nominaRouter.get("/vacaciones/dias-disponibles/:cedula", async (req, res) => {
  try {
    const result = await nominaService.getAvailableDays(req.params.cedula);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/vacaciones - Listar vacaciones
nominaRouter.get("/vacaciones/list", async (req, res) => {
  try {
    const result = await nominaService.listVacaciones({
      cedula: req.query.cedula as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/vacaciones/:id - Obtener vacación
nominaRouter.get("/vacaciones/:id", async (req, res) => {
  try {
    const result = await nominaService.getVacaciones(req.params.id);
    if (!result.cabecera) {
      return res.status(404).json({ error: "vacacion_not_found" });
    }
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/liquidacion/calcular - Calcular liquidación
nominaRouter.post("/liquidacion/calcular", async (req, res) => {
  const parsed = liquidacionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.calcularLiquidacion({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/liquidaciones - Listar liquidaciones
nominaRouter.get("/liquidaciones/list", async (req, res) => {
  try {
    const result = await nominaService.listLiquidaciones({
      cedula: req.query.cedula as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/liquidaciones/:id - Obtener liquidación
nominaRouter.get("/liquidaciones/:id", async (req, res) => {
  try {
    const result = await nominaService.getLiquidacion(req.params.id);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/constantes - Listar constantes
nominaRouter.get("/constantes", async (req, res) => {
  try {
    const result = await nominaService.listConstantes({
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/constantes - Guardar constante
nominaRouter.post("/constantes", async (req, res) => {
  const parsed = constanteSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await nominaService.saveConstante(parsed.data);
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ─── Batch Payroll Processing ────────────────────────────────

const batchDraftSchema = z.object({
  nomina: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  departamento: z.string().optional(),
});

const saveDraftLineSchema = z.object({
  lineId: z.number().int().positive(),
  quantity: z.number(),
  amount: z.number(),
  notes: z.string().max(500).optional(),
});

const batchAddLineSchema = z.object({
  batchId: z.number().int().positive(),
  employeeCode: z.string().min(1),
  conceptCode: z.string().min(1),
  conceptName: z.string().min(1),
  conceptType: z.enum(["ASIGNACION", "DEDUCCION", "BONO"]),
  quantity: z.number(),
  amount: z.number(),
});

const batchBulkUpdateSchema = z.object({
  batchId: z.number().int().positive(),
  conceptCode: z.string().min(1),
  conceptType: z.enum(["ASIGNACION", "DEDUCCION", "BONO"]),
  amount: z.number(),
  employeeCodes: z.array(z.string()).optional(),
});

// POST /v1/nomina/batch/draft - Generate batch draft
nominaRouter.post("/batch/draft", async (req, res) => {
  const parsed = batchDraftSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.generateBatchDraft({ ...parsed.data, codUsuario });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// PUT /v1/nomina/batch/line - Save draft line (autosave)
nominaRouter.put("/batch/line", async (req, res) => {
  const parsed = saveDraftLineSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.saveDraftLine({ ...parsed.data, codUsuario });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// POST /v1/nomina/batch/line - Add line to batch
nominaRouter.post("/batch/line", async (req, res) => {
  const parsed = batchAddLineSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.batchAddLine({ ...parsed.data, codUsuario });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// DELETE /v1/nomina/batch/line/:id - Remove line from batch
nominaRouter.delete("/batch/line/:id", async (req, res) => {
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.batchRemoveLine(Number(req.params.id), codUsuario);
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// GET /v1/nomina/batch - List batches
nominaRouter.get("/batch", async (req, res) => {
  try {
    const result = await nominaService.listBatches({
      nomina: req.query.nomina as string,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// GET /v1/nomina/batch/:id/summary - Get draft summary (pre-nómina)
nominaRouter.get("/batch/:id/summary", async (req, res) => {
  try {
    const result = await nominaService.getDraftSummary(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "batch_not_found" });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// GET /v1/nomina/batch/:id/grid - Get draft grid data
nominaRouter.get("/batch/:id/grid", async (req, res) => {
  try {
    const result = await nominaService.getDraftGrid({
      batchId: Number(req.params.id),
      search: req.query.search as string,
      department: req.query.department as string,
      onlyModified: req.query.onlyModified === "true",
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// GET /v1/nomina/batch/:id/employee/:code - Get employee lines
nominaRouter.get("/batch/:id/employee/:code", async (req, res) => {
  try {
    const result = await nominaService.getEmployeeLines(Number(req.params.id), req.params.code);
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// POST /v1/nomina/batch/:id/approve - Approve draft
nominaRouter.post("/batch/:id/approve", async (req, res) => {
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.approveDraft(Number(req.params.id), codUsuario);
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// POST /v1/nomina/batch/:id/process - Process approved batch
nominaRouter.post("/batch/:id/process", async (req, res) => {
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.processBatch(Number(req.params.id), codUsuario);
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// POST /v1/nomina/batch/bulk-update - Bulk update lines
nominaRouter.post("/batch/bulk-update", async (req, res) => {
  const parsed = batchBulkUpdateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await nominaService.batchBulkUpdate({ ...parsed.data, codUsuario });
    res.json(result);
  } catch (err: any) { res.status(500).json({ error: String(err) }); }
});

// ─── IMPORTANTE: Ruta wildcard al FINAL para no interceptar rutas específicas ───
// GET /v1/nomina/:nomina/:cedula - Obtener detalle de nómina
nominaRouter.get("/:nomina/:cedula", async (req, res) => {
  try {
    const result = await nominaService.getNomina(req.params.nomina, req.params.cedula);
    if (!result.cabecera) {
      return res.status(404).json({ error: "nomina_not_found" });
    }
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
