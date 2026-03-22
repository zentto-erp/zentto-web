-- ============================================================================
-- sys.PushDevice — Registro de dispositivos móviles para push notifications
-- ============================================================================

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
CREATE OR REPLACE FUNCTION usp_Sys_Device_Register(
    p_CompanyId     INT,
    p_UserId        INT DEFAULT NULL,
    p_PushToken     VARCHAR(500) DEFAULT NULL,
    p_Platform      VARCHAR(10) DEFAULT NULL,
    p_DeviceName    VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
DECLARE
    v_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM sys."PushDevice" WHERE "PushToken" = p_PushToken) THEN
        UPDATE sys."PushDevice"
        SET "CompanyId"  = p_CompanyId,
            "UserId"     = p_UserId,
            "Platform"   = p_Platform,
            "DeviceName" = COALESCE(p_DeviceName, "DeviceName"),
            "IsActive"   = TRUE,
            "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
        WHERE "PushToken" = p_PushToken
        RETURNING "DeviceId" INTO v_id;

        RETURN QUERY SELECT v_id, 'Dispositivo actualizado'::VARCHAR;
    ELSE
        INSERT INTO sys."PushDevice" ("CompanyId", "UserId", "PushToken", "Platform", "DeviceName")
        VALUES (p_CompanyId, p_UserId, p_PushToken, p_Platform, p_DeviceName)
        RETURNING "DeviceId" INTO v_id;

        RETURN QUERY SELECT v_id, 'Dispositivo registrado'::VARCHAR;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_Unregister
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_Sys_Device_Unregister(
    p_PushToken     VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
    UPDATE sys."PushDevice"
    SET "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "PushToken" = p_PushToken;

    RETURN QUERY SELECT 1, 'Dispositivo desregistrado'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_ListByUser
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_Sys_Device_ListByUser(
    p_CompanyId     INT DEFAULT NULL,
    p_UserId        INT DEFAULT NULL
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
    WHERE d."CompanyId" = p_CompanyId
      AND d."UserId" = p_UserId
      AND d."IsActive" = TRUE
    ORDER BY d."UpdatedAt" DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- usp_Sys_Device_GetTokensByUser — Para envío de push desde backend
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_Sys_Device_GetTokensByUser(
    p_CompanyId     INT DEFAULT NULL,
    p_UserId        INT DEFAULT NULL
)
RETURNS TABLE("PushToken" VARCHAR, "Platform" VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT d."PushToken", d."Platform"
    FROM sys."PushDevice" d
    WHERE d."CompanyId" = p_CompanyId
      AND d."UserId" = p_UserId
      AND d."IsActive" = TRUE;
END;
$$ LANGUAGE plpgsql;
