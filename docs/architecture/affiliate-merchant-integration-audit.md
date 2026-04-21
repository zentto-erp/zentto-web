# Auditoría: integrar Afiliados + Merchants con Backoffice y CRM

Fecha: 2026-04-20
Rama: `fix/zentto-grid-registro-automatico` (solo lectura, sin implementación)
Objetivo: entender el estado actual de los módulos CRM y Backoffice para decidir
cómo registrar afiliados/merchants del ecommerce como entidades visibles y
facturables dentro del ERP, evitando silos paralelos.

---

## 1. Estado actual CRM

### 1.1 Entidades y esquema

El módulo CRM usa el schema `crm` en PostgreSQL (migración `00127_crm_contact_company_deal_tables.sql`)
con cuatro entidades principales y otras de soporte:

| Tabla              | Rol                                                                 | PK                 | FK tenant    |
| ------------------ | ------------------------------------------------------------------- | ------------------ | ------------ |
| `crm.Company`      | Cuenta corporativa / empresa prospecto (B2B)                        | `CrmCompanyId`     | `CompanyId`  |
| `crm.Contact`      | Persona de contacto (opcionalmente ligada a `crm.Company`)          | `ContactId`        | `CompanyId`  |
| `crm.Deal`         | Oportunidad de venta con pipeline/stage, owner y valor estimado     | `DealId`           | `CompanyId`  |
| `crm.DealLine`     | Líneas de producto de una oportunidad                               | `LineId`           | (via deal)   |
| `crm.DealHistory`  | Timeline de cambios (stage, owner, status, notas)                   | `HistoryId`        | (via deal)   |
| `crm.Lead`         | Prospecto crudo (landing, cold inbound) antes de calificar          | `LeadId`           | `CompanyId`  |
| `crm.Pipeline`     | Pipelines con stages configurables (LANDING, INBOUND, etc.)         | `PipelineId`       | `CompanyId`  |
| `crm.PipelineStage`| Etapas ordenadas con probabilidad, color, flags `IsClosed`/`IsWon`  | `StageId`          | (via pipe)   |
| `crm.Agent`        | Agente/sales rep dueño de deals (tabla ya existente)                | `AgentId`          | `CompanyId`  |

Fuente: `web/api/migrations/postgres/00127_crm_contact_company_deal_tables.sql`, `00093_landing_leads_to_crm.sql`.

### 1.2 Tipificación / partner/reseller

- **NO hay** un campo `ContactType` ni `CompanyType` (`customer` / `partner` /
  `reseller` / `supplier`). Todas las entidades son "prospecto/cliente" por
  naturaleza. La única diferenciación hoy es:
  - `crm.Contact.PromotedCustomerId` → cuando el contacto fue promovido a
    `master.Customer` (ver SP `usp_crm_contact_promote_to_customer`, migración
    `00129_crm_contact_sps.sql`).
  - `crm.Lead.Source` → string libre (`'zentto-landing'`, `'WEB'`, `'COLD'`…).
  - `crm.Deal.Source` → string libre.
- **Sí hay** un concepto independiente de "partner" en `cfg.Partner` (migración
  `00082_pricing_plans_and_partners.sql`) — pero es **tabla separada** fuera del
  schema `crm`, con su propia noción de referidos y comisiones (ver §3.4).

### 1.3 Partner / Reseller: flujo actual

Hoy existen **tres silos de "alguien externo que nos trae negocio"** que **no
se hablan entre sí**:

1. `cfg.Partner` + `cfg.PartnerReferral` → referidores B2B (landing
   `/partners`, API `/v1/partners/*`). Comisión global por partner.
2. `store.Affiliate` + `store.AffiliateCommission` + `store.AffiliatePayout` →
   afiliados del marketplace (landing `/afiliados`). Comisión por categoría de
   producto.
3. `store.Merchant` + `store.MerchantProduct` + `store.MerchantPayout` →
   vendedores externos del marketplace (landing `/vender`). Comisión del sitio
   sobre sus ventas (revenue-share inverso).

