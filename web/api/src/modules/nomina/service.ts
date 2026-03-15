
import { callSp, callSpOut, sql } from "../../db/query.js";
import { arrayToXml } from "../../utils/xml.js";
import { getActiveScope } from "../_shared/scope.js";

export interface ConceptoNomina {
  codigo: string;
  codigoNomina: string;
  nombre: string;
  formula?: string;
  sobre?: string;
  clase?: string;
  tipo?: "ASIGNACION" | "DEDUCCION" | "BONO";
  uso?: string;
  bonificable?: string;
  esAntiguedad?: string;
  cuentaContable?: string;
  aplica?: string;
  valorDefecto?: number;
}

export interface NominaCabecera {
  nomina: string;
  cedula: string;
  nombreEmpleado?: string;
  cargo?: string;
  fechaProceso?: Date;
  fechaInicio?: Date;
  fechaHasta?: Date;
  totalAsignaciones?: number;
  totalDeducciones?: number;
  totalNeto?: number;
  cerrada?: boolean;
  tipoNomina?: string;
}

export interface NominaDetalle {
  coConcepto?: string;
  nombreConcepto?: string;
  tipoConcepto?: string;
  cantidad?: number;
  monto?: number;
  total?: number;
  descripcion?: string;
  cuentaContable?: string;
}

export interface Vacacion {
  vacacion: string;
  cedula: string;
  nombreEmpleado?: string;
  inicio?: Date;
  hasta?: Date;
  reintegro?: Date;
  fechaCalculo?: Date;
  total?: number;
  totalCalculado?: number;
}

type DefaultScope = {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
};

type EmployeeRef = {
  employeeId: number;
  employeeCode: string;
  employeeName: string;
  hireDate: Date | null;
};

