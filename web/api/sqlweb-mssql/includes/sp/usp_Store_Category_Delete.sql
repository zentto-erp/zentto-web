-- usp_Store_Category_Delete
-- Soft delete. Bloquea si hay productos asociados.

IF OBJECT_ID('dbo.usp_Store_Category_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Category_Delete;
GO

CREATE PROCEDURE dbo.usp_Store_Category_Delete
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
         WHERE CompanyId = @CompanyId AND CategoryCode = @Code AND IsDeleted = 0;

        IF @inUse > 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = CONCAT(N'No se puede eliminar: ', @inUse, N' productos usan esta categoría');
            RETURN;
        END

        UPDATE mstr.Category SET
            IsDeleted       = 1,
            IsActive        = 0,
            UpdatedAt       = @now,
            UpdatedByUserId = @UserId
         WHERE CompanyId = @CompanyId AND CategoryCode = @Code;

        IF @@ROWCOUNT = 0
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Categoría no encontrada'; RETURN; END

        SET @Resultado = 1; SET @Mensaje = N'Categoría eliminada';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
