-- =============================================================================
-- 18_fiscal_retenciones_schema.sql (PostgreSQL)
-- Tablas y ALTER para módulo de retenciones fiscales automáticas.
-- Soporta multi-país: VE (ISLR), ES (IRPF), CO (ReteFuente), MX (ISR).
-- =============================================================================

-- =============================================================================
-- 1. cfg.TaxUnit — Unidad Tributaria configurable por país y año
-- =============================================================================
CREATE TABLE IF NOT EXISTS cfg."TaxUnit" (
    "TaxUnitId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CountryCode"   CHAR(2)        NOT NULL,
    "TaxYear"       INT            NOT NULL,
    "UnitValue"     NUMERIC(18,4)  NOT NULL,
    "Currency"      CHAR(3)        NOT NULL DEFAULT 'VES',
    "EffectiveDate" DATE           NOT NULL,
    "IsActive"      BOOLEAN        NOT NULL DEFAULT TRUE,
    "CreatedAt"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_cfg_TaxUnit" UNIQUE ("CountryCode", "TaxYear", "EffectiveDate")
);

-- =============================================================================
-- 2. fiscal.WithholdingConcept — Conceptos de retención parametrizables
--    Mapea tipo persona + actividad → porcentaje de retención
-- =============================================================================
CREATE TABLE IF NOT EXISTS fiscal."WithholdingConcept" (
    "ConceptId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"       INT            NOT NULL DEFAULT 1,
    "CountryCode"     CHAR(2)        NOT NULL,
    "ConceptCode"     VARCHAR(20)    NOT NULL,
    "Description"     VARCHAR(200)   NOT NULL,
    "SupplierType"    VARCHAR(20)    NOT NULL DEFAULT 'AMBOS',
    "ActivityCode"    VARCHAR(30)    NULL,
    "RetentionType"   VARCHAR(20)    NOT NULL DEFAULT 'ISLR',
    "Rate"            NUMERIC(8,4)   NOT NULL,
    "SubtrahendUT"    NUMERIC(8,4)   NOT NULL DEFAULT 0,
    "MinBaseUT"       NUMERIC(8,4)   NOT NULL DEFAULT 0,
    "SeniatCode"      VARCHAR(10)    NULL,
    "IsActive"        BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"       BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_fiscal_WHConcept" UNIQUE ("CompanyId", "CountryCode", "ConceptCode"),
    CONSTRAINT "CK_fiscal_WHConcept_Type" CHECK ("SupplierType" IN ('NATURAL','JURIDICA','AMBOS')),
    CONSTRAINT "CK_fiscal_WHConcept_RetType" CHECK ("RetentionType" IN ('ISLR','IVA','IRPF','ISR','RETEFUENTE','MUNICIPAL'))
);

-- =============================================================================
-- 3. ALTER master.Supplier — Campos de clasificación fiscal
-- =============================================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='SupplierType') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "SupplierType" VARCHAR(20) NOT NULL DEFAULT 'JURIDICA';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='BusinessActivity') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "BusinessActivity" VARCHAR(30) NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='DefaultRetentionCode') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "DefaultRetentionCode" VARCHAR(20) NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='CountryCode') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "CountryCode" CHAR(2) NOT NULL DEFAULT 'VE';
    END IF;
END $$;

-- =============================================================================
-- 4. ALTER ap.PayableApplication — Campos de retención en pagos
-- =============================================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ap' AND table_name='PayableApplication' AND column_name='RetentionType') THEN
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionType" VARCHAR(20) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionRate" NUMERIC(8,4) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionAmount" NUMERIC(18,2) NOT NULL DEFAULT 0;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "NetAmount" NUMERIC(18,2) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "WithholdingVoucherId" BIGINT NULL;
    END IF;
END $$;

-- =============================================================================
-- 5. hr.EmployeeTaxProfile — Perfil fiscal del empleado (ARI)
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."EmployeeTaxProfile" (
    "ProfileId"                INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EmployeeId"               BIGINT         NOT NULL,
    "TaxYear"                  INT            NOT NULL,
    "EstimatedAnnualIncome"    NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "DeductionType"            VARCHAR(20)    NOT NULL DEFAULT 'UNICO',
    "UniqueDeductionUT"        NUMERIC(8,2)   NOT NULL DEFAULT 774,
    "DetailedDeductions"       NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "DependentCount"           INT            NOT NULL DEFAULT 0,
    "PersonalRebateUT"         NUMERIC(8,2)   NOT NULL DEFAULT 10,
    "DependentRebateUT"        NUMERIC(8,2)   NOT NULL DEFAULT 10,
    "MonthsRemaining"          INT            NOT NULL DEFAULT 12,
    "CalculatedAnnualISLR"     NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "MonthlyWithholding"       NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "CountryCode"              CHAR(2)        NOT NULL DEFAULT 'VE',
    "Status"                   VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',
    "CreatedAt"                TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"                TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_hr_EmpTaxProfile" UNIQUE ("EmployeeId", "TaxYear"),
    CONSTRAINT "CK_hr_EmpTaxProfile_Ded" CHECK ("DeductionType" IN ('UNICO','DETALLADO')),
    CONSTRAINT "CK_hr_EmpTaxProfile_Status" CHECK ("Status" IN ('ACTIVE','INACTIVE'))
);

