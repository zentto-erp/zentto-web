# Runbook — Backup y Restore (PostgreSQL)

**Fecha:** 2026-04-20
**Alcance:** PostgreSQL producción en `zentto-server` (178.104.56.185). Base por tenant + base compartida `zentto_prod`.
**Contexto:** Esta orquestación avanza solo PG (ver [`DECISIONES.md` §D-002](./DECISIONES.md)). Cuando exista el plan SQL Server, este runbook se extenderá con la sección equivalente.
**Storage remoto:** Hetzner Object Storage bucket `zentto-api-backups` en Nuremberg (`nbg1.your-objectstorage.com`).

---

## 1. Inventario de lo que hay que respaldar

| Recurso | Descripción | Frecuencia mínima |
|---|---|---|
| Base `zentto_prod` | Esquema compartido + configuración global | Diario |
| Bases por tenant (`zentto_<tenantCode>`) | Datos operativos por cliente | Diario |
| Roles y ACL PG | `pg_dumpall --roles-only` | Semanal |
| Configuración nginx | `/etc/nginx/sites-available/*` | Cada cambio |
| Compose + PM2 | `/opt/zentto/docker-compose.prod.yml`, `docker/pm2.config.cjs` | Cada cambio |
| Vaultwarden | `/opt/vaultwarden/data` | Diario |
| Certificados Let's Encrypt | `/etc/letsencrypt/` | Semanal |

---

## 2. Backup diario — PostgreSQL

### 2.1 Job actual (cron en servidor)

Ejecutado por `/root/zentto-backup.sh` todos los días a las 02:00 UTC. Produce:

```
zentto-prod-YYYY-MM-DD.dump        # pg_dump -Fc de zentto_prod
zentto-<tenant>-YYYY-MM-DD.dump    # por cada tenant
roles-YYYY-MM-DD.sql               # pg_dumpall --roles-only
```

Sube a `s3://zentto-api-backups/daily/` usando `rclone` con credenciales de `secrets_hetzner_s3.md`.

### 2.2 Comando manual (emergencia o verificación)

```bash
ssh root@178.104.56.185

export PGPASSWORD=<secret>
export BKDIR=/var/backups/pg/manual-$(date -u +%Y%m%d-%H%M)
mkdir -p "$BKDIR"

# Base compartida
pg_dump -Fc -h 127.0.0.1 -U zentto_app -d zentto_prod -f "$BKDIR/zentto-prod.dump"

# Bases por tenant (lista dinámica)
psql -h 127.0.0.1 -U zentto_app -d zentto_prod -At \
  -c "SELECT \"TenantCode\" FROM cfg.\"Tenant\" WHERE \"IsActive\" = true;" |
while read tenant; do
  pg_dump -Fc -h 127.0.0.1 -U zentto_app -d "zentto_$tenant" \
          -f "$BKDIR/zentto-$tenant.dump"
done

# Roles
pg_dumpall -h 127.0.0.1 -U zentto_app --roles-only > "$BKDIR/roles.sql"

# Subir
rclone copy "$BKDIR" "hetzner-s3:zentto-api-backups/manual/$(basename $BKDIR)/"
```

### 2.3 Retención

- Daily: 30 días.
- Weekly (domingo): 12 semanas.
- Monthly (día 1): 12 meses.
- **No se borra ningún backup manual (`manual-*`) por cron.**

---

## 3. Restore — procedimiento ensayado

### 3.1 Ensayo mensual obligatorio (staging)

Cada primer lunes del mes el responsable on-call ejecuta un restore en staging y deja evidencia en `docs/lanzamiento/restore-drills/YYYY-MM.md` con:

- Backup usado (nombre + timestamp).
- Tiempo total de restore (start/end).
- `SELECT COUNT(*)` de tablas representativas antes/después.
- Cualquier error o warning.

### 3.2 Restore en staging

```bash
# Preparar servidor staging (asumir PG 16 ya instalado)
ssh root@<staging>
createdb -U postgres zentto_prod_restore

# Descargar backup
rclone copy "hetzner-s3:zentto-api-backups/daily/zentto-prod-YYYY-MM-DD.dump" /tmp/

# Restore
pg_restore -h 127.0.0.1 -U postgres -d zentto_prod_restore \
           --no-owner --no-privileges -j 4 /tmp/zentto-prod-YYYY-MM-DD.dump

# Smoke check
psql -U postgres -d zentto_prod_restore -c "SELECT COUNT(*) FROM sec.\"User\";"
psql -U postgres -d zentto_prod_restore -c "SELECT COUNT(*) FROM cfg.\"PricingPlan\";"
psql -U postgres -d zentto_prod_restore -c "SELECT COUNT(*) FROM cfg.\"Tenant\";"
```

