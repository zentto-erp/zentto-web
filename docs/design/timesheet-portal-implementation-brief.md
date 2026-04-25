# Design Brief — Zentto Timesheet Portal (implementación frontend)

> Versión: 2026-04-23 · Autor: zentto-designer · Estado: Propuesta para implementación.
> Ámbito: `zentto-timesheet/frontend/` (Next.js App Router standalone) + ampliación `@zentto/shared-ui` + `@zentto/design-tokens` + nuevo package `@zentto/timesheet-ui` (scope modular).
> Complementa: [`timesheet-carga-laboral-brief.md`](./timesheet-carga-laboral-brief.md) (ADR conceptual). Este documento es el **plan ejecutable**.

---

## TL;DR (leer primero)

- **Stack**: Next.js 14 App Router + TS ESM + MUI v5 + `@zentto/shared-ui` + `@zentto/timesheet-client@0.1.0` + Recharts + TanStack Query v5.
- **Repo único**: el portal vive en `zentto-timesheet/frontend/` (patrón igual a `zentto-hotel/frontend/` + `zentto-notify/dashboard/`), **no** dentro del monorepo ERP.
- **4 personas, 3 shells**: empleado (`/` con `ZenttoVerticalLayout`), manager (mismo shell, navegación adicional), gerencia/RRHH (mismo shell), **kiosko `/kiosko` sin shell** (full-screen touch).
- **Componentes nuevos** (todos reutilizables): `ZenttoClockButton`, `ZenttoStatusChip`, `ZenttoTimeKiosk`, `ZenttoFavoritesPicker`, `ZenttoTimesheetMatrix`, `ZenttoWeekAgendaCalendar`, `ZenttoBarChart`, `ZenttoLineChart`, `ZenttoDayDetailTimeline`, `ZenttoKpiDeltaCard` (wrapper de `DashboardKpiCard` para delta).
- **Migración goose pendiente**: `00010_kiosk_pin.sql` (tabla `ts.KioskPin` + SPs `usp_TS_KioskPin_Set|Verify|Rotate|Disable`).
- **Orden de PRs**: shared-ui PR batch (chart+kiosk+matrix+favoritepicker) → auth shell → empleado dashboard+clockIn → día → período → rápido → semana → aprobaciones → carga-laboral → kiosko → reportes → perfil.
- **Reglas de oro**: sin `<table>` HTML jamás, sin mocks, cookie httpOnly, UTC-0 en storage, mobile-first, acordeones en dashboards grandes, i18n ES canónico.
- **Dominio dev**: `https://timesheetdev.zentto.net` → API `https://timesheetapidev.zentto.net`. Prod: `timesheet.zentto.net` → `timesheetapi.zentto.net`.

---

## 1. Matriz rutas × personas × permisos

Roles resueltos desde `zentto-auth` (`/me` devuelve `roles: string[]` por tenant). Convención de roles propuesta:

| Código | Nombre | Descripción |
|---|---|---|
| `ts.employee` | Empleado | Ficha, registra horas propias, envía a aprobación |
| `ts.manager` | Manager/Supervisor | Además, aprueba/rechaza hojas de su equipo |
| `ts.hr` | RRHH/Gerencia | Dashboard ejecutivo, reportes, exportar |
| `ts.admin` | Admin | Configurar calendarios, turnos, rotar PINs |
| `ts.kiosk` | Kiosko | Sesión anónima compartida en terminal físico |

### Matriz principal

| Ruta | Persona principal | Roles requeridos | Shell | Finalidad |
|---|---|---|---|---|
| `/login` | Todos | Anónimo | `auth-shell` | SSO (redirect a `auth.zentto.net` con `return_to`) |
| `/` | Empleado | `ts.employee` | `ZenttoVerticalLayout` | Dashboard personal: estado, clock, favoritos, últimas entries |
| `/tiempos` | Empleado | `ts.employee` | `ZenttoVerticalLayout` | Tabs Periodo/Rápido/Semana/Día |
| `/tiempos/nuevo` | Empleado | `ts.employee` | `ZenttoVerticalLayout` | Formulario nueva entry con favorites picker |
| `/tiempos/serie` | Empleado | `ts.employee` | `ZenttoVerticalLayout` | Registro en serie (rango fechas + plantilla) |
| `/tiempos/[id]` | Empleado | `ts.employee` (owner) o `ts.manager` | `ZenttoVerticalLayout` | Detalle + acciones Editar/Borrar/Copiar/PDF/Submit |
| `/favoritos` | Empleado | `ts.employee` | `ZenttoVerticalLayout` | CRUD de favoritos propios |
| `/kiosko` | Kiosko | `ts.kiosk` (session anónima) | **Sin shell** | Touch grande, auth por PIN, timeout 30s |
| `/aprobaciones` | Manager | `ts.manager` | `ZenttoVerticalLayout` | Bandeja bulk approve/reject con filtros |
| `/aprobaciones/[id]` | Manager | `ts.manager` | `ZenttoVerticalLayout` | Revisión detallada de una hoja |
| `/carga-laboral` | Gerencia/RRHH | `ts.hr` o `ts.manager` | `ZenttoVerticalLayout` | Dashboard ejecutivo con acordeones |
| `/reportes` | Empleado + Manager + RRHH | Según alcance | `ZenttoVerticalLayout` | Descargar PDF mensual, exportar Excel |
| `/perfil` | Todos autenticados | Cualquier rol `ts.*` | `ZenttoVerticalLayout` | Cambiar password SSO, rotar PIN kiosko |
| `/api/auth/*` | Middleware | — | — | Proxy a `auth.zentto.net` (SSR + refresh) |
| `/api/kiosk/*` | Middleware | — | — | Proxy autenticado a endpoints PIN |

### Reglas de acceso por componente

- **Menú lateral** (`ZenttoVerticalLayout.navigationFields`) filtra items según roles. `useSession()` de `@zentto/auth-client` hidrata el estado.
- **`/aprobaciones`** y **`/carga-laboral`** → middleware Next.js redirige a `/` si el usuario no tiene rol.
- **`/kiosko`** → middleware **bloquea** entrar con sesión de empleado (para evitar confusión); sólo sirve con cookie vacía o session `ts.kiosk`. Entrada explícita via `https://timesheet.zentto.net/kiosko`.

---

## 2. Wireframes por pantalla

