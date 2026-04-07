-- usp_Sec_SupervisorBiometric_Deactivate
-- Deactivates a biometric credential for a supervisor.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_SupervisorBiometric_Deactivate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_SupervisorBiometric_Deactivate;
GO

CREATE PROCEDURE dbo.usp_Sec_SupervisorBiometric_Deactivate
    @SupervisorUser   NVARCHAR(40),
    @CredentialHash   NCHAR(64),
    @ActorUser        NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sec.SupervisorBiometricCredential
       SET IsActive          = 0,
           UpdatedAtUtc      = SYSUTCDATETIME(),
           UpdatedByUserCode = @ActorUser
     WHERE SupervisorUserCode = @SupervisorUser
       AND CredentialHash     = @CredentialHash
       AND IsActive           = 1;

    SELECT BiometricCredentialId
      FROM sec.SupervisorBiometricCredential
     WHERE SupervisorUserCode = @SupervisorUser
       AND CredentialHash     = @CredentialHash;
END
GO
