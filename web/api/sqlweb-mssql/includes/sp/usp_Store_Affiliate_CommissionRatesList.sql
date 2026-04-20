-- usp_store_affiliate_commission_rates_list — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_commission_rates_list', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_commission_rates_list;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_commission_rates_list
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Category AS category, Rate AS rate, IsDefault AS isDefault
      FROM store.AffiliateCommissionRate
     WHERE IsDefault = 0
     ORDER BY Rate ASC;
END;
GO
