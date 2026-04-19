-- ============================================
-- Zentto ERP — Table definitions
-- Extracted from zentto_dev via pg_dump
-- Date: 2026-03-30
-- ============================================

SET default_tablespace = '';
SET default_table_access_method = heap;


CREATE TABLE acct."Account" (
    "AccountId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "AccountCode" character varying(40) NOT NULL,
    "AccountName" character varying(200) NOT NULL,
    "AccountType" character(1) NOT NULL,
    "AccountLevel" integer DEFAULT 1 NOT NULL,
    "ParentAccountId" bigint,
    "AllowsPosting" boolean DEFAULT true NOT NULL,
    "RequiresAuxiliary" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_acct_Account_AccountType" CHECK (("AccountType" = ANY (ARRAY['A'::bpchar, 'P'::bpchar, 'C'::bpchar, 'I'::bpchar, 'G'::bpchar])))
);


CREATE TABLE acct."FixedAssetCategory" (
    "CategoryId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "CategoryCode" character varying(20) NOT NULL,
    "CategoryName" character varying(200) NOT NULL,
    "DefaultUsefulLifeMonths" integer NOT NULL,
    "DefaultDepreciationMethod" character varying(20) DEFAULT 'STRAIGHT_LINE'::character varying NOT NULL,
    "DefaultResidualPercent" numeric(5,2) DEFAULT 0,
    "DefaultAssetAccountCode" character varying(20),
    "DefaultDeprecAccountCode" character varying(20),
    "DefaultExpenseAccountCode" character varying(20),
    "CountryCode" character varying(2),
    "IsActive" boolean DEFAULT true,
    "IsDeleted" boolean DEFAULT false,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE ar."SalesDocument" (
    "DocumentId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) NOT NULL,
    "CustomerCode" character varying(60),
    "CustomerName" character varying(255),
    "FiscalId" character varying(20),
    "DocumentDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "DueDate" timestamp without time zone,
    "DocumentTime" character varying(20) DEFAULT to_char((now() AT TIME ZONE 'UTC'::text), 'HH24:MI:SS'::text),
    "SubTotal" numeric(18,4) DEFAULT 0,
    "TaxableAmount" numeric(18,4) DEFAULT 0,
    "ExemptAmount" numeric(18,4) DEFAULT 0,
    "TaxAmount" numeric(18,4) DEFAULT 0,
    "TaxRate" numeric(8,4) DEFAULT 0,
    "TotalAmount" numeric(18,4) DEFAULT 0,
    "DiscountAmount" numeric(18,4) DEFAULT 0,
    "IsVoided" boolean DEFAULT false,
    "IsPaid" character varying(1) DEFAULT 'N'::character varying,
    "IsInvoiced" character varying(1) DEFAULT 'N'::character varying,
    "IsDelivered" character varying(1) DEFAULT 'N'::character varying,
    "OriginDocumentNumber" character varying(60),
    "OriginDocumentType" character varying(20),
    "ControlNumber" character varying(60),
    "IsLegal" boolean DEFAULT false,
    "IsPrinted" boolean DEFAULT false,
    "Notes" character varying(500),
    "Concept" character varying(255),
    "PaymentTerms" character varying(255),
    "ShipToAddress" character varying(255),
    "SellerCode" character varying(60),
    "DepartmentCode" character varying(50),
    "LocationCode" character varying(100),
    "CurrencyCode" character varying(20) DEFAULT 'BS'::character varying,
    "ExchangeRate" numeric(18,6) DEFAULT 1,
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "ReportDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "HostName" character varying(255),
    "VehiclePlate" character varying(20),
    "Mileage" integer,
    "TollAmount" numeric(18,4) DEFAULT 0,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE ar."SalesDocumentLine" (
    "LineId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) NOT NULL,
    "LineNumber" integer DEFAULT 0,
    "ProductCode" character varying(60),
    "Description" character varying(255),
    "AlternateCode" character varying(60),
    "Quantity" numeric(18,4) DEFAULT 0,
    "UnitPrice" numeric(18,4) DEFAULT 0,
    "DiscountedPrice" numeric(18,4) DEFAULT 0,
    "UnitCost" numeric(18,4) DEFAULT 0,
    "SubTotal" numeric(18,4) DEFAULT 0,
    "DiscountAmount" numeric(18,4) DEFAULT 0,
    "TotalAmount" numeric(18,4) DEFAULT 0,
    "TaxRate" numeric(8,4) DEFAULT 0,
    "TaxAmount" numeric(18,4) DEFAULT 0,
    "IsVoided" boolean DEFAULT false,
    "RelatedRef" character varying(10) DEFAULT '0'::character varying,
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "LineDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE ar."SalesDocumentPayment" (
    "PaymentId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) DEFAULT 'FACT'::character varying NOT NULL,
    "PaymentMethod" character varying(30),
    "BankCode" character varying(60),
    "PaymentNumber" character varying(60),
    "Amount" numeric(18,4) DEFAULT 0,
    "AmountBs" numeric(18,4) DEFAULT 0,
    "ExchangeRate" numeric(18,6) DEFAULT 1,
    "PaymentDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "DueDate" timestamp without time zone,
    "ReferenceNumber" character varying(100),
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE pay."CompanyPaymentConfig" (
    "Id" integer NOT NULL,
    "EmpresaId" integer NOT NULL,
    "SucursalId" integer DEFAULT 0 NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ProviderId" integer NOT NULL,
    "Environment" character varying(10) DEFAULT 'sandbox'::character varying,
    "ClientId" character varying(500),
    "ClientSecret" character varying(500),
    "MerchantId" character varying(100),
    "TerminalId" character varying(100),
    "IntegratorId" character varying(50),
    "CertificatePath" character varying(500),
    "ExtraConfig" text,
    "AutoCapture" boolean DEFAULT true,
    "AllowRefunds" boolean DEFAULT true,
    "MaxRefundDays" integer DEFAULT 30,
    "IsActive" boolean DEFAULT true,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE pay."Transactions" (
    "Id" bigint NOT NULL,
    "TransactionUUID" character varying(36) NOT NULL,
    "EmpresaId" integer NOT NULL,
    "SucursalId" integer DEFAULT 0 NOT NULL,
    "SourceType" character varying(30) NOT NULL,
    "SourceId" integer,
    "SourceNumber" character varying(50),
    "PaymentMethodCode" character varying(30) NOT NULL,
    "ProviderId" integer,
    "Currency" character varying(3) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "CommissionAmount" numeric(18,2),
    "NetAmount" numeric(18,2),
    "ExchangeRate" numeric(18,6),
    "AmountInBase" numeric(18,2),
    "TrxType" character varying(20) NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "GatewayTrxId" character varying(100),
    "GatewayAuthCode" character varying(50),
    "GatewayResponse" text,
    "GatewayMessage" character varying(500),
    "CardLastFour" character varying(4),
    "CardBrand" character varying(20),
    "MobileNumber" character varying(20),
    "BankCode" character varying(10),
    "PaymentRef" character varying(50),
    "IsReconciled" boolean DEFAULT false,
    "ReconciledAt" timestamp without time zone,
    "ReconciliationId" bigint,
    "StationId" character varying(50),
    "CashierId" character varying(20),
    "IpAddress" character varying(45),
    "UserAgent" character varying(500),
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE acct."AccountMonetaryClass" (
    "AccountMonetaryClassId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "AccountId" bigint NOT NULL,
    "Classification" character varying(20) NOT NULL,
    "SubClassification" character varying(40),
    "ReexpressionAccountId" bigint,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_AMC_Class" CHECK ((("Classification")::text = ANY ((ARRAY['MONETARY'::character varying, 'NON_MONETARY'::character varying])::text[])))
);


CREATE TABLE acct."AccountingPolicy" (
    "AccountingPolicyId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ModuleCode" character varying(20) NOT NULL,
    "ProcessCode" character varying(40) NOT NULL,
    "Nature" character varying(10) NOT NULL,
    "AccountId" bigint NOT NULL,
    "PriorityOrder" integer DEFAULT 1 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_Policy_Nature" CHECK ((("Nature")::text = ANY ((ARRAY['DEBIT'::character varying, 'CREDIT'::character varying])::text[])))
);


CREATE TABLE acct."BankDeposit" (
    "BankDepositId" integer NOT NULL,
    "Amount" numeric(18,4) DEFAULT 0 NOT NULL,
    "CheckNumber" character varying(80),
    "BankAccount" character varying(120),
    "CustomerCode" character varying(60),
    "IsRelated" boolean DEFAULT false NOT NULL,
    "BankName" character varying(120),
    "DocumentRef" character varying(60),
    "OperationType" character varying(20),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL
);


CREATE TABLE acct."Budget" (
    "BudgetId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BudgetName" character varying(200) NOT NULL,
    "FiscalYear" smallint NOT NULL,
    "CostCenterCode" character varying(20),
    "Status" character varying(10) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT ck_acct_bud_status CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'APPROVED'::character varying, 'CLOSED'::character varying])::text[])))
);


CREATE TABLE acct."BudgetLine" (
    "BudgetLineId" bigint NOT NULL,
    "BudgetId" integer NOT NULL,
    "AccountCode" character varying(20) NOT NULL,
    "Month01" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month02" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month03" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month04" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month05" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month06" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month07" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month08" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month09" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month10" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month11" numeric(18,2) DEFAULT 0 NOT NULL,
    "Month12" numeric(18,2) DEFAULT 0 NOT NULL,
    "AnnualTotal" numeric(18,2) GENERATED ALWAYS AS (((((((((((("Month01" + "Month02") + "Month03") + "Month04") + "Month05") + "Month06") + "Month07") + "Month08") + "Month09") + "Month10") + "Month11") + "Month12")) STORED,
    "Notes" character varying(200)
);


