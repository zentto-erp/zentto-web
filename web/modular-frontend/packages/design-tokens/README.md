# @zentto/design-tokens

Source-of-truth de design tokens de Zentto. Habilita **coherencia visual** entre los
dos stacks de UI del ecosistema según [ADR-NOTIFY-001 Opción C](../../../../../zentto-notify/docs/adr/ADR-NOTIFY-001-shared-ui-paradox.md):

| Stack           | Apps                                              | Consumo                                                |
| --------------- | ------------------------------------------------- | ------------------------------------------------------ |
| MUI             | `frontend-modular/*` (ERP, CRM, contabilidad…)    | `import { designTokens } from '@zentto/design-tokens'` |
| Tailwind v4     | microservicios (notify, futuros auditoria/cobros) | `@import '@zentto/design-tokens/css'` + `@theme`       |

## ¿Qué incluye?

- `designTokens.brand` — paleta de marca completa (derivada del ecommerce).
- `designTokens.color.light` / `.dark` — roles MUI `primary/secondary/success/warning/error/info` con `main/light/dark/contrastText` + `scheme` (background/surface/text/divider).
- `designTokens.color.lead` — roles CRM (`open` → primary, `won` → success, `lost` → error).
- `designTokens.color.priority` — `urgent/high` → error, `medium` → warning, `low` → info.
- `designTokens.layout` — `sectionGap: 24`, `formGap: 16`, `chipGap: 6`.
- `designTokens.density.rowHeight` — `{ compact: 28, default: 36, comfortable: 46 }` (px).
- `designTokens.typography.roles` — `display/headline/title/body/label`.
- `designTokens.radius` — `{ none: 0, sm: 4, md: 8, lg: 12, pill: 9999 }`.
- `designTokens.elevation` — 5 niveles (0..4) con sombras consistentes con MUI `Card`.
- `designTokens.zIndex` — base/dropdown/sticky/fixed/modalBackdrop/modal/popover/tooltip.
- `designTokens.breakpoints` — alineados con MUI `theme.breakpoints.values`.

## Instalación

Este paquete vive en el workspace del monorepo `zentto-modular-frontend`. No hace falta
`npm install` adicional — las apps lo consumen vía la topología del monorepo.

```bash
# Dentro de web/modular-frontend:
npm install
```

## Uso desde MUI (`@zentto/shared-ui`)

```ts
import { createTheme } from '@mui/material/styles';
import { designTokens } from '@zentto/design-tokens';

const theme = createTheme({
  palette: {
    primary: designTokens.color.light.primary,
    secondary: designTokens.color.light.secondary,
    error: designTokens.color.light.error,
    background: {
      default: designTokens.color.light.scheme.background,
      paper: designTokens.color.light.scheme.surface,
    },
    text: {
      primary: designTokens.color.light.scheme.text,
      secondary: designTokens.color.light.scheme.textSecondary,
    },
    divider: designTokens.color.light.scheme.divider,
  },
  typography: { fontFamily: designTokens.typography.fontFamily },
  shape: { borderRadius: designTokens.radius.lg },
  breakpoints: { values: designTokens.breakpoints },
});
```

Para densidad en `<zentto-grid>`:

```ts
import { designTokens, type DensityMode } from '@zentto/design-tokens';

const rowHeight = designTokens.density.rowHeight[density]; // density: DensityMode
```

## Uso desde Tailwind v4 (dashboard notify / microservicios)

`app/globals.css`:

```css
@import 'tailwindcss';
@import '@zentto/design-tokens/css';

/* Tailwind v4 @theme: aliases para que las utilidades resuelvan los tokens. */
@theme {
  --color-primary: var(--zentto-color-primary);
  --color-primary-contrast: var(--zentto-color-primary-contrast);
  --color-surface: var(--zentto-color-surface);
  --color-background: var(--zentto-color-background);
  --color-text: var(--zentto-color-text);
  --color-text-muted: var(--zentto-color-text-secondary);
  --color-divider: var(--zentto-color-divider);

  --font-sans: var(--zentto-font-family);
  --radius-md: var(--zentto-radius-md);
  --radius-lg: var(--zentto-radius-lg);
}
```

Luego en componentes Tailwind:

```tsx
<button className="bg-[var(--zentto-color-primary)] text-[var(--zentto-color-primary-contrast)] rounded-[var(--zentto-radius-lg)] h-[var(--zentto-density-row-default)]">
  Guardar
</button>
```

El archivo generado incluye variables para light (`:root`) y dark (`[data-theme="dark"]`, `.dark`, `[data-toolpad-color-scheme="dark"]`).

## Build

```bash
cd web/modular-frontend/packages/design-tokens
npm run build       # tsc (CommonJS) + genera dist/tokens.css + dist/index.js + *.d.ts
npm run build:css   # solo emite dist/tokens.css (re-usa dist/index.js o lo construye)
npm run typecheck   # strict type-check, no emite
```

- `dist/index.js` → CommonJS compilado (para futuro `npm publish`).
- `dist/tokens.css` → CSS variables generadas por `tokensToCss(designTokens)`.
- `dist/*.d.ts` → declaraciones de tipos.

Los consumidores **dentro del workspace** importan directamente desde `src/` vía
`main: "src/index.ts"` (Next.js los transpila). No necesitan ejecutar `build` previo.

## Publicación (npm privado, scope `@zentto/*`)

Este paquete se publica a npm como **privado restricted** (scope privado pago `@zentto`).
El workflow `.github/workflows/publish-design-tokens.yml` corre automáticamente en push a
`main` cuando cambia `web/modular-frontend/packages/design-tokens/**`:

1. `npm install --ignore-scripts` (sin ejecutar `prepare` aún).
2. `npm run typecheck` + `npm run build` (genera `dist/`).
3. Compara `package.json` version vs `npm view @zentto/design-tokens version`.
4. Si son distintas: `npm publish --access restricted`.

> ⚠️ **Nunca publicar público.** Scope `@zentto/*` es privado — siempre usar
> `publishConfig.access: "restricted"`. Ver memoria `feedback_npm_private_only.md`.

Para bumpear versión: editar `version` en `package.json`, commit, PR a `developer`, merge a
`main`, y el workflow publica automáticamente.

## Roadmap

- CRM-115 (este paquete, merged a `developer`).
- Dashboard notify consume `@zentto/design-tokens/css` en `globals.css` (issue separado).
- v0.1.0 publicado a npm privado (issue #437).

## Referencias

- [ADR-NOTIFY-001 — shared-ui paradox](../../../../../zentto-notify/docs/adr/ADR-NOTIFY-001-shared-ui-paradox.md)
- [Tailwind v4 `@theme` spec](https://tailwindcss.com/docs/v4-beta#theme-configuration)
- [MUI ThemeProvider](https://mui.com/material-ui/customization/theming/)
- [W3C Design Tokens](https://www.w3.org/community/design-tokens/)
