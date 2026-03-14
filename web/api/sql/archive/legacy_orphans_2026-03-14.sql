-- Archive generated before dropping legacy orphan objects
-- Date: 2026-03-14
-- Database: DatqBoxWeb
-- Objects: 41

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_anular_compra_tx]
-- =============================================

CREATE PROCEDURE sp_anular_compra_tx
    @NumFact NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @FechaAnulacion DATETIME;
    DECLARE @CodProveedor NVARCHAR(60);
    DECLARE @FechaCompra DATETIME;
    DECLARE @YaAnulada BIT;
    
    BEGIN TRY
        SET @FechaAnulacion = GETDATE();
        
        -- ============================================
        -- 1. Validar que la compra existe
        -- ============================================
        SELECT 
            @CodProveedor = COD_PROVEEDOR,
            @FechaCompra = FECHA,
            @YaAnulada = CASE WHEN ANULADA = 1 OR ANULADA = '1' THEN 1 ELSE 0 END
        FROM Compras
        WHERE NUM_FACT = @NumFact;
        
        IF @CodProveedor IS NULL
        BEGIN
            RAISERROR('compra_not_found', 16, 1);
            RETURN;
        END
        
        IF @YaAnulada = 1
        BEGIN
            RAISERROR('compra_already_anulled', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- ============================================
        -- 2. Marcar compra como anulada
        -- ============================================
        UPDATE Compras
        SET ANULADA = 1,
            CONCEPTO = ISNULL(CONCEPTO, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
        WHERE NUM_FACT = @NumFact;
        
        -- ============================================
        -- 3. Anular detalle
        -- ============================================
        UPDATE Detalle_Compras
        SET ANULADA = 1
        WHERE NUM_FACT = @NumFact;
        
        -- ============================================
        -- 4. Revertir Inventario (restar lo que se habÃ­a sumado)
        -- ============================================
        -- Obtener detalles de la compra para revertir
        DECLARE @Detalles TABLE (
            CODIGO NVARCHAR(60),
            CANTIDAD FLOAT
        );
        
        INSERT INTO @Detalles (CODIGO, CANTIDAD)
        SELECT 
            CODIGO,
            ISNULL(CANTIDAD, 0)
        FROM Detalle_Compras
        WHERE NUM_FACT = @NumFact
          AND ISNULL(ANULADA, 0) = 0;
        
        -- Insertar movimiento de anulaciÃ³n en MovInvent
        INSERT INTO MovInvent (
            DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO,
            CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
            PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA, ANULADA
        )
        SELECT 
            @NumFact + '_ANUL',
            D.CODIGO,
            D.CODIGO,
            @FechaAnulacion,
            'Anulacion Compra:' + @NumFact + ' - ' + @Motivo,
            'Anulacion Ingreso',
            ISNULL(I.EXISTENCIA, 0),
            D.CANTIDAD,
            ISNULL(I.EXISTENCIA, 0) - D.CANTIDAD,
            @CodUsuario,
            ISNULL(I.COSTO_REFERENCIA, 0),
            0,
            ISNULL(I.PRECIO_VENTA, 0),
            0
        FROM @Detalles D
        INNER JOIN Inventario I ON I.CODIGO = D.CODIGO
        WHERE D.CODIGO IS NOT NULL AND D.CANTIDAD > 0;
        
        -- Restar del inventario (revertir el ingreso)
        ;WITH Totales AS (
            SELECT CODIGO, SUM(CANTIDAD) AS TOTAL
            FROM @Detalles
            WHERE CODIGO IS NOT NULL
            GROUP BY CODIGO
        )
        UPDATE I 
        SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) - T.TOTAL
        FROM Inventario I
        INNER JOIN Totales T ON T.CODIGO = I.CODIGO;
        
        -- ============================================
        -- 5. Anular CxP (marcar como anulada en P_Pagar)
        -- ============================================
        -- Marcar como anulada (no eliminar, mantener historial)
        UPDATE P_Pagar
        SET PAID = 1,
            PEND = 0,
            SALDO = 0
        WHERE DOCUMENTO = @NumFact
          AND TIPO = 'FACT'
          AND CODIGO = @CodProveedor;
        
        -- ============================================
        -- 6. Recalcular saldos del proveedor
        -- ============================================
        DECLARE @SaldoTotal FLOAT;
        
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0)
        FROM P_Pagar 
        WHERE CODIGO = @CodProveedor 
        AND PAID = 0;
        
        UPDATE Proveedores 
        SET SALDO_TOT = @SaldoTotal,
            SALDO_30 = @SaldoTotal
        WHERE CODIGO = @CodProveedor;
        
        COMMIT TRANSACTION;
        
        -- Retornar resultado
        SELECT 
            CAST(1 AS BIT) AS ok,
            @NumFact AS numFact,
            @CodProveedor AS codProveedor,
            'Compra anulada exitosamente' AS mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_anular_factura_tx]
-- =============================================

CREATE PROCEDURE dbo.sp_anular_factura_tx
  @NumFact NVARCHAR(60),
  @CodUsuario NVARCHAR(60) = N'API',
  @Motivo NVARCHAR(500) = N''
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @codCliente NVARCHAR(20);
  SELECT TOP 1 @codCliente = CODIGO FROM dbo.Facturas WHERE NUM_FACT = @NumFact;

  IF @codCliente IS NULL
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @NumFact AS numFact, CAST(NULL AS NVARCHAR(20)) AS codCliente, N'Factura no existe' AS mensaje;
    RETURN;
  END;

  IF EXISTS (SELECT 1 FROM dbo.Facturas WHERE NUM_FACT = @NumFact AND ISNULL(ANULADA,0) = 1)
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @NumFact AS numFact, @codCliente AS codCliente, N'Factura ya anulada' AS mensaje;
    RETURN;
  END;

  UPDATE dbo.Facturas
  SET ANULADA = 1,
      CANCELADA = N'N',
      OBSERV = ISNULL(OBSERV, N'') + CASE WHEN LEN(ISNULL(OBSERV,N''))>0 THEN N' ' ELSE N'' END + N'[ANULADA] ' + ISNULL(@Motivo,N''),
      COD_USUARIO = @CodUsuario,
      FECHA_REPORTE = GETDATE()
  WHERE NUM_FACT = @NumFact;

  ;WITH X AS (
    SELECT COD_SERV, SUM(CANTIDAD) AS TotalCantidad
    FROM dbo.Detalle_facturas
    WHERE NUM_FACT = @NumFact
    GROUP BY COD_SERV
  )
  UPDATE i
  SET i.EXISTENCIA = ISNULL(i.EXISTENCIA,0) + x.TotalCantidad
  FROM dbo.Inventario i
  INNER JOIN X x ON x.COD_SERV = i.CODIGO;

  UPDATE dbo.P_Cobrar
  SET PEND = 0, SALDO = 0, PAID = 1, OBS = ISNULL(OBS, N'') + N' [ANULADO]'
  WHERE DOCUMENTO = @NumFact AND TIPO = 'FACT';

  SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @codCliente AS codCliente, N'Factura anulada' AS mensaje;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_anular_presupuesto_tx]
-- =============================================

CREATE PROCEDURE sp_anular_presupuesto_tx
    @NumFact NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @CodCliente NVARCHAR(60);
    DECLARE @YaAnulada BIT;

    SELECT @CodCliente = CODIGO, @YaAnulada = CASE WHEN ANULADA = 1 THEN 1 ELSE 0 END
    FROM Presupuestos WHERE NUM_FACT = @NumFact;

    IF @CodCliente IS NULL
    BEGIN
        RAISERROR('presupuesto_not_found', 16, 1);
        RETURN;
    END
    IF @YaAnulada = 1
    BEGIN
        RAISERROR('presupuesto_already_anulled', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Presupuestos SET ANULADA = 1, OBSERV = ISNULL(OBSERV, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']' WHERE NUM_FACT = @NumFact;
        UPDATE Detalle_Presupuestos SET ANULADA = 1 WHERE NUM_FACT = @NumFact;

        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT, RELACIONADA INT, COD_ALTERNO NVARCHAR(60));
        INSERT INTO @Detalles (COD_SERV, CANTIDAD, RELACIONADA, COD_ALTERNO)
        SELECT COD_SERV, ISNULL(CANTIDAD, 0), CASE WHEN Relacionada = 1 THEN 1 ELSE 0 END, Cod_Alterno
        FROM Detalle_Presupuestos WHERE NUM_FACT = @NumFact AND ISNULL(ANULADA, 0) = 0;

        INSERT INTO MovInvent (DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA, ANULADA)
        SELECT @NumFact + '_ANUL', D.COD_SERV, D.COD_SERV, @FechaAnulacion, 'Anulacion Presupuesto:' + @NumFact + ' - ' + @Motivo, 'Anulacion Egreso',
            ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) + D.CANTIDAD, @CodUsuario, ISNULL(I.COSTO_REFERENCIA, 0), 0, ISNULL(I.PRECIO_VENTA, 0), 0
        FROM @Detalles D INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

        ;WITH Totales AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV)
        UPDATE I SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) + T.TOTAL FROM Inventario I INNER JOIN Totales T ON T.COD_SERV = I.CODIGO;

        ;WITH AuxTotales AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE RELACIONADA = 1 AND COD_ALTERNO IS NOT NULL GROUP BY COD_ALTERNO)
        UPDATE IA SET CANTIDAD = ISNULL(IA.CANTIDAD, 0) + A.TOTAL FROM Inventario_Aux IA INNER JOIN AuxTotales A ON A.COD_ALTERNO = IA.CODIGO;

        UPDATE P_Cobrar SET PAID = 1, PEND = 0, SALDO = 0 WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;
        IF @@ROWCOUNT = 0
            UPDATE P_CobrarC SET PAID = 1, PEND = 0, SALDO = 0 WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;

        DECLARE @SaldoTotal FLOAT;
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_Cobrar WHERE CODIGO = @CodCliente AND PAID = 0;
        IF @SaldoTotal IS NULL
            SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_CobrarC WHERE CODIGO = @CodCliente AND PAID = 0;
        UPDATE Clientes SET SALDO_TOT = ISNULL(@SaldoTotal, 0), SALDO_30 = ISNULL(@SaldoTotal, 0) WHERE CODIGO = @CodCliente;

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @CodCliente AS codCliente, 'Presupuesto anulada' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_emitir_compra_tx]
-- =============================================

