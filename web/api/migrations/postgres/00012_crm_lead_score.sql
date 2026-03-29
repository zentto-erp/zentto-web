-- +goose Up
CREATE TABLE IF NOT EXISTS crm."LeadScore" (
    "LeadScoreId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "LeadId" BIGINT NOT NULL REFERENCES crm."Lead"("LeadId"),
    "Score" INT NOT NULL DEFAULT 0,
    "ScoreDate" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "Factors" JSONB DEFAULT '{}',
    "CalculatedByUserId" INT NULL
);
CREATE INDEX IF NOT EXISTS "IX_crm_LeadScore_LeadId" ON crm."LeadScore"("LeadId", "ScoreDate" DESC);

-- +goose Down
DROP TABLE IF EXISTS crm."LeadScore" CASCADE;
