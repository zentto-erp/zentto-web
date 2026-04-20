# Runbook — Release y Rollback

**Fecha:** 2026-04-20
**Alcance:** `zentto-web` (API + modular-frontend) en Hetzner (`178.104.56.185`).
**Flujo oficial:** Feature branch → PR a `developer` → CI/CD dev → PR `developer` → `main` → CI/CD prod.

> Este runbook NO reemplaza los workflows de GitHub Actions; los documenta para que cualquiera pueda ejecutar o auditar un release/rollback sin ayuda. Nunca deploys manuales por SSH salvo incidente declarado con S1 activo.

---

## 1. Pre-release checklist (obligatorio antes de PR → `main`)

- [ ] PR a `developer` mergeada con CI verde (`gh pr checks`).
- [ ] Funciona en `appdev.zentto.net` / `apidev.zentto.net` con el tenant `admin.demo`.
- [ ] Migraciones goose nuevas corren limpio en dev (log sin warnings).
- [ ] Ningún secreto ni archivo `.env` en el diff.
- [ ] `docs/lanzamiento/` actualizado si el cambio afecta matriz, runbook o decisiones.
- [ ] `CHANGELOG.md` actualizado con entrada en `[Unreleased]`.
- [ ] Revisar alertas abiertas en `kibana.zentto.net` (ningún S1 vivo).
- [ ] Confirmar con product owner cuando toque pricing/catalog/license/subscriptions.

---

## 2. Release a producción

### 2.1 Disparar deploy

1. `gh pr create --base main --head developer --title "release: YYYY-MM-DD"`.
2. Esperar aprobación del product owner **(regla D-002: merge a `main` es la única acción que sí requiere confirmación explícita)**.
3. `gh pr merge --squash --delete-branch=false` (nunca `--no-verify`).
4. Observar el run en `gh run watch` — workflow `.github/workflows/deploy.yml`.

### 2.2 Validación post-deploy (≤15 min después del merge)

- [ ] `curl -fsS https://api.zentto.net/health` → `200` con `status: ok`.
- [ ] `curl -fsS https://api.zentto.net/v1/status` → todas las dependencias `ok`.
- [ ] Login con `admin.demo` en `https://zentto.net` → dashboard carga sin 500.
- [ ] Revisar `kibana.zentto.net` → sin error spike en los últimos 15 min.
- [ ] `ssh root@178.104.56.185 'docker ps --filter name=zentto --format "{{.Names}}: {{.Status}}"'` → todos `healthy`.
- [ ] `ssh root@178.104.56.185 'docker logs zentto-api --tail 50'` → ningún panic/uncaught.

### 2.3 Tarjeta de cierre

Publicar en `#releases` (o al canal operativo acordado) una tarjeta con:

```
release: YYYY-MM-DD
pr: <url>
commits: <range> (N commits)
migraciones goose: [lista | none]
afecta módulos: [pricing, catalog, ...]
validación post-deploy: OK / FAIL
alertas 15 min: [lista | none]
```

---

## 3. Rollback

### 3.1 Cuándo rollback (criterios duros)

- `GET /health` falla > 2 min consecutivos.
- Error rate > 5 % medido por `zentto-obs` en 10 min.
- Cualquier `usp_*` clave tira error sistemático nuevo (Validate/Provision/ApplyModules).
- Login no funciona para tenants sanos (no un tenant aislado).

### 3.2 Estrategia de rollback (elegir en este orden)

1. **Fix-forward (preferido).** Crear rama `fix/rollback-YYYY-MM-DD-<slug>` desde `developer`, corregir, PR → `developer` → `main`. Respeta [`feedback_fix_forward_never_amend.md`](../../C:/Users/Dell/.claude/projects/d--DatqBoxWorkspace-DatqBoxWeb/memory/feedback_fix_forward_never_amend.md). Ejecutar siempre que el tiempo estimado de fix ≤ 30 min.
2. **Re-deploy de tag anterior.** Si el fix excede 30 min:
   - `gh release list --limit 5` → identificar tag estable previo.
   - `gh workflow run deploy.yml -f ref=<tag>` *(si el workflow soporta input `ref`; si no, ver 3.3)*.
   - Validar con la sección 2.2.
3. **Rollback directo en el servidor** (solo incidente S1 activo + autorización de product owner):
   ```bash
   ssh root@178.104.56.185
   docker pull ghcr.io/zentto-erp/zentto-web/api:<tag-estable>
   docker pull ghcr.io/zentto-erp/zentto-web/frontend:<tag-estable>
   cd /opt/zentto && docker compose -f docker-compose.prod.yml up -d
   docker ps --filter name=zentto
   ```

### 3.3 Rollback de migraciones goose

- `goose down` **solo** si la migración del release es la última y el plan tiene `-- +goose Down` completo.
- Si no hay `Down` seguro, emitir **migración correctiva** fix-forward que revierta el cambio.
- Nunca `DROP TABLE` en prod sin backup confirmado de <60 min (ver [`RUNBOOK_BACKUP_RESTORE.md`](./RUNBOOK_BACKUP_RESTORE.md)).

### 3.4 Post-rollback

- [ ] Crear issue en `zentto-erp/zentto-web` con label `incident` y `post-mortem:pending`.
- [ ] Adjuntar logs de APM + Kibana del intervalo afectado.
- [ ] Abrir PR de fix en ≤24 h siguiendo el fix-forward.
- [ ] Actualizar `DECISIONES.md` en `docs/lanzamiento/` si el incidente cambia una decisión.

---

## 4. Hotfix en `main` (excepcional)

Solo aplica si `developer` está demasiado adelantado para arrastrar al fix.

1. `git checkout main && git pull`.
2. `git checkout -b hotfix/<slug>`.
3. Aplicar fix mínimo.
4. PR a `main` con etiqueta `hotfix`. Product owner aprueba.
5. **Inmediatamente después del merge**: PR `main → developer` para re-sincronizar.

**Prohibido:** `push --force` a `main`, `--no-verify`, skipear tests.

---

## 5. Lista de workflows críticos

| Workflow | Trigger | Efecto |
|---|---|---|
| `.github/workflows/deploy.yml` | push a `main` | Build + push `ghcr.io` + SSH deploy |
| `.github/workflows/deploy-dev.yml` | push a `developer` | Deploy a `*.zentto.net` dev |
| `.github/workflows/test.yml` | PR | Lint + unit + integration |
| `.github/workflows/security-dev.yml` | PR a `developer` | Semgrep `fail-on: critical` |
| `.github/workflows/security-prod.yml` | PR a `main` | Semgrep `fail-on: high` |
| `.github/workflows/db-governance.yml` | PR con cambios SQL | Valida naming SP + dual DB |

---

## 6. Contactos y escalamiento

Ver [`SEVERIDADES.md`](./SEVERIDADES.md) para rotación on-call, canales y SLAs.

---

## 7. Referencias

- `C:\Users\Dell\.claude\CLAUDE.md` — Flujo Git obligatorio.
- Memoria `feedback_fix_forward_never_amend.md`.
- Memoria `feedback_git_workflow_feature_branch.md`.
- `docs/wiki/12-infraestructura.md`.
