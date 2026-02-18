-- =============================================
-- Stored Procedure: Emitir Pedido (Transaccional)
-- Descripcion: 
--   - Emite un pedido comprometiendo inventario
--   - Si se factura despues, NO vuelve a descontar inventario
--   - Si se anula, reversa el inventario
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_pedido_tx')
    DROP PROCEDURE sp_emitir_pedido_tx
GO

CREATE PROCEDURE sp_emitir_pedido_tx
    @PedidoXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @ActualizarInventario BIT = 1,
    @CodUsuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @px XML;
    DECLARE @dx XML;
    DECLARE @NumFact NVARCHAR(60);
    DECLARE @Codigo NVARCHAR(60);
    DECLARE @Fecha DATETIME;
    DECLARE @FechaStr NVARCHAR(50);
    DECLARE @Total DECIMAL(18,4);
    DECLARE @TotalStr NVARCHAR(50);
    DECLARE @Nombre NVARCHAR(200);
    DECLARE @SerialTipo NVARCHAR(60);
    DECLARE @Vendedor NVARCHAR(60);
    
    BEGIN TRY
        SET @px = CAST(@PedidoXml AS XML);
        SET @dx = CAST(@DetalleXml AS XML);
        
        SET @NumFact = NULLIF(@px.value('(/pedido/@NUM_FACT)[1]', 'nvarchar(60)'), '');
        SET @Codigo = NULLIF(@px.value('(/pedido/@CODIGO)[1]', 'nvarchar(60)'), '');
        SET @FechaStr = NULLIF(@px.value('(/pedido/@FECHA)[1]', 'nvarchar(50)'), '');
        SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
        SET @TotalStr = NULLIF(@px.value('(/pedido/@TOTAL)[1]', 'nvarchar(50)'), '');
        SET @Total = CASE WHEN @TotalStr IS NULL THEN 0 ELSE CAST(@TotalStr AS DECIMAL(18,4)) END;
        SET @Nombre = ISNULL(NULLIF(@px.value('(/pedido/@NOMBRE)[1]', 'nvarchar(200)'), ''), '');
        SET @SerialTipo = ISNULL(NULLIF(@px.value('(/pedido/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
        SET @Vendedor = ISNULL(NULLIF(@px.value('(/pedido/@Vendedor)[1]', 'nvarchar(60)'), ''), '');
        
        IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
        BEGIN
            RAISERROR('missing_num_pedido', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Pedidos WHERE NUM_FACT = @NumFact)
        BEGIN
            RAISERROR('pedido_already_exists', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- 1. Insertar cabecera en Pedidos
        INSERT INTO Pedidos (
            NUM_FACT, SERIALTIPO, CODIGO, FECHA, NOMBRE, TOTAL,
            COD_USUARIO, ANULADA, FECHA_REPORTE, CANCELADA, Vendedor
        )
        SELECT 
            @NumFact, @SerialTipo, @Codigo, @Fecha, @Nombre, @Total,
            @CodUsuario, 0, @Fecha, 'N', @Vendedor;
        
        -- 2. Insertar detalle en Detalle_Pedidos
        INSERT INTO Detalle_Pedidos (
            NUM_FACT, SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD,
            PRECIO, TOTAL, ANULADA, Co_Usuario, Alicuota, PRECIO_DESCUENTO,
            Relacionada, RENGLON, Vendedor, Cod_alterno
        )
        SELECT 
            @NumFact,
            COALESCE(NULLIF(T.X.value('@SERIALTIPO', 'nvarchar(60)'), ''), @SerialTipo),
            NULLIF(T.X.value('@COD_SERV', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@DESCRIPCION', 'nvarchar(255)'), ''),
            @Fecha,
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL THEN 
                (CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END *
                 CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END)
                ELSE CAST(T.X.value('@TOTAL', 'nvarchar(50)') AS FLOAT) END,
            0,
            @CodUsuario,
            CASE WHEN NULLIF(T.X.value('@Alicuota', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@Alicuota', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN 
                CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END
                ELSE CAST(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS FLOAT) END,
            COALESCE(NULLIF(T.X.value('@Relacionada', 'nvarchar(10)'), ''), '0'),
            CASE WHEN NULLIF(T.X.value('@RENGLON', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@RENGLON', 'nvarchar(50)') AS FLOAT) END,
            COALESCE(NULLIF(T.X.value('@Vendedor', 'nvarchar(60)'), ''), @Vendedor),
            NULLIF(T.X.value('@Cod_alterno', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);
        
        -- 3. Comprometer inventario
        IF @ActualizarInventario = 1
        BEGIN
            -- Tabla temporal para detalles
            DECLARE @Items TABLE (
                COD_SERV NVARCHAR(60),
                CANTIDAD DECIMAL(18,4),
                PRECIO DECIMAL(18,4),
                ALICUOTA DECIMAL(18,4)
            );
            
            INSERT INTO @Items (COD_SERV, CANTIDAD, PRECIO, ALICUOTA)
            SELECT 
                NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), ''),
                CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
                CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
                CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END
            FROM @dx.nodes('/detalles/row') N(X);
            
            -- MovInvent
            INSERT INTO MovInvent (
                DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA
            )
            SELECT 
                @NumFact, I.COD_SERV, I.COD_SERV, @Fecha, 'Pedido:' + @NumFact, 'Pedido',
                ISNULL(INV.EXISTENCIA, 0), I.CANTIDAD, ISNULL(INV.EXISTENCIA, 0) - I.CANTIDAD,
                @CodUsuario, ISNULL(INV.COSTO_REFERENCIA, 0), I.ALICUOTA, I.PRECIO
            FROM @Items I
            INNER JOIN Inventario INV ON INV.CODIGO = I.COD_SERV
            WHERE I.COD_SERV IS NOT NULL AND I.CANTIDAD > 0;
            
            -- Descontar existencias
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Items WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV
            )
            UPDATE INV SET EXISTENCIA = ISNULL(INV.EXISTENCIA, 0) - T.TOTAL
            FROM Inventario INV INNER JOIN Totales T ON T.COD_SERV = INV.CODIGO;
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numPedido,
               (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows,
               @ActualizarInventario AS inventoryUpdated;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000); SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- SP para anular pedido
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_pedido_tx')
    DROP PROCEDURE sp_anular_pedido_tx
GO

CREATE PROCEDURE sp_anular_pedido_tx
    @NumPedido NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @YaAnulado BIT;
    
    SELECT @YaAnulado = CASE WHEN ANULADA = 1 OR ANULADA = '1' THEN 1 ELSE 0 END
    FROM Pedidos WHERE NUM_FACT = @NumPedido;
    
    IF @YaAnulado IS NULL BEGIN RAISERROR('pedido_not_found', 16, 1); RETURN; END
    IF @YaAnulado = 1 BEGIN RAISERROR('pedido_already_anulled', 16, 1); RETURN; END
    
    BEGIN TRANSACTION;
    
    UPDATE Pedidos SET ANULADA = 1, OBSERV = ISNULL(OBSERV, '') + ' [ANULADO: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
    WHERE NUM_FACT = @NumPedido;
    UPDATE Detalle_Pedidos SET ANULADA = 1 WHERE NUM_FACT = @NumPedido;
    
    -- Reversar inventario
    DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT);
    INSERT INTO @Detalles SELECT COD_SERV, ISNULL(CANTIDAD, 0) FROM Detalle_Pedidos WHERE NUM_FACT = @NumPedido AND ISNULL(ANULADA, 0) = 0;
    
    INSERT INTO MovInvent (DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO)
    SELECT @NumPedido + '_ANUL', D.COD_SERV, D.COD_SERV, @FechaAnulacion, 'Anulacion Pedido:' + @NumPedido, 'Anulacion Pedido',
           ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) + D.CANTIDAD, @CodUsuario
    FROM @Detalles D INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;
    
    ;WITH Totales AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV)
    UPDATE I SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) + T.TOTAL FROM Inventario I INNER JOIN Totales T ON T.COD_SERV = I.CODIGO;
    
    COMMIT TRANSACTION;
    SELECT CAST(1 AS BIT) AS ok, @NumPedido AS numPedido, 'Pedido anulado' AS mensaje;
    
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err2 NVARCHAR(4000); SET @Err2 = ERROR_MESSAGE(); RAISERROR(@Err2, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'sp_%_pedido_tx';
