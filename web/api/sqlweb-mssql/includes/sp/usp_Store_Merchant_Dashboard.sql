-- usp_store_merchant_dashboard — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_merchant_dashboard', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_dashboard;
GO

CREATE PROCEDURE dbo.usp_store_merchant_dashboard
    @CompanyId  INT,
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MerchantId BIGINT = (
        SELECT TOP 1 Id FROM store.Merchant WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId
    );
    IF @MerchantId IS NULL
    BEGIN
        SELECT CAST(NULL AS BIGINT) AS merchantId WHERE 1 = 0;
        RETURN;
    END;

    SELECT
        s.Id AS merchantId,
        s.LegalName AS legalName,
        s.StoreSlug AS storeSlug,
        s.Status AS status,
        s.CommissionRate AS commissionRate,
        (SELECT COUNT(*) FROM store.MerchantProduct WHERE MerchantId = s.Id) AS productsTotal,
        (SELECT COUNT(*) FROM store.MerchantProduct WHERE MerchantId = s.Id AND Status = 'approved') AS productsApproved,
        (SELECT COUNT(*) FROM store.MerchantProduct WHERE MerchantId = s.Id AND Status = 'pending_review') AS productsPending,
        ISNULL((SELECT COUNT(DISTINCT l.DocumentNumber) FROM ar.SalesDocumentLine l WHERE l.MerchantId = s.Id), 0) AS ordersTotal,
        ISNULL((SELECT SUM(l.TotalAmount) FROM ar.SalesDocumentLine l WHERE l.MerchantId = s.Id), 0) AS grossSalesUsd,
        ISNULL((SELECT SUM(NetAmount) FROM store.MerchantPayout WHERE MerchantId = s.Id AND Status = 'paid'), 0) AS payoutsPaidUsd
      FROM store.Merchant s
     WHERE s.Id = @MerchantId;
END;
GO