### 2.1 `/login`

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              [Logo Zentto Timesheet]                        │
│                                                             │
│      Inicia sesión con tu cuenta Zentto                     │
│                                                             │
│   ┌──────────────────────────────────────────────┐          │
│   │ Email corporativo                            │          │
│   │ [raul@empresa.com                      ]    │          │
│   │ Contraseña                                   │          │
│   │ [••••••••••••                         ] 👁   │          │
│   │                                              │          │
│   │ [ ✅ Recordarme 30 días ]                   │          │
│   │                                              │          │
│   │ [    Iniciar sesión     ]                    │          │
│   │                                              │          │
│   │ ¿Acceso a kiosko? → /kiosko                 │          │
│   └──────────────────────────────────────────────┘          │
│                                                             │
│                                          v1.0.0             │
└─────────────────────────────────────────────────────────────┘
```

- **SDK**: `@zentto/auth-client` → `login({ email, password })`. Si devuelve `mfaChallenge`, modal con código.
- **Loading**: botón con `<CircularProgress size={18}/>`.
- **Error**: `<Alert severity="error">Credenciales inválidas.</Alert>` bajo el formulario.
- **Empty**: N/A.
- **Mobile**: card full-width con padding lateral 16px.

### 2.2 `/` — Dashboard empleado

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ZenttoVerticalLayout (sidebar colapsable + topbar)                               │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Hola, María · Jueves 23 Abr 2026 · Madrid (UTC+2)         [🔔 3]  [👤 perfil ▼]  │
│                                                                                  │
│ ┌─ Estado actual ────────────────────────────────────────────────────────────┐   │
│ │ [🟢 PRESENTE]       Entrada: 08:42    Trabajado hoy: 5h 32m               │   │
│ │                                                                           │   │
│ │  ┌──────────────────────┐  ┌─────────────────┐                            │   │
│ │  │                      │  │                 │                            │   │
│ │  │   ⏹   FICHAR SALIDA  │  │  ⏸   PAUSA      │                            │   │
│ │  │                      │  │                 │                            │   │
│ │  └──────────────────────┘  └─────────────────┘                            │   │
│ │  (ZenttoClockButton variant=danger | ZenttoClockButton variant=warning)   │   │
│ └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│ ┌─ KPIs del mes ─────────────────────────────────────────────────────────────┐   │
│ │ ┌─────────────┬─────────────┬─────────────┬─────────────┐                 │   │
│ │ │ Trabajado   │ Extras      │ Saldo mes   │ Pend. aprob │                 │   │
│ │ │ 122h 15m    │ 2h 30m      │ +1h 45m ▲  │ 3 hojas     │                 │   │
│ │ │ /168h prev. │ sobre 0h    │ vs previsto │             │                 │   │
│ │ └─────────────┴─────────────┴─────────────┴─────────────┘                 │   │
│ │ (4× DashboardKpiCard con trend)                                           │   │
│ └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│ ┌─ Imputa rápido ────────────────────────────────────────────────────────────┐   │
│ │ Favoritos:                                                                 │   │
│ │ [⭐ CRM · Backend    +1h]  [⭐ Hotel · Fase2  +1h]  [⭐ Ticket #1234 +0.5h]  │   │
│ │ [⭐ Soporte interno  +1h]  [+ Añadir favorito]                              │   │
│ │ (ZenttoFavoritesPicker horizontal)                                         │   │
│ └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│ ┌─ Últimas 10 entradas ──────────────────────────────────────────────────────┐   │
│ │ [ZenttoRecordTable con columnas:                                           │   │
│ │  Fecha · Inicio · Fin · Proyecto · Horas · Estado · Acciones]              │   │
│ │  23/04 · 13:05 · 15:20 · 🟦 CRM Backend    · 2h 15m · 📝 Borrador  · [✏]  │   │
│ │  23/04 · 08:42 · 12:30 · 🟦 CRM Backend    · 3h 48m · 📝 Borrador  · [✏]  │   │
│ │  22/04 · 09:15 · 17:30 · 🟩 Hotel Fase2    · 7h 45m · ✓ Aprobado  · [👁]  │   │
│ │  ...                                                                       │   │
│ └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│ [Ver todas mis entradas →] [Enviar borradores a aprobación]                      │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK calls**:
  - `attendance.todaySummary()` → estado chip + hora entrada + trabajado.
  - `dashboards.workload({ employeeId, month })` filtered self → KPIs del mes.
  - `timeEntries.list({ employeeId, limit:10, orderBy:'-date' })` → tabla.
  - `favorites.list()` → chips.
- **Loading**: skeletons por sección (cards, tabla).
- **Empty**:
  - Sin clock-in hoy → botón único `ZenttoClockButton variant="primary"` "FICHAR ENTRADA".
  - Sin entries → empty state de `ZenttoRecordTable` con CTA "Crear primer registro".
- **Error**: `<Alert severity="error">` por sección con retry.
- **Mobile (375px)**: una columna, clock button full-width, KPIs en grid 2×2, favoritos scroll horizontal, tabla colapsa a cards (opción compact de `ZenttoRecordTable` o fallback a lista custom).

### 2.3 `/tiempos` — Registro de tiempos con tabs

El wireframe completo ya está en [`timesheet-carga-laboral-brief.md §4`](./timesheet-carga-laboral-brief.md). Resumen aplicado al portal:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Registro de tiempos"                                       │
│   [Jue 23 Abr] [Semana 17 ▼]   ●●●   [+ Nuevo] [📄 PDF mes] [Enviar aprobación] │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ZenttoStatusChip bar (4 chips): Entrada · Pausa · Trabajado · Saldo              │
├──────────────────────────────────────────────────────────────────────────────────┤
│ [📅 Periodo] [⚡ Rápido] [🗓 Semana] [🕐 Día]  ← MUI Tabs, default según bp        │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   Render condicional por tab (§2.3.1–§2.3.4)                                    │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.3.1 Tab `Periodo`

Idéntico a `§4.2.1` del brief conceptual. Implementado con `<ZenttoRecordTable>` listando días del mes con columnas: Día · Previsto · Asistencia · Proyecto · Saldo · Estado · Acciones. Fila con `saldo < 0` en `alpha(error.main, 0.06)` + chip `<ZenttoStatusChip status="late">`.

- **SDK**: `dashboards.monthAgg({ employeeId, year, month })` + `timeEntries.list({ employeeId, from, to })`.
- **Mobile**: cards apiladas por día en lugar de grid horizontal.

#### 2.3.2 Tab `Rápido` — matriz semanal editable

Idéntico a `§4.2.2` + `§5.3` del brief conceptual. **Implementación real**: componente nuevo `ZenttoTimesheetMatrix` (renombrado de `ZenttoTimesheetGrid` para no confundir con `ZenttoDataGrid`).

- **SDK**: `timeEntries.list({ employeeId, weekStart })` para cargar filas; `timeEntries.save()` con debounce 800ms por celda.
- **Auto-save badge**: header derecha "Guardado · 14:12" usando `AppBarWrapper` slot.
- **Mobile**: fallback a vista lista por día (tab "Día") — la matriz no es usable <768px.

#### 2.3.3 Tab `Semana` — calendario agenda

Idéntico a `§4.2.3`. **Implementación real**: componente nuevo `ZenttoWeekAgendaCalendar` (wrapper de `@mui/x-date-pickers` extendido + drag logic custom — NO usamos FullCalendar porque licencia restrictiva y bundle grande).

Alternativa considerada y descartada: `react-big-calendar` (MIT, ~80KB). **Ventaja**: featureful. **Desventaja**: no sigue MUI, requiere override de estilos significativo.

**Decisión**: build desde cero encima de MUI usando CSS Grid (columnas días, filas horas). Custom code ~400 líneas — trazable y mantenible.

- **SDK**: `timeEntries.list({ employeeId, weekStart, weekEnd })`.
- **Drag-to-create**: mousedown + mousemove + mouseup detecta bloque; abre `RightDetailDrawer` para completar.
- **Mobile**: degrada a slider swipeable día-por-día (mismo render que tab `Día`).

#### 2.3.4 Tab `Día` — detalle cronológico

Idéntico a `§4.2.4`. **Implementación real**: componente nuevo `ZenttoDayDetailTimeline` (lista vertical con `<List>` + conectores entre items usando CSS pseudo-elementos).

- **SDK**: `timeEntries.list({ employeeId, date })`.
- **Crear desde aquí**: botón fixed bottom-right en mobile (FAB MUI); inline `+ Añadir registro` en desktop.

### 2.4 `/tiempos/nuevo`

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Nuevo registro"   [← Volver]                               │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ Usar un favorito (atajo) ───────────────────────────────────────────────┐     │
│ │ (ZenttoFavoritesPicker horizontal)                                        │     │
│ │ [⭐ CRM Backend] [⭐ Hotel F2] [⭐ Ticket #1234] [+ Favorito]              │     │
│ └──────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│ O crea uno nuevo:                                                                │
│ ┌─ FormGrid ───────────────────────────────────────────────────────────────┐     │
│ │ Fecha *              [23/04/2026  📅]   Tipo *   [🔘 Proyecto  ⚪ Ausencia]│     │
│ │ Proyecto *           [Autocomplete… ]   Fase    [Autocomplete… ]          │     │
│ │ Servicio             [Autocomplete… ]   Actividad [Autocomplete… ]        │     │
│ │ Inicio               [08:42      ]      Fin     [12:30     ]   = 3h 48m  │     │
│ │ O introduce horas    [3.80 h]            (no rango)                        │     │
│ │ Notas                [TextArea md…                                      ] │     │
│ │                                                                           │     │
│ │ [ ⬜ Guardar también como favorito para próximos días ]                    │     │
│ └──────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│ [Cancelar]                       [Guardar borrador]  [Guardar y enviar aprob.]   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `timeEntries.save({ …dto })` + opcional `favorites.save(...)`.
- **Catálogos**: `contexts.projects()`, `contexts.phases(projectId)`, `contexts.services()`, `contexts.activities()` — **sin mock**, todo del SDK.
- **Validation**: Zod inline + server (return shape `{ ok, mensaje }`).

### 2.5 `/tiempos/serie`

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Registro en serie"                                         │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ Paso 1/3 · Rango de fechas ─────────────────────────────────────────────┐     │
│ │ Desde *   [01/04/2026 📅]       Hasta *   [30/04/2026 📅]                 │     │
│ │ [ ☑ Solo días laborables (L-V)]                                           │     │
│ │ [ ☑ Excluir festivos del calendario "España-Madrid"]                      │     │
│ │ Previsualización: 22 días se generarán                                    │     │
│ └──────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│ ┌─ Paso 2/3 · Plantilla ────────────────────────────────────────────────────┐    │
│ │ Proyecto *   Fase   Servicio   Horas/día *   Notas                        │    │
│ │ [...]        [...]  [...]       [8.0]         [...]                        │    │
│ │ [+ Añadir línea]                                                           │    │
│ └──────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│ ┌─ Paso 3/3 · Confirmación ─────────────────────────────────────────────────┐    │
│ │ Se crearán 22 registros × 1 línea = 22 entries totales.                   │    │
│ │ Estado inicial: ◉ Borrador · ○ Enviar a aprobación directamente           │    │
│ │ Colisiones detectadas: 0 (ningún día tiene horas existentes)              │    │
│ └──────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│ [← Atrás]                                          [Generar serie (22 entries)]  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **Componente base**: `CustomStepper` (ya existe). 3 pasos.
- **SDK**: `timeEntries.series({ from, to, filter, template, action })`.
- **Colisiones**: fetch dry-run opcional — si el endpoint no lo soporta aún, mostrar `<Alert severity="info">Los registros existentes no se sobrescribirán.</Alert>`.

### 2.6 `/tiempos/[id]`

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Registro #a3f9" · Jue 23 Abr · 13:05-15:20                │
│   [✏ Editar] [📋 Copiar] [🗑 Borrar] [📄 PDF] [↑ Enviar]                         │
├──────────────────────────────────────────────────────────────────────────────────┤
│ CustomStepper: ● Borrador — ◯ Pendiente — ◯ Aprobado                             │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ Detalle ─────────────────────────────────┐  ┌─ Historial ──────────────┐      │
│ │ Proyecto   🟦 CRM · Migración              │  │ 23/04 13:05  Creado (MA)│      │
│ │ Servicio   Backend                         │  │ 23/04 13:07  Editado    │      │
│ │ Actividad  Code review                     │  └─────────────────────────┘      │
│ │ Horas      2h 15m                          │                                    │
│ │ Notas      Review de 3 PRs pendientes…    │                                    │
│ │ GPS        📍 Madrid (40.41, -3.70)       │                                    │
│ └───────────────────────────────────────────┘                                    │
│                                                                                  │
│ [Volver a la lista]                                                              │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `timeEntries.get(id)`, `timeEntries.delete(id)`, `timeEntries.copy(id, { to })`, `validation.act({ entries, action })`, `reports.timesheetPdf(...)`.

### 2.7 `/favoritos`

Lista + CRUD con `ZenttoRecordTable`:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Mis favoritos                                                    [+ Nuevo]       │
├──────────────────────────────────────────────────────────────────────────────────┤
│ [ZenttoRecordTable]                                                              │
│ Etiqueta          · Proyecto      · Horas def · Uso (30d) · Acciones             │
│ ⭐ CRM Backend    · CRM · Migr.   · 1h        · 48 veces  · [✏][🗑][↕]          │
│ ⭐ Hotel F2       · Hotel · F2    · 1h        · 22 veces  · [✏][🗑][↕]          │
│ ⭐ Ticket #1234   · Ticket        · 0.5h      · 12 veces  · [✏][🗑][↕]          │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `favorites.list()`, `favorites.save(dto)`, `favorites.delete(id)`.
- Drag handle `↕` reordena (campo `orderIndex` persistido).

### 2.8 `/kiosko` — Pantalla touch compartida

#### 2.8.1 Paso 1 · Login por PIN

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                                                                  │
│                                     14:23:07                                     │
│                                Jueves 23 Abril 2026                              │
│                                                                                  │
│                             Introduce tu PIN                                     │
│                                                                                  │
│                             ┌─────┬─────┬─────┐                                  │
│                             │  ●  │  ●  │     │                                  │
│                             └─────┴─────┴─────┘                                  │
│                                                                                  │
│                     ┌─────┐   ┌─────┐   ┌─────┐                                  │
│                     │  1  │   │  2  │   │  3  │                                  │
│                     ├─────┤   ├─────┤   ├─────┤                                  │
│                     │  4  │   │  5  │   │  6  │                                  │
│                     ├─────┤   ├─────┤   ├─────┤                                  │
│                     │  7  │   │  8  │   │  9  │                                  │
│                     ├─────┤   ├─────┤   ├─────┤                                  │
│                     │  ×  │   │  0  │   │  ✓  │                                  │
│                     └─────┘   └─────┘   └─────┘                                  │
│                                                                                  │
│                       ¿Olvidaste el PIN? Pide a RRHH rotarlo.                    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: llamada custom (no está en `@zentto/timesheet-client@0.1.0`): `POST /v1/auth/kiosk-pin` → devuelve `{ employee: {...}, sessionToken }`. Cookie httpOnly de kiosko con TTL corto (ej. 2 min desde último tap).
- **Seguridad**:
  - Rate limit nginx: 5 intentos / 60s / IP.
  - Lockout tras 5 fallos consecutivos → `<Alert severity="error">Demasiados intentos. Espera 60s.</Alert>`.
  - PIN 4–6 dígitos. Hash server-side con bcrypt 12 rounds + salt.

#### 2.8.2 Paso 2 · Panel acciones

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ 14:23:07 · Jueves 23 Abr 2026                      [Salir ×]   Sesión: 00:00:30 │
│                                                                                  │
│                  Hola, 👤 María López                                             │
│                  Último fichaje: 13:05 · Vuelta de pausa                         │
│                                                                                  │
│   ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐   │
│   │                      │  │                      │  │                      │   │
│   │          ⏹           │  │          ⏸           │  │          📂          │   │
│   │                      │  │                      │  │                      │   │
│   │      SALIDA          │  │      PAUSA           │  │   SELECCIONAR        │   │
│   │                      │  │                      │  │   PROYECTO           │   │
│   └──────────────────────┘  └──────────────────────┘  └──────────────────────┘   │
│   (ZenttoTimeKiosk)                                                              │
│                                                                                  │
│   ┌──────────────────────┐                                                       │
│   │          🏢           │                                                       │
│   │                      │                                                       │
│   │   SALIDA EMPRESA     │                                                       │
│   │   (fin jornada)      │                                                       │
│   └──────────────────────┘                                                       │
│                                                                                  │
│   Sesión auto-cerrará en 30s si no hay actividad.                                │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `attendance.clockIn|clockOut|breakStart|breakEnd|companyExit(employeeId)` — el SDK ya soporta pasar `employeeId` explícito (no asume caller).
- **Timeout**: 30s sin interacción → toast "Sesión cerrada automáticamente" + redirect a pantalla PIN.
- **Feedback post-tap**: toast 3s "✓ Pausa iniciada a las 14:23" y la acción realizada queda resaltada 1.5s con `alpha(success.main, 0.2)` ring.

#### 2.8.3 Paso 2.5 · Seleccionar proyecto

Overlay modal full-screen: lista de favoritos del empleado (grandes 120px alto) → tap → toast "✓ Imputando a 🟦 CRM Backend" → vuelve a panel acciones en el estado "IN_PROJECT".

### 2.9 `/aprobaciones` — Manager

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Aprobaciones pendientes" · 3 por revisar                   │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ ZenttoFilterPanel (inline desktop, drawer mobile) ─────────────────────┐     │
│ │ Empleado: [Autocompletar ▼]  Estado: [Pendiente ✕]  Rango: [01-30 Abr]   │     │
│ │ Unidad: [IT ✕] [Consultoría ✕]   Con extras: [ ⬜ ]   [Limpiar (2)]       │     │
│ └────────────────────────────────────────────────────────────────────────┘      │
│                                                                                  │
│ [ZenttoRecordTable con bulkActions]                                              │
│ ┌─┬────────────────┬──────────────┬──────┬─────┬────────┬────────────────────┐  │
│ │☐│ Empleado       │ Semana       │ Horas│ Ext │ Estado │ Acciones           │  │
│ ├─┼────────────────┼──────────────┼──────┼─────┼────────┼────────────────────┤  │
│ │☑│ 👤 María López │ Sem 17 Abr   │ 40h  │ 2h  │ 🟡 Pdte│ [👁 Ver] [✓][✗]    │  │
│ │☑│ 👤 Juan García │ Sem 17 Abr   │ 38h  │ 0h  │ 🟡 Pdte│ [👁 Ver] [✓][✗]    │  │
│ │☐│ 👤 Ana Ruiz    │ Sem 17 Abr   │ 42h  │ 4h  │ 🟠 Rev.│ [👁 Ver] [✓][✗]    │  │ ← naranja
│ └─┴────────────────┴──────────────┴──────┴─────┴────────┴────────────────────┘  │
│                                                                                  │
│ Seleccionadas: 2  [✓ Aprobar selección]  [✗ Rechazar con motivo…]               │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `validation.act({ entries: [...ids], action: 'APPROVE' | 'REJECT', reason? })`.
- **Bulk reject**: `FormDialog` pide motivo obligatorio.
- **Fila naranja**: si la hoja tiene extras o registros atrasados, `rowClassName` custom con `alpha(warning.main, 0.08)` + icono `⚠` en columna Estado.

### 2.10 `/aprobaciones/[id]` — revisión individual

Abre en misma ruta con `RightDetailDrawer` o página dedicada (propongo página — más cómoda para revisar una semana completa).

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Hoja de María López · Sem 17"   [← Volver]                 │
│   [✓ Aprobar]  [✗ Rechazar…]  [💬 Comentar]                                      │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Resumen:  40h trabajadas · 2h extras · Saldo +0h  · 3 proyectos                  │
│                                                                                  │
│ (Vista idéntica a tab "Semana calendario" del empleado, pero readonly)           │
│ [ZenttoWeekAgendaCalendar readonly]                                              │
│                                                                                  │
│ ┌─ Notas del manager ───────────────────────────────────────────────────────┐   │
│ │ [TextArea…                                                                 ] │   │
│ └──────────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 2.11 `/carga-laboral` — Dashboard ejecutivo

Idéntico a `§7.1` del brief conceptual. **Implementación**: se respetan los 4 acordeones `<Accordion>` MUI + `DashboardSection` como wrapper + `<ZenttoBarChart>` / `<ZenttoLineChart>` (nuevos, ver §3).

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Carga laboral"   [Año 2026 ▼] [📤 Exportar Excel] [📄 PDF]│
├──────────────────────────────────────────────────────────────────────────────────┤
│ [ZenttoFilterPanel]                                                              │
│ Unidad negocio · Empleado · Calendario · Rango meses                             │
├──────────────────────────────────────────────────────────────────────────────────┤
│ KPIs (4× DashboardKpiCard): Ocupación · Sub-asign · Sobre-asign · Plan vs Real   │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ▼ Resumen ejecutivo  (abierto)                                                   │
│     <ZenttoBarChart grouped + line target + Brush>                               │
│ ▶ Por empleado                                                                   │
│ ▶ Por proyecto                                                                   │
│ ▶ Tendencia anual                                                                │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `dashboards.workload(filters)` (API ya viva).
- **Drill-down**: click barra → `RightDetailDrawer` con tabs [Por empleado] [Por proyecto] + `<ZenttoRecordTable>`.

### 2.12 `/reportes`

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ContextActionHeader: "Reportes"                                                  │
├──────────────────────────────────────────────────────────────────────────────────┤
│ [ZenttoRecordTable]                                                              │
│ Periodo         · Empleado(s)    · Generado el  · Estado   · Acciones            │
│ 📄 Abr 2026     · Todo mi equipo · 23/04 14:00  · ✓ Listo │ [⬇ PDF] [🗑]         │
│ 📄 Abr 2026     · María López    · 23/04 09:12  · ✓ Listo │ [⬇ PDF]              │
│ 📄 Mar 2026     · Todo mi equipo · 01/04 07:00  · ✓ Listo │ [⬇ PDF]              │
├──────────────────────────────────────────────────────────────────────────────────┤
│ [+ Generar reporte]                                                              │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **SDK**: `reports.timesheetPdf({ employeeId, from, to })` streaming blob.

### 2.13 `/perfil`

3 secciones colapsadas con `SettingsLayout` + `SettingsSection`:

1. **Datos personales** (read-only, SSO) — nombre, email, tenant.
2. **Seguridad** — cambiar password (redirige a `auth.zentto.net/settings`). Configurar MFA.
3. **Kiosko** — botón `[🔄 Rotar PIN]` → POST `/v1/auth/kiosk-pin/rotate` → modal **muestra 1 sola vez** "Tu nuevo PIN: **4821** (guárdalo, no se mostrará de nuevo)".
4. **Preferencias** — timezone (autocompleta del `IANA`), idioma (ES/EN), notificaciones.

---

## 3. Inventario shared-ui + componentes nuevos

### 3.1 Componentes existentes reutilizables

Todos en `D:\DatqBoxWorkspace\DatqBoxWeb\web\modular-frontend\packages\shared-ui\src\components\` salvo indicación.

| Componente | Path real | Uso en portal |
|---|---|---|
| `ZenttoVerticalLayout` | `packages/vertical-layout/src/ZenttoVerticalLayout.tsx` | Shell principal (empleado/manager/RRHH) |
| `ZenttoLayout` | `packages/shared-ui/src/components/ZenttoLayout.tsx` | **NO** — es el shell ERP con sidebar tipo Odoo, pesado para portal standalone. Usamos `ZenttoVerticalLayout` |
| `ZenttoRecordTable` | `components/ZenttoRecordTable.tsx` | Todas las tablas (entries, aprobaciones, reportes, favoritos, drill-down carga laboral) |
| `ZenttoFilterPanel` | `components/ZenttoFilterPanel.tsx` | Filtros en `/aprobaciones` y `/carga-laboral` |
| `DashboardKpiCard` | `components/DashboardKpiCard.tsx` | KPIs dashboards empleado + carga laboral |
| `DashboardSection` | `components/DashboardSection.tsx` | Agrupador de sección en dashboard empleado |
| `DashboardShortcutCard` | `components/DashboardShortcutCard.tsx` | No aplica — el portal es feature-focused, no hub multi-módulo |
| `ModulePageShell` | `components/ModulePageShell.tsx` | `/tiempos`, `/aprobaciones`, `/carga-laboral` |
| `ContextActionHeader` | `components/ContextActionHeader.tsx` | Header de cada subpágina con acciones |
| `RightDetailDrawer` | `components/RightDetailDrawer.tsx` | Drill-down carga laboral + ediciones rápidas |
| `ConfirmDialog` / `DeleteDialog` / `FormDialog` | `components/dialogs/*` | Confirmar delete, rechazar con motivo, registro en serie |
| `FormGrid` / `FormField` | `components/FormGrid.tsx` | Formulario `/tiempos/nuevo` + `/perfil` |
| `CustomStepper` | `components/CustomStepper.tsx` | Workflow `Borrador→Pendiente→Aprobado`; wizard `/tiempos/serie` |
| `CommandPalette` | `components/CommandPalette.tsx` | Cmd+K global (nuevo registro, ir a tab, etc.) |
| `KeyboardShortcutsProvider` | `providers/KeyboardShortcutsProvider.tsx` | Atajos teclado |
| `KeyboardShortcutsCheatSheet` | `components/KeyboardShortcutsCheatSheet.tsx` | `?` muestra ayuda |
| `ToastProvider` / `useToast` | `providers/ToastProvider.tsx` | Feedback post-clock-in en kiosko |
| `LocalizationProviderWrapper` | `providers/LocalizationProviderWrapper.tsx` | MUI X date pickers |
| `BrandingProvider` / `BrandedThemeProvider` | `providers/BrandingProvider.tsx` + `components/BrandedThemeProvider.tsx` | Tema Zentto |
| `LoadingFallback` | `components/LoadingFallback.tsx` | Suspense boundaries |
| `PerfilDrawer` | `components/PerfilDrawer.tsx` | Drawer `/perfil` en mobile |
| `useIsDesktop` | `hooks/useIsDesktop.ts` | Decidir tab default `Día` vs `Semana` |
| `useDrawerQueryParam` | `hooks/useDrawerQueryParam.ts` | Persistir drawer de drill-down en URL |
| `SettingsLayout` + `SettingsSection` + `SettingsItem` + `SettingsInputGroup` | `components/Settings*.tsx` | Página `/perfil` |
| `HelpButton` + `HELP_MAP` | `components/HelpButton.tsx` + `lib/help-map.ts` | Ayuda contextual |
| `CountrySelect` / `PhoneInput` / `LocaleSelectorButton` | Respectivos | Preferencias `/perfil` |
| `ThemeToggle` | `components/ThemeToggle.tsx` | Light/dark toggle topbar |
| `LocalizacionModal` | `components/LocalizacionModal.tsx` | Selector timezone/idioma inicial |

### 3.2 Componentes NUEVOS a crear

**Decisión de ubicación**: todos los charts y componentes estrictamente timesheet van a un package nuevo `@zentto/timesheet-ui` dentro del monorepo ERP (`packages/timesheet-ui`) para **no acoplar** el microservicio standalone al monorepo. Este package se publica npm y se consume desde `zentto-timesheet/frontend`. Los charts (`ZenttoBarChart`, `ZenttoLineChart`) son genéricos → van a `shared-ui` del monorepo ERP porque también los usará nómina.

| Componente | Package destino | Justificación |
|---|---|---|
| `ZenttoBarChart` | `@zentto/shared-ui` | Genérico, Recharts wrapper |
| `ZenttoLineChart` | `@zentto/shared-ui` | Genérico, Recharts wrapper |
| `ZenttoKpiDeltaCard` | `@zentto/shared-ui` | Wrapper de `DashboardKpiCard` con delta prominent — reusable en cualquier dashboard |
| `ZenttoClockButton` | `@zentto/shared-ui` | Botón semáforo reutilizable (también útil en hotel/medical para "estoy en turno") |
| `ZenttoStatusChip` | `@zentto/shared-ui` | Chip con icono + color por estado — genérico |
| `ZenttoTimeKiosk` | `@zentto/timesheet-ui` | Específico timesheet |
| `ZenttoFavoritesPicker` | `@zentto/timesheet-ui` | Específico timesheet |
| `ZenttoTimesheetMatrix` | `@zentto/timesheet-ui` | Específico timesheet |
| `ZenttoWeekAgendaCalendar` | `@zentto/timesheet-ui` | Específico timesheet (podría evolucionar a `@zentto/scheduler` si hotel/medical lo adoptan) |
| `ZenttoDayDetailTimeline` | `@zentto/timesheet-ui` | Específico timesheet |
| `ZenttoPinPad` | `@zentto/timesheet-ui` | Específico timesheet (kiosko PIN) |

### 3.3 Contratos de componentes nuevos

Los contratos de `ZenttoBarChart`, `ZenttoLineChart`, `ZenttoTimesheetMatrix` (antes `ZenttoTimesheetGrid`), `ZenttoTimeKiosk` y `ZenttoFavoritesPicker` están en `timesheet-carga-laboral-brief.md §5`. Se respetan tal cual. Aquí se añaden los faltantes:

#### 3.3.1 `ZenttoClockButton`

```ts
export type ZenttoClockAction =
  | 'CLOCK_IN'
  | 'CLOCK_OUT'
  | 'PAUSE_START'
  | 'PAUSE_END'
  | 'COMPANY_EXIT';

export type ZenttoClockButtonProps = {
  action: ZenttoClockAction;
  label: string;
  size?: 'md' | 'lg' | 'xl';         // 56 | 80 | 120 altura
  variant: 'primary' | 'warning' | 'danger' | 'neutral';
  loading?: boolean;
  disabled?: boolean;
  /** Confirma al primer tap, ejecuta al segundo (opcional, default false) */
  doubleTapConfirm?: boolean;
  onClick: () => void | Promise<void>;
  fullWidth?: boolean;
  /** Icono override (default según action) */
  icon?: React.ReactNode;
};
```

- **Estados**: `default`, `hover`, `focus-visible` (outline 3px primary), `loading` (spinner + texto), `disabled` (alpha 0.4 + cursor not-allowed), `success` (pulso verde 800ms tras éxito).
- **Accesibilidad**: `<button type="button" aria-label>` + `aria-busy`.
- **Mobile**: si `fullWidth`, ocupa 100%; tamaño `xl` usa `min-height: 120px`.

#### 3.3.2 `ZenttoStatusChip`

```ts
export type ZenttoAttendanceStatus = 'PRESENT' | 'ABSENT' | 'ON_BREAK' | 'OUT' | 'LATE' | 'EARLY';
export type ZenttoApprovalStatus = 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED';

