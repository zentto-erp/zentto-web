/*  ═══════════════════════════════════════════════════════════════
    usp_ecommerce.sql — Stored Procedures para Tienda Online
    Tablas: master.Product, master.Customer, master.Category,
            cfg.EntityImage, cfg.MediaAsset,
            doc.SalesDocument, doc.SalesDocumentLine, sec.Users,
            store.ProductReview
    ═══════════════════════════════════════════════════════════════ */

USE [DatqBoxWeb];
GO

-- ───────────────────────────────────────────────────────
-- 0. Esquema y tabla de reseñas
-- ───────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'store')
    EXEC('CREATE SCHEMA store');
GO

IF OBJECT_ID('store.ProductReview', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductReview (
        ReviewId       INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId      INT NOT NULL DEFAULT 1,
        ProductCode    NVARCHAR(80) NOT NULL,
        Rating         INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
        Title          NVARCHAR(200) NULL,
        Comment        NVARCHAR(2000) NOT NULL,
        ReviewerName   NVARCHAR(200) NOT NULL DEFAULT N'Cliente',
        ReviewerEmail  NVARCHAR(150) NULL,
        IsVerified     BIT NOT NULL DEFAULT 0,
        IsApproved     BIT NOT NULL DEFAULT 1,
        IsDeleted      BIT NOT NULL DEFAULT 0,
        CreatedAt      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE NONCLUSTERED INDEX IX_ProductReview_Product
        ON store.ProductReview (CompanyId, ProductCode, IsDeleted, IsApproved)
        INCLUDE (Rating);
END;
GO

-- ───────────────────────────────────────────────────────
-- 0b. Columnas adicionales en master.Product (detalle estilo Amazon)
-- ───────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'ShortDescription')
    ALTER TABLE [master].Product ADD ShortDescription NVARCHAR(500) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'LongDescription')
    ALTER TABLE [master].Product ADD LongDescription NVARCHAR(MAX) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'BrandCode')
    ALTER TABLE [master].Product ADD BrandCode NVARCHAR(20) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'BarCode')
    ALTER TABLE [master].Product ADD BarCode NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'CompareAtPrice')
    ALTER TABLE [master].Product ADD CompareAtPrice DECIMAL(18,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'WeightKg')
    ALTER TABLE [master].Product ADD WeightKg DECIMAL(10,3) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'WidthCm')
    ALTER TABLE [master].Product ADD WidthCm DECIMAL(10,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'HeightCm')
    ALTER TABLE [master].Product ADD HeightCm DECIMAL(10,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'DepthCm')
    ALTER TABLE [master].Product ADD DepthCm DECIMAL(10,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'WarrantyMonths')
    ALTER TABLE [master].Product ADD WarrantyMonths INT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'Slug')
    ALTER TABLE [master].Product ADD Slug NVARCHAR(200) NULL;
GO

