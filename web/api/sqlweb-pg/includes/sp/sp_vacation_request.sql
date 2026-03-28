-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_vacation_request.sql
-- Flujo de trabajo de solicitudes de vacaciones (RRHH)
-- Depende de: hr.VacationRequest, hr.VacationRequestDay,
--             master.Employee, hr.VacationProcess
-- ============================================================

-- =============================================================
-- 1) usp_hr_vacation_request_create
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_create(
    INT, INT, VARCHAR, DATE, DATE, INT, BOOLEAN, VARCHAR, JSONB
);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_create(
    p_company_id    INT,
    p_branch_id     INT,
    p_employee_code VARCHAR(60),
    p_start_date    DATE,
    p_end_date      DATE,
    p_total_days    INT,
    p_is_partial    BOOLEAN,
    p_notes         VARCHAR(500),
    p_days          JSONB DEFAULT NULL  -- [{"dt":"2026-03-16", "tp":"COMPLETO"}, ...]
)
RETURNS TABLE (
    "RequestId" BIGINT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_request_id BIGINT;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION 'La fecha fin no puede ser anterior a la fecha inicio.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_total_days <= 0 THEN
        RAISE EXCEPTION 'El total de dias debe ser mayor a cero.'
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO hr."VacationRequest" (
        "CompanyId", "BranchId", "EmployeeCode",
        "StartDate", "EndDate", "TotalDays",
        "IsPartial", "Notes"
    )
    VALUES (
        p_company_id, p_branch_id, p_employee_code,
        p_start_date, p_end_date, p_total_days,
        p_is_partial, p_notes
    )
    RETURNING "RequestId" INTO v_request_id;

    -- Insertar dias desde JSONB: [{"dt":"2026-03-16", "tp":"COMPLETO"}, ...]
    IF p_days IS NOT NULL AND jsonb_array_length(p_days) > 0 THEN
        INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
        SELECT
            v_request_id,
            (elem->>'dt')::DATE,
            COALESCE(NULLIF(elem->>'tp', ''::VARCHAR), 'COMPLETO')
          FROM jsonb_array_elements(p_days) AS elem
         WHERE elem->>'dt' IS NOT NULL;
    END IF;

    RETURN QUERY SELECT v_request_id;
END;
$fn$;


-- =============================================================
-- 2) usp_hr_vacation_request_list
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_list(
    INT, VARCHAR, VARCHAR, INT, INT
);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_list(
    p_company_id    INT,
    p_employee_code VARCHAR(60) DEFAULT NULL,
    p_status        VARCHAR(20) DEFAULT NULL,
    p_offset        INT DEFAULT 0,
    p_limit         INT DEFAULT 50
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "ApprovedBy"      VARCHAR,
    "Notes"           VARCHAR,
    "RejectionReason" VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount"      INT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_total_count INT;
BEGIN
    SELECT COUNT(*)
      INTO v_total_count
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status);

    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."RejectionReason"::VARCHAR,
        vr."CreatedAt",
        v_total_count
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status)
     ORDER BY vr."RequestDate" DESC, vr."RequestId" DESC
     LIMIT p_limit
    OFFSET p_offset;
END;
$fn$;


