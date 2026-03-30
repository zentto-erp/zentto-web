#!/usr/bin/env bash
# ============================================
# bootstrap-db.sh — Crear BD desde baseline
#
# Crea una base de datos PostgreSQL completa desde el baseline
# extraido con pg_dump. Usa las capas en sqlweb-pg/baseline/.
#
# Uso:
#   ./scripts/bootstrap-db.sh                    # usa defaults
#   DB_NAME=zentto_dev DB_USER=zentto_app ./scripts/bootstrap-db.sh
#   ./scripts/bootstrap-db.sh --drop             # drop + recrear
#
# Requiere: psql, acceso como superuser (postgres)
# ============================================

set -euo pipefail

DB_NAME="${DB_NAME:-zentto_dev}"
DB_USER="${DB_USER:-zentto_app}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PG_SUPER="${PG_SUPER:-postgres}"
DROP_FIRST=false

# Parse args
for arg in "$@"; do
  case $arg in
    --drop) DROP_FIRST=true ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Support both local dev (scripts/) and Docker container (/app/scripts/)
if [ -d "$SCRIPT_DIR/../sqlweb-pg/baseline" ]; then
  BASELINE_DIR="$SCRIPT_DIR/../sqlweb-pg/baseline"
  SEEDS_DIR="$SCRIPT_DIR/../sqlweb-pg/seeds"
  MIGRATIONS_DIR="$SCRIPT_DIR/../migrations/postgres"
elif [ -d "$SCRIPT_DIR/../web/api/sqlweb-pg/baseline" ]; then
  BASELINE_DIR="$SCRIPT_DIR/../web/api/sqlweb-pg/baseline"
  SEEDS_DIR="$SCRIPT_DIR/../web/api/sqlweb-pg/seeds"
  MIGRATIONS_DIR="$SCRIPT_DIR/../web/api/migrations/postgres"
else
  echo "ERROR: no se encontro baseline. Buscado en $SCRIPT_DIR/../sqlweb-pg/ y $SCRIPT_DIR/../web/api/sqlweb-pg/"
  exit 1
fi

if [ ! -d "$BASELINE_DIR" ]; then
  echo "ERROR: $BASELINE_DIR no existe"
  exit 1
fi

echo "============================================"
echo "  Zentto DB Bootstrap"
echo "  DB: $DB_NAME | User: $DB_USER | Host: $DB_HOST"
echo "============================================"

# Helper to run psql as superuser
run_super() {
  PGPASSWORD="${PG_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER" "$@"
}

run_db() {
  PGPASSWORD="${PG_PASSWORD:-}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER" -d "$DB_NAME" -v ON_ERROR_STOP=1 "$@"
}

# Step 1: Drop + Create DB (if --drop)
if [ "$DROP_FIRST" = true ]; then
  echo ""
  echo "[1/6] Dropping and recreating $DB_NAME..."
  run_super -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
  run_super -c "DROP DATABASE IF EXISTS $DB_NAME;"
  run_super -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
  echo "  OK: $DB_NAME created"
else
  echo ""
  echo "[1/6] Verificando que $DB_NAME existe..."
  if ! run_super -lqt | grep -qw "$DB_NAME"; then
    echo "  DB no existe, creando..."
    run_super -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
  fi
  echo "  OK"
fi

# Step 2: Apply baseline layers
echo ""
echo "[2/6] Aplicando baseline..."
for f in \
  "$BASELINE_DIR/000_schemas.sql" \
  "$BASELINE_DIR/001_extensions.sql" \
  "$BASELINE_DIR/002_types.sql" \
  "$BASELINE_DIR/003_tables.sql" \
  "$BASELINE_DIR/004_sequences.sql" \
  "$BASELINE_DIR/005_functions.sql" \
  "$BASELINE_DIR/006_indexes.sql" \
  "$BASELINE_DIR/007_constraints.sql" \
  "$BASELINE_DIR/008_triggers.sql" \
  "$BASELINE_DIR/009_grants.sql"
do
  fname=$(basename "$f")
  echo -n "  $fname ... "
  run_db < "$f" > /dev/null 2>&1
  echo "OK"
