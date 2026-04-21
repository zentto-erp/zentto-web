-- usp_store_merchant_admin_get_detail — SQL Server 2012+
-- PII: opcionalmente descifra PayoutDetails con @MasterKey (paridad PG).
IF OBJECT_ID('dbo.usp_store_merchant_admin_get_detail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_admin_get_detail;
GO

CREATE PROCEDURE dbo.usp_store_merchant_admin_get_detail
    @CompanyId  INT,
    @MerchantId BIGINT,
    @MasterKey  NVARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        Id              AS id,
        LegalName       AS legalName,
        StoreSlug       AS storeSlug,
        Description     AS description,
        TaxId           AS taxId,
        ContactEmail    AS contactEmail,
        ContactPhone    AS contactPhone,
        LogoUrl         AS logoUrl,
        BannerUrl       AS bannerUrl,
        Status          AS status,
        CommissionRate  AS commissionRate,
        PayoutMethod    AS payoutMethod,
        CASE
          WHEN PayoutDetailsEnc IS NULL OR @MasterKey IS NULL OR LEN(@MasterKey) = 0 THEN NULL
          ELSE CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@MasterKey, PayoutDetailsEnc))
        END AS payoutDetails,
        RejectionReason AS rejectionReason,
        CreatedAt       AS createdAt,
        ApprovedAt      AS approvedAt,
        ApprovedBy      AS approvedBy
      FROM store.Merchant
     WHERE CompanyId = @CompanyId AND Id = @MerchantId;
END;
GO
