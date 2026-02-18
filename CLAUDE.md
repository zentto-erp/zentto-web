# DatqBox - Contexto para Claude Code

Usar este archivo como entrada operativa de Claude para este repo.

## Lectura inicial obligatoria

1. `docs/wiki/README.md`
2. `docs/wiki/02-api.md`
3. `docs/wiki/03-frontend.md`
4. `docs/wiki/04-modular-frontend.md`
5. `docs/wiki/05-mapa-vb6-a-web.md`
6. `docs/wiki/06-playbook-agentes.md`
7. `docs/wiki/07-compatibilidad-multi-ia.md`

## Pipeline de trabajo (equivalencia de agentes)

1. Planner -> `DatqBox Super Planner`
2. Developer -> `DatqBox Super Developer`
3. SQL -> `DatqBox SQL Server Specialist`
4. QA -> `DatqBox Super QA`

## Reglas

- Hacer cambios minimos, trazables y verificables.
- No exponer secretos de `web/api/.env`.
- No ejecutar commit/push automatico.
- Priorizar logica en API/servicios, no en UI.
- Mantener trazabilidad VB6 -> API/Frontend/Modular Frontend..
