# @zentto/platform-client

SDK unificado y tipado para los servicios de plataforma Zentto. Agrupa en un solo paquete los clientes para: notificaciones, autenticacion, cache, landing, event bus (Kafka) y verificacion de webhooks.

Uso oficial en el ERP, aplicaciones verticales (hotel, rental, medical, education, inmobiliario) y sitios de tenants clientes.

- Version: `0.5.0`
- Node.js: `>=20`
- Tipo de modulo: ESM
- Dependencia opcional: `kafkajs` (requerida solo si se usa el submodulo `/events`)

## Instalacion

```bash
npm install @zentto/platform-client
```

Para habilitar el submodulo de eventos (Kafka):

```bash
npm install @zentto/platform-client kafkajs
```

## Submodulos

Cada servicio de plataforma tiene su propio subpath de import. Se pueden importar individualmente o a traves del barrel principal.

| Submodulo | Import path | Descripcion |
|-----------|-------------|-------------|
| `notify` | `@zentto/platform-client/notify` | Emails, OTP, push web, SMS, WhatsApp via `notify.zentto.net` |
| `auth` | `@zentto/platform-client/auth` | Login, refresh, logout, me, provision de tenants via `auth.zentto.net` |
| `cache` | `@zentto/platform-client/cache` | Grid layouts, templates, schemas, blog posts via `cache.zentto.net` |
| `landing` | `@zentto/platform-client/landing` | Registro de leads desde sitios externos de tenants |
| `events` | `@zentto/platform-client/events` | Producer + consumer de eventos sobre Kafka (requiere `kafkajs`) |
| `webhooks` | `@zentto/platform-client/webhooks` | Verificacion HMAC-SHA256 de webhooks firmados por Zentto |

## Uso basico

### Importar todo desde el barrel

```typescript
import { notify, auth, cache } from '@zentto/platform-client';

const notifier    = new notify.NotifyClient({ apiKey: process.env.NOTIFY_API_KEY });
const authClient  = new auth.AuthClient({ accessToken: token });
const cacheClient = new cache.CacheClient({ clientKey: process.env.CACHE_APP_KEY });
```

### Importar submodulos directamente (tree-shaking optimo)

```typescript
import { NotifyClient, notifyFromEnv } from '@zentto/platform-client/notify';
import { AuthClient, authFromEnv }     from '@zentto/platform-client/auth';
import { EventBusClient, eventsFromEnv } from '@zentto/platform-client/events';
```

### Factory desde variables de entorno

Cada submodulo expone una funcion `*FromEnv` que construye el cliente desde variables de entorno estandar:

```typescript
import { notifyFromEnv }  from '@zentto/platform-client/notify';
import { authFromEnv }    from '@zentto/platform-client/auth';
import { cacheFromEnv }   from '@zentto/platform-client/cache';
import { landingFromEnv } from '@zentto/platform-client/landing';
import { eventsFromEnv }  from '@zentto/platform-client/events';

const notify  = notifyFromEnv();   // NOTIFY_API_URL + NOTIFY_API_KEY
const auth    = authFromEnv();     // AUTH_SERVICE_URL + AUTH_SERVICE_KEY
const cache   = cacheFromEnv();    // CACHE_URL + CACHE_APP_KEY
const landing = landingFromEnv();  // ZENTTO_API_URL + ZENTTO_TENANT_KEY
const events  = eventsFromEnv();   // KAFKA_BROKERS + ZENTTO_SERVICE_NAME + ZENTTO_TENANT_CODE
```

## API por submodulo

### notify

Cliente para `https://notify.zentto.net`. Patron best-effort: los metodos de negocio nunca lanzan excepcion, retornan `{ ok, error }`.

**`new NotifyClient(cfg: NotifyConfig)`**

| Opcion | Tipo | Requerida | Descripcion |
|--------|------|-----------|-------------|
| `apiKey` | `string` | Si | Clave de API del tenant |
| `baseUrl` | `string` | No | Default `https://notify.zentto.net` |
| `timeoutMs` | `number` | No | Timeout por request. Default `10000` ms |
| `retries` | `number` | No | Reintentos ante fallos de red o 5xx. Default `1` |
| `onError` | `function` | No | Hook para logs y observability |

