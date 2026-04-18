/**
 * Generador Modelo 190 AEAT — Resumen anual retenciones IRPF.
 * Formato TXT con registro de cabecera + N registros de perceptor.
 * REF: https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/iva/modelo-190.html
 */
import { CRLF, padAlpha, padDecimal, padInt, padNIF, padYear } from "./boe-txt.util.js";

export interface Modelo190Perceptor {
  nif: string;
  apellidosNombre: string;
  /** Clave: A (trabajo), G (actividades profesionales), etc. */
  clave: string;
  subClave?: string;
  provincia?: string;
  /** Percepciones integras anuales */
  percepciones: number;
  /** Retenciones anuales */
  retenciones: number;
  /** Percepciones en especie (si aplica) */
  percepcionesEspecie?: number;
  ingresoCuentaEspecie?: number;
}

export interface Modelo190Input {
  declarante: { nif: string; razonSocial: string };
  ejercicio: number;
  perceptores: Modelo190Perceptor[];
  numeroJustificante?: string;
}

export function generateModelo190(input: Modelo190Input): string {
  const { declarante, ejercicio, perceptores } = input;

  const totalPercepciones = perceptores.reduce((a, p) => a + p.percepciones, 0);
  const totalRetenciones = perceptores.reduce((a, p) => a + p.retenciones, 0);

  // Registro tipo 1 — Cabecera (ancho tipico 250 bytes)
  const header =
    "1" +
    padAlpha("190", 3) +
    padYear(ejercicio) +
    padNIF(declarante.nif) +
    padAlpha(declarante.razonSocial, 40) +
    padInt(perceptores.length, 9) +
    padDecimal(totalPercepciones, 15, 2) +
    padDecimal(totalRetenciones, 15, 2) +
    padAlpha(input.numeroJustificante ?? "", 13) +
    CRLF;

  // Registros tipo 2 — Un registro por perceptor
  const records = perceptores.map((p) =>
    "2" +
    padAlpha("190", 3) +
    padYear(ejercicio) +
    padNIF(declarante.nif) +
    padNIF(p.nif) +
    padAlpha(p.apellidosNombre, 40) +
    padAlpha(p.clave, 1) +
    padAlpha(p.subClave ?? "", 2) +
    padAlpha(p.provincia ?? "", 2) +
    padDecimal(p.percepciones, 13, 2) +
    padDecimal(p.retenciones, 13, 2) +
    padDecimal(p.percepcionesEspecie ?? 0, 13, 2) +
    padDecimal(p.ingresoCuentaEspecie ?? 0, 13, 2) +
    CRLF
  ).join("");

  return header + records;
}