**Ninguno crea un `crm.Contact` ni un `crm.Company`.** Ninguno dispara un
`crm.Lead` ni un `crm.Deal`. Son silos técnicos completamente separados.

### 1.4 Comisiones en CRM

- `crm.Deal` tiene `OwnerAgentId` → `crm.Agent`, pero **no hay** tabla
  `crm.AgentCommission` ni schema de comisiones internas. El cierre de deal
  (`closeDealWon`) no dispara nada contable ni remunerativo.
- Las comisiones reales viven en `store.AffiliateCommission` y en los payouts
  de merchant, pero no están vinculadas al CRM.

### 1.5 Bridge CRM ↔ ERP core (`master.Customer`)

- `crm.Contact.PromotedCustomerId BIGINT` — FK lógica (no física) a
  `master.Customer`.
- SP `usp_crm_contact_promote_to_customer` — migración `00129_crm_contact_sps.sql:274`.
  Crea o reutiliza `master.Customer` a partir del contacto (match por email/phone).
  Endpoint: `POST /v1/crm/contacts/:id/promote-customer`.
- **NO existe** el bridge equivalente para `crm.Company` → cuenta/proveedor.

### 1.6 UI actual

`web/modular-frontend/packages/module-crm/src/components/`:

- `LeadsPage.tsx`, `LeadDetailPanel.tsx`, `LeadActivityTimeline.tsx`, `LeadScoreBadge.tsx`, `StaleLeadsAlert.tsx`
- `PipelineKanban.tsx` — Kanban por stage
- `CompaniesPage.tsx`, `CompanyDetailPanel.tsx`
- `ContactsPage.tsx`, `ContactDetailPanel.tsx`
- `DealsPage.tsx`, `DealDetailPanel.tsx`
- `ActividadesPage.tsx`, `ActivityDetailPanel.tsx`
- `AutomationRulesPage.tsx`, `CRMReportsPage.tsx`, `CRMSettingsPage.tsx`
- `IntegrationsPage.tsx`, `LeadTimeline.tsx`

Hooks: `useCRM`, `useCompanies`, `useContacts`, `useDeals`, `useLeadConvert`,
`useCRMAnalytics`, `useCRMReports`, `useCRMScoring`, `useCRMAutomation`, `useIntegrations`.

**No hay** `PartnersPage`, `AffiliatesPage` ni `MerchantsPage` dentro del módulo CRM.

### 1.7 Hook existente: landing → CRM

Migración `00093_landing_leads_to_crm.sql` instala `usp_sys_lead_upsert(email,
name, company, country, source, topic, message, phone)` que:

1. Upsertea en `public.Lead` (tabla pública idempotente por `(Email, Source)`).
2. Crea/actualiza automáticamente un `crm.Lead` en el pipeline `LANDING` del
   tenant `ZENTTO` (stage `PROSPECT`).

**Este es el ÚNICO puente automático externo→CRM que existe hoy.** Y solo se
dispara desde la landing principal, no desde `/afiliados`, `/vender` ni
`/partners`.

---

## 2. Estado actual Backoffice

### 2.1 Qué es el backoffice Zentto

Es un **panel SaaS exclusivo del equipo interno Zentto** (no del cliente
final). Solo accede personal con `Master Key + TOTP 2FA` (ver
`backoffice-auth.routes.ts` y `layout.tsx` del shell).

Endpoints `/v1/backoffice/*` (requieren `X-Master-Key`):

| Endpoint                                            | Función                                           |
| --------------------------------------------------- | ------------------------------------------------- |
| `GET /tenants`, `GET /tenants/:id`                  | Lista/detalle de tenants (empresas clientes Zentto) |
| `POST /tenants/provision-full`                      | Provisionar tenant completo (company + BD + admin + welcome email) |
| `POST /tenants/:id/apply-plan`                      | Aplicar plan (FREE/STARTER/PRO/ENTERPRISE)        |
| `GET /revenue`                                      | Métricas revenue (MRR estimado por plan)          |
| `GET /dashboard`                                    | KPIs agregados (tenants, trial, MRR, DB size, tickets GitHub) |
| `GET /resources`, `GET /cleanup`, `POST /cleanup/*` | Cola de limpieza (tenants inactivos)              |
| `GET /backups`, `POST /tenants/:id/backup`          | Backups a Hetzner Object Storage                  |
| `POST /tenants/:id/restore/:backupId`               | Restore                                           |
| `GET /analytics/overview\|performance\|business`    | Observability cross-tenant vía Elasticsearch      |
| `GET /kafka/topics`                                 | Métricas de Kafka                                 |
| `GET /storage/status`                               | Estado Hetzner S3                                 |

