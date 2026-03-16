/**
 * Servicio de Plantillas de Documentos de Nómina
 * Tabla: hr.DocumentTemplate
 */
import { callSp, callSpOut } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";

// ─── Helpers locales ──────────────────────────────────────────────────────────

function formatDate(d: any): string {
  if (!d) return '';
  const date = d instanceof Date ? d : new Date(d);
  if (isNaN(date.getTime())) return '';
  return date.toLocaleDateString('es-VE');
}

function formatMoney(n: any): string {
  const num = Number(n ?? 0);
  if (isNaN(num)) return '0.00';
  return num.toFixed(2);
}

function calcAntiguedad(hireDate: any, toDate?: any): string {
  if (!hireDate) return '';
  const desde = hireDate instanceof Date ? hireDate : new Date(hireDate);
  const hasta = toDate ? (toDate instanceof Date ? toDate : new Date(toDate)) : new Date();
  if (isNaN(desde.getTime())) return '';

  const totalMonths =
    (hasta.getFullYear() - desde.getFullYear()) * 12 +
    (hasta.getMonth() - desde.getMonth());

  const years = Math.floor(totalMonths / 12);
  const months = totalMonths % 12;

  const parts: string[] = [];
  if (years > 0) parts.push(`${years} año${years !== 1 ? 's' : ''}`);
  if (months > 0) parts.push(`${months} mes${months !== 1 ? 'es' : ''}`);
  return parts.length > 0 ? parts.join(' y ') : 'Menos de un mes';
}

function numberToWords(n: number): string {
  // Implementación simple: retorna el monto en formato legible
  const num = Number(n ?? 0);
  if (isNaN(num)) return 'cero bolívares';
  return `${num.toFixed(2)} bolívares`;
}

function interpolate(content: string, vars: Record<string, string>): string {
  return content.replace(/\{\{([^}]+)\}\}/g, (_, key) => vars[key] ?? `{{${key}}}`);
}

function buildConceptTable(lines: any[], filterType?: string): string {
  const filtered = filterType
    ? lines.filter((l) => l.ConceptType === filterType)
    : lines;
  if (filtered.length === 0) return '*Sin conceptos*';

  let md = '| Código | Concepto | Tipo | Monto (Bs.) |\n';
  md += '|:-------|:---------|:-----|-----------:|\n';
  for (const l of filtered) {
    md += `| ${l.ConceptCode} | ${l.ConceptName} | ${l.ConceptType} | ${formatMoney(l.Total)} |\n`;
  }
  return md;
}

// ─── Funciones exportadas ─────────────────────────────────────────────────────

export async function listDocumentTemplates(
  companyId: number,
  countryCode?: string,
  templateType?: string
) {
  const rows = await callSp<any>(
    'usp_HR_DocumentTemplate_List',
    {
      CompanyId: companyId,
      CountryCode: countryCode?.trim().toUpperCase() || null,
      TemplateType: templateType?.trim().toUpperCase() || null,
    }
  );
  return rows;
}

export async function getDocumentTemplate(companyId: number, templateCode: string) {
  const rows = await callSp<any>(
    'usp_HR_DocumentTemplate_Get',
    {
      CompanyId: companyId,
      TemplateCode: String(templateCode ?? '').trim().toUpperCase(),
    }
  );

  const template = rows[0] ?? null;
  if (!template) {
    const err: any = new Error('template_not_found');
    err.statusCode = 404;
    throw err;
  }
  return template;
}

