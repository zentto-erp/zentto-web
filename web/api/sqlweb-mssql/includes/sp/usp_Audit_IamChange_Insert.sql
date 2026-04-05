-- usp_Audit_IamChange_Insert
-- Records IAM changes (role/permission/license) for audit trail.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Audit_IamChange_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_IamChange_Insert;
GO

CREATE PROCEDURE dbo.usp_Audit_IamChange_Insert
    @CompanyId         INT,
    @ChangeType        VARCHAR(50),
    @EntityType        VARCHAR(50),
    @EntityId          VARCHAR(50)   = NULL,
    @OldValue          NVARCHAR(MAX) = NULL,
    @NewValue          NVARCHAR(MAX) = NULL,
    @ChangedByUserId   INT           = 0,
    @IpAddress         VARCHAR(50)   = NULL,
    @UserAgent         VARCHAR(500)  = NULL,
    @Resultado         INT           OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.IamChangeLog (
        CompanyId, ChangeType, EntityType, EntityId,
        OldValue, NewValue, ChangedByUserId,
        IpAddress, UserAgent, ChangedAt
    ) VALUES (
        @CompanyId, @ChangeType, @EntityType, @EntityId,
        @OldValue, @NewValue, @ChangedByUserId,
        @IpAddress, @UserAgent, GETUTCDATE()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'Cambio IAM registrado';
END
GO
