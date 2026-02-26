
import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

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
  if (defaultScopeCache) return defaultScopeCache;

  const rows = await query<{ companyId: number; branchId: number; systemUserId: number | null }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId,
      su.UserId AS systemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
      ON b.CompanyId = c.CompanyId
     AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] su
      ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId
    `
  );

  const row = rows[0];
  defaultScopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };

  return defaultScopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  if (!code) return (await getDefaultScope()).systemUserId;

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@code)
    ORDER BY UserId
    `,
    { code }
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
  const rows = await query<{ value: number }>(
    `
    SELECT TOP 1 ConstantValue AS value
    FROM hr.PayrollConstant
    WHERE CompanyId = @companyId
      AND ConstantCode = @code
      AND IsActive = 1
    ORDER BY PayrollConstantId DESC
    `,
    {
      companyId: scope.companyId,
      code,
    }
  );

  const value = Number(rows[0]?.value ?? fallback);
  return Number.isFinite(value) ? value : fallback;
}

async function ensurePayrollType(companyId: number, payrollCode: string, userId: number | null) {
  const code = String(payrollCode ?? "").trim().toUpperCase();
  if (!code) return;

  const found = await query<{ id: number }>(
    `
    SELECT TOP 1 PayrollTypeId AS id
    FROM hr.PayrollType
    WHERE CompanyId = @companyId
      AND PayrollCode = @code
    `,
    { companyId, code }
  );
  if (found[0]?.id) return;

  await query(
    `
    INSERT INTO hr.PayrollType (
      CompanyId,
      PayrollCode,
      PayrollName,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @companyId,
      @code,
      @name,
      1,
      @userId,
      @userId
    )
    `,
    {
      companyId,
      code,
      name: `Nomina ${code}`,
      userId,
    }
  );
}

