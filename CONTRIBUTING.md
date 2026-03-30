# Guia de Contribucion — Zentto

Guia para contribuir a los repositorios de la organizacion **zentto-erp**. Este documento aplica a todos los repos del ecosistema.

---

## Tabla de Contenido

1. [Modelo de Ramas](#modelo-de-ramas)
2. [Flujo de Trabajo](#flujo-de-trabajo)
3. [Tipos de Deploy por Repo](#tipos-de-deploy-por-repo)
4. [Convenciones de Commits](#convenciones-de-commits)
5. [Reglas Criticas](#reglas-criticas)
6. [Estructura de la Organizacion](#estructura-de-la-organizacion)
7. [Setup Local](#setup-local)

---

## Modelo de Ramas

```
main         ← produccion (deploy automatico)
  ↑ PR
developer    ← integracion / staging
  ↑ PR
feature/*    ← trabajo individual
fix/*
hotfix/*
```

### Ramas permitidas

| Prefijo       | Origen      | Destino PR  | Uso                                       |
| ------------- | ----------- | ----------- | ----------------------------------------- |
| `feature/*`   | `developer` | `developer` | Nueva funcionalidad                       |
| `fix/*`       | `developer` | `developer` | Correccion de bug                         |
| `hotfix/*`    | `main`      | `main`      | Correccion critica en produccion          |
| `docs/*`      | `developer` | `developer` | Solo documentacion                        |
| `refactor/*`  | `developer` | `developer` | Mejoras internas sin cambio funcional     |

### Naming

```
feature/ISSUE-123-agregar-filtro-fechas
fix/ISSUE-456-corregir-calculo-iva
hotfix/timeout-conexion-db
docs/actualizar-wiki-fiscal
```

### Prohibiciones

- **Nunca** push directo a `main`.
- **Nunca** push directo a `developer`.
- **Nunca** `git push --force` a `main` o `developer`.
- Todo cambio entra via Pull Request con al menos una revision.

---

## Flujo de Trabajo

### 1. Crear branch desde developer

```bash
git checkout developer
git pull origin developer
git checkout -b feature/ISSUE-123-mi-feature
```

### 2. Desarrollar y hacer commits

```bash
# Trabajar en los cambios...
git add archivo1.ts archivo2.ts
git commit -m "feat: agregar filtro de fechas en reporte de ventas"
git push origin feature/ISSUE-123-mi-feature
```

### 3. Abrir PR contra developer

- Ir a GitHub y abrir Pull Request: `feature/ISSUE-123-mi-feature` -> `developer`
- CI ejecuta automaticamente (lint, build, tests)
- Solicitar review de al menos un miembro del equipo
- Resolver comentarios y obtener aprobacion
- Merge (squash o merge commit segun el caso)

### 4. Deploy a staging (automatico)

- El merge a `developer` dispara deploy automatico a entorno dev/beta.
- Verificar que todo funcione correctamente en staging.

### 5. PR de developer a main (produccion)

- Cuando el conjunto de cambios en `developer` este validado, abrir PR: `developer` -> `main`.
- Review final del equipo.
- Merge dispara deploy automatico a produccion.

### 6. Hotfix (emergencias)

```bash
git checkout main
git pull origin main
git checkout -b hotfix/descripcion-del-problema
# Corregir, commit, push
# PR directo a main
# Despues del merge, hacer cherry-pick o merge a developer
```

---

## Tipos de Deploy por Repo

| Tipo de Repo        | Ejemplo                    | Branch `developer`         | Branch `main`                |
| ------------------- | -------------------------- | -------------------------- | ---------------------------- |
| Librerias npm       | `@zentto/datagrid`         | Publish con tag `beta`     | Publish version estable      |
| Servicios Docker    | `zentto-web` (API + Front) | Build imagen tag `:dev`    | Build imagen tag `:latest`   |
| Sitios estaticos    | `zentto-erp-docs`          | Preview URL temporal       | Deploy a produccion          |
| Electron            | `zentto-fiscal-agent`      | Pre-release (draft)        | GitHub Release publica       |
| Microservicios      | `zentto-notify`            | Deploy a entorno staging   | Deploy a produccion          |

---

## Convenciones de Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/). El formato es:

```
tipo: descripcion breve en minusculas
```

### Tipos permitidos

| Tipo       | Uso                                               | Ejemplo                                         |
| ---------- | ------------------------------------------------- | ------------------------------------------------ |
| `feat`     | Nueva funcionalidad                               | `feat: agregar exportacion PDF en reportes`      |
| `fix`      | Correccion de bug                                 | `fix: corregir calculo de IVA en factura`        |
| `docs`     | Solo documentacion                                | `docs: actualizar wiki de fiscal multi-pais`     |
| `ci`       | Cambios en CI/CD (workflows, Docker, scripts)     | `ci: agregar step de lint en deploy.yml`         |
| `refactor` | Reestructuracion sin cambio funcional             | `refactor: extraer logica de auth a middleware`  |
| `test`     | Agregar o modificar tests                         | `test: agregar tests para SP de inventario`      |
| `chore`    | Mantenimiento general                             | `chore: actualizar dependencias de Next.js`      |
| `perf`     | Mejora de rendimiento                             | `perf: optimizar query de listado de productos`  |
| `style`    | Formato, espacios, punto y coma (sin logica)      | `style: formatear archivos con prettier`         |

### Reglas de mensajes

- Escribir en **minusculas** despues del tipo.
- Maximo 72 caracteres en la primera linea.
- Si se necesita detalle, dejar una linea en blanco y agregar cuerpo.
- Referenciar issues cuando aplique: `fix: corregir timeout (#123)`.

---

## Reglas Criticas

Estas reglas son **obligatorias** y no tienen excepciones.

### 1. Paridad Dual Database

Todo cambio de base de datos DEBE reflejarse en **ambos motores**:

| Paso | Accion                                                                     |
| ---- | -------------------------------------------------------------------------- |
| 1    | Crear migracion goose en `web/api/migrations/postgres/NNNNN_desc.sql`      |
| 2    | Actualizar funcion PL/pgSQL en `web/api/sqlweb-pg/includes/sp/`           |
| 3    | Actualizar equivalente T-SQL en `web/api/sqlweb/includes/sp/`             |
| 4    | Regenerar DDL SQL Server: `cd web/api/sqlweb-mssql && node pg2mssql.cjs`  |

**Si solo actualizas un motor, el otro queda roto.**

- SP naming: `usp_[Schema]_[Entity]_[Action]`
- Queries siempre parametrizadas, nunca concatenacion de strings.
- Deploy PG via `scripts/goose-deploy.sh` (ejecuta `goose up`).
- **Nunca** editar `sqlweb-pg/` directamente para deploys — todo va como migracion goose.

### 2. Fechas en UTC-0

- Toda fecha se almacena en UTC-0.
- La conversion a zona horaria local se hace en capa de presentacion.
- SQL Server: usar `SYSUTCDATETIME()` (nunca `GETDATE()`).
- PostgreSQL: usar `NOW() AT TIME ZONE 'UTC'`.
- Frontend: usar `useTimezone()` + `formatDate/formatDateTime` de `@zentto/shared-api`.

### 3. No Exponer Secretos

- Nunca versionar archivos `.env`, credenciales o tokens.
- Usar variables de entorno en CI/CD (GitHub Secrets).
- Si necesitas un secreto nuevo, agregarlo al `.env.example` con valor placeholder.

### 4. No Mock Data en Frontend

- **Nunca** hardcodear paises, estados, tipos, catalogos en componentes.
- Paises: `useCountries()` via `GET /v1/config/countries`
- Estados: `useStates(code)` via `GET /v1/config/states/:code`
- Lookups: `useLookup('TYPE')` via `GET /v1/config/lookups/:type`
- Todo dato de catalogo viene de la base de datos via API.

### 5. No Tablas HTML — Usar ZenttoDataGrid

- **Nunca** usar `<table>` HTML nativo para mostrar datos tabulares.
- Siempre usar `<ZenttoDataGrid>` de `@zentto/shared-ui`.
- Esto garantiza consistencia visual, paginacion, filtros y exportacion.

### 6. Logica en API, No en UI

- La logica de negocio va en la API (servicios, stored procedures).
- El frontend solo consume endpoints y presenta datos.
- Mantener contratos API documentados en `web/contracts/openapi.yaml` **antes** de cambiar frontend.

---

## Estructura de la Organizacion

### Repositorios

| Repositorio               | Descripcion                                        | Deploy                          |
| ------------------------- | -------------------------------------------------- | ------------------------------- |
| `zentto-web`              | Monorepo principal: API + Frontend modular         | Docker → `zentto.net`           |
| `zentto-erp-docs`         | Documentacion funcional y tecnica (Astro/Starlight)| `docs.zentto.net`               |
| `zentto-notify`           | Microservicio de notificaciones (email, SMS, push) | Docker → `notify.zentto.net`    |
| `zentto-fiscal-agent`     | Agente fiscal Windows (.NET 9, impresoras fiscales)| GitHub Releases (Electron/exe)  |
| `zentto-report`           | Motor de reportes (reemplazo Crystal Reports)      | npm `@zentto/report-*`          |
| `zentto-datagrid`         | Componente DataGrid React                          | npm `@zentto/datagrid`          |
| `zentto-broker`           | Broker de mensajeria entre servicios               | Docker                          |
| `zentto-cache`            | Capa de cache distribuida                          | Docker                          |
| `zentto-infra`            | Scripts de infraestructura y configuracion servidor | Manual / CI                    |

### Micro-apps del Frontend Modular

El frontend (`web/modular-frontend`) es un monorepo con 17 micro-aplicaciones Next.js:

| App            | Puerto | Descripcion                        |
| -------------- | ------ | ---------------------------------- |
| `shell`        | 3000   | Dashboard principal y navegacion   |
| `ventas`       | 3001   | Modulo de ventas y facturacion     |
| `compras`      | 3002   | Modulo de compras                  |
| `inventario`   | 3003   | Control de inventario              |
| `contabilidad` | 3004   | Contabilidad general               |
| `bancos`       | 3005   | Gestion bancaria y conciliacion    |
| `nomina`       | 3006   | Nomina y recursos humanos          |
| `crm`          | 3007   | Gestion de clientes y leads        |
| `pos`          | 3008   | Punto de venta                     |
| `manufactura`  | 3009   | Produccion y manufactura           |
| `lab`          | 3010   | Laboratorio y pruebas              |
| `auditoria`    | ---    | Logs de auditoria y fiscal         |
| `ecommerce`    | ---    | Tienda online (Zentto Store)       |
| `flota`        | ---    | Gestion de vehiculos y transporte  |
| `logistica`    | ---    | Almacen, despacho y devoluciones   |
| `restaurante`  | ---    | Gestion de restaurantes            |
| `shipping`     | ---    | Envios y paqueteria                |

### Paquetes Compartidos

| Paquete           | Descripcion                                         |
| ----------------- | --------------------------------------------------- |
| `shared-ui`       | Componentes UI comunes (ZenttoDataGrid, botones)    |
| `shared-api`      | Hooks de API, timezone, grid layout sync            |
| `shared-auth`     | Autenticacion, proxy de auth, sesiones              |
| `shared-reports`  | Componentes de reportes compartidos                 |
| `module-*`        | Logica especifica de cada modulo (flota, crm, etc.) |

---

## Setup Local

### Prerequisitos

- **Node.js** 20+ (recomendado: ultima LTS)
- **npm** 10+
- **Git** 2.40+
- **SQL Server** 2012+ (opcional, para desarrollo dual-DB)
- **PostgreSQL** 15+ (recomendado para desarrollo local)

### 1. Clonar el repositorio

```bash
git clone https://github.com/zentto-erp/zentto-web.git
cd zentto-web
```

### 2. Instalar dependencias

```bash
# API
cd web/api
npm install

# Frontend modular
cd web/modular-frontend
npm install
```

### 3. Configurar variables de entorno

```bash
# Copiar el archivo de ejemplo
cp web/api/.env.example web/api/.env
```

Editar `web/api/.env` con los valores necesarios. Valores minimos:

```env
DB_TYPE=postgres
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=datqboxweb
PG_USER=postgres
PG_PASSWORD=tu_password
JWT_SECRET=un_secreto_local
PORT=4000
```

### 4. Inicializar la base de datos

```bash
# PostgreSQL — crear BD y ejecutar scripts base
createdb datqboxweb
psql -U postgres -d datqboxweb -f web/api/sqlweb-pg/run_all.sql

# Ejecutar migraciones pendientes
cd web/api
npx goose -dir migrations/postgres postgres "user=postgres dbname=datqboxweb sslmode=disable" up
```

### 5. Iniciar servidores de desarrollo

```bash
# Terminal 1 — API
cd web/api
npm run dev

# Terminal 2 — Frontend (shell + modulos)
cd web/modular-frontend
npm run dev
```

La API estara disponible en `http://localhost:4000` y el frontend en `http://localhost:3000`.

### 6. Verificar que todo funciona

- Abrir `http://localhost:3000` en el navegador.
- Verificar que la API responde: `curl http://localhost:4000/health`

---

## Recursos Adicionales

- **Wiki tecnica**: `docs/wiki/README.md` (indice completo)
- **Contratos API**: `web/contracts/openapi.yaml`
- **Arquitectura dual-DB**: `docs/wiki/11-dual-database.md`
- **Playbook de agentes IA**: `docs/wiki/06-playbook-agentes.md`

---

## Preguntas Frecuentes

**P: Puedo hacer cambios solo en PostgreSQL sin actualizar SQL Server?**
No. La paridad dual-DB es obligatoria. Ver seccion [Reglas Criticas](#reglas-criticas).

**P: Donde van los nuevos endpoints de API?**
En `web/api/src/modules/{modulo}/routes.ts`. Documentar en `openapi.yaml` antes de consumir en frontend.

**P: Como agrego un nuevo SP?**
1. Migracion goose en `web/api/migrations/postgres/`
2. Funcion PL/pgSQL en `web/api/sqlweb-pg/includes/sp/`
3. Procedimiento T-SQL en `web/api/sqlweb/includes/sp/`
4. Regenerar con `node pg2mssql.cjs`

**P: Como creo una nueva micro-app de frontend?**
Usar como template cualquier app existente (ej. `apps/auditoria`). Registrar en `pm2.config.cjs` y en la navegacion del shell.

**P: Los tests son obligatorios?**
Se recomienda para toda logica de negocio y stored procedures. Los tests de contratos SP (`sp-contracts-mssql.test.ts`) validan paridad entre motores.
