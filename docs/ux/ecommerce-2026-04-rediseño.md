# Rediseño UX/UI — Zentto Store (abril 2026)

> Documento maestro consumido por 4 agentes implementadores en paralelo (una ola por agente).
> Cualquier cambio en shared-ui o contratos API que detectes fuera de alcance: NO improvises — abre issue y marca en el checklist "Pendiente shared-ui/API".

- **Producto**: Zentto Store (tier ecommerce del ERP Zentto — `appdev.zentto.net/ecommerce`).
- **Stack**: Next.js 14 (App Router) + MUI v5 + `@zentto/shared-ui` + `@zentto/module-ecommerce` + `@zentto/datagrid`.
- **Competencia de referencia**: Shopify admin, Amazon (frontend), Stripe Dashboard, Linear (keyboard-first), Polaris (datagrids), HubSpot (CMS).
- **Look actual a preservar**: header dark `#131921` / `#232f3e`, acento naranja `#ff9900`, cuerpo `#eaeded`, botón CTA amarillo `#ffd814` (estilo Amazon).
- **Idioma UI**: español. Identificadores código: inglés.

---

## 0. Principios rectores del rediseño

1. **Front-store cercano a Amazon** (familiaridad del usuario LATAM) — no reinventar el header.
2. **Admin cercano a Shopify + Polaris + Linear** — clean, denso, keyboard-first, acordeones por sección.
3. **Toda tabla es `ZenttoDataGrid`** — cero `<table>` HTML, cero MUI `DataGrid`, cero MUI `Table*`.
4. **Dashboards grandes → acordeones colapsables** con persistencia en `localStorage` (`zentto_acc_<section>_open`).
5. **Sin datos mock** — catálogos vía hooks (`useCountries`, `useStates`, `useLookup`, hooks de `@zentto/module-ecommerce`).
6. **Mobile-first** — toda pantalla debe funcionar en 360 px.
7. **WCAG AA** — contraste ≥ 4.5:1 para texto, `focus-visible` ring naranja de 2 px, orden de tab lógico.
8. **Formato monetario** siempre vía `formatPrice(value, currency)` de `module-ecommerce/utils/formatCurrency` (no `toFixed(2) + "$"` suelto).

---

## 1. Design tokens (autoritativo — usa estos valores)

Base: MUI theme (`BrandedThemeProvider` de `@zentto/shared-ui`). Los tokens del storefront complementan el theme sin romperlo.

### 1.1 Colores

| Token | Hex | Uso |
|---|---|---|
| `store.header.bg` | `#131921` | AppBar principal storefront + admin |
| `store.header.bgSecondary` | `#232f3e` | Banner top, nav de categorías, drawer mobile |
| `store.header.bgHoverDark` | `#37475a` | Hover sobre `#232f3e`, footer "Volver arriba" hover |
| `store.header.text` | `#ffffff` | Texto sobre header |
| `store.header.textMuted` | `#cccccc` | Subtítulos ("Hola, Identifícate") |
| `store.accent.primary` | `#ff9900` | Logo, badges, ring focus buscador, chips destacados |
| `store.accent.primaryHover` | `#e88a00` | Hover del naranja |
| `store.accent.secondary` | `#febd69` | Botón buscar (fondo) |
| `store.accent.secondaryHover` | `#f3a847` | Hover botón buscar |
| `store.cta.buy` | `#ffd814` | CTA comprar / checkout (amarillo Amazon) |
| `store.cta.buyHover` | `#f7ca00` | Hover CTA comprar |
| `store.cta.buyBorder` | `#fcd200` | Borde 1 px CTA comprar |
| `store.cta.addToCart` | `#ffa41c` | CTA añadir al carrito (naranja) |
| `store.cta.addToCartHover` | `#fa8900` | Hover añadir al carrito |
| `store.price` | `#b12704` | Precio en rojo Amazon (totales en carrito/drawer) |
| `store.pricePromo` | `#cc0c39` | Badge de oferta/descuento |
| `store.success` | `#067d62` | Envío gratis, compra segura, "en stock" |
| `store.successBg` | `#f0faf0` | Fondo verde claro del aviso envío gratis |
| `store.warning` | `#c45500` | "Stock bajo", "últimas unidades" |
| `store.error` | `#d13212` | Errores, validación |
| `store.body.bg` | `#eaeded` | Fondo storefront |
| `store.admin.bg` | `#f5f5f5` | Fondo contenido admin |
| `store.surface` | `#ffffff` | Cards, Papers, rows |
| `store.surfaceAlt` | `#fafafa` | Fila alternada datagrid |
| `store.border` | `#d5d9d9` | Bordes cards, inputs estado default |
| `store.borderSubtle` | `#e3e6e6` | Divisores sutiles (separadores carrito) |
| `store.borderStrong` | `#888c8c` | Hover borde input |
| `store.text.primary` | `#0f1111` | Texto principal |
| `store.text.secondary` | `#565959` | Texto secundario, captions |
| `store.text.tertiary` | `#888888` | Placeholder, iconos inactivos |
| `store.link` | `#007185` | Links "Ver detalles" (azul Amazon) |
| `store.linkHover` | `#c7511f` | Hover link (naranja cobrizo) |

Exposición recomendada (shared-ui, futuro): `theme.palette.store.header.bg` etc. Por ahora, declarar en cada archivo como constante `STORE_COLORS` o copiar inline (match con `StoreLayout.tsx`).

### 1.2 Tipografía

Mantener tipografía del theme MUI (system-ui, Roboto). Escalas:

| Token | Font-size | Line-height | Font-weight | Uso |
|---|---|---|---|---|
| `store.type.hero` | 40 / 48 px (xs/md) | 1.15 | 700 | H1 landings (/afiliados, /vende, /acerca) |
| `store.type.h2Section` | 28 / 32 px | 1.2 | 700 | H2 secciones landing |
| `store.type.h3Card` | 20 px | 1.3 | 600 | Títulos cards y popovers |
| `store.type.bodyLg` | 16 px | 1.6 | 400 | Párrafos landing |
| `store.type.body` | 14 px | 1.5 | 400 | Texto general storefront / admin |
| `store.type.bodySm` | 13 px | 1.45 | 400 | Metadatos, chips, botones |
| `store.type.caption` | 12 px | 1.4 | 400 | Labels header ("Hola, Identifícate") |
| `store.type.overline` | 11 px | 1.3 | 600 | Overlines, timestamps |
| `store.type.price` | 20 / 28 px | 1.1 | 700 | Precio principal producto |
| `store.type.priceCard` | 16 px | 1.2 | 700 | Precio en cards de producto |

Regla de títulos admin: `H1 página=24 px/700`, `H2 sección=18 px/600`, `label de campo=13 px/500`.

### 1.3 Spacing (escala MUI `theme.spacing(n) = n*8px`)

Usa la escala MUI. Reglas por contexto:

| Contexto | Padding/Margin |
|---|---|
| Page container | `py: { xs: 2, md: 4 }`, `px: { xs: 1, md: 2 }` |
| Card ecommerce | `p: 2` (16 px) |
| Card admin | `p: 2.5` (20 px) |
| Landing hero | `py: { xs: 6, md: 10 }` |
| Landing section | `py: { xs: 4, md: 8 }` |
| Form fields vertical gap | `spacing={2}` (16 px) en FormGrid |
| Datagrid toolbar | `px: 2, py: 1.5` |
| Popper / Drawer inner | `p: 2` |

### 1.4 Radius

| Token | Valor | Uso |
|---|---|---|
| `radius.sm` | 3 px | Botones header storefront, hovers outline |
| `radius.md` | 6 px | Inputs, buscador, popper |
| `radius.lg` | 8 px | Cards, papers admin, chips grandes |
| `radius.xl` | 12 px | Cards landing (hero, afiliados) |
| `radius.pill` | 20 px / `9999px` | Botón "Proceder al pago", chips estado |

### 1.5 Shadows

| Token | Valor CSS | Uso |
|---|---|---|
| `shadow.xs` | `0 1px 2px rgba(0,0,0,0.04)` | Cards admin reposo |
| `shadow.sm` | `0 2px 8px rgba(0,0,0,0.10)` | Cards landing, hover datagrid row |
| `shadow.md` | `0 4px 16px rgba(0,0,0,0.12)` | Popper, menu, mini-cart |
| `shadow.lg` | `0 8px 24px rgba(0,0,0,0.16)` | Drawer, modales |
| `shadow.focus` | `0 0 0 3px rgba(255,153,0,0.25)` | Focus ring naranja WCAG |
| `shadow.focusDanger` | `0 0 0 3px rgba(209,50,18,0.25)` | Focus ring error |

### 1.6 Transitions & motion

