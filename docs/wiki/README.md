# Zentto Wiki Tecnica

Esta wiki concentra el contexto operativo de la plataforma Zentto (antes DatqBox), con foco en:

- API (`web/api`) — Node + Express + TypeScript
- Frontend modular (`web/modular-frontend`) — Monorepo micro-frontends Next.js
- Base de datos dual: SQL Server (`web/api/sqlweb/`) + PostgreSQL (`web/api/sqlweb-pg/`)
- Trazabilidad funcional desde legado VB6

## Entrada rapida (super agentes)

Usar este flujo como entrada principal para tareas nuevas:

1. `Zentto Super Planner` (plan y riesgos)
2. `Zentto Super Developer` (implementacion)
3. `Zentto SQL Specialist` (validacion SQL — **ambos motores**)
4. `Zentto Super QA` (GO/NO-GO)

## Indice

1. [Vision General](./01-vision-general.md)
2. [API Node + Express + TypeScript](./02-api.md)
3. [Frontend Next.js](./03-frontend.md)
4. [Modular Frontend (Monorepo)](./04-modular-frontend.md)
5. [Mapa VB6 → Web/.NET](./05-mapa-vb6-a-web.md)
6. [Playbook de Agentes IA](./06-playbook-agentes.md)
7. [Compatibilidad Multi-IA (Codex/Claude/Kimi/Gemini)](./07-compatibilidad-multi-ia.md)
8. [Fiscal Multi-pais (VE + ES Verifactu)](./08-fiscal-multipais-ve-es.md)
9. [Gobernanza de Base de Datos (Fase 1)](./09-gobernanza-bd.md)
10. [ER Integridad Creada](./10-er-integridad-creada.md)
11. [**Arquitectura Dual Database (SQL Server + PostgreSQL)**](./11-dual-database.md)
12. [**Infraestructura y CI/CD**](./12-infraestructura.md)
13. [Analisis Competitivo](./13-analisis-competitivo.md)
14. [Integracion Ecosistema](./14-integracion-ecosistema.md)
15. [Event Bus](./15-event-bus.md)
16. [**Modelo entidades CRM (Contact / Company / Deal / Lead)**](./16-crm-entities-model.md)

### Design System

- [**Design System overlay**](./DESIGN-SYSTEM.md) — cómo adoptamos el formato
  Google Stitch / `DESIGN.md` en `shared-ui` y apps. Fuente de verdad:
  `web/modular-frontend/packages/shared-ui/DESIGN.md`.

### ADRs

- [`../adr/`](../adr/) — Architecture Decision Records firmados.

## Principios de trabajo

- No romper operacion legacy mientras se moderniza.
- Mantener contratos claros (`web/contracts/openapi.yaml`).
- Evitar logica de negocio en UI; moverla a casos de uso/servicios.
- No versionar secretos ni credenciales en documentacion o codigo.
- **Todo cambio SQL debe reflejarse en AMBOS motores** (sqlweb + sqlweb-pg). Ver [11-dual-database.md](./11-dual-database.md).