done

# Step 3: Apply seeds (with deferred constraints)
echo ""
echo "[3/6] Aplicando seeds..."
run_db -c "SET session_replication_role = 'replica';" > /dev/null 2>&1 || true
for f in "$SEEDS_DIR"/*.sql; do
  fname=$(basename "$f")
  echo -n "  $fname ... "
  run_db < "$f" > /dev/null 2>&1 || echo "WARN (some FK errors, non-fatal)"
  echo "OK"
done
run_db -c "SET session_replication_role = 'origin';" > /dev/null 2>&1 || true

# Step 4: Mark all goose migrations as applied
echo ""
echo "[4/6] Marcando migraciones goose como aplicadas..."
run_db -c "
  CREATE TABLE IF NOT EXISTS goose_db_version (
    id SERIAL PRIMARY KEY,
    version_id BIGINT NOT NULL,
    is_applied BOOLEAN NOT NULL DEFAULT TRUE,
    tstamp TIMESTAMP DEFAULT NOW()
  );
" > /dev/null 2>&1

LAST_VERSION=0
for mig in "$MIGRATIONS_DIR"/[0-9]*.sql; do
  ver=$(basename "$mig" | grep -oE '^[0-9]+' | sed 's/^0*//')
  if [ -n "$ver" ] && [ "$ver" -gt "$LAST_VERSION" ]; then
    LAST_VERSION=$ver
  fi
done

# Insert all versions as applied
for mig in "$MIGRATIONS_DIR"/[0-9]*.sql; do
  ver=$(basename "$mig" | grep -oE '^[0-9]+' | sed 's/^0*//')
  if [ -n "$ver" ]; then
    run_db -c "INSERT INTO goose_db_version (version_id, is_applied) SELECT $ver, true WHERE NOT EXISTS (SELECT 1 FROM goose_db_version WHERE version_id = $ver);" > /dev/null 2>&1
  fi
done
echo "  OK: $LAST_VERSION migraciones marcadas"

# Step 5: Grant permissions
echo ""
echo "[5/6] Otorgando permisos a $DB_USER..."
run_db -c "
  GRANT ALL ON ALL TABLES IN SCHEMA public TO $DB_USER;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
  GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;
  GRANT USAGE ON SCHEMA sec TO $DB_USER;
  GRANT ALL ON ALL TABLES IN SCHEMA sec TO $DB_USER;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA sec TO $DB_USER;
  GRANT USAGE ON SCHEMA cfg TO $DB_USER;
  GRANT ALL ON ALL TABLES IN SCHEMA cfg TO $DB_USER;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA cfg TO $DB_USER;
  GRANT USAGE ON SCHEMA hr TO $DB_USER;
  GRANT ALL ON ALL TABLES IN SCHEMA hr TO $DB_USER;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA hr TO $DB_USER;
  GRANT USAGE ON SCHEMA sys TO $DB_USER;
  GRANT ALL ON ALL TABLES IN SCHEMA sys TO $DB_USER;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA sys TO $DB_USER;
" > /dev/null 2>&1
echo "  OK"

# Step 6: Verify
echo ""
echo "[6/6] Verificando..."
TABLE_COUNT=$(run_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema');" 2>/dev/null | tr -d ' ')
FUNC_COUNT=$(run_db -t -c "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname LIKE 'usp_%';" 2>/dev/null | tr -d ' ')
OVERLOAD_COUNT=$(run_db -t -c "SELECT COUNT(*) FROM (SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname LIKE 'usp_%' GROUP BY p.proname HAVING COUNT(*)>1) sub;" 2>/dev/null | tr -d ' ')

echo "  Tablas: $TABLE_COUNT"
echo "  Funciones usp_*: $FUNC_COUNT"
echo "  Overloads duplicados: $OVERLOAD_COUNT"
echo ""

if [ "$OVERLOAD_COUNT" = "0" ]; then
  echo "=== BOOTSTRAP EXITOSO ==="
else
  echo "=== WARNING: hay $OVERLOAD_COUNT funciones con overloads ==="
fi
