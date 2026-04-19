# 04 - Modular Frontend (Monorepo)

## Ubicación

- Raíz: `web/modular-frontend`
- App host: `apps/shell`
- Apps verticales: `apps/<dominio>` (crm, pos, restaurante, ventas, compras, inventario, logistica, flota, manufactura, nomina, contabilidad, bancos, ecommerce, auditoria, shipping, report-studio, lab, panel)
- Paquetes: `packages/*`

## Objetivo

Permitir evolución por módulos de negocio sin acoplar toda la app en un único frontend monolítico.

## Paquetes

- `shared-auth` — cookies httpOnly, JWT, scope por tenant.
- `shared-ui` — design system Zentto (ver [DESIGN-SYSTEM.md](./DESIGN-SYSTEM.md) y `packages/shared-ui/DESIGN.md`).
- `shared-api` — cliente TanStack Query + SDK REST generado.
- `shared-i18n` — i18n multi-locale.
- `shared-reports` — layouts de `zentto-report` centralizados.
- `module-admin`, `module-auditoria`, `module-bancos`, `module-compras`, `module-contabilidad`, `module-crm`, `module-ecommerce`, `module-flota`, `module-inventario`, `module-logistica`, `module-manufactura`, `module-nomina`, `module-pos`, `module-restaurante`, `module-shipping`.

## Scripts

Desde `web/modular-frontend`:

- `npm run dev:shell`
- `npm run build:shell`
- `npm run start:shell`

## Estrategia de convivencia

- El `web/frontend` sigue siendo la referencia operativa principal.
- `modular-frontend` se usa para migrar capacidades por dominio sin interrupción.
- Compartir auth, UI y cliente API evita duplicación de lógica transversal.

---

## Rediseño CRM 2026-Q2

Desde 2026-Q2 el módulo CRM es el primer consumidor del design system v2 (tokens + `RightDetailDrawer` + `CommandPalette` + `ZenttoRecordTable` + `SavedViewsBar`). Los patrones introducidos aquí son obligatorios para cualquier app/módulo nuevo y se migran gradualmente al resto del ERP.

### Referencias de diseño y arquitectura

- **Design Brief** — `docs/wiki/design-audits/2026-04-19-crm.md` (hallazgos + propuesta visual).
- **Integration Review** — `docs/wiki/design-audits/2026-04-19-crm-integration.md` (impacto cross-módulo).
- **ADR-CRM-001** — [../adr/ADR-CRM-001-entities-model.md](../adr/ADR-CRM-001-entities-model.md) — modelo `Contact` / `Company` / `Deal` aprobado (B+B).
- **DESIGN.md base** — `web/modular-frontend/packages/shared-ui/DESIGN.md` (CRM-101).
- **DESIGN.md CRM** — `web/modular-frontend/apps/crm/DESIGN.md` (overlay específico, este issue).
- **Modelo de entidades** — [15-crm-entities-model.md](./15-crm-entities-model.md).
- **Design system overlay** — [DESIGN-SYSTEM.md](./DESIGN-SYSTEM.md).

### Patrones nuevos

| Patrón | Ubicación | Responsabilidad |
|---|---|---|
| `RightDetailDrawer` | `@zentto/shared-ui` | Panel lateral 480 px (desktop) / fullscreen (mobile) con tabs Overview/Activity/Notes/Files/Related. Abrir un registro NO saca al usuario de la lista. Deep-link via `?id=<uuid>`. |
| `CommandPalette` | `@zentto/shared-ui` | `Cmd/Ctrl-K` global. Fuzzy search cross-entity sobre registros recientes + acciones + navegación. Basado en `cmdk` envuelto en MUI. |
| `ZenttoRecordTable` | `@zentto/shared-ui` | Wrapper React sobre `<zentto-grid>` con toolbar integrado: density toggle, saved views dropdown, bulk action bar sticky, empty/loading/error states consistentes. |
| `SavedViewsBar` | `@zentto/shared-ui` + API `/v1/saved-views` (CRM-108) | Vistas guardadas por usuario: filtros + columnas visibles + orden + densidad. Shared/private. Estado reflejado en URL. |
| `FormDialog` | `@zentto/shared-ui` | Dialog estándar para crear/editar con `Cmd-Enter` save / `Esc` cancel. Reemplaza cualquier `Dialog` MUI crudo. |

