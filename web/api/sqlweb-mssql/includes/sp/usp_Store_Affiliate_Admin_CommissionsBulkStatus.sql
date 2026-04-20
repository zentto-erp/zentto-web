-- usp_store_affiliate_admin_commissions_bulk_status — SQL Server 2012+
-- Bulk-approve / bulk-mark-paid de comisiones para liquidación mensual.
-- El parámetro @Ids llega como CSV (ej. "12,45,78") por limitación de JSON/TVP en legacy.
IF OBJECT_ID('dbo.usp_store_affiliate_admin_commissions_bulk_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_store_affiliate_admin_commissions_bulk_status;
GO

CREATE PROCEDURE dbo.usp_store_affiliate_admin_commissions_bulk_status
    @CompanyId   INT,
    @Ids         NVARCHAR(MAX), -- CSV "1,2,3"
    @Status      NVARCHAR(20),
    @Actor       NVARCHAR(60),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @Updated     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Updated   = 0;

    IF @Status NOT IN ('approved','paid','reversed')
    BEGIN
        SET @Mensaje = N'Status inválido (solo approved/paid/reversed)';
        RETURN;
    END;

    IF @Ids IS NULL OR LEN(LTRIM(RTRIM(@Ids))) = 0
    BEGIN
        SET @Mensaje = N'Sin comisiones seleccionadas';
        RETURN;
    END;

    DECLARE @idTable TABLE (Id BIGINT);

    -- Parse CSV compatible con 2012 (STRING_SPLIT existe desde 2016).
    DECLARE @s NVARCHAR(MAX) = @Ids + ',', @pos INT = 1, @next INT = CHARINDEX(',', @s);
    WHILE @next > 0
    BEGIN
        DECLARE @token NVARCHAR(40) = LTRIM(RTRIM(SUBSTRING(@s, @pos, @next - @pos)));
        IF LEN(@token) > 0 AND ISNUMERIC(@token) = 1
            INSERT INTO @idTable (Id) VALUES (CAST(@token AS BIGINT));
        SET @pos = @next + 1;
        SET @next = CHARINDEX(',', @s, @pos);
    END;

    UPDATE c
       SET c.Status     = @Status,
           c.ApprovedAt = CASE WHEN @Status = 'approved' AND c.ApprovedAt IS NULL
                               THEN GETUTCDATE() ELSE c.ApprovedAt END,
           c.PaidAt     = CASE WHEN @Status = 'paid' AND c.PaidAt IS NULL
                               THEN GETUTCDATE() ELSE c.PaidAt END
      FROM store.AffiliateCommission c
      JOIN @idTable t ON t.Id = c.Id
     WHERE c.CompanyId = @CompanyId;

    SET @Updated   = @@ROWCOUNT;
    SET @Resultado = 1;
    SET @Mensaje   = CONCAT(@Updated, N' comisión(es) actualizada(s) a ', @Status, N' por ', @Actor);
END;
GO
