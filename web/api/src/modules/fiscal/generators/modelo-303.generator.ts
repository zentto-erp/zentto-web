/**
 * Generador Modelo 303 AEAT — Autoliquidacion IVA trimestral.
 * Formato TXT ancho fijo segun Orden Ministerial (BOE).
 *
 * Estructura simplificada:
 * - Registro tipo 1: Cabecera (50+ campos)
 * - Registro tipo 2: Datos adicionales
 *
 * REF: https://sede.agenciatributaria.gob.es/Sede/todas-gestiones/impuestos-tasas/iva/modelo-303-iva-autoliquidacion_.html
 *
 * NOTA: Esta es una implementacion v1 con los campos mas criticos. La version
 * oficial completa tiene 200+ campos. Valida contra el validador AEAT antes de presentar.
 */
import { CRLF, padAlpha, padDate, padDecimal, padInt, padNIF, padQuarter, padYear } from "./boe-txt.util.js";

export interface Modelo303Input {
  /** NIF del declarante */
  nif: string;
  /** Nombre/Razon social */
  razonSocial: string;
  /** Ejercicio fiscal (ano) */
  ejercicio: number;
  /** Periodo: 1, 2, 3, 4 (trimestres) */
  periodo: number;
  /** IVA devengado (ventas) */
  ivaDevengado: {
    /** Base imponible regimen general 21% */
    baseGeneral21: number;
    cuotaGeneral21: number;
    /** Regimen general 10% */
    baseGeneral10: number;
    cuotaGeneral10: number;
    /** Regimen general 4% */
    baseGeneral4: number;
    cuotaGeneral4: number;
    /** Recargo equivalencia (si aplica) */
    baseRE?: number;
    cuotaRE?: number;
    /** Total base imponible */
    totalBase?: number;
    /** Total cuota devengada */
    totalCuota?: number;
  };
  ivaDeducible: {
    /** IVA soportado en operaciones interiores corrientes */
    baseCorriente: number;
    cuotaCorriente: number;
    /** IVA soportado bienes inversion */
    baseInversion: number;
    cuotaInversion: number;
    /** Total deducible */
    totalDeducible?: number;
  };
  /** Resultado de la liquidacion (devengado - deducible) */
  resultado?: number;
  /** Fecha presentacion */
  fechaPresentacion?: Date;
  /** Numero justificante */
  numeroJustificante?: string;
}

