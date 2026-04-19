# Design System overlay (Zentto wiki)

> Este documento es una vista narrativa del design system de Zentto. La **fuente
> única de verdad** es `web/modular-frontend/packages/shared-ui/DESIGN.md`
> (formato Google Stitch / awesome-design-md). Si este doc y el DESIGN.md
> discrepan, **gana el DESIGN.md**.

## Qué es un DESIGN.md

Adoptamos el formato **Google Stitch** documentado en
[awesome-design-md](https://github.com/VoltAgent/awesome-design-md) y
[stitch.withgoogle.com/docs/design-md](https://stitch.withgoogle.com/docs/design-md/overview/).

Un DESIGN.md describe en 10-12 secciones:

1. **Identidad** — qué producto es, a quién sirve, con qué tono.
2. **Principios** — reglas inviolables que guían cada decisión.
3. **Tokens** — spacing, densidad, tipografía, color, radio, sombra.
4. **Componentes base** — layout, listas, dialogs, drawer, palette.
5. **Patrones** — listado→detalle, crear/editar, bulk actions, dashboard, empty.
6. **Anti-patrones** — qué NO hacer (ej. `<table>` HTML nativo).
7. **Densidad y breakpoints** — matriz de cómo adaptar por device.
8. **Accesibilidad** — AA mínimo, focus, ARIA, keyboard.
9. **Versionado y consumo** — cómo se distribuye el paquete.
10. **Roadmap vivo** — qué viene, qué está en curso.
11. **Referencias** — design systems de los que nos inspiramos.

## Jerarquía de DESIGN.md en Zentto

```
packages/shared-ui/DESIGN.md         ← BASE (tokens + componentes + principios)
         │
         └─ apps/crm/DESIGN.md       ← overlay CRM (casos, flujos, atajos)
         └─ apps/pos/DESIGN.md       ← overlay POS (tiled, touch, kiosk)
         └─ apps/ventas/DESIGN.md    ← overlay Ventas
         └─ apps/<modulo>/DESIGN.md  ← uno por app donde el overlay sea útil
```

### Regla

- La **base** (`shared-ui/DESIGN.md`) define TODO lo compartido: tokens, componentes genéricos, atajos globales, reglas de accesibilidad.
- Cada **overlay por app** solo documenta lo ESPECÍFICO: casos de uso del negocio, referentes (HubSpot/Pipedrive para CRM, Toast/Square para POS), flujos propios, colores semánticos extra, atajos contextuales.
- **Si un patrón sirve para >1 app, promoverlo a la base.** No duplicar.

## Cómo adoptar DESIGN.md en una app nueva

### Checklist

1. Crear `apps/<app>/DESIGN.md` con la plantilla (ver abajo).
2. En la introducción, incluir `> Overlay del design system base. Ver packages/shared-ui/DESIGN.md.`.
3. Declarar **identidad**: producto, audiencia, tono.
4. Listar **casos de uso** primarios (3-6 escenarios).
5. Citar **referentes** específicos del dominio (link a sus DESIGN.md en awesome-design-md cuando exista).
6. Listar **componentes protagonistas** (los que más aparecen en esta app).
7. Documentar **flujos clave** paso a paso.
8. Documentar **atajos contextuales** que extienden los globales.
9. Documentar **colores semánticos** propios (si aplica).
10. Declarar **breakpoints específicos** (si se desvía del base).

### Plantilla mínima

```markdown
# Zentto <Modulo> Design

> Overlay del design system base Zentto. Fuente de verdad: `packages/shared-ui/DESIGN.md`.
> Formato: Google Stitch / design.md.

## 1. Identidad
- Producto, audiencia, tono.

## 2. Casos de uso
- 3 a 6 escenarios con 1 línea cada uno.

## 3. Referentes
- Link a DESIGN.md de competidores donde aplique.

## 4. Componentes protagonistas
- 5 a 8 componentes del `shared-ui` que dominan esta app.

## 5. Flujos clave
- Paso a paso de los workflows primarios.

## 6. Atajos contextuales
- Tabla de shortcuts que extienden los globales.

## 7. Colores semánticos
- Tokens por entidad (ej. lead, deal.won, priority.urgent).

## 8. Responsive
- Breakpoints que difieran del base.
```

## Estado de adopción

| App / Módulo | DESIGN.md | Estado |
|---|---|---|
| `packages/shared-ui` | `shared-ui/DESIGN.md` | ✅ creado (CRM-101) |
| `apps/crm` | `apps/crm/DESIGN.md` | ✅ creado (CRM-114 — este issue) |
| `apps/pos` | `apps/pos/DESIGN.md` | ⏳ pendiente |
| `apps/restaurante` | `apps/restaurante/DESIGN.md` | ⏳ pendiente |
| `apps/ventas` | `apps/ventas/DESIGN.md` | ⏳ pendiente |
| `apps/ecommerce` | `apps/ecommerce/DESIGN.md` | ⏳ pendiente |
| `apps/report-studio` | `apps/report-studio/DESIGN.md` | ⏳ pendiente |
| Resto de apps modulares | — | backlog Fase 2 |

## Referencias

- Base: `web/modular-frontend/packages/shared-ui/DESIGN.md`.
- Modelo entidades CRM: [16-crm-entities-model.md](./16-crm-entities-model.md).
- Patrones UI del rediseño: [04-modular-frontend.md §Rediseño CRM 2026-Q2](./04-modular-frontend.md#rediseño-crm-2026-q2).
- ADR aprobado: [`../adr/ADR-CRM-001-entities-model.md`](../adr/ADR-CRM-001-entities-model.md).
- Standard awesome-design-md: https://github.com/VoltAgent/awesome-design-md
- Formato Google Stitch: https://stitch.withgoogle.com/docs/design-md/overview/
