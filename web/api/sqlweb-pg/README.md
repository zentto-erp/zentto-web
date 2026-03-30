# sqlweb-pg — PostgreSQL Baseline

Esquema completo de la base de datos PostgreSQL `zentto_dev`, extraido via `pg_dump` el 2026-03-30.

## Estructura

```
sqlweb-pg/
├── baseline/
│   ├── 000_schemas.sql          # 22 schemas (acct, ap, ar, cfg, inv, sec, ...)
│   ├── 001_extensions.sql       # btree_gin, pg_trgm, pgcrypto, unaccent, uuid-ossp
│   ├── 002_types.sql            # Custom types (ninguno actualmente)
│   ├── 003_tables.sql           # 256 tablas + 18 vistas
│   ├── 004_sequences.sql        # 42 secuencias + OWNED BY + SET DEFAULT
│   ├── 005_functions.sql        # 1087 funciones PL/pgSQL (usp_*, fn_*, trg_*)
│   ├── 006_indexes.sql          # 226 indices
│   ├── 007_constraints.sql      # 829 constraints (PK, FK, UNIQUE, CHECK)
│   ├── 008_triggers.sql         # 42 triggers + 3 rules (legacy views)
│   └── 009_grants.sql           # Permisos (vacio — gestionado por rol de conexion)
├── seeds/
│   └── 001_seed_data.sql        # Datos de referencia y demo (3161 INSERTs)
└── README.md
```

## Uso

### Crear la BD desde cero (desarrollo local)

```bash
createdb zentto_dev
psql zentto_dev < baseline/000_schemas.sql
psql zentto_dev < baseline/001_extensions.sql
psql zentto_dev < baseline/002_types.sql
psql zentto_dev < baseline/003_tables.sql
psql zentto_dev < baseline/004_sequences.sql
psql zentto_dev < baseline/005_functions.sql
psql zentto_dev < baseline/006_indexes.sql
psql zentto_dev < baseline/007_constraints.sql
psql zentto_dev < baseline/008_triggers.sql
psql zentto_dev < baseline/009_grants.sql
psql zentto_dev < seeds/001_seed_data.sql
```

### Orden de ejecucion

El orden numerico de los archivos respeta las dependencias:
1. Schemas primero (todo lo demas depende de schemas)
2. Extensions (funciones pueden depender de pgcrypto, etc.)
3. Types (tablas pueden usar tipos custom)
4. Tables + Views (requieren schemas)
5. Sequences + Defaults (requieren tablas)
6. Functions (pueden referenciar tablas)
7. Indexes (requieren tablas)
8. Constraints (requieren tablas, secuencias)
9. Triggers (requieren tablas, funciones)
10. Grants (ultimo)

## Reglas importantes

### Este baseline es de SOLO LECTURA

**NO modificar estos archivos para deploys.** Este baseline es una foto del esquema al 2026-03-30.
Todo cambio incremental va como migracion goose:

```
web/api/migrations/postgres/NNNNN_descripcion.sql
```

### Dual database

Cada cambio SQL debe reflejarse en AMBOS motores:
- PostgreSQL: `web/api/sqlweb-pg/` + migracion goose
- SQL Server: `web/api/sqlweb/includes/sp/`

### Naming conventions

- Funciones: `usp_[schema]_[entity]_[action]` (ej: `usp_inv_product_list`)
- Triggers: `trg_[schema]_[table]_[purpose]` (ej: `trg_cfg_Company_updated_at`)
- Indices: `IX_[schema]_[table]_[columns]` (ej: `IX_acct_JE_Date`)

## Origen

Extraido de la base `zentto_dev` en produccion (`178.104.56.185:5432`) usando:

```bash
pg_dump -Fc --no-owner --no-acl zentto_dev > zentto_dev.dump
pg_restore --section=pre-data -f pre-data.sql zentto_dev.dump
pg_restore --section=post-data -f post-data.sql zentto_dev.dump
pg_restore --section=data -f seed-data.sql zentto_dev.dump
```
