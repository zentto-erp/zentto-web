# Plan Maestro: @zentto/datagrid — Web Component Nativo

## Vision

Publicar `@zentto/datagrid` como paquete npm **open-source (MIT)** que funcione en
**cualquier framework** (React, Vue, Angular, Svelte, vanilla JS) sin dependencias
pesadas. Es la version publica y portable del ZenttoDataGrid interno.

---

## Arquitectura

```
zentto-datagrid/               ← nuevo repositorio
├── packages/
│   ├── core/                  ← logica pura (0 dependencias UI)
│   │   ├── src/
│   │   │   ├── data/          ← sort, filter, group, pivot, aggregate, paginate
│   │   │   ├── export/        ← CSV, Excel, JSON, Markdown
│   │   │   ├── selection/     ← cell range, row selection, clipboard
│   │   │   ├── layout/        ← column sizing, pinning, reorder, persistence
│   │   │   ├── search/        ← find (Ctrl+F) matching logic
│   │   │   └── types.ts       ← interfaces publicas
│   │   └── package.json       → @zentto/datagrid-core
│   │
│   ├── web-component/         ← Custom Element + Lit
│   │   ├── src/
│   │   │   ├── zentto-grid.ts          ← <zentto-grid> Custom Element
│   │   │   ├── renderers/              ← cell renderers (status, avatar, etc.)
│   │   │   ├── panels/                 ← pivot sidebar, find bar, context menu
│   │   │   ├── styles/                 ← CSS-in-JS con Shadow DOM
│   │   │   └── themes/                 ← light, dark, custom
│   │   └── package.json       → @zentto/datagrid
│   │
│   ├── react/                 ← wrapper React (auto-generado + hooks)
│   │   ├── src/
│   │   │   ├── ZenttoDataGrid.tsx      ← wrapper del Custom Element
│   │   │   └── hooks.ts               ← useZenttoGrid, useGridApi
│   │   └── package.json       → @zentto/datagrid-react
│   │
│   ├── vue/                   ← wrapper Vue (auto-generado)
│   │   └── package.json       → @zentto/datagrid-vue
│   │
│   └── angular/               ← wrapper Angular (auto-generado)
│       └── package.json       → @zentto/datagrid-angular
│
├── apps/
│   ├── docs/                  ← sitio de documentacion (Astro/Starlight)
│   │   └── src/content/       ← MDX con demos interactivos
│   └── playground/            ← sandbox online (como el lab actual)
│
├── scripts/
│   ├── generate-wrappers.ts   ← genera React/Vue/Angular desde web-component
│   └── build-all.ts
│
├── turbo.json                 ← Turborepo monorepo
├── package.json
└── LICENSE                    ← MIT
```

---

## Tecnologia: Lit (Google)

**Por que Lit y no Stencil:**

| Criterio | Lit | Stencil |
|---|---|---|
| Tamaño | ~5KB | ~14KB |
| Estándar web | 100% Custom Elements | Genera Custom Elements |
| Control | Total | Abstraído |
| Comunidad | Google, Chrome team | Ionic |
| TypeScript | Nativo | Nativo |
| SSR | Lit SSR oficial | Parcial |
| Mantenimiento | Activo (Google) | Activo (Ionic) |

Lit nos da maximo control y minimo peso. Los wrappers React/Vue/Angular se generan
con `@lit/react`, `@lit/vue-wrapper` (o manualmente — son 20 lineas).

---

## Features a portar (prioridad)

### Fase 1 — MVP (semanas 1-4)

Core funcional con las features mas usadas:

| # | Feature | Origen |
|---|---|---|
| 1 | Rendering columnas (sort, resize, reorder) | Core |
| 2 | Paginacion (client + server) | Core |
| 3 | Column templates (status, currency, avatar, flag) | Templates |
| 4 | Export CSV/JSON | Core |
| 5 | Responsive (mobile hide, detail drawer) | CSS + JS |
| 6 | Header filters (text, number, date, select) | Core |
| 7 | Totals row (sum, avg, count, min, max) | Core |
| 8 | Clipboard copy | Core |
| 9 | Dark/Light theme | CSS custom properties |
| 10 | Localizacion ES/EN | Core |

