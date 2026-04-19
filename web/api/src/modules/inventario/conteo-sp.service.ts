/**
 * Conteo físico, Albaranes y Traslados multi-paso — Stored Procedures
 * Migration: 00135_inv_conteo_fisico_albaranes.sql
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

// ── Interfaces ────────────────────────────────────────────────────────────────

export interface HojaConteoRow {
  HojaConteoId: number;
  Numero: string;
  WarehouseCode: string;
  Estado: string;
  FechaConteo: string;
  FechaCierre: string | null;
  TotalLineas: number;
  LineasContadas: number;
}

export interface HojaConteoListResult {
  rows: HojaConteoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface AlbaranRow {
  AlbaranId: number;
  Numero: string;
  Tipo: string;
  Estado: string;
  FechaEmision: string;
  WarehouseFrom: string | null;
  WarehouseTo: string | null;
  DestinatarioNombre: string | null;
  TotalLineas: number;
}

export interface AlbaranListResult {
  rows: AlbaranRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  ok: boolean;
  mensaje: string;
}

export interface CreateResult extends SpResult {
  id: number;
  numero: string;
}

// ── Conteo físico ─────────────────────────────────────────────────────────────

/** usp_inv_conteo_fisico_create */
export async function crearHojaConteoSP(
  companyId: number,
  warehouseCode: string,
  userId: number,
  notas?: string,
): Promise<CreateResult> {
  const rows = await callSp<{ ok: boolean; HojaConteoId: number; Numero: string; mensaje: string }>(
    "usp_inv_conteo_fisico_create",
    { p_company_id: companyId, p_warehouse_code: warehouseCode, p_user_id: userId, p_notas: notas ?? null },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, id: r?.HojaConteoId ?? 0, numero: r?.Numero ?? "", mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_conteo_fisico_upsert_linea */
export async function upsertLineaConteoSP(params: {
  hojaConteoId: number;
  productCode: string;
  stockFisico: number;
  unitCost?: number;
  justificacion?: string;
  userId?: number;
}): Promise<SpResult & { lineaId: number }> {
  const rows = await callSp<{ ok: boolean; LineaId: number; mensaje: string }>(
    "usp_inv_conteo_fisico_upsert_linea",
    {
      p_hoja_conteo_id: params.hojaConteoId,
      p_product_code:   params.productCode,
      p_stock_fisico:   params.stockFisico,
      p_unit_cost:      params.unitCost ?? 0,
      p_justificacion:  params.justificacion ?? null,
      p_user_id:        params.userId ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, lineaId: r?.LineaId ?? 0, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_conteo_fisico_close */
export async function cerrarHojaConteoSP(
  hojaConteoId: number,
  companyId: number,
  userId: number,
): Promise<SpResult & { ajustesGenerados: number }> {
  const rows = await callSp<{ ok: boolean; AjustesGenerados: number; mensaje: string }>(
    "usp_inv_conteo_fisico_close",
    { p_hoja_conteo_id: hojaConteoId, p_company_id: companyId, p_user_id: userId },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, ajustesGenerados: r?.AjustesGenerados ?? 0, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_conteo_fisico_list */
export async function listHojasConteoSP(params: {
  companyId: number;
  estado?: string;
  warehouseCode?: string;
  page?: number;
  limit?: number;
}): Promise<HojaConteoListResult> {
  const page  = Math.max(1, params.page  || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const rows = await callSp<HojaConteoRow & { TotalCount: number }>(
    "usp_inv_conteo_fisico_list",
    {
      p_company_id:     params.companyId,
      p_estado:         params.estado         || null,
      p_warehouse_code: params.warehouseCode  || null,
      p_page:           page,
      p_limit:          limit,
    },
  );

  return {
    rows:  rows || [],
    total: Number(rows?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

// ── Albaranes ─────────────────────────────────────────────────────────────────

/** usp_inv_albaran_create */
export async function crearAlbaranSP(params: {
  companyId: number;
  tipo: "DESPACHO" | "RECEPCION" | "TRASLADO";
  warehouseFrom?: string;
  warehouseTo?: string;
  destinatarioNombre?: string;
  destinatarioRif?: string;
  sourceType?: string;
  sourceId?: number;
  observaciones?: string;
  userId?: number;
}): Promise<CreateResult> {
  const rows = await callSp<{ ok: boolean; AlbaranId: number; Numero: string; mensaje: string }>(
    "usp_inv_albaran_create",
    {
      p_company_id:            params.companyId,
      p_tipo:                  params.tipo,
      p_warehouse_from:        params.warehouseFrom       ?? null,
      p_warehouse_to:          params.warehouseTo         ?? null,
      p_destinatario_nombre:   params.destinatarioNombre  ?? null,
      p_destinatario_rif:      params.destinatarioRif     ?? null,
      p_source_type:           params.sourceType          ?? null,
      p_source_id:             params.sourceId            ?? null,
      p_observaciones:         params.observaciones       ?? null,
      p_user_id:               params.userId              ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, id: r?.AlbaranId ?? 0, numero: r?.Numero ?? "", mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_albaran_add_linea */
export async function addLineaAlbaranSP(params: {
  albaranId: number;
  productCode: string;
  cantidad: number;
  unidad?: string;
  costo?: number;
  lote?: string;
  vencimiento?: string;
  observaciones?: string;
}): Promise<SpResult & { albaranLineaId: number }> {
  const rows = await callSp<{ ok: boolean; AlbaranLineaId: number; mensaje: string }>(
    "usp_inv_albaran_add_linea",
    {
      p_albaran_id:   params.albaranId,
      p_product_code: params.productCode,
      p_cantidad:     params.cantidad,
      p_unidad:       params.unidad       ?? null,
      p_costo:        params.costo        ?? 0,
      p_lote:         params.lote         ?? null,
      p_vencimiento:  params.vencimiento  ?? null,
      p_observaciones: params.observaciones ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, albaranLineaId: r?.AlbaranLineaId ?? 0, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_albaran_emit */
export async function emitirAlbaranSP(albaranId: number, companyId: number, userId: number): Promise<SpResult> {
  const rows = await callSp<{ ok: boolean; mensaje: string }>(
    "usp_inv_albaran_emit",
    { p_albaran_id: albaranId, p_company_id: companyId, p_user_id: userId },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_albaran_sign */
export async function firmarAlbaranSP(
  albaranId: number,
  companyId: number,
  userId: number,
  firmante?: string,
): Promise<SpResult & { movimientosGenerados: number }> {
  const rows = await callSp<{ ok: boolean; MovimientosGenerados: number; mensaje: string }>(
    "usp_inv_albaran_sign",
    { p_albaran_id: albaranId, p_company_id: companyId, p_user_id: userId, p_firmante: firmante ?? null },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, movimientosGenerados: r?.MovimientosGenerados ?? 0, mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_albaran_list */
export async function listAlbaranesSP(params: {
  companyId: number;
  tipo?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}): Promise<AlbaranListResult> {
  const page  = Math.max(1, params.page  || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const rows = await callSp<AlbaranRow & { TotalCount: number }>(
    "usp_inv_albaran_list",
    {
      p_company_id:  params.companyId,
      p_tipo:        params.tipo        || null,
      p_estado:      params.estado      || null,
      p_fecha_desde: params.fechaDesde  || null,
      p_fecha_hasta: params.fechaHasta  || null,
      p_page:        page,
      p_limit:       limit,
    },
  );

  return {
    rows:  rows || [],
    total: Number(rows?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

// ── Traslados multi-paso ──────────────────────────────────────────────────────

/** usp_inv_traslado_create */
export async function crearTrasladoMultiPasoSP(params: {
  companyId: number;
  warehouseFrom: string;
  warehouseTo: string;
  userId: number;
  notas?: string;
}): Promise<CreateResult> {
  const rows = await callSp<{ ok: boolean; TrasladoId: number; Numero: string; mensaje: string }>(
    "usp_inv_traslado_create",
    {
      p_company_id:     params.companyId,
      p_warehouse_from: params.warehouseFrom,
      p_warehouse_to:   params.warehouseTo,
      p_user_id:        params.userId,
      p_notas:          params.notas ?? null,
    },
  );
  const r = rows[0];
  return { ok: r?.ok ?? false, id: r?.TrasladoId ?? 0, numero: r?.Numero ?? "", mensaje: r?.mensaje ?? "error" };
}

/** usp_inv_traslado_advance */
export async function avanzarTrasladoSP(params: {
  trasladoId: number;
  companyId: number;
  userId: number;
  action: "APROBAR" | "DESPACHAR" | "RECIBIR" | "CANCELAR";
}): Promise<SpResult & { nuevoEstado: string; albaranId: number | null }> {
  const rows = await callSp<{ ok: boolean; NuevoEstado: string; AlbaranId: number | null; mensaje: string }>(
    "usp_inv_traslado_advance",
    {
      p_traslado_id: params.trasladoId,
      p_company_id:  params.companyId,
      p_user_id:     params.userId,
      p_action:      params.action,
    },
  );
  const r = rows[0];
  return {
    ok:          r?.ok          ?? false,
    nuevoEstado: r?.NuevoEstado ?? "",
    albaranId:   r?.AlbaranId   ?? null,
    mensaje:     r?.mensaje     ?? "error",
  };
}
