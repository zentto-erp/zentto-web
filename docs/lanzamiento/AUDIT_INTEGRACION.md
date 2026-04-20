# Auditoría de Integración del Ecosistema — Plan Multinicho

**Fecha:** 2026-04-20
**Agente:** `zentto-integration-reviewer`
**Alcance:** módulos del core (`web/api/src/modules/*`), contratos (`openapi.yaml`), SDK cross-repo (`@zentto/platform-client`), apps hermanas, observabilidad, notify, CMS.

> Documento vivo. Se actualiza cuando se cierra un gap. No se borran entradas: se marcan como **RESUELTO** con referencia a la PR.

---

## Resumen ejecutivo

- **Riesgo global:** **ALTO**
- **Veredicto conceptual:** **AJUSTAR (amarillo)**
- Los nombres de módulos del plan (`pricing`, `catalog`, `license`, `subscriptions`, `landing`, `health`) existen en `web/api/src/modules/`, pero la profundidad comercial que promete la matriz multinicho **no está soportada** hoy:
  - **Paridad dual DB rota** en todo el stack comercial (ver D-002 — se acepta excepción consciente, avanzamos solo PG).
  - **OpenAPI no documenta** ni uno solo de los endpoints de pricing/catalog/license/subscriptions/landing/tenants.
  - **Apps hermanas** (hotel, medical, tickets, education, rental, inmobiliario) **no consumen** `license`/`subscriptions`/`entitlements` del core.
  - **CHECK constraint** en `cfg.PricingPlan` bloquea 5 de los 6 nichos iniciales del plan.

---

## 1. Módulos del plan — existencia y estado

| Módulo | Estado | Endpoints | Persistencia PG | Persistencia SQL Server | Evidencia |
|---|---|---|---|---|---|
| `pricing/` | Parcial | `GET /v1/pricing/plans`, `GET /v1/pricing/plans/:slug` (público) | `cfg.PricingPlan` + `usp_cfg_pricing_plan_list/_get` | Falta | `web/api/src/modules/pricing/service.ts:19` · `migrations/postgres/00082_pricing_plans_and_partners.sql:8` |
| `catalog/` | Parcial | Público + backoffice CRUD + Paddle sync (`/v1/catalog/*`, `/v1/backoffice/catalog/*`) | `usp_cfg_catalog_list`, `usp_cfg_plan_get_by_slug`, `usp_cfg_subdomain_check` | Falta | `web/api/src/modules/catalog/admin.routes.ts` · `migrations/postgres/00085_catalog_sps.sql` |
| `license/` | Parcial | Validate + CRUD (master-key), enforcement por user/company | `usp_Sys_License_*` en PG | **Solo 3 SPs** (`CheckUserLimit`, `CheckCompanyLimit`, `GetLimits`) | `web/api/sqlweb-mssql/includes/sp/` |
| `subscriptions/` | Parcial | Self-service tenant (`/me`, `/entitlements`, `/items`) + Paddle | `usp_sys_subscription_*` | Falta | `web/api/src/modules/subscriptions/routes.ts:1-145` |
| `landing/` | Existe | `POST /api/landing/register` con `X-Tenant-Key` scoped | `usp_sys_Lead_Upsert`, `cfg.usp_cfg_publicapikey_verify_scope` | Requiere verificación humana | `web/api/src/modules/landing/service.ts` |
| `health/` | Parcial | `GET /health`, `/health/db`, `GET /v1/status` (DB+Redis+uptime) | `usp_Sys_HealthCheck` | Requiere verificación humana | `web/api/src/modules/health/status.routes.ts` — no hay dimensión por-tenant ni por-vertical |

**Lectura clave.** Todo el stack comercial está acoplado a PostgreSQL. La regla `dual DB` se acepta violada temporalmente bajo la decisión D-002; al cierre de esta orquestación se ejecutará plan dedicado para reconstruir SQL Server.

