-- =============================================================================
-- 29_fiscal_retenciones_schema.sql (SQL Server)
-- Tablas y ALTER para módulo de retenciones fiscales automáticas.
-- Soporta multi-país: VE (ISLR), ES (IRPF), CO (ReteFuente), MX (ISR).
-- =============================================================================

-- =============================================================================
-- 1. cfg.TaxUnit — Unidad Tributaria configurable por país y año
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('cfg.TaxUnit'))
BEGIN
    CREATE TABLE cfg.TaxUnit (
        TaxUnitId     INT IDENTITY(1,1) NOT NULL,
        CountryCode   CHAR(2)        NOT NULL,
        TaxYear       INT            NOT NULL,
        UnitValue     DECIMAL(18,4)  NOT NULL,
        Currency      CHAR(3)        NOT NULL DEFAULT 'VES',
        EffectiveDate DATE           NOT NULL,
        IsActive      BIT            NOT NULL DEFAULT 1,
        CreatedAt     DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt     DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_cfg_TaxUnit PRIMARY KEY (TaxUnitId),
        CONSTRAINT UQ_cfg_TaxUnit UNIQUE (CountryCode, TaxYear, EffectiveDate)
    );
END;
GO

-- =============================================================================
-- 2. fiscal.WithholdingConcept — Conceptos de retención parametrizables
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('fiscal.WithholdingConcept'))
BEGIN
    CREATE TABLE fiscal.WithholdingConcept (
        ConceptId       INT IDENTITY(1,1) NOT NULL,
        CompanyId       INT            NOT NULL DEFAULT 1,
        CountryCode     CHAR(2)        NOT NULL,
        ConceptCode     NVARCHAR(20)   NOT NULL,
        Description     NVARCHAR(200)  NOT NULL,
        SupplierType    NVARCHAR(20)   NOT NULL DEFAULT N'AMBOS',
        ActivityCode    NVARCHAR(30)   NULL,
        RetentionType   NVARCHAR(20)   NOT NULL DEFAULT N'ISLR',
        Rate            DECIMAL(8,4)   NOT NULL,
        SubtrahendUT    DECIMAL(8,4)   NOT NULL DEFAULT 0,
        MinBaseUT       DECIMAL(8,4)   NOT NULL DEFAULT 0,
        SeniatCode      NVARCHAR(10)   NULL,
        IsActive        BIT            NOT NULL DEFAULT 1,
        IsDeleted       BIT            NOT NULL DEFAULT 0,
        CreatedAt       DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_fiscal_WHConcept PRIMARY KEY (ConceptId),
        CONSTRAINT UQ_fiscal_WHConcept UNIQUE (CompanyId, CountryCode, ConceptCode),
        CONSTRAINT CK_fiscal_WHConcept_Type CHECK (SupplierType IN (N'NATURAL',N'JURIDICA',N'AMBOS')),
        CONSTRAINT CK_fiscal_WHConcept_RetType CHECK (RetentionType IN (N'ISLR',N'IVA',N'IRPF',N'ISR',N'RETEFUENTE',N'MUNICIPAL'))
    );
END;
GO

-- =============================================================================
-- 3. ALTER master.Supplier — Campos de clasificación fiscal
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('master.Supplier') AND name='SupplierType')
    ALTER TABLE master.Supplier ADD SupplierType NVARCHAR(20) NOT NULL DEFAULT N'JURIDICA';
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('master.Supplier') AND name='BusinessActivity')
    ALTER TABLE master.Supplier ADD BusinessActivity NVARCHAR(30) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('master.Supplier') AND name='DefaultRetentionCode')
    ALTER TABLE master.Supplier ADD DefaultRetentionCode NVARCHAR(20) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('master.Supplier') AND name='CountryCode')
    ALTER TABLE master.Supplier ADD CountryCode CHAR(2) NOT NULL DEFAULT 'VE';
GO

