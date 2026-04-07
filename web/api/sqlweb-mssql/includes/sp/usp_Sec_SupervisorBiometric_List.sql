-- usp_Sec_SupervisorBiometric_List
-- Lists active biometric credentials, optionally filtered by supervisor.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_SupervisorBiometric_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_SupervisorBiometric_List;
GO

CREATE PROCEDURE dbo.usp_Sec_SupervisorBiometric_List
    @SupervisorUser   NVARCHAR(40) = ''
AS
BEGIN
    SET NOCOUNT ON;

    SELECT bc.BiometricCredentialId   AS biometricCredentialId,
           bc.SupervisorUserCode      AS supervisorUserCode,
           bc.CredentialId            AS credentialId,
           bc.CredentialLabel         AS credentialLabel,
           bc.DeviceInfo              AS deviceInfo,
           bc.IsActive                AS isActive,
           CONVERT(NVARCHAR(30), bc.LastValidatedAtUtc, 127) AS lastValidatedAtUtc
      FROM sec.SupervisorBiometricCredential bc
     WHERE bc.IsActive = 1
       AND (@SupervisorUser = '' OR bc.SupervisorUserCode = @SupervisorUser)
     ORDER BY bc.BiometricCredentialId DESC;
END
GO
