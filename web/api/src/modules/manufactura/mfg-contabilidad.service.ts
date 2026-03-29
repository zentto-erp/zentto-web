/**
 * Manufactura — Integracion Contable (best-effort)
 *
 * Genera asientos contables cuando se completa una orden de trabajo.
 * Patron identico a bancos-contabilidad.service.ts:
 *   hasContabilidadInfra() + accountExists() + crearAsiento()
 *
 * DEBE: Inventario producto terminado (1.1.05)
 * HABER: Materias primas consumidas (1.1.06) + Mano de obra (5.2.01)
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

// ── Work Order Accounting Entry ─────────────────────────────────────────────

/**
 * Generates accounting entry when work order completes.
 * DEBE: Inventario producto terminado (1.1.05)
 * HABER: Materias primas consumidas (1.1.06) + Mano de obra (5.2.01)
 */
export async function emitWorkOrderAccountingEntry(
  input: {
    workOrderNumber: string;
    productCode: string;
    completedQuantity: number;
    materialCost: number;
    laborCost: number;
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

    const totalCost = round2(Math.abs(input.totalCost));
    if (totalCost <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    const materialCost = round2(Math.abs(input.materialCost));
    const laborCost = round2(totalCost - materialCost); // Ajuste para cuadrar

    // Cuenta DEBE: Inventario producto terminado
    const debitAccount = await pickFirstExistingAccount(["1.1.05", "1.1.04", "1.1.03"]);

    // Cuentas HABER: Materias primas + Mano de obra
    const materialAccount = await pickFirstExistingAccount(["1.1.06", "1.1.05", "1.1.03"]);
    const laborAccount = await pickFirstExistingAccount(["5.2.01", "5.1.01", "6.1.01"]);

    if (!debitAccount || !materialAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: `Produccion terminada - OT ${input.workOrderNumber} - ${input.productCode}`,
        centroCosto: "MFG",
        documento: input.workOrderNumber,
        debe: totalCost,
        haber: 0,
      },
    ];

    // Materias primas consumidas
    if (materialCost > 0 && materialAccount) {
      detalle.push({
        codCuenta: materialAccount,
        descripcion: `Materias primas consumidas - OT ${input.workOrderNumber}`,
        centroCosto: "MFG",
        documento: input.workOrderNumber,
        debe: 0,
        haber: materialCost,
      });
    }

    // Mano de obra
    if (laborCost > 0 && laborAccount) {
      detalle.push({
        codCuenta: laborAccount,
        descripcion: `Mano de obra - OT ${input.workOrderNumber}`,
        centroCosto: "MFG",
        documento: input.workOrderNumber,
        debe: 0,
        haber: laborCost,
      });
    }

    // Si solo hay materialCost y no laborAccount, poner todo en materialAccount
    if (laborCost > 0 && !laborAccount && materialAccount) {
      detalle[1].haber = totalCost;
      detalle.splice(2); // Remove labor line if exists
    }

    const asiento = await crearAsiento(
      {
        fecha: input.fecha,
        tipoAsiento: "DIA",
        referencia: input.workOrderNumber,
        concepto: `Produccion completada OT ${input.workOrderNumber} - ${input.productCode} x${input.completedQuantity}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "MANUFACTURA",
        origenDocumento: `WO:${input.workOrderNumber}`,
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
    console.error("[mfg-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
