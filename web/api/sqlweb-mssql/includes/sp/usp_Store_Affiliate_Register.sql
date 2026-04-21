-- usp_store_affiliate_register — SQL Server 2012+
-- PII: PayoutDetails se cifra con ENCRYPTBYPASSPHRASE(@MasterKey, ...).
-- Paridad con PG: store.pii_encrypt() + GUC zentto.master_key.
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
