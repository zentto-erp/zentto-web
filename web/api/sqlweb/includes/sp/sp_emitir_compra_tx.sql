-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Referencias a dbo.Inventario actualizadas a master.Product (StockQty, ProductCode, SalesPrice).
-- Referencias a dbo.Proveedores actualizadas a master.Supplier (TotalBalance, SupplierCode).
-- Tablas legacy sin migrar (Compras, Detalle_Compras, P_Pagar, etc.)
-- mantienen sus nombres originales — ver TODOs en el codigo.
-- =============================================
-- Stored Procedure: Emitir Compra (Compras)
-- Descripción: Emite una compra con inventario y CxP
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_compra_tx')
    DROP PROCEDURE sp_emitir_compra_tx
GO

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
        SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE SYSUTCDATETIME() END;
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
        -- TODO: tabla Compras es legacy
        IF EXISTS (SELECT 1 FROM Compras WHERE NUM_FACT = @NumFact)
        BEGIN
            RAISERROR('compra_already_exists', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;

        -- ============================================
        -- 1. Insertar cabecera en Compras
        -- TODO: tabla Compras es legacy
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
        -- TODO: tabla Detalle_Compras es legacy
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
        -- 3. Actualizar master.Product (antes dbo.Inventario) — Ingreso
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
                ISNULL(INV.StockQty, 0),            -- columna canonica master.Product
                I.CANTIDAD,
                ISNULL(INV.StockQty, 0) + I.CANTIDAD,
                @CodUsuario,
                I.PRECIO_COSTO,
                I.ALICUOTA,
                ISNULL(INV.SalesPrice, 0)           -- columna canonica master.Product
            FROM @Items I
            -- Ahora se usa master.Product (antes dbo.Inventario)
            INNER JOIN master.Product INV ON INV.ProductCode = I.COD_SERV
            WHERE I.COD_SERV IS NOT NULL AND I.CANTIDAD > 0;

            -- Actualizar existencias en master.Product.StockQty (antes dbo.Inventario.EXISTENCIA)
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL
                FROM @Items
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            UPDATE INV
            SET StockQty = ISNULL(INV.StockQty, 0) + T.TOTAL
            FROM master.Product INV
            INNER JOIN Totales T ON T.COD_SERV = INV.ProductCode;
        END

        -- ============================================
        -- 4. Generar CxP (si es crédito)
        -- TODO: tabla P_Pagar es legacy
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
        -- 5. Actualizar saldos del proveedor en master.Supplier (tabla canonica)
        -- Antes actualizaba dbo.Proveedores; ahora actualiza master.Supplier.TotalBalance
        -- ============================================
        IF @ActualizarSaldosProveedor = 1 AND @CodProveedor IS NOT NULL AND LTRIM(RTRIM(@CodProveedor)) <> ''
        BEGIN
            DECLARE @SaldoTotal FLOAT;

            -- TODO: tabla P_Pagar es legacy
            SELECT @SaldoTotal = ISNULL(SUM(CASE WHEN TIPO = 'FACT' THEN ISNULL(PEND, 0) ELSE 0 END), 0)
            FROM P_Pagar
            WHERE CODIGO = @CodProveedor;

            -- Actualizar master.Supplier.TotalBalance (columna canonica, antes dbo.Proveedores.SALDO_TOT)
            UPDATE master.Supplier
            SET TotalBalance = @SaldoTotal
            WHERE SupplierCode = @CodProveedor
              AND ISNULL(IsDeleted, 0) = 0;
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

-- Verificar creación
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_compra_tx';
