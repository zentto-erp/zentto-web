import { query } from "../../db/query.js";
import { procesarNominaEmpleado, procesarVacaciones, calcularLiquidacion } from "./service.js";

export interface ConceptoLegal {
  id?: number;
  convencion: string;
  tipoCalculo: string;
  coConcept: string;
  nbConcepto?: string;
  formula?: string;
  sobre?: string;
  tipo?: "ASIGNACION" | "DEDUCCION" | "BONO";
  bonificable?: string;
  lotttArticulo?: string;
  ccpClausula?: string;
  orden?: number;
  activo?: boolean;
}

export interface NominaResult {
  success: boolean;
  message: string;
  nomina?: string;
  cedula?: string;
  asignaciones?: number;
  deducciones?: number;
  neto?: number;
}

async function getDefaultCompanyId() {
  const rows = await query<{ companyId: number }>(
    `
    SELECT TOP 1 CompanyId AS companyId
    FROM cfg.Company
    WHERE CompanyCode = N'DEFAULT'
    ORDER BY CompanyId
    `
  );
  return Number(rows[0]?.companyId ?? 1);
}

export async function listConceptosLegales(params: {
  convencion?: string;
  tipoCalculo?: string;
  tipo?: string;
  activo?: boolean;
}) {
  const companyId = await getDefaultCompanyId();
  const where: string[] = ["CompanyId = @companyId", "ConventionCode IS NOT NULL"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.activo !== false) where.push("IsActive = 1");
  if (params.convencion?.trim()) {
    where.push("ConventionCode = @conventionCode");
    sqlParams.conventionCode = params.convencion.trim().toUpperCase();
  }
  if (params.tipoCalculo?.trim()) {
    where.push("CalculationType = @calculationType");
    sqlParams.calculationType = params.tipoCalculo.trim().toUpperCase();
  }
  if (params.tipo?.trim()) {
    where.push("ConceptType = @conceptType");
    sqlParams.conceptType = params.tipo.trim().toUpperCase();
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<ConceptoLegal>(
    `
    SELECT
      PayrollConceptId AS id,
      ConventionCode AS convencion,
      CalculationType AS tipoCalculo,
      ConceptCode AS coConcept,
      ConceptName AS nbConcepto,
      Formula AS formula,
      BaseExpression AS sobre,
      ConceptType AS tipo,
      CASE WHEN IsBonifiable = 1 THEN N'S' ELSE N'N' END AS bonificable,
      LotttArticle AS lotttArticulo,
      CcpClause AS ccpClausula,
      SortOrder AS orden,
      IsActive AS activo
    FROM hr.PayrollConcept
    ${clause}
    ORDER BY ConventionCode, CalculationType, SortOrder, ConceptCode
    `,
    sqlParams
  );

  return { rows };
}

export async function procesarNominaConceptoLegal(payload: {
  nomina: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  convencion?: string;
  tipoCalculo?: string;
  codUsuario?: string;
}): Promise<NominaResult> {
  const result = await procesarNominaEmpleado(
    {
      nomina: payload.nomina,
      cedula: payload.cedula,
      fechaInicio: payload.fechaInicio,
      fechaHasta: payload.fechaHasta,
      codUsuario: payload.codUsuario,
    },
    {
      conventionCode: payload.convencion,
      calculationType: payload.tipoCalculo,
      soloConceptosLegales: true,
    }
  );

  return {
    success: Boolean(result.success),
    message: String(result.message ?? ""),
    nomina: payload.nomina,
    cedula: payload.cedula,
    asignaciones: (result as any).asignaciones,
    deducciones: (result as any).deducciones,
    neto: (result as any).neto,
  };
}

export async function validarFormulasConceptos(params: {
  convencion?: string;
  tipoCalculo?: string;
}) {
  const companyId = await getDefaultCompanyId();
  const where: string[] = ["CompanyId = @companyId", "ConventionCode IS NOT NULL", "IsActive = 1"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.convencion?.trim()) {
    where.push("ConventionCode = @conventionCode");
    sqlParams.conventionCode = params.convencion.trim().toUpperCase();
  }
  if (params.tipoCalculo?.trim()) {
    where.push("CalculationType = @calculationType");
    sqlParams.calculationType = params.tipoCalculo.trim().toUpperCase();
  }

  const concepts = await query<{
    coConcept: string;
    nbConcepto: string;
    formula: string | null;
    defaultValue: number;
  }>(
    `
    SELECT
      ConceptCode AS coConcept,
      ConceptName AS nbConcepto,
      Formula AS formula,
      DefaultValue AS defaultValue
    FROM hr.PayrollConcept
    WHERE ${where.join(" AND ")}
    ORDER BY SortOrder, ConceptCode
    `,
    sqlParams
  );

  const formulaPattern = /^[A-Za-z0-9_+\-*/().\s]*$/;
  const errores = concepts
    .map((item) => {
      const formula = String(item.formula ?? "").trim();
      if (!formula && Number(item.defaultValue ?? 0) === 0) {
        return { coConcept: item.coConcept, nbConcepto: item.nbConcepto, error: "Sin formula y sin valor por defecto" };
      }
      if (formula && !formulaPattern.test(formula)) {
        return { coConcept: item.coConcept, nbConcepto: item.nbConcepto, error: "Formula contiene caracteres no permitidos" };
      }
      return null;
    })
    .filter((row): row is { coConcept: string; nbConcepto: string; error: string } => row !== null);

  return {
    resumen: {
      totalConceptos: concepts.length,
      conError: errores.length,
      validos: concepts.length - errores.length,
    },
    errores,
  };
}

export async function procesarVacacionesConceptoLegal(payload: {
  vacacionId: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  fechaReintegro?: string;
  convencion?: string;
  codUsuario?: string;
}) {
  return procesarVacaciones({
    vacacionId: payload.vacacionId,
    cedula: payload.cedula,
    fechaInicio: payload.fechaInicio,
    fechaHasta: payload.fechaHasta,
    fechaReintegro: payload.fechaReintegro,
    codUsuario: payload.codUsuario,
  });
}

export async function procesarLiquidacionConceptoLegal(payload: {
  liquidacionId: string;
  cedula: string;
  fechaRetiro: string;
  causaRetiro?: string;
  convencion?: string;
  codUsuario?: string;
}) {
  return calcularLiquidacion({
    liquidacionId: payload.liquidacionId,
    cedula: payload.cedula,
    fechaRetiro: payload.fechaRetiro,
    causaRetiro: payload.causaRetiro,
    codUsuario: payload.codUsuario,
  });
}

export async function getConvencionesDisponibles() {
  const companyId = await getDefaultCompanyId();
  return query<any>(
    `
    SELECT
      ConventionCode AS Convencion,
      COUNT(1) AS TotalConceptos,
      COUNT(CASE WHEN CalculationType = 'MENSUAL' THEN 1 END) AS ConceptosMensual,
      COUNT(CASE WHEN CalculationType = 'VACACIONES' THEN 1 END) AS ConceptosVacaciones,
      COUNT(CASE WHEN CalculationType = 'LIQUIDACION' THEN 1 END) AS ConceptosLiquidacion,
      MIN(SortOrder) AS OrdenInicio,
      MAX(SortOrder) AS OrdenFin
    FROM hr.PayrollConcept
    WHERE CompanyId = @companyId
      AND IsActive = 1
      AND ConventionCode IS NOT NULL
    GROUP BY ConventionCode
    ORDER BY ConventionCode
    `,
    { companyId }
  );
}
