-- ============================================================
-- 012_fix_text_varchar_hr_pettycash.sql
-- Corrige errores "structure of query does not match function result type"
-- en funciones HR/RRHH por mismatch TEXT vs CHARACTER VARYING,
-- y restaura implementaciones public.* de pettycash eliminadas por 011.
--
-- Problemas corregidos:
--   A) public.* de pettycash eliminados por el DO block de migración 011
--   B) usp_hr_legalconcept_list: CASE WHEN retorna TEXT, declarado VARCHAR
--   C) usp_hr_profitsharing_getsummary: 'HEADER'::TEXT / 'DETAIL'::TEXT
--   D) usp_hr_filing_getsummary: 'HEADER'::TEXT / 'DETAIL'::TEXT
--   E) usp_hr_trust_getemployeebalance: 'BALANCE'::TEXT / 'HISTORY'::TEXT
--   F) usp_hr_trust_getsummary: 'SUMMARY'::TEXT / 'DETAIL'::TEXT
--   G) usp_hr_savings_getbalance: 'FUND'::TEXT / 'TRANSACTION'::TEXT
--   H) usp_hr_occhealth_get: "Description" es TEXT en tabla, declarado VARCHAR
--   I) usp_hr_committee_getmeetings: "TopicsSummary"/"ActionItems" son TEXT en tabla
--
-- Ejecutar desde sqlweb-pg/:
--   psql -U zentto_app -d zentto_prod -f migrations/012_fix_text_varchar_hr_pettycash.sql
-- ============================================================

\echo '  [012] Restaurando implementaciones public.* de pettycash...'

-- ── A) Pettycash: restaurar public.* eliminados por migration 011 ────────────
-- La migration 011 eliminó los OIDs mínimos de todas las funciones con nombre
-- duplicado, lo cual borró los public.* ya que fueron creados antes que los fin.*
\ir ../includes/sp/usp_fin_pettycash.sql

\echo '  [012] Corrigiendo TEXT vs VARCHAR en funciones HR...'