export type ZenttoStatusChipProps = {
  kind: 'attendance' | 'approval' | 'custom';
  status: ZenttoAttendanceStatus | ZenttoApprovalStatus | string;
  /** Override de label (default: traducción i18n automática) */
  label?: string;
  size?: 'sm' | 'md';
  /** Icon override */
  icon?: React.ReactNode;
  /** Tooltip con contexto extra */
  tooltip?: string;
};
```

- Mapea `status → { color, icon, label }` vía tokens `timesheet.*` (§4).
- Usa `<Chip>` MUI con `icon` siempre presente (accesibilidad daltónica).

#### 3.3.3 `ZenttoWeekAgendaCalendar`

```ts
export type AgendaBlock = {
  id: string;
  start: string;          // ISO datetime UTC
  end: string;            // ISO datetime UTC
  projectId: string;
  projectName: string;
  projectColor: string;
  phaseName?: string;
  serviceName?: string;
  kind: 'PROJECT' | 'ATTENDANCE' | 'BREAK' | 'ABSENCE';
  readonly?: boolean;
};

export type ZenttoWeekAgendaCalendarProps = {
  weekStart: string;      // ISO date lunes
  blocks: AgendaBlock[];
  hoursRange?: [number, number];   // default [7, 20]
  slotMinutes?: 15 | 30 | 60;      // default 30
  onBlockClick?: (block: AgendaBlock) => void;
  onBlockCreate?: (slot: { start: string; end: string }) => void;  // drag-to-create
  onBlockResize?: (blockId: string, newEnd: string) => void;
  onBlockMove?: (blockId: string, newStart: string) => void;
  readonly?: boolean;
  loading?: boolean;
  timezone: string;       // IANA del empleado
};
```

- **Estados bloque**: `default`, `hover` (lift shadow), `dragging` (opacidad 0.6), `resizing`.
- **Accesibilidad**: `role="grid"` día × hora, `aria-selected` en slot activo, teclado Arrow para navegar, Enter para crear bloque, Del para borrar.
- **Fallback mobile**: prop `mobileFallback?: 'day-swiper' | 'list'` — default `'day-swiper'`.

#### 3.3.4 `ZenttoDayDetailTimeline`

```ts
export type TimelineItem = {
  id: string;
  start: string;          // ISO datetime
  end: string;
  kind: 'CLOCK_IN' | 'CLOCK_OUT' | 'BREAK' | 'PROJECT' | 'ABSENCE';
  projectName?: string;
  projectColor?: string;
  hoursDecimal?: number;
  activity?: string;
  status: ZenttoApprovalStatus;
  readonly?: boolean;
};

