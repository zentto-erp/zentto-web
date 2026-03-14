import { callSp } from "../../db/query.js";
import { procesarNominaEmpleado, procesarVacaciones, calcularLiquidacion } from "./service.js";
import { getActiveScope } from "../_shared/scope.js";

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
  const activeScope = getActiveScope();
  if (activeScope?.companyId) return activeScope.companyId;
  const rows = await callSp<{ companyId: number }>(
    "usp_Cfg_ResolveContext"
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

  const rows = await callSp<ConceptoLegal>(
    "usp_HR_LegalConcept_List",
    {
      CompanyId: companyId,
      ConventionCode: params.convencion?.trim().toUpperCase() || null,
      CalculationType: params.tipoCalculo?.trim().toUpperCase() || null,
      ConceptType: params.tipo?.trim().toUpperCase() || null,
      SoloActivos: params.activo !== false ? 1 : 0,
    }
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

  const concepts = await callSp<{
    coConcept: string;
    nbConcepto: string;
    formula: string | null;
    defaultValue: number;
  }>(
    "usp_HR_LegalConcept_ValidateFormulas",
    {
      CompanyId: companyId,
      ConventionCode: params.convencion?.trim().toUpperCase() || null,
      CalculationType: params.tipoCalculo?.trim().toUpperCase() || null,
    }
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
  return callSp<any>(
    "usp_HR_LegalConcept_ListConventions",
    { CompanyId: companyId }
  );
}
