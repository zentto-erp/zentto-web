---
title: ADR-LANDING-001 — Studio Schema + landing-kit Renderer
date: 2026-04-21
status: accepted
---

# ADR-LANDING-001 — Studio Schema + landing-kit Renderer

## Estado

**ACCEPTED** — 2026-04-21 (Raúl González Matute, product owner).

Fuente: sesión `/disena studio: llevar las landings al cms`. Análisis conjunto de
`zentto-designer` + `zentto-integration-reviewer`.

## Contexto

Las 8 landings `/para-{vertical}` (hotel, medical, tickets, restaurante, education,
inmobiliario, rental, pos) están hoy **hardcodeadas** en código TypeScript/JSX
dentro de `@zentto/landing-kit` + `catalog.tsx` de cada repo vertical. Cambiar el
copy o el orden de secciones requiere un PR + deploy. El product owner pidió
llevarlas al CMS (editor visual en `zentto.net/cms/landings/:vertical`) sin
perder SSG/SEO.

`zentto-studio-core` ya tiene un schema `LandingConfig` rico (27 `LandingSectionType`,
branding + navbar + footer + sections) que cubre lo que las landings verticales
necesitan. Sin embargo, el runtime de `zentto-studio` (`@zentto/studio-react`,
`@zentto/studio-web-component`) está **construido sobre Lit (web components)** y
**no declara `"use client"`**. Next.js 14+ Server Components **no pueden**
renderizar Lit en SSR/SSG:

- `LitElement` requiere `customElements` → no existe en Node.
- No hay `@lit-labs/ssr` en zentto-studio (grep vacío).
- No hay `renderLandingToHTML(schema)` ni `renderLandingToReact(schema)` en `studio-core`.

## Precedente crítico en el monorepo

`web/modular-frontend/packages/module-ecommerce/src/components/StudioPageRenderer.tsx:29-33`:

> "Hacemos un renderer MUI propio (Opción B) en lugar de importar `@zentto/studio-react`
> porque el studio original usa web components (Lit) que chocan con Next.js SSR."

**El equipo ya validó esta decisión en producción.** Esta ADR formaliza y extiende
ese patrón para las landings verticales.

## Alternativas evaluadas

### Opción A — Importar `@zentto/studio-react` dentro de cada landing

Rechazada. Lit no renderiza en SSR Next.js. Forzaría `dynamic(() => ..., { ssr: false })`
para cada sección, matando SSG → landings sin SEO → regresión directa del
objetivo de Lighthouse ≥ 95.

### Opción B — Renderer MUI custom por vertical (sin schema)

Rechazada. Duplica 8× el trabajo de mantenimiento. Rompe la promesa de "usamos
nuestro propio stack" (dog-fooding parcial).

### Opción C — Studio schema + landing-kit renderer (ELEGIDA)

Adoptar `LandingConfig` de `@zentto/studio-core` como **fuente de verdad del
schema** (tipos, validación), pero renderizar con `@zentto/landing-kit`
(React/MUI Server Component). Lit sólo vive en el **editor** (client-side en
`zentto.net/cms/landings/:vertical`).

## Consecuencias

### Positivas

- **SSG preservado** — Next.js + React Server Components siguen funcionando.
- **SEO inalterado** — HTML completo en la respuesta, Lighthouse ≥ baseline.
- **Dog-fooding parcial** — editamos en Studio, servimos con landing-kit.
- **Mockups custom mantenidos** — `FrontDeskMockup` y similares se registran
  via `registerCustomSection(id, Component)` (patrón Builder.io).
- **Preview cross-subdomain resuelto** — `PreviewToken` UUID en BD + endpoint
  público `/v1/public/cms/landings/preview?token=X`. Cookie httpOnly de
  `zentto.net` no llega a `hotel.zentto.net`, el token sí.
- **Rollout gradual** — flag `LANDING_FROM_CMS` por repo vertical (opt-in).

### Negativas / debt asumido

- **Dualidad runtime** — Studio renderiza en editor (Lit), landing-kit renderiza
  en producción (React). Riesgo: divergencia visual. Mitigación: Playwright
  pixel-diff < 2% antes de cada rollout vertical.
