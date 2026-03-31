-- +goose Up
-- Migration: Add CompanyId filtering to critical HR, PAY, and INV stored procedures.
-- Tables hr."PayrollCalcVariable", hr."EmployeeTaxProfile", hr."SavingsLoan",
-- hr."ObligationRiskLevel", pay."Transactions", pay."CompanyPaymentConfig",
-- pay."CardReaderDevices", pay."ReconciliationBatches", pay."AcceptedPaymentMethods"
-- now have a "CompanyId" column (migration 00058). This migration enforces
-- CompanyId filtering in all SPs that touch those tables or their children.

-- ============================================================================
-- 1. usp_hr_payroll_getdraftgrid — child of PayrollBatch; validate via JOIN
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftgrid(
    p_company_id integer,
    p_batch_id bigint,
    p_search character varying DEFAULT NULL::character varying,
    p_department character varying DEFAULT NULL::character varying,
    p_only_modified boolean DEFAULT false,
    p_offset integer DEFAULT 0,
    p_limit integer DEFAULT 50
) RETURNS TABLE(
    p_total_count bigint,
    "EmployeeCode" character varying,
    "EmployeeName" character varying,
    "EmployeeId" bigint,
    "DepartmentCode" character varying,
    "DepartmentName" character varying,
    "PositionName" character varying,
    "TotalGross" numeric,
    "TotalDeductions" numeric,
    "TotalNet" numeric,
    "HasModified" bigint,
    "ConceptCount" bigint
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate batch belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch" b
        WHERE b."BatchId" = p_batch_id AND b."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH "EmployeeSummary" AS (
        SELECT
            bl."EmployeeCode",
            bl."EmployeeName",
            bl."EmployeeId",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END) AS "TotalGross",
            SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)              AS "TotalDeductions",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)            AS "TotalNet",
            MAX(CASE WHEN bl."IsModified" THEN 1 ELSE 0 END)                                      AS "HasModified",
            COUNT(*)                                                                                AS "ConceptCount"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName", bl."EmployeeId"
    ), "Filtered" AS (
        SELECT es.*
        FROM "EmployeeSummary" es
        WHERE (p_search IS NULL
               OR es."EmployeeCode" ILIKE '%' || p_search || '%'
               OR es."EmployeeName" ILIKE '%' || p_search || '%')
          AND (NOT p_only_modified OR es."HasModified" = 1)
    )
    SELECT
        COUNT(*) OVER()       AS p_total_count,
        f."EmployeeCode"::VARCHAR,
        f."EmployeeName"::VARCHAR,
        f."EmployeeId",
        ''::VARCHAR           AS "DepartmentCode",
        ''::VARCHAR           AS "DepartmentName",
        ''::VARCHAR           AS "PositionName",
        f."TotalGross",
        f."TotalDeductions",
        f."TotalNet",
        f."HasModified"::BIGINT,
        f."ConceptCount"
    FROM "Filtered" f
    ORDER BY f."EmployeeName"
    OFFSET p_offset
    LIMIT p_limit;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 2. usp_hr_payroll_getdraftsummary — delegates to _header; add CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary(
    p_company_id integer,
    p_batch_id bigint
) RETURNS TABLE(
    "BatchId" integer, "CompanyId" integer, "BranchId" integer,
    "PayrollCode" character varying, "FromDate" date, "ToDate" date,
    "Status" character varying, "TotalEmployees" integer,
    "TotalGross" numeric, "TotalDeductions" numeric, "TotalNet" numeric,
    "CreatedBy" integer, "CreatedAt" timestamp without time zone,
    "ApprovedBy" integer, "ApprovedAt" timestamp without time zone,
    "PrevBatchId" integer, "PrevTotalGross" numeric,
    "PrevTotalDeductions" numeric, "PrevTotalNet" numeric,
    "NetChangePercent" numeric,
    "totalAsignaciones" numeric, "totalDeducciones" numeric,
    "totalNeto" numeric, "totalEmpleados" bigint
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        h."BatchId", h."CompanyId", h."BranchId",
        h."PayrollCode", h."FromDate", h."ToDate",
        h."Status", h."TotalEmployees",
        h."TotalGross", h."TotalDeductions", h."TotalNet",
        h."CreatedBy", h."CreatedAt",
        h."ApprovedBy", h."ApprovedAt",
        h."PrevBatchId", h."PrevTotalGross",
        h."PrevTotalDeductions", h."PrevTotalNet",
        h."NetChangePercent",
        h."TotalGross"::NUMERIC       AS "totalAsignaciones",
        h."TotalDeductions"::NUMERIC  AS "totalDeducciones",
        h."TotalNet"::NUMERIC         AS "totalNeto",
        h."TotalEmployees"::BIGINT    AS "totalEmpleados"
    FROM public.usp_hr_payroll_getdraftsummary_header(p_company_id, p_batch_id) h;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 3. usp_hr_payroll_getdraftsummary_alerts — child of PayrollBatch
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_alerts(
    p_company_id integer,
    p_batch_id bigint
) RETURNS TABLE(
    "AlertType" text,
    "EmployeeCode" character varying,
    "EmployeeName" character varying,
    "AlertMessage" text
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate batch belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch" b
        WHERE b."BatchId" = p_batch_id AND b."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        alerts."AlertType",
        alerts."EmployeeCode",
        alerts."EmployeeName",
        alerts."AlertMessage"
    FROM (
        -- Empleados sin asignaciones
        SELECT
            'SIN_ASIGNACIONES'::TEXT                               AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            'El empleado no tiene conceptos de asignación.'::TEXT  AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN 1 ELSE 0 END) = 0

        UNION ALL

        -- Empleados con neto negativo
        SELECT
            'NETO_NEGATIVO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('El neto del empleado es negativo: ' ||
             (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END))::TEXT
            )::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
              - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)) < 0

        UNION ALL

        -- Líneas con monto cero
        SELECT
            'MONTO_CERO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('Concepto ' || bl."ConceptCode" || ' tiene monto cero.')::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId"     = p_batch_id
          AND bl."Total"       = 0
          AND bl."ConceptType" IN ('ASIGNACION', 'BONO')

    ) alerts
    ORDER BY alerts."AlertType", alerts."EmployeeCode";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 4. usp_hr_payroll_getdraftsummary_bydept — child of PayrollBatch
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_bydept(
    p_company_id integer,
    p_batch_id bigint
) RETURNS TABLE(
    "DepartmentCode" text,
    "DepartmentName" text,
    "EmployeeCount" bigint,
    "DeptGross" numeric,
    "DeptDeductions" numeric,
    "DeptNet" numeric
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate batch belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch" b
        WHERE b."BatchId" = p_batch_id AND b."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        'GENERAL'::TEXT                                                          AS "DepartmentCode",
        'General'::TEXT                                                          AS "DepartmentName",
        COUNT(DISTINCT bl."EmployeeCode")                                        AS "EmployeeCount",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0) AS "DeptGross",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)             AS "DeptDeductions",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)           AS "DeptNet"
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId" = p_batch_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 5. usp_hr_payroll_getdraftsummary_header — filter PayrollBatch by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_header(
    p_company_id integer,
    p_batch_id bigint
) RETURNS TABLE(
    "BatchId" integer, "CompanyId" integer, "BranchId" integer,
    "PayrollCode" character varying, "FromDate" date, "ToDate" date,
    "Status" character varying, "TotalEmployees" integer,
    "TotalGross" numeric, "TotalDeductions" numeric, "TotalNet" numeric,
    "CreatedBy" integer, "CreatedAt" timestamp without time zone,
    "ApprovedBy" integer, "ApprovedAt" timestamp without time zone,
    "PrevBatchId" integer, "PrevTotalGross" numeric,
    "PrevTotalDeductions" numeric, "PrevTotalNet" numeric,
    "NetChangePercent" numeric
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BatchId"::INTEGER,
        b."CompanyId"::INTEGER,
        b."BranchId"::INTEGER,
        b."PayrollCode"::VARCHAR(15),
        b."FromDate"::DATE,
        b."ToDate"::DATE,
        b."Status"::VARCHAR(20),
        b."TotalEmployees"::INTEGER,
        b."TotalGross"::NUMERIC(18,2),
        b."TotalDeductions"::NUMERIC(18,2),
        b."TotalNet"::NUMERIC(18,2),
        b."CreatedBy"::INTEGER,
        b."CreatedAt"::TIMESTAMP,
        b."ApprovedBy"::INTEGER,
        b."ApprovedAt"::TIMESTAMP,
        prev."PrevBatchId"::INTEGER,
        prev."PrevTotalGross"::NUMERIC(18,2),
        prev."PrevTotalDeductions"::NUMERIC(18,2),
        prev."PrevTotalNet"::NUMERIC(18,2),
        CASE WHEN prev."PrevTotalNet" > 0
             THEN CAST(((b."TotalNet" - prev."PrevTotalNet") / prev."PrevTotalNet") * 100 AS NUMERIC(8,2))
             ELSE 0::NUMERIC(8,2)
        END AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN LATERAL (
        SELECT
            pb."BatchId"::INTEGER          AS "PrevBatchId",
            pb."TotalGross"::NUMERIC(18,2)       AS "PrevTotalGross",
            pb."TotalDeductions"::NUMERIC(18,2)  AS "PrevTotalDeductions",
            pb."TotalNet"::NUMERIC(18,2)         AS "PrevTotalNet"
        FROM hr."PayrollBatch" pb
        WHERE pb."CompanyId"   = b."CompanyId"
          AND pb."BranchId"    = b."BranchId"
          AND pb."PayrollCode" = b."PayrollCode"
          AND pb."ToDate"      < b."FromDate"
          AND pb."Status"      IN ('PROCESADA', 'CERRADA')
        ORDER BY pb."ToDate" DESC
        LIMIT 1
    ) prev ON TRUE
    WHERE b."BatchId" = p_batch_id
      AND b."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 6. usp_hr_payroll_getemployeelines — child of PayrollBatch
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getemployeelines(
    p_company_id integer,
    p_batch_id bigint,
    p_employee_code character varying
) RETURNS TABLE(
    "LineId" integer, "BatchId" integer, "EmployeeId" bigint,
    "EmployeeCode" character varying, "EmployeeName" character varying,
    "ConceptCode" character varying, "ConceptName" character varying,
    "ConceptType" character varying, "Quantity" numeric,
    "Amount" numeric, "Total" numeric, "IsModified" boolean,
    "Notes" character varying, "UpdatedAt" timestamp without time zone
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate batch belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch" b
        WHERE b."BatchId" = p_batch_id AND b."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        bl."LineId"::INTEGER,
        bl."BatchId"::INTEGER,
        bl."EmployeeId"::BIGINT,
        bl."EmployeeCode"::VARCHAR,
        bl."EmployeeName"::VARCHAR,
        bl."ConceptCode"::VARCHAR,
        bl."ConceptName"::VARCHAR,
        bl."ConceptType"::VARCHAR,
        bl."Quantity"::NUMERIC,
        bl."Amount"::NUMERIC,
        bl."Total"::NUMERIC,
        bl."IsModified"::BOOLEAN,
        bl."Notes"::VARCHAR,
        bl."UpdatedAt"::TIMESTAMP
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId"      = p_batch_id
      AND bl."EmployeeCode" = p_employee_code
    ORDER BY
        CASE bl."ConceptType"
            WHEN 'ASIGNACION' THEN 1
            WHEN 'BONO'       THEN 2
            WHEN 'DEDUCCION'  THEN 3
        END,
        bl."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 7. usp_hr_payroll_getrunlines — child of PayrollRun; validate via JOIN
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getrunlines(
    p_company_id integer,
    p_run_id bigint
) RETURNS TABLE(
    "coConcepto" character varying, "nombreConcepto" character varying,
    "tipoConcepto" character varying, cantidad numeric,
    monto numeric, total numeric, descripcion text,
    "cuentaContable" character varying
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        rl."ConceptCode", rl."ConceptName", rl."ConceptType",
        rl."Quantity", rl."Amount", rl."Total",
        rl."DescriptionText", rl."AccountingAccountCode"
    FROM hr."PayrollRunLine" rl
    INNER JOIN hr."PayrollRun" pr ON pr."PayrollRunId" = rl."PayrollRunId"
    WHERE rl."PayrollRunId" = p_run_id
      AND pr."CompanyId" = p_company_id
    ORDER BY rl."PayrollRunLineId";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 8. usp_hr_payroll_getsettlementlines — child of SettlementProcess
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getsettlementlines(
    p_company_id integer,
    p_settlement_process_id bigint
) RETURNS TABLE(
    codigo character varying, nombre character varying, monto numeric
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT sl."ConceptCode", sl."ConceptName", sl."Amount"
    FROM hr."SettlementProcessLine" sl
    INNER JOIN hr."SettlementProcess" sp ON sp."SettlementProcessId" = sl."SettlementProcessId"
    WHERE sl."SettlementProcessId" = p_settlement_process_id
      AND sp."CompanyId" = p_company_id
    ORDER BY sl."SettlementProcessLineId";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 9. usp_hr_payroll_getvacationlines — child of VacationProcess
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getvacationlines(
    p_company_id integer,
    p_vacation_process_id bigint
) RETURNS TABLE(
    codigo character varying, nombre character varying, monto numeric
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT vl."ConceptCode", vl."ConceptName", vl."Amount"
    FROM hr."VacationProcessLine" vl
    INNER JOIN hr."VacationProcess" vp ON vp."VacationProcessId" = vl."VacationProcessId"
    WHERE vl."VacationProcessId" = p_vacation_process_id
      AND vp."CompanyId" = p_company_id
    ORDER BY vl."VacationProcessLineId";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 10. usp_hr_vacation_request_get — filter by CompanyId on VacationRequest
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_get(
    p_company_id integer,
    p_request_id bigint
) RETURNS TABLE(
    "RequestId" bigint, "CompanyId" integer, "BranchId" integer,
    "EmployeeCode" character varying, "EmployeeName" character varying,
    "RequestDate" character varying, "StartDate" character varying,
    "EndDate" character varying, "TotalDays" integer,
    "IsPartial" boolean, "Status" character varying,
    "Notes" character varying, "ApprovedBy" character varying,
    "ApprovalDate" timestamp without time zone,
    "RejectionReason" character varying, "VacationId" bigint,
    "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone
)
    LANGUAGE plpgsql
    AS $$
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
     WHERE vr."RequestId" = p_request_id
       AND vr."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 11. usp_hr_vacation_request_get_days — child of VacationRequest
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_get_days(
    p_company_id integer,
    p_request_id bigint
) RETURNS TABLE(
    "DayId" bigint, "RequestId" bigint,
    "SelectedDate" character varying, "DayType" character varying
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate request belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest" vr
        WHERE vr."RequestId" = p_request_id AND vr."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

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
$$;
-- +goose StatementEnd

-- ============================================================================
-- 12. usp_hr_profitsharing_getsummary — filter ProfitSharing by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_getsummary(
    p_company_id integer,
    p_profit_sharing_id integer
) RETURNS TABLE(result_type text, row_data jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ProfitSharingId',      ps."ProfitSharingId",
            'CompanyId',            ps."CompanyId",
            'BranchId',             ps."BranchId",
            'FiscalYear',           ps."FiscalYear",
            'DaysGranted',          ps."DaysGranted",
            'TotalCompanyProfits',  ps."TotalCompanyProfits",
            'Status',               ps."Status",
            'CreatedBy',            ps."CreatedBy",
            'CreatedAt',            ps."CreatedAt",
            'ApprovedBy',           ps."ApprovedBy",
            'ApprovedAt',           ps."ApprovedAt",
            'UpdatedAt',            ps."UpdatedAt",
            'TotalEmployees',       (SELECT COUNT(*) FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"),
            'TotalGross',           COALESCE((SELECT SUM("GrossAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalInce',            COALESCE((SELECT SUM("InceDeduction") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalNet',             COALESCE((SELECT SUM("NetAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0)
        )
    FROM hr."ProfitSharing" ps
    WHERE ps."ProfitSharingId" = p_profit_sharing_id
      AND ps."CompanyId" = p_company_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'LineId',           l."LineId",
            'EmployeeId',       l."EmployeeId",
            'EmployeeCode',     l."EmployeeCode",
            'EmployeeName',     l."EmployeeName",
            'MonthlySalary',    l."MonthlySalary",
            'DailySalary',      l."DailySalary",
            'DaysWorked',       l."DaysWorked",
            'DaysEntitled',     l."DaysEntitled",
            'GrossAmount',      l."GrossAmount",
            'InceDeduction',    l."InceDeduction",
            'NetAmount',        l."NetAmount",
            'IsPaid',           l."IsPaid",
            'PaidAt',           l."PaidAt"
        )
    FROM hr."ProfitSharingLine" l
    INNER JOIN hr."ProfitSharing" ps ON ps."ProfitSharingId" = l."ProfitSharingId"
    WHERE l."ProfitSharingId" = p_profit_sharing_id
      AND ps."CompanyId" = p_company_id
    ORDER BY l."EmployeeName";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 13. usp_hr_profitsharing_approve — validate ProfitSharing belongs to company
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_approve(
    p_company_id integer,
    p_profit_sharing_id integer,
    p_approved_by integer,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status" INTO v_current_status
    FROM hr."ProfitSharing"
    WHERE "ProfitSharingId" = p_profit_sharing_id
      AND "CompanyId" = p_company_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Registro de utilidades no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'CALCULADA' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar utilidades en estado CALCULADA. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    UPDATE hr."ProfitSharing"
    SET "Status"     = 'PROCESADA',
        "ApprovedBy" = p_approved_by,
        "ApprovedAt" = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
    WHERE "ProfitSharingId" = p_profit_sharing_id
      AND "CompanyId" = p_company_id;

    p_resultado := p_profit_sharing_id;
    p_mensaje   := 'Utilidades aprobadas exitosamente.';
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 14. usp_hr_savings_approveloan — validate SavingsLoan via SavingsFund.CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_savings_approveloan(
    p_company_id integer,
    p_loan_id integer,
    p_approved boolean,
    p_approved_by integer,
    p_notes character varying DEFAULT NULL::character varying,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_status    VARCHAR(15);
    v_fund_id           INTEGER;
    v_loan_amount       NUMERIC(18,2);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT sl."Status", sl."SavingsFundId", sl."LoanAmount"
    INTO v_current_status, v_fund_id, v_loan_amount
    FROM hr."SavingsLoan" sl
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = sl."SavingsFundId"
    WHERE sl."LoanId" = p_loan_id
      AND sf."CompanyId" = p_company_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Préstamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'SOLICITADO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar/rechazar préstamos en estado SOLICITADO. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    BEGIN
        IF p_approved THEN
            UPDATE hr."SavingsLoan"
            SET "Status"        = 'ACTIVO',
                "ApprovedDate"  = CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                "ApprovedBy"    = p_approved_by,
                "Notes"         = COALESCE(p_notes, "Notes"),
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            SELECT COALESCE((
                SELECT "Balance" FROM hr."SavingsFundTransaction"
                WHERE "SavingsFundId" = v_fund_id
                ORDER BY "TransactionId" DESC LIMIT 1
            ), 0)
            INTO v_cur_balance;

            v_cur_balance := v_cur_balance - v_loan_amount;

            INSERT INTO hr."SavingsFundTransaction" (
                "SavingsFundId", "TransactionDate", "TransactionType",
                "Amount", "Balance", "Reference", "Notes", "CreatedAt"
            )
            VALUES (
                v_fund_id,
                CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                'PRESTAMO',
                v_loan_amount,
                v_cur_balance,
                'Desembolso préstamo #' || p_loan_id::TEXT,
                'Aprobado por usuario ' || p_approved_by::TEXT,
                (NOW() AT TIME ZONE 'UTC')
            );

            p_mensaje := 'Préstamo aprobado y desembolsado exitosamente.';
        ELSE
            UPDATE hr."SavingsLoan"
            SET "Status"    = 'RECHAZADO',
                "ApprovedBy" = p_approved_by,
                "Notes"      = COALESCE(p_notes, "Notes"),
                "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            p_mensaje := 'Préstamo rechazado.';
        END IF;

        p_resultado := p_loan_id;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 15. usp_hr_savings_processloanpayment — validate via SavingsFund.CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_savings_processloanpayment(
    p_company_id integer,
    p_loan_id integer,
    p_payment_amount numeric DEFAULT NULL::numeric,
    p_payment_date date DEFAULT NULL::date,
    p_payroll_batch_id integer DEFAULT NULL::integer,
    OUT p_resultado integer,
    OUT p_mensaje character varying
) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_fund_id           INTEGER;
    v_monthly_payment   NUMERIC(18,2);
    v_outstanding       NUMERIC(18,2);
    v_inst_paid         INTEGER;
    v_inst_total        INTEGER;
    v_current_status    VARCHAR(15);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT sl."SavingsFundId", sl."MonthlyPayment", sl."OutstandingBalance",
           sl."InstallmentsPaid", sl."InstallmentsTotal", sl."Status"
    INTO v_fund_id, v_monthly_payment, v_outstanding,
         v_inst_paid, v_inst_total, v_current_status
    FROM hr."SavingsLoan" sl
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = sl."SavingsFundId"
    WHERE sl."LoanId" = p_loan_id
      AND sf."CompanyId" = p_company_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Préstamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden registrar pagos en préstamos ACTIVOS. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_payment_amount IS NULL THEN p_payment_amount := v_monthly_payment; END IF;
    IF p_payment_date   IS NULL THEN p_payment_date   := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;

    IF p_payment_amount > v_outstanding THEN
        p_payment_amount := v_outstanding;
    END IF;

    BEGIN
        v_outstanding := v_outstanding - p_payment_amount;
        v_inst_paid   := v_inst_paid + 1;

        UPDATE hr."SavingsLoan"
        SET "OutstandingBalance"  = v_outstanding,
            "InstallmentsPaid"    = v_inst_paid,
            "Status"              = CASE WHEN v_outstanding <= 0 THEN 'PAGADO' ELSE 'ACTIVO' END,
            "UpdatedAt"           = (NOW() AT TIME ZONE 'UTC')
        WHERE "LoanId" = p_loan_id;

        SELECT COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = v_fund_id
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0)
        INTO v_cur_balance;

        v_cur_balance := v_cur_balance + p_payment_amount;

        INSERT INTO hr."SavingsFundTransaction" (
            "SavingsFundId", "TransactionDate", "TransactionType",
            "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
        )
        VALUES (
            v_fund_id,
            p_payment_date,
            'PAGO_PRESTAMO',
            p_payment_amount,
            v_cur_balance,
            'Pago cuota ' || v_inst_paid::TEXT || '/' || v_inst_total::TEXT || ' préstamo #' || p_loan_id::TEXT,
            p_payroll_batch_id,
            CASE WHEN v_outstanding <= 0 THEN 'Préstamo liquidado' ELSE NULL END,
            (NOW() AT TIME ZONE 'UTC')
        );

        p_resultado := p_loan_id;
        IF v_outstanding <= 0 THEN
            p_mensaje := 'Préstamo liquidado exitosamente.';
        ELSE
            p_mensaje := 'Pago registrado. Saldo pendiente: ' || v_outstanding::TEXT;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 16. usp_pay_transaction_updatestatus — filter by CompanyId on Transactions
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_updatestatus(
    p_company_id integer,
    p_transaction_uuid character varying,
    p_status character varying,
    p_gateway_trx_id character varying DEFAULT NULL::character varying,
    p_gateway_auth_code character varying DEFAULT NULL::character varying,
    p_gateway_response text DEFAULT NULL::text,
    p_gateway_message character varying DEFAULT NULL::character varying
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pay."Transactions"
    SET "Status"          = p_status,
        "GatewayTrxId"    = COALESCE(p_gateway_trx_id, "GatewayTrxId"),
        "GatewayAuthCode" = COALESCE(p_gateway_auth_code, "GatewayAuthCode"),
        "GatewayResponse" = COALESCE(p_gateway_response, "GatewayResponse"),
        "GatewayMessage"  = COALESCE(p_gateway_message, "GatewayMessage"),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE "TransactionUUID" = p_transaction_uuid
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 17. usp_pay_acceptedmethod_deactivate — filter by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pay_acceptedmethod_deactivate(
    p_company_id integer,
    p_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pay."AcceptedPaymentMethods"
    SET "IsActive" = FALSE
    WHERE "Id" = p_id
      AND "EmpresaId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 18. usp_pay_companyconfig_deactivatebyid — filter by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_deactivatebyid(
    p_company_id integer,
    p_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pay."CompanyPaymentConfig"
    SET "IsActive"  = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id
      AND "EmpresaId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 19. usp_inv_bin_list — child of WarehouseZone; validate via Warehouse.CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_bin_list(
    p_company_id integer,
    p_zone_id integer
) RETURNS TABLE(
    "BinId" integer, "ZoneId" integer, "BinCode" character varying,
    "BinName" character varying, "MaxWeight" numeric, "MaxVolume" numeric,
    "IsActive" boolean, "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT b."BinId", b."ZoneId", b."BinCode", b."BinName",
           b."MaxWeight", b."MaxVolume", b."IsActive", b."CreatedAt", b."UpdatedAt"
    FROM inv."WarehouseBin" b
    INNER JOIN inv."WarehouseZone" z ON z."ZoneId" = b."ZoneId"
    INNER JOIN inv."Warehouse" w ON w."WarehouseId" = z."WarehouseId"
    WHERE b."ZoneId" = p_zone_id
      AND w."CompanyId" = p_company_id
    ORDER BY b."BinCode";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 20. usp_inv_bin_upsert — validate zone belongs to company warehouse
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_bin_upsert(
    p_company_id integer,
    p_bin_id integer DEFAULT NULL::integer,
    p_zone_id integer DEFAULT NULL::integer,
    p_bin_code character varying DEFAULT NULL::character varying,
    p_bin_name character varying DEFAULT NULL::character varying,
    p_max_weight numeric DEFAULT NULL::numeric,
    p_max_volume numeric DEFAULT NULL::numeric,
    p_is_active boolean DEFAULT true,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate zone belongs to a warehouse of the company
    IF NOT EXISTS (
        SELECT 1 FROM inv."WarehouseZone" z
        INNER JOIN inv."Warehouse" w ON w."WarehouseId" = z."WarehouseId"
        WHERE z."ZoneId" = p_zone_id AND w."CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0, 'Zona no pertenece a un almacen de esta empresa'::VARCHAR;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM inv."WarehouseBin"
        WHERE "ZoneId" = p_zone_id
          AND "BinCode" = p_bin_code
          AND (p_bin_id IS NULL OR "BinId" <> p_bin_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de ubicacion ya existe en esta zona'::VARCHAR;
        RETURN;
    END IF;

    IF p_bin_id IS NULL THEN
        INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight",
            "MaxVolume", "IsActive", "CreatedBy", "CreatedAt")
        VALUES (p_zone_id, p_bin_code, p_bin_name, p_max_weight,
            p_max_volume, p_is_active, p_user_id, NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Ubicacion creada'::VARCHAR;
    ELSE
        UPDATE inv."WarehouseBin"
        SET "BinCode"   = p_bin_code,
            "BinName"   = p_bin_name,
            "MaxWeight" = p_max_weight,
            "MaxVolume" = p_max_volume,
            "IsActive"  = p_is_active,
            "UpdatedBy" = p_user_id,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "BinId" = p_bin_id;

        RETURN QUERY SELECT 1, 'Ubicacion actualizada'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 21. usp_inv_zone_list — child of Warehouse; validate CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_zone_list(
    p_company_id integer,
    p_warehouse_id integer
) RETURNS TABLE(
    "ZoneId" integer, "WarehouseId" integer, "ZoneCode" character varying,
    "ZoneName" character varying, "ZoneType" character varying,
    "Temperature" character varying, "IsActive" boolean,
    "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT z."ZoneId", z."WarehouseId", z."ZoneCode", z."ZoneName",
           z."ZoneType", z."Temperature", z."IsActive", z."CreatedAt", z."UpdatedAt"
    FROM inv."WarehouseZone" z
    INNER JOIN inv."Warehouse" w ON w."WarehouseId" = z."WarehouseId"
    WHERE z."WarehouseId" = p_warehouse_id
      AND w."CompanyId" = p_company_id
    ORDER BY z."ZoneCode";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 22. usp_inv_zone_upsert — validate warehouse belongs to company
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_zone_upsert(
    p_company_id integer,
    p_zone_id integer DEFAULT NULL::integer,
    p_warehouse_id integer DEFAULT NULL::integer,
    p_zone_code character varying DEFAULT NULL::character varying,
    p_zone_name character varying DEFAULT NULL::character varying,
    p_zone_type character varying DEFAULT NULL::character varying,
    p_temperature character varying DEFAULT NULL::character varying,
    p_is_active boolean DEFAULT true,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate warehouse belongs to company
    IF NOT EXISTS (
        SELECT 1 FROM inv."Warehouse" w
        WHERE w."WarehouseId" = p_warehouse_id AND w."CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0, 'Almacen no pertenece a esta empresa'::VARCHAR;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM inv."WarehouseZone"
        WHERE "WarehouseId" = p_warehouse_id
          AND "ZoneCode" = p_zone_code
          AND (p_zone_id IS NULL OR "ZoneId" <> p_zone_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de zona ya existe en este almacen'::VARCHAR;
        RETURN;
    END IF;

    IF p_zone_id IS NULL THEN
        INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType",
            "Temperature", "IsActive", "CreatedBy", "CreatedAt")
        VALUES (p_warehouse_id, p_zone_code, p_zone_name, p_zone_type,
            p_temperature, p_is_active, p_user_id, NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Zona creada'::VARCHAR;
    ELSE
        UPDATE inv."WarehouseZone"
        SET "ZoneCode"    = p_zone_code,
            "ZoneName"    = p_zone_name,
            "ZoneType"    = p_zone_type,
            "Temperature" = p_temperature,
            "IsActive"    = p_is_active,
            "UpdatedBy"   = p_user_id,
            "UpdatedAt"   = NOW() AT TIME ZONE 'UTC'
        WHERE "ZoneId" = p_zone_id;

        RETURN QUERY SELECT 1, 'Zona actualizada'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 23. usp_inv_movement_getbyid — filter InventoryMovement by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_movement_getbyid(
    p_company_id integer,
    p_id integer
) RETURNS TABLE(
    "MovementId" bigint, "Codigo" character varying, "Product" character varying,
    "Documento" character varying, "Tipo" character varying,
    "Fecha" timestamp without time zone, "Quantity" numeric,
    "UnitCost" numeric, "TotalCost" numeric, "Notes" character varying
)
    LANGUAGE plpgsql
    AS $$ BEGIN
    RETURN QUERY SELECT m."MovementId",m."ProductCode",m."ProductName",m."DocumentRef",
        m."MovementType",m."MovementDate"::TIMESTAMP,m."Quantity",m."UnitCost",m."TotalCost",m."Notes"
    FROM master."InventoryMovement" m
    WHERE m."MovementId"=p_id AND m."IsDeleted"=FALSE AND m."CompanyId"=p_company_id;
END; $$;
-- +goose StatementEnd

-- ============================================================================
-- 24. usp_inv_movement_listperiodsummary — add CompanyId filter
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_company_id integer,
    p_periodo character varying DEFAULT NULL::character varying,
    p_codigo character varying DEFAULT NULL::character varying,
    p_offset integer DEFAULT 0,
    p_limit integer DEFAULT 50
) RETURNS TABLE(
    "SummaryId" integer, "Periodo" character varying, "Codigo" character varying,
    "OpeningQty" numeric, "InboundQty" numeric, "OutboundQty" numeric,
    "ClosingQty" numeric, fecha timestamp without time zone,
    "IsClosed" boolean, "TotalCount" bigint
)
    LANGUAGE plpgsql
    AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE "CompanyId" = p_company_id
      AND (p_periodo IS NULL OR "Period"=p_periodo)
      AND (p_codigo IS NULL OR "ProductCode"=p_codigo);

    RETURN QUERY SELECT s."SummaryId",s."Period",s."ProductCode",s."OpeningQty",
        s."InboundQty",s."OutboundQty",s."ClosingQty",s."SummaryDate",s."IsClosed",v_total
    FROM master."InventoryPeriodSummary" s
    WHERE s."CompanyId" = p_company_id
      AND (p_periodo IS NULL OR s."Period"=p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode"=p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END; $$;
-- +goose StatementEnd

-- ============================================================================
-- 25. usp_inv_lot_get — filter ProductLot by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_lot_get(
    p_company_id integer,
    p_lot_id bigint
) RETURNS TABLE(
    "LotId" bigint, "CompanyId" integer, "ProductId" bigint,
    "LotNumber" character varying, "ManufactureDate" date, "ExpiryDate" date,
    "SupplierCode" character varying, "PurchaseDocumentNumber" character varying,
    "InitialQuantity" numeric, "CurrentQuantity" numeric, "UnitCost" numeric,
    "Status" character varying, "CreatedAt" timestamp without time zone
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT l."LotId", l."CompanyId", l."ProductId", l."LotNumber",
           l."ManufactureDate", l."ExpiryDate", l."SupplierCode",
           l."PurchaseDocumentNumber", l."InitialQuantity", l."CurrentQuantity",
           l."UnitCost", l."Status", l."CreatedAt"
    FROM inv."ProductLot" l
    WHERE l."LotId" = p_lot_id
      AND l."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 26. usp_inv_serial_get — filter ProductSerial by CompanyId
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_serial_get(
    p_company_id integer,
    p_serial_id bigint
) RETURNS TABLE(
    "SerialId" bigint, "CompanyId" integer, "ProductId" bigint,
    "SerialNumber" character varying, "LotId" bigint, "WarehouseId" bigint,
    "BinId" bigint, "Status" character varying,
    "PurchaseDocumentNumber" character varying,
    "SalesDocumentNumber" character varying, "CustomerId" bigint,
    "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone,
    "WarehouseName" character varying, "BinCode" character varying,
    "LotNumber" character varying
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT s."SerialId", s."CompanyId", s."ProductId", s."SerialNumber", s."LotId",
           s."WarehouseId", s."BinId", s."Status",
           s."PurchaseDocumentNumber", s."SalesDocumentNumber", s."CustomerId",
           s."CreatedAt", s."UpdatedAt",
           w."WarehouseName", b."BinCode", l."LotNumber"
    FROM inv."ProductSerial" s
    LEFT JOIN inv."Warehouse" w ON s."WarehouseId" = w."WarehouseId"
    LEFT JOIN inv."WarehouseBin" b ON s."BinId" = b."BinId"
    LEFT JOIN inv."ProductLot" l ON s."LotId" = l."LotId"
    WHERE s."SerialId" = p_serial_id
      AND s."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 27. usp_inv_serial_updatestatus — filter by CompanyId on ProductSerial
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_serial_updatestatus(
    p_company_id integer,
    p_serial_id integer,
    p_status character varying,
    p_sales_document_number character varying DEFAULT NULL::character varying,
    p_customer_id bigint DEFAULT NULL::bigint,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM inv."ProductSerial"
        WHERE "SerialId" = p_serial_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0, 'Serial no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE inv."ProductSerial"
    SET "Status"               = p_status,
        "SalesDocumentNumber"  = COALESCE(p_sales_document_number, "SalesDocumentNumber"),
        "CustomerId"           = COALESCE(p_customer_id, "CustomerId"),
        "UpdatedBy"            = p_user_id,
        "UpdatedAt"            = NOW() AT TIME ZONE 'UTC'
    WHERE "SerialId" = p_serial_id
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'Estado de serial actualizado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- Revert all functions to their original signatures without p_company_id.
-- Since these are CREATE OR REPLACE, a rollback would require restoring the
-- original function signatures. In practice, the baseline 005_functions.sql
-- contains the original definitions. A full rollback should re-run the baseline.
-- Individual DROP statements are not safe because callers may depend on these functions.
