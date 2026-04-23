"use client";

/**
 * Service layer para páginas corporativas CMS — usa el contrato en
 * web/api/src/modules/cms/routes.admin.ts (admin endpoints bajo /v1/cms/pages).
 *
 * Tipos canónicos `PageType` alineados con `CMS_PAGE_TYPES` del backend
 * (web/api/src/modules/cms/schema.ts).
 *
 * Reutiliza VERTICALS del _lib.ts raíz del CMS para no divergir labels.
 */

import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";
import { VERTICALS } from "../_lib";

export { VERTICALS };

export const CMS_PAGE_TYPES = [
  "about",
  "contact",
  "press",
  "legal-terms",
  "legal-privacy",
  "case-study",
  "custom",
] as const;

export type CmsPageType = (typeof CMS_PAGE_TYPES)[number];

export const PAGE_TYPE_LABELS: Record<CmsPageType, string> = {
  about: "Acerca",
  contact: "Contacto",
  press: "Prensa",
  "legal-terms": "Términos y condiciones",
  "legal-privacy": "Privacidad",
  "case-study": "Caso de éxito",
  custom: "Personalizada",
};

export const PAGE_TYPE_COLORS: Record<CmsPageType, "default" | "primary" | "secondary" | "info" | "success" | "warning" | "error"> = {
  about: "info",
  contact: "primary",
  press: "secondary",
  "legal-terms": "warning",
  "legal-privacy": "warning",
  "case-study": "success",
  custom: "default",
};

export type PageStatus = "draft" | "published" | "archived";

export interface CmsPage {
  PageId: number;
  CompanyId: number;
  Slug: string;
  Vertical: string;
  PageType: CmsPageType | string;
  Locale: string;
  Title: string;
  Body?: string;
  Meta?: Record<string, unknown>;
  SeoTitle: string;
  SeoDescription: string;
  Status: PageStatus | string;
  PublishedAt: string | null;
  CreatedAt?: string;
  UpdatedAt: string;
}

export interface PageListResponse {
  ok: boolean;
  data: CmsPage[];
  total?: number;
  limit?: number;
  offset?: number;
}

export interface PageDetailResponse {
  ok: boolean;
  data: CmsPage;
}

// ─── List ────────────────────────────────────────────────────────────────────
export async function listPages(
  opts: { vertical?: string; locale?: string; status?: string; pageType?: string; limit?: number; offset?: number } = {},
): Promise<PageListResponse> {
  return apiGet("/v1/cms/pages", opts as Record<string, unknown>);
}

// ─── Detail ──────────────────────────────────────────────────────────────────
export async function getPage(
  slug: string,
  vertical = "corporate",
  locale = "es",
): Promise<PageDetailResponse> {
  return apiGet(`/v1/cms/pages/${encodeURIComponent(slug)}`, { vertical, locale });
}

// ─── Upsert ──────────────────────────────────────────────────────────────────
/**
 * `id === 'new'` → POST /v1/cms/pages
 * `id === number` → PUT /v1/cms/pages/:id
 */
export async function upsertPage(
  id: number | "new",
  input: Partial<CmsPage> & { Slug?: string; Title?: string },
): Promise<{ ok: boolean; mensaje: string; page_id: number }> {
  const body = toPageBody(input);
  if (id === "new") {
    return apiPost("/v1/cms/pages", body);
  }
  return apiPut(`/v1/cms/pages/${id}`, body);
}

export async function publishPage(id: number): Promise<{ ok: boolean; mensaje: string }> {
  return apiPost(`/v1/cms/pages/${id}/publish`, {});
}

export async function deletePage(id: number): Promise<{ ok: boolean; mensaje: string }> {
  return apiDelete(`/v1/cms/pages/${id}`);
}