-- =============================================================================
-- 4. ALTER ap.PayableApplication — Campos de retención en pagos
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ap.PayableApplication') AND name='RetentionType')
BEGIN
    ALTER TABLE ap.PayableApplication ADD RetentionType NVARCHAR(20) NULL;
    ALTER TABLE ap.PayableApplication ADD RetentionRate DECIMAL(8,4) NULL;
    ALTER TABLE ap.PayableApplication ADD RetentionAmount DECIMAL(18,2) NOT NULL DEFAULT 0;
    ALTER TABLE ap.PayableApplication ADD NetAmount DECIMAL(18,2) NULL;
    ALTER TABLE ap.PayableApplication ADD WithholdingVoucherId BIGINT NULL;
END;
GO

-- =============================================================================
-- 5. hr.EmployeeTaxProfile — Perfil fiscal del empleado (ARI)
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'hr')
    EXEC('CREATE SCHEMA hr');
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('hr.EmployeeTaxProfile'))
BEGIN
    CREATE TABLE hr.EmployeeTaxProfile (
        ProfileId                INT IDENTITY(1,1) NOT NULL,
        EmployeeId               BIGINT         NOT NULL,
        TaxYear                  INT            NOT NULL,
        EstimatedAnnualIncome    DECIMAL(18,2)  NOT NULL DEFAULT 0,
        DeductionType            NVARCHAR(20)   NOT NULL DEFAULT N'UNICO',
        UniqueDeductionUT        DECIMAL(8,2)   NOT NULL DEFAULT 774,
        DetailedDeductions       DECIMAL(18,2)  NOT NULL DEFAULT 0,
        DependentCount           INT            NOT NULL DEFAULT 0,
        PersonalRebateUT         DECIMAL(8,2)   NOT NULL DEFAULT 10,
        DependentRebateUT        DECIMAL(8,2)   NOT NULL DEFAULT 10,
        MonthsRemaining          INT            NOT NULL DEFAULT 12,
        CalculatedAnnualISLR     DECIMAL(18,2)  NOT NULL DEFAULT 0,
        MonthlyWithholding       DECIMAL(18,2)  NOT NULL DEFAULT 0,
        CountryCode              CHAR(2)        NOT NULL DEFAULT 'VE',
        Status                   NVARCHAR(20)   NOT NULL DEFAULT N'ACTIVE',
        CreatedAt                DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt                DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_hr_EmpTaxProfile PRIMARY KEY (ProfileId),
        CONSTRAINT UQ_hr_EmpTaxProfile UNIQUE (EmployeeId, TaxYear),
        CONSTRAINT CK_hr_EmpTaxProfile_Ded CHECK (DeductionType IN (N'UNICO',N'DETALLADO')),
        CONSTRAINT CK_hr_EmpTaxProfile_Status CHECK (Status IN (N'ACTIVE',N'INACTIVE'))
    );
END;
GO

-- =============================================================================
-- 6. SEED DATA: Unidad Tributaria Venezuela 2026
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM cfg.TaxUnit WHERE CountryCode='VE' AND TaxYear=2026)
    INSERT INTO cfg.TaxUnit (CountryCode, TaxYear, UnitValue, Currency, EffectiveDate)
    VALUES ('VE', 2026, 9.00, 'VES', '2026-01-01');
GO

