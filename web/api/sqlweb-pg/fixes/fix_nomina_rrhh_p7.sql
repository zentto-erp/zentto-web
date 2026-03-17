-- ============================================================
-- FIX SCRIPT PART 7: Wrapper functions for write endpoints
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================
-- Service sends these param names (via toSnakeParam):
--   usp_HR_OccHealth_Create:
--     p_company_id, p_branch_id, p_employee_code, p_record_type,
--     p_incident_date (DATE string), p_description, p_severity, p_user_id
--   usp_HR_MedExam_Save:
--     p_company_id, p_branch_id, p_exam_id, p_employee_code,
--     p_exam_type, p_exam_date, p_result, p_notes, p_next_due_date, p_user_id
--   usp_HR_Training_Save:
--     p_company_id, p_branch_id, p_training_id, p_name, p_description,
--     p_start_date, p_end_date, p_instructor, p_hours, p_participants, p_user_id
--   usp_HR_Committee_Save:
--     p_company_id, p_branch_id, p_committee_id, p_name, p_committee_type,
--     p_start_date, p_end_date, p_user_id
-- ============================================================

-- 1. Fix usp_hr_payroll_saveconstant: RETURN casts TEXT but TABLE is VARCHAR
DROP FUNCTION IF EXISTS public.usp_hr_payroll_saveconstant(INT, VARCHAR, VARCHAR, NUMERIC, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_saveconstant(
    p_company_id  INT,
    p_code        VARCHAR(60),
    p_name        VARCHAR(200)   DEFAULT NULL,
    p_value       NUMERIC(18,4)  DEFAULT NULL,
    p_source_name VARCHAR(120)   DEFAULT NULL,
    p_user_id     INT            DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConstantId" INTO v_existing_id
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id AND "ConstantCode" = p_code
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"    = COALESCE(p_name, "ConstantName"),
            "ConstantValue"   = COALESCE(p_value, "ConstantValue"),
            "SourceName"      = COALESCE(p_source_name, "SourceName"),
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "PayrollConstantId" = v_existing_id;

        RETURN QUERY SELECT v_existing_id::INT, 'Constante actualizada'::VARCHAR;
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue",
            "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_code, COALESCE(p_name, p_code), COALESCE(p_value, 0),
            p_source_name, TRUE, p_user_id, p_user_id
        );

        RETURN QUERY SELECT 1::INT, 'Constante creada'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- 2. Wrapper for usp_HR_OccHealth_Create
-- Service sends: p_company_id, p_branch_id, p_employee_code, p_record_type,
--                p_incident_date (DATE string "YYYY-MM-DD"), p_description, p_severity, p_user_id
-- Underlying function needs: p_company_id, p_country_code (required), p_record_type,
--                             p_employee_code, p_occurrence_date (TIMESTAMP), p_description,
--                             p_severity, p_created_by
-- NOTE: p_incident_date is DATE (not TIMESTAMP) to match what the service sends
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(
    INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, TEXT, VARCHAR, INTEGER
) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_record_type   VARCHAR     DEFAULT NULL,
    p_incident_date DATE        DEFAULT NULL,
    p_description   TEXT        DEFAULT NULL,
    p_severity      VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    -- Resolve country code from company
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN
        v_country_code := 'VE';
    END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_occhealth_create(
        p_company_id      := p_company_id,
        p_country_code    := v_country_code,
        p_record_type     := UPPER(COALESCE(p_record_type, 'ACCIDENT')),
        p_employee_code   := p_employee_code,
        p_occurrence_date := p_incident_date::TIMESTAMP,
        p_description     := p_description,
        p_severity        := UPPER(p_severity),
        p_created_by      := p_user_id
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- 3. Wrapper for usp_HR_MedExam_Save
-- Service sends: p_company_id, p_branch_id, p_exam_id, p_employee_code,
--                p_exam_type, p_exam_date, p_result, p_notes, p_next_due_date, p_user_id
-- Underlying function needs: p_medical_exam_id, p_company_id, p_employee_id,
--                             p_employee_code, p_employee_name (NOT NULL in table),
--                             p_exam_type, p_exam_date, p_result, p_notes, p_next_due_date
-- We look up employee name from code to satisfy NOT NULL constraint
DROP FUNCTION IF EXISTS public.usp_hr_medexam_save(
    INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, DATE, INTEGER
) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_exam_id       INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_exam_type     VARCHAR     DEFAULT NULL,
    p_exam_date     DATE        DEFAULT NULL,
    p_result        VARCHAR     DEFAULT NULL,
    p_notes         VARCHAR     DEFAULT NULL,
    p_next_due_date DATE        DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
    v_employee_id  BIGINT;
    v_employee_name VARCHAR(200);
BEGIN
    -- Look up employee info from code
    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."CompanyId" = p_company_id
    LIMIT 1;

    -- If employee not found, use code as name placeholder
    IF v_employee_name IS NULL THEN
        v_employee_name := p_employee_code;
    END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_medexam_save(
        p_medical_exam_id := p_exam_id,
        p_company_id      := p_company_id,
        p_employee_id     := v_employee_id,
        p_employee_code   := p_employee_code,
        p_employee_name   := v_employee_name,
        p_exam_type       := UPPER(COALESCE(p_exam_type, 'PERIODIC')),
        p_exam_date       := p_exam_date,
        p_result          := UPPER(COALESCE(p_result, 'PENDING')),
        p_notes           := p_notes,
        p_next_due_date   := p_next_due_date
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- 4. Wrapper for usp_HR_Training_Save
-- Service sends: p_company_id, p_branch_id, p_training_id, p_name, p_description,
--                p_start_date, p_end_date, p_instructor, p_hours, p_participants, p_user_id
-- Underlying: p_training_record_id, p_company_id, p_country_code, p_training_type,
--             p_title, p_provider, p_start_date, p_end_date, p_duration_hours,
--             p_employee_code (NOT NULL in table), p_employee_name (NOT NULL in table), p_notes
-- Training courses at company level: use 'GENERAL'/'N/A' placeholders for employee fields
DROP FUNCTION IF EXISTS public.usp_hr_training_save(
    INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, VARCHAR, NUMERIC, VARCHAR, INTEGER
) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_training_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_training_id   INTEGER     DEFAULT NULL,
    p_name          VARCHAR     DEFAULT NULL,
    p_description   VARCHAR     DEFAULT NULL,
    p_start_date    DATE        DEFAULT NULL,
    p_end_date      DATE        DEFAULT NULL,
    p_instructor    VARCHAR     DEFAULT NULL,
    p_hours         NUMERIC     DEFAULT NULL,
    p_participants  VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    -- Resolve country code from company
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN
        v_country_code := 'VE';
    END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_training_save(
        p_training_record_id := p_training_id,
        p_company_id         := p_company_id,
        p_country_code       := v_country_code,
        p_training_type      := 'TECHNICAL',
        p_title              := p_name,
        p_provider           := p_instructor,
        p_start_date         := p_start_date,
        p_end_date           := p_end_date,
        p_duration_hours     := COALESCE(p_hours, 1),
        p_employee_code      := COALESCE(p_participants, 'GENERAL'),
        p_employee_name      := COALESCE(p_participants, p_name, 'GENERAL'),
        p_notes              := p_description
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- 5. Wrapper for usp_HR_Committee_Save
-- Service sends: p_company_id, p_branch_id, p_committee_id, p_name,
--                p_committee_type, p_start_date, p_end_date, p_user_id
-- Underlying: p_safety_committee_id, p_company_id, p_country_code,
--             p_committee_name, p_formation_date, p_meeting_frequency, p_is_active
DROP FUNCTION IF EXISTS public.usp_hr_committee_save(
    INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, INTEGER
) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_save(
    p_company_id     INTEGER,
    p_branch_id      INTEGER     DEFAULT NULL,
    p_committee_id   INTEGER     DEFAULT NULL,
    p_name           VARCHAR     DEFAULT NULL,
    p_committee_type VARCHAR     DEFAULT NULL,
    p_start_date     DATE        DEFAULT NULL,
    p_end_date       DATE        DEFAULT NULL,
    p_user_id        INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code     CHAR(2);
    v_resultado        INTEGER;
    v_mensaje          VARCHAR(500);
    v_meeting_freq     VARCHAR(15);
BEGIN
    -- Resolve country code from company
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN
        v_country_code := 'VE';
    END IF;

    -- Map committee_type to meeting_frequency if it looks like a frequency
    v_meeting_freq := CASE UPPER(COALESCE(p_committee_type, ''))
        WHEN 'MONTHLY'   THEN 'MONTHLY'
        WHEN 'QUARTERLY' THEN 'QUARTERLY'
        WHEN 'BIMONTHLY' THEN 'BIMONTHLY'
        WHEN 'WEEKLY'    THEN 'WEEKLY'
        ELSE 'MONTHLY'
    END;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_committee_save(
        p_safety_committee_id := p_committee_id,
        p_company_id          := p_company_id,
        p_country_code        := v_country_code,
        p_committee_name      := p_name,
        p_formation_date      := p_start_date,
        p_meeting_frequency   := v_meeting_freq,
        p_is_active           := TRUE
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


SELECT 'PART 7 WRAPPER FIXES APPLIED SUCCESSFULLY' AS status;
