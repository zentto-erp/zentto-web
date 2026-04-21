# `@zentto/landing-kit` — Design spec (runtime renderer)

**Estado**: Draft para PR #3 del plan "landing schemas en CMS".
**Última revisión**: 2026-04-21

---

## 1. Propósito

`landing-kit` evoluciona de "paquete de componentes React hardcoded por el consumidor" a **runtime renderer de schemas JSON** compatibles con `@zentto/studio-core`, preservando SSG/SSR de Next.js y la estética enterprise existente en 8 verticales.

**Drivers:**
- Eliminar los 8 `catalog.tsx` hardcodeados (1 por vertical, ~220 líneas c/u).
- Dogfooding real: si vendemos `zentto-studio`, nuestras landings lo usan — al menos como schema.
- Permitir que product marketers editen en `zentto.net/cms/landings/:vertical` sin PR+deploy.

**Constraint empírico**: Lit no SSR en Next.js ([StudioPageRenderer.tsx:29-33](../module-ecommerce/src/components/StudioPageRenderer.tsx) lo validó en producción). Por tanto `landing-kit` provee el renderer React Server Component; Studio solo provee el schema.

---

## 2. API pública nueva (v2.0)

### 2.1 `<LandingRenderer>` — Server Component

```tsx
import { LandingRenderer } from "@zentto/landing-kit/renderer";
import { FrontDeskMockup } from "./FrontDeskMockup";

export default async function ParaHotelesPage() {
  const schema = await fetchLandingSchema("hotel", "para-hoteles");
  return (
    <LandingRenderer
      schema={schema}
      tokens={buildLandingTokens("hotel")}   // ← 9 paletas por vertical, ya existente
      registry={{
        "hero-hotel-frontdesk": FrontDeskMockup,   // ← escape hatch Builder.io-style
      }}
      fallback={HOTEL_FALLBACK_SCHEMA}      // ← snapshot embebido por si CMS falla
    />
  );
}
```

### 2.2 Props

| Prop | Tipo | Descripción |
|---|---|---|
| `schema` | `LandingConfig` (de `@zentto/studio-core/app-types`) | Schema JSON validado server-side con Zod. Si inválido → usa `fallback`. |
| `tokens` | `LandingTokens` | Paleta + escalas del vertical. Ya existe `buildLandingTokens(v)`. |
| `registry` | `Record<string, React.ComponentType<any>>` | Mapa `componentId` → Component para `type: 'custom'` sections. Patrón Builder.io. |
| `fallback` | `LandingConfig` opcional | Schema a usar si `schema` es `undefined` o falla validación. |
| `locale` | `"es" \| "en" \| "pt"` opcional | i18n aplicado a strings del schema (v2.1, no bloqueante). |

### 2.3 Exports del nuevo módulo `@zentto/landing-kit/renderer`

```ts
export { LandingRenderer } from "./LandingRenderer";
export { SECTION_MAP } from "./section-map";             // expuesto para testing
export { ICON_MAP, resolveIcon } from "./icon-registry"; // mapa string → MUI Icon
export { buildSchemaFromCatalog } from "./seed-builder"; // util migration
export { LandingSchemaZod } from "./schema.zod";         // validación server-side
export type { LandingRegistry, LandingRendererProps } from "./types";
```

### 2.4 Exports del paquete raíz (sin cambios breaking)

Los 11 componentes actuales (`LandingHeader`, `Hero`, etc.) **siguen exportándose igual**. La v2.0 es **aditiva** — no rompe a ningún consumer. Solo cuando una vertical migra a `<LandingRenderer>` deja de importar componentes individuales.

---

## 3. Arquitectura interna

### 3.1 Flujo de rendering

```
schema JSON  →  Zod.safeParse  →  SECTION_MAP[section.type]  →  Component
                     ↓ falla
                 fallback schema
```

### 3.2 `SECTION_MAP` — fuente única de resolución

```ts
// src/renderer/section-map.ts
import type { LandingSection } from "@zentto/studio-core";

export const SECTION_MAP: Record<string, React.ComponentType<SectionProps>> = {
  hero:          HeroAdapter,          // mapea HeroSectionConfig → <Hero>
  features:      FeatureGridAdapter,
  pricing:       PricingSectionAdapter,
  testimonials:  TestimonialsSectionAdapter,
  cta:           CTAFinalAdapter,
  logos:         TrustBarAdapter,       // studio 'logos' → landing-kit TrustBar
  "blog-preview": BlogTeaserAdapter,    // studio 'blog-preview' → landing-kit BlogTeaser
  // Gaps (Fase B.3):
  // timeline:   HowItWorksAdapter,     // adaptamos timeline a estilo "01/02/03"
  // faq:        FaqAdapter,
  // stats:      StatsAdapter,
  // content:    ContentAdapter,         // markdown → MUI Typography
  custom:        CustomSectionResolver,  // delega al registry del host
};
```

