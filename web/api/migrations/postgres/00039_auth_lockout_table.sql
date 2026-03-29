-- +goose Up
-- +goose StatementBegin
-- Tabla de lockout de login persistente en BD (no en memoria)
-- Reemplaza el lockout in-memory que se pierde al reiniciar el servicio

CREATE TABLE IF NOT EXISTS zsys."SecLoginSecurity" (
  "UserCode"         VARCHAR(50) NOT NULL,
  "FailedAttempts"   INT NOT NULL DEFAULT 0,
  "LockoutUntilUtc"  TIMESTAMPTZ NULL,
  "LastFailedAtUtc"  TIMESTAMPTZ NULL,
  "LastSuccessAtUtc"  TIMESTAMPTZ NULL,
  "LastFailedIp"     VARCHAR(45) NULL,
  "CreatedAtUtc"     TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAtUtc"     TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_SecLoginSecurity" PRIMARY KEY ("UserCode")
);

COMMENT ON TABLE zsys."SecLoginSecurity" IS 'Lockout de intentos de login — persistente en BD';

-- SP: Verificar estado de lockout
CREATE OR REPLACE FUNCTION zsys."usp_Sec_Auth_GetLoginSecurityState"(
  p_user_code VARCHAR
)
RETURNS TABLE(
  "IsRegistrationPending" BOOLEAN,
  "EmailVerifiedAtUtc" TIMESTAMPTZ,
  "LockoutUntilUtc" TIMESTAMPTZ
) AS $$
DECLARE
  v_lockout TIMESTAMPTZ;
  v_pending BOOLEAN := FALSE;
  v_verified TIMESTAMPTZ;
BEGIN
  -- Check lockout
  SELECT s."LockoutUntilUtc" INTO v_lockout
  FROM zsys."SecLoginSecurity" s
  WHERE UPPER(s."UserCode") = UPPER(p_user_code);

  -- Check auth identity if exists
  BEGIN
    SELECT ai."IsRegistrationPending", ai."EmailVerifiedAtUtc"
    INTO v_pending, v_verified
    FROM zsys."SecAuthIdentity" ai
    WHERE UPPER(ai."UserCode") = UPPER(p_user_code);
  EXCEPTION WHEN undefined_table THEN
    v_pending := FALSE;
    v_verified := NULL;
  END;

  RETURN QUERY SELECT v_pending, v_verified, v_lockout;
END;
$$ LANGUAGE plpgsql;

-- SP: Registrar fallo de login
CREATE OR REPLACE FUNCTION zsys."usp_Sec_Auth_RegisterLoginFailure"(
  p_user_code VARCHAR,
  p_ip VARCHAR DEFAULT NULL,
  p_max_attempts INT DEFAULT 5,
  p_lockout_minutes INT DEFAULT 15
)
RETURNS VOID AS $$
DECLARE
  v_attempts INT;
BEGIN
  INSERT INTO zsys."SecLoginSecurity" ("UserCode", "FailedAttempts", "LastFailedAtUtc", "LastFailedIp", "UpdatedAtUtc")
  VALUES (UPPER(p_user_code), 1, NOW() AT TIME ZONE 'UTC', p_ip, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("UserCode") DO UPDATE SET
    "FailedAttempts" = zsys."SecLoginSecurity"."FailedAttempts" + 1,
    "LastFailedAtUtc" = NOW() AT TIME ZONE 'UTC',
    "LastFailedIp" = COALESCE(p_ip, zsys."SecLoginSecurity"."LastFailedIp"),
    "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC';

  SELECT "FailedAttempts" INTO v_attempts
  FROM zsys."SecLoginSecurity"
  WHERE UPPER("UserCode") = UPPER(p_user_code);

  IF v_attempts >= p_max_attempts THEN
    UPDATE zsys."SecLoginSecurity"
    SET "LockoutUntilUtc" = (NOW() AT TIME ZONE 'UTC') + (p_lockout_minutes || ' minutes')::INTERVAL
    WHERE UPPER("UserCode") = UPPER(p_user_code);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- SP: Registrar login exitoso (limpia lockout)
CREATE OR REPLACE FUNCTION zsys."usp_Sec_Auth_RegisterLoginSuccess"(
  p_user_code VARCHAR
)
RETURNS VOID AS $$
BEGIN
  UPDATE zsys."SecLoginSecurity"
  SET "FailedAttempts" = 0,
      "LockoutUntilUtc" = NULL,
      "LastSuccessAtUtc" = NOW() AT TIME ZONE 'UTC',
      "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
  WHERE UPPER("UserCode") = UPPER(p_user_code);
END;
$$ LANGUAGE plpgsql;

-- SP: Reset lockout (admin unlock)
CREATE OR REPLACE FUNCTION zsys."usp_Sec_Auth_ResetLockout"(
  p_user_code VARCHAR
)
RETURNS VOID AS $$
BEGIN
  UPDATE zsys."SecLoginSecurity"
  SET "FailedAttempts" = 0,
      "LockoutUntilUtc" = NULL,
      "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
  WHERE UPPER("UserCode") = UPPER(p_user_code);
END;
$$ LANGUAGE plpgsql;

-- SP: Check auth store exists
CREATE OR REPLACE FUNCTION zsys."usp_Sec_AuthStore_Check"()
RETURNS TABLE("hasStore" INT) AS $$
BEGIN
  RETURN QUERY SELECT 1;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS zsys."usp_Sec_AuthStore_Check"();
DROP FUNCTION IF EXISTS zsys."usp_Sec_Auth_ResetLockout"(VARCHAR);
DROP FUNCTION IF EXISTS zsys."usp_Sec_Auth_RegisterLoginSuccess"(VARCHAR);
DROP FUNCTION IF EXISTS zsys."usp_Sec_Auth_RegisterLoginFailure"(VARCHAR, VARCHAR, INT, INT);
DROP FUNCTION IF EXISTS zsys."usp_Sec_Auth_GetLoginSecurityState"(VARCHAR);
DROP TABLE IF EXISTS zsys."SecLoginSecurity";