### Fase 2 — Pro Features (semanas 5-8)

Features avanzadas que compiten con MUI Pro/AG Grid:

| # | Feature | Origen |
|---|---|---|
| 11 | Row grouping + subtotals | Core |
| 12 | Pivot table interactivo | Core + Panel |
| 13 | Master-detail (expandable rows) | Rendering |
| 14 | Column pinning (sticky left/right) | CSS |
| 15 | Context menu (clic derecho) | Panel |
| 16 | Find (Ctrl+F) | Core + Panel |
| 17 | Status bar | Panel |
| 18 | Excel export | Core |
| 19 | Layout persistence (IndexedDB) | Core |
| 20 | Column groups (multi-level headers) | Rendering |

### Fase 3 — Enterprise Features (semanas 9-12)

Features que nadie mas da gratis:

| # | Feature | Origen |
|---|---|---|
| 21 | Cell range selection (Excel-like) | Selection |
| 22 | Clipboard paste | Selection |
| 23 | Tree data | Core |
| 24 | Row reordering (drag) | Interaction |
| 25 | Sparklines (mini charts) | Rendering |
| 26 | Inline cell editing | Interaction |
| 27 | Undo/redo | Core |
| 28 | Row pinning (top/bottom) | Rendering |
| 29 | Markdown export | Core |
| 30 | Sidebar configurable (AG Grid style) | Panel |

---

## API Publica

### Vanilla JS / CDN

```html
<script type="module">
  import 'https://unpkg.com/@zentto/datagrid';
</script>

<zentto-grid
  columns='[{"field":"name","header":"Nombre"},{"field":"price","header":"Precio","type":"number","currency":"USD"}]'
  rows='[{"name":"Widget","price":9.99}]'
  enable-clipboard
  enable-find
  show-totals
  theme="light"
  locale="es"
></zentto-grid>
```

### React

```tsx
import { ZenttoDataGrid } from '@zentto/datagrid-react';

<ZenttoDataGrid
  columns={[
    { field: 'name', header: 'Nombre' },
    { field: 'price', header: 'Precio', type: 'number', currency: 'USD', aggregation: 'sum' },
    { field: 'status', header: 'Estado', statusColors: { Active: 'success', Inactive: 'error' } },
  ]}
  rows={data}
  enableClipboard
  enableFind
  enableContextMenu
  showTotals
  enableGrouping
  groupField="category"
/>
```

### Vue

```vue
<template>
  <zentto-grid
    :columns="columns"
    :rows="data"
    enable-clipboard
    enable-find
    show-totals
    @row-click="handleRowClick"
  />
</template>

<script setup>
import '@zentto/datagrid-vue';
</script>
```

---

## Rendering Engine

**No usar MUI DataGrid internamente.** El web component renderiza su propia tabla
HTML con CSS custom properties para theming.

### Virtualizacion

Para grids con miles de filas, implementar virtualizacion propia:
- Solo renderizar filas visibles en el viewport
- Buffer de 5-10 filas arriba/abajo
- Reciclar DOM nodes en scroll
- Opciones: IntersectionObserver o calculo manual de scroll position

### Performance targets

| Metrica | Target |
|---|---|
| Bundle size | < 50KB gzip |
| First render (100 filas) | < 50ms |
| Scroll (10K filas virtualizadas) | 60fps |
| Sort (10K filas) | < 100ms |
| Filter (10K filas) | < 50ms |

---

## Theming

CSS custom properties para maximo control sin depender de framework CSS:

```css
zentto-grid {
  --zg-font-family: Inter, system-ui, sans-serif;
  --zg-font-size: 0.875rem;
  --zg-header-bg: #f8f9fa;
  --zg-header-color: #333;
  --zg-header-font-weight: 600;
  --zg-row-bg: #fff;
  --zg-row-alt-bg: #fafafa;
  --zg-row-hover-bg: #f0f7ff;
  --zg-border-color: #e0e0e0;
  --zg-primary: #f59e0b;
  --zg-success: #067D62;
  --zg-error: #cc0c39;
  --zg-warning: #ff9800;
  --zg-info: #0288d1;
  --zg-totals-bg: #f5f5f5;
  --zg-totals-font-weight: 700;
  --zg-selection-bg: rgba(25, 118, 210, 0.08);
  --zg-find-match-bg: rgba(255, 213, 79, 0.3);
  --zg-find-current-bg: rgba(255, 152, 0, 0.5);
}
```

