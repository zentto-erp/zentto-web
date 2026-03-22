/**
 * Inventario Avanzado — Integracion con POS, Ventas y Logistica
 *
 * Funciones de integracion cross-module:
 * - reserveSerialForSale: valida y reserva serial al vender via POS/Factura
 * - validateLotForSale: valida lote no expirado antes de vender
 * - processGoodsReceiptStock: crea movimientos de stock al aprobar recepcion
 * - processDeliveryNoteStock: crea movimientos de stock al despachar nota de entrega
 */
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ─────────────────────────────────────────────────────────────────

function requireScope() {
  const scope = getActiveScope();
  if (!scope) throw new Error("Scope de empresa no disponible");
  return scope;
}

// ── Serial / Lot Integration ────────────────────────────────────────────────

/**
 * Validates and reserves a serial when selling via POS or Factura.
 * Called from POS facturacion flow and documentos-venta emit.
 */
export async function reserveSerialForSale(input: {
  companyId: number;
  productId: number;
  serialNumber: string;
  salesDocumentNumber: string;
  customerId?: number;
  codUsuario: string;
}): Promise<{ ok: boolean; serialId?: number; reason?: string }> {
  try {
    const rows = await callSp<{ ok: number; SerialId: number; reason: string }>(
      "usp_Inv_Serial_ReserveForSale",
      {
        CompanyId: input.companyId,
        ProductId: input.productId,
        SerialNumber: input.serialNumber,
        SalesDocumentNumber: input.salesDocumentNumber,
        CustomerId: input.customerId ?? null,
        UserId: input.codUsuario,
      }
    );

    const row = rows[0];
    if (!row || Number(row.ok) !== 1) {
      return { ok: false, reason: String(row?.reason ?? "serial_not_found") };
    }

    return { ok: true, serialId: Number(row.SerialId) };
  } catch (err) {
    console.error("[inv-integracion] reserveSerialForSale error:", err);
    return { ok: false, reason: "internal_error" };
  }
}

/**
 * Validates lot is not expired before selling.
 * Returns warning if product has expired lot.
 */
export async function validateLotForSale(input: {
  companyId: number;
  productId: number;
  lotId?: number;
  quantity: number;
}): Promise<{ ok: boolean; warning?: string; expired?: boolean; expiryDate?: string }> {
  try {
    const rows = await callSp<{
      ok: number;
      warning: string;
      expired: number;
      ExpiryDate: string;
    }>(
      "usp_Inv_Lot_ValidateForSale",
      {
        CompanyId: input.companyId,
        ProductId: input.productId,
        LotId: input.lotId ?? null,
        Quantity: input.quantity,
      }
    );

    const row = rows[0];
    if (!row) {
      return { ok: true }; // No lot tracking for this product
    }

    return {
      ok: Number(row.ok) === 1,
      warning: row.warning || undefined,
      expired: Number(row.expired) === 1,
      expiryDate: row.ExpiryDate || undefined,
    };
  } catch (err) {
    console.error("[inv-integracion] validateLotForSale error:", err);
    return { ok: false, warning: "Error validando lote" };
  }
}

// ── Logistics Integration ───────────────────────────────────────────────────

/**
 * Creates stock movements when goods receipt is approved.
 * Called from logistics GoodsReceipt approve flow.
 */
export async function processGoodsReceiptStock(input: {
  companyId: number;
  branchId: number;
  goodsReceiptId: number;
  codUsuario: string;
}): Promise<{ ok: boolean; movementsCreated: number }> {
  try {
    const rows = await callSp<{ ok: number; MovementsCreated: number }>(
      "usp_Inv_GoodsReceipt_ProcessStock",
      {
        CompanyId: input.companyId,
        BranchId: input.branchId,
        GoodsReceiptId: input.goodsReceiptId,
        UserId: input.codUsuario,
      }
    );

    const row = rows[0];
    return {
      ok: Number(row?.ok ?? 0) === 1,
      movementsCreated: Number(row?.MovementsCreated ?? 0),
    };
  } catch (err) {
    console.error("[inv-integracion] processGoodsReceiptStock error:", err);
    return { ok: false, movementsCreated: 0 };
  }
}

/**
 * Creates stock movements when delivery note is dispatched.
 * Called from logistics DeliveryNote dispatch flow.
 */
export async function processDeliveryNoteStock(input: {
  companyId: number;
  branchId: number;
  deliveryNoteId: number;
  codUsuario: string;
}): Promise<{ ok: boolean; movementsCreated: number }> {
  try {
    const rows = await callSp<{ ok: number; MovementsCreated: number }>(
      "usp_Inv_DeliveryNote_ProcessStock",
      {
        CompanyId: input.companyId,
        BranchId: input.branchId,
        DeliveryNoteId: input.deliveryNoteId,
        UserId: input.codUsuario,
      }
    );

    const row = rows[0];
    return {
      ok: Number(row?.ok ?? 0) === 1,
      movementsCreated: Number(row?.MovementsCreated ?? 0),
    };
  } catch (err) {
    console.error("[inv-integracion] processDeliveryNoteStock error:", err);
    return { ok: false, movementsCreated: 0 };
  }
}
