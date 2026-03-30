-- ============================================================================
-- 005_auth_security_hardening.sql — PostgreSQL
-- Tablas: sec.AuthIdentity, sec.AuthToken
-- Equivalente a sqlweb/includes/005_auth_security_hardening.sql (SQL Server)
-- ============================================================================

-- sec.AuthIdentity
CREATE TABLE IF NOT EXISTS sec."AuthIdentity" (
  "UserCode"              VARCHAR(10)   NOT NULL,
  "Email"                 VARCHAR(254)  NULL,
  "EmailNormalized"       VARCHAR(254)  NULL,
  "EmailVerifiedAtUtc"    TIMESTAMP     NULL,
  "IsRegistrationPending" BOOLEAN       NOT NULL DEFAULT FALSE,
  "FailedLoginCount"      INT           NOT NULL DEFAULT 0,
  "LastFailedLoginAtUtc"  TIMESTAMP     NULL,
  "LastFailedLoginIp"     VARCHAR(64)   NULL,
  "LockoutUntilUtc"       TIMESTAMP     NULL,
  "LastLoginAtUtc"        TIMESTAMP     NULL,
  "PasswordChangedAtUtc"  TIMESTAMP     NULL,
  "CreatedAtUtc"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAtUtc"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_sec_AuthIdentity" PRIMARY KEY ("UserCode"),
  CONSTRAINT "FK_sec_AuthIdentity_User"
    FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_sec_AuthIdentity_EmailNormalized"
  ON sec."AuthIdentity" ("EmailNormalized")
  WHERE "EmailNormalized" IS NOT NULL;

-- sec.AuthToken
CREATE TABLE IF NOT EXISTS sec."AuthToken" (
  "TokenId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserCode"          VARCHAR(10)   NOT NULL,
  "TokenType"         VARCHAR(32)   NOT NULL,
  "TokenHash"         CHAR(64)      NOT NULL,
  "EmailNormalized"   VARCHAR(254)  NULL,
  "ExpiresAtUtc"      TIMESTAMP     NOT NULL,
  "ConsumedAtUtc"     TIMESTAMP     NULL,
  "MetaIp"            VARCHAR(64)   NULL,
  "MetaUserAgent"     VARCHAR(256)  NULL,
  "CreatedAtUtc"      TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_sec_AuthToken_User"
    FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode"),
  CONSTRAINT "CK_sec_AuthToken_Type"
    CHECK ("TokenType" IN ('VERIFY_EMAIL', 'RESET_PASSWORD'))
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_sec_AuthToken_TokenHash"
  ON sec."AuthToken" ("TokenHash");

CREATE INDEX IF NOT EXISTS "IX_sec_AuthToken_UserCode_Type_Expires"
  ON sec."AuthToken" ("UserCode", "TokenType", "ExpiresAtUtc", "ConsumedAtUtc");

-- Seed: migrar usuarios existentes a AuthIdentity
INSERT INTO sec."AuthIdentity" (
  "UserCode", "EmailVerifiedAtUtc", "IsRegistrationPending",
  "FailedLoginCount", "CreatedAtUtc", "UpdatedAtUtc"
)
SELECT
  u."UserCode",
  NOW() AT TIME ZONE 'UTC',
  FALSE,
  0,
  NOW() AT TIME ZONE 'UTC',
  NOW() AT TIME ZONE 'UTC'
FROM sec."User" u
LEFT JOIN sec."AuthIdentity" ai ON ai."UserCode" = u."UserCode"
WHERE ai."UserCode" IS NULL AND u."IsDeleted" = FALSE
ON CONFLICT DO NOTHING;
