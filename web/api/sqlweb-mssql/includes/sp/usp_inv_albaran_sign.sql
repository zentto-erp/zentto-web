-- usp_inv_albaran_sign — SQL Server equivalent
-- Signs an albarán (EMITIDO → FIRMADO) and generates stock movements
IF OBJECT_ID('dbo.usp_inv_albaran_sign', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_inv_albaran_sign;
GO

CREATE PROCEDURE dbo.usp_inv_albaran_sign
    @AlbaranId   INT,
    @CompanyId   INT,
    @UserId      INT,
    @Firmante    NVARCHAR(200) = NULL,
    @Resultado   INT           OUTPUT,
    @MovsGenerados INT         OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @MovsGenerados = 0;

    DECLARE @Estado NVARCHAR(20), @Tipo NVARCHAR(20),
            @WhFrom NVARCHAR(20), @WhTo NVARCHAR(20), @AlbNum NVARCHAR(40);

    SELECT @Estado = Estado, @Tipo = Tipo,
           @WhFrom = WarehouseFrom, @WhTo = WarehouseTo, @AlbNum = Numero
    FROM inv.Albaran
    WHERE AlbaranId = @AlbaranId AND CompanyId = @CompanyId;

    IF @Estado IS NULL BEGIN SET @Mensaje = 'Albarán no encontrado'; RETURN; END
    IF @Estado <> 'EMITIDO' BEGIN SET @Mensaje = 'Solo se puede firmar desde estado EMITIDO'; RETURN; END

    DECLARE @MovType NVARCHAR(30), @WhCode NVARCHAR(20);
    IF @Tipo = 'DESPACHO'
    BEGIN SET @MovType = 'SALE_OUT';     SET @WhCode = ISNULL(@WhFrom, 'PRINCIPAL'); END
    ELSE IF @Tipo = 'RECEPCION'
    BEGIN SET @MovType = 'PURCHASE_IN';  SET @WhCode = ISNULL(@WhTo,   'PRINCIPAL'); END
    -- TRASLADO: movements handled by TrasladoMultiPaso workflow

    IF @MovType IS NOT NULL
    BEGIN
        INSERT INTO inv.StockMovement
            (CompanyId, ProductCode, MovementType, Quantity, UnitCost,
             WarehouseCode, SourceDocumentType, SourceDocumentId,
             MovementDate, CreatedByUserId, Notes)
        SELECT
            @CompanyId, l.ProductCode, @MovType,
            l.Cantidad, l.CostoUnitario,
            @WhCode, 'ALBARAN', @AlbaranId,
            GETUTCDATE(), @UserId, 'Albarán ' + @AlbNum
        FROM inv.AlbaranLinea l
        WHERE l.AlbaranId = @AlbaranId;

        SET @MovsGenerados = @@ROWCOUNT;
    END

    UPDATE inv.Albaran
    SET Estado = 'FIRMADO', FechaFirma = GETUTCDATE(),
        FirmadoPorId = @UserId,
        FirmadoPorNombre = ISNULL(@Firmante, 'Usuario #' + CAST(@UserId AS NVARCHAR(10)))
    WHERE AlbaranId = @AlbaranId;

    SET @Resultado = 1;
    SET @Mensaje = 'Albarán firmado. Movimientos generados: ' + CAST(@MovsGenerados AS NVARCHAR(10));
END;
GO
