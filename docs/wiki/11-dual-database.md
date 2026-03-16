# 11 - Arquitectura Dual Database (SQL Server + PostgreSQL)

## Vision general

Zentto soporta **dos motores de base de datos** en paralelo. El API detecta cual usar mediante la variable `DB_TYPE` en `web/api/.env`:

```env
DB_TYPE=sqlserver   # Motor: Microsoft SQL Server (mssql)
DB_TYPE=postgres    # Motor: PostgreSQL (pg / node-postgres)
```

Ambos motores son **funcionalmente equivalentes**. La API expone los mismos endpoints sin importar cual este activo.

## Directorios de scripts

| Motor | Directorio | Despliegue |
|-------|-----------|------------|
| SQL Server | `web/api/sqlweb/` | SSMS con `:r` includes en `run_all.sql` |
| PostgreSQL | `web/api/sqlweb-pg/` | `psql -U postgres -d datqboxweb -f run_all.sql` |

### Estructura de sqlweb/ (SQL Server)

```
web/api/sqlweb/
  includes/
    sp/
      usp_ar.sql          # Cuentas por Cobrar
      usp_ap.sql          # Cuentas por Pagar
      usp_doc_sales.sql   # Documentos de Venta
      usp_doc_purchase.sql# Documentos de Compra
      usp_acct.sql        # Contabilidad
      usp_util.sql        # Utilidades
      seed_*.sql           # Datos semilla
      ...
  run_all.sql              # Master script (SSMS)
```

### Estructura de sqlweb-pg/ (PostgreSQL)

```
web/api/sqlweb-pg/
  00_create_database.sql   # CREATE DATABASE + extensions
  01_core_foundation.sql   # Schemas + tablas cfg/sec
  02_master_data.sql       # Customer, Supplier, Employee, Product
  03_accounting_core.sql   # Account, JournalEntry
  04_operations_core.sql   # AR, AP, Fiscal, POS, REST
  05_api_compat_bridge.sql # Tablas legacy (Cuentas, Asientos, etc.)
  06_seed_reference_data.sql
  07_pos_rest_extensions.sql
  08_fin_hr_extensions.sql
  09_canonical_maestros.sql
  10_canonical_documents.sql
  11_canonical_usuarios_fiscal.sql
  12_payment_ecommerce.sql
  13_triggers.sql
  14_fulltext_search.sql
  15_seed_contabilidad.sql
  16_seed_nomina.sql
  17_seed_ecommerce.sql
  includes/
    sp/                     # Funciones PL/pgSQL (equivalentes a SPs)
      usp_ar.sql
      usp_ap.sql
      usp_doc_sales.sql
      ...
  tools/
    verify_migration.sql    # Verificacion post-despliegue
  run_all.sql               # Master script (psql)
```

## Despliegue PostgreSQL (desde cero)

```bash
# 1. Crear base de datos
psql -U postgres -f web/api/sqlweb-pg/00_create_database.sql

# 2. Desplegar todo
psql -U postgres -d datqboxweb -f web/api/sqlweb-pg/run_all.sql
```

## Despliegue SQL Server

Abrir `web/api/sqlweb/run_all.sql` en SSMS y ejecutar. Usa `:r` para incluir los sub-scripts.

## Capa API: Abstraccion de motor

El switch esta en `web/api/src/db/`:

- `query.ts` — Helpers `callSp()`, `callSpOut()`, `callSpTx()` que internamente detectan `DB_TYPE` y usan el driver correcto (`mssql` o `pg`).
- Los modulos en `src/modules/*/service.ts` **no saben** que motor esta activo. Solo llaman `callSp('usp_NombreDelSP', params)`.

## Configuracion en .env