type ProcessOptions = {
  conventionCode?: string;
  calculationType?: string;
  soloConceptosLegales?: boolean;
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

function toFlag(value: unknown, defaultValue: boolean) {
  const text = String(value ?? "").trim().toUpperCase();
  if (!text) return defaultValue;
  return ["1", "S", "SI", "Y", "YES", "TRUE"].includes(text);
}

function normalizeDate(input?: string) {
  if (!input) return null;
  const parsed = new Date(input);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function dayDiffInclusive(from: Date, to: Date) {
  const a = new Date(from);
  const b = new Date(to);
  a.setHours(0, 0, 0, 0);
  b.setHours(0, 0, 0, 0);
  const ms = b.getTime() - a.getTime();
  return Math.max(1, Math.floor(ms / 86400000) + 1);
}

async function getConstantValue(code: string, fallback = 0): Promise<number> {
  const scope = await getDefaultScope();
  const rows = await callSp<{ value: number }>(
    "usp_HR_Payroll_GetConstant",
    { CompanyId: scope.companyId, Code: code }
  );

  const value = Number(rows[0]?.value ?? fallback);
  return Number.isFinite(value) ? value : fallback;
}

async function ensurePayrollType(companyId: number, payrollCode: string, userId: number | null) {
  const code = String(payrollCode ?? "").trim().toUpperCase();
  if (!code) return;

  await callSp("usp_HR_Payroll_EnsureType", {
    CompanyId: companyId,
    PayrollCode: code,
    UserId: userId,
  });
}

async function ensureEmployee(cedula: string, userId: number | null): Promise<EmployeeRef> {
  const scope = await getDefaultScope();
  const document = String(cedula ?? "").trim();
  if (!document) throw new Error("cedula obligatoria");

  const rows = await callSp<EmployeeRef>(
    "usp_HR_Payroll_EnsureEmployee",
    {
      CompanyId: scope.companyId,
      Document: document,
      UserId: userId,
    }
  );

  const row = rows[0];
  return {
    employeeId: Number(row?.employeeId ?? 0),
    employeeCode: String(row?.employeeCode ?? document),
    employeeName: String(row?.employeeName ?? `Empleado ${document}`),
    hireDate: row?.hireDate ? new Date(row.hireDate) : new Date(),
  };
}

export async function listConceptos(params: {
  coNomina?: string;
  tipo?: string;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<ConceptoNomina>(
    "usp_HR_Payroll_ListConcepts",
    {
      CompanyId: scope.companyId,
      PayrollCode: params.coNomina?.trim().toUpperCase() || null,
      ConceptType: params.tipo?.trim().toUpperCase() || null,
      Search: params.search?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function saveConcepto(data: Partial<ConceptoNomina>) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const payrollCode = String(data.codigoNomina ?? "GENERAL").trim().toUpperCase();
  const conceptCode = String(data.codigo ?? "").trim().toUpperCase();
  const conceptName = String(data.nombre ?? "").trim();

  if (!conceptCode || !conceptName) {
    return { success: false, message: "codigo y nombre son obligatorios" };
  }

  await ensurePayrollType(scope.companyId, payrollCode, userId);

  const { output } = await callSpOut(
    "usp_HR_Payroll_SaveConcept",
    {
      CompanyId: scope.companyId,
      PayrollCode: payrollCode,
      ConceptCode: conceptCode,
      ConceptName: conceptName,
      Formula: data.formula ?? null,
      BaseExpression: data.sobre ?? null,
      ConceptClass: data.clase ?? null,
      ConceptType: String(data.tipo ?? "ASIGNACION").toUpperCase(),
      UsageType: data.uso ?? null,
      IsBonifiable: toFlag(data.bonificable, false),
      IsSeniority: toFlag(data.esAntiguedad, false),
      AccountingAccountCode: data.cuentaContable ?? null,
      AppliesFlag: toFlag(data.aplica, true),
      DefaultValue: Number(data.valorDefecto ?? 0),
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: true,
    message: String(output.Mensaje ?? "Concepto guardado"),
  };
}

async function loadConceptsForRun(
  payrollCode: string,
  conceptTypeFilter?: string,
  options?: ProcessOptions
) {
  const scope = await getDefaultScope();

  return callSp<{
    conceptCode: string;
    conceptName: string;
    conceptType: string;
    defaultValue: number;
    formula: string | null;
    accountingAccountCode: string | null;
  }>(
    "usp_HR_Payroll_LoadConceptsForRun",
    {
      CompanyId: scope.companyId,
      PayrollCode: payrollCode,
      ConceptType: conceptTypeFilter?.trim().toUpperCase() || null,
      ConventionCode: options?.conventionCode?.trim().toUpperCase() || null,
      CalculationType: options?.calculationType?.trim().toUpperCase() || null,
      SoloLegales: options?.soloConceptosLegales ? 1 : 0,
    }
  );
}

async function upsertRunWithLines(input: {
  payrollCode: string;
  fromDate: Date;
  toDate: Date;
  employee: EmployeeRef;
  userId: number | null;
  lines: Array<{
    code: string;
    name: string;
    type: string;
    quantity: number;
    amount: number;
    total: number;
    description: string | null;
    account: string | null;
  }>;
  totalAsignaciones: number;
  totalDeducciones: number;
  totalNeto: number;
  calculationType?: string;
}) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "usp_HR_Payroll_UpsertRun",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PayrollCode: input.payrollCode,
      EmployeeId: input.employee.employeeId,
      EmployeeCode: input.employee.employeeCode,
      EmployeeName: input.employee.employeeName,
      FromDate: input.fromDate,
      ToDate: input.toDate,
      TotalAssignments: input.totalAsignaciones,
      TotalDeductions: input.totalDeducciones,
      NetTotal: input.totalNeto,
      PayrollTypeName: input.calculationType ?? null,
      UserId: input.userId,
      LinesXml: arrayToXml(input.lines),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? -99);
  if (resultado < 0) {
    throw new Error(String(output.Mensaje ?? "Error en upsert run"));
  }
}

export async function procesarNominaEmpleado(
  payload: {
    nomina: string;
    cedula: string;
    fechaInicio: string;
    fechaHasta: string;
    codUsuario?: string;
  },
  options?: ProcessOptions
) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(payload.codUsuario);
  const payrollCode = String(payload.nomina ?? "").trim().toUpperCase();
  const fromDate = normalizeDate(payload.fechaInicio);
  const toDate = normalizeDate(payload.fechaHasta);

  if (!payrollCode || !fromDate || !toDate) {
    return { success: false, message: "Datos invalidos" };
  }

  await ensurePayrollType(scope.companyId, payrollCode, userId);

  const employee = await ensureEmployee(payload.cedula, userId);
  const concepts = await loadConceptsForRun(payrollCode, undefined, options);

  if (concepts.length === 0) {
    return { success: false, message: "No hay conceptos configurados para la nomina" };
  }

  const lines = concepts.map((concept) => {
    const amount = Number(concept.defaultValue ?? 0);
    const quantity = 1;
    const total = Number((quantity * amount).toFixed(2));
    return {
      code: String(concept.conceptCode),
      name: String(concept.conceptName),
      type: String(concept.conceptType).toUpperCase(),
      quantity,
      amount,
      total,
      description: concept.formula ?? null,
      account: concept.accountingAccountCode ?? null,
    };
  });

  const totalAsignaciones = Number(
    lines
      .filter((line) => line.type !== "DEDUCCION")
      .reduce((acc, line) => acc + line.total, 0)
      .toFixed(2)
  );
  const totalDeducciones = Number(
    lines
      .filter((line) => line.type === "DEDUCCION")
      .reduce((acc, line) => acc + line.total, 0)
      .toFixed(2)
  );
  const totalNeto = Number((totalAsignaciones - totalDeducciones).toFixed(2));

  await upsertRunWithLines({
    payrollCode,
    fromDate,
    toDate,
    employee,
    userId,
    lines,
    totalAsignaciones,
    totalDeducciones,
    totalNeto,
    calculationType: options?.calculationType,
  });

  return {
    success: true,
    message: `Nomina procesada. Asignaciones: ${totalAsignaciones.toFixed(2)} Deducciones: ${totalDeducciones.toFixed(2)} Neto: ${totalNeto.toFixed(2)}`,
    asignaciones: totalAsignaciones,
    deducciones: totalDeducciones,
    neto: totalNeto,
  };
}

export async function procesarNominaCompleta(payload: {
  nomina: string;
  fechaInicio: string;
  fechaHasta: string;
  soloActivos?: boolean;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();

  const employees = await callSp<{ employeeCode: string }>(
    "usp_HR_Payroll_ListActiveEmployees",
    {
      CompanyId: scope.companyId,
      SoloActivos: (payload.soloActivos ?? true) ? 1 : 0,
    }
  );

  let procesados = 0;
  let errores = 0;

  for (const employee of employees) {
    const result = await procesarNominaEmpleado(
      {
        nomina: payload.nomina,
        cedula: String(employee.employeeCode),
        fechaInicio: payload.fechaInicio,
        fechaHasta: payload.fechaHasta,
        codUsuario: payload.codUsuario,
      },
      undefined
    );

    if (result.success) procesados += 1;
    else errores += 1;
  }

  return {
    procesados,
    errores,
    message: `Nomina procesada para ${procesados} empleados`,
  };
}

export async function listNominas(params: {
  nomina?: string;
  cedula?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  soloAbiertas?: boolean;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const fromDate = params.fechaDesde ? normalizeDate(params.fechaDesde) : null;
  const toDate = params.fechaHasta ? normalizeDate(params.fechaHasta) : null;

  const { rows, output } = await callSpOut<NominaCabecera>(
    "usp_HR_Payroll_ListRuns",
    {
      CompanyId: scope.companyId,
      PayrollCode: params.nomina?.trim().toUpperCase() || null,
      EmployeeCode: params.cedula?.trim() || null,
      FromDate: fromDate,
      ToDate: toDate,
      SoloAbiertas: params.soloAbiertas ? 1 : 0,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function getNomina(nomina: string, cedula: string) {
  const scope = await getDefaultScope();
  const payrollCode = String(nomina ?? "").trim().toUpperCase();
  const employeeCode = String(cedula ?? "").trim();

  const cabeceraRows = await callSp<NominaCabecera & { runId: number }>(
    "usp_HR_Payroll_GetRunHeader",
    {
      CompanyId: scope.companyId,
      PayrollCode: payrollCode,
      EmployeeCode: employeeCode,
    }
  );

  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) {
    return { cabecera: null, detalle: [] as NominaDetalle[] };
  }

  const detalle = await callSp<NominaDetalle>(
    "usp_HR_Payroll_GetRunLines",
    { RunId: (cabecera as any).runId }
  );

  return {
    cabecera: {
      nomina: cabecera.nomina,
      cedula: cabecera.cedula,
      nombreEmpleado: cabecera.nombreEmpleado,
      cargo: cabecera.cargo,
      fechaProceso: cabecera.fechaProceso,
      fechaInicio: cabecera.fechaInicio,
      fechaHasta: cabecera.fechaHasta,
      totalAsignaciones: cabecera.totalAsignaciones,
      totalDeducciones: cabecera.totalDeducciones,
      totalNeto: cabecera.totalNeto,
      cerrada: cabecera.cerrada,
      tipoNomina: cabecera.tipoNomina,
    },
    detalle,
  };
}

export async function cerrarNomina(payload: {
  nomina: string;
  cedula?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(payload.codUsuario);

  const { output } = await callSpOut(
    "usp_HR_Payroll_CloseRun",
    {
      CompanyId: scope.companyId,
      PayrollCode: String(payload.nomina ?? "").trim().toUpperCase(),
      EmployeeCode: payload.cedula ? String(payload.cedula).trim() : null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const affected = Number(output.Resultado ?? 0);
  return {
    success: affected > 0,
    message: String(output.Mensaje ?? (affected > 0 ? "Nomina cerrada" : "No se encontraron registros abiertos")),
  };
}

export async function procesarVacaciones(payload: {
  vacacionId: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  fechaReintegro?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(payload.codUsuario);
  const employee = await ensureEmployee(payload.cedula, userId);

  const startDate = normalizeDate(payload.fechaInicio);
  const endDate = normalizeDate(payload.fechaHasta);
  const reintegrationDate = normalizeDate(payload.fechaReintegro);
  if (!startDate || !endDate) {
    return { success: false, message: "Fechas invalidas" };
  }

  const dailySalary = await getConstantValue("SALARIO_DIARIO", 0);
  const days = dayDiffInclusive(startDate, endDate);
  const total = Number((dailySalary * days).toFixed(2));

  await callSpOut(
    "usp_HR_Payroll_UpsertVacation",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      VacationCode: String(payload.vacacionId ?? "").trim(),
      EmployeeId: employee.employeeId,
      EmployeeCode: employee.employeeCode,
      EmployeeName: employee.employeeName,
      StartDate: startDate,
      EndDate: endDate,
      ReintegrationDate: reintegrationDate,
      TotalAmount: total,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: true,
    message: `Vacaciones procesadas por ${days} dias`,
  };
}

export async function listVacaciones(params: {
  cedula?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<Vacacion>(
    "usp_HR_Payroll_ListVacations",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.cedula?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function getVacaciones(vacacionId: string) {
  const scope = await getDefaultScope();
  const code = String(vacacionId ?? "").trim();

  const cabeceraRows = await callSp<any>(
    "usp_HR_Payroll_GetVacationHeader",
    {
      CompanyId: scope.companyId,
      VacationCode: code,
    }
  );

  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) return { cabecera: null, detalle: [] };

  const detalle = await callSp<any>(
    "usp_HR_Payroll_GetVacationLines",
    { VacationProcessId: Number(cabecera.id) }
  );

  return { cabecera, detalle };
}

export async function calcularLiquidacion(payload: {
  liquidacionId: string;
  cedula: string;
  fechaRetiro: string;
  causaRetiro?: string;
  codUsuario?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(payload.codUsuario);
  const employee = await ensureEmployee(payload.cedula, userId);
  const retiro = normalizeDate(payload.fechaRetiro);
  if (!retiro) {
    return { success: false, message: "Fecha de retiro invalida" };
  }

  const hireDate = employee.hireDate ?? retiro;
  const serviceDays = Math.max(0, dayDiffInclusive(hireDate, retiro) - 1);
  const serviceYears = serviceDays / 365;
  const salarioDiario = await getConstantValue("SALARIO_DIARIO", 0);

  const prestaciones = Number((serviceYears * salarioDiario * 30).toFixed(2));
  const vacPendientes = Number((salarioDiario * 15).toFixed(2));
  const bonoSalida = Number((salarioDiario * 10).toFixed(2));
  const total = Number((prestaciones + vacPendientes + bonoSalida).toFixed(2));

  await callSpOut(
    "usp_HR_Payroll_UpsertSettlement",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      SettlementCode: String(payload.liquidacionId ?? "").trim(),
      EmployeeId: employee.employeeId,
      EmployeeCode: employee.employeeCode,
      EmployeeName: employee.employeeName,
      RetirementDate: retiro,
      RetirementCause: payload.causaRetiro ?? null,
      TotalAmount: total,
      Prestaciones: prestaciones,
      VacPendientes: vacPendientes,
      BonoSalida: bonoSalida,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: true,
    message: "Liquidacion calculada",
  };
}

export async function listLiquidaciones(params: {
  cedula?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Payroll_ListSettlements",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.cedula?.trim() || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function getLiquidacion(liquidacionId: string) {
  const scope = await getDefaultScope();
  const code = String(liquidacionId ?? "").trim();

  const header = await callSp<{ id: number; total: number }>(
    "usp_HR_Payroll_GetSettlementHeader",
    {
      CompanyId: scope.companyId,
      SettlementCode: code,
    }
  );

  const id = Number(header[0]?.id ?? 0);
  if (!id) {
    return { detalle: [], totales: null };
  }

  const detalle = await callSp<any>(
    "usp_HR_Payroll_GetSettlementLines",
    { SettlementProcessId: id }
  );

  return {
    detalle,
    totales: { total: Number(header[0]?.total ?? 0) },
  };
}

export async function listConstantes(params: { page?: number; limit?: number }) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<any>(
    "usp_HR_Payroll_ListConstants",
    {
      CompanyId: scope.companyId,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function saveConstante(data: {
  codigo: string;
  nombre?: string;
  valor?: number;
  origen?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const code = String(data.codigo ?? "").trim().toUpperCase();
  if (!code) return { success: false, message: "codigo obligatorio" };

  const { output } = await callSpOut(
    "usp_HR_Payroll_SaveConstant",
    {
      CompanyId: scope.companyId,
      Code: code,
      Name: data.nombre ?? null,
      Value: data.valor == null ? null : Number(data.valor),
      SourceName: data.origen ?? null,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: true,
    message: String(output.Mensaje ?? "Constante guardada"),
  };
}

// ─── Solicitudes de Vacaciones ──────────────────────────────

export async function createVacationRequest(params: {
  employeeCode: string;
  startDate: string;
  endDate: string;
  totalDays: number;
  isPartial: boolean;
  notes?: string;
  days: Array<{ date: string; dayType: string }>;
}) {
  const scope = await getDefaultScope();
  const rows = await callSp<{ RequestId: number }>(
    "usp_HR_VacationRequest_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EmployeeCode: params.employeeCode,
      StartDate: params.startDate,
      EndDate: params.endDate,
      TotalDays: params.totalDays,
      IsPartial: params.isPartial,
      Notes: params.notes || null,
      Days: `<days>${params.days.map(d => `<d dt="${d.date}" tp="${d.dayType || 'COMPLETO'}"/>`).join('')}</days>`,
    }
  );
  return { success: true, requestId: rows[0]?.RequestId };
}

export async function listVacationRequests(params: {
  employeeCode?: string;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(params.page) || 1);
  const limit = Math.min(Math.max(1, Number(params.limit) || 50), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut(
    "usp_HR_VacationRequest_List",
    {
      CompanyId: scope.companyId,
      EmployeeCode: params.employeeCode || null,
      Status: params.status || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getVacationRequest(requestId: string) {
  const rows = await callSp("usp_HR_VacationRequest_Get", {
    RequestId: Number(requestId),
  });
  // SP returns 2 result sets: header + days
  return rows[0] ?? null;
}

export async function approveVacationRequest(requestId: string, approvedBy: string) {
  const rows = await callSp("usp_HR_VacationRequest_Approve", {
    RequestId: Number(requestId),
    ApprovedBy: approvedBy,
  });
  return { success: true, message: "Solicitud aprobada" };
}

export async function rejectVacationRequest(requestId: string, approvedBy: string, reason: string) {
  const rows = await callSp("usp_HR_VacationRequest_Reject", {
    RequestId: Number(requestId),
    ApprovedBy: approvedBy,
    RejectionReason: reason,
  });
  return { success: true, message: "Solicitud rechazada" };
}

export async function cancelVacationRequest(requestId: string) {
  const rows = await callSp("usp_HR_VacationRequest_Cancel", {
    RequestId: Number(requestId),
  });
  return { success: true, message: "Solicitud cancelada" };
}

export async function processVacationRequestPayment(requestId: string, codUsuario: string) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(codUsuario);

  // Get the request details
  const reqRows = await callSp<any>("usp_HR_VacationRequest_Get", {
    RequestId: Number(requestId),
  });
  const request = reqRows[0];
  if (!request) throw new Error("solicitud_not_found");
  if (request.Status !== "APROBADA") throw new Error("solicitud_not_approved");

  // Process the vacation using existing logic
  const result = await procesarVacaciones({
    vacacionId: `VAC-REQ-${requestId}`,
    cedula: request.EmployeeCode,
    fechaInicio: request.StartDate,
    fechaHasta: request.EndDate,
    codUsuario,
  });

  // Link the VacationId back to the request
  await callSp("usp_HR_VacationRequest_Process", {
    RequestId: Number(requestId),
    VacationId: 0, // The VacationProcess ID from the result
  });

  return { ...result, success: true, message: "Pago de vacaciones generado" };
}

export async function getAvailableDays(cedula: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<{
    DiasBase: number;
    AnosServicio: number;
    DiasAdicionales: number;
    DiasDisponibles: number;
    DiasTomados: number;
    DiasPendientes: number;
  }>(
    "usp_HR_VacationRequest_GetAvailableDays",
    {
      CompanyId: scope.companyId,
      EmployeeCode: cedula,
    }
  );
  return rows[0] ?? { DiasBase: 15, AnosServicio: 0, DiasAdicionales: 0, DiasDisponibles: 15, DiasTomados: 0, DiasPendientes: 0 };
}
