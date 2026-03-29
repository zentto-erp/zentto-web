#!/usr/bin/env bash
set -euo pipefail

# Zentto — Database Migration Runner (goose)
# Uso: ./scripts/migrate.sh [up|down|status|version|redo]
# Requiere: DB_TYPE (postgres|sqlserver), DATABASE_URL

COMMAND="${1:-up}"
GOOSE_BIN="${GOOSE_BIN:-goose}"

if [ -z "${DB_TYPE:-}" ]; then
  echo "ERROR: DB_TYPE no definido (postgres o sqlserver)"
  exit 1
fi

if [ "$DB_TYPE" = "postgres" ]; then
  DRIVER="postgres"
  DIR="web/api/migrations/postgres"
  URL="${DATABASE_URL:-postgres://${PG_USER:-zentto_app}:${PG_PASSWORD}@${PG_HOST:-127.0.0.1}:${PG_PORT:-5432}/${PG_DATABASE:-zentto_prod}?sslmode=disable}"
elif [ "$DB_TYPE" = "sqlserver" ]; then
  DRIVER="mssql"
  DIR="web/api/migrations/sqlserver"
  URL="${DATABASE_URL:-sqlserver://${MSSQL_USER:-sa}:${MSSQL_PASSWORD}@${MSSQL_HOST:-localhost}:${MSSQL_PORT:-1433}?database=${MSSQL_DATABASE:-DatqBoxWeb}}"
else
  echo "ERROR: DB_TYPE debe ser 'postgres' o 'sqlserver', got: $DB_TYPE"
  exit 1
fi

# Si estamos en Docker, el directorio es diferente
if [ -d "/app/migrations" ]; then
  DIR="/app/migrations/$DB_TYPE"
elif [ -d "$(dirname "$0")/../web/api/migrations" ]; then
  DIR="$(dirname "$0")/../web/api/migrations/$( [ "$DB_TYPE" = "postgres" ] && echo postgres || echo sqlserver )"
fi

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto — goose migrate: $COMMAND"
echo "║  Driver: $DRIVER"
echo "║  Dir: $DIR"
echo "╚══════════════════════════════════════════╝"

exec "$GOOSE_BIN" -dir "$DIR" "$DRIVER" "$URL" "$COMMAND"
