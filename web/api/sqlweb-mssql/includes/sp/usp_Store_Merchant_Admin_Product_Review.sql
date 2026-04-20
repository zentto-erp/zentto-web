-- usp_store_merchant_admin_product_review — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_merchant_admin_product_review', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_admin_product_review;
GO

CREATE PROCEDURE dbo.usp_store_merchant_admin_product_review
    @CompanyId  INT,
    @ProductId  BIGINT,
    @Status     NVARCHAR(20),
    @Notes      NVARCHAR(MAX) = NULL,
    @Actor      NVARCHAR(60),
    @Resultado  INT OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    IF @Status NOT IN ('approved','rejected')
    BEGIN
        SET @Mensaje = N'Status inválido'; RETURN;
    END;

    UPDATE store.MerchantProduct
       SET Status      = @Status,
           ReviewNotes = @Notes,
           ReviewedAt  = GETUTCDATE(),
           ReviewedBy  = @Actor,
           UpdatedAt   = GETUTCDATE()
     WHERE Id = @ProductId AND CompanyId = @CompanyId;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Mensaje = N'Producto no encontrado'; RETURN;
    END;
    SET @Resultado = 1;
    SET @Mensaje = N'Revisión guardada';
END;
GO
