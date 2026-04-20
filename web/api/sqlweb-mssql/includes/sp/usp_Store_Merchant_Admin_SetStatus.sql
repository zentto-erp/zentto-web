-- usp_store_merchant_admin_set_status — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_merchant_admin_set_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_merchant_admin_set_status;
GO

CREATE PROCEDURE dbo.usp_store_merchant_admin_set_status
    @CompanyId INT,
    @MerchantId  BIGINT,
    @Status    NVARCHAR(20),
    @Actor     NVARCHAR(60),
    @Reason    NVARCHAR(500) = NULL,
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    IF @Status NOT IN ('approved','rejected','suspended','pending')
    BEGIN
        SET @Mensaje = N'Status inválido'; RETURN;
    END;

    UPDATE store.Merchant
       SET Status         = @Status,
           ApprovedAt     = CASE WHEN @Status = 'approved' THEN GETUTCDATE() ELSE ApprovedAt END,
           ApprovedBy     = CASE WHEN @Status = 'approved' THEN @Actor ELSE ApprovedBy END,
           RejectionReason = CASE WHEN @Status IN ('rejected','suspended') THEN @Reason ELSE RejectionReason END
     WHERE Id = @MerchantId AND CompanyId = @CompanyId;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Mensaje = N'Vendedor no encontrado'; RETURN;
    END;
    SET @Resultado = 1;
    SET @Mensaje   = N'Estado actualizado';
END;
GO