**Por qué adapters** (en vez de mapear 1:1 a los componentes `Hero`, `FeatureGrid`, etc.):
- El schema de studio-core es genérico (ej. `HeroSectionConfig` no tiene `eyebrow`, `showTrustBadges`).
- El componente `Hero` de hotel tiene props ricos (eyebrow pill con dot, trust badges inline, gradient text).
- El adapter **traduce** el schema genérico a los props específicos usando convenciones + `props?.__landingKit` (extensión opcional).

Ejemplo `HeroAdapter`:

```ts
function HeroAdapter({ section, tokens, registry }: SectionProps) {
  const cfg = section.heroConfig!;
  const ext = cfg.extensions?.__landingKit ?? {}; // campos extra fuera del schema canónico

  // Si el hero tiene un componentId → delegar al registry (escape hatch)
  if (ext.mockupComponentId && registry[ext.mockupComponentId]) {
    const CustomMockup = registry[ext.mockupComponentId];
    return (
      <Hero
        tokens={tokens}
        eyebrow={ext.eyebrow}
        headline={cfg.headline}
        headlineAccent={ext.headlineAccent}  // porción con gradient
        description={cfg.description}
        primaryCta={cfg.ctaPrimary}
        secondaryCta={cfg.ctaSecondary}
        trustBadges={ext.trustBadges}
        mockup={<CustomMockup tokens={tokens} />}
      />
    );
  }

  // Hero genérico con image/video background (studio default)
  return <Hero tokens={tokens} {...mapStudioHeroToLandingKit(cfg)} />;
}
```

### 3.3 `CustomSectionResolver` — Builder.io pattern

```tsx
function CustomSectionResolver({ section, registry }: SectionProps) {
  const cfg = section.customConfig; // { componentId: string, props?: Record<string, unknown> }
  const Component = registry[cfg.componentId];
  if (!Component) {
    console.warn(`[LandingRenderer] Custom component "${cfg.componentId}" not registered`);
    return null;
  }
  return <Component {...(cfg.props ?? {})} />;
}
```

**Nota**: `type: 'custom'` no existe aún en `@zentto/studio-core@0.14` (gap identificado). Workaround viable: usar `type: 'html'` con `htmlContent` como `"__CUSTOM__:component-id:{json-props}"` y detectarlo en el resolver. Preferimos el gap resuelto en studio-core 0.15, pero no es bloqueante de Fase B.

### 3.4 `ICON_MAP` — íconos via strings

El schema JSON no puede transportar React nodes. Los íconos viajan como strings (`"EventSeatOutlined"`) y el renderer los resuelve vía map estático.

```ts
// src/renderer/icon-registry.ts
import EventSeatOutlined from "@mui/icons-material/EventSeatOutlined";
import InsightsOutlined  from "@mui/icons-material/InsightsOutlined";
// ... resto de 50-80 íconos más usados en landings

export const ICON_MAP = {
  EventSeatOutlined,
  InsightsOutlined,
  CloudSyncOutlined,
  VpnKeyOutlined,
  PaymentOutlined,
  HotelOutlined,
  CheckCircleOutline,
  BoltOutlined,
  // redes sociales
  X: XIcon, LinkedIn: LinkedInIcon, GitHub: GitHubIcon, Facebook: FacebookIcon,
  // ... etc
} as const;

export type IconKey = keyof typeof ICON_MAP;

export function resolveIcon(key: string, fontSize = 24): React.ReactNode {
  const Icon = ICON_MAP[key as IconKey];
  if (!Icon) {
    return null; // render vacío si el icon no existe — no crashea
  }
  return <Icon sx={{ fontSize }} />;
}
```

**Decisión crítica**: el `ICON_MAP` vive dentro del renderer (package `landing-kit`), no en studio-core. Razón: tamaño del bundle. Cada vertical importa solo los íconos que usa. Studio-core provee los tipos del schema, pero el registry físico lo decide el host.

Si en el futuro un vertical necesita un ícono que no está en el map, se agrega al map central o se usa `type: 'custom'` para la sección.