export type ZenttoDayDetailTimelineProps = {
  date: string;           // ISO date
  items: TimelineItem[];
  onEdit?: (id: string) => void;
  onDelete?: (id: string) => void;
  onAdd?: () => void;
  loading?: boolean;
  emptyMessage?: string;
  timezone: string;
};
```

- **Accesibilidad**: `<ol role="list">` con `<li>` por item. Cada item tiene botones `[Editar] [Borrar]` con `aria-label` completo.

#### 3.3.5 `ZenttoKpiDeltaCard`

```ts
export type ZenttoKpiDeltaCardProps = {
  title: string;
  value: string;                                      // formateado
  secondary?: string;                                 // "/ 168h previsto"
  delta?: { value: number; direction: 'up'|'down'|'flat'; label?: string };
  icon?: React.ReactNode;
  loading?: boolean;
  tone?: 'neutral' | 'positive' | 'warning' | 'danger';
  onClick?: () => void;                               // card clickable
  badge?: { label: string; color: 'warning'|'success'|'danger' };
};
```

- Wrapper fino sobre `DashboardKpiCard` que añade delta y badge — reutilizable en cualquier app.

#### 3.3.6 `ZenttoPinPad`

```ts
export type ZenttoPinPadProps = {
  length?: 4 | 5 | 6;          // default 4
  onSubmit: (pin: string) => void | Promise<void>;
  disabled?: boolean;
  error?: string;              // error bajo los dots
  helpText?: string;
  autoSubmit?: boolean;        // al completar length
  large?: boolean;             // teclas 120×120 para kiosko
};
```

- Teclado numérico grande. Dots arriba muestran progreso (● llenos / ○ vacíos).
- Rate-limit handled por parent — solo muestra `error` string.

### 3.4 Hooks a crear

En `zentto-timesheet/frontend/src/hooks/`:

| Hook | Propósito | SDK underlying |
|---|---|---|
| `useTodayStatus` | Estado presente/pausa/fuera + última acción | `attendance.todaySummary()` |
| `useTimeEntries(filters)` | Lista paginada de entries | `timeEntries.list` |
| `useTimeEntry(id)` | Una entry | `timeEntries.get` |
| `useFavorites` | Favoritos + CRUD | `favorites.*` |
| `useWorkload(filters)` | Dashboard carga laboral | `dashboards.workload` |
| `useMonthAgg(filters)` | Agregado mensual para tab Periodo | `dashboards.monthAgg` |
| `useContexts` | Proyectos, fases, servicios, actividades | `contexts.*` |
| `useClock` | Mutación clockIn/Out/break* con optimistic update | `attendance.*` |
| `useValidation` | Approve/reject bulk | `validation.act` |
| `useKioskSession` | Sesión PIN, timeout, auto-logout | `POST /v1/auth/kiosk-pin` |
| `useTimezone` | Timezone del empleado (localStorage + `/me`) | — |

Todos usan TanStack Query. Invalidación cruzada: `clockIn` invalida `['today']`, `['time-entries']`.

---

## 4. Tokens semánticos a añadir en `@zentto/design-tokens`

Archivo: `packages/design-tokens/src/tokens/color.ts`.

### 4.1 Nuevos roles

```ts
// Heredan estructura de 'lead' y 'priority' (ya existentes)
timesheet: {
  present:    { paletteKey: 'success',   hex: brand.success        },  // 🟢 en jornada
  absent:     { paletteKey: 'error',     hex: brand.danger         },  // 🔴 no ha fichado
  onBreak:    { paletteKey: 'warning',   hex: brand.accent         },  // 🟡 en pausa
  out:        { paletteKey: 'secondary', hex: brand.textMuted      },  // 🟤 salida empresa
  late:       { paletteKey: 'warning',   hex: '#B07500'            },
  early:      { paletteKey: 'info',      hex: brand.teal           },
},
approval: {
  draft:      { paletteKey: 'secondary', hex: brand.textMuted      },
  submitted:  { paletteKey: 'primary',   hex: brand.accent         },
  approved:   { paletteKey: 'success',   hex: brand.success        },
  rejected:   { paletteKey: 'error',     hex: brand.danger         },
},
workload: {   // ya propuesto en brief conceptual §8.2 — se reitera
  capacity:    { paletteKey: 'info',      hex: brand.indigo        },
  planned:     { paletteKey: 'info',      hex: brand.teal          },
  target:      { paletteKey: 'warning',   hex: brand.accent        },
  underLoaded: { paletteKey: 'warning',   hex: '#B07500'           },
  optimal:     { paletteKey: 'success',   hex: brand.success       },
  overLoaded:  { paletteKey: 'error',     hex: brand.danger        },
},
```

### 4.2 Nuevos spacing/size para kiosko

```ts
kiosko: {
  buttonMin:  { value: 200, unit: 'px' },
  buttonXl:   { value: 240, unit: 'px' },
  buttonXxl:  { value: 320, unit: 'px' },
  pinKeyMin:  { value: 96,  unit: 'px' },
  pinKeyLg:   { value: 120, unit: 'px' },
},
```

### 4.3 Contraste validado

| Token | Background | Ratio | AA |
|---|---|---|---|
| `timesheet.present` sobre `bgCard` (#fff) | #fff | 4.8:1 | ✓ |
| `timesheet.absent` sobre `bgCard` | #fff | 5.9:1 | ✓ |
| `approval.submitted` sobre `bgCard` | #fff | 3.1:1 | ⚠ usar texto oscuro dentro |
| `workload.target` sobre `bgCard` | #fff | 3.1:1 | ⚠ idem — por eso se usa solo como línea discontinua |

---

## 5. Flujo de auth

### 5.1 Login SSO (empleado/manager/RRHH)

```
usuario  →  GET timesheet.zentto.net/ 
          (middleware verifica cookie `zentto_session`)
          ├─ sin cookie → redirect 302 a /login
          └─ con cookie → /me via @zentto/auth-client.fetchWithRefresh()
                          ├─ 200 + roles → render shell + rutas permitidas
                          └─ 401 → refresh → retry → si falla: logout + redirect /login