CREATE PROCEDURE sp_emitir_compra_tx
    @CompraXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @ActualizarInventario BIT = 1,
    @GenerarCxP BIT = 1,
    @ActualizarSaldosProveedor BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @cx XML;
    DECLARE @dx XML;
    DECLARE @NumFact NVARCHAR(60);
    DECLARE @CodProveedor NVARCHAR(60);
    DECLARE @Fecha DATETIME;
    DECLARE @FechaStr NVARCHAR(50);
    DECLARE @Total DECIMAL(18,4);
    DECLARE @TotalStr NVARCHAR(50);
    DECLARE @CodUsuario NVARCHAR(60);
    DECLARE @Tipo NVARCHAR(30);
    DECLARE @Nombre NVARCHAR(200);
    DECLARE @Rif NVARCHAR(50);
    DECLARE @Concepto NVARCHAR(500);
    
    BEGIN TRY
        -- Convertir XML
        SET @cx = CAST(@CompraXml AS XML);
        SET @dx = CAST(@DetalleXml AS XML);
        
        -- Extraer datos de la compra
        SET @NumFact = NULLIF(@cx.value('(/compra/@NUM_FACT)[1]', 'nvarchar(60)'), '');
        SET @CodProveedor = NULLIF(@cx.value('(/compra/@COD_PROVEEDOR)[1]', 'nvarchar(60)'), '');
        SET @FechaStr = NULLIF(@cx.value('(/compra/@FECHA)[1]', 'nvarchar(50)'), '');
        SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
        SET @TotalStr = NULLIF(@cx.value('(/compra/@TOTAL)[1]', 'nvarchar(50)'), '');
        SET @Total = CASE WHEN @TotalStr IS NULL THEN 0 ELSE CAST(@TotalStr AS DECIMAL(18,4)) END;
        SET @CodUsuario = ISNULL(NULLIF(@cx.value('(/compra/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), 'API');
        SET @Tipo = UPPER(ISNULL(NULLIF(@cx.value('(/compra/@TIPO)[1]', 'nvarchar(30)'), ''), 'CONTADO'));
        SET @Nombre = ISNULL(NULLIF(@cx.value('(/compra/@NOMBRE)[1]', 'nvarchar(200)'), ''), '');
        SET @Rif = ISNULL(NULLIF(@cx.value('(/compra/@RIF)[1]', 'nvarchar(50)'), ''), '');
        SET @Concepto = NULLIF(@cx.value('(/compra/@CONCEPTO)[1]', 'nvarchar(500)'), '');
        
        IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
        BEGIN
            RAISERROR('missing_num_fact', 16, 1);
            RETURN;
        END
        
        -- Verificar que la compra no existe
        IF EXISTS (SELECT 1 FROM Compras WHERE NUM_FACT = @NumFact)
        BEGIN
            RAISERROR('compra_already_exists', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- ============================================
        -- 1. Insertar cabecera en Compras
        -- ============================================
        INSERT INTO Compras (
            NUM_FACT, COD_PROVEEDOR, FECHA, NOMBRE, RIF, TOTAL,
            TIPO, CONCEPTO, COD_USUARIO, ANULADA, FECHARECIBO
        )
        VALUES (
            @NumFact, @CodProveedor, @Fecha, @Nombre, @Rif, @Total,
            @Tipo, @Concepto, @CodUsuario, 0, @Fecha
        );
        
        -- ============================================
        -- 2. Insertar detalle en Detalle_Compras
        -- ============================================
        INSERT INTO Detalle_Compras (
            NUM_FACT, CODIGO, Referencia, DESCRIPCION, FECHA, CANTIDAD,
            PRECIO_COSTO, Alicuota, Co_Usuario
        )
        SELECT 
            @NumFact,
            NULLIF(T.X.value('@CODIGO', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@REFERENCIA', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@DESCRIPCION', 'nvarchar(200)'), ''),
            @Fecha,
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL 
                 THEN 0 
                 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) 
            END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_COSTO', 'nvarchar(50)'), '') IS NULL 
                 THEN 0 
                 ELSE CAST(T.X.value('@PRECIO_COSTO', 'nvarchar(50)') AS DECIMAL(18,4)) 
            END,
            CASE WHEN NULLIF(T.X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL 
                 THEN 0 
                 ELSE CAST(T.X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) 
            END,
            @CodUsuario
        FROM @dx.nodes('/detalles/row') T(X);
        
        -- ============================================
        -- 3. Actualizar Inventario (Ingreso)
        -- ============================================
        IF @ActualizarInventario = 1
        BEGIN
            -- Tabla temporal para evitar XML en GROUP BY
            DECLARE @Items TABLE (
                COD_SERV NVARCHAR(60),
                CANTIDAD DECIMAL(18,4),
                PRECIO_COSTO DECIMAL(18,4),
                ALICUOTA DECIMAL(18,4)
            );
            
            INSERT INTO @Items (COD_SERV, CANTIDAD, PRECIO_COSTO, ALICUOTA)
            SELECT 
                NULLIF(X.value('@CODIGO', 'nvarchar(60)'), ''),
                CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL 
                     THEN 0 
                     ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) 
                END,
                CASE WHEN NULLIF(X.value('@PRECIO_COSTO', 'nvarchar(50)'), '') IS NULL 
                     THEN 0 
                     ELSE CAST(X.value('@PRECIO_COSTO', 'nvarchar(50)') AS DECIMAL(18,4)) 
                END,
                CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL 
                     THEN 0 
                     ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) 
                END
            FROM @dx.nodes('/detalles/row') N(X);
            
            -- Insertar en MovInvent (historial)
            INSERT INTO MovInvent (
                DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA
            )
            SELECT 
                @NumFact,
                I.COD_SERV,
                I.COD_SERV,
                @Fecha,
                'Compra:' + @NumFact,
                'Ingreso',
                ISNULL(INV.EXISTENCIA, 0),
                I.CANTIDAD,
                ISNULL(INV.EXISTENCIA, 0) + I.CANTIDAD,
                @CodUsuario,
                I.PRECIO_COSTO,
                I.ALICUOTA,
                ISNULL(INV.PRECIO_VENTA, 0)
            FROM @Items I
            INNER JOIN Inventario INV ON INV.CODIGO = I.COD_SERV
            WHERE I.COD_SERV IS NOT NULL AND I.CANTIDAD > 0;
            
            -- Actualizar existencias en Inventario
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL
                FROM @Items
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            UPDATE INV 
            SET EXISTENCIA = ISNULL(INV.EXISTENCIA, 0) + T.TOTAL
            FROM Inventario INV
            INNER JOIN Totales T ON T.COD_SERV = INV.CODIGO;
        END
        
        -- ============================================
        -- 4. Generar CxP (si es crÃ©dito)
        -- ============================================
        IF @GenerarCxP = 1 AND @Tipo = 'CREDITO' AND @Total > 0
        BEGIN
            DECLARE @SaldoPrevio FLOAT;
            
            -- Obtener saldo previo del proveedor
            SELECT TOP 1 @SaldoPrevio = ISNULL(SALDO, 0)
            FROM P_Pagar
            WHERE CODIGO = @CodProveedor
            ORDER BY FECHA DESC;
            
            SET @SaldoPrevio = ISNULL(@SaldoPrevio, 0);
            
            -- Eliminar CxP previa del documento si existe
            DELETE FROM P_Pagar
            WHERE CODIGO = @CodProveedor
              AND DOCUMENTO = @NumFact
              AND TIPO = 'FACT';
            
            -- Insertar nueva CxP
            INSERT INTO P_Pagar (
                CODIGO, FECHA, DOCUMENTO, TIPO, DEBE, HABER, PEND, SALDO, ISRL, OBS
            )
            VALUES (
                @CodProveedor, @Fecha, @NumFact, 'FACT', 0, CAST(@Total AS FLOAT),
                CAST(@Total AS FLOAT), @SaldoPrevio + CAST(@Total AS FLOAT), '', ''
            );
        END
        
        -- ============================================
        -- 5. Actualizar saldos del proveedor
        -- ============================================
        IF @ActualizarSaldosProveedor = 1 AND @CodProveedor IS NOT NULL AND LTRIM(RTRIM(@CodProveedor)) <> ''
        BEGIN
            ;WITH Saldos AS (
                SELECT 
                    ISNULL(SUM(CASE WHEN TIPO = 'FACT' THEN PEND ELSE 0 END), 0) AS SALDO_TOT,
                    ISNULL(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, GETDATE()) <= 30 THEN PEND ELSE 0 END), 0) AS SALDO_30,
                    ISNULL(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, GETDATE()) > 30 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 60 THEN PEND ELSE 0 END), 0) AS SALDO_60,
                    ISNULL(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, GETDATE()) > 60 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 90 THEN PEND ELSE 0 END), 0) AS SALDO_90,
                    ISNULL(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, GETDATE()) > 90 THEN PEND ELSE 0 END), 0) AS SALDO_91
                FROM P_Pagar
                WHERE CODIGO = @CodProveedor
            )
            UPDATE P
            SET SALDO_TOT = S.SALDO_TOT,
                SALDO_30 = S.SALDO_30,
                SALDO_60 = S.SALDO_60,
                SALDO_90 = S.SALDO_90,
                SALDO_91 = S.SALDO_91
            FROM Proveedores P
            CROSS JOIN Saldos S
            WHERE P.CODIGO = @CodProveedor;
        END
        
        COMMIT TRANSACTION;
        
        -- Retornar resultado
        SELECT 
            CAST(1 AS BIT) AS ok,
            @NumFact AS numFact,
            (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows,
            @ActualizarInventario AS inventoryUpdated,
            CASE WHEN @GenerarCxP = 1 AND @Tipo = 'CREDITO' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS cxpGenerated;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_emitir_cotizacion_tx]
-- =============================================

