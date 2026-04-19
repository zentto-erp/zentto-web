# Zentto CRM Design

> Overlay del design system base de Zentto. Fuente de verdad para tokens y
> componentes compartidos: `packages/shared-ui/DESIGN.md`.
> Formato: Google Stitch / design.md
> (https://github.com/VoltAgent/awesome-design-md ·
> https://stitch.withgoogle.com/docs/design-md/overview/).

---

## 1. Identidad

**Zentto CRM** es el módulo comercial del ERP Zentto. SaaS B2B multi-tenant
pensado para equipos comerciales (SDR, Account Executive, Sales Manager) y
dueños de PYME que operan el pipeline de ventas dentro del mismo producto donde
facturan, cobran e integran contabilidad.

- **Audiencia**: comerciales que viven en el CRM 6-8 horas al día.
- **Tono**: preciso, data-first, amable. Sin lenguaje de marketing interno.
- **Unidad de trabajo**: el **Deal**. Todo se mira desde el Deal (o desde el
  Contact que lo abrió). No hay dashboards que no lleven eventualmente a un
  Deal con acción concreta.

---

## 2. Casos de uso primarios

1. **Prospect capture** — captar leads desde landing, import CSV, API pública,
   formulario manual. Un lead llega, se enriquece (Contact + Company), queda
   en `NEW` con owner SDR y entra a la cola de contacto.
2. **Lead qualification** — SDR recorre la cola, registra actividades
   (llamada/email/reunión), mueve el estado `NEW → CONTACTED → QUALIFIED`
   o `DISQUALIFIED`. Desde `QUALIFIED` convierte a Deal.
3. **Deal pipeline management** — Account Executive mueve Deals por el
   Kanban del pipeline (drag-drop), registra actividades, adjunta
   documentos, cierra `WON` o `LOST`.
4. **Account management** — ver todas las Companies, drilldown a sus
   Contacts, historial de Deals ganados/perdidos, próximas renovaciones.
5. **Forecast y reporting** — sales manager revisa velocity por stage,
   tasa de conversión del funnel, valor pipeline por mes, ranking por vendedor.
6. **Cross-sell / upsell** — un Contact con Deal WON puede abrir otro Deal
   con productos diferentes; se respeta el ciclo B2B recurrente.

---

## 3. Referentes

Citados como inspiración directa del rediseño:

- **HubSpot Smart CRM** — modelo Company → Contact → Deal, drawer lateral
  con tabs Overview/Activity/Notes/Files, command palette global.
  https://designers.hubspot.com/
- **Linear** — command palette `Cmd-K`, atajos teclado agresivos, densidad
  baja, URLs compartibles. https://linear.app/method
- **Pipedrive** — Deal-first en el pipeline, drag-drop con probabilidad por
  stage, forecast simple.
- **Attio** — RecordTable como unidad universal, filtros como ciudadanos de
  primera clase, saved views nominadas.
- **Salesforce** — flujo Lead → Opportunity conversion (referencia conceptual,
  no visual).

Cuando el referente tenga DESIGN.md público en awesome-design-md, se linkea
ahí directamente; hoy la mayoría tienen solo guías visuales / blog posts.

---

## 4. Componentes protagonistas

Todos vienen de `@zentto/shared-ui`. Este overlay solo documenta cómo los
consume el CRM.

| Componente | Uso en CRM |
|---|---|
| `ZenttoRecordTable` | Listas de Leads, Contacts, Companies, Deals, Activities. Columnas por defecto documentadas en el código del módulo. |
| `RightDetailDrawer` | Estándar para abrir cualquier registro. Tabs: **Overview** (campos clave), **Activity** (timeline), **Deals** (si es Contact/Company), **Notes**, **Files**, **Related** (cross-entity). |
| `PipelineKanban` | Vista principal de Deals agrupados por stage. Drag-drop entre stages emite evento `deal.stage.changed` + registra en `DealHistory`. |
| `CommandPalette` | `Cmd-K`. Secciones: **Go to** (navegación), **Create** (Lead/Contact/Company/Deal), **Recent** (últimos registros vistos), **Actions** (convertir lead, cerrar deal, reasignar owner). |
| `SavedViewsBar` | En cada lista. Vistas default: "Mis leads", "Deals abiertos > 30 días", "Companies sin activity 60 días". Personalizables. |
| `FormDialog` + `FormGrid` | Crear/editar Lead, Contact, Company, Deal, Activity. Nunca `Dialog` MUI crudo. |
| `DashboardKpiCard` + `DashboardSection` | Dashboard del módulo: KPIs (MRR pipeline, deals won month, conversion rate) + secciones colapsables (Funnel, Velocity, Rankings). |

---

## 5. Flujos clave

### 5.1 Prospect → Deal (primary flow)

```
Landing/Import → POST /v1/leads (tenant scope)
   └─ SP: usp_crm_Lead_Create
       ├─ match Contact por email/phone → crea si no existe
       ├─ match Company por Contact.Email.domain → crea si no existe
       └─ Lead.LeadStatus = NEW, OwnerAgentId = round-robin SDR queue

UI Leads List → click fila → RightDetailDrawer (Overview tab)
   └─ SDR registra actividad con botón primario "Log call / email / meeting"
   └─ cambia LeadStatus con dropdown (NEW → CONTACTED → QUALIFIED)

Desde QUALIFIED → botón primario drawer "Convert to Deal"
   └─ FormDialog "Convertir Lead a Deal" (prefill Contact/Company, pipeline default)
   └─ POST /v1/deals con ConvertedFromLeadId
   └─ Lead.LeadStatus = CONVERTED, ConvertedToDealId = <new>
   └─ Toast éxito + deep-link al drawer del Deal
```

### 5.2 Command palette (Cmd-K)

```
Cmd-K → CommandPalette abierto (backdrop + input con focus)
   ↳ escribir "acm" → fuzzy match cross-entity:
      ▸ Go to — Acme Corp (Company)
      ▸ Contact — John @ Acme
      ▸ Deal — Acme onboarding, $12k
   ↳ ↑ ↓ navega, Enter abre en drawer (no navega fuera)
   ↳ Tab cambia a modo "Create" o "Actions"
```

### 5.3 Quick-create con `C`

```
Lista de Leads + focus en el grid → tecla C
   └─ FormDialog "Nuevo Lead" abre con campos mínimos (Nombre, Email, Source)
   └─ Cmd-Enter guarda y abre drawer del nuevo Lead para continuar
```

### 5.4 Bulk actions

```
Lista + seleccionar N filas via checkbox
   └─ BulkActionBar aparece sticky bottom
   └─ Acciones: Reasignar owner · Cambiar estado · Exportar · Enviar email
   └─ Confirmación via ConfirmDialog con N en el mensaje
```

### 5.5 Pipeline Kanban drag-drop

```
Drag Deal card → soltar en stage destino
   └─ Optimistic update + POST /v1/deals/:id/stage
   └─ Server: SP usp_crm_Deal_ChangeStage inserta DealHistory + recalcula probability
   └─ Evento emitido: deal.stage.changed (→ event bus → automations)
   └─ ARIA live: "Deal movido a <stage>"
```

---

## 6. Atajos contextuales del CRM

Extienden los atajos globales de `packages/shared-ui/DESIGN.md` §2. Solo se
listan aquí los específicos del módulo.

| Atajo | Acción |
|---|---|
| `G` + `L` | Go to Leads list |
| `G` + `D` | Go to Deals list |
| `G` + `C` | Go to Contacts list |
| `G` + `O` | Go to Companies (Organizations) |
| `G` + `P` | Go to Pipeline Kanban |
| `[` / `]` | Mover Deal focus al stage anterior / siguiente (Kanban) |
| `W` | Marcar Deal seleccionado como WON (pide confirmación) |
| `X` | Marcar Deal seleccionado como LOST (pide razón) |
| `N` | Nueva Activity sobre el registro abierto en el drawer |

---

## 7. Colores semánticos

Extienden `token.color` del base. Resolver siempre en runtime vía
`theme.palette[paletteKey].main` para respetar dark mode y branding por tenant.

```ts
token.color.lead = {
  NEW:          { paletteKey: 'info'    },   // azul neutro
  CONTACTED:    { paletteKey: 'primary' },   // cálido acción pendiente
  QUALIFIED:    { paletteKey: 'warning' },   // listo para convertir
  DISQUALIFIED: { paletteKey: 'grey'    },   // archivado
  CONVERTED:    { paletteKey: 'success' },   // cerrado positivo
};

token.color.deal = {
  open: { paletteKey: 'primary' },
  won:  { paletteKey: 'success' },
  lost: { paletteKey: 'error'   },
};

token.color.priority = {
  urgent: { paletteKey: 'error'   },
  high:   { paletteKey: 'error'   },
  medium: { paletteKey: 'warning' },
  low:    { paletteKey: 'info'    },
};
```

Warm neutral: usado en chips de `Lead.NEW` como tono *warm grey* (no frío)
para no competir visualmente con estados accionables (CONTACTED/QUALIFIED).

---

## 8. Responsive / breakpoints

Hereda los breakpoints del base. Overrides del CRM:

| Breakpoint | Pipeline Kanban | RecordTable |
|---|---|---|
| `xs` (0+) | Single-column list por stage (drawer con selector de stage) | `compact` |
| `sm` / `md` (600+) | Kanban 2 columnas scroll horizontal | `default` |
| `lg` (1200+) | Kanban N columnas visibles + drawer overlay 480 px | `default` |
| `xl` (1536+) | Kanban N columnas + drawer persistente | `comfortable` |

En `xs` el `RightDetailDrawer` ocupa fullscreen y el back button del browser
lo cierra.

---

## 9. Empty states

| Vista | Ilustración ligera | Copy |
|---|---|---|
| Leads vacío | funnel con 1 bolita | "Aún no hay leads. Importa desde CSV o conecta un formulario." |
| Deals vacío | pipeline de 3 stages | "Sin deals. Califica un lead para abrir el primero." |
| Contacts vacío | persona silueta | "Sin contactos. Se crean automáticamente cuando llega un lead." |
| Companies vacío | edificio | "Sin empresas. Se crean automáticamente cuando un Contact tiene email corporativo." |
| Activity timeline vacío | reloj | "Sin actividades. Registra la primera llamada o email." |

Cada empty state tiene **CTA primario** (crear) + **link secundario** (importar / conectar API / abrir docs).

---

## 10. Anti-patrones específicos CRM

Además de los del base (`<table>`, MUI DataGrid, Dialog crudo, fontSize literal):

- **Nunca** mezclar Lead y Deal en la misma lista. Son entidades distintas tras el rediseño.
- **Nunca** navegar fuera de la lista para ver detalle — siempre `RightDetailDrawer`.
- **Nunca** permitir avanzar un Lead a Deal sin pasar por `QUALIFIED`.
- **Nunca** borrar un Deal con `WON`. Archivar sí; borrar rompe reporting histórico.
- **Nunca** mostrar Probability editable manualmente — la dicta el stage (salvo override explícito por sales manager).

---

## 11. Referencias

- Base: [`packages/shared-ui/DESIGN.md`](../../packages/shared-ui/DESIGN.md).
- Modelo entidades: [`docs/wiki/16-crm-entities-model.md`](../../../../docs/wiki/16-crm-entities-model.md).
- ADR aprobado: [`docs/adr/ADR-CRM-001-entities-model.md`](../../../../docs/adr/ADR-CRM-001-entities-model.md).
- Patrones UI ecosistema: [`docs/wiki/04-modular-frontend.md`](../../../../docs/wiki/04-modular-frontend.md).
- Design audits (en creación): `docs/wiki/design-audits/2026-04-19-crm.md`, `2026-04-19-crm-integration.md`.
- awesome-design-md: https://github.com/VoltAgent/awesome-design-md
- Google Stitch format: https://stitch.withgoogle.com/docs/design-md/overview/
- HubSpot Designers: https://designers.hubspot.com/
- Linear Method: https://linear.app/method
- Pipedrive: https://www.pipedrive.com/
- Attio: https://attio.com/
