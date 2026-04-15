# 14 — Integración nativa del ecosistema Zentto

**Status:** Active 2026-04-15 (MVP notify cliente)
**Ámbito:** cómo cualquier app del ecosistema habla con los servicios de plataforma (**landing, CRM, notify, cache**) — sin reescribir fetch a mano y con el mismo patrón para tenants externos.

## 1. Principios

1. **Cero duplicación de clientes HTTP.** Todo caller usa `@zentto/platform-client` (embebido hoy en `web/api/src/lib/platform-client`, extraíble a npm cuando lo adopte una segunda app).
2. **Una sola forma de autenticarse por contexto**:
   - *Server-to-server (ERP API ↔ notify, auth, cache)*: header `X-API-Key` con el master key del servicio.
   - *Dashboard del tenant (frontend Zentto)*: cookie HttpOnly de zentto-auth (cross-subdomain).
   - *Sitio externo de un tenant cliente (acme.com)*: header `X-Tenant-Key` con un `cfg.PublicApiKey` emitido desde el CRM del tenant.
3. **Best-effort por defecto**: los métodos de negocio (`email.send`, `contacts.upsert`) nunca tumban el flujo de negocio; loguean y retornan `{ ok: false }`.
4. **El paquete es el contrato**. Si una vertical necesita una pieza nueva (ej. `notify.reports.schedule`), se agrega *al paquete*, no a un fetch adhoc.

## 2. Matriz actual (resumen)

| Caller | Callee | Método |
|---|---|---|
| ERP API | notify.zentto.net | `@zentto/platform-client/notify` (MVP) |
| Verticals (hotel, medical, tickets, rental, education) | notify.zentto.net | ⚠ hoy fetch manual — pendiente migrar |
| Frontend modular | ERP API | cookie + Bearer refresh vía `shared-api` |
| ERP API | zentto-auth | `x-service-key` (pendiente encapsular en `platform-client/auth`) |
| ERP API | zentto-cache | `x-app-key` (pendiente encapsular en `platform-client/cache`) |
| Pages Function landing | ERP API (leads) | `X-Tenant-Key` o subdomain middleware |

## 3. Cómo adoptar el cliente en una app nueva

### Server-to-server (ERP, vertical, backoffice)

```ts
import { notifyFromEnv } from "../lib/platform-client/notify"; // ajustá la ruta

const notify = notifyFromEnv();

// Email con template centralizado en notify
await notify.email.sendTemplate("lead-confirmacion", {
  to: "lead@acme.com",
  variables: { firstName: "Juan", topicLabel: "Demo", ... },
});

// Contactos
await notify.contacts.upsert({ email, name, phone, tags: ["hotel", "check-in"] });

// OTP
await notify.otp.send({ channel: "email", destination: email });
```

Env vars requeridas: `NOTIFY_API_URL` (default `https://notify.zentto.net`) + `NOTIFY_API_KEY` (o `API_MASTER_KEY` como fallback).

### Tenant cliente (acme.com)

Los tenants clientes no usan el master key — usan una **`PublicApiKey`** que el admin genera desde el CRM:

```bash
curl -X POST https://api.zentto.net/api/v1/crm/public-keys \
  -H 'Authorization: Bearer <JWT del admin del tenant>' \
  -d '{"label":"acme.com","scopes":"landing:lead:create"}'
# → { ok: true, key: "zk_<prefix>_<secret>", ... }  (plain visible UNA vez)
```

Sitios externos incluyen el header `X-Tenant-Key` al llamar `/api/landing/register` y el lead cae en **su propio `crm.Lead`** (pipeline `LANDING` auto-provisionado).

**Roadmap**: los scopes van a extenderse (`notify:email:send`, `notify:otp:send`, `cache:read`) para que un sitio externo del tenant también pueda disparar emails o leer cache bajo su contexto.

## 4. Guía de migración por app

Cada vertical adopta el cliente en un PR pequeño:

1. Crear carpeta `src/lib/platform-client/` dentro del repo de la vertical *o* usar el mismo paquete vía symlink/npm.
2. Reemplazar cada `fetch(NOTIFY_URL + '/api/email/send')` por `notify.email.send({...})`.
3. Borrar duplicados de types, retries y shape de payload.
4. Cuando el paquete se publique a npm (`@zentto/platform-client`), migrar el import y eliminar la carpeta local.

## 5. Follow-ups priorizados

- [ ] Submódulo `platform-client/auth` — wrap de `zentto-auth.client.ts` + `createTenantUser`.
- [ ] Submódulo `platform-client/cache` — estandariza header (solo `x-app-key` + cookie).
- [ ] Submódulo `platform-client/landing` — para emitir lead desde widget embebido de tenant.
- [ ] Adopción en hotel, medical, tickets, rental, education (1 PR cada uno).
- [ ] Extraer `@zentto/platform-client` a npm (privado) una vez adoptado por 2+ repos.
- [ ] Scopes extendidos en `cfg.PublicApiKey` para notify/cache del tenant cliente.
- [ ] Event bus nativo sobre Kafka (ya existe `zentto-obs`) con topics `zentto.<tenant>.<domain>.<event>` para suscripciones webhook por tenant.

## 6. Reglas críticas

- **NUNCA** agregues una nueva llamada HTTP a `notify.zentto.net` fuera del cliente. Si te falta un método, agregalo al paquete.
- **NUNCA** hardcodees URLs de servicios en apps; todas vienen de env vars con default sensato.
- **NUNCA** inyectes master keys en frontend — usá cookie del usuario (zentto-auth) o `X-Tenant-Key` del tenant.
