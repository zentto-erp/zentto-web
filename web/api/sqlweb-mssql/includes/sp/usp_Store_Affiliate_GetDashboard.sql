-- usp_store_affiliate_get_dashboard — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_get_dashboard', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_get_dashboard;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_get_dashboard
    @CompanyId   INT,
    @CustomerId  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AffId BIGINT, @Code NVARCHAR(20), @Status NVARCHAR(20), @Legal NVARCHAR(200);

    SELECT TOP 1 @AffId = Id, @Code = ReferralCode, @Status = Status, @Legal = LegalName
      FROM store.Affiliate
     WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId;

    IF @AffId IS NULL
    BEGIN
        SELECT CAST(NULL AS BIGINT) AS affiliateId, CAST(NULL AS NVARCHAR(20)) AS referralCode
         WHERE 1 = 0;
        RETURN;
    END;

    DECLARE @Clicks BIGINT = (
      SELECT COUNT(*) FROM store.AffiliateClick
       WHERE ReferralCode = @Code
         AND CreatedAt > DATEADD(MONTH, -12, SYSUTCDATETIME())
    );
    DECLARE @Conv BIGINT = (SELECT COUNT(*) FROM store.AffiliateCommission WHERE AffiliateId = @AffId AND Status IN ('approved','paid'));
    DECLARE @Pending DECIMAL(14,2) = (SELECT ISNULL(SUM(CommissionAmount),0) FROM store.AffiliateCommission WHERE AffiliateId = @AffId AND Status = 'pending');
    DECLARE @Approved DECIMAL(14,2) = (SELECT ISNULL(SUM(CommissionAmount),0) FROM store.AffiliateCommission WHERE AffiliateId = @AffId AND Status = 'approved');
    DECLARE @Paid DECIMAL(14,2) = (SELECT ISNULL(SUM(CommissionAmount),0) FROM store.AffiliateCommission WHERE AffiliateId = @AffId AND Status = 'paid');

    -- Monthly: FOR JSON AUTO (SQL Server 2016+); fallback vacío
    DECLARE @Monthly NVARCHAR(MAX) = N'[]';
    BEGIN TRY
        SELECT @Monthly = (
            SELECT CONVERT(NVARCHAR(7), DATEADD(MONTH, DATEDIFF(MONTH, 0, CreatedAt), 0), 126) AS mon,
                   ISNULL(SUM(CommissionAmount), 0) AS amount
              FROM store.AffiliateCommission
             WHERE AffiliateId = @AffId
               AND CreatedAt > DATEADD(MONTH, -6, SYSUTCDATETIME())
             GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, CreatedAt), 0)
             ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, CreatedAt), 0)
             FOR JSON PATH
        );
    END TRY
    BEGIN CATCH SET @Monthly = N'[]'; END CATCH;

    SELECT
        @AffId                        AS affiliateId,
        @Code                         AS referralCode,
        @Status                       AS status,
        @Legal                        AS legalName,
        @Clicks                       AS clicksTotal,
        @Conv                         AS conversions,
        @Pending                      AS pendingAmount,
        @Approved                     AS approvedAmount,
        @Paid                         AS paidAmount,
        (@Pending + @Approved + @Paid) AS totalEarned,
        'USD'                         AS currencyCode,
        ISNULL(@Monthly, N'[]')       AS monthlyJson;
END;
GO