```typescript
const notify = new NotifyClient({ apiKey: process.env.NOTIFY_API_KEY });

// Email
await notify.email.send({ to: 'user@empresa.com', subject: 'Bienvenido', html: '<p>...</p>' });
await notify.email.sendTemplate('bienvenida-trial', {
  to: 'user@empresa.com',
  variables: { nombre: 'Juan', plan: 'Pro' },
});
await notify.email.sendQueued({
  to: 'user@empresa.com',
  templateId: 'factura-mensual',
  scheduledAt: '2026-05-01T08:00:00Z',
});

// OTP
await notify.otp.send({ channel: 'email', destination: 'user@empresa.com', brandName: 'Zentto' });
await notify.otp.verify({ channel: 'email', destination: 'user@empresa.com', code: '123456' });

// Push web
await notify.push.send({
  subscription: { endpoint: '...', keys: { p256dh: '...', auth: '...' } },
  title: 'Nueva factura',
  body: 'Tienes una factura pendiente',
  url: 'https://app.zentto.net/facturas',
});

// SMS
await notify.sms.send({ to: '+58 412 0000000', carrier: 'movistar', message: 'Tu codigo es 123456' });

// WhatsApp
await notify.whatsapp.send('instancia-01', {
  to: '+58 412 0000000',
  message: 'Hola desde Zentto',
  media: { url: 'https://...', caption: 'Adjunto' },
});

// Contactos CRM
await notify.contacts.upsert({
  email: 'lead@empresa.com',
  name: 'Maria Lopez',
  tags: ['trial', 'landing'],
  subscribed: true,
});

// Health check
const health = await notify.health(); // { ok: boolean, latencyMs?: number }
```

---

### auth

Cliente para `https://auth.zentto.net`. Dos modos: user-facing (cookies HttpOnly + Bearer JWT) y service-to-service (header `x-service-key`).

**`new AuthClient(opts: AuthConfig)`**

| Opcion | Tipo | Requerida | Descripcion |
|--------|------|-----------|-------------|
| `baseUrl` | `string` | No | Default `https://auth.zentto.net` |
| `accessToken` | `string` | No | Bearer JWT para llamadas user-facing |
| `serviceKey` | `string` | No | Service key para operaciones admin (provisioning) |
| `timeoutMs` | `number` | No | Default `10000` ms |
| `retries` | `number` | No | Default `1` |
| `meCacheTtlMs` | `number` | No | TTL cache de `me()`. Default `15000` ms. Pasar `0` para desactivar |

```typescript
// User-facing
const authClient = new AuthClient({ accessToken: jwtToken });

// Login (retorna datos del usuario o MfaChallenge si MFA esta habilitado)
const res = await authClient.login({ username, password, appId: 'zentto-erp' });
if (res.ok && res.data?.mfaChallengeToken) {
  await authClient.loginMfa({
    mfaChallengeToken: res.data.mfaChallengeToken,
    mfaToken: '123456',
  });
}

// Obtener usuario autenticado (cachea 15s por defecto)
const me = await authClient.me('zentto-erp');
if (me.ok) console.log(me.data?.user, me.data?.permisos);

// Registro
await authClient.registerForApp({
  email: 'user@empresa.com',
  password: '...',
  appId: 'zentto-hotel',
  role: 'owner',
});

// Consumo de magic-link (publico, no requiere auth)
await authClient.setPassword({ token: magicLinkToken, newPassword: 'nueva123' });

// Refresh + logout
await authClient.refresh();
await authClient.logout();

// Invalidar cache de me() tras cambios de permisos
authClient.invalidateMeCache();
```

**Operaciones admin (service-to-service):**

```typescript
const adminAuth = authFromEnv(); // lee AUTH_SERVICE_URL + AUTH_SERVICE_KEY

// Provisionar owner de un nuevo tenant
const provision = await adminAuth.admin.provisionOwner({
  email: 'owner@empresa.com',
  fullName: 'Carlos Mendez',
  companyId: 42,
  companyCode: 'EMPRESA42',
  tenantSubdomain: 'empresa42',
  role: 'owner',
  sendMagicLink: true,
});
// provision.data?.magicLinkUrl disponible si sendMagicLink = true

// Crear magic-link manualmente
const link = await adminAuth.admin.createMagicLink({
  email: 'user@empresa.com',
  companyId: 42,
  purpose: 'reset_password',
  ttlMinutes: 60,
});
```

---

### cache

Cliente para `https://cache.zentto.net`. Almacena y recupera artefactos por tenant/usuario: layouts de grillas, templates de reportes, schemas de studio y posts de blog.

**`new CacheClient(opts: CacheConfig)`**

| Opcion | Tipo | Requerida | Descripcion |
|--------|------|-----------|-------------|
| `clientKey` | `string` | Si | Header `x-client-key` — identifica la app consumidora |
| `baseUrl` | `string` | No | Default `https://cache.zentto.net` |

**Recursos disponibles:** `gridLayouts`, `reportTemplates`, `studioSchemas`, `blogPosts`.