-- ── B) usp_hr_legalconcept_list: CASE WHEN devuelve TEXT, tabla espera VARCHAR ─
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_list(integer, character varying, character varying, character varying, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_list(
    p_company_id        INTEGER,
    p_convention_code   CHARACTER VARYING DEFAULT NULL,
    p_calculation_type  CHARACTER VARYING DEFAULT NULL,
    p_concept_type      CHARACTER VARYING DEFAULT NULL,
    p_solo_activos      BOOLEAN           DEFAULT TRUE
)
RETURNS TABLE(
    id              BIGINT,
    convencion      CHARACTER VARYING,
    "tipoCalculo"   CHARACTER VARYING,
    "coConcept"     CHARACTER VARYING,
    "nbConcepto"    CHARACTER VARYING,
    formula         CHARACTER VARYING,
    sobre           CHARACTER VARYING,
    tipo            CHARACTER VARYING,
    bonificable     CHARACTER VARYING,
    "lotttArticulo" CHARACTER VARYING,
    "ccpClausula"   CHARACTER VARYING,
    orden           INTEGER,
    activo          BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."PayrollConceptId",
        pc."ConventionCode",
        pc."CalculationType",
        pc."ConceptCode",
        pc."ConceptName",
        pc."Formula",
        pc."BaseExpression",
        pc."ConceptType",
        (CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END)::CHARACTER VARYING,
        pc."LotttArticle",
        pc."CcpClause",
        pc."SortOrder",
        pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND (NOT p_solo_activos OR pc."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
    ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$$;

-- ── C) usp_hr_profitsharing_getsummary: 'HEADER'/'DETAIL'::TEXT → VARCHAR ────
DROP FUNCTION IF EXISTS public.usp_hr_profitsharing_getsummary(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_getsummary(p_profit_sharing_id integer)
RETURNS TABLE(result_type character varying, row_data jsonb)
LANGUAGE plpgsql AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::CHARACTER VARYING,
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
        'DETAIL'::CHARACTER VARYING,
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

-- ── D) usp_hr_filing_getsummary: 'HEADER'/'DETAIL'::TEXT → VARCHAR ───────────
DROP FUNCTION IF EXISTS public.usp_hr_filing_getsummary(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_filing_getsummary(p_obligation_filing_id integer)
RETURNS TABLE(result_type character varying, row_data jsonb)
LANGUAGE plpgsql AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::CHARACTER VARYING,
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
        'DETAIL'::CHARACTER VARYING,
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

-- ── E) usp_hr_trust_getemployeebalance: 'BALANCE'/'HISTORY'::TEXT → VARCHAR ──
DROP FUNCTION IF EXISTS public.usp_hr_trust_getemployeebalance(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_trust_getemployeebalance(
    p_company_id    INTEGER,
    p_employee_code CHARACTER VARYING
)
RETURNS TABLE(result_type character varying, row_data jsonb)
LANGUAGE plpgsql AS $$
BEGIN
    -- Saldo actual (1 fila)
    RETURN QUERY
    SELECT
        'BALANCE'::CHARACTER VARYING,
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
        'HISTORY'::CHARACTER VARYING,
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

-- ── F) usp_hr_trust_getsummary: 'SUMMARY'/'DETAIL'::TEXT → VARCHAR ────────────
DROP FUNCTION IF EXISTS public.usp_hr_trust_getsummary(integer, integer, smallint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_trust_getsummary(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER,
    p_quarter       SMALLINT
)
RETURNS TABLE(result_type character varying, row_data jsonb)
LANGUAGE plpgsql AS $$
BEGIN
    -- Resumen por estado
    RETURN QUERY
    SELECT
        'SUMMARY'::CHARACTER VARYING,
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
        'DETAIL'::CHARACTER VARYING,
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

-- ── G) usp_hr_savings_getbalance: 'FUND'/'TRANSACTION'::TEXT → VARCHAR ────────
DROP FUNCTION IF EXISTS public.usp_hr_savings_getbalance(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_savings_getbalance(
    p_company_id    INTEGER,
    p_employee_code CHARACTER VARYING
)
RETURNS TABLE(result_type character varying, row_data jsonb)
LANGUAGE plpgsql AS $$
BEGIN
    -- Datos del fondo
    RETURN QUERY
    SELECT
        'FUND'::CHARACTER VARYING,
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
        'TRANSACTION'::CHARACTER VARYING,
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

-- ── H) usp_hr_occhealth_get: "Description" es TEXT en tabla, declarado VARCHAR ─
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_get(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_get(
    p_occupational_health_id    INTEGER,
    p_company_id                INTEGER
)
RETURNS TABLE(
    "OccupationalHealthId"          INTEGER,
    "CompanyId"                     INTEGER,
    "CountryCode"                   CHARACTER,
    "RecordType"                    CHARACTER VARYING,
    "EmployeeId"                    BIGINT,
    "EmployeeCode"                  CHARACTER VARYING,
    "EmployeeName"                  CHARACTER VARYING,
    "OccurrenceDate"                TIMESTAMP WITHOUT TIME ZONE,
    "ReportDeadline"                TIMESTAMP WITHOUT TIME ZONE,
    "ReportedDate"                  TIMESTAMP WITHOUT TIME ZONE,
    "Severity"                      CHARACTER VARYING,
    "BodyPartAffected"              CHARACTER VARYING,
    "DaysLost"                      INTEGER,
    "Location"                      CHARACTER VARYING,
    "Description"                   CHARACTER VARYING,
    "RootCause"                     CHARACTER VARYING,
    "CorrectiveAction"              CHARACTER VARYING,
    "InvestigationDueDate"          DATE,
    "InvestigationCompletedDate"    DATE,
    "InstitutionReference"          CHARACTER VARYING,
    "Status"                        CHARACTER VARYING,
    "DocumentUrl"                   CHARACTER VARYING,
    "Notes"                         CHARACTER VARYING,
    "CreatedBy"                     INTEGER,
    "CreatedAt"                     TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"                     TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        o."OccupationalHealthId",
        o."CompanyId",
        o."CountryCode",
        o."RecordType",
        o."EmployeeId",
        o."EmployeeCode",
        o."EmployeeName",
        o."OccurrenceDate",
        o."ReportDeadline",
        o."ReportedDate",
        o."Severity",
        o."BodyPartAffected",
        o."DaysLost",
        o."Location",
        o."Description"::CHARACTER VARYING,
        o."RootCause",
        o."CorrectiveAction",
        o."InvestigationDueDate",
        o."InvestigationCompletedDate",
        o."InstitutionReference",
        o."Status",
        o."DocumentUrl",
        o."Notes",
        o."CreatedBy",
        o."CreatedAt",
        o."UpdatedAt"
    FROM hr."OccupationalHealth" o
    WHERE o."OccupationalHealthId" = p_occupational_health_id
      AND o."CompanyId" = p_company_id;
END;
$$;

-- ── I) usp_hr_committee_getmeetings: TEXT → VARCHAR para TopicsSummary/ActionItems
DROP FUNCTION IF EXISTS public.usp_hr_committee_getmeetings(integer, integer, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_getmeetings(
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_from_date             DATE    DEFAULT NULL,
    p_to_date               DATE    DEFAULT NULL,
    p_page                  INTEGER DEFAULT 1,
    p_limit                 INTEGER DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MeetingId"         INTEGER,
    "SafetyCommitteeId" INTEGER,
    "MeetingDate"       DATE,
    "MinutesUrl"        CHARACTER VARYING,
    "TopicsSummary"     CHARACTER VARYING,
    "ActionItems"       CHARACTER VARYING,
    "CreatedAt"         TIMESTAMP WITHOUT TIME ZONE,
    "CommitteeName"     CHARACTER VARYING
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    -- Verificar que el comité pertenece a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        m."MeetingId",
        m."SafetyCommitteeId",
        m."MeetingDate",
        m."MinutesUrl",
        m."TopicsSummary"::CHARACTER VARYING,
        m."ActionItems"::CHARACTER VARYING,
        m."CreatedAt",
        sc."CommitteeName"
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_safety_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date   IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

\echo '  [012] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('012_fix_text_varchar_hr_pettycash', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [012] COMPLETO — TEXT→VARCHAR y pettycash restaurados'
