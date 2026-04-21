-- ============================================================
-- Patch 09: Marketplace — productos merchant visibles en storefront.
-- Equivalente a la migración PG 00158_marketplace_products_visibility.sql.
--
-- SQL Server 2012+ compatible. Crea vista store.UnifiedProduct como
-- UNION ALL entre mstr.Product publicados y store.MerchantProduct
-- approved (con Merchant approved). Re-crea los SPs de listado y detalle
-- para que lean de la vista.
--
-- Notas:
--   - Esquema master se llama mstr en zentto_dev (reservado).
--   - No hay pgcrypto/pg_trgm; el sort y filtros son equivalentes.
--   - store.ProductReview.Rating existe (schema store, mismo nombre).
-- ============================================================
USE zentto_dev;
GO

-- =============================================================================
-- Vista store.UnifiedProduct
-- =============================================================================

IF OBJECT_ID('store.UnifiedProduct', 'V') IS NOT NULL
    DROP VIEW store.UnifiedProduct;
GO

CREATE VIEW store.UnifiedProduct
AS
SELECT
    CAST('zentto' AS NVARCHAR(16))      AS [source],
    CAST(p.ProductId AS BIGINT)          AS Id,
    CAST(p.ProductCode AS NVARCHAR(80))  AS Code,
    CAST(p.ProductName AS NVARCHAR(250)) AS Name,
    CAST(p.ShortDescription AS NVARCHAR(500)) AS ShortDescription,
    CAST(p.LongDescription AS NVARCHAR(MAX))  AS LongDescription,
    CAST(p.CategoryCode AS NVARCHAR(100))     AS CategoryCode,
    CAST(p.BrandCode AS NVARCHAR(50))         AS BrandCode,
    CAST(p.SalesPrice AS DECIMAL(18,4))       AS Price,
    CAST(p.CompareAtPrice AS DECIMAL(18,4))   AS CompareAtPrice,
    CAST(p.StockQty AS DECIMAL(18,4))         AS Stock,
    CAST(ISNULL(p.IsService, 0) AS BIT)       AS IsService,
    CAST(ISNULL(p.DefaultTaxRate, 0) AS DECIMAL(9,4)) AS TaxRate,
    CAST(p.Slug AS NVARCHAR(200))             AS Slug,
    CAST(NULL AS NVARCHAR(500))               AS ImageUrl,
    CAST(NULL AS BIGINT)                      AS MerchantId,
    CAST(NULL AS NVARCHAR(80))                AS MerchantSlug,
    CAST(NULL AS NVARCHAR(200))               AS MerchantName,
    CAST(NULL AS NVARCHAR(500))               AS MerchantLogoUrl,
    CAST(1 AS BIT)                            AS Published,
    CAST(p.CompanyId AS INT)                  AS CompanyId,
    p.CreatedAt                               AS CreatedAt,
    p.UpdatedAt                               AS UpdatedAt
  FROM mstr.Product p
 WHERE p.IsDeleted = 0
   AND p.IsActive  = 1
   AND ISNULL(p.IsPublishedStore, 0) = 1
UNION ALL
SELECT
    CAST('merchant' AS NVARCHAR(16))     AS [source],
    CAST(mp.Id AS BIGINT)                AS Id,
    CAST(mp.ProductCode AS NVARCHAR(80)) AS Code,
    CAST(mp.Name AS NVARCHAR(250))       AS Name,
    CAST(LEFT(ISNULL(mp.Description, N''), 500) AS NVARCHAR(500)) AS ShortDescription,
    CAST(mp.Description AS NVARCHAR(MAX)) AS LongDescription,
    CAST(mp.Category AS NVARCHAR(100))   AS CategoryCode,
    CAST(NULL AS NVARCHAR(50))           AS BrandCode,
    CAST(mp.Price AS DECIMAL(18,4))      AS Price,
    CAST(NULL AS DECIMAL(18,4))          AS CompareAtPrice,
    CAST(mp.Stock AS DECIMAL(18,4))      AS Stock,
    CAST(0 AS BIT)                       AS IsService,
    CAST(0 AS DECIMAL(9,4))              AS TaxRate,
    CAST(NULL AS NVARCHAR(200))          AS Slug,
    CAST(mp.ImageUrl AS NVARCHAR(500))   AS ImageUrl,
    CAST(m.Id AS BIGINT)                 AS MerchantId,
    CAST(m.StoreSlug AS NVARCHAR(80))    AS MerchantSlug,
    CAST(m.LegalName AS NVARCHAR(200))   AS MerchantName,
    CAST(m.LogoUrl AS NVARCHAR(500))     AS MerchantLogoUrl,
    CAST(1 AS BIT)                       AS Published,
    CAST(mp.CompanyId AS INT)            AS CompanyId,
    mp.CreatedAt                         AS CreatedAt,
    mp.UpdatedAt                         AS UpdatedAt
  FROM store.MerchantProduct mp
  JOIN store.Merchant m ON m.Id = mp.MerchantId
 WHERE mp.[Status] = N'approved'
   AND m.[Status]  = N'approved';
