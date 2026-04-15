# @zentto/platform-client (embedded)

Cliente tipado y compartido para los servicios de plataforma Zentto:
**notify**, **cache**, **auth**, **landing** (leads/CRM).

## Por qué existe

Antes, cada app del ecosistema (ERP API, modular-frontend, hotel, medical,
tickets, etc.) reimplementaba `fetch(notify.zentto.net/...)` con:
- Headers distintos (Bearer vs X-API-Key vs cookie).
- Retries y timeouts inconsistentes (o ausentes).
- Shape de payload duplicado.
- Cero observabilidad transversal.

Este paquete es **el único punto de contacto con los servicios de plataforma**.
Cuando un caller nuevo necesita notificar, cachear o crear leads, importa
acá — no escribe fetch a mano.

## Forma del paquete

```
lib/platform-client/
├── notify/          → NotifyClient (email, push, OTP, WhatsApp, contacts)
├── cache/           → (pendiente)  CacheClient
├── auth/            → (pendiente)  AuthServiceClient
└── landing/         → (pendiente)  LandingClient (leads para tenants externos)
```

Cada submódulo expone una **clase factory** que recibe config (baseUrl + key)
y retorna métodos typed. No hay singletons globales.

## Por qué vive en `web/api/src/lib` hoy

Como MVP vive dentro del monorepo del API. En una iteración siguiente se
extrae a un paquete npm `@zentto/platform-client` que cualquier repo
(verticals, mobile, SDKs de cliente) pueda instalar. La interfaz del
cliente queda estable desde ahora para no romper callers al mover.

## Adopción por otras apps

Ver `docs/wiki/13-integracion-plataforma.md` en `zentto-erp-docs`.