-- =============================================================================
-- 7. SEED DATA: Conceptos ISLR Venezuela (Decreto 1.808)
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM fiscal.WithholdingConcept WHERE ConceptCode='ISLR_HON_PN' AND CountryCode='VE')
BEGIN
    INSERT INTO fiscal.WithholdingConcept (CountryCode, ConceptCode, Description, SupplierType, ActivityCode, RetentionType, Rate, SubtrahendUT, MinBaseUT, SeniatCode) VALUES
    ('VE', N'ISLR_HON_PN', N'Honorarios profesionales (PN)',   N'NATURAL',  N'HONORARIOS',   N'ISLR', 3.0000, 1.0000, 25.0000, N'002'),
    ('VE', N'ISLR_HON_PJ', N'Honorarios profesionales (PJ)',   N'JURIDICA', N'HONORARIOS',   N'ISLR', 5.0000, 0.0000,  0.0000, N'002'),
    ('VE', N'ISLR_COM_PN', N'Comisiones y corretaje (PN)',     N'NATURAL',  N'COMISIONES',   N'ISLR', 3.0000, 1.0000, 25.0000, N'003'),
    ('VE', N'ISLR_COM_PJ', N'Comisiones y corretaje (PJ)',     N'JURIDICA', N'COMISIONES',   N'ISLR', 5.0000, 0.0000,  0.0000, N'003'),
    ('VE', N'ISLR_SRV_PN', N'Servicios en general (PN)',       N'NATURAL',  N'SERVICIOS',    N'ISLR', 1.0000, 1.0000, 25.0000, N'004'),
    ('VE', N'ISLR_SRV_PJ', N'Servicios en general (PJ)',       N'JURIDICA', N'SERVICIOS',    N'ISLR', 2.0000, 0.0000,  0.0000, N'004'),
    ('VE', N'ISLR_FLE_PN', N'Fletes y transporte (PN)',        N'NATURAL',  N'FLETES',       N'ISLR', 3.0000, 1.0000, 25.0000, N'005'),
    ('VE', N'ISLR_FLE_PJ', N'Fletes y transporte (PJ)',        N'JURIDICA', N'FLETES',       N'ISLR', 1.0000, 0.0000,  0.0000, N'005'),
    ('VE', N'ISLR_ALQ_PN', N'Alquiler bienes inmuebles (PN)',  N'NATURAL',  N'ALQUILER_INM', N'ISLR', 3.0000, 0.0000,  0.0000, N'006'),
    ('VE', N'ISLR_ALQ_PJ', N'Alquiler bienes inmuebles (PJ)',  N'JURIDICA', N'ALQUILER_INM', N'ISLR', 5.0000, 0.0000,  0.0000, N'006'),
    ('VE', N'ISLR_PUB_PN', N'Publicidad y propaganda (PN)',    N'NATURAL',  N'PUBLICIDAD',   N'ISLR', 1.0000, 1.0000, 25.0000, N'007'),
    ('VE', N'ISLR_PUB_PJ', N'Publicidad y propaganda (PJ)',    N'JURIDICA', N'PUBLICIDAD',   N'ISLR', 2.0000, 0.0000,  0.0000, N'007');
END;
GO

-- España IRPF
IF NOT EXISTS (SELECT 1 FROM fiscal.WithholdingConcept WHERE ConceptCode='IRPF_PROF' AND CountryCode='ES')
BEGIN
    INSERT INTO fiscal.WithholdingConcept (CountryCode, ConceptCode, Description, SupplierType, ActivityCode, RetentionType, Rate, SubtrahendUT, MinBaseUT) VALUES
    ('ES', N'IRPF_PROF',  N'Profesionales/autónomos',        N'AMBOS', N'PROFESIONAL', N'IRPF', 15.0000, 0, 0),
    ('ES', N'IRPF_NUEVO', N'Nuevos profesionales (3 años)',   N'AMBOS', N'PROFESIONAL', N'IRPF',  7.0000, 0, 0),
    ('ES', N'IRPF_ALQ',   N'Arrendamientos inmuebles',       N'AMBOS', N'ALQUILER_INM',N'IRPF', 19.0000, 0, 0),
    ('ES', N'IRPF_CAP',   N'Rendimientos de capital',        N'AMBOS', N'CAPITAL',     N'IRPF', 19.0000, 0, 0);
END;
GO

PRINT '>>> 29_fiscal_retenciones_schema.sql ejecutado correctamente <<<';
GO
