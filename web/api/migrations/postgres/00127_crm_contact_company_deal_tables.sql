-- +goose Up
-- ADR-CRM-001 — Modelo Contact/Company/Deal separado de Lead (decisión B+B).
-- Crea tablas: crm.Company, crm.Contact, crm.Deal, crm.DealLine, crm.DealHistory.
-- Refactor crm.Lead: añade ConvertedToDealId, amplia LeadStatus con CONTACTED|QUALIFIED|DISQUALIFIED|CONVERTED.

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.Company (cuenta corporativa / empresa prospecto)
-- Nota: nombre de columna "CompanyId" se reserva como tenant-id (convención ERP).
--       el PK propio de esta tabla es "CrmCompanyId".
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."Company" (
    "CrmCompanyId"     BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "CompanyId"        INTEGER NOT NULL,              -- tenant
    "Name"             VARCHAR(200) NOT NULL,
    "LegalName"        VARCHAR(200),
    "TaxId"            VARCHAR(50),
    "Industry"         VARCHAR(100),
    "Size"             VARCHAR(20),
    "Website"          VARCHAR(255),
    "Phone"            VARCHAR(50),
    "Email"            VARCHAR(255),
    "BillingAddress"   JSONB,
    "ShippingAddress"  JSONB,
    "Notes"            TEXT,
    "IsActive"         BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDeleted"        BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"        TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "UpdatedAt"        TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "DeletedAt"        TIMESTAMP,
    "CreatedByUserId"  INTEGER,
    "UpdatedByUserId"  INTEGER,
    "DeletedByUserId"  INTEGER,
    "RowVer"           INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT "CK_crm_Company_Size" CHECK (
        "Size" IS NULL OR
        "Size" IN ('1-10','11-50','51-200','201-500','501-1000','1000+')
    )
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Company_Tenant_Name"
    ON crm."Company" ("CompanyId", "Name")
    WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.Contact
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."Contact" (
    "ContactId"           BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "CompanyId"           INTEGER NOT NULL,            -- tenant
    "CrmCompanyId"        BIGINT REFERENCES crm."Company"("CrmCompanyId"),
    "FirstName"           VARCHAR(100) NOT NULL,
    "LastName"            VARCHAR(100),
    "Email"               VARCHAR(255),
    "Phone"               VARCHAR(50),
    "Mobile"              VARCHAR(50),
    "Title"               VARCHAR(100),
    "Department"          VARCHAR(100),
    "LinkedIn"            VARCHAR(255),
    "Notes"               TEXT,
    "PromotedCustomerId"  BIGINT,                      -- FK lógica a master."Customer" (referencia cruzada por id)
    "IsActive"            BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDeleted"           BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "DeletedAt"           TIMESTAMP,
    "CreatedByUserId"     INTEGER,
    "UpdatedByUserId"     INTEGER,
    "DeletedByUserId"     INTEGER,
    "RowVer"              INTEGER NOT NULL DEFAULT 1
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Contact_Tenant_Crmcompany"
    ON crm."Contact" ("CompanyId", "CrmCompanyId")
    WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Contact_Tenant_Email"
    ON crm."Contact" ("CompanyId", "Email")
    WHERE "Email" IS NOT NULL AND "IsDeleted" = FALSE;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.Deal (oportunidad de venta con pipeline)
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."Deal" (
    "DealId"             BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "CompanyId"          INTEGER NOT NULL,              -- tenant
    "BranchId"           INTEGER NOT NULL DEFAULT 1,
    "ContactId"          BIGINT REFERENCES crm."Contact"("ContactId"),
    "CrmCompanyId"       BIGINT REFERENCES crm."Company"("CrmCompanyId"),
    "PipelineId"         BIGINT NOT NULL REFERENCES crm."Pipeline"("PipelineId"),
    "StageId"            BIGINT NOT NULL REFERENCES crm."PipelineStage"("StageId"),
    "OwnerAgentId"       BIGINT REFERENCES crm."Agent"("AgentId"),
    "AssignedToUserId"   INTEGER,
    "Name"               VARCHAR(255) NOT NULL,
    "Value"              NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Currency"           VARCHAR(3) NOT NULL DEFAULT 'USD',
    "Probability"        NUMERIC(5,2),
    "ExpectedCloseDate"  DATE,
    "ActualCloseDate"    DATE,
    "Status"             VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    "WonLostReason"      VARCHAR(500),
    "Priority"           VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
    "Source"             VARCHAR(50),
    "Notes"              TEXT,
    "Tags"               VARCHAR(500),
    "SourceLeadId"       BIGINT REFERENCES crm."Lead"("LeadId"),
    "IsDeleted"          BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"          TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    "ClosedAt"           TIMESTAMP,
    "DeletedAt"          TIMESTAMP,
    "CreatedByUserId"    INTEGER,
    "UpdatedByUserId"    INTEGER,
    "DeletedByUserId"    INTEGER,
    "RowVer"             INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT "CK_crm_Deal_Status"      CHECK ("Status" IN ('OPEN','WON','LOST','ABANDONED')),
    CONSTRAINT "CK_crm_Deal_Priority"    CHECK ("Priority" IN ('URGENT','HIGH','MEDIUM','LOW')),
    CONSTRAINT "CK_crm_Deal_Probability" CHECK ("Probability" IS NULL OR ("Probability" BETWEEN 0 AND 100))
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Deal_Tenant_Stage"
    ON crm."Deal" ("CompanyId", "StageId")
    WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Deal_Contact"
    ON crm."Deal" ("ContactId")
    WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_Deal_CrmCompany"
    ON crm."Deal" ("CrmCompanyId")
    WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.DealLine
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."DealLine" (
    "LineId"       BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "DealId"       BIGINT NOT NULL REFERENCES crm."Deal"("DealId") ON DELETE CASCADE,
    "ProductId"    BIGINT,
    "Description"  VARCHAR(500) NOT NULL,
    "Quantity"     NUMERIC(18,4) NOT NULL DEFAULT 1,
    "UnitPrice"    NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Discount"     NUMERIC(5,2) NOT NULL DEFAULT 0,
    "TotalPrice"   NUMERIC(18,2) NOT NULL DEFAULT 0,
    "SortOrder"    INTEGER NOT NULL DEFAULT 0,
    "CreatedAt"    TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC')
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_DealLine_Deal"
    ON crm."DealLine" ("DealId");
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.DealHistory
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."DealHistory" (
    "HistoryId"    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "DealId"       BIGINT NOT NULL REFERENCES crm."Deal"("DealId") ON DELETE CASCADE,
    "ChangeType"   VARCHAR(30) NOT NULL,
    "OldValue"     JSONB,
    "NewValue"     JSONB,
    "Notes"        TEXT,
    "UserId"       INTEGER,
    "ChangedAt"    TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
    CONSTRAINT "CK_crm_DealHistory_Type" CHECK (
        "ChangeType" IN ('CREATED','STAGE_CHANGE','VALUE_CHANGE','OWNER_CHANGE',
                          'STATUS_CHANGE','NOTE','WON','LOST','REOPEN','BACKFILL')
    )
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_DealHistory_Deal"
    ON crm."DealHistory" ("DealId", "ChangedAt" DESC);
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- crm.Lead — ampliar LeadStatus con 4 valores nuevos, añadir ConvertedToDealId
-- No se eliminan columnas legacy (Stage, Probability, Value, CloseDate) para
-- preservar compat; otro PR posterior las retira tras el refactor del Kanban.
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
ALTER TABLE crm."Lead"
    ADD COLUMN IF NOT EXISTS "ConvertedToDealId" BIGINT REFERENCES crm."Deal"("DealId");
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'CK_crm_Lead_Status'
           AND conrelid = 'crm."Lead"'::regclass
    ) THEN
        ALTER TABLE crm."Lead" DROP CONSTRAINT "CK_crm_Lead_Status";
    END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
ALTER TABLE crm."Lead"
    ADD CONSTRAINT "CK_crm_Lead_Status" CHECK (
        "Status" IN (
            'OPEN','WON','LOST','ARCHIVED',
            'NEW','CONTACTED','QUALIFIED','DISQUALIFIED','CONVERTED'
        )
    );
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE crm."Lead" DROP COLUMN IF EXISTS "ConvertedToDealId";
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'CK_crm_Lead_Status'
           AND conrelid = 'crm."Lead"'::regclass
    ) THEN
        ALTER TABLE crm."Lead" DROP CONSTRAINT "CK_crm_Lead_Status";
    END IF;
    ALTER TABLE crm."Lead"
        ADD CONSTRAINT "CK_crm_Lead_Status" CHECK (
            "Status" IN ('OPEN','WON','LOST','ARCHIVED')
        );
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."DealHistory";
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."DealLine";
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."Deal";
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."Contact";
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."Company";
-- +goose StatementEnd
