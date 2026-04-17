/**
 * Generador Modelo 111 AEAT — Retenciones IRPF trimestral.
 * Formato TXT ancho fijo BOE.
 * REF: https://sede.agenciatributaria.gob.es/Sede/irpf/modelo-111.html
 */
import { CRLF, padAlpha, padDate, padDecimal, padInt, padNIF, padQuarter, padYear } from "./boe-txt.util.js";

export interface Modelo111Input {
  nif: string;
  razonSocial: string;
  ejercicio: number;
  periodo: number;
  /** Retenciones rendimientos trabajo */
  rendimientosTrabajo: {
    numPerceptores: number;
    baseRetenciones: number;
    importeRetenciones: number;
  };
  /** Retenciones actividades economicas (profesionales, autonomos) */
  actividadesEconomicas: {
    numPerceptores: number;
    baseRetenciones: number;
    importeRetenciones: number;
  };
  /** Retenciones premios */
  premios?: {
    numPerceptores: number;
    baseRetenciones: number;
    importeRetenciones: number;
  };
  /** Retenciones ganancias patrimoniales (aprovechamiento forestal) */
  gananciasForest?: {
    numPerceptores: number;
    baseRetenciones: number;
    importeRetenciones: number;
  };
  /** Total retenciones a ingresar */
  totalIngresar?: number;
  fechaPresentacion?: Date;
  numeroJustificante?: string;
}

export function generateModelo111(input: Modelo111Input): string {
  const total = input.totalIngresar ??
    (input.rendimientosTrabajo.importeRetenciones +
     input.actividadesEconomicas.importeRetenciones +
     (input.premios?.importeRetenciones ?? 0) +
     (input.gananciasForest?.importeRetenciones ?? 0));

  return (
    "1" +
    padAlpha("111", 3) +
    padYear(input.ejercicio) +
    padQuarter(input.periodo) +
    padNIF(input.nif) +
    padAlpha(input.razonSocial, 60) +
    // Rendimientos trabajo
    padInt(input.rendimientosTrabajo.numPerceptores, 9) +
    padDecimal(input.rendimientosTrabajo.baseRetenciones, 15, 2) +
    padDecimal(input.rendimientosTrabajo.importeRetenciones, 15, 2) +
    // Actividades economicas
    padInt(input.actividadesEconomicas.numPerceptores, 9) +
    padDecimal(input.actividadesEconomicas.baseRetenciones, 15, 2) +
    padDecimal(input.actividadesEconomicas.importeRetenciones, 15, 2) +
    // Premios
    padInt(input.premios?.numPerceptores ?? 0, 9) +
    padDecimal(input.premios?.baseRetenciones ?? 0, 15, 2) +
    padDecimal(input.premios?.importeRetenciones ?? 0, 15, 2) +
    // Ganancias forestales
    padInt(input.gananciasForest?.numPerceptores ?? 0, 9) +
    padDecimal(input.gananciasForest?.baseRetenciones ?? 0, 15, 2) +
    padDecimal(input.gananciasForest?.importeRetenciones ?? 0, 15, 2) +
    // Total
    padDecimal(total, 15, 2, true) +
    padDate(input.fechaPresentacion ?? new Date()) +
    padAlpha(input.numeroJustificante ?? "", 13) +
    CRLF
  );
}
