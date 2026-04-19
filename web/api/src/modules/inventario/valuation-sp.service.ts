/**
 * Valuation (FIFO/LIFO/WEIGHTED_AVG/LAST_COST/STANDARD) — SP wrappers
 * Migration: 00145_inv_fifo_lifo_valuation.sql
 */
import { callSp } from "../../db/query.js";

export type ValuationMethod = "FIFO" | "LIFO" | "WEIGHTED_AVG" | "LAST_COST" | "STANDARD";

export interface ValuationMethodRow {
  Method: ValuationMethod;
  StandardCost: number;
}

export interface ConsumeResult {
  ok: boolean;
  UnitCost: number;
  TotalCost: number;
  LayersConsumed: number;
  Method: ValuationMethod;
  mensaje: string;
}

/** usp_inv_valuation_get_method */
export async function getValuationMethodSP(
  companyId: number,
  productId: number,
): Promise<ValuationMethodRow> {
  const rows = await callSp<ValuationMethodRow>(
    "usp_inv_valuation_get_method",
    { p_company_id: companyId, p_product_id: productId },
  );
  const r = rows[0];
  return {
    Method: (r?.Method ?? "WEIGHTED_AVG") as ValuationMethod,
    StandardCost: Number(r?.StandardCost ?? 0),
  };
}

/** usp_inv_valuation_set_method */
export async function setValuationMethodSP(params: {
  companyId: number;
  productId: number;
  method: ValuationMethod;
  standardCost?: number;
  userId?: number;
}): Promise<{ ok: boolean; mensaje: string }> {
  const rows = await callSp<{ ok: boolean; mensaje: string }>(
    "usp_inv_valuation_set_method",
    {
      p_company_id:    params.companyId,
      p_product_id:    params.productId,
      p_method:        params.method,
      p_standard_cost: params.standardCost ?? 0,
      p_user_id:       params.userId ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_valuation_layer_create */
export async function createValuationLayerSP(params: {
  companyId: number;
  productId: number;
  quantity: number;
  unitCost: number;
  sourceDocumentType?: string;
  sourceDocumentNumber?: string;
  lotId?: number;
  layerDate?: string;
}): Promise<{ ok: boolean; layerId: number; mensaje: string }> {
  const rows = await callSp<{ ok: boolean; LayerId: number; mensaje: string }>(
    "usp_inv_valuation_layer_create",
    {
      p_company_id:             params.companyId,
      p_product_id:             params.productId,
      p_quantity:               params.quantity,
      p_unit_cost:              params.unitCost,
      p_source_document_type:   params.sourceDocumentType ?? null,
      p_source_document_number: params.sourceDocumentNumber ?? null,
      p_lot_id:                 params.lotId ?? null,
      p_layer_date:             params.layerDate ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, layerId: r?.LayerId ?? 0, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_valuation_consume */
export async function consumeValuationSP(
  companyId: number,
  productId: number,
  quantity: number,
): Promise<ConsumeResult> {
  const rows = await callSp<ConsumeResult>(
    "usp_inv_valuation_consume",
    { p_company_id: companyId, p_product_id: productId, p_quantity: quantity },
  );
  const r = rows[0];
  return {
    ok:             r?.ok ?? false,
    UnitCost:       Number(r?.UnitCost ?? 0),
    TotalCost:      Number(r?.TotalCost ?? 0),
    LayersConsumed: Number(r?.LayersConsumed ?? 0),
    Method:         (r?.Method ?? "WEIGHTED_AVG") as ValuationMethod,
    mensaje:        r?.mensaje ?? "error",
  };
}

/** usp_inv_product_current_cost */
export async function getProductCurrentCostSP(
  companyId: number,
  productId: number,
): Promise<{ UnitCost: number; Method: ValuationMethod }> {
  const rows = await callSp<{ UnitCost: number; Method: ValuationMethod }>(
    "usp_inv_product_current_cost",
    { p_company_id: companyId, p_product_id: productId },
  );
  const r = rows[0];
  return {
    UnitCost: Number(r?.UnitCost ?? 0),
    Method:   (r?.Method ?? "WEIGHTED_AVG") as ValuationMethod,
  };
}