CREATE PROCEDURE sp_emitir_cotizacion_tx
    @CotizacionXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @CodUsuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @cx XML;
    DECLARE @dx XML;
    DECLARE @NumFact NVARCHAR(60);
    DECLARE @Codigo NVARCHAR(60);
    DECLARE @Fecha DATETIME;
    DECLARE @FechaStr NVARCHAR(50);
    DECLARE @Total DECIMAL(18,4);
    DECLARE @TotalStr NVARCHAR(50);
    DECLARE @Nombre NVARCHAR(200);
    DECLARE @SerialTipo NVARCHAR(60);
    
    BEGIN TRY
        SET @cx = CAST(@CotizacionXml AS XML);
        SET @dx = CAST(@DetalleXml AS XML);
        
        SET @NumFact = NULLIF(@cx.value('(/cotizacion/@NUM_FACT)[1]', 'nvarchar(60)'), '');
        SET @Codigo = NULLIF(@cx.value('(/cotizacion/@CODIGO)[1]', 'nvarchar(60)'), '');
        SET @FechaStr = NULLIF(@cx.value('(/cotizacion/@FECHA)[1]', 'nvarchar(50)'), '');
        SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
        SET @TotalStr = NULLIF(@cx.value('(/cotizacion/@TOTAL)[1]', 'nvarchar(50)'), '');
        SET @Total = CASE WHEN @TotalStr IS NULL THEN 0 ELSE CAST(@TotalStr AS DECIMAL(18,4)) END;
        SET @Nombre = ISNULL(NULLIF(@cx.value('(/cotizacion/@NOMBRE)[1]', 'nvarchar(200)'), ''), '');
        SET @SerialTipo = ISNULL(NULLIF(@cx.value('(/cotizacion/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
        
        IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
        BEGIN
            RAISERROR('missing_num_fact', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Cotizacion WHERE NUM_FACT = @NumFact)
        BEGIN
            RAISERROR('cotizacion_already_exists', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- 1. Insertar cabecera
        INSERT INTO Cotizacion (
            NUM_FACT, SERIALTIPO, CODIGO, FECHA, NOMBRE, TOTAL,
            COD_USUARIO, ANULADA, FECHA_REPORTE, CANCELADA
        )
        SELECT 
            @NumFact, @SerialTipo, @Codigo, @Fecha, @Nombre, @Total,
            @CodUsuario, 0, @Fecha, 'N';
        
        -- 2. Insertar detalle
        INSERT INTO Detalle_Cotizacion (
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
            NULLIF(T.X.value('@Vendedor', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@Cod_alterno', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);
        
        COMMIT TRANSACTION;
        
        SELECT 
            CAST(1 AS BIT) AS ok,
            @NumFact AS numFact,
            (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_emitir_factura_tx]
-- =============================================

CREATE PROCEDURE dbo.sp_emitir_factura_tx
  @FacturaXml NVARCHAR(MAX),
  @DetalleXml NVARCHAR(MAX),
  @FormasPagoXml NVARCHAR(MAX) = NULL,
  @ActualizarInventario BIT = 1,
  @GenerarCxC BIT = 1,
  @CxcTable NVARCHAR(20) = N'P_Cobrar',
  @FormaPagoTable NVARCHAR(128) = N'Detalle_FormaPagoFacturas',
  @ActualizarSaldosCliente BIT = 1
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @fx XML = TRY_CAST(@FacturaXml AS XML);
  DECLARE @dx XML = TRY_CAST(@DetalleXml AS XML);
  DECLARE @px XML = TRY_CAST(@FormasPagoXml AS XML);
  IF @fx IS NULL OR @dx IS NULL
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, N'' AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  DECLARE @numFact NVARCHAR(60) = @fx.value('(/factura/@NUM_FACT)[1]', 'NVARCHAR(60)');
  DECLARE @codigo NVARCHAR(20) = @fx.value('(/factura/@CODIGO)[1]', 'NVARCHAR(20)');
  DECLARE @fecha DATETIME = ISNULL(TRY_CONVERT(DATETIME, @fx.value('(/factura/@FECHA)[1]', 'NVARCHAR(30)')), GETDATE());
  DECLARE @total FLOAT = ISNULL(TRY_CONVERT(FLOAT, @fx.value('(/factura/@TOTAL)[1]', 'NVARCHAR(50)')), 0);
  DECLARE @usuario NVARCHAR(20) = NULLIF(@fx.value('(/factura/@COD_USUARIO)[1]', 'NVARCHAR(20)'), N'');
  DECLARE @serial NVARCHAR(40) = NULLIF(@fx.value('(/factura/@SERIALTIPO)[1]', 'NVARCHAR(40)'), N'');
  DECLARE @tipoOrden NVARCHAR(6) = ISNULL(NULLIF(@fx.value('(/factura/@TIPO_ORDEN)[1]', 'NVARCHAR(6)'), N''), N'1');

  IF @numFact IS NULL OR LTRIM(RTRIM(@numFact)) = N''
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, N'' AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  IF EXISTS (SELECT 1 FROM dbo.Facturas WHERE NUM_FACT = @numFact)
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @numFact AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  INSERT INTO dbo.Facturas (NUM_FACT, CODIGO, FECHA, TOTAL, COD_USUARIO, SERIALTIPO, Tipo_Orden, NOMBRE, RIF, PAGO, CANCELADA, ANULADA)
  VALUES (
    @numFact,
    @codigo,
    @fecha,
    @total,
    ISNULL(@usuario, N'API'),
    @serial,
    @tipoOrden,
    NULLIF(@fx.value('(/factura/@NOMBRE)[1]', 'NVARCHAR(255)'), N''),
    NULLIF(@fx.value('(/factura/@RIF)[1]', 'NVARCHAR(20)'), N''),
    NULLIF(@fx.value('(/factura/@PAGO)[1]', 'NVARCHAR(20)'), N''),
    N'N',
    0
  );

  INSERT INTO dbo.Detalle_facturas (NUM_FACT, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, RELACIONADA, COD_ALTERNO, SERIALTIPO)
  SELECT
    @numFact,
    NULLIF(T.r.value('@COD_SERV', 'NVARCHAR(80)'), N''),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@CANTIDAD', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@PRECIO', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@ALICUOTA', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@TOTAL', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@PRECIO_DESCUENTO', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(INT, T.r.value('@RELACIONADA', 'NVARCHAR(10)')), 0),
    NULLIF(T.r.value('@COD_ALTERNO', 'NVARCHAR(50)'), N''),
    ISNULL(NULLIF(T.r.value('@SERIALTIPO', 'NVARCHAR(40)'), N''), @serial)
  FROM @dx.nodes('/detalles/row') T(r);

  DECLARE @montoEfectivo FLOAT = 0, @montoCheque FLOAT = 0, @montoTarjeta FLOAT = 0, @saldoPendiente FLOAT = 0;
  IF @px IS NOT NULL
  BEGIN
    ;WITH FP AS (
      SELECT
        UPPER(ISNULL(NULLIF(T.r.value('@TIPO', 'NVARCHAR(30)'), N''), N'')) AS TIPO,
        ISNULL(TRY_CONVERT(FLOAT, T.r.value('@MONTO', 'NVARCHAR(50)')), 0) AS MONTO
      FROM @px.nodes('/formasPago/row') T(r)
    )
    SELECT
      @montoEfectivo = ISNULL(SUM(CASE WHEN TIPO = 'EFECTIVO' THEN MONTO ELSE 0 END),0),
      @montoCheque = ISNULL(SUM(CASE WHEN TIPO = 'CHEQUE' THEN MONTO ELSE 0 END),0),
      @montoTarjeta = ISNULL(SUM(CASE WHEN TIPO LIKE 'TARJETA%' OR TIPO LIKE 'TICKET%' THEN MONTO ELSE 0 END),0),
      @saldoPendiente = ISNULL(SUM(CASE WHEN TIPO = 'SALDO PENDIENTE' THEN MONTO ELSE 0 END),0)
    FROM FP;
  END;

  UPDATE dbo.Facturas
  SET MONTO_EFECT = @montoEfectivo,
      MONTO_CHEQUE = @montoCheque,
      MONTO_TARJETA = @montoTarjeta,
      ABONO = ISNULL(TOTAL,0) - @saldoPendiente,
      SALDO = @saldoPendiente,
      CANCELADA = CASE WHEN @saldoPendiente > 0 THEN 'N' ELSE 'S' END,
      FECHA_REPORTE = GETDATE()
  WHERE NUM_FACT = @numFact;

  IF @GenerarCxC = 1 AND @saldoPendiente > 0
  BEGIN
    INSERT INTO dbo.P_Cobrar (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, SERIALTIPO, Tipo_Orden)
    VALUES (@codigo, ISNULL(@usuario, N'API'), @fecha, @numFact, @saldoPendiente, @saldoPendiente, @saldoPendiente, N'FACT', @serial, @tipoOrden);
  END;

  IF @ActualizarInventario = 1
  BEGIN
    ;WITH X AS (
      SELECT COD_SERV, SUM(CANTIDAD) AS TotalCantidad
      FROM dbo.Detalle_facturas
      WHERE NUM_FACT = @numFact
      GROUP BY COD_SERV
    )
    UPDATE i
    SET i.EXISTENCIA = ISNULL(i.EXISTENCIA,0) - x.TotalCantidad
    FROM dbo.Inventario i
    INNER JOIN X x ON x.COD_SERV = i.CODIGO;
  END;

  SELECT
    CAST(1 AS BIT) AS ok,
    @numFact AS numFact,
    (SELECT COUNT(1) FROM dbo.Detalle_facturas WHERE NUM_FACT = @numFact) AS detalleRows,
    @montoEfectivo AS montoEfectivo,
    @montoCheque AS montoCheque,
    @montoTarjeta AS montoTarjeta,
    @saldoPendiente AS saldoPendiente,
    (ISNULL(@total,0) - @saldoPendiente) AS abono;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[sp_emitir_presupuesto_tx]
-- =============================================

CREATE PROCEDURE [dbo].[sp_emitir_presupuesto_tx]
    @PresupuestoXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @FormasPagoXml NVARCHAR(MAX) = NULL,
    @ActualizarInventario BIT = 1,
    @GenerarCxC BIT = 1,
    @CxcTable NVARCHAR(20) = N'P_Cobrar',
    @FormaPagoTable NVARCHAR(128) = N'Detalle_FormaPagoCotizacion',
    @ActualizarSaldosCliente BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    DECLARE @StartedTran BIT = 0;
    DECLARE @SaveName SYSNAME = N'sp_emitir_presupuesto_tx_save';
    DECLARE @fx XML = CAST(@PresupuestoXml AS XML);
    DECLARE @dx XML = CAST(@DetalleXml AS XML);
    DECLARE @px XML;
    IF @FormasPagoXml IS NOT NULL AND LTRIM(RTRIM(@FormasPagoXml)) <> ''
        SET @px = CAST(@FormasPagoXml AS XML);

    DECLARE @NumFact NVARCHAR(60), @Codigo NVARCHAR(60), @Pago NVARCHAR(30), @CodUsuario NVARCHAR(60);
    DECLARE @SerialTipo NVARCHAR(60), @TipoOrden NVARCHAR(80), @Observ NVARCHAR(4000);
    DECLARE @FechaStr NVARCHAR(50), @FechaReporteStr NVARCHAR(50), @Fecha DATETIME, @FechaReporte DATETIME, @Total DECIMAL(18,4);

    SET @NumFact = NULLIF(@fx.value('(/presupuesto/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    IF @NumFact IS NULL SET @NumFact = NULLIF(@fx.value('(/factura/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    SET @Codigo = NULLIF(@fx.value('(/presupuesto/@CODIGO)[1]', 'nvarchar(60)'), '');
    IF @Codigo IS NULL SET @Codigo = NULLIF(@fx.value('(/factura/@CODIGO)[1]', 'nvarchar(60)'), '');
    SET @Pago = UPPER(ISNULL(NULLIF(@fx.value('(/presupuesto/@PAGO)[1]', 'nvarchar(30)'), ''), ''));
    IF @Pago = '' SET @Pago = UPPER(ISNULL(NULLIF(@fx.value('(/factura/@PAGO)[1]', 'nvarchar(30)'), ''), ''));
    SET @CodUsuario = ISNULL(NULLIF(@fx.value('(/presupuesto/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), 'API');
    IF @CodUsuario = 'API' SET @CodUsuario = ISNULL(NULLIF(@fx.value('(/factura/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), 'API');
    -- SERIALTIPO = serial mÃ¡quina fiscal; Tipo_Orden = nÃºmero de memoria fÃ­sica (1, 2, ... si se reemplaza la memoria)
    SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/presupuesto/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    IF @SerialTipo = '' SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/factura/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@Tipo_orden)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/factura/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '');
    SET @Observ = NULLIF(@fx.value('(/presupuesto/@OBSERV)[1]', 'nvarchar(4000)'), '');
    IF @Observ IS NULL SET @Observ = NULLIF(@fx.value('(/factura/@OBSERV)[1]', 'nvarchar(4000)'), '');
    SET @FechaStr = NULLIF(@fx.value('(/presupuesto/@FECHA)[1]', 'nvarchar(50)'), '');
    IF @FechaStr IS NULL SET @FechaStr = NULLIF(@fx.value('(/factura/@FECHA)[1]', 'nvarchar(50)'), '');
    SET @FechaReporteStr = NULLIF(@fx.value('(/presupuesto/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    IF @FechaReporteStr IS NULL SET @FechaReporteStr = NULLIF(@fx.value('(/factura/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    SET @FechaReporte = CASE WHEN ISDATE(@FechaReporteStr) = 1 THEN CAST(@FechaReporteStr AS DATETIME) ELSE @Fecha END;
    SET @Total = CASE WHEN NULLIF(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL
        THEN (CASE WHEN NULLIF(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END)
        ELSE CAST(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END;

    IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
    BEGIN
        RAISERROR('missing_num_fact', 16, 1);
        RETURN;
    END

    IF @CxcTable NOT IN (N'P_Cobrar', N'P_CobrarC') SET @CxcTable = N'P_Cobrar';
    IF @FormaPagoTable NOT IN (N'Detalle_FormaPagoFacturas', N'Detalle_FormaPagoCotizacion') SET @FormaPagoTable = N'Detalle_FormaPagoCotizacion';

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRAN; SET @StartedTran = 1; END
        ELSE SAVE TRANSACTION @SaveName;

        INSERT INTO dbo.Presupuestos (NUM_FACT, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, SERIALTIPO, Tipo_orden, OBSERV)
        VALUES (@NumFact, @Codigo, @Fecha, @FechaReporte, @Pago, @Total, @CodUsuario, @SerialTipo, @TipoOrden, @Observ);

        INSERT INTO dbo.Detalle_Presupuestos (NUM_FACT, SERIALTIPO, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno)
        SELECT
            CASE WHEN NULLIF(T.X.value('@NUM_FACT', 'nvarchar(60)'), '') IS NULL THEN @NumFact ELSE T.X.value('@NUM_FACT', 'nvarchar(60)') END,
            CASE WHEN NULLIF(T.X.value('@SERIALTIPO', 'nvarchar(60)'), '') IS NULL THEN @SerialTipo ELSE T.X.value('@SERIALTIPO', 'nvarchar(60)') END,
            NULLIF(T.X.value('@COD_SERV', 'nvarchar(60)'), ''),
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL
                 THEN (CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END) * (CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END)
                 ELSE CAST(T.X.value('@TOTAL', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END ELSE CAST(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@RELACIONADA', 'nvarchar(10)') AS INT) END,
            NULLIF(T.X.value('@COD_ALTERNO', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);

        DECLARE @Memoria NVARCHAR(80) = @TipoOrden;
        DECLARE @MontoEfectivo DECIMAL(18,4) = 0, @MontoCheque DECIMAL(18,4) = 0, @MontoTarjeta DECIMAL(18,4) = 0, @SaldoPendiente DECIMAL(18,4) = 0;
        DECLARE @NumTarjeta NVARCHAR(60) = N'0', @Cta NVARCHAR(80) = N' ', @BancoCheque NVARCHAR(120) = N' ', @BancoTarjeta NVARCHAR(120) = N' ';

        IF @px IS NOT NULL
        BEGIN
            DECLARE @sqlForma NVARCHAR(MAX) = N'
                DELETE FROM dbo.' + QUOTENAME(@FormaPagoTable) + N' WHERE NUM_FACT = @pNumFact AND MEMORIA = @pMemoria AND SERIALFISCAL = @pSerial;
                INSERT INTO dbo.' + QUOTENAME(@FormaPagoTable) + N' (tasacambio, TIPO, NUM_FACT, MONTO, BANCO, CUENTA, FECHA_RETENCION, NUMERO, MEMORIA, SERIALFISCAL)
                SELECT
                    CASE WHEN NULLIF(N.X.value(''@tasacambio'', ''nvarchar(50)''), '''') IS NULL THEN 1 ELSE CAST(N.X.value(''@tasacambio'', ''nvarchar(50)'') AS DECIMAL(18,6)) END,
                    NULLIF(N.X.value(''@tipo'', ''nvarchar(60)''), ''''),
                    @pNumFact,
                    CASE WHEN NULLIF(N.X.value(''@monto'', ''nvarchar(50)''), '''') IS NULL THEN 0 ELSE CAST(N.X.value(''@monto'', ''nvarchar(50)'') AS DECIMAL(18,4)) END,
                    CASE WHEN NULLIF(N.X.value(''@banco'', ''nvarchar(120)''), '''') IS NULL THEN '' '' ELSE N.X.value(''@banco'', ''nvarchar(120)'') END,
                    CASE WHEN NULLIF(N.X.value(''@cuenta'', ''nvarchar(120)''), '''') IS NULL THEN '' '' ELSE N.X.value(''@cuenta'', ''nvarchar(120)'') END,
                    @pFecha,
                    CASE WHEN NULLIF(N.X.value(''@numero'', ''nvarchar(80)''), '''') IS NULL THEN ''0'' ELSE N.X.value(''@numero'', ''nvarchar(80)'') END,
                    @pMemoria, @pSerial
                FROM @pXml.nodes(''/formasPago/row'') N(X);';
            EXEC sp_executesql @sqlForma, N'@pNumFact nvarchar(60), @pMemoria nvarchar(80), @pSerial nvarchar(60), @pFecha datetime, @pXml xml',
                @pNumFact = @NumFact, @pMemoria = @Memoria, @pSerial = @SerialTipo, @pFecha = @Fecha, @pXml = @px;

            ;WITH FP AS (
                SELECT UPPER(CASE WHEN NULLIF(N.X.value('@tipo', 'nvarchar(60)'), '') IS NULL THEN '' ELSE N.X.value('@tipo', 'nvarchar(60)') END) AS Tipo,
                    CASE WHEN NULLIF(N.X.value('@monto', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@monto', 'nvarchar(50)') AS DECIMAL(18,4)) END AS Monto,
                    CASE WHEN NULLIF(N.X.value('@banco', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@banco', 'nvarchar(120)') END AS Banco,
                    CASE WHEN NULLIF(N.X.value('@cuenta', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@cuenta', 'nvarchar(120)') END AS Cuenta,
                    CASE WHEN NULLIF(N.X.value('@numero', 'nvarchar(80)'), '') IS NULL THEN '0' ELSE N.X.value('@numero', 'nvarchar(80)') END AS Numero
                FROM @px.nodes('/formasPago/row') N(X))
            SELECT @MontoEfectivo = ISNULL(SUM(CASE WHEN Tipo = 'EFECTIVO' THEN Monto ELSE 0 END), 0),
                @MontoCheque = ISNULL(SUM(CASE WHEN Tipo = 'CHEQUE' THEN Monto ELSE 0 END), 0),
                @MontoTarjeta = ISNULL(SUM(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Monto ELSE 0 END), 0),
                @SaldoPendiente = ISNULL(SUM(CASE WHEN Tipo = 'SALDO PENDIENTE' THEN Monto ELSE 0 END), 0),
                @Cta = ISNULL(MAX(CASE WHEN Tipo = 'CHEQUE' THEN Cuenta END), @Cta),
                @BancoCheque = ISNULL(MAX(CASE WHEN Tipo = 'CHEQUE' THEN Banco END), @BancoCheque),
                @BancoTarjeta = ISNULL(MAX(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Banco END), @BancoTarjeta),
                @NumTarjeta = ISNULL(MAX(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Numero END), @NumTarjeta)
            FROM FP;

            INSERT INTO dbo.DETALLE_DEPOSITO (TOTAL, CHEQUE, CTA_BANCO, CLIENTE, RELACIONADA, BANCO)
            SELECT FP.Monto, FP.Numero, FP.Cuenta, @Codigo, 0, FP.Banco
            FROM (SELECT UPPER(CASE WHEN NULLIF(N.X.value('@tipo', 'nvarchar(60)'), '') IS NULL THEN '' ELSE N.X.value('@tipo', 'nvarchar(60)') END) AS Tipo,
                CASE WHEN NULLIF(N.X.value('@monto', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@monto', 'nvarchar(50)') AS DECIMAL(18,4)) END AS Monto,
                CASE WHEN NULLIF(N.X.value('@banco', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@banco', 'nvarchar(120)') END AS Banco,
                CASE WHEN NULLIF(N.X.value('@cuenta', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@cuenta', 'nvarchar(120)') END AS Cuenta,
                CASE WHEN NULLIF(N.X.value('@numero', 'nvarchar(80)'), '') IS NULL THEN '0' ELSE N.X.value('@numero', 'nvarchar(80)') END AS Numero
                FROM @px.nodes('/formasPago/row') N(X)) FP
            WHERE FP.Tipo = 'CHEQUE';
        END

        DECLARE @Abono DECIMAL(18,4) = @Total - @SaldoPendiente;
        DECLARE @Cancelada CHAR(1) = CASE WHEN @SaldoPendiente > 0 THEN 'N' ELSE 'S' END;

        UPDATE dbo.Presupuestos
        SET Monto_Efect = @MontoEfectivo, Monto_Cheque = @MontoCheque, Monto_Tarjeta = @MontoTarjeta,
            Abono = @Abono, Saldo = @SaldoPendiente, Tarjeta = @NumTarjeta, Cta = @Cta,
            BANCO_CHEQUE = @BancoCheque, Banco_Tarjeta = @BancoTarjeta,
            CANCELADA = @Cancelada, FECHA_REPORTE = @FechaReporte
        WHERE NUM_FACT = @NumFact;

        IF @GenerarCxC = 1 AND (@Pago = 'CREDITO' OR @SaldoPendiente > 0)
        BEGIN
            DECLARE @SaldoPrevio DECIMAL(18,4) = 0;
            DECLARE @sqlCxc NVARCHAR(MAX) = N'
                DELETE FROM dbo.' + QUOTENAME(@CxcTable) + N' WHERE CODIGO = @codigo AND DOCUMENTO = @numFact AND TIPO = ''PRESUP'';
                SELECT TOP 1 @saldoPrevioOut = ISNULL(SALDO, 0) FROM dbo.' + QUOTENAME(@CxcTable) + N' WHERE CODIGO = @codigo ORDER BY FECHA DESC;
                INSERT INTO dbo.' + QUOTENAME(@CxcTable) + N' (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, SERIALTIPO, Tipo_Orden)
                VALUES (@codigo, @codUsuario, @fecha, @numFact, @debe, @pend, ISNULL(@saldoPrevioOut,0) + @pend, ''PRESUP'', @serialTipo, @tipoOrden);';
            EXEC sp_executesql @sqlCxc, N'@codigo nvarchar(60), @numFact nvarchar(60), @codUsuario nvarchar(60), @fecha datetime, @debe decimal(18,4), @pend decimal(18,4), @saldoPrevioOut decimal(18,4) OUTPUT, @serialTipo nvarchar(60), @tipoOrden nvarchar(80)',
                @codigo = @Codigo, @numFact = @NumFact, @codUsuario = @CodUsuario, @fecha = @Fecha, @debe = @SaldoPendiente, @pend = @SaldoPendiente, @saldoPrevioOut = @SaldoPrevio OUTPUT, @serialTipo = @SerialTipo, @tipoOrden = @TipoOrden;
        END

        IF @ActualizarInventario = 1
        BEGIN
            INSERT INTO dbo.MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumFact, @Fecha, 'Presup:' + @NumFact, 'Egreso',
                ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) - D.CANTIDAD, @CodUsuario, ISNULL(I.COSTO_REFERENCIA, 0), D.ALICUOTA, D.PRECIO
            FROM (SELECT NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD,
                CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END AS PRECIO,
                CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END AS ALICUOTA
                FROM @dx.nodes('/detalles/row') N(X)) D
            INNER JOIN dbo.Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

            ;WITH RawD AS (SELECT NULLIF(N.X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM RawD GROUP BY COD_SERV)
            UPDATE I SET I.EXISTENCIA = ISNULL(I.EXISTENCIA, 0) - X.TOTAL FROM dbo.Inventario I INNER JOIN X ON X.COD_SERV = I.CODIGO;

            ;WITH RawA AS (SELECT NULLIF(N.X.value('@COD_ALTERNO', 'nvarchar(60)'), '') AS COD_ALTERNO,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD,
                CASE WHEN NULLIF(N.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@RELACIONADA', 'nvarchar(10)') AS INT) END AS RELACIONADA FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM RawA WHERE RELACIONADA = 1 GROUP BY COD_ALTERNO)
            UPDATE IA SET IA.CANTIDAD = ISNULL(IA.CANTIDAD, 0) - X.TOTAL FROM dbo.Inventario_Aux IA INNER JOIN X ON X.COD_ALTERNO = IA.CODIGO;
        END

        IF @ActualizarSaldosCliente = 1 AND @Codigo IS NOT NULL AND LTRIM(RTRIM(@Codigo)) <> ''
        BEGIN
            DECLARE @sqlSaldo NVARCHAR(MAX);
            IF @CxcTable = N'P_CobrarC'
                SET @sqlSaldo = N';WITH A AS (SELECT ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' THEN PEND ELSE 0 END), 0) AS SALDO_TOT,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) <= 30 THEN PEND ELSE 0 END), 0) AS SALDO_30,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 30 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 60 THEN PEND ELSE 0 END), 0) AS SALDO_60,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 60 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 90 THEN PEND ELSE 0 END), 0) AS SALDO_90,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 90 THEN PEND ELSE 0 END), 0) AS SALDO_91 FROM dbo.P_CobrarC WHERE CODIGO = @codigo)
                    UPDATE C SET SALDO_TOTC = A.SALDO_TOT, SALDO_30C = A.SALDO_30, SALDO_60C = A.SALDO_60, SALDO_90C = A.SALDO_90, SALDO_91C = A.SALDO_91 FROM dbo.Clientes C CROSS JOIN A WHERE C.CODIGO = @codigo;';
            ELSE
                SET @sqlSaldo = N';WITH A AS (SELECT ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' THEN PEND ELSE 0 END), 0) AS SALDO_TOT,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) <= 30 THEN PEND ELSE 0 END), 0) AS SALDO_30,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 30 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 60 THEN PEND ELSE 0 END), 0) AS SALDO_60,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 60 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 90 THEN PEND ELSE 0 END), 0) AS SALDO_90,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 90 THEN PEND ELSE 0 END), 0) AS SALDO_91 FROM dbo.P_Cobrar WHERE CODIGO = @codigo)
                    UPDATE C SET SALDO_TOT = A.SALDO_TOT, SALDO_30 = A.SALDO_30, SALDO_60 = A.SALDO_60, SALDO_90 = A.SALDO_90, SALDO_91 = A.SALDO_91 FROM dbo.Clientes C CROSS JOIN A WHERE C.CODIGO = @codigo;';
            EXEC sp_executesql @sqlSaldo, N'@codigo nvarchar(60)', @codigo = @Codigo;
        END

        IF @StartedTran = 1 AND XACT_STATE() = 1 COMMIT TRAN;

        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows,
            @MontoEfectivo AS montoEfectivo, @MontoCheque AS montoCheque, @MontoTarjeta AS montoTarjeta, @SaldoPendiente AS saldoPendiente, @Abono AS abono;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 BEGIN
            IF @StartedTran = 1 ROLLBACK TRAN;
            ELSE ROLLBACK TRANSACTION @SaveName;
        END
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Clientes_Delete]
-- =============================================
CREATE PROCEDURE usp_Clientes_Delete
    @Codigo NVARCHAR(12),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Clientes] WHERE CODIGO = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Clientes_GetByCodigo]
-- =============================================
CREATE PROCEDURE usp_Clientes_GetByCodigo
    @Codigo NVARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Clientes] WHERE CODIGO = @Codigo;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Clientes_Insert]
-- =============================================
CREATE PROCEDURE usp_Clientes_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(12)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Clientes] (
            CODIGO, NOMBRE, RIF, NIT, DIRECCION, DIRECCION1, SUCURSAL, TELEFONO,
            CONTACTO, VENDEDOR, ESTADO, CIUDAD, CPOSTAL, EMAIL, PAGINA_WWW,
            COD_USUARIO, LIMITE, CREDITO, LISTA_PRECIO
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(12)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@DIRECCION1', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@VENDEDOR', 'NVARCHAR(4)'), N''),
            NULLIF(r.value('@ESTADO', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@CIUDAD', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Clientes_Update]
-- =============================================
CREATE PROCEDURE usp_Clientes_Update
    @Codigo NVARCHAR(12),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente no encontrado';
            RETURN;
        END

        UPDATE c SET
            NOMBRE = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''), c.NOMBRE),
            RIF = COALESCE(NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''), c.RIF),
            NIT = COALESCE(NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''), c.NIT),
            DIRECCION = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), c.DIRECCION),
            DIRECCION1 = COALESCE(NULLIF(r.value('@DIRECCION1', 'NVARCHAR(50)'), N''), c.DIRECCION1),
            SUCURSAL = COALESCE(NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''), c.SUCURSAL),
            TELEFONO = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), c.TELEFONO),
            CONTACTO = COALESCE(NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''), c.CONTACTO),
            VENDEDOR = COALESCE(NULLIF(r.value('@VENDEDOR', 'NVARCHAR(4)'), N''), c.VENDEDOR),
            ESTADO = COALESCE(NULLIF(r.value('@ESTADO', 'NVARCHAR(20)'), N''), c.ESTADO),
            CIUDAD = COALESCE(NULLIF(r.value('@CIUDAD', 'NVARCHAR(20)'), N''), c.CIUDAD),
            CPOSTAL = COALESCE(NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''), c.CPOSTAL),
            EMAIL = COALESCE(NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''), c.EMAIL),
            PAGINA_WWW = COALESCE(NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''), c.PAGINA_WWW),
            COD_USUARIO = COALESCE(NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''), c.COD_USUARIO),
            LIMITE = CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN c.LIMITE ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CREDITO = CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN c.CREDITO ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            LISTA_PRECIO = CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN c.LISTA_PRECIO ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END
        FROM [dbo].[Clientes] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.CODIGO = @Codigo;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Compras_GetByNumFact]