usuario  →  /login   submit email+password
          → POST auth.zentto.net/v1/login (directo, NO proxied)
          → respuesta setea cookie httpOnly `zentto_session` y `zentto_refresh`
          → redirect a /

cookie domain: `.zentto.net` (compartida con otras apps del ecosistema)
```

### 5.2 Middleware Next.js (`middleware.ts`)

```ts
// Pseudocódigo
export async function middleware(req: NextRequest) {
  const pathname = req.nextUrl.pathname;
  const isPublic = ['/login', '/kiosko', '/api/auth', '/api/kiosk'].some(p => pathname.startsWith(p));
  if (isPublic) return NextResponse.next();

  const session = req.cookies.get('zentto_session');
  if (!session) return NextResponse.redirect(new URL('/login?return_to=' + pathname, req.url));

  // Validar via introspección de Zentto Auth (cached 60s en memoria del edge)
  const me = await introspect(session.value);
  if (!me) return NextResponse.redirect(new URL('/login', req.url));

  // Rol-based gate
  if (pathname.startsWith('/aprobaciones') && !me.roles.some(r => r === 'ts.manager' || r === 'ts.admin')) {
    return NextResponse.redirect(new URL('/', req.url));
  }
  if (pathname.startsWith('/carga-laboral') && !me.roles.some(r => ['ts.hr','ts.manager','ts.admin'].includes(r))) {
    return NextResponse.redirect(new URL('/', req.url));
  }

  return NextResponse.next();
}

