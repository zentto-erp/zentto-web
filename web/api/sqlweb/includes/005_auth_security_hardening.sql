SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID(N'sec.AuthIdentity', N'U') IS NULL
  BEGIN
    CREATE TABLE sec.AuthIdentity (
      UserCode NVARCHAR(10) NOT NULL,
      Email NVARCHAR(254) NULL,
      EmailNormalized NVARCHAR(254) NULL,
      EmailVerifiedAtUtc DATETIME2(0) NULL,
      IsRegistrationPending BIT NOT NULL CONSTRAINT DF_sec_AuthIdentity_IsRegistrationPending DEFAULT (0),
      FailedLoginCount INT NOT NULL CONSTRAINT DF_sec_AuthIdentity_FailedLoginCount DEFAULT (0),
      LastFailedLoginAtUtc DATETIME2(0) NULL,
      LastFailedLoginIp NVARCHAR(64) NULL,
      LockoutUntilUtc DATETIME2(0) NULL,
      LastLoginAtUtc DATETIME2(0) NULL,
      PasswordChangedAtUtc DATETIME2(0) NULL,
      CreatedAtUtc DATETIME2(0) NOT NULL CONSTRAINT DF_sec_AuthIdentity_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
      UpdatedAtUtc DATETIME2(0) NOT NULL CONSTRAINT DF_sec_AuthIdentity_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_sec_AuthIdentity PRIMARY KEY (UserCode),
      CONSTRAINT FK_sec_AuthIdentity_Usuarios
        FOREIGN KEY (UserCode) REFERENCES dbo.Usuarios(Cod_Usuario)
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_sec_AuthIdentity_EmailNormalized'
      AND object_id = OBJECT_ID(N'sec.AuthIdentity')
  )
  BEGIN
    CREATE UNIQUE INDEX UX_sec_AuthIdentity_EmailNormalized
      ON sec.AuthIdentity (EmailNormalized)
      WHERE EmailNormalized IS NOT NULL;
  END;

  IF OBJECT_ID(N'sec.AuthToken', N'U') IS NULL
  BEGIN
    CREATE TABLE sec.AuthToken (
      TokenId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      UserCode NVARCHAR(10) NOT NULL,
      TokenType VARCHAR(32) NOT NULL,
      TokenHash CHAR(64) NOT NULL,
      EmailNormalized NVARCHAR(254) NULL,
      ExpiresAtUtc DATETIME2(0) NOT NULL,
      ConsumedAtUtc DATETIME2(0) NULL,
      MetaIp NVARCHAR(64) NULL,
      MetaUserAgent NVARCHAR(256) NULL,
      CreatedAtUtc DATETIME2(0) NOT NULL CONSTRAINT DF_sec_AuthToken_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
      CONSTRAINT FK_sec_AuthToken_Usuarios
        FOREIGN KEY (UserCode) REFERENCES dbo.Usuarios(Cod_Usuario),
      CONSTRAINT CK_sec_AuthToken_Type
        CHECK (TokenType IN ('VERIFY_EMAIL', 'RESET_PASSWORD'))
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_sec_AuthToken_TokenHash'
      AND object_id = OBJECT_ID(N'sec.AuthToken')
  )
  BEGIN
    CREATE UNIQUE INDEX UX_sec_AuthToken_TokenHash
      ON sec.AuthToken (TokenHash);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_sec_AuthToken_UserCode_Type_Expires'
      AND object_id = OBJECT_ID(N'sec.AuthToken')
  )
  BEGIN
    CREATE INDEX IX_sec_AuthToken_UserCode_Type_Expires
      ON sec.AuthToken (UserCode, TokenType, ExpiresAtUtc, ConsumedAtUtc);
  END;

  IF OBJECT_ID(N'sec.AuthIdentity', N'U') IS NOT NULL
  BEGIN
    INSERT INTO sec.AuthIdentity (
      UserCode,
      EmailVerifiedAtUtc,
      IsRegistrationPending,
      FailedLoginCount,
      CreatedAtUtc,
      UpdatedAtUtc
    )
    SELECT
      u.Cod_Usuario,
      SYSUTCDATETIME(),
      0,
      0,
      SYSUTCDATETIME(),
      SYSUTCDATETIME()
    FROM dbo.Usuarios u
    LEFT JOIN sec.AuthIdentity ai
      ON ai.UserCode = u.Cod_Usuario
    WHERE ai.UserCode IS NULL;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;
  THROW;
END CATCH;
