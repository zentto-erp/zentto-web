# Design Brief — module-nomina / Registro de tiempos + Carga laboral

> Versión: 2026-04-23 · Autor: zentto-designer · Estado: Propuesta para revisión.
> Ámbito: `packages/module-nomina` + ampliación `packages/shared-ui` + nuevo `packages/shared-charts` (pendiente decisión).

---

## 1. Contexto

### 1.1 Origen funcional

Las dos pantallas nacen como port/adaptación de flujos ya validados por décadas en el mercado ERP, concretamente **SAP Business One + MARIProject**:

| Documento fuente | Pantalla objetivo en Zentto |
|---|---|
| MARIProject 6e — "Registro de tiempos" | `/nomina/tiempos` (empleado + manager) |
| MARIProject 14e — "Análisis de carga laboral" | `/nomina/carga-laboral` (RRHH + gerencia) |

El objetivo NO es clonar la UI alemana de SAP (denso, anticuado, modal-heavy), sino tomar **el modelo de datos y las reglas de negocio** y expresarlos con el estándar visual Zentto y los patrones contemporáneos de Linear, HubSpot, Toggl y SAP Fiori Horizon.

### 1.2 Estado actual del código

Inventario leído en esta sesión:

- `packages/module-nomina/src/pages/NominaHome.tsx` — dashboard stub con 4 `DashboardKpiCard` y 8 `DashboardShortcutCard`. KPIs "Horas Extras" y "Ausentismo" en `"—"`. No hay pantalla de timesheet; tampoco pantalla de carga laboral.
- `packages/module-nomina/src/hooks/` — ya existen `useEmpleados`, `useNomina`, `useRRHH`, `useVacacionesSolicitudes`. **No existen** hooks para `timesheet`, `attendance` ni `workload`.
- `packages/shared-ui/src/index.tsx` — exporta `DashboardKpiCard`, `DashboardShortcutCard`, `DashboardSection`, `ZenttoFilterPanel`, `ZenttoRecordTable` (wrapper de `<zentto-grid>`), `RightDetailDrawer`, `ConfirmDialog`, `FormDialog`, `ContextActionHeader`, `ModulePageShell`, `FormGrid`, `CustomStepper`, `ZenttoLayout`, `ZenttoVerticalLayout`, `BrandingProvider`, `brandColors`. **Sin componente de charts.**
- `packages/design-tokens/src/tokens/color.ts` — paleta Zentto lista (`brand.accent`, `brand.teal`, `brand.success`, `brand.danger`, `brand.shortcutViolet`, `brand.shortcutSlate`, `brand.indigo`, etc.) + roles semánticos `lead` y `priority`. **No hay** roles semánticos de "capacidad/carga/objetivo".
- Schema BD `hr` hoy solo cubre Seguridad Social ES. Timesheet, asistencia y calendario de jornada **no existen** (se deberán crear vía migraciones goose + SPs duales PG/MSSQL, pero eso queda fuera del scope de este brief — solo lo enumeramos como dependencia en §12).

### 1.3 Job-to-be-done

**Empleado (actor A):** "Al empezar mi día quiero fichar en 1 click y, cuando termino una tarea, imputar las horas al proyecto/ticket sin salir de mi flujo."

**Manager de equipo (actor B):** "Quiero ver quién está rojo hoy (sin fichar, horas extras descontroladas, días pasados sin imputar) y aprobar la semana de mi gente en un bloque."

**RRHH/Gerencia (actor C):** "Quiero saber si estoy sobre o sub-asignando al equipo antes de cerrar contratos nuevos, y poder bajar al detalle por empleado, mes y proyecto."

### 1.4 Pain points validados hoy

- Dashboard nómina no responde preguntas operativas: "¿Quién no ha fichado?" "¿Cuántas horas extras lleva el mes?" (los KPIs están en `—`).
- No hay forma de imputar horas a un proyecto desde el producto — el personal operativo lo hace en hojas de Excel paralelas.
- La gerencia no tiene visibilidad de carga laboral → decisiones de contratación a ciegas.

---

## 2. Referencias enterprise

### 2.1 Design systems que aplican

