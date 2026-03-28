# Zentto - Claude Code

## Idioma

- Toda la salida debe ser en **español**.
- Nombres de variables, funciones y codigo se mantienen en ingles.

## Modo de trabajo

- Usar **agentes en paralelo** siempre que las tareas sean independientes.
- Hacer cambios minimos, trazables y verificables.
- No exponer secretos de archivos `.env`.
- No ejecutar `git push` sin confirmacion explicita del usuario.
- Priorizar logica en API/servicios, no en UI.
- Mantener trazabilidad VB6 -> API/Frontend/Modular Frontend.

## Lectura obligatoria

1. `docs/wiki/README.md`
2. `docs/wiki/02-api.md`
3. `docs/wiki/03-frontend.md`
4. `docs/wiki/04-modular-frontend.md`
5. `docs/wiki/05-mapa-vb6-a-web.md`
6. `docs/wiki/06-playbook-agentes.md`
7. `docs/wiki/07-compatibilidad-multi-ia.md`
8. `docs/wiki/11-dual-database.md`

## Estructura

| Componente       | Ruta                         | Stack                              |
| ---------------- | ---------------------------- | ---------------------------------- |
| API              | `web/api`                    | Node + Express + TypeScript        |
| Frontend modular | `web/modular-frontend`       | Monorepo micro-frontends (Next.js) |
| Contratos        | `web/contracts/openapi.yaml` | OpenAPI                            |
| PostgreSQL (prod) | `web/api/sqlweb-pg/`         | PostgreSQL functions (plpgsql)     |
| Migraciones       | `web/api/migrations/postgres/` | Goose migrations (fuente de verdad) |
| SQL Server (ref)  | `web/api/sqlweb/`            | SQL Server SPs (referencia legacy) |

## Base de datos — PostgreSQL (produccion)

### Fuente de verdad

| Componente | Ruta | Uso |
| ---------- | ---- | --- |
| **Migraciones goose** | `web/api/migrations/postgres/` | **Fuente de verdad** para cambios incrementales |
| **Functions PL/pgSQL** | `web/api/sqlweb-pg/includes/sp/` | Definiciones de funciones + seeds |
| **SQL Server (legacy)** | `web/api/sqlweb/includes/sp/` | Solo referencia — NO se usa en produccion |

### PostgreSQL (produccion)

- Host produccion: `172.18.0.1:5432` (Docker gateway)
- Base: `zentto_prod` (produccion), `datqboxweb` (local)
- Scripts: `web/api/sqlweb-pg/`
- Deploy: `scripts/goose-deploy.sh` (migraciones goose)

### SQL Server (solo referencia local)

- Servidor: `DELLXEONE31545`
- Base: `DatqBoxWeb`
- Scripts: `web/api/sqlweb/includes/sp/` (165 SPs en T-SQL)
- **NO se usa en produccion** — solo referencia para futuras migraciones

### REGLA CRITICA: Todo cambio de BD va como migracion goose

**NUNCA editar sqlweb-pg/ directamente para deploys.** Todo cambio va como:

1. Migración goose: `web/api/migrations/postgres/NNNNN_descripcion.sql`
2. Actualizar funciones en: `web/api/sqlweb-pg/includes/sp/` (referencia local)
3. Deploy: `scripts/goose-deploy.sh` ejecuta `goose up`

| Accion            | Archivo                                          |
| ----------------- | ------------------------------------------------ |
| Nuevo SP/funcion  | Migración goose + `sqlweb-pg/includes/sp/usp_*.sql` |
| Nueva tabla       | Migración goose con DDL                          |
| Seed data         | Migración goose o `sqlweb-pg/includes/sp/seed_*.sql` |
| Cambio de esquema | Migración goose con ALTER verificable            |

### Carpetas eliminadas

- ~~`web/api/sql/`~~ — archivada, eliminada (scripts legacy sin uso)
- ~~`web/api/sqlweb-mssql/`~~ — intento incompleto de regenerar SQL Server, eliminado

## Nomenclatura del proyecto

| Contexto        | Nombre              |
| --------------- | ------------------- |
| Producto        | **Zentto**          |
| Scope npm       | `@zentto/*`         |
| Store ecommerce | Zentto Store        |
| Hardware hub    | ZenttoHardwareHub   |
| Fiscal agent    | Zentto Fiscal Agent |
| Report engine   | Zentto.JsReport     |

## Pipeline de trabajo

1. **Planner** -> planifica y evalua riesgos
2. **Developer** -> implementa
3. **SQL Specialist** -> valida SQL y crea migracion goose en `migrations/postgres/`
4. **QA** -> GO/NO-GO

## Infraestructura de Produccion

| Componente  | Valor                                                   |
| ----------- | ------------------------------------------------------- |
| Servidor    | Hetzner CX33 — `zentto-server`                          |
| IP          | `178.104.56.185`                                        |
| Dominio     | `zentto.net` (Cloudflare)                               |
| Frontend    | `https://zentto.net` → Docker container puerto 3000     |
| API         | `https://api.zentto.net` → Docker container puerto 4000 |
| Repositorio | `https://github.com/zentto-erp/zentto-web`              |
| Registry    | `ghcr.io/zentto-erp/zentto-web/api` y `.../frontend`    |

### CI/CD — GitHub Actions

- Rama `main` → deploy automatico a produccion
- Workflow: `.github/workflows/deploy.yml`
- Build Docker → push a ghcr.io → SSH deploy al servidor
- Secrets configurados: `SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`, `GHCR_PAT`

### Docker

```
docker/Dockerfile.api        # API Node/Express
docker/Dockerfile.frontend   # 11 micro-apps Next.js via PM2
docker/pm2.config.cjs        # PM2 ecosystem (ports 3000-3010)
docker-compose.yml           # Local (build)
docker-compose.prod.yml      # Produccion (imagenes ghcr.io)
nginx/zentto.conf            # Reverse proxy config
scripts/server-setup.sh      # Setup inicial del servidor
```

### Setup del servidor (primera vez)

```bash
# En el servidor como root:
bash <(curl -sSL https://raw.githubusercontent.com/datqbox/zentto-web/main/scripts/server-setup.sh)

# SSL (tras configurar DNS en Cloudflare):
certbot --nginx -d zentto.net -d www.zentto.net -d api.zentto.net
```

### DNS Cloudflare (registros requeridos)

```
A    zentto.net      178.104.56.185   (proxy OFF para SSH, ON para HTTP)
A    www.zentto.net  178.104.56.185
A    api.zentto.net  178.104.56.185
```

## Reglas

- Siempre parametrizar queries SQL.
- Mantener contratos API documentados antes de cambios en frontend.
- Cualquier cambio de esquema debe ir como migracion goose en `web/api/migrations/postgres/`.
- No versionar secretos ni credenciales.
- SP naming: `usp_[Schema]_[Entity]_[Action]` (ambos motores).
- Output pattern: Lists usan `@TotalCount OUTPUT` (SQL Server) / columna `"TotalCount"` (PG).
- Writes usan `@Resultado, @Mensaje OUTPUT` (SQL Server) / `RETURNS TABLE("ok", "mensaje")` (PG).
- Helpers API: `callSp()`, `callSpOut()`, `callSpTx()` en `web/api/src/db/query.ts`.
- Todas las fechas en **UTC-0**. Display convierte a timezone de empresa.
- No hacer `git push --force` a `main` sin confirmacion explicita.
- Deploy a produccion solo via CI/CD (push a main) o `workflow_dispatch`.
