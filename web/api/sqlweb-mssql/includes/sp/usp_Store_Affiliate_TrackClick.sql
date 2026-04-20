-- usp_store_affiliate_track_click — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_track_click', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_track_click;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_track_click
    @ReferralCode  NVARCHAR(20),
    @SessionId     NVARCHAR(100),
    @Ip            NVARCHAR(45),
    @UserAgent     NVARCHAR(500),
    @Referer       NVARCHAR(500),
    @Resultado     INT OUTPUT,
    @ClickId       BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @ClickId = NULL;

    DECLARE @AffId BIGINT = (
        SELECT TOP 1 Id FROM store.Affiliate
         WHERE ReferralCode = @ReferralCode AND Status = 'active'
    );
    IF @AffId IS NULL RETURN;

    INSERT INTO store.AffiliateClick (ReferralCode, AffiliateId, SessionId, Ip, UserAgent, Referer)
    VALUES (
        @ReferralCode, @AffId, @SessionId,
        LEFT(ISNULL(@Ip, ''), 45),
        LEFT(ISNULL(@UserAgent, ''), 500),
        LEFT(ISNULL(@Referer, ''), 500)
    );
    SET @ClickId = SCOPE_IDENTITY();
    SET @Resultado = 1;
END;
GO