Fuente: `web/api/src/modules/backoffice/backoffice.routes.ts`.

### 2.2 Entidades principales del backoffice

- `cfg.Company` (tenant) + `cfg.Branch` + `cfg.Tenant*`
- `sys.License` + `sys.TenantDatabase`
- `sys.CleanupQueue` + `sys.TenantBackup`
- `cfg.PricingPlan` (planes de suscripción) + `cfg.Partner`/`cfg.PartnerReferral`
- Logs cross-tenant en Elasticsearch (`zentto-api-logs-*`, `zentto-api-events-*`)

**No maneja** clientes finales del tenant, solo meta-gestión de la plataforma SaaS.

### 2.3 UI del backoffice

`web/modular-frontend/apps/shell/src/app/(dashboard)/backoffice/`:

- `page.tsx` — dashboard general
- `tenants/page.tsx`
- `planes/page.tsx` + `PlanFormModal.tsx`
- `recursos/page.tsx`, `limpieza/page.tsx`, `respaldos/page.tsx`
- `soporte/` — integración con GitHub Issues de `zentto-erp/zentto-support`

Sidebar fija con 7 items (Dashboard, Tenants, Planes, Recursos, Respaldos,
Limpieza, Soporte). **Cualquier item nuevo ("Partners", "Afiliados",
"Merchants") requiere editar `layout.tsx`**.

### 2.4 Extensibilidad

- **Widgets del dashboard:** el endpoint `GET /v1/backoffice/dashboard` agrega
  KPIs fijos (tenants, trials, cleanup, DB size, MRR, tickets). Para agregar un
  widget "Afiliados activos / Comisiones pendientes" hay que:
  1. Añadir consultas a `backoffice.routes.ts` (directas a `store.Affiliate*`).
  2. Añadir cards en `backoffice/page.tsx`.
  No existe un sistema de widgets pluggable.
- **Páginas nuevas:** crear carpeta nueva bajo `backoffice/` + añadir item a
  `MENU_ITEMS` en `layout.tsx`.
- **No hay** mecanismo de widgets "drop-in" ni sistema de permisos granulares
  (todo es SYSADMIN + master key).

### 2.5 Hoy no existe panel admin de afiliados/merchants dentro del backoffice

El panel admin de afiliados y merchants ya existe, **pero vive en la app
ecommerce**, no en el backoffice:

- `web/modular-frontend/apps/ecommerce/src/app/admin/afiliados/page.tsx`
- `web/modular-frontend/apps/ecommerce/src/app/admin/afiliados/comisiones/page.tsx`
- (panel admin de merchants — falta verificar, hay endpoints
  `usp_store_merchant_admin_*`)

El mismo contenido se repetiría si se moviera al backoffice, o se requiere
consolidar.

---

## 3. Puentes ecommerce ↔ CRM/backoffice hoy

### 3.1 Tabla de unión

**NO EXISTE** una tabla de unión que relacione:

| Desde                      | Hacia                            | Hoy           |
| -------------------------- | -------------------------------- | ------------- |
| `store.Affiliate`          | `crm.Contact` / `crm.Company`    | ❌ Nada       |
| `store.Merchant`           | `crm.Contact` / `crm.Company`    | ❌ Nada       |
| `cfg.Partner`              | `crm.Contact` / `crm.Company`    | ❌ Nada       |
| `store.Affiliate.CustomerId`| `master.Customer`                | ✅ FK lógica  |
| `store.Merchant.CustomerId`| `master.Customer`                | ✅ FK lógica  |
| `crm.Contact`              | `master.Customer`                | ✅ `PromotedCustomerId` + SP promote |
| `crm.Company`              | `master.Customer` / `Provider`   | ❌ No hay bridge |
| `ar.SalesDocumentLine`     | `store.Merchant` (attribution)   | ✅ columna `MerchantId` (migración 00151) |
| `ar.SalesDocumentLine`     | `store.Affiliate` (attribution)  | ❌ No directo; vía `AffiliateCommission.OrderNumber` |

