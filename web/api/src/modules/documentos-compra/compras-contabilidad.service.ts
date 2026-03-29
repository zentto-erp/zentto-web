import { crearAsiento, anularAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface CompraAccountingInput {
  numDoc: string;
  tipoOperacion: string;
  codProveedor: string;
  fecha: string;
  subtotal: number;
  iva: number;
  total: number;
  moneda?: string;
  tasaCambio?: number;
  isPaid?: boolean;
}

export interface CompraAccountingResult {
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

/**
 * Genera asiento contable al emitir compra.
 * Compra a crédito: DEBE Gastos/Inventario + IVA crédito, HABER CxP
 * Compra contado:   DEBE Gastos/Inventario + IVA crédito, HABER Caja/Banco
 */
export async function emitCompraAccountingEntry(
  input: CompraAccountingInput,
  codUsuario?: string
): Promise<CompraAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const total = round2(Math.abs(input.total));
    if (total <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    const base = round2(Math.abs(input.subtotal || total));
    const iva = round2(Math.abs(input.iva || 0));

    // Cuenta DEBE: Gastos o Inventario
    const expenseAccount = await pickFirstExistingAccount(["5.1.01", "5.1.02", "1.1.05"]);
    // IVA crédito fiscal (si aplica)
    const vatCreditAccount = iva > 0 ? await pickFirstExistingAccount(["1.1.04", "1.1.06"]) : null;

    // Cuenta HABER según contado o crédito
    const isContado = !!input.isPaid;
    const creditAccount = isContado
      ? await pickFirstExistingAccount(["1.1.01", "1.1.02"]) // Caja/Banco
      : await pickFirstExistingAccount(["2.1.01", "2.1.02"]); // CxP

    if (!expenseAccount || !creditAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: expenseAccount,
        descripcion: `Compra ${input.tipoOperacion} ${input.numDoc} - ${input.codProveedor}`,
        centroCosto: "COM",
        documento: input.numDoc,
        debe: iva > 0 ? base : total,
        haber: 0,
      },
    ];

    if (iva > 0 && vatCreditAccount) {
      detalle.push({
        codCuenta: vatCreditAccount,
        descripcion: "IVA crédito fiscal",
        centroCosto: "COM",
        documento: input.numDoc,
        debe: iva,
        haber: 0,
      });
    }

    detalle.push({
      codCuenta: creditAccount,
      descripcion: `${isContado ? "Compra contado" : "Compra a crédito"} - ${input.codProveedor}`,
      centroCosto: "COM",
      documento: input.numDoc,
      debe: 0,
      haber: total,
    });

    const originDocument = `${input.tipoOperacion}:${input.numDoc}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.numDoc,
        concepto: `${input.tipoOperacion} ${input.numDoc} - Proveedor ${input.codProveedor}`,
        moneda: input.moneda || "VES",
        tasa: input.tasaCambio || 1,
        origenModulo: "COMPRAS",
        origenDocumento: originDocument,
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
    console.error("[compras-contabilidad] emitCompraAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}

/**
 * Anula asiento vinculado al anular documento de compra.
 */
export async function voidCompraAccountingEntry(
  tipoOperacion: string,
  numDoc: string,
  motivo?: string
): Promise<CompraAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const originDocument = `${tipoOperacion}:${numDoc}`;

    let companyId = 1;
    let branchId = 1;
    const active = getActiveScope();
    if (active) {
      companyId = active.companyId;
      branchId = active.branchId;
    }

    const rows = await callSp<{ asientoId: number; numeroAsiento: string | null }>(
      "dbo.usp_Acct_Entry_FindByOrigin",
      {
        CompanyId: companyId,
        BranchId: branchId,
        Module: "COMPRAS",
        OriginDocument: originDocument,
      }
    );

    const existing = rows[0];
    if (!existing?.asientoId) {
      return { ok: true, skipped: true, reason: "no_linked_entry" };
    }

    const result = await anularAsiento(
      existing.asientoId,
      motivo || `Anulación ${tipoOperacion} ${numDoc}`
    );

    return {
      ok: result.ok,
      asientoId: existing.asientoId,
      numeroAsiento: existing.numeroAsiento,
      mensaje: result.mensaje,
    };
  } catch (err) {
    console.error("[compras-contabilidad] voidCompraAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
