-- +goose Up
-- Supervisor biometric credential stored procedures (paridad dual-DB)
-- PG equivalents of SQL Server usp_Sec_SupervisorBiometric_* procedures

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_enroll(
    p_supervisor_user VARCHAR,
    p_credential_hash VARCHAR,
    p_credential_id   VARCHAR,
    p_credential_label VARCHAR DEFAULT NULL,
    p_device_info      VARCHAR DEFAULT NULL,
    p_actor_user       VARCHAR DEFAULT NULL
) RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sec."SupervisorBiometricCredential" (
        "SupervisorUserCode", "CredentialHash", "CredentialId",
        "CredentialLabel", "DeviceInfo", "IsActive",
        "LastValidatedAtUtc", "CreatedAtUtc", "UpdatedAtUtc",
        "CreatedByUserCode", "UpdatedByUserCode"
    )
    VALUES (
        p_supervisor_user, p_credential_hash, p_credential_id,
        p_credential_label, p_device_info, TRUE,
        NULL, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC',
        p_actor_user, p_actor_user
    )
    ON CONFLICT ("SupervisorUserCode", "CredentialHash")
    DO UPDATE SET
        "CredentialId"       = EXCLUDED."CredentialId",
        "CredentialLabel"    = EXCLUDED."CredentialLabel",
        "DeviceInfo"         = EXCLUDED."DeviceInfo",
        "IsActive"           = TRUE,
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode"  = p_actor_user;

    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_deactivate(
    p_supervisor_user VARCHAR,
    p_credential_hash VARCHAR,
    p_actor_user      VARCHAR
) RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    UPDATE sec."SupervisorBiometricCredential"
    SET "IsActive"          = FALSE,
        "UpdatedAtUtc"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode" = p_actor_user
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE
    RETURNING "BiometricCredentialId";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_hasactive(
    p_supervisor_user VARCHAR,
    p_credential_hash VARCHAR
) RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
      AND bc."IsActive" = TRUE
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_list(
    p_supervisor_user VARCHAR DEFAULT ''::VARCHAR
) RETURNS TABLE(
    "biometricCredentialId" BIGINT,
    "supervisorUserCode"    VARCHAR,
    "credentialId"          VARCHAR,
    "credentialLabel"       VARCHAR,
    "deviceInfo"            VARCHAR,
    "isActive"              BOOLEAN,
    "lastValidatedAtUtc"    TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        bc."BiometricCredentialId", bc."SupervisorUserCode",
        bc."CredentialId", bc."CredentialLabel",
        bc."DeviceInfo", bc."IsActive",
        TO_CHAR(bc."LastValidatedAtUtc", 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."IsActive" = TRUE
      AND (p_supervisor_user = '' OR bc."SupervisorUserCode" = p_supervisor_user)
    ORDER BY bc."BiometricCredentialId" DESC;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_touch(
    p_supervisor_user VARCHAR,
    p_credential_hash VARCHAR
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."SupervisorBiometricCredential"
    SET "LastValidatedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC'
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_touch(VARCHAR, VARCHAR);
-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_list(VARCHAR);
-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_hasactive(VARCHAR, VARCHAR);
-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_deactivate(VARCHAR, VARCHAR, VARCHAR);
-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_enroll(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
-- +goose StatementEnd