export function generateModelo303(input: Modelo303Input): string {
  const {
    nif, razonSocial, ejercicio, periodo,
    ivaDevengado, ivaDeducible,
  } = input;

  // Calcular totales si no vienen
  const totalBaseDevengada = ivaDevengado.totalBase ??
    (ivaDevengado.baseGeneral21 + ivaDevengado.baseGeneral10 + ivaDevengado.baseGeneral4 + (ivaDevengado.baseRE ?? 0));
  const totalCuotaDevengada = ivaDevengado.totalCuota ??
    (ivaDevengado.cuotaGeneral21 + ivaDevengado.cuotaGeneral10 + ivaDevengado.cuotaGeneral4 + (ivaDevengado.cuotaRE ?? 0));
  const totalDeducible = ivaDeducible.totalDeducible ?? (ivaDeducible.cuotaCorriente + ivaDeducible.cuotaInversion);
  const resultado = input.resultado ?? (totalCuotaDevengada - totalDeducible);

  // ─── Registro tipo 1: Cabecera ────────────────────────────────────
  const header =
    "1" +                               // Tipo registro (1 byte)
    padAlpha("303", 3) +                // Modelo (3 bytes)
    padYear(ejercicio) +                // Ejercicio AAAA (4 bytes)
    padQuarter(periodo) +               // Periodo 1T/2T/3T/4T (2 bytes)
    padNIF(nif) +                       // NIF declarante (9 bytes)
    padAlpha(razonSocial, 60) +         // Apellidos/Razon social (60 bytes)
    // Datos IVA devengado - Regimen General
    padDecimal(ivaDevengado.baseGeneral21, 17, 2) +   // Base 21% (17)
    padDecimal(21, 5, 2) +                             // Tipo 21.00 (5)
    padDecimal(ivaDevengado.cuotaGeneral21, 17, 2) +  // Cuota 21% (17)
    padDecimal(ivaDevengado.baseGeneral10, 17, 2) +   // Base 10%
    padDecimal(10, 5, 2) +                             // Tipo 10.00
    padDecimal(ivaDevengado.cuotaGeneral10, 17, 2) +  // Cuota 10%
    padDecimal(ivaDevengado.baseGeneral4, 17, 2) +    // Base 4%
    padDecimal(4, 5, 2) +                              // Tipo 4.00
    padDecimal(ivaDevengado.cuotaGeneral4, 17, 2) +   // Cuota 4%
    // Recargo Equivalencia (opcional)
    padDecimal(ivaDevengado.baseRE ?? 0, 17, 2) +
    padDecimal(ivaDevengado.cuotaRE ?? 0, 17, 2) +
    // Totales devengado
    padDecimal(totalBaseDevengada, 17, 2) +
    padDecimal(totalCuotaDevengada, 17, 2) +
    // Datos IVA deducible
    padDecimal(ivaDeducible.baseCorriente, 17, 2) +
    padDecimal(ivaDeducible.cuotaCorriente, 17, 2) +
    padDecimal(ivaDeducible.baseInversion, 17, 2) +
    padDecimal(ivaDeducible.cuotaInversion, 17, 2) +
    padDecimal(totalDeducible, 17, 2) +
    // Resultado liquidacion
    padDecimal(resultado, 17, 2, true) +               // Con signo N = negativo
    // Fecha presentacion
    padDate(input.fechaPresentacion ?? new Date()) +
    padAlpha(input.numeroJustificante ?? "", 13);

  return header + CRLF;
}

/** Parsea input del API (tax-book entries) y arma Modelo303Input */
export function buildModelo303FromTaxBook(
  declarante: { nif: string; razonSocial: string },
  ejercicio: number,
  periodo: number,
  entries: Array<{
    bookType: "SALES" | "PURCHASES" | string;
    taxableBase: number;
    taxRate: number;
    taxAmount: number;
    isInvestment?: boolean;
  }>
): Modelo303Input {
  const sales = entries.filter((e) => e.bookType === "SALES");
  const purchases = entries.filter((e) => e.bookType === "PURCHASES");

  const sum = (arr: typeof entries, predicate: (e: typeof entries[0]) => boolean, field: "taxableBase" | "taxAmount") =>
    arr.filter(predicate).reduce((a, b) => a + Number(b[field] ?? 0), 0);

  return {
    nif: declarante.nif,
    razonSocial: declarante.razonSocial,
    ejercicio,
    periodo,
    ivaDevengado: {
      baseGeneral21: sum(sales, (e) => Math.abs(e.taxRate - 0.21) < 0.001, "taxableBase"),
      cuotaGeneral21: sum(sales, (e) => Math.abs(e.taxRate - 0.21) < 0.001, "taxAmount"),
      baseGeneral10: sum(sales, (e) => Math.abs(e.taxRate - 0.10) < 0.001, "taxableBase"),
      cuotaGeneral10: sum(sales, (e) => Math.abs(e.taxRate - 0.10) < 0.001, "taxAmount"),
      baseGeneral4: sum(sales, (e) => Math.abs(e.taxRate - 0.04) < 0.001, "taxableBase"),
      cuotaGeneral4: sum(sales, (e) => Math.abs(e.taxRate - 0.04) < 0.001, "taxAmount"),
    },
    ivaDeducible: {
      baseCorriente: sum(purchases, (e) => !e.isInvestment, "taxableBase"),
      cuotaCorriente: sum(purchases, (e) => !e.isInvestment, "taxAmount"),
      baseInversion: sum(purchases, (e) => !!e.isInvestment, "taxableBase"),
      cuotaInversion: sum(purchases, (e) => !!e.isInvestment, "taxAmount"),
    },
  };
}
