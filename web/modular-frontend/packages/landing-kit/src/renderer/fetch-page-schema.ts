/**
 * `fetchPageSchema` — helper compartido por los 8 verticales para obtener el
 * schema JSON de una **página corporativa** (/acerca, /contacto, /prensa,
 * /legal/*) desde el CMS.
 *
 * Diferencia con `fetchLandingSchema`:
 *  - Endpoint distinto: `/v1/public/cms/pages/:slug` (no landings/by-slug).
 *  - El schema viaja en `Meta` (JSONB) del cms.Page en vez de en `Schema`
 *    dedicado — por economía de esquema: cms.Page ya existía para páginas
 *    text-based, extendemos `Meta` con `{ landingConfig: {...} }` para cargar
 *    schemas de sections editables por el CMS.
 *  - Tag ISR: `page:{vertical}:{pageType}:{slug}` (permite invalidar todas las
 *    pages de un tipo con `revalidateTag("page:hotel:about:*")` cuando el
 *    editor actualiza plantilla base).
 *
 * Contrato del endpoint:
 *   GET {apiBaseUrl}/v1/public/cms/pages/{slug}?vertical=hotel&locale=es
 *     (companyId se resuelve del subdomain/header en el backend)
 *
 *   Response OK:
 *     { ok: true, data: {
 *         PageId, CompanyId, Slug, Vertical, PageType, Locale, Title,
 *         Body, Meta: { landingConfig: ValidLandingSchema | ... },
 *         SeoTitle, SeoDescription, Status, PublishedAt, ...
 *       }
 *     }
 *
 * Comportamiento: try/catch silent fail. Nunca lanza. Retorna `undefined`
 * si:
 *   - No hay endpoint configurado
 *   - HTTP !2xx (404 página no existe, 400 tenant no resoluble, 500 server)
 *   - Response body no parseable
 *   - `Meta` no contiene un `ValidLandingSchema` válido
 *
 * El caller hace fallback al schema embebido.
 */

import type { ValidLandingSchema } from "./schema.zod";
import { safeParseSchema } from "./schema.zod";

export interface FetchPageSchemaOpts {
  /** Base del API (core CMS, no vertical-api). Ej: "https://apidev.zentto.net". */
  apiBaseUrl: string;
  /** Vertical: "hotel", "medical", etc. O "corporate" para pages globales. */
  vertical: string;
  /** Slug de la página: "acerca", "contacto", "prensa", "legal/privacidad". */
  slug: string;
  /** Tenant id explícito (opcional — el backend resuelve por subdomain si falta). */
  companyId?: number;
  /** Locale: "es", "en", "pt". Default: "es". */
  locale?: string;
  /** Next.js ISR — seconds. Default: 600 (10 min). Pages cambian menos que landings. */
  revalidate?: number;
  /**
   * Custom Next.js tags para `revalidateTag()`. Default:
   * `["page:{vertical}:{slug}"]`.
   */
  tags?: string[];
}

interface PageApiResponse {
  ok: boolean;
  data?: {
    PageId?: number;
    Vertical?: string;
    Slug?: string;
    PageType?: string;
    Title?: string;
    Meta?: unknown;
    Status?: string;
    [key: string]: unknown;
  };
  error?: { code: string; message: string };
}

export async function fetchPageSchema(
  opts: FetchPageSchemaOpts,
): Promise<ValidLandingSchema | undefined> {
  const {
    apiBaseUrl,
    vertical,
    slug,
    companyId,
    locale = "es",
    revalidate = 600,
    tags,
  } = opts;

  if (!apiBaseUrl || !slug) return undefined;

  const base = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
  const effectiveTags = tags ?? [`page:${vertical}:${slug}`];

  const params = new URLSearchParams({ vertical, locale });
  if (typeof companyId === "number" && companyId > 0) {
    params.set("company_id", String(companyId));
  }

  const url = `${base}/v1/public/cms/pages/${encodeURIComponent(slug)}?${params.toString()}`;

  try {
    const res = await fetch(url, {
      headers: { Accept: "application/json" },
      // Next.js extended RequestInit — solo relevante en Server Components
      ...({
        next: {
          revalidate,
          tags: effectiveTags,
        },
      } as unknown as RequestInit),
    });
    if (!res.ok) return undefined;
    const body = (await res.json()) as PageApiResponse;
    if (!body.ok || !body.data) return undefined;

    // El schema vive en `Meta.landingConfig` o `Meta` directo según cómo lo
    // guarde el editor. Soportamos ambos para compat forward.
    const meta = body.data.Meta;
    if (!meta || typeof meta !== "object") return undefined;

    const metaObj = meta as Record<string, unknown>;
    const rawSchema =
      "landingConfig" in metaObj && metaObj.landingConfig !== null
        ? // Caso editor nuevo: Meta = { landingConfig: { ... }, ...otherMeta }
          // Envolvemos el schema completo para pasárselo al renderer.
          wrapLandingConfig(metaObj as { landingConfig: unknown }, body.data)
        : // Caso editor directo: Meta YA es un schema completo.
          meta;

    return safeParseSchema(rawSchema);
  } catch {
    return undefined;
  }
}

function wrapLandingConfig(
  meta: { landingConfig: unknown; [key: string]: unknown },
  pageData: { Title?: string; Slug?: string; Vertical?: string; PageType?: string },
): unknown {
  // El editor guarda solo el `landingConfig` (sections + navbar + footer) para
  // ahorrar redundancia. Reconstruimos el schema completo con id/version/
  // branding sintetizados desde los metadatos de la page.
  const id = `cms-page-${pageData.Vertical ?? "corporate"}-${pageData.Slug ?? "unknown"}`;
  return {
    id,
    version: "1.0.0",
    appMode: "landing",
    branding: (meta.branding as object) ?? { title: pageData.Title ?? "" },
    landingConfig: meta.landingConfig,
  };
}