-- =============================================
CREATE PROCEDURE usp_Compras_GetByNumFact
    @NumFact NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Compras] WHERE NUM_FACT = @NumFact;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Asiento_Anular]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Anular
  @AsientoId BIGINT,
  @Motivo NVARCHAR(400),
  @CodUsuario NVARCHAR(40) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM dbo.Asientos WHERE Id = @AsientoId)
  BEGIN
    SET @Resultado = 0;
    SET @Mensaje = N'Asiento no encontrado.';
    RETURN;
  END;

  UPDATE dbo.Asientos
  SET Estado = N'ANULADO',
      Concepto = LEFT(Concepto + N' | ANULADO: ' + ISNULL(@Motivo, N''), 400),
      FechaActualizacion = SYSUTCDATETIME()
  WHERE Id = @AsientoId;

  SET @Resultado = 1;
  SET @Mensaje = N'Asiento anulado.';
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Asiento_Crear]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Crear
  @Fecha DATE,
  @TipoAsiento NVARCHAR(20),
  @Referencia NVARCHAR(120) = NULL,
  @Concepto NVARCHAR(400),
  @Moneda NVARCHAR(10) = N'VES',
  @Tasa DECIMAL(18,6) = 1,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @CodUsuario NVARCHAR(40) = NULL,
  @DetalleXml XML,
  @AsientoId BIGINT OUTPUT,
  @NumeroAsiento NVARCHAR(40) OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    DECLARE @Detalle TABLE (
      CodCuenta NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(400) NULL,
      CentroCosto NVARCHAR(20) NULL,
      AuxiliarTipo NVARCHAR(30) NULL,
      AuxiliarCodigo NVARCHAR(120) NULL,
      Documento NVARCHAR(120) NULL,
      Debe DECIMAL(18,2) NOT NULL,
      Haber DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Detalle (CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber)
    SELECT
      T.X.value('@codCuenta', 'nvarchar(40)'),
      NULLIF(T.X.value('@descripcion', 'nvarchar(400)'), N''),
      NULLIF(T.X.value('@centroCosto', 'nvarchar(20)'), N''),
      NULLIF(T.X.value('@auxiliarTipo', 'nvarchar(30)'), N''),
      NULLIF(T.X.value('@auxiliarCodigo', 'nvarchar(120)'), N''),
      NULLIF(T.X.value('@documento', 'nvarchar(120)'), N''),
      ISNULL(T.X.value('@debe', 'decimal(18,2)'), 0),
      ISNULL(T.X.value('@haber', 'decimal(18,2)'), 0)
    FROM @DetalleXml.nodes('/rows/row') T(X);

    IF NOT EXISTS (SELECT 1 FROM @Detalle)
    BEGIN
      SET @Resultado = 0;
      SET @Mensaje = N'Detalle contable vacio.';
      ROLLBACK TRAN;
      RETURN;
    END;

    DECLARE @TotalDebe DECIMAL(18,2) = (SELECT ISNULL(SUM(Debe),0) FROM @Detalle);
    DECLARE @TotalHaber DECIMAL(18,2) = (SELECT ISNULL(SUM(Haber),0) FROM @Detalle);

    IF @TotalDebe <> @TotalHaber
    BEGIN
      SET @Resultado = 0;
      SET @Mensaje = N'Asiento no balanceado.';
      ROLLBACK TRAN;
      RETURN;
    END;

    INSERT INTO dbo.Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (@Fecha, @TipoAsiento, @Concepto, ISNULL(@OrigenDocumento, @Referencia), N'APROBADO', @TotalDebe, @TotalHaber, @OrigenModulo, ISNULL(@CodUsuario, N'API'));

    SET @AsientoId = SCOPE_IDENTITY();

    INSERT INTO dbo.Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber)
    SELECT @AsientoId, CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber
    FROM @Detalle;

    SET @NumeroAsiento = N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(@AsientoId AS NVARCHAR(20)), 10);
    SET @Resultado = 1;
    SET @Mensaje = N'Asiento creado correctamente.';

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Asiento_Get]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Get
  @AsientoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    a.Id AS AsientoId,
    N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(a.Id AS NVARCHAR(20)), 10) AS NumeroAsiento,
    a.Fecha,
    a.Tipo_Asiento AS TipoAsiento,
    a.Referencia,
    a.Concepto,
    N'VES' AS Moneda,
    CAST(1 AS DECIMAL(18,6)) AS Tasa,
    a.Total_Debe AS TotalDebe,
    a.Total_Haber AS TotalHaber,
    a.Estado,
    a.Origen_Modulo AS OrigenModulo,
    a.Cod_Usuario AS CodUsuario
  FROM dbo.Asientos a
  WHERE a.Id = @AsientoId;

  SELECT
    d.Id,
    d.Id_Asiento AS AsientoId,
    d.Cod_Cuenta AS CodCuenta,
    d.Descripcion,
    d.CentroCosto,
    d.AuxiliarTipo,
    d.AuxiliarCodigo,
    d.Documento,
    d.Debe,
    d.Haber
  FROM dbo.Asientos_Detalle d
  WHERE d.Id_Asiento = @AsientoId
  ORDER BY d.Id;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Asientos_List]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Asientos_List
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @TipoAsiento NVARCHAR(20) = NULL,
  @Estado NVARCHAR(20) = NULL,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;
  
  DECLARE @Base TABLE (
    AsientoId BIGINT NOT NULL,
    NumeroAsiento NVARCHAR(40) NOT NULL,
    Fecha DATE NOT NULL,
    TipoAsiento NVARCHAR(20) NOT NULL,
    Referencia NVARCHAR(120) NULL,
    Concepto NVARCHAR(400) NOT NULL,
    Moneda NVARCHAR(10) NOT NULL,
    Tasa DECIMAL(18,6) NOT NULL,
    TotalDebe DECIMAL(18,2) NOT NULL,
    TotalHaber DECIMAL(18,2) NOT NULL,
    Estado NVARCHAR(20) NOT NULL,
    OrigenModulo NVARCHAR(40) NULL,
    CodUsuario NVARCHAR(120) NULL,
    rn INT NOT NULL
  );

  INSERT INTO @Base (
    AsientoId, NumeroAsiento, Fecha, TipoAsiento, Referencia, Concepto,
    Moneda, Tasa, TotalDebe, TotalHaber, Estado, OrigenModulo, CodUsuario, rn
  )
  SELECT
    a.Id AS AsientoId,
    N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(a.Id AS NVARCHAR(20)), 10) AS NumeroAsiento,
    a.Fecha,
    a.Tipo_Asiento AS TipoAsiento,
    a.Referencia,
    a.Concepto,
    N'VES' AS Moneda,
    CAST(1 AS DECIMAL(18,6)) AS Tasa,
    a.Total_Debe AS TotalDebe,
    a.Total_Haber AS TotalHaber,
    a.Estado,
    a.Origen_Modulo AS OrigenModulo,
    a.Cod_Usuario AS CodUsuario,
    ROW_NUMBER() OVER (ORDER BY a.Fecha DESC, a.Id DESC) AS rn
  FROM dbo.Asientos a
  WHERE (@FechaDesde IS NULL OR a.Fecha >= @FechaDesde)
    AND (@FechaHasta IS NULL OR a.Fecha <= @FechaHasta)
    AND (@TipoAsiento IS NULL OR a.Tipo_Asiento = @TipoAsiento)
    AND (@Estado IS NULL OR a.Estado = @Estado)
    AND (@OrigenModulo IS NULL OR a.Origen_Modulo = @OrigenModulo)
    AND (@OrigenDocumento IS NULL OR a.Referencia = @OrigenDocumento);

  SELECT @TotalCount = COUNT(1) FROM @Base;

  SELECT AsientoId, NumeroAsiento, Fecha, TipoAsiento, Referencia, Concepto, Moneda, Tasa,
         TotalDebe, TotalHaber, Estado, OrigenModulo, CodUsuario
  FROM @Base
  WHERE rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Balance_Comprobacion]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Balance_Comprobacion
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.Cod_Cuenta AS CodCuenta, c.Desc_Cta AS Descripcion,
         SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber, SUM(d.Debe-d.Haber) AS Saldo
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  LEFT JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
  WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  GROUP BY d.Cod_Cuenta, c.Desc_Cta
  ORDER BY d.Cod_Cuenta;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Balance_General]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Balance_General
  @FechaCorte DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS (
    SELECT c.Tipo, d.Cod_Cuenta, c.Desc_Cta,
           SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber,
           SUM(d.Debe-d.Haber) AS SaldoNatural
    FROM dbo.Asientos_Detalle d
    INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
    INNER JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
    WHERE a.Fecha <= @FechaCorte
      AND a.Estado <> N'ANULADO'
      AND c.Tipo IN (N'A',N'P',N'C')
    GROUP BY c.Tipo, d.Cod_Cuenta, c.Desc_Cta
  )
  SELECT Tipo, Cod_Cuenta AS CodCuenta, Desc_Cta AS Descripcion, Debe, Haber,
         CASE WHEN Tipo=N'A' THEN SaldoNatural ELSE -SaldoNatural END AS Saldo
  FROM Base
  ORDER BY Cod_Cuenta;

  SELECT
    SUM(CASE WHEN Tipo=N'A' THEN SaldoNatural ELSE 0 END) AS TotalActivo,
    SUM(CASE WHEN Tipo=N'P' THEN -SaldoNatural ELSE 0 END) AS TotalPasivo,
    SUM(CASE WHEN Tipo=N'C' THEN -SaldoNatural ELSE 0 END) AS TotalPatrimonio
  FROM Base;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Estado_Resultados]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Estado_Resultados
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS (
    SELECT c.Tipo, d.Cod_Cuenta, c.Desc_Cta,
           SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber,
           SUM(d.Haber-d.Debe) AS SaldoResultado
    FROM dbo.Asientos_Detalle d
    INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
    INNER JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
    WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
      AND a.Estado <> N'ANULADO'
      AND c.Tipo IN (N'I',N'G')
    GROUP BY c.Tipo, d.Cod_Cuenta, c.Desc_Cta
  )
  SELECT Tipo, Cod_Cuenta AS CodCuenta, Desc_Cta AS Descripcion, Debe, Haber, SaldoResultado
  FROM Base
  ORDER BY Cod_Cuenta;

  SELECT
    SUM(CASE WHEN Tipo=N'I' THEN SaldoResultado ELSE 0 END) AS TotalIngresos,
    SUM(CASE WHEN Tipo=N'G' THEN -SaldoResultado ELSE 0 END) AS TotalGastos,
    SUM(CASE WHEN Tipo=N'I' THEN SaldoResultado ELSE 0 END) - SUM(CASE WHEN Tipo=N'G' THEN -SaldoResultado ELSE 0 END) AS UtilidadNeta
  FROM Base;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Libro_Mayor]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Libro_Mayor
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.Cod_Cuenta AS CodCuenta, c.Desc_Cta AS Descripcion,
         SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber, SUM(d.Debe-d.Haber) AS Saldo
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  LEFT JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
  WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  GROUP BY d.Cod_Cuenta, c.Desc_Cta
  ORDER BY d.Cod_Cuenta;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Mayor_Analitico]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Mayor_Analitico
  @CodCuenta NVARCHAR(40),
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT a.Id AS AsientoId, a.Fecha, a.Referencia, a.Concepto,
         d.Descripcion, d.Debe, d.Haber,
         SUM(d.Debe-d.Haber) OVER (ORDER BY a.Fecha, a.Id, d.Id ROWS UNBOUNDED PRECEDING) AS SaldoAcumulado
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  WHERE d.Cod_Cuenta = @CodCuenta
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  ORDER BY a.Fecha, a.Id, d.Id;
END;

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cotizacion_GetByNumFact]
-- =============================================
CREATE PROCEDURE usp_Cotizacion_GetByNumFact
    @NumFact NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Cotizacion] WHERE NUM_FACT = @NumFact;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cuentas_Delete]