- Duración estándar: `150ms`. Entradas de listas: `200ms`. Drawer: `280ms` (MUI default).
- Curva: `cubic-bezier(0.4, 0, 0.2, 1)` (MUI `ease-out`).
- Hover: solo color/background/border, nunca `transform: scale()` (aliasing). Excepción: cards de prensa con `translateY(-4px)`.
- Debounce búsqueda: **250 ms**.
- Toast/Snackbar: **4 s**, `anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}`.
- Skeleton/loading: `animation-duration: 1.2s`.

### 1.7 Breakpoints (MUI defaults — no cambiar)

| Key | Min px | Uso |
|---|---|---|
| `xs` | 0 | Mobile |
| `sm` | 600 | Tablet vertical |
| `md` | 900 | Tablet horizontal / laptop pequeño |
| `lg` | 1200 | Desktop |
| `xl` | 1536 | Wide |

Container storefront: `maxWidth="xl"` (`1536 px`) con `px: { xs: 1, md: 2 }`.

---

## 2. Patrones transversales

### 2.1 `FormGrid` / `FormField` — defaults reales de shared-ui

**OJO**: los defaults reales de `FormField` son `xs=12, sm=6, md=4, lg=3` (ver `packages/shared-ui/src/components/FormGrid.tsx`). En formularios de 1 columna debes override explícitamente:

```tsx
<FormGrid spacing={2}>
  <FormField xs={12} sm={12} md={12} lg={12}>
    <TextField label="Nombre completo" fullWidth />
  </FormField>
</FormGrid>
```

Reglas:
- `<TextField fullWidth />` siempre. Sin `fullWidth` → bug visual.
- Validación inline: `error={!!errors.email}` + `helperText={errors.email || 'Usaremos este email para notificaciones'}`.
- Para 2 columnas simétricas en desktop: `<FormField xs={12} sm={12} md={6} lg={6}>`.
- Para 3 columnas admin (ej. precio/stock/SKU): `<FormField xs={12} sm={6} md={4} lg={4}>`.
- Espaciado vertical `spacing={2}` (16 px). Nunca `spacing={3}` en mobile (desperdicia viewport).

### 2.2 `ZenttoDataGrid` — patrón único para tablas

Signatura (resumida, validar contra `packages/shared-ui/src/index.tsx`):

```tsx
<ZenttoDataGrid
  rows={rows}
  columns={columns}
  loading={isLoading}
  rowKey="id"
  pageSize={25}
  pageSizeOptions={[10, 25, 50, 100]}
  stickyHeader
  emptyState={<EmptyStateComponent />}
  toolbar={<DataGridToolbar />}
/>
```

**Toolbar obligatoria** (por encima del grid, inside el mismo Paper):

```
┌─────────────────────────────────────────────────────────────────────┐
│ [Buscar ___________ 🔍]  [Filtros (2) ▼]  │  [Export] [+ Nuevo]      │
└─────────────────────────────────────────────────────────────────────┘
```

- Buscar: 280 px, debounce 250 ms, emite `onSearchChange`.
- Filtros: `ZenttoFilterPanel` en popover, badge numérico cuando hay filtros activos.
- Acciones primarias (derecha): botón primario naranja `+ Nuevo` (admin) o export.
- Acciones secundarias (bulk): aparecen solo cuando `selectedRows.length > 0`, reemplazando la toolbar ("3 seleccionados · Exportar · Eliminar · Cambiar estado").

**Columna de status**: `<Chip>` con variantes:

| Estado | Bg | Text | Ejemplo |
|---|---|---|---|
| `active` / `approved` / `paid` | `#e7f6ec` | `#067d62` | "Activo" |
| `pending` / `draft` | `#fff4e5` | `#c45500` | "Pendiente" |
| `rejected` / `cancelled` / `error` | `#fdecea` | `#d13212` | "Rechazado" |
| `archived` / `inactive` | `#eceff1` | `#565959` | "Archivado" |

**Columna de acciones de fila**: al final (última columna), `align: 'right'`, `sortable: false`, `width: 120`. Contiene `<IconButton>` con menú kebab (3 puntos) — no exponer múltiples iconos sueltos que rompen alineación.

**Paginación**: bottom, `25` default, opciones `[10, 25, 50, 100]`.

**Sticky header**: siempre `true`.

**Empty state** (cuando `rows.length === 0 && !loading`):
```
┌─────────────────────────────────────┐
│           [icono grande]             │
│                                      │
│       Título (ej. "Sin productos")   │
│   Subtítulo con ayuda accionable     │
│                                      │
│        [+ Crear primero]             │
└─────────────────────────────────────┘
```
Min-height 280 px, icono 56 px `color: store.text.tertiary`, H3, párrafo secundario, CTA primario.

**Loading**: skeletons de 5 filas con altura real de fila (48 px admin, 56 px storefront) — no `<CircularProgress>` al centro.

### 2.3 Accesibilidad global

- Todo `<IconButton>` sin texto visible debe llevar `aria-label`. Ej: `<IconButton aria-label="Quitar del carrito">`.
- Todo `<input>` de búsqueda debe tener `aria-label` o `<label>` oculto (`visually-hidden`).
- Focus ring visible SIEMPRE:
  ```css
  &:focus-visible {
    outline: 2px solid #ff9900;
    outline-offset: 2px;
    box-shadow: 0 0 0 3px rgba(255,153,0,0.25);
  }
  ```
- Navegación por teclado obligatoria en: buscador (Esc cierra sugerencias, ↑↓ navega, Enter selecciona), mini-cart popper (Esc cierra), sidebar admin (Tab atraviesa).
- Anuncios con `role="status"` / `aria-live="polite"` para toasts y "Añadido al carrito".
- Contraste: todo texto sobre naranja `#ff9900` debe ser `#0f1111` (no blanco — ratio < 3:1).

### 2.4 Microcopy (español, tono cercano pero profesional)

- Confirmación destructiva: "¿Seguro que quieres eliminar este producto? Esta acción no se puede deshacer."
- Empty de productos admin: "Aún no tienes productos. Crea el primero para empezar a vender."
- Empty de carrito: "Tu carrito está vacío" + subtítulo "Agrega productos para comenzar tu compra".
- Error de red genérico: "No pudimos conectar con el servidor. Reintenta en unos segundos."
- Toast éxito: "Guardado" / "Producto creado" / "Pedido actualizado". 4 s. Bottom-right.

---

## OLA 1 — UX fixes header + registro + carrito + afiliados

**Alcance**: `StoreLayout.tsx`, `CurrencySelector.tsx`, `CartDrawer.tsx`, `registro/page.tsx`, `afiliados/page.tsx` (solo tabla).

### 1A. `CurrencySelector` → Autocomplete con búsqueda

**Problema actual**: dos `<Select>` con `minWidth: 110` que en mobile desaparecen y en desktop no son buscables. Con 14+ países latam la UX es torpe.

**Propuesta**:
- Reemplazar los dos `<Select>` por **un** `<Autocomplete>` unificado país+moneda.
- Opciones formato: `{ code: 'VE', flag: '🇻🇪', country: 'Venezuela', currency: 'VES', symbol: 'Bs.' }`.
- Render: `🇻🇪 VE · Bs. VES`.
- `groupBy` por continente (Latinoamérica, Norteamérica, Europa).
- `renderInput`: `<TextField size="small" placeholder="País / Moneda" />`, min-width 180 px desktop, full-width drawer mobile.
- Filtrado default MUI por `country + code + currency` concatenado.
- Al seleccionar: dispara `onCountryChange` existente (mantiene lógica fetch `/store/storefront/country/:code`).
- Persistencia: `useCartStore` (ya existe).
- **Mobile**: no cabe en header. Mover dentro del `Drawer` mobile (drawer.tsx hamburger) en una sección "Envío y moneda" al tope.

**Estados**:
- Default: bordes `store.border`, bg `#fff`, texto `#0f1111`, height `32 px` (size small).
- Focus: borde `store.accent.primary` 2 px + `shadow.focus`.
- Loading (mientras `useStorefrontCountries` carga): skeleton 180×32 px, no `<CircularProgress>`.
- Error: mostrar `<Tooltip title="No se pudo cargar la lista de países">` y permitir seguir sin bloquear.

**Criterios de aceptación**:
- [ ] Se puede buscar "Venezuela" o "VES" o "Bs." y encuentra la opción.
- [ ] Al cambiar país, el `taxRate` se actualiza en el carrito sin recargar página.
- [ ] En mobile 360 px no aparece en header (sí en drawer).
- [ ] Tiene `aria-label="Seleccionar país y moneda"`.
- [ ] Navegable por teclado (Tab enfoca, ↑↓ navega opciones, Enter selecciona, Esc cierra).

### 1B. Buscador global → sugerencias de productos

**Problema actual**: el dropdown solo muestra "Búsquedas recientes" del localStorage. Amazon/Shopify muestran productos sugeridos + categorías.

**Propuesta** — el dropdown tiene 3 secciones dinámicas:

