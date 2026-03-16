SET NOCOUNT ON;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.schemas
  WHERE name = N'sec'
)
BEGIN
  EXEC('CREATE SCHEMA sec');
END
GO

IF OBJECT_ID(N'sec.SupervisorBiometricCredential', N'U') IS NULL
BEGIN
  CREATE TABLE sec.SupervisorBiometricCredential (
    BiometricCredentialId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SupervisorUserCode NVARCHAR(10) NOT NULL,
    CredentialHash CHAR(64) NOT NULL,
    CredentialId NVARCHAR(512) NOT NULL,
    CredentialLabel NVARCHAR(120) NULL,
    DeviceInfo NVARCHAR(300) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_SupervisorBiometricCredential_IsActive DEFAULT(1),
    LastValidatedAtUtc DATETIME2(3) NULL,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_SupervisorBiometricCredential_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_SupervisorBiometricCredential_UpdatedAt DEFAULT(SYSUTCDATETIME()),
    CreatedByUserCode NVARCHAR(10) NULL,
    UpdatedByUserCode NVARCHAR(10) NULL,
    RowVer ROWVERSION NOT NULL,
    CONSTRAINT FK_SupervisorBiometricCredential_SupervisorUser
      FOREIGN KEY (SupervisorUserCode) REFERENCES sec.[User](UserCode)
  );
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'UX_SupervisorBiometricCredential_UserHash'
    AND object_id = OBJECT_ID(N'sec.SupervisorBiometricCredential')
)
BEGIN
  CREATE UNIQUE INDEX UX_SupervisorBiometricCredential_UserHash
    ON sec.SupervisorBiometricCredential (SupervisorUserCode, CredentialHash);
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'IX_SupervisorBiometricCredential_Active'
    AND object_id = OBJECT_ID(N'sec.SupervisorBiometricCredential')
)
BEGIN
  CREATE INDEX IX_SupervisorBiometricCredential_Active
    ON sec.SupervisorBiometricCredential (SupervisorUserCode, IsActive, LastValidatedAtUtc DESC);
END
GO
