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

# Hotfix: ejecutar SQL directo para columnas/funciones faltantes
# SKIP_HOTFIX=1 omite hotfixes (útil para entornos dev con BD nueva)
HOTFIX_SQL="/opt/zentto/hotfix-sec-functions.sql"
if [ "${SKIP_HOTFIX:-0}" != "1" ] && [ -f "$HOTFIX_SQL" ]; then
  echo "→ Ejecutando hotfix SQL..."
  su -c "psql -d ${PG_DATABASE} -v ON_ERROR_STOP=1 -f ${HOTFIX_SQL}" postgres 2>&1
  echo "✓ Hotfix SQL ejecutado"
elif [ "${SKIP_HOTFIX:-0}" = "1" ]; then
  echo "→ Hotfix SQL omitido (SKIP_HOTFIX=1)"
fi

# Debug: verificar funciones sec
DEBUG_SQL="/opt/zentto/debug-sec-function.sql"
if [ -f "$DEBUG_SQL" ]; then
  echo "→ Debug sec functions..."
  su -c "psql -d ${PG_DATABASE} -f ${DEBUG_SQL}" postgres 2>&1 || true
fi

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto — goose migrate up (PostgreSQL)  ║"
echo "╚══════════════════════════════════════════╝"

# Asegurar que goose_db_version tiene baseline marcado como aplicado
# La BD de producción ya tiene todo — no queremos re-ejecutar el baseline de 117K líneas
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' version" postgres 2>/dev/null || true

# Marcar baseline (1) y migraciones conocidas como aplicadas
BASELINE_APPLIED=$(su -c "psql -d ${PG_DATABASE} -tAc \"SELECT count(*) FROM public.goose_db_version WHERE version_id = 1 AND is_applied = true;\"" postgres 2>/dev/null || echo "0")
if [ "$BASELINE_APPLIED" = "0" ]; then
  echo "→ Marcando baseline + migraciones existentes como aplicadas..."
  su -c "psql -d ${PG_DATABASE} -c \"
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (1, true) ON CONFLICT DO NOTHING;
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (2, true) ON CONFLICT DO NOTHING;
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (3, true) ON CONFLICT DO NOTHING;
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (4, true) ON CONFLICT DO NOTHING;
    INSERT INTO public.goose_db_version (version_id, is_applied) VALUES (5, true) ON CONFLICT DO NOTHING;
  \"" postgres
  echo "✓ Migraciones 1-5 marcadas como aplicadas"
fi

# Ejecutar migraciones pendientes (solo las que vengan después de baseline)
echo "→ Ejecutando goose up..."
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' up" postgres 2>&1

echo ""
echo "→ Estado de migraciones:"
su -c "goose -dir ${GOOSE_DIR} postgres '${GOOSE_URL}' status" postgres 2>&1 || true

# Seeds idempotentes — se ejecutan SIEMPRE en cada deploy
# SEEDS_TYPE=config → solo run-seeds-config.sql (categoría A: config)
# SEEDS_TYPE=all   → run-seeds.sql (categorías A+B+C: config+starter+demo)
SEEDS_DIR="${SEEDS_DIR:-/opt/zentto/sqlweb-pg}"
SEEDS_TYPE="${SEEDS_TYPE:-all}"
if [ "$SEEDS_TYPE" = "config" ]; then
  SEEDS_FILE="${SEEDS_DIR}/run-seeds-config.sql"
else
  SEEDS_FILE="${SEEDS_DIR}/run-seeds.sql"
fi
if [ -f "$SEEDS_FILE" ]; then
  echo ""
  echo "→ Ejecutando seeds idempotentes (tipo: ${SEEDS_TYPE})..."
  cd "$SEEDS_DIR"
  su -c "psql -d ${PG_DATABASE} -v ON_ERROR_STOP=1 -f $(basename ${SEEDS_FILE})" postgres 2>&1
  echo "✓ Seeds ejecutados (${SEEDS_TYPE})"
else
  echo "WARN: No se encontró ${SEEDS_FILE} — saltando seeds"
fi

# Re-crear TODAS las funciones (CREATE OR REPLACE — fix text vs varchar)
FUNCTIONS_FILE="${SEEDS_DIR}/run-functions.sql"
if [ -f "$FUNCTIONS_FILE" ]; then
  echo ""
  echo "-> Recreando TODAS las funciones PostgreSQL..."
  cd "$SEEDS_DIR"
  su -c "psql -d ${PG_DATABASE} -v ON_ERROR_STOP=1 -f run-functions.sql" postgres 2>&1
  echo "OK Funciones recreadas"
fi

echo "-> Verificando contratos criticos de funciones..."
cat <<'EOSQL' | su -c "psql -d ${PG_DATABASE} -v ON_ERROR_STOP=1" postgres 2>&1
DO $$
DECLARE
  overload_count integer;
  fn_name text;
  required_functions text[] := ARRAY[
    'usp_sec_user_authenticate',
    'usp_cfg_resolvecontext',
    'usp_cfg_fiscal_getconfig',
    'usp_sys_backup_create',
    'usp_sys_backup_complete',
    'usp_sys_backup_fail',
    'usp_sys_backup_list',
    'usp_sys_resource_audit',
    'usp_sys_cleanup_scan',
    'usp_sys_cleanup_list',
    'usp_sys_cleanup_process'
  ];
  -- Note: shipping functions live in logistics schema, not public
  -- They are verified separately if needed
BEGIN
  SELECT COUNT(*) INTO overload_count
  FROM (
    SELECT p.proname
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname LIKE 'usp_%'
    GROUP BY p.proname
    HAVING COUNT(*) > 1
  ) overloads;

  IF overload_count > 0 THEN
    RAISE NOTICE 'Funciones con overloads duplicados:';
    FOR fn_name IN
      SELECT p.proname || ' (' || COUNT(*) || ' versiones)'
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname LIKE 'usp_%'
      GROUP BY p.proname
      HAVING COUNT(*) > 1
      ORDER BY p.proname
    LOOP
      RAISE NOTICE '  - %', fn_name;
    END LOOP;
    RAISE EXCEPTION 'Hay % funciones usp_* con overloads duplicados', overload_count;
  END IF;

  FOREACH fn_name IN ARRAY required_functions LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = fn_name
    ) THEN
      RAISE EXCEPTION 'Falta la funcion critica %', fn_name;
    END IF;
  END LOOP;
END $$;
EOSQL

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
