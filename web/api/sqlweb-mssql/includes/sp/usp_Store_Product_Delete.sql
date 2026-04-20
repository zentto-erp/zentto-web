-- usp_Store_Product_Delete
-- Soft delete de producto (setea IsDeleted=1, IsPublishedStore=0).

IF OBJECT_ID('dbo.usp_Store_Product_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_Delete;
GO

CREATE PROCEDURE dbo.usp_Store_Product_Delete
    @CompanyId INT           = 1,
    @Code      NVARCHAR(80)  = NULL,
    @UserId    INT           = NULL,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

    BEGIN TRY
        IF @Code IS NULL
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Código requerido'; RETURN;
        END

        UPDATE mstr.Product SET
            IsDeleted        = 1,
            DeletedAt        = @now,
            DeletedByUserId  = @UserId,
            IsActive         = 0,
            IsPublishedStore = 0,
            UpdatedAt        = @now,
            UpdatedByUserId  = @UserId
         WHERE CompanyId = @CompanyId AND ProductCode = @Code AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Producto no encontrado o ya eliminado'; RETURN;
        END

        SET @Resultado = 1; SET @Mensaje = N'Producto eliminado';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
