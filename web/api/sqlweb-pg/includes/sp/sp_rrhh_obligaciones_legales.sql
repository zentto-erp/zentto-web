-- =============================================================================
-- sp_rrhh_obligaciones_legales.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_obligaciones_legales.sql
-- Fecha conversión: 2026-03-16
--
-- Obligaciones Legales de RRHH (SSO, FAOV, INCE, TGSS, IMSS, EPS, FICA, etc.)
-- Modelo genérico, agnóstico de país, orientado a configuración.
--
-- Tablas:
--   hr.LegalObligation, hr.ObligationRiskLevel,
--   hr.EmployeeObligation, hr.ObligationFiling, hr.ObligationFilingDetail
--
-- Funciones:
--   1.  usp_HR_Obligation_List            - Listado paginado de obligaciones
--   2.  usp_HR_Obligation_Save            - Insertar/actualizar obligación
--   3.  usp_HR_Obligation_GetByCountry    - Obligaciones activas por país
--   4.  usp_HR_EmployeeObligation_Enroll  - Inscribir empleado en obligación
--   5.  usp_HR_EmployeeObligation_Disenroll - Desinscribir empleado
--   6.  usp_HR_EmployeeObligation_GetByEmployee - Obligaciones de un empleado
--   7.  usp_HR_Filing_Generate            - Generar declaración para un período
--   8.  usp_HR_Filing_GetSummary          - Cabecera + detalle de declaración
--   9.  usp_HR_Filing_MarkFiled           - Marcar como presentada
--   10. usp_HR_Filing_List                - Listado paginado de declaraciones
-- =============================================================================

