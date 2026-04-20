-- usp_store_seller_products_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_seller_products_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_seller_products_list;
GO

CREATE PROCEDURE dbo.usp_store_seller_products_list
    @CompanyId   INT,
    @CustomerId  INT,
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

    DECLARE @SellerId BIGINT = (
        SELECT TOP 1 Id FROM store.Seller WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId
    );
    IF @SellerId IS NULL
    BEGIN
        SET @TotalCount = 0;
        SELECT CAST(NULL AS BIGINT) AS id WHERE 1 = 0;
        RETURN;
    END;

    SELECT @TotalCount = COUNT(*)
      FROM store.SellerProduct
     WHERE SellerId = @SellerId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT Id, ProductCode, Name, Price, Stock, Category, ImageUrl, Status, ReviewNotes,
             CreatedAt, UpdatedAt,
             ROW_NUMBER() OVER (ORDER BY UpdatedAt DESC) AS rn
        FROM store.SellerProduct
       WHERE SellerId = @SellerId AND (@Status IS NULL OR Status = @Status)
    )
    SELECT Id AS id, ProductCode AS productCode, Name AS name, Price AS price, Stock AS stock,
           Category AS category, ImageUrl AS imageUrl, Status AS status, ReviewNotes AS reviewNotes,
           CreatedAt AS createdAt, UpdatedAt AS updatedAt
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
