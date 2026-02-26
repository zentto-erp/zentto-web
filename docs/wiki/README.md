# DatqBox Wiki TÃ©cnica

Esta wiki concentra el contexto operativo de la modernizaciÃ³n de DatqBox, con foco en:

- API (`web/api`)
- Frontend principal (`web/frontend`)
- Frontend modular (`web/modular-frontend`)
- Trazabilidad funcional desde legado VB6

## Entrada rÃ¡pida (super agentes)

Usar este flujo como entrada principal para tareas nuevas:

1. `DatqBox Super Planner` (plan y riesgos)
2. `DatqBox Super Developer` (implementaciÃ³n)
3. `DatqBox SQL Server Specialist` (validaciÃ³n SQL)
4. `DatqBox Super QA` (GO/NO-GO)

## Ãndice

1. [VisiÃ³n General](./01-vision-general.md)
2. [API Node + Express + TypeScript](./02-api.md)
3. [Frontend Next.js](./03-frontend.md)
4. [Modular Frontend (Monorepo)](./04-modular-frontend.md)
5. [Mapa VB6 â†’ Web/.NET](./05-mapa-vb6-a-web.md)
6. [Playbook de Agentes IA](./06-playbook-agentes.md)
7. [Compatibilidad Multi-IA (Codex/Claude/Kimi/Gemini)](./07-compatibilidad-multi-ia.md)
8. [Fiscal Multi-pais (VE + ES Verifactu)](./08-fiscal-multipais-ve-es.md)
9. [Gobernanza de Base de Datos (Fase 1)](./09-gobernanza-bd.md)

## Principios de trabajo

- No romper operaciÃ³n legacy mientras se moderniza.
- Mantener contratos claros (`web/contracts/openapi.yaml`).
- Evitar lÃ³gica de negocio en UI; moverla a casos de uso/servicios.
- No versionar secretos ni credenciales en documentaciÃ³n o cÃ³digo.