### 3.2 Hooks "auto-crear CRM entity"

- `cfg.Partner` (POST `/v1/partners/apply`) — **NO** crea `crm.Contact`.
- `store.Affiliate` (`usp_store_affiliate_register`) — **NO** crea `crm.Contact`.
- `store.Merchant` (`usp_store_merchant_apply`) — **NO** crea `crm.Contact`
  ni `crm.Company`.
- `public.Lead` (landing inbound) — **SÍ** crea `crm.Lead` en pipeline LANDING
  (único caso).

### 3.3 Contabilidad

**NO hay posteo contable automático desde ningún evento de comisión.** Revisado:

- `store.AffiliateCommission` → cuando pasa a `paid` vía
  `usp_store_affiliate_payout_generate`, solo se actualiza la tabla de
  comisiones. **No se crea asiento contable**.
- `store.MerchantPayout` → igual. Solo actualiza `Status = 'paid'`.
- `cfg.PartnerReferral` → igual.
- `ar.SalesDocumentLine` (órdenes del ecommerce) — tiene columna `MerchantId`
  pero el posteo contable de la venta se apoya en el flujo estándar ERP (SP
  de AR), sin segregación de comisión.

Grep confirma: 0 coincidencias `JournalEntry`/`usp_con_*` en las migraciones de
afiliados/merchants (00150, 00151).

### 3.4 Facturación y payouts

- Los `store.AffiliatePayout` y `store.MerchantPayout` son **tablas propias**,
  no facturas estándar. No tienen:
  - Número fiscal.
  - PDF generado.
  - Contabilización.
  - Retenciones legales (ISLR, IVA).
- El `TransactionRef` es texto libre.

---

## 4. Huecos detectados

Lista priorizada (1 = más urgente):

1. **Silos paralelos de "socio externo"** (`cfg.Partner`, `store.Affiliate`,
   `store.Merchant`) — tres tablas que modelan casi lo mismo (persona/empresa
   externa que genera revenue para Zentto) sin un concepto unificado.
2. **Ningún afiliado/merchant existe en el CRM** — imposible hacerles
   seguimiento comercial, asignarles `Owner`, mandarles actividades, ver
   historial de deals.
3. **Ningún afiliado/merchant existe en contabilidad** — los payouts son
   movimientos invisibles para el módulo fiscal. Riesgo tributario real (en
   Venezuela, ISLR 3% retención a personas naturales, etc.).
4. **Panel admin de afiliados/merchants vive en la app ecommerce** y no en el
   backoffice — el equipo Zentto los gestiona con las mismas credenciales del
   tenant ecommerce, no con la master key + TOTP. Separation of duties débil.
5. **Dashboards separados** — afiliados en `/afiliados/dashboard`, merchants en
   `/vender/dashboard`, partners en `/partners/dashboard`. El equipo interno no
   tiene un dashboard unificado "Canal / Revenue partners".
6. **`crm.Company` no se promueve a `master.Customer`/`Provider`** — el SP
   `usp_crm_contact_promote_to_customer` existe; el análogo para company, no.
7. **Comisiones no enlazadas con deals** — cuando el afiliado genera conversión
   del ecommerce, no se crea un `crm.Deal` WON con `OwnerAgentId` apuntando
   al afiliado/partner. Se pierde la trazabilidad comercial.
8. **El backoffice no tiene widgets "canal"** — el dashboard general no muestra
   afiliados activos, comisiones pendientes, payouts por procesar.
9. **No hay tipificación en `crm.Contact`/`crm.Company`** — no hay manera de
   filtrar "todos mis partners activos" o "todos mis merchants aprobados" en
   la UI del CRM aunque se cree el puente.

