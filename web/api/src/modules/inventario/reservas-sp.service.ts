/**
 * Reservas de Stock — Stored Procedures
 * usp_inv_stock_reserve / release / commit / available / cleanup_expired
 */
import { callSp } from "../../db/query.js";

export interface ReserveParams {
  companyId: number;
  productCode: string;
  quantity: number;
  referenceType: string;
  referenceId: string;
  ttlMinutes?: number;
  userId?: number;
}

export interface ReserveResult {
  ok: boolean;
  reservationId: number;
  mensaje: string;
  disponible: number;
}

export interface StockAvailableResult {
  ProductCode: string;
  StockQty: number;
  StockQtyReserved: number;
  StockQtyAvailable: number;
}

export async function reserveStockSP(params: ReserveParams): Promise<ReserveResult> {
  const rows = await callSp<{ ok: boolean; ReservationId: number; mensaje: string; Disponible: number }>(
    "usp_inv_stock_reserve",
    {
      CompanyId:     params.companyId,
      ProductCode:   params.productCode,
      Quantity:      params.quantity,
      ReferenceType: params.referenceType,
      ReferenceId:   params.referenceId,
      TtlMinutes:    params.ttlMinutes ?? 30,
      UserId:        params.userId ?? null,
    }
  );
  const r = rows[0];
  return {
    ok:            Boolean(r?.ok),
    reservationId: Number(r?.ReservationId ?? 0),
    mensaje:       String(r?.mensaje ?? ""),
    disponible:    Number(r?.Disponible ?? 0),
  };
}

export async function releaseStockSP(reservationId: number, companyId: number): Promise<{ ok: boolean; mensaje: string }> {
  const rows = await callSp<{ ok: boolean; mensaje: string }>(
    "usp_inv_stock_release",
    { ReservationId: reservationId, CompanyId: companyId }
  );
  const r = rows[0];
  return { ok: Boolean(r?.ok), mensaje: String(r?.mensaje ?? "") };
}

export async function commitStockSP(reservationId: number, companyId: number, unitCost = 0, userId?: number): Promise<{ ok: boolean; movementId: number; mensaje: string }> {
  const rows = await callSp<{ ok: boolean; MovementId: number; mensaje: string }>(
    "usp_inv_stock_commit",
    { ReservationId: reservationId, CompanyId: companyId, UnitCost: unitCost, UserId: userId ?? null }
  );
  const r = rows[0];
  return {
    ok:         Boolean(r?.ok),
    movementId: Number(r?.MovementId ?? 0),
    mensaje:    String(r?.mensaje ?? ""),
  };
}

export async function getStockAvailableSP(companyId: number, productCode: string): Promise<StockAvailableResult> {
  const rows = await callSp<StockAvailableResult>(
    "usp_inv_stock_available",
    { CompanyId: companyId, ProductCode: productCode }
  );
  return rows[0] ?? { ProductCode: productCode, StockQty: 0, StockQtyReserved: 0, StockQtyAvailable: 0 };
}

export async function cleanupExpiredReservationsSP(): Promise<number> {
  const rows = await callSp<{ released_count: number }>("usp_inv_stock_cleanup_expired", {});
  return Number(rows[0]?.released_count ?? 0);
}
