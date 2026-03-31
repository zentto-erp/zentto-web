-- usp_Sec_Role_Upsert
-- Create or update a role.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_Role_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_Role_Upsert;
GO

CREATE PROCEDURE dbo.usp_Sec_Role_Upsert
    @CompanyId  INT,
    @RoleId     INT          = NULL,
    @RoleCode   VARCHAR(50),
    @RoleName   NVARCHAR(100),
    @IsSystem   BIT          = 0,
    @IsActive   BIT          = 1,
    @Resultado  INT          OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @RoleId IS NOT NULL AND @RoleId > 0
    BEGIN
        UPDATE sec.[Role]
           SET RoleCode  = ISNULL(@RoleCode, RoleCode),
               RoleName  = ISNULL(@RoleName, RoleName),
               IsSystem  = ISNULL(@IsSystem, IsSystem),
               IsActive  = ISNULL(@IsActive, IsActive),
               UpdatedAt = GETUTCDATE()
         WHERE RoleId = @RoleId;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'Rol no encontrado';
            RETURN;
        END

        SET @Resultado = @RoleId;
        SET @Mensaje = N'Rol actualizado';
    END
    ELSE
    BEGIN
        INSERT INTO sec.[Role] (RoleCode, RoleName, IsSystem, IsActive)
        VALUES (@RoleCode, @RoleName, ISNULL(@IsSystem, 0), ISNULL(@IsActive, 1));

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = N'Rol creado con Id ' + CAST(@Resultado AS NVARCHAR(20));
    END
END
GO
