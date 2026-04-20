-- usp_store_seller_admin_products_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_seller_admin_products_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_seller_admin_products_list;
GO

CREATE PROCEDURE dbo.usp_store_seller_admin_products_list
    @CompanyId   INT,
    @Status      NVARCHAR(20) = NULL,
    @Page        INT = 1,
    @Limit       INT = 20,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page  < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 20;
    IF @Limit > 100 SET @Limit = 100;

    SELECT @TotalCount = COUNT(*)
      FROM store.SellerProduct
     WHERE CompanyId = @CompanyId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT sp.Id, sp.SellerId, s.LegalName AS sellerName,
             sp.ProductCode, sp.Name, sp.Price, sp.Stock, sp.Category, sp.ImageUrl,
             sp.Status, sp.ReviewNotes, sp.CreatedAt,
             ROW_NUMBER() OVER (ORDER BY sp.CreatedAt DESC) AS rn
        FROM store.SellerProduct sp
        JOIN store.Seller s ON s.Id = sp.SellerId
       WHERE sp.CompanyId = @CompanyId AND (@Status IS NULL OR sp.Status = @Status)
    )
    SELECT Id AS id, SellerId AS sellerId, sellerName, ProductCode AS productCode, Name AS name,
           Price AS price, Stock AS stock, Category AS category, ImageUrl AS imageUrl,
           Status AS status, ReviewNotes AS reviewNotes, CreatedAt AS createdAt
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
