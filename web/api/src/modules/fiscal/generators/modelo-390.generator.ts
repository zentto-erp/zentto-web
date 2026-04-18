/**
 * Generador Modelo 390 AEAT — Resumen anual IVA.
 * REF: https://sede.agenciatributaria.gob.es/Sede/todas-gestiones/impuestos-tasas/iva/modelo-390.html
 */
import { CRLF, padAlpha, padDate, padDecimal, padInt, padNIF, padYear } from "./boe-txt.util.js";

export interface Modelo390Input {
  declarante: { nif: string; razonSocial: string };
  ejercicio: number;
  /** Agregado anual de los 4 trimestres */
  anual: {
    baseGeneral21: number;
    cuotaGeneral21: number;
    baseGeneral10: number;
    cuotaGeneral10: number;
    baseGeneral4: number;
    cuotaGeneral4: number;
    baseRE?: number;
    cuotaRE?: number;
    totalBase?: number;
    totalCuota?: number;
    // Deducible
    baseDeducibleCorriente: number;
    cuotaDeducibleCorriente: number;
    baseDeducibleInversion: number;
    cuotaDeducibleInversion: number;
    totalDeducible?: number;
    resultadoAnual?: number;
  };
  fechaPresentacion?: Date;
  numeroJustificante?: string;
}

export function generateModelo390(input: Modelo390Input): string {
  const a = input.anual;
  const totalBase = a.totalBase ?? (a.baseGeneral21 + a.baseGeneral10 + a.baseGeneral4 + (a.baseRE ?? 0));
  const totalCuota = a.totalCuota ?? (a.cuotaGeneral21 + a.cuotaGeneral10 + a.cuotaGeneral4 + (a.cuotaRE ?? 0));
  const totalDeducible = a.totalDeducible ?? (a.cuotaDeducibleCorriente + a.cuotaDeducibleInversion);
  const resultado = a.resultadoAnual ?? (totalCuota - totalDeducible);

  return (
    "1" +
    padAlpha("390", 3) +
    padYear(input.ejercicio) +
    "0A" +                                              // Periodo anual
    padNIF(input.declarante.nif) +
    padAlpha(input.declarante.razonSocial, 60) +
    padDecimal(a.baseGeneral21, 17, 2) +
    padDecimal(21, 5, 2) +
    padDecimal(a.cuotaGeneral21, 17, 2) +
    padDecimal(a.baseGeneral10, 17, 2) +
    padDecimal(10, 5, 2) +
    padDecimal(a.cuotaGeneral10, 17, 2) +
    padDecimal(a.baseGeneral4, 17, 2) +
    padDecimal(4, 5, 2) +
    padDecimal(a.cuotaGeneral4, 17, 2) +
    padDecimal(a.baseRE ?? 0, 17, 2) +
    padDecimal(a.cuotaRE ?? 0, 17, 2) +
    padDecimal(totalBase, 17, 2) +
    padDecimal(totalCuota, 17, 2) +
    padDecimal(a.baseDeducibleCorriente, 17, 2) +
    padDecimal(a.cuotaDeducibleCorriente, 17, 2) +
    padDecimal(a.baseDeducibleInversion, 17, 2) +
    padDecimal(a.cuotaDeducibleInversion, 17, 2) +
    padDecimal(totalDeducible, 17, 2) +
    padDecimal(resultado, 17, 2, true) +
    padDate(input.fechaPresentacion ?? new Date()) +
    padAlpha(input.numeroJustificante ?? "", 13) +
    CRLF
  );
}
