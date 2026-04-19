# ADR-CRM-001 — Modelo de entidades CRM (Contact, Company, Deal)

## Estado
**APROBADO** — firmado por Raúl González Matute (product owner), 2026-04-19.

## Contexto

Hoy el módulo CRM vive en PostgreSQL con 14 tablas ([web/api/sqlweb-pg/baseline/003_tables.sql:1087-1394](../../web/api/sqlweb-pg/baseline/003_tables.sql)): `Activity, Agent, AutomationLog, AutomationRule, CallLog, CallQueue, CallScript, Campaign, CampaignContact, Lead, LeadHistory, LeadScore, Pipeline, PipelineStage`. SQL Server tiene solo 5 de ellas tangencialmente en [sqlweb-mssql/01_ddl_tables.sql:2835-2987](../../web/api/sqlweb-mssql/01_ddl_tables.sql) — la paridad dual-DB está rota.

`crm.Lead` mezcla dos ciclos de vida distintos en la misma fila:
- **Prospect frío** (nombre, email, teléfono, fuente, estado de calificación).
- **Oportunidad con pipeline** (stage, probability, value, closeDate, ownerAgent).

Esto impide:
1. Reportes de conversión funnel (Lead → Qualified → Deal Open → Won).
2. Velocity limpia (tiempos de Lead no comparables con tiempos de Deal).
3. Múltiples deals por contacto.
4. Separar prospecting (frío) de sales cycle (caliente) en UI y permisos.

"Contactos" no es una entidad de primera clase: `Lead` tiene `ContactName`, `ContactEmail` como strings planos, y `master.Customer` ([003_tables.sql:3069](../../web/api/sqlweb-pg/baseline/003_tables.sql)) es una tabla contable (con `FiscalId`, `CreditLimit`) pensada para facturación — no para prospects.

Apps hermanas relevantes: hotel, medical, rental, inmobiliario — todas acoplan a `master.Customer` vía `customerId` string por integraciones API, no por FK física. Añadir entidades nuevas en schema `crm` NO las rompe.

## Decisión 1 — Contact: **Opción B (crm.Contact + crm.Company independientes)**

Crear `crm.Contact` y `crm.Company` como entidades CRM independientes. Un Contact puede ser promovido opcionalmente a `master.Customer` cuando un Deal se gana (crea registro contable).

### Argumentos a favor
- No contamina `master.Customer` con leads fríos sin datos fiscales.
- Permite modelo HubSpot-style: 1 Company → N Contacts → N Deals.
- Preserva regla dual-DB limpia (migraciones nuevas en schema crm, sin tocar master).
- Apps hermanas no se rompen (acoplan por customerId string, no por FK).

### Argumentos en contra
- 2 tablas nuevas + 10 SPs nuevos + duplicación en T-SQL.
- Requiere lógica de "promoción" Contact → Customer al ganar Deal.

### Riesgos
- Dos fuentes de verdad sobre quién es cliente. Mitigación: `crm.Contact.PromotedCustomerId` FK nullable que referencia `master.Customer`.

### Impacto en BD
- 2 migraciones goose nuevas (`crm.Company`, `crm.Contact`).
- ~10 SPs PG + 10 T-SQL.
- Backfill opcional: strings de `Lead.ContactName/Email/Phone` → `crm.Contact` si se quiere historial.

## Decisión 2 — Deal: **Opción B (crm.Deal separado)**

Separar `crm.Deal` + `crm.DealLine` + `crm.DealHistory` como entidades nuevas. `crm.Lead` queda como prospect puro con estado `NEW|CONTACTED|QUALIFIED|DISQUALIFIED|CONVERTED`. Al calificar un Lead, se crea un Deal y Lead pasa a `CONVERTED` con `ConvertedToDealId` FK.

### Argumentos a favor
- Elimina la confusión Lead-vs-Deal que hoy mezcla prospecting y sales cycle.
- Habilita funnel analítico limpio.
- Permite múltiples deals por contact/company (ciclo recurrente B2B).
- Alineado con Pipedrive/Salesforce — referentes para comerciales.

### Argumentos en contra
- PipelineKanban debe refactorizarse (hoy es sobre Lead, debe migrar a Deal).
- Backfill histórico requerido para leads actuales con Stage.
- Mayor volumen inicial de código (más SPs, más endpoints, más UI).