-- =============================================================================
-- 1. usp_HR_Obligation_List
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_List(
    p_country_code      CHAR(2)         DEFAULT NULL,
    p_obligation_type   VARCHAR(20)     DEFAULT NULL,
    p_is_active         BOOLEAN         DEFAULT NULL,
    p_search            VARCHAR(100)    DEFAULT NULL,
    p_page              INTEGER         DEFAULT 1,
    p_limit             INTEGER         DEFAULT 50,
    OUT p_total_count   INTEGER
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO p_total_count
    FROM hr."LegalObligation"
    WHERE (p_country_code    IS NULL OR "CountryCode"    = p_country_code)
      AND (p_obligation_type IS NULL OR "ObligationType" = p_obligation_type)
      AND (p_is_active       IS NULL OR "IsActive"       = p_is_active)
      AND (p_search          IS NULL OR "Name" ILIKE '%' || p_search || '%'
                                     OR "Code" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        "LegalObligationId",
        "CountryCode",
        "Code",
        "Name",
        "InstitutionName",
        "ObligationType",
        "CalculationBasis",
        "SalaryCap",
        "SalaryCapUnit",
        "EmployerRate",
        "EmployeeRate",
        "RateVariableByRisk",
        "FilingFrequency",
        "FilingDeadlineRule",
        "EffectiveFrom",
        "EffectiveTo",
        "IsActive",
        "Notes"
    FROM hr."LegalObligation"
    WHERE (p_country_code    IS NULL OR "CountryCode"    = p_country_code)
      AND (p_obligation_type IS NULL OR "ObligationType" = p_obligation_type)
      AND (p_is_active       IS NULL OR "IsActive"       = p_is_active)
      AND (p_search          IS NULL OR "Name" ILIKE '%' || p_search || '%'
                                     OR "Code" ILIKE '%' || p_search || '%')
    ORDER BY "CountryCode", "Code"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 2. usp_HR_Obligation_Save
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_Save(
    p_legal_obligation_id   INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_code                  VARCHAR(30)     DEFAULT NULL,
    p_name                  VARCHAR(200)    DEFAULT NULL,
    p_institution_name      VARCHAR(200)    DEFAULT NULL,
    p_obligation_type       VARCHAR(20)     DEFAULT NULL,
    p_calculation_basis     VARCHAR(30)     DEFAULT NULL,
    p_salary_cap            NUMERIC(18,2)   DEFAULT NULL,
    p_salary_cap_unit       VARCHAR(20)     DEFAULT NULL,
    p_employer_rate         NUMERIC(8,5)    DEFAULT 0,
    p_employee_rate         NUMERIC(8,5)    DEFAULT 0,
    p_rate_variable_by_risk BOOLEAN         DEFAULT FALSE,
    p_filing_frequency      VARCHAR(15)     DEFAULT NULL,
    p_filing_deadline_rule  VARCHAR(200)    DEFAULT NULL,
    p_effective_from        DATE            DEFAULT NULL,
    p_effective_to          DATE            DEFAULT NULL,
    p_is_active             BOOLEAN         DEFAULT TRUE,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validaciones
    IF p_country_code IS NULL OR LENGTH(TRIM(p_country_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El código de país es obligatorio.';
        RETURN;
    END IF;

    IF p_code IS NULL OR LENGTH(TRIM(p_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El código de obligación es obligatorio.';
        RETURN;
    END IF;

    IF p_obligation_type NOT IN ('CONTRIBUTION','TAX_WITHHOLDING','REPORTING','REGISTRATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de obligación no válido. Use: CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION.';
        RETURN;
    END IF;

    IF p_calculation_basis NOT IN ('NORMAL_SALARY','INTEGRAL_SALARY','GROSS_PAYROLL','TAXABLE_INCOME','FIXED_AMOUNT') THEN
        p_resultado := -1;
        p_mensaje   := 'Base de cálculo no válida.';
        RETURN;
    END IF;

    IF p_filing_frequency NOT IN ('MONTHLY','QUARTERLY','ANNUAL','REALTIME') THEN
        p_resultado := -1;
        p_mensaje   := 'Frecuencia de presentación no válida.';
        RETURN;
    END IF;

    BEGIN
        IF p_legal_obligation_id IS NULL OR p_legal_obligation_id = 0 THEN
            -- Verificar duplicado
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe una obligación con ese código y fecha de vigencia para el país indicado.';
                RETURN;
            END IF;

            INSERT INTO hr."LegalObligation" (
                "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
                "CalculationBasis", "SalaryCap", "SalaryCapUnit", "EmployerRate", "EmployeeRate",
                "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
                "EffectiveFrom", "EffectiveTo", "IsActive", "Notes",
                "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_country_code, p_code, p_name, p_institution_name, p_obligation_type,
                p_calculation_basis, p_salary_cap, p_salary_cap_unit, p_employer_rate, p_employee_rate,
                p_rate_variable_by_risk, p_filing_frequency, p_filing_deadline_rule,
                p_effective_from, p_effective_to, p_is_active, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "LegalObligationId" INTO p_resultado;

            p_mensaje := 'Obligación legal creada exitosamente.';

        ELSE
            IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "LegalObligationId" = p_legal_obligation_id) THEN
                p_resultado := -3;
                p_mensaje   := 'No se encontró la obligación legal con el ID indicado.';
                RETURN;
            END IF;

            -- Verificar duplicado excluyendo el registro actual
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
                  AND "LegalObligationId" <> p_legal_obligation_id
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe otra obligación con ese código y fecha de vigencia para el país indicado.';
                RETURN;
            END IF;

            UPDATE hr."LegalObligation" SET
                "CountryCode"           = p_country_code,
                "Code"                  = p_code,
                "Name"                  = p_name,
                "InstitutionName"       = p_institution_name,
                "ObligationType"        = p_obligation_type,
                "CalculationBasis"      = p_calculation_basis,
                "SalaryCap"             = p_salary_cap,
                "SalaryCapUnit"         = p_salary_cap_unit,
                "EmployerRate"          = p_employer_rate,
                "EmployeeRate"          = p_employee_rate,
                "RateVariableByRisk"    = p_rate_variable_by_risk,
                "FilingFrequency"       = p_filing_frequency,
                "FilingDeadlineRule"    = p_filing_deadline_rule,
                "EffectiveFrom"         = p_effective_from,
                "EffectiveTo"           = p_effective_to,
                "IsActive"              = p_is_active,
                "Notes"                 = p_notes,
                "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
            WHERE "LegalObligationId" = p_legal_obligation_id;

            p_resultado := p_legal_obligation_id;
            p_mensaje   := 'Obligación legal actualizada exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 3. usp_HR_Obligation_GetByCountry
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_GetByCountry(
    p_country_code  CHAR(2),
    p_as_of_date    DATE DEFAULT NULL
)
RETURNS TABLE (
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHAR(2),
    "Code"                  VARCHAR(30),
    "Name"                  VARCHAR(200),
    "InstitutionName"       VARCHAR(200),
    "ObligationType"        VARCHAR(20),
    "CalculationBasis"      VARCHAR(30),
    "SalaryCap"             NUMERIC(18,2),
    "SalaryCapUnit"         VARCHAR(20),
    "EmployerRate"          NUMERIC(8,5),
    "EmployeeRate"          NUMERIC(8,5),
    "RateVariableByRisk"    BOOLEAN,
    "FilingFrequency"       VARCHAR(15),
    "FilingDeadlineRule"    VARCHAR(200),
    "EffectiveFrom"         DATE,
    "EffectiveTo"           DATE,
    "Notes"                 VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_as_of_date IS NULL THEN
        p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    RETURN QUERY
    SELECT
        o."LegalObligationId",
        o."CountryCode",
        o."Code",
        o."Name",
        o."InstitutionName",
        o."ObligationType",
        o."CalculationBasis",
        o."SalaryCap",
        o."SalaryCapUnit",
        o."EmployerRate",
        o."EmployeeRate",
        o."RateVariableByRisk",
        o."FilingFrequency",
        o."FilingDeadlineRule",
        o."EffectiveFrom",
        o."EffectiveTo",
        o."Notes"
    FROM hr."LegalObligation" o
    WHERE o."CountryCode" = p_country_code
      AND o."IsActive" = TRUE
      AND o."EffectiveFrom" <= p_as_of_date
      AND (o."EffectiveTo" IS NULL OR o."EffectiveTo" >= p_as_of_date)
    ORDER BY o."Code";
END;
$$;

-- =============================================================================
-- 4. usp_HR_EmployeeObligation_Enroll
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_Enroll(
    p_employee_id           BIGINT,
    p_legal_obligation_id   INTEGER,
    p_affiliation_number    VARCHAR(50)     DEFAULT NULL,
    p_institution_code      VARCHAR(50)     DEFAULT NULL,
    p_risk_level_id         INTEGER         DEFAULT NULL,
    p_enrollment_date       DATE            DEFAULT NULL,
    p_custom_rate           NUMERIC(8,5)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligación legal no existe o no está activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."EmployeeObligation"
        WHERE "EmployeeId"          = p_employee_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "Status"              = 'ACTIVE'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene una inscripción activa en esta obligación.';
        RETURN;
    END IF;

    IF p_risk_level_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."ObligationRiskLevel"
        WHERE "ObligationRiskLevelId" = p_risk_level_id
          AND "LegalObligationId"     = p_legal_obligation_id
    ) THEN
        p_resultado := -3;
        p_mensaje   := 'El nivel de riesgo indicado no corresponde a esta obligación.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."EmployeeObligation" (
            "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
            "RiskLevelId", "EnrollmentDate", "Status", "CustomRate", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_employee_id, p_legal_obligation_id, p_affiliation_number, p_institution_code,
            p_risk_level_id, p_enrollment_date, 'ACTIVE', p_custom_rate,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "EmployeeObligationId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito exitosamente en la obligación.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 5. usp_HR_EmployeeObligation_Disenroll
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_Disenroll(
    p_employee_obligation_id    INTEGER,
    p_disenrollment_date        DATE,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status    VARCHAR(15);
    v_enroll_date       DATE;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "EnrollmentDate"
    INTO v_current_status, v_enroll_date
    FROM hr."EmployeeObligation"
    WHERE "EmployeeObligationId" = p_employee_obligation_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontró la inscripción indicada.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVE' THEN
        p_resultado := -2;
        p_mensaje   := 'La inscripción no está activa. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_disenrollment_date < v_enroll_date THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha de retiro no puede ser anterior a la fecha de inscripción.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."EmployeeObligation" SET
            "DisenrollmentDate" = p_disenrollment_date,
            "Status"            = 'TERMINATED',
            "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
        WHERE "EmployeeObligationId" = p_employee_obligation_id;

        p_resultado := p_employee_obligation_id;
        p_mensaje   := 'Empleado desinscrito exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_EmployeeObligation_GetByEmployee
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_GetByEmployee(
    p_employee_id       BIGINT,
    p_status_filter     VARCHAR(15)     DEFAULT NULL,
    OUT p_total_count   INTEGER
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)
    INTO p_total_count
    FROM hr."EmployeeObligation"
    WHERE "EmployeeId" = p_employee_id
      AND (p_status_filter IS NULL OR "Status" = p_status_filter);

    RETURN QUERY
    SELECT
        eo."EmployeeObligationId",
        eo."EmployeeId",
        eo."LegalObligationId",
        lo."CountryCode",
        lo."Code",
        lo."Name"                               AS "ObligationName",
        lo."InstitutionName",
        lo."ObligationType",
        lo."CalculationBasis",
        eo."AffiliationNumber",
        eo."InstitutionCode",
        eo."RiskLevelId",
        rl."RiskLevel",
        rl."RiskDescription",
        eo."EnrollmentDate",
        eo."DisenrollmentDate",
        eo."Status",
        eo."CustomRate",
        COALESCE(eo."CustomRate", rl."EmployerRate", lo."EmployerRate") AS "EffectiveEmployerRate",
        COALESCE(
            CASE WHEN eo."CustomRate" IS NOT NULL THEN lo."EmployeeRate" ELSE NULL END,
            rl."EmployeeRate",
            lo."EmployeeRate"
        )                                       AS "EffectiveEmployeeRate"
    FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = eo."LegalObligationId"
    LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
    WHERE eo."EmployeeId" = p_employee_id
      AND (p_status_filter IS NULL OR eo."Status" = p_status_filter)
    ORDER BY lo."CountryCode", lo."Code";
END;
$$;

-- =============================================================================
-- 7. usp_HR_Filing_Generate
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_Generate(
    p_company_id            INTEGER,
    p_legal_obligation_id   INTEGER,
    p_filing_period_start   DATE,
    p_filing_period_end     DATE,
    p_due_date              DATE,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_employer_rate    NUMERIC(8,5);
    v_base_employee_rate    NUMERIC(8,5);
    v_cap                   NUMERIC(18,2);
    v_filing_id             INTEGER;
    v_tot_employer          NUMERIC(18,2);
    v_tot_employee          NUMERIC(18,2);
    v_emp_count             INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligación legal no existe o no está activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ObligationFiling"
        WHERE "CompanyId"           = p_company_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "FilingPeriodStart"   = p_filing_period_start
          AND "FilingPeriodEnd"     = p_filing_period_end
          AND "Status"             <> 'REJECTED'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe una declaración para este período y obligación.';
        RETURN;
    END IF;

    IF p_filing_period_end < p_filing_period_start THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha fin del período no puede ser anterior a la fecha inicio.';
        RETURN;
    END IF;

    BEGIN
        SELECT "EmployerRate", "EmployeeRate", "SalaryCap"
        INTO v_base_employer_rate, v_base_employee_rate, v_cap
        FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id;

        INSERT INTO hr."ObligationFiling" (
            "CompanyId", "LegalObligationId",
            "FilingPeriodStart", "FilingPeriodEnd",
            "DueDate", "Status", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_legal_obligation_id,
            p_filing_period_start, p_filing_period_end,
            p_due_date, 'PENDING',
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ObligationFilingId" INTO v_filing_id;

        INSERT INTO hr."ObligationFilingDetail" (
            "ObligationFilingId", "EmployeeId", "BaseSalary",
            "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
        )
        SELECT
            v_filing_id,
            eo."EmployeeId",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC
                LIMIT 1
            ), 0) AS "BaseSalary",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(eo."CustomRate", rl."EmployerRate", v_base_employer_rate) / 100.0,
            2) AS "EmployerAmount",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(rl."EmployeeRate", v_base_employee_rate) / 100.0,
            2) AS "EmployeeAmount",
            30 AS "DaysWorked",
            CASE
                WHEN eo."EnrollmentDate"     BETWEEN p_filing_period_start AND p_filing_period_end THEN 'ENROLLMENT'
                WHEN eo."DisenrollmentDate"  BETWEEN p_filing_period_start AND p_filing_period_end THEN 'WITHDRAWAL'
                ELSE 'NONE'
            END AS "NoveltyType"
        FROM hr."EmployeeObligation" eo
        INNER JOIN master."Employee" e ON e."EmployeeId" = eo."EmployeeId"
        LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
        WHERE eo."LegalObligationId" = p_legal_obligation_id
          AND eo."Status" IN ('ACTIVE','SUSPENDED')
          AND eo."EnrollmentDate" <= p_filing_period_end
          AND (eo."DisenrollmentDate" IS NULL OR eo."DisenrollmentDate" >= p_filing_period_start);

        SELECT
            COALESCE(SUM("EmployerAmount"), 0),
            COALESCE(SUM("EmployeeAmount"), 0),
            COUNT(*)
        INTO v_tot_employer, v_tot_employee, v_emp_count
        FROM hr."ObligationFilingDetail"
        WHERE "ObligationFilingId" = v_filing_id;

        UPDATE hr."ObligationFiling" SET
            "TotalEmployerAmount"   = v_tot_employer,
            "TotalEmployeeAmount"   = v_tot_employee,
            "TotalAmount"           = v_tot_employer + v_tot_employee,
            "EmployeeCount"         = v_emp_count,
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = v_filing_id;

        p_resultado := v_filing_id;
        p_mensaje   := 'Declaración generada exitosamente con ' || v_emp_count::TEXT || ' empleado(s).';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 8. usp_HR_Filing_GetSummary
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_GetSummary(
    p_obligation_filing_id INTEGER
)
RETURNS TABLE (
    result_type     TEXT,
    row_data        JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ObligationFilingId',   f."ObligationFilingId",
            'CompanyId',            f."CompanyId",
            'LegalObligationId',    f."LegalObligationId",
            'CountryCode',          lo."CountryCode",
            'ObligationCode',       lo."Code",
            'ObligationName',       lo."Name",
            'InstitutionName',      lo."InstitutionName",
            'ObligationType',       lo."ObligationType",
            'CalculationBasis',     lo."CalculationBasis",
            'BaseEmployerRate',     lo."EmployerRate",
            'BaseEmployeeRate',     lo."EmployeeRate",
            'FilingPeriodStart',    f."FilingPeriodStart",
            'FilingPeriodEnd',      f."FilingPeriodEnd",
            'DueDate',              f."DueDate",
            'FiledDate',            f."FiledDate",
            'ConfirmationNumber',   f."ConfirmationNumber",
            'TotalEmployerAmount',  f."TotalEmployerAmount",
            'TotalEmployeeAmount',  f."TotalEmployeeAmount",
            'TotalAmount',          f."TotalAmount",
            'EmployeeCount',        f."EmployeeCount",
            'Status',               f."Status",
            'FiledByUserId',        f."FiledByUserId",
            'DocumentUrl',          f."DocumentUrl",
            'Notes',                f."Notes",
            'CreatedAt',            f."CreatedAt",
            'UpdatedAt',            f."UpdatedAt"
        )
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE f."ObligationFilingId" = p_obligation_filing_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'DetailId',             d."DetailId",
            'ObligationFilingId',   d."ObligationFilingId",
            'EmployeeId',           d."EmployeeId",
            'EmployeeCode',         e."EmployeeCode",
            'EmployeeName',         e."EmployeeName",
            'BaseSalary',           d."BaseSalary",
            'EmployerAmount',       d."EmployerAmount",
            'EmployeeAmount',       d."EmployeeAmount",
            'TotalAmount',          d."EmployerAmount" + d."EmployeeAmount",
            'DaysWorked',           d."DaysWorked",
            'NoveltyType',          d."NoveltyType"
        )
    FROM hr."ObligationFilingDetail" d
    INNER JOIN master."Employee" e ON e."EmployeeId" = d."EmployeeId"
    WHERE d."ObligationFilingId" = p_obligation_filing_id
    ORDER BY e."EmployeeName";
END;
$$;

-- =============================================================================
-- 9. usp_HR_Filing_MarkFiled
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_MarkFiled(
    p_obligation_filing_id  INTEGER,
    p_filed_date            DATE            DEFAULT NULL,
    p_confirmation_number   VARCHAR(100)    DEFAULT NULL,
    p_filed_by_user_id      INTEGER         DEFAULT NULL,
    p_document_url          VARCHAR(500)    DEFAULT NULL,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(15);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM hr."ObligationFiling"
    WHERE "ObligationFilingId" = p_obligation_filing_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontró la declaración indicada.';
        RETURN;
    END IF;

    IF v_current_status NOT IN ('PENDING','LATE','REJECTED') THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden marcar como presentadas las declaraciones en estado PENDING, LATE o REJECTED. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_filed_date IS NULL THEN
        p_filed_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    BEGIN
        UPDATE hr."ObligationFiling" SET
            "Status"                = 'FILED',
            "FiledDate"             = p_filed_date,
            "ConfirmationNumber"    = p_confirmation_number,
            "FiledByUserId"         = p_filed_by_user_id,
            "DocumentUrl"           = p_document_url,
            "Notes"                 = COALESCE(p_notes, "Notes"),
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = p_obligation_filing_id;

        p_resultado := p_obligation_filing_id;
        p_mensaje   := 'Declaración marcada como presentada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_Filing_List
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_List(
    p_company_id            INTEGER         DEFAULT NULL,
    p_legal_obligation_id   INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_status                VARCHAR(15)     DEFAULT NULL,
    p_from_date             DATE            DEFAULT NULL,
    p_to_date               DATE            DEFAULT NULL,
    p_page                  INTEGER         DEFAULT 1,
    p_limit                 INTEGER         DEFAULT 50,
    OUT p_total_count       INTEGER
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO p_total_count
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE (p_company_id          IS NULL OR f."CompanyId"          = p_company_id)
      AND (p_legal_obligation_id IS NULL OR f."LegalObligationId"  = p_legal_obligation_id)
      AND (p_country_code        IS NULL OR lo."CountryCode"       = p_country_code)
      AND (p_status              IS NULL OR f."Status"             = p_status)
      AND (p_from_date           IS NULL OR f."FilingPeriodStart" >= p_from_date)
      AND (p_to_date             IS NULL OR f."FilingPeriodEnd"   <= p_to_date);

    RETURN QUERY
    SELECT
        f."ObligationFilingId",
        f."CompanyId",
        f."LegalObligationId",
        lo."CountryCode",
        lo."Code"           AS "ObligationCode",
        lo."Name"           AS "ObligationName",
        lo."InstitutionName",
        f."FilingPeriodStart",
        f."FilingPeriodEnd",
        f."DueDate",
        f."FiledDate",
        f."ConfirmationNumber",
        f."TotalEmployerAmount",
        f."TotalEmployeeAmount",
        f."TotalAmount",
        f."EmployeeCount",
        f."Status",
        f."CreatedAt"
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE (p_company_id          IS NULL OR f."CompanyId"          = p_company_id)
      AND (p_legal_obligation_id IS NULL OR f."LegalObligationId"  = p_legal_obligation_id)
      AND (p_country_code        IS NULL OR lo."CountryCode"       = p_country_code)
      AND (p_status              IS NULL OR f."Status"             = p_status)
      AND (p_from_date           IS NULL OR f."FilingPeriodStart" >= p_from_date)
      AND (p_to_date             IS NULL OR f."FilingPeriodEnd"   <= p_to_date)
    ORDER BY f."FilingPeriodStart" DESC, lo."Code"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- Seed data - Obligaciones legales Venezuela (VE)
-- =============================================================================

-- VE_SSO: Seguro Social Obligatorio / IVSS
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "SalaryCap", "SalaryCapUnit", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_SSO', 'Seguro Social Obligatorio', 'IVSS', 'CONTRIBUTION',
    'NORMAL_SALARY', 5, 'MIN_WAGES', 9.00000, 4.00000,
    TRUE, 'MONTHLY', 'Primeros 5 días hábiles del mes siguiente',
    '2000-01-01', TRUE, 'Tasa base clase I. Consultar tabla de riesgo para clases II-IV.',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO');

-- VE_FAOV: Fondo de Ahorro Obligatorio para la Vivienda / BANAVIH
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_FAOV', 'Fondo de Ahorro Obligatorio para la Vivienda', 'BANAVIH', 'CONTRIBUTION',
    'INTEGRAL_SALARY', 2.00000, 1.00000,
    FALSE, 'MONTHLY', 'Primeros 5 días hábiles del mes siguiente',
    '2000-01-01', TRUE, 'Base: salario integral (salario + alícuota utilidades + alícuota vacaciones).',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_FAOV');

-- VE_LRPE: Régimen Prestacional de Empleo (Paro Forzoso)
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_LRPE', 'Regimen Prestacional de Empleo (Paro Forzoso)', 'IVSS', 'CONTRIBUTION',
    'NORMAL_SALARY', 2.00000, 0.50000,
    FALSE, 'MONTHLY', 'Primeros 5 días hábiles del mes siguiente',
    '2000-01-01', TRUE, 'Paro forzoso - Ley del Régimen Prestacional de Empleo.',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_LRPE');

-- VE_INCE: Instituto Nacional de Capacitación y Educación Socialista
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_INCE', 'INCE - Aporte Patronal', 'INCE', 'CONTRIBUTION',
    'GROSS_PAYROLL', 2.00000, 0.00000,
    FALSE, 'QUARTERLY', 'Dentro de los 5 días hábiles después del cierre del trimestre',
    '2000-01-01', TRUE, 'Empleado aporta 0.5% sobre utilidades (manejado por separado en nómina).',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_INCE');

-- VE_SSO niveles de riesgo (clases I a IV)
DO $$
DECLARE
    v_sso_id INTEGER;
BEGIN
    SELECT "LegalObligationId" INTO v_sso_id
    FROM hr."LegalObligation"
    WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO';

    IF v_sso_id IS NOT NULL THEN
        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 1, 'Riesgo mínimo',  9.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 1);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 2, 'Riesgo medio',  10.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 2);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 3, 'Riesgo alto',   11.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 3);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 4, 'Riesgo máximo', 12.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 4);
    END IF;
END;
$$;