export async function saveDocumentTemplate(
  companyId: number,
  data: {
    templateCode: string;
    templateName: string;
    templateType: string;
    countryCode: string;
    payrollCode?: string;
    contentMD: string;
    isDefault?: boolean;
  }
) {
  const { output } = await callSpOut(
    'usp_HR_DocumentTemplate_Save',
    {
      CompanyId: companyId,
      TemplateCode: String(data.templateCode ?? '').trim().toUpperCase(),
      TemplateName: String(data.templateName ?? '').trim(),
      TemplateType: String(data.templateType ?? '').trim().toUpperCase(),
      CountryCode: String(data.countryCode ?? '').trim().toUpperCase(),
      PayrollCode: data.payrollCode?.trim().toUpperCase() || null,
      ContentMD: data.contentMD ?? '',
      IsDefault: data.isDefault ? 1 : 0,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? 0);
  if (resultado === 0) {
    throw new Error(String(output.Mensaje ?? 'Error al guardar la plantilla'));
  }

  return {
    success: true,
    message: String(output.Mensaje ?? 'Plantilla guardada'),
  };
}

export async function deleteDocumentTemplate(companyId: number, templateCode: string) {
  const { output } = await callSpOut(
    'usp_HR_DocumentTemplate_Delete',
    {
      CompanyId: companyId,
      TemplateCode: String(templateCode ?? '').trim().toUpperCase(),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? 'Plantilla eliminada'),
  };
}

export async function renderTemplate(
  companyId: number,
  templateCode: string,
  source: { payrollRunId?: number; batchId?: number; employeeCode?: string; }
) {
  // 1. Cargar la plantilla
  const template = await getDocumentTemplate(companyId, templateCode);

  let run: Record<string, any> = {};
  let lines: any[] = [];

  if (source.batchId && source.employeeCode) {
    // ── Modo Batch ────────────────────────────────────────────────────────────

    // 2a. Cargar datos del PayrollBatch
    let batch: Record<string, any> = {};
    try {
      const pool = await getPool();
      const request = pool.request();
      request.input('BatchId', source.batchId);
      request.input('CompanyId', companyId);
      const result = await request.query<any>(
        `SELECT BatchId, PayrollCode, FromDate, ToDate
         FROM hr.PayrollBatch
         WHERE BatchId = @BatchId AND CompanyId = @CompanyId`
      );
      batch = result.recordset[0] ?? {};
    } catch {
      batch = {};
    }

    // 3a. Cargar líneas del PayrollBatchLine para el empleado
    let batchLines: any[] = [];
    try {
      const pool = await getPool();
      const request = pool.request();
      request.input('BatchId', source.batchId);
      request.input('EmployeeCode', source.employeeCode);
      const result = await request.query<any>(
        `SELECT EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName,
                ConceptType, Quantity, Amount, Total
         FROM hr.PayrollBatchLine
         WHERE BatchId = @BatchId AND EmployeeCode = @EmployeeCode
         ORDER BY ConceptType DESC, ConceptCode`
      );
      batchLines = result.recordset ?? [];
    } catch {
      batchLines = [];
    }

    const empLine = batchLines[0] ?? null;

    // 4a. Intentar obtener detalles del empleado via SP
    let empDetail: Record<string, any> | null = null;
    try {
      const empRows = await callSp<any>(
        'usp_HR_Employee_GetByCode',
        { CompanyId: companyId, Cedula: source.employeeCode }
      );
      empDetail = empRows[0] ?? null;
    } catch {
      empDetail = null;
    }

    // 5a. Construir run dict para buildVarsDict
    const totalAssignments = batchLines
      .filter((l) => l.ConceptType !== 'DEDUCCION' && l.ConceptType !== 'PATRONAL')
      .reduce((s, l) => s + Number(l.Total ?? 0), 0);
    const totalDeductions = batchLines
      .filter((l) => l.ConceptType === 'DEDUCCION')
      .reduce((s, l) => s + Number(l.Total ?? 0), 0);

    run = {
      PayrollCode: batch.PayrollCode,
      DateFrom: batch.FromDate,
      DateTo: batch.ToDate,
      EmployeeCode: empLine?.EmployeeCode ?? source.employeeCode,
      EmployeeName: empLine?.EmployeeName ?? empDetail?.EmployeeName ?? '',
      TotalAssignments: totalAssignments,
      TotalDeductions: totalDeductions,
      NetTotal: totalAssignments - totalDeductions,
      HireDate: empDetail?.HireDate ?? null,
      PositionName: empDetail?.PositionName ?? '',
      DepartmentName: empDetail?.DepartmentName ?? '',
    };

    lines = batchLines.map((l) => ({
      ConceptCode: l.ConceptCode,
      ConceptName: l.ConceptName,
      ConceptType: l.ConceptType,
      Total: l.Total,
      Quantity: l.Quantity,
    }));

  } else {
    // ── Modo PayrollRun (legado) ───────────────────────────────────────────────
    const payrollRunId = source.payrollRunId!;

    // 2b. Cargar datos del PayrollRun mediante SP
    try {
      const runRows = await callSp<any>(
        'usp_HR_Payroll_GetRunDetail',
        {
          CompanyId: companyId,
          PayrollRunId: payrollRunId,
        }
      );
      run = runRows[0] ?? {};
    } catch {
      // Si el SP no existe, cargar solo datos básicos del PayrollRun
      const pool = await getPool();
      const request = pool.request();
      request.input('PayrollRunId', payrollRunId);
      request.input('CompanyId', companyId);
      try {
        const result = await request.query<any>(
          `SELECT PayrollRunId, PayrollCode, EmployeeId, DateFrom, DateTo,
                  TotalAssignments, TotalDeductions, NetTotal
           FROM hr.PayrollRun
           WHERE PayrollRunId = @PayrollRunId AND CompanyId = @CompanyId`
        );
        run = result.recordset[0] ?? {};
      } catch {
        run = {};
      }
    }

    // 3b. Cargar líneas del PayrollRun
    try {
      const pool = await getPool();
      const request = pool.request();
      request.input('PayrollRunId', payrollRunId);
      const result = await request.query<any>(
        `SELECT ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total
         FROM hr.PayrollRunLine
         WHERE PayrollRunId = @PayrollRunId
         ORDER BY ConceptType DESC, ConceptCode`
      );
      lines = result.recordset ?? [];
    } catch {
      lines = [];
    }
  }

  // 4. Cargar datos de la empresa
  let company: Record<string, any> = {};
  try {
    const companyRows = await callSp<any>(
      'usp_Cfg_Company_Get',
      { CompanyId: companyId }
    );
    company = companyRows[0] ?? {};
  } catch {
    // Si no existe el SP, consulta directa
    try {
      const pool = await getPool();
      const request = pool.request();
      request.input('CompanyId', companyId);
      const result = await request.query<any>(
        `SELECT LegalName, TradeName, FiscalId, Address, LegalRep, Phone
         FROM cfg.Company
         WHERE CompanyId = @CompanyId`
      );
      company = result.recordset[0] ?? {};
    } catch {
      company = {};
    }
  }

  // 5. Construir diccionario de variables
  const vars = buildVarsDict(run, company);

  // 6. Interpolar variables básicas
  let content: string = template.ContentMD ?? '';
  content = interpolate(content, vars);

  // 7. Reemplazar tablas de conceptos
  content = content.replace(
    /\{\{tabla_asignaciones\}\}/g,
    buildConceptTable(
      lines,
      undefined // Filtra ASIGNACION + BONO
    ).replace(
      // Reemplazamos por una tabla real de asignaciones y bonos
      /\*/g, '*'
    )
  );

  // Tablas específicas
  const tablaAsignaciones = buildConceptTable(
    lines.filter((l) => l.ConceptType === 'ASIGNACION' || l.ConceptType === 'BONO')
  );
  const tablaDeducciones = buildConceptTable(
    lines.filter((l) => l.ConceptType === 'DEDUCCION')
  );
  const tablaTodos = buildConceptTable(
    lines.filter((l) => l.ConceptType !== 'PATRONAL')
  );

  content = content.replace(/\{\{tabla_asignaciones\}\}/g, tablaAsignaciones);
  content = content.replace(/\{\{tabla_deducciones\}\}/g, tablaDeducciones);
  content = content.replace(/\{\{tabla_todos\}\}/g, tablaTodos);

  // 8. Reemplazar conceptos individuales {{concepto.CODIGO.monto}} y {{concepto.CODIGO.cantidad}}
  for (const line of lines) {
    const code = String(line.ConceptCode ?? '').toUpperCase();
    content = content.replace(
      new RegExp(`\\{\\{concepto\\.${escapeRegex(code)}\\.monto\\}\\}`, 'g'),
      formatMoney(line.Total)
    );
    content = content.replace(
      new RegExp(`\\{\\{concepto\\.${escapeRegex(code)}\\.cantidad\\}\\}`, 'g'),
      String(line.Quantity ?? 0)
    );
  }

  return {
    templateCode: template.TemplateCode,
    templateName: template.TemplateName,
    contentRendered: content,
    vars,
    format: 'markdown' as const,
  };
}

export async function renderTemplateFromBatch(
  companyId: number,
  templateCode: string,
  batchId: number,
  employeeCode: string
) {
  return renderTemplate(companyId, templateCode, { batchId, employeeCode });
}

export async function getTemplateVariables(companyId: number, payrollRunId: number) {
  let run: Record<string, any> = {};
  try {
    const runRows = await callSp<any>(
      'usp_HR_Payroll_GetRunDetail',
      { CompanyId: companyId, PayrollRunId: payrollRunId }
    );
    run = runRows[0] ?? {};
  } catch {
    run = {};
  }

  let company: Record<string, any> = {};
  try {
    const companyRows = await callSp<any>(
      'usp_Cfg_Company_Get',
      { CompanyId: companyId }
    );
    company = companyRows[0] ?? {};
  } catch {
    try {
      const pool = await getPool();
      const req = pool.request();
      req.input('CompanyId', companyId);
      const result = await req.query<any>(
        `SELECT LegalName, TradeName, FiscalId, Address, LegalRep, Phone FROM cfg.Company WHERE CompanyId = @CompanyId`
      );
      company = result.recordset[0] ?? {};
    } catch {
      company = {};
    }
  }

  return buildVarsDict(run, company);
}

export async function getTemplateVariablesFromBatch(
  companyId: number,
  batchId: number,
  employeeCode: string
) {
  // Cargar datos del PayrollBatch
  let batch: Record<string, any> = {};
  try {
    const pool = await getPool();
    const request = pool.request();
    request.input('BatchId', batchId);
    request.input('CompanyId', companyId);
    const result = await request.query<any>(
      `SELECT BatchId, PayrollCode, FromDate, ToDate
       FROM hr.PayrollBatch
       WHERE BatchId = @BatchId AND CompanyId = @CompanyId`
    );
    batch = result.recordset[0] ?? {};
  } catch {
    batch = {};
  }

  // Cargar líneas del empleado
  let batchLines: any[] = [];
  try {
    const pool = await getPool();
    const request = pool.request();
    request.input('BatchId', batchId);
    request.input('EmployeeCode', employeeCode);
    const result = await request.query<any>(
      `SELECT EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName,
              ConceptType, Quantity, Amount, Total
       FROM hr.PayrollBatchLine
       WHERE BatchId = @BatchId AND EmployeeCode = @EmployeeCode
       ORDER BY ConceptType DESC, ConceptCode`
    );
    batchLines = result.recordset ?? [];
  } catch {
    batchLines = [];
  }

  const empLine = batchLines[0] ?? null;

  // Intentar obtener detalles del empleado via SP
  let empDetail: Record<string, any> | null = null;
  try {
    const empRows = await callSp<any>(
      'usp_HR_Employee_GetByCode',
      { CompanyId: companyId, Cedula: employeeCode }
    );
    empDetail = empRows[0] ?? null;
  } catch {
    empDetail = null;
  }

  const totalAssignments = batchLines
    .filter((l) => l.ConceptType !== 'DEDUCCION' && l.ConceptType !== 'PATRONAL')
    .reduce((s, l) => s + Number(l.Total ?? 0), 0);
  const totalDeductions = batchLines
    .filter((l) => l.ConceptType === 'DEDUCCION')
    .reduce((s, l) => s + Number(l.Total ?? 0), 0);

  const run: Record<string, any> = {
    PayrollCode: batch.PayrollCode,
    DateFrom: batch.FromDate,
    DateTo: batch.ToDate,
    EmployeeCode: empLine?.EmployeeCode ?? employeeCode,
    EmployeeName: empLine?.EmployeeName ?? empDetail?.EmployeeName ?? '',
    TotalAssignments: totalAssignments,
    TotalDeductions: totalDeductions,
    NetTotal: totalAssignments - totalDeductions,
    HireDate: empDetail?.HireDate ?? null,
    PositionName: empDetail?.PositionName ?? '',
    DepartmentName: empDetail?.DepartmentName ?? '',
  };

  let company: Record<string, any> = {};
  try {
    const companyRows = await callSp<any>(
      'usp_Cfg_Company_Get',
      { CompanyId: companyId }
    );
    company = companyRows[0] ?? {};
  } catch {
    try {
      const pool = await getPool();
      const req = pool.request();
      req.input('CompanyId', companyId);
      const result = await req.query<any>(
        `SELECT LegalName, TradeName, FiscalId, Address, LegalRep, Phone FROM cfg.Company WHERE CompanyId = @CompanyId`
      );
      company = result.recordset[0] ?? {};
    } catch {
      company = {};
    }
  }

  return buildVarsDict(run, company);
}

// ─── Helpers internos ─────────────────────────────────────────────────────────

function buildVarsDict(
  run: Record<string, any>,
  company: Record<string, any>
): Record<string, string> {
  return {
    'empresa.nombre': company.LegalName ?? company.TradeName ?? '',
    'empresa.rif': company.FiscalId ?? '',
    'empresa.direccion': company.Address ?? '',
    'empresa.representante': company.LegalRep ?? '',
    'empresa.telefono': company.Phone ?? '',
    'empleado.nombre': run.EmployeeName ?? '',
    'empleado.cedula': run.EmployeeCode ?? '',
    'empleado.cargo': run.PositionName ?? '',
    'empleado.departamento': run.DepartmentName ?? '',
    'empleado.fechaIngreso': formatDate(run.HireDate),
    'empleado.antiguedad': calcAntiguedad(run.HireDate, run.DateTo),
    'periodo.desde': formatDate(run.DateFrom),
    'periodo.hasta': formatDate(run.DateTo),
    'periodo.tipo': run.PayrollCode ?? '',
    'nomina.tipo': run.PayrollCode ?? '',
    'nomina.totalAsignaciones': formatMoney(run.TotalAssignments),
    'nomina.totalDeducciones': formatMoney(run.TotalDeductions),
    'nomina.neto': formatMoney(run.NetTotal),
    'nomina.netoLetras': numberToWords(Number(run.NetTotal ?? 0)),
    'fecha.generacion': new Date().toLocaleDateString('es-VE'),
    'anio': new Date().getFullYear().toString(),
    'mes': new Date().toLocaleDateString('es-VE', { month: 'long' }),
    'liquidacion.causa': 'Renuncia Voluntaria',
  };
}

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
