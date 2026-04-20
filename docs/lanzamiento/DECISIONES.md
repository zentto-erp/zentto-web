# Registro de Decisiones — Lanzamiento Multinicho

Log inmutable. Cada decisión se agrega al final; nunca se reescribe el pasado. Si una decisión se revierte, se registra una nueva que referencia a la anterior.

**Formato:** `D-NNN · YYYY-MM-DD · Título` → Contexto / Decisión / Consecuencias.

---

## D-001 · 2026-04-20 · Orquestación del plan arranca en Lote 1.A (solo docs)

**Contexto.** El plan `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md` define 5 fases / 5 streams. La auditoría de integración identificó blockers en paridad SQL Server y en el `CHECK` de `cfg.PricingPlan`.

**Decisión.** Arrancar por un Lote 1.A que solo produce documentación (matriz comercial, runbooks, severidades, audit) en una rama feature desde `developer`. Ningún cambio de código, BD ni infraestructura en este lote.

**Consecuencias.**
- Riesgo técnico del primer paso = 0.
- La matriz comercial queda aprobada (o iterada) antes de tocar BD.
- Lote 1.B (motor PG) arrancará en rama separada cuando la matriz esté firmada.

---

## D-002 · 2026-04-20 · Avanzar solo en PostgreSQL; plan SQL Server dedicado

**Contexto.** La regla `web/api/CLAUDE.md` exige dual DB obligatorio en toda migración. La auditoría encontró que SQL Server carece de paridad en SPs de License/Subscription/Pricing/Catalog (solo 3 SPs de License existen hoy). Levantar paridad al mismo tiempo que el lanzamiento multinicho duplica el trabajo y congela el flujo comercial.

**Decisión.** Durante la ejecución de este plan de lanzamiento multinicho, avanzamos **solo en PostgreSQL**. Al cierre de esta orquestación, se ejecutará un plan aparte que recrea el esquema completo en SQL Server tomando PG como estado canónico.

**Consecuencias.**
- `sqlweb-mssql/` y `sqlweb/` quedan congelados a efectos de esta orquestación.
- Cada migración goose que se emita aquí dejará una entrada en `DECISIONES.md` para que el plan futuro de SQL Server pueda replicarla.
- No se rompe producción SQL Server porque no hay clientes productivos sobre ese motor para estos módulos (pricing/catalog/license/subscriptions/landing).
- Esta decisión es **excepción consciente** a la regla dual DB y está autorizada por el product owner.

---

## D-003 · 2026-04-20 · Nichos iniciales del Lote 1 = 10 ofertas

**Contexto.** El Planner propuso 10 ofertas iniciales (ERP, POS, Restaurante, Ecommerce, CRM, Contabilidad, Hotel, Medical, Education, Inmobiliario/Rental). El reviewer marcó los 5 últimos como "requieren wiring cross-repo". El plan maestro sugiere arrancar con 6.

**Decisión.** La **matriz v1 documenta las 10 ofertas** (Stream A produce matriz documental). Sin embargo, los primeros **4 nichos activables** (ERP, POS, Restaurante, CRM) se seedan en BD en el Lote 1.B; los 6 restantes pasan a cola tras desbloquear `platform-client` + adopción en apps hermanas (Lote 1.C+).

**Consecuencias.**
- Stream A comercial no se recorta.
- Stream D operativo (onboarding) arranca con 4 nichos GO para el GO/NO-GO de Fase 4.
- Riesgo R3 del audit (apps hermanas sin entitlements del core) se resuelve antes de activar Hotel/Medical/Education/Inmobiliario/Rental.

---

## D-004 · 2026-04-20 · Ampliación de `chk_pricing_vertical` en Lote 1.B

**Contexto.** `migrations/postgres/00082_pricing_plans_and_partners.sql:22` define `chk_pricing_vertical` con solo 5 valores (`erp, medical, tickets, hotel, education`). La matriz v1 necesita `pos, restaurante, ecommerce, crm, contabilidad, inmobiliario, rental`.

**Decisión.** Lote 1.B incluye una migración goose nueva que **amplía el CHECK a 12 valores** (los 5 originales + 7 nuevos). No se usa lookup table en esta iteración — cambio mínimo y trazable. Si se requiere taxonomía viva, se migra a `cfg.Vertical` en un lote posterior.

**Consecuencias.**
- La migración debe ser reversible: `-- +goose Down` con el CHECK original.
- Los seeds de planes POS/Restaurante/Ecommerce/CRM/Contabilidad pueden entrar el mismo lote.
- SQL Server NO se toca (ver D-002). Al activar el plan SQL Server, replicará este CHECK.

---

## D-005 · 2026-04-20 · Sin `Co-Authored-By` en ningún commit

**Contexto.** Regla global hard-no del workspace Zentto.

**Decisión.** Ningún commit de esta orquestación incluye `Co-Authored-By: Claude` ni variantes. Identidad git: `raulgonzalezdev <gq.raul@gmail.com>`.

**Consecuencias.** Si una PR aparece con esa línea, se rehace con `git reset --soft HEAD~1` + recommit (solo en la misma rama feature, nunca sobre commits ya mergeados).

---

## D-006 · 2026-04-20 · Fuente única de verdad para entitlements = `cfg.PricingPlan.ModuleCodes`

**Contexto.** El audit encontró `PLAN_MODULE_DEFAULTS` hard-coded en `web/api/src/modules/license/license.types.ts` con 4 planes (FREE/STARTER/PRO/ENTERPRISE). Esto coexiste con `cfg.PricingPlan.ModuleCodes` en BD → dos fuentes de verdad.

**Decisión.** `cfg.PricingPlan.ModuleCodes` es la fuente canónica. `PLAN_MODULE_DEFAULTS` queda como **fallback de emergencia** (cuando BD no responde) y se marcará `@deprecated` en Lote 1.C. No se borra en este lote para no romper paths de onboarding legacy.

**Consecuencias.**
- Cada plan de la matriz v1 debe llevar `ModuleCodes` explícitos en BD.
- El Lote 1.C o Lote 2 revisa y, si aplica, retira `PLAN_MODULE_DEFAULTS`.

---

## D-007 · 2026-04-20 · GitHub Issues es el tracker (no Jira)

**Contexto.** `zentto-erp.atlassian.net` devuelve 404. El setup Free nunca se consolidó.

**Decisión.** Todo backlog operativo de esta orquestación vive en **GitHub Issues del repo `zentto-erp/zentto-web`** con labels `lanzamiento-multinicho`, `fase-1..5`, `stream-a..e`. Cada tarea del Planner se convierte en un issue con referencia al archivo en `docs/lanzamiento/`.

**Consecuencias.**
- El orquestador abre issues al cierre de Lote 1.A.
- PRs referencian `Fixes #<n>`.

---

<!-- Nuevas decisiones van debajo. No editar decisiones pasadas. -->
