# Zentto — Lanzamiento Multinicho

**Estado:** Lote 1.A (Documentación) en ejecución
**Rama fuente:** `developer`
**Plan maestro:** [`../PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`](../PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md)

---

## Propósito

Carpeta viva con los entregables del plan de lanzamiento multinicho. Aquí aterrizan los artefactos que nacen del pipeline **Planner → Developer → SQL Specialist → QA** descrito en el plan maestro.

La regla de oro: *no recortamos alcance; convertimos lo ya construido en una plataforma vendible, operable y repetible.*

---

## Índice de artefactos

| Documento | Fase | Propósito |
|---|---|---|
| [`MATRIZ_COMERCIAL_V1.md`](./MATRIZ_COMERCIAL_V1.md) | Fase 1 · Stream A | Catálogo oficial de ofertas (nicho × producto × módulos × addons × precio × onboarding). |
| [`AUDIT_INTEGRACION.md`](./AUDIT_INTEGRACION.md) | Diagnóstico previo | Gaps reales del ecosistema (módulos API, platform-client, apps hermanas, OpenAPI). |
| [`DECISIONES.md`](./DECISIONES.md) | Transversal | Log inmutable de decisiones de orquestación con fecha, contexto y consecuencias. |
| [`RUNBOOK_RELEASE_ROLLBACK.md`](./RUNBOOK_RELEASE_ROLLBACK.md) | Fase 2 · Stream B | Procedimiento consolidado de release a producción y rollback en incidente. |
| [`RUNBOOK_BACKUP_RESTORE.md`](./RUNBOOK_BACKUP_RESTORE.md) | Fase 2 · Stream B | Procedimiento de respaldo PG y ensayo periódico de restore. |
| [`SEVERIDADES.md`](./SEVERIDADES.md) | Fase 2 · Stream B | Política de severidades S1–S4, responsabilidad, escalamiento y soporte inicial. |

---

## Convenciones

- **Idioma:** español. Código/identificadores en inglés cuando aplique.
- **Fechas:** formato `YYYY-MM-DD`, zona UTC-0.
- **Trazabilidad:** cada cambio material va por PR a `developer`. Nunca commit directo a `main` ni a `developer`.
- **Dual DB:** por decisión explícita del 2026-04-20 esta orquestación avanza solo sobre PostgreSQL; SQL Server se recreará en un plan dedicado posterior. Ver [`DECISIONES.md`](./DECISIONES.md) §D-002.

---

## Cómo se mantiene

1. **Planner** abre documento en esta carpeta al inicio de cada fase.
2. **Developer/SQL/QA** agregan referencias al final del documento cuando implementan algo que lo afecta.
3. **Orquestador** actualiza `DECISIONES.md` con cada cambio de alcance o dirección.
4. Cambios de fondo → PR separada a `developer`. No amendar.

---

## Referencias obligatorias

- [`../wiki/README.md`](../wiki/README.md)
- [`../wiki/02-api.md`](../wiki/02-api.md)
- [`../wiki/03-frontend.md`](../wiki/03-frontend.md)
- [`../wiki/04-modular-frontend.md`](../wiki/04-modular-frontend.md)
- [`../wiki/06-playbook-agentes.md`](../wiki/06-playbook-agentes.md)
- [`../wiki/11-dual-database.md`](../wiki/11-dual-database.md)
- [`../wiki/14-integracion-ecosistema.md`](../wiki/14-integracion-ecosistema.md)
- [`../adr/ADR-CMS-001-ecosystem-cms.md`](../adr/ADR-CMS-001-ecosystem-cms.md)