```
┌──────────────────────────────────────────────────┐
│  Búsquedas recientes                              │
│  🕒 iphone 15                                  ✕  │
│  🕒 teclado mecánico                           ✕  │
├──────────────────────────────────────────────────┤
│  Sugerencias                                      │
│  🔍 teléfonos — en Electrónica                    │
│  🔍 televisores — en Electrónica                  │
├──────────────────────────────────────────────────┤
│  Productos (5)                                    │
│  [img] iPhone 15 128GB              $ 950.00      │
│        Electrónica · 4.7 ★ · 1.2k reseñas         │
│  [img] iPhone 15 Pro Max            $ 1,299.00    │
│  ...                                              │
│  → Ver todos los resultados para "iphone"         │
└──────────────────────────────────────────────────┘
```

**Comportamiento**:
- Debounce 250 ms al teclear. Solo dispara fetch si `query.length >= 2`.
- Hook nuevo: `useProductSuggestions(query, { limit: 5 })` en `module-ecommerce`. **Si no existe, Ola 1 lo debe crear o dejar stub con flag `Pendiente shared-ui/API`**.
- Máximo 5 productos + 3 sugerencias de categoría + 5 recientes.
- Cada resultado de producto es un link a `/productos/[code]`.
- Imagen 48×48 px, border-radius 4 px, fit cover.
- Último ítem: "→ Ver todos los resultados para '[query]'" — link a `/productos?search={query}`.
- `↑` / `↓` navegan entre items (incluyendo recientes + sugerencias + productos), `Enter` abre el activo, `Esc` cierra.
- Scroll interno si supera 420 px de alto.

**Estados**:
- Idle (sin query): solo muestra recientes (comportamiento actual).
- Loading (query activa, fetch en curso): skeleton 3 rows en sección "Productos".
- Empty (query sin resultados): "No encontramos productos para '{query}'. Revisa la ortografía o busca por otra palabra."
- Error: fallback silencioso a solo "Recientes".

**Criterios de aceptación**:
- [ ] Al teclear "ipho" aparecen productos en <500 ms percibido.
- [ ] Esc cierra dropdown sin perder texto.
- [ ] Click fuera cierra (ya implementado en `StoreLayout`).
- [ ] `aria-expanded`, `role="listbox"` y `aria-activedescendant` presentes.

### 1C. Mini-cart → `Popper` desktop / `Drawer` mobile

**Problema actual**: el `CartDrawer` abre en ambos viewports. En desktop se siente pesado para decisiones rápidas ("vi mi carrito, sigo comprando").

**Propuesta**:
- Desktop (`md+`): click en carrito abre un **`Popper`** anclado al icono, ancho **360 px**, con preview de 3 items + CTA.
- Mobile (`<md`): mantiene `CartDrawer` actual (100% width).
- Hover del icono en desktop (con delay 200 ms para evitar abrir al cruzar): preview automático. Click: abre popper sticky.
- Popper cierra al: click fuera, Esc, ratón fuera del icono+popper por 400 ms.

**Layout Popper desktop (360 × auto)**:

```
┌──────────────────────────────────────────┐
│  Carrito (5)                          ✕  │  ← header 48 px
├──────────────────────────────────────────┤
│  [img 56px] Producto A                   │
│             x2 · $ 25.00                 │
│  ─────────────────────────────────────   │
│  [img 56px] Producto B                   │
│             x1 · $ 48.00                 │
│  ─────────────────────────────────────   │
│  [img 56px] Producto C                   │
│             x1 · $ 12.00                 │
│                                          │
│  + 2 productos más                       │  ← si items.length > 3
├──────────────────────────────────────────┤
│  Subtotal                    $ 98.00     │
│  IVA (16%)                   $ 15.68     │
│  ───────────────────────────────────     │
│  Total                      $ 113.68     │  ← color #b12704, bold
├──────────────────────────────────────────┤
│  [ Proceder al pago ]  ← CTA amarillo    │  ← ffd814
│  Ver carrito completo → ← link #007185   │
└──────────────────────────────────────────┘
```

**Specs**:
- Ancho: `360 px` fijo desktop. Altura máx: `calc(100vh - 120px)` con scroll interno.
- Elevación: `shadow.lg`, `borderRadius: 8px`.
- Imagen item: `56×56 px`, `border-radius: 4px`, fondo `#f5f5f5` cuando no hay imagen.
- Cantidad: stepper `-` / número / `+` inline (h=28 px).
- Quitar: `<IconButton size="small" aria-label="Quitar">` (x) a la derecha.
- Divisor entre items: `1 px solid store.borderSubtle`.
- Estado vacío: "Tu carrito está vacío" + icono carrito 48 px + link "Ver productos" → `/productos`.
- Focus trap activo cuando popper abierto.

**Transición**: `fade-in 150ms` + `translateY(-8px → 0)`.

**Criterios de aceptación**:
- [ ] En 1440 px desktop abre popper 360 px anclado al icono.
- [ ] En 375 px mobile sigue abriendo CartDrawer de 100% width.
- [ ] Popper muestra máximo 3 items y "+ N más" cuando hay más.
- [ ] "Ver carrito completo" lleva a `/carrito`.
- [ ] "Proceder al pago" lleva a `/checkout` y cierra el popper.
- [ ] Esc cierra popper sin vaciar carrito.
- [ ] Actualizar cantidad desde popper refleja cambio inmediato (estado Zustand).

### 1D. `/registro` → layout simétrico con login

**Problema actual**: `/login` y `/registro` se ven desalineados visualmente (ancho diferente, jerarquía distinta).

**Propuesta**:
- Contenedor: `maxWidth: 480 px`, `mx: 'auto'`, `py: { xs: 4, md: 6 }`.
- Paper: `p: 4`, `borderRadius: 8 px`, `shadow.sm`.
- Layout shell idéntico a `/login` (ver `login/page.tsx` — match spacing, tipografía, ancho botón).
- Header del form:
  - Título `Crear cuenta` (24 px/700), align left (no centrado).
  - Subtítulo `Únete a Zentto Store en 30 segundos` (14 px/400, `store.text.secondary`).
  - Espacio 24 px antes del primer campo.
- Campos (en este orden):
  1. Nombre completo — `xs={12} md={12}`
  2. Email — `xs={12} md={12}`
  3. Teléfono (opcional) — `xs={12} md={12}`
  4. Contraseña — `xs={12} md={6}` (2 col desktop)
  5. Confirmar contraseña — `xs={12} md={6}`
- Validación inline:
  - Nombre: mínimo 2 caracteres.
  - Email: regex + verifica dominio.
  - Contraseña: mínimo 8 caracteres, al menos una letra y un número. Mostrar indicador de fuerza (débil/media/fuerte) como barra horizontal bajo el campo.
  - Confirmar: coincidencia. `helperText` en verde `store.success` cuando coincide.
- Checkbox "Acepto términos y condiciones y política de privacidad" (links a `/legal/terminos` y `/legal/privacidad`). **Obligatorio** para submit.
- Botón submit: `fullWidth`, variant contained, naranja `store.accent.primary`, color `#0f1111`, bold, height 48 px.
- Link footer: "¿Ya tienes cuenta? **Inicia sesión**" — centrado, mt: 3.
- Estado success: mantener diseño actual pero iconografía real (sobre Material) en vez de `&#9993;` raw. Icon `EmailOutlined` 56 px naranja.

**Social login** (si hay hook disponible): divisor "o continúa con" + botones `<Button variant="outlined">` Google + Apple bajo el primer campo. Si no existe hook, placeholder con flag `Pendiente shared-ui/API`.

**Criterios de aceptación**:
- [ ] `/login` y `/registro` tienen el mismo ancho y padding.
- [ ] Al submit con contraseñas distintas muestra error inline bajo "Confirmar" (no alert global).
- [ ] El indicador de fuerza de contraseña se actualiza mientras escribe.
- [ ] Funciona con teclado (Tab, Enter submit).

### 1E. Tabla de comisiones `/afiliados` → `ZenttoDataGrid`

**Problema actual** (bloqueo crítico): el archivo usa `<Table>`/`<TableBody>` MUI nativo. **Viola regla #1 del ecosistema**. Ver `apps/ecommerce/src/app/afiliados/page.tsx` líneas 178-206.

**Propuesta**:
- Reemplazar `<TableContainer><Table>...</Table></TableContainer>` por `<ZenttoDataGrid>`.
- Mantener el fondo oscuro `#232f3e` como wrapper de la sección, pero el grid en sí es fondo blanco.
- Sin toolbar (tabla estática de marketing).
- Sin paginación (≤ 20 filas).
- Columnas:
  ```ts
  [
    { field: 'category', headerName: 'Categoría', flex: 2, sortable: false },
    { field: 'rate', headerName: 'Comisión', flex: 1, align: 'center',
      renderCell: (row) => <Chip label={row.rate} sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700 }} /> },
    { field: 'cookie', headerName: 'Duración cookie', flex: 1, align: 'center' },
    { field: 'min', headerName: 'Mínimo retiro', flex: 1, align: 'right' },
  ]
  ```