- **Dogfooding no completo** — la promesa "el ERP es la plataforma" se cumple a
  nivel de schema, no de runtime. Aceptable mientras `zentto-studio` no tenga
  SSR (futuro `@lit-labs/ssr` o `renderLandingToReact()`).
- **Sin import de `@zentto/studio-react` en Server Components** — si algún día
  se agregan secciones nuevas sólo en `studio`, requieren port manual al
  `SECTION_MAP` de landing-kit (PR #3 del plan).

## Bloqueantes / reglas no negociables

Documentadas en `C:/Users/Dell/.claude/projects/.../memory/project_landing_schemas_cms.md`:

1. **DB dual obligatorio** — migración goose + archivo MSSQL paralelo + SPs duales.
2. **Observability** — módulo `cms/` arranca `obs.audit/error/perf` wiring en este PR.
3. **Rol existente** — `CMS_EDITOR` (ya cubre multi-tenant vía `req.scope.companyId`). No crear `LANDING_EDITOR`.
4. **Preview token UUID** — tabla `cms.LandingSchema.PreviewToken`.
5. **Revalidate cross-container** — webhook POST con shared secret (`LANDING_REVALIDATE_ENABLED`, default OFF).
6. **Build-time fetch con fallback** — si CMS down durante `next build`, fallback a snapshot JSON (patrón `BlogTeaser.tsx:82-84`).
7. **Flag opt-in por repo vertical** — `vars.LANDING_FROM_CMS == 'true'`.
8. **Tokens de landing-kit** — fuente de verdad (9 paletas AA). `studio-core` los importará, no al revés.

## Secuencia de PRs (13 total)

**Fase A — Foundation (este PR y el siguiente, sin tocar frontends):**

- **PR #1 (este) — DatqBoxWeb**: migración `00161_cms_landing_schemas.sql` + patch
  MSSQL `11_patch_cms_landing_schemas.sql` + 8 SPs duales + 7 endpoints REST
  (`/v1/public/cms/landings/*` + `/v1/cms/landings/*`) + OpenAPI + `obs.audit/error/perf`
  wiring + ADR.
- PR #2 DatqBoxWeb: editor UI en `zentto.net/cms/landings/:vertical`.

**Fase B — Piloto hotel:**

- PR #3 DatqBoxWeb (landing-kit): `<LandingRenderer>` Server Component + `SECTION_MAP` + `registerCustomSection()`.
- PR #4 zentto-hotel: `page.tsx` fetch + fallback, flag `LANDING_FROM_CMS`.
- PR #5 zentto-hotel: `/api/revalidate` endpoint.
- PR #6 DatqBoxWeb: seed script + ADR publicado.

**Fase C — Rollout 6 verticales:** PRs #7-12 (medical, education, rental, inmobiliario, restaurante, pos).

**Fase D — Cleanup:** PR #13 tickets (decisión migrar `/` → `/para-ticketeras` o mantener divergencia).

**Regla**: NO empezar PR #3+ hasta PR #1 merged y smoke-test verde en `apidev.zentto.net`.

## Criterios de aceptación (al final del plan)

- Lighthouse SEO ≥ baseline (95+) por vertical.
- Pixel diff Playwright < 2% desktop + mobile vs actual.
- Schema inválido → fallback default, nunca 500.
- Multi-tenant: tenant A no ve landing de tenant B.
- Draft vs published: `?preview=TOKEN` muestra draft sin auth.
- BlogTeaser sigue conectado al CMS posts sin regresión.
- Mockups custom (FrontDeskMockup) pixel-identical vía registry.

## Referencias

- Precedente: `web/modular-frontend/packages/module-ecommerce/src/components/StudioPageRenderer.tsx:29-33`.
- Patrón SP dual: `web/api/migrations/postgres/00159_cms_multitenant.sql`.
- Patrón obs: `web/api/src/modules/backoffice/backoffice-auth.routes.ts:186, 237, 242`.
- Fallback pattern: `web/modular-frontend/packages/landing-kit/src/components/BlogTeaser.tsx:82-84`.
- ADR anterior: `docs/adr/ADR-CMS-001-ecosystem-cms.md`.
