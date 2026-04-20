-- usp_store_merchant_admin_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_merchant_admin_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_admin_list;
GO

CREATE PROCEDURE dbo.usp_store_merchant_admin_list
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
      FROM store.Merchant
     WHERE CompanyId = @CompanyId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT s.Id, s.LegalName, s.StoreSlug, s.ContactEmail, s.TaxId, s.Status, s.CommissionRate,
             ISNULL((SELECT COUNT(*) FROM store.MerchantProduct sp WHERE sp.MerchantId = s.Id), 0) AS productCount,
             ISNULL((SELECT COUNT(*) FROM store.MerchantProduct sp WHERE sp.MerchantId = s.Id AND sp.Status = 'approved'), 0) AS approvedCount,
             s.CreatedAt, s.ApprovedAt,
             ROW_NUMBER() OVER (ORDER BY s.CreatedAt DESC) AS rn
        FROM store.Merchant s
       WHERE s.CompanyId = @CompanyId AND (@Status IS NULL OR s.Status = @Status)
    )
    SELECT Id AS id, LegalName AS legalName, StoreSlug AS storeSlug,
           ContactEmail AS contactEmail, TaxId AS taxId, Status AS status,
           CommissionRate AS commissionRate, productCount, approvedCount,
           CreatedAt AS createdAt, ApprovedAt AS approvedAt
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
