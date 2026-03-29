-- +goose Up
CREATE TABLE IF NOT EXISTS crm."AutomationRule" (
    "RuleId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId" INT NOT NULL,
    "RuleName" VARCHAR(200) NOT NULL,
    "TriggerEvent" VARCHAR(50) NOT NULL,
    "ConditionJson" JSONB DEFAULT '{}',
    "ActionType" VARCHAR(50) NOT NULL,
    "ActionConfig" JSONB DEFAULT '{}',
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder" INT NOT NULL DEFAULT 0,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT NULL,
    "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS "IX_crm_AutomationRule_Company" ON crm."AutomationRule"("CompanyId", "IsActive") WHERE "IsDeleted" = FALSE;

CREATE TABLE IF NOT EXISTS crm."AutomationLog" (
    "LogId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "RuleId" BIGINT NOT NULL REFERENCES crm."AutomationRule"("RuleId"),
    "LeadId" BIGINT REFERENCES crm."Lead"("LeadId"),
    "ActionTaken" VARCHAR(50) NOT NULL,
    "ActionResult" TEXT,
    "ExecutedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE INDEX IF NOT EXISTS "IX_crm_AutomationLog_Rule" ON crm."AutomationLog"("RuleId", "ExecutedAt" DESC);

-- +goose Down
DROP TABLE IF EXISTS crm."AutomationLog" CASCADE;
DROP TABLE IF EXISTS crm."AutomationRule" CASCADE;