export const config = { matcher: ['/((?!_next|static|favicon).*)'] };
```

### 5.3 PIN kiosko

Flujo independiente, **no** usa `zentto_session`. Cookie separada `ts_kiosk_session` con `SameSite=Strict; HttpOnly; Secure; Max-Age=120` (2 min).

```
POST /v1/auth/kiosk-pin  { tenantId, pin: '4821' }
  → servidor busca usp_TS_KioskPin_Verify(tenantId, pin_hash)
  → devuelve { employee: {...}, sessionToken }
  → setea cookie ts_kiosk_session (JWT corto con employeeRefId)

Cada acción del panel kiosko (clock-in, etc.) envía X-Kiosk-Session: <token>
y renueva TTL en respuesta. Sin actividad 30s → expirar → frontend detecta 401 → vuelve a pantalla PIN.
```

### 5.4 `/api/auth/*` y `/api/kiosk/*`

Rutas Next.js Route Handlers para evitar CORS en browser:

- `POST /api/auth/login` → proxy a `auth.zentto.net/v1/login` (seteo cookie directo).
- `POST /api/auth/logout` → limpia cookies.
- `POST /api/kiosk/pin` → proxy a API timesheet (`/v1/auth/kiosk-pin`).
- `POST /api/kiosk/pin/rotate` → proxy a API timesheet.

---

## 6. Estructura de carpetas Next.js App Router

```
zentto-timesheet/frontend/
├── src/
│   ├── app/
│   │   ├── (empleado)/
│   │   │   ├── layout.tsx              ← ZenttoVerticalLayout con nav empleado
│   │   │   ├── page.tsx                ← Dashboard "/"
│   │   │   ├── tiempos/
│   │   │   │   ├── page.tsx            ← Tabs Periodo/Rápido/Semana/Día
│   │   │   │   ├── nuevo/page.tsx
│   │   │   │   ├── serie/page.tsx
│   │   │   │   └── [id]/
│   │   │   │       ├── page.tsx        ← Detalle
│   │   │   │       └── edit/page.tsx
│   │   │   ├── favoritos/page.tsx
│   │   │   ├── reportes/page.tsx
│   │   │   └── perfil/page.tsx
│   │   ├── (manager)/
│   │   │   ├── layout.tsx              ← mismo shell + nav manager merged
│   │   │   ├── aprobaciones/
│   │   │   │   ├── page.tsx
│   │   │   │   └── [id]/page.tsx
│   │   │   └── carga-laboral/page.tsx  ← accesible también por ts.hr
│   │   ├── (kiosko)/
│   │   │   ├── layout.tsx              ← SIN sidebar, solo theme + toast
│   │   │   └── kiosko/
│   │   │       ├── page.tsx            ← PIN pad + panel acciones (dos estados)
│   │   │       └── select-project/page.tsx
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   │   ├── login/route.ts
│   │   │   │   ├── logout/route.ts
│   │   │   │   └── me/route.ts
│   │   │   └── kiosk/
│   │   │       ├── pin/route.ts
│   │   │       └── pin/rotate/route.ts
│   │   ├── providers.tsx               ← BrandingProvider + ToastProvider + QueryProvider + LocalizationProvider + KeyboardShortcutsProvider
│   │   ├── layout.tsx                  ← root layout + <html lang="es">
│   │   ├── globals.css
│   │   └── error.tsx
│   ├── components/
│   │   ├── EmployeeNav.ts               ← NavigationField[] empleado
│   │   ├── ManagerNav.ts                ← NavigationField[] manager (incluye empleado + /aprobaciones + /carga-laboral)
│   │   ├── TimeBar.tsx                  ← chips de estado del día
│   │   └── QuickImputePicker.tsx        ← wrapper de ZenttoFavoritesPicker con lógica propia
│   ├── hooks/
│   │   ├── useTodayStatus.ts
│   │   ├── useTimeEntries.ts
│   │   ├── useFavorites.ts
│   │   ├── useWorkload.ts
│   │   ├── useMonthAgg.ts
│   │   ├── useContexts.ts
│   │   ├── useClock.ts
│   │   ├── useValidation.ts
│   │   ├── useKioskSession.ts
│   │   └── useTimezone.ts
│   ├── lib/
│   │   ├── sdk.ts                       ← createTimesheetClient(config) — singleton
│   │   ├── auth.ts                      ← wrappers @zentto/auth-client
│   │   ├── i18n.ts                      ← strings ES (y EN en v2)
│   │   ├── time.ts                      ← helpers dayjs
│   │   └── env.ts                       ← lectura NEXT_PUBLIC_*
│   ├── middleware.ts                    ← ver §5.2
│   └── types/
│       └── session.ts                   ← tipos role/session locales
├── public/
│   ├── logo-zentto-timesheet.svg
│   └── favicon.ico
├── next.config.mjs
├── package.json
├── tsconfig.json
├── Dockerfile                           ← standalone output
└── .env.example
```

Patrón clonado de `zentto-hotel/frontend/` — mismo layout/providers/middleware.

---

## 7. Orden de implementación (priorización de PRs)

Reordenado respecto a la propuesta del usuario tras el análisis. Criterio: **desbloquear al empleado primero** (mayor ROI), luego manager, luego RRHH, luego kiosko (tiene dependencia BD).

### Fase 0 · Prerrequisitos (en monorepo ERP)

| # | PR | Repo | Descripción | Bloquea |
|---|---|---|---|---|
| 0.1 | `feat(shared-ui): chart wrappers (bar/line/kpiDelta)` | DatqBoxWeb monorepo | `ZenttoBarChart`, `ZenttoLineChart`, `ZenttoKpiDeltaCard` con Recharts `peerDep` | 9 (dashboards) |
| 0.2 | `feat(shared-ui): clock button + status chip` | DatqBoxWeb monorepo | `ZenttoClockButton`, `ZenttoStatusChip` | 2, 3 |
| 0.3 | `feat(design-tokens): workload + timesheet + approval + kiosko tokens` | DatqBoxWeb monorepo | Tokens §4 | 0.1–0.2 (consumen tokens) |
| 0.4 | `feat(timesheet-ui): new package skeleton` | DatqBoxWeb monorepo | Nuevo package `@zentto/timesheet-ui` vacío con tooling | 0.5+ |
| 0.5 | `feat(timesheet-ui): ZenttoTimeKiosk + ZenttoPinPad + ZenttoFavoritesPicker` | DatqBoxWeb monorepo | Componentes para empleado+kiosko | 2, 7, 9 |
| 0.6 | `feat(timesheet-ui): ZenttoTimesheetMatrix + ZenttoWeekAgendaCalendar + ZenttoDayDetailTimeline` | DatqBoxWeb monorepo | Matriz semanal + agenda + timeline día | 3 |
| 0.7 | `feat(timesheet-api): migración 00010 + SPs KioskPin` | zentto-timesheet | Tabla + 4 SPs (§11) | 7 (kiosko) |
| 0.8 | `feat(timesheet-api): endpoints /v1/auth/kiosk-pin + /rotate` | zentto-timesheet | API kiosko PIN | 7 |

### Fase 1 · Portal MVP empleado

| # | PR | Repo | Descripción |
|---|---|---|---|
| 1 | `feat(frontend): bootstrap + auth shell + login` | zentto-timesheet | Setup Next.js, providers, middleware, `/login`, `/perfil` básico |
| 2 | `feat(frontend): dashboard empleado + clockIn` | zentto-timesheet | `/` con `TimeBar`, `ZenttoClockButton`, KPIs, favoritos horizontal, tabla últimas 10 |
| 3 | `feat(frontend): /tiempos tab Día + /tiempos/nuevo + /tiempos/[id]` | zentto-timesheet | Timeline día, formulario nuevo, detalle |
| 4 | `feat(frontend): /tiempos tab Periodo` | zentto-timesheet | Agregado mensual con `ZenttoRecordTable` |
| 5 | `feat(frontend): /tiempos tab Semana (agenda)` | zentto-timesheet | `ZenttoWeekAgendaCalendar` con drag-to-create |
| 6 | `feat(frontend): /tiempos tab Rápido (matriz) + /tiempos/serie + /favoritos` | zentto-timesheet | Matriz editable + wizard serie + CRUD favoritos |

### Fase 2 · Manager

| # | PR | Repo | Descripción |
|---|---|---|---|
| 7 | `feat(frontend): /aprobaciones + detalle` | zentto-timesheet | Bandeja con filtros + bulk approve/reject |

### Fase 3 · Gerencia

| # | PR | Repo | Descripción |
|---|---|---|---|
| 8 | `feat(frontend): /carga-laboral dashboard ejecutivo` | zentto-timesheet | Acordeones + charts + drill-down + export |

### Fase 4 · Kiosko

| # | PR | Repo | Descripción |
|---|---|---|---|
| 9 | `feat(frontend): /kiosko con PIN + panel acciones` | zentto-timesheet | PIN pad + ZenttoTimeKiosk + auto-logout 30s |

### Fase 5 · Reportes y polish

| # | PR | Repo | Descripción |
|---|---|---|---|
| 10 | `feat(frontend): /reportes + integración PDF` | zentto-timesheet | Descarga PDF mensual via `reports.timesheetPdf` |
| 11 | `chore(frontend): PWA + offline IndexedDB kiosko` | zentto-timesheet | Service worker + queue offline para kiosko en red mala |
| 12 | `feat(frontend): command palette + shortcuts + help cheatsheet` | zentto-timesheet | Cmd+K, G→T, `?`, etc. |
| 13 | `feat(zentto-report): template timesheet_month.json` | zentto-report | Template PDF firma empleado/cliente |
| 14 | `chore(infra): dominios timesheet(dev).zentto.net + nginx` | zentto-infra | Cloudflare + nginx site + SSL |

### Justificación del reorden

- **Tab Día antes que Periodo**: el empleado de campo necesita crear/ver registros del día hoy mismo; el agregado mensual puede esperar 1 sprint.
- **Tab Semana antes que Rápido**: mejor ROI visual, validación temprana con usuarios reales. La matriz es más compleja de QA.
- **Kiosko tras aprobaciones**: kiosko depende de migración BD (PR 0.7) y del `ts.kiosk` role; mientras tanto el empleado ya ficha desde mobile.
- **Carga laboral tras aprobaciones**: gerencia no pide el dashboard si no hay hojas aprobadas que mirar.
- **Command palette + shortcuts al final**: son "delight", no blockers.

### Paralelización sugerida

- Fase 0 pre-requisitos en paralelo: 0.1+0.2+0.3 (mismo equipo shared-ui), 0.4+0.5+0.6 (mismo equipo timesheet-ui), 0.7+0.8 (backend).
- Fase 1: secuencial 1→2, luego 3+4 paralelos, luego 5+6 paralelos.
- Fase 2+3: paralelos una vez Fase 1 cerrada.

---

## 8. Criterios de aceptación (QA checklist por pantalla)

### 8.1 `/login`

- [ ] Formulario email+password con validación Zod inline (email válido, password ≥ 8).
- [ ] Error "Credenciales inválidas" en `<Alert>`.
- [ ] MFA challenge abre modal con code pad.
- [ ] `return_to` preservado en redirect post-login.
- [ ] Accesibilidad: `<label htmlFor>` en inputs, Tab order correcto, Enter submit.

### 8.2 `/` Dashboard empleado

- [ ] Chip estado refleja `attendance.todaySummary()` en tiempo real.
- [ ] Click `[FICHAR ENTRADA]` → llama `attendance.clockIn()`, optimistic update, toast "✓ Entrada registrada 08:42".
- [ ] Error clockIn → toast error + rollback optimistic + `<Alert>` banner con retry.
- [ ] 4 KPIs cargan de `dashboards.workload(self)` + `dashboards.monthAgg(self)`.
- [ ] Chip favorito click → popover "¿cuántas horas?" default 1h → submit crea entry vía `timeEntries.save`.
- [ ] Tabla últimas 10 entries carga de `timeEntries.list({ limit:10 })` vía `<ZenttoRecordTable>`.
- [ ] Mobile 375px: una columna, clock button 100%, KPIs 2×2, favoritos swipe horizontal, tabla degrada a cards.
- [ ] Sin `<table>` HTML (grep verificado).
- [ ] Sin mocks (grep `mockData`/`fakeData`).

### 8.3 `/tiempos` (4 tabs)

Ver `§11.1` del brief conceptual. Añadidos específicos del portal:

- [ ] Tab default: desktop=Semana, mobile=Día (`useIsDesktop` hook).
- [ ] URL refleja tab activo: `/tiempos?tab=semana`.
- [ ] Auto-save matriz muestra "Guardado · HH:MM" en `ContextActionHeader`.
- [ ] Banner `<Alert>` si `fecha < hoy - 7d`.
- [ ] Botón "Imprimir hoja" descarga PDF vía `reports.timesheetPdf`.

### 8.4 `/kiosko`

- [ ] PIN 4–6 dígitos configurable; feedback dots.
- [ ] Lockout tras 5 fallos (60s). Timer visible.
- [ ] Auto-logout 30s sin actividad. Countdown visual.
- [ ] Botones `ZenttoTimeKiosk` ≥ 240×240, contraste AAA.
- [ ] Toast 3s tras cada acción + icono con `aria-live="polite"`.
- [ ] Sin sidebar ni topbar (layout group `(kiosko)`).
- [ ] Navegación solo teclado: `1..6` → acciones, `Esc` → logout.
- [ ] Funciona offline (IndexedDB queue) — Fase 5.
- [ ] Cookie `ts_kiosk_session` con `SameSite=Strict; Secure; HttpOnly`.

### 8.5 `/aprobaciones`

- [ ] `<ZenttoFilterPanel>` con Empleado, Estado, Rango, Unidad, Con-extras.
- [ ] `<ZenttoRecordTable bulkActions>` con checkboxes + acciones Aprobar/Rechazar.
- [ ] Reject requiere motivo obligatorio (`FormDialog`).
- [ ] Fila naranja si `hasExtras || hasLateEntries`.
- [ ] Paginación server-side.

### 8.6 `/carga-laboral`

Ver `§11.2` brief conceptual.

### 8.7 `/reportes`

- [ ] Lista de reportes generados (si API lo soporta) o modal "Generar ahora" que llama `reports.timesheetPdf`.
- [ ] Descarga blob con filename `timesheet_{employee}_{YYYY-MM}.pdf`.
- [ ] Streaming progress para archivos > 2MB.

### 8.8 `/perfil`

- [ ] Rotar PIN muestra nuevo PIN **1 sola vez** (re-apertura del modal muestra `****`).
- [ ] PIN copiado al clipboard con confirmación.
- [ ] Timezone preselecciona `Intl.DateTimeFormat().resolvedOptions().timeZone`.
- [ ] Cambio idioma persiste en cookie + localStorage.

### 8.9 Cross-cutting

- [ ] Todas las tablas son `<ZenttoDataGrid>` / `<ZenttoRecordTable>` — **grep `<table` retorna 0** en `src/`.
- [ ] Todas las fechas en UTC-0 al persistir (`dayjs.utc().toISOString()`).
- [ ] Display usa timezone del empleado via `useTimezone()`.
- [ ] Idioma UI español; identificadores código inglés.
- [ ] Light + dark mode funcionales.
- [ ] Lighthouse Accessibility ≥ 95 en las 3 rutas más usadas (`/`, `/tiempos`, `/aprobaciones`).
- [ ] Lighthouse Performance ≥ 80 (primer chart render < 1.5s con 12 meses × 50 empleados).
- [ ] Bundle `app/(empleado)` + `app/(kiosko)` code-split (Next.js route groups nativo).
- [ ] Kiosko bundle < 180KB JS (sin Recharts, sin MUI X Charts, sin TanStack Query si no hace falta — usar `fetch` directo).

---

## 9. Riesgos UX + mitigación

Además de los del brief conceptual `§12.2`, específicos del portal standalone:

| Riesgo | Mitigación |
|---|---|
| **Empleado olvida fichar salida** (deja el navegador abierto, se va a casa) | Cron server-side `ts.attendance_autoclose` (configurable 22:00 tenant local). Notify push al empleado la mañana siguiente "Ayer no cerraste jornada. ¿Fue a las 18:00? [Sí / Editar]". |
| **Doble fichaje en mobile + kiosko** | Idempotency-Key en llamadas clock-* con `employeeId + action + minute-bucket`. Servidor retorna 409 con mensaje "Ya registrado". Frontend muestra toast info no error. |
| **PIN kiosko débil** (4 dígitos) | Rate limit 5/60s + lockout 1min tras 5 fallos + rotación forzada cada 90 días + audit log acceso. Además PIN 4 dígitos es OK porque es un segundo factor (ya estás físicamente en el kiosko y sólo ficha). |
| **Empleado ficha desde mobile fuera de la oficina** | Geofence opcional por empresa (flag `ts.geofence.enabled`). Si activo, browser pide permiso geolocalización + servidor valida contra polígono de sedes. Si off, se registra lat/lng como metadato no bloqueante. |
| **Conexión intermitente en campo** | Service worker + IndexedDB queue. UI muestra chip "3 pendientes de sincronizar" en topbar. Auto-sync al reconectar. Fase 5 del plan. |
| **Manager aprueba toda la semana sin mirar** | `/aprobaciones` destaca semanas con `⚠` si hay extras > X% o días atrasados; bulk approve excluye esas por default — requiere click explícito. |
| **RRHH exporta datos sensibles sin trazabilidad** | Audit log de export con `employeeId, filters, generatedAt` en BD. Vista solo `ts.admin`. |
| **Empleado usa kiosko de otra persona (vuelve de pausa y no ficha el suyo)** | Nombre + foto del empleado + último fichaje visibles durante toda la sesión en top del panel. Si no coincide, click "No soy yo" → logout inmediato. |
| **Matriz semanal cuelga navegador con 20 filas × 7 días × 200 tenants** | Virtualization con `@tanstack/react-virtual` si rows > 15. Evaluar necesario tras PR 6. |
| **Drag-to-create bloque en calendario genera entry sin proyecto** | Drop abre `RightDetailDrawer` obligando a escoger proyecto antes de persistir; si cancela, bloque no se crea. |
| **Favoritos se pierden al cambiar empleado de empresa** | Cuando `tenantId` cambia, `favorites.list()` devuelve set del nuevo tenant. Cacheo por `tenantId + employeeId`. |
| **`dashboards.workload` lento con 12 meses × 100 empleados** | API debe soportar `resolution: 'year'|'month'|'week'` y `aggregate: 'by-employee'|'by-project'`. Si lento, añadir caché Redis 5min server-side. |

---

## 10. Migración goose requerida — `00010_kiosk_pin.sql`

**No escribo SQL en este brief** (lo hace el dev/SQL agent). Diseño:

### 10.1 Tabla `ts.KioskPin`

| Columna | Tipo | Null | Default | Comentario |
|---|---|---|---|---|
| `Id` | BIGINT / UUID | NO | IDENTITY / `gen_random_uuid()` | PK |
| `TenantId` | UUID | NO | — | FK multi-tenant |
| `EmployeeRefId` | BIGINT / UUID | NO | — | FK `ts.Employee` (único por tenant+employee) |
| `PinHash` | VARCHAR(255) | NO | — | bcrypt hash (12 rounds) |
| `PinSalt` | VARCHAR(64) | NO | — | salt random |
| `Active` | BIT / BOOLEAN | NO | true | flag soft-disable |
| `FailedAttempts` | INT | NO | 0 | contador para lockout |
| `LockedUntil` | DATETIME2 / TIMESTAMPTZ | YES | NULL | lockout temporal tras 5 fallos |
| `LastUsedAt` | DATETIME2 / TIMESTAMPTZ | YES | NULL | audit |
| `LastRotatedAt` | DATETIME2 / TIMESTAMPTZ | NO | now | para forzar rotación cada 90d |
| `CreatedAt` | DATETIME2 / TIMESTAMPTZ | NO | now | |
| `UpdatedAt` | DATETIME2 / TIMESTAMPTZ | NO | now | trigger update |

Índices:
- UNIQUE (`TenantId`, `EmployeeRefId`) filtered `Active = true`.
- INDEX (`TenantId`, `PinHash`) — para lookup rápido al verificar.
- INDEX (`TenantId`, `LastRotatedAt`) — job de expiración.

### 10.2 SPs duales (PG + MSSQL)

| SP | Inputs | Outputs | Lógica |
|---|---|---|---|
| `usp_TS_KioskPin_Set` | `TenantId`, `EmployeeRefId`, `PinPlaintext` | `{ ok, mensaje }` | Hash bcrypt con salt aleatorio. Upsert. Setea `LastRotatedAt=now`, resetea `FailedAttempts=0`, `LockedUntil=null`. Retorna PIN plaintext para mostrar 1 vez. |
| `usp_TS_KioskPin_Verify` | `TenantId`, `PinPlaintext` | `{ EmployeeRefId, FailedAttempts, LockedUntil }` o `NULL` | Busca todas las filas Active=true del tenant, aplica bcrypt.compare en cada una (o usa hash sin salt si se restructura a hash-determinista, pero perdería seguridad). Si match: incrementa `LastUsedAt`, resetea `FailedAttempts=0`. Si no match en ninguna: **no identifica al employee**, devuelve NULL. Rate limit en API layer. |
| `usp_TS_KioskPin_Rotate` | `TenantId`, `EmployeeRefId` | `{ ok, mensaje, newPin }` | Genera PIN aleatorio 4 dígitos, llama internamente a `Set`. Retorna PIN plaintext para mostrar 1 vez. |
| `usp_TS_KioskPin_Disable` | `TenantId`, `EmployeeRefId` | `{ ok, mensaje }` | Soft disable. |

**Nota clave de seguridad**: bcrypt.compare requiere iterar sobre todas las filas del tenant → si hay 1000 empleados, 1000 compares (lento). Opciones:

1. **Aceptable hasta 200 empleados/tenant** — la latencia de ~200 * 5ms = 1s es tolerable en kiosko.
2. **Alternativa óptima**: índice blind: guardar `PinFingerprint = SHA256(TenantId || PinPlaintext)` (no seguro para brute-force solo, pero reduce candidatos a 0-5); luego bcrypt solo sobre esos. Decisión: el SQL agent evaluará.
3. **Alternativa simple**: PIN = 6 dígitos (no 4) + índice determinista con pepper global → 10^6 combinaciones × bcrypt ≈ brute-force no factible. Este brief recomienda **PIN 6 dígitos por default**.

### 10.3 Archivos a tocar

- `zentto-timesheet/migrations/postgres/00010_kiosk_pin.sql` (o siguiente número libre tras auditar colisiones — ver memoria 2026-04-20).
- `zentto-timesheet/migrations/postgres/seeds/XX_ts_kioskpin_sps.sql` (si el repo separa seeds).
- No hay equivalente SQL Server en `zentto-timesheet` (repo standalone, PG-only inicialmente). Si en el futuro se dualiza, añadir en `sqlweb-mssql/`.

---

## 11. Dependencias al `zentto-integration-reviewer`

Flags que disparan revisión del integrador:

- [ ] **Contratos OpenAPI**: nuevo endpoint `POST /v1/auth/kiosk-pin` + `POST /v1/auth/kiosk-pin/rotate` debe añadirse a `zentto-timesheet/src/routes/*` y actualizar OpenAPI.
- [ ] **SDK `@zentto/timesheet-client`**: falta módulo `auth.kioskPin.verify(pin)` y `auth.kioskPin.rotate(employeeId)`. Bump minor (0.2.0).
- [ ] **Auth cross-cookie**: cookie `zentto_session` con domain `.zentto.net` debe incluir path scope correcto para que `timesheet.zentto.net` la lea. Verificar con `zentto-auth` maintainers que no haya restricción path.
- [ ] **Observabilidad**: logs de `attendance.*` y `kioskPin.*` deben emitir a `zentto-infra` logging stack (loki) con campos `tenantId`, `employeeRefId`, `action`, `kiosk`.
- [ ] **Nginx**: rate limit `/v1/auth/kiosk-pin` debe ser más agresivo (5/min/IP) — PR paralela en `zentto-infra`.
- [ ] **CORS**: verificar que `timesheet.zentto.net` y `timesheetdev.zentto.net` están en whitelist CORS del API.
- [ ] **Notify**: recordatorios diarios de pausa + auto-close nocturno requieren topic en `zentto-notify` — coordinar con owner del microservicio.
- [ ] **Feature flag**: `ts.kiosk.enabled` por tenant (recomendado para rollout gradual).
- [ ] **`zentto-report`**: template `timesheet_month.json` debe publicarse antes de Fase 5.

---

## 12. Entregables siguientes

- [ ] **Este brief** — revisión PO.
- [ ] **PR docs**: copiar este brief a `zentto-erp-docs` como `docs/timesheet/portal-implementation.md` + ADR corto.
- [ ] **Tickets GitHub** (crear en `zentto-erp/zentto-timesheet`):
  - `feat(api): migración 00010 ts.KioskPin + SPs Set/Verify/Rotate/Disable`
  - `feat(api): endpoints /v1/auth/kiosk-pin + /rotate`
  - `feat(frontend): bootstrap Next.js portal + auth shell + /login`
  - `feat(frontend): dashboard empleado + clockIn`
  - `feat(frontend): /tiempos tab Día + /nuevo + /[id]`
  - `feat(frontend): /tiempos tab Periodo`
  - `feat(frontend): /tiempos tab Semana (agenda calendar)`
  - `feat(frontend): /tiempos tab Rápido (matriz) + /serie + /favoritos`
  - `feat(frontend): /aprobaciones + bulk actions`
  - `feat(frontend): /carga-laboral dashboard ejecutivo`
  - `feat(frontend): /kiosko PIN + panel acciones`
  - `feat(frontend): /reportes PDF`
  - `feat(frontend): PWA offline queue`
  - `feat(frontend): command palette + shortcuts`
- [ ] **Tickets GitHub** (en `DatqBoxWeb` monorepo):
  - `feat(shared-ui): ZenttoBarChart + ZenttoLineChart + ZenttoKpiDeltaCard (Recharts)`
  - `feat(shared-ui): ZenttoClockButton + ZenttoStatusChip`
  - `feat(design-tokens): tokens workload + timesheet + approval + kiosko`
  - `feat(timesheet-ui): new package with ZenttoTimeKiosk + ZenttoPinPad + ZenttoFavoritesPicker + ZenttoTimesheetMatrix + ZenttoWeekAgendaCalendar + ZenttoDayDetailTimeline`
- [ ] **Ticket en `zentto-report`**: `feat(templates): timesheet_month.json`.
- [ ] **Ticket en `zentto-infra`**: `feat(nginx): rate limit kiosk-pin + dominios timesheet(dev).zentto.net`.

---

## 13. Referencias

- Brief conceptual previo — `docs/design/timesheet-carga-laboral-brief.md`.
- Inventario shared-ui — `web/modular-frontend/packages/shared-ui/src/index.tsx`.
- Vertical layout — `web/modular-frontend/packages/vertical-layout/src/ZenttoVerticalLayout.tsx`.
- Patrón frontend standalone — `zentto-hotel/frontend/`, `zentto-notify/dashboard/`.
- SDK auth — `@zentto/auth-client@0.4.0` (`zentto-auth/client/`).
- SDK timesheet — `@zentto/timesheet-client@0.1.0` (ya publicado).
- Recharts — https://recharts.org/.
- TanStack Query v5 — https://tanstack.com/query/v5.
- Polaris, Carbon, Atlassian, SAP Fiori Horizon — ver §2 del brief conceptual.
- MARIProject 6e / 14e — PDFs del PO (modelo de datos y flujos).
- RD-Ley 8/2019 España — registro horario obligatorio.
- Memoria proyecto:
  - Sin `<table>` HTML — `feedback_no_html_tables.md`.
  - Dashboards con acordeones — `feedback_dashboard_accordions.md`.
  - Feature branch desde developer — `feedback_git_workflow_feature_branch.md`.
  - Colisión numeración goose — `feedback_goose_numbering_race.md`.
  - Impacto zentto-infra — `feedback_always_check_zentto_infra_impact.md`.
