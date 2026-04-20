-- usp_store_merchant_product_submit — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_merchant_product_submit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_product_submit;
GO

CREATE PROCEDURE dbo.usp_store_merchant_product_submit
    @CompanyId   INT,
    @CustomerId  INT,
    @ProductId   BIGINT = NULL,
    @Code        NVARCHAR(64) = NULL,
    @Name        NVARCHAR(250),
    @Description NVARCHAR(MAX) = NULL,
    @Price       DECIMAL(18,4),
    @Stock       DECIMAL(18,4),
    @Category    NVARCHAR(80) = NULL,
    @ImageUrl    NVARCHAR(500) = NULL,
    @Submit      BIT = 0,
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @OutProductId BIGINT OUTPUT,
    @OutStatus   NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @OutProductId = NULL;
    SET @OutStatus = NULL;

    DECLARE @MerchantId BIGINT = (
        SELECT TOP 1 Id FROM store.Merchant
         WHERE CompanyId = @CompanyId AND CustomerId = @CustomerId AND Status = 'approved'
    );
    IF @MerchantId IS NULL
    BEGIN
        SET @Mensaje = N'Vendedor no aprobado'; RETURN;
    END;

    DECLARE @Status NVARCHAR(20) = CASE WHEN @Submit = 1 THEN 'pending_review' ELSE 'draft' END;

    IF @ProductId IS NOT NULL
    BEGIN
        UPDATE store.MerchantProduct
           SET Name = @Name, Description = @Description, Price = @Price, Stock = @Stock,
               Category = @Category, ImageUrl = @ImageUrl,
               Status = @Status, UpdatedAt = GETUTCDATE()
         WHERE Id = @ProductId AND MerchantId = @MerchantId;
        IF @@ROWCOUNT = 0
        BEGIN
            SET @Mensaje = N'Producto no encontrado'; RETURN;
        END;
        SET @OutProductId = @ProductId;
    END
    ELSE
    BEGIN
        INSERT INTO store.MerchantProduct
            (MerchantId, CompanyId, ProductCode, Name, Description, Price, Stock, Category, ImageUrl, Status)
        VALUES
            (@MerchantId, @CompanyId,
             ISNULL(@Code, CONCAT('MP-', ABS(CHECKSUM(NEWID())) % 1000000)),
             @Name, @Description, @Price, @Stock, @Category, @ImageUrl, @Status);
        SET @OutProductId = SCOPE_IDENTITY();
    END;

    SET @OutStatus = @Status;
    SET @Resultado = 1;
    SET @Mensaje = CASE WHEN @Submit = 1 THEN N'Producto enviado a revisión' ELSE N'Borrador guardado' END;
END;
GO