-- =============================================================================
-- 6. SEED DATA: Unidad Tributaria Venezuela 2026
-- =============================================================================
INSERT INTO cfg."TaxUnit" ("CountryCode", "TaxYear", "UnitValue", "Currency", "EffectiveDate")
SELECT 'VE', 2026, 9.00, 'VES', '2026-01-01'
WHERE NOT EXISTS (
    SELECT 1 FROM cfg."TaxUnit" WHERE "CountryCode"='VE' AND "TaxYear"=2026
);

-- =============================================================================
-- 7. SEED DATA: Conceptos ISLR Venezuela (Decreto 1.808)
-- =============================================================================
INSERT INTO fiscal."WithholdingConcept"
    ("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT", "SeniatCode")
SELECT v.*
FROM (VALUES
    ('VE', 'ISLR_HON_PN',   'Honorarios profesionales (PN)',          'NATURAL',  'HONORARIOS',    'ISLR', 3.0000, 1.0000, 25.0000, '002'),
    ('VE', 'ISLR_HON_PJ',   'Honorarios profesionales (PJ)',          'JURIDICA', 'HONORARIOS',    'ISLR', 5.0000, 0.0000,  0.0000, '002'),
    ('VE', 'ISLR_COM_PN',   'Comisiones y corretaje (PN)',            'NATURAL',  'COMISIONES',    'ISLR', 3.0000, 1.0000, 25.0000, '003'),
    ('VE', 'ISLR_COM_PJ',   'Comisiones y corretaje (PJ)',            'JURIDICA', 'COMISIONES',    'ISLR', 5.0000, 0.0000,  0.0000, '003'),
    ('VE', 'ISLR_SRV_PN',   'Servicios en general (PN)',              'NATURAL',  'SERVICIOS',     'ISLR', 1.0000, 1.0000, 25.0000, '004'),
    ('VE', 'ISLR_SRV_PJ',   'Servicios en general (PJ)',              'JURIDICA', 'SERVICIOS',     'ISLR', 2.0000, 0.0000,  0.0000, '004'),
    ('VE', 'ISLR_FLE_PN',   'Fletes y transporte (PN)',               'NATURAL',  'FLETES',        'ISLR', 3.0000, 1.0000, 25.0000, '005'),
    ('VE', 'ISLR_FLE_PJ',   'Fletes y transporte (PJ)',               'JURIDICA', 'FLETES',        'ISLR', 1.0000, 0.0000,  0.0000, '005'),
    ('VE', 'ISLR_ALQ_PN',   'Alquiler bienes inmuebles (PN)',         'NATURAL',  'ALQUILER_INM',  'ISLR', 3.0000, 0.0000,  0.0000, '006'),
    ('VE', 'ISLR_ALQ_PJ',   'Alquiler bienes inmuebles (PJ)',         'JURIDICA', 'ALQUILER_INM',  'ISLR', 5.0000, 0.0000,  0.0000, '006'),
    ('VE', 'ISLR_PUB_PN',   'Publicidad y propaganda (PN)',           'NATURAL',  'PUBLICIDAD',    'ISLR', 1.0000, 1.0000, 25.0000, '007'),
    ('VE', 'ISLR_PUB_PJ',   'Publicidad y propaganda (PJ)',           'JURIDICA', 'PUBLICIDAD',    'ISLR', 2.0000, 0.0000,  0.0000, '007')
) AS v("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT", "SeniatCode")
WHERE NOT EXISTS (
    SELECT 1 FROM fiscal."WithholdingConcept" WHERE "ConceptCode" = v."ConceptCode" AND "CountryCode" = 'VE'
);

-- España IRPF
INSERT INTO fiscal."WithholdingConcept"
    ("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT")
SELECT v.*
FROM (VALUES
    ('ES', 'IRPF_PROF',    'Profesionales/autónomos',     'AMBOS',   'PROFESIONAL', 'IRPF', 15.0000, 0, 0),
    ('ES', 'IRPF_NUEVO',   'Nuevos profesionales (3 años)', 'AMBOS', 'PROFESIONAL', 'IRPF',  7.0000, 0, 0),
    ('ES', 'IRPF_ALQ',     'Arrendamientos inmuebles',    'AMBOS',   'ALQUILER_INM','IRPF', 19.0000, 0, 0),
    ('ES', 'IRPF_CAP',     'Rendimientos de capital',     'AMBOS',   'CAPITAL',     'IRPF', 19.0000, 0, 0)
) AS v("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT")
WHERE NOT EXISTS (
    SELECT 1 FROM fiscal."WithholdingConcept" WHERE "ConceptCode" = v."ConceptCode" AND "CountryCode" = 'ES'
);

DO $$ BEGIN RAISE NOTICE '>>> 18_fiscal_retenciones_schema.sql ejecutado correctamente <<<'; END $$;