GO

-- =============================================================================
-- SP dbo.usp_Store_Product_List — ahora lee de store.UnifiedProduct
-- =============================================================================

IF OBJECT_ID('dbo.usp_Store_Product_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_List;
GO

CREATE PROCEDURE dbo.usp_Store_Product_List
    @CompanyId       INT             = 1,
    @BranchId        INT             = 1,
    @Search          NVARCHAR(200)   = NULL,
    @Category        NVARCHAR(100)   = NULL,
    @Brand           NVARCHAR(50)    = NULL,
    @PriceMin        DECIMAL(18,4)   = NULL,
    @PriceMax        DECIMAL(18,4)   = NULL,
    @MinRating       INT             = NULL,
    @InStockOnly     BIT             = 1,
    @SortBy          NVARCHAR(20)    = 'name',
    @Page            INT             = 1,
    @Limit           INT             = 24,
    @MerchantSlug    NVARCHAR(80)    = NULL,
    @IncludeMerchant BIT             = 1,
    @TotalCount      INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset  INT = (CASE WHEN @Page < 1 THEN 0 ELSE @Page - 1 END) * @Limit;
    DECLARE @pattern NVARCHAR(210) = CASE
        WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
            THEN N'%' + LTRIM(RTRIM(@Search)) + N'%'
        ELSE NULL END;

    ;WITH Ratings AS (
        SELECT r.CompanyId, r.ProductCode,
               AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
               COUNT(*)                    AS ReviewCount
          FROM store.ProductReview r
         WHERE r.IsDeleted = 0 AND r.IsApproved = 1
         GROUP BY r.CompanyId, r.ProductCode
    )
    SELECT @TotalCount = COUNT(*)
      FROM store.UnifiedProduct u
      LEFT JOIN Ratings rv
             ON rv.CompanyId = u.CompanyId AND rv.ProductCode = u.Code
     WHERE u.CompanyId = @CompanyId
       AND (@IncludeMerchant = 1 OR u.[source] = N'zentto')
       AND (@InStockOnly = 0 OR u.Stock > 0 OR u.IsService = 1)
       AND (@pattern IS NULL OR u.Code LIKE @pattern
            OR u.Name LIKE @pattern OR ISNULL(u.CategoryCode, N'') LIKE @pattern)
       AND (@Category IS NULL OR u.CategoryCode = @Category)
       AND (@Brand    IS NULL OR u.BrandCode    = @Brand)
       AND (@PriceMin IS NULL OR u.Price >= @PriceMin)
       AND (@PriceMax IS NULL OR u.Price <= @PriceMax)
       AND (@MinRating IS NULL OR ISNULL(rv.AvgRating, 0) >= @MinRating)
       AND (@MerchantSlug IS NULL OR u.MerchantSlug = @MerchantSlug);

    ;WITH Ratings AS (
        SELECT r.CompanyId, r.ProductCode,
               AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
               COUNT(*)                    AS ReviewCount
          FROM store.ProductReview r
         WHERE r.IsDeleted = 0 AND r.IsApproved = 1
         GROUP BY r.CompanyId, r.ProductCode
    )
    SELECT
        u.Id                         AS id,
        u.Code                       AS code,
        u.Name                       AS name,
        ISNULL(u.ShortDescription, u.Name) AS [fullDescription],
        u.ShortDescription           AS [shortDescription],
        u.CategoryCode               AS category,
        c.CategoryName               AS [categoryName],
        u.BrandCode                  AS [brandCode],
        b.BrandName                  AS [brandName],
        u.Price                      AS price,
        u.CompareAtPrice             AS [compareAtPrice],
        u.Stock                      AS stock,
        u.IsService                  AS [isService],
        CASE WHEN u.TaxRate > 1 THEN u.TaxRate / 100.0
             ELSE ISNULL(u.TaxRate, 0) END AS [taxRate],
        ISNULL(u.ImageUrl, img.PublicUrl) AS [imageUrl],
        ISNULL(rv.AvgRating, 0)      AS [avgRating],
        ISNULL(rv.ReviewCount, 0)    AS [reviewCount],
        u.[source]                   AS [source],
        u.MerchantId                 AS [merchantId],
        u.MerchantSlug               AS [merchantSlug],
        u.MerchantName               AS [merchantName]
      FROM store.UnifiedProduct u
      LEFT JOIN mstr.Category c
             ON c.CategoryCode = u.CategoryCode
            AND c.CompanyId    = u.CompanyId
            AND c.IsDeleted    = 0
      LEFT JOIN mstr.Brand b
             ON b.BrandCode = u.BrandCode
            AND b.CompanyId = u.CompanyId
            AND b.IsDeleted = 0
      OUTER APPLY (
          SELECT TOP 1 ma.PublicUrl
            FROM cfg.EntityImage ei
            INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
           WHERE u.[source]     = N'zentto'
             AND ei.CompanyId   = u.CompanyId
             AND ei.BranchId    = @BranchId
             AND ei.EntityType  = N'MASTER_PRODUCT'
             AND ei.EntityId    = u.Id
             AND ei.IsDeleted   = 0
             AND ei.IsActive    = 1
             AND ma.IsDeleted   = 0
             AND ma.IsActive    = 1
           ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder
      ) img
      LEFT JOIN Ratings rv
             ON rv.CompanyId = u.CompanyId AND rv.ProductCode = u.Code
     WHERE u.CompanyId = @CompanyId
       AND (@IncludeMerchant = 1 OR u.[source] = N'zentto')
       AND (@InStockOnly = 0 OR u.Stock > 0 OR u.IsService = 1)
       AND (@pattern IS NULL OR u.Code LIKE @pattern
            OR u.Name LIKE @pattern OR ISNULL(u.CategoryCode, N'') LIKE @pattern)
       AND (@Category IS NULL OR u.CategoryCode = @Category)
       AND (@Brand    IS NULL OR u.BrandCode    = @Brand)
       AND (@PriceMin IS NULL OR u.Price >= @PriceMin)
       AND (@PriceMax IS NULL OR u.Price <= @PriceMax)
       AND (@MinRating IS NULL OR ISNULL(rv.AvgRating, 0) >= @MinRating)
       AND (@MerchantSlug IS NULL OR u.MerchantSlug = @MerchantSlug)
     ORDER BY
        CASE WHEN @SortBy = 'name'       THEN u.Name  END ASC,
        CASE WHEN @SortBy = 'price_asc'  THEN u.Price END ASC,
        CASE WHEN @SortBy = 'price_desc' THEN u.Price END DESC,
        CASE WHEN @SortBy = 'rating'     THEN ISNULL(rv.AvgRating, 0) END DESC,
        CASE WHEN @SortBy = 'newest'     THEN u.CreatedAt END DESC,
        u.Name ASC
    OFFSET @offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- SP dbo.usp_Store_Product_GetByCode — ahora incluye merchant + rating
-- =============================================================================

IF OBJECT_ID('dbo.usp_Store_Product_GetByCode', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_GetByCode;
GO

CREATE PROCEDURE dbo.usp_Store_Product_GetByCode
    @CompanyId INT           = 1,
    @BranchId  INT           = 1,
    @Code      NVARCHAR(80)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Ratings AS (
        SELECT r.CompanyId, r.ProductCode,
               AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
               COUNT(*)                    AS ReviewCount
          FROM store.ProductReview r
         WHERE r.IsDeleted = 0 AND r.IsApproved = 1
         GROUP BY r.CompanyId, r.ProductCode
    ),
    MerchantRatings AS (
        SELECT mp.MerchantId,
               AVG(CAST(r.Rating AS FLOAT)) AS AvgRating,
               COUNT(*)                    AS ReviewCount
          FROM store.MerchantProduct mp
          INNER JOIN store.ProductReview r
                 ON r.ProductCode = mp.ProductCode
                AND r.IsDeleted = 0 AND r.IsApproved = 1
         WHERE mp.[Status] = N'approved'
         GROUP BY mp.MerchantId
    )
    SELECT TOP 1
        u.Id                      AS id,
        u.Code                    AS code,
        u.Name                    AS name,
        ISNULL(u.ShortDescription, u.Name) AS [fullDescription],
        u.ShortDescription        AS [shortDescription],
        u.LongDescription         AS [longDescription],
        u.CategoryCode            AS category,
        c.CategoryName            AS [categoryName],
        u.BrandCode               AS [brandCode],
        b.BrandName               AS [brandName],
        u.Price                   AS price,
        u.CompareAtPrice          AS [compareAtPrice],
        p.CostPrice               AS [costPrice],
        u.Stock                   AS stock,
        u.IsService               AS [isService],
        p.UnitCode                AS [unitCode],
        CASE WHEN u.TaxRate > 1 THEN u.TaxRate / 100.0
             ELSE ISNULL(u.TaxRate, 0) END AS [taxRate],
        p.WeightKg                AS [weightKg],
        p.WidthCm                 AS [widthCm],
        p.HeightCm                AS [heightCm],
        p.DepthCm                 AS [depthCm],
        p.WarrantyMonths          AS [warrantyMonths],
        p.BarCode                 AS [barCode],
        u.Slug                    AS slug,
        ISNULL(rv.AvgRating, 0)   AS [avgRating],
        ISNULL(rv.ReviewCount, 0) AS [reviewCount],
        u.[source]                AS [source],
        u.MerchantId              AS [merchantId],
        u.MerchantSlug            AS [merchantSlug],
        u.MerchantName            AS [merchantName],
        u.MerchantLogoUrl         AS [merchantLogoUrl],
        ISNULL(mr.AvgRating, 0)   AS [merchantRating]
      FROM store.UnifiedProduct u
      LEFT JOIN mstr.Product p
             ON u.[source]    = N'zentto'
            AND p.ProductId   = u.Id
            AND p.CompanyId   = u.CompanyId
      LEFT JOIN mstr.Category c
             ON c.CategoryCode = u.CategoryCode
            AND c.CompanyId    = u.CompanyId
            AND c.IsDeleted    = 0
      LEFT JOIN mstr.Brand b
             ON b.BrandCode = u.BrandCode
            AND b.CompanyId = u.CompanyId
            AND b.IsDeleted = 0
      LEFT JOIN Ratings rv
             ON rv.CompanyId = u.CompanyId AND rv.ProductCode = u.Code
      LEFT JOIN MerchantRatings mr
             ON mr.MerchantId = u.MerchantId
     WHERE u.CompanyId = @CompanyId
       AND u.Code      = @Code;
END;
GO

-- =============================================================================
-- SP dbo.usp_Store_Merchant_Public_Get — perfil público del merchant
-- =============================================================================

IF OBJECT_ID('dbo.usp_Store_Merchant_Public_Get', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Merchant_Public_Get;
GO

CREATE PROCEDURE dbo.usp_Store_Merchant_Public_Get
    @CompanyId INT           = 1,
    @Slug      NVARCHAR(80)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        m.Id                    AS [merchantId],
        m.StoreSlug             AS [storeSlug],
        m.LegalName             AS [legalName],
        m.Description           AS [description],
        m.LogoUrl               AS [logoUrl],
        m.BannerUrl             AS [bannerUrl],
        m.ContactEmail          AS [contactEmail],
        (SELECT COUNT(*) FROM store.MerchantProduct sp
          WHERE sp.MerchantId = m.Id AND sp.[Status] = N'approved') AS [productsApproved],
        ISNULL((
            SELECT AVG(CAST(r.Rating AS FLOAT))
              FROM store.MerchantProduct sp
              INNER JOIN store.ProductReview r
                     ON r.ProductCode = sp.ProductCode
                    AND r.IsDeleted = 0 AND r.IsApproved = 1
             WHERE sp.MerchantId = m.Id AND sp.[Status] = N'approved'
        ), 0) AS [avgRating],
        ISNULL((
            SELECT COUNT(*)
              FROM store.MerchantProduct sp
              INNER JOIN store.ProductReview r
                     ON r.ProductCode = sp.ProductCode
                    AND r.IsDeleted = 0 AND r.IsApproved = 1
             WHERE sp.MerchantId = m.Id AND sp.[Status] = N'approved'
        ), 0) AS [reviewCount],
        m.CreatedAt             AS [createdAt]
      FROM store.Merchant m
     WHERE m.CompanyId = @CompanyId
       AND m.StoreSlug = @Slug
       AND m.[Status]  = N'approved';
END;
GO
