-- ============================================================================
-- sys.PushDevice — Registro de dispositivos móviles para push notifications
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS sys;

CREATE TABLE IF NOT EXISTS sys."PushDevice" (
    "DeviceId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"     INT NOT NULL,
    "UserId"        INT,
    "PushToken"     VARCHAR(500) NOT NULL,
    "Platform"      VARCHAR(10) NOT NULL,       -- 'ios' | 'android'
    "DeviceName"    VARCHAR(200),
    "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_PushDevice_Token" UNIQUE ("PushToken")
);

CREATE INDEX IF NOT EXISTS "IX_PushDevice_User"
    ON sys."PushDevice" ("CompanyId", "UserId") WHERE "IsActive" = TRUE;

-- ============================================================================
-- usp_Sys_Device_Register
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Sys_Device_Register(INT, INT, VARCHAR, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Device_Register(
    p_company_id    INT,
    p_user_id       INT DEFAULT NULL,
    p_push_token    VARCHAR(500) DEFAULT NULL,
    p_platform      VARCHAR(10) DEFAULT NULL,
    p_device_name   VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
DECLARE
    v_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM sys."PushDevice" WHERE "PushToken" = p_push_token) THEN
        UPDATE sys."PushDevice"
        SET "CompanyId"  = p_company_id,
            "UserId"     = p_user_id,
            "Platform"   = p_platform,
            "DeviceName" = COALESCE(p_device_name, "DeviceName"),
            "IsActive"   = TRUE,
            "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
        WHERE "PushToken" = p_push_token
        RETURNING "DeviceId" INTO v_id;

        RETURN QUERY SELECT v_id, 'Dispositivo actualizado'::VARCHAR;
    ELSE
        INSERT INTO sys."PushDevice" ("CompanyId", "UserId", "PushToken", "Platform", "DeviceName")
        VALUES (p_company_id, p_user_id, p_push_token, p_platform, p_device_name)
        RETURNING "DeviceId" INTO v_id;

        RETURN QUERY SELECT v_id, 'Dispositivo registrado'::VARCHAR;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_Unregister
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Sys_Device_Unregister(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Device_Unregister(
    p_push_token    VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
    UPDATE sys."PushDevice"
    SET "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "PushToken" = p_push_token;

    RETURN QUERY SELECT 1, 'Dispositivo desregistrado'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_ListByUser
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Sys_Device_ListByUser(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Device_ListByUser(
    p_company_id    INT DEFAULT NULL,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE(
    "DeviceId" INT, "PushToken" VARCHAR, "Platform" VARCHAR,
    "DeviceName" VARCHAR, "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT d."DeviceId", d."PushToken", d."Platform",
           d."DeviceName", d."CreatedAt", d."UpdatedAt"
    FROM sys."PushDevice" d
    WHERE d."CompanyId" = p_company_id
      AND d."UserId" = p_user_id
      AND d."IsActive" = TRUE
    ORDER BY d."UpdatedAt" DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_GetTokensByUser — Para envío de push desde backend
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Sys_Device_GetTokensByUser(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Device_GetTokensByUser(
    p_company_id    INT DEFAULT NULL,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("PushToken" VARCHAR, "Platform" VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT d."PushToken", d."Platform"
    FROM sys."PushDevice" d
    WHERE d."CompanyId" = p_company_id
      AND d."UserId" = p_user_id
      AND d."IsActive" = TRUE;
END;
$$ LANGUAGE plpgsql;