async function ensureEmployee(cedula: string, userId: number | null): Promise<EmployeeRef> {
  const scope = await getDefaultScope();
  const document = String(cedula ?? "").trim();
  if (!document) throw new Error("cedula obligatoria");

  const existing = await query<EmployeeRef>(
    `
    SELECT TOP 1
      EmployeeId AS employeeId,
      EmployeeCode AS employeeCode,
      EmployeeName AS employeeName,
      HireDate AS hireDate
    FROM [master].Employee
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND (
        EmployeeCode = @document
        OR FiscalId = @document
      )
    ORDER BY EmployeeId
    `,
    {
      companyId: scope.companyId,
      document,
    }
  );

  if (existing[0]) {
    return {
      employeeId: Number(existing[0].employeeId),
      employeeCode: String(existing[0].employeeCode),
      employeeName: String(existing[0].employeeName),
      hireDate: existing[0].hireDate ? new Date(existing[0].hireDate) : null,
    };
  }

  const created = await query<{ employeeId: number }>(
    `
    INSERT INTO [master].Employee (
      CompanyId,
      EmployeeCode,
      EmployeeName,
      FiscalId,
      HireDate,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.EmployeeId AS employeeId
    VALUES (
      @companyId,
      @code,
      @name,
      @fiscalId,
      CAST(GETDATE() AS DATE),
      1,
      @userId,
      @userId
    )
    `,
    {
      companyId: scope.companyId,
      code: document,
      name: `Empleado ${document}`,
      fiscalId: document,
      userId,
    }
  );

  return {
    employeeId: Number(created[0]?.employeeId ?? 0),
    employeeCode: document,
    employeeName: `Empleado ${document}`,
    hireDate: new Date(),
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

  const where: string[] = ["CompanyId = @companyId", "IsActive = 1"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };

  if (params.coNomina?.trim()) {
    where.push("PayrollCode = @payrollCode");
    sqlParams.payrollCode = params.coNomina.trim().toUpperCase();
  }

  if (params.tipo?.trim()) {
    where.push("ConceptType = @conceptType");
    sqlParams.conceptType = params.tipo.trim().toUpperCase();
  }

  if (params.search?.trim()) {
    where.push("(ConceptCode LIKE @search OR ConceptName LIKE @search)");
    sqlParams.search = `%${params.search.trim()}%`;
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<ConceptoNomina>(
    `
    SELECT
      ConceptCode AS codigo,
      PayrollCode AS codigoNomina,
      ConceptName AS nombre,
      Formula AS formula,
      BaseExpression AS sobre,
      ConceptClass AS clase,
      ConceptType AS tipo,
      UsageType AS uso,
      CASE WHEN IsBonifiable = 1 THEN N'S' ELSE N'N' END AS bonificable,
      CASE WHEN IsSeniority = 1 THEN N'S' ELSE N'N' END AS esAntiguedad,
      AccountingAccountCode AS cuentaContable,
      CASE WHEN AppliesFlag = 1 THEN N'S' ELSE N'N' END AS aplica,
      DefaultValue AS valorDefecto
    FROM hr.PayrollConcept
    ${clause}
    ORDER BY PayrollCode, SortOrder, ConceptCode
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM hr.PayrollConcept
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
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

  const existing = await query<{ id: number }>(
    `
    SELECT TOP 1 PayrollConceptId AS id
    FROM hr.PayrollConcept
    WHERE CompanyId = @companyId
      AND PayrollCode = @payrollCode
      AND ConceptCode = @conceptCode
      AND ConventionCode IS NULL
      AND CalculationType IS NULL
    ORDER BY PayrollConceptId
    `,
    {
      companyId: scope.companyId,
      payrollCode,
      conceptCode,
    }
  );

  const payload = {
    companyId: scope.companyId,
    payrollCode,
    conceptCode,
    conceptName,
    formula: data.formula ?? null,
    baseExpression: data.sobre ?? null,
    conceptClass: data.clase ?? null,
    conceptType: String(data.tipo ?? "ASIGNACION").toUpperCase(),
    usageType: data.uso ?? null,
    isBonifiable: toFlag(data.bonificable, false),
    isSeniority: toFlag(data.esAntiguedad, false),
    accountingAccountCode: data.cuentaContable ?? null,
    appliesFlag: toFlag(data.aplica, true),
    defaultValue: Number(data.valorDefecto ?? 0),
    userId,
  };

  if (existing[0]?.id) {
    await query(
      `
      UPDATE hr.PayrollConcept
      SET
        ConceptName = @conceptName,
        Formula = @formula,
        BaseExpression = @baseExpression,
        ConceptClass = @conceptClass,
        ConceptType = @conceptType,
        UsageType = @usageType,
        IsBonifiable = @isBonifiable,
        IsSeniority = @isSeniority,
        AccountingAccountCode = @accountingAccountCode,
        AppliesFlag = @appliesFlag,
        DefaultValue = @defaultValue,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE PayrollConceptId = @id
      `,
      {
        ...payload,
        id: Number(existing[0].id),
      }
    );
  } else {
    await query(
      `
      INSERT INTO hr.PayrollConcept (
        CompanyId,
        PayrollCode,
        ConceptCode,
        ConceptName,
        Formula,
        BaseExpression,
        ConceptClass,
        ConceptType,
        UsageType,
        IsBonifiable,
        IsSeniority,
        AccountingAccountCode,
        AppliesFlag,
        DefaultValue,
        ConventionCode,
        CalculationType,
        SortOrder,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @companyId,
        @payrollCode,
        @conceptCode,
        @conceptName,
        @formula,
        @baseExpression,
        @conceptClass,
        @conceptType,
        @usageType,
        @isBonifiable,
        @isSeniority,
        @accountingAccountCode,
        @appliesFlag,
        @defaultValue,
        NULL,
        NULL,
        0,
        1,
        @userId,
        @userId
      )
      `,
      payload
    );
  }

  return {
    success: true,
    message: "Concepto guardado",
  };
}

async function loadConceptsForRun(
  payrollCode: string,
  conceptTypeFilter?: string,
  options?: ProcessOptions
) {
  const scope = await getDefaultScope();
  const where: string[] = [
    "CompanyId = @companyId",
    "PayrollCode = @payrollCode",
    "IsActive = 1",
    "AppliesFlag = 1",
  ];

  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    payrollCode,
  };

  if (conceptTypeFilter?.trim()) {
    where.push("ConceptType = @conceptType");
    sqlParams.conceptType = conceptTypeFilter.trim().toUpperCase();
  }

  if (options?.soloConceptosLegales) {
    if (options.conventionCode?.trim()) {
      where.push("ConventionCode = @conventionCode");
      sqlParams.conventionCode = options.conventionCode.trim().toUpperCase();
    } else {
      where.push("ConventionCode IS NOT NULL");
    }
  } else if (options?.conventionCode?.trim()) {
    where.push("(ConventionCode = @conventionCode OR ConventionCode IS NULL)");
    sqlParams.conventionCode = options.conventionCode.trim().toUpperCase();
  }

  if (options?.calculationType?.trim()) {
    where.push("(CalculationType = @calculationType OR CalculationType IS NULL)");
    sqlParams.calculationType = options.calculationType.trim().toUpperCase();
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  return query<{
    conceptCode: string;
    conceptName: string;
    conceptType: string;
    defaultValue: number;
    formula: string | null;
    accountingAccountCode: string | null;
  }>(
    `
    SELECT
      ConceptCode AS conceptCode,
      ConceptName AS conceptName,
      ConceptType AS conceptType,
      DefaultValue AS defaultValue,
      Formula AS formula,
      AccountingAccountCode AS accountingAccountCode
    FROM hr.PayrollConcept
    ${clause}
    ORDER BY SortOrder, ConceptCode
    `,
    sqlParams
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
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const reqGet = new sql.Request(tx);
    reqGet.input("companyId", sql.Int, scope.companyId);
    reqGet.input("branchId", sql.Int, scope.branchId);
    reqGet.input("payrollCode", sql.NVarChar(15), input.payrollCode);
    reqGet.input("employeeCode", sql.NVarChar(24), input.employee.employeeCode);
    reqGet.input("fromDate", sql.Date, input.fromDate);
    reqGet.input("toDate", sql.Date, input.toDate);

    const existing = await reqGet.query<{ id: number }>(
      `
      SELECT TOP 1 PayrollRunId AS id
      FROM hr.PayrollRun
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND PayrollCode = @payrollCode
        AND EmployeeCode = @employeeCode
        AND DateFrom = @fromDate
        AND DateTo = @toDate
        AND RunSource = N'MANUAL'
      ORDER BY PayrollRunId DESC
      `
    );

    let runId = Number(existing.recordset?.[0]?.id ?? 0);
    if (runId > 0) {
      const reqUpdate = new sql.Request(tx);
      reqUpdate.input("runId", sql.BigInt, runId);
      reqUpdate.input("processDate", sql.Date, new Date());
      reqUpdate.input("totalAsignaciones", sql.Decimal(18, 2), input.totalAsignaciones);
      reqUpdate.input("totalDeducciones", sql.Decimal(18, 2), input.totalDeducciones);
      reqUpdate.input("totalNeto", sql.Decimal(18, 2), input.totalNeto);
      reqUpdate.input("payrollTypeName", sql.NVarChar(50), input.calculationType ?? null);
      reqUpdate.input("updatedByUserId", sql.Int, input.userId ?? null);
      await reqUpdate.query(
        `
        UPDATE hr.PayrollRun
        SET
          ProcessDate = @processDate,
          TotalAssignments = @totalAsignaciones,
          TotalDeductions = @totalDeducciones,
          NetTotal = @totalNeto,
          PayrollTypeName = COALESCE(@payrollTypeName, PayrollTypeName),
          UpdatedAt = SYSUTCDATETIME(),
          UpdatedByUserId = @updatedByUserId
        WHERE PayrollRunId = @runId
        `
      );

      const reqDelete = new sql.Request(tx);
      reqDelete.input("runId", sql.BigInt, runId);
      await reqDelete.query("DELETE FROM hr.PayrollRunLine WHERE PayrollRunId = @runId");
    } else {
      const reqInsert = new sql.Request(tx);
      reqInsert.input("companyId", sql.Int, scope.companyId);
      reqInsert.input("branchId", sql.Int, scope.branchId);
      reqInsert.input("payrollCode", sql.NVarChar(15), input.payrollCode);
      reqInsert.input("employeeId", sql.BigInt, input.employee.employeeId);
      reqInsert.input("employeeCode", sql.NVarChar(24), input.employee.employeeCode);
      reqInsert.input("employeeName", sql.NVarChar(200), input.employee.employeeName);
      reqInsert.input("positionName", sql.NVarChar(120), null);
      reqInsert.input("processDate", sql.Date, new Date());
      reqInsert.input("fromDate", sql.Date, input.fromDate);
      reqInsert.input("toDate", sql.Date, input.toDate);
      reqInsert.input("totalAsignaciones", sql.Decimal(18, 2), input.totalAsignaciones);
      reqInsert.input("totalDeducciones", sql.Decimal(18, 2), input.totalDeducciones);
      reqInsert.input("totalNeto", sql.Decimal(18, 2), input.totalNeto);
      reqInsert.input("payrollTypeName", sql.NVarChar(50), input.calculationType ?? null);
      reqInsert.input("createdByUserId", sql.Int, input.userId ?? null);
      const inserted = await reqInsert.query<{ id: number }>(
        `
        INSERT INTO hr.PayrollRun (
          CompanyId,
          BranchId,
          PayrollCode,
          EmployeeId,
          EmployeeCode,
          EmployeeName,
          PositionName,
          ProcessDate,
          DateFrom,
          DateTo,
          TotalAssignments,
          TotalDeductions,
          NetTotal,
          PayrollTypeName,
          RunSource,
          CreatedByUserId,
          UpdatedByUserId
        )
        OUTPUT INSERTED.PayrollRunId AS id
        VALUES (
          @companyId,
          @branchId,
          @payrollCode,
          @employeeId,
          @employeeCode,
          @employeeName,
          @positionName,
          @processDate,
          @fromDate,
          @toDate,
          @totalAsignaciones,
          @totalDeducciones,
          @totalNeto,
          @payrollTypeName,
          N'MANUAL',
          @createdByUserId,
          @createdByUserId
        )
        `
      );
      runId = Number(inserted.recordset?.[0]?.id ?? 0);
    }

    for (const line of input.lines) {
      const reqLine = new sql.Request(tx);
      reqLine.input("runId", sql.BigInt, runId);
      reqLine.input("code", sql.NVarChar(20), line.code);
      reqLine.input("name", sql.NVarChar(120), line.name);
      reqLine.input("type", sql.NVarChar(15), line.type);
      reqLine.input("quantity", sql.Decimal(18, 4), line.quantity);
      reqLine.input("amount", sql.Decimal(18, 4), line.amount);
      reqLine.input("total", sql.Decimal(18, 2), line.total);
      reqLine.input("description", sql.NVarChar(255), line.description ?? null);
      reqLine.input("account", sql.NVarChar(50), line.account ?? null);
      await reqLine.query(
        `
        INSERT INTO hr.PayrollRunLine (
          PayrollRunId,
          ConceptCode,
          ConceptName,
          ConceptType,
          Quantity,
          Amount,
          Total,
          DescriptionText,
          AccountingAccountCode
        )
        VALUES (
          @runId,
          @code,
          @name,
          @type,
          @quantity,
          @amount,
          @total,
          @description,
          @account
        )
        `
      );
    }

    await tx.commit();
    return runId;
  } catch (error) {
    await tx.rollback();
    throw error;
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
  const where = ["CompanyId = @companyId", "IsDeleted = 0"];
  if (payload.soloActivos ?? true) {
    where.push("IsActive = 1");
  }

  const employees = await query<{ employeeCode: string }>(
    `
    SELECT EmployeeCode AS employeeCode
    FROM [master].Employee
    WHERE ${where.join(" AND ")}
    ORDER BY EmployeeCode
    `,
    { companyId: scope.companyId }
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

  const where: string[] = ["CompanyId = @companyId"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };

  if (params.nomina?.trim()) {
    where.push("PayrollCode = @payrollCode");
    sqlParams.payrollCode = params.nomina.trim().toUpperCase();
  }
  if (params.cedula?.trim()) {
    where.push("EmployeeCode = @employeeCode");
    sqlParams.employeeCode = params.cedula.trim();
  }
  if (params.fechaDesde) {
    const fromDate = normalizeDate(params.fechaDesde);
    if (fromDate) {
      where.push("DateFrom >= @fromDate");
      sqlParams.fromDate = fromDate;
    }
  }
  if (params.fechaHasta) {
    const toDate = normalizeDate(params.fechaHasta);
    if (toDate) {
      where.push("DateTo <= @toDate");
      sqlParams.toDate = toDate;
    }
  }
  if (params.soloAbiertas) {
    where.push("IsClosed = 0");
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<NominaCabecera>(
    `
    SELECT
      PayrollCode AS nomina,
      EmployeeCode AS cedula,
      EmployeeName AS nombreEmpleado,
      PositionName AS cargo,
      ProcessDate AS fechaProceso,
      DateFrom AS fechaInicio,
      DateTo AS fechaHasta,
      TotalAssignments AS totalAsignaciones,
      TotalDeductions AS totalDeducciones,
      NetTotal AS totalNeto,
      IsClosed AS cerrada,
      PayrollTypeName AS tipoNomina
    FROM hr.PayrollRun
    ${clause}
    ORDER BY ProcessDate DESC, PayrollRunId DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM hr.PayrollRun
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
  };
}

export async function getNomina(nomina: string, cedula: string) {
  const scope = await getDefaultScope();
  const payrollCode = String(nomina ?? "").trim().toUpperCase();
  const employeeCode = String(cedula ?? "").trim();

  const cabeceraRows = await query<NominaCabecera & { runId: number }>(
    `
    SELECT TOP 1
      PayrollRunId AS runId,
      PayrollCode AS nomina,
      EmployeeCode AS cedula,
      EmployeeName AS nombreEmpleado,
      PositionName AS cargo,
      ProcessDate AS fechaProceso,
      DateFrom AS fechaInicio,
      DateTo AS fechaHasta,
      TotalAssignments AS totalAsignaciones,
      TotalDeductions AS totalDeducciones,
      NetTotal AS totalNeto,
      IsClosed AS cerrada,
      PayrollTypeName AS tipoNomina
    FROM hr.PayrollRun
    WHERE CompanyId = @companyId
      AND PayrollCode = @payrollCode
      AND EmployeeCode = @employeeCode
    ORDER BY ProcessDate DESC, PayrollRunId DESC
    `,
    {
      companyId: scope.companyId,
      payrollCode,
      employeeCode,
    }
  );

  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) {
    return { cabecera: null, detalle: [] as NominaDetalle[] };
  }

  const detalle = await query<NominaDetalle>(
    `
    SELECT
      ConceptCode AS coConcepto,
      ConceptName AS nombreConcepto,
      ConceptType AS tipoConcepto,
      Quantity AS cantidad,
      Amount AS monto,
      Total AS total,
      DescriptionText AS descripcion,
      AccountingAccountCode AS cuentaContable
    FROM hr.PayrollRunLine
    WHERE PayrollRunId = @runId
    ORDER BY PayrollRunLineId
    `,
    {
      runId: (cabecera as any).runId,
    }
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

  const affectedRows = await query<{ affected: number }>(
    `
    UPDATE hr.PayrollRun
    SET
      IsClosed = 1,
      ClosedAt = SYSUTCDATETIME(),
      ClosedByUserId = @userId,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @userId
    WHERE CompanyId = @companyId
      AND PayrollCode = @payrollCode
      AND IsClosed = 0
      AND (@employeeCode IS NULL OR EmployeeCode = @employeeCode);

    SELECT @@ROWCOUNT AS affected;
    `,
    {
      companyId: scope.companyId,
      payrollCode: String(payload.nomina ?? "").trim().toUpperCase(),
      employeeCode: payload.cedula ? String(payload.cedula).trim() : null,
      userId,
    }
  );

  const affected = Number(affectedRows[0]?.affected ?? 0);
  return {
    success: affected > 0,
    message: affected > 0 ? "Nomina cerrada" : "No se encontraron registros abiertos",
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

  const existing = await query<{ id: number }>(
    `
    SELECT TOP 1 VacationProcessId AS id
    FROM hr.VacationProcess
    WHERE CompanyId = @companyId
      AND VacationCode = @vacationCode
    `,
    {
      companyId: scope.companyId,
      vacationCode: String(payload.vacacionId ?? "").trim(),
    }
  );

  let vacationProcessId = Number(existing[0]?.id ?? 0);
  if (vacationProcessId > 0) {
    await query(
      `
      UPDATE hr.VacationProcess
      SET
        EmployeeId = @employeeId,
        EmployeeCode = @employeeCode,
        EmployeeName = @employeeName,
        StartDate = @startDate,
        EndDate = @endDate,
        ReintegrationDate = @reintegrationDate,
        ProcessDate = CAST(GETDATE() AS DATE),
        TotalAmount = @total,
        CalculatedAmount = @total,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE VacationProcessId = @id
      `,
      {
        id: vacationProcessId,
        employeeId: employee.employeeId,
        employeeCode: employee.employeeCode,
        employeeName: employee.employeeName,
        startDate,
        endDate,
        reintegrationDate,
        total,
        userId,
      }
    );
  } else {
    const inserted = await query<{ id: number }>(
      `
      INSERT INTO hr.VacationProcess (
        CompanyId,
        BranchId,
        VacationCode,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        StartDate,
        EndDate,
        ReintegrationDate,
        ProcessDate,
        TotalAmount,
        CalculatedAmount,
        CreatedByUserId,
        UpdatedByUserId
      )
      OUTPUT INSERTED.VacationProcessId AS id
      VALUES (
        @companyId,
        @branchId,
        @vacationCode,
        @employeeId,
        @employeeCode,
        @employeeName,
        @startDate,
        @endDate,
        @reintegrationDate,
        CAST(GETDATE() AS DATE),
        @total,
        @total,
        @userId,
        @userId
      )
      `,
      {
        companyId: scope.companyId,
        branchId: scope.branchId,
        vacationCode: String(payload.vacacionId ?? "").trim(),
        employeeId: employee.employeeId,
        employeeCode: employee.employeeCode,
        employeeName: employee.employeeName,
        startDate,
        endDate,
        reintegrationDate,
        total,
        userId,
      }
    );
    vacationProcessId = Number(inserted[0]?.id ?? 0);
  }

  await query("DELETE FROM hr.VacationProcessLine WHERE VacationProcessId = @id", { id: vacationProcessId });
  await query(
    `
    INSERT INTO hr.VacationProcessLine (
      VacationProcessId,
      ConceptCode,
      ConceptName,
      Amount
    )
    VALUES (@id, N'VACACIONES', N'Pago de vacaciones', @amount)
    `,
    {
      id: vacationProcessId,
      amount: total,
    }
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

  const where: string[] = ["CompanyId = @companyId"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };
  if (params.cedula?.trim()) {
    where.push("EmployeeCode = @employeeCode");
    sqlParams.employeeCode = params.cedula.trim();
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<Vacacion>(
    `
    SELECT
      VacationCode AS vacacion,
      EmployeeCode AS cedula,
      EmployeeName AS nombreEmpleado,
      StartDate AS inicio,
      EndDate AS hasta,
      ReintegrationDate AS reintegro,
      ProcessDate AS fechaCalculo,
      TotalAmount AS total,
      CalculatedAmount AS totalCalculado
    FROM hr.VacationProcess
    ${clause}
    ORDER BY VacationProcessId DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM hr.VacationProcess
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
  };
}

export async function getVacaciones(vacacionId: string) {
  const scope = await getDefaultScope();
  const code = String(vacacionId ?? "").trim();

  const cabeceraRows = await query<any>(
    `
    SELECT TOP 1
      VacationProcessId AS id,
      VacationCode AS vacacion,
      EmployeeCode AS cedula,
      EmployeeName AS nombreEmpleado,
      StartDate AS inicio,
      EndDate AS hasta,
      ReintegrationDate AS reintegro,
      ProcessDate AS fechaCalculo,
      TotalAmount AS total,
      CalculatedAmount AS totalCalculado
    FROM hr.VacationProcess
    WHERE CompanyId = @companyId
      AND VacationCode = @code
    `,
    {
      companyId: scope.companyId,
      code,
    }
  );

  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) return { cabecera: null, detalle: [] };

  const detalle = await query<any>(
    `
    SELECT
      ConceptCode AS codigo,
      ConceptName AS nombre,
      Amount AS monto
    FROM hr.VacationProcessLine
    WHERE VacationProcessId = @id
    ORDER BY VacationProcessLineId
    `,
    { id: Number(cabecera.id) }
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

  const code = String(payload.liquidacionId ?? "").trim();
  const existing = await query<{ id: number }>(
    `
    SELECT TOP 1 SettlementProcessId AS id
    FROM hr.SettlementProcess
    WHERE CompanyId = @companyId
      AND SettlementCode = @code
    `,
    { companyId: scope.companyId, code }
  );

  let settlementId = Number(existing[0]?.id ?? 0);
  if (settlementId > 0) {
    await query(
      `
      UPDATE hr.SettlementProcess
      SET
        EmployeeId = @employeeId,
        EmployeeCode = @employeeCode,
        EmployeeName = @employeeName,
        RetirementDate = @retirementDate,
        RetirementCause = @retirementCause,
        TotalAmount = @total,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE SettlementProcessId = @id
      `,
      {
        id: settlementId,
        employeeId: employee.employeeId,
        employeeCode: employee.employeeCode,
        employeeName: employee.employeeName,
        retirementDate: retiro,
        retirementCause: payload.causaRetiro ?? null,
        total,
        userId,
      }
    );
  } else {
    const inserted = await query<{ id: number }>(
      `
      INSERT INTO hr.SettlementProcess (
        CompanyId,
        BranchId,
        SettlementCode,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        RetirementDate,
        RetirementCause,
        TotalAmount,
        CreatedByUserId,
        UpdatedByUserId
      )
      OUTPUT INSERTED.SettlementProcessId AS id
      VALUES (
        @companyId,
        @branchId,
        @settlementCode,
        @employeeId,
        @employeeCode,
        @employeeName,
        @retirementDate,
        @retirementCause,
        @total,
        @userId,
        @userId
      )
      `,
      {
        companyId: scope.companyId,
        branchId: scope.branchId,
        settlementCode: code,
        employeeId: employee.employeeId,
        employeeCode: employee.employeeCode,
        employeeName: employee.employeeName,
        retirementDate: retiro,
        retirementCause: payload.causaRetiro ?? null,
        total,
        userId,
      }
    );
    settlementId = Number(inserted[0]?.id ?? 0);
  }

  await query("DELETE FROM hr.SettlementProcessLine WHERE SettlementProcessId = @id", { id: settlementId });
  await query(
    `
    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount)
    VALUES
      (@id, N'PRESTACIONES', N'Prestaciones sociales', @prestaciones),
      (@id, N'VACACIONES_PEND', N'Vacaciones pendientes', @vacPendientes),
      (@id, N'BONO_SALIDA', N'Bono de salida', @bonoSalida)
    `,
    {
      id: settlementId,
      prestaciones,
      vacPendientes,
      bonoSalida,
    }
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

  const where: string[] = ["CompanyId = @companyId"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };
  if (params.cedula?.trim()) {
    where.push("EmployeeCode = @employeeCode");
    sqlParams.employeeCode = params.cedula.trim();
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<any>(
    `
    SELECT
      SettlementCode AS liquidacion,
      EmployeeCode AS cedula,
      EmployeeName AS nombreEmpleado,
      RetirementDate AS fechaRetiro,
      RetirementCause AS causaRetiro,
      TotalAmount AS total
    FROM hr.SettlementProcess
    ${clause}
    ORDER BY SettlementProcessId DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM hr.SettlementProcess
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
  };
}

export async function getLiquidacion(liquidacionId: string) {
  const scope = await getDefaultScope();
  const code = String(liquidacionId ?? "").trim();

  const header = await query<{ id: number; total: number }>(
    `
    SELECT TOP 1
      SettlementProcessId AS id,
      TotalAmount AS total
    FROM hr.SettlementProcess
    WHERE CompanyId = @companyId
      AND SettlementCode = @code
    `,
    {
      companyId: scope.companyId,
      code,
    }
  );

  const id = Number(header[0]?.id ?? 0);
  if (!id) {
    return { detalle: [], totales: null };
  }

  const detalle = await query<any>(
    `
    SELECT
      ConceptCode AS codigo,
      ConceptName AS nombre,
      Amount AS monto
    FROM hr.SettlementProcessLine
    WHERE SettlementProcessId = @id
    ORDER BY SettlementProcessLineId
    `,
    { id }
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

  const rows = await query<any>(
    `
    SELECT
      ConstantCode AS codigo,
      ConstantName AS nombre,
      ConstantValue AS valor,
      SourceName AS origen,
      IsActive AS activo
    FROM hr.PayrollConstant
    WHERE CompanyId = @companyId
    ORDER BY ConstantCode
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    {
      companyId: scope.companyId,
      offset,
      limit,
    }
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM hr.PayrollConstant
    WHERE CompanyId = @companyId
    `,
    { companyId: scope.companyId }
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
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

  const found = await query<{ id: number }>(
    `
    SELECT TOP 1 PayrollConstantId AS id
    FROM hr.PayrollConstant
    WHERE CompanyId = @companyId
      AND ConstantCode = @code
    `,
    {
      companyId: scope.companyId,
      code,
    }
  );

  if (found[0]?.id) {
    await query(
      `
      UPDATE hr.PayrollConstant
      SET
        ConstantName = COALESCE(@name, ConstantName),
        ConstantValue = COALESCE(@value, ConstantValue),
        SourceName = COALESCE(@sourceName, SourceName),
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE PayrollConstantId = @id
      `,
      {
        id: Number(found[0].id),
        name: data.nombre ?? null,
        value: data.valor == null ? null : Number(data.valor),
        sourceName: data.origen ?? null,
        userId,
      }
    );
  } else {
    await query(
      `
      INSERT INTO hr.PayrollConstant (
        CompanyId,
        ConstantCode,
        ConstantName,
        ConstantValue,
        SourceName,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @companyId,
        @code,
        @name,
        @value,
        @sourceName,
        1,
        @userId,
        @userId
      )
      `,
      {
        companyId: scope.companyId,
        code,
        name: data.nombre ?? code,
        value: Number(data.valor ?? 0),
        sourceName: data.origen ?? null,
        userId,
      }
    );
  }

  return {
    success: true,
    message: "Constante guardada",
  };
}
