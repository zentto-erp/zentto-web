import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp, callSpOut } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface BankMovementAccountingInput {
  movimientoId: number;
  nroCta: string;
  tipo: string;  // DEP, PCH, NCR, NDB, IDB
  monto: number;
  beneficiario: string;
  concepto: string;
  nroRef: string;
}

export interface BankMovementAccountingResult {
  ok: boolean;
  skipped?: boolean;
  reason?: string;
  asientoId?: number | null;
  numeroAsiento?: string | null;
  mensaje?: string;
}

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

async function hasContabilidadInfra(): Promise<boolean> {
  const rows = await callSp<{ ok: number }>("dbo.usp_Acct_Infra_Check");
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function accountExists(accountCode: string): Promise<boolean> {
  // Get scope from getActiveScope or default
  let companyId = 1;
  const active = getActiveScope();
  if (active) companyId = active.companyId;

  const rows = await callSp<{ ok: number }>(
    "dbo.usp_Acct_Account_Exists",
    { CompanyId: companyId, AccountCode: accountCode }
  );
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function pickFirstExistingAccount(candidates: string[]): Promise<string | null> {
  for (const c of candidates) {
    if (!c) continue;
    if (await accountExists(c)) return c;
  }
  return null;
}

// Map movement type to debit/credit accounts
function resolveAccountMapping(tipo: string): { debitCandidates: string[]; creditCandidates: string[]; concept: string } {
  const normalized = tipo.trim().toUpperCase();
  switch (normalized) {
    case "DEP": // Depósito: DEBE Bancos, HABER Ingresos
      return {
        debitCandidates: ["1.1.02", "1.1.01"],
        creditCandidates: ["4.1.01", "4.2.01"],
        concept: "Depósito bancario"
      };
    case "PCH": // Pago Cheque: DEBE Gastos, HABER Bancos
      return {
        debitCandidates: ["5.1.01", "5.1.02", "6.1.01"],
        creditCandidates: ["1.1.02", "1.1.01"],
        concept: "Pago con cheque"
      };
    case "NCR": // Nota de Crédito: DEBE Bancos, HABER Ajustes
      return {
        debitCandidates: ["1.1.02", "1.1.01"],
        creditCandidates: ["4.1.01", "4.2.01"],
        concept: "Nota de crédito bancaria"
      };
    case "NDB": // Nota de Débito: DEBE Gastos, HABER Bancos
      return {
        debitCandidates: ["5.1.01", "6.1.01", "5.1.02"],
        creditCandidates: ["1.1.02", "1.1.01"],
        concept: "Nota de débito bancaria"
      };
    case "IDB": // Ingreso a Débito: DEBE Bancos, HABER Ingresos financieros
      return {
        debitCandidates: ["1.1.02", "1.1.01"],
        creditCandidates: ["4.2.01", "4.1.01"],
        concept: "Ingreso a débito"
      };
    default:
      return {
        debitCandidates: ["1.1.02"],
        creditCandidates: ["4.1.01"],
        concept: "Movimiento bancario"
      };
  }
}

export async function emitBankMovementAccountingEntry(
  input: BankMovementAccountingInput,
  codUsuario?: string
): Promise<BankMovementAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.monto));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    const mapping = resolveAccountMapping(input.tipo);
    const debitAccount = await pickFirstExistingAccount(mapping.debitCandidates);
    const creditAccount = await pickFirstExistingAccount(mapping.creditCandidates);

    if (!debitAccount || !creditAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const originDocument = `BANCO:${input.movimientoId}`;
    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: `${mapping.concept} - ${input.beneficiario}`,
        centroCosto: "BAN",
        documento: input.nroRef,
        debe: amount,
        haber: 0
      },
      {
        codCuenta: creditAccount,
        descripcion: `${mapping.concept} - ${input.concepto}`,
        centroCosto: "BAN",
        documento: input.nroRef,
        debe: 0,
        haber: amount
      }
    ];

    const asiento = await crearAsiento(
      {
        fecha: new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.nroRef,
        concepto: `${mapping.concept}: ${input.beneficiario} - ${input.concepto}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "BANCOS",
        origenDocumento: originDocument,
        detalle
      },
      codUsuario || "API"
    );

    if (!asiento.ok) {
      return { ok: false, mensaje: asiento.mensaje, reason: "contabilidad_create_failed" };
    }

    return {
      ok: true,
      asientoId: asiento.asientoId,
      numeroAsiento: asiento.numeroAsiento,
      mensaje: asiento.mensaje
    };
  } catch (err) {
    console.error("[bancos-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}

/**
 * Vincula un movimiento bancario con un asiento contable (actualiza JournalEntryId).
 */
export async function linkMovementToEntry(
  movimientoId: number,
  journalEntryId: number
): Promise<void> {
  try {
    await callSpOut("usp_Bank_Movement_LinkJournalEntry", {
      MovementId: movimientoId,
      JournalEntryId: journalEntryId,
    });
  } catch (err) {
    console.error("[bancos-contabilidad] linkMovementToEntry error:", err);
  }
}

/**
 * Genera asiento resumen al cerrar una conciliación bancaria.
 * Best-effort: nunca bloquea la operación de cierre.
 */
export async function emitConciliacionClosingEntry(
  conciliacionId: number,
  saldoFinalSistema: number,
  saldoFinalBanco: number,
  nroCta: string,
  codUsuario?: string
): Promise<BankMovementAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const diferencia = round2(Math.abs(saldoFinalSistema - saldoFinalBanco));
    if (diferencia <= 0) {
      return { ok: true, skipped: true, reason: "zero_difference" };
    }

    const debitAccount = await pickFirstExistingAccount(["1.1.02", "1.1.01"]);
    const creditAccount = await pickFirstExistingAccount(["5.1.01", "6.1.01"]);
    if (!debitAccount || !creditAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const isSystemHigher = saldoFinalSistema > saldoFinalBanco;
    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: isSystemHigher ? creditAccount : debitAccount,
        descripcion: `Ajuste conciliación bancaria #${conciliacionId} - Cta ${nroCta}`,
        centroCosto: "BAN",
        documento: `CONC-${conciliacionId}`,
        debe: isSystemHigher ? diferencia : 0,
        haber: isSystemHigher ? 0 : diferencia,
      },
      {
        codCuenta: isSystemHigher ? debitAccount : creditAccount,
        descripcion: `Ajuste conciliación bancaria #${conciliacionId} - Cta ${nroCta}`,
        centroCosto: "BAN",
        documento: `CONC-${conciliacionId}`,
        debe: isSystemHigher ? 0 : diferencia,
        haber: isSystemHigher ? diferencia : 0,
      },
    ];

    const asiento = await crearAsiento(
      {
        fecha: new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: `CONC-${conciliacionId}`,
        concepto: `Cierre conciliación bancaria #${conciliacionId} - Cta ${nroCta}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "BANCOS",
        origenDocumento: `CONCILIACION:${conciliacionId}`,
        detalle,
      },
      codUsuario || "API"
    );

    if (!asiento.ok) {
      return { ok: false, mensaje: asiento.mensaje, reason: "contabilidad_create_failed" };
    }

    return {
      ok: true,
      asientoId: asiento.asientoId,
      numeroAsiento: asiento.numeroAsiento,
      mensaje: asiento.mensaje,
    };
  } catch (err) {
    console.error("[bancos-contabilidad] emitConciliacionClosingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}

/**
 * Obtiene asientos contables vinculados a una conciliación bancaria.
 */
export async function getLinkedEntries(conciliacionId: number): Promise<any[]> {
  try {
    return await callSp("usp_Bank_Reconciliation_GetLinkedEntries", {
      ReconciliationId: conciliacionId,
    });
  } catch (err) {
    console.error("[bancos-contabilidad] getLinkedEntries error:", err);
    return [];
  }
}
