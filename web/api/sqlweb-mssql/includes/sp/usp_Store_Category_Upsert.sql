-- usp_Store_Category_Upsert

IF OBJECT_ID('dbo.usp_Store_Category_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Category_Upsert;
GO

CREATE PROCEDURE dbo.usp_Store_Category_Upsert
    @CompanyId   INT           = 1,
    @Code        NVARCHAR(20)  = NULL,
    @Name        NVARCHAR(100) = NULL,
    @Description NVARCHAR(500) = NULL,
    @UserId      INT           = NULL,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @OutCode     NVARCHAR(20)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

    BEGIN TRY
        IF @Code IS NULL OR LTRIM(RTRIM(@Code)) = ''
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Código requerido'; SET @OutCode = NULL; RETURN; END
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Nombre requerido'; SET @OutCode = NULL; RETURN; END

        IF EXISTS (SELECT 1 FROM mstr.Category WHERE CompanyId = @CompanyId AND CategoryCode = @Code)
        BEGIN
            UPDATE mstr.Category SET
                CategoryName     = @Name,
                [Description]    = @Description,
                IsActive         = 1,
                IsDeleted        = 0,
                UpdatedAt        = @now,
                UpdatedByUserId  = @UserId
             WHERE CompanyId = @CompanyId AND CategoryCode = @Code;

            SET @Resultado = 1; SET @Mensaje = N'Categoría actualizada'; SET @OutCode = @Code;
        END
        ELSE
        BEGIN
            INSERT INTO mstr.Category (
                CompanyId, CategoryCode, CategoryName, [Description],
                IsActive, IsDeleted, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
            ) VALUES (
                @CompanyId, @Code, @Name, @Description, 1, 0, @now, @now, @UserId, @UserId
            );

            SET @Resultado = 1; SET @Mensaje = N'Categoría creada'; SET @OutCode = @Code;
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500); SET @OutCode = NULL;
    END CATCH
END
GO