-- =============================================================
-- 3) usp_hr_vacation_request_get
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get(
    p_request_id BIGINT
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "CompanyId"       INT,
    "BranchId"        INT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "Notes"           VARCHAR,
    "ApprovedBy"      VARCHAR,
    "ApprovalDate"    TIMESTAMP,
    "RejectionReason" VARCHAR,
    "VacationId"      BIGINT,
    "CreatedAt"       TIMESTAMP,
    "UpdatedAt"       TIMESTAMP
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."CompanyId",
        vr."BranchId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."ApprovalDate",
        vr."RejectionReason"::VARCHAR,
        vr."VacationId",
        vr."CreatedAt",
        vr."UpdatedAt"
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."RequestId" = p_request_id;
END;
$fn$;


-- =============================================================
-- 3b) usp_hr_vacation_request_get_days
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get_days(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_days(
    p_request_id BIGINT
)
RETURNS TABLE (
    "DayId"        BIGINT,
    "RequestId"    BIGINT,
    "SelectedDate" VARCHAR,
    "DayType"      VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        d."DayId",
        d."RequestId",
        TO_CHAR(d."SelectedDate", 'YYYY-MM-DD')::VARCHAR AS "SelectedDate",
        d."DayType"::VARCHAR
      FROM hr."VacationRequestDay" d
     WHERE d."RequestId" = p_request_id
     ORDER BY d."SelectedDate";
END;
$fn$;


-- =============================================================
-- 4) usp_hr_vacation_request_approve
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_approve(BIGINT, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_approve(
    p_request_id  BIGINT,
    p_approved_by VARCHAR(60)
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden aprobar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"       = 'APROBADA',
           "ApprovedBy"   = p_approved_by,
           "ApprovalDate" = NOW() AT TIME ZONE 'UTC',
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'APROBADA'::VARCHAR;
END;
$fn$;


-- =============================================================
-- 5) usp_hr_vacation_request_reject
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_reject(BIGINT, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_reject(
    p_request_id       BIGINT,
    p_approved_by      VARCHAR(60),
    p_rejection_reason VARCHAR(500)
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden rechazar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"          = 'RECHAZADA',
           "ApprovedBy"      = p_approved_by,
           "ApprovalDate"    = NOW() AT TIME ZONE 'UTC',
           "RejectionReason" = p_rejection_reason,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'RECHAZADA'::VARCHAR;
END;
$fn$;


-- =============================================================
-- 6) usp_hr_vacation_request_cancel
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_cancel(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_cancel(
    p_request_id BIGINT
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden cancelar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"    = 'CANCELADA',
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'CANCELADA'::VARCHAR;
END;
$fn$;


-- =============================================================
-- 7) usp_hr_vacation_request_process
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_process(BIGINT, BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_process(
    p_request_id  BIGINT,
    p_vacation_id BIGINT
)
RETURNS TABLE (
    "RequestId"  BIGINT,
    "Status"     VARCHAR,
    "VacationId" BIGINT
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'APROBADA'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden procesar solicitudes en estado APROBADA.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"     = 'PROCESADA',
           "VacationId" = p_vacation_id,
           "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'APROBADA';

    RETURN QUERY SELECT p_request_id, 'PROCESADA'::VARCHAR, p_vacation_id;
END;
$fn$;


-- =============================================================
-- 8) usp_hr_vacation_request_get_available_days
-- =============================================================
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get_available_days(INT, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_available_days(
    p_company_id    INT,
    p_employee_code VARCHAR(60)
)
RETURNS TABLE (
    "DiasBase"        INT,
    "AnosServicio"    INT,
    "DiasAdicionales" INT,
    "DiasDisponibles" INT,
    "DiasTomados"     INT,
    "DiasPendientes"  INT,
    "DiasSaldo"       INT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_hire_date         DATE;
    v_anos_servicio     INT;
    v_dias_base         INT := 15;
    v_dias_adicionales  INT;
    v_dias_disponibles  INT;
    v_dias_tomados      INT;
    v_dias_pendientes   INT;
BEGIN
    SELECT e."HireDate"
      INTO v_hire_date
      FROM master."Employee" e
     WHERE e."CompanyId" = p_company_id
       AND e."EmployeeCode" = p_employee_code
       AND COALESCE(e."IsDeleted", FALSE) = FALSE;

    IF v_hire_date IS NULL THEN
        RETURN QUERY SELECT
            v_dias_base,
            0,
            0,
            v_dias_base,
            0,
            0,
            v_dias_base;
        RETURN;
    END IF;

    -- Calcular anos de servicio
    v_anos_servicio := EXTRACT(YEAR FROM age(NOW() AT TIME ZONE 'UTC', v_hire_date))::INT;
    IF v_anos_servicio < 0 THEN
        v_anos_servicio := 0;
    END IF;

    v_dias_adicionales := v_anos_servicio;
    v_dias_disponibles := v_dias_base + v_dias_adicionales;

    -- Dias ya procesados (disfrutados) en el ano actual
    SELECT COALESCE(SUM((vp."EndDate" - vp."StartDate") + 1), 0)
      INTO v_dias_tomados
      FROM hr."VacationProcess" vp
     WHERE vp."CompanyId" = p_company_id
       AND vp."EmployeeCode" = p_employee_code
       AND EXTRACT(YEAR FROM vp."StartDate") = EXTRACT(YEAR FROM (NOW() AT TIME ZONE 'UTC'));

    -- Dias en solicitudes pendientes o aprobadas
    SELECT COALESCE(SUM(vr."TotalDays"), 0)
      INTO v_dias_pendientes
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND vr."EmployeeCode" = p_employee_code
       AND vr."Status" IN ('PENDIENTE', 'APROBADA');

    RETURN QUERY SELECT
        v_dias_base,
        v_anos_servicio,
        v_dias_adicionales,
        v_dias_disponibles,
        v_dias_tomados,
        v_dias_pendientes,
        (v_dias_disponibles - COALESCE(v_dias_tomados, 0) - COALESCE(v_dias_pendientes, 0));
END;
$fn$;

-- ================================================================
-- ALIAS: usp_hr_vacationrequest_list
-- Alias for usp_hr_vacation_request_list to match API calling convention
-- (usp_HR_VacationRequest_List â†’ usp_hr_vacationrequest_list)
-- ================================================================
DROP FUNCTION IF EXISTS usp_hr_vacationrequest_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_vacationrequest_list(
    p_company_id    INT,
    p_employee_code VARCHAR(60) DEFAULT NULL,
    p_status        VARCHAR(20) DEFAULT NULL,
    p_offset        INT DEFAULT 0,
    p_limit         INT DEFAULT 50
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "ApprovedBy"      VARCHAR,
    "Notes"           VARCHAR,
    "RejectionReason" VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount"      INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM usp_hr_vacation_request_list(
        p_company_id, p_employee_code, p_status, p_offset, p_limit
    );
END;
$$;