### 3.5 Validación Zod

```ts
// src/renderer/schema.zod.ts
import { z } from "zod";

const LandingSectionZod = z.object({
  id: z.string(),
  type: z.string(),                 // permisivo — no validamos enum para evitar breaking al agregar types
  variant: z.string().optional(),
  anchor: z.string().optional(),
  background: z.any().optional(),
  padding: z.enum(["none","sm","md","lg","xl"]).optional(),
  animation: z.string().optional(),
  // Configs específicas — permisivas (validación estricta en adapters)
  heroConfig: z.any().optional(),
  featuresConfig: z.any().optional(),
  pricingConfig: z.any().optional(),
  testimonialsConfig: z.any().optional(),
  ctaConfig: z.any().optional(),
  logosConfig: z.any().optional(),
  blogPreviewConfig: z.any().optional(),
  customConfig: z.object({
    componentId: z.string(),
    props: z.record(z.unknown()).optional(),
  }).optional(),
}).passthrough(); // permite futuros campos sin romper

export const LandingSchemaZod = z.object({
  id: z.string(),
  version: z.string(),
  appMode: z.literal("landing"),
  branding: z.object({
    title: z.string(),
    subtitle: z.string().optional(),
    primaryColor: z.string().optional(),
  }),
  landingConfig: z.object({
    navbar: z.any(),
    footer: z.any(),
    sections: z.array(LandingSectionZod),
    seo: z.any().optional(),
  }),
}).passthrough();

export type ValidLandingSchema = z.infer<typeof LandingSchemaZod>;
```

**Estrategia**: validación estructural estricta, contenido permisivo. Los adapters validan su subset propio. Al agregar un nuevo section type a studio-core, el schema **no rompe** — pasa con warning.

---

## 4. Fallback strategy

### 4.1 Build-time (Next.js SSG)

```tsx
// zentto-hotel/frontend/src/app/para-hoteles/page.tsx (Fase B)
import { LandingRenderer } from "@zentto/landing-kit/renderer";
import { HOTEL_FALLBACK_SCHEMA } from "./fallback.schema";
import { FrontDeskMockup } from "./FrontDeskMockup";

async function fetchSchema() {
  try {
    const res = await fetch(`${API}/v1/public/cms/landings/by-slug?vertical=hotel&slug=para-hoteles&companyId=1&locale=es`, {
      next: { tags: ["landing:hotel:para-hoteles"], revalidate: 300 },
    });
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null; // silent fail — usa fallback
  }
}

export default async function ParaHotelesPage() {
  const schema = await fetchSchema();
  return (
    <LandingRenderer
      schema={schema?.data ?? undefined}
      fallback={HOTEL_FALLBACK_SCHEMA}   // nunca null
      tokens={tokens}
      registry={{ "hero-hotel-frontdesk": FrontDeskMockup }}
    />
  );
}
```

### 4.2 Fallback schema (snapshot embebido)

`fallback.schema.ts` es **el resultado del seed builder** commiteado en el repo como safety net. Se actualiza manualmente cada ~N semanas o cuando se publica un cambio crítico en la landing. El seed script (Fase B.4) puede generarlo automáticamente.

---

## 5. SEO y metadata

`LandingConfig.seo` (existe en studio-core) mapea a `generateMetadata` de Next.js App Router:

```ts
// zentto-hotel/frontend/src/app/para-hoteles/page.tsx
export async function generateMetadata() {
  const schema = await fetchSchema();
  const seo = schema?.data?.landingConfig?.seo ?? HOTEL_FALLBACK_SEO;
  return {
    title: seo.title,
    description: seo.description,
    openGraph: { title: seo.ogTitle ?? seo.title, images: [seo.ogImage].filter(Boolean) },
  };
}
```

`landing-kit/renderer` exporta `buildMetadataFromSchema(schema)` para evitar repetición.

---

## 6. Revalidación ISR on-demand

El endpoint `/api/revalidate` en cada frontend vertical recibe webhook del API cuando se publica:

```ts
// zentto-hotel/frontend/src/app/api/revalidate/route.ts
export async function POST(req: Request) {
  const token = req.headers.get("x-revalidate-token");
  if (token !== process.env.REVALIDATE_SECRET) return new Response("forbidden", { status: 403 });

  const { tag } = await req.json();
  revalidateTag(tag); // Next.js marca stale → próxima request regenera
  return Response.json({ ok: true, tag });
}
```

