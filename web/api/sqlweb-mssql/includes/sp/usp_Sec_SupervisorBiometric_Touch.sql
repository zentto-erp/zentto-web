-- usp_Sec_SupervisorBiometric_Touch
-- Updates LastValidatedAtUtc for a biometric credential after successful validation.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_SupervisorBiometric_Touch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_SupervisorBiometric_Touch;
GO

CREATE PROCEDURE dbo.usp_Sec_SupervisorBiometric_Touch
    @SupervisorUser   NVARCHAR(40),
    @CredentialHash   NCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sec.SupervisorBiometricCredential
       SET LastValidatedAtUtc = SYSUTCDATETIME(),
           UpdatedAtUtc       = SYSUTCDATETIME()
     WHERE SupervisorUserCode = @SupervisorUser
       AND CredentialHash     = @CredentialHash
       AND IsActive           = 1;
END
GO
