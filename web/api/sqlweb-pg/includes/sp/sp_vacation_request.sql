-- =============================================
-- Funciones: Vacation Request Workflow
-- Depends on: hr."VacationRequest", hr."VacationRequestDay", master."Employee", hr."VacationProcess"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================================
-- 1) usp_hr_vacation_request_create
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_create(
    p_company_id    INT,
    p_branch_id     INT,
    p_employee_code VARCHAR(60),
    p_start_date    DATE,
    p_end_date      DATE,
    p_total_days    INT,
    p_is_partial    BOOLEAN,
    p_notes         VARCHAR(500),
    p_days          TEXT DEFAULT NULL  -- CSV: date1|type1;date2|type2;...  OR JSON array
)
RETURNS TABLE(
    "RequestId" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_request_id BIGINT;
    v_item       TEXT;
    v_parts      TEXT[];
    v_day_arr    TEXT[];
    v_json       JSONB;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION 'La fecha fin no puede ser anterior a la fecha inicio.';
    END IF;

    IF p_total_days <= 0 THEN
        RAISE EXCEPTION 'El total de dias debe ser mayor a cero.';
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
    RETURNING hr."VacationRequest"."RequestId" INTO v_request_id;

    -- Parse days: try JSON first, then CSV
    IF p_days IS NOT NULL AND p_days <> '' THEN
        -- Check if it looks like JSON array
        IF LEFT(TRIM(p_days), 1) = '[' THEN
            v_json := p_days::JSONB;
            INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
            SELECT v_request_id,
                   (item->>'dt')::DATE,
                   COALESCE(item->>'tp', 'COMPLETO')
            FROM jsonb_array_elements(v_json) AS item;
        ELSE
            -- Parse CSV format: 2026-03-16|COMPLETO;2026-03-17|COMPLETO
            FOREACH v_item IN ARRAY string_to_array(p_days, ';')
            LOOP
                IF LENGTH(TRIM(v_item)) >= 10 THEN
                    v_parts := string_to_array(TRIM(v_item), '|');
                    INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
                    VALUES (
                        v_request_id,
                        v_parts[1]::DATE,
                        COALESCE(v_parts[2], 'COMPLETO')
                    );
                END IF;
            END LOOP;
        END IF;
    END IF;

    RETURN QUERY SELECT v_request_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;

-- =============================================================
-- 2) usp_hr_vacation_request_list
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_list(
    p_company_id    INT,
    p_employee_code VARCHAR(60) DEFAULT NULL,
    p_status        VARCHAR(20) DEFAULT NULL,
    p_offset        INT DEFAULT 0,
    p_limit         INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"    BIGINT,
    "RequestId"     BIGINT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "RequestDate"   VARCHAR,
    "StartDate"     VARCHAR,
    "EndDate"       VARCHAR,
    "TotalDays"     INT,
    "IsPartial"     BOOLEAN,
    "Status"        VARCHAR,
    "ApprovedBy"    VARCHAR,
    "Notes"         VARCHAR,
    "RejectionReason" VARCHAR,
    "CreatedAt"     TIMESTAMP
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM hr."VacationRequest" vr
    WHERE vr."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
      AND (p_status IS NULL OR vr."Status" = p_status);

    RETURN QUERY
    SELECT
        v_total,
        vr."RequestId",
        vr."EmployeeCode",
        COALESCE(e."EmployeeName", vr."EmployeeCode"),
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD'),
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD'),
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD'),
        vr."TotalDays",
        vr."IsPartial",
        vr."Status",
        vr."ApprovedBy",
        vr."Notes",
        vr."RejectionReason",
        vr."CreatedAt"
    FROM hr."VacationRequest" vr
    LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
    WHERE vr."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
      AND (p_status IS NULL OR vr."Status" = p_status)
    ORDER BY vr."RequestDate" DESC, vr."RequestId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================
-- 3) usp_hr_vacation_request_get (header)
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get(
    p_request_id BIGINT
)
RETURNS TABLE(
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
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."CompanyId",
        vr."BranchId",
        vr."EmployeeCode",
        COALESCE(e."EmployeeName", vr."EmployeeCode"),
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD'),
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD'),
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD'),
        vr."TotalDays",
        vr."IsPartial",
        vr."Status",
        vr."Notes",
        vr."ApprovedBy",
        vr."ApprovalDate",
        vr."RejectionReason",
        vr."VacationId",
        vr."CreatedAt",
        vr."UpdatedAt"
    FROM hr."VacationRequest" vr
    LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
    WHERE vr."RequestId" = p_request_id;
END;
$$;

-- Obtener dias de la solicitud
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_days(
    p_request_id BIGINT
)
RETURNS TABLE(
    "DayId"        BIGINT,
    "RequestId"    BIGINT,
    "SelectedDate" VARCHAR,
    "DayType"      VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."DayId",
        d."RequestId",
        TO_CHAR(d."SelectedDate", 'YYYY-MM-DD'),
        d."DayType"
    FROM hr."VacationRequestDay" d
    WHERE d."RequestId" = p_request_id
    ORDER BY d."SelectedDate";
END;
$$;

-- =============================================================
-- 4) usp_hr_vacation_request_approve
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_approve(
    p_request_id BIGINT,
    p_approved_by VARCHAR(60)
)
RETURNS TABLE(
    "RequestId" BIGINT,
    "Status"    VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE') THEN
        RAISE EXCEPTION 'Solo se pueden aprobar solicitudes en estado PENDIENTE.';
    END IF;

    UPDATE hr."VacationRequest"
    SET "Status"       = 'APROBADA',
        "ApprovedBy"   = p_approved_by,
        "ApprovalDate" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
    WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'APROBADA'::VARCHAR;
END;
$$;

-- =============================================================
-- 5) usp_hr_vacation_request_reject
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_reject(
    p_request_id       BIGINT,
    p_approved_by      VARCHAR(60),
    p_rejection_reason VARCHAR(500)
)
RETURNS TABLE(
    "RequestId" BIGINT,
    "Status"    VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE') THEN
        RAISE EXCEPTION 'Solo se pueden rechazar solicitudes en estado PENDIENTE.';
    END IF;

    UPDATE hr."VacationRequest"
    SET "Status"          = 'RECHAZADA',
        "ApprovedBy"      = p_approved_by,
        "ApprovalDate"    = NOW() AT TIME ZONE 'UTC',
        "RejectionReason" = p_rejection_reason,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'RECHAZADA'::VARCHAR;
END;
$$;

-- =============================================================
-- 6) usp_hr_vacation_request_cancel
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_cancel(
    p_request_id BIGINT
)
RETURNS TABLE(
    "RequestId" BIGINT,
    "Status"    VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE') THEN
        RAISE EXCEPTION 'Solo se pueden cancelar solicitudes en estado PENDIENTE.';
    END IF;

    UPDATE hr."VacationRequest"
    SET "Status"    = 'CANCELADA',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'CANCELADA'::VARCHAR;
END;
$$;

-- =============================================================
-- 7) usp_hr_vacation_request_process
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_process(
    p_request_id  BIGINT,
    p_vacation_id BIGINT
)
RETURNS TABLE(
    "RequestId"  BIGINT,
    "Status"     VARCHAR,
    "VacationId" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = p_request_id AND "Status" = 'APROBADA') THEN
        RAISE EXCEPTION 'Solo se pueden procesar solicitudes en estado APROBADA.';
    END IF;

    UPDATE hr."VacationRequest"
    SET "Status"     = 'PROCESADA',
        "VacationId" = p_vacation_id,
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "RequestId" = p_request_id AND "Status" = 'APROBADA';

    RETURN QUERY SELECT p_request_id, 'PROCESADA'::VARCHAR, p_vacation_id;
END;
$$;

-- =============================================================
-- 8) usp_hr_vacation_request_get_available_days
-- =============================================================
CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_available_days(
    p_company_id    INT,
    p_employee_code VARCHAR(60)
)
RETURNS TABLE(
    "DiasBase"         INT,
    "AnosServicio"     INT,
    "DiasAdicionales"  INT,
    "DiasDisponibles"  INT,
    "DiasTomados"      INT,
    "DiasPendientes"   INT,
    "DiasSaldo"        INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_hire_date         DATE;
    v_anos_servicio     INT;
    v_dias_base         INT := 15;
    v_dias_adicionales  INT;
    v_dias_disponibles  INT;
    v_dias_tomados      INT;
    v_dias_pendientes   INT;
BEGIN
    SELECT e."HireDate" INTO v_hire_date
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND e."EmployeeCode" = p_employee_code
      AND COALESCE(e."IsDeleted", FALSE) = FALSE;

    IF v_hire_date IS NULL THEN
        RETURN QUERY
        SELECT
            v_dias_base,
            0,
            0,
            v_dias_base,
            0,
            0,
            v_dias_base;
        RETURN;
    END IF;

    v_anos_servicio := EXTRACT(YEAR FROM age(NOW() AT TIME ZONE 'UTC', v_hire_date))::INT;
    IF v_anos_servicio < 0 THEN
        v_anos_servicio := 0;
    END IF;

    v_dias_adicionales := v_anos_servicio;
    v_dias_disponibles := v_dias_base + v_dias_adicionales;

    -- Dias ya procesados (disfrutados) en el anio actual
    SELECT COALESCE(SUM(("EndDate" - "StartDate") + 1), 0)::INT
    INTO v_dias_tomados
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id
      AND vp."EmployeeCode" = p_employee_code
      AND EXTRACT(YEAR FROM vp."StartDate") = EXTRACT(YEAR FROM (NOW() AT TIME ZONE 'UTC'));

    -- Dias en solicitudes pendientes o aprobadas
    SELECT COALESCE(SUM(vr."TotalDays"), 0)::INT
    INTO v_dias_pendientes
    FROM hr."VacationRequest" vr
    WHERE vr."CompanyId" = p_company_id
      AND vr."EmployeeCode" = p_employee_code
      AND vr."Status" IN ('PENDIENTE', 'APROBADA');

    RETURN QUERY
    SELECT
        v_dias_base,
        v_anos_servicio,
        v_dias_adicionales,
        v_dias_disponibles,
        v_dias_tomados,
        v_dias_pendientes,
        (v_dias_disponibles - COALESCE(v_dias_tomados, 0) - COALESCE(v_dias_pendientes, 0));
END;
$$;
