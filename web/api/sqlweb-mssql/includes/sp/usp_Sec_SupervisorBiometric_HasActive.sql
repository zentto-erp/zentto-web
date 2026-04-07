-- usp_Sec_SupervisorBiometric_HasActive
-- Checks if a supervisor has an active biometric credential with the given hash.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_SupervisorBiometric_HasActive', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_SupervisorBiometric_HasActive;
GO

CREATE PROCEDURE dbo.usp_Sec_SupervisorBiometric_HasActive
    @SupervisorUser   NVARCHAR(40),
    @CredentialHash   NCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 BiometricCredentialId
      FROM sec.SupervisorBiometricCredential
     WHERE SupervisorUserCode = @SupervisorUser
       AND CredentialHash     = @CredentialHash
       AND IsActive           = 1;
END
GO
