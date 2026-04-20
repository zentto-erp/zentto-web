-- usp_store_affiliate_attribute_order — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_attribute_order', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_attribute_order;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_attribute_order
    @CompanyId     INT,
    @OrderNumber   NVARCHAR(60),
    @ReferralCode  NVARCHAR(20),
    @SessionId     NVARCHAR(100),
    @OrderAmount   DECIMAL(18,4),
    @Currency      NVARCHAR(10),
    @Resultado     INT OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT,
    @CommissionAmount DECIMAL(14,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @CommissionAmount = 0;

    DECLARE @AffId BIGINT = (
        SELECT TOP 1 Id FROM store.Affiliate WHERE ReferralCode = @ReferralCode AND Status = 'active'
    );
    IF @AffId IS NULL
    BEGIN
        SET @Mensaje = N'Afiliado inactivo o no encontrado';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM store.AffiliateCommission WHERE CompanyId = @CompanyId AND OrderNumber = @OrderNumber)
    BEGIN
        SET @Mensaje = N'Orden ya atribuida';
        RETURN;
    END;

    DECLARE @ClickId BIGINT = (
        SELECT TOP 1 Id FROM store.AffiliateClick
         WHERE ReferralCode = @ReferralCode
           AND (SessionId = @SessionId OR @SessionId IS NULL)
           AND CreatedAt > DATEADD(DAY, -30, SYSDATETIMEOFFSET())
         ORDER BY CreatedAt DESC
    );

    DECLARE @Rate DECIMAL(5,2), @Category NVARCHAR(80);

    -- Categoría mayoritaria (JOIN best-effort con master.Product)
    SELECT TOP 1 @Category = p.Category
      FROM ar.SalesDocumentLine l
      LEFT JOIN master.Product p ON p.ProductCode = l.ProductCode
     WHERE l.DocumentNumber = @OrderNumber
     GROUP BY p.Category
     ORDER BY COUNT(*) DESC;

    SELECT TOP 1 @Rate = Rate FROM store.AffiliateCommissionRate WHERE LOWER(Category) = LOWER(ISNULL(@Category, ''));
    IF @Rate IS NULL
        SELECT TOP 1 @Rate = Rate, @Category = N'default' FROM store.AffiliateCommissionRate WHERE IsDefault = 1;
    IF @Rate IS NULL SET @Rate = 3.00;

    SET @CommissionAmount = ROUND(@OrderAmount * @Rate / 100.0, 2);

    INSERT INTO store.AffiliateCommission
        (AffiliateId, CompanyId, OrderNumber, Rate, Category, CommissionAmount, CurrencyCode, Status, ClickId)
    VALUES
        (@AffId, @CompanyId, @OrderNumber, @Rate, ISNULL(@Category, 'default'),
         @CommissionAmount, UPPER(ISNULL(@Currency, 'USD')), 'pending', @ClickId);

    SET @Resultado = 1;
    SET @Mensaje   = N'Comisión registrada';
END;
GO
