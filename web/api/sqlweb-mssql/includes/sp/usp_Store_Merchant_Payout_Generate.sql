-- usp_store_merchant_payout_generate — SQL Server 2012+
-- Agrupa store.MerchantCommission approved por (MerchantId, CurrencyCode) en el período
-- y genera un store.MerchantPayout por grupo. Marca las commissions como paid.
IF OBJECT_ID('dbo.usp_store_merchant_payout_generate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_payout_generate;
GO

CREATE PROCEDURE dbo.usp_store_merchant_payout_generate
    @CompanyId      INT,
    @PeriodStart    DATE = NULL,
    @PeriodEnd      DATE = NULL,
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT,
    @PayoutsCreated INT            OUTPUT,
    @TotalAmount    DECIMAL(14,2)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @PayoutsCreated = 0;
    SET @TotalAmount = 0;

    IF @PeriodStart IS NULL
        SET @PeriodStart = DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, -1, SYSUTCDATETIME())), 0);
    IF @PeriodEnd IS NULL
        SET @PeriodEnd = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, SYSUTCDATETIME()), 0));

    DECLARE @MerchantId BIGINT, @Currency CHAR(3);
    DECLARE @Gross DECIMAL(14,2), @Commission DECIMAL(14,2), @NetMerchant DECIMAL(14,2);
    DECLARE @PayoutId BIGINT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT MerchantId, CurrencyCode,
               SUM(GrossAmount), SUM(CommissionAmount), SUM(MerchantEarning)
          FROM store.MerchantCommission
         WHERE CompanyId = @CompanyId
           AND Status    = 'approved'
           AND CAST(CreatedAt AS DATE) BETWEEN @PeriodStart AND @PeriodEnd
         GROUP BY MerchantId, CurrencyCode
        HAVING SUM(MerchantEarning) > 0;

    OPEN cur;
    FETCH NEXT FROM cur INTO @MerchantId, @Currency, @Gross, @Commission, @NetMerchant;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO store.MerchantPayout (
            MerchantId, CompanyId, PeriodStart, PeriodEnd,
            GrossAmount, CommissionAmount, NetAmount, CurrencyCode, Status
        )
        VALUES (
            @MerchantId, @CompanyId, @PeriodStart, @PeriodEnd,
            @Gross, @Commission, @NetMerchant, @Currency, 'pending'
        );
        SET @PayoutId = SCOPE_IDENTITY();

        UPDATE store.MerchantCommission
           SET Status   = 'paid',
               PaidAt   = GETUTCDATE(),
               PayoutId = @PayoutId
         WHERE CompanyId    = @CompanyId
           AND MerchantId   = @MerchantId
           AND CurrencyCode = @Currency
           AND Status       = 'approved'
           AND CAST(CreatedAt AS DATE) BETWEEN @PeriodStart AND @PeriodEnd;

        SET @PayoutsCreated = @PayoutsCreated + 1;
        SET @TotalAmount    = @TotalAmount + @NetMerchant;

        FETCH NEXT FROM cur INTO @MerchantId, @Currency, @Gross, @Commission, @NetMerchant;
    END;
    CLOSE cur; DEALLOCATE cur;

    SET @Resultado = 1;
    SET @Mensaje = CONCAT(@PayoutsCreated, N' payout(s) merchant generado(s) por ', @TotalAmount);
END;
GO
