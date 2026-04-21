-- usp_store_order_populate_merchants — SQL Server 2012+
-- Popula ar.SalesDocumentLine.MerchantId desde store.MerchantProduct por ProductCode.
-- Idempotente: solo actualiza líneas con MerchantId NULL.
IF OBJECT_ID('dbo.usp_store_order_populate_merchants', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_order_populate_merchants;
GO

CREATE PROCEDURE dbo.usp_store_order_populate_merchants
    @CompanyId    INT,
    @OrderNumber  NVARCHAR(60),
    @Resultado    INT OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT,
    @LinesUpdated INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @LinesUpdated = 0;

    UPDATE l
       SET l.MerchantId = mp.MerchantId
      FROM ar.SalesDocumentLine AS l
      JOIN store.MerchantProduct AS mp
        ON mp.ProductCode = l.ProductCode
       AND mp.CompanyId   = @CompanyId
       AND mp.Status      = 'approved'
     WHERE l.DocumentNumber = @OrderNumber
       AND l.MerchantId IS NULL;

    SET @LinesUpdated = @@ROWCOUNT;
    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO
