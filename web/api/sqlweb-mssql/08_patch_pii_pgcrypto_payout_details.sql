-- ============================================================
-- Patch 08: Cifrado PII de PayoutDetails (paridad con pgcrypto)
-- Equivalente a la migración PG 00155_pii_pgcrypto_payout_details.sql
--
-- SQL Server 2012+ compatible. No hay pgcrypto en MSSQL, así que
-- usamos ENCRYPTBYPASSPHRASE / DECRYPTBYPASSPHRASE con la MASTER_KEY
-- pasada como parámetro @MasterKey. Paridad funcional mínima: cifrado
-- simétrico con misma passphrase en ambos motores.
--
-- Estrategia:
--   1. Renombrar PayoutDetails → PayoutDetailsPlain y agregar PayoutDetailsEnc VARBINARY(MAX).
--   2. Los SPs de write (Register, Apply) ahora reciben @MasterKey y cifran.
--   3. Los SPs de read admin reciben @MasterKey y descifran.
--
-- NOTA: el rollout de data existente queda diferido igual que en PG.
-- Las columnas *Plain conservan el JSON original hasta que el PO lance el
-- script one-shot de migración (ver docs/security/pii-encryption.md).
-- ============================================================
USE zentto_dev;
GO

-- =============================================================================
-- AFFILIATE — split PayoutDetails → Plain + Enc
-- =============================================================================

IF COL_LENGTH('store.Affiliate', 'PayoutDetails') IS NOT NULL
   AND COL_LENGTH('store.Affiliate', 'PayoutDetailsPlain') IS NULL
BEGIN
    EXEC sp_rename 'store.Affiliate.PayoutDetails', 'PayoutDetailsPlain', 'COLUMN';
END;
GO

IF COL_LENGTH('store.Affiliate', 'PayoutDetailsEnc') IS NULL
    ALTER TABLE store.Affiliate ADD PayoutDetailsEnc VARBINARY(MAX) NULL;
GO

-- =============================================================================
-- MERCHANT — split PayoutDetails → Plain + Enc
-- =============================================================================

IF COL_LENGTH('store.Merchant', 'PayoutDetails') IS NOT NULL
   AND COL_LENGTH('store.Merchant', 'PayoutDetailsPlain') IS NULL
BEGIN
    EXEC sp_rename 'store.Merchant.PayoutDetails', 'PayoutDetailsPlain', 'COLUMN';
END;
GO

IF COL_LENGTH('store.Merchant', 'PayoutDetailsEnc') IS NULL
    ALTER TABLE store.Merchant ADD PayoutDetailsEnc VARBINARY(MAX) NULL;
GO

