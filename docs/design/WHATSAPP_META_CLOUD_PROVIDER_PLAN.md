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

Tenant elige al crear instancia. Default por plan:

| Plan | Default | Permite cambiar |
|---|---|---|
| Free | `baileys` | No |
| Pro | `meta-cloud` | Sí (puede usar Baileys para dev) |
| Enterprise | `meta-cloud` | Sí (puede tener mixto) |

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
  ADD COLUMN meta_webhook_verify_token TEXT;

-- credenciales sensibles van encriptadas en wa_credentials (ya existe la tabla)
-- columnas en wa_credentials: access_token, app_secret (encrypted_jsonb)

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

| Fase | Días | Branch | PR | Bloqueante de |
|---|---|---|---|---|
| **F0** | 0.5 | `feat/whatsapp-meta-cloud-provider` | en notify | F1 |
| Crear estructura `providers/` + `WhatsAppProvider` interface + mover Baileys actual a `providers/baileys/` (refactor sin cambio funcional). Tests existentes deben seguir pasando. | | | | |
| **F1** | 3 | `feat/whatsapp-meta-cloud-client` | notify | F2 F3 |
| `providers/meta-cloud/client.ts` + `webhook-verify.ts` + `media.ts`. Endpoints `POST /api/whatsapp/webhooks/meta/:id` + GET challenge. Migración goose con extensión `wa_instances`. Tests de envío text/media + verificación firma. | | | | |
| **F2** | 2 | `feat/whatsapp-templates` | notify | F4 |
| `providers/meta-cloud/templates.ts` + tabla `wa_templates` + 5 endpoints REST + sync via webhook event. | | | | |
| **F3** | 4 | `feat/whatsapp-campaigns-bullmq` | notify | F5 |
| `wa_campaigns` + `wa_campaign_recipients` tables + BullMQ queue + worker + retry policy + rate limiting + 6 endpoints REST. | | | | |
| **F4** | 2 | `feat/whatsapp-canned-responses` | notify | — |
| Tabla + 4 endpoints + UI dashboard (CRUD simple con ZenttoDataGrid). | | | | |
| **F5** | 5 | `feat/whatsapp-flow-builder-xyflow` | notify | — |
| Frontend xyflow + JSON↔YAML adapter + UI nodos + `flow_json` column. | | | | |
| **F6** | 3 | `feat/whatsapp-dashboard-pro` | notify | — |
| Dashboard `/whatsapp/templates` + `/whatsapp/campaigns` + `/whatsapp/canned-responses` con ZenttoDataGrid. Realtime status via WebSocket o polling. | | | | |
| **F7** | 2 | `chore/whatsapp-docs-and-migration` | notify + zentto-erp-docs | — |
| Doc usuario final + migration guide para clientes Pro que pasan de Baileys a Meta. | | | | |
| **Total** | **~21.5 días** | | | |

**Diferencia con estimación inicial (24-32 días):** acoté scope eliminando IVR, custom JS, SLA tracking. Esfuerzo real concentrado en F1+F3+F5.

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

1. **Plan pricing Pro/Enterprise** — ¿ya hay precio definido para Meta Cloud o se ajusta?
2. **Quién hace verificación Meta Business** — ¿yo gestiono, o Raúl con la cuenta legal de Zentto?
3. **¿Implementamos F4 (canned responses) y F5 (flow builder) en este sprint o se difieren?** — Se pueden vender Pro sin ellos si urge.
4. **App ID Meta** — ¿una App ID compartida para todos los tenants (con system user token), o una App por tenant grande?
5. **Webhook URL** — ¿dominio nuevo `wa-webhook.zentto.net` o reusa `api-notify.zentto.net`?

---

## 13. Decisiones tomadas

- **Provider primario** = Meta Cloud para Pro/Enterprise. Baileys = secundario / Free.
- **Stack Node** = no migramos a Go; portamos features de whatomate al stack actual.
- **Visual flow builder** = `@xyflow/react` (no Vue Flow, encaja con Next.js).
- **Queue** = BullMQ (no goroutines, no canales Go).
- **Fuente de verdad whatomate** = clonado en `D:\DatqBoxWorkspace\_references\whatomate` (commit hash referenciado en cada PR de implementación).
- **NO copiamos** = IVR voice, custom JS executor, SLA tracking, single-binary deployment.

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

Aprobación PO de este doc → arrancar **F0 (refactor sin cambio funcional)** en branch `feat/whatsapp-meta-cloud-provider` del repo `zentto-notify`. PR a `developer`.
