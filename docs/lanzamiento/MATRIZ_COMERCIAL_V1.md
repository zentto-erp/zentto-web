# Matriz Comercial Multinicho — v1

**Fecha:** 2026-04-20
**Estado:** Draft para revisión de negocio
**Alcance:** PostgreSQL únicamente (ver [`DECISIONES.md` §D-002](./DECISIONES.md))
**Fase:** 1 · Stream A

> **Frase guía.** *No recortamos alcance; convertimos el alcance actual en una plataforma vendible, operable y repetible.*

---

## 1. Taxonomía oficial

Cuatro tiers comerciales que se mapean sobre los campos existentes de `cfg.PricingPlan`:

| Tier | Significado | Campos clave en `cfg.PricingPlan` |
|---|---|---|
| **core** | Producto de entrada por nicho. Activa el conjunto mínimo de `ModuleCodes` para operar ese vertical. | `IsAddon = false`, `Tier = 'core'` *(nuevo campo — Lote 1.B)*, `ModuleCodes` explícito |
| **bundle** | Variante empaquetada (ej. "STARTER", "PRO") del mismo nicho con más módulos/límites. | `IsAddon = false`, `Tier = 'bundle'`, hereda `ProductCode` del core |
| **addon** | Unidad vendible opcional que agrega `ModuleCodes` o sube `Limits`. | `IsAddon = true`, `Tier = 'addon'` |
| **enterprise** | Plan negociado directo. Módulos y límites definidos por acuerdo. | `IsAddon = false`, `Tier = 'enterprise'`, `IsTrialOnly = false` |

**Nota sobre el campo `Tier`.** Hoy no existe en `cfg.PricingPlan`. Su introducción se ejecuta en Lote 1.B (migración goose nueva) y se documenta en [`DECISIONES.md` §D-004](./DECISIONES.md).

---

## 2. Matriz de ofertas — Lote 1 (10 ofertas)

Precios en USD/mes. `ModuleCodes` usan el vocabulario real de `license.types.ts` y `packages/module-*`.

| # | Nicho | Slug de entrada | Tier | Módulos incluidos | Addons sugeridos | STARTER | PRO | Onboarding | Dependencia técnica |
|---|---|---|---|---|---|---|---|---|---|
| 1 | ERP general | `erp-starter` | core | clientes, articulos, inventario, facturas, pagos, cxc, cxp, bancos, reportes, usuarios | `contabilidad`, `nomina`, `manufactura` | $49 | $99 | **L** | Existente — `usp_Cfg_Plan_ApplyModules` (STARTER/PRO ya definidos) |
| 2 | Retail POS | `pos-starter` | core | pos, articulos, inventario, clientes, pagos, reportes | `ecommerce`, `fiscal-ve`, `fiscal-es` | $39 | $79 | **L** | `module-pos` + app standalone `zentto-pos` |
| 3 | Restaurante | `resto-starter` | core | restaurante, articulos, inventario, clientes, pagos, reportes | `ecommerce`, `shipping`, `nomina` | $49 | $89 | **M** | `module-restaurante` + `zentto-restaurante` |
| 4 | Ecommerce | `ecom-starter` | core | ecommerce, articulos, inventario, clientes, pagos, shipping | `crm`, `logistica`, `contabilidad` | $59 | $109 | **M** | `module-ecommerce` + `module-shipping` |
| 5 | CRM-only | `crm-pro` | core | crm, clientes, reportes, usuarios | `ecommerce`, `notify-email-plus` | $29 | $69 | **L** | `module-crm` (design system v2 listo) |
| 6 | Contabilidad | `cont-pro` | core | contabilidad, facturas, pagos, cxc, cxp, bancos, reportes | `nomina`, `auditoria`, `fiscal-*` | $49 | $99 | **M** | `module-contabilidad` + `module-nomina` |
| 7 | Hotel | `hotel-core` | core | hotel (standalone), clientes, facturas, pagos, reportes | `restaurante`, `shipping` | $79 | $149 | **H** | App externa `zentto-hotel` — requiere wiring platform-client |
| 8 | Médico/Clínica | `medical-core` | core | medical (standalone), clientes, facturas, pagos, reportes | `crm`, `contabilidad` | $69 | $129 | **H** | App externa `zentto-medical` |
| 9 | Educación | `education-core` | core | education (standalone), clientes, facturas, pagos | `crm`, `contabilidad`, `notify` | $59 | $119 | **H** | App externa `zentto-education` |
| 10 | Inmobiliaria / Rental | `realestate-core` | core | inmobiliario (standalone) o rental, clientes, facturas, pagos, reportes | `crm`, `shipping` | $59 | $119 | **H** | Apps externas `zentto-inmobiliario` y `zentto-rental` |

---

## 3. Nichos activables en Lote 1.B vs. postergados

Ver [`DECISIONES.md` §D-003](./DECISIONES.md).