---

## 5. Opciones de integración

### Opción A — Minimal: reusar `crm.Contact` / `crm.Company` con columna `Kind`

**Cambio mínimo.** Añadir a `crm.Contact` una columna `Kind VARCHAR(20)` con
check constraint:

```
'LEAD' | 'CUSTOMER' | 'PARTNER' | 'AFFILIATE' | 'MERCHANT' | 'SUPPLIER'
```

Similar en `crm.Company`. Y agregar FK inversa opcional:

```sql
ALTER TABLE store."Affiliate" ADD COLUMN "CrmContactId" BIGINT REFERENCES crm."Contact"("ContactId");
ALTER TABLE store."Merchant"  ADD COLUMN "CrmContactId" BIGINT REFERENCES crm."Contact"("ContactId");
ALTER TABLE store."Merchant"  ADD COLUMN "CrmCompanyId" BIGINT REFERENCES crm."Company"("CrmCompanyId");
ALTER TABLE cfg."Partner"     ADD COLUMN "CrmContactId" BIGINT REFERENCES crm."Contact"("ContactId");
ALTER TABLE cfg."Partner"     ADD COLUMN "CrmCompanyId" BIGINT REFERENCES crm."Company"("CrmCompanyId");
```

Extender los SPs `apply` de los tres (`usp_store_affiliate_register`,
`usp_store_merchant_apply`, `usp_cfg_partner_apply`) para crear/linkear
`crm.Contact` + `crm.Company` con `Kind` correcto.

**Pros:**
- Cambio pequeño, 3-4 migraciones.
- Reusa todo el UI del CRM (Contactos / Empresas ya listos).
- Filtrable en UI con `?kind=AFFILIATE`.
- Alta compatibilidad retroactiva.
- No rompe nada de ecommerce.

**Cons:**
- `crm.Contact` sigue teniendo columnas específicas de B2B (Department, Title,
  LinkedIn) que no aplican a afiliados físicos.
- Los datos comerciales de afiliado (ReferralCode, PayoutMethod, TaxId de payout,
  etc.) siguen en `store.Affiliate`, con doble fuente de verdad para email/phone.
- `Kind` es denormalización: un contacto que es cliente Y afiliado necesita
  dos filas o un array.
- No unifica comisiones — siguen en tablas separadas.

### Opción B — Fuerte: tabla bridge `crm.Partner` (supertipo)

Crear una entidad nueva `crm.Partner` que represente "cualquier socio externo
que genera revenue para Zentto" (afiliado, merchant, referidor B2B,
distribuidor):

```sql
CREATE TABLE crm."Partner" (
  "PartnerId"       BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CompanyId"       INTEGER NOT NULL,                          -- tenant
  "PartnerType"     VARCHAR(20) NOT NULL,                      -- AFFILIATE | MERCHANT | RESELLER | REFERRER
  "ContactId"       BIGINT REFERENCES crm."Contact"(...),
  "CrmCompanyId"    BIGINT REFERENCES crm."Company"(...),
  "Code"            VARCHAR(40),                               -- ReferralCode | StoreSlug | etc.
  "Status"          VARCHAR(20) NOT NULL,
  "CommissionRate"  NUMERIC(5,2),
  "PayoutMethod"    VARCHAR(30),
  "PayoutDetails"   JSONB,                                     -- cifrado pgcrypto
  "TaxId"           VARCHAR(40),
  "LegalName"       VARCHAR(200),
  "ApprovedAt"      TIMESTAMP,
  "ApprovedBy"      VARCHAR(60),
  "CreatedAt"       TIMESTAMP DEFAULT (now() AT TIME ZONE 'UTC'),
  CONSTRAINT "UK_crm_Partner_Type_Code" UNIQUE ("CompanyId", "PartnerType", "Code")
);
```

Y una tabla `crm.PartnerCommission` que **unifica** las comisiones:

