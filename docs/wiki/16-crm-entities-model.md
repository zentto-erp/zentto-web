# 16 — Modelo de entidades CRM (Contact / Company / Deal / Lead)

> Fuente única de verdad: [ADR-CRM-001](../adr/ADR-CRM-001-entities-model.md).
> Este documento es la vista narrativa para equipo de producto, QA y frontend.
> Si el ADR y este doc discrepan, **gana el ADR**.

## 1. Contexto

Hasta 2026-Q1, el CRM vivía en PostgreSQL con 14 tablas en schema `crm` (Lead, Pipeline, PipelineStage, Activity, Campaign, CampaignContact, Agent, LeadHistory, LeadScore, AutomationRule, AutomationLog, CallLog, CallQueue, CallScript). `crm.Lead` mezclaba dos ciclos de vida distintos:

- **Prospect frío** (nombre, email, teléfono, fuente, estado de calificación).
- **Oportunidad con pipeline** (stage, probability, value, closeDate, ownerAgent).

Esa mezcla impedía reportes de conversión funnel limpios, múltiples deals por contacto y separar prospecting de sales cycle en UI y permisos. "Contactos" tampoco era entidad de primera clase: `Lead.ContactName/Email/Phone` eran strings planos, y `master.Customer` (tabla contable) no es apropiada para prospects sin datos fiscales.

El **ADR-CRM-001** aprobó la **opción B+B**: crear `crm.Contact` y `crm.Company` como entidades independientes, separar `crm.Deal` del `crm.Lead`, y mantener `Lead` como prospect puro.

## 2. Diagrama ER (ASCII)

```
                         ┌───────────────────────┐
                         │     crm.Company       │
                         │───────────────────────│
                         │ CompanyId  (PK, UUID) │
                         │ Name                  │
                         │ Domain                │
                         │ Industry              │
                         │ Size                  │
                         │ OwnerAgentId  (FK)    │
                         │ CreatedAt / UpdatedAt │
                         └──────────┬────────────┘
                                    │ 1
                                    │
                                    │ N
                         ┌──────────┴────────────┐
                         │     crm.Contact       │
                         │───────────────────────│
                         │ ContactId   (PK, UUID)│
                         │ CompanyId   (FK null) │
                         │ FirstName / LastName  │
                         │ Email / Phone         │
                         │ JobTitle              │
                         │ OwnerAgentId (FK)     │
                         │ PromotedCustomerId    │──┐  FK opcional → master.Customer
                         │ CreatedAt / UpdatedAt │  │     (al ganar un Deal)
                         └─────┬──────────┬──────┘  │
                               │ 1        │ 1       │
                               │          │         ▼
                               │          │   ┌──────────────────┐
                               │          │   │ master.Customer  │  ← tabla contable
                               │          │   │ (facturación)    │
                               │          │   └──────────────────┘
                               │ N        │ N
                    ┌──────────┴──────┐   │
                    │   crm.Lead      │   │
                    │─────────────────│   │
                    │ LeadId (PK)     │   │
                    │ ContactId (FK)  │   │     (un Lead puede convertirse
                    │ CompanyId (FK)  │   │      a Deal; al convertirse,
                    │ Source          │   │      LeadStatus = CONVERTED y
                    │ LeadStatus      │   │      ConvertedToDealId se popula)
                    │ (NEW|CONTACTED  │   │
                    │  |QUALIFIED     │   │
                    │  |DISQUALIFIED  │   │
                    │  |CONVERTED)    │   │
                    │ ConvertedToDeal │───┼───┐
                    │ Id  (FK null)   │   │   │
                    │ OwnerAgentId    │   │   │
                    └─────────────────┘   │   │
                                          │   │
                               ┌──────────┴───┼──────────┐
                               │   crm.Deal   │          │
                               │──────────────┤          │
                               │ DealId (PK)  │◄─────────┘
                               │ ContactId (FK)│
                               │ CompanyId (FK)│
                               │ PipelineId(FK)│ → crm.Pipeline
                               │ StageId  (FK) │ → crm.PipelineStage
                               │ Status        │ (OPEN|WON|LOST)
                               │ Value / Currency
                               │ Probability   │
                               │ CloseDate     │
                               │ OwnerAgentId  │
                               │ CreatedAt     │
                               └──────┬────────┘
                                      │ 1
                                      │
                        ┌─────────────┴─────────────┐
                        │ N                         │ N
               ┌────────┴────────┐        ┌─────────┴─────────┐
               │  crm.DealLine   │        │  crm.DealHistory  │
               │─────────────────│        │───────────────────│
               │ DealLineId (PK) │        │ DealHistoryId (PK)│
               │ DealId (FK)     │        │ DealId (FK)       │
               │ ProductId (FK?) │        │ OldStageId        │
               │ Description     │        │ NewStageId        │
               │ Quantity        │        │ ChangedAt         │
               │ UnitPrice       │        │ ChangedByUserId   │
               │ LineTotal       │        │ Origin            │
               └─────────────────┘        └───────────────────┘
```

