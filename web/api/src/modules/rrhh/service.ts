/**
 * Servicio de RRHH — Módulos complementarios de Recursos Humanos
 *
 * Utilidades, Fideicomiso, Caja de Ahorro, Obligaciones Legales,
 * Salud Ocupacional, Exámenes y Órdenes Médicas, Capacitación,
 * Comités de Seguridad.
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ─── Scope helpers ──────────────────────────────────────────

type DefaultScope = {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
};

let defaultScopeCache: DefaultScope | null = null;

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (defaultScopeCache && activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (defaultScopeCache) return defaultScopeCache;

  const rows = await callSp<{ companyId: number; branchId: number; systemUserId: number | null }>(
    "usp_HR_Payroll_ResolveScope"
  );

  const row = rows[0];
  defaultScopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };

  if (activeScope) {
    return {
      ...defaultScopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }

  return defaultScopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  const rows = await callSp<{ userId: number }>(
    "usp_HR_Payroll_ResolveUser",
    { UserCode: code || null }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getDefaultScope()).systemUserId;
}

function paginationParams(page?: number, limit?: number) {
  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(Math.max(1, Number(limit) || 50), 500);
  return { offset: (p - 1) * l, limit: l };
}

// ═══════════════════════════════════════════════════════════════
// UTILIDADES (Profit Sharing)
// ═══════════════════════════════════════════════════════════════

export async function generateProfitSharing(params: {
  year: number;
  totalProfit: number;
  daysBase?: number;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_ProfitSharing_Generate",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Year: params.year,
      TotalProfit: params.totalProfit,
      DaysBase: params.daysBase ?? 30,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Utilidades generadas"),
  };
}

export async function getProfitSharingSummary(id: number) {
  const rows = await callSp<any>("usp_HR_ProfitSharing_GetSummary", { ProfitSharingId: id });
  return rows[0] ?? null;
}

export async function approveProfitSharing(id: number, codUsuario?: string) {
  const userId = await resolveUserId(codUsuario);

  const { output } = await callSpOut(
    "usp_HR_ProfitSharing_Approve",
    {
      ProfitSharingId: id,
      ApprovedBy: codUsuario || "SYSTEM",
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Utilidades aprobadas"),
  };
}

export async function listProfitSharing(params: {
  year?: number;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_ProfitSharing_List",
    {
      CompanyId: scope.companyId,
      Year: params.year ?? null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// FIDEICOMISO (Social Benefits Trust)
// ═══════════════════════════════════════════════════════════════

export async function calculateTrustQuarter(params: {
  year: number;
  quarter: number;
  interestRate?: number;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Trust_CalculateQuarter",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Year: params.year,
      Quarter: params.quarter,
      InterestRate: params.interestRate ?? null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Trimestre calculado"),
  };
}

export async function getTrustBalance(employeeCode: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_Trust_GetEmployeeBalance", {
    CompanyId: scope.companyId,
    EmployeeCode: employeeCode,
  });
  return rows[0] ?? null;
}

export async function getTrustSummary(params: { year: number; quarter: number }) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_Trust_GetSummary", {
    CompanyId: scope.companyId,
    Year: params.year,
    Quarter: params.quarter,
  });
  return rows[0] ?? null;
}

export async function listTrust(params: {
  year?: number;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Trust_List",
    {
      CompanyId: scope.companyId,
      Year: params.year ?? null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// CAJA DE AHORRO (Savings Fund)
// ═══════════════════════════════════════════════════════════════

export async function enrollSavings(params: {
  employeeCode: string;
  contributionPct: number;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Savings_Enroll",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EmployeeCode: params.employeeCode,
      ContributionPct: params.contributionPct,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Empleado inscrito"),
  };
}

export async function processMonthlyContributions(codUsuario?: string) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Savings_ProcessMonthly",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      UserId: userId,
    },
    { Procesados: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    procesados: Number(output.Procesados ?? 0),
    message: String(output.Mensaje ?? "Aportes procesados"),
  };
}

export async function getSavingsBalance(employeeCode: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_Savings_GetBalance", {
    CompanyId: scope.companyId,
    EmployeeCode: employeeCode,
  });
  return rows[0] ?? null;
}

export async function requestLoan(params: {
  employeeCode: string;
  amount: number;
  installments: number;
  reason?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Savings_RequestLoan",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EmployeeCode: params.employeeCode,
      Amount: params.amount,
      Installments: params.installments,
      Reason: params.reason ?? null,
      UserId: userId,
    },
    { LoanId: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    loanId: Number(output.LoanId ?? 0),
    message: String(output.Mensaje ?? "Prestamo solicitado"),
  };
}

export async function approveLoan(params: {
  loanId: number;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Savings_ApproveLoan",
    {
      LoanId: params.loanId,
      ApprovedBy: params.codUsuario || "SYSTEM",
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Prestamo aprobado"),
  };
}

export async function processLoanPayment(params: {
  loanId: number;
  amount: number;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Savings_ProcessLoanPayment",
    {
      LoanId: params.loanId,
      Amount: params.amount,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Pago registrado"),
  };
}

export async function listSavings(params: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Savings_List",
    {
      CompanyId: scope.companyId,
      Search: params.search?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function listLoans(params: {
  employeeCode?: string;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Savings_LoanList",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.employeeCode?.trim() || null,
      Status: params.status?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// OBLIGACIONES LEGALES (Legal Obligations)
// ═══════════════════════════════════════════════════════════════

export async function listObligations(params: {
  countryCode?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Obligation_List",
    {
      CompanyId: scope.companyId,
      CountryCode: params.countryCode?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function saveObligation(params: {
  obligationId?: number;
  countryCode: string;
  name: string;
  description?: string;
  frequency: string;
  entityName?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Obligation_Save",
    {
      CompanyId: scope.companyId,
      ObligationId: params.obligationId ?? null,
      CountryCode: params.countryCode.trim().toUpperCase(),
      Name: params.name.trim(),
      Description: params.description?.trim() || null,
      Frequency: params.frequency.trim().toUpperCase(),
      EntityName: params.entityName?.trim() || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Obligacion guardada"),
  };
}

export async function getObligationsByCountry(countryCode: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_Obligation_GetByCountry", {
    CompanyId: scope.companyId,
    CountryCode: countryCode.trim().toUpperCase(),
  });
  return rows;
}

export async function enrollEmployeeObligation(params: {
  employeeId: number;
  obligationId: number;
  startDate: string;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_EmployeeObligation_Enroll",
    {
      EmployeeId: params.employeeId,
      ObligationId: params.obligationId,
      StartDate: params.startDate,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Empleado inscrito en obligacion"),
  };
}

export async function disenrollEmployeeObligation(enrollmentId: number, codUsuario?: string) {
  const userId = await resolveUserId(codUsuario);

  const { output } = await callSpOut(
    "usp_HR_EmployeeObligation_Disenroll",
    {
      EnrollmentId: enrollmentId,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Inscripcion eliminada"),
  };
}

export async function getEmployeeObligations(employeeId: number) {
  const rows = await callSp<any>("usp_HR_EmployeeObligation_GetByEmployee", {
    EmployeeId: employeeId,
  });
  return rows;
}

export async function generateFiling(params: {
  obligationId: number;
  periodStart: string;
  periodEnd: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Filing_Generate",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      ObligationId: params.obligationId,
      PeriodStart: params.periodStart,
      PeriodEnd: params.periodEnd,
      UserId: userId,
    },
    { FilingId: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    filingId: Number(output.FilingId ?? 0),
    message: String(output.Mensaje ?? "Declaracion generada"),
  };
}

export async function getFilingSummary(id: number) {
  const rows = await callSp<any>("usp_HR_Filing_GetSummary", { FilingId: id });
  return rows[0] ?? null;
}

export async function markFiled(params: {
  filingId: number;
  filedDate: string;
  referenceNumber?: string;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Filing_MarkFiled",
    {
      FilingId: params.filingId,
      FiledDate: params.filedDate,
      ReferenceNumber: params.referenceNumber?.trim() || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Declaracion marcada como presentada"),
  };
}

export async function listFilings(params: {
  obligationId?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Filing_List",
    {
      CompanyId: scope.companyId,
      ObligationId: params.obligationId ?? null,
      Status: params.status?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// SALUD OCUPACIONAL (Occupational Health)
// ═══════════════════════════════════════════════════════════════

export async function createOccHealthRecord(params: {
  employeeCode: string;
  recordType: string;
  incidentDate: string;
  description: string;
  severity?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_OccHealth_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EmployeeCode: params.employeeCode,
      RecordType: params.recordType.trim().toUpperCase(),
      IncidentDate: params.incidentDate,
      Description: params.description.trim(),
      Severity: params.severity?.trim().toUpperCase() || null,
      UserId: userId,
    },
    { RecordId: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    recordId: Number(output.RecordId ?? 0),
    message: String(output.Mensaje ?? "Registro creado"),
  };
}

export async function updateOccHealthRecord(params: {
  recordId: number;
  status?: string;
  followUpNotes?: string;
  closedDate?: string;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_OccHealth_Update",
    {
      RecordId: params.recordId,
      Status: params.status?.trim().toUpperCase() || null,
      FollowUpNotes: params.followUpNotes?.trim() || null,
      ClosedDate: params.closedDate || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Registro actualizado"),
  };
}

export async function listOccHealth(params: {
  employeeCode?: string;
  recordType?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_OccHealth_List",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.employeeCode?.trim() || null,
      RecordType: params.recordType?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getOccHealthRecord(id: number) {
  const rows = await callSp<any>("usp_HR_OccHealth_Get", { RecordId: id });
  return rows[0] ?? null;
}

// ═══════════════════════════════════════════════════════════════
// EXÁMENES MÉDICOS (Medical Exams)
// ═══════════════════════════════════════════════════════════════

export async function saveMedicalExam(params: {
  examId?: number;
  employeeCode: string;
  examType: string;
  examDate: string;
  result?: string;
  notes?: string;
  nextDueDate?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_MedExam_Save",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      ExamId: params.examId ?? null,
      EmployeeCode: params.employeeCode,
      ExamType: params.examType.trim().toUpperCase(),
      ExamDate: params.examDate,
      Result: params.result?.trim() || null,
      Notes: params.notes?.trim() || null,
      NextDueDate: params.nextDueDate || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Examen guardado"),
  };
}

export async function listMedicalExams(params: {
  employeeCode?: string;
  examType?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_MedExam_List",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.employeeCode?.trim() || null,
      ExamType: params.examType?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getPendingExams() {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_MedExam_GetPending", {
    CompanyId: scope.companyId,
  });
  return rows;
}

// ═══════════════════════════════════════════════════════════════
// ÓRDENES MÉDICAS (Medical Orders)
// ═══════════════════════════════════════════════════════════════

export async function createMedicalOrder(params: {
  employeeCode: string;
  orderType: string;
  diagnosis?: string;
  treatment?: string;
  startDate: string;
  endDate?: string;
  restDays?: number;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_MedOrder_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EmployeeCode: params.employeeCode,
      OrderType: params.orderType.trim().toUpperCase(),
      Diagnosis: params.diagnosis?.trim() || null,
      Treatment: params.treatment?.trim() || null,
      StartDate: params.startDate,
      EndDate: params.endDate || null,
      RestDays: params.restDays ?? null,
      UserId: userId,
    },
    { OrderId: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    orderId: Number(output.OrderId ?? 0),
    message: String(output.Mensaje ?? "Orden creada"),
  };
}

export async function approveMedicalOrder(params: {
  orderId: number;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_MedOrder_Approve",
    {
      OrderId: params.orderId,
      ApprovedBy: params.codUsuario || "SYSTEM",
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Orden aprobada"),
  };
}

export async function listMedicalOrders(params: {
  employeeCode?: string;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_MedOrder_List",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.employeeCode?.trim() || null,
      Status: params.status?.trim().toUpperCase() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// CAPACITACIÓN (Training)
// ═══════════════════════════════════════════════════════════════

export async function saveTraining(params: {
  trainingId?: number;
  name: string;
  description?: string;
  startDate: string;
  endDate?: string;
  instructor?: string;
  hours?: number;
  participants?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Training_Save",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      TrainingId: params.trainingId ?? null,
      Name: params.name.trim(),
      Description: params.description?.trim() || null,
      StartDate: params.startDate,
      EndDate: params.endDate || null,
      Instructor: params.instructor?.trim() || null,
      Hours: params.hours ?? null,
      Participants: params.participants?.trim() || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Capacitacion guardada"),
  };
}

export async function listTraining(params: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Training_List",
    {
      CompanyId: scope.companyId,
      Search: params.search?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getEmployeeCertifications(employeeCode: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>("usp_HR_Training_GetEmployeeCertifications", {
    CompanyId: scope.companyId,
    EmployeeCode: employeeCode,
  });
  return rows;
}

// ═══════════════════════════════════════════════════════════════
// COMITÉS DE SEGURIDAD (Safety Committees)
// ═══════════════════════════════════════════════════════════════

export async function saveCommittee(params: {
  committeeId?: number;
  name: string;
  committeeType?: string;
  startDate: string;
  endDate?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Committee_Save",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CommitteeId: params.committeeId ?? null,
      Name: params.name.trim(),
      CommitteeType: params.committeeType?.trim().toUpperCase() || null,
      StartDate: params.startDate,
      EndDate: params.endDate || null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Comite guardado"),
  };
}

export async function addCommitteeMember(params: {
  committeeId: number;
  employeeCode: string;
  role: string;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Committee_AddMember",
    {
      CommitteeId: params.committeeId,
      EmployeeCode: params.employeeCode,
      Role: params.role.trim(),
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Miembro agregado"),
  };
}

export async function removeCommitteeMember(params: {
  committeeId: number;
  memberId: number;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Committee_RemoveMember",
    {
      CommitteeId: params.committeeId,
      MemberId: params.memberId,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    message: String(output.Mensaje ?? "Miembro removido"),
  };
}

export async function recordMeeting(params: {
  committeeId: number;
  meetingDate: string;
  agenda?: string;
  minutes?: string;
  attendees?: string;
  codUsuario?: string;
}) {
  const userId = await resolveUserId(params.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Committee_RecordMeeting",
    {
      CommitteeId: params.committeeId,
      MeetingDate: params.meetingDate,
      Agenda: params.agenda?.trim() || null,
      Minutes: params.minutes?.trim() || null,
      Attendees: params.attendees?.trim() || null,
      UserId: userId,
    },
    { MeetingId: sql.Int, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) >= 0,
    meetingId: Number(output.MeetingId ?? 0),
    message: String(output.Mensaje ?? "Reunion registrada"),
  };
}

export async function listCommittees(params: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const { offset, limit } = paginationParams(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Committee_List",
    {
      CompanyId: scope.companyId,
      Search: params.search?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getCommitteeMeetings(committeeId: number) {
  const rows = await callSp<any>("usp_HR_Committee_GetMeetings", {
    CommitteeId: committeeId,
  });
  return rows;
}
