/*
 * ============================================================================
 *  Archivo : acct_legal_tables.sql
 *  Esquema : acct (contabilidad legal)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-15
 *
 *  Descripcion:
 *    Tablas para el modulo contable legal multi-pais:
 *    - Ajuste por inflacion (VEN-NIF / NIC 29 / DPC-10)
 *    - Movimientos patrimoniales (Superavit VE / ECPN ES)
 *    - Plantillas editables de reportes con bases legales
 *
 *  Marcos legales soportados:
 *    VE: BA VEN-NIF 2 (inflacion), BA VEN-NIF 8 (PCGA), NIC 29, DPC-10, LISLR Art. 173-193
 *    ES: RD 1514/2007 (PGC), RD 1515/2007 (PGC-PYME), Codigo de Comercio Art. 25-49
 *
 *  Tablas (7):
 *    acct.InflationIndex, acct.AccountMonetaryClass,
 *    acct.InflationAdjustment, acct.InflationAdjustmentLine,
 *    acct.EquityMovement,
 *    acct.ReportTemplate, acct.ReportTemplateVariable
 *
 *  Patron  : IF OBJECT_ID IS NULL (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
-- 1. acct.InflationIndex
--    Almacena indices de precios mensuales (INPC Venezuela, IPC Espana, etc.)
--    Ref: BA VEN-NIF 2, NIC 29 parrafo 37
-- ============================================================================
IF OBJECT_ID('acct.InflationIndex', 'U') IS NULL
BEGIN
    CREATE TABLE acct.InflationIndex (
        InflationIndexId    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId           INT NOT NULL CONSTRAINT DF_acct_II_CompanyId DEFAULT(1),
        CountryCode         CHAR(2) NOT NULL,                          -- 'VE', 'ES'
        IndexName           NVARCHAR(30) NOT NULL,                     -- 'INPC' (VE), 'IPC' (ES)
        PeriodCode          CHAR(6) NOT NULL,                          -- 'YYYYMM' ej: '202601'
        IndexValue          DECIMAL(18,6) NOT NULL,                    -- valor del indice
        SourceReference     NVARCHAR(200) NULL,                        -- Gaceta Oficial / BCV / INE
        CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_II_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_II_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT UQ_acct_II UNIQUE (CompanyId, CountryCode, IndexName, PeriodCode),
        CONSTRAINT FK_acct_II_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT CK_acct_II_Country CHECK (CountryCode IN ('VE','ES','CO','MX','US'))
    );
    PRINT 'Tabla acct.InflationIndex creada.';
END;
GO

-- ============================================================================
-- 2. acct.AccountMonetaryClass
--    Clasifica cuentas contables como monetarias o no monetarias
--    para calculo de ajuste por inflacion.
--    Ref: DPC-10 parrafos 15-22, NIC 29 parrafo 12
-- ============================================================================
IF OBJECT_ID('acct.AccountMonetaryClass', 'U') IS NULL
BEGIN
    CREATE TABLE acct.AccountMonetaryClass (
        AccountMonetaryClassId  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId               INT NOT NULL CONSTRAINT DF_acct_AMC_CompanyId DEFAULT(1),
        AccountId               BIGINT NOT NULL,                       -- FK a acct.Account
        Classification          NVARCHAR(20) NOT NULL,                 -- 'MONETARY' | 'NON_MONETARY'
        SubClassification       NVARCHAR(40) NULL,                     -- 'CASH','RECEIVABLE','PAYABLE','FIXED_ASSET','INVENTORY','EQUITY','INTANGIBLE'
        ReexpressionAccountId   BIGINT NULL,                           -- cuenta contrapartida para ajuste
        IsActive                BIT NOT NULL CONSTRAINT DF_acct_AMC_Active DEFAULT(1),
        CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_AMC_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_AMC_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT UQ_acct_AMC UNIQUE (CompanyId, AccountId),
        CONSTRAINT FK_acct_AMC_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT CK_acct_AMC_Class CHECK (Classification IN ('MONETARY','NON_MONETARY'))
    );
    PRINT 'Tabla acct.AccountMonetaryClass creada.';
END;
GO

-- ============================================================================
-- 3. acct.InflationAdjustment
--    Cabecera de cada calculo de ajuste por inflacion.
--    Un registro por periodo procesado.
--    Ref: BA VEN-NIF 2, NIC 29 parrafos 11-28
-- ============================================================================
IF OBJECT_ID('acct.InflationAdjustment', 'U') IS NULL
BEGIN
    CREATE TABLE acct.InflationAdjustment (
        InflationAdjustmentId   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId               INT NOT NULL CONSTRAINT DF_acct_IA_CompanyId DEFAULT(1),
        BranchId                INT NOT NULL CONSTRAINT DF_acct_IA_BranchId DEFAULT(1),
        CountryCode             CHAR(2) NOT NULL DEFAULT('VE'),
        PeriodCode              CHAR(6) NOT NULL,                      -- 'YYYYMM'
        FiscalYear              SMALLINT NOT NULL,
        AdjustmentDate          DATE NOT NULL,
        BaseIndexValue          DECIMAL(18,6) NOT NULL,                -- INPC inicio (base)
        EndIndexValue           DECIMAL(18,6) NOT NULL,                -- INPC fin del periodo
        AccumulatedInflation    DECIMAL(18,6) NULL,                    -- % acumulado anual
        ReexpressionFactor      DECIMAL(18,8) NOT NULL,                -- EndIndex / BaseIndex
        JournalEntryId          BIGINT NULL,                           -- asiento generado al publicar
        TotalMonetaryGainLoss   DECIMAL(18,2) NOT NULL DEFAULT(0),     -- REME
        TotalAdjustmentAmount   DECIMAL(18,2) NOT NULL DEFAULT(0),     -- suma de ajustes no monetarios
        Status                  NVARCHAR(20) NOT NULL CONSTRAINT DF_acct_IA_Status DEFAULT('DRAFT'),
        Notes                   NVARCHAR(500) NULL,
        CreatedByUserId         INT NULL,
        CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_IA_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_IA_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT CK_acct_IA_Status CHECK (Status IN ('DRAFT','POSTED','VOIDED')),
        CONSTRAINT UQ_acct_IA UNIQUE (CompanyId, BranchId, PeriodCode),
        CONSTRAINT FK_acct_IA_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
    );
    PRINT 'Tabla acct.InflationAdjustment creada.';
END;
GO

-- ============================================================================
-- 4. acct.InflationAdjustmentLine
--    Detalle del ajuste: una linea por cada cuenta no monetaria procesada.
--    Ref: NIC 29 parrafos 14-25
-- ============================================================================
IF OBJECT_ID('acct.InflationAdjustmentLine', 'U') IS NULL
BEGIN
    CREATE TABLE acct.InflationAdjustmentLine (
        LineId                  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        InflationAdjustmentId   INT NOT NULL,
        AccountId               BIGINT NOT NULL,
        AccountCode             NVARCHAR(30) NOT NULL,
        AccountName             NVARCHAR(200) NULL,
        Classification          NVARCHAR(20) NOT NULL,                 -- MONETARY | NON_MONETARY
        HistoricalBalance       DECIMAL(18,2) NOT NULL,                -- saldo historico
        ReexpressionFactor      DECIMAL(18,8) NOT NULL,
        AdjustedBalance         DECIMAL(18,2) NOT NULL,                -- saldo reexpresado
        AdjustmentAmount        DECIMAL(18,2) NOT NULL,                -- diferencia (ajusted - historical)
        CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_IAL_CreatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT FK_acct_IAL_Header FOREIGN KEY (InflationAdjustmentId) REFERENCES acct.InflationAdjustment(InflationAdjustmentId)
    );
    CREATE NONCLUSTERED INDEX IX_acct_IAL_Header ON acct.InflationAdjustmentLine(InflationAdjustmentId);
    PRINT 'Tabla acct.InflationAdjustmentLine creada.';
END;
GO

-- ============================================================================
-- 5. acct.EquityMovement
--    Registra movimientos patrimoniales para generar el Estado de Cambios
--    en el Patrimonio (VE: Superavit, ES: ECPN).
--    Ref VE: BA VEN-NIF 1 parrafos 106-110
--    Ref ES: PGC 3ra parte, Art. 35.1.c LSC
-- ============================================================================
IF OBJECT_ID('acct.EquityMovement', 'U') IS NULL
BEGIN
    CREATE TABLE acct.EquityMovement (
        EquityMovementId    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId           INT NOT NULL CONSTRAINT DF_acct_EM_CompanyId DEFAULT(1),
        BranchId            INT NOT NULL CONSTRAINT DF_acct_EM_BranchId DEFAULT(1),
        FiscalYear          SMALLINT NOT NULL,
        AccountId           BIGINT NOT NULL,                           -- cuenta patrimonial
        AccountCode         NVARCHAR(30) NOT NULL,
        AccountName         NVARCHAR(200) NULL,
        MovementType        NVARCHAR(30) NOT NULL,                     -- tipo de movimiento
        MovementDate        DATE NOT NULL,
        Amount              DECIMAL(18,2) NOT NULL,
        JournalEntryId      BIGINT NULL,                               -- asiento asociado
        Description         NVARCHAR(400) NULL,
        CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_EM_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_EM_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT FK_acct_EM_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT CK_acct_EM_Type CHECK (MovementType IN (
            'CAPITAL_INCREASE','CAPITAL_DECREASE',
            'RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY',
            'RETAINED_EARNINGS','ACCUMULATED_DEFICIT',
            'DIVIDEND_CASH','DIVIDEND_STOCK',
            'REVALUATION_SURPLUS','INFLATION_ADJUST',
            'NET_INCOME','NET_LOSS',
            'OTHER_COMPREHENSIVE','OPENING_BALANCE'
        ))
    );
    CREATE NONCLUSTERED INDEX IX_acct_EM_Year ON acct.EquityMovement(CompanyId, FiscalYear);
    PRINT 'Tabla acct.EquityMovement creada.';
END;
GO

-- ============================================================================
-- 6. acct.ReportTemplate
--    Plantillas editables de reportes financieros formales.
--    Contenido en Markdown con variables {{...}} que se interpolan
--    con datos reales al momento de renderizar/exportar PDF.
-- ============================================================================
IF OBJECT_ID('acct.ReportTemplate', 'U') IS NULL
BEGIN
    CREATE TABLE acct.ReportTemplate (
        ReportTemplateId    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId           INT NOT NULL CONSTRAINT DF_acct_RT_CompanyId DEFAULT(1),
        CountryCode         CHAR(2) NOT NULL,                          -- 'VE', 'ES'
        ReportCode          NVARCHAR(50) NOT NULL,                     -- 'BALANCE_GENERAL_VE', 'PYG_ES', etc.
        ReportName          NVARCHAR(200) NOT NULL,
        LegalFramework      NVARCHAR(50) NOT NULL,                     -- 'VEN-NIF', 'PGC', 'PGC-PYME'
        LegalReference      NVARCHAR(300) NULL,                        -- 'BA VEN-NIF 1, parrafos 55-80'
        TemplateContent     NVARCHAR(MAX) NOT NULL,                    -- Markdown con {{variables}}
        HeaderJson          NVARCHAR(MAX) NULL,                        -- JSON config cabecera
        FooterJson          NVARCHAR(MAX) NULL,                        -- JSON config pie de pagina
        IsDefault           BIT NOT NULL CONSTRAINT DF_acct_RT_Default DEFAULT(0),
        IsActive            BIT NOT NULL CONSTRAINT DF_acct_RT_Active DEFAULT(1),
        Version             INT NOT NULL CONSTRAINT DF_acct_RT_Version DEFAULT(1),
        CreatedByUserId     INT NULL,
        CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_RT_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_RT_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT UQ_acct_RT UNIQUE (CompanyId, CountryCode, ReportCode),
        CONSTRAINT FK_acct_RT_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT CK_acct_RT_Framework CHECK (LegalFramework IN ('VEN-NIF','PGC','PGC-PYME','NIIF-PYME','NIIF-FULL'))
    );
    PRINT 'Tabla acct.ReportTemplate creada.';
END;
GO

-- ============================================================================
-- 7. acct.ReportTemplateVariable
--    Define las variables disponibles para interpolar en cada plantilla.
--    Ejemplo: {{companyName}} -> cfg.Company.CompanyName
--             {{table:balanceGeneral}} -> SP usp_Acct_Report_BalanceGeneral
-- ============================================================================
IF OBJECT_ID('acct.ReportTemplateVariable', 'U') IS NULL
BEGIN
    CREATE TABLE acct.ReportTemplateVariable (
        VariableId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ReportTemplateId    INT NOT NULL,
        VariableName        NVARCHAR(100) NOT NULL,                    -- 'companyName', 'table:balanceGeneral'
        VariableType        NVARCHAR(20) NOT NULL,                     -- 'TEXT','DATE','TABLE','CURRENCY','NUMBER'
        DataSource          NVARCHAR(200) NULL,                        -- SP name o campo config
        DefaultValue        NVARCHAR(500) NULL,
        Description         NVARCHAR(300) NULL,                        -- ayuda para el editor
        SortOrder           INT NOT NULL CONSTRAINT DF_acct_RTV_Sort DEFAULT(0),
        CONSTRAINT FK_acct_RTV_Template FOREIGN KEY (ReportTemplateId) REFERENCES acct.ReportTemplate(ReportTemplateId) ON DELETE CASCADE,
        CONSTRAINT CK_acct_RTV_Type CHECK (VariableType IN ('TEXT','DATE','TABLE','CURRENCY','NUMBER','BOOLEAN'))
    );
    CREATE NONCLUSTERED INDEX IX_acct_RTV_Template ON acct.ReportTemplateVariable(ReportTemplateId);
    PRINT 'Tabla acct.ReportTemplateVariable creada.';
END;
GO

PRINT '=== acct_legal_tables.sql completado ===';
GO