-- =============================================
CREATE PROCEDURE usp_Cuentas_Delete
    @CodCuenta NVARCHAR(50),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta no encontrada';
            RETURN;
        END

        DELETE FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cuentas_GetByCodigo]
-- =============================================
CREATE PROCEDURE usp_Cuentas_GetByCodigo
    @CodCuenta NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cuentas_Insert]
-- =============================================
CREATE PROCEDURE usp_Cuentas_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @xml.value('(/row/@COD_CUENTA)[1]', 'NVARCHAR(50)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Cuentas] (
            COD_CUENTA, DESCRIPCION, TIPO, PRESUPUESTO, SALDO, COD_USUARIO, grupo, LINEA, USO, Nivel, Porcentaje
        )
        SELECT
            NULLIF(r.value('@COD_CUENTA', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(100)'), N''),
            NULLIF(r.value('@TIPO', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@PRESUPUESTO', 'NVARCHAR(50)') IS NULL OR r.value('@PRESUPUESTO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRESUPUESTO', 'NVARCHAR(50)') AS INT) END,
            CASE WHEN r.value('@SALDO', 'NVARCHAR(50)') IS NULL OR r.value('@SALDO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@SALDO', 'NVARCHAR(50)') AS INT) END,
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@grupo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@LINEA', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@USO', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@Nivel', 'NVARCHAR(50)') IS NULL OR r.value('@Nivel', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Nivel', 'NVARCHAR(50)') AS INT) END,
            CASE WHEN r.value('@Porcentaje', 'NVARCHAR(50)') IS NULL OR r.value('@Porcentaje', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Porcentaje', 'NVARCHAR(50)') AS FLOAT) END
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cuentas_Update]
-- =============================================
CREATE PROCEDURE usp_Cuentas_Update
    @CodCuenta NVARCHAR(50),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta no encontrada';
            RETURN;
        END

        UPDATE c SET
            DESCRIPCION = COALESCE(NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(100)'), N''), c.DESCRIPCION),
            TIPO = COALESCE(NULLIF(r.value('@TIPO', 'NVARCHAR(50)'), N''), c.TIPO),
            grupo = COALESCE(NULLIF(r.value('@grupo', 'NVARCHAR(50)'), N''), c.grupo),
            LINEA = COALESCE(NULLIF(r.value('@LINEA', 'NVARCHAR(50)'), N''), c.LINEA),
            USO = COALESCE(NULLIF(r.value('@USO', 'NVARCHAR(50)'), N''), c.USO),
            Nivel = CASE WHEN r.value('@Nivel', 'NVARCHAR(50)') IS NULL OR r.value('@Nivel', 'NVARCHAR(50)') = '' THEN c.Nivel ELSE CAST(r.value('@Nivel', 'NVARCHAR(50)') AS INT) END,
            Porcentaje = CASE WHEN r.value('@Porcentaje', 'NVARCHAR(50)') IS NULL OR r.value('@Porcentaje', 'NVARCHAR(50)') = '' THEN c.Porcentaje ELSE CAST(r.value('@Porcentaje', 'NVARCHAR(50)') AS FLOAT) END
        FROM [dbo].[Cuentas] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.COD_CUENTA = @CodCuenta;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Empleados_Delete]
-- =============================================
CREATE PROCEDURE usp_Empleados_Delete
    @Cedula NVARCHAR(20),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @Cedula)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Empleados] WHERE CEDULA = @Cedula;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Empleados_GetByCedula]
