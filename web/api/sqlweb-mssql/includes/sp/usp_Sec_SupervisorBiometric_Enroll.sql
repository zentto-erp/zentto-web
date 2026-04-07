-- usp_Sec_SupervisorBiometric_Enroll
-- Enrolls or re-activates a biometric credential for a supervisor.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_SupervisorBiometric_Enroll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_SupervisorBiometric_Enroll;
GO

CREATE PROCEDURE dbo.usp_Sec_SupervisorBiometric_Enroll
    @SupervisorUser   NVARCHAR(40),
    @CredentialHash   NCHAR(64),
    @CredentialId     NVARCHAR(512),
    @CredentialLabel  NVARCHAR(120) = NULL,
    @DeviceInfo       NVARCHAR(300) = NULL,
    @ActorUser        NVARCHAR(40)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

    IF EXISTS (
        SELECT 1
          FROM sec.SupervisorBiometricCredential
         WHERE SupervisorUserCode = @SupervisorUser
           AND CredentialHash     = @CredentialHash
    )
    BEGIN
        UPDATE sec.SupervisorBiometricCredential
           SET CredentialId      = @CredentialId,
               CredentialLabel   = @CredentialLabel,
               DeviceInfo        = @DeviceInfo,
               IsActive          = 1,
               UpdatedAtUtc      = @Now,
               UpdatedByUserCode = @ActorUser
         WHERE SupervisorUserCode = @SupervisorUser
           AND CredentialHash     = @CredentialHash;
    END
    ELSE
    BEGIN
        INSERT INTO sec.SupervisorBiometricCredential (
            SupervisorUserCode, CredentialHash, CredentialId,
            CredentialLabel, DeviceInfo, IsActive,
            LastValidatedAtUtc, CreatedAtUtc, UpdatedAtUtc,
            CreatedByUserCode, UpdatedByUserCode
        )
        VALUES (
            @SupervisorUser, @CredentialHash, @CredentialId,
            @CredentialLabel, @DeviceInfo, 1,
            NULL, @Now, @Now,
            @ActorUser, @ActorUser
        );
    END

    SELECT BiometricCredentialId
      FROM sec.SupervisorBiometricCredential
     WHERE SupervisorUserCode = @SupervisorUser
       AND CredentialHash     = @CredentialHash;
END
GO
