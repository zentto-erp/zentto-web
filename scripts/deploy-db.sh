#!/bin/bash
# =============================================================================
# deploy-db.sh — Despliega schemas y SPs de PostgreSQL en producción
# Ejecuta todos los scripts SQL necesarios y corrige ownership.
#
# Uso:  bash scripts/deploy-db.sh
# Desde: servidor de producción (root@178.104.56.185)
# DB:    zentto_prod
# User:  zentto_app (owner de todos los objetos)
# =============================================================================

set -e

DB="zentto_prod"
OWNER="zentto_app"
SQL_DIR="/opt/zentto/sqlweb-pg"

echo "═══════════════════════════════════════════════"
echo "  Zentto DB Deploy — PostgreSQL"
echo "  Database: $DB | Owner: $OWNER"
echo "═══════════════════════════════════════════════"

# 1. Ejecutar DDL de tablas (schemas)
echo ""
echo "▶ Fase 1: DDL de tablas..."
for f in \
  09_inventory_advanced.sql \
  10_logistics.sql \
  11_crm.sql \
  12_manufacturing.sql \
  13_fleet.sql \
  18_fiscal_retenciones_schema.sql; do
  if [ -f "$SQL_DIR/$f" ]; then
    echo "  ◆ $f"
    sudo -u postgres psql -d "$DB" -f "$SQL_DIR/$f" -q 2>&1 | grep -i "error" || true
  fi
done

# 2. Ejecutar ALTERs
echo ""
echo "▶ Fase 2: ALTERs..."
for f in \
  includes/sp/alter_bank_movement_journal.sql \
  includes/sp/alter_salesdocument_addresses.sql; do
  if [ -f "$SQL_DIR/$f" ]; then
    echo "  ◆ $f"
    sudo -u postgres psql -d "$DB" -f "$SQL_DIR/$f" -q 2>&1 | grep -i "error" || true
  fi
done

# 3. Ejecutar SPs / funciones
echo ""
echo "▶ Fase 3: Stored Procedures..."
for f in \
  includes/sp/usp_inv.sql \
  includes/sp/usp_logistics.sql \
  includes/sp/usp_crm.sql \
  includes/sp/usp_crm_callcenter.sql \
  includes/sp/usp_fleet.sql \
  includes/sp/usp_mfg.sql \
  includes/sp/usp_mfg_integracion.sql \
  includes/sp/usp_rbac.sql \
  includes/sp/usp_fiscal_retenciones.sql; do
  if [ -f "$SQL_DIR/$f" ]; then
    echo "  ◆ $f"
    sudo -u postgres psql -d "$DB" -f "$SQL_DIR/$f" -q 2>&1 | grep -i "error" || true
  fi
done

# 4. Corregir ownership
echo ""
echo "▶ Fase 4: Ownership → $OWNER..."
sudo -u postgres psql -d "$DB" -q <<EOSQL
-- Schemas
DO \$\$
DECLARE s TEXT;
BEGIN
  FOR s IN SELECT schema_name FROM information_schema.schemata
    WHERE schema_name IN ('crm','logistics','inv','mfg','fleet','fiscal','hr','cfg')
  LOOP
    EXECUTE 'ALTER SCHEMA ' || quote_ident(s) || ' OWNER TO $OWNER';
  END LOOP;
END\$\$;

-- Tablas
DO \$\$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT schemaname, tablename FROM pg_tables
    WHERE schemaname IN ('crm','logistics','inv','mfg','fleet','fiscal','hr','cfg')
  LOOP
    EXECUTE 'ALTER TABLE ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename) || ' OWNER TO $OWNER';
  END LOOP;
END\$\$;

-- Funciones nuevas
DO \$\$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT p.oid::regprocedure as func FROM pg_proc p
    WHERE p.proname LIKE 'usp_crm_%' OR p.proname LIKE 'usp_fleet_%'
       OR p.proname LIKE 'usp_logistics_%' OR p.proname LIKE 'usp_mfg_%'
       OR p.proname LIKE 'usp_inv_%' OR p.proname LIKE 'usp_sec_approval%'
       OR p.proname LIKE 'usp_sec_permission%' OR p.proname LIKE 'usp_fiscal_withholding%'
       OR p.proname LIKE 'usp_fiscal_islr%' OR p.proname LIKE 'usp_cfg_taxunit%'
       OR p.proname LIKE 'usp_bank_movement_link%' OR p.proname LIKE 'usp_bank_reconciliation_getlinked%'
  LOOP
    EXECUTE 'ALTER FUNCTION ' || r.func || ' OWNER TO $OWNER';
  END LOOP;
END\$\$;

-- Grants
DO \$\$
DECLARE s TEXT;
BEGIN
  FOR s IN SELECT schema_name FROM information_schema.schemata
    WHERE schema_name IN ('crm','logistics','inv','mfg','fleet','fiscal','hr','cfg')
  LOOP
    EXECUTE 'GRANT USAGE ON SCHEMA ' || quote_ident(s) || ' TO $OWNER';
    EXECUTE 'GRANT ALL ON ALL TABLES IN SCHEMA ' || quote_ident(s) || ' TO $OWNER';
    EXECUTE 'GRANT ALL ON ALL SEQUENCES IN SCHEMA ' || quote_ident(s) || ' TO $OWNER';
  END LOOP;
END\$\$;
EOSQL

echo ""
echo "✓ Deploy completado: $(date -u)"
echo "═══════════════════════════════════════════════"
