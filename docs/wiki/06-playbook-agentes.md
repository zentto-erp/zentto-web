# 06 - Playbook de Agentes IA

## Objetivo

Operar Zentto con un pipeline estable de agentes para planificacion, implementacion, validacion SQL dual y pruebas, en foreground o background.

## Entrada principal (obligatoria)

Estos son los agentes de entrada del proyecto:

- `Zentto Super Planner` -> `.vscode/prompts/datqbox-super-planner.agent.md`
- `Zentto Super Developer` -> `.vscode/prompts/datqbox-super-developer.agent.md`
- `Zentto Super QA` -> `.vscode/prompts/datqbox-super-qa.agent.md`
- `Zentto SQL Specialist` -> `.vscode/prompts/datqbox-sqlserver.agent.md`

Contexto fuente:

- Wiki tecnica: `docs/wiki/README.md`
- Dual database: `docs/wiki/11-dual-database.md`
- API: `web/api`
- Modular frontend: `web/modular-frontend`
- Mapa legacy: `docs/wiki/05-mapa-vb6-a-web.md`

## Flujo recomendado (background)

1. **Planner**: define fases, archivos, riesgos y criterios de aceptacion.
2. **Developer**: ejecuta cambios en bloques pequenos y reporta diff verificable.
3. **SQL Specialist**: valida impacto SQL en **AMBOS motores** (sqlweb + sqlweb-pg). Checklist obligatorio:
   - [ ] SP/funcion creada en `web/api/sqlweb/includes/sp/` (SQL Server)
   - [ ] SP/funcion creada en `web/api/sqlweb-pg/includes/sp/` (PostgreSQL)
   - [ ] `run_all.sql` de ambos motores actualizado si hay archivo nuevo
   - [ ] Probado con `DB_TYPE=sqlserver`
   - [ ] Probado con `DB_TYPE=postgres`
4. **QA**: emite GO/NO-GO con evidencia.

## Reglas para cambios SQL

Cualquier agente que modifique base de datos **DEBE**:

1. Leer `docs/wiki/11-dual-database.md` antes de empezar
2. Crear el cambio en SQL Server (`web/api/sqlweb/includes/sp/`)
3. Crear el equivalente en PostgreSQL (`web/api/sqlweb-pg/includes/sp/`)
4. Usar la tabla de traduccion de `11-dual-database.md`
5. Actualizar `run_all.sql` de ambos motores si es archivo nuevo
6. No usar `GETDATE()` ni `SYSDATETIME()` — solo `SYSUTCDATETIME()` (SQL Server) y `NOW() AT TIME ZONE 'UTC'` (PostgreSQL)

## Variable de motor en .env

```env
# web/api/.env
DB_TYPE=sqlserver   # o "postgres"
```

El switch es transparente para la API. Los services llaman `callSp()` y el helper resuelve el motor.

## Plantillas de trabajo en background

Ubicacion: `.vscode/prompts`

- `datqbox-bg-plan.prompt.md`
- `datqbox-bg-implement.prompt.md`
- `datqbox-bg-sql.prompt.md`
- `datqbox-bg-test.prompt.md`

## Alias MCP recomendados en VS Code

Definidos en `.vscode/settings.json`:

- `@database-agent` — valida SQL en ambos motores
- `@api-agent` — cambios en web/api
- `@frontend-agent` — cambios en web/modular-frontend
- `@sqlserver-agent` — alias operativo del database-agent

## Salida minima por agente

- Resumen corto
- Archivos tocados (si aplica)
- **Motor(es) de BD afectado(s)**: sqlweb, sqlweb-pg, o ambos
- Riesgos abiertos
- Comandos de validacion
- Mensaje de commit sugerido (sin auto-commit)

## Seguridad

- Nunca mostrar secretos de `.env`.
- Nunca guardar credenciales en prompts o wiki.
- Confirmar antes de DDL/DML destructivo.
- No versionar `.env` — solo `.env.example`.
