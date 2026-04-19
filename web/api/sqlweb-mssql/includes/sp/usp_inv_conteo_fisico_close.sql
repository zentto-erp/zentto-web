-- usp_inv_conteo_fisico_close — SQL Server equivalent
-- Closes a physical count sheet and generates AJUSTE stock movements
IF OBJECT_ID('dbo.usp_inv_conteo_fisico_close', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_inv_conteo_fisico_close;
GO

CREATE PROCEDURE dbo.usp_inv_conteo_fisico_close
    @HojaConteoId   INT,
    @CompanyId      INT,
    @UserId         INT,
    @Resultado      INT           OUTPUT,
    @AjustesGenerados INT         OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @AjustesGenerados = 0;

    DECLARE @Estado NVARCHAR(20), @WarehouseCode NVARCHAR(20);
    SELECT @Estado = Estado, @WarehouseCode = WarehouseCode
    FROM inv.HojaConteo
    WHERE HojaConteoId = @HojaConteoId AND CompanyId = @CompanyId;

    IF @Estado IS NULL
    BEGIN SET @Mensaje = 'Hoja de conteo no encontrada'; RETURN; END

    IF @Estado NOT IN ('BORRADOR','EN_PROCESO','APROBADA')
    BEGIN SET @Mensaje = 'La hoja no puede cerrarse desde estado: ' + @Estado; RETURN; END

    -- Generate adjustment movements for all counted lines with variance
    INSERT INTO inv.StockMovement
        (CompanyId, ProductCode, MovementType, Quantity, UnitCost,
         WarehouseCode, SourceDocumentType, SourceDocumentId,
         MovementDate, CreatedByUserId, Notes)
    SELECT
        @CompanyId,
        l.ProductCode,
        CASE WHEN (l.StockFisico - l.StockSistema) > 0 THEN 'ADJUSTMENT_IN' ELSE 'ADJUSTMENT_OUT' END,
        ABS(l.StockFisico - l.StockSistema),
        l.UnitCost,
        @WarehouseCode,
        'CONTEO_FISICO',
        @HojaConteoId,
        GETUTCDATE(),
        @UserId,
        'Ajuste por conteo físico CNT#' + CAST(@HojaConteoId AS NVARCHAR(10))
    FROM inv.HojaConteoLinea l
    WHERE l.HojaConteoId = @HojaConteoId
      AND l.StockFisico  IS NOT NULL
      AND (l.StockFisico - l.StockSistema) <> 0;

    SET @AjustesGenerados = @@ROWCOUNT;

    UPDATE inv.HojaConteo
    SET Estado = 'CERRADA', FechaCierre = GETUTCDATE()
    WHERE HojaConteoId = @HojaConteoId;

    SET @Resultado = 1;
    SET @Mensaje = 'Conteo cerrado. Ajustes generados: ' + CAST(@AjustesGenerados AS NVARCHAR(10));
END;
GO
