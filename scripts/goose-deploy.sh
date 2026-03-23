#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# goose-deploy.sh — Ejecuta migraciones goose en producción
# Uso: PG_DATABASE=zentto_prod ./goose-deploy.sh
# Ejecutar como root en el servidor
# ============================================================

PG_DATABASE="${PG_DATABASE:-zentto_prod}"
GOOSE_DIR="${GOOSE_DIR:-/opt/zentto/migrations/postgres}"
GOOSE_URL="postgres://postgres@/${PG_DATABASE}?host=/var/run/postgresql&sslmode=disable"

# Instalar goose si no existe
if ! command -v goose &>/dev/null; then
  echo "→ Instalando goose..."
  wget -qO /usr/local/bin/goose https://github.com/pressly/goose/releases/download/v3.24.1/goose_linux_x86_64
  chmod +x /usr/local/bin/goose
fi

# Extensiones requeridas (necesita superuser)
echo "→ Asegurando extensiones PostgreSQL..."
su -c "psql -d ${PG_DATABASE} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm; CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"; CREATE EXTENSION IF NOT EXISTS btree_gin;'" postgres || true

# Grants de schemas
echo "→ Aplicando grants de schemas..."
su -c "psql -d ${PG_DATABASE} -c 'GRANT CREATE ON SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;'" postgres || true

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto — goose migrate up (PostgreSQL)  ║"
echo "╚══════════════════════════════════════════╝"

# Detectar si la BD ya existía antes de goose
# Si goose_db_version no existe, dejamos que goose la cree con 'up-to 0'
# y luego marcamos el baseline (1) como aplicado para no re-ejecutar 117K líneas
HAS_GOOSE=$(su -c "psql -d ${PG_DATABASE} -tAc \"SELECT count(*) FROM information_schema.tables WHERE table_name='goose_db_version';\"" postgres || echo "0")

if [ "$HAS_GOOSE" = "0" ]; then
  echo "→ Primera vez con goose en esta BD (existente pre-goose)"
  echo "→ Inicializando tabla goose_db_version y marcando baseline..."

  # Dejar que goose cree su tabla con el formato correcto
  su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' version" postgres 2>/dev/null || true

  # Marcar baseline (migración 00001) como ya aplicada
  su -c "psql -d ${PG_DATABASE} -c \"INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (1, true) ON CONFLICT DO NOTHING;\"" postgres

  echo "✓ Baseline marcado como aplicado (BD ya tiene todo)"
fi

# Ejecutar migraciones pendientes (solo las que vengan después de baseline)
echo "→ Ejecutando goose up..."
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' up" postgres 2>&1 || {
  echo "ERROR: goose up falló — ver errores arriba"
  echo "→ Continuando con ownership..."
}

echo ""
echo "→ Estado de migraciones:"
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' status" postgres 2>&1 || true

# Ownership de todo → zentto_app
echo "→ Transfiriendo ownership a zentto_app..."
su -c "psql -d ${PG_DATABASE} <<'EOSQL'
DO \$\$
DECLARE r RECORD; s TEXT;
BEGIN
  FOR s IN SELECT schema_name FROM information_schema.schemata
    WHERE schema_name NOT IN ('pg_catalog','information_schema','pg_toast')
  LOOP
    EXECUTE 'GRANT USAGE ON SCHEMA ' || quote_ident(s) || ' TO zentto_app';
    EXECUTE 'GRANT ALL ON ALL TABLES IN SCHEMA ' || quote_ident(s) || ' TO zentto_app';
    EXECUTE 'GRANT ALL ON ALL SEQUENCES IN SCHEMA ' || quote_ident(s) || ' TO zentto_app';
  END LOOP;
  FOR r IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' LOOP
    BEGIN EXECUTE 'ALTER FUNCTION ' || r.oid::regprocedure || ' OWNER TO zentto_app'; EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
  FOR r IN SELECT schemaname, viewname FROM pg_views WHERE schemaname NOT IN ('pg_catalog','information_schema') LOOP
    BEGIN EXECUTE 'ALTER VIEW ' || quote_ident(r.schemaname) || '.' || quote_ident(r.viewname) || ' OWNER TO zentto_app'; EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
END \$\$;
EOSQL
" postgres || true

echo "✓ Migraciones goose + ownership completados: $(date -u)"
