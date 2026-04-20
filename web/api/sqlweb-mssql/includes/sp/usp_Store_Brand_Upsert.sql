-- usp_Store_Brand_Upsert

IF OBJECT_ID('dbo.usp_Store_Brand_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Brand_Upsert;
GO

CREATE PROCEDURE dbo.usp_Store_Brand_Upsert
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

        IF EXISTS (SELECT 1 FROM mstr.Brand WHERE CompanyId = @CompanyId AND BrandCode = @Code)
        BEGIN
            UPDATE mstr.Brand SET
                BrandName        = @Name,
                [Description]    = @Description,
                IsActive         = 1,
                IsDeleted        = 0,
                UpdatedAt        = @now,
                UpdatedByUserId  = @UserId
             WHERE CompanyId = @CompanyId AND BrandCode = @Code;

            SET @Resultado = 1; SET @Mensaje = N'Marca actualizada'; SET @OutCode = @Code;
        END
        ELSE
        BEGIN
            INSERT INTO mstr.Brand (
                CompanyId, BrandCode, BrandName, [Description],
                IsActive, IsDeleted, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
            ) VALUES (
                @CompanyId, @Code, @Name, @Description, 1, 0, @now, @now, @UserId, @UserId
            );

            SET @Resultado = 1; SET @Mensaje = N'Marca creada'; SET @OutCode = @Code;
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500); SET @OutCode = NULL;
    END CATCH
END
GO
