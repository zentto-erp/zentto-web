-- +goose Up

-- Schema sys
CREATE SCHEMA IF NOT EXISTS sys;

-- Tabla sys.TenantDatabase
CREATE TABLE IF NOT EXISTS sys."TenantDatabase" (
    "TenantDbId" integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId" integer NOT NULL,
    "CompanyCode" character varying(20) NOT NULL,
    "DbName" character varying(63) NOT NULL,
    "DbHost" character varying(255) DEFAULT NULL,
    "DbPort" integer,
    "DbUser" character varying(63) DEFAULT NULL,
    "DbPassword" character varying(255) DEFAULT NULL,
    "PoolMin" integer DEFAULT 0 NOT NULL,
    "PoolMax" integer DEFAULT 5 NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsDemo" boolean DEFAULT false NOT NULL,
    "ProvisionedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
    "LastMigration" character varying(100),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
    CONSTRAINT "UQ_sys_TenantDatabase_CompanyId" UNIQUE ("CompanyId"),
    CONSTRAINT "UQ_sys_TenantDatabase_DbName" UNIQUE ("DbName")
);

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_tenantdb_resolve(p_company_id integer)
RETURNS TABLE(
    "DbName" character varying,
    "DbHost" character varying,
    "DbPort" integer,
    "DbUser" character varying,
    "DbPassword" character varying,
    "PoolMin" integer,
    "PoolMax" integer,
    "IsDemo" boolean
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."DbName",
        t."DbHost",
        t."DbPort",
        t."DbUser",
        t."DbPassword",
        t."PoolMin",
        t."PoolMax",
        t."IsDemo"
    FROM sys."TenantDatabase" t
    WHERE t."CompanyId" = p_company_id
      AND t."IsActive" = true;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_tenantdb_register(
    p_company_id integer,
    p_company_code character varying,
    p_db_name character varying
)
RETURNS TABLE("ok" boolean, "mensaje" character varying) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName")
    VALUES (p_company_id, p_company_code, p_db_name)
    ON CONFLICT ("CompanyId") DO UPDATE
    SET "DbName" = EXCLUDED."DbName",
        "CompanyCode" = EXCLUDED."CompanyCode",
        "IsActive" = true;

    RETURN QUERY SELECT true, 'Tenant registrado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_sys_tenantdb_register(integer, character varying, character varying);
DROP FUNCTION IF EXISTS usp_sys_tenantdb_resolve(integer);
DROP TABLE IF EXISTS sys."TenantDatabase";
