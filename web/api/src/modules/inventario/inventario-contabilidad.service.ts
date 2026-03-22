import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface InventarioAccountingInput {
  productCode: string;
  movementType: string; // ENTRADA, SALIDA, AJUSTE, TRASLADO
  quantity: number;
  unitCost: number;
  totalCost: number;
  documentRef?: string;
  notes?: string;
  fecha?: string;
}

export interface InventarioAccountingResult {
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
 * Genera asiento contable por movimiento de inventario.
 *
 * ENTRADA:  DEBE Inventario (1.1.05), HABER Compras/Ajuste (5.1.01 o 4.9.02)
 * SALIDA:   DEBE Costo de venta (5.2.01), HABER Inventario (1.1.05)
 * AJUSTE+:  DEBE Inventario (1.1.05), HABER Ajuste inventario (4.9.02)
 * AJUSTE-:  DEBE Pérdida inventario (6.2.01), HABER Inventario (1.1.05)
 * TRASLADO: Sin asiento (no cambia valor total de inventario)
 */
export async function emitInventarioMovementEntry(
  input: InventarioAccountingInput,
  codUsuario?: string
): Promise<InventarioAccountingResult> {
  try {
    if (!(await hasContabilidadInfra())) {
      return { ok: false, skipped: true, reason: "contabilidad_infra_not_ready" };
    }

    const amount = round2(Math.abs(input.totalCost));
    if (amount <= 0) {
      return { ok: false, skipped: true, reason: "zero_amount" };
    }

    const tipo = (input.movementType ?? "").trim().toUpperCase();

    // Traslados no generan asiento (no cambia valor total)
    if (tipo === "TRASLADO") {
      return { ok: true, skipped: true, reason: "traslado_no_entry" };
    }

    // Cuenta inventario
    const inventoryAccount = await pickFirstExistingAccount(["1.1.05", "1.5.01", "1.1.06"]);
    if (!inventoryAccount) {
      return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };
    }

    const detalle: AsientoDetalleInput[] = [];
    let concepto = "";

    if (tipo === "ENTRADA") {
      const contraAccount = await pickFirstExistingAccount(["5.1.01", "5.1.02", "4.9.02"]);
      if (!contraAccount) return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };

      detalle.push(
        { codCuenta: inventoryAccount, descripcion: `Entrada inventario ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: amount, haber: 0 },
        { codCuenta: contraAccount, descripcion: `Entrada inventario ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: 0, haber: amount },
      );
      concepto = `Entrada inventario: ${input.productCode} x${input.quantity}`;

    } else if (tipo === "SALIDA") {
      const cogsAccount = await pickFirstExistingAccount(["5.2.01", "5.1.01", "6.1.01"]);
      if (!cogsAccount) return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };

      detalle.push(
        { codCuenta: cogsAccount, descripcion: `Salida inventario ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: amount, haber: 0 },
        { codCuenta: inventoryAccount, descripcion: `Salida inventario ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: 0, haber: amount },
      );
      concepto = `Salida inventario: ${input.productCode} x${input.quantity}`;

    } else if (tipo === "AJUSTE") {
      // Determinar si es ajuste positivo o negativo por contexto
      // Si hay notes con "faltante", "pérdida", "merma" → negativo
      const isNegative = /faltante|p[eé]rdida|merma|da[nñ]o/i.test(input.notes ?? "");

      if (isNegative) {
        const lossAccount = await pickFirstExistingAccount(["6.2.01", "6.1.01", "5.2.01"]);
        if (!lossAccount) return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };

        detalle.push(
          { codCuenta: lossAccount, descripcion: `Ajuste inventario (pérdida) ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: amount, haber: 0 },
          { codCuenta: inventoryAccount, descripcion: `Ajuste inventario (pérdida) ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: 0, haber: amount },
        );
        concepto = `Ajuste inventario (pérdida): ${input.productCode}`;
      } else {
        const adjustAccount = await pickFirstExistingAccount(["4.9.02", "4.1.01"]);
        if (!adjustAccount) return { ok: false, skipped: true, reason: "contabilidad_accounts_not_configured" };

        detalle.push(
          { codCuenta: inventoryAccount, descripcion: `Ajuste inventario (sobrante) ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: amount, haber: 0 },
          { codCuenta: adjustAccount, descripcion: `Ajuste inventario (sobrante) ${input.productCode}`, centroCosto: "INV", documento: input.documentRef || "", debe: 0, haber: amount },
        );
        concepto = `Ajuste inventario (sobrante): ${input.productCode}`;
      }
    } else {
      return { ok: false, skipped: true, reason: "unsupported_movement_type" };
    }

    const originDocument = `INV:${tipo}:${input.productCode}:${Date.now()}`;

    const asiento = await crearAsiento(
      {
        fecha: input.fecha || new Date().toISOString().slice(0, 10),
        tipoAsiento: "DIA",
        referencia: input.documentRef || input.productCode,
        concepto,
        moneda: "VES",
        tasa: 1,
        origenModulo: "INVENTARIO",
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
    console.error("[inventario-contabilidad] emitInventarioMovementEntry error:", err);
    return { ok: false, reason: "contabilidad_error" };
  }
}
