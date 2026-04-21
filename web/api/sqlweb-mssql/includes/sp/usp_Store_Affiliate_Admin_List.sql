-- usp_store_affiliate_admin_list — SQL Server 2012+
-- PII: opcionalmente descifra PayoutDetails con @MasterKey (paridad PG).
IF OBJECT_ID('dbo.usp_store_affiliate_admin_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_admin_list;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_admin_list
    @CompanyId   INT,
    @Status      NVARCHAR(20) = NULL,
    @Page        INT = 1,
    @Limit       INT = 20,
    @MasterKey   NVARCHAR(256) = NULL,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page  < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 20;
    IF @Limit > 100 SET @Limit = 100;

    SELECT @TotalCount = COUNT(*)
      FROM store.Affiliate
     WHERE CompanyId = @CompanyId AND (@Status IS NULL OR Status = @Status);

    ;WITH ordered AS (
      SELECT a.Id, a.ReferralCode, a.CustomerId, a.LegalName, a.ContactEmail,
             a.Status, a.TaxId, a.PayoutMethod, a.PayoutDetailsEnc,
             a.CreatedAt, a.ApprovedAt,
             ISNULL((SELECT SUM(CommissionAmount) FROM store.AffiliateCommission WHERE AffiliateId = a.Id AND Status = 'pending'), 0) AS pendingAmount,
             ISNULL((SELECT SUM(CommissionAmount) FROM store.AffiliateCommission WHERE AffiliateId = a.Id AND Status = 'paid'), 0) AS paidAmount,
             ROW_NUMBER() OVER (ORDER BY a.CreatedAt DESC) AS rn
        FROM store.Affiliate a
       WHERE a.CompanyId = @CompanyId AND (@Status IS NULL OR a.Status = @Status)
    )
    SELECT Id AS id, ReferralCode AS referralCode, CustomerId AS customerId,
           LegalName AS legalName, ContactEmail AS contactEmail, Status AS status, TaxId AS taxId,
           PayoutMethod AS payoutMethod,
           CASE
             WHEN PayoutDetailsEnc IS NULL OR @MasterKey IS NULL OR LEN(@MasterKey) = 0 THEN NULL
             ELSE CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@MasterKey, PayoutDetailsEnc))
           END AS payoutDetails,
           CreatedAt AS createdAt, ApprovedAt AS approvedAt,
           pendingAmount, paidAmount
      FROM ordered
     WHERE rn > (@Page - 1) * @Limit AND rn <= @Page * @Limit
     ORDER BY rn;
END;
GO
