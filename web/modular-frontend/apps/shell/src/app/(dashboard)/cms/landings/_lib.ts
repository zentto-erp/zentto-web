"use client";

/**
 * Service layer para landings CMS — usa el contrato en
 * web/api/src/modules/cms/landing-schemas.routes.ts (admin endpoints).
 *
 * No redeclaramos VERTICALS: reutilizamos el catálogo oficial del CMS (posts)
 * para que no haya divergencia de labels si agregamos/renombramos un vertical.
 */

import { apiGet, apiPost, apiPut } from "@zentto/shared-api";
import { VERTICALS } from "../_lib";

export { VERTICALS };

export type LandingStatus = "draft" | "published" | "archived";

export interface LandingListItem {
  landingSchemaId: number;
  companyId: number;
  vertical: string;
  slug: string;
  locale: string;
  version: number;
  status: LandingStatus;
  publishedAt: string | null;
  updatedAt: string | null;
}

export interface LandingDetail extends LandingListItem {
  /** Schema en edición (lo que consume `<ZenttoLandingDesigner>`). */
  draftSchema: Record<string, unknown> | null;
  /** Último snapshot publicado. */
  publishedSchema: Record<string, unknown> | null;
  themeTokens: Record<string, unknown> | null;
  seoMeta: Record<string, unknown> | null;
  /** UUID para preview cross-subdomain vía `/v1/public/cms/landings/preview?token=X`. */
  previewToken: string | null;
  createdAt: string | null;
  createdBy: number | null;
  publishedBy: number | null;
  updatedBy: number | null;
}

export interface LandingListResponse {
  ok: boolean;
  data: LandingListItem[];
  total: number;
  limit: number;
  offset: number;
}

export interface LandingDetailResponse {
  ok: boolean;
  data: LandingDetail;
}

export interface LandingVersion {
  landingSchemaHistoryId: number;
  landingSchemaId: number;
  version: number;
  publishedAt: string | null;
  publishedBy: number | null;
}

export interface UpsertDraftBody {
  vertical?: string;
  slug: string;
  locale: string;
  draftSchema: Record<string, unknown>;
  themeTokens?: Record<string, unknown> | null;
  seoMeta?: Record<string, unknown> | null;
}

// ─── List ────────────────────────────────────────────────────────────────────
export async function listLandings(
  opts: { vertical?: string; status?: LandingStatus; limit?: number; offset?: number } = {},
): Promise<LandingListResponse> {
  return apiGet("/v1/cms/landings", opts as Record<string, unknown>);
}

// ─── Detail ──────────────────────────────────────────────────────────────────
export async function getLanding(id: number): Promise<LandingDetailResponse> {
  return apiGet(`/v1/cms/landings/${id}`);
}

// ─── Upsert draft ────────────────────────────────────────────────────────────
/**
 * PUT /v1/cms/landings/:id — acepta `"new"` para creación.
 * Devuelve `{ landingSchemaId }` (el backend devuelve 201 en create, 200 en update).
 */
export async function upsertLandingDraft(
  id: number | "new",
  body: UpsertDraftBody,
): Promise<{ ok: boolean; mensaje?: string; data: { landingSchemaId: number } }> {
  return apiPut(`/v1/cms/landings/${id}`, body);
}

// ─── Publish ─────────────────────────────────────────────────────────────────
export async function publishLanding(
  id: number,
): Promise<{
  ok: boolean;
  mensaje?: string;
  data: { landingSchemaId: number; version: number; vertical?: string };
}> {
  return apiPost(`/v1/cms/landings/${id}/publish`, {});
}

// ─── Versions history ────────────────────────────────────────────────────────
export async function listLandingVersions(
  id: number,
  opts: { limit?: number; offset?: number } = {},
): Promise<{ ok: boolean; data: LandingVersion[]; total: number }> {
  return apiGet(`/v1/cms/landings/${id}/versions`, opts as Record<string, unknown>);
}

// ─── Preview token rotation ──────────────────────────────────────────────────
export async function rotatePreviewToken(
  id: number,
): Promise<{ ok: boolean; data: { landingSchemaId: number; previewToken: string | null } }> {
  return apiPost(`/v1/cms/landings/${id}/preview-token`, {});
}

// ─── Helpers de UI ───────────────────────────────────────────────────────────

/**
 * Construye la URL pública del landing publicado en el frontend dev del vertical.
 * Patrón: https://{vertical}dev.zentto.net/{slug} — usamos dev para no
 * interferir con prod al abrir preview desde el CMS dev.
 */
export function buildPublicUrl(vertical: string, slug: string, previewToken?: string | null): string {
  const base = `https://${vertical}dev.zentto.net`;
  // Slug "default" o vacío → home del vertical (que ya hosta la landing del CMS).
  const path = !slug || slug === "default" ? "" : `/${slug.replace(/^\/+/, "")}`;
  const url = `${base}${path}`;
  return previewToken ? `${url}?_preview=${encodeURIComponent(previewToken)}` : url;
}

/** Schema inicial mínimo para landings recién creadas. */
export function emptyLandingSchema(vertical: string, slug: string): Record<string, unknown> {
  return {
    id: `landing-${vertical}-${slug}`,
    version: "1.0.0",
    appMode: "landing",
    branding: {},
    landingConfig: {
      navbar: { items: [] },
      footer: {},
      sections: [],
    },
  };
}
