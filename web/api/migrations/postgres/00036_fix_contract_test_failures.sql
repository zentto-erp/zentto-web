-- +goose Up

-- +goose StatementBegin
-- ===========================================================================
-- 00036_fix_contract_test_failures.sql
-- Corrige 20 endpoints fallidos en test de contrato:
--   - 9 funciones RRHH con parámetros incorrectos (error 500)
--   - 6 funciones core con tablas canónicas (timeout)
-- Usa tablas canónicas: cfg.Company, master.CostCenter, master.Seller, etc.
-- ===========================================================================

-- ============================================================
-- PARTE 1: Funciones core (tablas canónicas)
-- ============================================================

-- 1a. usp_empresa_get → cfg."Company"
CREATE OR REPLACE FUNCTION public.usp_empresa_get()
RETURNS TABLE(
    "Empresa" VARCHAR(100), "RIF" VARCHAR(50), "Nit" VARCHAR(50),
    "Telefono" VARCHAR(60), "Direccion" VARCHAR(255), "Rifs" VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."LegalName"::VARCHAR(100), c."FiscalId"::VARCHAR(50),
           c."FiscalId"::VARCHAR(50), c."Phone"::VARCHAR(60),
           c."Address"::VARCHAR(255), c."FiscalId"::VARCHAR(50)
    FROM cfg."Company" c
    WHERE c."IsActive" = TRUE AND COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
END;
$$;

-- 1b. usp_centrocosto_getbycodigo → master."CostCenter"
DROP FUNCTION IF EXISTS public.usp_centrocosto_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_getbycodigo(p_codigo VARCHAR(50))
RETURNS TABLE("Codigo" VARCHAR, "Descripcion" VARCHAR, "Presupuestado" VARCHAR, "Saldo_Real" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cc."CostCenterCode"::VARCHAR, cc."CostCenterName"::VARCHAR, '0'::VARCHAR, '0'::VARCHAR
    FROM master."CostCenter" cc
    WHERE cc."CostCenterCode" = p_codigo AND COALESCE(cc."IsDeleted", FALSE) = FALSE;
END;
$$;

-- 1c. usp_vendedores_getbycodigo → master."Seller"
DROP FUNCTION IF EXISTS public.usp_vendedores_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_getbycodigo(p_codigo VARCHAR(10))
RETURNS TABLE(
    "Codigo" VARCHAR, "Nombre" VARCHAR, "Comision" DOUBLE PRECISION,
    "Status" BOOLEAN, "IsActive" BOOLEAN, "IsDeleted" BOOLEAN, "CompanyId" INT,
    "SellerCode" VARCHAR, "SellerName" VARCHAR, "Commission" DOUBLE PRECISION,
    "Direccion" VARCHAR, "Telefonos" VARCHAR, "Email" VARCHAR, "Tipo" VARCHAR,
    "Clave" VARCHAR, "RangoVentasUno" DOUBLE PRECISION, "ComisionVentasUno" DOUBLE PRECISION,
    "RangoVentasDos" DOUBLE PRECISION, "ComisionVentasDos" DOUBLE PRECISION,
    "RangoVentasTres" DOUBLE PRECISION, "ComisionVentasTres" DOUBLE PRECISION,
    "RangoVentasCuatro" DOUBLE PRECISION, "ComisionVentasCuatro" DOUBLE PRECISION
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT s."SellerCode"::VARCHAR, s."SellerName"::VARCHAR,
           COALESCE(s."Commission",0)::DOUBLE PRECISION, s."IsActive", s."IsActive",
           COALESCE(s."IsDeleted",FALSE), s."CompanyId",
           s."SellerCode"::VARCHAR, s."SellerName"::VARCHAR,
           COALESCE(s."Commission",0)::DOUBLE PRECISION,
           s."Address"::VARCHAR, s."Phone"::VARCHAR, s."Email"::VARCHAR,
           s."SellerType"::VARCHAR, NULL::VARCHAR,
           0::DOUBLE PRECISION, 0::DOUBLE PRECISION, 0::DOUBLE PRECISION, 0::DOUBLE PRECISION,
           0::DOUBLE PRECISION, 0::DOUBLE PRECISION, 0::DOUBLE PRECISION, 0::DOUBLE PRECISION
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$fn$;

-- 1d. usp_tax_retention_getbycode → master."TaxRetention"
DROP FUNCTION IF EXISTS public.usp_tax_retention_getbycode(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tax_retention_getbycode(p_codigo VARCHAR(60))
RETURNS TABLE("RetentionId" INT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo" VARCHAR, "Porcentaje" NUMERIC, "Pais" VARCHAR, "IsActive" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT tr."RetentionId", tr."RetentionCode"::VARCHAR, tr."Description"::VARCHAR,
           tr."RetentionType"::VARCHAR, tr."RetentionRate", tr."CountryCode"::VARCHAR, tr."IsActive"
    FROM master."TaxRetention" tr
    WHERE tr."RetentionCode" = p_codigo AND COALESCE(tr."IsDeleted", FALSE) = FALSE LIMIT 1;
END;
$$;

-- 1e. usp_cfg_entityimage_list → cfg."EntityImage" + cfg."MediaAsset" (BIGINT IDs)
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_list(INT, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_entityimage_list(
    p_company_id INT, p_branch_id INT, p_entity_type VARCHAR(50), p_entity_id INT
)
RETURNS TABLE(
    "entityImageId" BIGINT, "entityType" VARCHAR, "entityId" BIGINT,
    "mediaAssetId" BIGINT, "roleCode" VARCHAR, "sortOrder" INT, "isPrimary" BOOLEAN,
    "publicUrl" VARCHAR, "originalFileName" VARCHAR, "mimeType" VARCHAR,
    "fileSizeBytes" BIGINT, "altText" VARCHAR, "createdAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT ei."EntityImageId", ei."EntityType"::VARCHAR, ei."EntityId",
           ei."MediaAssetId", ei."RoleCode"::VARCHAR, ei."SortOrder", ei."IsPrimary",
           ma."PublicUrl"::VARCHAR, ma."OriginalFileName"::VARCHAR, ma."MimeType"::VARCHAR,
           ma."FileSizeBytes", ma."AltText"::VARCHAR, ma."CreatedAt"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."EntityType" = p_entity_type
      AND ei."EntityId" = p_entity_id
      AND COALESCE(ei."IsDeleted", FALSE) = FALSE AND ei."IsActive" = TRUE
      AND COALESCE(ma."IsDeleted", FALSE) = FALSE AND ma."IsActive" = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId";
END;
$fn$;

-- 1f. usp_inv_movement_listperiodsummary → master."InventoryPeriodSummary" (BIGINT SummaryId)
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo VARCHAR(10) DEFAULT NULL, p_codigo VARCHAR(60) DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "SummaryId" BIGINT, "Periodo" VARCHAR, "Codigo" VARCHAR,
    "OpeningQty" NUMERIC, "InboundQty" NUMERIC, "OutboundQty" NUMERIC,
    "ClosingQty" NUMERIC, "fecha" DATE, "IsClosed" BOOLEAN, "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR "ProductCode" = p_codigo);
    RETURN QUERY
    SELECT s."SummaryId", s."Period"::VARCHAR, s."ProductCode"::VARCHAR,
           s."OpeningQty", s."InboundQty", s."OutboundQty", s."ClosingQty",
           s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- ============================================================
-- PARTE 2: Funciones RRHH (parámetros corregidos + columnas reales)
-- ============================================================

-- 2a. usp_HR_Savings_List (CompanyId, Search, Offset, Limit)
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_savings_list(
    p_company_id INT, p_search VARCHAR DEFAULT NULL, p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "SavingsFundId" INT, "EmployeeId" BIGINT,
    "EmployeeCode" VARCHAR(24), "EmployeeName" VARCHAR(200),
    "EmployeeContribution" NUMERIC(8,4), "EmployerMatch" NUMERIC(8,4),
    "EnrollmentDate" DATE, "Status" VARCHAR(15), "CreatedAt" TIMESTAMP,
    "CurrentBalance" NUMERIC(18,2)
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (p_search IS NULL OR sf."EmployeeName" ILIKE '%' || p_search || '%'
           OR sf."EmployeeCode" ILIKE '%' || p_search || '%');
    RETURN QUERY
    SELECT v_total, sf."SavingsFundId", sf."EmployeeId", sf."EmployeeCode", sf."EmployeeName",
           sf."EmployeeContribution", sf."EmployerMatch", sf."EnrollmentDate",
           sf."Status", sf."CreatedAt",
           COALESCE((SELECT SUM(t."Amount") FROM hr."SavingsFundTransaction" t
                     WHERE t."SavingsFundId" = sf."SavingsFundId"), 0::NUMERIC(18,2))
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (p_search IS NULL OR sf."EmployeeName" ILIKE '%' || p_search || '%'
           OR sf."EmployeeCode" ILIKE '%' || p_search || '%')
    ORDER BY sf."EmployeeName" LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2b. usp_HR_Trust_List (CompanyId, Year, Offset, Limit)
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(INT, INT, SMALLINT, VARCHAR, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(INT, INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_trust_list(
    p_company_id INT, p_year INT DEFAULT NULL, p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "TrustId" INT, "EmployeeId" BIGINT,
    "EmployeeCode" VARCHAR(24), "EmployeeName" VARCHAR(200), "FiscalYear" INT,
    "Quarter" SMALLINT, "DailySalary" NUMERIC(18,2), "DaysDeposited" INT,
    "BonusDays" INT, "DepositAmount" NUMERIC(18,2), "InterestRate" NUMERIC(8,5),
    "InterestAmount" NUMERIC(18,2), "AccumulatedBalance" NUMERIC(18,2),
    "Status" VARCHAR(20), "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND (p_year IS NULL OR t."FiscalYear" = p_year);
    RETURN QUERY
    SELECT v_total, t."TrustId", t."EmployeeId", t."EmployeeCode", t."EmployeeName",
           t."FiscalYear", t."Quarter", t."DailySalary", t."DaysDeposited",
           t."BonusDays", t."DepositAmount", t."InterestRate", t."InterestAmount",
           t."AccumulatedBalance", t."Status", t."CreatedAt"
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND (p_year IS NULL OR t."FiscalYear" = p_year)
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC, t."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2c. usp_HR_Obligation_List (CompanyId, CountryCode, Offset, Limit)
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(CHAR, VARCHAR, BOOLEAN, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_list(
    p_company_id INT, p_country_code VARCHAR DEFAULT NULL, p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "LegalObligationId" INT, "CountryCode" CHAR(2),
    "Code" VARCHAR(30), "Name" VARCHAR(200), "InstitutionName" VARCHAR(200),
    "ObligationType" VARCHAR(20), "CalculationBasis" VARCHAR(30),
    "SalaryCap" NUMERIC(18,2), "SalaryCapUnit" VARCHAR(20),
    "EmployerRate" NUMERIC(8,5), "EmployeeRate" NUMERIC(8,5),
    "RateVariableByRisk" BOOLEAN, "FilingFrequency" VARCHAR(15),
    "FilingDeadlineRule" VARCHAR(200), "EffectiveFrom" DATE, "EffectiveTo" DATE, "Notes" TEXT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."LegalObligation" o
    WHERE o."IsActive" = TRUE AND (p_country_code IS NULL OR o."CountryCode" = p_country_code::CHAR(2));
    RETURN QUERY
    SELECT v_total, o."LegalObligationId", o."CountryCode", o."Code", o."Name",
           o."InstitutionName", o."ObligationType", o."CalculationBasis",
           o."SalaryCap", o."SalaryCapUnit", o."EmployerRate", o."EmployeeRate",
           o."RateVariableByRisk", o."FilingFrequency", o."FilingDeadlineRule",
           o."EffectiveFrom", o."EffectiveTo", o."Notes"::TEXT
    FROM hr."LegalObligation" o
    WHERE o."IsActive" = TRUE AND (p_country_code IS NULL OR o."CountryCode" = p_country_code::CHAR(2))
    ORDER BY o."CountryCode", o."Code" LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2d. usp_HR_Obligation_GetByCountry (CompanyId, CountryCode)
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(CHAR, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_getbycountry(p_company_id INT, p_country_code VARCHAR)
RETURNS TABLE(
    "LegalObligationId" INT, "CountryCode" CHAR(2), "Code" VARCHAR(30),
    "Name" VARCHAR(200), "InstitutionName" VARCHAR(200), "ObligationType" VARCHAR(20),
    "CalculationBasis" VARCHAR(30), "SalaryCap" NUMERIC(18,2), "SalaryCapUnit" VARCHAR(20),
    "EmployerRate" NUMERIC(8,5), "EmployeeRate" NUMERIC(8,5), "RateVariableByRisk" BOOLEAN,
    "FilingFrequency" VARCHAR(15), "FilingDeadlineRule" VARCHAR(200),
    "EffectiveFrom" DATE, "EffectiveTo" DATE, "Notes" TEXT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT o."LegalObligationId", o."CountryCode", o."Code", o."Name",
           o."InstitutionName", o."ObligationType", o."CalculationBasis",
           o."SalaryCap", o."SalaryCapUnit", o."EmployerRate", o."EmployeeRate",
           o."RateVariableByRisk", o."FilingFrequency", o."FilingDeadlineRule",
           o."EffectiveFrom", o."EffectiveTo", o."Notes"::TEXT
    FROM hr."LegalObligation" o
    WHERE o."IsActive" = TRUE AND o."CountryCode" = p_country_code::CHAR(2)
      AND (o."EffectiveTo" IS NULL OR o."EffectiveTo" >= CURRENT_DATE)
    ORDER BY o."Code";
END;
$fn$;

-- 2e. usp_HR_OccHealth_List (CompanyId, EmployeeCode, RecordType, Offset, Limit)
-- Columna InvestigationCompletedDate (no ClosedDate)
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(INT, VARCHAR, VARCHAR, VARCHAR, CHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_list(
    p_company_id INT, p_employee_code VARCHAR DEFAULT NULL, p_record_type VARCHAR DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "OccupationalHealthId" INT, "CompanyId" INT, "CountryCode" CHAR(2),
    "RecordType" VARCHAR(25), "EmployeeId" BIGINT, "EmployeeCode" VARCHAR(24),
    "EmployeeName" VARCHAR(200), "OccurrenceDate" TIMESTAMP, "ReportDeadline" TIMESTAMP,
    "ReportedDate" TIMESTAMP, "Status" VARCHAR(15), "Severity" VARCHAR(100),
    "Description" TEXT, "FollowUpDate" DATE, "ClosedDate" DATE
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."OccupationalHealth" oh
    WHERE oh."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR oh."EmployeeCode" = p_employee_code)
      AND (p_record_type IS NULL OR oh."RecordType" = p_record_type);
    RETURN QUERY
    SELECT v_total, oh."OccupationalHealthId", oh."CompanyId", oh."CountryCode",
           oh."RecordType", oh."EmployeeId", oh."EmployeeCode", oh."EmployeeName",
           oh."OccurrenceDate", oh."ReportDeadline", oh."ReportedDate",
           oh."Status", oh."Severity", oh."Description",
           oh."InvestigationDueDate", oh."InvestigationCompletedDate"::DATE
    FROM hr."OccupationalHealth" oh
    WHERE oh."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR oh."EmployeeCode" = p_employee_code)
      AND (p_record_type IS NULL OR oh."RecordType" = p_record_type)
    ORDER BY oh."OccurrenceDate" DESC NULLS LAST LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2f. usp_HR_MedExam_List (CompanyId, EmployeeCode, ExamType, Offset, Limit)
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(INT, VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_list(
    p_company_id INT, p_employee_code VARCHAR DEFAULT NULL, p_exam_type VARCHAR DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "MedicalExamId" INT, "CompanyId" INT, "EmployeeId" BIGINT,
    "EmployeeCode" VARCHAR(24), "EmployeeName" VARCHAR(200), "ExamType" VARCHAR(20),
    "ExamDate" DATE, "NextDueDate" DATE, "Result" VARCHAR(20),
    "Restrictions" VARCHAR(500), "PhysicianName" VARCHAR(200), "ClinicName" VARCHAR(200)
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."MedicalExam" me
    WHERE me."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR me."EmployeeCode" = p_employee_code)
      AND (p_exam_type IS NULL OR me."ExamType" = p_exam_type);
    RETURN QUERY
    SELECT v_total, me."MedicalExamId", me."CompanyId", me."EmployeeId",
           me."EmployeeCode", me."EmployeeName", me."ExamType", me."ExamDate",
           me."NextDueDate", me."Result", me."Restrictions",
           me."PhysicianName", me."ClinicName"
    FROM hr."MedicalExam" me
    WHERE me."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR me."EmployeeCode" = p_employee_code)
      AND (p_exam_type IS NULL OR me."ExamType" = p_exam_type)
    ORDER BY me."ExamDate" DESC LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2g. usp_HR_MedOrder_List (CompanyId, EmployeeCode, Status, Offset, Limit)
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(INT, VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_list(
    p_company_id INT, p_employee_code VARCHAR DEFAULT NULL, p_status VARCHAR DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "MedicalOrderId" INT, "CompanyId" INT, "EmployeeId" BIGINT,
    "EmployeeCode" VARCHAR(24), "EmployeeName" VARCHAR(200), "OrderType" VARCHAR(20),
    "OrderDate" DATE, "Diagnosis" VARCHAR(500), "PhysicianName" VARCHAR(200),
    "Prescriptions" TEXT, "EstimatedCost" NUMERIC(18,2), "ApprovedAmount" NUMERIC(18,2),
    "Status" VARCHAR(15)
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."MedicalOrder" mo
    WHERE mo."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR mo."EmployeeCode" = p_employee_code)
      AND (p_status IS NULL OR mo."Status" = p_status);
    RETURN QUERY
    SELECT v_total, mo."MedicalOrderId", mo."CompanyId", mo."EmployeeId",
           mo."EmployeeCode", mo."EmployeeName", mo."OrderType", mo."OrderDate",
           mo."Diagnosis", mo."PhysicianName", mo."Prescriptions",
           mo."EstimatedCost", mo."ApprovedAmount", mo."Status"
    FROM hr."MedicalOrder" mo
    WHERE mo."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR mo."EmployeeCode" = p_employee_code)
      AND (p_status IS NULL OR mo."Status" = p_status)
    ORDER BY mo."OrderDate" DESC LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2h. usp_HR_Training_List (CompanyId, Search, Offset, Limit)
-- Columna DurationHours (no Hours), sin Instructor en tabla
DROP FUNCTION IF EXISTS public.usp_hr_training_list(INT, VARCHAR, VARCHAR, CHAR, BOOLEAN, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_training_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_training_list(
    p_company_id INT, p_search VARCHAR DEFAULT NULL, p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "TrainingRecordId" INT, "CompanyId" INT, "CountryCode" CHAR(2),
    "TrainingType" VARCHAR(25), "Title" VARCHAR(200), "Provider" VARCHAR(200),
    "StartDate" DATE, "EndDate" DATE, "Hours" NUMERIC(6,2), "EmployeeId" BIGINT,
    "EmployeeCode" VARCHAR(24), "EmployeeName" VARCHAR(200), "Instructor" VARCHAR(100),
    "Result" VARCHAR(15), "IsRegulatory" BOOLEAN
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."TrainingRecord" tr
    WHERE tr."CompanyId" = p_company_id
      AND (p_search IS NULL OR tr."Title" ILIKE '%' || p_search || '%'
           OR tr."EmployeeName" ILIKE '%' || p_search || '%'
           OR tr."Provider" ILIKE '%' || p_search || '%');
    RETURN QUERY
    SELECT v_total, tr."TrainingRecordId", tr."CompanyId", tr."CountryCode",
           tr."TrainingType", tr."Title", tr."Provider",
           tr."StartDate", tr."EndDate", tr."DurationHours",
           tr."EmployeeId", tr."EmployeeCode", tr."EmployeeName",
           NULL::VARCHAR(100), tr."Result", tr."IsRegulatory"
    FROM hr."TrainingRecord" tr
    WHERE tr."CompanyId" = p_company_id
      AND (p_search IS NULL OR tr."Title" ILIKE '%' || p_search || '%'
           OR tr."EmployeeName" ILIKE '%' || p_search || '%'
           OR tr."Provider" ILIKE '%' || p_search || '%')
    ORDER BY tr."StartDate" DESC LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 2i. usp_HR_Committee_List (CompanyId, Search, Offset, Limit)
-- SafetyCommitteeMember no tiene IsActive
DROP FUNCTION IF EXISTS public.usp_hr_committee_list(INT, CHAR, BOOLEAN, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_committee_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_list(
    p_company_id INT, p_search VARCHAR DEFAULT NULL, p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "SafetyCommitteeId" INT, "CompanyId" INT, "CountryCode" CHAR(2),
    "CommitteeName" VARCHAR(200), "FormationDate" DATE, "MeetingFrequency" VARCHAR(15),
    "IsActive" BOOLEAN, "CreatedAt" TIMESTAMP, "ActiveMemberCount" BIGINT, "TotalMeetings" BIGINT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (p_search IS NULL OR sc."CommitteeName" ILIKE '%' || p_search || '%');
    RETURN QUERY
    SELECT v_total, sc."SafetyCommitteeId", sc."CompanyId", sc."CountryCode",
           sc."CommitteeName", sc."FormationDate", sc."MeetingFrequency",
           sc."IsActive", sc."CreatedAt",
           (SELECT COUNT(1) FROM hr."SafetyCommitteeMember" m
            WHERE m."SafetyCommitteeId" = sc."SafetyCommitteeId"),
           (SELECT COUNT(1) FROM hr."SafetyCommitteeMeeting" mt
            WHERE mt."SafetyCommitteeId" = sc."SafetyCommitteeId")
    FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (p_search IS NULL OR sc."CommitteeName" ILIKE '%' || p_search || '%')
    ORDER BY sc."CommitteeName" LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- +goose StatementEnd

-- +goose Down
-- No se borran funciones en rollback para no romper la API
SELECT 1;