| Sistema | URL del patrón relevante | Uso en este brief |
|---|---|---|
| **Polaris (Shopify)** | [polaris.shopify.com/components/feedback/banner](https://polaris.shopify.com/components/feedback/banner) · [components/selection/tabs](https://polaris.shopify.com/components/selection/tabs) · [patterns/date-picking](https://polaris.shopify.com/patterns/date-picking) | Banner de advertencia "registro atrasado", tabs de los 4 modos (Período/Rápido/Semana/Día), picker de período mensual, empty states |
| **Carbon (IBM)** | [carbondesignsystem.com/components/data-table/usage](https://carbondesignsystem.com/components/data-table/usage) · [components/tabs/usage](https://carbondesignsystem.com/components/tabs/usage) · [patterns/dashboard-pattern](https://carbondesignsystem.com/patterns/dashboard-pattern) | Densidad editable de la matriz semanal tipo spreadsheet, tabs densos, grid de KPIs del dashboard de carga |
| **Atlassian Design System** | [atlassian.design/components/inline-edit/examples](https://atlassian.design/components/inline-edit/examples) · [components/empty-state](https://atlassian.design/components/empty-state) | Edición inline de celdas horas (tab→next cell, Enter→commit, Esc→cancel) y empty-state con CTA "Crear primer registro" |
| **SAP Fiori Horizon** | [experience.sap.com/fiori-design-web/timesheet](https://experience.sap.com/fiori-design-web/timesheet) · [fiori-design-web/calendar](https://experience.sap.com/fiori-design-web/calendar) | Modelo de datos (asistencia vs proyecto, registro en serie, favoritos) y calendario semanal con bloques |
| **Material Design 3** | [m3.material.io/components/date-pickers](https://m3.material.io/components/date-pickers) · [components/tabs](https://m3.material.io/components/tabs) · [components/bottom-app-bar](https://m3.material.io/components/bottom-app-bar) | Base MUI ya adoptada — date pickers, tabs, bottom bar en mobile para el kiosco |
| **Lightning (Salesforce)** | [lightningdesignsystem.com/components/path](https://lightningdesignsystem.com/components/path) | Workflow de aprobación del timesheet (borrador → enviado → aprobado) como path-progress |
| **Base Web (Uber)** | [baseweb.design/components/timepicker](https://baseweb.design/components/timepicker) | TimePicker para entrada/salida manuales |

### 2.2 Productos de mercado como benchmark

| Producto | Qué copiamos | Qué NO copiamos |
|---|---|---|
| **BambooHR** — Time Tracking | La "pared verde" de entrada/salida en mobile con botón gigante; "Pending approval" como bandeja clara para el manager | El look-and-feel demasiado HR-consumer; queremos un tono más enterprise |
| **Factorial** — Registro horario | El inline panel dentro del dashboard del empleado (sin modal, sin salir del home); banner legal de recordatorio horario (requisito España RD 8/2019) | El énfasis en "geolocalización obligatoria" — Zentto lo deja opcional por empresa |
| **Rippling** — Timesheets | El **registro en serie** mediante selección con `Shift+click` sobre el calendario para "desde X hasta Y con este proyecto" | La densidad excesiva: tenemos apps hermanas medical/hotel que viven en mobile |
| **Toggl Track** | La **matriz semanal** como grid tipo spreadsheet con navegación por teclado (Tab/Arrow/Enter); los **favoritos como chips arriba** | La gamificación de "pomodoro timer" |
| **Clockify** | El **color-coding** por proyecto en la vista calendario semanal (bloques con color de proyecto) y el picker "repeat yesterday" | El stack de botones flotantes, visualmente ruidoso |
| **SAP Fiori Horizon — Timesheet app** | Los 4 modos (Period/Fast-entry/Calendar/Day) como pestañas y los **favoritos** | La densidad alemana de 12 columnas en una sola fila |
| **Linear** — Command palette + keyboard-first | `Cmd+K` para abrir "nuevo registro", atajos `G then T` para ir a timesheet, `Cmd+Enter` para enviar a aprobación | — |
| **HubSpot Sales Hub** — Workload dashboard | Las **barras agrupadas con línea de objetivo** en el dashboard de capacidad comercial, y el drill-down al hacer click en barra que abre un side-panel con la tabla detallada | — |
| **Harvest** — Reports | El **time slider** de período en el dashboard de carga laboral (arrastras el mes y todo se recalcula) | La paleta corporativa naranja-beige — usamos la Zentto |

---

## 3. Principios rectores para esta mejora

1. **Un registro, un click** (inspirado Factorial + Toggl): desde el home del empleado, fichar entrada o imputar 1 hora al proyecto favorito debe ocurrir en **≤ 2 interacciones**. No se abren modales para tareas diarias.
2. **Diferenciación visual entre asistencia y proyecto** (MARIProject 6e §1.1 + Fiori): asistencia = chip neutro con icono reloj, proyecto = chip con color del proyecto. Jamás se mezclan en la misma fila sin distinción.
3. **Modo de entrada preferido por contexto** (Carbon + Rippling):
   - Empleado desktop → vista "Semana calendario" por default.
   - Empleado mobile → "Día" por default (vertical, un bloque por hora).
   - Kiosco compartido → `ZenttoTimeKiosk` full-screen dedicado (sin sidebar, sin distractores).
   - Manager → "Período" + drill a "Registro rápido".
4. **Accesibilidad por teclado nativa** (Linear + Toggl): la matriz semanal es un grid accesible ARIA con navegación `Tab/Arrow/Enter/Esc` sin depender del ratón. Los atajos del kiosco también existen con teclado.
5. **Estados visuales semáforo no daltónicos** (Carbon AA): cualquier status (dentro/fuera de rango, sub/sobre-asignado) usa **color + icono + texto**, nunca solo color. La paleta base usa verde `brand.success` y rojo `brand.danger` ya existentes, nunca inventamos.
6. **Dashboard de carga laboral en acordeones** (regla Zentto + Carbon): 4 secciones colapsables — Resumen ejecutivo / Por empleado / Por proyecto / Tendencia anual — con la primera expandida por default. Reduce ruido visual y permite scroll predecible.
7. **Mobile-first real** (regla Zentto): la vista Día del timesheet debe ser utilizable desde el móvil del técnico de campo; el kiosco debe funcionar en tablet apaisada.

---

## 4. Pantalla A — Registro de tiempos (`/nomina/tiempos`)

### 4.1 Wireframe desktop

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ ZenttoLayout header                                                                │
├────────────────────────────────────────────────────────────────────────────────────┤
│ Registro de tiempos                         [Jue 23 Abr 2026]  [Semana 17 ▼]       │
│ ┌──────────────────────────────────────────────────────────────────────────────┐   │
│ │ TIME BAR (chips de estado del día — sticky top)                              │   │
│ │ ┌──────────┬──────────┬──────────┬──────────────────┬──────────────────┐     │   │
│ │ │ 🕐 08:42  │ ⏸ 00:35  │ ⚒ 07:12  │ 📊 +2.4h extras  │ ⏳ Pend. aprob.   │     │   │
│ │ │ Entrada  │ Pausa    │ Trabajado│ (este mes)       │ (semana 16)       │     │   │
│ │ └──────────┴──────────┴──────────┴──────────────────┴──────────────────┘     │   │
│ └──────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                    │
│ ┌─ Asistencia ────────────────────────┐  ┌─ Favoritos proyectos ──────────────┐    │
│ │ [▶ Entrada]  [⏸ Pausa]  [⏹ Salida]  │  │ [⭐ CRM · Migración · Backend]      │    │
│ │ [🏢 Salida empresa]                 │  │ [⭐ Hotel · Fase 2 · Consultoría]   │    │
│ │ Últimos 5 fichajes ↓                │  │ [⭐ Ticket #1234 · Soporte]        │    │
│ │ 08:42 IN   · Oficina · GPS ok       │  │ [+ Añadir favorito]                 │    │
│ │ 12:30 OUT  · Pausa                  │  └────────────────────────────────────┘    │
│ │ 13:05 IN   · Pausa-fin              │                                            │
│ └─────────────────────────────────────┘                                            │
│                                                                                    │
│ [📅 Período] [⚡ Registro rápido] [🗓 Semana calendario] [🕐 Día]    ← Tabs Mui    │
│ ─────────────────────────────────────────────────────────────────────────────────  │
│                                                                                    │
│   ⟨⟨ Vista activa — render según tab ⟩⟩                                            │
│                                                                                    │
│ ─────────────────────────────────────────────────────────────────────────────────  │
│ [Guardar borrador]                            [Enviar a aprobación del supervisor] │
└────────────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Wireframe de cada tab

#### 4.2.1 Tab "Período" (mensual)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Abril 2026                                   [◀ Mes anterior]   [Mes siguiente ▶]│
├──┬────────┬──────────┬────────────┬──────────┬─────────┬──────────┬──────────────┤
│  │ Día    │ Previsto │ Asistencia │ Proyecto │ Saldo   │ Estado   │ Acciones     │
├──┼────────┼──────────┼────────────┼──────────┼─────────┼──────────┼──────────────┤
│  │ L 01   │ 8h       │ 8h 15m     │ 7h 30m   │  +0h 15m│ ✓ Aprob. │ [Ver]        │
│  │ M 02   │ 8h       │ 7h 00m     │ 6h 50m   │  -1h 00m│ ⚠ Atrasado│ [Editar]     │ ← fila roja
│  │ X 03   │ 8h       │ 8h 30m     │ 8h 00m   │  +0h 30m│ ✓ Aprob. │ [Ver]        │
│  │ ...                                                                           │
├──┼────────┼──────────┼────────────┼──────────┼─────────┼──────────┼──────────────┤
│  │ TOTAL  │ 168h     │ 165h 20m   │ 158h 00m │  -2h 40m│ 8 pend.  │              │
└──┴────────┴──────────┴────────────┴──────────┴─────────┴──────────┴──────────────┘
```

Implementado con `<ZenttoRecordTable>` (wrapper `<zentto-grid>`). Fila roja = `sx` condicional por `renderCell` del grid (semáforo Zentto) cuando `saldo < 0`.

#### 4.2.2 Tab "Registro rápido" (matriz semanal tipo spreadsheet)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Semana 17 · 20–26 Abr                            [◀]  [Hoy]  [▶]  [💾 Auto-save] │
├────────────────────────────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬────┤
│ Proyecto / Fase / Servicio │ L 20 │ M 21 │ X 22 │ J 23 │ V 24 │ S 25 │ D 26 │ Σ  │
├────────────────────────────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼────┤
│ CRM · Migración · Backend  │ 4.0  │ 3.5  │ 2.0  │ 4.0  │      │      │      │13.5│
│ CRM · Migración · QA       │      │      │ 2.0  │      │ 2.0  │      │      │ 4.0│
│ Hotel · Fase2 · Consultoría│ 4.0  │ 4.5  │ 4.0  │ 4.0  │ 4.0  │      │      │20.5│
│ + Añadir fila              │                                                     │
├────────────────────────────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼────┤
│ Total imputado             │ 8.0  │ 8.0  │ 8.0  │ 8.0  │ 6.0  │ 0    │ 0    │38.0│
│ Asistencia                 │ 8.0  │ 7.5  │ 8.5  │ 7.2  │ 6.0  │ —    │ —    │37.2│
│ Diferencia                 │ 0.0  │-0.5  │+0.5  │-0.8  │ 0.0  │ —    │ —    │-0.8│ ← semáforo
└────────────────────────────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴────┘

Atajos: Tab=siguiente celda · ↑↓←→=navegar · Enter=commit · Esc=revertir
        Ctrl+D=copiar celda abajo · Ctrl+R=repetir fila ayer · Ctrl+F=favoritos
```

Implementado con **`ZenttoTimesheetGrid`** (nuevo componente, §5.3). **No es** `<zentto-grid>` porque necesita edición inline celda-a-celda con semántica especial (columnas = días, filas = combinación proyecto+fase+servicio); sí reutiliza tokens y densidad del datagrid.

#### 4.2.3 Tab "Semana calendario"

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Semana 17 · 20–26 Abr                                    [◀]  [Hoy]  [▶]         │
├──────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬─────────┤
│      │ L 20     │ M 21     │ X 22     │ J 23     │ V 24     │ S 25     │ D 26    │
├──────┼──────────┼──────────┼──────────┼──────────┼──────────┼──────────┼─────────┤
│ 08h  │          │          │          │ ⬛ Async │          │          │         │
│ 09h  │ 🟦 CRM    │ 🟦 CRM   │ 🟩 Hotel │          │ 🟩 Hotel │          │         │
│ 10h  │ Migración│ Migración│ Fase2    │ 🟩 Hotel │ Fase2    │          │         │
│ 11h  │ Backend  │ Backend  │          │ Fase2    │          │          │         │
│ 12h  │          │ 🟨 Pausa │ 🟨 Pausa │          │ 🟨 Pausa │          │         │
│ 13h  │ 🟨 Pausa │ 🟦 CRM   │ 🟦 CRM   │ 🟨 Pausa │          │          │         │
│ 14h  │ 🟩 Hotel │ Migr. QA │ Migr. QA │ 🟦 CRM    │          │          │         │
│ 15h  │ Fase2    │          │          │ Migración│          │          │         │
│ ...                                                                              │
└──────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴─────────┘

Drag-to-create: click y arrastra vertical para crear bloque con favorito seleccionado
Click bloque: abre RightDetailDrawer con formulario de edición (horas, notas, actividad)
```

Color de bloque = color estable del proyecto (derivado con `stringToColor()` + paleta Zentto; los proyectos estratégicos permiten override manual desde ajustes).

#### 4.2.4 Tab "Día"

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Jueves 23 Abr 2026                                                [Registrar +]  │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────┬──────┬─────────────────────────────┬─────────┬──────────────┬─────────┐ │
│ │ De   │ A    │ Proyecto / Servicio         │ Horas   │ Actividad    │         │ │
│ ├──────┼──────┼─────────────────────────────┼─────────┼──────────────┼─────────┤ │
│ │ 08:42│ 12:30│ 🟦 CRM · Migración · Backend│ 3h 48m  │ Review PRs   │ [✏][🗑] │ │
│ │ 12:30│ 13:05│ 🟨 Pausa comida             │ 0h 35m  │ —            │         │ │
│ │ 13:05│ 15:20│ 🟦 CRM · Migración · Backend│ 2h 15m  │ Bug #4312    │ [✏][🗑] │ │
│ │ 15:20│ 17:00│ 🟩 Hotel · Fase2 · Consult. │ 1h 40m  │ Reunión clte │ [✏][🗑] │ │
│ └──────┴──────┴─────────────────────────────┴─────────┴──────────────┴─────────┘ │
│                                                                                  │
│ Notas del día (md)                                                               │
│ ┌──────────────────────────────────────────────────────────────────────────────┐ │
│ │ Revisé los 3 PRs pendientes. Bloqueador con middleware callSp en branch…     │ │
│ └──────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Wireframe mobile (375px — el mismo usuario empleado)

```
┌───────────────────────────┐
│ ≡  Registro tiempos    ⋮  │
├───────────────────────────┤
│ 🕐 08:42 — Entrada        │
│ ⚒ 07:12 trabajadas        │
│ 📊 +2.4h extras mes       │
├───────────────────────────┤
│ [▶  ENTRADA/SALIDA]       │
│ [⏸  PAUSA]                │
├───────────────────────────┤
│ Favoritos                 │
│ [⭐ CRM Backend   +1h]     │
│ [⭐ Hotel F2      +1h]     │
│ [⭐ Ticket #1234  +1h]     │
├───────────────────────────┤
│ Hoy — Jue 23 Abr          │
│ ● 08:42 IN                │
│ ● 12:30 PAUSA 35m         │
│ ● 13:05 CRM Backend 3h    │
│ ● 15:20 Hotel F2 1h 40m   │
│                           │
│ [+ Añadir registro]       │
├───────────────────────────┤
│ Tabs secundarios:         │
│ [📅][⚡][🗓][🕐]            │
└───────────────────────────┘
```

Los 4 tabs siguen existiendo como bottom-bar `MUI Tabs variant="scrollable"` con iconos. En mobile, "Registro rápido" degrada a lista vertical por día (no hay matriz), "Semana calendario" degrada a "Día siguiente/anterior" con swipe.

### 4.4 Kiosko "Time Touch" (ruta dedicada: `/nomina/kiosko`)

Pantalla dedicada, sin sidebar, sin sidebar, sin `ZenttoLayout`. Se activa en terminales compartidos en planta/recepción. El usuario se identifica con tarjeta NFC, PIN o QR (fuera de scope de este brief, pero el contrato del componente lo soporta).

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                                                                  │
│                              🕐 14:23:07   Jueves 23 Abr                         │
│                                                                                  │
│        Hola, [Foto]  María López                              [Cerrar sesión]   │
│                                                                                  │
│   ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐   │
│   │                      │  │                      │  │                      │   │
│   │      ▶               │  │      ⏸               │  │      ⏹               │   │
│   │                      │  │                      │  │                      │   │
│   │    ENTRADA          │  │     PAUSA            │  │     SALIDA           │   │
│   │                      │  │                      │  │                      │   │
│   └──────────────────────┘  └──────────────────────┘  └──────────────────────┘   │
│                                                                                  │
│   ┌──────────────────────┐  ┌──────────────────────┐                             │
│   │      📂               │  │      🏢               │                             │
│   │   SELECCIONAR        │  │   SALIDA EMPRESA     │                             │
│   │   PROYECTO           │  │   (fin jornada)      │                             │
│   └──────────────────────┘  └──────────────────────┘                             │
│                                                                                  │
│                        Último fichaje: 13:05 · Vuelta de pausa                   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

Cada botón = 240×240 mínimo, contraste AAA, feedback sonoro opcional, `aria-label` explícito, tras tap se muestra toast 3s "✓ Entrada registrada 14:23" y auto-cerrar sesión en 10s.

### 4.5 Reglas funcionales (cross-tabs)

- **Registrar posteriormente**: cualquier tab permite cambiar el día seleccionado. Si `fecha < hoy - N días` (config empresa, default `N=7`), se muestra `<Alert severity="warning">Estás registrando N días atrás. Se notificará al supervisor.</Alert>` antes del submit.
- **Editar/borrar**: botones solo visibles si `estado === 'DRAFT' || estado === 'REJECTED'`. Si está `SUBMITTED` o `APPROVED`, el botón queda deshabilitado con tooltip "Registro validado, contacta a tu supervisor".
- **Registro en serie**: botón "Registrar en serie" abre `FormDialog` con `DateRangePicker` + selector proyecto/fase/servicio + horas/día → genera N registros de golpe (endpoint server-side).
- **Favoritos**: chips arriba de la vista activa. Click en chip abre mini-popover "¿cuántas horas?" → commit. Max 8 favoritos visibles + overflow `•••`.
- **Copiar registro**: botón contextual en cada fila/bloque → copia al día siguiente (mismo proyecto/fase/actividad, distinto día).
- **Imprimir hoja**: acción header `[📄 PDF mensual]` → genera PDF con `@zentto/report` (template `timesheet_month.json`) + campos "Firma empleado / Firma cliente".
- **Workflow aprobación**: path `DRAFT → SUBMITTED → APPROVED | REJECTED → (editar) → SUBMITTED`. Visualizado arriba como `CustomStepper` (ya existe en shared-ui).
- **Vínculo con tickets**: el selector de "Proyecto" acepta también "Ticket soporte". Al seleccionar un ticket, se muestra chip `🎫 #1234 — título` y las horas se imputan al ticket (endpoint compartido con zentto-tickets).

---

## 5. Especificación de componentes nuevos

Los 5 componentes se crean en `packages/shared-ui/src/components/` (+ tipos en `packages/shared-ui/src/index.tsx`). Se considera spin-off a `packages/shared-charts` solo si el chart wrapper crece en número de variantes. Para este brief, quedan **todos en shared-ui**.

### 5.1 `ZenttoBarChart`

Wrapper sobre la librería de charts elegida (§6). Responsabilidades: tokens Zentto, estados `loading/empty/error`, responsividad, accesibilidad, API estable desacoplada de Recharts.

```ts
export type BarChartSeries = {
  key: string;                 // 'capacidad' | 'carga' | 'objetivo'
  label: string;               // Traducido para legend
  color: string;               // Token semántico (ver §7)
  type?: 'bar' | 'line';       // Permite superponer línea sobre barras (objetivo)
  dashed?: boolean;            // Líneas discontinuas para targets
};

export type ZenttoBarChartProps = {
  /** Datos por categoría (mes, empleado, proyecto…) */
  data: Array<Record<string, string | number>>;
  /** Key de la categoría en X axis */
  xKey: string;
  /** Series a pintar */
  series: BarChartSeries[];
  /** Formato del valor en tooltip/axis. Default: Intl.NumberFormat */
  valueFormatter?: (v: number) => string;
  /** Sufijo del valor (ej. 'h', 'd', '%'). */
  unit?: string;
  /** Altura fija (default 320). */
  height?: number;
  /** 'grouped' | 'stacked'. Default 'grouped'. */
  layout?: 'grouped' | 'stacked';
  /** Loading skeleton */
  loading?: boolean;
  /** Empty state (si data.length===0) */
  emptyState?: { title: string; description?: string; action?: React.ReactNode };
  /** Error state */
  error?: { message: string; onRetry?: () => void } | null;
  /** Click en barra — drill-down. Recibe categoría + serie. */
  onBarClick?: (payload: { category: string; series: string; value: number }) => void;
  /** aria-label global del chart (accesibilidad) */
  ariaLabel: string;
  /** Exportar chart como PNG/SVG (header action) */
  exportable?: boolean;
};
```

**Estados**:
- `loading` → `<Skeleton variant="rectangular" height={height}/>` con shimmer.
- `empty` → `EmptyStateSpec` centrado con CTA opcional (copia del patrón `ZenttoRecordTable`).
- `error` → `<Alert severity="error">` con `<Button onClick={onRetry}>Reintentar</Button>`.

**Accesibilidad**:
- `role="img"` + `aria-label`.
- Tabla oculta `<table hidden>` con los mismos datos como fallback para screen readers — excepción justificada al "no HTML tables": es tabla semántica oculta, no UI visible. Patrón Carbon Charts.
- Colores derivados de tokens; en `prefers-contrast: more`, se aumenta stroke-width y se añaden patterns (rayas).

### 5.2 `ZenttoLineChart`

Mismo contrato que `ZenttoBarChart` pero para time-series (tendencia anual, horas/día histórico). Props extra:

```ts
export type ZenttoLineChartProps = Omit<ZenttoBarChartProps, 'layout'> & {
  /** Area fill bajo la línea */
  filled?: boolean;
  /** Punto destacado */
  highlightIndex?: number;
  /** Smooth curve */
  curved?: boolean;  // default true
};
```

### 5.3 `ZenttoTimesheetGrid`

Matriz semanal editable. **No** es wrapper de `<zentto-grid>` (el grid está pensado para listas tabulares CRUD). Éste es un componente especializado.

```ts
export type TimesheetRowKey = string;  // `${projectId}|${phaseId}|${serviceId}`

export type TimesheetRow = {
  key: TimesheetRowKey;
  projectId: string;
  projectName: string;
  projectColor: string;        // Hex, derivado o override
  phaseId?: string;
  phaseName?: string;
  serviceId?: string;
  serviceName?: string;
  /** Horas por día: clave = ISO date 'YYYY-MM-DD', valor = horas decimales */
  hours: Record<string, number>;
  /** Estado del registro por día */
  status: Record<string, 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED'>;
  /** Nota por día (opcional) */
  notes?: Record<string, string>;
};

export type ZenttoTimesheetGridProps = {
  /** ISO 'YYYY-MM-DD' del lunes de la semana */
  weekStart: string;
  /** Filas */
  rows: TimesheetRow[];
  /** Horas de asistencia por día (fila footer comparativa) */
  attendanceHours?: Record<string, number>;
  /** Límite diario visual en header (ej. 8h jornada) */
  dailyQuota?: number;
  /** Callback al editar celda */
  onCellChange: (rowKey: TimesheetRowKey, date: string, hours: number) => void;
  /** Callback al añadir fila (trigger "+ Añadir fila") */
  onAddRow: () => void;
  /** Callback al eliminar fila */
  onRemoveRow: (rowKey: TimesheetRowKey) => void;
  /** Auto-save debounce (ms). Default 800. */
  autoSaveDebounce?: number;
  /** readonly si registro enviado */
  readonly?: boolean;
  /** Sólo lectura por celda (p.ej. APPROVED) */
  isCellReadonly?: (rowKey: TimesheetRowKey, date: string) => boolean;
  /** Copy en celda con Ctrl+D: mismo proyecto, día siguiente */
  enableKeyboardShortcuts?: boolean;  // default true
  /** Integración favoritos: mostrar fila `+ Añadir desde favoritos` */
  onPickFavorite?: () => void;
};
```

**Estados por celda**:
- `default` — fondo surface, borde `divider`.
- `hover` — fondo `alpha(primary.main, 0.06)`.
- `focus` — borde `primary.main` 2px (outline visible AA).
- `editing` — `<TextField>` inline, `type="number" step="0.25"`.
- `readonly` (APPROVED) — fondo `action.disabledBackground`, cursor `not-allowed`, tooltip "Aprobado el DD/MM".
- `error` (total > dailyQuota sin aprobación de extras) — borde `error.main` + icono `⚠` con tooltip.

**Atajos teclado**:
| Tecla | Acción |
|---|---|
| `Tab` / `Shift+Tab` | Siguiente/anterior celda |
| `↑ ↓ ← →` | Navegar en grid |
| `Enter` | Commit y bajar |
| `Esc` | Revertir valor celda |
| `Ctrl+D` | Duplicar valor celda inmediatamente inferior |
| `Ctrl+R` | Repetir fila completa del día anterior |
| `Ctrl+F` | Abrir `ZenttoFavoritesPicker` |
| `Del` / `Backspace` sobre celda | Vaciar |

### 5.4 `ZenttoTimeKiosk`

Botón gigante pensado para touch. Full-width flex item.

```ts
export type ZenttoTimeKioskAction =
  | 'CLOCK_IN'
  | 'CLOCK_OUT'
  | 'PAUSE_START'
  | 'PAUSE_END'
  | 'PROJECT_SELECT'
  | 'COMPANY_EXIT';

export type ZenttoTimeKioskProps = {
  action: ZenttoTimeKioskAction;
  /** Texto grande */
  label: string;
  /** Icono MUI */
  icon: React.ReactNode;
  /** Colores semánticos: 'primary' (verde entrada), 'warning' (pausa), 'error' (salida), 'info' (selector proyecto) */
  variant: 'primary' | 'warning' | 'error' | 'info' | 'neutral';
  /** Touch feedback: vibration + sonido opcional */
  haptics?: boolean;
  /** Deshabilitado (ej: pausa ya activa) */
  disabled?: boolean;
  onPress: () => void | Promise<void>;
  /** Tamaño. Default 'xl' (240px) */
  size?: 'lg' | 'xl' | '2xl';
};
```

Dimensiones mínimas: 200×200 (`size='lg'`), 240×240 (`size='xl'`), 320×320 (`size='2xl'`). Contraste AAA (brand token + texto blanco/negro según variante). `type="button"` nativo, `aria-label` con label completo + contexto.

### 5.5 `ZenttoFavoritesPicker`

```ts
export type TimesheetFavorite = {
  id: string;
  label: string;          // "CRM · Migración · Backend"
  projectId: string;
  projectColor: string;
  phaseId?: string;
  serviceId?: string;
  activityId?: string;
  defaultHours?: number;  // sugerencia al click
  usageCount?: number;    // para ordenar
};

export type ZenttoFavoritesPickerProps = {
  favorites: TimesheetFavorite[];
  onPick: (fav: TimesheetFavorite, hours: number) => void;
  onManage: () => void;          // abre diálogo de gestión
  maxVisibleChips?: number;      // default 6 desktop / 3 mobile
  orientation?: 'horizontal' | 'vertical';  // vertical para sidebar
  loading?: boolean;
};
```

Renderiza `<Chip color="primary" variant="outlined">` por favorito, icono estrella, al click abre popover con `<TextField type="number">` preseleccionando `defaultHours`. Soporta arrastrar para reordenar (dnd-kit). Chip con color del proyecto como border-left.

---

## 6. Decisión — Librería de charts

### Recomendación: **Recharts**

**Por qué**:
1. **Licencia MIT** — compatible con productos privados `@zentto/*`. Nivo también MIT, pero Recharts pesa menos.
2. **Bundle size**: ~96KB gzipped (Recharts 2.x) vs Nivo ~180KB vs Apache ECharts ~420KB. En un micro-frontend que solo usa 3 tipos de chart, Recharts es el sweet spot.
3. **MUI fit**: API composicional basada en componentes React (no canvas imperativo) → encaja con el patrón MUI `sx`/`theme`. Tokens Zentto se pasan directo como `fill={theme.palette.primary.main}`.
4. **Time-series nativo**: `XAxis type="category" | "number"`, `Brush` para time-slider de carga laboral §7.2.
5. **Responsividad**: `<ResponsiveContainer>` nativo, no hay que calcular dimensiones.
6. **Accesibilidad**: soporta `role="img"` + tabla semántica oculta como fallback (patrón Carbon).

**Alternativas descartadas**:
- **Nivo** — más bonito out-of-the-box pero +90KB por tipo y API menos composicional. Reevaluar si necesitamos mapas/heatmaps en un roadmap futuro.
- **Apache ECharts** — potentísimo pero bundle excesivo para 3 charts. Guardarlo para un "Analytics Hub" dedicado.
- **Chart.js + react-chartjs-2** — Canvas-based, peor accesibilidad, tokens se pasan por plugin (friction). Descartado.
- **MUI X Charts** — sería el camino más ortodoxo, pero a día de hoy (`@mui/x-charts` v7) la implementación pro-features (Brush, grouped bars estables) aún requiere suscripción. Recharts es sin coste y cubre todo lo pedido.

**Instalación prevista**:
- `packages/shared-ui/package.json` → añadir `recharts@^2.12.0` como `peerDependency` (apps la instalan explícitamente → permite tree-shaking por app).
- `ZenttoBarChart` y `ZenttoLineChart` = adaptadores que **no exportan nada de Recharts directamente** → si un día migramos a Nivo, sólo cambiamos el interior.

---

## 7. Pantalla B — Dashboard carga laboral (`/nomina/carga-laboral`)

### 7.1 Wireframe desktop

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ZenttoLayout header                                                                  │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ Carga laboral de empleados                             [Año: 2026 ▼] [📤 Exportar]   │
│                                                                                      │
│ ┌─ ZenttoFilterPanel (lateral drawer en mobile, inline desktop) ──────────────────┐  │
│ │ Unidad negocio: [IT ✕] [Consultoría ✕] [+]   Tipo recurso: ◉ Indiv ○ Pool ○ Amb │  │
│ │ Rango: [01/01/2026] → [31/12/2026]   Empleado: [Autocompletar… ]   [Limpiar (3)]│  │
│ └────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│ ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│ │ KPI 1: Ocupación │ KPI 2: Sub-asign. │ KPI 3: Sobre-asig.│ KPI 4: Plan vs Real   │ │
│ │    82.4%          │    5 empleados     │    3 empleados    │  1240h / 1180h       │ │
│ │    ▲ +3.2% vs abr │    (<70% obj.)     │    (>110% obj.)   │  95.2% cumplimiento  │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│ ┌─ Accordion 1 · Resumen ejecutivo [expanded] ────────────────────────────────────┐  │
│ │                                                                                 │  │
│ │    <ZenttoBarChart                                                              │  │
│ │        xKey="mes"                                                               │  │
│ │        series=[                                                                 │  │
│ │          { key:'capacidad', label:'Capacidad (días)',   color: brand.indigo },  │  │
│ │          { key:'carga',     label:'Carga laboral (d)',  color: brand.teal   },  │  │
│ │          { key:'objetivo',  label:'Objetivo 90%',       color: brand.accent,   │  │
│ │                                                          type:'line', dashed:true}│  │
│ │        ]                                                                        │  │
│ │        onBarClick={(p)=>openDrillDown(p.category)}                              │  │
│ │    />                                                                           │  │
│ │                                                                                 │  │
│ │    ┌──────────────── Time slider (Brush component de Recharts) ────────────┐    │  │
│ │    │ ░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░                                │    │  │
│ │    │ Ene  Feb  Mar  Abr  May  Jun  Jul  Ago  Sep  Oct  Nov  Dic            │    │  │
│ │    └──────────────────────────────────────────────────────────────────────┘    │  │
│ └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│ ┌─ Accordion 2 · Por empleado [collapsed] ───────────────────────────────────────┐   │
│ │ (click expand → tabla con empleados + barras horizontales + semáforo)          │   │
│ └────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│ ┌─ Accordion 3 · Por proyecto [collapsed] ────────────────────────────────────────┐  │
│ │ (…)                                                                             │  │
│ └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│ ┌─ Accordion 4 · Tendencia anual [collapsed] ────────────────────────────────────┐   │
│ │ (…) ZenttoLineChart 12 meses                                                   │   │
│ └────────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Acordeones — contenido detallado

#### Accordion 1 · Resumen ejecutivo (default: expanded)
- `ZenttoBarChart` grouped bars + line (objetivo).
- `Brush` de Recharts como time-slider abajo (permite zoom temporal sin reload).
- Tooltip hover muestra: mes, capacidad (d), carga (d), delta % vs objetivo.

#### Accordion 2 · Por empleado
- `ZenttoRecordTable` (wrapper `<zentto-grid>`) con columnas:
  - Empleado (avatar + nombre)
  - Unidad de negocio
  - Capacidad del periodo (días)
  - Carga planificada (días)
  - Utilización % (barra horizontal con semáforo: <70% amarillo, 70–110% verde, >110% rojo)
  - Horas planificadas / realizadas
  - Botón "Ver detalle" → `RightDetailDrawer` con `ZenttoLineChart` personal.
- Filtro búsqueda inline del grid (`searchPlaceholder="Buscar empleado"`) + persistencia de vistas guardadas.

#### Accordion 3 · Por proyecto
- `ZenttoRecordTable` con una fila por proyecto mostrando carga agregada.
- Acción "Drill-down" abre `RightDetailDrawer` con barras por empleado asignado al proyecto.

#### Accordion 4 · Tendencia anual
- `ZenttoLineChart` 12 meses con 3 series (capacidad / carga / objetivo) + banda de confianza.
- Dropdown para comparar con año anterior (overlay).

### 7.3 Drill-down

Click en una barra del Accordion 1 → `RightDetailDrawer` (ya existe en shared-ui) con:
- Header: "Detalle — Abril 2026"
- Tabs: [Por empleado] [Por proyecto] [Por actividad]
- Body: `ZenttoRecordTable` con data filtrada al mes seleccionado.
- Footer: `[📄 Exportar Excel]` `[📊 Ver en timesheet]`.

### 7.4 Wireframe mobile (375px)

```
┌───────────────────────────┐
│ ≡ Carga laboral      🔍   │
├───────────────────────────┤
│ [📅 Abr 2026 ▼] [Filtros] │
├───────────────────────────┤
│ Ocupación                 │
│ 82.4%  ▲ +3.2%            │
├───────────────────────────┤
│ Sub-asignados: 5          │
│ Sobre-asignados: 3        │
├───────────────────────────┤
│ ▿ Resumen ejecutivo       │
│   ┌─────────────────────┐ │
│   │  [bar chart sw]     │ │ ← swipe horizontal
│   │  ▓▓░░▒░▓░░░░░        │ │
│   └─────────────────────┘ │
├───────────────────────────┤
│ ▸ Por empleado            │
│ ▸ Por proyecto            │
│ ▸ Tendencia anual         │
└───────────────────────────┘
```

En mobile los charts escalan con `ResponsiveContainer`; las barras se rotan 90° si hay <5 categorías para legibilidad. Time-slider se convierte en paginador `[◀ Mar] Abr [May ▶]`.

---

## 8. Tokens de diseño

### 8.1 Uso de tokens existentes (heredar)

| Semántica | Token Zentto | Hex Light | Uso |
|---|---|---|---|
| Background dashboard | `brand.bgPage` | `#f9fafb` | body |
| Surface card | `brand.bgCard` | `#ffffff` | cards, acordeones |
| Border | `brand.border` | `#e3e6e6` | grid cells, cards |
| Primary | `brand.accent` | `#FFB547` | CTAs, chip favorito activo, `objetivo` line color |
| Info (neutral) | `brand.teal` | `#007185` | chips asistencia, bloques calendario default |
| Success | `brand.success` | `#067D62` | estado APPROVED, celdas dentro de rango |
| Danger | `brand.danger` | `#cc0c39` | estado REJECTED, sobre-asignación, saldo negativo |
| Warning (pausa/warning) | `brand.accent` (reuse) | `#FFB547` | Alertas registro atrasado |
| Neutral 1 | `brand.shortcutSlate` | `#37475a` | header chips asistencia |
| Violet | `brand.shortcutViolet` | `#6B3FA0` | proyectos violeta (paleta proyectos) |
| Indigo | `brand.indigo` | `#6C63FF` | **Capacidad** serie |

### 8.2 Nuevos tokens semánticos a añadir a `design-tokens/tokens/color.ts`

Los añadimos dentro de `DesignTokens['color']` (nuevo roles block `workload` y `timesheet`). Siguen el patrón de los roles `lead` y `priority` ya definidos → se resuelven con `palette[paletteKey].main` en runtime respetando light/dark.

```ts
workload: {
  capacity:    { paletteKey: 'info',      hex: brand.indigo        },  // '#6C63FF'
  planned:     { paletteKey: 'info',      hex: brand.teal          },  // '#007185'
  target:      { paletteKey: 'warning',   hex: brand.accent        },  // '#FFB547'
  underLoaded: { paletteKey: 'warning',   hex: '#B07500'           },  // < 70%
  optimal:     { paletteKey: 'success',   hex: brand.success       },  // 70–110%
  overLoaded:  { paletteKey: 'error',     hex: brand.danger        },  // > 110%
},
timesheet: {
  attendance:  { paletteKey: 'secondary', hex: brand.shortcutSlate },
  project:     { paletteKey: 'info',      hex: brand.teal          },
  pause:       { paletteKey: 'warning',   hex: brand.accent        },
  overtime:    { paletteKey: 'error',     hex: brand.danger        },
  approved:    { paletteKey: 'success',   hex: brand.success       },
  draft:       { paletteKey: 'secondary', hex: brand.textMuted     },
  rejected:    { paletteKey: 'error',     hex: brand.danger        },
  submitted:   { paletteKey: 'primary',   hex: brand.accent        },
},
```

**Criterio AA**: todos los hex tienen contraste ≥ 4.5:1 contra `bgCard` (validado con WebAIM Contrast Checker para `#FFB547/#fff` → requiere texto `brand.dark`).

### 8.3 Paleta de proyectos (color-coding)

Los bloques del calendario semanal usan color por proyecto. Si el admin no asigna override, se deriva vía `stringToColor(projectId)` sobre un banco finito de 12 colores sólidos desaturados:

```
#1F6FEB  #067D62  #6B3FA0  #FFB547  #CC0C39  #007185
#37475A  #D2691E  #8B4513  #2E8B57  #4682B4  #DC143C
```

---

## 9. Accesibilidad

### 9.1 Teclado (todas las vistas)

| Contexto | Atajo | Acción |
|---|---|---|
| Global | `Cmd+K` | Command palette (ya existe) |
| Global | `G` then `T` | Ir a `/nomina/tiempos` |
| Global | `G` then `W` | Ir a `/nomina/carga-laboral` |
| Timesheet | `N` | Nuevo registro |
| Timesheet | `Cmd+Enter` | Enviar a aprobación |
| Timesheet grid | Ver §5.3 | Navegación celda |
| Kiosco | `1..6` | Seleccionar botón 1–6 |
| Kiosco | `Esc` | Cerrar sesión inmediata |
| Charts | `Enter` sobre barra | Drill-down |

Todos los atajos se registran vía `useKeyboardShortcut()` del `KeyboardShortcutsProvider` existente, y aparecen automáticamente en `KeyboardShortcutsCheatSheet`.

### 9.2 ARIA

- `ZenttoTimesheetGrid` → `role="grid"`, cada fila `role="row"`, cada celda `role="gridcell"` con `aria-readonly` dinámico, `aria-describedby` en celdas aprobadas, `aria-invalid` en celdas sobre-quota.
- `ZenttoBarChart` / `ZenttoLineChart` → `role="img"`, `aria-label` descriptivo ("Gráfico de barras: capacidad, carga y objetivo por mes") + `<table hidden>` con data-equivalent.
- `ZenttoTimeKiosk` → `<button>` nativo con `aria-label` completo ("Registrar entrada — botón grande").
- Acordeones dashboard → `<Accordion>` MUI ya usa `aria-expanded` y `aria-controls` correctamente.

### 9.3 Contraste y daltonismo

- Semáforo verde/rojo **siempre acompañado de icono** (`✓` verde, `⚠` rojo, `⬧` amarillo) y texto en inglés accesible.
- Línea de "objetivo" en charts = `brand.accent` **+ patrón punteado** (`strokeDasharray="5,5"`) → legible sin color.
- Modo `prefers-contrast: more` → borders 2px, box-shadow desactivado.

### 9.4 Foco visible

Todos los botones, chips y celdas editables respetan `:focus-visible` con outline `2px solid primary.main` + `outline-offset: 2px`. Ya es el default del tema Zentto; solo verificar en `ZenttoTimeKiosk` (los botones grandes en kiosco compartido deben tener foco ultra-visible con outline 4px en ese layout específico).

### 9.5 Mobile touch targets

- Mínimo 44×44 (Apple HIG) / 48×48 (Material AA).
- Kiosco: 200×200 mínimo.
- Botón "Añadir registro" desktop: 36 altura, mobile: 44 altura.

---

## 10. Internacionalización

Strings clave (ES = canónico, EN = fallback), dictados vía `@zentto/shared-i18n` (ya existente):

| Key | ES | EN |
|---|---|---|
| `nomina.tiempos.title` | Registro de tiempos | Time tracking |
| `nomina.tiempos.tab.period` | Período | Period |
| `nomina.tiempos.tab.fast` | Registro rápido | Fast entry |
| `nomina.tiempos.tab.week` | Semana calendario | Week calendar |
| `nomina.tiempos.tab.day` | Día | Day |
| `nomina.tiempos.clockIn` | Entrada | Clock in |
| `nomina.tiempos.clockOut` | Salida | Clock out |
| `nomina.tiempos.pauseStart` | Iniciar pausa | Start break |
| `nomina.tiempos.pauseEnd` | Fin de pausa | End break |
| `nomina.tiempos.companyExit` | Salida empresa | End of workday |
| `nomina.tiempos.submit` | Enviar a aprobación | Submit for approval |
| `nomina.tiempos.status.draft` | Borrador | Draft |
| `nomina.tiempos.status.submitted` | Pendiente | Pending |
| `nomina.tiempos.status.approved` | Aprobado | Approved |
| `nomina.tiempos.status.rejected` | Rechazado | Rejected |
| `nomina.tiempos.lateWarning` | Estás registrando {n} días atrás. Se notificará al supervisor. | You are logging {n} days late. Your supervisor will be notified. |
| `nomina.tiempos.seriesEntry` | Registrar en serie | Bulk entry |
| `nomina.tiempos.favoritesAdd` | Añadir favorito | Add favourite |
| `nomina.tiempos.printSheet` | Imprimir hoja mensual | Print monthly sheet |
| `nomina.tiempos.empty.day` | Aún no has registrado horas hoy. | You haven't logged any hours today yet. |
| `nomina.carga.title` | Carga laboral de empleados | Employee workload |
| `nomina.carga.kpi.occupation` | Ocupación promedio | Avg. occupation |
| `nomina.carga.kpi.underLoaded` | Sub-asignados | Under-assigned |
| `nomina.carga.kpi.overLoaded` | Sobre-asignados | Over-assigned |
| `nomina.carga.kpi.plannedVsActual` | Planificado vs Real | Planned vs Actual |
| `nomina.carga.series.capacity` | Capacidad | Capacity |
| `nomina.carga.series.planned` | Carga laboral | Workload |
| `nomina.carga.series.target` | Objetivo 90% | Target 90% |
| `nomina.carga.section.executive` | Resumen ejecutivo | Executive summary |
| `nomina.carga.section.byEmployee` | Por empleado | By employee |
| `nomina.carga.section.byProject` | Por proyecto | By project |
| `nomina.carga.section.annualTrend` | Tendencia anual | Annual trend |
| `nomina.carga.drillDown.title` | Detalle — {period} | Detail — {period} |
| `common.loading` | Cargando… | Loading… |
| `common.empty` | No hay datos para mostrar | No data to display |
| `common.retry` | Reintentar | Retry |
| `common.export` | Exportar | Export |

---

## 11. Criterios de aceptación (QA checklist)

### 11.1 Pantalla A — Registro de tiempos

- [ ] La ruta `/nomina/tiempos` existe y requiere auth cookie HttpOnly.
- [ ] Header TimeBar muestra hora entrada, pausa acumulada, trabajado, extras mes, estado aprobación.
- [ ] Los 4 tabs (Período/Rápido/Semana/Día) renderizan y el tab por default depende del breakpoint (desktop=Semana, mobile=Día).
- [ ] Tab "Período" usa `<ZenttoRecordTable>`, nunca `<table>` HTML.
- [ ] Filas con `saldo < 0` se pintan con fondo `alpha(error.main, 0.06)` + icono `⚠` + texto `Atrasado`.
- [ ] Tab "Registro rápido" permite editar celda con Tab/Arrow/Enter/Esc.
- [ ] `Ctrl+D` duplica celda al día siguiente; `Ctrl+R` repite fila día anterior; `Ctrl+F` abre favoritos.
- [ ] Auto-save dispara ≤ 800ms tras última edición y muestra indicador "Guardado • 14:12" en header.
- [ ] Tab "Semana calendario" soporta drag-to-create bloques; click sobre bloque abre `RightDetailDrawer`.
- [ ] Tab "Día" muestra timeline de registros + notas md y permite editar/borrar.
- [ ] Banner `<Alert severity="warning">` aparece si `fecha < hoy - 7 días`.
- [ ] Botón "Registrar en serie" abre `FormDialog` con `DateRangePicker` y crea N registros en backend.
- [ ] Chips de favoritos visibles desde los 4 tabs; click abre popover con horas sugeridas.
- [ ] Workflow visualizado en `CustomStepper`: `Borrador → Pendiente → Aprobado/Rechazado`.
- [ ] Proyecto seleccionable incluye opción "Ticket soporte" con icono `🎫`.
- [ ] Acción "Imprimir hoja mensual" genera PDF via `@zentto/report` con campos firma.
- [ ] Kiosco `/nomina/kiosko` se abre sin sidebar, botones 240×240 mín., auto-logout 10s tras último tap.
- [ ] Mobile (375px): layout degrada a una columna, bottom-tabs scrollable, botones touch ≥ 48px.
- [ ] Todos los hooks consumen API via react-query, sin mock.
- [ ] Todas las fechas persisten UTC-0; display convierte via `useTimezone()`.
- [ ] Navegación por teclado completa sin ratón en los 4 tabs.
- [ ] Contraste AA validado con axe-core.

### 11.2 Pantalla B — Dashboard carga laboral

- [ ] La ruta `/nomina/carga-laboral` existe y requiere auth + rol `hr-admin` o `manager`.
- [ ] Filter panel `<ZenttoFilterPanel>` con Unidad negocio (multi), Tipo recurso (toggle), Rango fechas, Empleado (autocompletar).
- [ ] 4 KPIs arriba usando `<DashboardKpiCard>` con trend chips.
- [ ] 4 acordeones (Ejecutivo / Por empleado / Por proyecto / Tendencia anual); solo el primero expandido al cargar.
- [ ] Accordion 1 renderiza `<ZenttoBarChart>` grouped bars (capacidad, carga) + línea objetivo punteada.
- [ ] `<Brush>` time-slider permite zoom temporal sin reload.
- [ ] Click en barra abre `<RightDetailDrawer>` con tabs y `<ZenttoRecordTable>` detallado.
- [ ] Accordion 2 muestra barra horizontal con semáforo (<70% / 70–110% / >110%).
- [ ] Accordion 4 renderiza `<ZenttoLineChart>` 12 meses + overlay año anterior.
- [ ] Empty state "No hay datos para este rango" con CTA "Cambiar filtros".
- [ ] Error state "No se pudo cargar" con botón Reintentar.
- [ ] Todas las tablas son `<ZenttoRecordTable>` (wrapper `<zentto-grid>`), nunca `<table>` HTML.
- [ ] Exportar Excel/PDF funciona desde header.
- [ ] Mobile (375px): charts escalan, acordeones colapsados por default excepto Resumen.
- [ ] Charts tienen `aria-label` + tabla semántica oculta.
- [ ] Lighthouse Accessibility ≥ 95.
- [ ] Lighthouse Performance ≥ 85 (chart primer render < 1.5s con 12 meses × 20 empleados).

### 11.3 Cross-cutting

- [ ] Sin `<table>` HTML en ningún lugar (verificado con `grep -r '<table' packages/module-nomina/src`).
- [ ] Sin MUI DataGrid (verificado: solo `<zentto-grid>` via `ZenttoRecordTable`).
- [ ] Sin mock data — todo via hooks react-query.
- [ ] Todas las strings vía `@zentto/shared-i18n` (ES/EN).
- [ ] Tema MUI Zentto respetado; no colores hex hardcodeados fuera de tokens.
- [ ] Componentes reutilizables en `packages/shared-ui` (no en `module-nomina`).

---

## 12. Riesgos e integración

### 12.1 Dependencias fuera de este brief (deben pedirse al agente integrador / backend)

| # | Qué falta | A quién | Flag |
|---|---|---|---|
| D1 | Schema `hr` ampliado: `hr.timesheet_entry`, `hr.attendance_event`, `hr.project_assignment`, `hr.work_calendar`, `hr.favorites` — **migraciones goose duales PG + MSSQL** | `datqbox-super-developer` + `datqbox-sqlserver` | Bloquea ambos pantallas |
| D2 | SPs `usp_hr_Timesheet_*` (List/Upsert/Submit/Approve/Reject) + `usp_hr_Attendance_*` + `usp_hr_Workload_*` | `datqbox-sqlserver` | Bloquea ambos |
| D3 | Endpoints OpenAPI en `web/contracts/openapi.yaml`: `/hr/timesheet`, `/hr/attendance`, `/hr/workload`, `/hr/favorites` | API team | Bloquea hooks react-query |
| D4 | Hooks react-query: `useTimesheet`, `useAttendance`, `useWorkload`, `useTimesheetFavorites` | `datqbox-super-developer` | Bloquea ambos |
| D5 | Decisión: geolocalización opcional por empresa (feature flag) para fichajes kiosco web/mobile | PO + security | No bloquea, sí UX |
| D6 | Integración tickets: endpoint para que timesheet impute horas a `zentto-tickets.ticket_id` | `zentto-integration-reviewer` | Bloquea feature "ticket en selector proyecto" |
| D7 | Feature flag `nomina.timesheet.enabled` por empresa | Platform team | Recomendado para rollout gradual |
| D8 | `@zentto/report` template `timesheet_month.json` para PDF firma cliente/empleado | Report team | Bloquea "Imprimir hoja" |

### 12.2 Riesgos UX

| Riesgo | Mitigación |
|---|---|
| **Empleado olvida marcar pausa** → distorsiona horas reales | Recordatorio silencioso tras 2h continuas sin pausa registrada (push notification browser + banner no bloqueante) |
| **Kiosco compartido sin cerrar sesión** → fichajes cruzados | Auto-logout tras 10s del último tap + confirmación visual 3s "Hola {nombre}" al identificarse |
| **Matriz semanal demasiado ancha en laptop 13"** | Scroll horizontal fluido + sticky "Proyecto/Fase/Servicio" left column; columnas días compactables a 60px mínimo |
| **Registros atrasados masivos al final de mes** | Badge "X días sin registrar" en sidebar desde día 3 sin fichaje; email automático día 5 |
| **Sobre-asignación invisible hasta que es tarde** | Dashboard de carga muestra barrita roja en `Accordion 2 · Por empleado` en tiempo real al planificar |
| **Copy-paste entre celdas sin validación** → horas imposibles (>24/día) | Validación client-side: total fila+día ≤ quotaDiaria+extrasMáximos. Celda error con `aria-invalid="true"` |
| **Drag-to-create accidental en calendario** | Umbral 8px de arrastre antes de iniciar bloque + undo toast 5s |
| **Favoritos demasiados → saturan barra** | Cap 8 visibles + overflow `•••` con popover; auto-orden por `usageCount` |
| **Kiosco falla en conectividad mala** | Cola offline (IndexedDB) + sincroniza al reconectar; icono WiFi visible |
| **Manager aprueba sin revisar** (anti-pattern MARIProject) | Dashboard del manager resalta semanas con ≥1 anomalía (extras, atrasos, sub-asignación) en naranja |
| **Daltonismo rojo/verde** | Ver §9.3 — icono + texto siempre |
| **Jornadas partidas (España)** | El kiosco soporta `PAUSE_START/PAUSE_END` múltiples por día; el Tab "Día" muestra cada tramo en su fila |

### 12.3 Impacto `zentto-infra`

Declaración requerida por memoria 2026-04-20. **Evaluación de esta propuesta:**
- **Ninguno inmediato**. Las pantallas viven en `module-nomina` y `shared-ui`. No nuevos contenedores, no nuevo nginx, no nuevos secrets.
- **Eventual** si el PO aprueba kiosco: endpoint `POST /v1/hr/attendance/kiosk` puede tener rate-limit más agresivo que resto de API (~3 req/s por IP) → configurable en `zentto-infra/nginx/zentto.conf`. PR paralela cuando se implemente.

---

## 13. Entregables siguientes

1. [ ] **Este brief** — revisión del PO.
2. [ ] **PR en `zentto-erp-docs`** — este brief como ADR-NOMINA-001 (adaptado a formato ADR).
3. [ ] **PR #1 (shared-ui)** — `ZenttoBarChart` + `ZenttoLineChart` con Recharts.
4. [ ] **PR #2 (shared-ui)** — `ZenttoTimesheetGrid`.
5. [ ] **PR #3 (shared-ui)** — `ZenttoTimeKiosk` + `ZenttoFavoritesPicker`.
6. [ ] **PR #4 (design-tokens)** — tokens `workload` + `timesheet`.
7. [ ] **PR #5 (backend)** — migraciones goose + SPs duales (dependencias D1–D3).
8. [ ] **PR #6 (module-nomina)** — pantalla `/nomina/tiempos`.
9. [ ] **PR #7 (module-nomina)** — pantalla `/nomina/kiosko`.
10. [ ] **PR #8 (module-nomina)** — pantalla `/nomina/carga-laboral`.
11. [ ] **PR #9 (shared-i18n)** — keys ES/EN de §10.
12. [ ] **PR #10 (zentto-report)** — template `timesheet_month.json`.

Sugerido: issues en GitHub del repo `DatqBoxWeb`:
- `feat(nomina): timesheet entry screen — MVP`
- `feat(nomina): workload dashboard`
- `feat(nomina): time kiosk for shared terminals`
- `feat(shared-ui): chart wrappers (bar/line) with Recharts`
- `feat(shared-ui): timesheet editable grid`

---

## 14. Referencias bibliográficas

- MARIProject 6e — "Registro de tiempos" (PDF del PO).
- MARIProject 14e — "Análisis de carga laboral" (PDF del PO).
- Polaris Design System — https://polaris.shopify.com/
- Carbon Design System — https://carbondesignsystem.com/
- Atlassian Design System — https://atlassian.design/
- SAP Fiori Horizon — https://experience.sap.com/fiori-design-web/
- Material Design 3 — https://m3.material.io/
- Lightning (Salesforce) — https://lightningdesignsystem.com/
- Base Web (Uber) — https://baseweb.design/
- Recharts — https://recharts.org/
- Awesome Design Systems — https://github.com/alexpate/awesome-design-systems
- Awesome Design MD — https://github.com/VoltAgent/awesome-design-md
- RD-Ley 8/2019 (España — registro horario obligatorio) — https://www.boe.es/buscar/act.php?id=BOE-A-2019-3481
- WebAIM Contrast Checker — https://webaim.org/resources/contrastchecker/
