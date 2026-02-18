# Agentes DatqBox Web

Este archivo define el esquema de agentes para `web/api`, `web/frontend` y `web/modular-frontend`.

## Entrada principal (super agentes)

- `DatqBox Super Planner`
- `DatqBox Super Developer`
- `DatqBox SQL Server Specialist`
- `DatqBox Super QA`

Ubicacion de agentes/prompts:

- `.vscode/prompts`
- `%APPDATA%/Code/User/prompts` (perfil global)

## Subagentes operativos MCP

- `@api-agent` -> scope `web/api`
- `@frontend-agent` -> scope `web/frontend` y `web/modular-frontend`
- `@database-agent` / `@sqlserver-agent` -> scope SQL Server (`web/api/.env`)

## Flujo recomendado

1. Planner define alcance y riesgos.
2. Developer implementa cambios.
3. SQL Specialist valida impacto de BD.
4. QA ejecuta validacion final y GO/NO-GO.

## Sincronizacion obligatoria

- API publica: `web/contracts/openapi.yaml`
- Estado de avance: `web/STATUS.md`
- Endpoints versionados: `/v1/*`

## Prompts background

- `datqbox-bg-plan.prompt.md`
- `datqbox-bg-implement.prompt.md`
- `datqbox-bg-sql.prompt.md`
- `datqbox-bg-test.prompt.md`

## Comandos

- Instalar todo: `npm run install:all` (en `web/`)
- Levantar stack: `npm run dev`
- Solo API: `npm run dev:api`
- Solo Frontend: `npm run dev:web`
- Verificar sync: `npm run sync:check`