```sql
CREATE TABLE crm."PartnerCommission" (
  "CommissionId"     BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "PartnerId"        BIGINT NOT NULL REFERENCES crm."Partner"("PartnerId"),
  "CompanyId"        INTEGER NOT NULL,
  "SourceType"       VARCHAR(20),   -- STORE_ORDER | PARTNER_REFERRAL | DEAL_WON
  "SourceRef"        VARCHAR(60),   -- OrderNumber | DealId | …
  "Rate"             NUMERIC(5,2),
  "CommissionAmount" NUMERIC(14,2),
  "Status"           VARCHAR(20),
  "CreatedAt"        TIMESTAMP,
  "ApprovedAt"       TIMESTAMP,
  "PaidAt"           TIMESTAMP,
  "PayoutId"         BIGINT
);
```

`store.Affiliate`, `store.Merchant`, `cfg.Partner` sobreviven como
**extensiones especializadas** con FK a `crm.Partner`. Las tablas
`store.AffiliateCommission`, `store.MerchantPayout`, `cfg.PartnerReferral`
migran a `crm.PartnerCommission` (o quedan como vistas legacy).

**Pros:**
- Un solo lugar para "todos los canales".
- Un solo dashboard "Partners" en el backoffice.
- Un solo pago masivo mensual.
- Trazabilidad completa con CRM (Owner, actividades, deals).
- Facilita posteo contable unificado (§6).
- Nuevos tipos de partner (reseller, VAR, white-label) se añaden sin schema
  change: solo un nuevo `PartnerType`.

**Cons:**
- Migración de datos no trivial (3 tablas → 1 + extensiones).
- Hay que tocar los tres flujos de `apply` y los tres servicios.
- Mientras dure la migración hay duplicación temporal.
- El UI del CRM necesita una sección nueva "Partners" (no es solo
  contactos/empresas).

### Opción C — Módulo nuevo `partners` (tercer módulo)

Crear un **módulo nuevo** paralelo a `crm` y `backoffice`:

- Schema BD: `ptr.*` (o mantener `crm.Partner*` pero tercer microfrontend).
- API: `/v1/partners/*` (ya existe parcial — se expande).
- Frontend: `packages/module-partners/`, app standalone `apps/partners/` o
  sección dentro de `apps/shell`.

Absorbe:
- `/afiliados/*` y `/vender/*` de la app ecommerce (panel público de aplicación
  queda como landing, pero el dashboard interno migra a module-partners).
- `/admin/afiliados` y `/admin/merchants` de la app ecommerce → `/partners/admin/*`.
- `/partners/*` actual → `/partners/referrers/*`.

**Pros:**
- Separación clarísima entre "CRM (pipeline comercial)" y "Partners (canales
  de revenue externo)".
- Módulo autocontenido, fácil de evolucionar.
- Puede tener su propio schema BD sin contaminar `crm` ni `store`.
- Patrón monorepo ya existe (module-admin, module-crm, module-ecommerce).
- Permite dashboards independientes y permisos propios.

**Cons:**
- Mayor overhead: monorepo crece, microfrontend extra, nuevas páginas shell.
- El CRM pierde visibilidad directa de partners (hay que cross-linkear).
- Duplica funcionalidad si el CRM ya tiene contactos/empresas.
- Más superficie para mantener.

---

## 6. Recomendación

**Opción B — tabla bridge `crm.Partner` + `crm.PartnerCommission`**, con
migración **incremental** (no big-bang):

### Justificación

1. **Ya existe el precedente `PromotedCustomerId`**: el CRM es la fuente de
   verdad de personas/empresas externas en el ecosistema Zentto. Meter
   afiliados/merchants allí es coherente.
2. **Hay 3 silos que convergen**: `cfg.Partner`, `store.Affiliate`,
   `store.Merchant` modelan variantes del mismo concepto. Un supertipo evita
   rehacer el problema cada vez que aparezca un cuarto tipo (reseller,
   white-label, influencer, etc.).
3. **Comisiones unificadas desbloquean contabilidad**: con una sola tabla
   `crm.PartnerCommission`, un único SP `usp_crm_Commission_PostToAccounting`
   genera asientos contables estándar (Debe: Gastos de comisiones / Haber:
   Cuentas por pagar partner) y eventualmente facturas de reverso.
