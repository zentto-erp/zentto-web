-- ============================================================
-- FIX SCRIPT PART 8: Resolve function overload ambiguity
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================
-- Problem: usp_hr_occhealth_create has two overloads (8-param wrapper
-- and 21-param underlying). PG cannot resolve when all params are 'unknown'.
-- Solution: Rename underlying function to usp_hr_occhealth_create_internal
-- and update the 8-param wrapper to call the internal version.
--
-- Similarly fix usp_hr_medexam_save and usp_hr_training_save if needed.
-- ============================================================

-- 1. Rename underlying usp_hr_occhealth_create (21 params) to internal name
-- First create the internal version, then drop the original
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create_internal(
    p_company_id                INTEGER,
    p_country_code              CHAR(2),
    p_record_type               VARCHAR(25),
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_occurrence_date           TIMESTAMP       DEFAULT NULL,
    p_report_deadline           TIMESTAMP       DEFAULT NULL,
    p_reported_date             TIMESTAMP       DEFAULT NULL,
    p_severity                  VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected        VARCHAR(100)    DEFAULT NULL,
    p_days_lost                 INTEGER         DEFAULT NULL,
    p_location                  VARCHAR(200)    DEFAULT NULL,
    p_description               TEXT            DEFAULT NULL,
    p_root_cause                VARCHAR(500)    DEFAULT NULL,
    p_corrective_action         VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date    DATE            DEFAULT NULL,
    p_institution_reference     VARCHAR(100)    DEFAULT NULL,
    p_document_url              VARCHAR(500)    DEFAULT NULL,
    p_notes                     VARCHAR(500)    DEFAULT NULL,
    p_created_by                INTEGER         DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no válido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no válida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- Now drop the original 21-param usp_hr_occhealth_create
-- (the 8-param wrapper still exists and will call the _internal version)
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(
    INTEGER, CHAR(2), VARCHAR(25),
    BIGINT, VARCHAR(24), VARCHAR(200),
    TIMESTAMP, TIMESTAMP, TIMESTAMP,
    VARCHAR(15), VARCHAR(100), INTEGER, VARCHAR(200), TEXT,
    VARCHAR(500), VARCHAR(500), DATE, VARCHAR(100), VARCHAR(500), VARCHAR(500), INTEGER
) CASCADE;

-- Drop any TIMESTAMP-based 8-param wrapper from prior fix runs
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(
    INTEGER, INTEGER, VARCHAR, VARCHAR, TIMESTAMP, TEXT, VARCHAR, INTEGER
) CASCADE;

-- Recreate the 8-param wrapper to call _internal
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
    FROM public.usp_hr_occhealth_create_internal(
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


-- 2. Similarly for usp_hr_medexam_save: rename underlying to _internal
-- Check if there's ambiguity issue. Service sends 10 params, underlying has 16.
-- The names differ enough (p_medical_exam_id vs p_exam_id) so no ambiguity.
-- But we test just in case.

-- 3. Similarly for usp_hr_training_save: service sends 11 params, underlying has 19.
-- Names differ (p_training_id vs p_training_record_id, p_name vs p_title).
-- No ambiguity - confirmed by successful test.

SELECT 'PART 8 OVERLOAD AMBIGUITY FIXES APPLIED' AS status;