## 3. Tablas

### 3.1 `crm.Company`

Empresa/cuenta B2B. Una Company agrupa N Contacts y N Deals. Ciclo de vida largo: una vez creada, rara vez se elimina (se archiva).

| Campo | Tipo | Notas |
|---|---|---|
| `CompanyId` | UUID PK | |
| `Name` | text | Obligatorio |
| `Domain` | text | Ej. `acme.com`, usado para matching auto de contacts |
| `Industry` | text | Clasificación libre o tomada de `mstr.IndustryCatalog` |
| `Size` | text | `1-10 / 11-50 / 51-200 / 201-1000 / 1000+` |
| `OwnerAgentId` | FK `crm.Agent` | Vendedor responsable |
| `CreatedAt / UpdatedAt` | timestamptz | UTC-0 |

### 3.2 `crm.Contact`

Persona de un Company (o individual sin Company). Promovible a `master.Customer` al ganar un Deal.

| Campo | Tipo | Notas |
|---|---|---|
| `ContactId` | UUID PK | |
| `CompanyId` | FK `crm.Company` (nullable) | B2C si null |
| `FirstName / LastName` | text | |
| `Email / Phone` | text | Indexados; Email único por tenant |
| `JobTitle` | text | |
| `OwnerAgentId` | FK `crm.Agent` | |
| `PromotedCustomerId` | FK `master.Customer` (nullable) | Se popula al ganar un Deal; evita duplicar CRM vs contabilidad |
| `CreatedAt / UpdatedAt` | timestamptz | |

### 3.3 `crm.Lead` (refactorizado)

Prospect frío. Después del refactor, el Lead NO tiene stage/probability/value/closeDate — esos campos migran a `crm.Deal`.

| Campo | Tipo | Notas |
|---|---|---|
| `LeadId` | UUID PK | |
| `ContactId` | FK `crm.Contact` | Se crea/matchea al ingresar el lead |
| `CompanyId` | FK `crm.Company` (nullable) | |
| `Source` | text | `WEBSITE / LANDING / FORM / REFERRAL / IMPORT / API` |
| `LeadStatus` | enum | `NEW / CONTACTED / QUALIFIED / DISQUALIFIED / CONVERTED` |
| `ConvertedToDealId` | FK `crm.Deal` (nullable) | Populado al convertir |
| `OwnerAgentId` | FK `crm.Agent` | |
| `CreatedAt / UpdatedAt` | timestamptz | |

Campos **removidos** del Lead (migran a Deal): `Stage`, `StageId`, `Probability`, `Value`, `Currency`, `CloseDate`.

### 3.4 `crm.Deal`

Oportunidad en pipeline. Múltiples Deals por Contact/Company (ciclo recurrente B2B).

| Campo | Tipo | Notas |
|---|---|---|
| `DealId` | UUID PK | |
| `ContactId` | FK `crm.Contact` | Obligatorio |
| `CompanyId` | FK `crm.Company` | Nullable (B2C) |
| `PipelineId` | FK `crm.Pipeline` | |
| `StageId` | FK `crm.PipelineStage` | |
| `Status` | enum | `OPEN / WON / LOST` |
| `Value / Currency` | numeric / text | Respeta `cfg.Country.Currency` |
| `Probability` | numeric(3,0) | 0..100, usualmente dictada por el stage |
| `CloseDate` | date | Estimada mientras `OPEN`; real al `WON/LOST` |
| `OwnerAgentId` | FK `crm.Agent` | |

### 3.5 `crm.DealLine`

Línea de producto/servicio dentro de un Deal. Sirve para cotización previa a factura.

| Campo | Tipo | Notas |
|---|---|---|
| `DealLineId` | UUID PK | |
| `DealId` | FK `crm.Deal` | |
| `ProductId` | FK `inv.Product` (nullable) | Puede ser servicio libre |
| `Description / Quantity / UnitPrice / LineTotal` | text / numeric | |

### 3.6 `crm.DealHistory`

Auditoría de cambios de stage. Alimenta reportes de velocity.

| Campo | Tipo | Notas |
|---|---|---|
| `DealHistoryId` | UUID PK | |
| `DealId` | FK `crm.Deal` | |
| `OldStageId / NewStageId` | FK `crm.PipelineStage` | |
| `ChangedAt` | timestamptz | UTC-0 |
| `ChangedByUserId` | FK `mstr.User` | |
| `Origin` | text | `UI / API / AUTOMATION / BACKFILL_LEAD:<leadId>` |