Todos los recursos exponen los mismos cuatro metodos: `list`, `get`, `put`, `delete`.

```typescript
const cache    = cacheFromEnv();
const identity = { companyId: 42, userId: 7 };

// Listar IDs guardados
const list = await cache.gridLayouts.list(identity);

// Leer un item
const item = await cache.gridLayouts.get('facturas-grid', identity);
// item.data?.layout contiene el valor guardado

// Guardar o actualizar
await cache.gridLayouts.put('facturas-grid', { columns: [...], filters: [...] }, identity);

// Eliminar
await cache.gridLayouts.delete('facturas-grid', identity);
```

El mismo patron aplica para `reportTemplates`, `studioSchemas` y `blogPosts`.

---

### landing

Cliente para registrar leads desde sitios externos de tenants clientes. Resuelve el tenant destino via el header `X-Tenant-Key`.

**`new LandingClient(opts: LandingConfig)`**

| Opcion | Tipo | Requerida | Descripcion |
|--------|------|-----------|-------------|
| `tenantKey` | `string` | No | PublicApiKey emitida desde el CRM del tenant |
| `baseUrl` | `string` | No | Default `https://api.zentto.net` |

```typescript
const landing = new LandingClient({ tenantKey: 'pk_empresa42_xxx' });

const result = await landing.registerLead({
  email: 'contacto@prospecto.com',
  name: 'Ana Torres',
  company: 'Prospecto SRL',
  country: 'VE',
  phone: '+58 212 0000000',
  source: 'landing-home',
  message: 'Quiero mas informacion sobre el plan Pro',
});
// result.data?.ok === true si el lead fue registrado
```

---

### events

Producer + consumer de eventos sobre Kafka. Requiere `kafkajs` instalado como dependencia en el proyecto consumidor.

**`new EventBusClient(cfg: EventBusConfig)`**

| Opcion | Tipo | Requerida | Descripcion |
|--------|------|-----------|-------------|
| `brokers` | `string[]` | Si | Brokers Kafka (ej. `['kafka:9092']`) |
| `source` | `string` | Si | Nombre del servicio emisor (ej. `'zentto-hotel'`) |
| `tenantCode` | `string` | Si | TenantCode por defecto para publicar eventos |
| `clientId` | `string` | No | Default `zentto-{source}-{pid}` |
| `groupId` | `string` | No | Default `zentto-{source}` |
| `logLevel` | `string` | No | `debug/info/warn/error/nothing`. Default `warn` |
| `dedup` | `EventDedup` | No | Estrategia de deduplicacion. Default: en memoria con TTL 10min |

Nomenclatura de topics: `zentto.{tenantCode}.{eventType}` (ej. `zentto.acme.hotel.reservation.confirmed`).

```typescript
import { EventBusClient } from '@zentto/platform-client/events';

const bus = new EventBusClient({
  brokers: ['kafka:9092'],
  source: 'zentto-hotel',
  tenantCode: 'ACME',
});

// Producer
await bus.connect();
const envelope = await bus.publish({
  eventType: 'hotel.reservation.confirmed',
  data: { reservationId: 123, checkIn: '2026-05-01', guests: 2 },
  correlationId: 'req-abc-123',
});

// Consumer (suscribir por eventType exacto o regex)
bus.on('hotel.reservation.confirmed', async (evt) => {
  console.log(evt.data, evt.tenantCode, evt.eventId);
});
bus.on(/hotel\..+/, async (evt) => { /* ... */ });

await bus.start({ fromBeginning: false });
await bus.disconnect();
```

Deduplicacion personalizada (persistir entre reinicios):

```typescript
import type { EventDedup } from '@zentto/platform-client/events';

class RedisDedup implements EventDedup {
  async seen(eventId: string): Promise<boolean> { /* redis GET */ return false; }
  async mark(eventId: string): Promise<void>    { /* redis SET EX 600 */ }
}

const bus = new EventBusClient({ ..., dedup: new RedisDedup() });
```

---

### webhooks

Verificacion y firma de webhooks enviados por Zentto. Solo disponible en Node.js (usa `node:crypto`).

```typescript
import { verifySignature, signBody } from '@zentto/platform-client/webhooks';

// Express handler (body como Buffer o string sin parsear)
app.post('/webhook', express.raw({ type: 'application/json' }), (req, res) => {
  const rawBody = req.body.toString('utf-8');
  const sig = req.headers['x-zentto-signature'];

  if (!verifySignature(rawBody, sig, process.env.WEBHOOK_SECRET_HASH)) {
    return res.status(401).end();
  }

  const envelope = JSON.parse(rawBody);
  // envelope.eventType, envelope.data, envelope.tenantCode
  res.status(200).end();
});

// Firmar un body (util en tests y mocks)
const signature = signBody(JSON.stringify(payload), secretHash);
// Resultado: "sha256=<64 caracteres hexadecimales>"
```

