-- usp_Store_Product_Upsert
-- Crea o actualiza un producto del store con columnas SEO + publicación.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Store_Product_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_Upsert;
GO

CREATE PROCEDURE dbo.usp_Store_Product_Upsert
    @CompanyId        INT           = 1,
    @Code             NVARCHAR(80)   = NULL,
    @Name             NVARCHAR(250)  = NULL,
    @Category         NVARCHAR(50)   = NULL,
    @Brand            NVARCHAR(20)   = NULL,
    @Price            DECIMAL(18,2) = 0,
    @CompareAtPrice   DECIMAL(18,4) = NULL,
    @CostPrice        DECIMAL(18,2) = 0,
    @StockQty         DECIMAL(18,3) = 0,
    @ShortDescription NVARCHAR(500)  = NULL,
    @LongDescription  NVARCHAR(MAX)  = NULL,
    @MetaTitle        NVARCHAR(200)  = NULL,
    @MetaDescription  NVARCHAR(320)  = NULL,
    @Slug             NVARCHAR(200)  = NULL,
    @Barcode          NVARCHAR(50)   = NULL,
    @UnitCode         NVARCHAR(20)   = 'UND',
    @TaxRate          DECIMAL(9,4)  = 0,
    @WeightKg         DECIMAL(10,3) = NULL,
    @IsService        BIT           = 0,
    @IsPublished      BIT           = 0,
    @UserId           INT           = NULL,
    @Resultado        INT            OUTPUT,
    @Mensaje          NVARCHAR(500)  OUTPUT,
    @OutCode          NVARCHAR(80)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @slugTrim NVARCHAR(200) = NULLIF(LTRIM(RTRIM(ISNULL(@Slug, ''))), '');

    BEGIN TRY
        IF @Code IS NULL OR LTRIM(RTRIM(@Code)) = ''
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'El código del producto es requerido'; SET @OutCode = NULL;
            RETURN;
        END
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'El nombre del producto es requerido'; SET @OutCode = NULL;
            RETURN;
        END

        IF @slugTrim IS NOT NULL AND EXISTS (
            SELECT 1 FROM mstr.Product
             WHERE CompanyId = @CompanyId
               AND Slug = @slugTrim
               AND ProductCode <> @Code
               AND IsDeleted = 0
        )
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'El slug ya está en uso por otro producto'; SET @OutCode = NULL;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM mstr.Product WHERE CompanyId = @CompanyId AND ProductCode = @Code)
        BEGIN
            UPDATE mstr.Product SET
                ProductName      = @Name,
                CategoryCode     = @Category,
                BrandCode        = @Brand,
                SalesPrice       = ISNULL(@Price, 0),
                CompareAtPrice   = @CompareAtPrice,
                CostPrice        = ISNULL(@CostPrice, 0),
                StockQty         = ISNULL(@StockQty, 0),
                ShortDescription = @ShortDescription,
                LongDescription  = @LongDescription,
                MetaTitle        = @MetaTitle,
                MetaDescription  = @MetaDescription,
                Slug             = @slugTrim,
                BarCode          = @Barcode,
                UnitCode         = ISNULL(@UnitCode, 'UND'),
                DefaultTaxRate   = ISNULL(@TaxRate, 0),
                WeightKg         = @WeightKg,
                IsService        = ISNULL(@IsService, 0),
                IsPublishedStore = ISNULL(@IsPublished, 0),
                PublishedAt      = CASE
                                       WHEN @IsPublished = 1 AND PublishedAt IS NULL THEN @now
                                       WHEN @IsPublished = 0 THEN NULL
                                       ELSE PublishedAt
                                   END,
                IsActive         = 1,
                IsDeleted        = 0,
                UpdatedAt        = @now,
                UpdatedByUserId  = @UserId
             WHERE CompanyId = @CompanyId AND ProductCode = @Code;

            SET @Resultado = 1; SET @Mensaje = N'Producto actualizado'; SET @OutCode = @Code;
        END
        ELSE
        BEGIN
            INSERT INTO mstr.Product (
                CompanyId, ProductCode, ProductName, CategoryCode, BrandCode,
                SalesPrice, CompareAtPrice, CostPrice, StockQty,
                ShortDescription, LongDescription, MetaTitle, MetaDescription,
                Slug, BarCode, UnitCode, DefaultTaxRate, WeightKg,
                IsService, IsPublishedStore, PublishedAt, IsActive, IsDeleted,
                CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
            ) VALUES (
                @CompanyId, @Code, @Name, @Category, @Brand,
                ISNULL(@Price, 0), @CompareAtPrice, ISNULL(@CostPrice, 0), ISNULL(@StockQty, 0),
                @ShortDescription, @LongDescription, @MetaTitle, @MetaDescription,
                @slugTrim, @Barcode, ISNULL(@UnitCode, 'UND'), ISNULL(@TaxRate, 0), @WeightKg,
                ISNULL(@IsService, 0), ISNULL(@IsPublished, 0),
                CASE WHEN @IsPublished = 1 THEN @now ELSE NULL END,
                1, 0, @now, @now, @UserId, @UserId
            );

            SET @Resultado = 1; SET @Mensaje = N'Producto creado'; SET @OutCode = @Code;
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = LEFT(ERROR_MESSAGE(), 500);
        SET @OutCode   = NULL;
    END CATCH
END
GO