CREATE TABLE acct."CostCenter" (
    "CostCenterId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CostCenterCode" character varying(20) NOT NULL,
    "CostCenterName" character varying(200) NOT NULL,
    "ParentCostCenterId" integer,
    "Level" smallint DEFAULT 1 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE acct."DocumentLink" (
    "DocumentLinkId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "ModuleCode" character varying(20) NOT NULL,
    "DocumentType" character varying(20) NOT NULL,
    "DocumentNumber" character varying(120) NOT NULL,
    "NativeDocumentId" bigint,
    "JournalEntryId" bigint NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE acct."EquityMovement" (
    "EquityMovementId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "FiscalYear" smallint NOT NULL,
    "AccountId" bigint NOT NULL,
    "AccountCode" character varying(30) NOT NULL,
    "AccountName" character varying(200),
    "MovementType" character varying(30) NOT NULL,
    "MovementDate" date NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "JournalEntryId" bigint,
    "Description" character varying(400),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_EM_Type" CHECK ((("MovementType")::text = ANY ((ARRAY['CAPITAL_INCREASE'::character varying, 'CAPITAL_DECREASE'::character varying, 'RESERVE_LEGAL'::character varying, 'RESERVE_STATUTORY'::character varying, 'RESERVE_VOLUNTARY'::character varying, 'RETAINED_EARNINGS'::character varying, 'ACCUMULATED_DEFICIT'::character varying, 'DIVIDEND_CASH'::character varying, 'DIVIDEND_STOCK'::character varying, 'REVALUATION_SURPLUS'::character varying, 'INFLATION_ADJUST'::character varying, 'NET_INCOME'::character varying, 'NET_LOSS'::character varying, 'OTHER_COMPREHENSIVE'::character varying, 'OPENING_BALANCE'::character varying])::text[])))
);


CREATE TABLE acct."FiscalPeriod" (
    "FiscalPeriodId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "PeriodCode" character(6) NOT NULL,
    "PeriodName" character varying(50),
    "YearCode" smallint NOT NULL,
    "MonthCode" smallint NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date NOT NULL,
    "Status" character varying(10) DEFAULT 'OPEN'::character varying NOT NULL,
    "ClosedAt" timestamp without time zone,
    "ClosedByUserId" integer,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT ck_acct_fp_status CHECK ((("Status")::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSED'::character varying, 'LOCKED'::character varying])::text[])))
);


CREATE TABLE acct."FixedAsset" (
    "AssetId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer DEFAULT 0 NOT NULL,
    "AssetCode" character varying(40) NOT NULL,
    "Description" character varying(250) NOT NULL,
    "CategoryId" integer,
    "AcquisitionDate" date NOT NULL,
    "AcquisitionCost" numeric(18,2) NOT NULL,
    "ResidualValue" numeric(18,2) DEFAULT 0,
    "UsefulLifeMonths" integer NOT NULL,
    "DepreciationMethod" character varying(20) DEFAULT 'STRAIGHT_LINE'::character varying NOT NULL,
    "AssetAccountCode" character varying(20) NOT NULL,
    "DeprecAccountCode" character varying(20) NOT NULL,
    "ExpenseAccountCode" character varying(20) NOT NULL,
    "CostCenterCode" character varying(20),
    "Location" character varying(200),
    "SerialNumber" character varying(100),
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying,
    "DisposalDate" date,
    "DisposalAmount" numeric(18,2),
    "DisposalReason" character varying(500),
    "DisposalEntryId" bigint,
    "AcquisitionEntryId" bigint,
    "UnitsCapacity" integer,
    "CurrencyCode" character varying(3) DEFAULT 'VES'::character varying,
    "IsDeleted" boolean DEFAULT false,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "UpdatedAt" timestamp without time zone,
    "CreatedBy" character varying(40),
    "UpdatedBy" character varying(40)
);


CREATE TABLE acct."FixedAssetDepreciation" (
    "DepreciationId" bigint NOT NULL,
    "AssetId" bigint NOT NULL,
    "PeriodCode" character varying(7) NOT NULL,
    "DepreciationDate" date NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "AccumulatedDepreciation" numeric(18,2) NOT NULL,
    "BookValue" numeric(18,2) NOT NULL,
    "JournalEntryId" bigint,
    "Status" character varying(20) DEFAULT 'GENERATED'::character varying,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE acct."FixedAssetImprovement" (
    "ImprovementId" bigint NOT NULL,
    "AssetId" bigint NOT NULL,
    "ImprovementDate" date NOT NULL,
    "Description" character varying(500) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "AdditionalLifeMonths" integer DEFAULT 0,
    "JournalEntryId" bigint,
    "CreatedBy" character varying(40),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE acct."FixedAssetRevaluation" (
    "RevaluationId" bigint NOT NULL,
    "AssetId" bigint NOT NULL,
    "RevaluationDate" date NOT NULL,
    "PreviousCost" numeric(18,2) NOT NULL,
    "NewCost" numeric(18,2) NOT NULL,
    "PreviousAccumDeprec" numeric(18,2) NOT NULL,
    "NewAccumDeprec" numeric(18,2) NOT NULL,
    "IndexFactor" numeric(12,6) NOT NULL,
    "JournalEntryId" bigint,
    "CountryCode" character varying(2) NOT NULL,
    "CreatedBy" character varying(40),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE acct."InflationAdjustment" (
    "InflationAdjustmentId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL,
    "PeriodCode" character(6) NOT NULL,
    "FiscalYear" smallint NOT NULL,
    "AdjustmentDate" date NOT NULL,
    "BaseIndexValue" numeric(18,6) NOT NULL,
    "EndIndexValue" numeric(18,6) NOT NULL,
    "AccumulatedInflation" numeric(18,6),
    "ReexpressionFactor" numeric(18,8) NOT NULL,
    "JournalEntryId" bigint,
    "TotalMonetaryGainLoss" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalAdjustmentAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_IA_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'POSTED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE acct."InflationAdjustmentLine" (
    "LineId" bigint NOT NULL,
    "InflationAdjustmentId" integer NOT NULL,
    "AccountId" bigint NOT NULL,
    "AccountCode" character varying(30) NOT NULL,
    "AccountName" character varying(200),
    "Classification" character varying(20) NOT NULL,
    "HistoricalBalance" numeric(18,2) NOT NULL,
    "ReexpressionFactor" numeric(18,8) NOT NULL,
    "AdjustedBalance" numeric(18,2) NOT NULL,
    "AdjustmentAmount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE acct."InflationIndex" (
    "InflationIndexId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "IndexName" character varying(30) NOT NULL,
    "PeriodCode" character(6) NOT NULL,
    "IndexValue" numeric(18,6) NOT NULL,
    "SourceReference" character varying(200),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_II_Country" CHECK (("CountryCode" = ANY (ARRAY['VE'::bpchar, 'ES'::bpchar, 'CO'::bpchar, 'MX'::bpchar, 'US'::bpchar])))
);


CREATE TABLE acct."JournalEntry" (
    "JournalEntryId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "EntryNumber" character varying(40) NOT NULL,
    "EntryDate" date NOT NULL,
    "PeriodCode" character varying(7) NOT NULL,
    "EntryType" character varying(20) NOT NULL,
    "ReferenceNumber" character varying(120),
    "Concept" character varying(400) NOT NULL,
    "CurrencyCode" character(3) NOT NULL,
    "ExchangeRate" numeric(18,6) DEFAULT 1 NOT NULL,
    "TotalDebit" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalCredit" numeric(18,2) DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'APPROVED'::character varying NOT NULL,
    "SourceModule" character varying(40),
    "SourceDocumentType" character varying(40),
    "SourceDocumentNo" character varying(120),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_acct_JE_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'APPROVED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE acct."JournalEntryLine" (
    "JournalEntryLineId" bigint NOT NULL,
    "JournalEntryId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "AccountId" bigint NOT NULL,
    "AccountCodeSnapshot" character varying(40) NOT NULL,
    "Description" character varying(400),
    "DebitAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "CreditAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "AuxiliaryType" character varying(20),
    "AuxiliaryCode" character varying(80),
    "CostCenterCode" character varying(20),
    "SourceDocumentNo" character varying(120),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_acct_JEL_DebitCredit" CHECK ((("DebitAmount" >= (0)::numeric) AND ("CreditAmount" >= (0)::numeric) AND (NOT (("DebitAmount" > (0)::numeric) AND ("CreditAmount" > (0)::numeric)))))
);


CREATE TABLE acct."RecurringEntry" (
    "RecurringEntryId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "TemplateName" character varying(200) NOT NULL,
    "Frequency" character varying(10) DEFAULT 'MONTHLY'::character varying NOT NULL,
    "NextExecutionDate" date NOT NULL,
    "LastExecutedDate" date,
    "TimesExecuted" integer DEFAULT 0 NOT NULL,
    "MaxExecutions" integer,
    "TipoAsiento" character varying(20) DEFAULT 'DIARIO'::character varying NOT NULL,
    "Concepto" character varying(300) NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT ck_acct_re_freq CHECK ((("Frequency")::text = ANY ((ARRAY['DAILY'::character varying, 'WEEKLY'::character varying, 'MONTHLY'::character varying, 'QUARTERLY'::character varying, 'YEARLY'::character varying])::text[])))
);


CREATE TABLE acct."RecurringEntryLine" (
    "LineId" integer NOT NULL,
    "RecurringEntryId" integer NOT NULL,
    "AccountCode" character varying(20) NOT NULL,
    "Description" character varying(200),
    "CostCenterCode" character varying(20),
    "Debit" numeric(18,2) DEFAULT 0 NOT NULL,
    "Credit" numeric(18,2) DEFAULT 0 NOT NULL
);


CREATE TABLE acct."ReportTemplate" (
    "ReportTemplateId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ReportCode" character varying(50) NOT NULL,
    "ReportName" character varying(200) NOT NULL,
    "LegalFramework" character varying(50) NOT NULL,
    "LegalReference" character varying(300),
    "TemplateContent" text NOT NULL,
    "HeaderJson" text,
    "FooterJson" text,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "Version" integer DEFAULT 1 NOT NULL,
    "CreatedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_acct_RT_Framework" CHECK ((("LegalFramework")::text = ANY ((ARRAY['VEN-NIF'::character varying, 'PGC'::character varying, 'PGC-PYME'::character varying, 'NIIF-PYME'::character varying, 'NIIF-FULL'::character varying])::text[])))
);


CREATE TABLE acct."ReportTemplateVariable" (
    "VariableId" integer NOT NULL,
    "ReportTemplateId" integer NOT NULL,
    "VariableName" character varying(100) NOT NULL,
    "VariableType" character varying(20) NOT NULL,
    "DataSource" character varying(200),
    "DefaultValue" character varying(500),
    "Description" character varying(300),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "CK_acct_RTV_Type" CHECK ((("VariableType")::text = ANY ((ARRAY['TEXT'::character varying, 'DATE'::character varying, 'TABLE'::character varying, 'CURRENCY'::character varying, 'NUMBER'::character varying, 'BOOLEAN'::character varying])::text[])))
);


CREATE TABLE ap."PayableApplication" (
    "PayableApplicationId" bigint NOT NULL,
    "PayableDocumentId" bigint NOT NULL,
    "ApplyDate" date NOT NULL,
    "AppliedAmount" numeric(18,2) NOT NULL,
    "PaymentReference" character varying(120),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RetentionType" character varying(20),
    "RetentionRate" numeric(8,4),
    "RetentionAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "NetAmount" numeric(18,2),
    "WithholdingVoucherId" bigint
);


CREATE TABLE ap."PayableDocument" (
    "PayableDocumentId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "SupplierId" bigint NOT NULL,
    "DocumentType" character varying(20) NOT NULL,
    "DocumentNumber" character varying(120) NOT NULL,
    "IssueDate" date NOT NULL,
    "DueDate" date,
    "CurrencyCode" character(3) NOT NULL,
    "TotalAmount" numeric(18,2) NOT NULL,
    "PendingAmount" numeric(18,2) NOT NULL,
    "PaidFlag" boolean DEFAULT false NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_ap_PayDoc_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDING'::character varying, 'PARTIAL'::character varying, 'PAID'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE ap."PurchaseDocument" (
    "DocumentId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) DEFAULT 'COMPRA'::character varying NOT NULL,
    "SupplierCode" character varying(60),
    "SupplierName" character varying(255),
    "FiscalId" character varying(15),
    "DocumentDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "DueDate" timestamp without time zone,
    "ReceiptDate" timestamp without time zone,
    "PaymentDate" timestamp without time zone,
    "DocumentTime" character varying(20) DEFAULT to_char((now() AT TIME ZONE 'UTC'::text), 'HH24:MI:SS'::text),
    "SubTotal" numeric(18,4) DEFAULT 0,
    "TaxableAmount" numeric(18,4) DEFAULT 0,
    "ExemptAmount" numeric(18,4) DEFAULT 0,
    "TaxAmount" numeric(18,4) DEFAULT 0,
    "TaxRate" numeric(8,4) DEFAULT 0,
    "TotalAmount" numeric(18,4) DEFAULT 0,
    "ExemptTotalAmount" numeric(18,4) DEFAULT 0,
    "DiscountAmount" numeric(18,4) DEFAULT 0,
    "IsVoided" boolean DEFAULT false,
    "IsPaid" character varying(1) DEFAULT 'N'::character varying,
    "IsReceived" character varying(1) DEFAULT 'N'::character varying,
    "IsLegal" boolean DEFAULT false,
    "OriginDocumentNumber" character varying(60),
    "ControlNumber" character varying(60),
    "VoucherNumber" character varying(50),
    "VoucherDate" timestamp without time zone,
    "RetainedTax" numeric(18,4) DEFAULT 0,
    "IsrCode" character varying(50),
    "IsrAmount" numeric(18,4) DEFAULT 0,
    "IsrSubjectAmount" numeric(18,4) DEFAULT 0,
    "RetentionRate" numeric(8,4) DEFAULT 0,
    "ImportAmount" numeric(18,4) DEFAULT 0,
    "ImportTax" numeric(18,4) DEFAULT 0,
    "ImportBase" numeric(18,4) DEFAULT 0,
    "FreightAmount" numeric(18,4) DEFAULT 0,
    "Concept" character varying(255),
    "Notes" character varying(500),
    "OrderNumber" character varying(20),
    "ReceivedBy" character varying(20),
    "WarehouseCode" character varying(50),
    "CurrencyCode" character varying(20) DEFAULT 'BS'::character varying,
    "ExchangeRate" numeric(18,6) DEFAULT 1,
    "UsdAmount" numeric(18,4) DEFAULT 0,
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "ShortUserCode" character varying(10),
    "ReportDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "HostName" character varying(255),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE ap."PurchaseDocumentLine" (
    "LineId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) DEFAULT 'COMPRA'::character varying NOT NULL,
    "LineNumber" integer DEFAULT 0,
    "ProductCode" character varying(60),
    "Description" character varying(255),
    "Quantity" numeric(18,4) DEFAULT 0,
    "UnitPrice" numeric(18,4) DEFAULT 0,
    "UnitCost" numeric(18,4) DEFAULT 0,
    "SubTotal" numeric(18,4) DEFAULT 0,
    "DiscountAmount" numeric(18,4) DEFAULT 0,
    "TotalAmount" numeric(18,4) DEFAULT 0,
    "TaxRate" numeric(8,4) DEFAULT 0,
    "TaxAmount" numeric(18,4) DEFAULT 0,
    "IsVoided" boolean DEFAULT false,
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "LineDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE ap."PurchaseDocumentPayment" (
    "PaymentId" integer NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "SerialType" character varying(60) DEFAULT ''::character varying NOT NULL,
    "FiscalMemoryNumber" character varying(80) DEFAULT ''::character varying,
    "OperationType" character varying(20) DEFAULT 'COMPRA'::character varying NOT NULL,
    "PaymentMethod" character varying(30),
    "BankCode" character varying(60),
    "PaymentNumber" character varying(60),
    "Amount" numeric(18,4) DEFAULT 0,
    "PaymentDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "DueDate" timestamp without time zone,
    "ReferenceNumber" character varying(100),
    "UserCode" character varying(60) DEFAULT 'API'::character varying,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE ar."ReceivableApplication" (
    "ReceivableApplicationId" bigint NOT NULL,
    "ReceivableDocumentId" bigint NOT NULL,
    "ApplyDate" date NOT NULL,
    "AppliedAmount" numeric(18,2) NOT NULL,
    "PaymentReference" character varying(120),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE ar."ReceivableDocument" (
    "ReceivableDocumentId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CustomerId" bigint NOT NULL,
    "DocumentType" character varying(20) NOT NULL,
    "DocumentNumber" character varying(120) NOT NULL,
    "IssueDate" date NOT NULL,
    "DueDate" date,
    "CurrencyCode" character(3) NOT NULL,
    "TotalAmount" numeric(18,2) NOT NULL,
    "PendingAmount" numeric(18,2) NOT NULL,
    "PaidFlag" boolean DEFAULT false NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_ar_RecDoc_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDING'::character varying, 'PARTIAL'::character varying, 'PAID'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE audit."AuditLog" (
    "AuditLogId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "UserId" integer,
    "UserName" character varying(100),
    "ModuleName" character varying(50) NOT NULL,
    "EntityName" character varying(100) NOT NULL,
    "EntityId" character varying(50),
    "ActionType" character varying(10) NOT NULL,
    "Summary" character varying(500),
    "OldValues" text,
    "NewValues" text,
    "IpAddress" character varying(50),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."AppSetting" (
    "SettingId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "Module" character varying(60) NOT NULL,
    "SettingKey" character varying(120) NOT NULL,
    "SettingValue" text DEFAULT ''::text NOT NULL,
    "ValueType" character varying(20) DEFAULT 'string'::character varying NOT NULL,
    "Description" character varying(500),
    "IsReadOnly" boolean DEFAULT false NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedByUserId" integer
);


CREATE TABLE cfg."Branch" (
    "BranchId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchCode" character varying(20) NOT NULL,
    "BranchName" character varying(150) NOT NULL,
    "AddressLine" character varying(250),
    "Phone" character varying(40),
    "CountryCode" character varying(5),
    "CurrencyCode" character varying(5),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE cfg."Company" (
    "CompanyId" integer NOT NULL,
    "CompanyCode" character varying(20) NOT NULL,
    "LegalName" character varying(200) NOT NULL,
    "TradeName" character varying(200),
    "FiscalCountryCode" character(2) NOT NULL,
    "FiscalId" character varying(30),
    "BaseCurrency" character(3) NOT NULL,
    "Address" character varying(500),
    "LegalRep" character varying(200),
    "Phone" character varying(50),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "LicenseKey" character varying(64),
    "Plan" character varying(30),
    "TenantStatus" character varying(20),
    "OwnerEmail" character varying(255),
    "TenantSubdomain" character varying(100),
    "ProvisionedAt" timestamp without time zone,
    "PaddleSubscriptionId" character varying(100)
);


CREATE TABLE cfg."CompanyProfile" (
    "ProfileId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "Phone" character varying(60),
    "AddressLine" character varying(250),
    "NitCode" character varying(50),
    "AltFiscalId" character varying(50),
    "WebSite" character varying(150),
    "LogoBase64" text,
    "Notes" character varying(500),
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."Country" (
    "CountryCode" character(2) NOT NULL,
    "CountryName" character varying(80) NOT NULL,
    "CurrencyCode" character(3) NOT NULL,
    "TaxAuthorityCode" character varying(20) NOT NULL,
    "FiscalIdName" character varying(20) NOT NULL,
    "TimeZoneIana" character varying(50),
    "CurrencySymbol" character varying(10),
    "DecimalSeparator" character(1) DEFAULT '.'::bpchar,
    "ThousandsSeparator" character(1) DEFAULT ','::bpchar,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."Currency" (
    "CurrencyId" integer NOT NULL,
    "CurrencyCode" character(3) NOT NULL,
    "CurrencyName" character varying(60) NOT NULL,
    "Symbol" character varying(10),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."DocumentSequence" (
    "SequenceId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer,
    "DocumentType" character varying(20) NOT NULL,
    "Prefix" character varying(10),
    "Suffix" character varying(10),
    "CurrentNumber" bigint DEFAULT 1 NOT NULL,
    "PaddingLength" integer DEFAULT 8 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."EntityImage" (
    "EntityImageId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "EntityType" character varying(50) NOT NULL,
    "EntityId" bigint NOT NULL,
    "MediaAssetId" bigint NOT NULL,
    "RoleCode" character varying(50) DEFAULT 'PRODUCT_IMAGE'::character varying NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsPrimary" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."ExchangeRateDaily" (
    "ExchangeRateDailyId" bigint NOT NULL,
    "CurrencyCode" character(3) NOT NULL,
    "RateToBase" numeric(18,6) NOT NULL,
    "RateDate" date NOT NULL,
    "SourceName" character varying(120),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer
);


CREATE TABLE cfg."Holiday" (
    "HolidayId" integer NOT NULL,
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL,
    "HolidayDate" date NOT NULL,
    "HolidayName" character varying(100) NOT NULL,
    "IsRecurring" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."Lookup" (
    "LookupId" integer NOT NULL,
    "LookupTypeId" integer NOT NULL,
    "Code" character varying(50) NOT NULL,
    "Label" character varying(150) NOT NULL,
    "LabelEn" character varying(150),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "Extra" character varying(500)
);


CREATE TABLE cfg."LookupType" (
    "LookupTypeId" integer NOT NULL,
    "TypeCode" character varying(50) NOT NULL,
    "TypeName" character varying(100) NOT NULL,
    "Description" character varying(250)
);


CREATE TABLE cfg."MediaAsset" (
    "MediaAssetId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "StorageProvider" character varying(30) DEFAULT 'external'::character varying NOT NULL,
    "StorageKey" character varying(500) NOT NULL,
    "PublicUrl" character varying(500) NOT NULL,
    "OriginalFileName" character varying(255),
    "MimeType" character varying(100),
    "FileExtension" character varying(10),
    "FileSizeBytes" bigint DEFAULT 0 NOT NULL,
    "AltText" character varying(255),
    "WidthPx" integer,
    "HeightPx" integer,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."ReportTemplate" (
    "ReportId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ReportCode" character varying(50) NOT NULL,
    "ReportName" character varying(150) NOT NULL,
    "ReportType" character varying(20) DEFAULT 'REPORT'::character varying NOT NULL,
    "QueryText" text,
    "Parameters" text,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."State" (
    "StateId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "StateCode" character varying(10) NOT NULL,
    "StateName" character varying(100) NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL
);


CREATE TABLE cfg."TaxUnit" (
    "TaxUnitId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "TaxYear" integer NOT NULL,
    "UnitValue" numeric(18,4) NOT NULL,
    "Currency" character(3) DEFAULT 'VES'::bpchar NOT NULL,
    "EffectiveDate" date NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."PlanDefinition" (
    "PlanCode" character varying(30) NOT NULL,
    "PlanName" character varying(100) NOT NULL,
    "MaxUsers" integer,
    "MaxCompanies" integer,
    "MaxBranches" integer,
    "MultiCompanyEnabled" boolean DEFAULT false,
    "MonthlyPriceUsd" numeric(10,2),
    "AnnualPriceUsd" numeric(10,2),
    "IsActive" boolean DEFAULT true,
    "SortOrder" integer DEFAULT 0,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE cfg."PlanModule" (
    "PlanModuleId" bigint NOT NULL,
    "PlanCode" character varying(30) NOT NULL,
    "ModuleCode" character varying(60) NOT NULL,
    "IsEnabled" boolean DEFAULT true,
    "SortOrder" integer DEFAULT 0,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE crm."Activity" (
    "ActivityId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "LeadId" bigint,
    "CustomerId" bigint,
    "ActivityType" character varying(20) DEFAULT 'NOTE'::character varying NOT NULL,
    "Subject" character varying(200) NOT NULL,
    "Description" text,
    "DueDate" timestamp without time zone,
    "CompletedAt" timestamp without time zone,
    "AssignedToUserId" integer,
    "IsCompleted" boolean DEFAULT false NOT NULL,
    "Priority" character varying(10) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "DeletedAt" timestamp without time zone,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_crm_Activity_Priority" CHECK ((("Priority")::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT "CK_crm_Activity_Type" CHECK ((("ActivityType")::text = ANY ((ARRAY['CALL'::character varying, 'EMAIL'::character varying, 'MEETING'::character varying, 'NOTE'::character varying, 'TASK'::character varying, 'FOLLOWUP'::character varying])::text[])))
);


CREATE TABLE crm."Agent" (
    "AgentId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "QueueId" bigint,
    "AgentCode" character varying(20) NOT NULL,
    "AgentName" character varying(200) NOT NULL,
    "Extension" character varying(20),
    "Status" character varying(20) DEFAULT 'OFFLINE'::character varying NOT NULL,
    "MaxConcurrentCalls" integer DEFAULT 1 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_Agent_Status" CHECK ((("Status")::text = ANY ((ARRAY['AVAILABLE'::character varying, 'BUSY'::character varying, 'ON_CALL'::character varying, 'BREAK'::character varying, 'OFFLINE'::character varying])::text[])))
);


CREATE TABLE crm."AutomationLog" (
    "LogId" bigint NOT NULL,
    "RuleId" bigint NOT NULL,
    "LeadId" bigint,
    "ActionTaken" character varying(50) NOT NULL,
    "ActionResult" text,
    "ExecutedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE crm."AutomationRule" (
    "RuleId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "RuleName" character varying(200) NOT NULL,
    "TriggerEvent" character varying(50) NOT NULL,
    "ConditionJson" jsonb DEFAULT '{}'::jsonb,
    "ActionType" character varying(50) NOT NULL,
    "ActionConfig" jsonb DEFAULT '{}'::jsonb,
    "IsActive" boolean DEFAULT true NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL
);


CREATE TABLE crm."CallLog" (
    "CallLogId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "AgentId" bigint,
    "QueueId" bigint,
    "CallDirection" character varying(10) NOT NULL,
    "CallerNumber" character varying(30) NOT NULL,
    "CalledNumber" character varying(30) NOT NULL,
    "CustomerCode" character varying(24),
    "CustomerId" bigint,
    "LeadId" bigint,
    "ContactName" character varying(200),
    "CallStartTime" timestamp without time zone NOT NULL,
    "CallEndTime" timestamp without time zone,
    "DurationSeconds" integer,
    "WaitSeconds" integer,
    "Result" character varying(20) NOT NULL,
    "Disposition" character varying(30),
    "Notes" text,
    "RecordingUrl" character varying(500),
    "CallbackScheduled" timestamp without time zone,
    "RelatedDocumentType" character varying(30),
    "RelatedDocumentNumber" character varying(60),
    "Tags" character varying(500),
    "SatisfactionScore" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_CallLog_Direction" CHECK ((("CallDirection")::text = ANY ((ARRAY['INBOUND'::character varying, 'OUTBOUND'::character varying])::text[]))),
    CONSTRAINT "CK_CallLog_Result" CHECK ((("Result")::text = ANY ((ARRAY['ANSWERED'::character varying, 'NO_ANSWER'::character varying, 'BUSY'::character varying, 'VOICEMAIL'::character varying, 'CALLBACK'::character varying, 'TRANSFERRED'::character varying, 'DROPPED'::character varying])::text[]))),
    CONSTRAINT "CK_CallLog_Score" CHECK ((("SatisfactionScore" IS NULL) OR (("SatisfactionScore" >= 1) AND ("SatisfactionScore" <= 5))))
);


CREATE TABLE crm."CallQueue" (
    "QueueId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "QueueCode" character varying(20) NOT NULL,
    "QueueName" character varying(100) NOT NULL,
    "QueueType" character varying(20) DEFAULT 'GENERAL'::character varying NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_CallQueue_Type" CHECK ((("QueueType")::text = ANY ((ARRAY['SALES'::character varying, 'SUPPORT'::character varying, 'COLLECTIONS'::character varying, 'GENERAL'::character varying])::text[])))
);


CREATE TABLE crm."CallScript" (
    "ScriptId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ScriptCode" character varying(20) NOT NULL,
    "ScriptName" character varying(200) NOT NULL,
    "QueueType" character varying(20) NOT NULL,
    "Content" text NOT NULL,
    "Version" integer DEFAULT 1 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE crm."Campaign" (
    "CampaignId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "CampaignCode" character varying(20) NOT NULL,
    "CampaignName" character varying(200) NOT NULL,
    "CampaignType" character varying(30) NOT NULL,
    "QueueId" bigint,
    "ScriptId" bigint,
    "StartDate" date NOT NULL,
    "EndDate" date,
    "TotalContacts" integer DEFAULT 0 NOT NULL,
    "ContactedCount" integer DEFAULT 0 NOT NULL,
    "SuccessCount" integer DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" text,
    "AssignedToUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_Campaign_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'ACTIVE'::character varying, 'PAUSED'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[]))),
    CONSTRAINT "CK_Campaign_Type" CHECK ((("CampaignType")::text = ANY ((ARRAY['OUTBOUND_SALES'::character varying, 'OUTBOUND_COLLECTION'::character varying, 'OUTBOUND_SURVEY'::character varying, 'OUTBOUND_FOLLOWUP'::character varying])::text[])))
);


CREATE TABLE crm."CampaignContact" (
    "CampaignContactId" bigint NOT NULL,
    "CampaignId" bigint NOT NULL,
    "CustomerId" bigint,
    "LeadId" bigint,
    "ContactName" character varying(200) NOT NULL,
    "Phone" character varying(30) NOT NULL,
    "Email" character varying(150),
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "Attempts" integer DEFAULT 0 NOT NULL,
    "LastAttempt" timestamp without time zone,
    "LastResult" character varying(30),
    "CallbackDate" timestamp without time zone,
    "AssignedAgentId" bigint,
    "Notes" text,
    "Priority" character varying(10) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_CampaignContact_Priority" CHECK ((("Priority")::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying])::text[]))),
    CONSTRAINT "CK_CampaignContact_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDING'::character varying, 'CALLED'::character varying, 'CALLBACK'::character varying, 'COMPLETED'::character varying, 'SKIPPED'::character varying, 'DO_NOT_CALL'::character varying])::text[])))
);


CREATE TABLE crm."Lead" (
    "LeadId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "PipelineId" bigint NOT NULL,
    "StageId" bigint NOT NULL,
    "LeadCode" character varying(40) NOT NULL,
    "ContactName" character varying(200),
    "CompanyName" character varying(200),
    "Email" character varying(150),
    "Phone" character varying(40),
    "Source" character varying(20) DEFAULT 'OTHER'::character varying NOT NULL,
    "AssignedToUserId" integer,
    "CustomerId" bigint,
    "EstimatedValue" numeric(18,2),
    "CurrencyCode" character(3) DEFAULT 'USD'::bpchar NOT NULL,
    "ExpectedCloseDate" date,
    "LostReason" character varying(500),
    "Notes" text,
    "Tags" character varying(500),
    "Priority" character varying(10) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "Status" character varying(10) DEFAULT 'OPEN'::character varying NOT NULL,
    "WonAt" timestamp without time zone,
    "LostAt" timestamp without time zone,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "DeletedAt" timestamp without time zone,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_crm_Lead_Priority" CHECK ((("Priority")::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT "CK_crm_Lead_Source" CHECK ((("Source")::text = ANY ((ARRAY['WEB'::character varying, 'REFERRAL'::character varying, 'COLD_CALL'::character varying, 'EVENT'::character varying, 'SOCIAL'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT "CK_crm_Lead_Status" CHECK ((("Status")::text = ANY ((ARRAY['OPEN'::character varying, 'WON'::character varying, 'LOST'::character varying, 'ARCHIVED'::character varying])::text[])))
);


CREATE TABLE crm."LeadHistory" (
    "HistoryId" bigint NOT NULL,
    "LeadId" bigint NOT NULL,
    "FromStageId" bigint,
    "ToStageId" bigint,
    "ChangedByUserId" integer,
    "ChangeType" character varying(20) DEFAULT 'NOTE'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_crm_LeadHistory_ChangeType" CHECK ((("ChangeType")::text = ANY ((ARRAY['STAGE_CHANGE'::character varying, 'ASSIGN'::character varying, 'NOTE'::character varying, 'STATUS'::character varying])::text[])))
);


CREATE TABLE crm."LeadScore" (
    "LeadScoreId" bigint NOT NULL,
    "LeadId" bigint NOT NULL,
    "Score" integer DEFAULT 0 NOT NULL,
    "ScoreDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "Factors" jsonb DEFAULT '{}'::jsonb,
    "CalculatedByUserId" integer
);


CREATE TABLE crm."Pipeline" (
    "PipelineId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "PipelineCode" character varying(30) NOT NULL,
    "PipelineName" character varying(150) NOT NULL,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "DeletedAt" timestamp without time zone,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE crm."PipelineStage" (
    "StageId" bigint NOT NULL,
    "PipelineId" bigint NOT NULL,
    "StageCode" character varying(30) NOT NULL,
    "StageName" character varying(100) NOT NULL,
    "StageOrder" integer DEFAULT 0 NOT NULL,
    "Probability" numeric(5,2) DEFAULT 0 NOT NULL,
    "DaysExpected" integer DEFAULT 7 NOT NULL,
    "Color" character varying(7),
    "IsClosed" boolean DEFAULT false NOT NULL,
    "IsWon" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "DeletedAt" timestamp without time zone,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE crm."SavedView" (
    "ViewId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "Entity" character varying(50) NOT NULL,
    "Name" character varying(200) NOT NULL,
    "FilterJson" jsonb DEFAULT '{}'::jsonb NOT NULL,
    "ColumnsJson" jsonb,
    "SortJson" jsonb,
    "IsShared" boolean DEFAULT false NOT NULL,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "CK_crm_SavedView_Entity" CHECK ((("Entity")::text = ANY ((ARRAY['LEAD'::character varying, 'CONTACT'::character varying, 'COMPANY'::character varying, 'DEAL'::character varying, 'ACTIVITY'::character varying])::text[])))
);


CREATE TABLE fin."Bank" (
    "BankId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BankCode" character varying(30) NOT NULL,
    "BankName" character varying(120) NOT NULL,
    "ContactName" character varying(120),
    "AddressLine" character varying(250),
    "Phones" character varying(120),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE fin."BankAccount" (
    "BankAccountId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "BankId" bigint NOT NULL,
    "AccountNumber" character varying(40) NOT NULL,
    "AccountName" character varying(150),
    "CurrencyCode" character(3) NOT NULL,
    "Balance" numeric(18,2) DEFAULT 0 NOT NULL,
    "AvailableBalance" numeric(18,2) DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE fin."BankMovement" (
    "BankMovementId" bigint NOT NULL,
    "BankAccountId" bigint NOT NULL,
    "ReconciliationId" bigint,
    "MovementDate" timestamp without time zone NOT NULL,
    "MovementType" character varying(12) NOT NULL,
    "MovementSign" smallint NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "NetAmount" numeric(18,2) NOT NULL,
    "ReferenceNo" character varying(50),
    "Beneficiary" character varying(255),
    "Concept" character varying(255),
    "CategoryCode" character varying(50),
    "RelatedDocumentNo" character varying(60),
    "RelatedDocumentType" character varying(20),
    "BalanceAfter" numeric(18,2),
    "IsReconciled" boolean DEFAULT false NOT NULL,
    "ReconciledAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "JournalEntryId" bigint,
    CONSTRAINT "CK_fin_BankMovement_Amount" CHECK (("Amount" >= (0)::numeric)),
    CONSTRAINT "CK_fin_BankMovement_Sign" CHECK (("MovementSign" = ANY (ARRAY['-1'::integer, 1])))
);


CREATE TABLE fin."BankReconciliation" (
    "BankReconciliationId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "BankAccountId" bigint NOT NULL,
    "DateFrom" date NOT NULL,
    "DateTo" date NOT NULL,
    "OpeningSystemBalance" numeric(18,2) NOT NULL,
    "ClosingSystemBalance" numeric(18,2) NOT NULL,
    "OpeningBankBalance" numeric(18,2) NOT NULL,
    "ClosingBankBalance" numeric(18,2),
    "DifferenceAmount" numeric(18,2),
    "Status" character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    "Notes" character varying(500),
    "ClosedAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "ClosedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_fin_BankRec_Status" CHECK ((("Status")::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSED'::character varying, 'CLOSED_WITH_DIFF'::character varying])::text[])))
);


CREATE TABLE fin."BankReconciliationMatch" (
    "BankReconciliationMatchId" bigint NOT NULL,
    "ReconciliationId" bigint NOT NULL,
    "BankMovementId" bigint NOT NULL,
    "StatementLineId" bigint,
    "MatchedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "MatchedByUserId" integer
);


CREATE TABLE fin."BankStatementLine" (
    "StatementLineId" bigint NOT NULL,
    "ReconciliationId" bigint NOT NULL,
    "StatementDate" timestamp without time zone NOT NULL,
    "DescriptionText" character varying(255),
    "ReferenceNo" character varying(50),
    "EntryType" character varying(12) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "Balance" numeric(18,2),
    "IsMatched" boolean DEFAULT false NOT NULL,
    "MatchedAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_fin_BankStatementLine_Amount" CHECK (("Amount" >= (0)::numeric)),
    CONSTRAINT "CK_fin_BankStatementLine_EntryType" CHECK ((("EntryType")::text = ANY ((ARRAY['DEBITO'::character varying, 'CREDITO'::character varying])::text[])))
);


CREATE TABLE fin."PettyCashBox" (
    "Id" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "Name" character varying(100) NOT NULL,
    "AccountCode" character varying(20),
    "MaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "CurrentBalance" numeric(18,2) DEFAULT 0 NOT NULL,
    "Responsible" character varying(100),
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer
);


CREATE TABLE fin."PettyCashExpense" (
    "Id" integer NOT NULL,
    "SessionId" integer NOT NULL,
    "BoxId" integer NOT NULL,
    "Category" character varying(50) NOT NULL,
    "Description" character varying(255) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "Beneficiary" character varying(150),
    "ReceiptNumber" character varying(50),
    "AccountCode" character varying(20),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer
);


CREATE TABLE fin."PettyCashSession" (
    "Id" integer NOT NULL,
    "BoxId" integer NOT NULL,
    "OpeningAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "ClosingAmount" numeric(18,2),
    "TotalExpenses" numeric(18,2) DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    "OpenedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ClosedAt" timestamp without time zone,
    "OpenedByUserId" integer,
    "ClosedByUserId" integer,
    "Notes" character varying(500)
);


CREATE TABLE fiscal."CountryConfig" (
    "CountryConfigId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "Currency" character(3) NOT NULL,
    "TaxRegime" character varying(50),
    "DefaultTaxCode" character varying(30),
    "DefaultTaxRate" numeric(9,4) NOT NULL,
    "FiscalPrinterEnabled" boolean DEFAULT false NOT NULL,
    "PrinterBrand" character varying(30),
    "PrinterPort" character varying(20),
    "VerifactuEnabled" boolean DEFAULT false NOT NULL,
    "VerifactuMode" character varying(10),
    "CertificatePath" character varying(500),
    "CertificatePassword" character varying(255),
    "AEATEndpoint" character varying(500),
    "SenderNIF" character varying(20),
    "SenderRIF" character varying(20),
    "SoftwareId" character varying(100),
    "SoftwareName" character varying(200),
    "SoftwareVersion" character varying(20),
    "PosEnabled" boolean DEFAULT true NOT NULL,
    "RestaurantEnabled" boolean DEFAULT true NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_fiscal_CountryCfg_VerifactuMode" CHECK (((("VerifactuMode")::text = ANY ((ARRAY['auto'::character varying, 'manual'::character varying])::text[])) OR ("VerifactuMode" IS NULL)))
);


CREATE TABLE fiscal."DeclarationTemplate" (
    "TemplateId" integer NOT NULL,
    "CountryCode" character varying(2) NOT NULL,
    "DeclarationType" character varying(30) NOT NULL,
    "TemplateName" character varying(200) NOT NULL,
    "FileFormat" character varying(10) NOT NULL,
    "FormatVersion" character varying(20),
    "AuthorityName" character varying(100),
    "AuthorityUrl" character varying(500),
    "IsActive" boolean DEFAULT true,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE fiscal."ISLRTariff" (
    "TariffId" integer NOT NULL,
    "CountryCode" character varying(2) DEFAULT 'VE'::character varying NOT NULL,
    "TaxYear" integer NOT NULL,
    "BracketFrom" numeric(18,2) NOT NULL,
    "BracketTo" numeric(18,2),
    "Rate" numeric(5,2) NOT NULL,
    "Subtrahend" numeric(18,2) DEFAULT 0,
    "IsActive" boolean DEFAULT true
);


CREATE TABLE fiscal."InvoiceType" (
    "InvoiceTypeId" bigint NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "InvoiceTypeCode" character varying(20) NOT NULL,
    "InvoiceTypeName" character varying(120) NOT NULL,
    "IsRectificative" boolean DEFAULT false NOT NULL,
    "RequiresRecipientId" boolean DEFAULT false NOT NULL,
    "MaxAmount" numeric(18,2),
    "RequiresFiscalPrinter" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE fiscal."Record" (
    "FiscalRecordId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "InvoiceId" integer NOT NULL,
    "InvoiceType" character varying(20) NOT NULL,
    "InvoiceNumber" character varying(50) NOT NULL,
    "InvoiceDate" date NOT NULL,
    "RecipientId" character varying(20),
    "TotalAmount" numeric(18,2) NOT NULL,
    "RecordHash" character varying(64) NOT NULL,
    "PreviousRecordHash" character varying(64),
    "XmlContent" text,
    "DigitalSignature" text,
    "QRCodeData" character varying(800),
    "SentToAuthority" boolean DEFAULT false NOT NULL,
    "SentAt" timestamp without time zone,
    "AuthorityResponse" text,
    "AuthorityStatus" character varying(20),
    "FiscalPrinterSerial" character varying(30),
    "FiscalControlNumber" character varying(30),
    "ZReportNumber" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE fiscal."TaxBookEntry" (
    "EntryId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BookType" character varying(10) NOT NULL,
    "PeriodCode" character varying(7) NOT NULL,
    "EntryDate" date NOT NULL,
    "DocumentNumber" character varying(60) NOT NULL,
    "DocumentType" character varying(30),
    "ControlNumber" character varying(40),
    "ThirdPartyId" character varying(40),
    "ThirdPartyName" character varying(200),
    "TaxableBase" numeric(18,2) DEFAULT 0 NOT NULL,
    "ExemptAmount" numeric(18,2) DEFAULT 0,
    "TaxRate" numeric(5,2) DEFAULT 0 NOT NULL,
    "TaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "WithholdingRate" numeric(5,2) DEFAULT 0,
    "WithholdingAmount" numeric(18,2) DEFAULT 0,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "SourceDocumentId" bigint,
    "SourceModule" character varying(20),
    "CountryCode" character varying(2) NOT NULL,
    "DeclarationId" bigint,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE fiscal."TaxDeclaration" (
    "DeclarationId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer DEFAULT 0 NOT NULL,
    "CountryCode" character varying(2) NOT NULL,
    "DeclarationType" character varying(30) NOT NULL,
    "PeriodCode" character varying(7) NOT NULL,
    "PeriodStart" date NOT NULL,
    "PeriodEnd" date NOT NULL,
    "SalesBase" numeric(18,2) DEFAULT 0,
    "SalesTax" numeric(18,2) DEFAULT 0,
    "PurchasesBase" numeric(18,2) DEFAULT 0,
    "PurchasesTax" numeric(18,2) DEFAULT 0,
    "TaxableBase" numeric(18,2) DEFAULT 0,
    "TaxAmount" numeric(18,2) DEFAULT 0,
    "WithholdingsCredit" numeric(18,2) DEFAULT 0,
    "PreviousBalance" numeric(18,2) DEFAULT 0,
    "NetPayable" numeric(18,2) DEFAULT 0,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying,
    "SubmittedAt" timestamp without time zone,
    "SubmittedFile" character varying(500),
    "AuthorityResponse" text,
    "PaidAt" timestamp without time zone,
    "PaymentReference" character varying(100),
    "JournalEntryId" bigint,
    "Notes" character varying(1000),
    "CreatedBy" character varying(40),
    "UpdatedBy" character varying(40),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "UpdatedAt" timestamp without time zone
);


CREATE TABLE fiscal."TaxRate" (
    "TaxRateId" bigint NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "TaxCode" character varying(30) NOT NULL,
    "TaxName" character varying(120) NOT NULL,
    "Rate" numeric(9,4) NOT NULL,
    "SurchargeRate" numeric(9,4),
    "AppliesToPOS" boolean DEFAULT true NOT NULL,
    "AppliesToRestaurant" boolean DEFAULT true NOT NULL,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_fiscal_TaxRate_Rate" CHECK ((("Rate" >= (0)::numeric) AND ("Rate" <= (1)::numeric))),
    CONSTRAINT "CK_fiscal_TaxRate_Surcharge" CHECK ((("SurchargeRate" IS NULL) OR (("SurchargeRate" >= (0)::numeric) AND ("SurchargeRate" <= (1)::numeric))))
);


CREATE TABLE fiscal."WithholdingConcept" (
    "ConceptId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "Description" character varying(200) NOT NULL,
    "SupplierType" character varying(20) DEFAULT 'AMBOS'::character varying NOT NULL,
    "ActivityCode" character varying(30),
    "RetentionType" character varying(20) DEFAULT 'ISLR'::character varying NOT NULL,
    "Rate" numeric(8,4) NOT NULL,
    "SubtrahendUT" numeric(8,4) DEFAULT 0 NOT NULL,
    "MinBaseUT" numeric(8,4) DEFAULT 0 NOT NULL,
    "SeniatCode" character varying(10),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_fiscal_WHConcept_RetType" CHECK ((("RetentionType")::text = ANY ((ARRAY['ISLR'::character varying, 'IVA'::character varying, 'IRPF'::character varying, 'ISR'::character varying, 'RETEFUENTE'::character varying, 'MUNICIPAL'::character varying])::text[]))),
    CONSTRAINT "CK_fiscal_WHConcept_Type" CHECK ((("SupplierType")::text = ANY ((ARRAY['NATURAL'::character varying, 'JURIDICA'::character varying, 'AMBOS'::character varying])::text[])))
);


CREATE TABLE fiscal."WithholdingVoucher" (
    "VoucherId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "VoucherNumber" character varying(40) NOT NULL,
    "VoucherDate" date NOT NULL,
    "WithholdingType" character varying(20) NOT NULL,
    "ThirdPartyId" character varying(40) NOT NULL,
    "ThirdPartyName" character varying(200),
    "DocumentNumber" character varying(60) NOT NULL,
    "DocumentDate" date,
    "TaxableBase" numeric(18,2) NOT NULL,
    "WithholdingRate" numeric(5,2) NOT NULL,
    "WithholdingAmount" numeric(18,2) NOT NULL,
    "PeriodCode" character varying(7) NOT NULL,
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying,
    "CountryCode" character varying(2) NOT NULL,
    "JournalEntryId" bigint,
    "CreatedBy" character varying(40),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE fleet."FuelLog" (
    "FuelLogId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "VehicleId" bigint NOT NULL,
    "DriverId" bigint,
    "FuelDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "FuelType" character varying(20) NOT NULL,
    "Quantity" numeric(10,3) NOT NULL,
    "UnitPrice" numeric(18,4) NOT NULL,
    "TotalCost" numeric(18,2) NOT NULL,
    "CurrencyCode" character(3) DEFAULT 'USD'::bpchar NOT NULL,
    "OdometerReading" numeric(12,2),
    "IsFullTank" boolean DEFAULT true NOT NULL,
    "StationName" character varying(200),
    "InvoiceNumber" character varying(60),
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE fleet."MaintenanceOrder" (
    "MaintenanceOrderId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "VehicleId" bigint NOT NULL,
    "MaintenanceTypeId" bigint NOT NULL,
    "OrderNumber" character varying(30) NOT NULL,
    "OrderDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "OdometerAtService" numeric(12,2),
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Priority" character varying(10) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "ScheduledDate" timestamp without time zone,
    "StartedAt" timestamp without time zone,
    "CompletedAt" timestamp without time zone,
    "WorkshopName" character varying(200),
    "TechnicianName" character varying(200),
    "TotalLaborCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalPartsCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "CurrencyCode" character(3) DEFAULT 'USD'::bpchar NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_fleet_MaintOrder_Priority" CHECK ((("Priority")::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT "CK_fleet_MaintOrder_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'SCHEDULED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


CREATE TABLE fleet."MaintenanceOrderLine" (
    "MaintenanceOrderLineId" bigint NOT NULL,
    "MaintenanceOrderId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "LineType" character varying(10) DEFAULT 'PART'::character varying NOT NULL,
    "ProductId" bigint,
    "Description" character varying(300) NOT NULL,
    "Quantity" numeric(18,3) DEFAULT 1 NOT NULL,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "TotalCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_fleet_MOLine_Type" CHECK ((("LineType")::text = ANY ((ARRAY['PART'::character varying, 'LABOR'::character varying, 'SERVICE'::character varying, 'OTHER'::character varying])::text[])))
);


CREATE TABLE fleet."MaintenanceType" (
    "MaintenanceTypeId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "TypeCode" character varying(20) NOT NULL,
    "TypeName" character varying(200) NOT NULL,
    "Category" character varying(20) DEFAULT 'PREVENTIVE'::character varying NOT NULL,
    "DefaultIntervalKm" numeric(12,2),
    "DefaultIntervalDays" integer,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_fleet_MaintType_Category" CHECK ((("Category")::text = ANY ((ARRAY['PREVENTIVE'::character varying, 'CORRECTIVE'::character varying, 'PREDICTIVE'::character varying, 'INSPECTION'::character varying])::text[])))
);


CREATE TABLE fleet."Trip" (
    "TripId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "VehicleId" bigint NOT NULL,
    "DriverId" bigint,
    "DeliveryNoteId" bigint,
    "TripNumber" character varying(30) NOT NULL,
    "TripDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "Origin" character varying(300),
    "Destination" character varying(300),
    "DistanceKm" numeric(10,2),
    "OdometerStart" numeric(12,2),
    "OdometerEnd" numeric(12,2),
    "DepartedAt" timestamp without time zone,
    "ArrivedAt" timestamp without time zone,
    "Status" character varying(20) DEFAULT 'PLANNED'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_fleet_Trip_Status" CHECK ((("Status")::text = ANY ((ARRAY['PLANNED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


CREATE TABLE fleet."Vehicle" (
    "VehicleId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "VehicleCode" character varying(20) NOT NULL,
    "LicensePlate" character varying(20) NOT NULL,
    "VehicleType" character varying(30) DEFAULT 'CAR'::character varying NOT NULL,
    "Brand" character varying(60),
    "Model" character varying(60),
    "Year" integer,
    "Color" character varying(30),
    "VinNumber" character varying(30),
    "EngineNumber" character varying(30),
    "FuelType" character varying(20) DEFAULT 'GASOLINE'::character varying NOT NULL,
    "TankCapacity" numeric(10,2),
    "CurrentOdometer" numeric(12,2) DEFAULT 0 NOT NULL,
    "OdometerUnit" character varying(5) DEFAULT 'KM'::character varying NOT NULL,
    "DefaultDriverId" bigint,
    "WarehouseId" bigint,
    "PurchaseDate" date,
    "PurchaseCost" numeric(18,2),
    "InsurancePolicy" character varying(60),
    "InsuranceExpiry" date,
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "Notes" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_fleet_Vehicle_Fuel" CHECK ((("FuelType")::text = ANY ((ARRAY['GASOLINE'::character varying, 'DIESEL'::character varying, 'GAS'::character varying, 'ELECTRIC'::character varying, 'HYBRID'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT "CK_fleet_Vehicle_OdoUnit" CHECK ((("OdometerUnit")::text = ANY ((ARRAY['KM'::character varying, 'MI'::character varying])::text[]))),
    CONSTRAINT "CK_fleet_Vehicle_Status" CHECK ((("Status")::text = ANY ((ARRAY['ACTIVE'::character varying, 'IN_MAINTENANCE'::character varying, 'OUT_OF_SERVICE'::character varying, 'SOLD'::character varying, 'SCRAPPED'::character varying])::text[]))),
    CONSTRAINT "CK_fleet_Vehicle_Type" CHECK ((("VehicleType")::text = ANY ((ARRAY['CAR'::character varying, 'TRUCK'::character varying, 'VAN'::character varying, 'MOTORCYCLE'::character varying, 'BUS'::character varying, 'TRAILER'::character varying, 'FORKLIFT'::character varying, 'OTHER'::character varying])::text[])))
);


CREATE TABLE fleet."VehicleDocument" (
    "VehicleDocumentId" bigint NOT NULL,
    "VehicleId" bigint NOT NULL,
    "DocumentType" character varying(30) NOT NULL,
    "DocumentNumber" character varying(60),
    "Description" character varying(300),
    "IssuedAt" date,
    "ExpiresAt" date,
    "FileUrl" character varying(500),
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_fleet_VehicleDoc_Type" CHECK ((("DocumentType")::text = ANY ((ARRAY['REGISTRATION'::character varying, 'INSURANCE'::character varying, 'INSPECTION'::character varying, 'PERMIT'::character varying, 'WARRANTY'::character varying, 'TITLE'::character varying, 'OTHER'::character varying])::text[])))
);


CREATE TABLE hr."DocumentTemplate" (
    "TemplateId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "TemplateCode" character varying(50) NOT NULL,
    "TemplateName" character varying(200) NOT NULL,
    "TemplateType" character varying(30) DEFAULT 'PAYROLL'::character varying NOT NULL,
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL,
    "PayrollCode" character varying(20),
    "ContentMD" text DEFAULT ''::text NOT NULL,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "IsSystem" boolean DEFAULT false NOT NULL
);


CREATE TABLE hr."EmployeeObligation" (
    "EmployeeObligationId" integer NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "LegalObligationId" integer NOT NULL,
    "AffiliationNumber" character varying(50),
    "InstitutionCode" character varying(50),
    "RiskLevelId" integer,
    "EnrollmentDate" date NOT NULL,
    "DisenrollmentDate" date,
    "Status" character varying(15) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "CustomRate" numeric(8,5),
    "CreatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."EmployeeTaxProfile" (
    "ProfileId" integer NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "TaxYear" integer NOT NULL,
    "EstimatedAnnualIncome" numeric(18,2) DEFAULT 0 NOT NULL,
    "DeductionType" character varying(20) DEFAULT 'UNICO'::character varying NOT NULL,
    "UniqueDeductionUT" numeric(8,2) DEFAULT 774 NOT NULL,
    "DetailedDeductions" numeric(18,2) DEFAULT 0 NOT NULL,
    "DependentCount" integer DEFAULT 0 NOT NULL,
    "PersonalRebateUT" numeric(8,2) DEFAULT 10 NOT NULL,
    "DependentRebateUT" numeric(8,2) DEFAULT 10 NOT NULL,
    "MonthsRemaining" integer DEFAULT 12 NOT NULL,
    "CalculatedAnnualISLR" numeric(18,2) DEFAULT 0 NOT NULL,
    "MonthlyWithholding" numeric(18,2) DEFAULT 0 NOT NULL,
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL,
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_hr_EmpTaxProfile_Ded" CHECK ((("DeductionType")::text = ANY ((ARRAY['UNICO'::character varying, 'DETALLADO'::character varying])::text[]))),
    CONSTRAINT "CK_hr_EmpTaxProfile_Status" CHECK ((("Status")::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


CREATE TABLE hr."LegalObligation" (
    "LegalObligationId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "Code" character varying(30) NOT NULL,
    "Name" character varying(200) NOT NULL,
    "InstitutionName" character varying(200),
    "ObligationType" character varying(20) NOT NULL,
    "CalculationBasis" character varying(30) NOT NULL,
    "SalaryCap" numeric(18,2),
    "SalaryCapUnit" character varying(20),
    "EmployerRate" numeric(8,5) DEFAULT 0 NOT NULL,
    "EmployeeRate" numeric(8,5) DEFAULT 0 NOT NULL,
    "RateVariableByRisk" boolean DEFAULT false NOT NULL,
    "FilingFrequency" character varying(15) NOT NULL,
    "FilingDeadlineRule" character varying(200),
    "EffectiveFrom" date NOT NULL,
    "EffectiveTo" date,
    "IsActive" boolean DEFAULT true NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."MedicalExam" (
    "MedicalExamId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "ExamType" character varying(20) NOT NULL,
    "ExamDate" date NOT NULL,
    "NextDueDate" date,
    "Result" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "Restrictions" character varying(500),
    "PhysicianName" character varying(200),
    "ClinicName" character varying(200),
    "DocumentUrl" character varying(500),
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."MedicalOrder" (
    "MedicalOrderId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "OrderType" character varying(20) NOT NULL,
    "OrderDate" date NOT NULL,
    "Diagnosis" character varying(500),
    "PhysicianName" character varying(200),
    "Prescriptions" text,
    "EstimatedCost" numeric(18,2),
    "ApprovedAmount" numeric(18,2),
    "Status" character varying(15) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "ApprovedBy" integer,
    "ApprovedAt" timestamp without time zone,
    "DocumentUrl" character varying(500),
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."ObligationFiling" (
    "ObligationFilingId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "LegalObligationId" integer NOT NULL,
    "FilingPeriodStart" date NOT NULL,
    "FilingPeriodEnd" date NOT NULL,
    "DueDate" date NOT NULL,
    "FiledDate" date,
    "ConfirmationNumber" character varying(100),
    "TotalEmployerAmount" numeric(18,2),
    "TotalEmployeeAmount" numeric(18,2),
    "TotalAmount" numeric(18,2),
    "EmployeeCount" integer,
    "Status" character varying(15) DEFAULT 'PENDING'::character varying NOT NULL,
    "FiledByUserId" integer,
    "DocumentUrl" character varying(500),
    "Notes" character varying(500),
    "CreatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp(0) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."ObligationFilingDetail" (
    "DetailId" integer NOT NULL,
    "ObligationFilingId" integer NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "BaseSalary" numeric(18,2) DEFAULT 0 NOT NULL,
    "EmployerAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "EmployeeAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "DaysWorked" integer DEFAULT 30 NOT NULL,
    "NoveltyType" character varying(20) DEFAULT 'NONE'::character varying NOT NULL
);


CREATE TABLE hr."ObligationRiskLevel" (
    "ObligationRiskLevelId" integer NOT NULL,
    "LegalObligationId" integer NOT NULL,
    "RiskLevel" smallint NOT NULL,
    "RiskDescription" character varying(100),
    "EmployerRate" numeric(8,5) DEFAULT 0 NOT NULL,
    "EmployeeRate" numeric(8,5) DEFAULT 0 NOT NULL
);


CREATE TABLE hr."OccupationalHealth" (
    "OccupationalHealthId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "RecordType" character varying(25) NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24),
    "EmployeeName" character varying(200),
    "OccurrenceDate" timestamp without time zone NOT NULL,
    "ReportDeadline" timestamp without time zone,
    "ReportedDate" timestamp without time zone,
    "Severity" character varying(15),
    "BodyPartAffected" character varying(100),
    "DaysLost" integer,
    "Location" character varying(200),
    "Description" text,
    "RootCause" character varying(500),
    "CorrectiveAction" character varying(500),
    "InvestigationDueDate" date,
    "InvestigationCompletedDate" date,
    "InstitutionReference" character varying(100),
    "Status" character varying(15) DEFAULT 'OPEN'::character varying NOT NULL,
    "DocumentUrl" character varying(500),
    "Notes" character varying(500),
    "CreatedBy" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."PayrollBatch" (
    "BatchId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "PayrollCode" character varying(20) NOT NULL,
    "FromDate" date NOT NULL,
    "ToDate" date NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "TotalEmployees" integer DEFAULT 0 NOT NULL,
    "TotalGross" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalDeductions" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalNet" numeric(18,2) DEFAULT 0 NOT NULL,
    "CreatedBy" integer,
    "ApprovedBy" integer,
    "ApprovedAt" timestamp without time zone
);


CREATE TABLE hr."PayrollBatchLine" (
    "LineId" bigint NOT NULL,
    "BatchId" bigint NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "ConceptName" character varying(100) NOT NULL,
    "ConceptType" character varying(20) NOT NULL,
    "Quantity" numeric(18,4) DEFAULT 1 NOT NULL,
    "Amount" numeric(18,2) DEFAULT 0 NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "IsModified" boolean DEFAULT false NOT NULL,
    "Notes" character varying(500),
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."PayrollCalcVariable" (
    "SessionID" character varying(80) NOT NULL,
    "Variable" character varying(120) NOT NULL,
    "Valor" numeric(18,6) DEFAULT 0 NOT NULL,
    "Descripcion" character varying(255),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."PayrollConcept" (
    "PayrollConceptId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "PayrollCode" character varying(15) NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "ConceptName" character varying(120) NOT NULL,
    "Formula" character varying(500),
    "BaseExpression" character varying(255),
    "ConceptClass" character varying(20),
    "ConceptType" character varying(15) DEFAULT 'ASIGNACION'::character varying NOT NULL,
    "UsageType" character varying(20),
    "IsBonifiable" boolean DEFAULT false NOT NULL,
    "IsSeniority" boolean DEFAULT false NOT NULL,
    "AccountingAccountCode" character varying(50),
    "AppliesFlag" boolean DEFAULT true NOT NULL,
    "DefaultValue" numeric(18,4) DEFAULT 0 NOT NULL,
    "ConventionCode" character varying(50),
    "CalculationType" character varying(50),
    "LotttArticle" character varying(50),
    "CcpClause" character varying(50),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_hr_PayrollConcept_Type" CHECK ((("ConceptType")::text = ANY ((ARRAY['ASIGNACION'::character varying, 'DEDUCCION'::character varying, 'BONO'::character varying])::text[])))
);


CREATE TABLE hr."PayrollConstant" (
    "PayrollConstantId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ConstantCode" character varying(50) NOT NULL,
    "ConstantName" character varying(120) NOT NULL,
    "ConstantValue" numeric(18,4) NOT NULL,
    "SourceName" character varying(60),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE hr."PayrollRun" (
    "PayrollRunId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "PayrollCode" character varying(15) NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "PositionName" character varying(120),
    "ProcessDate" date NOT NULL,
    "DateFrom" date NOT NULL,
    "DateTo" date NOT NULL,
    "TotalAssignments" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalDeductions" numeric(18,2) DEFAULT 0 NOT NULL,
    "NetTotal" numeric(18,2) DEFAULT 0 NOT NULL,
    "IsClosed" boolean DEFAULT false NOT NULL,
    "PayrollTypeName" character varying(50),
    "RunSource" character varying(20) DEFAULT 'MANUAL'::character varying NOT NULL,
    "ClosedAt" timestamp without time zone,
    "ClosedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE hr."PayrollRunLine" (
    "PayrollRunLineId" bigint NOT NULL,
    "PayrollRunId" bigint NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "ConceptName" character varying(120) NOT NULL,
    "ConceptType" character varying(15) NOT NULL,
    "Quantity" numeric(18,4) DEFAULT 1 NOT NULL,
    "Amount" numeric(18,4) DEFAULT 0 NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "DescriptionText" character varying(255),
    "AccountingAccountCode" character varying(50),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."PayrollType" (
    "PayrollTypeId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "PayrollCode" character varying(15) NOT NULL,
    "PayrollName" character varying(120) NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE hr."ProfitSharing" (
    "ProfitSharingId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "FiscalYear" integer NOT NULL,
    "DaysGranted" integer NOT NULL,
    "TotalCompanyProfits" numeric(18,2),
    "Status" character varying(20) DEFAULT 'BORRADOR'::character varying NOT NULL,
    "CreatedBy" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ApprovedBy" integer,
    "ApprovedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_ProfitSharing_Days" CHECK ((("DaysGranted" >= 30) AND ("DaysGranted" <= 120))),
    CONSTRAINT "CK_ProfitSharing_Status" CHECK ((("Status")::text = ANY ((ARRAY['CERRADA'::character varying, 'PROCESADA'::character varying, 'CALCULADA'::character varying, 'BORRADOR'::character varying])::text[])))
);


CREATE TABLE hr."ProfitSharingLine" (
    "LineId" integer NOT NULL,
    "ProfitSharingId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "MonthlySalary" numeric(18,2) NOT NULL,
    "DailySalary" numeric(18,2) NOT NULL,
    "DaysWorked" integer NOT NULL,
    "DaysEntitled" integer NOT NULL,
    "GrossAmount" numeric(18,2) NOT NULL,
    "InceDeduction" numeric(18,2) DEFAULT 0 NOT NULL,
    "NetAmount" numeric(18,2) NOT NULL,
    "IsPaid" boolean DEFAULT false NOT NULL,
    "PaidAt" timestamp without time zone
);


CREATE TABLE hr."SafetyCommittee" (
    "SafetyCommitteeId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "CommitteeName" character varying(200) NOT NULL,
    "FormationDate" date NOT NULL,
    "MeetingFrequency" character varying(15) DEFAULT 'MONTHLY'::character varying NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."SafetyCommitteeMeeting" (
    "MeetingId" integer NOT NULL,
    "SafetyCommitteeId" integer NOT NULL,
    "MeetingDate" timestamp without time zone NOT NULL,
    "MinutesUrl" character varying(500),
    "TopicsSummary" text,
    "ActionItems" text,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."SafetyCommitteeMember" (
    "MemberId" integer NOT NULL,
    "SafetyCommitteeId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "Role" character varying(25) NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date
);


CREATE TABLE hr."SavingsFund" (
    "SavingsFundId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "EmployeeContribution" numeric(8,4) NOT NULL,
    "EmployerMatch" numeric(8,4) NOT NULL,
    "EnrollmentDate" date NOT NULL,
    "Status" character varying(15) DEFAULT 'ACTIVO'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_SavingsFund_Status" CHECK ((("Status")::text = ANY ((ARRAY['ACTIVO'::character varying, 'SUSPENDIDO'::character varying, 'RETIRADO'::character varying])::text[])))
);


CREATE TABLE hr."SavingsFundTransaction" (
    "TransactionId" integer NOT NULL,
    "SavingsFundId" integer NOT NULL,
    "TransactionDate" date NOT NULL,
    "TransactionType" character varying(20) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "Balance" numeric(18,2) NOT NULL,
    "Reference" character varying(100),
    "PayrollBatchId" integer,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_SavingsTx_Type" CHECK ((("TransactionType")::text = ANY ((ARRAY['APORTE_EMPLEADO'::character varying, 'APORTE_PATRONAL'::character varying, 'RETIRO'::character varying, 'PRESTAMO'::character varying, 'PAGO_PRESTAMO'::character varying, 'INTERES'::character varying])::text[])))
);


CREATE TABLE hr."SavingsLoan" (
    "LoanId" integer NOT NULL,
    "SavingsFundId" integer NOT NULL,
    "EmployeeCode" character varying(24) NOT NULL,
    "RequestDate" date NOT NULL,
    "ApprovedDate" date,
    "LoanAmount" numeric(18,2) NOT NULL,
    "InterestRate" numeric(8,5) DEFAULT 0 NOT NULL,
    "TotalPayable" numeric(18,2) NOT NULL,
    "MonthlyPayment" numeric(18,2) NOT NULL,
    "InstallmentsTotal" integer NOT NULL,
    "InstallmentsPaid" integer DEFAULT 0 NOT NULL,
    "OutstandingBalance" numeric(18,2) NOT NULL,
    "Status" character varying(15) DEFAULT 'SOLICITADO'::character varying NOT NULL,
    "ApprovedBy" integer,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_SavingsLoan_Status" CHECK ((("Status")::text = ANY ((ARRAY['SOLICITADO'::character varying, 'APROBADO'::character varying, 'ACTIVO'::character varying, 'PAGADO'::character varying, 'RECHAZADO'::character varying])::text[])))
);


CREATE TABLE hr."SettlementProcess" (
    "SettlementProcessId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "SettlementCode" character varying(50) NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "RetirementDate" date NOT NULL,
    "RetirementCause" character varying(40),
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE hr."SettlementProcessLine" (
    "SettlementProcessLineId" bigint NOT NULL,
    "SettlementProcessId" bigint NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "ConceptName" character varying(120) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."SocialBenefitsTrust" (
    "TrustId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "FiscalYear" integer NOT NULL,
    "Quarter" smallint NOT NULL,
    "DailySalary" numeric(18,2) NOT NULL,
    "DaysDeposited" integer DEFAULT 15 NOT NULL,
    "BonusDays" integer DEFAULT 0 NOT NULL,
    "DepositAmount" numeric(18,2) NOT NULL,
    "InterestRate" numeric(8,5) DEFAULT 0 NOT NULL,
    "InterestAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "AccumulatedBalance" numeric(18,2) NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_Trust_Quarter" CHECK ((("Quarter" >= 1) AND ("Quarter" <= 4))),
    CONSTRAINT "CK_Trust_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDIENTE'::character varying, 'DEPOSITADO'::character varying, 'PAGADO'::character varying])::text[])))
);


CREATE TABLE hr."TrainingRecord" (
    "TrainingRecordId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "TrainingType" character varying(25) NOT NULL,
    "Title" character varying(200) NOT NULL,
    "Provider" character varying(200),
    "StartDate" date NOT NULL,
    "EndDate" date,
    "DurationHours" numeric(6,2) NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "CertificateNumber" character varying(100),
    "CertificateUrl" character varying(500),
    "Result" character varying(15),
    "IsRegulatory" boolean DEFAULT false NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."VacationProcess" (
    "VacationProcessId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "VacationCode" character varying(50) NOT NULL,
    "EmployeeId" bigint,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date NOT NULL,
    "ReintegrationDate" date,
    "ProcessDate" date NOT NULL,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "CalculatedAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE hr."VacationProcessLine" (
    "VacationProcessLineId" bigint NOT NULL,
    "VacationProcessId" bigint NOT NULL,
    "ConceptCode" character varying(20) NOT NULL,
    "ConceptName" character varying(120) NOT NULL,
    "Amount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE hr."VacationRequest" (
    "RequestId" bigint NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer DEFAULT 1 NOT NULL,
    "EmployeeCode" character varying(60) NOT NULL,
    "RequestDate" date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date NOT NULL,
    "TotalDays" integer NOT NULL,
    "IsPartial" boolean DEFAULT false NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "Notes" character varying(500),
    "ApprovedBy" character varying(60),
    "ApprovalDate" timestamp without time zone,
    "RejectionReason" character varying(500),
    "VacationId" bigint,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_VacationRequest_Dates" CHECK (("EndDate" >= "StartDate")),
    CONSTRAINT "CK_VacationRequest_Days" CHECK (("TotalDays" > 0)),
    CONSTRAINT "CK_VacationRequest_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADA'::character varying, 'RECHAZADA'::character varying, 'CANCELADA'::character varying, 'PROCESADA'::character varying])::text[])))
);


CREATE TABLE hr."VacationRequestDay" (
    "DayId" bigint NOT NULL,
    "RequestId" bigint NOT NULL,
    "SelectedDate" date NOT NULL,
    "DayType" character varying(20) DEFAULT 'COMPLETO'::character varying NOT NULL,
    CONSTRAINT "CK_VacationRequestDay_Type" CHECK ((("DayType")::text = ANY ((ARRAY['COMPLETO'::character varying, 'MEDIO_DIA'::character varying])::text[])))
);


CREATE TABLE inv."InventoryValuationLayer" (
    "LayerId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "LotId" bigint,
    "LayerDate" date NOT NULL,
    "RemainingQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "SourceDocumentType" character varying(30),
    "SourceDocumentNumber" character varying(60),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE inv."InventoryValuationMethod" (
    "ValuationMethodId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "Method" character varying(20) DEFAULT 'WEIGHTED_AVG'::character varying NOT NULL,
    "StandardCost" numeric(18,4),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_inv_ValMethod_Method" CHECK ((("Method")::text = ANY ((ARRAY['FIFO'::character varying, 'LIFO'::character varying, 'WEIGHTED_AVG'::character varying, 'LAST_COST'::character varying, 'STANDARD'::character varying])::text[])))
);


CREATE TABLE inv."ProductBinStock" (
    "ProductBinStockId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "WarehouseId" bigint NOT NULL,
    "BinId" bigint,
    "LotId" bigint,
    "QuantityOnHand" numeric(18,4) DEFAULT 0 NOT NULL,
    "QuantityReserved" numeric(18,4) DEFAULT 0 NOT NULL,
    "QuantityAvailable" numeric(18,4) DEFAULT 0 NOT NULL,
    "LastCountDate" date,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE inv."ProductLot" (
    "LotId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "LotNumber" character varying(60) NOT NULL,
    "ManufactureDate" date,
    "ExpiryDate" date,
    "SupplierCode" character varying(24),
    "PurchaseDocumentNumber" character varying(60),
    "InitialQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "CurrentQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_inv_ProductLot_Status" CHECK ((("Status")::text = ANY ((ARRAY['ACTIVE'::character varying, 'DEPLETED'::character varying, 'EXPIRED'::character varying, 'QUARANTINE'::character varying, 'BLOCKED'::character varying])::text[])))
);


CREATE TABLE inv."ProductSerial" (
    "SerialId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "LotId" bigint,
    "SerialNumber" character varying(100) NOT NULL,
    "WarehouseId" bigint,
    "BinId" bigint,
    "Status" character varying(20) DEFAULT 'AVAILABLE'::character varying NOT NULL,
    "PurchaseDocumentNumber" character varying(60),
    "SalesDocumentNumber" character varying(60),
    "CustomerId" bigint,
    "SoldAt" timestamp without time zone,
    "WarrantyExpiry" date,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_inv_ProductSerial_Status" CHECK ((("Status")::text = ANY ((ARRAY['AVAILABLE'::character varying, 'RESERVED'::character varying, 'SOLD'::character varying, 'RETURNED'::character varying, 'DEFECTIVE'::character varying, 'SCRAPPED'::character varying])::text[])))
);


CREATE TABLE inv."StockMovement" (
    "MovementId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "LotId" bigint,
    "SerialId" bigint,
    "FromWarehouseId" bigint,
    "ToWarehouseId" bigint,
    "FromBinId" bigint,
    "ToBinId" bigint,
    "MovementType" character varying(20) NOT NULL,
    "Quantity" numeric(18,4) NOT NULL,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "TotalCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "SourceDocumentType" character varying(30),
    "SourceDocumentNumber" character varying(60),
    "Notes" character varying(500),
    "MovementDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_inv_StockMovement_Type" CHECK ((("MovementType")::text = ANY ((ARRAY['PURCHASE_IN'::character varying, 'SALE_OUT'::character varying, 'TRANSFER'::character varying, 'ADJUSTMENT'::character varying, 'RETURN_IN'::character varying, 'RETURN_OUT'::character varying, 'PRODUCTION_IN'::character varying, 'PRODUCTION_OUT'::character varying, 'SCRAP'::character varying])::text[])))
);


CREATE TABLE inv."Warehouse" (
    "WarehouseId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "WarehouseCode" character varying(30) NOT NULL,
    "WarehouseName" character varying(150) NOT NULL,
    "AddressLine" character varying(250),
    "ContactName" character varying(120),
    "Phone" character varying(40),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE inv."WarehouseBin" (
    "BinId" bigint NOT NULL,
    "ZoneId" bigint NOT NULL,
    "BinCode" character varying(30) NOT NULL,
    "BinName" character varying(100),
    "MaxWeight" numeric(18,2),
    "MaxVolume" numeric(18,4),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE inv."WarehouseZone" (
    "ZoneId" bigint NOT NULL,
    "WarehouseId" bigint NOT NULL,
    "ZoneCode" character varying(30) NOT NULL,
    "ZoneName" character varying(150) NOT NULL,
    "ZoneType" character varying(20) DEFAULT 'STORAGE'::character varying NOT NULL,
    "Temperature" character varying(20) DEFAULT 'AMBIENT'::character varying NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_inv_WarehouseZone_Temp" CHECK ((("Temperature")::text = ANY ((ARRAY['AMBIENT'::character varying, 'COLD'::character varying, 'FROZEN'::character varying])::text[]))),
    CONSTRAINT "CK_inv_WarehouseZone_Type" CHECK ((("ZoneType")::text = ANY ((ARRAY['RECEIVING'::character varying, 'STORAGE'::character varying, 'PICKING'::character varying, 'SHIPPING'::character varying, 'QUARANTINE'::character varying])::text[])))
);


CREATE TABLE logistics."Carrier" (
    "CarrierId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "CarrierCode" character varying(30) NOT NULL,
    "CarrierName" character varying(150) NOT NULL,
    "FiscalId" character varying(30),
    "ContactName" character varying(120),
    "Phone" character varying(40),
    "Email" character varying(150),
    "AddressLine" character varying(250),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE logistics."DeliveryNote" (
    "DeliveryNoteId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "DeliveryNumber" character varying(40) NOT NULL,
    "SalesDocumentNumber" character varying(60),
    "CustomerId" bigint NOT NULL,
    "WarehouseId" bigint NOT NULL,
    "DeliveryDate" date NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "CarrierId" bigint,
    "DriverId" bigint,
    "VehiclePlate" character varying(20),
    "ShipToAddress" character varying(500),
    "ShipToContact" character varying(150),
    "EstimatedDelivery" date,
    "ActualDelivery" date,
    "DeliveredToName" character varying(150),
    "DeliverySignature" character varying(500),
    "Notes" character varying(500),
    "DispatchedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "DeliveryNote_Status_check" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'PICKING'::character varying, 'PACKED'::character varying, 'DISPATCHED'::character varying, 'IN_TRANSIT'::character varying, 'DELIVERED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE logistics."DeliveryNoteLine" (
    "DeliveryNoteLineId" bigint NOT NULL,
    "DeliveryNoteId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "ProductCode" character varying(40) NOT NULL,
    "Description" character varying(250),
    "Quantity" numeric(18,4) NOT NULL,
    "LotNumber" character varying(60),
    "WarehouseId" bigint,
    "BinId" bigint,
    "PickedQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "PackedQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE logistics."DeliveryNoteSerial" (
    "DeliveryNoteSerialId" bigint NOT NULL,
    "DeliveryNoteLineId" bigint NOT NULL,
    "SerialId" bigint,
    "SerialNumber" character varying(100) NOT NULL,
    "Status" character varying(20) DEFAULT 'DISPATCHED'::character varying NOT NULL,
    CONSTRAINT "DeliveryNoteSerial_Status_check" CHECK ((("Status")::text = ANY ((ARRAY['DISPATCHED'::character varying, 'DELIVERED'::character varying, 'RETURNED'::character varying])::text[])))
);


CREATE TABLE logistics."Driver" (
    "DriverId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "CarrierId" bigint,
    "DriverCode" character varying(30) NOT NULL,
    "DriverName" character varying(150) NOT NULL,
    "FiscalId" character varying(30),
    "LicenseNumber" character varying(40),
    "LicenseExpiry" date,
    "Phone" character varying(40),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE logistics."GoodsReceipt" (
    "GoodsReceiptId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "ReceiptNumber" character varying(40) NOT NULL,
    "PurchaseDocumentNumber" character varying(60),
    "SupplierId" bigint NOT NULL,
    "WarehouseId" bigint NOT NULL,
    "ReceiptDate" date NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" character varying(500),
    "CarrierId" bigint,
    "DriverName" character varying(150),
    "VehiclePlate" character varying(20),
    "ReceivedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "GoodsReceipt_Status_check" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'PARTIAL'::character varying, 'COMPLETE'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE logistics."GoodsReceiptLine" (
    "GoodsReceiptLineId" bigint NOT NULL,
    "GoodsReceiptId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "ProductCode" character varying(40) NOT NULL,
    "Description" character varying(250),
    "OrderedQuantity" numeric(18,4) NOT NULL,
    "ReceivedQuantity" numeric(18,4) NOT NULL,
    "RejectedQuantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "UnitCost" numeric(18,4) NOT NULL,
    "TotalCost" numeric(18,2) NOT NULL,
    "LotNumber" character varying(60),
    "ExpiryDate" date,
    "WarehouseId" bigint,
    "BinId" bigint,
    "InspectionStatus" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "GoodsReceiptLine_InspectionStatus_check" CHECK ((("InspectionStatus")::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying])::text[])))
);


CREATE TABLE logistics."GoodsReceiptSerial" (
    "GoodsReceiptSerialId" bigint NOT NULL,
    "GoodsReceiptLineId" bigint NOT NULL,
    "SerialNumber" character varying(100) NOT NULL,
    "Status" character varying(20) DEFAULT 'RECEIVED'::character varying NOT NULL,
    "Notes" character varying(250),
    CONSTRAINT "GoodsReceiptSerial_Status_check" CHECK ((("Status")::text = ANY ((ARRAY['RECEIVED'::character varying, 'REJECTED'::character varying])::text[])))
);


CREATE TABLE logistics."GoodsReturn" (
    "GoodsReturnId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "ReturnNumber" character varying(40) NOT NULL,
    "GoodsReceiptId" bigint,
    "SupplierId" bigint NOT NULL,
    "WarehouseId" bigint NOT NULL,
    "ReturnDate" date NOT NULL,
    "Reason" character varying(500),
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "GoodsReturn_Status_check" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'APPROVED'::character varying, 'SHIPPED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE logistics."GoodsReturnLine" (
    "GoodsReturnLineId" bigint NOT NULL,
    "GoodsReturnId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "ProductCode" character varying(40) NOT NULL,
    "Quantity" numeric(18,4) NOT NULL,
    "UnitCost" numeric(18,4) NOT NULL,
    "LotNumber" character varying(60),
    "SerialNumber" character varying(100),
    "Reason" character varying(250),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE logistics."CarrierConfig" (
    "CarrierConfigId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "CarrierCode" character varying(50) NOT NULL,
    "CarrierName" character varying(200) NOT NULL,
    "CarrierType" character varying(50),
    "SupportedCountries" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE master."AlternateStock" (
    "AlternateStockId" integer NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "StockQty" numeric(18,4) DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL
);


CREATE TABLE master."Brand" (
    "BrandId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BrandCode" character varying(20),
    "BrandName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "UserCode" character varying(20),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."Category" (
    "CategoryId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CategoryCode" character varying(20),
    "CategoryName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "UserCode" character varying(20),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."CostCenter" (
    "CostCenterId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CostCenterCode" character varying(20) NOT NULL,
    "CostCenterName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."Customer" (
    "CustomerId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "CustomerCode" character varying(24) NOT NULL,
    "CustomerName" character varying(200) NOT NULL,
    "FiscalId" character varying(30),
    "Email" character varying(150),
    "Phone" character varying(40),
    "AddressLine" character varying(250),
    "CreditLimit" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalBalance" numeric(18,2) DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE master."CustomerAddress" (
    "AddressId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CustomerCode" character varying(24) NOT NULL,
    "Label" character varying(50) NOT NULL,
    "RecipientName" character varying(200) NOT NULL,
    "Phone" character varying(40),
    "AddressLine" character varying(300) NOT NULL,
    "City" character varying(100),
    "State" character varying(100),
    "ZipCode" character varying(20),
    "Country" character varying(50) DEFAULT 'Venezuela'::character varying NOT NULL,
    "Instructions" character varying(300),
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE master."CustomerPaymentMethod" (
    "PaymentMethodId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "CustomerCode" character varying(24) NOT NULL,
    "MethodType" character varying(30) NOT NULL,
    "Label" character varying(50) NOT NULL,
    "BankName" character varying(100),
    "AccountPhone" character varying(40),
    "AccountNumber" character varying(40),
    "AccountEmail" character varying(150),
    "HolderName" character varying(200),
    "HolderFiscalId" character varying(30),
    "CardType" character varying(20),
    "CardLast4" character varying(4),
    "CardExpiry" character varying(7),
    "IsDefault" boolean DEFAULT false NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE master."Employee" (
    "EmployeeId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "EmployeeCode" character varying(24) NOT NULL,
    "EmployeeName" character varying(200) NOT NULL,
    "FiscalId" character varying(30),
    "HireDate" date,
    "TerminationDate" date,
    "PositionName" character varying(150),
    "DepartmentName" character varying(150),
    "Salary" numeric(18,2),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE master."InventoryMovement" (
    "MovementId" bigint NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer,
    "ProductCode" character varying(80) NOT NULL,
    "ProductName" character varying(250),
    "DocumentRef" character varying(60),
    "MovementType" character varying(20) DEFAULT 'ENTRADA'::character varying NOT NULL,
    "MovementDate" date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date NOT NULL,
    "Quantity" numeric(18,4) DEFAULT 0 NOT NULL,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "TotalCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "Notes" character varying(300),
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."InventoryPeriodSummary" (
    "SummaryId" bigint NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "Period" character(6) NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "OpeningQty" numeric(18,4) DEFAULT 0 NOT NULL,
    "InboundQty" numeric(18,4) DEFAULT 0 NOT NULL,
    "OutboundQty" numeric(18,4) DEFAULT 0 NOT NULL,
    "ClosingQty" numeric(18,4) DEFAULT 0 NOT NULL,
    "SummaryDate" date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date NOT NULL,
    "IsClosed" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE master."Product" (
    "ProductId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "ProductName" character varying(250) NOT NULL,
    "CategoryCode" character varying(50),
    "UnitCode" character varying(20),
    "SalesPrice" numeric(18,2) DEFAULT 0 NOT NULL,
    "CostPrice" numeric(18,2) DEFAULT 0 NOT NULL,
    "DefaultTaxCode" character varying(30),
    "DefaultTaxRate" numeric(9,4) DEFAULT 0 NOT NULL,
    "StockQty" numeric(18,3) DEFAULT 0 NOT NULL,
    "IsService" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "ShortDescription" character varying(500),
    "LongDescription" text,
    "CompareAtPrice" numeric(18,4),
    "BrandCode" character varying(20),
    "BarCode" character varying(50),
    "Slug" character varying(200),
    "WeightKg" numeric(10,3),
    "WidthCm" numeric(10,2),
    "HeightCm" numeric(10,2),
    "DepthCm" numeric(10,2),
    "WarrantyMonths" integer,
    "IsVariantParent" boolean DEFAULT false NOT NULL,
    "ParentProductCode" character varying(80),
    "IndustryTemplateCode" character varying(30),
    "SearchVector" tsvector
);


CREATE TABLE master."ProductClass" (
    "ClassId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ClassCode" character varying(20) NOT NULL,
    "ClassName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."ProductGroup" (
    "GroupId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "GroupCode" character varying(20) NOT NULL,
    "GroupName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."ProductLine" (
    "LineId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "LineCode" character varying(20) NOT NULL,
    "LineName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."ProductType" (
    "TypeId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "TypeCode" character varying(20) NOT NULL,
    "TypeName" character varying(100) NOT NULL,
    "CategoryCode" character varying(50),
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."Seller" (
    "SellerId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "SellerCode" character varying(10) NOT NULL,
    "SellerName" character varying(120) NOT NULL,
    "Commission" numeric(5,2) DEFAULT 0 NOT NULL,
    "Address" character varying(250),
    "Phone" character varying(60),
    "Email" character varying(150),
    "SellerType" character varying(20) DEFAULT 'INTERNO'::character varying NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."Supplier" (
    "SupplierId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "SupplierCode" character varying(24) NOT NULL,
    "SupplierName" character varying(200) NOT NULL,
    "FiscalId" character varying(30),
    "Email" character varying(150),
    "Phone" character varying(40),
    "AddressLine" character varying(250),
    "CreditLimit" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalBalance" numeric(18,2) DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "SupplierType" character varying(20) DEFAULT 'JURIDICA'::character varying NOT NULL,
    "BusinessActivity" character varying(30),
    "DefaultRetentionCode" character varying(20),
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL
);


CREATE TABLE master."SupplierLine" (
    "SupplierLineId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "LineCode" character varying(20) NOT NULL,
    "LineName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE master."TaxRetention" (
    "RetentionId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "RetentionCode" character varying(20) NOT NULL,
    "Description" character varying(200) NOT NULL,
    "RetentionType" character varying(20) DEFAULT 'ISLR'::character varying NOT NULL,
    "RetentionRate" numeric(8,4) DEFAULT 0 NOT NULL,
    "CountryCode" character(2) DEFAULT 'VE'::bpchar NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."UnitOfMeasure" (
    "UnitId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "UnitCode" character varying(20) NOT NULL,
    "Description" character varying(100) NOT NULL,
    "Symbol" character varying(10),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE master."Warehouse" (
    "WarehouseId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "BranchId" integer,
    "WarehouseCode" character varying(20) NOT NULL,
    "Description" character varying(200) NOT NULL,
    "WarehouseType" character varying(20) DEFAULT 'PRINCIPAL'::character varying NOT NULL,
    "AddressLine" character varying(250),
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE mfg."BOMLine" (
    "BOMLineId" bigint NOT NULL,
    "BOMId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "ComponentProductId" bigint NOT NULL,
    "Quantity" numeric(18,3) NOT NULL,
    "UnitOfMeasure" character varying(20),
    "WastePercent" numeric(5,2) DEFAULT 0 NOT NULL,
    "IsOptional" boolean DEFAULT false NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE mfg."BillOfMaterials" (
    "BOMId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BOMCode" character varying(30) NOT NULL,
    "BOMName" character varying(200) NOT NULL,
    "ProductId" bigint NOT NULL,
    "OutputQuantity" numeric(18,3) DEFAULT 1 NOT NULL,
    "UnitOfMeasure" character varying(20),
    "Version" integer DEFAULT 1 NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "EffectiveFrom" date,
    "EffectiveTo" date,
    "Notes" character varying(500),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_mfg_BOM_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'ACTIVE'::character varying, 'OBSOLETE'::character varying])::text[])))
);


CREATE TABLE mfg."Routing" (
    "RoutingId" bigint NOT NULL,
    "BOMId" bigint NOT NULL,
    "OperationNumber" integer NOT NULL,
    "OperationName" character varying(200) NOT NULL,
    "WorkCenterId" bigint NOT NULL,
    "SetupTimeMinutes" numeric(10,2) DEFAULT 0 NOT NULL,
    "RunTimeMinutes" numeric(10,2) DEFAULT 0 NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE mfg."WorkCenter" (
    "WorkCenterId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "WorkCenterCode" character varying(20) NOT NULL,
    "WorkCenterName" character varying(200) NOT NULL,
    "WarehouseId" bigint,
    "CostPerHour" numeric(18,4) DEFAULT 0 NOT NULL,
    "Capacity" numeric(18,2) DEFAULT 1 NOT NULL,
    "CapacityUom" character varying(20) DEFAULT 'UNITS_PER_HOUR'::character varying NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE mfg."WorkOrder" (
    "WorkOrderId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "WorkOrderNumber" character varying(30) NOT NULL,
    "BOMId" bigint NOT NULL,
    "ProductId" bigint NOT NULL,
    "PlannedQuantity" numeric(18,3) NOT NULL,
    "ProducedQuantity" numeric(18,3) DEFAULT 0 NOT NULL,
    "ScrapQuantity" numeric(18,3) DEFAULT 0 NOT NULL,
    "UnitOfMeasure" character varying(20),
    "WarehouseId" bigint NOT NULL,
    "Status" character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    "Priority" character varying(10) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "PlannedStartDate" timestamp without time zone,
    "PlannedEndDate" timestamp without time zone,
    "ActualStartDate" timestamp without time zone,
    "ActualEndDate" timestamp without time zone,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_mfg_WorkOrder_Priority" CHECK ((("Priority")::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT "CK_mfg_WorkOrder_Status" CHECK ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'CONFIRMED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


CREATE TABLE mfg."WorkOrderMaterial" (
    "WorkOrderMaterialId" bigint NOT NULL,
    "WorkOrderId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "ProductId" bigint NOT NULL,
    "PlannedQuantity" numeric(18,3) NOT NULL,
    "ConsumedQuantity" numeric(18,3) DEFAULT 0 NOT NULL,
    "UnitOfMeasure" character varying(20),
    "LotId" bigint,
    "BinId" bigint,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE mfg."WorkOrderOutput" (
    "WorkOrderOutputId" bigint NOT NULL,
    "WorkOrderId" bigint NOT NULL,
    "ProductId" bigint NOT NULL,
    "Quantity" numeric(18,3) NOT NULL,
    "UnitOfMeasure" character varying(20),
    "LotNumber" character varying(60),
    "WarehouseId" bigint NOT NULL,
    "BinId" bigint,
    "UnitCost" numeric(18,4) DEFAULT 0 NOT NULL,
    "IsScrap" boolean DEFAULT false NOT NULL,
    "Notes" character varying(500),
    "ProducedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE pay."AcceptedPaymentMethods" (
    "Id" integer NOT NULL,
    "EmpresaId" integer NOT NULL,
    "SucursalId" integer DEFAULT 0 NOT NULL,
    "PaymentMethodId" integer NOT NULL,
    "ProviderId" integer,
    "AppliesToPOS" boolean DEFAULT true,
    "AppliesToWeb" boolean DEFAULT true,
    "AppliesToRestaurant" boolean DEFAULT true,
    "MinAmount" numeric(18,2),
    "MaxAmount" numeric(18,2),
    "CommissionPct" numeric(5,4),
    "CommissionFixed" numeric(18,2),
    "IsActive" boolean DEFAULT true,
    "SortOrder" integer DEFAULT 0
);


CREATE TABLE pay."CardReaderDevices" (
    "Id" integer NOT NULL,
    "EmpresaId" integer NOT NULL,
    "SucursalId" integer DEFAULT 0 NOT NULL,
    "StationId" character varying(50) NOT NULL,
    "DeviceName" character varying(100) NOT NULL,
    "DeviceType" character varying(30) NOT NULL,
    "ConnectionType" character varying(30) NOT NULL,
    "ConnectionConfig" character varying(500),
    "ProviderId" integer,
    "IsActive" boolean DEFAULT true,
    "LastSeenAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE pay."PaymentMethods" (
    "Id" integer NOT NULL,
    "Code" character varying(30) NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Category" character varying(30) NOT NULL,
    "CountryCode" character(2),
    "IconName" character varying(50),
    "RequiresGateway" boolean DEFAULT false,
    "IsActive" boolean DEFAULT true,
    "SortOrder" integer DEFAULT 0,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE pay."PaymentProviders" (
    "Id" integer NOT NULL,
    "Code" character varying(30) NOT NULL,
    "Name" character varying(150) NOT NULL,
    "CountryCode" character(2),
    "ProviderType" character varying(30) NOT NULL,
    "BaseUrlSandbox" character varying(500),
    "BaseUrlProd" character varying(500),
    "AuthType" character varying(30),
    "DocsUrl" character varying(500),
    "LogoUrl" character varying(500),
    "IsActive" boolean DEFAULT true,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE pay."ProviderCapabilities" (
    "Id" integer NOT NULL,
    "ProviderId" integer NOT NULL,
    "Capability" character varying(50) NOT NULL,
    "PaymentMethod" character varying(30),
    "EndpointPath" character varying(200),
    "HttpMethod" character varying(10) DEFAULT 'POST'::character varying,
    "IsActive" boolean DEFAULT true
);


CREATE TABLE pay."ReconciliationBatches" (
    "Id" bigint NOT NULL,
    "EmpresaId" integer NOT NULL,
    "ProviderId" integer NOT NULL,
    "DateFrom" date NOT NULL,
    "DateTo" date NOT NULL,
    "TotalTransactions" integer DEFAULT 0,
    "TotalAmount" numeric(18,2) DEFAULT 0,
    "MatchedCount" integer DEFAULT 0,
    "UnmatchedCount" integer DEFAULT 0,
    "Status" character varying(20) DEFAULT 'PENDING'::character varying,
    "ResultJson" text,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "CompletedAt" timestamp without time zone,
    "UserId" character varying(20)
);


CREATE TABLE pos."FiscalCorrelative" (
    "FiscalCorrelativeId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CorrelativeType" character varying(20) DEFAULT 'FACTURA'::character varying NOT NULL,
    "CashRegisterCode" character varying(10) DEFAULT 'GLOBAL'::character varying NOT NULL,
    "SerialFiscal" character varying(40) NOT NULL,
    "CurrentNumber" integer DEFAULT 0 NOT NULL,
    "Description" character varying(200),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE pos."SaleTicket" (
    "SaleTicketId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "InvoiceNumber" character varying(20) NOT NULL,
    "CashRegisterCode" character varying(10) NOT NULL,
    "SoldByUserId" integer,
    "CustomerId" bigint,
    "CustomerCode" character varying(24),
    "CustomerName" character varying(200),
    "CustomerFiscalId" character varying(30),
    "PriceTier" character varying(20) DEFAULT 'DETAIL'::character varying NOT NULL,
    "PaymentMethod" character varying(50),
    "FiscalPayload" text,
    "WaitTicketId" bigint,
    "NetAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "DiscountAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "SoldAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE pos."SaleTicketLine" (
    "SaleTicketLineId" bigint NOT NULL,
    "SaleTicketId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ProductId" bigint,
    "ProductCode" character varying(80) NOT NULL,
    "ProductName" character varying(250) NOT NULL,
    "Quantity" numeric(10,3) NOT NULL,
    "UnitPrice" numeric(18,2) NOT NULL,
    "DiscountAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxCode" character varying(30) NOT NULL,
    "TaxRate" numeric(9,4) NOT NULL,
    "NetAmount" numeric(18,2) NOT NULL,
    "TaxAmount" numeric(18,2) NOT NULL,
    "TotalAmount" numeric(18,2) NOT NULL,
    "SupervisorApprovalId" bigint,
    "LineMetaJson" character varying(1000)
);


CREATE TABLE pos."WaitTicket" (
    "WaitTicketId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "CashRegisterCode" character varying(10) NOT NULL,
    "StationName" character varying(50),
    "CreatedByUserId" integer,
    "CustomerId" bigint,
    "CustomerCode" character varying(24),
    "CustomerName" character varying(200),
    "CustomerFiscalId" character varying(30),
    "PriceTier" character varying(20) DEFAULT 'DETAIL'::character varying NOT NULL,
    "Reason" character varying(200),
    "NetAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "DiscountAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "Status" character varying(20) DEFAULT 'WAITING'::character varying NOT NULL,
    "RecoveredByUserId" integer,
    "RecoveredAtRegister" character varying(10),
    "RecoveredAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_pos_WaitTicket_Status" CHECK ((("Status")::text = ANY ((ARRAY['WAITING'::character varying, 'RECOVERED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE pos."WaitTicketLine" (
    "WaitTicketLineId" bigint NOT NULL,
    "WaitTicketId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ProductId" bigint,
    "ProductCode" character varying(80) NOT NULL,
    "ProductName" character varying(250) NOT NULL,
    "Quantity" numeric(10,3) NOT NULL,
    "UnitPrice" numeric(18,2) NOT NULL,
    "DiscountAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxCode" character varying(30) NOT NULL,
    "TaxRate" numeric(9,4) NOT NULL,
    "NetAmount" numeric(18,2) NOT NULL,
    "TaxAmount" numeric(18,2) NOT NULL,
    "TotalAmount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "SupervisorApprovalId" bigint,
    "LineMetaJson" character varying(1000)
);


CREATE TABLE sec."UserModuleAccess" (
    "AccessId" integer NOT NULL,
    "UserCode" character varying(20) NOT NULL,
    "ModuleCode" character varying(60) NOT NULL,
    "IsAllowed" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE public."ConciliacionBancaria" (
    "ID" integer NOT NULL,
    "Nro_Cta" character varying(20) NOT NULL,
    "Fecha_Desde" timestamp without time zone NOT NULL,
    "Fecha_Hasta" timestamp without time zone NOT NULL,
    "Saldo_Inicial_Sistema" numeric(18,2) DEFAULT 0,
    "Saldo_Final_Sistema" numeric(18,2) DEFAULT 0,
    "Saldo_Inicial_Banco" numeric(18,2) DEFAULT 0,
    "Saldo_Final_Banco" numeric(18,2) DEFAULT 0,
    "Diferencia" numeric(18,2) DEFAULT 0,
    "Estado" character varying(20) DEFAULT 'PENDIENTE'::character varying,
    "Observaciones" character varying(500),
    "Co_Usuario" character varying(60) DEFAULT 'API'::character varying,
    "Fecha_Creacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text),
    "Fecha_Cierre" timestamp without time zone
);


CREATE TABLE public."ConciliacionDetalle" (
    "ID" integer NOT NULL,
    "Conciliacion_ID" integer NOT NULL,
    "Tipo_Origen" character varying(20) NOT NULL,
    "MovCuentas_ID" integer,
    "Extracto_ID" integer,
    "Fecha" timestamp without time zone,
    "Descripcion" character varying(255),
    "Referencia" character varying(50),
    "Debito" numeric(18,2) DEFAULT 0,
    "Credito" numeric(18,2) DEFAULT 0,
    "Conciliado" boolean DEFAULT false,
    "Tipo_Ajuste" character varying(20),
    "Co_Usuario" character varying(60) DEFAULT 'API'::character varying
);


CREATE TABLE public."ExtractoBancario" (
    "ID" integer NOT NULL,
    "Nro_Cta" character varying(20) NOT NULL,
    "Fecha" timestamp without time zone NOT NULL,
    "Descripcion" character varying(255),
    "Referencia" character varying(50),
    "Tipo" character varying(10),
    "Monto" numeric(18,2) NOT NULL,
    "Saldo" numeric(18,2),
    "Conciliado" boolean DEFAULT false,
    "Fecha_Conciliacion" timestamp without time zone,
    "MovCuentas_ID" integer,
    "Co_Usuario" character varying(60) DEFAULT 'API'::character varying,
    "Fecha_Reg" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


CREATE TABLE public."Lead" (
    "LeadId" integer NOT NULL,
    "Email" character varying(255) NOT NULL,
    "FullName" character varying(255) NOT NULL,
    "Company" character varying(255),
    "Country" character varying(10),
    "Source" character varying(100) DEFAULT 'zentto-landing'::character varying NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE public."PosVentas" (
    "Id" integer NOT NULL,
    "NumFactura" character varying(20) NOT NULL,
    "CajaId" character varying(10) NOT NULL,
    "CodUsuario" character varying(10),
    "ClienteId" character varying(12),
    "ClienteNombre" character varying(100),
    "ClienteRif" character varying(20),
    "TipoPrecio" character varying(20) DEFAULT 'Detal'::character varying NOT NULL,
    "Subtotal" numeric(18,2) DEFAULT 0 NOT NULL,
    "Descuento" numeric(18,2) DEFAULT 0 NOT NULL,
    "Impuestos" numeric(18,2) DEFAULT 0 NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "MetodoPago" character varying(50),
    "FechaVenta" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "TramaFiscal" text,
    "EsperaOrigenId" integer
);


CREATE TABLE public."PosVentasDetalle" (
    "Id" integer NOT NULL,
    "VentaId" integer NOT NULL,
    "ProductoId" character varying(15) NOT NULL,
    "Codigo" character varying(30),
    "Nombre" character varying(200) NOT NULL,
    "Cantidad" numeric(10,3) NOT NULL,
    "PrecioUnitario" numeric(18,2) NOT NULL,
    "Descuento" numeric(18,2) DEFAULT 0 NOT NULL,
    "IVA" numeric(5,2) DEFAULT 16 NOT NULL,
    "Subtotal" numeric(18,2) NOT NULL
);


CREATE TABLE public."PosVentasEnEspera" (
    "Id" integer NOT NULL,
    "CajaId" character varying(10) NOT NULL,
    "EstacionNombre" character varying(50),
    "CodUsuario" character varying(10),
    "ClienteId" character varying(12),
    "ClienteNombre" character varying(100),
    "ClienteRif" character varying(20),
    "TipoPrecio" character varying(20) DEFAULT 'Detal'::character varying NOT NULL,
    "Motivo" character varying(200),
    "Subtotal" numeric(18,2) DEFAULT 0 NOT NULL,
    "Descuento" numeric(18,2) DEFAULT 0 NOT NULL,
    "Impuestos" numeric(18,2) DEFAULT 0 NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "FechaCreacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "Estado" character varying(20) DEFAULT 'espera'::character varying NOT NULL,
    "RecuperadoPor" character varying(10),
    "RecuperadoEn" character varying(10),
    "FechaRecuperado" timestamp without time zone,
    CONSTRAINT "CK_PosEspera_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['espera'::character varying, 'recuperado'::character varying, 'anulado'::character varying])::text[])))
);


CREATE TABLE public."PosVentasEnEsperaDetalle" (
    "Id" integer NOT NULL,
    "VentaEsperaId" integer NOT NULL,
    "ProductoId" character varying(15) NOT NULL,
    "Codigo" character varying(30),
    "Nombre" character varying(200) NOT NULL,
    "Cantidad" numeric(10,3) NOT NULL,
    "PrecioUnitario" numeric(18,2) NOT NULL,
    "Descuento" numeric(18,2) DEFAULT 0 NOT NULL,
    "IVA" numeric(5,2) DEFAULT 16 NOT NULL,
    "Subtotal" numeric(18,2) NOT NULL,
    "Orden" integer DEFAULT 0 NOT NULL
);


CREATE TABLE public."RestauranteAmbientes" (
    "Id" integer NOT NULL,
    "Nombre" character varying(50) NOT NULL,
    "Color" character varying(10) DEFAULT '#4CAF50'::character varying NOT NULL,
    "Activo" boolean DEFAULT true NOT NULL,
    "Orden" integer DEFAULT 0 NOT NULL
);


CREATE TABLE public."RestauranteCategorias" (
    "Id" integer NOT NULL,
    "Nombre" character varying(50) NOT NULL,
    "Descripcion" character varying(200),
    "Color" character varying(10) DEFAULT '#E0E0E0'::character varying,
    "Orden" integer DEFAULT 0 NOT NULL,
    "Activa" boolean DEFAULT true NOT NULL
);


CREATE TABLE public."RestauranteComponenteOpciones" (
    "Id" integer NOT NULL,
    "ComponenteId" integer NOT NULL,
    "Nombre" character varying(100) NOT NULL,
    "PrecioExtra" numeric(18,2) DEFAULT 0 NOT NULL,
    "Orden" integer DEFAULT 0 NOT NULL
);


CREATE TABLE public."RestauranteCompras" (
    "Id" integer NOT NULL,
    "NumCompra" character varying(20) NOT NULL,
    "ProveedorId" character varying(12),
    "FechaCompra" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "FechaRecepcion" timestamp without time zone,
    "Estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "Subtotal" numeric(18,2) DEFAULT 0 NOT NULL,
    "IVA" numeric(18,2) DEFAULT 0 NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "Observaciones" character varying(500),
    "CodUsuario" character varying(10)
);


CREATE TABLE public."RestauranteComprasDetalle" (
    "Id" integer NOT NULL,
    "CompraId" integer NOT NULL,
    "InventarioId" character varying(15),
    "Descripcion" character varying(200) NOT NULL,
    "Cantidad" numeric(10,3) NOT NULL,
    "PrecioUnit" numeric(18,2) NOT NULL,
    "Subtotal" numeric(18,2) NOT NULL,
    "IVA" numeric(5,2) DEFAULT 16 NOT NULL
);


CREATE TABLE public."RestauranteMesas" (
    "Id" integer NOT NULL,
    "Numero" integer NOT NULL,
    "Nombre" character varying(50) NOT NULL,
    "Capacidad" integer DEFAULT 4 NOT NULL,
    "AmbienteId" character varying(10) DEFAULT '1'::character varying NOT NULL,
    "Ambiente" character varying(50) DEFAULT 'Salon Principal'::character varying NOT NULL,
    "PosicionX" integer DEFAULT 0 NOT NULL,
    "PosicionY" integer DEFAULT 0 NOT NULL,
    "Estado" character varying(20) DEFAULT 'libre'::character varying NOT NULL,
    "Activa" boolean DEFAULT true NOT NULL,
    "FechaCreacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ColorAmbiente" character varying(10) DEFAULT '#4CAF50'::character varying
);


CREATE TABLE public."RestaurantePedidoItems" (
    "Id" integer NOT NULL,
    "PedidoId" integer NOT NULL,
    "ProductoId" character varying(15) NOT NULL,
    "Nombre" character varying(200) NOT NULL,
    "Cantidad" numeric(10,3) DEFAULT 1 NOT NULL,
    "PrecioUnitario" numeric(18,2) NOT NULL,
    "Subtotal" numeric(18,2) NOT NULL,
    "IvaPct" numeric(9,4),
    "Estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "EsCompuesto" boolean DEFAULT false NOT NULL,
    "Componentes" text,
    "Comentarios" character varying(500),
    "EnviadoACocina" boolean DEFAULT false NOT NULL,
    "HoraEnvio" timestamp without time zone
);


CREATE TABLE public."RestaurantePedidos" (
    "Id" integer NOT NULL,
    "MesaId" integer NOT NULL,
    "ClienteNombre" character varying(100),
    "ClienteRif" character varying(20),
    "Estado" character varying(20) DEFAULT 'abierto'::character varying NOT NULL,
    "Total" numeric(18,2) DEFAULT 0 NOT NULL,
    "Comentarios" character varying(500),
    "FechaApertura" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "FechaCierre" timestamp without time zone,
    "CodUsuario" character varying(10)
);


CREATE TABLE public."RestauranteProductoComponentes" (
    "Id" integer NOT NULL,
    "ProductoId" integer NOT NULL,
    "Nombre" character varying(100) NOT NULL,
    "Obligatorio" boolean DEFAULT false NOT NULL,
    "Orden" integer DEFAULT 0 NOT NULL
);


CREATE TABLE public."RestauranteProductos" (
    "Id" integer NOT NULL,
    "Codigo" character varying(20) NOT NULL,
    "Nombre" character varying(200) NOT NULL,
    "Descripcion" character varying(500),
    "CategoriaId" integer,
    "Precio" numeric(18,2) DEFAULT 0 NOT NULL,
    "CostoEstimado" numeric(18,2) DEFAULT 0,
    "IVA" numeric(5,2) DEFAULT 16 NOT NULL,
    "EsCompuesto" boolean DEFAULT false NOT NULL,
    "TiempoPreparacion" integer DEFAULT 0 NOT NULL,
    "Imagen" character varying(500),
    "EsSugerenciaDelDia" boolean DEFAULT false NOT NULL,
    "Disponible" boolean DEFAULT true NOT NULL,
    "Activo" boolean DEFAULT true NOT NULL,
    "ArticuloInventarioId" character varying(15),
    "FechaCreacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "FechaModificacion" timestamp without time zone
);


CREATE TABLE public."RestauranteRecetas" (
    "Id" integer NOT NULL,
    "ProductoId" integer NOT NULL,
    "InventarioId" character varying(15) NOT NULL,
    "Cantidad" numeric(10,3) NOT NULL,
    "Unidad" character varying(20),
    "Comentario" character varying(200)
);


CREATE TABLE public."SchemaGovernanceDecision" (
    "Id" bigint NOT NULL,
    "DecisionGroup" character varying(60) NOT NULL,
    "ObjectType" character varying(20) NOT NULL,
    "ObjectName" character varying(256) NOT NULL,
    "DecisionStatus" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "RiskLevel" character varying(20) DEFAULT 'MEDIUM'::character varying NOT NULL,
    "ProposedAction" character varying(500),
    "Notes" text,
    "Owner" character varying(80),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedBy" character varying(40),
    "UpdatedBy" character varying(40)
);


CREATE TABLE public."SchemaGovernanceSnapshot" (
    "Id" bigint NOT NULL,
    "SnapshotAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "TotalTables" integer NOT NULL,
    "TablesWithoutPK" integer NOT NULL,
    "TablesWithoutCreatedAt" integer NOT NULL,
    "TablesWithoutUpdatedAt" integer NOT NULL,
    "TablesWithoutCreatedBy" integer NOT NULL,
    "TablesWithoutDateColumns" integer NOT NULL,
    "DuplicateNameCandidatePairs" integer NOT NULL,
    "SimilarityCandidatePairs" integer NOT NULL,
    "Notes" character varying(500)
);


CREATE TABLE public."Sys_Mensajes" (
    "Id" integer NOT NULL,
    "RemitenteId" character varying(50) NOT NULL,
    "RemitenteNombre" character varying(150) NOT NULL,
    "DestinatarioId" character varying(50) NOT NULL,
    "Asunto" character varying(200) NOT NULL,
    "Cuerpo" text,
    "Leido" boolean DEFAULT false NOT NULL,
    "FechaEnvio" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE public."Sys_Notificaciones" (
    "Id" integer NOT NULL,
    "Tipo" character varying(30) DEFAULT 'INFO'::character varying NOT NULL,
    "Titulo" character varying(200) NOT NULL,
    "Mensaje" text,
    "Leido" boolean DEFAULT false NOT NULL,
    "UsuarioId" character varying(50),
    "FechaCreacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RutaNavegacion" character varying(500)
);


CREATE TABLE public."Sys_Tareas" (
    "Id" integer NOT NULL,
    "Titulo" character varying(200) NOT NULL,
    "Descripcion" text,
    "Progreso" integer DEFAULT 0 NOT NULL,
    "Color" character varying(30) DEFAULT 'blue'::character varying,
    "AsignadoA" character varying(50),
    "FechaVencimiento" date,
    "Completado" boolean DEFAULT false NOT NULL,
    "FechaCreacion" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."User" (
    "UserId" integer NOT NULL,
    "UserCode" character varying(40) NOT NULL,
    "UserName" character varying(150) NOT NULL,
    "PasswordHash" character varying(255),
    "Email" character varying(150),
    "IsAdmin" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "LastLoginAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL,
    "UserType" character varying(10) DEFAULT 'USER'::character varying,
    "CanUpdate" boolean DEFAULT true NOT NULL,
    "CanCreate" boolean DEFAULT true NOT NULL,
    "CanDelete" boolean DEFAULT false NOT NULL,
    "IsCreator" boolean DEFAULT false NOT NULL,
    "CanChangePwd" boolean DEFAULT true NOT NULL,
    "CanChangePrice" boolean DEFAULT false NOT NULL,
    "CanGiveCredit" boolean DEFAULT false NOT NULL,
    "Avatar" text,
    "CompanyId" integer DEFAULT 1,
    "DisplayName" character varying(200),
    "Role" character varying(30) DEFAULT 'admin'::character varying
);


CREATE TABLE public._migrations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    applied_at timestamp without time zone DEFAULT now(),
    duration_ms bigint DEFAULT 0
);


CREATE TABLE public.goose_db_version (
    id integer NOT NULL,
    version_id bigint NOT NULL,
    is_applied boolean NOT NULL,
    tstamp timestamp without time zone DEFAULT now()
);


CREATE TABLE rest."DiningTable" (
    "DiningTableId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "TableNumber" character varying(20) NOT NULL,
    "TableName" character varying(100),
    "Capacity" integer DEFAULT 4 NOT NULL,
    "EnvironmentCode" character varying(20),
    "EnvironmentName" character varying(80),
    "PositionX" integer,
    "PositionY" integer,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE rest."MenuCategory" (
    "MenuCategoryId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CategoryCode" character varying(30) NOT NULL,
    "CategoryName" character varying(120) NOT NULL,
    "DescriptionText" character varying(250),
    "ColorHex" character varying(10),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE rest."MenuComponent" (
    "MenuComponentId" bigint NOT NULL,
    "MenuProductId" bigint NOT NULL,
    "ComponentName" character varying(120) NOT NULL,
    "IsRequired" boolean DEFAULT false NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE rest."MenuEnvironment" (
    "MenuEnvironmentId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "EnvironmentCode" character varying(30) NOT NULL,
    "EnvironmentName" character varying(120) NOT NULL,
    "ColorHex" character varying(10),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE rest."MenuOption" (
    "MenuOptionId" bigint NOT NULL,
    "MenuComponentId" bigint NOT NULL,
    "OptionName" character varying(120) NOT NULL,
    "ExtraPrice" numeric(18,2) DEFAULT 0 NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE rest."MenuProduct" (
    "MenuProductId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "ProductCode" character varying(40) NOT NULL,
    "ProductName" character varying(200) NOT NULL,
    "DescriptionText" character varying(500),
    "MenuCategoryId" bigint,
    "PriceAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "EstimatedCost" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxRatePercent" numeric(9,4) DEFAULT 16 NOT NULL,
    "IsComposite" boolean DEFAULT false NOT NULL,
    "PrepMinutes" integer DEFAULT 0 NOT NULL,
    "ImageUrl" character varying(500),
    "IsDailySuggestion" boolean DEFAULT false NOT NULL,
    "IsAvailable" boolean DEFAULT true NOT NULL,
    "InventoryProductId" bigint,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE rest."MenuRecipe" (
    "MenuRecipeId" bigint NOT NULL,
    "MenuProductId" bigint NOT NULL,
    "IngredientProductId" bigint NOT NULL,
    "Quantity" numeric(18,4) NOT NULL,
    "UnitCode" character varying(20),
    "Notes" character varying(200),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE rest."OrderTicket" (
    "OrderTicketId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "TableNumber" character varying(20),
    "OpenedByUserId" integer,
    "ClosedByUserId" integer,
    "CustomerName" character varying(200),
    "CustomerFiscalId" character varying(30),
    "Status" character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    "NetAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "OpenedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ClosedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "RowVer" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "CK_rest_OrderTicket_Status" CHECK ((("Status")::text = ANY ((ARRAY['OPEN'::character varying, 'SENT'::character varying, 'CLOSED'::character varying, 'VOIDED'::character varying])::text[])))
);


CREATE TABLE rest."OrderTicketLine" (
    "OrderTicketLineId" bigint NOT NULL,
    "OrderTicketId" bigint NOT NULL,
    "LineNumber" integer NOT NULL,
    "CountryCode" character(2) NOT NULL,
    "ProductId" bigint,
    "ProductCode" character varying(80) NOT NULL,
    "ProductName" character varying(250) NOT NULL,
    "Quantity" numeric(10,3) NOT NULL,
    "UnitPrice" numeric(18,2) NOT NULL,
    "TaxCode" character varying(30) NOT NULL,
    "TaxRate" numeric(9,4) NOT NULL,
    "NetAmount" numeric(18,2) NOT NULL,
    "TaxAmount" numeric(18,2) NOT NULL,
    "TotalAmount" numeric(18,2) NOT NULL,
    "Notes" character varying(300),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "SupervisorApprovalId" bigint
);


CREATE TABLE rest."Purchase" (
    "PurchaseId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "PurchaseNumber" character varying(30) NOT NULL,
    "SupplierId" bigint,
    "PurchaseDate" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "Status" character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "SubtotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TaxAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "TotalAmount" numeric(18,2) DEFAULT 0 NOT NULL,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "RowVer" integer DEFAULT 1 NOT NULL
);


CREATE TABLE rest."PurchaseLine" (
    "PurchaseLineId" bigint NOT NULL,
    "PurchaseId" bigint NOT NULL,
    "IngredientProductId" bigint,
    "DescriptionText" character varying(200) NOT NULL,
    "Quantity" numeric(18,4) NOT NULL,
    "UnitPrice" numeric(18,2) NOT NULL,
    "TaxRatePercent" numeric(9,4) NOT NULL,
    "SubtotalAmount" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."ApprovalAction" (
    "ApprovalActionId" bigint NOT NULL,
    "ApprovalRequestId" bigint NOT NULL,
    "ActionType" character varying(20) NOT NULL,
    "ActionByUserId" integer NOT NULL,
    "ActionAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "Comments" character varying(500),
    CONSTRAINT "CK_sec_ApprovalAction_Type" CHECK ((("ActionType")::text = ANY ((ARRAY['APPROVE'::character varying, 'REJECT'::character varying, 'ESCALATE'::character varying, 'COMMENT'::character varying, 'CANCEL'::character varying])::text[])))
);


CREATE TABLE sec."ApprovalRequest" (
    "ApprovalRequestId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "ApprovalRuleId" bigint NOT NULL,
    "DocumentType" character varying(30) NOT NULL,
    "DocumentId" bigint NOT NULL,
    "DocumentNumber" character varying(60),
    "RequestedAmount" numeric(18,2),
    "CurrencyCode" character(3),
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "RequestedByUserId" integer NOT NULL,
    "RequestedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ResolvedAt" timestamp without time zone,
    "Notes" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_sec_ApprovalRequest_Status" CHECK ((("Status")::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'ESCALATED'::character varying, 'CANCELLED'::character varying, 'EXPIRED'::character varying])::text[])))
);


CREATE TABLE sec."ApprovalRule" (
    "ApprovalRuleId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "RuleCode" character varying(30) NOT NULL,
    "RuleName" character varying(200) NOT NULL,
    "DocumentType" character varying(30) NOT NULL,
    "Condition" character varying(30) DEFAULT 'AMOUNT_ABOVE'::character varying NOT NULL,
    "ThresholdAmount" numeric(18,2),
    "CurrencyCode" character(3),
    "ApproverRoleId" integer,
    "ApproverUserId" integer,
    "RequiredApprovals" integer DEFAULT 1 NOT NULL,
    "AutoApproveBelow" numeric(18,2),
    "EscalateAfterHours" integer,
    "EscalateToUserId" integer,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_sec_ApprovalRule_Condition" CHECK ((("Condition")::text = ANY ((ARRAY['AMOUNT_ABOVE'::character varying, 'DISCOUNT_ABOVE'::character varying, 'CREDIT_LIMIT'::character varying, 'ALWAYS'::character varying, 'CUSTOM'::character varying])::text[])))
);


CREATE TABLE sec."AuthIdentity" (
    "UserCode" character varying(10) NOT NULL,
    "Email" character varying(254),
    "EmailNormalized" character varying(254),
    "EmailVerifiedAtUtc" timestamp without time zone,
    "IsRegistrationPending" boolean DEFAULT false NOT NULL,
    "FailedLoginCount" integer DEFAULT 0 NOT NULL,
    "LastFailedLoginAtUtc" timestamp without time zone,
    "LastFailedLoginIp" character varying(64),
    "LockoutUntilUtc" timestamp without time zone,
    "LastLoginAtUtc" timestamp without time zone,
    "PasswordChangedAtUtc" timestamp without time zone,
    "CreatedAtUtc" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAtUtc" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."AuthToken" (
    "TokenId" bigint NOT NULL,
    "UserCode" character varying(10) NOT NULL,
    "TokenType" character varying(32) NOT NULL,
    "TokenHash" character(64) NOT NULL,
    "EmailNormalized" character varying(254),
    "ExpiresAtUtc" timestamp without time zone NOT NULL,
    "ConsumedAtUtc" timestamp without time zone,
    "MetaIp" character varying(64),
    "MetaUserAgent" character varying(256),
    "CreatedAtUtc" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "CK_sec_AuthToken_Type" CHECK ((("TokenType")::text = ANY ((ARRAY['VERIFY_EMAIL'::character varying, 'RESET_PASSWORD'::character varying])::text[])))
);


CREATE TABLE sec."Permission" (
    "PermissionId" bigint NOT NULL,
    "PermissionCode" character varying(80) NOT NULL,
    "PermissionName" character varying(200) NOT NULL,
    "Module" character varying(40) NOT NULL,
    "Category" character varying(40),
    "Description" character varying(500),
    "IsSystem" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE sec."PriceRestriction" (
    "PriceRestrictionId" bigint NOT NULL,
    "CompanyId" integer NOT NULL,
    "RoleId" integer,
    "UserId" integer,
    "MaxDiscountPercent" numeric(5,2) DEFAULT 0 NOT NULL,
    "MinMarginPercent" numeric(5,2),
    "MaxCreditAmount" numeric(18,2),
    "CurrencyCode" character(3),
    "CanOverridePrice" boolean DEFAULT false NOT NULL,
    "CanGiveFreeItems" boolean DEFAULT false NOT NULL,
    "RequiresApprovalAbove" numeric(18,2),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer
);


CREATE TABLE sec."Role" (
    "RoleId" integer NOT NULL,
    "RoleCode" character varying(40) NOT NULL,
    "RoleName" character varying(120) NOT NULL,
    "IsSystem" boolean DEFAULT false NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."RolePermission" (
    "RolePermissionId" bigint NOT NULL,
    "RoleId" integer NOT NULL,
    "PermissionId" bigint NOT NULL,
    "CanCreate" boolean DEFAULT false NOT NULL,
    "CanRead" boolean DEFAULT true NOT NULL,
    "CanUpdate" boolean DEFAULT false NOT NULL,
    "CanDelete" boolean DEFAULT false NOT NULL,
    "CanExport" boolean DEFAULT false NOT NULL,
    "CanApprove" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer
);


CREATE TABLE sec."SupervisorBiometricCredential" (
    "BiometricCredentialId" bigint NOT NULL,
    "SupervisorUserCode" character varying(10) NOT NULL,
    "CredentialHash" character(64) NOT NULL,
    "CredentialId" character varying(512) NOT NULL,
    "CredentialLabel" character varying(120),
    "DeviceInfo" character varying(300),
    "IsActive" boolean DEFAULT true NOT NULL,
    "LastValidatedAtUtc" timestamp(3) without time zone,
    "CreatedAtUtc" timestamp(3) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAtUtc" timestamp(3) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserCode" character varying(10),
    "UpdatedByUserCode" character varying(10)
);


CREATE TABLE sec."SupervisorOverride" (
    "OverrideId" bigint NOT NULL,
    "ModuleCode" character varying(32) NOT NULL,
    "ActionCode" character varying(64) NOT NULL,
    "Status" character varying(20) DEFAULT 'APPROVED'::character varying NOT NULL,
    "CompanyId" integer,
    "BranchId" integer,
    "RequestedByUserCode" character varying(50),
    "SupervisorUserCode" character varying(50) NOT NULL,
    "Reason" character varying(300) NOT NULL,
    "PayloadJson" text,
    "SourceDocumentId" bigint,
    "SourceLineId" bigint,
    "ReversalLineId" bigint,
    "ApprovedAtUtc" timestamp(3) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "ConsumedAtUtc" timestamp(3) without time zone,
    "ConsumedByUserCode" character varying(50),
    "CreatedAt" timestamp(3) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp(3) without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."UserCompanyAccess" (
    "AccessId" integer NOT NULL,
    "CodUsuario" character varying(50) NOT NULL,
    "CompanyId" integer NOT NULL,
    "BranchId" integer NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDefault" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sec."UserPermissionOverride" (
    "UserPermissionOverrideId" bigint NOT NULL,
    "UserId" integer NOT NULL,
    "PermissionId" bigint NOT NULL,
    "OverrideType" character varying(10) DEFAULT 'GRANT'::character varying NOT NULL,
    "CanCreate" boolean,
    "CanRead" boolean,
    "CanUpdate" boolean,
    "CanDelete" boolean,
    "CanExport" boolean,
    "CanApprove" boolean,
    "ExpiresAt" timestamp without time zone,
    "Reason" character varying(500),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CreatedByUserId" integer,
    "UpdatedByUserId" integer,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "DeletedAt" timestamp without time zone,
    "DeletedByUserId" integer,
    CONSTRAINT "CK_sec_UPOverride_Type" CHECK ((("OverrideType")::text = ANY ((ARRAY['GRANT'::character varying, 'DENY'::character varying])::text[])))
);


CREATE TABLE sec."UserRole" (
    "UserRoleId" bigint NOT NULL,
    "UserId" integer NOT NULL,
    "RoleId" integer NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."IndustryTemplate" (
    "IndustryTemplateId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "TemplateCode" character varying(30) NOT NULL,
    "TemplateName" character varying(100) NOT NULL,
    "Description" character varying(500),
    "IconName" character varying(50),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."IndustryTemplateAttribute" (
    "TemplateAttributeId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "TemplateCode" character varying(30) NOT NULL,
    "AttributeKey" character varying(50) NOT NULL,
    "AttributeLabel" character varying(100) NOT NULL,
    "DataType" character varying(20) DEFAULT 'TEXT'::character varying NOT NULL,
    "IsRequired" boolean DEFAULT false NOT NULL,
    "DefaultValue" character varying(200),
    "ListOptions" text,
    "DisplayGroup" character varying(100) DEFAULT 'General'::character varying NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductAttribute" (
    "ProductAttributeId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "TemplateCode" character varying(30) NOT NULL,
    "AttributeKey" character varying(50) NOT NULL,
    "ValueText" character varying(500),
    "ValueNumber" numeric(18,4),
    "ValueDate" date,
    "ValueBoolean" boolean,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductHighlight" (
    "HighlightId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "HighlightText" character varying(500) NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductReview" (
    "ReviewId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "Rating" integer NOT NULL,
    "Title" character varying(200),
    "Comment" character varying(2000) NOT NULL,
    "ReviewerName" character varying(200) DEFAULT 'Cliente'::character varying NOT NULL,
    "ReviewerEmail" character varying(150),
    "IsVerified" boolean DEFAULT false NOT NULL,
    "IsApproved" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    CONSTRAINT "ProductReview_Rating_check" CHECK ((("Rating" >= 1) AND ("Rating" <= 5)))
);


CREATE TABLE store."ProductSpec" (
    "SpecId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ProductCode" character varying(80) NOT NULL,
    "SpecGroup" character varying(100) DEFAULT 'General'::character varying NOT NULL,
    "SpecKey" character varying(100) NOT NULL,
    "SpecValue" character varying(500) NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductVariant" (
    "ProductVariantId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "ParentProductCode" character varying(80) NOT NULL,
    "VariantProductCode" character varying(80) NOT NULL,
    "SKU" character varying(80),
    "PriceDelta" numeric(18,2) DEFAULT 0 NOT NULL,
    "StockOverride" numeric(18,4),
    "IsDefault" boolean DEFAULT false NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductVariantGroup" (
    "VariantGroupId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "GroupCode" character varying(30) NOT NULL,
    "GroupName" character varying(100) NOT NULL,
    "DisplayType" character varying(20) DEFAULT 'BUTTON'::character varying NOT NULL,
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductVariantOption" (
    "VariantOptionId" integer NOT NULL,
    "CompanyId" integer DEFAULT 1 NOT NULL,
    "VariantGroupId" integer NOT NULL,
    "OptionCode" character varying(30) NOT NULL,
    "OptionLabel" character varying(100) NOT NULL,
    "ColorHex" character varying(7),
    "ImageUrl" character varying(500),
    "SortOrder" integer DEFAULT 0 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDeleted" boolean DEFAULT false NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE store."ProductVariantOptionValue" (
    "VariantOptionValueId" integer NOT NULL,
    "ProductVariantId" integer NOT NULL,
    "VariantOptionId" integer NOT NULL
);


CREATE TABLE sys."BillingEvent" (
    "BillingEventId" integer NOT NULL,
    "CompanyId" integer,
    "EventType" character varying(80) NOT NULL,
    "PaddleEventId" character varying(100),
    "Payload" text,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sys."CleanupQueue" (
    "QueueId" bigint NOT NULL,
    "CompanyId" bigint NOT NULL,
    "Reason" character varying(50) NOT NULL,
    "FlaggedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "FlaggedBy" character varying(100) DEFAULT 'auto'::character varying,
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "NotifiedAt" timestamp without time zone,
    "ArchivedAt" timestamp without time zone,
    "DeletedAt" timestamp without time zone,
    "Notes" text
);


CREATE TABLE sys."License" (
    "LicenseId" bigint NOT NULL,
    "CompanyId" bigint NOT NULL,
    "LicenseType" character varying(20) DEFAULT 'SUBSCRIPTION'::character varying NOT NULL,
    "Plan" character varying(30) DEFAULT 'STARTER'::character varying NOT NULL,
    "LicenseKey" character varying(64) NOT NULL,
    "Status" character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    "StartsAt" timestamp without time zone DEFAULT now() NOT NULL,
    "ExpiresAt" timestamp without time zone,
    "PaddleSubId" character varying(100),
    "ContractRef" character varying(100),
    "MaxUsers" integer,
    "MaxBranches" integer,
    "Notes" text,
    "ConvertedFromTrial" boolean DEFAULT false,
    "CreatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


CREATE TABLE sys."PushDevice" (
    "DeviceId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "UserId" integer,
    "PushToken" character varying(500) NOT NULL,
    "Platform" character varying(10) NOT NULL,
    "DeviceName" character varying(200),
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sys."Subscription" (
    "SubscriptionId" integer NOT NULL,
    "CompanyId" integer,
    "PaddleSubscriptionId" character varying(100) NOT NULL,
    "PaddleCustomerId" character varying(100),
    "PriceId" character varying(100),
    "PlanName" character varying(100),
    "Status" character varying(30) DEFAULT 'active'::character varying NOT NULL,
    "CurrentPeriodStart" timestamp without time zone,
    "CurrentPeriodEnd" timestamp without time zone,
    "CancelledAt" timestamp without time zone,
    "TenantSubdomain" character varying(63),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sys."TenantBackup" (
    "BackupId" bigint NOT NULL,
    "CompanyId" bigint NOT NULL,
    "DbName" character varying(100) NOT NULL,
    "FilePath" character varying(500),
    "FileName" character varying(200),
    "FileSizeBytes" bigint,
    "FileSizeMB" numeric(10,2),
    "Status" character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    "StartedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CompletedAt" timestamp without time zone,
    "ErrorMessage" text,
    "CreatedBy" character varying(100) DEFAULT 'backoffice'::character varying,
    "Notes" text,
    "StorageKey" character varying(500),
    "StorageUrl" character varying(1000),
    "StorageStatus" character varying(20) DEFAULT 'LOCAL_ONLY'::character varying
);


CREATE TABLE sys."TenantDatabase" (
    "TenantDbId" integer NOT NULL,
    "CompanyId" integer NOT NULL,
    "CompanyCode" character varying(20) NOT NULL,
    "DbName" character varying(63) NOT NULL,
    "DbHost" character varying(255) DEFAULT NULL::character varying,
    "DbPort" integer,
    "DbUser" character varying(63) DEFAULT NULL::character varying,
    "DbPassword" character varying(255) DEFAULT NULL::character varying,
    "PoolMin" integer DEFAULT 0 NOT NULL,
    "PoolMax" integer DEFAULT 5 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDemo" boolean DEFAULT false NOT NULL,
    "ProvisionedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "LastMigration" character varying(100),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE sys."TenantResourceLog" (
    "LogId" bigint NOT NULL,
    "CompanyId" bigint NOT NULL,
    "DbName" character varying(100),
    "DbSizeBytes" bigint,
    "DbSizeMB" numeric(10,2),
    "TableCount" integer,
    "LastLoginAt" timestamp without time zone,
    "UserCount" integer,
    "RecordedAt" timestamp without time zone DEFAULT now() NOT NULL
);


CREATE TABLE sys."ByocDeployJob" (
    "JobId" bigint NOT NULL,
    "CompanyId" bigint NOT NULL,
    "Provider" character varying(50) NOT NULL,
    "Status" character varying(30) DEFAULT 'PENDING'::character varying NOT NULL,
    "DeployConfig" jsonb DEFAULT '{}'::jsonb,
    "ServerIp" character varying(100),
    "TenantUrl" character varying(500),
    "LogOutput" text,
    "ErrorMessage" text,
    "StartedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "CompletedAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE zsys."StudioAddon" (
    "AddonId" character varying(100) NOT NULL,
    "CompanyId" integer NOT NULL,
    "Name" character varying(200) NOT NULL,
    "Description" character varying(500),
    "Icon" character varying(100),
    "Config" text DEFAULT '{}'::text NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedBy" integer DEFAULT 0 NOT NULL,
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL,
    "UpdatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text) NOT NULL
);


CREATE TABLE zsys."StudioAddonModule" (
    "AddonId" character varying(100) NOT NULL,
    "ModuleId" character varying(100) NOT NULL
);


-- ============================================
-- Views
-- ============================================


CREATE VIEW public."DocumentosCompra" AS
 SELECT "DocumentId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "SupplierCode" AS "COD_PROVEEDOR",
    "SupplierName" AS "NOMBRE",
    "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA",
    "DueDate" AS "FECHA_VENCE",
    "ReceiptDate" AS "FECHA_RECIBO",
    "PaymentDate" AS "FECHA_PAGO",
    "DocumentTime" AS "HORA",
    ("SubTotal")::double precision AS "SUBTOTAL",
    ("TaxableAmount")::double precision AS "MONTO_GRA",
    ("ExemptAmount")::double precision AS "MONTO_EXE",
    ("TaxAmount")::double precision AS "IVA",
    ("TaxRate")::double precision AS "ALICUOTA",
    ("TotalAmount")::double precision AS "TOTAL",
    ("ExemptTotalAmount")::double precision AS "EXENTO",
    ("DiscountAmount")::double precision AS "DESCUENTO",
    "IsVoided" AS "ANULADA",
    "IsPaid" AS "CANCELADA",
    "IsReceived" AS "RECIBIDA",
    "IsLegal" AS "LEGAL",
    "OriginDocumentNumber" AS "DOC_ORIGEN",
    "ControlNumber" AS "NUM_CONTROL",
    "VoucherNumber" AS "NRO_COMPROBANTE",
    "VoucherDate" AS "FECHA_COMPROBANTE",
    ("RetainedTax")::double precision AS "IVA_RETENIDO",
    "IsrCode" AS "ISLR",
    ("IsrAmount")::double precision AS "MONTO_ISLR",
    "IsrCode" AS "CODIGO_ISLR",
    ("IsrSubjectAmount")::double precision AS "SUJETO_ISLR",
    ("RetentionRate")::double precision AS "TASA_RETENCION",
    ("ImportAmount")::double precision AS "IMPORTACION",
    ("ImportTax")::double precision AS "IVA_IMPORT",
    ("ImportBase")::double precision AS "BASE_IMPORT",
    ("FreightAmount")::double precision AS "FLETE",
    "Concept" AS "CONCEPTO",
    "Notes" AS "OBSERV",
    "OrderNumber" AS "PEDIDO",
    "ReceivedBy" AS "RECIBIDO",
    "WarehouseCode" AS "ALMACEN",
    "CurrencyCode" AS "MONEDA",
    ("ExchangeRate")::double precision AS "TASA_CAMBIO",
    ("UsdAmount")::double precision AS "PRECIO_DOLLAR",
    "UserCode" AS "COD_USUARIO",
    "ShortUserCode" AS "CO_USUARIO",
    "ReportDate" AS "FECHA_REPORTE",
    "HostName" AS "COMPUTER",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ap."PurchaseDocument";


CREATE VIEW doc."PurchaseDocument" AS
 SELECT "ID" AS "DocumentId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "DocumentType",
    "COD_PROVEEDOR" AS "SupplierCode",
    "NOMBRE" AS "SupplierName",
    "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate",
    "FECHA_VENCE" AS "DueDate",
    "SUBTOTAL" AS "Subtotal",
    "MONTO_GRA" AS "TaxableAmount",
    "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount",
    "ALICUOTA" AS "TaxRate",
    "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount",
    "ANULADA" AS "IsVoided",
    "CANCELADA" AS "IsCanceled",
    "OBSERV" AS "Notes",
    "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode",
    "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosCompra";


CREATE VIEW public."DocumentosCompraDetalle" AS
 SELECT "LineId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON",
    "ProductCode" AS "COD_SERV",
    "Description" AS "DESCRIPCION",
    ("Quantity")::double precision AS "CANTIDAD",
    ("UnitPrice")::double precision AS "PRECIO",
    ("UnitCost")::double precision AS "COSTO",
    ("SubTotal")::double precision AS "SUBTOTAL",
    ("DiscountAmount")::double precision AS "DESCUENTO",
    ("TotalAmount")::double precision AS "TOTAL",
    ("TaxRate")::double precision AS "ALICUOTA",
    ("TaxAmount")::double precision AS "MONTO_IVA",
    "IsVoided" AS "ANULADA",
    "UserCode" AS "CO_USUARIO",
    "LineDate" AS "FECHA",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ap."PurchaseDocumentLine";


CREATE VIEW doc."PurchaseDocumentLine" AS
 SELECT "ID" AS "LineId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber",
    "COD_SERV" AS "ProductCode",
    "DESCRIPCION" AS "Description",
    "CANTIDAD" AS "Quantity",
    "PRECIO" AS "UnitPrice",
    "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal",
    "DESCUENTO" AS "DiscountAmount",
    "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate",
    "MONTO_IVA" AS "TaxAmount",
    "ANULADA" AS "IsVoided",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosCompraDetalle";


CREATE VIEW public."DocumentosCompraPago" AS
 SELECT "PaymentId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO",
    "BankCode" AS "BANCO",
    "PaymentNumber" AS "NUMERO",
    ("Amount")::double precision AS "MONTO",
    "PaymentDate" AS "FECHA",
    "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA",
    "UserCode" AS "CO_USUARIO",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ap."PurchaseDocumentPayment";


CREATE VIEW doc."PurchaseDocumentPayment" AS
 SELECT "ID" AS "PaymentId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType",
    "BANCO" AS "BankCode",
    "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount",
    "FECHA" AS "ApplyDate",
    "FECHA_VENCE" AS "DueDate",
    "REFERENCIA" AS "PaymentReference",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosCompraPago";


CREATE VIEW public."DocumentosVenta" AS
 SELECT "DocumentId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "CustomerCode" AS "CODIGO",
    "CustomerName" AS "NOMBRE",
    "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA",
    "DueDate" AS "FECHA_VENCE",
    "DocumentTime" AS "HORA",
    ("SubTotal")::double precision AS "SUBTOTAL",
    ("TaxableAmount")::double precision AS "MONTO_GRA",
    ("ExemptAmount")::double precision AS "MONTO_EXE",
    ("TaxAmount")::double precision AS "IVA",
    ("TaxRate")::double precision AS "ALICUOTA",
    ("TotalAmount")::double precision AS "TOTAL",
    ("DiscountAmount")::double precision AS "DESCUENTO",
    "IsVoided" AS "ANULADA",
    "IsPaid" AS "CANCELADA",
    "IsInvoiced" AS "FACTURADA",
    "IsDelivered" AS "ENTREGADA",
    "OriginDocumentNumber" AS "DOC_ORIGEN",
    "OriginDocumentType" AS "TIPO_DOC_ORIGEN",
    "ControlNumber" AS "NUM_CONTROL",
    "IsLegal" AS "LEGAL",
    "IsPrinted" AS "IMPRESA",
    "Notes" AS "OBSERV",
    "Concept" AS "CONCEPTO",
    "PaymentTerms" AS "TERMINOS",
    "ShipToAddress" AS "DESPACHAR",
    "SellerCode" AS "VENDEDOR",
    "DepartmentCode" AS "DEPARTAMENTO",
    "LocationCode" AS "LOCACION",
    "CurrencyCode" AS "MONEDA",
    ("ExchangeRate")::double precision AS "TASA_CAMBIO",
    "UserCode" AS "COD_USUARIO",
    "ReportDate" AS "FECHA_REPORTE",
    "HostName" AS "COMPUTER",
    "VehiclePlate" AS "PLACAS",
    "Mileage" AS "KILOMETROS",
    ("TollAmount")::double precision AS "PEAJE",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ar."SalesDocument";


CREATE VIEW doc."SalesDocument" AS
 SELECT "ID" AS "DocumentId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "OperationType",
    "CODIGO" AS "CustomerCode",
    "NOMBRE" AS "CustomerName",
    "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate",
    "FECHA_VENCE" AS "DueDate",
    "HORA" AS "DocumentTime",
    "SUBTOTAL" AS "Subtotal",
    "MONTO_GRA" AS "TaxableAmount",
    "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount",
    "ALICUOTA" AS "TaxRate",
    "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount",
    "ANULADA" AS "IsVoided",
    "CANCELADA" AS "IsCanceled",
    "FACTURADA" AS "IsInvoiced",
    "ENTREGADA" AS "IsDelivered",
    "DOC_ORIGEN" AS "SourceDocumentNumber",
    "TIPO_DOC_ORIGEN" AS "SourceDocumentType",
    "NUM_CONTROL" AS "ControlNumber",
    "OBSERV" AS "Notes",
    "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode",
    "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosVenta";


CREATE VIEW public."DocumentosVentaDetalle" AS
 SELECT "LineId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON",
    "ProductCode" AS "COD_SERV",
    "Description" AS "DESCRIPCION",
    "AlternateCode" AS "COD_ALTERNO",
    ("Quantity")::double precision AS "CANTIDAD",
    ("UnitPrice")::double precision AS "PRECIO",
    ("DiscountedPrice")::double precision AS "PRECIO_DESCUENTO",
    ("UnitCost")::double precision AS "COSTO",
    ("SubTotal")::double precision AS "SUBTOTAL",
    ("DiscountAmount")::double precision AS "DESCUENTO",
    ("TotalAmount")::double precision AS "TOTAL",
    ("TaxRate")::double precision AS "ALICUOTA",
    ("TaxAmount")::double precision AS "MONTO_IVA",
    "IsVoided" AS "ANULADA",
    "RelatedRef" AS "RELACIONADA",
    "UserCode" AS "CO_USUARIO",
    "LineDate" AS "FECHA",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ar."SalesDocumentLine";


CREATE VIEW doc."SalesDocumentLine" AS
 SELECT "ID" AS "LineId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber",
    "COD_SERV" AS "ProductCode",
    "DESCRIPCION" AS "Description",
    "COD_ALTERNO" AS "AlternateCode",
    "CANTIDAD" AS "Quantity",
    "PRECIO" AS "UnitPrice",
    "PRECIO_DESCUENTO" AS "DiscountUnitPrice",
    "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal",
    "DESCUENTO" AS "DiscountAmount",
    "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate",
    "MONTO_IVA" AS "TaxAmount",
    "ANULADA" AS "IsVoided",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosVentaDetalle";


CREATE VIEW public."DocumentosVentaPago" AS
 SELECT "PaymentId" AS "ID",
    "DocumentNumber" AS "NUM_DOC",
    "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA",
    "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO",
    "BankCode" AS "BANCO",
    "PaymentNumber" AS "NUMERO",
    ("Amount")::double precision AS "MONTO",
    ("AmountBs")::double precision AS "MONTO_BS",
    ("ExchangeRate")::double precision AS "TASA_CAMBIO",
    "PaymentDate" AS "FECHA",
    "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA",
    "UserCode" AS "CO_USUARIO",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM ar."SalesDocumentPayment";


CREATE VIEW doc."SalesDocumentPayment" AS
 SELECT "ID" AS "PaymentId",
    "NUM_DOC" AS "DocumentNumber",
    "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber",
    "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType",
    "BANCO" AS "BankCode",
    "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount",
    "MONTO_BS" AS "AmountLocal",
    "TASA_CAMBIO" AS "ExchangeRate",
    "FECHA" AS "ApplyDate",
    "FECHA_VENCE" AS "DueDate",
    "REFERENCIA" AS "PaymentReference",
    "CreatedAt",
    "UpdatedAt",
    "CreatedByUserId",
    "UpdatedByUserId",
    "IsDeleted",
    "DeletedAt",
    "DeletedByUserId"
   FROM public."DocumentosVentaPago";


CREATE VIEW public."AccesoUsuarios" AS
 SELECT "UserCode" AS "Cod_Usuario",
    "ModuleCode" AS "Modulo",
    "IsAllowed" AS "Permitido",
    "CreatedAt",
    "UpdatedAt"
   FROM sec."UserModuleAccess";


CREATE VIEW public."Usuarios" AS
 SELECT "UserCode" AS "Cod_Usuario",
    "PasswordHash" AS "Password",
    "UserName" AS "Nombre",
    "UserType" AS "Tipo",
    "CanUpdate" AS "Updates",
    "CanCreate" AS "Addnews",
    "CanDelete" AS "Deletes",
    "IsCreator" AS "Creador",
    "CanChangePwd" AS "Cambiar",
    "CanChangePrice" AS "PrecioMinimo",
    "CanGiveCredit" AS "Credito",
    "IsAdmin",
    "Avatar"
   FROM sec."User"
  WHERE ("IsDeleted" = false);


CREATE VIEW public."vw_Governance_AuditCoverage" AS
 WITH t AS (
         SELECT n.nspname AS schema_name,
            c.relname AS table_name,
            c.oid AS object_id
           FROM (pg_class c
             JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
          WHERE ((c.relkind = 'r'::"char") AND (c.relname <> 'sysdiagrams'::name) AND (c.relname !~~ '%SchemaGovernance%'::text) AND (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
        ), pk AS (
         SELECT DISTINCT con.conrelid AS object_id
           FROM pg_constraint con
          WHERE (con.contype = 'p'::"char")
        ), aud AS (
         SELECT a.attrelid AS object_id,
            max(
                CASE
                    WHEN (a.attname = ANY (ARRAY['CreatedAt'::name, 'FechaCreacion'::name, 'Fecha_Creacion'::name, 'created_at'::name])) THEN 1
                    ELSE 0
                END) AS has_created_at,
            max(
                CASE
                    WHEN (a.attname = ANY (ARRAY['UpdatedAt'::name, 'FechaModificacion'::name, 'Fecha_Modificacion'::name, 'updated_at'::name])) THEN 1
                    ELSE 0
                END) AS has_updated_at,
            max(
                CASE
                    WHEN (a.attname = ANY (ARRAY['CreatedBy'::name, 'CodUsuario'::name, 'Cod_Usuario'::name, 'UsuarioCreacion'::name, 'created_by'::name])) THEN 1
                    ELSE 0
                END) AS has_created_by,
            max(
                CASE
                    WHEN (a.attname = ANY (ARRAY['UpdatedBy'::name, 'UsuarioModificacion'::name, 'updated_by'::name])) THEN 1
                    ELSE 0
                END) AS has_updated_by,
            max(
                CASE
                    WHEN (a.attname = ANY (ARRAY['IsDeleted'::name, 'is_deleted'::name])) THEN 1
                    ELSE 0
                END) AS has_is_deleted
           FROM pg_attribute a
          WHERE ((a.attnum > 0) AND (NOT a.attisdropped))
          GROUP BY a.attrelid
        ), dt AS (
         SELECT a.attrelid AS object_id,
            sum(
                CASE
                    WHEN (tp.typname = ANY (ARRAY['timestamp'::name, 'timestamptz'::name, 'date'::name])) THEN 1
                    ELSE 0
                END) AS date_column_count
           FROM (pg_attribute a
             JOIN pg_type tp ON ((a.atttypid = tp.oid)))
          WHERE ((a.attnum > 0) AND (NOT a.attisdropped))
          GROUP BY a.attrelid
        )
 SELECT t.schema_name,
    t.table_name,
        CASE
            WHEN (pk.object_id IS NULL) THEN false
            ELSE true
        END AS has_pk,
    (COALESCE(aud.has_created_at, 0))::boolean AS has_created_at,
    (COALESCE(aud.has_updated_at, 0))::boolean AS has_updated_at,
    (COALESCE(aud.has_created_by, 0))::boolean AS has_created_by,
    (COALESCE(aud.has_updated_by, 0))::boolean AS has_updated_by,
    (COALESCE(aud.has_is_deleted, 0))::boolean AS has_is_deleted,
    COALESCE(dt.date_column_count, (0)::bigint) AS date_column_count
   FROM (((t
     LEFT JOIN pk ON ((pk.object_id = t.object_id)))
     LEFT JOIN aud ON ((aud.object_id = t.object_id)))
     LEFT JOIN dt ON ((dt.object_id = t.object_id)));


CREATE VIEW public."vw_Governance_DuplicateNameCandidates" AS
 WITH base AS (
         SELECT c.relname AS table_name,
            lower((c.relname)::text) AS name_lower
           FROM (pg_class c
             JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
          WHERE ((c.relkind = 'r'::"char") AND (c.relname <> 'sysdiagrams'::name) AND (c.relname !~~ '%SchemaGovernance%'::text) AND (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
        ), norm AS (
         SELECT base.table_name,
                CASE
                    WHEN (("right"(base.name_lower, 1) = 's'::text) AND ("right"(base.name_lower, 2) <> 'ss'::text)) THEN "left"(base.name_lower, (length(base.name_lower) - 1))
                    ELSE base.name_lower
                END AS stem
           FROM base
        )
 SELECT a.table_name AS table_a,
    b.table_name AS table_b,
    a.stem AS normalized_name
   FROM (norm a
     JOIN norm b ON (((a.stem = b.stem) AND (a.table_name < b.table_name))));


CREATE VIEW public."vw_Governance_TableSimilarityCandidates" AS
 WITH cols AS (
         SELECT a.attrelid AS object_id,
            lower((a.attname)::text) AS column_name
           FROM ((pg_attribute a
             JOIN pg_class c ON ((c.oid = a.attrelid)))
             JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
          WHERE ((c.relkind = 'r'::"char") AND (a.attnum > 0) AND (NOT a.attisdropped) AND (c.relname <> 'sysdiagrams'::name) AND (c.relname !~~ '%SchemaGovernance%'::text) AND (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
        ), tcols AS (
         SELECT cols.object_id,
            count(1) AS column_count
           FROM cols
          GROUP BY cols.object_id
        ), common_cols AS (
         SELECT a.object_id AS object_id_a,
            b.object_id AS object_id_b,
            count(1) AS common_count
           FROM (cols a
             JOIN cols b ON (((a.column_name = b.column_name) AND (a.object_id < b.object_id))))
          GROUP BY a.object_id, b.object_id
        )
 SELECT ta.relname AS table_a,
    tb.relname AS table_b,
    cc.common_count,
    ca.column_count AS columns_a,
    cb.column_count AS columns_b,
    (
        CASE
            WHEN (((ca.column_count + cb.column_count) - cc.common_count) = 0) THEN (0)::numeric
            ELSE (((cc.common_count)::numeric * 1.0) / (((ca.column_count + cb.column_count) - cc.common_count))::numeric)
        END)::numeric(9,4) AS similarity_ratio
   FROM ((((common_cols cc
     JOIN tcols ca ON ((ca.object_id = cc.object_id_a)))
     JOIN tcols cb ON ((cb.object_id = cc.object_id_b)))
     JOIN pg_class ta ON ((ta.oid = cc.object_id_a)))
     JOIN pg_class tb ON ((tb.oid = cc.object_id_b)))
  WHERE (cc.common_count >= 5);


CREATE VIEW public.vw_conceptos_por_regimen AS
 SELECT "PayrollConceptId" AS "Id",
    "ConventionCode" AS "Convencion",
    "CalculationType" AS "TipoCalculo",
    "ConceptCode" AS "CO_CONCEPT",
    "ConceptName" AS "NB_CONCEPTO",
    "Formula" AS "FORMULA",
    "BaseExpression" AS "SOBRE",
    "ConceptType" AS "TIPO",
        CASE
            WHEN ("IsBonifiable" = true) THEN 'S'::text
            ELSE 'N'::text
        END AS "BONIFICABLE",
    "LotttArticle" AS "LOTTT_Articulo",
    "CcpClause" AS "CCP_Clausula",
    "SortOrder" AS "Orden",
    "IsActive" AS "Activo",
    "PayrollCode" AS "CO_NOMINA",
    "CompanyId"
   FROM hr."PayrollConcept" pc
  WHERE ("ConventionCode" IS NOT NULL);

