-- =============================================================================
--  Archivo : acct_legal_tables.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/acct_legal_tables.sql
--
--  Descripcion:
--    Tablas para el modulo contable legal multi-pais:
--    - Ajuste por inflacion (VEN-NIF / NIC 29 / DPC-10)
--    - Movimientos patrimoniales (Superavit VE / ECPN ES)
--    - Plantillas editables de reportes con bases legales
--
--  Marcos legales soportados:
--    VE: BA VEN-NIF 2 (inflacion), BA VEN-NIF 8 (PCGA), NIC 29, DPC-10, LISLR Art. 173-193
--    ES: RD 1514/2007 (PGC), RD 1515/2007 (PGC-PYME), Codigo de Comercio Art. 25-49
--
--  Tablas (7):
--    acct.InflationIndex, acct.AccountMonetaryClass,
--    acct.InflationAdjustment, acct.InflationAdjustmentLine,
--    acct.EquityMovement,
--    acct.ReportTemplate, acct.ReportTemplateVariable
-- =============================================================================

-- Ensure schemas exist
CREATE SCHEMA IF NOT EXISTS acct;
CREATE SCHEMA IF NOT EXISTS cfg;

-- ============================================================================
-- 1. acct.InflationIndex
--    Almacena indices de precios mensuales (INPC Venezuela, IPC Espana, etc.)
--    Ref: BA VEN-NIF 2, NIC 29 parrafo 37
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."InflationIndex" (
    "InflationIndexId"  INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"         INTEGER NOT NULL DEFAULT 1,
    "CountryCode"       CHAR(2) NOT NULL,           -- 'VE', 'ES'
    "IndexName"         VARCHAR(30) NOT NULL,         -- 'INPC' (VE), 'IPC' (ES)
    "PeriodCode"        CHAR(6) NOT NULL,             -- 'YYYYMM' ej: '202601'
    "IndexValue"        NUMERIC(18,6) NOT NULL,       -- valor del indice
    "SourceReference"   VARCHAR(200) NULL,            -- Gaceta Oficial / BCV / INE
    "CreatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "UQ_acct_II" UNIQUE ("CompanyId", "CountryCode", "IndexName", "PeriodCode"),
    CONSTRAINT "FK_acct_II_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT "CK_acct_II_Country" CHECK ("CountryCode" IN ('VE','ES','CO','MX','US'))
);

-- ============================================================================
-- 2. acct.AccountMonetaryClass
--    Clasifica cuentas contables como monetarias o no monetarias
--    para calculo de ajuste por inflacion.
--    Ref: DPC-10 parrafos 15-22, NIC 29 parrafo 12
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."AccountMonetaryClass" (
    "AccountMonetaryClassId"  INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"               INTEGER NOT NULL DEFAULT 1,
    "AccountId"               BIGINT NOT NULL,         -- FK a acct.Account
    "Classification"          VARCHAR(20) NOT NULL,    -- 'MONETARY' | 'NON_MONETARY'
    "SubClassification"       VARCHAR(40) NULL,        -- 'CASH','RECEIVABLE','PAYABLE','FIXED_ASSET','INVENTORY','EQUITY','INTANGIBLE'
    "ReexpressionAccountId"   BIGINT NULL,             -- cuenta contrapartida para ajuste
    "IsActive"                BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"               TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    "UpdatedAt"               TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "UQ_acct_AMC" UNIQUE ("CompanyId", "AccountId"),
    CONSTRAINT "FK_acct_AMC_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT "CK_acct_AMC_Class" CHECK ("Classification" IN ('MONETARY','NON_MONETARY'))
);

