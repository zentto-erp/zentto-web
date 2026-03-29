/**
 * Integración Manufactura ↔ Inventario.
 * Al completar una orden de trabajo:
 * 1. Crea StockMovement PRODUCTION_OUT por cada material consumido
 * 2. Crea StockMovement PRODUCTION_IN por el producto terminado
 */
import { callSp } from "../../db/query.js";

export interface MfgStockInput {
  companyId: number;
  branchId: number;
  workOrderId: number;
  userId: number;
}

export interface MfgStockResult {
  ok: boolean;
  materialsConsumed: number;
  outputCreated: boolean;
  reason?: string;
}

/**
 * Procesa movimientos de stock al completar orden de producción.
 * Best-effort: nunca bloquea la operación principal.
 */
export async function processWorkOrderStock(
  input: MfgStockInput
): Promise<MfgStockResult> {
  try {
    const rows = await callSp<{
      ok: number;
      materialsConsumed: number;
      outputCreated: number;
      mensaje: string;
    }>("usp_Mfg_WorkOrder_ProcessStock", {
      CompanyId: input.companyId,
      BranchId: input.branchId,
      WorkOrderId: input.workOrderId,
      UserId: input.userId,
    });

    const r = rows[0];
    return {
      ok: Number(r?.ok ?? 0) === 1,
      materialsConsumed: Number(r?.materialsConsumed ?? 0),
      outputCreated: Number(r?.outputCreated ?? 0) === 1,
      reason: r?.mensaje,
    };
  } catch (err) {
    console.error("[mfg-integracion] processWorkOrderStock error:", err);
    return { ok: false, materialsConsumed: 0, outputCreated: false, reason: "integration_error" };
  }
}
