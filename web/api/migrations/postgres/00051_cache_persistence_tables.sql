-- +goose Up
-- Tablas para persistencia definitiva de datos de zentto-cache (Redis).
-- Redis es cache rapida; PostgreSQL es fuente de verdad.

-- 1. Grid Layouts
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."CacheGridLayout" (
    "GridLayoutId"  SERIAL PRIMARY KEY,
    "CompanyId"     INTEGER NOT NULL,
    "UserId"        VARCHAR(100) NOT NULL,
    "GridId"        VARCHAR(200) NOT NULL,
    "Layout"        JSONB NOT NULL,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CacheGridLayout" ON cfg."CacheGridLayout" ("CompanyId", "UserId", "GridId");
CREATE INDEX IF NOT EXISTS "IX_CacheGridLayout_User" ON cfg."CacheGridLayout" ("CompanyId", "UserId");
-- +goose StatementEnd

-- 2. Report Templates
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."CacheReportTemplate" (
    "ReportTemplateId" SERIAL PRIMARY KEY,
    "CompanyId"     INTEGER NOT NULL,
    "UserId"        VARCHAR(100),
    "TemplateId"    VARCHAR(200) NOT NULL,
    "Name"          VARCHAR(200),
    "Description"   TEXT,
    "Category"      VARCHAR(50),
    "Template"      JSONB NOT NULL,
    "IsPublic"      BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CacheReportTemplate" ON cfg."CacheReportTemplate" ("CompanyId", COALESCE("UserId", '_public_'), "TemplateId");
CREATE INDEX IF NOT EXISTS "IX_CacheReportTemplate_Public" ON cfg."CacheReportTemplate" ("CompanyId") WHERE "IsPublic" = TRUE;
-- +goose StatementEnd

-- 3. Studio Schemas
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."CacheStudioSchema" (
    "StudioSchemaId" SERIAL PRIMARY KEY,
    "CompanyId"     INTEGER NOT NULL,
    "UserId"        VARCHAR(100),
    "SchemaId"      VARCHAR(200) NOT NULL,
    "Name"          VARCHAR(200),
    "Description"   TEXT,
    "Schema"        JSONB NOT NULL,
    "IsPublic"      BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CacheStudioSchema" ON cfg."CacheStudioSchema" ("CompanyId", COALESCE("UserId", '_public_'), "SchemaId");
CREATE INDEX IF NOT EXISTS "IX_CacheStudioSchema_Public" ON cfg."CacheStudioSchema" ("CompanyId") WHERE "IsPublic" = TRUE;
-- +goose StatementEnd

-- Grants
GRANT ALL ON cfg."CacheGridLayout" TO zentto_app;
GRANT ALL ON cfg."CacheReportTemplate" TO zentto_app;
GRANT ALL ON cfg."CacheStudioSchema" TO zentto_app;
GRANT USAGE ON SEQUENCE cfg."CacheGridLayout_GridLayoutId_seq" TO zentto_app;
GRANT USAGE ON SEQUENCE cfg."CacheReportTemplate_ReportTemplateId_seq" TO zentto_app;
GRANT USAGE ON SEQUENCE cfg."CacheStudioSchema_StudioSchemaId_seq" TO zentto_app;

-- +goose Down
DROP TABLE IF EXISTS cfg."CacheStudioSchema" CASCADE;
DROP TABLE IF EXISTS cfg."CacheReportTemplate" CASCADE;
DROP TABLE IF EXISTS cfg."CacheGridLayout" CASCADE;
