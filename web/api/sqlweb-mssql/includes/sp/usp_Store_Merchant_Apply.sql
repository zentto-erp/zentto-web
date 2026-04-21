-- usp_store_merchant_apply — SQL Server 2012+
-- PII: PayoutDetails se cifra con ENCRYPTBYPASSPHRASE(@MasterKey, ...).
-- Paridad con PG: store.pii_encrypt() + GUC zentto.master_key.
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

    SET @MerchantId   = SCOPE_IDENTITY();
    SET @StoreSlugOut = @clean;
    SET @Resultado    = 1;
    SET @Mensaje      = N'Solicitud recibida. Revisaremos tu tienda en 24-48h.';
END;
GO