- Datos: por ahora hardcoded (es landing de marketing, aceptable mientras no exista endpoint). Marcar TODO: mover a `useAffiliateCommissionTable()`.
- Expandir datos a 6-8 filas reales con categorías completas: Electrónica 3 %, Ropa y moda 5 %, Hogar 7 %, Software y SaaS 10 %, Servicios digitales 12 %, Cursos online 15 %, Libros 4 %, Juguetería 6 %.

**Criterios de aceptación**:
- [ ] Cero `<table>` HTML en el archivo.
- [ ] Cero `<Table>`, `<TableRow>`, `<TableCell>` MUI.
- [ ] El grid es responsive — en mobile se convierte a cards (comportamiento default `ZenttoDataGrid`).
- [ ] Chip de comisión usa naranja sobre texto oscuro (WCAG AA OK).

---

## OLA 2 — Admin productos (backoffice catálogo)

**Alcance**: nuevo árbol bajo `/admin`. Sidebar admin con acordeones. Productos CRUD con tabs. Categorías, marcas, reviews.

### 2.0 Layout admin — sidebar con acordeones

**Reemplazar** `apps/ecommerce/src/app/admin/layout.tsx` por una versión con acordeones por sección (la actual es una lista plana de 3 items).

**Estructura del sidebar** (`DRAWER_WIDTH = 240 px`):

```
┌──────────────────────────────┐
│  ZenttoStore · Admin         │  ← toolbar header #131921
├──────────────────────────────┤
│                              │
│  📊 Dashboard                │  ← item suelto (no acordeón)
│                              │
│  🛒 VENTAS                 ▼ │  ← acordeón (open por default en ruta)
│    · Pedidos                 │
│    · Devoluciones      [3]   │  ← badge numérico naranja si hay pending
│    · Afiliados               │
│    · Vendedores              │
│                              │
│  📦 CATÁLOGO              ▼ │
│    · Productos               │
│    · Categorías              │
│    · Marcas                  │
│    · Reviews           [12]  │
│                              │
│  📝 CONTENIDO             ▶ │  ← collapsed
│    · Páginas CMS             │
│    · Prensa / Blog           │
│    · Banners                 │
│                              │
│  ⚙️ SISTEMA               ▶ │
│    · Configuración           │
│    · Performance             │
│    · Logs                    │
│                              │
└──────────────────────────────┘
```

**Specs**:
- Sidebar bg `#232f3e` (match actual), texto `#fff`, item activo bg `#37475a` + barra izquierda 3 px `#ff9900`, texto activo `#ff9900`.
- Header acordeón: uppercase, 12 px/700, letter-spacing 0.5 px, color `#cccccc`, padding `10px 16px`, icono chevron rotativo `transition: transform 150ms`.
- Items: 13 px/400, padding `8px 16px 8px 40px` (indent bajo sección). Icono izquierdo opcional (14 px).
- Badge numérico: `<Chip size="small" sx={{ bgcolor: '#ff9900', color: '#0f1111', height: 18, fontSize: 11, fontWeight: 700 }} />`.
- Persistencia estado acordeones: `localStorage['zentto_admin_sidebar_<section>']` ('open'|'closed').
- Auto-expand de la sección activa al cargar (según `pathname`).
- Mobile (<md): sidebar se convierte en Drawer temporal, hamburger en AppBar.

**Items iniciales** (algunos disabled con tooltip "Próximamente" hasta que exista):

```
Ventas
  - /admin/pedidos                    (existe /pedidos cliente; admin pendiente)
  - /admin/devoluciones               (existe)
  - /admin/afiliados                  (nuevo — Ola 4)
  - /admin/vendedores                 (nuevo — Ola 4)

Catálogo
  - /admin/productos                  (nuevo)
  - /admin/categorias                 (nuevo)
  - /admin/marcas                     (nuevo)
  - /admin/reviews                    (nuevo)

Contenido
  - /admin/cms                        (nuevo — Ola 3)
  - /admin/prensa                     (nuevo — Ola 3)
  - /admin/banners                    (pendiente)

Sistema
  - /admin/configuracion              (pendiente)
  - /admin/perf                       (existe)
  - /admin/logs                       (pendiente)
```

**Criterios de aceptación**:
- [ ] Acordeón con ruta activa viene expandido al entrar.
- [ ] Al colapsar una sección, se guarda estado en localStorage.
- [ ] Items con badge de count pendiente (reviews/devoluciones) muestran el número real de la API.
- [ ] Hover sobre item: bg `#37475a` sin glitch de z-index.
- [ ] Navegación por teclado: Tab enfoca headers acordeón, Enter los abre/cierra, flecha abajo salta al primer item.

### 2.1 `/admin/productos` — Lista

**Ruta**: `apps/ecommerce/src/app/admin/productos/page.tsx`.

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│  Productos                       [⚙ Columnas]  [+ Nuevo producto]│  ← header H1 + CTA
│  Gestiona el catálogo de tu tienda                                │  ← subtítulo
├─────────────────────────────────────────────────────────────────┤
│  [Buscar SKU, nombre, código 🔍]  [Filtros (2)▼]  [Export CSV]    │  ← toolbar grid
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│   ZenttoDataGrid con columnas:                                   │
│   - [checkbox]                                                    │
│   - [img 40px] Imagen                                             │
│   - SKU                                                           │
│   - Nombre (link a editar)                                        │
│   - Categoría (chip)                                              │
│   - Marca                                                         │
│   - Precio (align right, currency)                                │
│   - Stock (numeric; chip rojo si < 5)                             │
│   - Estado (chip: Activo/Borrador/Archivado)                      │
│   - Última actualización (timeago)                                │
│   - Acciones (kebab menu)                                         │
│                                                                   │
│                                          [< 1 2 3 4 5 >]  25 ▼    │
└─────────────────────────────────────────────────────────────────┘
```

**Filtros** (ZenttoFilterPanel en popover):
- Estado: multi-chip (Activo, Borrador, Archivado).
- Categoría: autocomplete multi.
- Marca: autocomplete multi.
- Stock: radio (Todos, Con stock, Sin stock, Stock bajo < 10).
- Precio: rango slider.
- Fecha creación: date-range picker.

**Bulk actions** (cuando hay seleccionados):
- Cambiar estado → dropdown (Activar / Archivar / Borrador).
- Asignar categoría.
- Eliminar (con confirmación).
- Exportar seleccionados.

**Menú kebab por fila**:
- Ver en tienda (link a `/productos/[code]` target _blank).
- Editar (link a `/admin/productos/[id]`).
- Duplicar.
- Archivar.
- Eliminar (destructivo).

**Empty state**:
```
📦 (icono 64 px)
Aún no tienes productos
Crea tu primer producto para empezar a vender.
[+ Nuevo producto]   [Importar CSV]
```

**Criterios de aceptación**:
- [ ] Grid usa `ZenttoDataGrid`, no MUI `DataGrid`.
- [ ] Buscar debounced 250 ms, busca por nombre + SKU + código.
- [ ] Chip stock < 5 es rojo `store.error`.
- [ ] Columna precio formateada con `formatPrice(value, currency)`.
- [ ] Export CSV descarga archivo real (no alert).
- [ ] URL state: filtros se sincronizan con query params (`?status=active&cat=1,2`).

### 2.2 `/admin/productos/nuevo` y `/admin/productos/[id]` — Formulario con tabs

**Ruta compartida** (un solo page.tsx para ambos): `apps/ecommerce/src/app/admin/productos/[id]/page.tsx` con `id === 'nuevo'` → modo create.

**Layout**:
```
┌───────────────────────────────────────────────────────────────┐
│  ← Productos / Nuevo producto                    [Guardar ▼]   │  ← breadcrumb + sticky CTA
│                                                                 │
│  ┌─ Tabs horizontales ───────────────────────────────────┐     │
│  │ Info · SEO · Galería · Highlights · Specs · Variantes · Reviews │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌─ Panel principal (8/12) ─┐ ┌─ Sidebar (4/12) ─────────┐    │
│  │                           │ │  Estado                   │    │
│  │  [Contenido del tab]      │ │  [Activo ▼]               │    │
│  │                           │ │                           │    │
│  │                           │ │  Organización             │    │
│  │                           │ │  Categoría                │    │
│  │                           │ │  Marca                    │    │
│  │                           │ │  Tags                     │    │
│  │                           │ │                           │    │
│  │                           │ │  Precio                   │    │
│  │                           │ │  $ 0.00                   │    │
│  │                           │ │  Precio comparativo       │    │
│  │                           │ │                           │    │
│  │                           │ │  Inventario               │    │
│  │                           │ │  SKU · Stock              │    │
│  │                           │ │                           │    │
│  └───────────────────────────┘ └───────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

**Sidebar derecho (fijo `md+`, stack arriba `<md`)**: acordeones colapsables Estado / Organización / Precio / Inventario / Envío.

