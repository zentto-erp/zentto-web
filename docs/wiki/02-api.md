# 02 - API Node + Express + TypeScript

## Ubicacion

- Raiz API: `web/api`
- Entry points: `src/index.ts`, `src/app.ts`
- Modulos: `src/modules/*`
- Contrato: `web/contracts/openapi.yaml`
- DB helpers: `src/db/query.ts` (`callSp`, `callSpOut`, `callSpTx`)

## Stack

- Node.js + Express
- TypeScript
- **Dual DB**: SQL Server (`mssql`) + PostgreSQL (`pg`)
- JWT para autenticacion
- Zod para validacion
- Redis opcional (`ioredis`)

## Scripts

Desde `web/api`:

- `npm run dev` — desarrollo con hot-reload
- `npm run build` — compilar TypeScript
- `npm run start` — produccion

## Modulos de negocio

Incluye, entre otros:

- Clientes, Proveedores, Inventario, Compras, Facturas
- Bancos, Cuentas, CxC, CxP, Pagos, Abonos
- Contabilidad, Nomina, Empleados
- Pedidos, Cotizaciones, Notas, Ordenes, Presupuestos
- POS, Restaurante, Ecommerce
- CRUD/meta y modulos shared

## Base de datos — Motor dual

El motor activo se selecciona con `DB_TYPE` en `web/api/.env`:

```env
DB_TYPE=sqlserver   # Microsoft SQL Server
DB_TYPE=postgres    # PostgreSQL
```

### Variables SQL Server

```env
DB_SERVER=DELLXEONE31545
DB_DATABASE=DatqBoxWeb
DB_USER=sa
DB_PASSWORD=****
DB_ENCRYPT=false
DB_TRUST_CERT=true
```

### Variables PostgreSQL

```env
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=datqboxweb
PG_USER=postgres
PG_PASSWORD=****
PG_POOL_MIN=0
PG_POOL_MAX=10
PG_SSL=false
```

Ver `web/api/.env.example` para la plantilla completa.

## Directorios de scripts SQL

| Motor | Directorio | Tipo |
|-------|-----------|------|
| SQL Server | `web/api/sqlweb/includes/sp/` | Stored Procedures (T-SQL) |
| PostgreSQL | `web/api/sqlweb-pg/includes/sp/` | Functions (PL/pgSQL) |

**REGLA**: Todo SP/funcion/seed/tabla nueva debe crearse en **ambos** directorios. Ver [11-dual-database.md](./11-dual-database.md) para la guia completa de traduccion.

## Convencion de SPs

- Nombre: `usp_[Schema]_[Entity]_[Action]`
- Ejemplo: `usp_ar_salesdocument_list`, `usp_master_customer_create`
- Lists: devuelven `TotalCount` para paginacion
- Writes: devuelven `ok` + `mensaje`
- Todas las fechas en **UTC-0** (`SYSUTCDATETIME()` / `NOW() AT TIME ZONE 'UTC'`)

## Reglas

- Siempre parametrizar queries.
- Mantener contratos API documentados antes de cambios en frontend.
- Cualquier cambio de esquema debe dejar script SQL verificable en **ambos** directorios (`sqlweb/` y `sqlweb-pg/`).
- No versionar secretos ni credenciales.
