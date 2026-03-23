/**
 * Rutas de RRHH — Módulos complementarios de Recursos Humanos
 *
 * Montado en /v1/rrhh
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as svc from "./service.js";
import { emitRRHHAccountingEntry } from "./rrhh-contabilidad.service.js";

/** Map PascalCase API row → camelCase frontend row using explicit field map */
function mapRow(row: any, fieldMap: Record<string, string>): any {
  const out: any = {};
  for (const [camel, pascal] of Object.entries(fieldMap)) {
    out[camel] = row[pascal] ?? null;
  }
  return out;
}
function mapRows(rows: any[], fieldMap: Record<string, string>): any[] {
  return (rows || []).map(r => mapRow(r, fieldMap));
}

// ─── Field maps: camelCase (frontend) → PascalCase (PG) ─────────────────
const occHealthFields: Record<string, string> = {
  id: "OccupationalHealthId", date: "OccurrenceDate", type: "RecordType",
  employeeCode: "EmployeeCode", employeeName: "EmployeeName",
  severity: "Severity", daysLost: "DaysLost", status: "Status",
  description: "Description", correctiveActions: "CorrectiveAction",
  location: "Location", rootCause: "RootCause", notes: "Notes",
};
const medExamFields: Record<string, string> = {
  id: "MedicalExamId", employeeCode: "EmployeeCode", employeeName: "EmployeeName",
  type: "ExamType", examDate: "ExamDate", nextDueDate: "NextDueDate",
  result: "Result", provider: "ClinicName", notes: "Notes",
};
const medOrderFields: Record<string, string> = {
  id: "MedicalOrderId", employeeCode: "EmployeeCode", employeeName: "EmployeeName",
  type: "OrderType", date: "OrderDate", diagnosis: "Diagnosis",
  cost: "EstimatedCost", status: "Status", description: "Prescriptions",
  physicianName: "PhysicianName", notes: "Notes",
};
const trainingFields: Record<string, string> = {
  id: "TrainingRecordId", employeeCode: "EmployeeCode", employeeName: "EmployeeName",
  title: "Title", type: "TrainingType", provider: "Provider",
  hours: "DurationHours", startDate: "StartDate", endDate: "EndDate",
  result: "Result", regulatory: "IsRegulatory", certificateUrl: "CertificateUrl",
  notes: "Notes",
};
const committeeFields: Record<string, string> = {
  id: "SafetyCommitteeId", name: "CommitteeName", type: "CountryCode",
  startDate: "FormationDate", endDate: "MeetingFrequency",
  memberCount: "ActiveMemberCount", active: "IsActive",
  totalMeetings: "TotalMeetings",
};
const obligationFields: Record<string, string> = {
  id: "LegalObligationId", countryCode: "CountryCode", code: "Code",
  name: "Name", employeeRate: "EmployeeRate", employerRate: "EmployerRate",
  frequency: "FilingFrequency", entity: "InstitutionName",
  description: "Notes", isActive: "IsActive",
};
const savingsFields: Record<string, string> = {
  id: "SavingsFundId", employeeCode: "EmployeeCode", employeeName: "EmployeeName",
  contributionPct: "EmployeeContribution", employerMatchPct: "EmployerMatch",
  balance: "CurrentBalance", status: "Status", enrollmentDate: "EnrollmentDate",
};

const router = Router();

// ─── Helper ────────────────────────────────────────────────
function codUsuario(req: Request): string {
  return (req as any).user?.code ?? (req as any).user?.username ?? "API";
}

// ═══════════════════════════════════════════════════════════════
// UTILIDADES (Profit Sharing)
// ═══════════════════════════════════════════════════════════════

const generateProfitSharingSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  totalProfit: z.number(),
  daysBase: z.number().int().positive().optional(),
});