El fetch del schema incluye `tags: [\`landing:${vertical}:${slug}\`]` para que `revalidateTag` surta efecto.

---

## 7. Blog completo (Fase B.2)

**Decisión**: el blog completo (`/blog`, `/blog/[slug]`) vive en cada vertical como páginas separadas de la landing — NO forma parte del schema de landing. El schema tiene una sección `blog-preview` (teaser) que apunta a `/blog`.

### 7.1 Rutas nuevas por vertical

```
zentto-hotel/frontend/src/app/blog/
  ├── page.tsx           ← listado paginado de posts (vertical='hotel')
  └── [slug]/
      └── page.tsx       ← detalle del post markdown
```

### 7.2 Componentes reusables en `landing-kit/renderer/blog`

```ts
export { BlogIndex }      // listado paginado con filtros
export { BlogPostReader } // render markdown + meta + related posts
export { BlogBreadcrumbs }
```

Consumen `GET /v1/public/cms/posts?vertical=X` (existente) y `GET /v1/public/cms/posts/:slug` (existente). Usan `ReactMarkdown` + plugins (gfm, rehype-sanitize) para el body.

### 7.3 SEO blog

- `/blog` → metadata genérica del vertical (`"Ideas para hoteleros — Zentto Hotel"`)
- `/blog/[slug]` → `generateMetadata` usa el post fetched: `og:image` del cover, `article:published_time`, JSON-LD `Article`.

---

## 8. Testing

### 8.1 Unit (vitest + React Testing Library)

- `SECTION_MAP` mapea todos los tipos documentados
- `resolveIcon` fallback gracioso si key no existe
- `LandingSchemaZod` parsea fixtures válidos/inválidos
- Adapter de Hero con `registry` custom renderiza mockup inyectado

### 8.2 E2E (Playwright)

- Pixel diff `/para-hoteles` vs baseline snapshot antes de migración (< 2%)
- Lighthouse SEO ≥ 95 en hotel migrado
- Fallback: borrar response del CMS → página aún renderiza (con snapshot)

### 8.3 Integration (dev env)

- Publicar schema en `/cms` → cambio visible en `/para-hoteles` en ≤ 30s (via webhook + revalidateTag)

---

## 9. Roadmap del renderer (dentro de Fase B del plan global)

| PR | Scope | Output |
|---|---|---|
| B.1 | `src/renderer/`: SECTION_MAP minimal (hero, features, pricing, testimonials, cta, logos, blog-preview, custom) + Zod + icon-registry + adapters | landing-kit v2.0 en workspace (no publish aún) |
| B.2 | Blog completo: `BlogIndex`, `BlogPostReader`, rutas `/blog` y `/blog/[slug]` en hotel | hotel con blog funcional |
| B.3 | Adapters faltantes: `timeline`, `faq`, `stats`, `content`, `contact`, `gallery`, `video` | paridad studio 80% |
| B.4 | Seed builder: script que convierte `catalog.tsx` legacy → JSON | `scripts/seed-landing-from-code.ts` |
| B.5 | Publicar `@zentto/landing-kit@2.0.0` a npm privado | consumible por verticales |

---

## 10. Decisiones y trade-offs

| Decisión | Trade-off |
|---|---|
| Adapters en vez de mapeo 1:1 | +flexibilidad para custom props por vertical, -1 capa de indirección |
| ICON_MAP estático | +SSG funciona, -menos dinamismo (pero permite dynamic imports en v2.1) |
| Zod permisivo (passthrough) | +resiliencia a schema changes, -errores de datos tarde en runtime |
| Renderer en landing-kit (no studio-core) | +SSG sin Lit, -duplicación de tipos con studio-core |
| Escape hatch `custom` via registry | +potencia para mockups únicos, -pierde editabilidad desde CMS para esas piezas |

---

## 11. Abiertos (preguntas para Fase B)

1. ¿Tokens fuente de verdad sigue siendo `landing-kit`, o migramos a `@zentto/design-tokens` como paquete separado (clean architecture)?
2. ¿El `BlogPostReader` renderiza markdown o MDX? (MDX permite embeds de componentes, markdown es más simple y seguro).
3. ¿`/blog/[slug]` soporta RSS? (bueno para SEO + discoverability).
4. ¿Comentarios en posts (tipo Disqus) vivirán en Zentto propio o se embeben terceros?

Estas preguntas no bloquean el MVP. Se resuelven durante Fase B.2 / B.3.
