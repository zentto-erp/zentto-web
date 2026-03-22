import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface PagoAccountingInput {
  numPago: string;
  codProveedor: string;
  fecha: string;
  montoTotal: number;
  observaciones?: string;
  formasPago: Array<{ formaPago: string; monto: number }>;
}

export interface PagoAccountingResult {
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

function isCashPayment(formaPago: string): boolean {
  const normalized = formaPago.trim().toUpperCase();
  return ["EFECTIVO", "CASH", "EFE"].includes(normalized);
}

function resolveCreditCandidates(formaPago: string): string[] {
  if (isCashPayment(formaPago)) {
    return ["1.1.01", "1.1.02"]; // Caja primero
  }
  return ["1.1.02", "1.1.01"]; // Bancos primero
}

export async function emitPagoAccountingEntry(
  input: PagoAccountingInput,
  codUsuario?: string
): Promise<PagoAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.montoTotal));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    // Verificar cuenta CxP (DEBE)
    const cxpAccount = await pickFirstExistingAccount(["2.1.01", "2.1.02"]);
    if (!cxpAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    // Linea DEBE: CxP por el total (se libera la obligacion)
    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: cxpAccount,
        descripcion: `Pago proveedor ${input.codProveedor}`,
        centroCosto: "CXP",
        documento: input.numPago,
        debe: amount,
        haber: 0,
      },
    ];

    // Construir lineas HABER (una por forma de pago)
    for (const fp of input.formasPago) {
      const fpMonto = round2(Math.abs(fp.monto));
      if (fpMonto <= 0) continue;

      const creditAccount = await pickFirstExistingAccount(resolveCreditCandidates(fp.formaPago));
      if (!creditAccount) {
        return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
      }

      detalle.push({
        codCuenta: creditAccount,
        descripcion: `Pago proveedor ${input.codProveedor} - ${fp.formaPago}`,
        centroCosto: "CXP",
        documento: input.numPago,
        debe: 0,
        haber: fpMonto,
      });
    }

    // Verificar que hay al menos una linea HABER
    if (detalle.length <= 1) {
      return { ok: false, skipped: true, reason: "no_payment_lines" };
    }

    const originDocument = `PAGO:${input.numPago}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.numPago,
        concepto: `Pago CxP proveedor ${input.codProveedor} - Pago ${input.numPago}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "CXP",
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
    console.error("[cxp-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
