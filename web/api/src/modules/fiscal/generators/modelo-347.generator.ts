/**
 * Generador Modelo 347 AEAT — Declaracion operaciones con terceros (>3005.06 EUR anual).
 * REF: https://sede.agenciatributaria.gob.es/Sede/todas-gestiones/impuestos/modelo-347.html
 */
import { CRLF, padAlpha, padDecimal, padInt, padNIF, padYear } from "./boe-txt.util.js";

export interface Modelo347Operacion {
  nif: string;
  /** Razon social o apellidos */
  nombre: string;
  /** Codigo pais si no es ES */
  codigoPais?: string;
  /** Provincia (2 digitos) */
  provincia?: string;
  /** Clave operacion: A=Adquisiciones, B=Entregas, ... */
  claveOperacion: "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H";
  /** Importe total operaciones anuales */
  importeAnual: number;
  /** Importes trimestrales (Q1, Q2, Q3, Q4) */
  importesTrimestrales: [number, number, number, number];
  /** Operaciones afectas SII (opcional) */
  siiOperaciones?: number;
}

export interface Modelo347Input {
  declarante: { nif: string; razonSocial: string };
  ejercicio: number;
  operaciones: Modelo347Operacion[];
  numeroJustificante?: string;
}

export function generateModelo347(input: Modelo347Input): string {
  const { declarante, ejercicio, operaciones } = input;
  const totalOp = operaciones.length;
  const totalImp = operaciones.reduce((a, o) => a + o.importeAnual, 0);

  const header =
    "1" +
    padAlpha("347", 3) +
    padYear(ejercicio) +
    padNIF(declarante.nif) +
    padAlpha(declarante.razonSocial, 40) +
    padInt(totalOp, 9) +
    padDecimal(totalImp, 15, 2) +
    padAlpha(input.numeroJustificante ?? "", 13) +
    CRLF;

  const records = operaciones.map((op) =>
    "2" +
    padAlpha("347", 3) +
    padYear(ejercicio) +
    padNIF(declarante.nif) +
    padNIF(op.nif) +
    padAlpha(op.nombre, 40) +
    padAlpha(op.codigoPais ?? "ES", 2) +
    padAlpha(op.provincia ?? "", 2) +
    padAlpha(op.claveOperacion, 1) +
    padDecimal(op.importeAnual, 16, 2, true) +
    padDecimal(op.importesTrimestrales[0] ?? 0, 16, 2, true) +
    padDecimal(op.importesTrimestrales[1] ?? 0, 16, 2, true) +
    padDecimal(op.importesTrimestrales[2] ?? 0, 16, 2, true) +
    padDecimal(op.importesTrimestrales[3] ?? 0, 16, 2, true) +
    padDecimal(op.siiOperaciones ?? 0, 16, 2, true) +
    CRLF
  ).join("");

  return header + records;
}