**Save button**: sticky top-right. Split button con "Guardar" (default) + dropdown: "Guardar y salir", "Guardar como borrador", "Guardar y duplicar".

#### Tab **Info**

```
FormGrid spacing=2
  FormField xs=12 md=12: TextField "Nombre" (required, 3-200 chars)
  FormField xs=12 md=6:  TextField "Código (slug URL)" (auto-generado del nombre, editable)
  FormField xs=12 md=6:  TextField "SKU" (required, único)
  FormField xs=12 md=12: TextField "Descripción corta" (multiline rows=2, 160 chars máx, contador)
  FormField xs=12 md=12: RichTextEditor "Descripción completa"   ← usa @zentto/shared-ui RichText si existe, si no TextField multiline y flag Pendiente
```

Contador de caracteres bajo descripción corta: `{n}/160` en gris, naranja si > 140.

#### Tab **SEO**

```
FormGrid
  FormField xs=12: TextField "Meta título" (50-60 chars, contador)
  FormField xs=12: TextField "Meta descripción" (multiline rows=3, 140-160 chars, contador)
  FormField xs=12: TextField "URL canónica" (auto, readonly-toggle)
  FormField xs=12: Autocomplete multi "Keywords"
  FormField xs=12: ImageUpload "Imagen social (og:image)" (1200×630 sugerido)

  Preview SERP (read-only):
  ┌─────────────────────────────────────────┐
  │ zentto.net/ecommerce/productos/xxx       │
  │ Título de la página — Zentto Store      │  ← azul link
  │ Meta descripción preview en gris...      │
  └─────────────────────────────────────────┘
```

Contador chars verde 50-60 título / 140-160 descripción, amarillo al borde, rojo fuera.

#### Tab **Galería** (drag-drop)

**Zona upload**:
```
┌───────────────────────────────────────────────────────┐
│  ┌ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┐     │
│  ┇   [icono upload 48 px]                      ┇     │
│  ┇   Arrastra imágenes aquí o haz clic         ┇     │
│  ┇   JPG, PNG, WebP · máx 5 MB cada una        ┇     │
│  ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈ ┈     │
│     border: 2px dashed #d5d9d9 → #ff9900 en hover/drag-over │
└───────────────────────────────────────────────────────┘
```

**Grid de previews** (3 columnas desktop / 2 tablet / 2 mobile):

```
┌─────────┬─────────┬─────────┐
│  [img]  │  [img]  │  [img]  │
│  ★      │  ☆ x    │  ☆ x    │  ← star si primaria (amarillo), x delete (hover reveal)
│  alt:.. │  alt:.. │  alt:.. │  ← TextField inline 12 px
└─────────┴─────────┴─────────┘
```

Specs:
- Preview 180×180 px, `objectFit: cover`, `borderRadius: 6px`.
- Primaria: halo amarillo `#ff9900` border 2 px + icono estrella top-left en chip.
- Hover: overlay oscuro 30 %, botones `★ Hacer primaria`, `x Eliminar` centrados.
- Reordenable por drag (DnD): el orden define orden en storefront.
- Alt text inline obligatorio (accesibilidad) — WCAG. Si está vacío, borde rojo + helperText "Añade texto alternativo para accesibilidad".
- Progreso de upload: barra horizontal 4 px bajo cada preview durante subida.
- Error de upload: tarjeta roja con retry.

**Criterios de aceptación**:
- [ ] Arrastrar al drop zone cambia el borde a naranja.
- [ ] Drag entre previews reordena y persiste al guardar.
- [ ] La primera imagen cargada es primaria automática.
- [ ] Alt text vacío bloquea el guardado global con toast de error.

#### Tab **Highlights** (bullets de producto)

Lista editable de bullets (destacados tipo Amazon "Acerca de este artículo"). Drag-sort.

```
┌─────────────────────────────────────────────────┐
│  Destacados del producto                         │
│  Muestra 3-6 bullets en la página del producto.  │
│                                                  │
│  ⋮  Pantalla 6.1" Super Retina XDR          x   │
│  ⋮  Chip A16 Bionic — el más rápido          x   │
│  ⋮  Cámara 48 MP con modo acción             x   │
│                                                  │
│  [+ Añadir destacado]                            │
└─────────────────────────────────────────────────┘
```

Max 200 chars por bullet. Hint: "Usa verbos y beneficios concretos".

#### Tab **Specs** (tabla key-value)

Grid de especificaciones técnicas agrupadas por categoría (General / Pantalla / Batería / Conectividad...).

```
┌── General ─────────────────┐
│ Modelo       | iPhone 15    │ [x]
│ Color        | Titanio      │ [x]
│ Peso         | 171 g        │ [x]
│ [+ Añadir spec]              │
└─────────────────────────────┘

[+ Añadir grupo]
```

Cada row: `<TextField>` key, `<TextField>` value, icono eliminar. Drag-sort entre grupos.

#### Tab **Variantes**

Modelo: atributos (Color, Talla) → combinaciones generadas.

```
Atributos
┌─────────────────────────────────────────┐
│ Color: [Negro] [Blanco] [+ Añadir]      │
│ Talla: [S] [M] [L] [XL] [+ Añadir]      │
└─────────────────────────────────────────┘
                  ↓ generar

Combinaciones (8)
┌────────────────────────────────────────────────┐
│ ZenttoDataGrid:                                │
│ Color | Talla | SKU        | Precio  | Stock  │
│ Negro | S     | VAR-001    | 100.00  | 10     │
│ Negro | M     | VAR-002    | 100.00  | 15     │
│ ...                                             │
└────────────────────────────────────────────────┘
```

Bulk edit: seleccionar varias combinaciones y editar precio/stock masivo.

#### Tab **Reviews**

Listado read-only de reviews del producto con `ZenttoDataGrid`:
- Autor, rating (estrellas), título, snippet, fecha, estado (aprobado/pendiente), acciones (aprobar, rechazar, responder, eliminar).

Panel superior: distribución de estrellas (barras horizontales 5★-1★) + rating promedio grande.

**Criterios de aceptación globales formulario producto**:
- [ ] Si usuario cambia de tab con cambios sin guardar, aparece modal "¿Descartar cambios?".
- [ ] Validación global muestra chip rojo en tab con errores.
- [ ] `Ctrl+S` guarda.
- [ ] El botón "Guardar" muestra loading state y toast de éxito al terminar.
- [ ] Breadcrumb siempre lleva de vuelta a `/admin/productos` conservando filtros.

### 2.3 `/admin/categorias`

Lista en `ZenttoDataGrid`:
- Nombre (con icono/color si existe)
- Slug
- Productos (count)
- Padre (para jerarquía)
- Orden
- Estado
- Acciones

Vista alternativa: **árbol jerárquico** con toggle `Lista | Árbol` en toolbar. En árbol: drag para reordenar, indentación por nivel.

Formulario `/admin/categorias/[id]`:
- Nombre, slug, descripción, padre (select tree), imagen, icono (opcional), banner URL, SEO meta, orden, estado.

### 2.4 `/admin/marcas`

Grid simple:
- Nombre, logo (48 px), productos count, país, estado, acciones.

Upload logo con zona drag-drop (reusar componente de Galería producto, tamaño 120 × 40 preferido).

### 2.5 `/admin/reviews`

Grid con filtro extra por rating (1-5 estrellas radio) y estado (Pendiente / Aprobado / Rechazado). Vista default: filtro "Pendiente" activado.

Acciones bulk: aprobar / rechazar / eliminar seleccionados.

Modal detalle al hacer click en un review: review completo + caja de respuesta del admin.

---

## OLA 3 — CMS público + studio admin

**Alcance**: páginas públicas `/prensa`, `/prensa/[slug]`, `/acerca`, `/trabaja-con-nosotros`, `/contacto`, `/devoluciones`, `/centro-de-ayuda` alimentadas desde CMS. Admin `/admin/cms` y `/admin/prensa` con editor.

### 3.0 Arquitectura CMS (contrato)

El CMS expone dos tipos:
1. **Pages** (estáticas): `/acerca`, `/contacto`, `/devoluciones`, `/centro-de-ayuda`, `/trabaja-con-nosotros`. Cada una tiene un JSON de bloques + meta.
2. **Posts** (blog/prensa): `/prensa` (lista paginada), `/prensa/[slug]` (detalle).

Hooks esperados en `@zentto/module-ecommerce/cms`:
- `useCmsPage(slug)` → `{ title, blocks, meta, publishedAt, updatedAt }`
- `useCmsPostsList({ page, pageSize, category })` → `{ posts, total }`
- `useCmsPost(slug)` → full post
- `useCmsPageSave(slug)`, `useCmsPostSave(id)` mutations

**Si no existen**: pedir a agente integración. Marcar `Pendiente shared-ui/API`.

### 3.1 `/prensa` — Listado (público)

