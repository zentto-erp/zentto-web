# Política de Severidades y Soporte Inicial

**Fecha:** 2026-04-20
**Alcance:** ecosistema Zentto en producción (API, modular-frontend, apps hermanas, notify, auth, report, landings).
**Vigencia:** hasta que se publique una política formal aprobada por product owner.

> Esta política existe para evitar tratar todo como "urgente" cuando hay varios clientes en paralelo. La severidad la declara el **responsable on-call** a la luz del impacto real, no el cliente ni el reportante.

---

## 1. Definiciones de severidad

| Severidad | Definición | Ejemplos | SLA de respuesta | SLA de resolución |
|---|---|---|---|---|
| **S1 — Crítico** | Producto caído, datos en riesgo, pérdida monetaria directa, o múltiples tenants afectados. | `api.zentto.net` 5xx > 2 min; login roto para todos; pagos Paddle no llegan; BD no responde. | 15 min, 24×7 | 4 h hábiles |
| **S2 — Alto** | Funcionalidad crítica de un tenant roto pero con workaround; o regresión comercial en módulo vendido. | Facturación no calcula IVA en un tenant; cliente no puede crear factura pero sí operar el resto; sync Paddle atorado para un plan. | 1 h hábil | 1 día hábil |
| **S3 — Medio** | Bug molesto sin workaround evidente o con impacto parcial. | Dashboard no carga un chart; filtro de tabla ignora un campo; email de bienvenida no se envía. | 1 día hábil | 1 semana |
| **S4 — Bajo** | Mejora, typo, estado visual, feature request, caso raro. | Icono desalineado; texto truncado; nueva columna solicitada. | 3 días hábiles | Siguiente release programado |

**Regla de oro.** Si dudas entre dos niveles, sube uno. Se reclasifica después con evidencia.

---

## 2. Quién declara y quién resuelve

| Rol | Responsable | Canal |
|---|---|---|
| Receptor inicial | Primer on-call (rotación) | `#soporte` + email `info@zentto.net` |
| Triaje y clasificación | On-call | Issue en `zentto-erp/zentto-web` con label `sev-1..4` |
| Resolución técnica | Claude Code + developer asignado | PR fix-forward a `developer` |
| Validación | QA | Comentario en el issue con evidencia |
| Comunicación al cliente | On-call | Email desde `info@zentto.net` o plataforma acordada |

---

## 3. Flujo operativo por severidad

### 3.1 S1 — Crítico

1. Detectado (alerta APM o cliente).
2. On-call abre issue `sev-1` + crea thread en `#incidents`.
3. Mitigación inmediata (rollback — ver [`RUNBOOK_RELEASE_ROLLBACK.md`](./RUNBOOK_RELEASE_ROLLBACK.md) §3).
4. Notificar al product owner en ≤15 min.
5. Comunicación formal a clientes afectados en ≤30 min.
6. Post-mortem obligatorio en ≤48 h. Se archiva en `docs/lanzamiento/post-mortems/YYYY-MM-DD-<slug>.md`.

### 3.2 S2 — Alto

1. On-call abre issue `sev-2`.
2. Fix asignado al siguiente día hábil.
3. Workaround comunicado al cliente en ≤1 h hábil.
4. Validación QA antes de cerrar.

### 3.3 S3 — Medio

1. Issue `sev-3` en backlog.
2. Entra al próximo sprint o release.

### 3.4 S4 — Bajo

1. Issue `sev-4` en backlog con label `good-first-issue` cuando aplique.
2. Resolución oportunista.

---

## 4. Canales oficiales

| Propósito | Canal |
|---|---|
| Incidentes en vivo | `#incidents` |
| Alertas automáticas | `#alerts` (feed APM + Kibana) |
| Coordinación release | `#releases` |
| Soporte de clientes | `#soporte` + `info@zentto.net` |
| Tickets técnicos | GitHub Issues en `zentto-erp/zentto-web` con label correspondiente |

**Jira no está activo** (ver memoria `secrets_jira.md`). El tracker oficial es **GitHub Issues** (ver [`DECISIONES.md` §D-007](./DECISIONES.md)).

---

## 5. Rotación on-call (inicial)

Hasta que exista equipo formal de soporte, la rotación es:

- **Primary on-call:** Raúl González (`raulgonzalezdev`).
- **Secondary:** Claude Code (asistente automatizado, resuelve S3/S4 y prepara fix-forward de S1/S2 bajo supervisión).

Cuando se escale el equipo, esta sección se reemplaza con rotación semanal documentada en `docs/lanzamiento/oncall-schedule.md`.

---

## 6. Métricas mínimas a observar

Panel operativo (ver Fase 2 / gap G-08 en [`AUDIT_INTEGRACION.md`](./AUDIT_INTEGRACION.md)) debe mostrar al menos:

- Error rate 5xx por app y por tenant (últimos 15 min / 1 h / 24 h).
- p95 latencia de `/v1/status`, `/api/auth/login`, `/v1/catalog/plans`.
- Jobs Kafka con `consumer lag > 1000`.
- Webhooks Paddle fallidos en las últimas 24 h.
- Migraciones goose pendientes por tenant.
- Certificados SSL con expiración < 14 días.

---

## 7. Comunicación externa

Plantillas mínimas (se ampliarán en notify con templates por-nicho, ver G-09):

### S1 en vivo

> Estamos atendiendo un incidente en Zentto que afecta <alcance>. El equipo está trabajando en la mitigación. Daremos el siguiente update en <15|30|60> min. Hora del reporte: YYYY-MM-DD HH:MM UTC.

### S1 resuelto

> El incidente reportado a las HH:MM UTC ha sido resuelto a las HH:MM UTC. <resumen breve>. El post-mortem estará disponible en <48 h>.

### S2 con workaround

> Identificamos una regresión en <módulo> que afecta a <alcance>. Mientras preparamos el fix (ETA: <día hábil>), el workaround es: <workaround>.

---

## 8. Escalamiento

- Si el on-call primary no responde en el SLA de respuesta, escalamiento automático al product owner.
- Si la severidad inicial resulta subestimada, reclasificar y notificar el salto explícitamente.

---

## 9. Referencias

- [`RUNBOOK_RELEASE_ROLLBACK.md`](./RUNBOOK_RELEASE_ROLLBACK.md)
- [`RUNBOOK_BACKUP_RESTORE.md`](./RUNBOOK_BACKUP_RESTORE.md)
- [`AUDIT_INTEGRACION.md`](./AUDIT_INTEGRACION.md) — gap G-08 (dashboard por tenant).
- Memoria `feedback_support_workflow.md`.
