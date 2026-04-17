/**
 * Utilidades formato TXT ancho fijo BOE/AEAT.
 * Los modelos AEAT (303, 390, 111, 190, 347) usan TXT con codificacion ISO-8859-1.
 *
 * Reglas BOE:
 * - Alfabetico: alineado izquierda, relleno con espacios a la derecha
 * - Numerico entero: alineado derecha, relleno con ceros a la izquierda
 * - Numerico decimal: sin punto decimal, ultimos N digitos son decimales
 * - Fecha: AAAAMMDD (8 digitos)
 * - Signos: N = negativo (saldo negativo), espacio = positivo
 */

/** Rellena texto alfanumerico a la derecha (alinea izquierda) con espacios. */
export function padAlpha(value: string | null | undefined, length: number): string {
  const raw = String(value ?? "").toUpperCase().replace(/[ÁÉÍÓÚÜÑ]/g, (c) => {
    const map: Record<string, string> = { 'Á':'A','É':'E','Í':'I','Ó':'O','Ú':'U','Ü':'U','Ñ':'N' };
    return map[c] ?? c;
  });
  // Elimina acentos y caracteres no alfanumericos basicos
  const clean = raw.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^A-Z0-9 \.\-\/]/g, " ");
  return clean.length >= length ? clean.substring(0, length) : clean + " ".repeat(length - clean.length);
}

/** Rellena entero a la izquierda con ceros. */
export function padInt(value: number | null | undefined, length: number): string {
  const n = value ?? 0;
  const str = String(Math.trunc(Math.abs(n)));
  return str.length >= length ? str.substring(str.length - length) : "0".repeat(length - str.length) + str;
}

/**
 * Numerico con decimales — sin punto decimal, relleno con ceros izquierda.
 * Si length=13 y decimals=2, 1234.56 -> "0000000123456"
 * Si length=15 y decimals=2 y negativo: -100.50 -> "N00000000010050"
 */
export function padDecimal(value: number | null | undefined, length: number, decimals = 2, signed = false): string {
  const n = value ?? 0;
  const isNegative = n < 0;
  const abs = Math.abs(n);
  const multiplied = Math.round(abs * Math.pow(10, decimals));
  const str = String(multiplied);
  const totalDigits = signed ? length - 1 : length;
  const padded = str.length >= totalDigits ? str.substring(str.length - totalDigits) : "0".repeat(totalDigits - str.length) + str;
  return signed ? (isNegative ? "N" : " ") + padded : padded;
}

/** Formato fecha AAAAMMDD. */
export function padDate(date: Date | string | null | undefined): string {
  if (!date) return "00000000";
  const d = typeof date === "string" ? new Date(date) : date;
  const y = String(d.getUTCFullYear()).padStart(4, "0");
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  return y + m + dd;
}

/** NIF/CIF: 9 caracteres alineado izquierda. */
export function padNIF(nif: string | null | undefined): string {
  return padAlpha(String(nif ?? "").replace(/[^A-Z0-9]/gi, ""), 9);
}

/** Ejercicio fiscal 4 digitos. */
export function padYear(year: number): string {
  return padInt(year, 4);
}

/** Periodo trimestral: "1T", "2T", "3T", "4T". */
export function padQuarter(q: number): string {
  const qStr = Math.max(1, Math.min(4, q));
  return `${qStr}T`;
}

/** Numero de registro de 4 digitos (relleno con ceros). */
export function padRegNumber(n: number): string {
  return padInt(n, 4);
}

/** Une strings y valida longitud total (util para debug). */
export function assembleRecord(parts: Array<{ name: string; value: string; length: number }>): string {
  const errors: string[] = [];
  let result = "";
  for (const p of parts) {
    if (p.value.length !== p.length) {
      errors.push(`Campo '${p.name}' tiene longitud ${p.value.length}, esperado ${p.length}`);
    }
    result += p.value;
  }
  if (errors.length > 0) {
    throw new Error(`BOE TXT assembly errors:\n${errors.join("\n")}`);
  }
  return result;
}

/** CRLF final de linea (BOE/AEAT usan CRLF). */
export const CRLF = "\r\n";
