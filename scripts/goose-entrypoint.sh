#!/usr/bin/env bash
set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto API — Starting with migrations   ║"
echo "╚══════════════════════════════════════════╝"

# Construir DATABASE_URL desde variables individuales si no existe
if [ -z "${DATABASE_URL:-}" ]; then
  PG_USER="${PG_USER:-zentto_app}"
  PG_PASSWORD="${PG_PASSWORD:-}"
  PG_HOST="${PG_HOST:-172.18.0.1}"
  PG_PORT="${PG_PORT:-5432}"
  PG_DATABASE="${PG_DATABASE:-zentto_prod}"
  DATABASE_URL="postgres://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}?sslmode=disable"
fi

DB_TYPE="${DB_TYPE:-postgres}"
MIGRATION_DIR="/app/migrations/${DB_TYPE}"

if [ ! -d "$MIGRATION_DIR" ]; then
  echo "WARN: No migration directory found at $MIGRATION_DIR — skipping migrations"
  exec node dist/index.js
fi

# Esperar a que la BD esté disponible (max 30s)
RETRIES=15
until goose -dir "$MIGRATION_DIR" "$DB_TYPE" "$DATABASE_URL" version 2>/dev/null; do
  RETRIES=$((RETRIES - 1))
  if [ $RETRIES -le 0 ]; then
    echo "ERROR: No se pudo conectar a la base de datos después de 30s"
    echo "→ Iniciando API sin migraciones..."
    exec node dist/index.js
  fi
  echo "Esperando base de datos... ($RETRIES intentos restantes)"
  sleep 2
done

# Ejecutar migraciones
echo "→ Ejecutando migraciones (goose up)..."
if goose -dir "$MIGRATION_DIR" "$DB_TYPE" "$DATABASE_URL" up; then
  echo "✓ Migraciones completadas exitosamente"
else
  echo "ERROR: Migraciones fallaron — revisar logs arriba"
  echo "→ Iniciando API de todas formas para no perder el contenedor..."
fi

# Mostrar estado
goose -dir "$MIGRATION_DIR" "$DB_TYPE" "$DATABASE_URL" status 2>/dev/null || true

echo "→ Iniciando API..."
exec node dist/index.js
