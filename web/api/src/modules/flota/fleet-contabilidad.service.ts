/**
 * Flota — Integracion Contable (best-effort)
 *
 * Genera asientos contables para:
 * - Ordenes de mantenimiento completadas
 * - Cargas de combustible
 *
 * Patron identico a bancos-contabilidad.service.ts:
 *   hasContabilidadInfra() + accountExists() + crearAsiento()
 */
import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers (same as bancos-contabilidad) ───────────────────────────────────

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

async function hasContabilidadInfra(): Promise<boolean> {
  const rows = await callSp<{ ok: number }>("dbo.usp_Acct_Infra_Check");
  return Number(rows[0]?.ok ?? 0) === 1;
}

async function accountExists(accountCode: string): Promise<boolean> {
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

// ── Maintenance Accounting Entry ────────────────────────────────────────────

/**
 * Generates accounting entry for completed maintenance orders.
 * DEBE: Gastos mantenimiento vehiculos (5.3.01)
 * HABER: Caja/Banco (1.1.01/1.1.02) or CxP (2.1.01) if not paid
 */
export async function emitMaintenanceAccountingEntry(
  input: {
    orderNumber: string;
    vehiclePlate: string;
    actualCost: number;
    fecha: string;
    isPaid?: boolean;
  },
  codUsuario?: string
): Promise<{
  ok: boolean;
  skipped?: boolean;
  reason?: string;
  asientoId?: number | null;
  numeroAsiento?: string | null;
}> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.actualCost));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    // DEBE: Gastos mantenimiento vehiculos
    const debitAccount = await pickFirstExistingAccount(["5.3.01", "5.1.01", "6.1.01"]);

    // HABER: Si pagado -> Caja/Banco; Si no pagado -> CxP
    const creditCandidates = input.isPaid
      ? ["1.1.01", "1.1.02"]
      : ["2.1.01", "2.1.02", "1.1.01"];
    const creditAccount = await pickFirstExistingAccount(creditCandidates);

    if (!debitAccount || !creditAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: `Mantenimiento vehiculo ${input.vehiclePlate} - Orden ${input.orderNumber}`,
        centroCosto: "FLT",
        documento: input.orderNumber,
        debe: amount,
        haber: 0,
      },
      {
        codCuenta: creditAccount,
        descripcion: `Pago mantenimiento vehiculo ${input.vehiclePlate}`,
        centroCosto: "FLT",
        documento: input.orderNumber,
        debe: 0,
        haber: amount,
      },
    ];

    const asiento = await crearAsiento(
      {
        fecha: input.fecha,
        tipoAsiento: "DIA",
        referencia: input.orderNumber,
        concepto: `Mantenimiento vehiculo ${input.vehiclePlate} - Orden ${input.orderNumber}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "FLOTA",
        origenDocumento: `MNT:${input.orderNumber}`,
        detalle,
      },
      codUsuario || "API"
    );

    if (!asiento.ok) {
      return { ok: false, reason: "contabilidad_create_failed" };
    }

    return {
      ok: true,
      asientoId: asiento.asientoId,
      numeroAsiento: asiento.numeroAsiento,
    };
  } catch (err) {
    console.error("[fleet-contabilidad] emitMaintenanceAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}

// ── Fuel Accounting Entry ───────────────────────────────────────────────────

/**
 * Generates accounting entry for fuel purchases.
 * DEBE: Gastos combustible (5.3.02)
 * HABER: Caja (1.1.01)
 */
export async function emitFuelAccountingEntry(
  input: {
    vehiclePlate: string;
    totalCost: number;
    fecha: string;
  },
  codUsuario?: string
): Promise<{
  ok: boolean;
  skipped?: boolean;
  reason?: string;
  asientoId?: number | null;
  numeroAsiento?: string | null;
}> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.totalCost));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    // DEBE: Gastos combustible
    const debitAccount = await pickFirstExistingAccount(["5.3.02", "5.3.01", "5.1.01"]);

    // HABER: Caja
    const creditAccount = await pickFirstExistingAccount(["1.1.01", "1.1.02"]);

    if (!debitAccount || !creditAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: `Combustible vehiculo ${input.vehiclePlate}`,
        centroCosto: "FLT",
        documento: `FUEL-${input.vehiclePlate}`,
        debe: amount,
        haber: 0,
      },
      {
        codCuenta: creditAccount,
        descripcion: `Pago combustible vehiculo ${input.vehiclePlate}`,
        centroCosto: "FLT",
        documento: `FUEL-${input.vehiclePlate}`,
        debe: 0,
        haber: amount,
      },
    ];

    const asiento = await crearAsiento(
      {
        fecha: input.fecha,
        tipoAsiento: "DIA",
        referencia: `FUEL-${input.vehiclePlate}`,
        concepto: `Carga de combustible vehiculo ${input.vehiclePlate}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "FLOTA",
        origenDocumento: `FUEL:${input.vehiclePlate}:${input.fecha}`,
        detalle,
      },
      codUsuario || "API"
    );

    if (!asiento.ok) {
      return { ok: false, reason: "contabilidad_create_failed" };
    }

    return {
      ok: true,
      asientoId: asiento.asientoId,
      numeroAsiento: asiento.numeroAsiento,
    };
  } catch (err) {
    console.error("[fleet-contabilidad] emitFuelAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
