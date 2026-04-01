-- usp_Sec_Role_Delete
-- Soft-delete a role (prevents system roles from deletion).
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_Role_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_Role_Delete;
GO

CREATE PROCEDURE dbo.usp_Sec_Role_Delete
    @RoleId    INT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @isSystem BIT;

    SELECT @isSystem = IsSystem
      FROM sec.[Role]
     WHERE RoleId = @RoleId;

    IF @isSystem IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'Rol no encontrado';
        RETURN;
    END

    IF @isSystem = 1
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'No se puede eliminar un rol de sistema';
        RETURN;
    END

    UPDATE sec.[Role]
       SET IsActive  = 0,
           UpdatedAt = GETUTCDATE()
     WHERE RoleId = @RoleId;

    SET @Resultado = 1;
    SET @Mensaje = N'Rol desactivado';
END
GO
