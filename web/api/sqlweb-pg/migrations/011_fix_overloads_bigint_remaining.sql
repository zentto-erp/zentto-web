-- ============================================================
-- 011_fix_overloads_bigint_remaining.sql
-- Corrige los últimos overloads duplicados y parámetros INT->BIGINT
--
-- Problemas corregidos:
--   A) Overloads exactos duplicados (pettycash — 7 funciones)
--   B) Overloads integer+bigint (hr payroll — 3 funciones)
--   C) usp_acct_account_insert.p_parent_account_id INT -> BIGINT
--   D) usp_acct_equitymovement_delete/update.p_equity_movement_id INT -> BIGINT
--   E) usp_acct_equitymovement_list "EquityMovementId" INTEGER -> BIGINT
--   F) usp_rest_admin_compra_insert.p_supplier_id INT -> BIGINT
--   G) usp_rest_admin_receta_upsert.p_ingredient_product_id INT -> BIGINT
--   H) usp_rest_admin_syncmenuproductimage.p_menu_product_id INT -> BIGINT
--   I) usp_rest_admin_compralinea_delete/getprev "ingredientProductId" INT -> BIGINT
--
-- Ejecutar desde sqlweb-pg/:
--   psql -U zentto_app -d zentto_prod -f migrations/011_fix_overloads_bigint_remaining.sql
-- ============================================================

\echo '  [011] Eliminando overloads duplicados exactos en pettycash...'

-- ── A) Pettycash — duplicados exactos: mantener el OID más alto ───────────
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT proname, MIN(oid) AS old_oid
        FROM pg_proc
        WHERE proname LIKE 'usp_fin_pettycash%'
        GROUP BY proname
        HAVING COUNT(*) > 1
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || rec.proname ||
                '(' || pg_get_function_identity_arguments(rec.old_oid) || ') CASCADE';
        RAISE NOTICE 'Dropped old OID % for %', rec.old_oid, rec.proname;
    END LOOP;
END;
$$;

\echo '  [011] Eliminando versiones INTEGER de hr payroll (manteniendo BIGINT)...'

-- ── B) HR Payroll — versiones INTEGER (mantener las BIGINT) ───────────────
DROP FUNCTION IF EXISTS usp_hr_payroll_batchaddline(integer, character varying, character varying, character varying, character varying, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_batchremoveline(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_hr_payroll_processbatch(integer, integer) CASCADE;

\echo '  [011] Corrigiendo parámetros INT->BIGINT en usp_acct...'

-- ── C) usp_acct_account_insert: p_parent_account_id INT -> BIGINT ─────────
DROP FUNCTION IF EXISTS usp_acct_account_insert(integer, character varying, character varying, character varying, integer, integer, boolean) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_account_insert(integer, character varying, character varying, character varying, integer, bigint, boolean) CASCADE;

-- ── D) usp_acct_equitymovement_delete: p_equity_movement_id INT -> BIGINT ─
DROP FUNCTION IF EXISTS usp_acct_equitymovement_delete(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_equitymovement_delete(integer, bigint) CASCADE;

-- ── D) usp_acct_equitymovement_update: p_equity_movement_id INT -> BIGINT ─
DROP FUNCTION IF EXISTS usp_acct_equitymovement_update(integer, integer, character varying, date, numeric, character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_equitymovement_update(integer, bigint, character varying, date, numeric, character varying) CASCADE;

-- ── E) usp_acct_equitymovement_list: RETURNS TABLE "EquityMovementId" INT ─
DROP FUNCTION IF EXISTS usp_acct_equitymovement_list(integer, integer, smallint) CASCADE;
DROP FUNCTION IF EXISTS usp_acct_equitymovement_list(integer, integer, integer) CASCADE;

\echo '  [011] Corrigiendo parámetros INT->BIGINT en usp_rest_admin...'

-- ── F) usp_rest_admin_compra_insert: p_supplier_id INT -> BIGINT ──────────
DROP FUNCTION IF EXISTS usp_rest_admin_compra_insert(integer, integer, character varying, integer, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_insert(integer, integer, character varying, bigint, character varying, integer) CASCADE;

-- ── G) usp_rest_admin_receta_upsert: p_ingredient_product_id INT -> BIGINT ─
DROP FUNCTION IF EXISTS usp_rest_admin_receta_upsert(integer, integer, integer, numeric, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_receta_upsert(integer, integer, bigint, numeric, character varying, character varying) CASCADE;

-- ── H) usp_rest_admin_syncmenuproductimage: p_menu_product_id INT -> BIGINT
DROP FUNCTION IF EXISTS usp_rest_admin_syncmenuproductimage(integer, integer, integer, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_syncmenuproductimage(integer, integer, bigint, character varying, integer) CASCADE;

-- ── I) usp_rest_admin_compralinea_delete: RETURNS TABLE ingredientProductId INT
DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_delete(integer, integer) CASCADE;

-- ── I) usp_rest_admin_compralinea_getprev: RETURNS TABLE ingredientProductId INT
DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_getprev(integer, integer) CASCADE;

\echo '  [011] Recreando funciones corregidas...'

\i ../includes/sp/usp_acct.sql
\i ../includes/sp/usp_rest_admin.sql

\echo '  [011] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('011_fix_overloads_bigint_remaining', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [011] COMPLETO — overloads y parámetros BIGINT corregidos'