---

## 2. Top 10 gaps

| # | Gap | Severidad | Apps impactadas | Evidencia |
|---|---|---|---|---|
| G-01 | SQL Server sin Validate/Create/Revoke/Renew de License ni SPs de Subscription/Pricing/Catalog | **BLOCKER** (mitigado por D-002) | Cualquier tenant con `DB_TYPE=sqlserver` | `web/api/sqlweb-mssql/includes/sp/` solo tiene 3 archivos License |
| G-02 | CHECK `chk_pricing_vertical` bloquea POS/Restaurante/Ecommerce/CRM/Contabilidad | **BLOCKER** | Stream A + Fase 4 onboarding | `migrations/postgres/00082_pricing_plans_and_partners.sql:22` |
| G-03 | `openapi.yaml` no documenta pricing/catalog/license/subscriptions/landing/tenants | **HIGH** | Partners, SDK auto-gen, E2E por contrato | 10.475 líneas revisadas, 0 coincidencias |
| G-04 | `@zentto/platform-client` no expone submódulos `catalog` / `license` / `subscriptions` / `pricing` | **HIGH** | Hotel, medical, tickets, education, rental, inmobiliario, pos, restaurante | `web/platform-client/src/index.ts` |
| G-05 | Ninguna vertical hermana lee entitlements del core — cada una solo valida auth | **HIGH** | Todas las apps standalone | Grep `license\|entitlement\|subscription` → 0 hits en apps hermanas |
| G-06 | `PLAN_MODULE_DEFAULTS` en código duplica `cfg.PricingPlan.ModuleCodes` en BD | **MEDIUM** | Todo tenant; drift entre código y BD | `web/api/src/modules/license/license.types.ts:21` |
| G-07 | `cfg.PricingPlan.CompanyId NOT NULL DEFAULT 0` en tabla global de planes → potencial leak cross-tenant | **MEDIUM** | Multi-tenant | `migrations/postgres/00082_pricing_plans_and_partners.sql:20` |
| G-08 | `/v1/status` sin dimensión por-tenant ni por-app; dashboard ops de Fase 2 no existe | **HIGH** | Stream B | `web/api/src/modules/health/status.routes.ts` |
| G-09 | Notify no tiene templates de onboarding por-nicho (`htl-onboarding`, `med-onboarding`, etc.) | **MEDIUM** | Fase 4 | `zentto-notify/src/db/seed-zentto.ts`, `zentto-notify/src/templates/lead-seeds.ts:167-185` |
| G-10 | `landing-kit` tiene 9 paletas; faltan `ecommerce`, `crm`, `contabilidad` del plan | **MEDIUM** | Fase 1 landings, Fase 4 demo | `web/modular-frontend/packages/landing-kit/src/tokens.ts:15-25` |

---

## 3. Riesgos de romper el ecosistema

| Riesgo | Vector | Mitigación previa |
|---|---|---|
| Agregar nichos a `VerticalType` sin migrar el CHECK → inserts rotos en prod | BD | Migración goose PG + D-002 posterga MSSQL |
| Apps hermanas empiezan a gatear features por "plan" sin API central → cada una reimplementa entitlements | Ecosistema | Lote 1.C: submódulo `platform-client/license` antes de Fase 4 |
| Backoffice crea planes para POS/Restaurante pero OpenAPI queda sin documentar → partners y SDKs huérfanos | Contratos | Lote 1.B: documentar `openapi.yaml` antes de publicar nuevos planes |
| Doble fuente de verdad `PLAN_MODULE_DEFAULTS` vs `cfg.PricingPlan.ModuleCodes` | Código vs BD | D-006: dejar BD como canónico y `PLAN_MODULE_DEFAULTS` como fallback `@deprecated` |
| `subscriptions.routes.ts` asume `paddle.client` en todo → tenants on-prem/BYOC sin Paddle quedan sin addons | Billing | Auditar `DELETE items/:id` y branch `Source === "paddle"` |
| Provisioning de tenant exige master-key y solo acepta 4 planes (`FREE/STARTER/PRO/ENTERPRISE`) | Auth/tenants | Extender `provisionSchema` con `productCode` + `verticalType` en Lote 2 |
| Multi-tenant leak en `cfg.PricingPlan.CompanyId` si el SP no enforza filtro | Multi-tenant | Verificación humana de `usp_cfg_catalog_list` |

