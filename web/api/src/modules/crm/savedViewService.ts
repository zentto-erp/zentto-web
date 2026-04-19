/**
 * savedViewService.ts — CRM SavedView (CRM-108)
 *
 * Gestiona vistas guardadas (filtros + columnas + orden) por usuario/entidad
 * para grids y listados del CRM. Multi-tenant por CompanyId.
 *
 * Dual-DB: llama SPs usp_CRM_SavedView_* (PostgreSQL + SQL Server).
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Tipos ────────────────────────────────────────────────────────────────────

export type SavedViewEntity = "LEAD" | "CONTACT" | "COMPANY" | "DEAL" | "ACTIVITY";

export interface SavedView {
  ViewId: number;
  CompanyId: number;
  UserId: number;
  Entity: SavedViewEntity;
  Name: string;
  FilterJson: Record<string, unknown> | null;
  ColumnsJson: unknown[] | null;
  SortJson: unknown[] | null;
  IsShared: boolean;
  IsDefault: boolean;
  IsOwner: boolean;
  CreatedAt: string;
  UpdatedAt: string;
}

interface SpResult {
  success: boolean;
  message: string;
  viewId?: number | null;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

function userIdFromReq(req: { user?: { userId?: number; id?: number } }): number {
  return req.user?.userId ?? req.user?.id ?? 0;
}

function toJsonParam(v: unknown): string | null {
  if (v === undefined || v === null) return null;
  if (typeof v === "string") return v;
  try {
    return JSON.stringify(v);
  } catch {
    return null;
  }
}

// ── Listar ───────────────────────────────────────────────────────────────────

export async function listSavedViews(
  userId: number,
  entity?: SavedViewEntity,
): Promise<SavedView[]> {
  const { companyId } = scope();
  const rows = await callSp<SavedView>("usp_CRM_SavedView_List", {
    CompanyId: companyId,
    UserId: userId,
    Entity: entity ?? null,
  });
  return rows ?? [];
}

// ── Detalle ──────────────────────────────────────────────────────────────────

export async function getSavedView(
  userId: number,
  viewId: number,
): Promise<SavedView | null> {
  const { companyId } = scope();
  const rows = await callSp<SavedView>("usp_CRM_SavedView_Detail", {
    CompanyId: companyId,
    UserId: userId,
    ViewId: viewId,
  });
  return rows?.[0] ?? null;
}

// ── Upsert (create o update) ─────────────────────────────────────────────────

export interface UpsertSavedViewInput {
  viewId?: number | null;
  entity?: SavedViewEntity;
  name?: string;
  filterJson?: unknown;
  columnsJson?: unknown;
  sortJson?: unknown;
  isShared?: boolean;
  isDefault?: boolean;
}

export async function upsertSavedView(
  userId: number,
  data: UpsertSavedViewInput,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_SavedView_Upsert",
    {
      CompanyId: companyId,
      UserId: userId,
      ViewId: data.viewId ?? null,
      Entity: data.entity ?? null,
      Name: data.name ?? null,
      FilterJson: toJsonParam(data.filterJson) ?? "{}",
      ColumnsJson: toJsonParam(data.columnsJson),
      SortJson: toJsonParam(data.sortJson),
      IsShared: data.isShared ?? false,
      IsDefault: data.isDefault ?? false,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      OutViewId: sql.BigInt,
    },
  );

  // PG retorna columna "ViewId" en el RETURNS TABLE.
  // MSSQL la expone como @OutViewId OUTPUT.
  const rawViewId =
    output.OutViewId ??
    (output as any).ViewId ??
    (output as any).viewid ??
    null;

  return {
    success: Number(output.Resultado ?? (output as any).ok ?? 0) === 1,
    message: String(output.Mensaje ?? (output as any).mensaje ?? "OK"),
    viewId: rawViewId != null ? Number(rawViewId) : null,
  };
}

// ── Delete ───────────────────────────────────────────────────────────────────

export async function deleteSavedView(
  userId: number,
  viewId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_SavedView_Delete",
    {
      CompanyId: companyId,
      UserId: userId,
      ViewId: viewId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );

  return {
    success: Number(output.Resultado ?? (output as any).ok ?? 0) === 1,
    message: String(output.Mensaje ?? (output as any).mensaje ?? "OK"),
  };
}

// ── Set Default ──────────────────────────────────────────────────────────────

export async function setDefaultSavedView(
  userId: number,
  viewId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_SavedView_SetDefault",
    {
      CompanyId: companyId,
      UserId: userId,
      ViewId: viewId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );

  return {
    success: Number(output.Resultado ?? (output as any).ok ?? 0) === 1,
    message: String(output.Mensaje ?? (output as any).mensaje ?? "OK"),
  };
}

// Re-export helper para las routes.
export { userIdFromReq };
