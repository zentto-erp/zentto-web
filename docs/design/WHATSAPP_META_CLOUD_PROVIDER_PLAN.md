# WhatsApp Meta Cloud API — Provider Primario en Zentto Notify

**Estado:** Propuesta — pendiente aprobación PO
**Autor:** Claude Code (basado en estudio de [shridarpatil/whatomate](https://github.com/shridarpatil/whatomate))
**Fecha:** 2026-04-26
**Branch implementación:** `feat/whatsapp-meta-cloud-provider` (en zentto-notify, pendiente)
**Doc relacionado:** `CHAT_AI_RAG_PLAN.md` (v1, ya en prod)

---

## 1. Objetivo

Convertir **Meta Cloud API (oficial)** en el provider primario de WhatsApp en `zentto-notify`, dejando **Baileys como provider secundario** (free / dev / clientes que no requieren templates aprobados).

**Por qué ahora:**
- Baileys (WhatsApp Web no oficial) tiene riesgo de baneo cuando se hace bulk; bloqueante para clientes Pro/Enterprise.
- No soporta templates Meta-aprobados ni campañas formales — features que clientes pagantes piden.
- El stack Node TS encaja bien con el patrón whatomate (HTTP client + webhook + queue + workers).

**No-goals (no se implementan en este ciclo):**
- IVR / voice calling (whatomate lo tiene; complejidad muy alta, no priorizado).
- Flow executor propio para chatbots (whatomate delega a Meta Flows; nosotros también).
- Custom JavaScript en flows (no soportado por Meta).
- SLA tracking automático para agentes.

---

## 1.5 Modelo comercial — zentto-notify como producto SaaS

**Decisión arquitectónica clave:** `zentto-notify` se diseña como **producto SaaS multi-tenant comercializable**, no como herramienta interna del ERP. Esto impacta TODAS las decisiones siguientes.

### 1.5.1 Quién es el cliente

| Tipo | Caso de uso | Cómo conecta WhatsApp |
|---|---|---|
| **Cliente Zentto ERP** (interno) | Notificaciones del ERP a sus contactos | WABA propia (manual o Embedded Signup) |
| **Cliente standalone** (externo) | Empresa que solo usa notify, no el ERP | Embedded Signup Meta |
| **Partner / agencia** (revendedor) | Gestiona N WABAs de N clientes finales | API + multi-org membership |
| **Desarrollador** (API consumer) | Integra notify en su propia app | API keys + webhooks |

### 1.5.2 Implicaciones arquitectónicas (vs solo "interno")

| Capability | Si fuera interno | Como SaaS comercial |
|---|---|---|
| Tenancy | `user_id` simple | `organization_id` + RBAC granular + multi-org users |
| Conexión WABA | App ID compartida Zentto | **Embedded Signup Meta como Tech Provider** + BYO opcional |
| Acceso API | Solo dashboard interno | **API keys por org** + scopes + rate limiting per-key |
| Costo Meta | Lo absorbe Zentto | **Usage metering** + facturación al cliente |
| Branding | Zentto fijo | **White-label** (logo, colores, dominio custom opcional) |
| Compliance | Mínimo | **GDPR delete, AES-256-GCM tokens, audit log, data residency** |
| Webhooks salientes | Internos | Públicos al sistema del cliente, con HMAC signing y retry |
| Observabilidad | Logs server | **Dashboard de métricas POR TENANT** (msgs sent, deliverability, errors) |
| Soporte | Slack interno | **Audit log + impersonation segura** para soporte revisar problemas |

### 1.5.3 Tiers comerciales (propuesta inicial — PO ajusta)

| Tier | Provider permitido | Mensajes/mes incluidos | Features |
|---|---|---|---|
| **Free** | Baileys solo | 100 (rate-limited fuerte) | 1 instancia, sin templates, sin campaigns, sin API |
| **Starter** | Baileys + Meta Cloud (BYO WABA) | 1,000 + costo Meta passthrough | 3 instancias, templates, canned responses |
| **Pro** | Meta Cloud (Embedded Signup o BYO) | 10,000 + costo Meta passthrough | 10 instancias, campaigns, flow builder, API |
| **Enterprise** | Meta Cloud (multi-WABA) | Ilimitado + bundle | Multi-org users, white-label, SLA, audit log, data residency |

### 1.5.4 Decisión sobre App ID Meta

**Descartada:** App ID compartida única para todos los clientes.
- ❌ Si Meta suspende la App, **todos los clientes caen** (riesgo sistémico inaceptable).
- ❌ Cuotas Meta agregadas → ahogan a unos clientes por uso de otros.
- ❌ Compliance: clientes regulados (banca, salud) NO pueden compartir App.

**Adoptada: arquitectura híbrida BSP-like:**

| Modo | Quién | App ID | Tech Provider |
|---|---|---|---|
| **Embedded Signup** | Pro/Enterprise mayoría | App ID Zentto (Tech Provider verificado Meta) | Zentto |
| **BYO WABA** (Bring Your Own) | Enterprise regulados | App ID del cliente | Cliente |
| **Baileys** | Free / dev | N/A | N/A |

Requiere: Zentto debe registrarse como **Tech Provider en Meta Business** (proceso ~7-21 días, pre-requisito de F1).

---

---

## 2. Estado actual (resumen)

| Módulo | Estado | Path |
|---|---|---|
| Provider Baileys | ✅ Funcional 70% | `zentto-notify/src/channels/whatsapp/session.ts` |
| Endpoints REST | ✅ 8 rutas vivas | `zentto-notify/src/channels/whatsapp/routes.ts` |
| Integración chat-engine (RAG) | ✅ vía `ai_respond` action | `zentto-notify/src/chat/flow-executor.ts:414` |
| Multi-tenant | ✅ `wa_instances.user_id` | DB `wa_instances`, `wa_credentials` |
| Templates Meta | ❌ no implementado | — |
| Bulk campaigns con retry | ❌ no implementado | — |
| Visual flow builder | ❌ vacío en dashboard | `zentto-notify/dashboard/app/flows/editor/` |
| Canned responses | ❌ no implementado | — |

---

## 3. Arquitectura propuesta

### 3.1 Patrón provider-agnostic

```
src/channels/whatsapp/
  index.ts                    ← entry point, expone WhatsAppService
  service.ts                  ← lógica común (multi-tenant, persistence, hooks)
  providers/
    types.ts                  ← interface WhatsAppProvider
    baileys/
      session.ts              ← lo que existe hoy (mover acá)
      provider.ts             ← implementa WhatsAppProvider
    meta-cloud/               ← NUEVO
      client.ts               ← HTTP client a graph.facebook.com
      provider.ts             ← implementa WhatsAppProvider
      webhook-verify.ts       ← HMAC-SHA256 verification
      media.ts                ← upload/download/resumable upload
      templates.ts            ← submit/sync templates
  routes.ts                   ← REST igual, internamente delega a provider
  webhooks/
    baileys.ts                ← lo que existe (separar)
    meta-cloud.ts             ← NUEVO: receiver Meta + signature verify
```

### 3.2 Selección de provider por tenant

```ts
// service.ts
function getProvider(instance: WaInstance): WhatsAppProvider {
  switch (instance.provider) {
    case 'meta-cloud': return new MetaCloudProvider(instance.credentials)
    case 'baileys':    return new BaileysProvider(instance.credentials)
    default: throw new Error(`unknown provider: ${instance.provider}`)
  }
}
```

Tenant elige al crear instancia, **scope organization_id** (no user_id):

| Tier | Provider permitido | Onboarding WABA |
|---|---|---|
| Free | `baileys` solo | QR scan |
| Starter | `baileys` o `meta-cloud` BYO | QR o credenciales manuales |
| Pro | `meta-cloud` (Embedded Signup default) | OAuth Meta + Phone selection |
| Enterprise | `meta-cloud` BYO o Embedded | Embedded + multi-WABA |

### 3.3 Multi-tenant + RBAC (foundation crítica)

Antes de cualquier provider, refactor `wa_instances` para soportar multi-tenancy real:

- `wa_organizations` — entidad raíz comercial (tiene plan, billing_status, branding_config).
- `wa_users` — perfiles users (puede pertenecer a N orgs via `wa_user_organizations`).
- `wa_roles` + `wa_permissions` — RBAC granular (resource × action).
- `wa_instances.organization_id` (no user_id) → soft-migration de datos existentes.
- `wa_api_keys` — API keys por org con scopes y rate limit.
- `wa_audit_log` — append-only log de acciones sensibles (soporte, compliance).

### 3.3 Interface común `WhatsAppProvider`

Mínima, basada en lo que ambos providers pueden cumplir:

```ts
interface WhatsAppProvider {
  // conexión
  connect(): Promise<{ status: 'connected' | 'qr_required'; qr?: string }>
  disconnect(): Promise<void>
  isConnected(): Promise<boolean>

  // envío
  sendText(to: string, text: string, replyTo?: string): Promise<{ messageId: string }>
  sendMedia(to: string, media: MediaInput): Promise<{ messageId: string }>
  sendInteractive(to: string, payload: InteractiveInput): Promise<{ messageId: string }>
  sendTemplate(to: string, template: TemplateInput): Promise<{ messageId: string }>  // solo meta-cloud

  // info
  checkNumber(phone: string): Promise<{ exists: boolean }>
  uploadMedia(buffer: Buffer, mime: string): Promise<{ mediaId: string }>
}
```

Métodos exclusivos de Meta (`sendTemplate`, `submitTemplate`, `subscribeWebhook`) lanzan `ProviderNotSupportedError` en Baileys.

---

## 4. Modelo de datos (extensión)

Migración goose nueva en `zentto-notify/src/db/migrations/` (verificar siguiente número libre antes del PR).

**Nota crítica:** la migración va en **2 partes** porque hay refactor de tenancy + features Meta. Parte 1 (multi-tenant foundation) NO toca features Meta y debe ir primero.

### 4.1 Parte 1 — Multi-tenant foundation (F-1)

```sql
-- 0NN_whatsapp_multitenant_foundation.sql
-- +goose Up

-- Organizaciones (entidad comercial raíz)
CREATE TABLE wa_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL DEFAULT 'free'
    CHECK (plan IN ('free','starter','pro','enterprise')),
  billing_status TEXT NOT NULL DEFAULT 'active'
    CHECK (billing_status IN ('active','past_due','suspended','cancelled')),
  branding_config JSONB DEFAULT '{}'::jsonb,
  data_residency TEXT DEFAULT 'eu' CHECK (data_residency IN ('eu','us','latam')),
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users
CREATE TABLE wa_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  password_hash TEXT,
  is_super_admin BOOLEAN DEFAULT false,
  sso_provider TEXT,
  sso_subject TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Many-to-many users ↔ orgs
CREATE TABLE wa_user_organizations (
  user_id UUID NOT NULL REFERENCES wa_users(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES wa_organizations(id) ON DELETE CASCADE,
  role_id UUID NOT NULL,
  is_default BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, organization_id)
);

-- Roles RBAC granular
CREATE TABLE wa_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES wa_organizations(id) ON DELETE CASCADE,
  -- NULL organization_id = role builtin (admin, agent, viewer)
  name TEXT NOT NULL,
  is_builtin BOOLEAN DEFAULT false,
  permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- ej: ["templates:read","templates:create","campaigns:start","contacts:delete"]
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (organization_id, name)
);

-- API keys por org (para integraciones externas + SDK)
CREATE TABLE wa_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES wa_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  key_prefix TEXT NOT NULL,         -- visible: "wak_live_abc123"
  key_hash TEXT NOT NULL,           -- bcrypt
  scopes JSONB NOT NULL DEFAULT '["*"]'::jsonb,
  rate_limit_per_minute INT DEFAULT 60,
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_by UUID REFERENCES wa_users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_wa_api_keys_prefix ON wa_api_keys(key_prefix) WHERE revoked_at IS NULL;

-- Audit log (compliance + soporte)
CREATE TABLE wa_audit_log (
  id BIGSERIAL PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES wa_organizations(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES wa_users(id),
  actor_api_key_id UUID REFERENCES wa_api_keys(id),
  action TEXT NOT NULL,             -- "instance.created", "template.submitted", "campaign.started"
  resource_type TEXT,
  resource_id TEXT,
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_wa_audit_log_org_time ON wa_audit_log(organization_id, created_at DESC);

-- Usage events (billing/metering)
CREATE TABLE wa_usage_events (
  id BIGSERIAL PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES wa_organizations(id) ON DELETE CASCADE,
  instance_id UUID,
  event_type TEXT NOT NULL,         -- "message.sent","message.delivered","template.submitted"
  category TEXT,                    -- "utility","marketing","authentication","service" (Meta categorías de billing)
  quantity INT DEFAULT 1,
  meta_cost_usd NUMERIC(10,6),      -- costo Meta passthrough
  metadata JSONB,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_wa_usage_events_org_time ON wa_usage_events(organization_id, occurred_at DESC);
CREATE INDEX idx_wa_usage_events_billing ON wa_usage_events(organization_id, occurred_at) WHERE meta_cost_usd > 0;

-- Webhooks salientes (al sistema del cliente)
CREATE TABLE wa_outbound_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES wa_organizations(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  secret TEXT NOT NULL,             -- HMAC signing
  event_types JSONB NOT NULL DEFAULT '["*"]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  last_success_at TIMESTAMPTZ,
  consecutive_failures INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Refactor wa_instances: agregar organization_id
ALTER TABLE wa_instances
  ADD COLUMN organization_id UUID REFERENCES wa_organizations(id) ON DELETE CASCADE,
  ADD COLUMN created_by_user_id UUID REFERENCES wa_users(id);

-- Backfill: cada user_id existente → org sintética con su user como admin
-- (script en scripts/migrate-wa-users-to-orgs.ts; ver F-1 punto 4)

CREATE INDEX idx_wa_instances_org ON wa_instances(organization_id);

-- Seed roles builtin
INSERT INTO wa_roles (id, organization_id, name, is_builtin, permissions) VALUES
  (gen_random_uuid(), NULL, 'org_admin', true,
   '["*"]'::jsonb),
  (gen_random_uuid(), NULL, 'agent', true,
   '["messages:read","messages:send","contacts:read","contacts:create","canned:read"]'::jsonb),
  (gen_random_uuid(), NULL, 'viewer', true,
   '["messages:read","contacts:read","campaigns:read","analytics:read"]'::jsonb);

-- +goose Down
ALTER TABLE wa_instances
  DROP COLUMN created_by_user_id,
  DROP COLUMN organization_id;
DROP TABLE wa_outbound_webhooks;
DROP TABLE wa_usage_events;
DROP TABLE wa_audit_log;
DROP TABLE wa_api_keys;
DROP TABLE wa_user_organizations;
DROP TABLE wa_roles;
DROP TABLE wa_users;
DROP TABLE wa_organizations;
```

### 4.2 Parte 2 — Meta Cloud features (F1-F4)

```sql
-- 0NN_whatsapp_meta_cloud_support.sql
-- +goose Up

ALTER TABLE wa_instances
  ADD COLUMN provider TEXT NOT NULL DEFAULT 'baileys'
    CHECK (provider IN ('baileys', 'meta-cloud')),
  ADD COLUMN meta_phone_id TEXT,
  ADD COLUMN meta_business_id TEXT,
  ADD COLUMN meta_app_id TEXT,
  ADD COLUMN meta_api_version TEXT DEFAULT 'v21.0',
  ADD COLUMN meta_webhook_verify_token TEXT,
  ADD COLUMN meta_signup_mode TEXT DEFAULT 'manual'
    CHECK (meta_signup_mode IN ('manual','embedded_signup','byo_app')),
  ADD COLUMN meta_signup_session_id TEXT,
  ADD COLUMN meta_tier INT DEFAULT 1 CHECK (meta_tier IN (1,2,3,4));

-- Credenciales encriptadas con AES-256-GCM (no en texto plano)
-- wa_credentials.encrypted_jsonb ya existe; cifrar con KEK de KMS o env var

CREATE INDEX idx_wa_instances_provider ON wa_instances(provider);

-- Templates Meta-aprobados (whatomate parity)
CREATE TABLE wa_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES wa_instances(id) ON DELETE CASCADE,
  meta_template_id TEXT,           -- null hasta que Meta aprueba
  name TEXT NOT NULL,
  language TEXT NOT NULL,          -- 'es', 'en_US', etc.
  category TEXT NOT NULL CHECK (category IN ('UTILITY','MARKETING','AUTHENTICATION')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','PAUSED','DISABLED')),
  body_content TEXT NOT NULL,
  header_type TEXT,                -- 'TEXT'|'IMAGE'|'VIDEO'|'DOCUMENT'|null
  header_handle TEXT,              -- file handle de resumable upload
  buttons JSONB DEFAULT '[]'::jsonb,
  sample_values JSONB,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (instance_id, name, language)
);

-- Bulk campaigns (whatomate parity)
CREATE TABLE wa_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES wa_instances(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  template_id UUID REFERENCES wa_templates(id),
  status TEXT NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','QUEUED','PROCESSING','COMPLETED','FAILED','PAUSED','CANCELLED')),
  total_recipients INT DEFAULT 0,
  sent_count INT DEFAULT 0,
  delivered_count INT DEFAULT 0,
  read_count INT DEFAULT 0,
  failed_count INT DEFAULT 0,
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE wa_campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES wa_campaigns(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  recipient_name TEXT,
  template_params JSONB,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','sent','delivered','read','failed')),
  whatsapp_message_id TEXT,
  error_message TEXT,
  attempt_count INT DEFAULT 0,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wa_campaign_recipients_campaign ON wa_campaign_recipients(campaign_id);
CREATE INDEX idx_wa_campaign_recipients_status ON wa_campaign_recipients(status);

-- Canned responses (whatomate parity)
CREATE TABLE wa_canned_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  name TEXT NOT NULL,
  shortcut TEXT,                   -- "/saludo", "/cierre", etc.
  content TEXT NOT NULL,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  usage_count INT DEFAULT 0,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_canned_shortcut_per_tenant
  ON wa_canned_responses(tenant_id, shortcut)
  WHERE shortcut IS NOT NULL;

-- +goose Down
DROP TABLE wa_canned_responses;
DROP TABLE wa_campaign_recipients;
DROP TABLE wa_campaigns;
DROP TABLE wa_templates;
ALTER TABLE wa_instances
  DROP COLUMN meta_webhook_verify_token,
  DROP COLUMN meta_api_version,
  DROP COLUMN meta_app_id,
  DROP COLUMN meta_business_id,
  DROP COLUMN meta_phone_id,
  DROP COLUMN provider;
```

**Equivalente SQL Server:** generar con `sqlweb-mssql/pg2mssql.cjs` siguiendo regla CLAUDE.md.

---

## 5. Endpoints REST nuevos

Todos bajo `/api/whatsapp/` (existente). Auth por JWT del tenant.

### Provider config
- `POST /api/whatsapp/instances` — extender body con `provider: 'meta-cloud' | 'baileys'` y `metaConfig?: {...}` opcional.
- `POST /api/whatsapp/instances/:id/meta/verify` — ping a Meta para validar credenciales.
- `GET /api/whatsapp/webhooks/meta/:instanceId` — challenge verification (Meta GET).
- `POST /api/whatsapp/webhooks/meta/:instanceId` — receiver de mensajes/statuses Meta.

### Templates
- `GET    /api/whatsapp/templates?instanceId=&status=&category=&search=`
- `POST   /api/whatsapp/templates` — crear local + opcionalmente submit a Meta.
- `POST   /api/whatsapp/templates/:id/submit` — enviar a Meta para aprobación.
- `POST   /api/whatsapp/templates/:id/sync` — refrescar status desde Meta.
- `DELETE /api/whatsapp/templates/:id`

### Campaigns
- `GET    /api/whatsapp/campaigns?instanceId=&status=`
- `POST   /api/whatsapp/campaigns` — crear DRAFT con template_id + recipients (CSV upload o array).
- `POST   /api/whatsapp/campaigns/:id/start` — encola jobs a BullMQ.
- `POST   /api/whatsapp/campaigns/:id/pause`
- `POST   /api/whatsapp/campaigns/:id/cancel`
- `GET    /api/whatsapp/campaigns/:id/recipients?status=&page=`

### Canned responses
- `GET    /api/whatsapp/canned-responses?search=&active=`
- `POST   /api/whatsapp/canned-responses`
- `PATCH  /api/whatsapp/canned-responses/:id`
- `DELETE /api/whatsapp/canned-responses/:id`

---

## 6. Queue + Workers

**Stack:** BullMQ (Redis-backed). Ya hay Redis opcional para rate-limiting; lo hacemos requerido para producción Meta Cloud.

```
src/queue/
  index.ts                ← BullMQ Queue + Worker bootstrap
  campaigns.queue.ts      ← cola 'wa-campaigns', jobs por recipient
  campaigns.worker.ts     ← consumer que llama provider.sendTemplate()
```

**Job shape:**
```ts
type CampaignRecipientJob = {
  campaignId: string
  recipientId: string
  instanceId: string
  to: string
  templateName: string
  templateLang: string
  templateParams: Record<string, string>
}
```

**Retry policy** (no implementado en whatomate, lo agregamos):
- 3 reintentos con backoff exponencial (1m / 5m / 15m)
- Tras 3 fallos → status `failed`, error guardado en `wa_campaign_recipients.error_message`
- Errores 4xx de Meta (number not on WA, blocked) → marcar failed sin reintentar
- Errores 5xx / timeout → reintentar
- DLQ opcional en Redis para inspección manual

**Rate limiting Meta:**
- Tier 1 = 80 msg/s, Tier 2 = 200 msg/s, Tier 3 = 1000 msg/s, Tier 4 = unlimited
- Configuración por instancia: `meta_tier` con throttle BullMQ `limiter: { max, duration }`

**Worker scaling:**
- `WA_CAMPAIGN_WORKERS=4` env var → spawn N workers concurrentes
- En prod: separar API + workers en containers distintos (compose service `notify-worker`)

---

## 7. Webhook receiver Meta

```ts
// providers/meta-cloud/webhook-verify.ts
import crypto from 'node:crypto'

export function verifyMetaSignature(
  rawBody: Buffer,
  signatureHeader: string | undefined,
  appSecret: string,
): boolean {
  if (!signatureHeader?.startsWith('sha256=')) return false
  const expected = crypto
    .createHmac('sha256', appSecret)
    .update(rawBody)
    .digest('hex')
  const received = signatureHeader.slice('sha256='.length)
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(received, 'hex'),
  )
}
```

**Crítico:** Express debe usar `express.raw({ type: 'application/json' })` SOLO en la ruta del webhook, para tener `req.body` como Buffer y poder verificar la firma. El resto de la API sigue con `express.json()`.

**Eventos manejados:**
1. `messages` → guardar en `wa_messages`, dispatch a flow executor (igual que Baileys hoy).
2. `statuses` → actualizar `wa_messages.status` y `wa_campaign_recipients.{status, delivered_at, read_at}`.
3. `message_template_status_update` → actualizar `wa_templates.status` (APPROVED/REJECTED/PAUSED/DISABLED).

---

## 8. Visual Flow Builder (frontend)

**Librería:** `@xyflow/react` (versión moderna del legacy `reactflow`). Encaja con Next.js 16.

**Componente:**
```
dashboard/app/flows/editor/
  page.tsx                ← canvas con xyflow
  components/
    NodePalette.tsx       ← sidebar con tipos de nodo (Message, Condition, AI, HTTP, End)
    NodeMessage.tsx
    NodeCondition.tsx
    NodeAi.tsx            ← integra con chat-engine RAG
    NodeHttp.tsx
    PropertiesPanel.tsx   ← edición del nodo seleccionado
```

**Modelo de datos:** ya existe `flows` en notify (YAML). Agregar columna `flow_json JSONB` con shape compatible con xyflow:
```json
{ "nodes": [{"id":"1","type":"message","position":{"x":0,"y":0},"data":{"text":"Hola"}}],
  "edges": [{"id":"e1-2","source":"1","target":"2"}] }
```

Backwards-compat: el executor (`flow-executor.ts`) ya consume YAML. Agregar adapter `jsonToFlowYaml()` para que el JSON visual se convierta al formato YAML que el engine ya entiende. **Sin breaking changes.**

**Reusable cross-vertical:** este builder lo pueden usar los flows de hotel, medical, education, etc. Considerar extraerlo a `@zentto/flow-builder` package en el futuro.

---

## 9. Fases e implementación

**Replanificadas para producto SaaS comercial.** Las fases F-1, F-0.5, F8, F9, F10 son nuevas o reordenadas vs versión inicial (que asumía herramienta interna).

| Fase | Días | Branch | Bloqueante de | Sprint |
|---|---|---|---|---|
| **F-1** Multi-tenant foundation | 4 | `refactor/whatsapp-multitenant-foundation` | TODO | 1 |
| Tablas `wa_organizations`, `wa_users`, `wa_user_organizations`, `wa_roles`, `wa_api_keys`, `wa_audit_log`, `wa_usage_events`, `wa_outbound_webhooks`. Refactor `wa_instances.user_id` → `organization_id` + script de migración de datos. Middleware auth con scoping `organization_id` en todas las queries. RBAC enforcement. **Sin esto no se puede vender.** | | | | |
| **F-0.5** Crypto + audit | 1 | `feat/whatsapp-crypto-audit` | F1 | 1 |
| Cifrado AES-256-GCM de access tokens en `wa_credentials` (KEK por env var, rotable). Audit log middleware en endpoints sensibles. GDPR delete (`POST /api/organizations/:id/erase`). | | | | |
| **F0** Provider abstraction | 0.5 | `refactor/whatsapp-provider-interface` | F1 | 1 |
| Crear `providers/` + interface `WhatsAppProvider` + mover Baileys a `providers/baileys/`. Sin cambio funcional, tests existentes pasan. | | | | |
| **F1** Meta Cloud client (manual creds) | 3 | `feat/whatsapp-meta-cloud-client` | F2 F3 F8 | 2 |
| `providers/meta-cloud/{client,webhook-verify,media}.ts`. Endpoints webhook (challenge GET + POST con HMAC). Onboarding manual (cliente pega `phone_id`/`business_id`/`access_token`). Tests con vectores Meta conocidos. | | | | |
| **F2** Templates Meta-aprobados | 2 | `feat/whatsapp-templates` | F3 | 2 |
| `wa_templates` + endpoints CRUD + submit a Meta + sync status via webhook event `message_template_status_update`. | | | | |
| **F3** Bulk campaigns + BullMQ + usage metering | 5 | `feat/whatsapp-campaigns-bullmq` | F6 | 3 |
| `wa_campaigns` + `wa_campaign_recipients` + BullMQ queue + worker + **retry exponencial** (no en whatomate) + rate limiting per-tier + **emit `wa_usage_events` por mensaje enviado** (foundation de billing). 6 endpoints REST + 4 endpoints SDK. | | | | |
| **F4** Public API + SDK + outbound webhooks | 3 | `feat/whatsapp-public-api-sdk` | — | 3 |
| Auth por API key (header `Authorization: Bearer wak_live_xxx`) + rate limiter per-key. Outbound webhooks con HMAC + retry policy. Extender `packages/sdk/` con métodos `whatsapp.*`. OpenAPI spec. | | | | |
| **F5** Canned responses | 1.5 | `feat/whatsapp-canned-responses` | — | 4 |
| Tabla + 4 endpoints + UI dashboard. | | | | |
| **F6** Visual flow builder | 5 | `feat/whatsapp-flow-builder-xyflow` | — | 4-5 |
| Frontend `@xyflow/react` + JSON↔YAML adapter + nodos (Message, Condition, AI/RAG, HTTP, End) + `flow_json` column. Compat backwards: el engine sigue consumiendo YAML. | | | | |
| **F7** Dashboard pro multi-tenant | 4 | `feat/whatsapp-dashboard-multitenant` | — | 5 |
| `/whatsapp/templates`, `/whatsapp/campaigns`, `/whatsapp/canned-responses`, `/whatsapp/api-keys`, `/whatsapp/audit-log`, `/whatsapp/usage` con ZenttoDataGrid. Realtime status via WebSocket. Org switcher (multi-org users). | | | | |
| **F8** Embedded Signup Meta (BSP-like) | 5 | `feat/whatsapp-embedded-signup` | — | 6 |
| **Pre-requisito externo: Zentto verificada como Tech Provider en Meta** (proceso paralelo ~7-21 días). UI button "Connect WhatsApp" → popup OAuth Meta → callback con `phone_number_id`/`waba_id` → instancia auto-creada. Usa SDK Facebook JS o flow custom. Es lo que cierra el funnel de auto-onboarding Pro. | | | | |
| **F9** Billing + usage dashboard | 4 | `feat/whatsapp-billing-usage` | — | 6-7 |
| Aggregation `wa_usage_events` → reportes mensuales por org. Integración con Stripe/Paddle (revisar `project_paddle_notify.md` en memoria). Dashboard `/billing/usage` con gráficos. Email mensual. **Threshold alerts** (cliente excede 80% del plan). | | | | |
| **F10** White-label + custom domain | 3 | `feat/whatsapp-whitelabel` | — | 7 |
| `wa_organizations.branding_config` aplicado a dashboard (logo, colores, favicon). Subdominio `<org-slug>.notify.zentto.net` o dominio custom CNAME (con cert via Cloudflare for SaaS o Let's Encrypt). Email branding. | | | | |
| **F11** Docs + migration guide | 2 | `chore/whatsapp-docs` (`zentto-erp-docs`) | — | 7 |
| Docs cliente final, API reference (Stoplight/Redoc), migration guide Baileys→Meta, onboarding videos. | | | | |
| **Total** | **~43 días** senior dev | | | **~7 sprints** |

**Camino crítico mínimo viable comercial** (vender Pro): F-1 → F-0.5 → F0 → F1 → F2 → F3 → F4 → F7 + F8 ≈ **30.5 días**.

**Diferencia con plan v1 (21.5 días):** v1 omitía toda la layer comercial (multi-tenant real, API pública, embedded signup, billing, white-label). Para producto interno valdría 21.5 días; para SaaS vendible, mínimo 30.5 días MVP comercial.

---

## 10. Variables de entorno nuevas

```bash
# Provider Meta Cloud (default tier 1)
META_API_VERSION=v21.0                # versión Graph API
META_DEFAULT_TIER=1                   # 1|2|3|4 (rate limiting)

# Webhook
META_WEBHOOK_BASE_URL=https://api-notify.zentto.net   # callback URL pública

# Workers
WA_CAMPAIGN_WORKERS=4                 # concurrencia BullMQ
WA_CAMPAIGN_RETRY_BACKOFF=exponential # exponential|fixed
WA_CAMPAIGN_MAX_ATTEMPTS=3
```

Por tenant (en `wa_instances`):
- `meta_phone_id`, `meta_business_id`, `meta_app_id` (no sensibles, plain text).
- `meta_webhook_verify_token` (random per instance, plain text).
- En `wa_credentials.encrypted_jsonb`: `access_token`, `app_secret`.

---

## 11. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Meta rechaza app por verificación | Media | Bloquea Pro/Enterprise | Iniciar verificación Meta Business **ya** (proceso paralelo, ~7-14 días) |
| Costo por mensaje Meta excede free tier rápido | Media | Margen reducido | Trasladar costo a cliente Pro/Ent en pricing |
| Templates rechazados por Meta | Alta | Retraso onboarding cliente | Plantillas pre-aprobadas para casos comunes (saludo, OTP, recordatorio cita) — crear 10 templates "starter pack" |
| BullMQ requiere Redis siempre on | Baja | Caída de notify si Redis falla | Health check + fallback a queue en PG (`graphile-worker`) — fuera de scope F3, evaluar después |
| Migración clientes Baileys → Meta sin downtime | Media | Riesgo SLA | Doble provider activo durante 1 semana por cliente; flag `migrated_to_meta_at` para corte |
| Webhook signature mal implementada → mensajes fake aceptados | Baja | Crítico (security) | Tests obligatorios con vectores conocidos antes de F1 merge; review por PO |

---

## 12. Decisiones pendientes (PO)

1. **Tiers + pricing Pro/Enterprise** — ¿precio definido o se ajusta? Cuántos mensajes/mes incluidos por tier.
2. **Verificación Meta Tech Provider** — ¿quién gestiona ante Meta Business? Es bloqueante de F8 (paralelo, no del MVP).
3. **Stripe vs Paddle** para billing — verificar `project_paddle_notify.md` en memoria.
4. **Webhook domain** — `wa.zentto.net`, `api.notify.zentto.net/webhooks/wa` o subdominio por org.
5. **Branding default** — ¿usamos branding Zentto en Free, o mostramos "Powered by Zentto" tipo Vercel?
6. **Multi-region desde el día 1?** — `data_residency` está en schema; ¿deploy real EU/US/LATAM en F-1 o se difiere?

---

## 13. Decisiones tomadas

- **zentto-notify es producto SaaS comercial multi-tenant**, no herramienta interna.
- **Provider primario** = Meta Cloud para Pro/Enterprise. Baileys = Free / dev / Starter BYO.
- **App ID Meta** = arquitectura híbrida BSP-like:
  - Embedded Signup con App ID Zentto (Tech Provider) para self-service Pro/Ent.
  - BYO App ID para Enterprise regulados.
  - Descartada: App compartida única (riesgo sistémico).
- **Stack Node** = no migramos a Go; portamos features de whatomate al stack actual.
- **Visual flow builder** = `@xyflow/react` (no Vue Flow, encaja con Next.js).
- **Queue** = BullMQ (no goroutines, no canales Go).
- **Multi-tenant** = `organization_id` no `user_id`; users pueden pertenecer a N orgs (partners/agencias).
- **Auth API** = API keys con scopes + rate limit per-key (no solo dashboard).
- **Compliance** = AES-256-GCM credenciales, audit log, GDPR delete, data_residency selectable.
- **Fuente de verdad whatomate** = clonado en `D:\DatqBoxWorkspace\_references\whatomate` (commit hash referenciado en cada PR de implementación).
- **NO copiamos** = IVR voice, custom JS executor, SLA tracking, single-binary deployment.

---

## 16. Producto SaaS — checklist commercialization

Ítems necesarios para que zentto-notify sea **comercializable de verdad**, no solo "técnicamente multi-tenant":

| Categoría | Ítem | Fase | Bloqueante de venta |
|---|---|---|---|
| **Tenancy** | Organizations + RBAC | F-1 | Sí |
| **Tenancy** | Multi-org users (un user en N orgs) | F-1 | Para partners/agencias |
| **Auth** | API keys con scopes | F4 | Sí (Pro+) |
| **Auth** | SSO (SAML/OIDC) | Post-MVP | Solo Enterprise |
| **Onboarding** | Manual (paste credentials) | F1 | MVP Starter |
| **Onboarding** | Embedded Signup Meta | F8 | MVP Pro escalable |
| **Billing** | Usage metering events | F3 | Sí |
| **Billing** | Stripe/Paddle integration | F9 | Sí |
| **Billing** | Threshold alerts | F9 | Sí |
| **Billing** | Invoice generation | F9 | Sí |
| **Compliance** | AES-256-GCM credenciales | F-0.5 | Sí (legal) |
| **Compliance** | Audit log inmutable | F-0.5 | Enterprise |
| **Compliance** | GDPR delete API | F-0.5 | Sí (UE) |
| **Compliance** | Data residency selection | F-1 (schema), Post-MVP (deploy) | Enterprise |
| **Compliance** | DPA template + Terms of Service | Legal task, paralelo | Sí |
| **Compliance** | SOC2 / ISO27001 | Año 2 | Solo Enterprise grandes |
| **Branding** | White-label dashboard | F10 | Pro+ premium |
| **Branding** | Custom domain CNAME | F10 | Enterprise |
| **API** | Public REST API + OpenAPI spec | F4 | Sí |
| **API** | SDK npm `@zentto/notify-client` | F4 | Sí |
| **API** | Webhooks salientes con HMAC + retry | F4 | Sí |
| **Observabilidad** | Metrics dashboard per-tenant | F7 | Sí |
| **Observabilidad** | Status page público (statuspage.io) | Post-MVP | Sí |
| **Observabilidad** | Alerting + on-call (Grafana, PagerDuty) | Post-MVP infra | Pro+ |
| **Soporte** | Audit log + impersonation segura | F-0.5 + F7 | Sí |
| **Soporte** | In-app chat support | Post-MVP (usar nuestro propio widget!) | Pro+ |
| **Marketing** | Landing comercial `notify.zentto.net` | Post-MVP, equipo marketing | Sí |
| **Marketing** | Documentación pública | F11 | Sí |
| **Marketing** | Free trial sin tarjeta | F9 funnel | Sí |
| **Confianza** | Trust center (security.txt, certs, etc.) | Post-MVP | Enterprise |
| **Confianza** | Reference customers / case studies | Año 2 | Enterprise grandes |

---

## 14. Referencias whatomate (paths exactos)

| Componente | Path en whatomate (Go) |
|---|---|
| Cliente HTTP Meta | `pkg/whatsapp/client.go` |
| Envío de mensajes | `pkg/whatsapp/message.go` |
| Templates | `pkg/whatsapp/template.go` |
| Webhook + HMAC verify | `internal/handlers/webhook.go:599-616` |
| Modelo Account | `pkg/whatsapp/types.go:9-16` |
| Modelo WhatsAppAccount | `internal/models/models.go:293-335` |
| Queue interface | `internal/queue/queue.go:30-55` |
| Worker | `internal/worker/worker.go:21-296` |
| Modelo BulkCampaign | `internal/models/bulk.go:9-89` |
| Modelo Template | `internal/models/models.go:~425` |
| Modelo CannedResponse | `internal/models/canned_responses.go:7-26` |
| Modelo Organization/RBAC | `internal/models/models.go:89-104` |
| FlowBuilder Vue | `frontend/src/components/flow-builder/FlowBuilder.vue` |
| @vue-flow/core (lib) | `frontend/package.json` |

---

## 15. Próximo paso

Modo automático autorizado por PO. Arrancar **F-1 (multi-tenant foundation)** en branch `refactor/whatsapp-multitenant-foundation` del repo `zentto-notify`. PR a `developer` cuando F-1 cierre.

Orden de ejecución:
1. Push branch actual (DatqBoxWeb) con doc actualizado + abrir PR a `developer`.
2. Crear branch en `zentto-notify` desde `developer` para F-1.
3. Implementar F-1 (4 días estimados): migración goose multi-tenant + middleware auth/RBAC + script de migración de datos existentes.
4. Smoke test en `apidev.zentto.net` → merge a `developer` → continuar F-0.5.

Trámites paralelos no-código que el PO debe arrancar YA porque tienen lead time:
- Registro Zentto como Tech Provider en Meta Business Manager (~7-21 días).
- Acuerdo Stripe o Paddle.
- DPA + ToS legal (abogado).
- Definición final de tiers + pricing.
