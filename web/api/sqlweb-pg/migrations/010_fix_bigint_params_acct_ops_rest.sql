-- ============================================================
-- 010_fix_bigint_params_acct_ops_rest.sql
-- Corrige parámetros INT → BIGINT en funciones de acct, ops y rest.
--
-- Entidades afectadas:
--   pos."SaleTicket".SaleTicketId     = BIGINT
--   rest."OrderTicket".OrderTicketId  = BIGINT
--   master."Customer".CustomerId      = BIGINT
--   master."Product".ProductId        = BIGINT
--   master."Supplier".SupplierId      = BIGINT
--   fin."BankMovement".BankMovementId = BIGINT
--
-- Ejecutar desde sqlweb-pg/:
--   psql -d datqboxweb -f migrations/010_fix_bigint_params_acct_ops_rest.sql
-- ============================================================

\echo '  [010] Eliminando firmas obsoletas INT para entidades BIGINT...'

-- ── acct (sale_ticket_id, order_ticket_id) ────────────────────
DROP FUNCTION IF EXISTS usp_acct_pos_getheader(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_pos_gettaxsummary(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_rest_getheader(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_rest_gettaxsummary(integer) CASCADE;

-- ── ops/pos (customer_id, product_id en parámetros y RETURNS TABLE) ──
DROP FUNCTION IF EXISTS usp_pos_waitticket_create(integer, integer, integer, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticketline_insert(bigint, integer, character varying, integer, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_saleticket_create(integer, integer, bigint, integer, integer, integer, integer, integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_saleticketline_insert(bigint, integer, character varying, numeric, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_insert(integer, integer, integer, integer, numeric, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(bigint) CASCADE;
DROP FUNCTION IF EXISTS usp_bank_movement_create(integer, bigint, character varying, character varying, numeric, timestamp without time zone, character varying, character varying, integer) CASCADE;

-- ── rest_admin (supplier_id, product_id) ────────────────────
DROP FUNCTION IF EXISTS usp_rest_admin_compra_update(integer, integer, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_adjuststock(integer, numeric) CASCADE;

\echo '  [010] Recreando funciones con tipos BIGINT correctos...'

\ir ../includes/sp/usp_acct.sql
\ir ../includes/sp/usp_ops.sql
\ir ../includes/sp/usp_rest_admin.sql

\echo '  [010] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('010_fix_bigint_params_acct_ops_rest.sql', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [010] COMPLETO — parámetros BIGINT corregidos en acct, ops, rest_admin'