-- =============================================================================
-- usp_store_affiliate_register — ahora cifra PayoutDetails
-- =============================================================================
IF OBJECT_ID('dbo.usp_store_affiliate_register', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_register;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_register
    @CompanyId      INT,
    @CustomerId     INT,
    @LegalName      NVARCHAR(200),
    @TaxId          NVARCHAR(40),
    @ContactEmail   NVARCHAR(200),
    @PayoutMethod   NVARCHAR(30),
    @PayoutDetails  NVARCHAR(MAX),
    @MasterKey      NVARCHAR(256),
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT,
    @ReferralCode   NVARCHAR(20) OUTPUT,
    @AffiliateId    BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @Mensaje = N'customer_id requerido';
        RETURN;
    END;

    SELECT TOP 1 @AffiliateId = Id, @ReferralCode = ReferralCode
      FROM store.Affiliate
     WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId;

    IF @AffiliateId IS NOT NULL
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje   = N'Ya eres afiliado';
        RETURN;
    END;

    DECLARE @Attempt INT = 0, @Code NVARCHAR(20), @Exists INT = 1;
    WHILE @Attempt < 10 AND @Exists > 0
    BEGIN
        SET @Code = 'ZEN-' + UPPER(SUBSTRING(CONVERT(NVARCHAR(36), NEWID()), 1, 8));
        SELECT @Exists = COUNT(*) FROM store.Affiliate WHERE ReferralCode = @Code;
        SET @Attempt = @Attempt + 1;
    END;

    DECLARE @Enc VARBINARY(MAX) = NULL;
    IF @PayoutDetails IS NOT NULL AND LEN(@PayoutDetails) > 0
    BEGIN
        IF @MasterKey IS NULL OR LEN(@MasterKey) = 0
        BEGIN
            SET @Mensaje = N'MasterKey requerida para cifrar PayoutDetails';
            RETURN;
        END;
        SET @Enc = ENCRYPTBYPASSPHRASE(@MasterKey, @PayoutDetails);
    END;

    INSERT INTO store.Affiliate
        (CompanyId, CustomerId, ReferralCode, Status, PayoutMethod, PayoutDetailsEnc, TaxId, LegalName, ContactEmail)
    VALUES
        (@CompanyId, @CustomerId, @Code, 'pending', @PayoutMethod, @Enc, @TaxId, @LegalName, @ContactEmail);

    SET @AffiliateId   = SCOPE_IDENTITY();
    SET @ReferralCode  = @Code;
    SET @Resultado     = 1;
    SET @Mensaje       = N'Aplicación recibida. Te notificaremos cuando sea aprobada.';
END;
GO

-- =============================================================================
-- usp_store_affiliate_admin_list — ahora descifra PayoutDetails con @MasterKey
-- =============================================================================
IF OBJECT_ID('dbo.usp_store_affiliate_admin_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_admin_list;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_admin_list
    @CompanyId  INT,
    @Status     NVARCHAR(20),
    @Page       INT,
    @Limit      INT,
    @MasterKey  NVARCHAR(256) = NULL,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @P INT = CASE WHEN ISNULL(@Page, 1) < 1 THEN 1 ELSE @Page END;
    DECLARE @L INT = CASE WHEN ISNULL(@Limit, 20) < 1 THEN 20
                          WHEN @Limit > 100 THEN 100 ELSE @Limit END;
    DECLARE @Offset INT = (@P - 1) * @L;

    SELECT @TotalCount = COUNT(*)
      FROM store.Affiliate
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status);

    SELECT
        Id              AS id,
        ReferralCode    AS referralCode,
        CustomerId      AS customerId,
        LegalName       AS legalName,
        ContactEmail    AS contactEmail,
        Status          AS status,
        TaxId           AS taxId,
        PayoutMethod    AS payoutMethod,
        CASE
          WHEN PayoutDetailsEnc IS NULL OR @MasterKey IS NULL OR LEN(@MasterKey) = 0 THEN NULL
          ELSE CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@MasterKey, PayoutDetailsEnc))
        END AS payoutDetails,
        CreatedAt       AS createdAt,
        ApprovedAt      AS approvedAt,
        ISNULL((SELECT SUM(CommissionAmount) FROM store.AffiliateCommission WHERE AffiliateId = a.Id AND Status = 'pending'), 0) AS pendingAmount,
        ISNULL((SELECT SUM(CommissionAmount) FROM store.AffiliateCommission WHERE AffiliateId = a.Id AND Status = 'paid'), 0)    AS paidAmount
      FROM store.Affiliate a
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status)
     ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @L ROWS ONLY;
END;
GO