// GET /v1/rrhh/utilidades
router.get("/utilidades", async (req: Request, res: Response) => {
  try {
    const result = await svc.listProfitSharing({
      year: req.query.year ? parseInt(req.query.year as string) : undefined,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/utilidades/generate
router.post("/utilidades/generate", async (req: Request, res: Response) => {
  const parsed = generateProfitSharingSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.generateProfitSharing({ ...parsed.data, codUsuario: codUsuario(req) });

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "UTILIDADES",
            referencia: `UTIL-${parsed.data.year}`,
            concepto: `Utilidades año ${parsed.data.year}`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: parsed.data.totalProfit,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.status(result.success ? 200 : 400).json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/utilidades/:id/summary
router.get("/utilidades/:id/summary", async (req: Request, res: Response) => {
  try {
    const result = await svc.getProfitSharingSummary(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/utilidades/:id/approve
router.post("/utilidades/:id/approve", async (req: Request, res: Response) => {
  try {
    const result = await svc.approveProfitSharing(Number(req.params.id), codUsuario(req));
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// FIDEICOMISO (Social Benefits Trust)
// ═══════════════════════════════════════════════════════════════

const calculateTrustSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  quarter: z.number().int().min(1).max(4),
  interestRate: z.number().optional(),
});

// GET /v1/rrhh/fideicomiso
router.get("/fideicomiso", async (req: Request, res: Response) => {
  try {
    const result = await svc.listTrust({
      year: req.query.year ? parseInt(req.query.year as string) : undefined,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/fideicomiso/calculate
router.post("/fideicomiso/calculate", async (req: Request, res: Response) => {
  const parsed = calculateTrustSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.calculateTrustQuarter({ ...parsed.data, codUsuario: codUsuario(req) });

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "FIDEICOMISO",
            referencia: `FID-${parsed.data.year}-Q${parsed.data.quarter}`,
            concepto: `Fideicomiso ${parsed.data.year} Q${parsed.data.quarter}`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: (result as any).totalAmount ?? 0,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.status(result.success ? 200 : 400).json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/fideicomiso/balance/:employeeCode
router.get("/fideicomiso/balance/:employeeCode", async (req: Request, res: Response) => {
  try {
    const result = await svc.getTrustBalance(req.params.employeeCode);
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/fideicomiso/summary
router.get("/fideicomiso/summary", async (req: Request, res: Response) => {
  try {
    const year = parseInt(req.query.year as string);
    const quarter = parseInt(req.query.quarter as string);
    if (isNaN(year) || isNaN(quarter)) return res.status(400).json({ error: "year and quarter required" });
    const result = await svc.getTrustSummary({ year, quarter });
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// CAJA DE AHORRO (Savings Fund)
// ═══════════════════════════════════════════════════════════════

const enrollSavingsSchema = z.object({
  employeeCode: z.string().min(1),
  contributionPct: z.number().min(0).max(100),
});

const requestLoanSchema = z.object({
  employeeCode: z.string().min(1),
  amount: z.number().positive(),
  installments: z.number().int().positive(),
  reason: z.string().max(500).optional(),
});

const loanPaymentSchema = z.object({
  amount: z.number().positive(),
});

// GET /v1/rrhh/caja-ahorro
router.get("/caja-ahorro", async (req: Request, res: Response) => {
  try {
    const result = await svc.listSavings({
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, savingsFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/caja-ahorro/enroll
router.post("/caja-ahorro/enroll", async (req: Request, res: Response) => {
  const parsed = enrollSavingsSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.enrollSavings({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/caja-ahorro/balance/:employeeCode
router.get("/caja-ahorro/balance/:employeeCode", async (req: Request, res: Response) => {
  try {
    const result = await svc.getSavingsBalance(req.params.employeeCode);
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/caja-ahorro/loans
router.get("/caja-ahorro/loans", async (req: Request, res: Response) => {
  try {
    const result = await svc.listLoans({
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

// POST /v1/rrhh/caja-ahorro/loans
router.post("/caja-ahorro/loans", async (req: Request, res: Response) => {
  const parsed = requestLoanSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.requestLoan({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/caja-ahorro/loans/:loanId/approve
router.post("/caja-ahorro/loans/:loanId/approve", async (req: Request, res: Response) => {
  try {
    const result = await svc.approveLoan({
      loanId: Number(req.params.loanId),
      codUsuario: codUsuario(req),
    });

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "PRESTAMO_APROBADO",
            referencia: `PREST-${req.params.loanId}`,
            concepto: `Préstamo caja ahorro #${req.params.loanId} aprobado`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: (result as any).amount ?? 0,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/caja-ahorro/loans/:loanId/payment
router.post("/caja-ahorro/loans/:loanId/payment", async (req: Request, res: Response) => {
  const parsed = loanPaymentSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.processLoanPayment({
      loanId: Number(req.params.loanId),
      amount: parsed.data.amount,
      codUsuario: codUsuario(req),
    });

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "PRESTAMO_PAGO",
            referencia: `PREST-PAG-${req.params.loanId}`,
            concepto: `Pago préstamo #${req.params.loanId}`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: parsed.data.amount,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/caja-ahorro/process-monthly
router.post("/caja-ahorro/process-monthly", async (req: Request, res: Response) => {
  try {
    const result = await svc.processMonthlyContributions(codUsuario(req));

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "APORTE_MENSUAL",
            referencia: `APORTE-${new Date().toISOString().slice(0, 7)}`,
            concepto: `Aportes mensuales caja de ahorro`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: (result as any).totalAmount ?? 0,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// OBLIGACIONES LEGALES (Legal Obligations)
// ═══════════════════════════════════════════════════════════════

const obligationSchema = z.object({
  obligationId: z.number().int().optional(),
  countryCode: z.string().min(2).max(5),
  name: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  frequency: z.string().min(1).max(50),
  entityName: z.string().max(200).optional(),
});

const enrollObligationSchema = z.object({
  employeeId: z.number().int().positive(),
  obligationId: z.number().int().positive(),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

const generateFilingSchema = z.object({
  obligationId: z.number().int().positive(),
  periodStart: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  periodEnd: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

const markFiledSchema = z.object({
  filedDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  referenceNumber: z.string().max(100).optional(),
});

// GET /v1/rrhh/obligaciones
router.get("/obligaciones", async (req: Request, res: Response) => {
  try {
    const result = await svc.listObligations({
      countryCode: req.query.countryCode as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, obligationFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/obligaciones
router.post("/obligaciones", async (req: Request, res: Response) => {
  const parsed = obligationSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.saveObligation({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/obligaciones/country/:code
router.get("/obligaciones/country/:code", async (req: Request, res: Response) => {
  try {
    const result = await svc.getObligationsByCountry(req.params.code);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/obligaciones/enroll
router.post("/obligaciones/enroll", async (req: Request, res: Response) => {
  const parsed = enrollObligationSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.enrollEmployeeObligation({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/obligaciones/employee/:employeeId
router.get("/obligaciones/employee/:employeeId", async (req: Request, res: Response) => {
  try {
    const employeeId = Number(req.params.employeeId);
    if (!Number.isFinite(employeeId)) return res.status(400).json({ error: "employeeId must be a valid number" });
    const result = await svc.getEmployeeObligations(employeeId);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/obligaciones/filings
router.get("/obligaciones/filings", async (req: Request, res: Response) => {
  try {
    const result = await svc.listFilings({
      obligationId: req.query.obligationId ? parseInt(req.query.obligationId as string) : undefined,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/obligaciones/filings/generate
router.post("/obligaciones/filings/generate", async (req: Request, res: Response) => {
  const parsed = generateFilingSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.generateFiling({ ...parsed.data, codUsuario: codUsuario(req) });

    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (result.success) {
      try {
        contabilidad = await emitRRHHAccountingEntry(
          {
            tipo: "OBLIGACION_LEGAL",
            referencia: `OBLIG-${parsed.data.obligationId}-${parsed.data.periodStart}`,
            concepto: `Obligación legal #${parsed.data.obligationId} período ${parsed.data.periodStart}`,
            fecha: new Date().toISOString().slice(0, 10),
            monto: (result as any).totalAmount ?? 0,
          },
          codUsuario(req)
        );
      } catch { /* never blocks */ }
    }

    res.status(result.success ? 201 : 400).json({ ...result, contabilidad });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/obligaciones/filings/:id
router.get("/obligaciones/filings/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.getFilingSummary(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/obligaciones/filings/:filingId/mark-filed
router.post("/obligaciones/filings/:filingId/mark-filed", async (req: Request, res: Response) => {
  const parsed = markFiledSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.markFiled({
      filingId: Number(req.params.filingId),
      ...parsed.data,
      codUsuario: codUsuario(req),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// SALUD OCUPACIONAL (Occupational Health)
// ═══════════════════════════════════════════════════════════════

const createOccHealthSchema = z.object({
  employeeCode: z.string().min(1),
  recordType: z.string().min(1).max(50),
  incidentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  description: z.string().min(1).max(2000),
  severity: z.string().max(50).optional(),
});

const updateOccHealthSchema = z.object({
  status: z.string().max(50).optional(),
  followUpNotes: z.string().max(2000).optional(),
  closedDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

// GET /v1/rrhh/salud-ocupacional
router.get("/salud-ocupacional", async (req: Request, res: Response) => {
  try {
    const result = await svc.listOccHealth({
      employeeCode: req.query.employeeCode as string,
      recordType: req.query.recordType as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, occHealthFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/salud-ocupacional
router.post("/salud-ocupacional", async (req: Request, res: Response) => {
  const parsed = createOccHealthSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createOccHealthRecord({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/salud-ocupacional/:id
router.get("/salud-ocupacional/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.getOccHealthRecord(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(mapRow(result, occHealthFields));
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/rrhh/salud-ocupacional/:id
router.put("/salud-ocupacional/:id", async (req: Request, res: Response) => {
  const parsed = updateOccHealthSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.updateOccHealthRecord({
      recordId: Number(req.params.id),
      ...parsed.data,
      codUsuario: codUsuario(req),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// EXÁMENES MÉDICOS (Medical Exams)
// ═══════════════════════════════════════════════════════════════

const medicalExamSchema = z.object({
  examId: z.number().int().optional(),
  employeeCode: z.string().min(1),
  examType: z.string().min(1).max(50),
  examDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  result: z.string().max(500).optional(),
  notes: z.string().max(2000).optional(),
  nextDueDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

// GET /v1/rrhh/examenes-medicos
router.get("/examenes-medicos", async (req: Request, res: Response) => {
  try {
    const result = await svc.listMedicalExams({
      employeeCode: req.query.employeeCode as string,
      examType: req.query.examType as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, medExamFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/examenes-medicos
router.post("/examenes-medicos", async (req: Request, res: Response) => {
  const parsed = medicalExamSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.saveMedicalExam({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/examenes-medicos/pending
router.get("/examenes-medicos/pending", async (_req: Request, res: Response) => {
  try {
    const result = await svc.getPendingExams();
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// ÓRDENES MÉDICAS (Medical Orders)
// ═══════════════════════════════════════════════════════════════

const medicalOrderSchema = z.object({
  employeeCode: z.string().min(1),
  orderType: z.string().min(1).max(50),
  diagnosis: z.string().max(1000).optional(),
  treatment: z.string().max(2000).optional(),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  restDays: z.number().int().min(0).optional(),
});

// GET /v1/rrhh/ordenes-medicas
router.get("/ordenes-medicas", async (req: Request, res: Response) => {
  try {
    const result = await svc.listMedicalOrders({
      employeeCode: req.query.employeeCode as string,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, medOrderFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/ordenes-medicas
router.post("/ordenes-medicas", async (req: Request, res: Response) => {
  const parsed = medicalOrderSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createMedicalOrder({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/ordenes-medicas/:orderId/approve
router.post("/ordenes-medicas/:orderId/approve", async (req: Request, res: Response) => {
  try {
    const result = await svc.approveMedicalOrder({
      orderId: Number(req.params.orderId),
      codUsuario: codUsuario(req),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// CAPACITACIÓN (Training)
// ═══════════════════════════════════════════════════════════════

const trainingSchema = z.object({
  trainingId: z.number().int().optional(),
  name: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  instructor: z.string().max(200).optional(),
  hours: z.number().int().positive().optional(),
  participants: z.string().max(4000).optional(),
});

// GET /v1/rrhh/capacitacion
router.get("/capacitacion", async (req: Request, res: Response) => {
  try {
    const result = await svc.listTraining({
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, trainingFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/capacitacion
router.post("/capacitacion", async (req: Request, res: Response) => {
  const parsed = trainingSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.saveTraining({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/capacitacion/certifications/:employeeCode
router.get("/capacitacion/certifications/:employeeCode", async (req: Request, res: Response) => {
  try {
    const result = await svc.getEmployeeCertifications(req.params.employeeCode);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// COMITÉS DE SEGURIDAD (Safety Committees)
// ═══════════════════════════════════════════════════════════════

const committeeSchema = z.object({
  committeeId: z.number().int().optional(),
  name: z.string().min(1).max(200),
  committeeType: z.string().max(50).optional(),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

const committeeMemberSchema = z.object({
  employeeCode: z.string().min(1),
  role: z.string().min(1).max(100),
});

const meetingSchema = z.object({
  meetingDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  agenda: z.string().max(4000).optional(),
  minutes: z.string().max(4000).optional(),
  attendees: z.string().max(4000).optional(),
});

// GET /v1/rrhh/comites
router.get("/comites", async (req: Request, res: Response) => {
  try {
    const result = await svc.listCommittees({
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json({ ...result, rows: mapRows(result.rows, committeeFields) });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/comites
router.post("/comites", async (req: Request, res: Response) => {
  const parsed = committeeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.saveCommittee({ ...parsed.data, codUsuario: codUsuario(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/comites/:committeeId/members
router.post("/comites/:committeeId/members", async (req: Request, res: Response) => {
  const parsed = committeeMemberSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.addCommitteeMember({
      committeeId: Number(req.params.committeeId),
      ...parsed.data,
      codUsuario: codUsuario(req),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// DELETE /v1/rrhh/comites/:committeeId/members/:memberId
router.delete("/comites/:committeeId/members/:memberId", async (req: Request, res: Response) => {
  try {
    const result = await svc.removeCommitteeMember({
      committeeId: Number(req.params.committeeId),
      memberId: Number(req.params.memberId),
      codUsuario: codUsuario(req),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/rrhh/comites/:committeeId/meetings
router.post("/comites/:committeeId/meetings", async (req: Request, res: Response) => {
  const parsed = meetingSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.recordMeeting({
      committeeId: Number(req.params.committeeId),
      ...parsed.data,
      codUsuario: codUsuario(req),
    });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/rrhh/comites/:committeeId/meetings
router.get("/comites/:committeeId/meetings", async (req: Request, res: Response) => {
  try {
    const committeeId = Number(req.params.committeeId);
    if (!Number.isFinite(committeeId)) return res.status(400).json({ error: "committeeId must be a valid number" });
    const result = await svc.getCommitteeMeetings(committeeId);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

export default router;
