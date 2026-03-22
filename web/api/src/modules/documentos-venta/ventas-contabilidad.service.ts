import { crearAsiento, anularAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface VentaAccountingInput {
  numDoc: string;
  tipoOperacion: string;
  codCliente: string;
  fecha: string;
  subtotal: number;
  iva: number;
  total: number;
  moneda?: string;
  tasaCambio?: number;
  isPaid?: boolean;
}

export interface VentaAccountingResult {
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
 * Genera asiento contable al emitir factura de venta (no POS/REST).
 * Factura a crédito: DEBE CxC, HABER Ventas + IVA
 * Factura contado:   DEBE Caja, HABER Ventas + IVA
 */
export async function emitVentaAccountingEntry(
  input: VentaAccountingInput,
  codUsuario?: string
): Promise<VentaAccountingResult> {
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

    // Determinar cuenta DEBE según si es contado o crédito
    const isContado = !!input.isPaid;
    const debitAccount = isContado
      ? await pickFirstExistingAccount(["1.1.01", "1.1.02"]) // Caja/Banco
      : await pickFirstExistingAccount(["1.1.03", "1.1.04"]); // CxC

    const salesAccount = await pickFirstExistingAccount(["4.1.01", "4.1.02"]);
    const vatAccount = iva > 0 ? await pickFirstExistingAccount(["2.1.03"]) : null;

    if (!debitAccount || !salesAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: `${isContado ? "Venta contado" : "Venta a crédito"} - ${input.codCliente}`,
        centroCosto: "VEN",
        documento: input.numDoc,
        debe: total,
        haber: 0,
      },
      {
        codCuenta: salesAccount,
        descripcion: `Ingreso por venta ${input.tipoOperacion} ${input.numDoc}`,
        centroCosto: "VEN",
        documento: input.numDoc,
        debe: 0,
        haber: iva > 0 ? base : total,
      },
    ];

    if (iva > 0 && vatAccount) {
      detalle.push({
        codCuenta: vatAccount,
        descripcion: "IVA por pagar",
        centroCosto: "VEN",
        documento: input.numDoc,
        debe: 0,
        haber: iva,
      });
    }

    const originDocument = `${input.tipoOperacion}:${input.numDoc}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.numDoc,
        concepto: `${input.tipoOperacion} ${input.numDoc} - Cliente ${input.codCliente}`,
        moneda: input.moneda || "VES",
        tasa: input.tasaCambio || 1,
        origenModulo: "VENTAS",
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
    console.error("[ventas-contabilidad] emitVentaAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}

/**
 * Genera asiento de reverso al anular documento de venta.
 * Busca el asiento original por origenDocumento y lo anula.
 */
export async function voidVentaAccountingEntry(
  tipoOperacion: string,
  numDoc: string,
  motivo?: string
): Promise<VentaAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const originDocument = `${tipoOperacion}:${numDoc}`;

    // Buscar asiento vinculado
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
        Module: "VENTAS",
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
    console.error("[ventas-contabilidad] voidVentaAccountingEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