> La verificacion usa `timingSafeEqual` para prevenir timing attacks. Zentto firma con `secretHash` (almacenado en BD), no con el `secret` plano que el administrador vio al crear el webhook.

---

## Configuracion

### Variables de entorno estandar

| Variable | Submodulo | Descripcion |
|----------|-----------|-------------|
| `NOTIFY_API_URL` | notify | URL base. Default `https://notify.zentto.net` |
| `NOTIFY_API_KEY` | notify | API key (preferida) |
| `API_MASTER_KEY` | notify | Fallback si `NOTIFY_API_KEY` no esta seteada |
| `AUTH_SERVICE_URL` o `AUTH_URL` | auth | URL base. Default `https://auth.zentto.net` |
| `AUTH_SERVICE_KEY` | auth | Service key para operaciones admin |
| `CACHE_URL` | cache | URL base. Default `https://cache.zentto.net` |
| `CACHE_APP_KEY` | cache | Header `x-client-key` (obligatoria) |
| `ZENTTO_API_URL` | landing | URL base. Default `https://api.zentto.net` |
| `ZENTTO_TENANT_KEY` | landing | PublicApiKey del tenant |
| `KAFKA_BROKERS` | events | CSV de brokers (obligatoria). Ej: `kafka:9092,kafka2:9092` |
| `ZENTTO_SERVICE_NAME` | events | Nombre del servicio emisor (obligatoria) |
| `ZENTTO_TENANT_CODE` | events | TenantCode por defecto. Default `ZENTTO` |

### Opciones de resiliencia

Los clientes basados en HTTP (auth, cache, landing) soportan:

```typescript
new AuthClient({
  timeoutMs: 5_000,
  retries: 2,
  onError: (err, ctx) => logger.error({ err, ctx }, '[auth] request failed'),
  rateLimit: { capacity: 50, refillRate: 10 }, // token bucket client-side
});
```

El HTTP helper interno incluye:
- Reintentos con backoff exponencial (250ms, 500ms, ...) ante errores de red o 5xx
- Sin reintentos en 4xx
- Circuit breaker por baseUrl — evita cascadas cuando un upstream falla
- Rate limiter client-side (token bucket) opcional

## Tipos principales

```typescript
// Errores tipados exportados desde el barrel raiz
import {
  PlatformError,
  AuthError,
  ValidationError,
  NotFoundError,
  RateLimitedError,
  ServiceError,
  NetworkError,
  CircuitOpenError,
} from '@zentto/platform-client';

// Usar con errorInstance para evitar try/catch
const r = await authClient.login({ username, password });
if (!r.ok) {
  if (r.errorInstance instanceof RateLimitedError) {
    await sleep((r.errorInstance.retryAfterSec ?? 30) * 1000);
  }
  if (r.errorInstance instanceof AuthError) redirectToLogin();
}

// HttpResult — shape de retorno de auth, cache, landing
interface HttpResult<T> {
  ok: boolean;
  status?: number;
  data?: T;
  error?: string;
  errorInstance?: PlatformError;
}

// NotifyResult — shape de retorno del NotifyClient
interface NotifyResult<T = unknown> {
  ok: boolean;
  messageId?: string;
  via?: string;
  data?: T;
  error?: string;
}

// EventEnvelope — shape de mensajes del event bus
interface EventEnvelope<T = unknown> {
  eventId: string;
  eventType: string;   // "crm.lead.created" — convencion "<dominio>.<entidad>.<accion>"
  tenantCode: string;
  tenantId?: number;
  timestamp: string;   // ISO 8601 UTC
  source: string;
  correlationId?: string;
  data: T;
  version: number;
}

// CacheIdentity — contexto de propiedad de datos en zentto-cache
interface CacheIdentity {
  companyId: number;
  userId?: number | string;
  email?: string;
}
```

## Documentacion extendida

Arquitectura, matriz de autenticacion por contexto y guia de adopcion:

- `docs/wiki/14-integracion-ecosistema.md` en [zentto-erp/zentto-web](https://github.com/zentto-erp/zentto-web)
- `docs/wiki/15-event-bus.md` — nomenclatura de topics y patrones de consumo

## Repositorio

`https://github.com/zentto-erp/zentto-web` — directorio `web/platform-client/`

## Licencia

MIT (C) Zentto ERP
