-- usp_store_affiliate_payout_generate — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_payout_generate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_payout_generate;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_payout_generate
    @CompanyId      INT,
    @PeriodStart    DATE = NULL,
    @PeriodEnd      DATE = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT,
    @PayoutsCreated INT OUTPUT,
    @TotalAmount    DECIMAL(14,2) OUTPUT
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

    DECLARE @AffId BIGINT, @Total DECIMAL(14,2), @PayoutId BIGINT;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT AffiliateId, SUM(CommissionAmount)
          FROM store.AffiliateCommission
         WHERE CompanyId = @CompanyId AND Status = 'approved'
           AND CAST(CreatedAt AS DATE) BETWEEN @PeriodStart AND @PeriodEnd
         GROUP BY AffiliateId
        HAVING SUM(CommissionAmount) > 0;

    OPEN cur;
    FETCH NEXT FROM cur INTO @AffId, @Total;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO store.AffiliatePayout (AffiliateId, CompanyId, PeriodStart, PeriodEnd, TotalAmount, Status)
        VALUES (@AffId, @CompanyId, @PeriodStart, @PeriodEnd, @Total, 'pending');
        SET @PayoutId = SCOPE_IDENTITY();

        UPDATE store.AffiliateCommission
           SET Status = 'paid', PaidAt = GETUTCDATE(), PayoutId = @PayoutId
         WHERE CompanyId = @CompanyId
           AND AffiliateId = @AffId
           AND Status = 'approved'
           AND CAST(CreatedAt AS DATE) BETWEEN @PeriodStart AND @PeriodEnd;

        SET @PayoutsCreated = @PayoutsCreated + 1;
        SET @TotalAmount = @TotalAmount + @Total;
        FETCH NEXT FROM cur INTO @AffId, @Total;
    END;
    CLOSE cur; DEALLOCATE cur;

    SET @Resultado = 1;
    SET @Mensaje = CONCAT(@PayoutsCreated, N' payout(s) generado(s) por ', @TotalAmount);
END;
GO
