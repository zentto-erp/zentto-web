-- usp_Store_Product_ListAdmin
-- Lista admin completa: incluye draft + publicado + stock bajo. Usa @TotalCount OUTPUT.

IF OBJECT_ID('dbo.usp_Store_Product_ListAdmin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_ListAdmin;
GO

CREATE PROCEDURE dbo.usp_Store_Product_ListAdmin
    @CompanyId      INT             = 1,
    @BranchId       INT             = 1,
    @Search         NVARCHAR(200)   = NULL,
    @Category       NVARCHAR(50)    = NULL,
    @Brand          NVARCHAR(20)    = NULL,
    @Published      NVARCHAR(20)    = NULL,       -- 'published' | 'draft' | NULL
    @LowStockOnly   BIT             = 0,
    @LowStockLimit  DECIMAL(18,3)   = 5,
    @Page           INT             = 1,
    @Limit          INT             = 25,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (CASE WHEN @Page < 1 THEN 0 ELSE @Page - 1 END) * @Limit;
    DECLARE @pattern NVARCHAR(210) = CASE
        WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
            THEN '%' + LTRIM(RTRIM(@Search)) + '%'
        ELSE NULL END;

    SELECT @TotalCount = COUNT(*)
      FROM mstr.Product p
     WHERE p.CompanyId = @CompanyId
       AND p.IsDeleted = 0
       AND (@pattern IS NULL OR p.ProductCode LIKE @pattern OR p.ProductName LIKE @pattern)
       AND (@Category IS NULL OR p.CategoryCode = @Category)
       AND (@Brand IS NULL OR p.BrandCode = @Brand)
       AND (@Published IS NULL
            OR (@Published = 'published' AND ISNULL(p.IsPublishedStore, 0) = 1)
            OR (@Published = 'draft'     AND ISNULL(p.IsPublishedStore, 0) = 0))
       AND (@LowStockOnly = 0 OR p.StockQty <= @LowStockLimit);

    SELECT
        p.ProductId                   AS id,
        p.ProductCode                 AS code,
        p.ProductName                 AS name,
        p.CategoryCode                AS category,
        c.CategoryName                AS categoryName,
        p.BrandCode                   AS brandCode,
        b.BrandName                   AS brandName,
        p.SalesPrice                  AS price,
        p.CompareAtPrice              AS compareAtPrice,
        p.CostPrice                   AS costPrice,
        p.StockQty                    AS stock,
        p.IsService                   AS isService,
        ISNULL(p.IsPublishedStore, 0) AS isPublished,
        p.PublishedAt                 AS publishedAt,
        img.PublicUrl                 AS imageUrl,
        p.Slug                        AS slug,
        p.CreatedAt                   AS createdAt,
        p.UpdatedAt                   AS updatedAt
      FROM mstr.Product p
      LEFT JOIN mstr.Category c
             ON c.CategoryCode = p.CategoryCode AND c.CompanyId = p.CompanyId AND c.IsDeleted = 0
      LEFT JOIN mstr.Brand b
             ON b.BrandCode = p.BrandCode AND b.CompanyId = p.CompanyId AND b.IsDeleted = 0
      OUTER APPLY (
          SELECT TOP 1 ma.PublicUrl
            FROM cfg.EntityImage ei
            INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
           WHERE ei.CompanyId   = p.CompanyId
             AND ei.BranchId    = @BranchId
             AND ei.EntityType  = 'MASTER_PRODUCT'
             AND ei.EntityId    = p.ProductId
             AND ei.IsDeleted   = 0
             AND ei.IsActive    = 1
             AND ma.IsDeleted   = 0
           ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder
      ) img
     WHERE p.CompanyId = @CompanyId
       AND p.IsDeleted = 0
       AND (@pattern IS NULL OR p.ProductCode LIKE @pattern OR p.ProductName LIKE @pattern)
       AND (@Category IS NULL OR p.CategoryCode = @Category)
       AND (@Brand IS NULL OR p.BrandCode = @Brand)
       AND (@Published IS NULL
            OR (@Published = 'published' AND ISNULL(p.IsPublishedStore, 0) = 1)
            OR (@Published = 'draft'     AND ISNULL(p.IsPublishedStore, 0) = 0))
       AND (@LowStockOnly = 0 OR p.StockQty <= @LowStockLimit)
     ORDER BY p.UpdatedAt DESC, p.ProductId DESC
     OFFSET @offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
