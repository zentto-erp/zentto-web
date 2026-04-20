-- usp_store_affiliate_admin_set_status — SQL Server 2012+
IF OBJECT_ID('dbo.usp_store_affiliate_admin_set_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_admin_set_status;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_admin_set_status
    @CompanyId   INT,
    @AffiliateId BIGINT,
    @Status      NVARCHAR(20),
    @Actor       NVARCHAR(60),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @Status NOT IN ('active','suspended','pending','rejected')
    BEGIN
        SET @Mensaje = N'Status inválido';
        RETURN;
    END;

    UPDATE store.Affiliate
       SET Status     = @Status,
           ApprovedAt = CASE WHEN @Status = 'active' THEN GETUTCDATE() ELSE ApprovedAt END,
           ApprovedBy = CASE WHEN @Status = 'active' THEN @Actor ELSE ApprovedBy END
     WHERE Id = @AffiliateId AND CompanyId = @CompanyId;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Mensaje = N'Afiliado no encontrado';
        RETURN;
    END;
    SET @Resultado = 1;
    SET @Mensaje = N'Estado actualizado';
END;
GO
