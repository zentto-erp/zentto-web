<div align="center">

# Zentto ERP

**Plataforma empresarial modular para Latinoamérica y España**

Facturación · Contabilidad · Inventario · Nómina · POS · Restaurante · Ecommerce

[![Deploy](https://github.com/zentto-erp/zentto-web/actions/workflows/deploy.yml/badge.svg)](https://github.com/zentto-erp/zentto-web/actions/workflows/deploy.yml)
[![Node.js](https://img.shields.io/badge/Node.js-20-green)](https://nodejs.org)
[![Next.js](https://img.shields.io/badge/Next.js-15-black)](https://nextjs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)](https://www.typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED)](https://www.docker.com)

🌐 **[zentto.net](https://zentto.net)** · 📡 **[api.zentto.net](https://api.zentto.net)**

</div>

---

## ¿Qué es Zentto?

Zentto es un ERP SaaS multi-empresa, multi-país y multi-moneda diseñado para PYMEs. Nació como migración de un sistema legado VB6 y evolucionó a una plataforma web moderna con arquitectura de micro-frontends.

### Módulos disponibles

| Módulo | Puerto | Descripción |
|--------|--------|-------------|
| Shell (hub) | 3000 | Dashboard principal y navegación |
| Contabilidad | 3001 | Plan de cuentas, asientos, balances |
| Nómina | 3002 | Cálculo de nómina, Venezuela y España |
| POS | 3003 | Punto de venta táctil |
| Bancos | 3004 | Conciliación bancaria, CxC, CxP |
| Inventario | 3005 | Productos, almacenes, movimientos |
| Ventas | 3006 | Facturas, pedidos, cotizaciones |
| Compras | 3007 | Órdenes de compra, proveedores |
| Restaurante | 3008 | Mesas, comandas, cocina |
| Ecommerce | 3009 | Tienda online Zentto Store |
| Auditoría | 3010 | Logs, trazabilidad, seguridad |

---

## Stack técnico

```
Frontend    Next.js 15 · React · TypeScript · Tailwind CSS
            Monorepo npm workspaces (11 apps + packages compartidos)

API         Node.js 20 · Express · TypeScript
            JWT auth · Zod validation · Redis (opcional)

Base datos  SQL Server (desarrollo) + PostgreSQL 16 (producción)
            Stored Procedures / PL/pgSQL — arquitectura dual-DB

DevOps      Docker · GitHub Actions CI/CD
            Hetzner CX33 · Cloudflare DNS + SSL · Nginx
```

---

## Desarrollo local

### Requisitos

- Node.js 20+
- npm 10+
- SQL Server o PostgreSQL
- (Opcional) Redis

### Setup

```bash
# 1. Clonar
git clone https://github.com/zentto-erp/zentto-web.git
cd zentto-web

# 2. Configurar API
cp web/api/.env.example web/api/.env
# Editar web/api/.env con tus credenciales de BD

# 3. Instalar dependencias
cd web/api && npm install
cd ../modular-frontend && npm install

# 4. Desarrollo
# Terminal 1 — API (puerto 4000)
cd web/api && npm run dev

# Terminal 2 — Frontend (todos los módulos)
cd web/modular-frontend && npm run dev:all
```

### Base de datos

**SQL Server** (desarrollo Windows):
```bash
# Ejecutar en SSMS
web/api/sqlweb/run_all.sql
```

**PostgreSQL** (desarrollo Linux/Mac o producción):
```bash
psql -U postgres -f web/api/sqlweb-pg/00_create_database.sql
psql -U postgres -d datqboxweb -f web/api/sqlweb-pg/run_all.sql
```

Seleccionar motor en `web/api/.env`:
```env
DB_TYPE=sqlserver   # o "postgres"
```

---

## Producción con Docker

### Build local

```bash
docker compose up --build
```

### Stack completo (API + Frontend + Nginx)

```
http://localhost      → Frontend shell
http://localhost/api  → API (via nginx)
```

### Deploy manual al servidor

```bash
# En el servidor (178.104.56.185)
cd /opt/zentto
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

---

## CI/CD — Despliegue continuo

```
Push a main
    └─► GitHub Actions
           ├─► Build Docker images → ghcr.io/zentto-erp/zentto-web
           └─► SSH deploy → zentto-server (178.104.56.185)
                   └─► docker compose pull + up -d
```

**Servidor:** Hetzner CX33 · Ubuntu 24.04 · Docker 29
**Dominio:** zentto.net (Cloudflare CDN + SSL)
**Certificado:** Let's Encrypt (auto-renovación)

### Configurar un servidor nuevo

```bash
curl -sSL https://raw.githubusercontent.com/zentto-erp/zentto-web/main/scripts/server-setup.sh | bash
```

### Secrets de GitHub Actions requeridos

| Secret | Descripción |
|--------|-------------|
| `SSH_HOST` | IP del servidor |
| `SSH_USER` | Usuario SSH (root) |
| `SSH_PRIVATE_KEY` | Clave privada ED25519 para CI/CD |

---

## Estructura del repositorio

```
zentto-web/
├── web/
│   ├── api/                    # API Node.js + Express
│   │   ├── src/modules/        # Módulos de negocio
│   │   ├── src/db/query.ts     # Helpers DB (callSp, callSpOut, callSpTx)
│   │   ├── sqlweb/             # Scripts SQL Server
│   │   └── sqlweb-pg/          # Scripts PostgreSQL
│   └── modular-frontend/       # Monorepo Next.js
│       ├── apps/               # 11 micro-apps
│       └── packages/           # shared-ui, shared-api, shared-auth...
├── docker/                     # Dockerfiles + PM2 config
├── nginx/                      # Nginx reverse proxy config
├── scripts/                    # Scripts de servidor
├── .github/workflows/          # GitHub Actions CI/CD
└── docs/wiki/                  # Documentación técnica
```

---

## Documentación técnica

| Documento | Descripción |
|-----------|-------------|
| [docs/wiki/README.md](docs/wiki/README.md) | Índice general |
| [docs/wiki/02-api.md](docs/wiki/02-api.md) | API — endpoints y convenciones |
| [docs/wiki/04-modular-frontend.md](docs/wiki/04-modular-frontend.md) | Frontend micro-apps |
| [docs/wiki/06-playbook-agentes.md](docs/wiki/06-playbook-agentes.md) | Playbook agentes IA |
| [docs/wiki/11-dual-database.md](docs/wiki/11-dual-database.md) | Arquitectura dual DB |

---

## Convenciones de desarrollo

- **Ramas:** `develop` (trabajo) → PR → `main` (producción)
- **SPs:** `usp_[Schema]_[Entity]_[Action]` en ambos motores
- **Fechas:** siempre UTC-0 en BD, conversión a timezone de empresa en display
- **Secrets:** nunca en código — usar `.env` local o GitHub Secrets
- **SQL:** todo cambio de BD va en `sqlweb/` **y** `sqlweb-pg/` sin excepción

---

<div align="center">

**Zentto** · Hecho con ❤️ para PYMEs latinoamericanas

[zentto.net](https://zentto.net) · [zentto-erp/zentto-web](https://github.com/zentto-erp/zentto-web)

</div>
