-- =============================================================================
-- sp_rrhh_beneficios.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_beneficios.sql
-- Fecha conversiÃ³n: 2026-03-16
--
-- Beneficios Laborales (LOTTT Venezuela):
--   1. Utilidades (Profit Sharing) - Art. 131-140
--   2. Fideicomiso / Prestaciones Sociales (Social Benefits Trust) - Art. 141-143
--   3. Caja de Ahorro (Savings Fund)
--
-- Funciones (16 en total):
--   1.  usp_HR_ProfitSharing_Generate        - Generar cÃ¡lculo de utilidades
--   2.  usp_HR_ProfitSharing_GetSummary      - Resumen cabecera + detalle
--   3.  usp_HR_ProfitSharing_Approve         - Aprobar utilidades
--   4.  usp_HR_ProfitSharing_List            - Listado paginado de utilidades
--   5.  usp_HR_Trust_CalculateQuarter        - Calcular fideicomiso trimestral
--   6.  usp_HR_Trust_GetEmployeeBalance      - Saldo y historial por empleado
--   7.  usp_HR_Trust_GetSummary              - Resumen trimestral
--   8.  usp_HR_Trust_List                    - Listado paginado
--   9.  usp_HR_Savings_Enroll                - Inscribir empleado
--   10. usp_HR_Savings_ProcessMonthly        - Procesar aportes mensuales
--   11. usp_HR_Savings_GetBalance            - Saldo y transacciones
--   12. usp_HR_Savings_RequestLoan           - Solicitar prÃ©stamo
--   13. usp_HR_Savings_ApproveLoan           - Aprobar/rechazar prÃ©stamo
--   14. usp_HR_Savings_ProcessLoanPayment    - Registrar pago de prÃ©stamo
--   15. usp_HR_Savings_List                  - Listado paginado de afiliados
--   16. usp_HR_Savings_LoanList              - Listado paginado de prÃ©stamos
-- =============================================================================