-- =============================================
CREATE PROCEDURE usp_Empleados_GetByCedula
    @Cedula NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Empleados] WHERE CEDULA = @Cedula;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Empleados_Insert]
-- =============================================
CREATE PROCEDURE usp_Empleados_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @xml.value('(/row/@CEDULA)[1]', 'NVARCHAR(20)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Empleados] (
            CEDULA, GRUPO, NOMBRE, DIRECCION, TELEFONO, NACIMIENTO, CARGO, NOMINA,
            SUELDO, INGRESO, RETIRO, STATUS, COMISION, UTILIDAD, CO_Usuario,
            SEXO, NACIONALIDAD, Autoriza, Apodo
        )
        SELECT
            NULLIF(r.value('@CEDULA', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@GRUPO', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(100)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            CASE WHEN r.value('@NACIMIENTO', 'NVARCHAR(50)') IS NULL OR r.value('@NACIMIENTO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@NACIMIENTO', 'NVARCHAR(50)') AS DATETIME) END,
            NULLIF(r.value('@CARGO', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@NOMINA', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@SUELDO', 'NVARCHAR(50)') IS NULL OR r.value('@SUELDO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@SUELDO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@INGRESO', 'NVARCHAR(50)') IS NULL OR r.value('@INGRESO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@INGRESO', 'NVARCHAR(50)') AS DATETIME) END,
            CASE WHEN r.value('@RETIRO', 'NVARCHAR(50)') IS NULL OR r.value('@RETIRO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@RETIRO', 'NVARCHAR(50)') AS DATETIME) END,
            NULLIF(r.value('@STATUS', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@COMISION', 'NVARCHAR(50)') IS NULL OR r.value('@COMISION', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@COMISION', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@UTILIDAD', 'NVARCHAR(50)') IS NULL OR r.value('@UTILIDAD', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@UTILIDAD', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@CO_Usuario', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@SEXO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@NACIONALIDAD', 'NVARCHAR(50)'), N''),
            ISNULL(r.value('@Autoriza', 'BIT'), 0),
            NULLIF(r.value('@Apodo', 'NVARCHAR(50)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Empleados_Update]
-- =============================================
CREATE PROCEDURE usp_Empleados_Update
    @Cedula NVARCHAR(20),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @Cedula)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado no encontrado';
            RETURN;
        END

        UPDATE e SET
            GRUPO = COALESCE(NULLIF(r.value('@GRUPO', 'NVARCHAR(50)'), N''), e.GRUPO),
            NOMBRE = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(100)'), N''), e.NOMBRE),
            DIRECCION = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), e.DIRECCION),
            TELEFONO = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), e.TELEFONO),
            CARGO = COALESCE(NULLIF(r.value('@CARGO', 'NVARCHAR(50)'), N''), e.CARGO),
            NOMINA = COALESCE(NULLIF(r.value('@NOMINA', 'NVARCHAR(50)'), N''), e.NOMINA),
            SUELDO = CASE WHEN r.value('@SUELDO', 'NVARCHAR(50)') IS NULL OR r.value('@SUELDO', 'NVARCHAR(50)') = '' THEN e.SUELDO ELSE CAST(r.value('@SUELDO', 'NVARCHAR(50)') AS FLOAT) END,
            STATUS = COALESCE(NULLIF(r.value('@STATUS', 'NVARCHAR(50)'), N''), e.STATUS),
            COMISION = CASE WHEN r.value('@COMISION', 'NVARCHAR(50)') IS NULL OR r.value('@COMISION', 'NVARCHAR(50)') = '' THEN e.COMISION ELSE CAST(r.value('@COMISION', 'NVARCHAR(50)') AS FLOAT) END,
            SEXO = COALESCE(NULLIF(r.value('@SEXO', 'NVARCHAR(10)'), N''), e.SEXO),
            NACIONALIDAD = COALESCE(NULLIF(r.value('@NACIONALIDAD', 'NVARCHAR(50)'), N''), e.NACIONALIDAD),
            Autoriza = ISNULL(r.value('@Autoriza', 'BIT'), e.Autoriza)
        FROM [dbo].[Empleados] e
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE e.CEDULA = @Cedula;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Facturas_GetByNumFact]
-- =============================================
CREATE PROCEDURE usp_Facturas_GetByNumFact
    @NumFact NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Facturas] WHERE NUM_FACT = @NumFact;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Inventario_Delete]
