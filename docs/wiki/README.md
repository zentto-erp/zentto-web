# DatqBox Wiki Técnica

Esta wiki concentra el contexto operativo de la modernización de DatqBox, con foco en:

- API (`web/api`)
- Frontend principal (`web/frontend`)
- Frontend modular (`web/modular-frontend`)
- Trazabilidad funcional desde legado VB6

## Entrada rápida (super agentes)

Usar este flujo como entrada principal para tareas nuevas:

1. `DatqBox Super Planner` (plan y riesgos)
2. `DatqBox Super Developer` (implementación)
3. `DatqBox SQL Server Specialist` (validación SQL)
4. `DatqBox Super QA` (GO/NO-GO)

## Índice

1. [Visión General](./01-vision-general.md)
2. [API Node + Express + TypeScript](./02-api.md)
3. [Frontend Next.js](./03-frontend.md)
4. [Modular Frontend (Monorepo)](./04-modular-frontend.md)
5. [Mapa VB6 → Web/.NET](./05-mapa-vb6-a-web.md)
6. [Playbook de Agentes IA](./06-playbook-agentes.md)
7. [Compatibilidad Multi-IA (Codex/Claude/Kimi/Gemini)](./07-compatibilidad-multi-ia.md)

## Principios de trabajo

- No romper operación legacy mientras se moderniza.
- Mantener contratos claros (`web/contracts/openapi.yaml`).
- Evitar lógica de negocio en UI; moverla a casos de uso/servicios.
- No versionar secretos ni credenciales en documentación o código.
