# Zentto Design System

> Documento base del design system de Zentto. Formato **Google Stitch / design.md**
> (ver https://stitch.withgoogle.com/docs/design-md/overview/ y
> https://github.com/VoltAgent/awesome-design-md).
> Fuente de verdad para tokens, componentes y patrones compartidos entre todos
> los módulos (`@zentto/*`) y apps standalone (hotel, medical, tickets, education,
> inmobiliario, rental, pos, restaurant, ecommerce).

---

## 1. Identidad

**Zentto** es un ERP SaaS B2B multi-módulo (contabilidad, ventas, inventario,
CRM, POS, hotel, educación, medical, tickets, rental, flota, manufactura,
nómina, ecommerce, report studio) con una sola piel, una sola librería de
componentes y una sola gramática visual.

- **Audiencia**: operadores comerciales, contadores, administradores de PYMES,
  soporte interno. Gente que vive dentro del producto 8 horas al día.
- **Tono**: data-first, preciso, amable. Nada de lenguaje de marketing dentro
  de la app; las ilustraciones son accentos, no protagonistas.
- **Referentes explícitos**: Linear · HubSpot · Pipedrive · Attio · Polaris
  (Shopify) · Carbon (IBM) · Atlassian Design System · Primer (GitHub).

---

## 2. Principios

1. **Data-first, chrome-second**. Cada pantalla maximiza el espacio para datos.
   Header `<= 56 px`, filtros colapsables, panel lateral oculto por defecto.
2. **Keyboard-first no opcional**. `Cmd/Ctrl-K` abre command palette; `C` crea;
   `J/K` navega filas; `Esc` cierra drawer; `?` muestra atajos.
3. **Densidad escalable**. El mismo grid sirve al comercial en mobile y al
   admin en 4K. Tres modos: *compact*, *default*, *comfortable* persistidos
   por usuario.
4. **Drawer vs navegar**. Abrir un registro nunca saca al usuario de su
   contexto. `RightDetailDrawer` con deep-link `?id=...` preserva la vista.
5. **Filtros y vistas como ciudadanos de primera clase**. `ZenttoFilterPanel`
   + saved views por usuario + estado reflejado en URL para compartir.
6. **Empty states accionables**. Nunca un "No hay datos" pelado — siempre
   ilustración ligera + por qué + CTA primario + link secundario.
7. **Un solo widget de tabla**. Todas las listas usan `<zentto-grid>` /
   `ZenttoRecordTable`. Prohibido `<table>` HTML o MUI `<DataGrid>`.
8. **Accesibilidad AA mínimo**. Contraste, focus visible, ARIA roles, navegación
   por teclado, no depender del color para comunicar estado.

---

## 3. Tokens

Exportados desde `@zentto/shared-ui` como `token` (ver `src/theme.ts`). Son
**semánticos**, no dependen de valores de marca — permiten white-label.

### 3.1 Spacing / layout

```ts
token.layout = {
  sectionGap: 24,  // separación entre secciones mayores de una vista
  formGap:    16,  // separación entre campos en un formulario
  chipGap:     6,  // separación entre chips / badges
};
```

Base MUI `theme.spacing(1) = 8px`. Los tokens son múltiplos de 8 salvo
`chipGap` (6 px, patrón Polaris para tags cortos).

### 3.2 Densidad

```ts
token.density.rowHeight = { compact: 28, default: 36, comfortable: 46 };
```

Aplicado al `<zentto-grid>` via attribute `row-height` o al toolbar
`DensityToggle`. Persistido por usuario con `useGridLayoutSync`.

### 3.3 Tipografía (roles semánticos)

```ts
token.typography.roles = {
  display:  { variant: 'h4',      size: '1.75rem',  weight: 700 }, // 28 / 32 700
  headline: { variant: 'h5',      size: '1.25rem',  weight: 700 }, // 20 / 24 700
  title:    { variant: 'h6',      size: '1rem',     weight: 600 }, // 16 / 22 600
  body:     { variant: 'body1',   size: '0.875rem', weight: 400 }, // 14 / 20 400
  label:    { variant: 'caption', size: '0.75rem',  weight: 600 }, // 12 / 16 600
};
```

**Regla crítica**: ningún `fontSize` literal (`sx={{ fontSize: '0.85rem' }}`)
fuera del tema en código nuevo. Si falta una variante, agregarla aquí primero.

Fuente: **Inter** + fallbacks del sistema. Configurada en `theme.typography.fontFamily`.

### 3.4 Color — roles

- **Marca** en `brandColors` (ver `src/theme.ts`). No usar hex hardcoded.
- **Paleta MUI** (`primary/secondary/error/warning/info/success`) para estados
  y acciones genéricas.
- **Roles semánticos por entidad** (nuevo en v2):
  ```ts
  token.color.lead = {
    open: { paletteKey: 'primary' },  // MUI theme.palette.primary.main
    won:  { paletteKey: 'success' },
    lost: { paletteKey: 'error' },
  };
  token.color.priority = {
    urgent: { paletteKey: 'error'   },
    high:   { paletteKey: 'error'   },
    medium: { paletteKey: 'warning' },
    low:    { paletteKey: 'info'    },
  };
  ```
  Resolver en runtime con `theme.palette[paletteKey].main` para respetar
  dark mode y branding por tenant.

### 3.5 Radio y sombras

- `borderRadius: 12` en cards, buttons, paper, dialogs (ya configurado).
- Sombra estándar card: `0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)`.
- Drawer y dialog sin sombra adicional (el backdrop ya separa).

---

## 4. Componentes base

### 4.1 Layout

- **`OdooLayout`** — chrome completo (sidebar + appbar + main). Todas las apps
  lo usan. Soporta `rightPanel` (coming soon) para `RightDetailDrawer`.
- **`ContextActionHeader`** — header de página (title + subtitle + acciones
  + search). Usar `primaryAction`, `secondaryActions`, `onSearch` cuando
  estén disponibles.
- **`SettingsLayout`** / `SettingsSection` / `SettingsItem` — páginas de
  configuración con 2 columnas (menú + contenido).

### 4.2 Listas y CRUDs

- **`<zentto-grid>`** (web component) — standard universal para listar datos.
  Soporta filtros por columna, quick search, export CSV/Excel/JSON,
  agrupación, totales, pivot, persistencia de layout.
- **`ZenttoRecordTable`** (coming soon) — wrapper React sobre `<zentto-grid>`
  que añade: toolbar con density toggle, BulkActionBar sticky, SavedViews
  dropdown, empty/loading/error states consistentes.
- **`ZenttoFilterPanel`** — panel de filtros reutilizable. Chips de filtros
  activos. Clic en chip lo elimina (patrón Polaris).

### 4.3 Dialogs y formularios

- **`FormDialog`** — dialog genérico para crear/editar (cancel + save en
  footer, loading state, keyboard `Cmd-Enter` save / `Esc` cancel).
- **`ConfirmDialog`** — confirmar acción genérica.
- **`DeleteDialog`** — variante con tono destructivo (error color).
- **`FormGrid` / `FormField`** — grilla 12-col para layouts de form consistentes.

### 4.4 Detalle (coming soon)

- **`RightDetailDrawer`** — panel lateral 480 px desktop / fullscreen mobile.
  Tabs Overview/Activity/Notes/Files/Related. `Esc` cierra. Deep-link `?id=`.

### 4.5 Navegación (coming soon)

- **`CommandPalette`** — `Cmd/Ctrl-K` global. Fuzzy search sobre registros
  recientes + acciones + navegación. Basado en `cmdk` (Shadcn) envuelto en MUI.

### 4.6 Dashboard

- **`DashboardShortcutCard`** — card de atajo (icon + title + subtitle +
  onClick).
- **`DashboardKpiCard`** — KPI tile (valor + delta + sparkline opcional).
- **`DashboardSection`** — sección de dashboard con título y colapsable.
  Usar en dashboards grandes (regla: si >4 cards, envolver en acordeones).

### 4.7 Otros

- **`PerfilDrawer`, `SidebarFooterAccount`, `ToolbarAccountOverride`** —
  integración con auth.
- **`LocalizacionModal`, `CountrySelect`, `PhoneInput`, `LocaleSelectorButton`**
  — i18n y locale.
- **`PaymentSettingsPanel`, `ProviderConfigCard`, `AcceptedMethodsManager`**
  — gateways de pago.
- **`HelpButton`** — ayuda contextual por ruta.

---

## 5. Patrones

### 5.1 Listado → detalle

1. Página lista con `ZenttoRecordTable` + `ZenttoFilterPanel` arriba.
2. Click en fila → abre `RightDetailDrawer` (no navega fuera).
3. URL refleja `?<entity>=<id>` para deep-link.
4. `Esc` cierra; lista mantiene selección y scroll.

### 5.2 Crear/editar

1. Botón primario en `ContextActionHeader` → abre `FormDialog`.
2. `FormDialog` usa `FormGrid` para layout.
3. `Cmd-Enter` guarda, `Esc` cierra, toast de éxito/error.

### 5.3 Bulk actions

1. Selección múltiple en `ZenttoRecordTable`.
2. `BulkActionBar` sticky bottom aparece cuando N>0.
3. Acciones contextuales al tipo de registro.

### 5.4 Dashboards grandes

1. Agrupar secciones por subdominio (`OPERACIONES`, `FINANCIERO`, …).
2. Cada grupo en `Accordion` con primera abierta, estado persistido por usuario.
3. Máx 4 KPI cards visibles sin scroll; el resto colapsado.

### 5.5 Empty state

```
[ilustración ligera]
[H3] Aún no hay {entidad}
[body] Breve copy de valor ("Los leads que crees aparecerán aquí…")
[primary] Crear {entidad}
[link] Importar desde CSV
```

---

## 6. Anti-patrones

- **Nunca** `<table>` HTML nativo. Usar `<zentto-grid>` / `ZenttoRecordTable`.
- **Nunca** MUI `<DataGrid>` en apps nuevas (hotel/medical/tickets/education/
  inmobiliario/rental). Solo el ERP principal mantuvo legacy durante la migración.
- **Nunca** `fontSize` literal nuevo fuera del tema. Si falta un rol, agregarlo.
- **Nunca** colores hardcoded fuera de `brandColors` / `theme.palette`.
- **Nunca** datos mock en features reales (regla `feedback_no_mock_data`).
- **Nunca** duplicar módulos del ERP en apps nuevas (regla
  `feedback_no_duplicate_erp_modules`). Heredar de `shared-ui`.
- **Nunca** navegar fuera de la lista para ver detalle — siempre drawer.
- **Nunca** `<Dialog>` MUI crudo para crear/editar — usar `FormDialog`.

---

## 7. Densidad y breakpoints

| Breakpoint | Min width | Sidebar    | Drawer        | Density default |
|------------|-----------|------------|---------------|-----------------|
| xs         | 0         | off-canvas | full-screen   | compact         |
| sm         | 600       | mini       | overlay       | default         |
| md         | 600+      | mini       | overlay       | default         |
| lg         | 1200      | full       | 480 px lateral | default         |
| xl         | 1536      | full       | 480 px lateral | comfortable     |

Nota: `sm === md === 600` porque la escala original del ERP no distingue
tablet vs mobile pequeño en layout; se diferencia por densidad.

---

## 8. Accesibilidad

- Focus ring visible: `:focus-visible` outline 2 px `primary.main`.
- ARIA roles correctos: `role="grid"` en tablas, `role="listbox"` en menus,
  `role="combobox"` en command palette, `role="dialog"` + `aria-modal` en drawer.
- Contraste AA mínimo en texto y controles; AAA para texto de cuerpo largo.
- Navegación por teclado sin excepciones en componentes interactivos.
- Anuncios `aria-live="polite"` para cambios de estado (drop en Kanban,
  bulk action completada, saved view aplicada).

---

## 9. Versionado y consumo

- Paquete: `@zentto/shared-ui` (privado, npm Teams).
- **Nunca** referenciar versiones públicas antiguas (regla
  `feedback_npm_private_only`).
- Tras `npm publish`, esperar 5 min antes de consumir en apps hermanas
  (regla `feedback_npm_publish_5min_wait`). Workspace `"*"` es instantáneo.
- Bumps:
  - **patch** — fix sin cambios de API.
  - **minor** — componentes/tokens nuevos, compatible.
  - **major** — breaking changes (renombrar props, remover componentes).

---

## 10. Roadmap vivo

Siguientes piezas pendientes (ver `docs/wiki/design-audits/`):

- `ZenttoRecordTable` con SavedViews + BulkActionBar + DensityToggle.
- `RightDetailDrawer` + prop `rightPanel` en `OdooLayout`.
- `CommandPalette` global.
- `EmptyState` estándar con ilustración ligera.
- Audit accesibilidad AA post-rediseño CRM.
- Docs en `zentto-erp-docs` con patrones de cada módulo.

---

## 11. Referencias

- **Polaris** (Shopify) — https://polaris.shopify.com/
- **Carbon** (IBM) — https://carbondesignsystem.com/
- **Atlassian DS** — https://atlassian.design/
- **Primer** (GitHub) — https://primer.style/
- **Material 3** — https://m3.material.io/
- **Base Web** (Uber) — https://baseweb.design/
- **Linear** — https://linear.app/method
- **HubSpot Smart CRM** — https://designers.hubspot.com/
- **Pipedrive** — https://www.pipedrive.com/
- **Attio** — https://attio.com/
