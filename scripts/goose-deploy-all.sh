#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# goose-deploy-all.sh — Migra TODAS las BDs (demo + tenants)
# Uso: PG_DATABASE=zentto_prod ./goose-deploy-all.sh
# Ejecutar como root en el servidor
# ============================================================

PG_DATABASE="${PG_DATABASE:-zentto_prod}"
SEEDS_DIR="${SEEDS_DIR:-/opt/zentto/sqlweb-pg}"

echo "╔══════════════════════════════════════════════════════╗"
echo "║  Zentto — Deploy ALL databases (demo + tenants)      ║"
echo "╚══════════════════════════════════════════════════════╝"

ERRORS=0
MIGRATED=0

# ── 1. Migrar BD principal (demo) con seeds completos ──
echo ""
echo "═══ [1/N] BD Principal: ${PG_DATABASE} (demo + seeds completos) ═══"
PG_DATABASE="$PG_DATABASE" SEEDS_DIR="$SEEDS_DIR" SEEDS_TYPE="all" /opt/zentto/goose-deploy.sh || {
  echo "ERROR: BD principal falló"
  ERRORS=$((ERRORS + 1))
}
MIGRATED=$((MIGRATED + 1))

# ── 2. Listar BDs de tenants activos ──
TENANT_DBS=$(su -c "psql -d ${PG_DATABASE} -tAc \"
  SELECT \\\"DbName\\\" FROM sys.\\\"TenantDatabase\\\"
  WHERE \\\"IsActive\\\" = TRUE AND \\\"IsDemo\\\" = FALSE
  ORDER BY \\\"CompanyId\\\"
\" 2>/dev/null" postgres || echo "")

if [ -z "$TENANT_DBS" ]; then
  echo ""
  echo "→ No hay BDs de tenants registradas (solo demo)"
else
  TOTAL=$(echo "$TENANT_DBS" | wc -l)
  echo ""
  echo "→ ${TOTAL} BDs de tenants encontradas"

  # ── 3. Migrar cada BD de tenant ──
  IDX=0
  for DB in $TENANT_DBS; do
    IDX=$((IDX + 1))
    echo ""
    echo "═══ [$((IDX + 1))/N] Tenant: ${DB} ═══"

    # goose up + seeds config (categoría A solamente)
    PG_DATABASE="$DB" SEEDS_DIR="$SEEDS_DIR" SEEDS_TYPE="config" /opt/zentto/goose-deploy.sh 2>&1 || {
      echo "ERROR: migración falló para ${DB}"
      ERRORS=$((ERRORS + 1))
      continue
    }

    MIGRATED=$((MIGRATED + 1))
    echo "✓ ${DB} migrado"
  done
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "  Resultado: ${MIGRATED} BDs migradas, ${ERRORS} errores"
echo "╚══════════════════════════════════════════════════════╝"

if [ $ERRORS -gt 0 ]; then
  echo "⚠ Hubo errores — revisar logs arriba"
  # No fallar el pipeline completo por errores en tenants individuales
fi