**Layout**:
```
┌───────────────────────────────────────────────────┐
│  HERO (actual ok, solo ajustes)                    │
│  Gradient #131921 → #232f3e                        │
│  NewspaperOutlined 64px orange                     │
│  H1 "Prensa y noticias" (40 px/700)                │
│  Subtitle "Zentto en los medios"                   │
└───────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────┐
│  [Buscar posts 🔍]   [Categoría: Todas ▼]          │  ← filtros simples
├───────────────────────────────────────────────────┤
│                                                     │
│  Post destacado (card horizontal, 1 col)           │  ← primer post con flag featured
│  ┌──────────┬──────────────────────────────────┐  │
│  │  [img    │  📅 15 Mar 2026 · Producto        │  │
│  │  16:9    │  Zentto lanza plataforma ecomm    │  │
│  │  ]       │  Excerpt 2 líneas...               │  │
│  │          │  Leer más →                        │  │
│  └──────────┴──────────────────────────────────┘  │
│                                                     │
│  Grid de posts (3 col desktop / 2 tablet / 1 mobile)│
│  ┌──────┬──────┬──────┐                            │
│  │ [img]│ [img]│ [img]│                            │
│  │ fecha│      │      │                            │
│  │ H3   │      │      │                            │
│  │ snip │      │      │                            │
│  └──────┴──────┴──────┘                            │
│  ...                                                │
│                                                     │
│                         [< 1 2 3 4 5 >]            │
└───────────────────────────────────────────────────┘
```

Card post:
- Paper `p: 0`, `borderRadius: 12 px` (landing feel).
- Imagen top `16:9 aspect-ratio`, `objectFit: cover`, `borderRadius: 12px 12px 0 0`.
- Body padding 20 px.
- Fecha 12 px naranja + categoría chip pequeña.
- Título 18 px/600 dos líneas máx (`line-clamp: 2`).
- Excerpt 14 px/400 tres líneas máx.
- Hover: `translateY(-4px)`, `shadow.md`, `150ms`.

**Empty state**: "Pronto publicaremos novedades. Mientras tanto, [suscríbete a nuestro newsletter]."

### 3.2 `/prensa/[slug]` — Detalle post

**Layout centrado** (lectura):
```
┌─────────────────────────────────────────────────┐
│  ← Volver a Prensa                               │  ← link naranja top
│                                                   │
│  [Categoría chip]  · 📅 15 Mar 2026 · 5 min       │  ← meta
│  H1 Título grande (40-48 px / 700)                │
│  Subtítulo opcional 20 px                         │
│                                                   │
│  [Hero image 16:9]                                │
│                                                   │
│  Cuerpo Markdown renderizado                      │
│  maxWidth: 720 px                                 │
│  Tipografía serif? No — system sans, 17 px/1.75   │
│  H2, H3, listas, quotes, code blocks estilados    │
│                                                   │
│  ── Autor card al final ──                        │
│  [avatar 48] Autor Name · Rol                     │
│  Bio corta                                         │
│                                                   │
│  ── Compartir ──                                  │
│  [Twitter] [LinkedIn] [WhatsApp] [Copiar link]    │
│                                                   │
│  ── Posts relacionados (3 cards) ──               │
└─────────────────────────────────────────────────┘
```

- Container `maxWidth: 800 px`, lectura tipográfica.
- Headings: h1 40 px, h2 28 px, h3 22 px.
- Párrafos: 17 px / 1.75 line-height / `#0f1111`.
- Quotes: border-left 4 px `#ff9900`, padding-left 16 px, italic.
- Code inline: bg `#f5f5f5`, borderRadius 4 px, padding `2px 6px`, font mono.
- Code block: bg `#0f1111`, color `#fff`, padding 16 px, borderRadius 6 px, overflow-x auto.
- Imágenes cuerpo: `maxWidth: 100%`, borderRadius 8 px, caption opcional 13 px gris.

### 3.3 `/acerca`, `/trabaja-con-nosotros`, `/devoluciones`, `/centro-de-ayuda` — Página CMS genérica

**Renderer de bloques** — el CMS devuelve `blocks: Block[]` donde `Block` es uno de:

```
- HeroBlock        { title, subtitle, image, cta }
- TextBlock        { markdown }
- TwoColumnBlock   { left: Block, right: Block }
- ImageGalleryBlock { images[] }
- FAQBlock         { items: [{question, answer}] }
- StatsBlock       { stats: [{label, value}] }
- CTABlock         { title, description, button }
- TeamBlock        { members: [{name, role, photo, bio}] }
- TimelineBlock    { events: [{year, title, description}] }
- JobsListBlock    { jobs: [{title, location, type}] } ← trabaja-con-nosotros
- ReturnStepsBlock { steps: [{step, title, description}] } ← devoluciones
- HelpCategoriesBlock { categories: [{icon, title, articles}] } ← centro-de-ayuda
```

Cada bloque tiene spec visual propia. Mantener paleta tokens para consistencia.

### 3.4 `/contacto` — Form real

**Problema actual**: `handleSubmit` solo limpia el estado, no envía nada.

**Propuesta**:
- Hook `useContactFormSubmit()` de `module-ecommerce` (crear o marcar pendiente).
- Endpoint sugerido: `POST /store/contact` con `{ nombre, email, asunto, mensaje, phone?, company? }`.
- Integra con `@zentto/notify` para envío email a `soporte@zentto.net` + autoreply al usuario.

Campos form:
- Nombre (required)
- Email (required, regex)
- Teléfono (optional)
- Empresa (optional)
- Asunto (select — ya existe lista)
- Mensaje (multiline rows=5, 20-1000 chars, contador)
- reCAPTCHA v3 invisible (si disponible).

Estados:
- Submitting: botón disabled con spinner + "Enviando...".
- Success: reemplaza form por card éxito centrada: icono check verde 56 px + "Mensaje recibido" + "Te responderemos en menos de 24 h hábiles" + botón "Enviar otro mensaje".
- Error: Alert severity=error sticky sobre el form + retry.

### 3.5 Admin CMS

#### `/admin/cms` — listado de páginas

`ZenttoDataGrid`:
- Slug (`/acerca`, `/contacto`, etc.)
- Título
- Última edición (timeago + autor)
- Estado (Publicado / Borrador)
- Visitas (30d) — si hay analytics
- Acciones (Ver en vivo, Editar, Historial, Duplicar)

Botón "+ Nueva página" — abre wizard.

#### `/admin/cms/[slug]` — editor de página

**Layout** (split 50/50 desktop, stack mobile):

```
┌── Editor (50%) ──────────┐ ┌── Preview (50%) ───────┐
│  Bloques actuales:        │ │                        │
│  ▼ Hero                   │ │   Renderizado live      │
│  ▼ Texto                  │ │   de la página          │
│  ▼ FAQ                    │ │                        │
│  ▶ Stats                  │ │                        │
│                            │ │                        │
│  [+ Añadir bloque ▾]       │ │                        │
│                            │ │                        │
│  Desktop ▼ Tablet ▼ Mobile▼│ │  [desktop/tablet/mobile│
│                            │ │   toggle preview size] │
└──────────────────────────┘ └────────────────────────┘
```

Cada bloque es un acordeón:
- Header: drag handle ⋮ + nombre bloque + botón colapsar + botón eliminar.
- Body: formulario específico del bloque (usar FormGrid).

Preview actualizado en realtime (debounce 500 ms en cambios) — usa el mismo renderer que la página pública.

Toolbar top del editor:
- Título editable inline.
- Status chip (Publicado/Borrador).
- Botones `[Ver en vivo]` (abre nueva pestaña) `[Guardar borrador]` `[Publicar]` (primario naranja).
- Historial: abre drawer con versiones anteriores + diff.

#### `/admin/prensa` — listado posts blog

`ZenttoDataGrid`:
- Imagen (40 px)
- Título (link edit)
- Slug
- Categoría (chip)
- Autor
- Fecha publicación
- Estado
- Destacado (toggle ★)
- Acciones (ver, editar, eliminar, duplicar)

#### `/admin/prensa/[id]` — editor post

Editor markdown con preview (split pane). Librería sugerida: `@uiw/react-md-editor` si ya está, si no evaluar en Ola 3.

Campos adicionales (sidebar derecho):
- Slug (auto-gen + editable)
- Categoría (select)
- Tags (autocomplete multi)
- Featured (toggle)
- Imagen de portada (upload drag-drop)
- Autor (select users)
- SEO meta (título, descripción, og:image — reusar tab SEO de producto).
- Schedule publish (date-time picker).

**Criterios de aceptación CMS**:
- [ ] Preview live refleja cambios <1 s.
- [ ] Guardar borrador no publica.
- [ ] Publicar actualiza página pública en <10 s (tiempo de revalidate Next).
- [ ] Historial muestra últimas 10 versiones.
- [ ] Editor markdown soporta imágenes (upload inline) y links relativos.

---

## OLA 4 — Afiliados + Marketplace multi-vendor

