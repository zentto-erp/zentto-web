#!/usr/bin/env bash
# ============================================================
# run-pg-migrations.sh
# Ejecuta migraciones PostgreSQL incrementales.
# - Crea tabla public._migrations si no existe
# - Aplica solo archivos .sql en sqlweb-pg/migrations/ pendientes
# - Idempotente: salta los ya aplicados
#
# Uso:
#   PGPASSWORD=<pwd> ./run-pg-migrations.sh <user> <host> <database> <sqlweb-pg-dir>
#
# Variables de entorno requeridas:
#   PGPASSWORD
# ============================================================

set -euo pipefail

PG_USER="${1:-zentto_app}"
PG_HOST="${2:-127.0.0.1}"
PG_DB="${3:-zentto_prod}"
SQLWEB_PG_DIR="${4:-/opt/zentto/sqlweb-pg}"
MIGRATIONS_DIR="${SQLWEB_PG_DIR}/migrations"

PSQL="psql -U ${PG_USER} -h ${PG_HOST} -d ${PG_DB} -v ON_ERROR_STOP=1"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Zentto — Migraciones PostgreSQL Incrementales"
echo "  DB: ${PG_DB} @ ${PG_HOST}"
echo "══════════════════════════════════════════════════════"
echo ""

# ── 1. Garantizar tabla de control ──────────────────────────
${PSQL} -c "
  CREATE TABLE IF NOT EXISTS public._migrations (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    duration_ms INT         NOT NULL DEFAULT 0
  );
"

# ── 2. Verificar que existe el directorio de migraciones ────
if [ ! -d "${MIGRATIONS_DIR}" ]; then
  echo "[INFO] No hay directorio de migraciones en: ${MIGRATIONS_DIR}"
  echo "[INFO] Ejecutando run_all.sql como fallback..."
  ${PSQL} -f "${SQLWEB_PG_DIR}/run_all.sql"
  echo "[OK]   run_all.sql ejecutado."
  exit 0
fi

# ── 3. Obtener migraciones ya aplicadas ─────────────────────
APPLIED=$(${PSQL} -t -A -c "SELECT name FROM public._migrations ORDER BY name;")

# ── 4. Iterar archivos en orden ─────────────────────────────
TOTAL=0
APPLIED_COUNT=0
SKIPPED=0
ERRORS=0

for FILEPATH in $(ls "${MIGRATIONS_DIR}"/*.sql 2>/dev/null | sort); do
  FILENAME=$(basename "${FILEPATH}")
  TOTAL=$((TOTAL + 1))

  # Verificar si ya está aplicada
  if echo "${APPLIED}" | grep -qxF "${FILENAME}"; then
    echo "[SKIP] ${FILENAME} (ya aplicada)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Aplicar migración
  printf "[RUN]  %-50s ... " "${FILENAME}"
  START_NS=$(date +%s%N 2>/dev/null || echo 0)

  if ${PSQL} -f "${FILEPATH}" > /dev/null 2>&1; then
    END_NS=$(date +%s%N 2>/dev/null || echo 0)
    DURATION_MS=$(( (END_NS - START_NS) / 1000000 ))

    # Registrar en tabla de control
    ${PSQL} -c "
      INSERT INTO public._migrations (name, duration_ms)
      VALUES ('${FILENAME}', ${DURATION_MS})
      ON CONFLICT (name) DO NOTHING;
    " > /dev/null

    echo "✓ (${DURATION_MS}ms)"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
  else
    echo "✗"
    echo "[ERROR] Falló la migración: ${FILENAME}"
    # Mostrar el error
    ${PSQL} -f "${FILEPATH}" || true
    ERRORS=$((ERRORS + 1))
    break
  fi
done

echo ""
echo "──────────────────────────────────────────────────────"
echo "[DONE] Total: ${TOTAL} | Aplicadas: ${APPLIED_COUNT} | Saltadas: ${SKIPPED} | Errores: ${ERRORS}"
echo "══════════════════════════════════════════════════════"
echo ""

if [ "${ERRORS}" -gt 0 ]; then
  exit 1
fi