### 3.7 Tablas preservadas

Sin cambios estructurales mayores: `crm.Pipeline`, `crm.PipelineStage`, `crm.Activity`, `crm.Agent`, `crm.Campaign`, `crm.CampaignContact`, `crm.AutomationRule`, `crm.AutomationLog`, `crm.CallLog`, `crm.CallQueue`, `crm.CallScript`, `crm.LeadHistory`, `crm.LeadScore`.

## 4. Flujo Lead → Deal → Customer

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐       ┌──────────────────┐
│   LEAD      │──────▶│  QUALIFIED  │──────▶│    DEAL     │──────▶│   DEAL WON       │
│   (NEW)     │  SDR  │             │  SDR  │   (OPEN)    │  AE   │                  │
└─────────────┘       └─────────────┘       └─────────────┘       └────────┬─────────┘
                                                                           │
                                                                           ▼
                                                                  ┌──────────────────┐
                                                                  │ Promote Contact  │
                                                                  │ → master.Customer│
                                                                  │ (opcional, solo  │
                                                                  │ si hay facturar) │
                                                                  └──────────────────┘
                            │                       │
                            ▼ DISQUALIFIED          ▼ DEAL LOST
                    (LeadStatus=DISQ)        (Status=LOST, CloseDate=today)
```

### Reglas

1. **Un Lead siempre pertenece a un Contact.** Al ingresar un lead nuevo (formulario web, importación, API), se busca el Contact por email/phone; si no existe, se crea automáticamente. Si el dominio del email matchea `crm.Company.Domain`, el Contact se liga a esa Company.
2. **Solo los leads `QUALIFIED` pueden convertirse a Deal.** Al convertir:
   - `Lead.LeadStatus = 'CONVERTED'`.
   - `Lead.ConvertedToDealId = <nuevoDealId>`.
   - Se crea el `crm.Deal` con los datos del Contact + stage inicial del pipeline default.
3. **Múltiples Deals por Contact/Company.** No se archiva el Contact al ganar/perder un Deal; permite ciclos recurrentes de ventas B2B (cross-sell/upsell).
4. **Promoción Contact → Customer** es opcional y explícita. Se dispara cuando:
   - El Deal pasa a `WON` **y** el usuario emite una cotización/factura que requiere `master.Customer`.
   - El SP `usp_crm_Deal_Win` verifica `Contact.PromotedCustomerId`. Si es null, crea `master.Customer` con los datos fiscales que aporte el usuario en ese momento (`FiscalId`, `CreditLimit`, etc.) y popula el FK.
5. **Reportes funnel** se calculan sobre el conjunto:
   - Leads creados → Leads qualified → Deals open → Deals won (ratio y velocity por stage).
6. **Dual-DB obligatorio.** Todas las tablas y SPs se crean en ambos motores (PostgreSQL + SQL Server) vía migración goose + T-SQL (regla `feedback_dual_database`).

## 5. Impacto

Según ADR-CRM-001 §"Consecuencias":

- 12 migraciones goose.
- ~25 SPs PostgreSQL + ~25 T-SQL equivalentes.
- ~30 endpoints API.
- 4 páginas UI nuevas (Contactos, Empresas, Deals, Deal detail).
- 2 backfills (Lead→Deal obligatorio, Contact→Customer opcional).
- Estimación: 4-5 semanas, paralelizable en 3 workstreams.

## 6. Implementación y referencias

Issues en el milestone [CRM Redesign · Fase 1](https://github.com/zentto-erp/zentto-web/milestone/1):

- **CRM-101** #375 — tokens + DESIGN.md base.
- **CRM-108** #382 — API SavedView.
- **CRM-110** #384 — API Contact/Company/Deal dual (habilitado por este ADR).
- **CRM-111** #385 — UI Contactos/Empresas/Deals.
- **CRM-114** #388 — este doc + wiki + DESIGN.md por app + sync `zentto-erp-docs`.

Documentos relacionados:

- [ADR-CRM-001](../adr/ADR-CRM-001-entities-model.md) — fuente única de verdad.
- [04-modular-frontend.md](./04-modular-frontend.md) — patrones UI del rediseño.
- [DESIGN-SYSTEM.md](./DESIGN-SYSTEM.md) — overlay de design system.
- [11-dual-database.md](./11-dual-database.md) — regla dual-DB y propagación de cambios.
- [15-event-bus.md](./15-event-bus.md) — eventos emitidos por CRM (lead.created, deal.won, etc.).
