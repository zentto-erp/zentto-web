# DatqBox Web - Claude Code

## Idioma

- Toda la salida debe ser en **español**.
- Nombres de variables, funciones y código se mantienen en inglés.

## Modo de trabajo

- Usar **agentes en paralelo** siempre que las tareas sean independientes.
- Hacer cambios mínimos, trazables y verificables.
- No exponer secretos de archivos `.env`.
- No ejecutar `git push` sin confirmación explícita del usuario.
- Priorizar lógica en API/servicios, no en UI.
- Mantener trazabilidad VB6 -> API/Frontend/Modular Frontend.

## Lectura obligatoria

1. `docs/wiki/README.md`
2. `docs/wiki/02-api.md`
3. `docs/wiki/03-frontend.md`
4. `docs/wiki/04-modular-frontend.md`
5. `docs/wiki/05-mapa-vb6-a-web.md`
6. `docs/wiki/06-playbook-agentes.md`
7. `docs/wiki/07-compatibilidad-multi-ia.md`

## Estructura

| Componente | Ruta | Stack |
|---|---|---|
| API | `web/api` | Node + Express + TypeScript + mssql |
| Frontend modular | `web/modular-frontend` | Monorepo micro-frontends |
| Frontend principal | `web/frontend` | Next.js |
| Contratos | `web/contracts/openapi.yaml` | OpenAPI |
| SQL | `web/api/sqlweb/` | SQL Server scripts |

## Base de datos

- Servidor: `DELLXEONE31545`
- Usuario: `sa` / Password: `1234`
- Base: `DatqBoxWeb`

## Pipeline de trabajo

1. Planner -> planifica y evalúa riesgos
2. Developer -> implementa
3. SQL Specialist -> valida SQL
4. QA -> GO/NO-GO

## Reglas

- Siempre parametrizar queries SQL.
- Mantener contratos API documentados antes de cambios en frontend.
- Cualquier cambio de esquema debe dejar script SQL verificable.
- No versionar secretos ni credenciales.
