# @zentto/platform-client

Cliente oficial tipado para los servicios de plataforma Zentto: **notify**, **cache** (pronto), **auth** (pronto), **landing** (pronto).

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

### Construcción manual (multi-tenant, tests)

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
