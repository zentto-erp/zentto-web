-- =============================================================================
--  Migración 029: Reparar SPs de contabilidad avanzada
--  Motivo: periodos, centros-costo, recurrentes y presupuestos retornan 500
--  debido a type mismatch (character vs character(6) en PeriodCode) y a que
--  las tablas acct.FiscalPeriod, acct.CostCenter, acct.RecurringEntry no
--  existían en producción.
--  Fix: re-desplegar usp_acct_advanced.sql que tiene CREATE TABLE IF NOT EXISTS
--  y las funciones correctas. Corre DESPUÉS de fix_costcenter_period_list.sql
--  (FASE 6.5) para sobrescribir la versión bugueada con la versión correcta.
-- =============================================================================

\echo '  [029] Re-desplegando usp_acct_advanced (periodos, centros-costo, presupuestos, recurrentes)...'

\ir ../includes/sp/usp_acct_advanced.sql

\echo '  [029] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('029_fix_acct_advanced_all_sps', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [029] COMPLETO — acct_advanced re-desplegado'
