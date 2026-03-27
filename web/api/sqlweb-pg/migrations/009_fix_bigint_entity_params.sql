-- ============================================================
-- 009_fix_bigint_entity_params.sql
-- Corrige parámetros de funciones que usan INTEGER para IDs
-- de entidades cuyas PKs son BIGINT en el DDL real.
--
-- Entidades afectadas:
--   hr."PayrollBatch".BatchId         = BIGINT
--   hr."PayrollBatchLine".LineId       = BIGINT
--   master."Product".ProductId        = BIGINT
--   fin."BankMovement".BankMovementId  = BIGINT
--
-- Ejecutar desde sqlweb-pg/:
--   psql -d datqboxweb -f migrations/009_fix_bigint_entity_params.sql
-- ============================================================

\echo '  [009] Eliminando firmas obsoletas INTEGER para entidades BIGINT...'

-- ── hr (Nómina - PayrollBatch) ────────────────────────────────
DROP FUNCTION IF EXISTS usp_hr_payroll_generatedraft(integer, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_batchaddline(integer, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_savedraftline(integer, integer, integer, numeric, boolean) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_batchremoveline(integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_getdraftsummary_header(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_getdraftsummary_bydept(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_getdraftsummary_alerts(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_getdraftgrid(integer, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_getemployeelines(integer, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_approvedraft(integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_processbatch(integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_batchbulkupdate(integer, integer, character varying, integer) CASCADE;

-- ── rest_admin (Restaurante) ──────────────────────────────────
DROP FUNCTION IF EXISTS usp_rest_admin_producto_upsert(integer, integer, integer, bigint, character varying, character varying, numeric, boolean, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_upsert(integer, integer, integer, integer, bigint, numeric, numeric, character varying, integer) CASCADE;

-- ── bancos (BankMovement) ────────────────────────────────────
DROP FUNCTION IF EXISTS sp_get_movimiento_bancario_by_id(integer) CASCADE;
DROP FUNCTION IF EXISTS sp_get_movimiento_bancario_by_id(bigint) CASCADE;
DROP FUNCTION IF EXISTS spgetmovimientobancariobyid(integer) CASCADE;
DROP FUNCTION IF EXISTS spgetmovimientobancariobyid(bigint) CASCADE;

\echo '  [009] Recreando funciones con tipos BIGINT correctos...'

\ir ../includes/sp/sp_nomina_batch.sql
\ir ../includes/sp/usp_rest_admin.sql
\ir ../includes/sp/sp_bancos_conciliacion.sql

\echo '  [009] Registrando migración...'
INSERT INTO public._migrations (id, description, applied_at)
VALUES (9, 'fix_bigint_entity_params', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (id) DO NOTHING;

\echo '  [009] COMPLETO — parámetros de entidades BIGINT corregidos'
