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

| Componente | Ruta | Stack |
|---|---|---|
| API | `web/api` | Node + Express + TypeScript |
| Frontend modular | `web/modular-frontend` | Monorepo micro-frontends (Next.js) |
| Contratos | `web/contracts/openapi.yaml` | OpenAPI |
| SQL Server | `web/api/sqlweb/` | SQL Server stored procedures |
| PostgreSQL | `web/api/sqlweb-pg/` | PostgreSQL functions (plpgsql) |

## Base de datos — DUAL ENGINE

Zentto soporta **dos motores** de base de datos. El switch se controla con `DB_TYPE` en `web/api/.env`:

```
DB_TYPE=sqlserver   # usa SQL Server (mssql)
DB_TYPE=postgres    # usa PostgreSQL (pg)
```

### SQL Server
- Servidor: `DELLXEONE31545`
- Base: `DatqBoxWeb`
- Scripts: `web/api/sqlweb/includes/sp/`
- Despliegue: Ejecutar scripts via SSMS con `:r` includes

### PostgreSQL
- Host: `localhost:5432`
- Base: `datqboxweb`
- Scripts: `web/api/sqlweb-pg/`
- Despliegue: `psql -U postgres -d datqboxweb -f run_all.sql`

### REGLA CRITICA: Paridad dual-DB

**Todo cambio de base de datos DEBE reflejarse en AMBOS directorios:**

| Accion | SQL Server (`sqlweb/`) | PostgreSQL (`sqlweb-pg/`) |
|--------|----------------------|--------------------------|
| Nuevo SP/funcion | `includes/sp/usp_*.sql` | `includes/sp/usp_*.sql` (plpgsql) |
| Nueva tabla | DDL en archivo numerado | DDL en archivo numerado (01-17) |
| Seed data | `includes/sp/seed_*.sql` | `includes/sp/seed_*.sql` |
| Indices | Script dedicado | Script dedicado |
| Cambio de esquema | Script ALTER verificable | Script ALTER verificable |

Si solo actualizas UNO, el otro motor queda roto. **No hay excepciones.**

### Traducciones SQL Server -> PostgreSQL

| SQL Server | PostgreSQL |
|---|---|
| `CREATE PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `DATETIME/DATETIME2` | `TIMESTAMP` |
| `INT IDENTITY(1,1)` | `INT GENERATED ALWAYS AS IDENTITY` |
| `SYSUTCDATETIME()` | `NOW() AT TIME ZONE 'UTC'` |
| `ISNULL()` | `COALESCE()` |
| `OPENJSON` | `jsonb_array_elements` |
| `BEGIN TRY/CATCH` | `EXCEPTION WHEN OTHERS THEN` |
| `N'texto'` | `'texto'` |
| `GO` | (omitir) |

## Nomenclatura del proyecto

| Contexto | Nombre |
|----------|--------|
| Producto | **Zentto** |
| Scope npm | `@zentto/*` |
| Store ecommerce | Zentto Store |
| Hardware hub | ZenttoHardwareHub |
| Fiscal agent | Zentto Fiscal Agent |
| Report engine | Zentto.JsReport |

## Pipeline de trabajo

1. **Planner** -> planifica y evalua riesgos
2. **Developer** -> implementa
3. **SQL Specialist** -> valida SQL en AMBOS motores (sqlweb + sqlweb-pg)
4. **QA** -> GO/NO-GO

## Reglas

- Siempre parametrizar queries SQL.
- Mantener contratos API documentados antes de cambios en frontend.
- Cualquier cambio de esquema debe dejar script SQL verificable en **ambos** directorios.
- No versionar secretos ni credenciales.
- SP naming: `usp_[Schema]_[Entity]_[Action]` (ambos motores).
- Output pattern: Lists usan `@TotalCount OUTPUT` (SQL Server) / columna `"TotalCount"` (PG).
- Writes usan `@Resultado, @Mensaje OUTPUT` (SQL Server) / `RETURNS TABLE("ok", "mensaje")` (PG).
- Helpers API: `callSp()`, `callSpOut()`, `callSpTx()` en `web/api/src/db/query.ts`.
- Todas las fechas en **UTC-0**. Display convierte a timezone de empresa.