### Riesgos
- Durante la migración hay período en que Lead y Deal coexisten con solape. Mitigación: flag `vars.CRM_NEW_UI` opt-in dev → prod.
- Posible pérdida de trazabilidad si el backfill no es perfecto. Mitigación: `crm.DealHistory` con origen=`'BACKFILL_LEAD:{id}'`.

### Impacto en BD
- 3 migraciones goose nuevas (`crm.Deal`, `crm.DealLine`, `crm.DealHistory`).
- Refactor `crm.Lead`: remover `Stage`, `Probability`, `Value`, `CloseDate` (migran a Deal). Añadir `ConvertedToDealId`. Normalizar `LeadStatus` a 5 valores.
- ~15 SPs PG + 15 T-SQL.
- Backfill script: `INSERT INTO crm.Deal SELECT ... FROM crm.Lead WHERE Stage IS NOT NULL`.

## Consecuencias (B+B aprobada)

| Ítem | Cantidad |
|---|---|
| Migraciones goose | 12 |
| SPs PG nuevos | ~25 |
| SPs T-SQL equivalentes | ~25 |
| Endpoints API | ~30 |
| Páginas UI nuevas | 4 (Contactos, Empresas, Deals, Deal detail) |
| Backfills | 2 (Lead→Deal, opcional Contact promotion) |
| Estimación | 4-5 semanas (1 dev + 1 SQL + 1 QA, paralelizable 3 workstreams) |

## Alternativas descartadas

- **A+A (reusar master.Customer + extender Lead)**: descartada. Contamina tabla contable con leads fríos e impide modelo 1-Company-N-Contacts-N-Deals.
- **Híbrido A+B (reusar Customer + separar Deal)**: descartada. Forzaría `Deal.CustomerId → master.Customer`, inaceptable para deals aún no ganados.
- **Híbrido B+A (crm.Contact + extender Lead)**: descartada. Mezcla de criterios; el overhead de tener Contact sin Deal propio es peor que tener todo limpio.

## Plan de implementación

Ver [docs/wiki/design-audits/2026-04-19-crm.md](../wiki/design-audits/2026-04-19-crm.md) sección 7 y los issues creados en el milestone [CRM Redesign · Fase 1](https://github.com/zentto-erp/zentto-web/milestone/1):

1. **CRM-101** [#375](https://github.com/zentto-erp/zentto-web/issues/375) — tokens + DESIGN.md base (en curso).
2. **CRM-108** [#382](https://github.com/zentto-erp/zentto-web/issues/382) — API SavedView (en curso).
3. **CRM-110** [#384](https://github.com/zentto-erp/zentto-web/issues/384) — API Contact/Company/Deal dual (este ADR lo habilita).
4. **CRM-111** [#385](https://github.com/zentto-erp/zentto-web/issues/385) — UI Contactos/Empresas/Deals.
5. Resto del milestone para drawer, RecordTable, palette, etc.

## Criterios de aceptación del ADR

- [x] Firma del product owner.
- [ ] PR CRM-110 merged con backfill Lead→Deal ejecutado en dev.
- [ ] Reportes de conversión funnel demostrados funcionando en `/reportes`.
- [ ] SQL Server nivelado con PG para las 14 tablas CRM + 3 nuevas (`Contact`, `Company`, `Deal`).
- [ ] ≥ 1 app hermana (hotel o medical) demostrando consumo de `RecordTable` de shared-ui sin romper.

## Referencias

- [Design Brief](../wiki/design-audits/2026-04-19-crm.md)
- [Integration Review](../wiki/design-audits/2026-04-19-crm-integration.md)
- HubSpot Smart CRM — Contact/Company/Deal model.
- Pipedrive — Deal-first pipeline model.
- Salesforce — Lead → Opportunity conversion flow.
- Schema actual CRM: [web/api/sqlweb-pg/baseline/003_tables.sql:1087-1394](../../web/api/sqlweb-pg/baseline/003_tables.sql).
- SQL Server desfasado: [web/api/sqlweb-mssql/01_ddl_tables.sql:2835-2987](../../web/api/sqlweb-mssql/01_ddl_tables.sql).
