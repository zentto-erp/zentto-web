-- usp_store_affiliate_admin_commissions_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_admin_commissions_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_admin_commissions_list;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_admin_commissions_list
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
      FROM store.AffiliateCommission
     WHERE CompanyId = @CompanyId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT c.Id, c.AffiliateId, a.ReferralCode, a.LegalName,
             c.OrderNumber, c.Rate, c.Category, c.CommissionAmount, c.CurrencyCode,
             c.Status, c.CreatedAt,
             ROW_NUMBER() OVER (ORDER BY c.CreatedAt DESC) AS rn
        FROM store.AffiliateCommission c
        JOIN store.Affiliate a ON a.Id = c.AffiliateId
       WHERE c.CompanyId = @CompanyId AND (@Status IS NULL OR c.Status = @Status)
    )
    SELECT Id AS id, AffiliateId AS affiliateId, ReferralCode AS referralCode,
           LegalName AS legalName, OrderNumber AS orderNumber, Rate AS rate, Category AS category,
           CommissionAmount AS commissionAmount, CurrencyCode AS currencyCode,
           Status AS status, CreatedAt AS createdAt
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
