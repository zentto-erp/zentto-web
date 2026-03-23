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

# Grants de schemas
echo "→ Aplicando grants de schemas..."
su -c "psql -d ${PG_DATABASE} -c 'GRANT CREATE ON SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;'" postgres || true

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto — goose migrate up (PostgreSQL)  ║"
echo "╚══════════════════════════════════════════╝"

# Detectar si es primera vez con goose (BD existente pre-goose)
HAS_GOOSE=$(su -c "psql -d ${PG_DATABASE} -tAc \"SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='goose_db_version');\"" postgres)

if [ "$HAS_GOOSE" != "t" ]; then
  echo "→ Primera vez con goose: marcando baseline como aplicado..."
  # Crear tabla goose y marcar migración 1 (baseline) como aplicada
  su -c "psql -d ${PG_DATABASE} -c \"
    CREATE TABLE IF NOT EXISTS public.goose_db_version (
      id SERIAL PRIMARY KEY,
      version_id BIGINT NOT NULL,
      is_applied BOOLEAN NOT NULL,
      tstamp TIMESTAMP DEFAULT now()
    );
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (0, true);
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (1, true);
  \"" postgres
  echo "✓ Baseline marcado como aplicado (BD ya tiene todo)"
fi

# Ejecutar migraciones pendientes
echo "→ Ejecutando goose up..."
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' up" postgres

echo ""
echo "→ Estado de migraciones:"
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' status" postgres

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
