-- ============================================================
-- 008_fix_timestamptz_to_timestamp.sql
-- Corrige funciones que usan TIMESTAMP WITH TIME ZONE (TIMESTAMPTZ)
-- por TIMESTAMP WITHOUT TIME ZONE, conforme a política UTC-0.
--
-- Todas las fechas se almacenan en UTC-0. El display local se hace
-- en el frontend/API — nunca en la base de datos.
--
-- Ejecutar desde sqlweb-pg/:
--   psql -d datqboxweb -f migrations/008_fix_timestamptz_to_timestamp.sql
-- ============================================================

\echo '  [008] Eliminando firmas TIMESTAMPTZ obsoletas...'

-- ── fin (PettyCash) ──────────────────────────────────────────
DROP FUNCTION IF EXISTS usp_fin_pettycash_box_list(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_session_getactive(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_expense_list(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_summary_box(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_summary_session(integer) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_box_list(integer) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_session_getactive(integer) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_expense_list(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_summary(integer) CASCADE;

-- ── pay (Pasarela de pagos) ──────────────────────────────────
DROP FUNCTION IF EXISTS usp_pay_provider_get(character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_pay_companyconfig_list(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_pay_cardreader_list(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_pay_cardreader_listbycompany(integer, integer) CASCADE;

-- ── rest_admin (Restaurante) ──────────────────────────────────
DROP FUNCTION IF EXISTS usp_rest_admin_compra_list(integer, integer, character varying, timestamp with time zone, timestamp with time zone) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_list(integer, integer, character varying, timestamp without time zone, timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_header(integer) CASCADE;

-- ── ops (Inventario + Bancos + Restaurante) ───────────────────
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(bigint) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_statementline_insert(bigint, timestamp with time zone, numeric, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_statementline_insert(bigint, timestamp without time zone, numeric, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_inv_movement_list(integer, integer, integer, date, date, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_inv_movement_getbyid(bigint) CASCADE;
DROP FUNCTION IF EXISTS usp_inv_movement_listperiodsummary(integer, integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getsystemmovements(bigint, date, date) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getpendingstatements(bigint) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_movement_listbyaccount(integer, integer, bigint, date, date, integer, integer) CASCADE;

\echo '  [008] Recreando funciones con TIMESTAMP (sin zona)...'

\i ../includes/sp/usp_fin_pettycash.sql
\i ../includes/sp/usp_pay.sql
\i ../includes/sp/usp_rest_admin.sql
\i ../includes/sp/usp_ops.sql

\echo '  [008] Registrando migración...'
INSERT INTO public._migrations (id, description, applied_at)
VALUES (8, 'fix_timestamptz_to_timestamp', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (id) DO NOTHING;

\echo '  [008] COMPLETO — TIMESTAMPTZ eliminado de todas las funciones usp_*'
