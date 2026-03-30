-- +goose Up
-- Drop old HR function signatures that conflict with the new ones (different param types).
-- These old signatures were defined in 03_hr.sql with country_code/is_active params,
-- while the new versions use p_search/p_offset/p_limit.

DROP FUNCTION IF EXISTS public.usp_hr_committee_list(integer, character, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(integer, character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(integer, character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(character, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(character, character varying, boolean, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(integer, character varying, character varying, character varying, character, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(integer, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_training_list(integer, character varying, character varying, character, boolean, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(integer, integer, smallint, character varying, character varying, integer, integer) CASCADE;

-- +goose Down
-- No-op: old overloads should not be restored
