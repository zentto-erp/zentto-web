-- usp_store_affiliate_commissions_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_commissions_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_commissions_list;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_commissions_list
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

    DECLARE @AffId BIGINT = (
      SELECT TOP 1 Id FROM store.Affiliate WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId
    );
    IF @AffId IS NULL
    BEGIN
        SET @TotalCount = 0;
        SELECT CAST(NULL AS BIGINT) AS id WHERE 1 = 0;
        RETURN;
    END;

    SELECT @TotalCount = COUNT(*)
      FROM store.AffiliateCommission
     WHERE AffiliateId = @AffId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT Id, OrderNumber, Rate, Category, CommissionAmount, CurrencyCode, Status,
             CreatedAt, PaidAt,
             ROW_NUMBER() OVER (ORDER BY CreatedAt DESC) AS rn
        FROM store.AffiliateCommission
       WHERE AffiliateId = @AffId AND (@Status IS NULL OR Status = @Status)
    )
    SELECT Id AS id, OrderNumber AS orderNumber, Rate AS rate, Category AS category,
           CommissionAmount AS commissionAmount, CurrencyCode AS currencyCode,
           Status AS status, CreatedAt AS createdAt, PaidAt AS paidAt
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