-- =============================================================================
-- 1. usp_HR_ProfitSharing_Generate
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Generate(INTEGER, INTEGER, INTEGER, INTEGER, NUMERIC(18,2), INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_Generate(
    p_company_id            INTEGER,
    p_branch_id             INTEGER,
    p_fiscal_year           INTEGER,
    p_days_granted          INTEGER,
    p_total_company_profits NUMERIC(18,2)   DEFAULT NULL,
    p_created_by            INTEGER         DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_id            INTEGER;
    v_ps_id             INTEGER;
    v_year_start        DATE;
    v_year_end          DATE;
    v_total_days        INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_days_granted < 30 OR p_days_granted > 120 THEN
        p_resultado := -1;
        p_mensaje   := 'Los dÃ­as otorgados deben estar entre 30 y 120 (LOTTT Art. 131).';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "FiscalYear" = p_fiscal_year
          AND "Status" IN ('CALCULADA','PROCESADA','CERRADA')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cÃ¡lculo de utilidades procesado para este aÃ±o fiscal.';
        RETURN;
    END IF;

    BEGIN
        v_year_start     := MAKE_DATE(p_fiscal_year, 1, 1);
        v_year_end       := MAKE_DATE(p_fiscal_year, 12, 31);
        v_total_days     := (v_year_end - v_year_start) + 1;

        -- Eliminar borrador previo si existe
        SELECT "ProfitSharingId" INTO v_old_id
        FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "FiscalYear" = p_fiscal_year AND "Status" = 'BORRADOR';

        IF v_old_id IS NOT NULL THEN
            DELETE FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = v_old_id;
            DELETE FROM hr."ProfitSharing"     WHERE "ProfitSharingId" = v_old_id;
        END IF;

        INSERT INTO hr."ProfitSharing" (
            "CompanyId", "BranchId", "FiscalYear", "DaysGranted",
            "TotalCompanyProfits", "Status", "CreatedBy", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_branch_id, p_fiscal_year, p_days_granted,
            p_total_company_profits, 'CALCULADA', p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ProfitSharingId" INTO v_ps_id;

        INSERT INTO hr."ProfitSharingLine" (
            "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
            "GrossAmount", "InceDeduction", "NetAmount"
        )
        SELECT
            v_ps_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) AS "MonthlySalary",
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            -- DaysWorked: desde mayor(HireDate, YearStart) hasta menor(hoy, YearEnd)
            (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
             - GREATEST(e."HireDate", v_year_start) + 1)::INTEGER AS "DaysWorked",
            -- DaysEntitled = (DaysWorked / TotalDays) * DaysGranted
            ROUND(
                (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                 - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                / v_total_days::NUMERIC * p_days_granted,
            2) AS "DaysEntitled",
            -- GrossAmount = DailySalary * DaysEntitled
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2),
            2) AS "GrossAmount",
            -- InceDeduction = GrossAmount * 0.5%
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2) * 0.005,
            2) AS "InceDeduction",
            -- NetAmount = GrossAmount - InceDeduction
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2)
                -
                ROUND(
                    (COALESCE((
                        SELECT prl."Amount"
                        FROM hr."PayrollRun" pr
                        INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                        WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                        ORDER BY pr."CreatedAt" DESC LIMIT 1
                    ), 0) / 30.0)
                    * ROUND(
                        (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                         - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                        / v_total_days::NUMERIC * p_days_granted,
                    2) * 0.005,
                2),
            2) AS "NetAmount"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= v_year_end
          AND (e."TerminationDate" IS NULL OR e."TerminationDate" >= v_year_start);

        p_resultado := v_ps_id;
        p_mensaje   := 'Utilidades generadas exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 2. usp_HR_ProfitSharing_GetSummary
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_GetSummary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_GetSummary(
    p_profit_sharing_id INTEGER
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
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
    WHERE ps."ProfitSharingId" = p_profit_sharing_id;

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
    WHERE l."ProfitSharingId" = p_profit_sharing_id
    ORDER BY l."EmployeeName";
END;
$$;

-- =============================================================================
-- 3. usp_HR_ProfitSharing_Approve
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Approve(INTEGER, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_Approve(
    p_profit_sharing_id INTEGER,
    p_approved_by       INTEGER,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status" INTO v_current_status
    FROM hr."ProfitSharing"
    WHERE "ProfitSharingId" = p_profit_sharing_id;

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
    WHERE "ProfitSharingId" = p_profit_sharing_id;

    p_resultado := p_profit_sharing_id;
    p_mensaje   := 'Utilidades aprobadas exitosamente.';
END;
$$;

-- =============================================================================
-- 4. usp_HR_ProfitSharing_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_List(INTEGER, INTEGER, INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_List(INTEGER, INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_List(
    p_company_id    INTEGER,
    p_year          INTEGER         DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "ProfitSharingId"   INTEGER,
    "CompanyId"         INTEGER,
    "FiscalYear"        INTEGER,
    "DaysGranted"       INTEGER,
    "TotalCompanyProfits" NUMERIC(18,2),
    "Status"            VARCHAR(20),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP,
    "TotalEmployees"    BIGINT,
    "TotalNet"          NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()                                                                                           AS p_total_count,
        ps."ProfitSharingId",
        ps."CompanyId",
        ps."FiscalYear",
        ps."DaysGranted",
        ps."TotalCompanyProfits",
        ps."Status",
        ps."CreatedAt",
        ps."UpdatedAt",
        (SELECT COUNT(*) FROM hr."ProfitSharingLine" psl WHERE psl."ProfitSharingId" = ps."ProfitSharingId")::BIGINT     AS "TotalEmployees",
        COALESCE((SELECT SUM(psl2."NetAmount") FROM hr."ProfitSharingLine" psl2 WHERE psl2."ProfitSharingId" = ps."ProfitSharingId"), 0) AS "TotalNet"
    FROM hr."ProfitSharing" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_year     IS NULL OR ps."FiscalYear"  = p_year)
      AND (p_status   IS NULL OR ps."Status"      = p_status)
    ORDER BY ps."FiscalYear" DESC, ps."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 5. usp_HR_Trust_CalculateQuarter
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_CalculateQuarter(INTEGER, INTEGER, SMALLINT, NUMERIC(8,5), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_CalculateQuarter(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER,
    p_quarter       SMALLINT,
    p_interest_rate NUMERIC(8,5)    DEFAULT 0,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted      INTEGER;
    v_year_end_str  TEXT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_quarter < 1 OR p_quarter > 4 THEN
        p_resultado := -1;
        p_mensaje   := 'El trimestre debe estar entre 1 y 4.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SocialBenefitsTrust"
        WHERE "CompanyId" = p_company_id AND "FiscalYear" = p_fiscal_year AND "Quarter" = p_quarter
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cÃ¡lculo para el trimestre ' || p_quarter::TEXT || ' del aÃ±o ' || p_fiscal_year::TEXT || '.';
        RETURN;
    END IF;

    v_year_end_str := p_fiscal_year::TEXT || '-12-31';

    BEGIN
        INSERT INTO hr."SocialBenefitsTrust" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "FiscalYear", "Quarter", "DailySalary",
            "DaysDeposited", "BonusDays", "DepositAmount",
            "InterestRate", "InterestAmount", "AccumulatedBalance", "Status",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_company_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            p_fiscal_year,
            p_quarter,
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            15 AS "DaysDeposited",
            -- BonusDays: 2 dÃ­as por cada aÃ±o despuÃ©s del primero, max 30, solo en Q4
            CASE
                WHEN p_quarter = 4
                 AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                THEN LEAST(
                    (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                    30
                )
                ELSE 0
            END AS "BonusDays",
            -- DepositAmount = DailySalary * (15 + BonusDays)
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2) AS "DepositAmount",
            p_interest_rate,
            -- InterestAmount = saldo acumulado anterior * tasa / 4
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "InterestAmount",
            -- AccumulatedBalance = saldo anterior + deposito + interes
            COALESCE((
                SELECT t."AccumulatedBalance"
                FROM hr."SocialBenefitsTrust" t
                WHERE t."CompanyId" = p_company_id
                  AND t."EmployeeCode" = e."EmployeeCode"
                  AND (t."FiscalYear" < p_fiscal_year
                       OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                LIMIT 1
            ), 0)
            +
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2)
            +
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "AccumulatedBalance",
            'PENDIENTE',
            (NOW() AT TIME ZONE 'UTC'),
            (NOW() AT TIME ZONE 'UTC')
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= MAKE_DATE(p_fiscal_year, p_quarter * 3, 28);

        GET DIAGNOSTICS v_inserted = ROW_COUNT;

        p_resultado := v_inserted;
        p_mensaje   := 'Fideicomiso calculado para ' || v_inserted::TEXT || ' empleados.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_Trust_GetEmployeeBalance
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetEmployeeBalance(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_GetEmployeeBalance(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Saldo actual (1 fila)
    RETURN QUERY
    SELECT
        'BALANCE'::TEXT,
        jsonb_build_object(
            'EmployeeCode',     t."EmployeeCode",
            'EmployeeName',     t."EmployeeName",
            'CurrentBalance',   t."AccumulatedBalance",
            'LastFiscalYear',   t."FiscalYear",
            'LastQuarter',      t."Quarter"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
    LIMIT 1;

    -- Historial
    RETURN QUERY
    SELECT
        'HISTORY'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'FiscalYear',           t."FiscalYear",
            'Quarter',              t."Quarter",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status",
            'CreatedAt',            t."CreatedAt"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear", t."Quarter";
END;
$$;

-- =============================================================================
-- 7. usp_HR_Trust_GetSummary
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetSummary(INTEGER, INTEGER, SMALLINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_GetSummary(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER,
    p_quarter       SMALLINT
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Resumen por estado
    RETURN QUERY
    SELECT
        'SUMMARY'::TEXT,
        jsonb_build_object(
            'TotalEmployees',           COUNT(*),
            'TotalDeposits',            SUM(t."DepositAmount"),
            'TotalInterest',            SUM(t."InterestAmount"),
            'TotalBonusDays',           SUM(t."BonusDays"),
            'TotalAccumulatedBalance',  SUM(t."AccumulatedBalance"),
            'Status',                   t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    GROUP BY t."Status";

    -- Detalle por empleado
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'EmployeeCode',         t."EmployeeCode",
            'EmployeeName',         t."EmployeeName",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    ORDER BY t."EmployeeName";
END;
$$;

-- =============================================================================
-- 8. usp_HR_Trust_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_List(INTEGER, INTEGER, SMALLINT, VARCHAR(24), VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_List(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER         DEFAULT NULL,
    p_quarter       SMALLINT        DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "TrustId"               INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "FiscalYear"            INTEGER,
    "Quarter"               SMALLINT,
    "DailySalary"           NUMERIC(18,2),
    "DaysDeposited"         INTEGER,
    "BonusDays"             INTEGER,
    "DepositAmount"         NUMERIC(18,2),
    "InterestRate"          NUMERIC(8,5),
    "InterestAmount"        NUMERIC(18,2),
    "AccumulatedBalance"    NUMERIC(18,2),
    "Status"                VARCHAR(20),
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        t."TrustId",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."FiscalYear",
        t."Quarter",
        t."DailySalary",
        t."DaysDeposited",
        t."BonusDays",
        t."DepositAmount",
        t."InterestRate",
        t."InterestAmount",
        t."AccumulatedBalance",
        t."Status",
        t."CreatedAt"
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id
      AND (p_fiscal_year   IS NULL OR t."FiscalYear"    = p_fiscal_year)
      AND (p_quarter       IS NULL OR t."Quarter"        = p_quarter)
      AND (p_employee_code IS NULL OR t."EmployeeCode"   = p_employee_code)
      AND (p_status        IS NULL OR t."Status"         = p_status)
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC, t."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 9. usp_HR_Savings_Enroll
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_Enroll(INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), NUMERIC(8,4), NUMERIC(8,4), DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_Enroll(
    p_company_id                INTEGER,
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_employee_contribution     NUMERIC(8,4)    DEFAULT NULL,
    p_employer_match            NUMERIC(8,4)    DEFAULT NULL,
    p_enrollment_date           DATE            DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM hr."SavingsFund"
        WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya estÃ¡ inscrito en la caja de ahorro.';
        RETURN;
    END IF;

    IF p_employee_contribution <= 0 OR p_employer_match < 0 THEN
        p_resultado := -2;
        p_mensaje   := 'El porcentaje de aporte del empleado debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SavingsFund" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_employee_contribution, p_employer_match, p_enrollment_date, 'ACTIVO',
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "SavingsFundId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito en caja de ahorro exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_Savings_ProcessMonthly
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessMonthly(INTEGER, DATE, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ProcessMonthly(
    p_company_id        INTEGER,
    p_process_date      DATE,
    p_payroll_batch_id  INTEGER         DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fund_id       INTEGER;
    v_emp_code      VARCHAR(24);
    v_emp_contrib   NUMERIC(8,4);
    v_match_pct     NUMERIC(8,4);
    v_salary        NUMERIC(18,2);
    v_emp_amount    NUMERIC(18,2);
    v_match_amount  NUMERIC(18,2);
    v_cur_balance   NUMERIC(18,2);
    v_processed     INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        FOR v_fund_id, v_emp_code, v_emp_contrib, v_match_pct IN
            SELECT sf."SavingsFundId", sf."EmployeeCode", sf."EmployeeContribution", sf."EmployerMatch"
            FROM hr."SavingsFund" sf
            WHERE sf."CompanyId" = p_company_id AND sf."Status" = 'ACTIVO'
        LOOP
            SELECT COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0)
            INTO v_salary
            FROM master."Employee" e
            WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = v_emp_code AND e."IsActive" = TRUE;

            IF v_salary IS NOT NULL AND v_salary > 0 THEN
                v_emp_amount   := ROUND(v_salary * v_emp_contrib / 100.0, 2);
                v_match_amount := ROUND(v_salary * v_match_pct  / 100.0, 2);

                SELECT COALESCE((
                    SELECT "Balance" FROM hr."SavingsFundTransaction"
                    WHERE "SavingsFundId" = v_fund_id
                    ORDER BY "TransactionId" DESC LIMIT 1
                ), 0)
                INTO v_cur_balance;

                v_cur_balance := v_cur_balance + v_emp_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_EMPLEADO',
                    v_emp_amount, v_cur_balance,
                    'Aporte mensual ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_cur_balance := v_cur_balance + v_match_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_PATRONAL',
                    v_match_amount, v_cur_balance,
                    'Aporte patronal ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_processed := v_processed + 1;
            END IF;
        END LOOP;

        p_resultado := v_processed;
        p_mensaje   := 'Aportes procesados para ' || v_processed::TEXT || ' miembros.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 11. usp_HR_Savings_GetBalance
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_GetBalance(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_GetBalance(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Datos del fondo
    RETURN QUERY
    SELECT
        'FUND'::TEXT,
        jsonb_build_object(
            'SavingsFundId',        sf."SavingsFundId",
            'EmployeeCode',         sf."EmployeeCode",
            'EmployeeName',         sf."EmployeeName",
            'EmployeeContribution', sf."EmployeeContribution",
            'EmployerMatch',        sf."EmployerMatch",
            'EnrollmentDate',       sf."EnrollmentDate",
            'Status',               sf."Status",
            'CurrentBalance',       COALESCE((
                                        SELECT "Balance" FROM hr."SavingsFundTransaction"
                                        WHERE "SavingsFundId" = sf."SavingsFundId"
                                        ORDER BY "TransactionId" DESC LIMIT 1
                                    ), 0)
        )
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code;

    -- Historial de transacciones
    RETURN QUERY
    SELECT
        'TRANSACTION'::TEXT,
        jsonb_build_object(
            'TransactionId',    tx."TransactionId",
            'TransactionDate',  tx."TransactionDate",
            'TransactionType',  tx."TransactionType",
            'Amount',           tx."Amount",
            'Balance',          tx."Balance",
            'Reference',        tx."Reference",
            'PayrollBatchId',   tx."PayrollBatchId",
            'Notes',            tx."Notes",
            'CreatedAt',        tx."CreatedAt"
        )
    FROM hr."SavingsFundTransaction" tx
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = tx."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code
    ORDER BY tx."TransactionDate" DESC, tx."TransactionId" DESC;
END;
$$;

-- =============================================================================
-- 12. usp_HR_Savings_RequestLoan
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_RequestLoan(INTEGER, VARCHAR(24), NUMERIC(18,2), NUMERIC(8,5), INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_RequestLoan(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(24),
    p_loan_amount       NUMERIC(18,2),
    p_interest_rate     NUMERIC(8,5)    DEFAULT 0,
    p_installments_total INTEGER        DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fund_id       INTEGER;
    v_total_payable NUMERIC(18,2);
    v_monthly_pmt   NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "SavingsFundId" INTO v_fund_id
    FROM hr."SavingsFund"
    WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO';

    IF v_fund_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado no tiene una cuenta activa en caja de ahorro.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SavingsLoan"
        WHERE "SavingsFundId" = v_fund_id AND "Status" IN ('SOLICITADO','APROBADO','ACTIVO')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene un prÃ©stamo activo o pendiente.';
        RETURN;
    END IF;

    IF p_loan_amount <= 0 THEN
        p_resultado := -3;
        p_mensaje   := 'El monto del prÃ©stamo debe ser mayor a cero.';
        RETURN;
    END IF;

    IF p_installments_total <= 0 THEN
        p_resultado := -4;
        p_mensaje   := 'El nÃºmero de cuotas debe ser mayor a cero.';
        RETURN;
    END IF;

    v_total_payable := ROUND(p_loan_amount * (1 + p_interest_rate / 100.0), 2);
    v_monthly_pmt   := ROUND(v_total_payable / p_installments_total, 2);

    BEGIN
        INSERT INTO hr."SavingsLoan" (
            "SavingsFundId", "EmployeeCode", "RequestDate",
            "LoanAmount", "InterestRate", "TotalPayable", "MonthlyPayment",
            "InstallmentsTotal", "InstallmentsPaid", "OutstandingBalance",
            "Status", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_fund_id, p_employee_code, CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
            p_loan_amount, p_interest_rate, v_total_payable, v_monthly_pmt,
            p_installments_total, 0, v_total_payable,
            'SOLICITADO', p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "LoanId" INTO p_resultado;

        p_mensaje := 'Solicitud de prÃ©stamo registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 13. usp_HR_Savings_ApproveLoan
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ApproveLoan(INTEGER, BOOLEAN, INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ApproveLoan(
    p_loan_id       INTEGER,
    p_approved      BOOLEAN,
    p_approved_by   INTEGER,
    p_notes         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
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

    SELECT "Status", "SavingsFundId", "LoanAmount"
    INTO v_current_status, v_fund_id, v_loan_amount
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'PrÃ©stamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'SOLICITADO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar/rechazar prÃ©stamos en estado SOLICITADO. Estado actual: ' || v_current_status;
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
                'Desembolso prÃ©stamo #' || p_loan_id::TEXT,
                'Aprobado por usuario ' || p_approved_by::TEXT,
                (NOW() AT TIME ZONE 'UTC')
            );

            p_mensaje := 'PrÃ©stamo aprobado y desembolsado exitosamente.';
        ELSE
            UPDATE hr."SavingsLoan"
            SET "Status"    = 'RECHAZADO',
                "ApprovedBy" = p_approved_by,
                "Notes"      = COALESCE(p_notes, "Notes"),
                "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            p_mensaje := 'PrÃ©stamo rechazado.';
        END IF;

        p_resultado := p_loan_id;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 14. usp_HR_Savings_ProcessLoanPayment
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessLoanPayment(INTEGER, NUMERIC(18,2), DATE, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ProcessLoanPayment(
    p_loan_id           INTEGER,
    p_payment_amount    NUMERIC(18,2)   DEFAULT NULL,
    p_payment_date      DATE            DEFAULT NULL,
    p_payroll_batch_id  INTEGER         DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
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

    SELECT "SavingsFundId", "MonthlyPayment", "OutstandingBalance",
           "InstallmentsPaid", "InstallmentsTotal", "Status"
    INTO v_fund_id, v_monthly_payment, v_outstanding,
         v_inst_paid, v_inst_total, v_current_status
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'PrÃ©stamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden registrar pagos en prÃ©stamos ACTIVOS. Estado actual: ' || v_current_status;
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
            'Pago cuota ' || v_inst_paid::TEXT || '/' || v_inst_total::TEXT || ' prÃ©stamo #' || p_loan_id::TEXT,
            p_payroll_batch_id,
            CASE WHEN v_outstanding <= 0 THEN 'PrÃ©stamo liquidado' ELSE NULL END,
            (NOW() AT TIME ZONE 'UTC')
        );

        p_resultado := p_loan_id;
        IF v_outstanding <= 0 THEN
            p_mensaje := 'PrÃ©stamo liquidado exitosamente.';
        ELSE
            p_mensaje := 'Pago registrado. Saldo pendiente: ' || v_outstanding::TEXT;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 15. usp_HR_Savings_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_List(INTEGER, VARCHAR(15), VARCHAR(24), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_List(
    p_company_id    INTEGER,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "SavingsFundId"         INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "EmployeeContribution"  NUMERIC(8,4),
    "EmployerMatch"         NUMERIC(8,4),
    "EnrollmentDate"        DATE,
    "Status"                VARCHAR(15),
    "CreatedAt"             TIMESTAMP,
    "CurrentBalance"        NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sf."SavingsFundId",
        sf."EmployeeId",
        sf."EmployeeCode",
        sf."EmployeeName",
        sf."EmployeeContribution",
        sf."EmployerMatch",
        sf."EnrollmentDate",
        sf."Status",
        sf."CreatedAt",
        COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = sf."SavingsFundId"
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0::NUMERIC) AS "CurrentBalance"
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sf."Status"       = p_status)
      AND (p_employee_code IS NULL OR sf."EmployeeCode" = p_employee_code)
    ORDER BY sf."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 16. usp_HR_Savings_LoanList
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_LoanList(INTEGER, VARCHAR(15), VARCHAR(24), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_LoanList(
    p_company_id    INTEGER,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "LoanId"                INTEGER,
    "SavingsFundId"         INTEGER,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "RequestDate"           DATE,
    "ApprovedDate"          DATE,
    "LoanAmount"            NUMERIC(18,2),
    "InterestRate"          NUMERIC(8,4),
    "TotalPayable"          NUMERIC(18,2),
    "MonthlyPayment"        NUMERIC(18,2),
    "InstallmentsTotal"     INTEGER,
    "InstallmentsPaid"      INTEGER,
    "OutstandingBalance"    NUMERIC(18,2),
    "Status"                VARCHAR(15),
    "ApprovedBy"            INTEGER,
    "Notes"                 VARCHAR(500),
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sl."LoanId",
        sl."SavingsFundId",
        sl."EmployeeCode",
        sf."EmployeeName",
        sl."RequestDate",
        sl."ApprovedDate",
        sl."LoanAmount",
        sl."InterestRate",
        sl."TotalPayable",
        sl."MonthlyPayment",
        sl."InstallmentsTotal",
        sl."InstallmentsPaid",
        sl."OutstandingBalance",
        sl."Status",
        sl."ApprovedBy",
        sl."Notes",
        sl."CreatedAt"
    FROM hr."SavingsLoan" sl
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = sl."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sl."Status"       = p_status)
      AND (p_employee_code IS NULL OR sl."EmployeeCode" = p_employee_code)
    ORDER BY sl."RequestDate" DESC, sl."LoanId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
