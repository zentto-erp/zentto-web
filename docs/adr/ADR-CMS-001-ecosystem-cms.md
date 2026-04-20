# ADR-CMS-001 — CMS del ecosistema Zentto (blog + páginas institucionales)

## Estado
**PROPUESTO** — autor: Claude Code + Raúl González Matute (product owner), 2026-04-20.

Pendiente: firma del product owner tras revisar este ADR.

## Contexto

Zentto vende `@zentto/studio` — un mini-framework web component que ya trae un **motor de blog completo** (`<zs-blog-list>`, `<zs-blog-post>`, `<zs-landing-page>` con 14 section types y 15 templates). Sin embargo:

- [zentto.net](https://zentto.net) **no tiene blog, prensa ni recursos**. Tiene landing corporativa, verticales, pricing y nosotros — pero ninguna sección editorial.
- Las 8 apps verticales (hotel, medical, tickets, restaurante, education, inmobiliario, rental, pos) tienen landing B2B `/para-{vertical}` con `@zentto/landing-kit`, pero **ninguna tiene blog, acerca, contacto real, prensa ni casos**.
- `zentto-docs` (Astro) ya tiene `/casos`, `/casos/[slug]`, `/contacto`, `/carreras`, `/productos`, pero no blog.
- Otros dos sistemas de landing conviven: `zentto-landings` (Astro, paid ads) y `zentto-landing-designer` (Electron visual builder).

Son **4 sistemas de contenido** sin frontera clara. El product owner resume la tensión:

> "¿Cómo vamos a vender algo que ni siquiera nosotros como solución usamos?"

Dos vectores de valor simultáneos:
1. **Credibilidad comercial + SEO orgánico** — blogs por vertical cubren long-tail y cross-sell.
2. **Dog-food** — usar nuestro propio stack (`@zentto/studio` + Astro + Notify) cierra la promesa de ecosistema.

Revisión crítica del `zentto-integration-reviewer` en [sesión 2026-04-20](../design/cms-review-2026-04-20.md): meter `@zentto/studio` (Lit web components) dentro de las 8 apps Next.js verticales multiplica bundles, rompe CSP (`unsafe-eval`), duplica deploys y choca con `@zentto/landing-kit` (React/MUI) ya en producción.

## Decisión 1 — Ubicación del CMS público: **`zentto-docs` (Astro)**

Todo el **blog + páginas institucionales corporativas** vive en `zentto-docs` (ya Astro, ya en producción con `/casos`). Se añaden rutas:
- `/blog`, `/blog/[slug]`, `/blog/categoria/[cat]`, `/blog/producto/[vertical]`
- `/acerca`, `/prensa`, `/recursos`

### Argumentos a favor
- Astro renderiza contenido ≥ 30% más rápido que Next.js SSR (MPA + islands, cero JS por defecto).
- `zentto-docs` ya tiene SEO orgánico y convierte; reaprovechamos dominio y autoridad.
- Frontera estable: **un solo dominio corporativo** para contenido editorial (`zentto.net`).
- No requiere tocar las 8 apps verticales ni sus pipelines.

### Argumentos en contra
- `zentto-docs` tiene varias ramas activas (`fix/i18n-links-legal-pages`, `feat/contact-form-notifications`, etc.) — trabajo en progreso de otros devs. Coordinación requerida.

### Riesgos
- Riesgo de contenido duplicado si cada vertical añade su propio blog. Mitigación: **un blog maestro** con categorías por vertical (`?vertical=hotel`), no 9 blogs independientes.

## Decisión 2 — Fuente de los posts: **BD dual (PG + SQL Server)**

Los posts viven en tablas `cms."Post"` + `cms."Page"`, servidos por el API central `DatqBoxWeb/web/api`. No Markdown-in-repo. Rationale:
- Autores no-devs pueden publicar desde un panel (`<zs-landing-designer>`) sin recompilar.
- Evita un CHANGELOG por repo vertical.
- Cumple regla dual DB obligatoria del proyecto.

### Argumentos a favor
- Centralizado → único punto de cambio para posts y páginas.
- Editor visual via `@zentto/studio` en backoffice (rol `cms_editor`, fase siguiente).
- Cacheable en `zentto-cache` (Redis) con TTL 5 min.

### Argumentos en contra
- Requiere 10 SPs × 2 motores = 20 SPs nuevos.
- Requiere migración goose + `sqlweb-mssql` patch + regenerar `pg2mssql.cjs`.
- Cada post requiere un API call (mitigado con ISR/SSG en Astro + Redis).

### Riesgos
- Latencia en builds SSG si cada post vivió en BD. Mitigación: Astro consume endpoint público con cache CDN agresivo; revalidación on-demand vía webhook al publicar.

## Decisión 3 — Integración en las 8 verticales: **feed API, NO `@zentto/studio` embebido**

Cada landing vertical `/para-{vertical}` añade **una sola sección "Últimos del blog"** al final (antes del CTA). Esta sección hace fetch a `GET /v1/public/posts?vertical={vertical}&limit=3` y renderiza con los componentes **React/MUI nativos** de cada app (o con un nuevo `<BlogTeaser>` en `@zentto/landing-kit`).

### Argumentos a favor
- Zero `@zentto/studio` en los 8 frontends → no hay conflicto con `@zentto/landing-kit`.
- No rompe CSP, no multiplica bundles Lit, no cambia `next.config.mjs`.
- Un único componente `<BlogTeaser>` en `landing-kit` reutilizado en 8 apps.

### Argumentos en contra
- Duplica lógica de "card de blog" en el reino React (vs. el `<zs-blog-card>` Lit de Studio).
- El diseñador/editor visual de Studio no alcanza a los teasers — son solo vitrinas.

### Riesgos
- Divergencia de estilo entre teaser (React) y post completo (Astro). Mitigación: tokens comunes vía `@zentto/shared-ui/DESIGN.md`.

## Decisión 4 — Endpoints API

**Públicos (sin auth):**
- `GET /v1/public/posts?vertical=&category=&locale=&limit=&offset=` → lista paginada (solo `Status='published'`).
- `GET /v1/public/posts/:slug?locale=` → detalle.
- `GET /v1/public/pages/:slug?vertical=&locale=` → página institucional.
- `GET /v1/public/posts/feed?vertical=&limit=` → feed JSON optimizado para teasers (min 5 campos).

**Privados (auth JWT httpOnly + rol `cms_editor`):**
- `POST /v1/cms/posts` · `PUT /v1/cms/posts/:id` · `DELETE /v1/cms/posts/:id`
- `POST /v1/cms/posts/:id/publish` · `POST /v1/cms/posts/:id/unpublish`
- `POST /v1/cms/pages` · `PUT /v1/cms/pages/:id` · `DELETE /v1/cms/pages/:id`
- `POST /v1/cms/pages/:id/publish`

**Tenant scope:** por defecto los posts/páginas son **globales corporativos** (`CompanyId = 1` = ZENTTO). Se permite multi-tenant futuro (CompanyId parametrizable) sin cambios de schema.

## Decisión 5 — Rol RBAC: **`cms_editor` en `zentto-auth`**

Nuevo rol `cms_editor` expedido vía `zentto-auth`. Requiere PR separado en ese repo (bloqueante para que las rutas `/v1/cms/*` sean usables en producción). Mientras tanto, endpoints quedan detrás de check `req.scope?.companyId === 1 && req.scope?.roles.includes('admin')` como fallback temporal.

## Decisión 6 — Newsletter y lead forms: **fase 2, vía `zentto-notify`**

- `/contacto` → reusa endpoint existente `POST /api/landing/register` (no duplicar).
- Newsletter signup → nuevo canal `list` en `zentto-notify` (fase siguiente). Fuera de scope de esta fase 1.

## Alcance de esta fase (PR `feat/cms-foundation`)

Este PR en `DatqBoxWeb` entrega solo la **fundación backend**:
- Migración goose `00147_cms_foundation.sql` (2 tablas + 10 SPs PG).
- SPs T-SQL equivalentes en `sqlweb-mssql/includes/sp/`.
- Módulo API `web/api/src/modules/cms/` con routes + service + zod.
- Actualización de `web/contracts/openapi.yaml`.

Los demás repos se disparan vía **GitHub issues paralelos**:
- `zentto-docs` — rutas `/blog`, `/acerca`, `/prensa`, `/recursos`, consumiendo el API.
- `zentto-auth` — rol `cms_editor`.
- `zentto-notify` — canal `list` para newsletter (fase 2).
- 8 apps verticales — sección "Últimos del blog" en `/para-{vertical}` vía fetch API + `<BlogTeaser>` de `@zentto/landing-kit`.

## Schema propuesto

```sql
-- Schema nuevo
CREATE SCHEMA IF NOT EXISTS cms;

-- cms."Post" — entradas de blog
cms."Post" (
  "PostId"         SERIAL PRIMARY KEY,
  "CompanyId"      INTEGER NOT NULL DEFAULT 1,     -- 1 = ZENTTO corporate; extensible a multi-marca
  "Slug"           VARCHAR(200) NOT NULL,
  "Vertical"       VARCHAR(50)  NOT NULL,          -- corporate|hotel|medical|tickets|...
  "Category"       VARCHAR(50)  NOT NULL,          -- producto|casos|tutoriales|noticias|changelog
  "Locale"         VARCHAR(10)  NOT NULL DEFAULT 'es',
  "Title"          VARCHAR(300) NOT NULL,
  "Excerpt"        VARCHAR(500) DEFAULT '',
  "Body"           TEXT NOT NULL,                   -- Markdown
  "CoverUrl"       VARCHAR(500) DEFAULT '',
  "AuthorName"     VARCHAR(200) DEFAULT '',
  "AuthorSlug"     VARCHAR(100) DEFAULT '',
  "AuthorAvatar"   VARCHAR(500) DEFAULT '',
  "Tags"           VARCHAR(500) DEFAULT '',         -- CSV simple
  "ReadingMin"     INTEGER DEFAULT 5,
  "SeoTitle"       VARCHAR(300) DEFAULT '',
  "SeoDescription" VARCHAR(500) DEFAULT '',
  "SeoImageUrl"    VARCHAR(500) DEFAULT '',
  "Status"         VARCHAR(20) NOT NULL DEFAULT 'draft',   -- draft|published|archived
  "PublishedAt"    TIMESTAMPTZ,
  "CreatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE ("Slug", "Locale")
);

-- cms."Page" — páginas institucionales (acerca, prensa, recursos)
cms."Page" (
  "PageId"         SERIAL PRIMARY KEY,
  "CompanyId"      INTEGER NOT NULL DEFAULT 1,
  "Slug"           VARCHAR(100) NOT NULL,           -- acerca|prensa|recursos|...
  "Vertical"       VARCHAR(50)  NOT NULL DEFAULT 'corporate',
  "Locale"         VARCHAR(10)  NOT NULL DEFAULT 'es',
  "Title"          VARCHAR(300) NOT NULL,
  "Body"           TEXT NOT NULL,
  "Meta"           JSONB NOT NULL DEFAULT '{}',     -- sections[], logos[], team[], etc.
  "SeoTitle"       VARCHAR(300) DEFAULT '',
  "SeoDescription" VARCHAR(500) DEFAULT '',
  "Status"         VARCHAR(20) NOT NULL DEFAULT 'draft',
  "PublishedAt"    TIMESTAMPTZ,
  "CreatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE ("Slug", "Vertical", "Locale")
);
```

## Criterios de aceptación del PR

- [ ] Migración goose 00147 aplica limpio en PG (zentto_dev).
- [ ] SPs T-SQL equivalentes commiteados en `sqlweb-mssql/includes/sp/`.
- [ ] Módulo `cms/` registrado en `app.ts` (`/v1/public/*` y `/v1/cms/*`).
- [ ] OpenAPI describe los 10 endpoints nuevos con ejemplos.
- [ ] Endpoints públicos devuelven solo `Status='published'`.
- [ ] Endpoints privados rechazan sin auth (401).
- [ ] Build TypeScript pasa (`npm run build` en `web/api`).
- [ ] Tests de contrato SP existen (mínimo list + get).
- [ ] CI verde en GitHub Actions.

## Siguientes pasos (post-merge)

- Issue `zentto-docs`: rutas blog + páginas + 3 posts corporativos semilla.
- Issue `zentto-auth`: rol `cms_editor`.
- Issue `landing-kit`: componente `<BlogTeaser>`.
- 8 issues (uno por app vertical): sección "Últimos del blog" en `/para-{vertical}`.
- Issue `zentto-notify`: canal `list` para newsletter (fase 2).
- Issue `zentto-cache`: TTL y invalidación on-publish.

## Referencias

- Brief del zentto-designer: "Dog-food del ecosistema Zentto" (sesión 2026-04-20).
- Review crítica del zentto-integration-reviewer (sesión 2026-04-20).
- Módulo `brand/` como patrón de módulo simple: [web/api/src/modules/brand/routes.ts](../../web/api/src/modules/brand/routes.ts).
- Migración de referencia: [00081_brand_config_table_and_sps.sql](../../web/api/migrations/postgres/00081_brand_config_table_and_sps.sql).
