-- usp_store_merchant_commission_generate — SQL Server 2012+
-- Genera store.MerchantCommission por cada línea de una orden con MerchantId.
-- Fix negocio afiliado+merchant:
--   AffiliateDeduction = MIN(@AffiliatePerLine, CommissionAmount)
--   NetZenttoRevenue   = CommissionAmount - AffiliateDeduction  (nunca negativo)
IF OBJECT_ID('dbo.usp_store_merchant_commission_generate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_commission_generate;
GO

CREATE PROCEDURE dbo.usp_store_merchant_commission_generate
    @CompanyId                  INT,
    @OrderNumber                NVARCHAR(60),
    @AffiliateCommissionAmount  DECIMAL(14,2) = 0,
    @Resultado                  INT            OUTPUT,
    @Mensaje                    NVARCHAR(500)  OUTPUT,
    @CommissionsCreated         INT            OUTPUT,
    @TotalMerchantEarning       DECIMAL(14,2)  OUTPUT,
    @TotalZenttoRevenue         DECIMAL(14,2)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @CommissionsCreated = 0;
    SET @TotalMerchantEarning = 0;
    SET @TotalZenttoRevenue = 0;

    -- Moneda desde cabecera
    DECLARE @Currency CHAR(3);
    SELECT TOP 1 @Currency = COALESCE(CurrencyCode, 'USD')
      FROM ar.SalesDocument
     WHERE DocumentNumber = @OrderNumber;
    IF @Currency IS NULL SET @Currency = 'USD';

    -- Idempotencia
    IF EXISTS (SELECT 1 FROM store.MerchantCommission
                WHERE CompanyId = @CompanyId AND OrderNumber = @OrderNumber)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'Orden ya tiene commissions generadas';
        RETURN;
    END

    -- Contar líneas con merchant
    DECLARE @LinesTotal INT = 0;
    SELECT @LinesTotal = COUNT(*)
      FROM ar.SalesDocumentLine
     WHERE DocumentNumber = @OrderNumber
       AND MerchantId IS NOT NULL
       AND ISNULL(IsVoided, 0) = 0;

    IF @LinesTotal = 0
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje = N'Sin líneas de merchant en la orden';
        RETURN;
    END

    DECLARE @AffPerLine   DECIMAL(14,2) = 0;
    DECLARE @AffRemaining DECIMAL(14,2) = ISNULL(@AffiliateCommissionAmount, 0);
    IF @AffRemaining > 0
        SET @AffPerLine = ROUND(@AffRemaining / @LinesTotal, 2);

    DECLARE @LineId INT, @MerchantId BIGINT, @ProductCode NVARCHAR(64),
            @Category NVARCHAR(80), @Gross DECIMAL(14,2), @Rate DECIMAL(5,2);
    DECLARE @Commission DECIMAL(14,2), @Earning DECIMAL(14,2),
            @AffDed DECIMAL(14,2), @NetZ DECIMAL(14,2);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT l.LineId, l.MerchantId, l.ProductCode,
               mp.Category, CAST(ISNULL(l.SubTotal, 0) AS DECIMAL(14,2)), m.CommissionRate
          FROM ar.SalesDocumentLine AS l
          JOIN store.Merchant AS m ON m.Id = l.MerchantId
          LEFT JOIN store.MerchantProduct AS mp
            ON mp.CompanyId  = @CompanyId
           AND mp.MerchantId = l.MerchantId
           AND mp.ProductCode = l.ProductCode
         WHERE l.DocumentNumber = @OrderNumber
           AND l.MerchantId IS NOT NULL
           AND ISNULL(l.IsVoided, 0) = 0
         ORDER BY l.LineId;

    OPEN cur;
    FETCH NEXT FROM cur INTO @LineId, @MerchantId, @ProductCode, @Category, @Gross, @Rate;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Rate IS NULL SET @Rate = 12.00;
        SET @Commission = ROUND(@Gross * @Rate / 100.0, 2);
        SET @Earning    = ROUND(@Gross - @Commission, 2);

        -- AffDed = min(perLine, commission, remaining), nunca < 0
        SET @AffDed = CASE WHEN @AffPerLine < @Commission THEN @AffPerLine ELSE @Commission END;
        IF @AffDed > @AffRemaining SET @AffDed = @AffRemaining;
        IF @AffDed < 0 SET @AffDed = 0;
        SET @AffRemaining = @AffRemaining - @AffDed;

        SET @NetZ = @Commission - @AffDed;
        IF @NetZ < 0 SET @NetZ = 0;

        INSERT INTO store.MerchantCommission (
            CompanyId, MerchantId, OrderNumber, OrderLineId, ProductCode, Category,
            GrossAmount, CommissionRate, CommissionAmount, MerchantEarning,
            AffiliateDeduction, NetZenttoRevenue, CurrencyCode, Status
        )
        VALUES (
            @CompanyId, @MerchantId, @OrderNumber, @LineId, @ProductCode, @Category,
            @Gross, @Rate, @Commission, @Earning,
            @AffDed, @NetZ, @Currency, 'pending'
        );

        SET @CommissionsCreated   = @CommissionsCreated + 1;
        SET @TotalMerchantEarning = @TotalMerchantEarning + @Earning;
        SET @TotalZenttoRevenue   = @TotalZenttoRevenue + @NetZ;

        FETCH NEXT FROM cur INTO @LineId, @MerchantId, @ProductCode, @Category, @Gross, @Rate;
    END;
    CLOSE cur; DEALLOCATE cur;

    SET @Resultado = 1;
    SET @Mensaje = CONCAT(@CommissionsCreated, N' commission(es) creada(s)');
END;
GO
