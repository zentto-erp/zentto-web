# Docker — Zentto Production

## Archivos en esta carpeta

| Archivo | Proposito |
|---------|-----------|
| `Dockerfile.api` | Build de la API Node/Express |
| `Dockerfile.frontend` | Build de las 11 micro-apps Next.js |
| `pm2.config.cjs` | PM2 ecosystem (puertos 3000-3010) |
| `.env.api.production` | **PLANTILLA** de env para la API en servidor |
| `.env.frontend.production` | **PLANTILLA** de env para el frontend en servidor |

## Despliegue en servidor

### 1. Copiar los .env al servidor

```bash
# En tu maquina local:
scp docker/.env.api.production root@178.104.56.185:/opt/zentto/.env.api
scp docker/.env.frontend.production root@178.104.56.185:/opt/zentto/.env.frontend

# En el servidor, editar y cambiar los secretos:
ssh root@178.104.56.185
nano /opt/zentto/.env.api        # Cambiar: PG_PASSWORD, JWT_SECRET, CAPTCHA_SECRET
nano /opt/zentto/.env.frontend   # Cambiar: AUTH_SECRET, NEXT_PUBLIC_TURNSTILE_SITE_KEY
chmod 600 /opt/zentto/.env.api /opt/zentto/.env.frontend
```

### 2. Variables que DEBES cambiar (marcadas con CAMBIAR_*)

**En `.env.api`:**
- `PG_PASSWORD` — password de PostgreSQL en produccion
- `JWT_SECRET` — secreto para firmar tokens JWT (min 32 chars)
- `CAPTCHA_SECRET` — secreto de Turnstile/reCAPTCHA

**En `.env.frontend`:**
- `AUTH_SECRET` — secreto de NextAuth (generar con `openssl rand -base64 32`)
- `NEXT_PUBLIC_TURNSTILE_SITE_KEY` — clave publica de Turnstile

### 3. Deploy automatico

El CI/CD (`.github/workflows/deploy.yml`) hace:
1. Build Docker con `NEXT_PUBLIC_API_*=https://api.zentto.net` (baked en JS)
2. Push imagenes a `ghcr.io/zentto-erp/zentto-web/{api,frontend}`
3. SSH al servidor → pull imagenes → `docker compose up -d`

### 4. Deploy manual

```bash
# En el servidor:
cd /opt/zentto
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
```

## Puertos

| App | Puerto | Dominio (produccion) |
|-----|--------|---------------------|
| API | 4000 | `https://api.zentto.net` |
| Shell | 3000 | `https://zentto.net` |
| Contabilidad | 3001 | interno (proxy via shell) |
| Nomina | 3002 | interno |
| POS | 3003 | interno |
| Bancos | 3004 | interno |
| Inventario | 3005 | interno |
| Ventas | 3006 | interno |
| Compras | 3007 | interno |
| Restaurante | 3008 | interno |
| Ecommerce | 3009 | interno |
| Auditoria | 3010 | interno |

## Flujo de variables de entorno

```
Dockerfile.frontend
  ARG NEXT_PUBLIC_API_BASE_URL   ← CI/CD pasa https://api.zentto.net
  ARG NEXT_PUBLIC_API_BASE       ← baked en el JS bundle (cliente)
  ARG NEXT_PUBLIC_API_URL
  ARG NEXT_PUBLIC_BACKEND_URL

docker-compose.prod.yml
  env_file: .env.frontend        ← AUTH_SECRET (runtime, server-side)
  environment:
    AUTH_TRUST_HOST=true          ← runtime
    NEXTAUTH_URL=https://zentto.net
    BACKEND_URL=http://zentto-api:4000  ← SSR server-to-server
    API_URL=http://zentto-api:4000

pm2.config.cjs
  shellEnv: hereda AUTH_*, BACKEND_URL del contenedor
  runtimeEnv: hereda BACKEND_URL, API_URL del contenedor
```