-- ============================================================================
-- 3. acct.InflationAdjustment
--    Cabecera de cada calculo de ajuste por inflacion.
--    Un registro por periodo procesado.
--    Ref: BA VEN-NIF 2, NIC 29 parrafos 11-28
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."InflationAdjustment" (
    "InflationAdjustmentId"   INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"               INTEGER NOT NULL DEFAULT 1,
    "BranchId"                INTEGER NOT NULL DEFAULT 1,
    "CountryCode"             CHAR(2) NOT NULL DEFAULT 'VE',
    "PeriodCode"              CHAR(6) NOT NULL,                    -- 'YYYYMM'
    "FiscalYear"              SMALLINT NOT NULL,
    "AdjustmentDate"          DATE NOT NULL,
    "BaseIndexValue"          NUMERIC(18,6) NOT NULL,              -- INPC inicio (base)
    "EndIndexValue"           NUMERIC(18,6) NOT NULL,              -- INPC fin del periodo
    "AccumulatedInflation"    NUMERIC(18,6) NULL,                  -- % acumulado anual
    "ReexpressionFactor"      NUMERIC(18,8) NOT NULL,              -- EndIndex / BaseIndex
    "JournalEntryId"          BIGINT NULL,                         -- asiento generado al publicar
    "TotalMonetaryGainLoss"   NUMERIC(18,2) NOT NULL DEFAULT 0,    -- REME
    "TotalAdjustmentAmount"   NUMERIC(18,2) NOT NULL DEFAULT 0,    -- suma de ajustes no monetarios
    "Status"                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "Notes"                   VARCHAR(500) NULL,
    "CreatedByUserId"         INTEGER NULL,
    "CreatedAt"               TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    "UpdatedAt"               TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "CK_acct_IA_Status" CHECK ("Status" IN ('DRAFT','POSTED','VOIDED')),
    CONSTRAINT "UQ_acct_IA" UNIQUE ("CompanyId", "BranchId", "PeriodCode"),
    CONSTRAINT "FK_acct_IA_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

-- ============================================================================
-- 4. acct.InflationAdjustmentLine
--    Detalle del ajuste: una linea por cada cuenta no monetaria procesada.
--    Ref: NIC 29 parrafos 14-25
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."InflationAdjustmentLine" (
    "LineId"                  BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "InflationAdjustmentId"   INTEGER NOT NULL,
    "AccountId"               BIGINT NOT NULL,
    "AccountCode"             VARCHAR(30) NOT NULL,
    "AccountName"             VARCHAR(200) NULL,
    "Classification"          VARCHAR(20) NOT NULL,    -- MONETARY | NON_MONETARY
    "HistoricalBalance"       NUMERIC(18,2) NOT NULL,  -- saldo historico
    "ReexpressionFactor"      NUMERIC(18,8) NOT NULL,
    "AdjustedBalance"         NUMERIC(18,2) NOT NULL,  -- saldo reexpresado
    "AdjustmentAmount"        NUMERIC(18,2) NOT NULL,  -- diferencia (adjusted - historical)
    "CreatedAt"               TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "FK_acct_IAL_Header" FOREIGN KEY ("InflationAdjustmentId")
        REFERENCES acct."InflationAdjustment"("InflationAdjustmentId")
);

CREATE INDEX IF NOT EXISTS "IX_acct_IAL_Header"
    ON acct."InflationAdjustmentLine"("InflationAdjustmentId");

-- ============================================================================
-- 5. acct.EquityMovement
--    Registra movimientos patrimoniales para generar el Estado de Cambios
--    en el Patrimonio (VE: Superavit, ES: ECPN).
--    Ref VE: BA VEN-NIF 1 parrafos 106-110
--    Ref ES: PGC 3ra parte, Art. 35.1.c LSC
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."EquityMovement" (
    "EquityMovementId"  INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"         INTEGER NOT NULL DEFAULT 1,
    "BranchId"          INTEGER NOT NULL DEFAULT 1,
    "FiscalYear"        SMALLINT NOT NULL,
    "AccountId"         BIGINT NOT NULL,               -- cuenta patrimonial
    "AccountCode"       VARCHAR(30) NOT NULL,
    "AccountName"       VARCHAR(200) NULL,
    "MovementType"      VARCHAR(30) NOT NULL,           -- tipo de movimiento
    "MovementDate"      DATE NOT NULL,
    "Amount"            NUMERIC(18,2) NOT NULL,
    "JournalEntryId"    BIGINT NULL,                   -- asiento asociado
    "Description"       VARCHAR(400) NULL,
    "CreatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "FK_acct_EM_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT "CK_acct_EM_Type" CHECK ("MovementType" IN (
        'CAPITAL_INCREASE','CAPITAL_DECREASE',
        'RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY',
        'RETAINED_EARNINGS','ACCUMULATED_DEFICIT',
        'DIVIDEND_CASH','DIVIDEND_STOCK',
        'REVALUATION_SURPLUS','INFLATION_ADJUST',
        'NET_INCOME','NET_LOSS',
        'OTHER_COMPREHENSIVE','OPENING_BALANCE'
    ))
);

CREATE INDEX IF NOT EXISTS "IX_acct_EM_Year"
    ON acct."EquityMovement"("CompanyId", "FiscalYear");

-- ============================================================================
-- 6. acct.ReportTemplate
--    Plantillas editables de reportes financieros formales.
--    Contenido en Markdown con variables {{...}} que se interpolan
--    con datos reales al momento de renderizar/exportar PDF.
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."ReportTemplate" (
    "ReportTemplateId"  INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"         INTEGER NOT NULL DEFAULT 1,
    "CountryCode"       CHAR(2) NOT NULL,              -- 'VE', 'ES'
    "ReportCode"        VARCHAR(50) NOT NULL,           -- 'BALANCE_GENERAL_VE', 'PYG_ES', etc.
    "ReportName"        VARCHAR(200) NOT NULL,
    "LegalFramework"    VARCHAR(50) NOT NULL,           -- 'VEN-NIF', 'PGC', 'PGC-PYME'
    "LegalReference"    VARCHAR(300) NULL,              -- 'BA VEN-NIF 1, parrafos 55-80'
    "TemplateContent"   TEXT NOT NULL,                 -- Markdown con {{variables}}
    "HeaderJson"        TEXT NULL,                     -- JSON config cabecera
    "FooterJson"        TEXT NULL,                     -- JSON config pie de pagina
    "IsDefault"         BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
    "Version"           INTEGER NOT NULL DEFAULT 1,
    "CreatedByUserId"   INTEGER NULL,
    "CreatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT ((NOW() AT TIME ZONE 'UTC')),
    CONSTRAINT "UQ_acct_RT" UNIQUE ("CompanyId", "CountryCode", "ReportCode"),
    CONSTRAINT "FK_acct_RT_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT "CK_acct_RT_Framework" CHECK ("LegalFramework" IN ('VEN-NIF','PGC','PGC-PYME','NIIF-PYME','NIIF-FULL'))
);

-- ============================================================================
-- 7. acct.ReportTemplateVariable
--    Define las variables disponibles para interpolar en cada plantilla.
--    Ejemplo: {{companyName}} -> cfg.Company.CompanyName
--             {{table:balanceGeneral}} -> SP usp_Acct_Report_BalanceGeneral
-- ============================================================================
CREATE TABLE IF NOT EXISTS acct."ReportTemplateVariable" (
    "VariableId"        INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "ReportTemplateId"  INTEGER NOT NULL,
    "VariableName"      VARCHAR(100) NOT NULL,          -- 'companyName', 'table:balanceGeneral'
    "VariableType"      VARCHAR(20) NOT NULL,            -- 'TEXT','DATE','TABLE','CURRENCY','NUMBER'
    "DataSource"        VARCHAR(200) NULL,               -- SP name o campo config
    "DefaultValue"      VARCHAR(500) NULL,
    "Description"       VARCHAR(300) NULL,               -- ayuda para el editor
    "SortOrder"         INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "FK_acct_RTV_Template" FOREIGN KEY ("ReportTemplateId")
        REFERENCES acct."ReportTemplate"("ReportTemplateId") ON DELETE CASCADE,
    CONSTRAINT "CK_acct_RTV_Type" CHECK ("VariableType" IN ('TEXT','DATE','TABLE','CURRENCY','NUMBER','BOOLEAN'))
);

CREATE INDEX IF NOT EXISTS "IX_acct_RTV_Template"
    ON acct."ReportTemplateVariable"("ReportTemplateId");
