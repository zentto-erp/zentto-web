import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface CobroAccountingInput {
  numRecibo: string;
  codCliente: string;
  fecha: string;
  montoTotal: number;
  observaciones?: string;
  formasPago: Array<{ formaPago: string; monto: number }>;
}

export interface CobroAccountingResult {
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

function resolveDebitCandidates(formaPago: string): string[] {
  if (isCashPayment(formaPago)) {
    return ["1.1.01", "1.1.02"]; // Caja primero
  }
  return ["1.1.02", "1.1.01"]; // Bancos primero
}

export async function emitCobroAccountingEntry(
  input: CobroAccountingInput,
  codUsuario?: string
): Promise<CobroAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.montoTotal));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    // Verificar cuenta CxC (HABER)
    const cxcAccount = await pickFirstExistingAccount(["1.1.03", "1.1.04"]);
    if (!cxcAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    // Construir lineas DEBE (una por forma de pago)
    const detalle: AsientoDetalleInput[] = [];

    for (const fp of input.formasPago) {
      const fpMonto = round2(Math.abs(fp.monto));
      if (fpMonto <= 0) continue;

      const debitAccount = await pickFirstExistingAccount(resolveDebitCandidates(fp.formaPago));
      if (!debitAccount) {
        return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
      }

      detalle.push({
        codCuenta: debitAccount,
        descripcion: `Cobro cliente ${input.codCliente} - ${fp.formaPago}`,
        centroCosto: "CXC",
        documento: input.numRecibo,
        debe: fpMonto,
        haber: 0,
      });
    }

    if (detalle.length === 0) {
      return { ok: false, skipped: true, reason: "no_payment_lines" };
    }

    // Linea HABER: CxC por el total
    detalle.push({
      codCuenta: cxcAccount,
      descripcion: `Cobro cliente ${input.codCliente}`,
      centroCosto: "CXC",
      documento: input.numRecibo,
      debe: 0,
      haber: amount,
    });

    const originDocument = `COBRO:${input.numRecibo}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.numRecibo,
        concepto: `Cobro CxC cliente ${input.codCliente} - Recibo ${input.numRecibo}`,
        moneda: "VES",
        tasa: 1,
        origenModulo: "CXC",
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
    console.error("[cxc-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