function toPageBody(p: Partial<CmsPage> & { Slug?: string; Title?: string }) {
  return {
    slug: p.Slug ?? "",
    vertical: p.Vertical ?? "corporate",
    locale: p.Locale ?? "es",
    title: p.Title ?? "",
    body: p.Body ?? "",
    meta: p.Meta ?? {},
    seoTitle: p.SeoTitle ?? "",
    seoDescription: p.SeoDescription ?? "",
    pageType: (p.PageType as CmsPageType | undefined) ?? "custom",
  };
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
export function slugify(s: string): string {
  return s
    .toLowerCase()
    .trim()
    .normalize("NFD").replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 100);
}

/**
 * Plantillas starter para cada tipo de página corporativa. Se usan al crear
 * una nueva page desde el editor. Devuelven un objeto `meta` con
 * `landingConfig` (hero + sections + footer) compatible con `@zentto/landing-kit`.
 */
export function pageTemplateMeta(
  pageType: CmsPageType,
  vertical = "corporate",
): Record<string, unknown> {
  switch (pageType) {
    case "about":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: `Acerca de ${vertical === "corporate" ? "Zentto" : vertical}`,
            subtitle: "Construimos el ERP que las empresas de verdad necesitan.",
            ctaPrimary: { label: "Contactar", href: "/contacto" },
          },
          sections: [
            {
              type: "features",
              title: "Nuestra misión",
              items: [
                { title: "Misión", description: "Democratizar la gestión empresarial." },
                { title: "Visión", description: "Ser el ERP multivertical de referencia en LATAM." },
                { title: "Valores", description: "Transparencia, velocidad, obsesión por el cliente." },
              ],
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    case "contact":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: "Contáctanos",
            subtitle: "Responderemos en menos de 24 horas.",
          },
          sections: [
            {
              type: "contactForm",
              title: "Envíanos un mensaje",
              fields: ["name", "email", "subject", "message"],
              submitLabel: "Enviar",
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    case "press":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: "Prensa y medios",
            subtitle: "Recursos, comunicados y kit de marca.",
          },
          sections: [
            {
              type: "pressReleases",
              title: "Comunicados recientes",
              items: [],
            },
            {
              type: "mediaKit",
              title: "Kit de marca",
              downloads: [
                { label: "Logo pack", href: "/brand/zentto-logos.zip" },
                { label: "Guía de marca (PDF)", href: "/brand/zentto-brand.pdf" },
              ],
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    case "legal-terms":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: "Términos y condiciones",
            subtitle: "Última actualización: " + new Date().toISOString().slice(0, 10),
          },
          sections: [
            {
              type: "legalContent",
              body: "# 1. Aceptación\n\nTexto pendiente — reemplazar con términos reales.",
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    case "legal-privacy":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: "Política de privacidad",
            subtitle: "Última actualización: " + new Date().toISOString().slice(0, 10),
          },
          sections: [
            {
              type: "legalContent",
              body: "# 1. Datos que recolectamos\n\nTexto pendiente — reemplazar con política real.",
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    case "case-study":
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: {
            title: "Caso de éxito: {{cliente}}",
            subtitle: "Cómo {{cliente}} redujo {{métrica}} con Zentto.",
          },
          sections: [
            {
              type: "caseStats",
              items: [
                { value: "-40%", label: "Tiempo de cierre contable" },
                { value: "+25%", label: "Productividad del equipo" },
              ],
            },
            {
              type: "caseStory",
              body: "# El reto\n\n# La solución\n\n# Resultados",
            },
          ],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
    default:
      return {
        landingConfig: {
          navbar: { items: [] },
          hero: { title: "", subtitle: "" },
          sections: [],
          footer: { copyright: new Date().getFullYear() + " Zentto" },
        },
      };
  }
}

/** URL pública esperada del vertical (dev) para el preview. */
export function buildPagePublicUrl(vertical: string, slug: string): string {
  const base =
    vertical === "corporate" ? "https://zenttodev.zentto.net" : `https://${vertical}dev.zentto.net`;
  const path = slug ? `/${slug.replace(/^\/+/, "")}` : "";
  return `${base}${path}`;
}
