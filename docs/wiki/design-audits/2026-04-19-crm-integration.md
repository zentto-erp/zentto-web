# Integration Review — CRM rediseño global

> **Fecha:** 2026-04-19
> **Autor:** zentto-integration-reviewer (subagent)
> **Documento hermano:** [2026-04-19-crm.md](./2026-04-19-crm.md)
> **Estado:** Revisión adjunta al milestone [CRM Redesign · Fase 1](https://github.com/zentto-erp/zentto-web/milestone/1).

---

## Resumen ejecutivo

**Riesgo agregado:** ALTO. **Veredicto:** ajustar (no bloquear).

El rediseño propuesto para CRM (ver documento hermano) toca piezas transversales del ecosistema Zentto — shared-ui, API contracts, observabilidad, multi-tenant, DB dual, módulos hermanos. Hay suficiente riesgo para justificar una revisión transversal, pero ninguno de los hallazgos es bloqueante si se siguen las recomendaciones de secuencia (§6) y se respeta el patrón `vars.CRM_NEW_UI` opt-in.

**Leyenda de severidad por vector:**
- ⛔ Bloqueante hasta resolver dependencia.
- ⚠️ Requiere mitigación antes de merge a `main`.
- ✅ Sin riesgo estructural.

---

## 1. Hallazgos por vector

### 1.1 API contracts — ⛔

- Rediseño introduce entidades nuevas (`crm.Contact`, `crm.Company`, `crm.Deal`, `crm.DealLine`, `crm.DealHistory`) que requieren contratos OpenAPI en `web/contracts/openapi.yaml` antes de que el frontend pueda tiparlos.
- Rompe la regla "contratos primero" si se empieza por UI. Ver `feedback_contracts_first`.
- `crm.Lead` cambia su shape (quita Stage/Probability/Value/CloseDate). Cualquier consumer externo del API Lead queda roto hasta versionar.
- **Mitigación**: PR-E (CRM-110) publica primero SPs + OpenAPI. UI no arranca hasta que openapi.yaml esté merged en developer. Mantener endpoints `/v1/crm/lead/*` legacy 1 sprint para consumers externos, con campo `deprecated: true` en la spec.

### 1.2 Auth / RBAC / httpOnly cookies — ✅

- Sin cambios en flujo de auth. Cookies httpOnly siguen siendo canal.
- Nuevas entidades heredan políticas del schema `crm` ya existente.
- RBAC: agregar permisos `crm.contact.*`, `crm.company.*`, `crm.deal.*` en `sys.Permission` + `sys.RolePermission`. Seed en migración goose.

### 1.3 Notify — ⛔

- PipelineKanban v2 sobre `crm.Deal` emite eventos que hoy son consumidos por zentto-notify ("Deal movido a Won" → email al owner). Los job types de notify están hardcoded al shape viejo de Lead.
- **Mitigación**: publicar en notify los nuevos job types `deal.won`, `deal.lost`, `deal.stage_changed` ANTES de migrar el Kanban. Mantener `lead.converted` como espejo.
- Revisar templates en `zentto-notify/templates/crm/*.njk` para aceptar `{{ deal.* }}` en vez de `{{ lead.* }}`.

### 1.4 Observability — ⚠️

- SDK `obs.log/error/audit/perf/event` debe invocarse en todos los endpoints nuevos.
- Eventos necesarios: `crm.contact.created/updated/deleted`, `crm.company.*`, `crm.deal.*`, `crm.table.load`, `crm.drawer.open`, `crm.palette.action`, `crm.kanban.move`.
- Dashboard Kibana existente apunta a `crm.lead.*`. **Hay que versionar el dashboard** con filtros sobre `deal.*` y `lead.*` en paralelo. Coordinar con zentto-observability.
- **Mitigación**: actualizar dashboard en CRM-112 (Kanban v2). Alertas APM deben tolerar coexistencia Lead↔Deal durante backfill.

### 1.5 Multi-tenant — ✅

- Todas las entidades nuevas llevan `CompanyId` y `TenantId` como el resto del schema crm.
- Policies RLS en PostgreSQL siguen el patrón estándar ya aplicado a Lead.
- Sin cambios en estrategia por schema/tenant.

### 1.6 Shared-UI — ⛔

- `<ZenttoRecordTable>` es un componente nuevo grande (~15k LOC estimadas). Debe publicarse como `@zentto/shared-ui` ≥ 1.3.0 antes de que cualquier app lo consuma.
- Publicar paquete privado en npm Teams (scope `@zentto/*`, registry privado). Ver `feedback_npm_private_only`.
- Tras `npm publish`, esperar 5 min para propagación antes de `npm install` downstream. Ver `feedback_npm_publish_5min_wait`.
- **Consumidores impactados**: TODAS las apps del modular-frontend (12+). Si RecordTable regresiona ZenttoDataGrid por side-effect, quiebre transversal.
- **Mitigación**: RecordTable coexiste con DataGrid, no reemplaza. Tests de regresión en cada app consumer (hotel, medical, ventas, compras, ...).

### 1.7 CI/CD — ⚠️

- Pipelines dev y prod deben correr sin cambios en el shape del build. Confirmar que security-dev (`fail-on: critical`) no bloquea el PR por warnings de RecordTable (nueva superficie).
- Feature flag `vars.CRM_NEW_UI` debe configurarse opt-in en Actions. Ver `feedback_github_actions_vars`.
- Deploy a prod solo cuando backfill Lead→Deal esté validado en `appdev.zentto.net`.

### 1.8 DB dual (PG + SQL Server) — ⛔

- Toda migración goose en `web/api/migrations/postgres/` requiere equivalente T-SQL en `web/api/sqlweb/includes/sp/` + regenerar `sqlweb-mssql/01_ddl_tables.sql` con `pg2mssql.cjs`.
- Si solo se actualiza un motor, el switch `DB_TYPE=sqlserver` rompe clientes SQL Server en producción.
- SQL Server está a 5/14 tablas CRM hoy; el milestone obliga llevar a 17/17 (las 14 + Contact + Company + Deal).
- **Mitigación**: el SQL Specialist agent valida cada PR que toca BD. Tests `sp-contracts-mssql.test.ts` deben pasar. Bootstrap canónico en `zentto_dev` debe reconstruirse y validarse.

### 1.9 Módulos hermanos (hotel, medical, rental, inmobiliario, ventas) — ⚠️

- Módulos acoplan a `master.Customer` vía `customerId` string por integraciones API, no por FK. Crear `crm.Contact` y promover a Customer al ganar Deal no los rompe.
- Pero: si algún módulo empieza a consumir `<ZenttoRecordTable>` por side-effect (`shared-ui` actualizado), hay que probar. Ya tenemos al menos 2 apps candidatas (hotel reservas, ventas orders).
- **Mitigación**: versión de shared-ui con RecordTable es minor bump, no major. Consumers se adoptan en su propio tiempo. Matriz de compatibilidad publicada en `docs/wiki/04-modular-frontend.md`.

---

## 2. Dependencias bloqueantes (8 items)

1. **OpenAPI publicado antes de UI**. PR-E (contratos + SPs) debe mergear antes de PR-F (UI).
2. **shared-ui ≥ 1.3.0 publicado en npm privado** con RecordTable + CommandPalette + RightDetailDrawer. Antes de cualquier consumo.
3. **Notify job types `deal.*` publicados** antes de Kanban v2.
4. **Backfill Lead→Deal** probado en dev antes de encender `vars.CRM_NEW_UI` para prod.
5. **SQL Server dual** al día (14→17 tablas CRM) antes de encender clientes con `DB_TYPE=sqlserver`.
6. **Observability dashboard versionado** antes de tirar la columna `lead.*` histórica.
7. **RBAC seeds** de los nuevos permisos `crm.contact.*` / `crm.company.*` / `crm.deal.*` antes de que existan las rutas en API.
8. **Matriz de compat shared-ui** publicada en docs antes de merge a `main`.

---

## 3. Recomendaciones de secuencia — 7 PRs

Orden sugerido para minimizar blocking transversal:

1. **PR-A (tokens + DESIGN.md)** — base de todo, aislado, sin dependencias.
2. **PR-B (RecordTable + CommandPalette + Drawer en shared-ui)** — publish a npm privado, esperar 5 min, bump consumers al instalar.
3. **PR-E (API Contact/Company/Deal dual + OpenAPI)** — migraciones goose + SPs PG + T-SQL + `pg2mssql.cjs` + openapi.yaml + seeds RBAC.
4. **PR-F (UI Contactos / Empresas / Deals)** — consume shared-ui ya publicado + contratos ya publicados. Feature flag `vars.CRM_NEW_UI`.
5. **PR-G (ActivityTimeline unificado)** — aislado, consume contracts existentes.
6. **PR-H (PipelineKanban v2 + backfill Lead→Deal + notify job types)** — requiere notify actualizado + observability dashboard versionado previamente.
7. **PR-I (Saved views + empty states + polish)** — cierra el milestone, consume API SavedView de CRM-108.

Merge a `developer` por PR cada vez que CI esté verde. Merge a `main` solo cuando los 7 PRs estén en developer y `appdev.zentto.net` valide el flujo end-to-end.

---

## 4. Conclusión

El rediseño CRM es viable y mejorará el producto. Los riesgos transversales están acotados a 3 ejes: shared-ui (coexistencia con ZenttoDataGrid), DB dual (mantener SQL Server al día) y notify (nuevos job types). Todos tienen mitigación concreta en los PRs planeados. La secuencia de §3 respeta las dependencias bloqueantes de §2.

Coordinador recomendado: `datqbox-super-orchestrator`. Sub-agents por fase: Architecture (cerrar ADR), Planner (secuenciar PRs), Developer (ejecutar), SQL (validar dual), QA (Go/No-Go por PR), Integration Reviewer (este documento + update por PR).

**Go / No-go por PR:** cada uno de los 7 PRs necesita su propia revisión QA antes de merge a `developer`.
