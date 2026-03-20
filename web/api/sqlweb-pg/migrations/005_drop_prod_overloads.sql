-- ============================================================
-- 005_drop_prod_overloads.sql
-- Elimina overloads acumulados SOLO en producción.
-- Causa: run_all.sql ejecutado multiples veces con cambios de firma.
-- ============================================================

-- ── acct period: conservar versión con p_user_id TEXT ────────
DROP FUNCTION IF EXISTS usp_acct_period_close(
    p_company_id integer, p_period_code character, p_user_id integer,
    OUT p_resultado integer, OUT p_mensaje text) CASCADE;

DROP FUNCTION IF EXISTS usp_acct_period_generateclosingentries(
    p_company_id integer, p_period_code character, p_user_id integer,
    OUT p_resultado integer, OUT p_mensaje text) CASCADE;

DROP FUNCTION IF EXISTS usp_acct_period_reopen(
    p_company_id integer, p_period_code character, p_user_id integer,
    OUT p_resultado integer, OUT p_mensaje text) CASCADE;

-- ── cfg_country_save: conservar versión con character varying ─
DROP FUNCTION IF EXISTS usp_cfg_country_save(
    p_country_code character varying, p_country_name character varying,
    p_currency_code character varying, p_currency_symbol character varying,
    p_reference_currency character varying, p_reference_currency_symbol character varying,
    p_default_exchange_rate numeric, p_prices_include_tax boolean,
    p_special_tax_rate numeric, p_special_tax_enabled boolean,
    p_tax_authority_code character varying, p_fiscal_id_name character varying,
    p_time_zone_iana character varying, p_phone_prefix character varying,
    p_sort_order integer, p_is_active boolean,
    OUT p_resultado integer, OUT p_mensaje character varying) CASCADE;

-- ── doc_salesdocument_list: conservar versión más nueva ───────
DROP FUNCTION IF EXISTS usp_doc_salesdocument_list(
    p_tipo_operacion character varying, p_page integer, p_limit integer,
    p_search character varying, p_codigo character varying,
    p_from_date timestamp without time zone, p_to_date timestamp without time zone) CASCADE;

-- ── fin_pettycash: duplicados exactos — eliminar todos y recrear ─
-- (se recrean via run_all.sql o sus archivos SP, aquí solo limpiamos)
DROP FUNCTION IF EXISTS usp_fin_pettycash_box_create(
    integer, integer, character varying, character varying, numeric, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_box_list(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_expense_add(
    integer, integer, character varying, character varying, numeric,
    character varying, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_expense_list(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_session_close(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_session_getactive(integer) CASCADE;
DROP FUNCTION IF EXISTS usp_fin_pettycash_session_open(integer, numeric, integer) CASCADE;

-- ── hr_obligation_getbycountry: conservar versión con company_id ─
DROP FUNCTION IF EXISTS usp_hr_obligation_getbycountry(
    p_country_code character, p_as_of_date date) CASCADE;

-- ── sys_notificacion_markread: conservar versión TEXT ─────────
DROP FUNCTION IF EXISTS usp_sys_notificacion_markread(
    p_ids_csv character varying) CASCADE;
