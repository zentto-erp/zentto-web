-- ============================================================
-- FIX SCRIPT PART 5: Vacation request aliases with proper return types
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- Alias approve with TABLE return type
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_approve(BIGINT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_approve(
    p_request_id    BIGINT,
    p_approved_by   VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE("RequestId" BIGINT, "Status" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."RequestId", r."Status"
    FROM public.usp_hr_vacation_request_approve(p_request_id, p_approved_by) r;
END;
$$;

-- Alias reject with TABLE return type
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_reject(BIGINT, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_reject(
    p_request_id        BIGINT,
    p_approved_by       VARCHAR(50) DEFAULT NULL,
    p_rejection_reason  VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("RequestId" BIGINT, "Status" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."RequestId", r."Status"
    FROM public.usp_hr_vacation_request_reject(p_request_id, p_approved_by, p_rejection_reason) r;
END;
$$;

-- Alias cancel with TABLE return type
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_cancel(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_cancel(
    p_request_id    BIGINT
)
RETURNS TABLE("RequestId" BIGINT, "Status" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."RequestId", r."Status"
    FROM public.usp_hr_vacation_request_cancel(p_request_id) r;
END;
$$;

-- Alias process with TABLE return type
-- Server: usp_hr_vacation_request_process(p_request_id bigint, p_vacation_id bigint)
-- Service calls: process(RequestId, VacationId) -> p_request_id, p_vacation_id
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_process(BIGINT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_process(
    p_request_id    BIGINT,
    p_vacation_id   BIGINT
)
RETURNS TABLE("RequestId" BIGINT, "Status" VARCHAR, "VacationId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."RequestId", r."Status", r."VacationId"
    FROM public.usp_hr_vacation_request_process(p_request_id, p_vacation_id) r;
END;
$$;

-- Alias create vacation request
-- Server: usp_hr_vacation_request_create(p_company_id, p_branch_id, p_employee_code, p_start_date, p_end_date, p_total_days, p_is_partial, p_notes, p_days jsonb)
-- Service passes Days as XML: <days><d dt="..." tp="..."/></days>
-- query.ts adaptParamsForPg only converts *Xml keys, not *Xml values
-- Need to handle XML->JSON conversion in the alias function
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_create(INTEGER, INTEGER, VARCHAR, DATE, DATE, INTEGER, BOOLEAN, VARCHAR, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_create(
    p_company_id        INTEGER,
    p_branch_id         INTEGER,
    p_employee_code     VARCHAR(30),
    p_start_date        DATE,
    p_end_date          DATE,
    p_total_days        INTEGER,
    p_is_partial        BOOLEAN,
    p_notes             VARCHAR(500) DEFAULT NULL,
    p_days              TEXT         DEFAULT NULL
)
RETURNS TABLE("RequestId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_days_json JSONB;
BEGIN
    -- Handle XML format: <days><d dt="2026-01-01" tp="COMPLETO"/></days>
    -- or JSON format: [{"date":"2026-01-01","dayType":"COMPLETO"}]
    IF p_days IS NOT NULL THEN
        IF p_days LIKE '<%' THEN
            -- XML format - extract date/type pairs
            v_days_json := (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'date', (regexp_matches(d, 'dt="([^"]+)"'))[1],
                        'dayType', COALESCE((regexp_matches(d, 'tp="([^"]+)"'))[1], 'COMPLETO')
                    )
                )
                FROM regexp_split_to_table(p_days, '<d ') AS d
                WHERE d LIKE '%dt="%'
            );
        ELSE
            v_days_json := p_days::JSONB;
        END IF;
    END IF;

    RETURN QUERY
    SELECT r."RequestId"
    FROM public.usp_hr_vacation_request_create(
        p_company_id, p_branch_id, p_employee_code,
        p_start_date, p_end_date, p_total_days, p_is_partial, p_notes,
        v_days_json
    ) r;
END;
$$;

SELECT 'PART 5 VACATION REQUEST ALIASES APPLIED' AS status;