-- ───────────────────────────────────────────────────────
-- 0c. Tabla store.ProductHighlight (bullets "Acerca de este artículo")
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('store.ProductHighlight', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductHighlight (
        HighlightId    INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId      INT NOT NULL DEFAULT 1,
        ProductCode    NVARCHAR(80) NOT NULL,
        SortOrder      INT NOT NULL DEFAULT 0,
        HighlightText  NVARCHAR(500) NOT NULL,
        IsActive       BIT NOT NULL DEFAULT 1,
        CreatedAt      DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE NONCLUSTERED INDEX IX_ProductHighlight_Product
        ON store.ProductHighlight (CompanyId, ProductCode, IsActive)
        INCLUDE (SortOrder, HighlightText);
    PRINT 'Created table store.ProductHighlight';
END;
GO

-- ───────────────────────────────────────────────────────
-- 0d. Tabla store.ProductSpec (especificaciones técnicas key-value)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('store.ProductSpec', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductSpec (
        SpecId         INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId      INT NOT NULL DEFAULT 1,
        ProductCode    NVARCHAR(80) NOT NULL,
        SpecGroup      NVARCHAR(100) NOT NULL DEFAULT N'General',
        SpecKey        NVARCHAR(100) NOT NULL,
        SpecValue      NVARCHAR(500) NOT NULL,
        SortOrder      INT NOT NULL DEFAULT 0,
        IsActive       BIT NOT NULL DEFAULT 1,
        CreatedAt      DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE NONCLUSTERED INDEX IX_ProductSpec_Product
        ON store.ProductSpec (CompanyId, ProductCode, IsActive)
        INCLUDE (SpecGroup, SpecKey, SpecValue, SortOrder);
    PRINT 'Created table store.ProductSpec';
END;
GO

-- ───────────────────────────────────────────────────────
-- 1. Catálogo público de productos (con rating)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Product_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Product_List;
GO
CREATE PROCEDURE dbo.usp_Store_Product_List
    @CompanyId   INT           = 1,
    @BranchId    INT           = 1,
    @Search      NVARCHAR(200) = NULL,
    @Category    NVARCHAR(100) = NULL,
    @Brand       NVARCHAR(100) = NULL,
    @PriceMin    DECIMAL(18,2) = NULL,
    @PriceMax    DECIMAL(18,2) = NULL,
    @MinRating   INT           = NULL,      -- filtro por rating minimo (1-5)
    @InStockOnly BIT           = 1,         -- 1=solo en stock, 0=todos
    @SortBy      NVARCHAR(30)  = N'name',   -- name, price_asc, price_desc, rating, newest, bestseller
    @Page        INT           = 1,
    @Limit       INT           = 24,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;
    DECLARE @SearchPattern NVARCHAR(202) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> '' THEN '%' + LTRIM(RTRIM(@Search)) + '%' ELSE NULL END;

    -- Usar tabla temporal para filtrar una vez, contar y paginar
    CREATE TABLE #Products (
        RowNum            INT IDENTITY(1,1),
        ProductId         BIGINT,
        ProductCode       NVARCHAR(80),
        ProductName       NVARCHAR(250),
        ShortDescription  NVARCHAR(500),
        CategoryCode      NVARCHAR(100),
        CategoryName      NVARCHAR(200),
        BrandCode         NVARCHAR(20),
        BrandName         NVARCHAR(200),
        SalesPrice        DECIMAL(18,2),
        CompareAtPrice    DECIMAL(18,2),
        StockQty          DECIMAL(18,4),
        IsService         BIT,
        TaxRate           DECIMAL(18,6),
        ImageUrl          NVARCHAR(500),
        AvgRating         FLOAT,
        ReviewCount       INT
    );

    INSERT INTO #Products (ProductId, ProductCode, ProductName, ShortDescription, CategoryCode, CategoryName,
        BrandCode, BrandName, SalesPrice, CompareAtPrice, StockQty, IsService, TaxRate, ImageUrl, AvgRating, ReviewCount)
    SELECT
        p.ProductId,
        p.ProductCode,
        p.ProductName,
        p.ShortDescription,
        p.CategoryCode,
        c.CategoryName,
        p.BrandCode,
        b.BrandName,
        p.SalesPrice,
        p.CompareAtPrice,
        p.StockQty,
        p.IsService,
        CASE WHEN p.DefaultTaxRate > 1 THEN p.DefaultTaxRate / 100.0 ELSE ISNULL(p.DefaultTaxRate, 0) END,
        img.PublicUrl,
        ISNULL(rv.AvgRating, 0),
        ISNULL(rv.ReviewCount, 0)
    FROM [master].Product p
    LEFT JOIN [master].Category c ON c.CategoryCode = p.CategoryCode AND c.CompanyId = p.CompanyId AND c.IsDeleted = 0
    LEFT JOIN [master].Brand b ON b.BrandCode = p.BrandCode AND b.CompanyId = p.CompanyId AND b.IsDeleted = 0
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId   = p.CompanyId
          AND ei.BranchId    = @BranchId
          AND ei.EntityType  = N'MASTER_PRODUCT'
          AND ei.EntityId    = p.ProductId
          AND ei.IsDeleted   = 0
          AND ei.IsActive    = 1
          AND ma.IsDeleted   = 0
          AND ma.IsActive    = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    OUTER APPLY (
        SELECT
            AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
            COUNT(*) AS ReviewCount
        FROM store.ProductReview r
        WHERE r.CompanyId = p.CompanyId
          AND r.ProductCode = p.ProductCode
          AND r.IsDeleted = 0
          AND r.IsApproved = 1
    ) rv
    WHERE p.CompanyId  = @CompanyId
      AND p.IsDeleted  = 0
      AND p.IsActive   = 1
      AND (@InStockOnly = 0 OR p.StockQty > 0 OR p.IsService = 1)
      AND (@SearchPattern IS NULL OR p.ProductCode LIKE @SearchPattern OR p.ProductName LIKE @SearchPattern
           OR p.CategoryCode LIKE @SearchPattern)
      AND (@Category IS NULL OR p.CategoryCode = @Category)
      AND (@Brand IS NULL OR p.BrandCode = @Brand)
      AND (@PriceMin IS NULL OR p.SalesPrice >= @PriceMin)
      AND (@PriceMax IS NULL OR p.SalesPrice <= @PriceMax)
      AND (@MinRating IS NULL OR ISNULL(rv.AvgRating, 0) >= @MinRating);

    SELECT @TotalCount = COUNT(*) FROM #Products;

    -- Paginar con orden dinámico
    SELECT
        ProductId         AS id,
        ProductCode       AS code,
        ProductName       AS name,
        ISNULL(ShortDescription, ProductName) AS fullDescription,
        ShortDescription  AS shortDescription,
        CategoryCode      AS category,
        CategoryName      AS categoryName,
        BrandCode         AS brandCode,
        BrandName         AS brandName,
        SalesPrice        AS price,
        CompareAtPrice    AS compareAtPrice,
        StockQty          AS stock,
        IsService         AS isService,
        TaxRate           AS taxRate,
        ImageUrl          AS imageUrl,
        AvgRating         AS avgRating,
        ReviewCount       AS reviewCount
    FROM #Products
    ORDER BY
        CASE WHEN @SortBy = N'name'       THEN ProductName END ASC,
        CASE WHEN @SortBy = N'price_asc'  THEN SalesPrice  END ASC,
        CASE WHEN @SortBy = N'price_desc' THEN SalesPrice  END DESC,
        CASE WHEN @SortBy = N'rating'     THEN AvgRating   END DESC,
        CASE WHEN @SortBy = N'newest'     THEN ProductId   END DESC,
        CASE WHEN @SortBy = N'bestseller' THEN ReviewCount END DESC,
        ProductName ASC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    DROP TABLE #Products;
END;
GO

-- ───────────────────────────────────────────────────────
-- 2. Detalle de producto con imágenes
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Product_GetByCode', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Product_GetByCode;
GO
CREATE PROCEDURE dbo.usp_Store_Product_GetByCode
    @CompanyId  INT           = 1,
    @BranchId   INT           = 1,
    @Code       NVARCHAR(80)
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Producto con rating + campos extendidos + variantes/industria
    SELECT TOP 1
        p.ProductId       AS id,
        p.ProductCode     AS code,
        p.ProductName     AS name,
        ISNULL(p.ShortDescription, p.ProductName) AS fullDescription,
        p.ShortDescription AS shortDescription,
        p.LongDescription  AS longDescription,
        p.CategoryCode    AS category,
        c.CategoryName    AS categoryName,
        p.BrandCode       AS brandCode,
        b.BrandName       AS brandName,
        p.SalesPrice      AS price,
        p.CompareAtPrice  AS compareAtPrice,
        p.CostPrice       AS costPrice,
        p.StockQty        AS stock,
        p.IsService       AS isService,
        p.UnitCode        AS unitCode,
        CASE WHEN p.DefaultTaxRate > 1 THEN p.DefaultTaxRate / 100.0 ELSE ISNULL(p.DefaultTaxRate, 0) END AS taxRate,
        p.WeightKg        AS weightKg,
        p.WidthCm         AS widthCm,
        p.HeightCm        AS heightCm,
        p.DepthCm         AS depthCm,
        p.WarrantyMonths  AS warrantyMonths,
        p.BarCode         AS barCode,
        p.Slug            AS slug,
        ISNULL(p.IsVariantParent, 0)  AS isVariantParent,
        p.ParentProductCode           AS parentProductCode,
        p.IndustryTemplateCode        AS industryTemplateCode,
        it.TemplateName               AS industryTemplateName,
        ISNULL(rv.AvgRating, 0) AS avgRating,
        ISNULL(rv.ReviewCount, 0) AS reviewCount
    FROM [master].Product p
    LEFT JOIN [master].Category c ON c.CategoryCode = p.CategoryCode AND c.CompanyId = p.CompanyId AND c.IsDeleted = 0
    LEFT JOIN [master].Brand b ON b.BrandCode = p.BrandCode AND b.CompanyId = p.CompanyId AND b.IsDeleted = 0
    LEFT JOIN store.IndustryTemplate it ON it.TemplateCode = p.IndustryTemplateCode AND it.CompanyId = p.CompanyId AND it.IsDeleted = 0
    OUTER APPLY (
        SELECT
            AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
            COUNT(*) AS ReviewCount
        FROM store.ProductReview r
        WHERE r.CompanyId = p.CompanyId
          AND r.ProductCode = p.ProductCode
          AND r.IsDeleted = 0
          AND r.IsApproved = 1
    ) rv
    WHERE p.CompanyId  = @CompanyId
      AND p.IsDeleted  = 0
      AND p.IsActive   = 1
      AND p.ProductCode = @Code;

    -- Recordset 2: Imágenes del producto
    SELECT
        ma.MediaAssetId   AS id,
        ma.PublicUrl      AS url,
        ei.RoleCode       AS role,
        ei.IsPrimary      AS isPrimary,
        ei.SortOrder      AS sortOrder,
        ma.AltText        AS altText
    FROM cfg.EntityImage ei
    INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
    INNER JOIN [master].Product p ON p.ProductId = ei.EntityId AND p.CompanyId = ei.CompanyId
    WHERE ei.CompanyId   = @CompanyId
      AND ei.BranchId    = @BranchId
      AND ei.EntityType  = N'MASTER_PRODUCT'
      AND p.ProductCode  = @Code
      AND ei.IsDeleted   = 0
      AND ei.IsActive    = 1
      AND ma.IsDeleted   = 0
      AND ma.IsActive    = 1
    ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder;

    -- Recordset 3: Highlights (bullets "Acerca de este artículo")
    SELECT
        h.HighlightText AS text
    FROM store.ProductHighlight h
    WHERE h.CompanyId   = @CompanyId
      AND h.ProductCode = @Code
      AND h.IsActive    = 1
    ORDER BY h.SortOrder, h.HighlightId;

    -- Recordset 4: Especificaciones técnicas
    SELECT
        s.SpecGroup AS [group],
        s.SpecKey   AS [key],
        s.SpecValue AS value
    FROM store.ProductSpec s
    WHERE s.CompanyId   = @CompanyId
      AND s.ProductCode = @Code
      AND s.IsActive    = 1
    ORDER BY s.SpecGroup, s.SortOrder, s.SpecId;

    -- Recordset 5: Variantes (si IsVariantParent = 1)
    SELECT
        pv.ProductVariantId   AS variantId,
        pv.VariantProductCode AS code,
        vp.ProductName        AS name,
        ISNULL(pv.SKU, pv.VariantProductCode) AS sku,
        vp.SalesPrice         AS price,
        pv.PriceDelta         AS priceDelta,
        ISNULL(pv.StockOverride, vp.StockQty) AS stock,
        pv.IsDefault          AS isDefault,
        pv.SortOrder          AS sortOrder
    FROM store.ProductVariant pv
    INNER JOIN [master].Product vp ON vp.ProductCode = pv.VariantProductCode AND vp.CompanyId = pv.CompanyId
    WHERE pv.CompanyId          = @CompanyId
      AND pv.ParentProductCode  = @Code
      AND pv.IsDeleted = 0
      AND pv.IsActive  = 1
      AND vp.IsDeleted = 0
      AND vp.IsActive  = 1
    ORDER BY pv.SortOrder, pv.ProductVariantId;

    -- Recordset 6: Opciones de variante (para cada variante del recordset 5)
    SELECT
        pv.VariantProductCode AS code,
        vg.GroupCode          AS groupCode,
        vg.GroupName          AS groupName,
        vg.DisplayType        AS displayType,
        vo.OptionCode         AS optionCode,
        vo.OptionLabel        AS optionLabel,
        vo.ColorHex           AS colorHex,
        vo.ImageUrl           AS optionImageUrl
    FROM store.ProductVariantOptionValue pvov
    INNER JOIN store.ProductVariant pv ON pv.ProductVariantId = pvov.ProductVariantId
    INNER JOIN store.ProductVariantOption vo ON vo.VariantOptionId = pvov.VariantOptionId
    INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId
    WHERE pv.CompanyId          = @CompanyId
      AND pv.ParentProductCode  = @Code
      AND pv.IsDeleted = 0
      AND pv.IsActive  = 1
    ORDER BY vg.SortOrder, vo.SortOrder;

    -- Recordset 7: Atributos de industria del producto
    SELECT
        pa.AttributeKey       AS [key],
        ita.AttributeLabel    AS label,
        ita.DataType          AS dataType,
        ita.DisplayGroup      AS displayGroup,
        pa.ValueText          AS valueText,
        pa.ValueNumber        AS valueNumber,
        pa.ValueDate          AS valueDate,
        pa.ValueBoolean       AS valueBoolean,
        ita.SortOrder         AS sortOrder
    FROM store.ProductAttribute pa
    INNER JOIN store.IndustryTemplateAttribute ita
        ON ita.TemplateCode  = pa.TemplateCode
       AND ita.AttributeKey  = pa.AttributeKey
       AND ita.CompanyId     = pa.CompanyId
       AND ita.IsDeleted     = 0
       AND ita.IsActive      = 1
    WHERE pa.CompanyId   = @CompanyId
      AND pa.ProductCode = @Code
      AND pa.IsDeleted   = 0
      AND pa.IsActive    = 1
    ORDER BY ita.DisplayGroup, ita.SortOrder;
END;
GO

-- ───────────────────────────────────────────────────────
-- 3. Categorías con conteo de productos
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Category_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Category_List;
GO
CREATE PROCEDURE dbo.usp_Store_Category_List
    @CompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CategoryCode AS code,
        c.CategoryName AS name,
        COUNT(p.ProductId) AS productCount
    FROM [master].Category c
    LEFT JOIN [master].Product p
        ON p.CategoryCode = c.CategoryCode
        AND p.CompanyId = c.CompanyId
        AND p.IsDeleted = 0
        AND p.IsActive = 1
        AND (p.StockQty > 0 OR p.IsService = 1)
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND c.IsActive = 1
    GROUP BY c.CategoryCode, c.CategoryName
    HAVING COUNT(p.ProductId) > 0
    ORDER BY c.CategoryName;
END;
GO

-- ───────────────────────────────────────────────────────
-- 4. Marcas (basado en tabla Brand — sin filtro directo en Product)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Brand_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Brand_List;
GO
CREATE PROCEDURE dbo.usp_Store_Brand_List
    @CompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BrandCode  AS code,
        b.BrandName  AS name,
        0            AS productCount
    FROM [master].Brand b
    WHERE b.CompanyId = @CompanyId
      AND b.IsDeleted = 0
      AND b.IsActive  = 1
    ORDER BY b.BrandName;
END;
GO

-- ───────────────────────────────────────────────────────
-- 5. Buscar o crear cliente por email
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Customer_FindOrCreate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Customer_FindOrCreate;
GO
CREATE PROCEDURE dbo.usp_Store_Customer_FindOrCreate
    @CompanyId    INT            = 1,
    @Email        NVARCHAR(150),
    @Name         NVARCHAR(200),
    @Phone        NVARCHAR(40)   = NULL,
    @Address      NVARCHAR(250)  = NULL,
    @FiscalId     NVARCHAR(30)   = NULL,
    @CustomerCode NVARCHAR(24)   OUTPUT,
    @Resultado    INT            OUTPUT,
    @Mensaje      NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 @CustomerCode = CustomerCode
    FROM [master].Customer
    WHERE CompanyId = @CompanyId AND Email = @Email AND IsDeleted = 0;

    IF @CustomerCode IS NOT NULL
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje = N'Cliente encontrado';
        RETURN;
    END;

    DECLARE @Seq INT;
    SELECT @Seq = ISNULL(MAX(CAST(REPLACE(CustomerCode, 'ECOM-', '') AS INT)), 0) + 1
    FROM [master].Customer
    WHERE CompanyId = @CompanyId AND CustomerCode LIKE 'ECOM-%';

    SET @CustomerCode = 'ECOM-' + RIGHT('000000' + CAST(@Seq AS NVARCHAR(6)), 6);

    INSERT INTO [master].Customer (
        CompanyId, CustomerCode, CustomerName, Email, Phone, AddressLine, FiscalId,
        IsActive, IsDeleted, CreatedAt, UpdatedAt
    ) VALUES (
        @CompanyId, @CustomerCode, @Name, @Email, @Phone, @Address,
        ISNULL(@FiscalId, N''),
        1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'Cliente creado';
END;
GO

-- ───────────────────────────────────────────────────────
-- 6. Registro de cuenta de cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Customer_Register', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Customer_Register;
GO
CREATE PROCEDURE dbo.usp_Store_Customer_Register
    @CompanyId    INT            = 1,
    @Email        NVARCHAR(150),
    @Name         NVARCHAR(200),
    @PasswordHash NVARCHAR(500),
    @Phone        NVARCHAR(40)   = NULL,
    @Address      NVARCHAR(250)  = NULL,
    @FiscalId     NVARCHAR(30)   = NULL,
    @Resultado    INT            OUTPUT,
    @Mensaje      NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM sec.Users WHERE Email = @Email AND IsDeleted = 0)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Ya existe una cuenta con este email';
        RETURN;
    END;

    DECLARE @CustomerCode NVARCHAR(24);
    DECLARE @R INT, @M NVARCHAR(500);
    EXEC dbo.usp_Store_Customer_FindOrCreate
        @CompanyId = @CompanyId, @Email = @Email, @Name = @Name,
        @Phone = @Phone, @Address = @Address, @FiscalId = @FiscalId,
        @CustomerCode = @CustomerCode OUTPUT, @Resultado = @R OUTPUT, @Mensaje = @M OUTPUT;

    INSERT INTO sec.Users (
        CompanyId, UserName, Email, PasswordHash, DisplayName,
        IsAdmin, IsActive, IsDeleted, Role, CreatedAt
    ) VALUES (
        @CompanyId, @Email, @Email, @PasswordHash, @Name,
        0, 1, 0, N'customer', SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'Cuenta creada exitosamente';
END;
GO

-- ───────────────────────────────────────────────────────
-- 7. Login de cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Customer_Login', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Customer_Login;
GO
CREATE PROCEDURE dbo.usp_Store_Customer_Login
    @Email NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        u.UserId, u.Email, u.DisplayName AS displayName, u.PasswordHash AS passwordHash, u.IsActive AS isActive,
        c.CustomerCode AS customerCode, c.CustomerName AS customerName,
        c.Phone AS phone, c.AddressLine AS address, c.FiscalId AS fiscalId
    FROM sec.Users u
    LEFT JOIN [master].Customer c ON c.Email = u.Email AND c.CompanyId = u.CompanyId AND c.IsDeleted = 0
    WHERE u.Email = @Email AND u.IsDeleted = 0 AND u.Role = N'customer';
END;
GO

-- ───────────────────────────────────────────────────────
-- 8. Crear pedido ecommerce
-- SQL Server 2012: usa XML en lugar de OPENJSON
-- doc.SalesDocument NO tiene CompanyId/BranchId
-- doc.SalesDocumentLine NO tiene CompanyId/BranchId/OperationType
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Order_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Order_Create;
GO
CREATE PROCEDURE dbo.usp_Store_Order_Create
    @CompanyId          INT             = 1,
    @BranchId           INT             = 1,
    @CustomerCode       NVARCHAR(24),
    @CustomerName       NVARCHAR(200),
    @CustomerEmail      NVARCHAR(150),
    @FiscalId           NVARCHAR(30)    = NULL,
    @Phone              NVARCHAR(40)    = NULL,
    @Address            NVARCHAR(250)   = NULL,
    @Notes              NVARCHAR(500)   = NULL,
    @ItemsXml           NVARCHAR(MAX),
    @AddressId          INT             = NULL,
    @PaymentMethodId    INT             = NULL,
    @PaymentMethodType  NVARCHAR(30)    = NULL,
    @OrderNumber        NVARCHAR(60)    OUTPUT,
    @OrderToken         NVARCHAR(100)   OUTPUT,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @xml XML = @ItemsXml;

        -- Parsear items XML a tabla temporal
        DECLARE @Items TABLE (
            RowNum       INT IDENTITY(1,1),
            productCode  NVARCHAR(80),
            productName  NVARCHAR(250),
            quantity     DECIMAL(18,3),
            unitPrice    DECIMAL(18,2),
            taxRate      DECIMAL(9,4),
            subtotal     DECIMAL(18,2),
            taxAmount    DECIMAL(18,2)
        );

        INSERT INTO @Items (productCode, productName, quantity, unitPrice, taxRate, subtotal, taxAmount)
        SELECT
            x.value('@pc', 'NVARCHAR(80)'),
            x.value('@pn', 'NVARCHAR(250)'),
            x.value('@qty', 'DECIMAL(18,3)'),
            x.value('@up', 'DECIMAL(18,2)'),
            x.value('@tr', 'DECIMAL(9,4)'),
            x.value('@st', 'DECIMAL(18,2)'),
            x.value('@ta', 'DECIMAL(18,2)')
        FROM @xml.nodes('/items/i') AS t(x);

        -- Generar número de pedido
        DECLARE @Today NVARCHAR(8) = CONVERT(NVARCHAR(8), GETDATE(), 112);
        DECLARE @Seq INT;
        SELECT @Seq = ISNULL(MAX(
            CASE WHEN ISNUMERIC(RIGHT(DocumentNumber, 4)) = 1
                 THEN CAST(RIGHT(DocumentNumber, 4) AS INT) ELSE 0 END
        ), 0) + 1
        FROM doc.SalesDocument
        WHERE OperationType = N'PEDIDO' AND DocumentNumber LIKE N'ECOM-' + @Today + '-%';

        SET @OrderNumber = N'ECOM-' + @Today + '-' + RIGHT('0000' + CAST(@Seq AS NVARCHAR(4)), 4);
        SET @OrderToken = LOWER(REPLACE(CAST(NEWID() AS NVARCHAR(36)), '-', ''));

        -- Calcular totales
        DECLARE @TotalSub DECIMAL(18,2), @TotalTax DECIMAL(18,2);
        SELECT @TotalSub = SUM(subtotal), @TotalTax = SUM(taxAmount) FROM @Items;

        -- Insertar cabecera
        INSERT INTO doc.SalesDocument (
            DocumentNumber, SerialType, OperationType,
            CustomerCode, CustomerName, FiscalId,
            IssueDate, DocumentTime,
            Subtotal, TaxableAmount, ExemptAmount, TaxAmount, TotalAmount, DiscountAmount,
            IsVoided, IsCanceled, IsInvoiced, IsDelivered,
            Notes, CurrencyCode, ExchangeRate,
            CreatedAt, UpdatedAt, IsDeleted
        ) VALUES (
            @OrderNumber, N'ECOM', N'PEDIDO',
            @CustomerCode, @CustomerName, ISNULL(@FiscalId, N''),
            CAST(GETDATE() AS DATE), CONVERT(NVARCHAR(8), GETDATE(), 108),
            @TotalSub, @TotalSub, 0, @TotalTax, @TotalSub + @TotalTax, 0,
            0, N'N', N'N', N'N',
            ISNULL(@Notes, N'') + N' | token=' + @OrderToken
                + CASE WHEN @AddressId IS NOT NULL THEN N' | addressId=' + CAST(@AddressId AS NVARCHAR(10)) ELSE N'' END
                + CASE WHEN @PaymentMethodId IS NOT NULL THEN N' | paymentMethodId=' + CAST(@PaymentMethodId AS NVARCHAR(10)) ELSE N'' END
                + CASE WHEN @PaymentMethodType IS NOT NULL THEN N' | paymentType=' + @PaymentMethodType ELSE N'' END,
            N'USD', 1.0,
            SYSUTCDATETIME(), SYSUTCDATETIME(), 0
        );

        -- Insertar líneas de detalle
        INSERT INTO doc.SalesDocumentLine (
            DocumentNumber, SerialType, DocumentType, LineNumber,
            ProductCode, Description, Quantity, UnitPrice, DiscountUnitPrice, UnitCost,
            Subtotal, DiscountAmount, LineTotal, TaxRate, TaxAmount, IsVoided,
            CreatedAt, UpdatedAt, IsDeleted
        )
        SELECT
            @OrderNumber, N'ECOM', N'PEDIDO', d.RowNum,
            d.productCode, d.productName, d.quantity, d.unitPrice, d.unitPrice, 0,
            d.subtotal, 0, d.subtotal + d.taxAmount, d.taxRate, d.taxAmount, 0,
            SYSUTCDATETIME(), SYSUTCDATETIME(), 0
        FROM @Items d;

        -- Descontar stock
        UPDATE p SET p.StockQty = p.StockQty - d.qty
        FROM [master].Product p
        INNER JOIN (
            SELECT productCode, SUM(quantity) AS qty FROM @Items GROUP BY productCode
        ) d ON d.productCode = p.ProductCode AND p.CompanyId = @CompanyId;

        COMMIT TRANSACTION;
        SET @Resultado = 1;
        SET @Mensaje = N'Pedido creado exitosamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        SET @OrderNumber = NULL;
        SET @OrderToken = NULL;
    END CATCH;
END;
GO

-- ───────────────────────────────────────────────────────
-- 9. Historial de pedidos
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Order_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Order_List;
GO
CREATE PROCEDURE dbo.usp_Store_Order_List
    @CompanyId INT = 1, @CustomerCode NVARCHAR(24),
    @Page INT = 1, @Limit INT = 20, @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*) FROM doc.SalesDocument
    WHERE OperationType = N'PEDIDO' AND SerialType = N'ECOM'
      AND CustomerCode = @CustomerCode AND IsVoided = 0;

    SELECT DocumentNumber AS orderNumber, IssueDate AS orderDate, CustomerName AS customerName,
        Subtotal AS subtotal, TaxAmount AS taxAmount, TotalAmount AS totalAmount,
        IsInvoiced AS isInvoiced, IsDelivered AS isDelivered, Notes AS notes
    FROM doc.SalesDocument
    WHERE OperationType = N'PEDIDO' AND SerialType = N'ECOM'
      AND CustomerCode = @CustomerCode AND IsVoided = 0
    ORDER BY IssueDate DESC, DocumentNumber DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ───────────────────────────────────────────────────────
-- 10. Detalle de pedido por número
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Order_GetByNumber', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Order_GetByNumber;
GO
CREATE PROCEDURE dbo.usp_Store_Order_GetByNumber
    @CompanyId INT = 1, @OrderNumber NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 DocumentNumber AS orderNumber, IssueDate AS orderDate,
        CustomerCode AS customerCode, CustomerName AS customerName, FiscalId AS fiscalId,
        Subtotal AS subtotal, TaxAmount AS taxAmount, TotalAmount AS totalAmount,
        DiscountAmount AS discountAmount, IsInvoiced AS isInvoiced,
        IsDelivered AS isDelivered, Notes AS notes, CreatedAt AS createdAt
    FROM doc.SalesDocument
    WHERE OperationType = N'PEDIDO' AND DocumentNumber = @OrderNumber;

    SELECT LineNumber AS lineNumber, ProductCode AS productCode, Description AS productName,
        Quantity AS quantity, UnitPrice AS unitPrice, Subtotal AS subtotal,
        TaxRate AS taxRate, TaxAmount AS taxAmount, LineTotal AS lineTotal
    FROM doc.SalesDocumentLine
    WHERE DocumentNumber = @OrderNumber AND SerialType = N'ECOM' AND IsVoided = 0
    ORDER BY LineNumber;
END;
GO

-- ───────────────────────────────────────────────────────
-- 11. Obtener pedido por token
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Order_GetByToken', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Order_GetByToken;
GO
CREATE PROCEDURE dbo.usp_Store_Order_GetByToken
    @CompanyId INT = 1, @Token NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OrderNumber NVARCHAR(60);
    SELECT TOP 1 @OrderNumber = DocumentNumber FROM doc.SalesDocument
    WHERE OperationType = N'PEDIDO' AND SerialType = N'ECOM'
      AND Notes LIKE N'%token=' + @Token + '%';
    IF @OrderNumber IS NOT NULL
        EXEC dbo.usp_Store_Order_GetByNumber @CompanyId = @CompanyId, @OrderNumber = @OrderNumber;
END;
GO

-- ───────────────────────────────────────────────────────
-- 12. Listar reseñas de un producto
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Review_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Review_List;
GO
CREATE PROCEDURE dbo.usp_Store_Review_List
    @CompanyId INT = 1, @ProductCode NVARCHAR(80), @Page INT = 1, @Limit INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT ISNULL(AVG(CAST(Rating AS FLOAT)), 0) AS avgRating, COUNT(*) AS totalCount,
        SUM(CASE WHEN Rating = 1 THEN 1 ELSE 0 END) AS star1,
        SUM(CASE WHEN Rating = 2 THEN 1 ELSE 0 END) AS star2,
        SUM(CASE WHEN Rating = 3 THEN 1 ELSE 0 END) AS star3,
        SUM(CASE WHEN Rating = 4 THEN 1 ELSE 0 END) AS star4,
        SUM(CASE WHEN Rating = 5 THEN 1 ELSE 0 END) AS star5
    FROM store.ProductReview
    WHERE CompanyId = @CompanyId AND ProductCode = @ProductCode AND IsDeleted = 0 AND IsApproved = 1;

    SELECT ReviewId AS id, Rating AS rating, Title AS title, Comment AS comment,
        ReviewerName AS reviewerName, IsVerified AS isVerified, CreatedAt AS createdAt
    FROM store.ProductReview
    WHERE CompanyId = @CompanyId AND ProductCode = @ProductCode AND IsDeleted = 0 AND IsApproved = 1
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ───────────────────────────────────────────────────────
-- 13. Crear reseña
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Review_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Review_Create;
GO
CREATE PROCEDURE dbo.usp_Store_Review_Create
    @CompanyId INT = 1, @ProductCode NVARCHAR(80), @Rating INT,
    @Title NVARCHAR(200) = NULL, @Comment NVARCHAR(2000),
    @ReviewerName NVARCHAR(200) = N'Cliente', @ReviewerEmail NVARCHAR(150) = NULL,
    @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Rating < 1 OR @Rating > 5
    BEGIN SET @Resultado = -1; SET @Mensaje = N'La calificación debe ser entre 1 y 5'; RETURN; END;

    INSERT INTO store.ProductReview (CompanyId, ProductCode, Rating, Title, Comment, ReviewerName, ReviewerEmail, IsVerified, IsApproved, IsDeleted, CreatedAt)
    VALUES (@CompanyId, @ProductCode, @Rating, @Title, @Comment, @ReviewerName, @ReviewerEmail, 0, 1, 0, SYSUTCDATETIME());

    SET @Resultado = 1; SET @Mensaje = N'Reseña creada exitosamente';
END;
GO

-- =============================================
-- DIRECCIONES Y METODOS DE PAGO DEL CLIENTE
-- Tablas: master.CustomerAddress, master.CustomerPaymentMethod
-- =============================================

-- ───────────────────────────────────────────────────────
-- 14. Tabla CustomerAddress
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('master.CustomerAddress', 'U') IS NULL
BEGIN
    CREATE TABLE [master].[CustomerAddress] (
        AddressId       INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL DEFAULT 1,
        CustomerCode    NVARCHAR(24) NOT NULL,
        Label           NVARCHAR(50) NOT NULL,
        RecipientName   NVARCHAR(200) NOT NULL,
        Phone           NVARCHAR(40) NULL,
        AddressLine     NVARCHAR(300) NOT NULL,
        City            NVARCHAR(100) NULL,
        State           NVARCHAR(100) NULL,
        ZipCode         NVARCHAR(20) NULL,
        Country         NVARCHAR(50) NOT NULL DEFAULT 'Venezuela',
        Instructions    NVARCHAR(300) NULL,
        IsDefault       BIT NOT NULL DEFAULT 0,
        IsDeleted       BIT NOT NULL DEFAULT 0,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created table master.CustomerAddress';
END;
GO

-- ───────────────────────────────────────────────────────
-- 15. Tabla CustomerPaymentMethod
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('master.CustomerPaymentMethod', 'U') IS NULL
BEGIN
    CREATE TABLE [master].[CustomerPaymentMethod] (
        PaymentMethodId INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL DEFAULT 1,
        CustomerCode    NVARCHAR(24) NOT NULL,
        MethodType      NVARCHAR(30) NOT NULL,
        Label           NVARCHAR(50) NOT NULL,
        BankName        NVARCHAR(100) NULL,
        AccountPhone    NVARCHAR(40) NULL,
        AccountNumber   NVARCHAR(40) NULL,
        AccountEmail    NVARCHAR(150) NULL,
        HolderName      NVARCHAR(200) NULL,
        HolderFiscalId  NVARCHAR(30) NULL,
        CardType        NVARCHAR(20) NULL,
        CardLast4       NVARCHAR(4) NULL,
        CardExpiry      NVARCHAR(7) NULL,
        IsDefault       BIT NOT NULL DEFAULT 0,
        IsDeleted       BIT NOT NULL DEFAULT 0,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created table master.CustomerPaymentMethod';
END;
GO

-- ───────────────────────────────────────────────────────
-- 16. Listar direcciones del cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Address_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Address_List;
GO
CREATE PROCEDURE dbo.usp_Store_Address_List
    @CompanyId     INT = 1,
    @CustomerCode  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT AddressId, Label, RecipientName, Phone, AddressLine,
           City, State, ZipCode, Country, Instructions, IsDefault
    FROM [master].[CustomerAddress]
    WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode AND IsDeleted = 0
    ORDER BY IsDefault DESC, UpdatedAt DESC;
END;
GO

-- ───────────────────────────────────────────────────────
-- 17. Upsert direccion del cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Address_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Address_Upsert;
GO
CREATE PROCEDURE dbo.usp_Store_Address_Upsert
    @AddressId     INT = NULL,
    @CompanyId     INT = 1,
    @CustomerCode  NVARCHAR(24),
    @Label         NVARCHAR(50),
    @RecipientName NVARCHAR(200),
    @Phone         NVARCHAR(40)  = NULL,
    @AddressLine   NVARCHAR(300),
    @City          NVARCHAR(100) = NULL,
    @State         NVARCHAR(100) = NULL,
    @ZipCode       NVARCHAR(20)  = NULL,
    @Country       NVARCHAR(50)  = N'Venezuela',
    @Instructions  NVARCHAR(300) = NULL,
    @IsDefault     BIT = 0,
    @Resultado     INT OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT,
    @NewId         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NewId = 0;

    BEGIN TRY
        -- Si es default, quitar default de las demas
        IF @IsDefault = 1
            UPDATE [master].[CustomerAddress]
            SET IsDefault = 0, UpdatedAt = SYSUTCDATETIME()
            WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode AND IsDeleted = 0;

        IF @AddressId IS NULL
        BEGIN
            -- INSERT
            INSERT INTO [master].[CustomerAddress]
                (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine,
                 City, State, ZipCode, Country, Instructions, IsDefault)
            VALUES
                (@CompanyId, @CustomerCode, @Label, @RecipientName, @Phone, @AddressLine,
                 @City, @State, @ZipCode, ISNULL(@Country, N'Venezuela'), @Instructions, @IsDefault);

            SET @NewId = SCOPE_IDENTITY();

            -- Si es la primera, hacerla default
            IF NOT EXISTS (SELECT 1 FROM [master].[CustomerAddress]
                          WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode
                            AND IsDeleted = 0 AND IsDefault = 1)
                UPDATE [master].[CustomerAddress] SET IsDefault = 1 WHERE AddressId = @NewId;
        END
        ELSE
        BEGIN
            -- UPDATE
            IF NOT EXISTS (SELECT 1 FROM [master].[CustomerAddress]
                          WHERE AddressId = @AddressId AND CustomerCode = @CustomerCode AND IsDeleted = 0)
            BEGIN
                SET @Resultado = -1;
                SET @Mensaje = N'Dirección no encontrada';
                RETURN;
            END

            UPDATE [master].[CustomerAddress] SET
                Label = @Label, RecipientName = @RecipientName, Phone = @Phone,
                AddressLine = @AddressLine, City = @City, State = @State,
                ZipCode = @ZipCode, Country = ISNULL(@Country, N'Venezuela'),
                Instructions = @Instructions, IsDefault = @IsDefault,
                UpdatedAt = SYSUTCDATETIME()
            WHERE AddressId = @AddressId AND CustomerCode = @CustomerCode;
            SET @NewId = @AddressId;
        END

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END;
GO

-- ───────────────────────────────────────────────────────
-- 18. Eliminar direccion (soft delete)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_Address_Delete', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Address_Delete;
GO
CREATE PROCEDURE dbo.usp_Store_Address_Delete
    @AddressId     INT,
    @CustomerCode  NVARCHAR(24),
    @Resultado     INT OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [master].[CustomerAddress]
                  WHERE AddressId = @AddressId AND CustomerCode = @CustomerCode AND IsDeleted = 0)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Dirección no encontrada';
        RETURN;
    END

    UPDATE [master].[CustomerAddress]
    SET IsDeleted = 1, IsDefault = 0, UpdatedAt = SYSUTCDATETIME()
    WHERE AddressId = @AddressId AND CustomerCode = @CustomerCode;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- ───────────────────────────────────────────────────────
-- 19. Listar metodos de pago del cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_PaymentMethod_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_PaymentMethod_List;
GO
CREATE PROCEDURE dbo.usp_Store_PaymentMethod_List
    @CompanyId     INT = 1,
    @CustomerCode  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PaymentMethodId, MethodType, Label, BankName, AccountPhone,
           AccountNumber, AccountEmail, HolderName, HolderFiscalId,
           CardType, CardLast4, CardExpiry, IsDefault
    FROM [master].[CustomerPaymentMethod]
    WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode AND IsDeleted = 0
    ORDER BY IsDefault DESC, UpdatedAt DESC;
END;
GO

-- ───────────────────────────────────────────────────────
-- 20. Upsert metodo de pago del cliente
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_PaymentMethod_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_PaymentMethod_Upsert;
GO
CREATE PROCEDURE dbo.usp_Store_PaymentMethod_Upsert
    @PaymentMethodId INT = NULL,
    @CompanyId       INT = 1,
    @CustomerCode    NVARCHAR(24),
    @MethodType      NVARCHAR(30),
    @Label           NVARCHAR(50),
    @BankName        NVARCHAR(100) = NULL,
    @AccountPhone    NVARCHAR(40)  = NULL,
    @AccountNumber   NVARCHAR(40)  = NULL,
    @AccountEmail    NVARCHAR(150) = NULL,
    @HolderName      NVARCHAR(200) = NULL,
    @HolderFiscalId  NVARCHAR(30)  = NULL,
    @CardType        NVARCHAR(20)  = NULL,
    @CardLast4       NVARCHAR(4)   = NULL,
    @CardExpiry      NVARCHAR(7)   = NULL,
    @IsDefault       BIT = 0,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT,
    @NewId           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NewId = 0;

    -- Validar tipo
    IF @MethodType NOT IN (N'PAGO_MOVIL', N'TRANSFERENCIA', N'ZELLE', N'EFECTIVO', N'TARJETA')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Tipo de método de pago inválido';
        RETURN;
    END

    BEGIN TRY
        -- Si es default, quitar default de los demas
        IF @IsDefault = 1
            UPDATE [master].[CustomerPaymentMethod]
            SET IsDefault = 0, UpdatedAt = SYSUTCDATETIME()
            WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode AND IsDeleted = 0;

        IF @PaymentMethodId IS NULL
        BEGIN
            -- INSERT
            INSERT INTO [master].[CustomerPaymentMethod]
                (CompanyId, CustomerCode, MethodType, Label, BankName, AccountPhone,
                 AccountNumber, AccountEmail, HolderName, HolderFiscalId,
                 CardType, CardLast4, CardExpiry, IsDefault)
            VALUES
                (@CompanyId, @CustomerCode, @MethodType, @Label, @BankName, @AccountPhone,
                 @AccountNumber, @AccountEmail, @HolderName, @HolderFiscalId,
                 @CardType, @CardLast4, @CardExpiry, @IsDefault);

            SET @NewId = SCOPE_IDENTITY();

            -- Si es el primero, hacerlo default
            IF NOT EXISTS (SELECT 1 FROM [master].[CustomerPaymentMethod]
                          WHERE CompanyId = @CompanyId AND CustomerCode = @CustomerCode
                            AND IsDeleted = 0 AND IsDefault = 1)
                UPDATE [master].[CustomerPaymentMethod] SET IsDefault = 1 WHERE PaymentMethodId = @NewId;
        END
        ELSE
        BEGIN
            -- UPDATE
            IF NOT EXISTS (SELECT 1 FROM [master].[CustomerPaymentMethod]
                          WHERE PaymentMethodId = @PaymentMethodId AND CustomerCode = @CustomerCode AND IsDeleted = 0)
            BEGIN
                SET @Resultado = -1;
                SET @Mensaje = N'Método de pago no encontrado';
                RETURN;
            END

            UPDATE [master].[CustomerPaymentMethod] SET
                MethodType = @MethodType, Label = @Label, BankName = @BankName,
                AccountPhone = @AccountPhone, AccountNumber = @AccountNumber,
                AccountEmail = @AccountEmail, HolderName = @HolderName,
                HolderFiscalId = @HolderFiscalId, CardType = @CardType,
                CardLast4 = @CardLast4, CardExpiry = @CardExpiry,
                IsDefault = @IsDefault, UpdatedAt = SYSUTCDATETIME()
            WHERE PaymentMethodId = @PaymentMethodId AND CustomerCode = @CustomerCode;
            SET @NewId = @PaymentMethodId;
        END

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END;
GO

-- ───────────────────────────────────────────────────────
-- 21. Eliminar metodo de pago (soft delete)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Store_PaymentMethod_Delete', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_PaymentMethod_Delete;
GO
CREATE PROCEDURE dbo.usp_Store_PaymentMethod_Delete
    @PaymentMethodId INT,
    @CustomerCode    NVARCHAR(24),
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [master].[CustomerPaymentMethod]
                  WHERE PaymentMethodId = @PaymentMethodId AND CustomerCode = @CustomerCode AND IsDeleted = 0)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Método de pago no encontrado';
        RETURN;
    END

    UPDATE [master].[CustomerPaymentMethod]
    SET IsDeleted = 1, IsDefault = 0, UpdatedAt = SYSUTCDATETIME()
    WHERE PaymentMethodId = @PaymentMethodId AND CustomerCode = @CustomerCode;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

PRINT '=== usp_ecommerce.sql deployed OK ===';
GO
