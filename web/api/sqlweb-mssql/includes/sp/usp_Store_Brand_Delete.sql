-- usp_Store_Brand_Delete

IF OBJECT_ID('dbo.usp_Store_Brand_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Brand_Delete;
GO

CREATE PROCEDURE dbo.usp_Store_Brand_Delete
    @CompanyId INT           = 1,
    @Code      NVARCHAR(20)  = NULL,
    @UserId    INT           = NULL,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @inUse INT;

    BEGIN TRY
        IF @Code IS NULL
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Código requerido'; RETURN; END

        SELECT @inUse = COUNT(*) FROM mstr.Product
         WHERE CompanyId = @CompanyId AND BrandCode = @Code AND IsDeleted = 0;

        IF @inUse > 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = CONCAT(N'No se puede eliminar: ', @inUse, N' productos usan esta marca');
            RETURN;
        END

        UPDATE mstr.Brand SET
            IsDeleted       = 1,
            IsActive        = 0,
            UpdatedAt       = @now,
            UpdatedByUserId = @UserId
         WHERE CompanyId = @CompanyId AND BrandCode = @Code;

        IF @@ROWCOUNT = 0
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Marca no encontrada'; RETURN; END

        SET @Resultado = 1; SET @Mensaje = N'Marca eliminada';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
