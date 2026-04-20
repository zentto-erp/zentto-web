-- usp_store_seller_dashboard — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_seller_dashboard', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_seller_dashboard;
GO

CREATE PROCEDURE dbo.usp_store_seller_dashboard
    @CompanyId  INT,
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SellerId BIGINT = (
        SELECT TOP 1 Id FROM store.Seller WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId
    );
    IF @SellerId IS NULL
    BEGIN
        SELECT CAST(NULL AS BIGINT) AS sellerId WHERE 1 = 0;
        RETURN;
    END;

    SELECT
        s.Id AS sellerId,
        s.LegalName AS legalName,
        s.StoreSlug AS storeSlug,
        s.Status AS status,
        s.CommissionRate AS commissionRate,
        (SELECT COUNT(*) FROM store.SellerProduct WHERE SellerId = s.Id) AS productsTotal,
        (SELECT COUNT(*) FROM store.SellerProduct WHERE SellerId = s.Id AND Status = 'approved') AS productsApproved,
        (SELECT COUNT(*) FROM store.SellerProduct WHERE SellerId = s.Id AND Status = 'pending_review') AS productsPending,
        ISNULL((SELECT COUNT(DISTINCT l.DocumentNumber) FROM ar.SalesDocumentLine l WHERE l.SellerId = s.Id), 0) AS ordersTotal,
        ISNULL((SELECT SUM(l.TotalAmount) FROM ar.SalesDocumentLine l WHERE l.SellerId = s.Id), 0) AS grossSalesUsd,
        ISNULL((SELECT SUM(NetAmount) FROM store.SellerPayout WHERE SellerId = s.Id AND Status = 'paid'), 0) AS payoutsPaidUsd
      FROM store.Seller s
     WHERE s.Id = @SellerId;
END;
GO