**Alcance**: público afiliados (landing/registro/dashboard), público marketplace (`/vende`, `/vender/aplicar`, `/vender/dashboard`), admin (`/admin/afiliados`, `/admin/afiliados/comisiones`, `/admin/vendedores`, `/admin/vendedores/productos`).

### 4.0 Modelos mentales

**Afiliado**: persona que comparte links y cobra comisión por venta.
**Vendedor (seller)**: empresa/persona que vende productos propios en el marketplace — tiene catálogo, recibe pedidos, cobra payouts.

Son dos roles separados. Un usuario puede ser ambos.

### 4.1 `/afiliados` — landing (mejora Ola 1 ya entrega tabla con ZenttoDataGrid)

Complementos Ola 4:
- Sección **testimonios** (3 cards) con foto afiliado + monto generado mes pasado (maquetado, datos reales cuando haya).
- Sección **métricas agregadas del programa**: "Más de 500 afiliados · $50k pagados en comisiones · 98% de satisfacción" — en banda `#232f3e`.
- CTA principal habilitado (actualmente `disabled`) → `/afiliados/registro`.

### 4.2 `/afiliados/registro`

Form:
```
Datos personales
  - Nombre completo
  - Email (usa el de la cuenta si logueado, read-only)
  - Teléfono / WhatsApp
  - País (Autocomplete, prellenado del CurrencySelector)

Datos bancarios (para payouts)
  - Método preferido (radio: Transferencia bancaria / PayPal / Stripe / USDT)
  - Campos condicionales según método

Perfil digital
  - Sitio web (opcional)
  - Redes sociales (Instagram, YouTube, TikTok, X) — max 4
  - Audiencia aproximada (select rango: <1k, 1-10k, 10-100k, 100k+)
  - Nichos (multi-chip: Tech, Moda, Hogar, Finanzas, Educación, Salud...)

Términos
  - Checkbox "Acepto términos del programa de afiliados"
```

Al submit → email de verificación → al aprobar (manual o auto) → acceso a `/afiliados/dashboard`.

Estados:
- Pendiente aprobación → página con card "Estamos revisando tu solicitud. Te notificaremos en 24-48 h."
- Rechazado → card con motivo y opción de reaplicar.
- Aprobado → redirect a dashboard.

### 4.3 `/afiliados/dashboard` — métricas + link + comisiones + gráfico

**Layout** (dashboard clásico SaaS):

```
┌──── KPI cards (4 columnas desktop, 2 mobile) ────────────────────┐
│ Clicks este mes │ Conversiones │ Comisión ganada │ Balance disponible │
│ 1,245           │ 23 (1.8%)    │ $ 340.20        │ $ 120.50           │
│ +12% vs mes ant │ +5% ...      │ +22% ...        │ [Solicitar retiro] │
└───────────────────────────────────────────────────────────────────┘

┌── Tu link de referido ────────────────────────────────────────────┐
│  https://zentto.net/ref/ABC123                     [Copiar]        │
│  QR code 80×80 (toggle "Ver QR")                                   │
│  Usa este link en tus publicaciones para ganar comisión.           │
└─────────────────────────────────────────────────────────────────────┘

┌── Ventas (últimos 6 meses) ───────────────────────────────────────┐
│  [Line chart 180px altura — Ventas y comisiones mes a mes]         │
│  Ejes: mes X, monto Y. Dos líneas: Ventas (gris) + Comisión (naranja)│
└─────────────────────────────────────────────────────────────────────┘

┌── Comisiones ─────────────────────────────────────────────────────┐
│ Acordeón "Comisiones" (default open)                              │
│   [Filtros: fecha / estado]                                        │
│   ZenttoDataGrid:                                                  │
│   Fecha | Pedido | Cliente | Monto venta | Categoría | % | Tu comisión | Estado │
│   2026-04-18 | #123 | Juan P. | $ 150 | Software | 10% | $ 15.00 | Pagada │
│   ...                                                               │
└─────────────────────────────────────────────────────────────────────┘

┌── Retiros ────────────────────────────────────────────────────────┐
│ Acordeón "Retiros" (default closed)                               │
│   ZenttoDataGrid: Fecha · Monto · Método · Estado · Comprobante    │
└─────────────────────────────────────────────────────────────────────┘

┌── Material promocional ───────────────────────────────────────────┐
│ Acordeón "Material promocional" (default closed)                   │
│   Grid 3x2 de banners descargables + instrucciones                 │
└─────────────────────────────────────────────────────────────────────┘
```

**Gráfico**: usar `@zentto/report` si expone chart o `recharts` (verificar qué usa el resto del frontend — **no añadir nueva lib sin confirmación**). Marcar `Pendiente shared-ui` si hace falta componente `<LineChart>`.

**KPI card**:
```
┌────────────────────────┐
│ Clicks este mes        │  ← label 12 px #565959
│ 1,245                  │  ← número 28 px / 700 #0f1111
│ ▲ +12% vs mes anterior │  ← delta verde si ↑, rojo si ↓
└────────────────────────┘
p: 2.5, borderRadius: 8, shadow.xs, bg #fff
```

**Criterios de aceptación**:
- [ ] Todos los grids son `ZenttoDataGrid`.
- [ ] Dashboard usa acordeones para secciones de "Comisiones", "Retiros", "Material".
- [ ] Link de referido se copia al clipboard con toast "Link copiado".
- [ ] Gráfico se adapta a mobile (altura proporcional, labels abreviados).
- [ ] "Solicitar retiro" abre modal de confirmación y muestra monto mínimo si el balance < mínimo.

### 4.4 `/vende` — landing marketplace (seller)

Copy: "Vende tus productos en Zentto Store. Llega a miles de clientes sin montar tu propio ecommerce."

Secciones:
1. Hero con CTA "Aplica para vender" (hero reusar patrón `/afiliados`).
2. Beneficios (3 cards): "Catálogo ilimitado", "Pagos seguros", "Panel completo".
3. **Comisiones por vertical** (ZenttoDataGrid — diferente de afiliados):
   - Categoría | % Zentto | Tu ganancia por $100 | Mínimo payout
4. Proceso de onboarding (timeline 4 pasos): Aplicar → Verificación → Alta catálogo → Primera venta.
5. FAQ (accordions).
6. CTA final.

### 4.5 `/vender/aplicar`

Form similar a afiliados/registro pero para empresa:
- Datos empresa (nombre fiscal, RUC/RFC/NIT, dirección, país, ciudad).
- Representante (nombre, email, teléfono).
- Documentos (upload): registro mercantil, RUC/RFC doc, identificación del representante.
- Categorías de producto (multi-chip).
- Volumen mensual esperado (select).
- Website actual (optional).
- Términos específicos seller.

Estado pendiente → card "Tu aplicación está en revisión. Plazo 3-5 días hábiles."

### 4.6 `/vender/dashboard` — panel seller con acordeones

**Tres acordeones principales** (default el de la última ruta usada):

```
┌── Mis productos ──────────────────────────────────── ▼ ──┐
│  [+ Nuevo producto]     [Importar CSV]                    │
│  ZenttoDataGrid con columnas similares a /admin/productos │
│  pero filtrado solo a los del vendedor.                    │
└─────────────────────────────────────────────────────────────┘

┌── Ventas ──────────────────────────────────────────── ▶ ──┐
│  KPI row: Ventas mes · Pedidos · Ticket promedio · Payout pendiente │
│  Gráfico ventas 30d                                         │
│  ZenttoDataGrid pedidos: Fecha · Cliente · Productos · Total · Estado │
└─────────────────────────────────────────────────────────────┘

┌── Payouts ─────────────────────────────────────────── ▶ ──┐
│  Balance disponible: $ 3,421.50                             │
│  [Solicitar payout]  mín $50                                │
│  Historial de payouts (ZenttoDataGrid)                      │
└─────────────────────────────────────────────────────────────┘
```

Formulario de nuevo producto del seller: mismo patrón que admin productos (tabs) pero **sin** tab de Variantes/Reviews en MVP — marcar `Pendiente shared-ui/API`.

### 4.7 Admin `/admin/afiliados`

Grid afiliados:
- Afiliado (nombre + email)
- País
- Estado (Pendiente / Aprobado / Suspendido / Rechazado)
- Clicks 30d
- Conversiones 30d
- Comisión generada total
- Última actividad
- Acciones (ver detalle, aprobar, suspender, contactar)

Filtros: estado, país, rango fecha registro, rango comisión.

Vista detalle `/admin/afiliados/[id]`: panel similar al dashboard del afiliado pero en modo admin, con controles extra (ajustar %, banear, enviar mensaje).

### 4.8 Admin `/admin/afiliados/comisiones`

Grid global de comisiones generadas por todos los afiliados. Útil para auditoría y liquidación mensual.

