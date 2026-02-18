# 06 - Playbook de Agentes IA

## Objetivo

Operar DatqBox con un pipeline estable de agentes para planificacion, implementacion, SQL Server y pruebas, en foreground o background.

## Entrada principal (obligatoria)

Estos son los agentes de entrada del proyecto:

- `DatqBox Super Planner` -> `.vscode/prompts/datqbox-super-planner.agent.md`
- `DatqBox Super Developer` -> `.vscode/prompts/datqbox-super-developer.agent.md`
- `DatqBox Super QA` -> `.vscode/prompts/datqbox-super-qa.agent.md`
- `DatqBox SQL Server Specialist` -> `.vscode/prompts/datqbox-sqlserver.agent.md`

Contexto fuente:

- Wiki tecnica: `docs/wiki/README.md`
- API: `web/api`
- Frontend: `web/frontend`
- Modular frontend: `web/modular-frontend`
- Mapa legacy: `docs/wiki/05-mapa-vb6-a-web.md`

## Flujo recomendado (background)

1. Planner: define fases, archivos, riesgos y criterios de aceptacion.
2. Developer: ejecuta cambios en bloques pequenos y reporta diff verificable.
3. SQL Specialist: valida impacto SQL (consultas, indices, scripts, rollback).
4. QA: emite GO/NO-GO con evidencia.

## Plantillas de trabajo en background

Ubicacion: `.vscode/prompts`

- `datqbox-bg-plan.prompt.md`
- `datqbox-bg-implement.prompt.md`
- `datqbox-bg-sql.prompt.md`
- `datqbox-bg-test.prompt.md`

## Alias MCP recomendados en VS Code

Definidos en `.vscode/settings.json`:

- `@database-agent`
- `@api-agent`
- `@frontend-agent`
- `@sqlserver-agent` (alias operativo del database-agent)

## Salida minima por agente

- Resumen corto
- Archivos tocados (si aplica)
- Riesgos abiertos
- Comandos de validacion
- Mensaje de commit sugerido (sin auto-commit)

## Seguridad

- Nunca mostrar secretos de `.env`.
- Nunca guardar credenciales en prompts o wiki.
- Confirmar antes de DDL/DML destructivo.
