# 15 — Event bus del ecosistema Zentto

**Status:** Design 2026-04-15 — infraestructura Kafka ya corre (zentto-obs); falta estandarizar convention de topics + adopción por apps.

## 1. Por qué event bus

Hasta hoy, cuando algo ocurre en una app (ej. una reserva confirmada en hotel), si otra app necesita enterarse (ej. CRM del tenant para crear una actividad, o notify para mandar email al huésped), se resuelve con llamadas HTTP directas vertical→vertical. Resultado: acoplamiento N×M, retries duplicados, y **los tenants clientes no pueden consumir eventos propios** sin un hook custom por caso.

Un event bus publica eventos de negocio a Kafka con un topic name estándar; cualquier consumer (interno o un webhook de un tenant cliente) se suscribe.

## 2. Convención de topics

```
zentto.<tenant>.<domain>.<event>
```

| Segmento | Ejemplos | Notas |
|---|---|---|
| `tenant` | `master`, `zentto`, `acme`, `syswin` | `CompanyCode` del tenant propietario. Para eventos globales del master tenant: `master`. |
| `domain` | `crm`, `hotel`, `medical`, `tickets`, `billing`, `fiscal`, `auth` | Módulo/app de origen. |
| `event` | `lead.created`, `lead.won`, `reservation.confirmed`, `invoice.paid` | `entidad.accion` en camelCase. Pasado simple. |

Ejemplos reales:

- `zentto.zentto.crm.lead.created`
- `zentto.acme.hotel.reservation.confirmed`
- `zentto.syswin.billing.invoice.paid`

**Wildcards para consumers**: Kafka no soporta nativamente, pero se puede suscribir con regex via `consumer.subscribe({ topic: /zentto\.acme\..+/ })` si se necesita un consumer por-tenant que escuche todos sus eventos.

## 3. Shape del mensaje

```json
{
  "eventId": "evt_<uuid>",
  "eventType": "crm.lead.created",
  "tenantId": 4,
  "tenantCode": "ZENTTO",
  "timestamp": "2026-04-15T20:00:00Z",
  "source": "zentto-web-api",
  "correlationId": "req-abc-123",
  "data": {
    "leadId": 123,
    "email": "...",
    "topic": "demo",
    "companyId": 4
  },
  "version": 1
}
```

- `eventId`: UUID único — idempotencia a nivel consumer.
- `tenantId` + `tenantCode`: identifican el tenant propietario — base para routing y para que el webhook del tenant reciba solo los suyos.
- `source`: app origen (para debugging).
- `correlationId`: propagado desde el request HTTP si viene → trazabilidad cross-system.
- `version`: si el shape de `data` cambia, bump.

## 4. Quién publica qué (seed list)

| Domain | Events | App emisora |
|---|---|---|
| `crm` | `lead.created`, `lead.won`, `lead.lost`, `lead.stage_changed`, `activity.overdue` | zentto-web |
| `hotel` | `reservation.confirmed`, `reservation.cancelled`, `checkin.completed`, `checkout.completed` | zentto-hotel |
| `medical` | `appointment.scheduled`, `appointment.completed`, `prescription.issued` | zentto-medical |
| `tickets` | `order.confirmed`, `ticket.issued`, `ticket.scanned` | zentto-tickets |
| `rental` | `booking.confirmed`, `return.completed`, `fine.issued` | zentto-rental |
| `billing` | `invoice.issued`, `invoice.paid`, `payment.received` | zentto-web (AR/AP) |
| `auth` | `user.registered`, `tenant.provisioned` | zentto-auth |
| `notify` | `email.sent`, `email.bounced`, `otp.verified` | zentto-notify |

## 5. Webhooks por-tenant

El tenant registra un webhook URL con un filtro de topics. El zentto-web-api corre un **webhook router** consumer que:

1. Escucha todos los topics.
2. Filtra por `tenantCode`.
3. Resuelve los webhooks registrados para ese tenant + topic.
4. POST al URL del webhook con HMAC signature (cabecera `X-Zentto-Signature`).
5. Reintentos con backoff exponencial + dead-letter queue.

Tabla `cfg.TenantWebhook`:

```sql
CREATE TABLE cfg."TenantWebhook" (
  "WebhookId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId" INTEGER NOT NULL REFERENCES cfg."Company"("CompanyId"),
  "Url" VARCHAR(500) NOT NULL,
  "SecretHash" VARCHAR(64) NOT NULL, -- HMAC para firmar payload
  "EventFilter" VARCHAR(500),        -- CSV: "crm.lead.*,hotel.reservation.*"
  "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
  "LastDeliveredAt" TIMESTAMP,
  "FailureCount" INTEGER NOT NULL DEFAULT 0,
  "CreatedAt" TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC')
);
```

Admin CRUD en `/api/v1/crm/webhooks` (similar a `/public-keys`).

## 6. SDK — submódulo `events` (próxima versión 0.3.0)

```ts
import { events } from "@zentto/platform-client";

const bus = events.eventsFromEnv();

// Publicar (producer)
await bus.publish({
  eventType: "crm.lead.created",
  tenantCode: "ZENTTO",
  data: { leadId: 123, email: "x@x.com" },
});

// Consumir (registra listeners)
bus.on("crm.lead.created", async (evt) => {
  await doSomething(evt.data);
});
await bus.start(); // abre conexión kafka
```

Internamente wrappea kafkajs con:
- topicName = `zentto.${tenantCode.toLowerCase()}.${eventType}`.
- Producer con acks=all, idempotent=true.
- Consumer group auto-gen (`zentto-<service>-<hostname>`) con retry + DLQ.
- Envelope automático (eventId, timestamp, source, correlationId).

## 7. Roadmap de implementación

- [x] Kafka infraestructura (zentto-obs) — corre en prod.
- [x] Consumer existente (`kafka-notification-consumer.ts`) → queda como referencia.
- [ ] **Submódulo SDK `events`** (v0.3.0 de platform-client).
- [ ] Tabla `cfg.TenantWebhook` + CRUD admin.
- [ ] Webhook router consumer (dentro de zentto-web o microservicio aparte).
- [ ] Adopción por apps emisoras (1 PR cada una): publicar evento en vez de, o además de, mandar mail directo.
- [ ] Dashboard en el CRM del tenant: listar sus webhooks, ver deliveries, reintentos, DLQ.

## 8. Reglas críticas

- **Nombres de topics**: seguir `zentto.<tenant>.<domain>.<event>` sin excepciones. Si un topic no matchea, el router de webhooks no lo enruta correctamente.
- **Shape**: envelope siempre con `eventId`, `tenantCode`, `timestamp`. Cambios en `data` → bump `version`.
- **No eventos sincrónicos bloqueantes**: `publish` es fire-and-forget. Si una operación de negocio depende de un side-effect cross-service, usar HTTP + platform-client — no el bus.
- **Idempotencia en consumers**: el mismo evento puede entregarse >1 vez. Consumers deben deduplicar por `eventId` (tabla de seen events, TTL 24h).