- Fecha | Afiliado | Pedido | Cliente | Monto venta | % | Comisión | Estado (Pendiente/Aprobada/Pagada/Disputada)
- Acciones: ver pedido, aprobar manualmente, marcar pagada, disputar.
- Bulk actions: aprobar seleccionadas, marcar pagadas (con referencia de pago).
- Filtro por período default "mes actual".
- Export CSV para liquidación.

### 4.9 Admin `/admin/vendedores`

Grid sellers:
- Seller (logo + nombre empresa)
- País
- Productos activos (count)
- Ventas 30d
- Estado (Pendiente / Activo / Suspendido / Rechazado)
- Score reviews promedio
- Acciones (ver, aprobar, suspender, contactar, revisar docs)

### 4.10 Admin `/admin/vendedores/productos`

Grid consolidado de TODOS los productos de TODOS los sellers. Permite al admin moderar catálogo marketplace sin entrar seller por seller.

Columnas: Producto | Seller | Categoría | Precio | Stock | Estado | Fecha alta | Acciones (ver, aprobar, rechazar, suspender).

Filtros: seller, categoría, estado (Pendiente aprobación / Aprobado / Rechazado / Suspendido).

Workflow: seller crea producto → status `Pendiente aprobación` → admin revisa y aprueba/rechaza → aparece en catálogo público.

---

## Anti-patrones detectados en mocks actuales (comunicar a implementadores)

1. **`<Table>` MUI en `afiliados/page.tsx`** (líneas 178-206) — reemplazar por `ZenttoDataGrid` obligatorio.
2. **Character entity raw `&#9993;`** en `registro/page.tsx` línea 51 — usar icono Material `<EmailOutlined />`.
3. **`subjects` hardcoded** en `contacto/page.tsx` — debe venir de lookup API (`useLookup('contact_subjects')`).
4. **`pressReleases` hardcoded** en `prensa/page.tsx` — debe venir del CMS (`useCmsPostsList`).
5. **Sidebar admin plano** (`admin/layout.tsx`) con solo 3 items — crear acordeones por sección Ventas/Catálogo/Contenido/Sistema.
6. **`CurrencySelector` dos Select no buscables** — en LATAM 14+ países pide Autocomplete.
7. **Buscador sin sugerencias de producto** — solo recientes, Amazon/Shopify tienen productos inline.
8. **Mini-cart siempre Drawer** — desktop se beneficia de Popper 360 px.
9. **Registro y login visualmente desalineados** — simetrizar shell.
10. **Botones "Próximamente" disabled** en `/afiliados` y `/prensa` kit — OK como placeholder, pero marcar en backlog.
11. **Colors hardcoded en cada archivo** (`#131921`, `#232f3e`, `#ff9900`) — considerar mover a `theme.palette.store.*` en shared-ui (post Ola 4, no bloqueante).
12. **Sin focus-visible ring** en botones custom del header (los `Box onClick`) — añadir `&:focus-visible` con outline naranja.
13. **Header "Cuenta y Listas"** sin `<button>` semántico (es `<Box onClick>`) — cambiar a `<ButtonBase>` para accesibilidad.
14. **Footer links abren href directo** sin usar `onNavigate` — consistencia de navegación rota.
15. **`FormField` default `md=4 lg=3`** no documentado — implementadores tienden a asumir `md=12`. Documentar y override explícito en forms de 1 columna.
16. **Lado derecho del admin drawer con `ml: 220 px`** y sin cálculo de `width: calc(100% - 220px)` cuando colapsa — al añadir collapse mobile se rompe. Fix: usar `Box component="main"` sin width explícito.
17. **CartDrawer sin stepper cantidad** dentro del drawer — CartItem lo maneja, pero en popper Ola 1 debe ser explícito.
18. **Success states con string raw de email** (`registro` pone email grande sin verificar formato) — envolver en `<strong>` semántico.
19. **Hero `<Box bg>` repetido** en 5 landings con mismos valores — candidato a componente `<CmsHero>` en `module-ecommerce`.
20. **Ninguna página admin tiene breadcrumb** — agregar `<Breadcrumbs>` MUI sticky en todas.

---

## Referencias de inspiración (patrones — NO copiar literal)

- Shopify admin — https://polaris.shopify.com/patterns — lista productos, form producto con sidebar derecho, drag gallery.
- Polaris DataTable — https://polaris.shopify.com/components/tables/data-table — inspira toolbar + sticky header + empty state.
- Linear — keyboard-first, sidebar colapsable por sección, command palette (futuro).
- Stripe Dashboard — https://stripe.com/docs — KPI cards limpios, gráfico line-chart, export CSV.
- Amazon — header, mini-cart popper desktop 360 px, chip "Añadir al carrito" amarillo, suggestions dropdown.
- HubSpot CMS — editor de bloques split preview, biblioteca de bloques, schedule publish.
- Notion — tab layout con breadcrumb, Ctrl+S feel.
- Attio — records con drawer lateral.
- Supabase — dashboards dark densos (inspira header storefront).

## Checklist global por ola (para que cada agente implementador marque al cerrar)

### Ola 1
- [ ] `CurrencySelector` reescrito con Autocomplete buscable.
- [ ] Buscador con sugerencias de producto (hook `useProductSuggestions` o flag).
- [ ] Mini-cart Popper desktop + CartDrawer mobile.
- [ ] `/registro` simétrico a `/login` con validación inline + indicador fuerza contraseña.
- [ ] Tabla `/afiliados` migrada a `ZenttoDataGrid`.
- [ ] Cero `<table>`, cero `<Table>` MUI, cero MUI `DataGrid` en diff.
- [ ] Focus ring naranja visible en todos los botones custom del header.

### Ola 2
- [ ] Sidebar admin con acordeones + badges + persistencia localStorage.
- [ ] `/admin/productos` grid completo con filtros + bulk actions.
- [ ] Formulario producto con tabs Info/SEO/Galería/Highlights/Specs/Variantes/Reviews.
- [ ] Galería drag-drop + reorder + alt obligatorio.
- [ ] `/admin/categorias` lista + vista árbol.
- [ ] `/admin/marcas` y `/admin/reviews` con workflow de moderación.
- [ ] Ctrl+S guarda en formulario producto.
- [ ] Export CSV funcional en grid productos.

### Ola 3
- [ ] Contratos CMS `useCmsPage`, `useCmsPostsList`, `useCmsPost` (o flag pendiente).
- [ ] `/prensa` + `/prensa/[slug]` públicos dinámicos.
- [ ] `/acerca`, `/trabaja-con-nosotros`, `/devoluciones`, `/centro-de-ayuda` alimentados por blocks.
- [ ] `/contacto` envía real a `soporte@zentto.net` vía notify.
- [ ] `/admin/cms` editor split editor/preview con live update.
- [ ] `/admin/prensa` editor markdown con preview.
- [ ] Breadcrumbs en todas las vistas admin.

### Ola 4
- [ ] `/afiliados` landing completo + testimonios + métricas.
- [ ] `/afiliados/registro` con validación + flujo pendiente.
- [ ] `/afiliados/dashboard` con KPIs + gráfico + 3 acordeones + link referido copy.
- [ ] `/vende`, `/vender/aplicar`, `/vender/dashboard` (3 acordeones seller).
- [ ] `/admin/afiliados`, `/admin/afiliados/comisiones`.
- [ ] `/admin/vendedores`, `/admin/vendedores/productos` con moderación.
- [ ] Todos los grids con `ZenttoDataGrid`, todos los dashboards con acordeones.

---

## Notas para el agente de integración (si se lanza)

**Posibles impactos en contratos API / servicios hermanos**:
- Ola 1: nuevo endpoint `GET /store/storefront/products/suggestions?q=...&limit=5`.
- Ola 2: CRUD completo productos/categorías/marcas/reviews (verificar cobertura vs. `/store/storefront/*` actual).
- Ola 3: endpoints CMS `/cms/pages/:slug`, `/cms/posts`, `/cms/posts/:slug` + notify integration en `/store/contact`.
- Ola 4: endpoints afiliados (`/affiliates/*`), sellers (`/sellers/*`), comisiones (`/affiliates/commissions`).

**Ningún cambio propuesto** rompe auth httpOnly, timezone UTC-0 ni hooks existentes del frontend. Sin riesgo sobre `zentto-notify` más allá del alta de template "contacto recibido" para Ola 3.

**Banderas para `zentto-integration-reviewer`**:
- Si los endpoints CMS de Ola 3 no existen, debe crearse microservicio o extender API DatqBoxWeb.
- Gráfico dashboard afiliado requiere confirmar stack chart (no añadir libs sin aprobación).
- Upload imágenes producto → confirmar storage (Hetzner Object Storage / S3 / local).

## Entregables siguientes (fuera de este doc)

Cada ola deja en su PR:
- Branch `feat/ecommerce-ola{1..4}-*` desde `developer`.
- PR a `developer` con checklist marcado arriba.
- Screenshots antes/después por pantalla principal de la ola.
- Tests e2e básicos del happy-path con Playwright (si stack disponible).