### 3.3 Restore en producción (incidente S1)

**Prerrequisito:** autorización explícita del product owner. Cualquier restore en producción **sobrescribe** datos.

```bash
ssh root@178.104.56.185

# 1. Detener API para evitar escrituras durante restore
cd /opt/zentto && docker compose -f docker-compose.prod.yml stop api

# 2. Crear DB temporal y restaurar ahí
sudo -u postgres createdb zentto_prod_restore
rclone copy "hetzner-s3:zentto-api-backups/daily/zentto-prod-YYYY-MM-DD.dump" /tmp/
sudo -u postgres pg_restore -d zentto_prod_restore \
                 --no-owner --no-privileges -j 4 /tmp/zentto-prod-YYYY-MM-DD.dump

# 3. Smoke check
sudo -u postgres psql -d zentto_prod_restore -c "SELECT COUNT(*) FROM cfg.\"Tenant\";"

# 4. Swap (ventana corta — product owner confirma GO):
sudo -u postgres psql -c "ALTER DATABASE zentto_prod RENAME TO zentto_prod_preincident_$(date -u +%Y%m%d_%H%M);"
sudo -u postgres psql -c "ALTER DATABASE zentto_prod_restore RENAME TO zentto_prod;"

# 5. Reparar grants
sudo -u postgres psql -d zentto_prod -c "GRANT ALL PRIVILEGES ON DATABASE zentto_prod TO zentto_app;"
sudo -u postgres psql -d zentto_prod -c "ALTER DATABASE zentto_prod OWNER TO zentto_app;"

# 6. Restart API
cd /opt/zentto && docker compose -f docker-compose.prod.yml up -d api

# 7. Validación post-restore
curl -fsS https://api.zentto.net/health
curl -fsS https://api.zentto.net/v1/status
```

### 3.4 RTO y RPO objetivos

- **RTO (Recovery Time Objective):** 30 min desde autorización hasta API viva con datos restaurados.
- **RPO (Recovery Point Objective):** 24 h (backup diario) o mejor si hay WAL archiving habilitado.
- Si el incidente requiere RPO < 24 h → evaluar replicación streaming en Fase 2+.

---

## 4. Backup de infraestructura (no BD)

### 4.1 Configuración crítica

Semanal por cron desde `zentto-server`:

```bash
tar czf /var/backups/infra/nginx-$(date -u +%Y%m%d).tar.gz /etc/nginx
tar czf /var/backups/infra/compose-$(date -u +%Y%m%d).tar.gz /opt/zentto
tar czf /var/backups/infra/vaultwarden-$(date -u +%Y%m%d).tar.gz /opt/vaultwarden/data
rclone copy /var/backups/infra "hetzner-s3:zentto-api-backups/infra/"
```

### 4.2 Certificados SSL

- Renovación automática: `certbot renew` vía cron de systemd.
- Backup: copia `/etc/letsencrypt/` a bucket semanal.
- En caso de pérdida total: re-emitir con `certbot --nginx -d zentto.net -d www.zentto.net -d api.zentto.net`.

---

## 5. Verificación de integridad

Cada backup se verifica al subir al bucket:

```bash
pg_restore --list zentto-prod-YYYY-MM-DD.dump | wc -l   # debe ser > 0
sha256sum zentto-prod-YYYY-MM-DD.dump > zentto-prod-YYYY-MM-DD.dump.sha256
```

El hash se guarda junto al dump. El ensayo mensual (§3.1) verifica que el dump se restaura limpio.

---

## 6. Checklist para el ensayo mensual

- [ ] Backup del día N-1 descargado desde `hetzner-s3`.
- [ ] Hash `sha256` coincide con el archivado.
- [ ] `pg_restore --list` devuelve tabla de contenidos legible.
- [ ] Restore en staging completa sin error.
- [ ] `SELECT COUNT(*)` en `sec.User`, `cfg.Tenant`, `cfg.PricingPlan` > 0.
- [ ] Evidencia archivada en `docs/lanzamiento/restore-drills/YYYY-MM.md`.
- [ ] Issue creado en `zentto-erp/zentto-web` con label `restore-drill`.

---

## 7. Referencias

- Memoria `secrets_hetzner_s3.md` — credenciales bucket.
- Memoria `server-production.md` — detalles Hetzner CX33.
- `C:\Users\Dell\.claude\CLAUDE.md` — infra producción.
- [`RUNBOOK_RELEASE_ROLLBACK.md`](./RUNBOOK_RELEASE_ROLLBACK.md).
- [`SEVERIDADES.md`](./SEVERIDADES.md).