| Nicho | Lote 1.B (seed BD) | Gate para activar |
|---|---|---|
| ERP general | ✅ | Ya activo |
| Retail POS | ✅ | Schema `pos` + `module-pos` listos |
| Restaurante | ✅ | Schema `rest` + `module-restaurante` listos |
| CRM-only | ✅ | Design system v2 listo |
| Ecommerce | ⏳ Lote 1.C | Requiere paletas `landing-kit` (G-10) |
| Contabilidad | ⏳ Lote 1.C | Requiere paletas `landing-kit` (G-10) |
| Hotel | ⏳ Lote 2 | Requiere `@zentto/platform-client/license` (G-04) + wiring en `zentto-hotel` |
| Médico/Clínica | ⏳ Lote 2 | Idem Hotel |
| Educación | ⏳ Lote 2 | Idem Hotel |
| Inmobiliaria/Rental | ⏳ Lote 2 | Idem Hotel |

---

## 4. Reglas de activación por plan

### 4.1 `core` / `bundle`

- El upsert del plan debe traer `ModuleCodes` explícitos.
- `usp_Cfg_Plan_ApplyModules(CompanyId, PlanCode)` entrega los módulos al tenant en `sec.UserModuleAccess` al provisionar.
- **Idempotente**: si el admin ya tocó `UserModuleAccess`, el apply es merge (no delete+insert). Requiere verificación SQL Specialist en Lote 1.B.

### 4.2 `addon`

- Se agrega al tenant via `usp_sys_subscription_item_add(CompanyId, AddonSlug)`.
- No re-ejecuta `applyPlanModules`; solo agrega `ModuleCodes` del addon.
- Quitar un addon: `usp_sys_subscription_item_remove`; los `ModuleCodes` se retiran salvo que otro plan/addon activo los reclame.

### 4.3 `enterprise`

- Creado a mano por backoffice con `IsTrialOnly = false` y `Limits` negociados.
- No se sincroniza a Paddle automáticamente — requiere flag explícito.

---

## 5. Relación con `cfg.PricingPlan` y SPs existentes

| Acción comercial | SP existente a reusar | Estado |
|---|---|---|
| Listar planes públicos | `usp_cfg_pricing_plan_list`, `usp_cfg_catalog_list` | Existe (duplicación — ver R1 del Planner) |
| Obtener plan por slug | `usp_cfg_plan_get_by_slug` | Existe |
| Upsert plan | `usp_cfg_plan_upsert` | Existe — **requiere extensión con `Tier`** |
| Aplicar módulos al tenant | `usp_Cfg_Plan_ApplyModules` | Existe |
| Validar licencia | `usp_Sys_License_Validate` | Existe en PG |
| Verificar subdominio disponible | `usp_cfg_subdomain_check` | Existe |
| Alta de lead desde landing | `usp_sys_Lead_Upsert` | Existe |
| Provision de tenant | `usp_Cfg_Tenant_Provision` | Existe — requiere extensión con `vertical` (Lote 2) |

---

## 6. Venta de entrada vs upsell

**Venta de entrada (self-service via landing):**
- `erp-starter`, `pos-starter`, `resto-starter`, `crm-pro`

**Venta asistida con onboarding (backoffice):**
- `ecom-starter`, `cont-pro`

**Venta consultiva / cross-repo (requiere wiring previo):**
- `hotel-core`, `medical-core`, `education-core`, `realestate-core`

**Upsells naturales:**
- De STARTER → PRO dentro del mismo nicho.
- De `core` a `core + addon` (ej. `erp-starter` + `addon-nomina`).
- De cualquier vertical a `crm-pro` como add-on cross-nicho.

---

## 7. Criterios GO de la matriz v1

- ✅ Documento firmado por negocio (este archivo + commit en rama feature).
- ⏳ Todos los planes `core`/`bundle` del Lote 1 presentes en `cfg.PricingPlan` con `PaddleSyncStatus = 'synced'` (Lote 1.B cerrará esto).
- ⏳ `GET /v1/catalog/matrix` responde <500ms con los 10 productos (QW-1 del Planner, entregable del Lote 1.B).
- ⏳ QA valida que `applyPlanModules` entrega los `ModuleCodes` declarados para los 4 nichos activables (Lote 1.B).

---

## 8. Fuera de Lote 1 (candidatos Lote 2+)

- Vertical `tickets` — app existe (`zentto-tickets`), falta wiring platform-client.
- Vertical `broker` — pendiente limpieza mocks (ver memoria `project_broker_needs_cleanup.md`).
- `manufactura-pro`, `flota-pro`, `logistica-pro`.
- `enterprise-all-in` — oferta global negociada directa (Fase 3 o Fase 4).

---

## 9. Referencias

- [`PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`](../PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md)
- [`AUDIT_INTEGRACION.md`](./AUDIT_INTEGRACION.md)
- [`DECISIONES.md`](./DECISIONES.md)
- `web/api/src/modules/pricing/service.ts`
- `web/api/src/modules/catalog/admin.service.ts`
- `web/api/src/modules/license/license.types.ts`
- `web/api/migrations/postgres/00082_pricing_plans_and_partners.sql`
- `web/api/migrations/postgres/00085_catalog_sps.sql`
