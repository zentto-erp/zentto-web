# 07 - Compatibilidad Multi-IA (Codex/Claude/Kimi/Gemini)

## Objetivo

Usar una sola base de contexto y el mismo flujo de agentes en multiples asistentes de codigo.

## Fuente unica de contexto

Todos los asistentes deben leer primero:

1. `docs/wiki/README.md`
2. `docs/wiki/02-api.md`
3. `docs/wiki/03-frontend.md`
4. `docs/wiki/04-modular-frontend.md`
5. `docs/wiki/05-mapa-vb6-a-web.md`
6. `docs/wiki/06-playbook-agentes.md`

## Estado actual en este repo

- Codex/Copilot (VS Code): agentes y prompts en `.vscode/prompts`
- MCP: `web/mcp-agents` con `database-agent`, `api-agent`, `frontend-agent`
- Claude: `CLAUDE.md`
- Kimi: `KIMI.md`
- Gemini: `GEMINI.md`
- Skill local Codex: `C:/Users/Dell/.codex/skills/datqbox-super-orchestrator`

## Pipeline estandar para cualquier IA

1. Planner
2. Developer
3. SQL Specialist
4. QA

Formato esperado al cerrar una tarea:

- Resumen
- Archivos
- Validacion
- Riesgos
- Siguiente accion recomendada

## Compatibilidad de agentes por herramienta

### VS Code Copilot/Codex

- Usa `@DatqBox Super Planner`, `@DatqBox Super Developer`, `@DatqBox Super QA`.
- Usa `@sqlserver-agent` para SQL Server.
- Plantillas background en `.vscode/prompts/datqbox-bg-*.prompt.md`.
- En Codex Skills, invoca: `$datqbox-super-orchestrator`.

### Claude Code

- Usa `CLAUDE.md` como entrypoint.
- Referencia los mismos roles: Planner, Developer, QA, SQL.
- Reutiliza la wiki como fuente principal.

### Kimi Code

- Usa `KIMI.md` como entrypoint.
- Mismo pipeline en 4 pasos.
- No duplicar reglas fuera de la wiki.

### Gemini

- Usa `GEMINI.md` como entrypoint.
- Mismo pipeline y mismas reglas de seguridad.
- Mantener trazabilidad VB6 -> API/Frontend.

## SQL Server y credenciales

- Las credenciales viven en `web/api/.env`.
- No copiar valores en documentacion ni chats.
- El agente SQL usa esa configuracion local en tiempo de ejecucion.
