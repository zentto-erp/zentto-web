# @zentto/landing-kit

Componentes enterprise B2B SaaS portables para todas las landings del ecosistema Zentto (tickets, hotel, medical, restaurante, education, inmobiliario, rental, pos, shipping).

Probado en producción en [`tickets.zentto.net`](https://tickets.zentto.net). Candidato a adopción por apps hermanas cuando lancen su landing SaaS B2B.

## Características

- **11 componentes** listos para componer una landing enterprise completa.
- **9 paletas por vertical** (`tickets` · `hotel` · `medical` · `restaurante` · ...) con el mismo set de neutrales WCAG AA.
- **Tipografía `clamp()` responsive** — sin saltos entre breakpoints.
- **Spacing canónico** — section vertical padding constante en todas las secciones.
- **Regla de simetría**: grids de N items solo aceptan breakpoints divisores de N (1/2/3/6 para 6).
- **Focus-visible AA** en todos los CTAs.
- **Helpers SEO** (`buildLandingMetadata`, `buildLandingRobots`, `buildLandingSitemap`).
- **Framework-agnostic** respecto al routing — acepta `Link` de Next.js (u otro) como prop.
- **Server Component por defecto** donde es posible (LandingHeader y CTAButton son client).

## Instalación

```bash
npm install @zentto/landing-kit
```

Peer deps: `react`, `react-dom`, `next`, `@mui/material`, `@mui/icons-material`.

## Uso mínimo

```tsx
// app/page.tsx
import Link from "next/link";
import HotelIcon from "@mui/icons-material/Hotel";
import {
  buildLandingTokens,
  LandingHeader, LandingFooter,
  TrustBar, FeatureGrid, HowItWorksSection,
  PricingSection, TestimonialsSection, CTAFinal,
} from "@zentto/landing-kit";

const tokens = buildLandingTokens("hotel");

export default function Page() {
  return (
    <>
      <LandingHeader
        tokens={tokens}
        verticalName="Hotel"
        logoIcon={<HotelIcon sx={{ fontSize: 20 }} />}
        LinkComponent={Link}
        navLinks={[
          { label: "Producto", href: "#features" },
          { label: "Precios", href: "#pricing" },
        ]}
      />

      <TrustBar tokens={tokens} logos={[{ name: "Hotel Caracas" }, { name: "VenueGroup" }]} />

      <FeatureGrid
        tokens={tokens}
        features={[
          { icon: <HotelIcon />, title: "Gestión multi-propiedad", description: "..." },
          // ...
        ]}
      />

      <HowItWorksSection tokens={tokens} steps={[
        { step: "01", title: "Conecta tu PMS", description: "..." },
        { step: "02", title: "Configura tarifas", description: "..." },
        { step: "03", title: "Recibe reservas", description: "..." },
      ]} />

      <PricingSection tokens={tokens} LinkComponent={Link} plans={[
        { name: "Starter", price: "Gratis", period: "para siempre", description: "...", bullets: [...], cta: "Empezar", href: "/register" },
        { name: "Pro", price: "$99", period: "por mes", description: "...", bullets: [...], cta: "Demo", href: "/demo", highlight: true },
      ]} />

      <TestimonialsSection tokens={tokens} testimonials={[
        { quote: "...", author: "María", role: "Revenue Mgr", company: "Hotel X", featured: true },
      ]} />

      <CTAFinal
        tokens={tokens}
        title="¿Listo para escalar tu hotel?"
        primaryCta={{ label: "Solicitar demo", href: "/demo" }}
        secondaryCta={{ label: "Probar gratis", href: "/register" }}
        LinkComponent={Link}
      />

      <LandingFooter
        tokens={tokens}
        verticalName="Hotel"
        logoIcon={<HotelIcon sx={{ fontSize: 20 }} />}
        brandTagline="PMS moderno para hoteles independientes y cadenas."
        LinkComponent={Link}
        columns={[
          { title: "Producto", links: [{ label: "Front desk", href: "/front-desk" }] },
          { title: "Recursos", links: [{ label: "Docs", href: "https://docs.zentto.net", external: true }] },
        ]}
      />
    </>
  );
}
```

## Metadata SEO

```tsx
// app/layout.tsx
import { buildLandingMetadata, buildLandingViewport } from "@zentto/landing-kit/metadata";

export const metadata = buildLandingMetadata({
  publicUrl: process.env.NEXT_PUBLIC_PUBLIC_URL ?? "https://hotel.zentto.net",
  titleDefault: "Zentto Hotel — PMS moderno para hoteles",
  description: "Property management system con booking engine...",
  applicationName: "Zentto Hotel",
});

export const viewport = buildLandingViewport();
```

```ts
// app/robots.ts
import { buildLandingRobots } from "@zentto/landing-kit/metadata";
export default () =>
  buildLandingRobots({
    publicUrl: process.env.NEXT_PUBLIC_PUBLIC_URL ?? "https://hotel.zentto.net",
  });
```

```ts
// app/sitemap.ts
import { buildLandingSitemap } from "@zentto/landing-kit/metadata";
export default () =>
  buildLandingSitemap({
    publicUrl: process.env.NEXT_PUBLIC_PUBLIC_URL ?? "https://hotel.zentto.net",
    routes: [
      { path: "/", changeFrequency: "weekly", priority: 1.0 },
      { path: "/demo", changeFrequency: "monthly", priority: 0.8 },
      { path: "/register", changeFrequency: "yearly", priority: 0.6 },
    ],
  });
```

El helper detecta automáticamente si la `publicUrl` contiene `dev` o `localhost` y activa `noindex`.

## Paletas por vertical

Cada vertical tiene su propio par `brand`/`accent`:

| Vertical | Brand | Accent |
|---|---|---|
| `tickets` | Indigo `#4F46E5` | Amber `#F59E0B` |
| `hotel` | Cyan `#0891B2` | Amber `#F59E0B` |
| `medical` | Emerald `#059669` | Sky `#0EA5E9` |
| `restaurante` | Red `#DC2626` | Amber `#F59E0B` |
| `education` | Purple `#7C3AED` | Amber `#F59E0B` |
| `inmobiliario` | Sky `#0284C7` | Amber `#F59E0B` |
| `rental` | Orange `#EA580C` | Indigo `#4F46E5` |
| `pos` | Green `#16A34A` | Amber `#F59E0B` |
| `shipping` | Blue `#2563EB` | Amber `#F59E0B` |

Los neutrales (`bg`, `textPrimary`, ...) son idénticos en todas las verticales → garantiza consistencia visual del ecosistema.

## Patrón de adopción

Cuando tu app quiera lanzar una landing B2B SaaS:

1. **Crear ruta** `app/para-{vertical}/page.tsx` (sin tocar la landing B2C existente si la hay).
2. **Definir catálogos específicos** del vertical en un archivo local:
   - `FEATURES` (6 cards)
   - `HOW_IT_WORKS` (3 pasos)
   - `PRICING_PLANS` (3 planes, el del medio con `highlight: true`)
   - `TESTIMONIALS` (1 featured + 2 compact)
   - `TRUST_LOGOS`, `NAV_LINKS`, `FOOTER_COLUMNS`, `SOCIAL`
3. **Invocar** `buildLandingTokens("vertical")` y pasar a todos los componentes.
4. **Configurar SEO** con `buildLandingMetadata` + `robots.ts` + `sitemap.ts`.
5. **Assets** en `/public/landing/{vertical}/` (OG image 1200×630, logos clientes SVG monocromos).

Ver como referencia la implementación en [`zentto-tickets`](https://github.com/zentto-erp/zentto-tickets) — la landing de `tickets.zentto.net` usa exactamente estos componentes (inicialmente local, a migrar cuando este paquete se publique a npm).

## Documentación canónica

El patrón completo está documentado en [`zentto-erp-docs/landings/enterprise-landing-pattern.md`](https://github.com/zentto-erp/zentto-erp-docs/blob/main/landings/enterprise-landing-pattern.md) — incluye wireframe, diagnóstico de anti-patrones, criterios de aceptación, playbook de adopción.

## Versionado

Sigue SemVer. Breaking changes bumpean major. Cambios en copy default / variantes de tokens bumpean minor. Bug fixes bumpean patch.

## License

MIT — uso interno del ecosistema Zentto.
