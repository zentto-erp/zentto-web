-- +goose Up
-- Migration: tabla sys.TenantDatabase + funciones de tenant routing

-- +goose StatementBegin
CREATE SCHEMA IF NOT EXISTS sys;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS sys."TenantDatabase" (
  "TenantDbId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT NOT NULL,
  "CompanyCode"   VARCHAR(20) NOT NULL,
  "DbName"        VARCHAR(63) NOT NULL,
  "DbHost"        VARCHAR(255) DEFAULT NULL,
  "DbPort"        INT DEFAULT NULL,
  "DbUser"        VARCHAR(63) DEFAULT NULL,
  "DbPassword"    VARCHAR(255) DEFAULT NULL,
  "PoolMin"       INT NOT NULL DEFAULT 0,
  "PoolMax"       INT NOT NULL DEFAULT 5,
  "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
  "IsDemo"        BOOLEAN NOT NULL DEFAULT FALSE,
  "ProvisionedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "LastMigration" VARCHAR(100) NULL,
  "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_sys_TenantDatabase_CompanyId" UNIQUE ("CompanyId"),
  CONSTRAINT "UQ_sys_TenantDatabase_DbName" UNIQUE ("DbName")
);
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_sys_tenantdb_resolve(p_company_id INT)
RETURNS TABLE(
  "DbName" VARCHAR, "DbHost" VARCHAR, "DbPort" INT,
  "DbUser" VARCHAR, "DbPassword" VARCHAR,
  "PoolMin" INT, "PoolMax" INT, "IsDemo" BOOLEAN
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t."DbName", t."DbHost", t."DbPort", t."DbUser", t."DbPassword",
         t."PoolMin", t."PoolMax", t."IsDemo"
  FROM sys."TenantDatabase" t
  WHERE t."CompanyId" = p_company_id AND t."IsActive" = TRUE;

  IF NOT FOUND THEN
    RETURN QUERY
    SELECT t."DbName", t."DbHost", t."DbPort", t."DbUser", t."DbPassword",
           t."PoolMin", t."PoolMax", t."IsDemo"
    FROM sys."TenantDatabase" t
    WHERE t."IsDemo" = TRUE AND t."IsActive" = TRUE
    LIMIT 1;
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_tenantdb_list()
RETURNS TABLE(
  "TenantDbId" INT, "CompanyId" INT, "CompanyCode" VARCHAR,
  "DbName" VARCHAR, "DbHost" VARCHAR, "DbPort" INT,
  "DbUser" VARCHAR, "DbPassword" VARCHAR,
  "PoolMin" INT, "PoolMax" INT,
  "IsActive" BOOLEAN, "IsDemo" BOOLEAN,
  "ProvisionedAt" TIMESTAMP, "LastMigration" VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t."TenantDbId", t."CompanyId", t."CompanyCode",
         t."DbName", t."DbHost", t."DbPort",
         t."DbUser", t."DbPassword",
         t."PoolMin", t."PoolMax",
         t."IsActive", t."IsDemo",
         t."ProvisionedAt", t."LastMigration"
  FROM sys."TenantDatabase" t
  WHERE t."IsActive" = TRUE
  ORDER BY t."CompanyId";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_tenantdb_register(
  p_company_id   INT,
  p_company_code VARCHAR(20),
  p_db_name      VARCHAR(63),
  p_db_host      VARCHAR(255) DEFAULT NULL,
  p_db_port      INT DEFAULT NULL,
  p_db_user      VARCHAR(63) DEFAULT NULL,
  p_db_password  VARCHAR(255) DEFAULT NULL,
  p_pool_min     INT DEFAULT 0,
  p_pool_max     INT DEFAULT 5,
  p_is_demo      BOOLEAN DEFAULT FALSE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO sys."TenantDatabase" (
    "CompanyId", "CompanyCode", "DbName",
    "DbHost", "DbPort", "DbUser", "DbPassword",
    "PoolMin", "PoolMax", "IsDemo"
  ) VALUES (
    p_company_id, p_company_code, p_db_name,
    p_db_host, p_db_port, p_db_user, p_db_password,
    p_pool_min, p_pool_max, p_is_demo
  )
  ON CONFLICT ("CompanyId") DO UPDATE SET
    "CompanyCode" = EXCLUDED."CompanyCode",
    "DbName"      = EXCLUDED."DbName",
    "DbHost"      = EXCLUDED."DbHost",
    "DbPort"      = EXCLUDED."DbPort",
    "DbUser"      = EXCLUDED."DbUser",
    "DbPassword"  = EXCLUDED."DbPassword",
    "PoolMin"     = EXCLUDED."PoolMin",
    "PoolMax"     = EXCLUDED."PoolMax",
    "IsDemo"      = EXCLUDED."IsDemo";

  RETURN QUERY SELECT TRUE::BOOLEAN, 'Tenant registrado correctamente'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE::BOOLEAN, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Seed: registrar la BD demo actual
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
VALUES (0, 'DEMO', current_database() || '_demo', TRUE)
ON CONFLICT ("CompanyId") DO UPDATE SET
  "CompanyCode" = EXCLUDED."CompanyCode",
  "DbName" = EXCLUDED."DbName",
  "IsDemo" = EXCLUDED."IsDemo";
-- +goose StatementEnd

-- +goose Down

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_sys_tenantdb_resolve;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_sys_tenantdb_list;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_sys_tenantdb_register;
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS sys."TenantDatabase";
-- +goose StatementEnd
