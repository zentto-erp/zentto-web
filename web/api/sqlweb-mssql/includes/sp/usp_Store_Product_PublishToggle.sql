-- usp_Store_Product_PublishToggle
-- Alterna publicación del producto en el store (o setea explícitamente).

IF OBJECT_ID('dbo.usp_Store_Product_PublishToggle', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_PublishToggle;
GO

CREATE PROCEDURE dbo.usp_Store_Product_PublishToggle
    @CompanyId   INT           = 1,
    @Code        NVARCHAR(80)  = NULL,
    @Publish     BIT           = NULL,
    @UserId      INT           = NULL,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @IsPublished BIT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @target BIT;

    BEGIN TRY
        IF @Code IS NULL
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Código requerido'; SET @IsPublished = NULL; RETURN;
        END

        IF @Publish IS NULL
        BEGIN
            SELECT @target = CASE WHEN ISNULL(IsPublishedStore, 0) = 1 THEN 0 ELSE 1 END
              FROM mstr.Product
             WHERE CompanyId = @CompanyId AND ProductCode = @Code AND IsDeleted = 0;
        END
        ELSE
            SET @target = @Publish;

        IF @target IS NULL
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Producto no encontrado'; SET @IsPublished = NULL; RETURN;
        END

        UPDATE mstr.Product SET
            IsPublishedStore = @target,
            PublishedAt      = CASE
                                   WHEN @target = 1 AND PublishedAt IS NULL THEN @now
                                   WHEN @target = 0 THEN NULL
                                   ELSE PublishedAt
                               END,
            UpdatedAt        = @now,
            UpdatedByUserId  = @UserId
         WHERE CompanyId = @CompanyId AND ProductCode = @Code AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Producto no encontrado'; SET @IsPublished = NULL; RETURN;
        END

        SET @IsPublished = @target;
        SET @Resultado = 1;
        SET @Mensaje = CASE WHEN @target = 1 THEN N'Producto publicado' ELSE N'Producto despublicado' END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500); SET @IsPublished = NULL;
    END CATCH
END
GO
