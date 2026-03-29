import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export type RRHHOperationType =
  | "UTILIDADES"
  | "FIDEICOMISO"
  | "PRESTAMO_APROBADO"
  | "PRESTAMO_PAGO"
  | "APORTE_MENSUAL"
  | "OBLIGACION_LEGAL";

export interface RRHHAccountingInput {
  tipo: RRHHOperationType;
  referencia: string;
  concepto: string;
  fecha: string;
  monto: number;
}

export interface RRHHAccountingResult {
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

function resolveAccountMapping(tipo: RRHHOperationType): {
  debitCandidates: string[];
  creditCandidates: string[];
  centroCosto: string;
} {
  switch (tipo) {
    case "UTILIDADES":
      // DEBE: Gasto utilidades, HABER: Utilidades por pagar
      return {
        debitCandidates: ["5.2.03", "5.2.01", "5.1.03"],
        creditCandidates: ["2.1.07", "2.1.06", "2.1.01"],
        centroCosto: "NOM",
      };
    case "FIDEICOMISO":
      // DEBE: Gasto prestaciones, HABER: Fideicomiso por pagar
      return {
        debitCandidates: ["5.2.04", "5.2.01", "5.1.03"],
        creditCandidates: ["2.1.08", "2.1.06"],
        centroCosto: "NOM",
      };
    case "PRESTAMO_APROBADO":
      // DEBE: Préstamos a empleados (activo), HABER: Banco/Caja
      return {
        debitCandidates: ["1.1.07", "1.1.05"],
        creditCandidates: ["1.1.02", "1.1.01"],
        centroCosto: "NOM",
      };
    case "PRESTAMO_PAGO":
      // DEBE: Banco/Caja, HABER: Préstamos a empleados (reduce activo)
      return {
        debitCandidates: ["1.1.02", "1.1.01"],
        creditCandidates: ["1.1.07", "1.1.05"],
        centroCosto: "NOM",
      };
    case "APORTE_MENSUAL":
      // DEBE: Gasto aportes patronales, HABER: Aportes por pagar
      return {
        debitCandidates: ["5.2.05", "5.2.01"],
        creditCandidates: ["2.1.09", "2.1.04"],
        centroCosto: "NOM",
      };
    case "OBLIGACION_LEGAL":
      // DEBE: Gasto obligaciones legales, HABER: Obligaciones por pagar
      return {
        debitCandidates: ["5.2.06", "5.2.01"],
        creditCandidates: ["2.1.10", "2.1.04"],
        centroCosto: "NOM",
      };
    default:
      return {
        debitCandidates: ["5.2.01"],
        creditCandidates: ["2.1.06"],
        centroCosto: "NOM",
      };
  }
}

export async function emitRRHHAccountingEntry(
  input: RRHHAccountingInput,
  codUsuario?: string
): Promise<RRHHAccountingResult> {
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

    const detalle: AsientoDetalleInput[] = [
      {
        codCuenta: debitAccount,
        descripcion: input.concepto,
        centroCosto: mapping.centroCosto,
        documento: input.referencia,
        debe: amount,
        haber: 0,
      },
      {
        codCuenta: creditAccount,
        descripcion: input.concepto,
        centroCosto: mapping.centroCosto,
        documento: input.referencia,
        debe: 0,
        haber: amount,
      },
    ];

    const originDocument = `${input.tipo}:${input.referencia}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.referencia,
        concepto: input.concepto,
        moneda: "VES",
        tasa: 1,
        origenModulo: "RRHH",
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
    console.error("[rrhh-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