-- =============================================
CREATE PROCEDURE usp_Inventario_Delete
    @Codigo NVARCHAR(15),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Inventario] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'ArtÃ­culo no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Inventario] WHERE CODIGO = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Inventario_GetByCodigo]
-- =============================================
CREATE PROCEDURE usp_Inventario_GetByCodigo
    @Codigo NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *,
           LTRIM(RTRIM(
               ISNULL(RTRIM(Categoria), '') +
               CASE WHEN RTRIM(ISNULL(Tipo, '')) <> '' THEN ' ' + RTRIM(Tipo) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(DESCRIPCION) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(Marca, '')) <> '' THEN ' ' + RTRIM(Marca) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(Clase, '')) <> '' THEN ' ' + RTRIM(Clase) ELSE '' END
           )) AS DescripcionCompleta
    FROM [dbo].[Inventario]
    WHERE CODIGO = @Codigo;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Inventario_Insert]
-- =============================================
CREATE PROCEDURE usp_Inventario_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Inventario] WHERE CODIGO = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(15)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'ArtÃ­culo ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Inventario] (
            CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION,
            EXISTENCIA, VENTA, MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA, PORCENTAJE,
            UBICACION, Co_Usuario, Linea, N_PARTE, Barra
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(15)'), N''),
            NULLIF(r.value('@Referencia', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Categoria', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Unidad', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Clase', 'NVARCHAR(25)'), N''),
            NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(255)'), N''),
            CASE WHEN r.value('@EXISTENCIA', 'NVARCHAR(50)') IS NULL OR r.value('@EXISTENCIA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@EXISTENCIA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@VENTA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MINIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MINIMO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@MINIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MAXIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MAXIMO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@MAXIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_VENTA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRECIO_VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PORCENTAJE', 'NVARCHAR(50)') IS NULL OR r.value('@PORCENTAJE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PORCENTAJE', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@UBICACION', 'NVARCHAR(40)'), N''),
            NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@Linea', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@N_PARTE', 'NVARCHAR(18)'), N''),
            NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Inventario_Update]
-- =============================================
CREATE PROCEDURE usp_Inventario_Update
    @Codigo NVARCHAR(15),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Inventario] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'ArtÃ­culo no encontrado';
            RETURN;
        END

        UPDATE c SET
            Referencia = COALESCE(NULLIF(r.value('@Referencia', 'NVARCHAR(30)'), N''), c.Referencia),
            Categoria = COALESCE(NULLIF(r.value('@Categoria', 'NVARCHAR(50)'), N''), c.Categoria),
            Marca = COALESCE(NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''), c.Marca),
            Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''), c.Tipo),
            Unidad = COALESCE(NULLIF(r.value('@Unidad', 'NVARCHAR(30)'), N''), c.Unidad),
            Clase = COALESCE(NULLIF(r.value('@Clase', 'NVARCHAR(25)'), N''), c.Clase),
            DESCRIPCION = COALESCE(NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(255)'), N''), c.DESCRIPCION),
            EXISTENCIA = CASE WHEN r.value('@EXISTENCIA', 'NVARCHAR(50)') IS NULL OR r.value('@EXISTENCIA', 'NVARCHAR(50)') = '' THEN c.EXISTENCIA ELSE CAST(r.value('@EXISTENCIA', 'NVARCHAR(50)') AS FLOAT) END,
            VENTA = CASE WHEN r.value('@VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@VENTA', 'NVARCHAR(50)') = '' THEN c.VENTA ELSE CAST(r.value('@VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            MINIMO = CASE WHEN r.value('@MINIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MINIMO', 'NVARCHAR(50)') = '' THEN c.MINIMO ELSE CAST(r.value('@MINIMO', 'NVARCHAR(50)') AS FLOAT) END,
            MAXIMO = CASE WHEN r.value('@MAXIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MAXIMO', 'NVARCHAR(50)') = '' THEN c.MAXIMO ELSE CAST(r.value('@MAXIMO', 'NVARCHAR(50)') AS FLOAT) END,
            PRECIO_COMPRA = CASE WHEN r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') = '' THEN c.PRECIO_COMPRA ELSE CAST(r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') AS FLOAT) END,
            PRECIO_VENTA = CASE WHEN r.value('@PRECIO_VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_VENTA', 'NVARCHAR(50)') = '' THEN c.PRECIO_VENTA ELSE CAST(r.value('@PRECIO_VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            PORCENTAJE = CASE WHEN r.value('@PORCENTAJE', 'NVARCHAR(50)') IS NULL OR r.value('@PORCENTAJE', 'NVARCHAR(50)') = '' THEN c.PORCENTAJE ELSE CAST(r.value('@PORCENTAJE', 'NVARCHAR(50)') AS FLOAT) END,
            UBICACION = COALESCE(NULLIF(r.value('@UBICACION', 'NVARCHAR(40)'), N''), c.UBICACION),
            Co_Usuario = COALESCE(NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''), c.Co_Usuario),
            Linea = COALESCE(NULLIF(r.value('@Linea', 'NVARCHAR(30)'), N''), c.Linea),
            N_PARTE = COALESCE(NULLIF(r.value('@N_PARTE', 'NVARCHAR(18)'), N''), c.N_PARTE),
            Barra = COALESCE(NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N''), c.Barra)
        FROM [dbo].[Inventario] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.CODIGO = @Codigo;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Pedidos_GetByNumFact]
-- =============================================
CREATE PROCEDURE usp_Pedidos_GetByNumFact
    @NumFact NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Pedidos] WHERE NUM_FACT = @NumFact;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Proveedores_Delete]
-- =============================================
CREATE PROCEDURE usp_Proveedores_Delete
    @Codigo NVARCHAR(10),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Proveedores] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Proveedores] WHERE CODIGO = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Proveedores_GetByCodigo]
-- =============================================
CREATE PROCEDURE usp_Proveedores_GetByCodigo
    @Codigo NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Proveedores] WHERE CODIGO = @Codigo;
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Proveedores_Insert]
-- =============================================
CREATE PROCEDURE usp_Proveedores_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Proveedores] WHERE CODIGO = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(10)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Proveedores] (
            CODIGO, NOMBRE, RIF, NIT, DIRECCION, DIRECCION1, SUCURSAL, TELEFONO, FAX,
            CONTACTO, VENDEDOR, ESTADO, CIUDAD, CPOSTAL, EMAIL, PAGINA_WWW,
            COD_USUARIO, LIMITE, CREDITO, LISTA_PRECIO, NOTAS
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@DIRECCION1', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@FAX', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@VENDEDOR', 'NVARCHAR(2)'), N''),
            NULLIF(r.value('@ESTADO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@CIUDAD', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END,
            NULLIF(r.value('@NOTAS', 'NVARCHAR(50)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Proveedores_Update]
-- =============================================
CREATE PROCEDURE usp_Proveedores_Update
    @Codigo NVARCHAR(10),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Proveedores] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor no encontrado';
            RETURN;
        END

        UPDATE c SET
            NOMBRE = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''), c.NOMBRE),
            RIF = COALESCE(NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''), c.RIF),
            NIT = COALESCE(NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''), c.NIT),
            DIRECCION = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), c.DIRECCION),
            DIRECCION1 = COALESCE(NULLIF(r.value('@DIRECCION1', 'NVARCHAR(255)'), N''), c.DIRECCION1),
            SUCURSAL = COALESCE(NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''), c.SUCURSAL),
            TELEFONO = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), c.TELEFONO),
            FAX = COALESCE(NULLIF(r.value('@FAX', 'NVARCHAR(10)'), N''), c.FAX),
            CONTACTO = COALESCE(NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''), c.CONTACTO),
            VENDEDOR = COALESCE(NULLIF(r.value('@VENDEDOR', 'NVARCHAR(2)'), N''), c.VENDEDOR),
            ESTADO = COALESCE(NULLIF(r.value('@ESTADO', 'NVARCHAR(60)'), N''), c.ESTADO),
            CIUDAD = COALESCE(NULLIF(r.value('@CIUDAD', 'NVARCHAR(30)'), N''), c.CIUDAD),
            CPOSTAL = COALESCE(NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''), c.CPOSTAL),
            EMAIL = COALESCE(NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''), c.EMAIL),
            PAGINA_WWW = COALESCE(NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''), c.PAGINA_WWW),
            COD_USUARIO = COALESCE(NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''), c.COD_USUARIO),
            LIMITE = CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN c.LIMITE ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CREDITO = CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN c.CREDITO ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            LISTA_PRECIO = CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN c.LISTA_PRECIO ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END,
            NOTAS = COALESCE(NULLIF(r.value('@NOTAS', 'NVARCHAR(50)'), N''), c.NOTAS)
        FROM [dbo].[Proveedores] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.CODIGO = @Codigo;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO

-- =============================================
-- VIEW [dbo].[DtllAsiento]
-- =============================================