```env
# ── Motor activo ──
DB_TYPE=sqlserver          # "sqlserver" | "postgres"

# ── SQL Server ──
DB_SERVER=DELLXEONE31545
DB_DATABASE=DatqBoxWeb
DB_USER=sa
DB_PASSWORD=****
DB_ENCRYPT=false
DB_TRUST_CERT=true

# ── PostgreSQL ──
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

## REGLA CRITICA: Paridad obligatoria

**TODO cambio de base de datos DEBE implementarse en AMBOS directorios.** No hay excepciones.

### Checklist para cualquier cambio SQL

- [ ] Crear/modificar SP en `web/api/sqlweb/includes/sp/` (SQL Server)
- [ ] Crear/modificar funcion equivalente en `web/api/sqlweb-pg/includes/sp/` (PostgreSQL)
- [ ] Si es tabla nueva: DDL en ambos directorios
- [ ] Si es seed: seed en ambos directorios
- [ ] Si es indice: indice en ambos directorios
- [ ] Verificar que `run_all.sql` de PG incluye el nuevo archivo (linea `\i`)
- [ ] Verificar que `run_all.sql` de SQL Server incluye el nuevo archivo (linea `:r`)
- [ ] Probar con `DB_TYPE=sqlserver` y con `DB_TYPE=postgres`

### Tabla de traduccion rapida

| SQL Server | PostgreSQL |
|---|---|
| `CREATE PROCEDURE usp_X` | `CREATE OR REPLACE FUNCTION usp_x(...) RETURNS ... LANGUAGE plpgsql AS $$` |
| `@Param INT` | `p_param INT` |
| `@Resultado INT OUTPUT` | `RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)` |
| `@TotalCount INT OUTPUT` | Columna `"TotalCount"` en `RETURNS TABLE` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `NVARCHAR(MAX)` | `TEXT` |
| `BIT` | `BOOLEAN` |
| `DATETIME` / `DATETIME2` | `TIMESTAMP` |
| `INT IDENTITY(1,1)` | `INT GENERATED ALWAYS AS IDENTITY` |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` |
| `FLOAT` | `DOUBLE PRECISION` |
| `SYSUTCDATETIME()` | `NOW() AT TIME ZONE 'UTC'` |
| `GETDATE()` | **PROHIBIDO** — usar `NOW() AT TIME ZONE 'UTC'` |
| `ISNULL(x, d)` | `COALESCE(x, d)` |
| `OPENJSON(...)` | `jsonb_array_elements(...)` |
| `FOR JSON PATH` | `json_agg(row_to_json(...))` |
| `BEGIN TRY...CATCH` | `EXCEPTION WHEN OTHERS THEN` |
| `IF OBJECT_ID(...) IS NULL` | `CREATE TABLE IF NOT EXISTS` |
| `MERGE...WHEN NOT MATCHED` | `INSERT...ON CONFLICT DO NOTHING/UPDATE` |
| `N'texto'` | `'texto'` |
| `GO` | (omitir) |
| `PascalCase` columnas | `"PascalCase"` entre comillas dobles |

## Schemas de base de datos

Ambos motores usan los mismos schemas logicos:

| Schema | Descripcion |
|--------|-------------|
| `cfg` | Configuracion (Company, Branch, AppSetting) |
| `sec` | Seguridad (User, Role, Permission) |
| `master` | Maestros (Customer, Supplier, Employee, Product) |
| `doc` | Documentos (alias a ar/ap) |
| `ar` | Cuentas por Cobrar |
| `ap` | Cuentas por Pagar |
| `acct` | Contabilidad |
| `pay` | Pasarela de pagos |
| `pos` | Punto de Venta |
| `rest` | Restaurante |
| `hr` | Recursos Humanos |
| `fin` | Finanzas |
| `sys` | Sistema (logs, audit) |
| `store` | Ecommerce |

## Convenciones de nombrado

- **SPs/Funciones**: `usp_[Schema]_[Entity]_[Action]` — Ejemplo: `usp_ar_salesdocument_list`
- **Tablas**: `PascalCase` — Ejemplo: `ar."SalesDocument"`
- **Archivos SQL**: `usp_[modulo].sql` para funciones, `seed_[tema].sql` para datos, `sp_[accion].sql` para transacciones
- **Parametros**: `@ParamName` (SQL Server), `p_param_name` (PostgreSQL)