-- =============================================================================
-- usp_store_merchant_apply — ahora cifra PayoutDetails
-- =============================================================================
IF OBJECT_ID('dbo.usp_store_merchant_apply', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_apply;
GO

CREATE PROCEDURE dbo.usp_store_merchant_apply
    @CompanyId     INT,
    @CustomerId    INT,
    @LegalName     NVARCHAR(200),
    @TaxId         NVARCHAR(40),
    @StoreSlug     NVARCHAR(80),
    @Description   NVARCHAR(MAX),
    @LogoUrl       NVARCHAR(500),
    @ContactEmail  NVARCHAR(200),
    @ContactPhone  NVARCHAR(40),
    @PayoutMethod  NVARCHAR(30),
    @PayoutDetails NVARCHAR(MAX),
    @MasterKey     NVARCHAR(256),
    @Resultado     INT OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT,
    @MerchantId    BIGINT OUTPUT,
    @StoreSlugOut  NVARCHAR(80) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @Mensaje = N'customer_id requerido'; RETURN;
    END;
    IF @LegalName IS NULL OR LEN(LTRIM(RTRIM(@LegalName))) = 0
    BEGIN
        SET @Mensaje = N'Razón social requerida'; RETURN;
    END;

    SELECT TOP 1 @MerchantId = Id FROM store.Merchant WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId;
    IF @MerchantId IS NOT NULL
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje   = N'Ya tienes una solicitud de vendedor';
        RETURN;
    END;

    DECLARE @Slug NVARCHAR(80) = LOWER(ISNULL(@StoreSlug, @LegalName));
    DECLARE @i INT = 1, @ch NCHAR(1), @clean NVARCHAR(80) = N'';
    WHILE @i <= LEN(@Slug)
    BEGIN
        SET @ch = SUBSTRING(@Slug, @i, 1);
        IF (@ch LIKE '[a-z]' OR @ch LIKE '[0-9]')
            SET @clean = @clean + @ch;
        ELSE
            SET @clean = @clean + '-';
        SET @i = @i + 1;
    END;
    WHILE LEN(@clean) > 0 AND LEFT(@clean, 1) = '-' SET @clean = SUBSTRING(@clean, 2, LEN(@clean));
    WHILE LEN(@clean) > 0 AND RIGHT(@clean, 1) = '-' SET @clean = LEFT(@clean, LEN(@clean) - 1);
    IF LEN(@clean) < 3 SET @clean = CONCAT('merchant-', @CustomerId);

    DECLARE @base NVARCHAR(80) = @clean, @attempt INT = 0, @Exists INT = 1;
    WHILE @attempt < 10 AND @Exists > 0
    BEGIN
        SELECT @Exists = COUNT(*) FROM store.Merchant WHERE StoreSlug = @clean;
        IF @Exists > 0
        BEGIN
            SET @clean = CONCAT(@base, '-', ABS(CHECKSUM(NEWID())) % 10000);
        END;
        SET @attempt = @attempt + 1;
    END;

    DECLARE @Enc VARBINARY(MAX) = NULL;
    IF @PayoutDetails IS NOT NULL AND LEN(@PayoutDetails) > 0
    BEGIN
        IF @MasterKey IS NULL OR LEN(@MasterKey) = 0
        BEGIN
            SET @Mensaje = N'MasterKey requerida para cifrar PayoutDetails';
            RETURN;
        END;
        SET @Enc = ENCRYPTBYPASSPHRASE(@MasterKey, @PayoutDetails);
    END;

    INSERT INTO store.Merchant
        (CompanyId, CustomerId, LegalName, TaxId, StoreSlug, Description, LogoUrl,
         ContactEmail, ContactPhone, PayoutMethod, PayoutDetailsEnc)
    VALUES
        (@CompanyId, @CustomerId, @LegalName, @TaxId, @clean, @Description, @LogoUrl,
         @ContactEmail, @ContactPhone, @PayoutMethod, @Enc);

    SET @MerchantId    = SCOPE_IDENTITY();
    SET @StoreSlugOut  = @clean;
    SET @Resultado     = 1;
    SET @Mensaje       = N'Solicitud recibida. Revisaremos tu tienda en 24-48h.';
END;
GO

-- =============================================================================
-- usp_store_merchant_admin_get_detail — ahora descifra PayoutDetails con @MasterKey
-- TODO(pii-mssql): si hace falta, exponer más campos. Por ahora paridad mínima.
-- =============================================================================
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