4. **Opción A es demasiado débil**: denormalizar con `Kind` no resuelve las
   comisiones ni el payout unificado; solo mueve la dispersión a columnas.
5. **Opción C es prematura**: aún no hay volumen de partners ni requisitos de
   permisos especiales que justifiquen un microfrontend propio. Si en 12-18
   meses hay suficiente volumen se puede extraer `partners/` desde el CRM
   sin romper nada.

### Primer PR que desbloquea todo

Feature branch: `feat/crm-partner-bridge`

Contenido del PR:
1. Migración goose `00160_crm_partner_bridge.sql`:
   - `CREATE TABLE crm."Partner"` (supertipo).
   - `CREATE TABLE crm."PartnerCommission"` (comisiones unificadas; las
     existentes quedan intactas, sólo se suman).
   - `ALTER TABLE store."Affiliate"  ADD "CrmPartnerId" BIGINT REFERENCES crm."Partner"("PartnerId");`
   - `ALTER TABLE store."Merchant"   ADD "CrmPartnerId" BIGINT REFERENCES crm."Partner"("PartnerId");`
   - `ALTER TABLE cfg."Partner"      ADD "CrmPartnerId" BIGINT REFERENCES crm."Partner"("PartnerId");`
   - Backfill idempotente: por cada fila existente en las 3 tablas, crear su
     `crm.Partner` + `crm.Contact` mínimo + FK.
2. Mismas SPs equivalentes en SQL Server (`web/api/sqlweb/includes/sp/`) — regla dual DB.
3. SPs PG:
   - `usp_crm_Partner_List`, `Detail`, `UpsertFromAffiliate`, `UpsertFromMerchant`, `UpsertFromReferrer`.
   - `usp_crm_PartnerCommission_Register` (genérico, reemplaza gradualmente a
     `store_affiliate_attribute_order`).
4. Modificación de los tres `apply` SPs para **también** poblar `crm.Partner`
   + `crm.Contact` + (opcional) `crm.Company` si `LegalName` es B2B.

Con este PR solo:
- Todos los afiliados/merchants/referrers existentes **aparecen en
  `crm.Contact`** con `Kind=partner` (equivalente vía la FK inversa).
- Las 3 UIs actuales **siguen funcionando** (no se migra data).
- Quedan desbloqueados los siguientes PRs (§ abajo).

---

## 7. PRs posteriores (roadmap)

Una vez mergeado `feat/crm-partner-bridge`:

1. **`feat/backoffice-partners-widget`** — agregar sección Partners al sidebar
   del backoffice + tabla consolidada + widgets en dashboard general ("Partners
   activos / Comisiones pendientes / Payouts del mes").
2. **`feat/crm-contact-kind-filter`** — agregar columna `Kind` (derivada o
   denormalizada) a `crm.Contact`/`crm.Company` y filtro de UI "Ver solo
   partners / afiliados / merchants".
3. **`feat/partner-commission-accounting`** — SP
   `usp_crm_PartnerCommission_PostToAccounting` que genera asiento contable
   al aprobar/pagar comisión (migración goose + tests SQL Server).
4. **`feat/partner-deal-link`** — cuando `store.AffiliateCommission` se crea,
   opcional crear `crm.Deal` cerrado-ganado con `OwnerAgentId = partner.Agent`
   (si se modela partner como agente).
5. **`feat/unified-partner-payout`** — reemplazar los 3 endpoints de payout
   por uno unificado `POST /v1/backoffice/partners/payout-run` que genera los
   payouts de los 3 tipos en un solo lote fiscal.
6. **`feat/crm-company-promote-bridge`** — SP análogo a
   `usp_crm_contact_promote_to_customer` pero para company → `master.Customer`
   y company → `ap.Provider` (proveedores / partners que nos facturan).
7. **`chore/partners-public-apis-consolidation`** — consolidar los 3 endpoints
   `apply` públicos (`/partners/apply`, `/v1/store/affiliate/register`,
   `/v1/store/merchant/apply`) bajo el mismo patrón de
   `usp_crm_Partner_ApplyExternal` y documentar flujo en OpenAPI.
