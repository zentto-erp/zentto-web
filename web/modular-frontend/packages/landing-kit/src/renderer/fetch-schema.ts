/**
 * `fetchLandingSchema` — helper compartido por las 8 verticales para obtener
 * su schema de landing del CMS.
 *
 * Contrato esperado del endpoint (PR #1, Fase A):
 *   GET {apiBaseUrl}/v1/public/cms/landings/by-slug
 *     ?vertical=hotel&slug=para-hoteles&companyId=1&locale=es
 *
 *   Preview (cross-subdomain):
 *   GET {apiBaseUrl}/v1/public/cms/landings/preview?token=UUID
 *
 *   Response OK (contrato actual, metadata + schema anidado):
 *     { ok: true, data: { landingSchemaId, version, status, ..., schema: {
 *         id, version, appMode, branding, landingConfig
 *     } } }
 *   Response OK (contrato legacy aplanado, también soportado):
 *     { ok: true, data: { id, version, appMode, branding, landingConfig } }
 *   Response error:
 *     { ok: false, error: { code, message } } (o HTTP !2xx)
 *
 * Comportamiento: try/catch silent fail. Nunca lanza. Si el fetch falla
 * (red, 404, 500, JSON inválido, timeout), retorna `undefined` y el caller
 * usa su fallback embebido — regla crítica: build-time con CMS caído NO
 * debe romper el deploy.
 */

import type { ValidLandingSchema } from "./schema.zod";
import { safeParseSchema } from "./schema.zod";

export interface FetchSchemaOpts {
  /** Base del API, sin trailing slash. Ej: "https://api.zentto.net". */
  apiBaseUrl: string;
  /** Vertical del tenant: "hotel", "medical", etc. */
  vertical: string;
  /** Slug de la landing: "para-hoteles", "home", etc. */
  slug: string;
  /** Tenant id. Default: 1 (Zentto corporate). */
  companyId: number;
  /** Locale: "es", "en", "pt". Default: "es". */
  locale?: string;
  /** Token de preview para ver draft sin auth (cross-subdomain). */
  previewToken?: string;
  /** Next.js ISR — seconds. Default: 300 (5 min). */
  revalidate?: number;
  /**
   * Custom Next.js tags para `revalidateTag()`. Default:
   * `["landing:{vertical}:{slug}"]`.
   */
  tags?: string[];
}

interface LandingApiResponse {
  ok: boolean;
  data?: unknown;
  error?: { code: string; message: string };
}

export async function fetchLandingSchema(
  opts: FetchSchemaOpts,
): Promise<ValidLandingSchema | undefined> {
  const {
    apiBaseUrl,
    vertical,
    slug,
    companyId,
    locale = "es",
    previewToken,
    revalidate = 300,
    tags,
  } = opts;

  if (!apiBaseUrl) return undefined;

  const base = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
  const effectiveTags = tags ?? [`landing:${vertical}:${slug}`];

  const url = previewToken
    ? `${base}/v1/public/cms/landings/preview?token=${encodeURIComponent(previewToken)}`
    : `${base}/v1/public/cms/landings/by-slug?${new URLSearchParams({
        vertical,
        slug,
        companyId: String(companyId),
        locale,
      }).toString()}`;

  try {
    const res = await fetch(url, {
      headers: { Accept: "application/json" },
      // Preview → no cache (siempre fresh). Publicado → ISR con tags.
      ...(previewToken
        ? { cache: "no-store" as const }
        : {
            next: {
              revalidate,
              tags: effectiveTags,
            },
          }),
    } as RequestInit);
    if (!res.ok) return undefined;
    const body = (await res.json()) as LandingApiResponse;
    if (!body.ok || body.data === undefined) return undefined;

    // El endpoint devuelve metadata + `schema` anidado para los endpoints
    // públicos (by-slug/preview). Algunos clientes de contrato más antiguos
    // pueden aplanar a `data` directamente. Soportamos ambos: preferir
    // `data.schema` si existe, sino caer a `data`.
    const maybeWrapped = body.data as Record<string, unknown>;
    const rawSchema =
      maybeWrapped && typeof maybeWrapped === "object" && "schema" in maybeWrapped
        ? (maybeWrapped as { schema: unknown }).schema
        : body.data;

    return safeParseSchema(rawSchema);
  } catch {
    return undefined;
  }
}
