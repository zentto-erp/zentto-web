import { execute, query } from "../../db/query.js";

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
  const rows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );
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

  const where: string[] = ["CompanyId = @companyId", "ISNULL(IsDeleted,0) = 0"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.search) {
    where.push("(EmployeeCode LIKE @search OR EmployeeName LIKE @search OR FiscalId LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }

  if (params.status) {
    const normalized = String(params.status).trim().toUpperCase();
    if (normalized === "ACTIVO") where.push("IsActive = 1");
    if (normalized === "INACTIVO") where.push("IsActive = 0");
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive
       FROM [master].Employee
       ${clause}
      ORDER BY EmployeeCode
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM [master].Employee
      ${clause}`,
    sqlParams
  );

  return {
    rows: rows.map(mapEmployeeRow),
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getEmpleadoByCedulaSP(cedula: string): Promise<EmpleadoRow | null> {
  const companyId = await getDefaultCompanyId();

  const rows = await query<any>(
    `SELECT TOP 1 EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive
       FROM [master].Employee
      WHERE CompanyId = @companyId
        AND EmployeeCode = @cedula
        AND ISNULL(IsDeleted,0) = 0`,
    { companyId, cedula }
  );

  return rows[0] ? mapEmployeeRow(rows[0]) : null;
}

export async function insertEmpleadoSP(row: EmpleadoRow): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const code = String(row.CEDULA ?? "").trim();
  const name = String(row.NOMBRE ?? "").trim();

  if (!code) return { success: false, message: "CEDULA requerida" };
  if (!name) return { success: false, message: "NOMBRE requerido" };

  const exists = await query<{ EmployeeId: number }>(
    `SELECT TOP 1 EmployeeId
       FROM [master].Employee
      WHERE CompanyId = @companyId
        AND EmployeeCode = @code
        AND ISNULL(IsDeleted,0) = 0`,
    { companyId, code }
  );

  if (exists[0]?.EmployeeId) {
    return { success: false, message: "El empleado ya existe" };
  }

  const isActive = String(row.STATUS ?? "ACTIVO").trim().toUpperCase() !== "INACTIVO";

  await execute(
    `INSERT INTO [master].Employee
      (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive, CreatedAt, UpdatedAt, IsDeleted)
     VALUES
      (@companyId, @code, @name, @fiscalId, @hireDate, @terminationDate, @isActive, SYSUTCDATETIME(), SYSUTCDATETIME(), 0)`,
    {
      companyId,
      code,
      name,
      fiscalId: row.CEDULA ?? null,
      hireDate: row.INGRESO ?? new Date(),
      terminationDate: row.RETIRO ?? null,
      isActive: isActive ? 1 : 0,
    }
  );

  return { success: true, message: "Empleado creado" };
}

export async function updateEmpleadoSP(cedula: string, row: Partial<EmpleadoRow>): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  const exists = await query<{ EmployeeId: number }>(
    `SELECT TOP 1 EmployeeId
       FROM [master].Employee
      WHERE CompanyId = @companyId
        AND EmployeeCode = @cedula
        AND ISNULL(IsDeleted,0) = 0`,
    { companyId, cedula }
  );

  if (!exists[0]?.EmployeeId) {
    return { success: false, message: "Empleado no encontrado" };
  }

  const hasStatus = row.STATUS !== undefined;
  const isActive = hasStatus
    ? (String(row.STATUS ?? "").trim().toUpperCase() !== "INACTIVO" ? 1 : 0)
    : null;

  await execute(
    `UPDATE [master].Employee
        SET EmployeeName = COALESCE(@name, EmployeeName),
            FiscalId = COALESCE(@fiscalId, FiscalId),
            HireDate = COALESCE(@hireDate, HireDate),
            TerminationDate = COALESCE(@terminationDate, TerminationDate),
            IsActive = COALESCE(@isActive, IsActive),
            UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND EmployeeCode = @cedula
        AND ISNULL(IsDeleted,0) = 0`,
    {
      companyId,
      cedula,
      name: row.NOMBRE ?? null,
      fiscalId: row.CEDULA ?? null,
      hireDate: row.INGRESO ?? null,
      terminationDate: row.RETIRO ?? null,
      isActive,
    }
  );

  return { success: true, message: "Empleado actualizado" };
}

export async function deleteEmpleadoSP(cedula: string): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  await execute(
    `UPDATE [master].Employee
        SET IsDeleted = 1,
            IsActive = 0,
            DeletedAt = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND EmployeeCode = @cedula
        AND ISNULL(IsDeleted,0) = 0`,
    { companyId, cedula }
  );

  return { success: true, message: "Empleado eliminado" };
}