---

## 4. Dependencias cross-repo obligatorias

### Antes de Lote 2 (onboarding por nicho)

1. ~~Paridad SQL Server~~ **→ postergado por D-002**.
2. **Ampliar `chk_pricing_vertical`** (G-02) — migración goose en Lote 1.B.
3. **Extender `@zentto/platform-client`** con `license` + `catalog` (G-04) — Lote 1.C, publish privado.
4. **Templates notify por-nicho** (G-09) — seed en `zentto-notify`.

### Antes de Lote 3 (E2E + observabilidad)

5. **`/v1/status` por-tenant y por-app** (G-08) — impacta `zentto-obs` / Kibana.
6. **Documentar contratos en `openapi.yaml`** (G-03) — sin esto, QA no puede generar tests E2E contra contrato.
7. **Fuente única de verdad** para entitlements (G-06) — D-006.

### Antes de Lote 4 (UX/performance)

8. **Paletas faltantes en `landing-kit`** (G-10) — añadir `ecommerce`, `crm`, `contabilidad` o mapear explícitamente a `default`.

---

## 5. Qué se puede atacar YA (sin bloqueos técnicos)

| Tarea | Por qué no tiene bloqueo |
|---|---|
| `MATRIZ_COMERCIAL_V1.md` (solo Markdown) | No toca código |
| Taxonomía `core/bundle/addon/enterprise` documental | `cfg.PricingPlan` ya tiene `IsAddon`, `ProductCode`, `BillingCycleDefault` |
| Runbooks release/rollback/backup | Solo docs |
| Política severidades y soporte | Docs + GitHub Issues (D-007) |
| Matriz de 10 ofertas contra planes existentes | Lectura de `cfg.PricingPlan` ya poblada |
| Auditoría de flujos E2E — inventario coverage | Discovery, no implementación |

---

## 6. Notas y puntos a verificar con humano

- **CI/CD feature flags:** solo 2 workflows usan `vars`. El stack `FeatureFlag` + `subscription` middleware existe; no hay bloqueo de Actions.
- **Auth:** `zentto-auth` centralizado con cookie HttpOnly `*.zentto.net` operativo. El plan no propone cambios — sin riesgo.
- **CMS (ADR-CMS-001, PR #477):** schema `cms.Post`/`cms.Page` soporta `vertical` libre; encaja para landings por nicho.
- **Multi-tenant leak (G-07):** `cfg.PricingPlan.CompanyId DEFAULT 0` requiere verificación humana del SP para confirmar que tenants nuevos no leen planes de otros.
- **Paddle:** `paddleApi.post("/transactions")` y webhook path existen; onboarding con plan no-FREE funciona hoy.

---

## 7. Rutas relevantes

```
web/api/src/modules/{pricing,catalog,license,subscriptions,landing,health,tenants,billing}/
web/api/migrations/postgres/00082_pricing_plans_and_partners.sql
web/api/migrations/postgres/00085_catalog_sps.sql
web/api/sqlweb-mssql/includes/sp/usp_Sys_License_*.sql
web/contracts/openapi.yaml
web/platform-client/src/index.ts
web/modular-frontend/packages/landing-kit/src/tokens.ts
D:\DatqBoxWorkspace\zentto-notify\src\db\seed-zentto.ts
D:\DatqBoxWorkspace\zentto-hotel\api\src\notifications\notify.ts  (único que ya usa @zentto/platform-client/notify)
```