Temas predefinidos: `light` (default), `dark`, `zentto` (brand).

---

## Testing

| Tipo | Tool | Cobertura |
|---|---|---|
| Unit (core logic) | Vitest | sort, filter, group, pivot, aggregate |
| Component (web component) | Web Test Runner + @open-wc/testing | render, events, props |
| Visual regression | Playwright | screenshots de cada feature |
| E2E (playground) | Playwright | interacciones completas |
| Benchmarks | Vitest bench | performance targets |

---

## CI/CD

```yaml
# GitHub Actions
on push main:
  1. Lint + Type check
  2. Unit tests
  3. Build all packages
  4. Visual regression tests
  5. Publish to npm (semantic-release)
  6. Deploy docs to datagrid.zentto.net
```

---

## Documentacion (datagrid.zentto.net)

Sitio Astro/Starlight con:

1. **Getting Started** — instalacion, CDN, frameworks
2. **Columns** — tipos, templates, currency, status, avatar, flag, progress, rating, link
3. **Features** — una pagina por feature con demo interactivo
4. **API Reference** — todas las props con tipos
5. **Playground** — sandbox en vivo (como el lab actual)
6. **Migration Guide** — de MUI DataGrid / AG Grid a @zentto/datagrid
7. **Changelog**

---

## Publicacion npm

```
@zentto/datagrid-core    → logica pura, 0 deps
@zentto/datagrid         → web component (Lit), depende de core
@zentto/datagrid-react   → wrapper React, depende de web component
@zentto/datagrid-vue     → wrapper Vue
@zentto/datagrid-angular → wrapper Angular
```

### Versionado

Semantic versioning. Monorepo con changesets o semantic-release.

### Licencia

**MIT** — 100% gratis, sin restricciones.

---

## Relacion con el proyecto actual (DatqBoxWeb)

| Aspecto | Proyecto actual | Paquete npm |
|---|---|---|
| Framework | React + MUI DataGrid | Lit (Custom Elements) |
| Dependencias | MUI, emotion, lodash | 0 deps externas |
| Donde vive | `packages/shared-ui/` | Repo separado `zentto-datagrid` |
| Quien lo usa | Solo Zentto ERP | Cualquier desarrollador |
| Mantenimiento | Interno | Open source + community |

### Plan de migracion (futuro)

1. Publicar `@zentto/datagrid-react` con API compatible
2. En DatqBoxWeb, reemplazar `@zentto/shared-ui` ZenttoDataGrid por `@zentto/datagrid-react`
3. Eliminar dependencia de MUI DataGrid (ahorro ~200KB bundle)
4. Las 90+ features se mantienen identicas

---

## Timeline estimado

| Semana | Entregable |
|---|---|
| 1-2 | Repo + core (sort, filter, paginate) + web component basico |
| 3-4 | Column templates + export + header filters + clipboard |
| 5-6 | Row grouping + pivot + master-detail |
| 7-8 | Context menu + find + status bar + pinning |
| 9-10 | Cell selection + paste + tree data + editing |
| 11-12 | Wrappers React/Vue/Angular + docs site |
| 13 | Beta launch npm + playground publico |
| 14 | v1.0.0 release |

---

## Diferenciadores vs competencia

| Nosotros (GRATIS) | MUI Pro ($180/dev) | AG Grid ($999/dev) |
|---|---|---|
| 90+ features | ~40 features | ~60 features |
| 0 dependencias | MUI + emotion | AG Grid core |
| Web component nativo | Solo React | Multi-framework |
| < 50KB gzip | ~200KB+ | ~300KB+ |
| MIT license | Comercial | Comercial |
| Pivot + grouping gratis | Premium ($600) | Enterprise ($999) |
| Column templates (7 tipos) | No tiene | No tiene |
| Mobile detail drawer | No tiene | No tiene |

**Mensaje: "Todo lo que MUI Pro y AG Grid Enterprise cobran, nosotros lo damos gratis."**
