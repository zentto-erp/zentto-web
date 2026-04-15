# @zentto/platform-client

Cliente oficial tipado para los servicios de plataforma Zentto: **notify**, **auth**, **cache**, **landing**, **events**.

Incluye circuit breaker, auto-refresh de JWT, errores tipados (AuthError, RateLimitedError, ServiceError, etc.) y event bus sobre Kafka.

Úsalo desde el ERP, cualquier vertical (hotel, medical, tickets, rental, education, inmobiliario…) o un sitio externo de un tenant cliente.

## Instalación

```bash
npm install @zentto/platform-client
```

## Uso rápido

### Server-to-server (ERP API, vertical, backoffice)

```ts
import { notify } from "@zentto/platform-client";

const n = notify.notifyFromEnv();

// Email con template centralizado en notify.zentto.net
await n.email.sendTemplate("lead-confirmacion", {
  to: "lead@acme.com",
  variables: { firstName: "Juan", topicLabel: "Demo" },
});

// Contactos (CRM notify para campañas/unsubscribe/tracking)
await n.contacts.upsert({ email, name, phone, tags: ["hotel", "booking"] });

// OTP por email o SMS
await n.otp.send({ channel: "email", destination: email });
```

Variables de entorno:

| Var | Default | Notas |
|---|---|---|
| `NOTIFY_API_URL` | `https://notify.zentto.net` | Endpoint del servicio |
| `NOTIFY_API_KEY` | — | Master key del servicio (server-to-server) |
| `API_MASTER_KEY` | — | Fallback legacy |

### Auth (zentto-auth)

```ts
import { authFromEnv, AuthClient } from "@zentto/platform-client/auth";

// Service-to-service (backend) — provisioning de owners desde el ERP
const svc = authFromEnv(); // lee AUTH_SERVICE_URL + AUTH_SERVICE_KEY
await svc.admin.provisionOwner({
  email, fullName, companyId, companyCode, sendMagicLink: true,
});

// User-facing (con JWT del usuario)
const user = new AuthClient({ accessToken: jwt });
const me = await user.me();
```

### Cache (zentto-cache)

```ts
import { cacheFromEnv } from "@zentto/platform-client/cache";
const c = cacheFromEnv(); // lee CACHE_URL + CACHE_APP_KEY

await c.gridLayouts.put("invoices-list", layoutJson, { companyId, userId });
const res = await c.gridLayouts.get("invoices-list", { companyId, userId });
// res.data.layout → layout guardado
```

### Events (bus Kafka)

Requiere `kafkajs` como peer dependency (opcional):

```bash
npm install kafkajs
```

```ts
import { EventBusClient } from "@zentto/platform-client/events";

const bus = new EventBusClient({
  brokers: ["kafka:9092"],
  source: "zentto-hotel",
  tenantCode: "ACME",
});

await bus.connect();

// Producer
await bus.publish({
  eventType: "hotel.reservation.confirmed",
  data: { reservationId: 42, guest: "Juan" },
  correlationId: req.headers["x-request-id"],
});

// Consumer (otro proceso)
bus.on(/^crm\..+/, async (evt) => {
  console.log("got", evt.eventType, evt.data);
});
await bus.start();
```

Topic: `zentto.acme.hotel.reservation.confirmed`. Envelope estándar con `eventId` (dedup automática), `timestamp`, `source`, `correlationId`, `version`.

### Errores tipados

```ts
import { AuthError, RateLimitedError, ServiceError } from "@zentto/platform-client";

const r = await notify.email.send(...);
if (!r.ok && r.errorInstance instanceof RateLimitedError) {
  await wait(r.errorInstance.retryAfterSec ?? 30);
}
```

### Landing (leads de tenants clientes)

```ts
import { LandingClient } from "@zentto/platform-client/landing";
const landing = new LandingClient({ tenantKey: "zk_<prefix>_<secret>" });

await landing.registerLead({
  email, name, phone, topic: "sales", message, source: "acme.com",
});
// Cae en el crm.Lead del tenant dueño de la key.
```

### Construcción manual

```ts
import { notify } from "@zentto/platform-client";

const n = new notify.NotifyClient({
  baseUrl: "https://notify-dev.zentto.net",
  apiKey: process.env.NOTIFY_DEV_KEY!,
  timeoutMs: 5000,
  retries: 2,
  onError: (err, ctx) => logger.error({ err, ctx }, "[notify] failed"),
});
```

## Principios

1. **Best-effort**: los métodos de negocio nunca tumban el flujo de negocio. Retornan `{ ok: false, error }` cuando algo falla.
2. **Retries con backoff exponencial** en errores de red o 5xx; sin retry en 4xx.
3. **Typed**: todos los inputs/outputs tienen interfaces exportadas.
4. **Sin dependencias externas**: usa `fetch` nativo de Node 20+ / navegadores modernos.

## Documentación extendida

Arquitectura, matriz de auth por contexto y guía de adopción:

- `docs/wiki/14-integracion-ecosistema.md` en [zentto-erp/zentto-web](https://github.com/zentto-erp/zentto-web).

## Licencia

MIT © Zentto ERP