CREATE VIEW dbo.DtllAsiento
AS
  SELECT
    CAST(Id AS BIGINT) AS Id,
    CAST(Id_Asiento AS BIGINT) AS Id_Asiento,
    Cod_Cuenta,
    Descripcion,
    Debe,
    Haber
  FROM dbo.Asientos_Detalle;

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Clientes_List]
-- =============================================
CREATE PROCEDURE usp_Clientes_List
    @Search NVARCHAR(100) = NULL,
    @Estado NVARCHAR(20) = NULL,
    @Vendedor NVARCHAR(60) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Estado NVARCHAR(20), @Vendedor NVARCHAR(60), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CODIGO LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND ESTADO = @Estado';
    IF @Vendedor IS NOT NULL AND LTRIM(RTRIM(@Vendedor)) <> N''
        SET @Where = @Where + N' AND VENDEDOR = @Vendedor';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Clientes] ' + @Where + N';
    SELECT * FROM [dbo].[Clientes] ' + @Where + N'
    ORDER BY CODIGO
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Estado = @Estado,
        @Vendedor = @Vendedor,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Proveedores_List]
-- =============================================
CREATE PROCEDURE usp_Proveedores_List
    @Search NVARCHAR(100) = NULL,
    @Estado NVARCHAR(60) = NULL,
    @Vendedor NVARCHAR(2) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Estado NVARCHAR(60), @Vendedor NVARCHAR(2), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CODIGO LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND ESTADO = @Estado';
    IF @Vendedor IS NOT NULL AND LTRIM(RTRIM(@Vendedor)) <> N''
        SET @Where = @Where + N' AND VENDEDOR = @Vendedor';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Proveedores] ' + @Where + N';
    SELECT * FROM [dbo].[Proveedores] ' + @Where + N'
    ORDER BY CODIGO
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Estado = @Estado,
        @Vendedor = @Vendedor,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Inventario_List]
-- =============================================
CREATE PROCEDURE usp_Inventario_List
    @Search     NVARCHAR(100) = NULL,
    @Categoria  NVARCHAR(50)  = NULL,
    @Marca      NVARCHAR(50)  = NULL,
    @Linea      NVARCHAR(30)  = NULL,
    @Tipo       NVARCHAR(50)  = NULL,
    @Clase      NVARCHAR(25)  = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1  SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Construir cláusula WHERE dinámica
    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql   NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(1000) = N'@Search NVARCHAR(100), @Categoria NVARCHAR(50), @Marca NVARCHAR(50), @Linea NVARCHAR(30), @Tipo NVARCHAR(50), @Clase NVARCHAR(25), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    -- Búsqueda libre: busca en CODIGO, Referencia y todos los campos descriptivos
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CODIGO LIKE @Search OR Referencia LIKE @Search OR DESCRIPCION LIKE @Search OR Categoria LIKE @Search OR Tipo LIKE @Search OR Marca LIKE @Search OR Clase LIKE @Search OR Linea LIKE @Search)';

    -- Filtros exactos por campo
    IF @Categoria IS NOT NULL AND LTRIM(RTRIM(@Categoria)) <> N''
        SET @Where = @Where + N' AND Categoria = @Categoria';
    IF @Marca IS NOT NULL AND LTRIM(RTRIM(@Marca)) <> N''
        SET @Where = @Where + N' AND Marca = @Marca';
    IF @Linea IS NOT NULL AND LTRIM(RTRIM(@Linea)) <> N''
        SET @Where = @Where + N' AND Linea = @Linea';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';
    IF @Clase IS NOT NULL AND LTRIM(RTRIM(@Clase)) <> N''
        SET @Where = @Where + N' AND Clase = @Clase';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    -- Preparar parámetro de búsqueda con comodines
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    -- Descripción compuesta: CATEGORIA + TIPO + DESCRIPCION + MARCA + CLASE
    -- Se usa LTRIM/RTRIM para eliminar espacios sobrantes
    DECLARE @DescExpr NVARCHAR(500) = N'
        LTRIM(RTRIM(
            ISNULL(RTRIM(Categoria), '''') +
            CASE WHEN RTRIM(ISNULL(Tipo, '''')) <> '''' THEN '' '' + RTRIM(Tipo) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(DESCRIPCION, '''')) <> '''' THEN '' '' + RTRIM(DESCRIPCION) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(Marca, '''')) <> '''' THEN '' '' + RTRIM(Marca) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(Clase, '''')) <> '''' THEN '' '' + RTRIM(Clase) ELSE '''' END
        ))';

    -- Contar total
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Inventario] ' + @Where + N';';

    -- Seleccionar con campo DescripcionCompleta calculado
    SET @Sql = @Sql + N'
    SELECT *,
           ' + @DescExpr + N' AS DescripcionCompleta
    FROM [dbo].[Inventario] ' + @Where + N'
    ORDER BY CODIGO
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search    = @SearchParam,
        @Categoria = @Categoria,
        @Marca     = @Marca,
        @Linea     = @Linea,
        @Tipo      = @Tipo,
        @Clase     = @Clase,
        @Offset    = @Offset,
        @Limit     = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Empleados_List]
-- =============================================
CREATE PROCEDURE usp_Empleados_List
    @Search NVARCHAR(100) = NULL,
    @Grupo NVARCHAR(50) = NULL,
    @Status NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Grupo NVARCHAR(50), @Status NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CEDULA LIKE @Search OR NOMBRE LIKE @Search OR CARGO LIKE @Search)';
    IF @Grupo IS NOT NULL AND LTRIM(RTRIM(@Grupo)) <> N''
        SET @Where = @Where + N' AND GRUPO = @Grupo';
    IF @Status IS NOT NULL AND LTRIM(RTRIM(@Status)) <> N''
        SET @Where = @Where + N' AND STATUS = @Status';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Empleados] ' + @Where + N';
    SELECT * FROM [dbo].[Empleados] ' + @Where + N'
    ORDER BY NOMBRE
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Grupo = @Grupo,
        @Status = @Status,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cuentas_List]
-- =============================================
CREATE PROCEDURE usp_Cuentas_List
    @Search NVARCHAR(100) = NULL,
    @Tipo NVARCHAR(50) = NULL,
    @Grupo NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Grupo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (COD_CUENTA LIKE @Search OR DESCRIPCION LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND TIPO = @Tipo';
    IF @Grupo IS NOT NULL AND LTRIM(RTRIM(@Grupo)) <> N''
        SET @Where = @Where + N' AND grupo = @Grupo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Cuentas] ' + @Where + N';
    SELECT * FROM [dbo].[Cuentas] ' + @Where + N'
    ORDER BY COD_CUENTA
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Tipo = @Tipo,
        @Grupo = @Grupo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Facturas_List]
-- =============================================
CREATE PROCEDURE usp_Facturas_List
    @NumFact NVARCHAR(20) = NULL,
    @CodUsuario NVARCHAR(10) = NULL,
    @From DATE = NULL,
    @To DATE = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@NumFact NVARCHAR(20), @CodUsuario NVARCHAR(10), @From DATE, @To DATE, @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @NumFact IS NOT NULL AND LTRIM(RTRIM(@NumFact)) <> N''
        SET @Where = @Where + N' AND NUM_FACT = @NumFact';
    IF @CodUsuario IS NOT NULL AND LTRIM(RTRIM(@CodUsuario)) <> N''
        SET @Where = @Where + N' AND COD_USUARIO = @CodUsuario';
    IF @From IS NOT NULL
        SET @Where = @Where + N' AND FECHA >= @From';
    IF @To IS NOT NULL
        SET @Where = @Where + N' AND FECHA <= @To';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Facturas] ' + @Where + N';
    SELECT * FROM [dbo].[Facturas] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @NumFact = @NumFact,
        @CodUsuario = @CodUsuario,
        @From = @From,
        @To = @To,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Compras_List]
-- =============================================
CREATE PROCEDURE usp_Compras_List
    @Search NVARCHAR(100) = NULL,
    @Proveedor NVARCHAR(10) = NULL,
    @Estado NVARCHAR(50) = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Proveedor NVARCHAR(10), @Estado NVARCHAR(50), @FechaDesde DATE, @FechaHasta DATE, @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (NUM_FACT LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Proveedor IS NOT NULL AND LTRIM(RTRIM(@Proveedor)) <> N''
        SET @Where = @Where + N' AND COD_PROVEEDOR = @Proveedor';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND TIPO = @Estado';
    IF @FechaDesde IS NOT NULL
        SET @Where = @Where + N' AND FECHA >= @FechaDesde';
    IF @FechaHasta IS NOT NULL
        SET @Where = @Where + N' AND FECHA <= @FechaHasta';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Compras] ' + @Where + N';
    SELECT * FROM [dbo].[Compras] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Proveedor = @Proveedor,
        @Estado = @Estado,
        @FechaDesde = @FechaDesde,
        @FechaHasta = @FechaHasta,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Cotizacion_List]
-- =============================================
CREATE PROCEDURE usp_Cotizacion_List
    @Search NVARCHAR(100) = NULL,
    @Codigo NVARCHAR(10) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(400) = N'@Search NVARCHAR(100), @Codigo NVARCHAR(10), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (NUM_FACT LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Codigo IS NOT NULL AND LTRIM(RTRIM(@Codigo)) <> N''
        SET @Where = @Where + N' AND CODIGO = @Codigo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Cotizacion] ' + @Where + N';
    SELECT * FROM [dbo].[Cotizacion] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Codigo = @Codigo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Pedidos_List]
-- =============================================
CREATE PROCEDURE usp_Pedidos_List
    @Search NVARCHAR(100) = NULL,
    @Codigo NVARCHAR(10) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(400) = N'@Search NVARCHAR(100), @Codigo NVARCHAR(10), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (NUM_FACT LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Codigo IS NOT NULL AND LTRIM(RTRIM(@Codigo)) <> N''
        SET @Where = @Where + N' AND CODIGO = @Codigo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Pedidos] ' + @Where + N';
    SELECT * FROM [dbo].[Pedidos] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Codigo = @Codigo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Ajuste_Crear]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Ajuste_Crear
  @Fecha DATE,
  @TipoAjuste NVARCHAR(40),
  @Referencia NVARCHAR(120) = NULL,
  @Motivo NVARCHAR(500),
  @CodUsuario NVARCHAR(40) = NULL,
  @DetalleXml XML,
  @AsientoId BIGINT OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  DECLARE @NumeroAsiento NVARCHAR(40);

  EXEC dbo.usp_Contabilidad_Asiento_Crear
    @Fecha = @Fecha,
    @TipoAsiento = @TipoAjuste,
    @Referencia = @Referencia,
    @Concepto = @Motivo,
    @Moneda = N'VES',
    @Tasa = 1,
    @OrigenModulo = N'AJUSTE',
    @OrigenDocumento = @Referencia,
    @CodUsuario = @CodUsuario,
    @DetalleXml = @DetalleXml,
    @AsientoId = @AsientoId OUTPUT,
    @NumeroAsiento = @NumeroAsiento OUTPUT,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
END;

GO


-- =============================================
-- SQL_STORED_PROCEDURE [dbo].[usp_Contabilidad_Depreciacion_Generar]
-- =============================================

CREATE PROCEDURE dbo.usp_Contabilidad_Depreciacion_Generar
  @Periodo NVARCHAR(7),
  @CodUsuario NVARCHAR(40) = NULL,
  @CentroCosto NVARCHAR(20) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 1;
  SET @Mensaje = N'Proceso de depreciacion preparado (sin reglas cargadas).';
END;

GO

