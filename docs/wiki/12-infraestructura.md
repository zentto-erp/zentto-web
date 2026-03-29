# Infraestructura y CI/CD

## Repositorio de infraestructura

Toda la configuracion de infraestructura vive en un repo dedicado:

- **Repo:** [zentto-infra](https://github.com/zentto-erp/zentto-infra)
- **Contenido:** Scripts de servidor, registro de apps, templates de deploy, documentacion de arquitectura

## Servidor de produccion

| Recurso | Valor |
|---|---|
| Proveedor | Hetzner CX33, Nuremberg |
| IP | `178.104.56.185` |
| OS | Ubuntu 24.04 |
| Dominio | `zentto.net` (Cloudflare) |
| SSL | Let's Encrypt (certbot) |
| Reverse proxy | Nginx |
| Base de datos | PostgreSQL 16 (en host) |
| Contenedores | Docker + systemd auto-start |

## Apps desplegadas

| App | Puerto | Subdominio | Repo |
|---|---|---|---|
| zentto-api | 4000 | api.zentto.net | zentto-web |
| zentto-frontend | 3000-3010 | app.zentto.net | zentto-web |
| zentto-notify | 5000 | notify.zentto.net | zentto-notify |
| notify-dashboard | 3100 | notify-dash.zentto.net | zentto-notify |
| broker-api | 4100 | broker.zentto.net | zentto-broker |

## CI/CD

Cada repositorio tiene su propio workflow de GitHub Actions:

```
Push a main → Build Docker → Push ghcr.io → SSH → Pull + Deploy
```

- **zentto-web:** `deploy-api.yml` + `deploy-frontend.yml`
- **zentto-notify:** `deploy.yml`
- **zentto-broker:** `deploy.yml`

Todos comparten los mismos secrets de GitHub:
- `SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`
- `GITHUB_TOKEN` (automatico)

Secrets adicionales por plataforma/integracion:
- `AUTH_SECRET` — frontend/shell de zentto-web
- `NOTIFY_API_KEY` — integracion de zentto-web con zentto-notify para webhook de correo

## Como agregar una nueva app

Ver la guia completa en `zentto-infra/docs/onboarding-new-app.md`.

Resumen:
1. Crear repo en `zentto-erp`
2. Agregar Dockerfile + workflow de deploy
3. Registrar en `zentto-infra/apps/registry.json`
4. Configurar Nginx + DNS
5. Push a main = deploy automatico

## Registro central de apps

El archivo `zentto-infra/apps/registry.json` es el catalogo de todas las apps. Contiene:
- Nombre del contenedor
- Imagen Docker
- Puerto
- Red Docker
- Health check
- Config de Nginx

Este registro es la fuente de verdad para la infraestructura.

## Referencia rapida de comandos (en el servidor)

```bash
# Ver todos los contenedores
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Reiniciar un servicio
docker restart zentto-api

# Ver logs
docker logs -f zentto-api

# Health check manual
curl http://localhost:4000/health
curl http://localhost:5000/health

# Ejecutar script de inicio completo
/opt/zentto/start-services.sh

# Ver log de inicio del sistema
tail -f /var/log/zentto-startup.log
```
