import { callSp } from "../../db/query.js";

export interface EmpleadoRow {
  CEDULA?: string;
  GRUPO?: string;
  NOMBRE?: string;
  DIRECCION?: string;
  TELEFONO?: string;
  NACIMIENTO?: Date;
  CARGO?: string;
  NOMINA?: string;
  SUELDO?: number;
  INGRESO?: Date;
  RETIRO?: Date;
  STATUS?: string;
  COMISION?: number;
  UTILIDAD?: number;
  CO_Usuario?: string;
  SEXO?: string;
  NACIONALIDAD?: string;
  Autoriza?: boolean;
  Apodo?: string;
  [key: string]: unknown;
}

export interface ListEmpleadosParams {
  search?: string;
  grupo?: string;
  status?: string;
  page?: number;
  limit?: number;
}

export interface ListEmpleadosResult {
  rows: EmpleadoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

async function getDefaultCompanyId() {
  const rows = await callSp<{ CompanyId: number }>('usp_HR_Employee_GetDefaultCompany');
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  return companyId;
}

function mapEmployeeRow(row: Record<string, unknown>): EmpleadoRow {
  return {
    CEDULA: String(row.EmployeeCode ?? ""),
    NOMBRE: String(row.EmployeeName ?? ""),
    STATUS: Number(row.IsActive ?? 0) ? "ACTIVO" : "INACTIVO",
    INGRESO: (row.HireDate as Date | undefined) ?? undefined,
    RETIRO: (row.TerminationDate as Date | undefined) ?? undefined,
    NACIONALIDAD: "VE",
    Autoriza: Number(row.IsActive ?? 0) === 1,
    FiscalId: row.FiscalId
  };
}

export async function listEmpleadosSP(params: ListEmpleadosParams = {}): Promise<ListEmpleadosResult> {
  const companyId = await getDefaultCompanyId();
  const page = Math.max(1, Number(params.page || 1));
  const limit = Math.min(Math.max(1, Number(params.limit || 50)), 500);
  const offset = (page - 1) * limit;

  const statusNormalized = params.status
    ? String(params.status).trim().toUpperCase()
    : null;

  const rows = await callSp<any>('usp_HR_Employee_List', {
    CompanyId: companyId,
    Search: params.search || null,
    Status: statusNormalized === 'ACTIVO' || statusNormalized === 'INACTIVO' ? statusNormalized : null,
    Offset: offset,
    Limit: limit
  });

  const totalRows = await callSp<{ total: number }>('usp_HR_Employee_Count', {
    CompanyId: companyId,
    Search: params.search || null,
    Status: statusNormalized === 'ACTIVO' || statusNormalized === 'INACTIVO' ? statusNormalized : null
  });

  return {
    rows: rows.map(mapEmployeeRow),
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getEmpleadoByCedulaSP(cedula: string): Promise<EmpleadoRow | null> {
  const companyId = await getDefaultCompanyId();

  const rows = await callSp<any>('usp_HR_Employee_GetByCode', {
    CompanyId: companyId,
    Cedula: cedula
  });

  return rows[0] ? mapEmployeeRow(rows[0]) : null;
}

export async function insertEmpleadoSP(row: EmpleadoRow): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const code = String(row.CEDULA ?? "").trim();
  const name = String(row.NOMBRE ?? "").trim();

  if (!code) return { success: false, message: "CEDULA requerida" };
  if (!name) return { success: false, message: "NOMBRE requerido" };

  const exists = await callSp<{ EmployeeId: number }>('usp_HR_Employee_ExistsByCode', {
    CompanyId: companyId,
    Code: code
  });

  if (exists[0]?.EmployeeId) {
    return { success: false, message: "El empleado ya existe" };
  }

  const isActive = String(row.STATUS ?? "ACTIVO").trim().toUpperCase() !== "INACTIVO";

  await callSp('usp_HR_Employee_Insert', {
    CompanyId: companyId,
    Code: code,
    Name: name,
    FiscalId: row.CEDULA ?? null,
    HireDate: row.INGRESO ?? null,
    TerminationDate: row.RETIRO ?? null,
    IsActive: isActive ? 1 : 0
  });

  return { success: true, message: "Empleado creado" };
}

export async function updateEmpleadoSP(cedula: string, row: Partial<EmpleadoRow>): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  const exists = await callSp<{ EmployeeId: number }>('usp_HR_Employee_ExistsByCode', {
    CompanyId: companyId,
    Code: cedula
  });

  if (!exists[0]?.EmployeeId) {
    return { success: false, message: "Empleado no encontrado" };
  }

  const hasStatus = row.STATUS !== undefined;
  const isActive = hasStatus
    ? (String(row.STATUS ?? "").trim().toUpperCase() !== "INACTIVO" ? 1 : 0)
    : null;

  await callSp('usp_HR_Employee_Update', {
    CompanyId: companyId,
    Cedula: cedula,
    Name: row.NOMBRE ?? null,
    FiscalId: row.CEDULA ?? null,
    HireDate: row.INGRESO ?? null,
    TerminationDate: row.RETIRO ?? null,
    IsActive: isActive
  });

  return { success: true, message: "Empleado actualizado" };
}

export async function deleteEmpleadoSP(cedula: string): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  await callSp('usp_HR_Employee_Delete', {
    CompanyId: companyId,
    Cedula: cedula
  });

  return { success: true, message: "Empleado eliminado" };
}
