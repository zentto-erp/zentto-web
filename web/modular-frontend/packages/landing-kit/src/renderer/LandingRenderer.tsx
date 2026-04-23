/**
 * LandingRenderer — Server Component raíz del runtime renderer.
 *
 * Responsabilidades:
 *  1. Validar el schema vía Zod. Si falla → usa `fallback`.
 *  2. Renderizar `LandingHeader` (navbar) + sections + `LandingFooter`.
 *  3. Resolver cada `section.type` vía SECTION_MAP. Sections desconocidas
 *     → log warning + omit (no rompe).
 *
 * Preserva el wrapping exacto del `page.tsx` del hotel para pixel-equivalencia.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import { LandingHeader } from "../components/LandingHeader";
import { LandingFooter } from "../components/LandingFooter";
import type { LandingRendererProps } from "./types";
import { safeParseSchema } from "./schema.zod";
import { resolveSection } from "./section-map";
import { resolveIcon } from "./icon-registry";
import type { FooterColumn, SocialLink, NavLink } from "../types";

function mapFooterColumns(cols: unknown): FooterColumn[] {
  if (!Array.isArray(cols)) return [];
  return cols.map((c: any) => ({
    title: String(c?.title ?? ""),
    links: Array.isArray(c?.links)
      ? c.links.map((l: any) => ({
          label: String(l?.label ?? ""),
          href: String(l?.href ?? "#"),
          external: Boolean(l?.external),
        }))
      : [],
  }));
}

function mapSocialLinks(social: unknown): SocialLink[] {
  if (!Array.isArray(social)) return [];
  const out: SocialLink[] = [];
  for (const s of social as any[]) {
    const iconId = s?.iconId ?? s?.icon;
    const icon = resolveIcon(iconId, 16);
    const href = s?.href ?? s?.url;
    if (!icon || !href) continue;
    out.push({
      label: String(s?.label ?? iconId ?? ""),
      icon: icon as React.ReactNode,
      href: String(href),
    });
  }
  return out;
}

function mapNavLinks(links: unknown): NavLink[] {
  if (!Array.isArray(links)) return [];
  return links.map((l: any) => ({
    label: String(l?.label ?? ""),
    href: String(l?.href ?? "#"),
  }));
}

export function LandingRenderer({
  schema,
  fallback,
  tokens,
  registry = {},
  locale = "es",
  companyId,
  apiBaseUrl,
}: LandingRendererProps) {
  // Valida schema. Si viene undefined o inválido → usa fallback.
  const parsedRaw = schema ? safeParseSchema(schema) : undefined;
  const effective = parsedRaw ?? safeParseSchema(fallback) ?? fallback;

  const navbar = effective.landingConfig?.navbar;
  const footer = effective.landingConfig?.footer;
  const sections = effective.landingConfig?.sections ?? [];

  const verticalName =
    navbar?.verticalName ??
    navbar?.title ??
    effective.branding?.title ??
    "Zentto";

  const logoIconId =
    navbar?.logoIconId ?? effective.branding?.logoIconId ?? "HotelOutlined";

  const headerLogoIcon = resolveIcon(logoIconId, 20);
  const footerLogoIcon = resolveIcon(
    footer?.logoIconId ?? logoIconId,
    20,
  );

  const primaryCta = navbar?.primaryCta ?? navbar?.ctaButton;

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        bgcolor: tokens.color.bg,
        color: tokens.color.textPrimary,
      }}
    >
      {navbar ? (
        <LandingHeader
          tokens={tokens}
          verticalName={verticalName}
          logoIcon={headerLogoIcon}
          navLinks={mapNavLinks(navbar.links)}
          primaryCtaHref={primaryCta?.href}
          primaryCtaLabel={primaryCta?.label}
          loginHref={navbar.loginHref}
          homeHref={navbar.homeHref}
        />
      ) : null}

      <Box component="main" sx={{ flex: 1 }}>
        {sections.map((section) => {
          const Adapter = resolveSection(section.type);
          if (!Adapter) {
            if (typeof console !== "undefined" && console.warn) {
              console.warn(
                `[landing-kit] Tipo de sección desconocido: "${section.type}" (id=${section.id}) — omitido`,
              );
            }
            return null;
          }
          // Adapter puede ser sync o async (Server Component). `@types/react@18`
          // no tipifica async components — cast a FC para satisfacer JSX.
          const AdapterFC = Adapter as unknown as React.FC<
            import("./types").SectionAdapterProps
          >;
          return (
            <AdapterFC
              key={section.id}
              section={section}
              tokens={tokens}
              registry={registry}
              locale={locale}
              companyId={companyId}
              apiBaseUrl={apiBaseUrl}
            />
          );
        })}
      </Box>

      {footer ? (
        <LandingFooter
          tokens={tokens}
          verticalName={footer.verticalName ?? verticalName}
          logoIcon={footerLogoIcon}
          brandTagline={
            footer.brandTagline ??
            effective.branding?.subtitle ??
            "Parte del ecosistema Zentto."
          }
          columns={mapFooterColumns(footer.columns)}
          social={mapSocialLinks(footer.social)}
          legalLinks={footer.legalLinks}
          statusLink={footer.statusLink}
        />
      ) : null}
    </Box>
  );
}
