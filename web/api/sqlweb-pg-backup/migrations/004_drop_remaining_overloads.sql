-- ============================================================
-- 004_drop_remaining_overloads.sql
-- Elimina overloads obsoletos detectados por sp-contracts.test.ts
-- Regla: se conserva la versión que usa la API (callSp/callSpOut)
--        y se elimina la versión antigua acumulada.
-- ============================================================

-- 1. usp_ap_payable_applypayment
--    Conservar: JSONB  |  Eliminar: TEXT
DROP FUNCTION IF EXISTS usp_ap_payable_applypayment(
    p_cod_proveedor character varying,
    p_fecha date,
    p_request_id character varying,
    p_num_pago character varying,
    p_documentos_json text
) CASCADE;

-- 2. usp_ar_receivable_applypayment
--    Conservar: JSONB  |  Eliminar: TEXT
DROP FUNCTION IF EXISTS usp_ar_receivable_applypayment(
    p_cod_cliente character varying,
    p_fecha date,
    p_request_id character varying,
    p_num_recibo character varying,
    p_documentos_json text
) CASCADE;

-- 3. usp_cfg_country_save
--    Conservar: versión extendida (16 parámetros, usada en config/routes.ts)
--    Eliminar: versión corta (6 parámetros + 2 OUT)
DROP FUNCTION IF EXISTS usp_cfg_country_save(
    p_country_code character,
    p_country_name character varying,
    p_currency_code character,
    p_tax_authority_code character varying,
    p_fiscal_id_name character varying,
    p_is_active boolean,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) CASCADE;

-- 4. usp_hr_committee_save
--    Conservar: versión nueva (company_id, branch_id, committee_id, name...)
--    Eliminar: versión antigua (safety_committee_id, country_code, formation_date...)
DROP FUNCTION IF EXISTS usp_hr_committee_save(
    p_safety_committee_id integer,
    p_company_id integer,
    p_country_code character,
    p_committee_name character varying,
    p_formation_date date,
    p_meeting_frequency character varying,
    p_is_active boolean,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) CASCADE;

-- 5. usp_hr_medexam_save
--    Conservar: versión nueva (company_id, branch_id, exam_id...)
--    Eliminar: versión antigua (medical_exam_id, employee_id bigint, physician_name...)
DROP FUNCTION IF EXISTS usp_hr_medexam_save(
    p_medical_exam_id integer,
    p_company_id integer,
    p_employee_id bigint,
    p_employee_code character varying,
    p_employee_name character varying,
    p_exam_type character varying,
    p_exam_date date,
    p_next_due_date date,
    p_result character varying,
    p_restrictions character varying,
    p_physician_name character varying,
    p_clinic_name character varying,
    p_document_url character varying,
    p_notes character varying,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) CASCADE;

-- 6. usp_hr_payroll_upsertrun
--    Conservar: JSONB  |  Eliminar: TEXT
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertrun(
    p_company_id integer,
    p_branch_id integer,
    p_payroll_code character varying,
    p_employee_id bigint,
    p_employee_code character varying,
    p_employee_name character varying,
    p_from_date date,
    p_to_date date,
    p_total_assignments numeric,
    p_total_deductions numeric,
    p_net_total numeric,
    p_payroll_type_name character varying,
    p_user_id integer,
    p_lines_json text
) CASCADE;

-- 7. usp_hr_training_save
--    Conservar: versión nueva (company_id, branch_id, training_id, name...)
--    Eliminar: versión antigua (training_record_id, country_code, title, provider...)
DROP FUNCTION IF EXISTS usp_hr_training_save(
    p_training_record_id integer,
    p_company_id integer,
    p_country_code character,
    p_training_type character varying,
    p_title character varying,
    p_provider character varying,
    p_start_date date,
    p_end_date date,
    p_duration_hours numeric,
    p_employee_id bigint,
    p_employee_code character varying,
    p_employee_name character varying,
    p_certificate_number character varying,
    p_certificate_url character varying,
    p_result character varying,
    p_is_regulatory boolean,
    p_notes character varying,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) CASCADE;
