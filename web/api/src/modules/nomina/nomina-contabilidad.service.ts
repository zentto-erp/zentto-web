import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface NominaAccountingInput {
  tipo: "NOMINA" | "VACACIONES" | "LIQUIDACION" | "UTILIDADES";
  referencia: string;
  cedula: string;
  nombreEmpleado?: string;
  fecha: string;
  totalAsignaciones: number;
  totalDeducciones: number;
  totalNeto: number;
  detalleConceptos?: Array<{
    codigo: string;
    nombre: string;
    tipo: string; // ASIGNACION | DEDUCCION | BONO
    monto: number;
    cuentaContable?: string | null;
  }>;
}

export interface NominaAccountingResult {
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

// Cuentas default por tipo de concepto
const DEFAULT_ACCOUNTS: Record<string, string[]> = {
  // Asignaciones: Gasto de nómina
  ASIGNACION: ["5.2.01", "5.2.02", "5.1.03"],
  BONO: ["5.2.01", "5.2.02", "5.1.03"],
  // Deducciones: Pasivos retenidos (SSO, ISLR, etc.)
  DEDUCCION: ["2.1.04", "2.1.05", "2.1.03"],
  // Neto por pagar: Pasivo nómina por pagar / Banco
  NETO_PAGAR: ["2.1.06", "2.1.01"],
};

function resolveConceptLabel(tipo: string): string {
  switch (tipo) {
    case "NOMINA": return "Nómina";
    case "VACACIONES": return "Vacaciones";
    case "LIQUIDACION": return "Liquidación";
    case "UTILIDADES": return "Utilidades";
    default: return "Nómina";
  }
}

/**
 * Genera asiento contable para operaciones de nómina.
 *
 * Asiento tipo nómina:
 *   DEBE: Gastos de nómina (asignaciones + bonos) — una línea por concepto si tiene cuenta
 *   HABER: Retenciones (deducciones) + Neto por pagar (banco/caja)
 *
 * Si los conceptos no tienen cuentaContable, se usa cuenta genérica.
 */
export async function emitNominaAccountingEntry(
  input: NominaAccountingInput,
  codUsuario?: string
): Promise<NominaAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const totalNeto = round2(Math.abs(input.totalNeto));
    if (totalNeto <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    const label = resolveConceptLabel(input.tipo);
    const centroCosto = "NOM";
    const detalle: AsientoDetalleInput[] = [];

    // --- DEBE: Gastos (asignaciones) ---
    if (input.detalleConceptos && input.detalleConceptos.length > 0) {
      // Agrupar por cuenta contable
      const debitGroups = new Map<string, { monto: number; desc: string }>();
      const creditGroups = new Map<string, { monto: number; desc: string }>();

      for (const concepto of input.detalleConceptos) {
        const monto = round2(Math.abs(concepto.monto));
        if (monto <= 0) continue;

        const tipoNorm = concepto.tipo.toUpperCase();
        const isDeduccion = tipoNorm === "DEDUCCION";

        // Resolver cuenta: primero la del concepto, luego fallback
        let cuenta = concepto.cuentaContable?.trim() || null;
        if (cuenta && !(await accountExists(cuenta))) cuenta = null;
        if (!cuenta) {
          const candidates = isDeduccion ? DEFAULT_ACCOUNTS.DEDUCCION : DEFAULT_ACCOUNTS.ASIGNACION;
          cuenta = await pickFirstExistingAccount(candidates);
        }
        if (!cuenta) continue;

        const group = isDeduccion ? creditGroups : debitGroups;
        const existing = group.get(cuenta);
        if (existing) {
          existing.monto = round2(existing.monto + monto);
        } else {
          group.set(cuenta, {
            monto,
            desc: `${label} - ${concepto.nombre}`,
          });
        }
      }

      // Líneas DEBE (asignaciones)
      for (const [cuenta, data] of debitGroups) {
        detalle.push({
          codCuenta: cuenta,
          descripcion: data.desc,
          centroCosto,
          documento: input.referencia,
          debe: data.monto,
          haber: 0,
        });
      }

      // Líneas HABER (deducciones retenidas)
      for (const [cuenta, data] of creditGroups) {
        detalle.push({
          codCuenta: cuenta,
          descripcion: data.desc,
          centroCosto,
          documento: input.referencia,
          debe: 0,
          haber: data.monto,
        });
      }
    } else {
      // Sin detalle: una línea genérica DEBE por asignaciones
      const gastoAccount = await pickFirstExistingAccount(DEFAULT_ACCOUNTS.ASIGNACION);
      if (!gastoAccount) {
        return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
      }

      detalle.push({
        codCuenta: gastoAccount,
        descripcion: `${label} - Asignaciones ${input.cedula}`,
        centroCosto,
        documento: input.referencia,
        debe: round2(Math.abs(input.totalAsignaciones)),
        haber: 0,
      });

      // Línea HABER genérica por deducciones (si hay)
      if (input.totalDeducciones > 0) {
        const deduccionAccount = await pickFirstExistingAccount(DEFAULT_ACCOUNTS.DEDUCCION);
        if (deduccionAccount) {
          detalle.push({
            codCuenta: deduccionAccount,
            descripcion: `${label} - Deducciones ${input.cedula}`,
            centroCosto,
            documento: input.referencia,
            debe: 0,
            haber: round2(Math.abs(input.totalDeducciones)),
          });
        }
      }
    }

    // Línea HABER final: Neto por pagar (banco/caja)
    const netoAccount = await pickFirstExistingAccount(DEFAULT_ACCOUNTS.NETO_PAGAR);
    if (!netoAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    detalle.push({
      codCuenta: netoAccount,
      descripcion: `${label} neto por pagar - ${input.cedula}`,
      centroCosto,
      documento: input.referencia,
      debe: 0,
      haber: totalNeto,
    });

    if (detalle.length < 2) {
      return { ok: false, skipped: true, reason: "insufficient_lines" };
    }

    const originDocument = `${input.tipo}:${input.referencia}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.referencia,
        concepto: `${label} ${input.cedula} - ${input.nombreEmpleado || ""}`.trim(),
        moneda: "VES",
        tasa: 1,
        origenModulo: "NOMINA",
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
    console.error("[nomina-contabilidad] Error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
