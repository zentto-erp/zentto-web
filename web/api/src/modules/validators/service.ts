/**
 * Validadores identificación España (NIF/NIE/CIF/IBAN).
 * Wrappers a funciones PL/pgSQL fn_validate_*_es creadas en migration 00110.
 */
import { query } from "../../db/query.js";

async function callValidator(fn: string, value: string): Promise<boolean> {
  const rows = await query<{ valid: boolean }>(
    `SELECT ${fn}(@value) AS valid`,
    { value }
  );
  return Boolean(rows?.[0]?.valid);
}

export async function validateNIF(nif: string): Promise<boolean> {
  if (!nif) return false;
  return callValidator("fn_validate_nif_es", nif);
}

export async function validateNIE(nie: string): Promise<boolean> {
  if (!nie) return false;
  return callValidator("fn_validate_nie_es", nie);
}

export async function validateCIF(cif: string): Promise<boolean> {
  if (!cif) return false;
  return callValidator("fn_validate_cif_es", cif);
}

export async function validateIBAN(iban: string): Promise<boolean> {
  if (!iban) return false;
  return callValidator("fn_validate_iban_es", iban);
}