### Atajos de teclado globales

Todos los módulos del ERP que usan el nuevo design system respetan estos shortcuts:

| Atajo | Acción | Contexto |
|---|---|---|
| `Cmd/Ctrl-K` | Abrir `CommandPalette` | Global |
| `C` | Quick-create del registro primario de la página | Página de lista |
| `J` / `K` | Navegar fila abajo / arriba | Lista con focus en `ZenttoRecordTable` |
| `Enter` | Abrir `RightDetailDrawer` de la fila seleccionada | Lista |
| `Esc` | Cerrar drawer / dialog / palette | Global |
| `Cmd/Ctrl-Enter` | Guardar formulario | `FormDialog` abierto |
| `?` | Mostrar cheat sheet de atajos | Global |
| `/` | Focus en quick search de la lista | Lista |
| `[` / `]` | Prev / next pipeline stage (Kanban) | Módulo CRM / Deals |
| `G` + `L` / `D` / `C` | Go to Leads / Deals / Contacts | Módulo CRM |
| `Shift+D` | Rotar densidad (compact ↔ default ↔ comfortable) | Lista |

### Densidades del grid

Persistidas por usuario vía `useGridLayoutSync`. Tokens en `@zentto/shared-ui` → `token.density.rowHeight`.

| Modo | Alto fila (px) | Target device | Default |
|---|---|---|---|
| `compact` | 28 | Mobile / operador POS | `xs` |
| `default` | 36 | Desktop (1200–1536 px) | `sm` / `md` / `lg` |
| `comfortable` | 46 | Monitores 4K / auditoría | `xl` |

Toggle visible en toolbar del `ZenttoRecordTable` (`DensityToggle`). Atajo `Shift+D` rota entre modos.

### Migración obligatoria

El rediseño CRM introduce tres refactors que aplican a **todas** las apps y módulos:

1. **`<table>` HTML → `<ZenttoDataGrid>` / `<ZenttoRecordTable>`**
   Ningún componente nuevo puede introducir `<table>` nativo ni `MUI DataGrid`. Reglas: `feedback_no_html_tables` + `feedback_zentto_datagrid_standard`. Legado ERP pendiente de migración se documenta en `docs/wiki/design-audits/` cuando aplique.

2. **`Dialog` MUI crudo → `FormDialog`**
   Cualquier creación/edición de registro usa `FormDialog` + `FormGrid` + `FormField`. Esto garantiza footer consistente, loading state, toasts de éxito/error y atajos `Cmd-Enter` / `Esc`. Revisar en PR de cualquier módulo: si se ve `<Dialog open=` nuevo para un CRUD, rechazar.

3. **Lista → navegación → detalle → volver** reemplazado por `RightDetailDrawer`
   La ruta `/<entidad>/<id>` se mantiene como deep-link, pero el comportamiento por defecto al hacer click en una fila es abrir el drawer (no hacer `router.push`). Esto preserva scroll, selección y filtros aplicados.

### Roadmap de adopción

| Fase | Alcance | Issues |
|---|---|---|
| Fase 1 (actual) | Módulo CRM completo + `shared-ui` v2 | `CRM-101`..`CRM-114` |
| Fase 2 | Apps verticales (hotel, medical, tickets, education, inmobiliario) | backlog |
| Fase 3 | Módulos ERP core (ventas, compras, inventario, contabilidad) | backlog |
| Fase 4 | Audit accesibilidad AA + cheat sheet `?` global | backlog |

Detalle de issues y ADR en [6. Playbook Agentes IA](./06-playbook-agentes.md) y [`docs/adr/`](../adr/).
