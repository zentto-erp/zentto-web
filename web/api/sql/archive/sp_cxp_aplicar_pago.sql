-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Este SP (v1) ha sido supersedido por sp_cxp_aplicar_pago_v2.sql
-- que ya usa master.Supplier directamente desde el API TypeScript.
-- Mantener solo como referencia historica.
-- =============================================
-- Stored Procedure: Aplicar Pago (CxP)
-- Descripcion: Aplica un pago a documentos de proveedores
--              Genera movimientos bancarios automaticamente
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_CxP_AplicarPago')
    DROP PROCEDURE usp_CxP_AplicarPago
GO

CREATE PROCEDURE usp_CxP_AplicarPago
    @RequestId VARCHAR(100),
    @CodProveedor VARCHAR(20),
    @Fecha VARCHAR(10),
    @MontoTotal DECIMAL(18,2),
    @CodUsuario VARCHAR(20),
    @Observaciones VARCHAR(500) = '',
    @DocumentosXml NVARCHAR(MAX),
    @FormasPagoXml NVARCHAR(MAX),
    @NumPago VARCHAR(50) OUTPUT,
    @Resultado INT OUTPUT,
    @Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @dx XML;
    DECLARE @px XML;
    DECLARE @FechaDate DATETIME;
    DECLARE @Timestamp VARCHAR(20);
    DECLARE @ProxRecnum INT;
    DECLARE @NombreProveedor NVARCHAR(255);

    -- Inicializar salidas
    SET @Resultado = 0;
    SET @Mensaje = '';
    SET @NumPago = '';

    BEGIN TRY
        -- Convertir XML
        SET @dx = CAST(@DocumentosXml AS XML);
        SET @px = CAST(@FormasPagoXml AS XML);
        SET @FechaDate = CAST(@Fecha AS DATETIME);

        -- Generar numero de pago
        SET @Timestamp = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), '-', ''), ' ', ''), ':', '');
        SET @NumPago = 'PG' + LEFT(@Timestamp, 12);

        -- Obtener proximo RECNUM para Abonos
        -- TODO: tabla Abonos es legacy; migrar a tabla canonica en el API
        SELECT @ProxRecnum = ISNULL(MAX(CAST(RECNUM AS INT)), 0) + 1 FROM Abonos;

        -- Validar que el proveedor existe en master.Supplier (tabla canonica)
        SELECT @NombreProveedor = SupplierName
        FROM master.Supplier
        WHERE SupplierCode = @CodProveedor
          AND ISNULL(IsDeleted, 0) = 0;

        IF @NombreProveedor IS NULL
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = 'Proveedor no encontrado: ' + @CodProveedor;
            RETURN;
        END

        BEGIN TRANSACTION;

        -- ============================================
        -- 1. Insertar cabecera en Abonos (Pago)
        -- TODO: tabla Abonos es legacy; migrar a tabla canonica en el API
        -- ============================================
        INSERT INTO Abonos (
            CODIGO, RECNUM, FECHA, DOCUMENTO, PEND, APLICADO, SALDO, CANC,
            PAGO, CHEQUE, BANCO, NOMBRE, TIPO, Legal,
            obs, ANULADO, NOTA, CONTROL, PorcentajeDescuento
        )
        VALUES (
            @CodProveedor,
            @ProxRecnum,
            @FechaDate,
            @NumPago,
            0,  -- PEND
            CAST(@MontoTotal AS FLOAT),  -- APLICADO
            0,  -- SALDO
            0,  -- CANC
            'EFECTIVO',
            0,  -- CHEQUE
            '',  -- BANCO
            @NombreProveedor,
            '',  -- Tipo
            0,  -- Legal
            @Observaciones,
            0,  -- ANULADO
            '',  -- NOTA
            '',  -- CONTROL
            0   -- PorcentajeDescuento
        );

        -- ============================================
        -- 2. Insertar formas de pago en Abonos_Detalle
        --    Y generar movimientos bancarios si aplica
        -- ============================================

        -- Tabla temporal para procesar formas de pago
        DECLARE @FormasPago TABLE (
            RowNum INT IDENTITY(1,1),
            FormaPago NVARCHAR(60),
            Monto DECIMAL(18,2),
            Banco NVARCHAR(120),
            NumCheque NVARCHAR(80),
            FechaVencimiento NVARCHAR(20),
            EsBancaria BIT
        );

        INSERT INTO @FormasPago (FormaPago, Monto, Banco, NumCheque, FechaVencimiento, EsBancaria)
        SELECT
            ISNULL(NULLIF(T.X.value('@formaPago', 'nvarchar(60)'), ''), 'EFECTIVO'),
            ISNULL(CAST(NULLIF(T.X.value('@monto', 'nvarchar(50)'), '') AS DECIMAL(18,2)), 0),
            ISNULL(NULLIF(T.X.value('@banco', 'nvarchar(120)'), ''), ''),
            ISNULL(NULLIF(T.X.value('@numCheque', 'nvarchar(80)'), ''), ''),
            NULLIF(T.X.value('@fechaVencimiento', 'nvarchar(20)'), ''),
            CASE
                WHEN ISNULL(NULLIF(T.X.value('@formaPago', 'nvarchar(60)'), ''), 'EFECTIVO')
                    IN ('CHEQUE', 'TRANSFERENCIA', 'DEPOSITO', 'TARJETA', 'ACH')
                THEN 1 ELSE 0
            END
        FROM @px.nodes('/formasPago/row') T(X);

        -- TODO: tabla Abonos_Detalle es legacy; migrar a tabla canonica en el API
        -- Insertar en Abonos_Detalle
        INSERT INTO Abonos_Detalle (
            RECNUM, FECHA, TIPO, CUENTA, NUMERO, MONTO,
            ANULADO, BANCO, codigo
        )
        SELECT
            @ProxRecnum,
            @FechaDate,
            f.FormaPago,
            '',  -- CUENTA
            f.NumCheque,
            CAST(f.Monto AS FLOAT),
            0,  -- ANULADO
            f.Banco,
            @CodProveedor
        FROM @FormasPago f;

        -- ============================================
        -- 3. Generar movimientos bancarios automaticos
        -- ============================================
        DECLARE @FpRowNum INT = 1;
        DECLARE @FpFormaPago NVARCHAR(60);
        DECLARE @FpMonto DECIMAL(18,2);
        DECLARE @FpBanco NVARCHAR(120);
        DECLARE @FpNumCheque NVARCHAR(80);
        DECLARE @FpEsBancaria BIT;
        DECLARE @NroCta NVARCHAR(20);
        DECLARE @TipoMovBank NVARCHAR(10);

        WHILE EXISTS (SELECT 1 FROM @FormasPago WHERE RowNum = @FpRowNum)
        BEGIN
            SELECT
                @FpFormaPago = FormaPago,
                @FpMonto = Monto,
                @FpBanco = Banco,
                @FpNumCheque = NumCheque,
                @FpEsBancaria = EsBancaria
            FROM @FormasPago
            WHERE RowNum = @FpRowNum;

            -- Si es forma de pago bancaria, generar movimiento
            IF @FpEsBancaria = 1 AND @FpMonto > 0
            BEGIN
                -- Buscar cuenta bancaria por banco
                SELECT TOP 1 @NroCta = Nro_Cta
                FROM CuentasBank
                WHERE Banco LIKE '%' + @FpBanco + '%' OR Descripcion LIKE '%' + @FpBanco + '%';

                -- Si no se encontro por nombre, buscar cualquier cuenta activa
                IF @NroCta IS NULL
                    SELECT TOP 1 @NroCta = Nro_Cta FROM CuentasBank WHERE Activa = 1;

                IF @NroCta IS NOT NULL
                BEGIN
                    -- Determinar tipo de movimiento bancario
                    SET @TipoMovBank = CASE @FpFormaPago
                        WHEN 'CHEQUE' THEN 'PCH'
                        WHEN 'TRANSFERENCIA' THEN 'PCH'
                        WHEN 'ACH' THEN 'PCH'
                        WHEN 'DEPOSITO' THEN 'DEP'
                        WHEN 'TARJETA' THEN 'PCH'
                        ELSE 'PCH'
                    END;

                    -- Generar movimiento bancario (egreso)
                    EXEC sp_GenerarMovimientoBancario
                        @Nro_Cta = @NroCta,
                        @Tipo = @TipoMovBank,
                        @Nro_Ref = ISNULL(NULLIF(@FpNumCheque, ''), @NumPago),
                        @Beneficiario = @NombreProveedor,
                        @Monto = @FpMonto,
                        @Concepto = 'Pago a proveedor: ' + @NumPago + ' - ' + LEFT(@Observaciones, 50),
                        @Categoria = 'PROVEEDORES',
                        @Co_Usuario = @CodUsuario,
                        @Documento_Relacionado = @NumPago,
                        @Tipo_Doc_Rel = 'PAGO_PROV';
                END
            END

            SET @FpRowNum = @FpRowNum + 1;
        END

        -- ============================================
        -- 4. Procesar documentos (P_Pagar)
        -- TODO: tabla P_Pagar es legacy; migrar a tabla canonica en el API
        -- ============================================
        DECLARE @TipoDoc VARCHAR(10);
        DECLARE @NumDoc VARCHAR(20);
        DECLARE @MontoAplicar DECIMAL(18,2);
        DECLARE @PendienteActual FLOAT;
        DECLARE @NuevoPendiente FLOAT;

        -- Crear tabla temporal para iterar documentos
        DECLARE @Docs TABLE (
            RowNum INT IDENTITY(1,1),
            TipoDoc VARCHAR(10),
            NumDoc VARCHAR(20),
            MontoAplicar DECIMAL(18,2)
        );

        INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
        SELECT
            NULLIF(T.X.value('@tipoDoc', 'nvarchar(10)'), ''),
            NULLIF(T.X.value('@numDoc', 'nvarchar(20)'), ''),
            ISNULL(CAST(NULLIF(T.X.value('@montoAplicar', 'nvarchar(50)'), '') AS DECIMAL(18,2)), 0)
        FROM @dx.nodes('/documentos/row') T(X);

        -- Iterar sobre cada documento
        DECLARE @RowIdx INT = 1;

        WHILE EXISTS (SELECT 1 FROM @Docs WHERE RowNum = @RowIdx)
        BEGIN
            SELECT
                @TipoDoc = TipoDoc,
                @NumDoc = NumDoc,
                @MontoAplicar = MontoAplicar
            FROM @Docs
            WHERE RowNum = @RowIdx;

            -- Verificar que el documento existe en P_Pagar
            IF NOT EXISTS (
                SELECT 1 FROM P_Pagar
                WHERE DOCUMENTO = @NumDoc
                AND TIPO = @TipoDoc
                AND CODIGO = @CodProveedor
            )
            BEGIN
                SET @Resultado = -2;
                SET @Mensaje = 'Documento no encontrado: ' + @TipoDoc + '-' + @NumDoc;
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Obtener pendiente actual
            SELECT @PendienteActual = ISNULL(PEND, ISNULL(SALDO, 0))
            FROM P_Pagar
            WHERE DOCUMENTO = @NumDoc
            AND TIPO = @TipoDoc
            AND CODIGO = @CodProveedor;

            -- Validar saldo
            IF @PendienteActual <= 0
            BEGIN
                SET @Resultado = -3;
                SET @Mensaje = 'Documento ' + @TipoDoc + '-' + @NumDoc + ' ya esta cancelado';
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF CAST(@MontoAplicar AS FLOAT) > @PendienteActual
            BEGIN
                SET @Resultado = -4;
                SET @Mensaje = 'Monto excede pendiente en ' + @TipoDoc + '-' + @NumDoc;
                ROLLBACK TRANSACTION;
                RETURN;
            END

            SET @NuevoPendiente = @PendienteActual - CAST(@MontoAplicar AS FLOAT);

            -- Actualizar P_Pagar
            UPDATE P_Pagar
            SET PEND = @NuevoPendiente,
                SALDO = @NuevoPendiente,
                PAID = CASE WHEN @NuevoPendiente <= 0 THEN 1 ELSE 0 END,
                DEBE = ISNULL(DEBE, 0) + CAST(@MontoAplicar AS FLOAT)
            WHERE DOCUMENTO = @NumDoc
            AND TIPO = @TipoDoc
            AND CODIGO = @CodProveedor;

            -- TODO: tabla Movimiento_Cuenta es legacy; migrar a tabla canonica en el API
            -- Insertar en Movimiento_Cuenta (por cada documento)
            INSERT INTO Movimiento_Cuenta (
                COD_CUENTA, COD_OPER, FECHA, DEBE, HABER, COD_USUARIO,
                COD_PROVEEDOR, DESCRIPCION, CONCEPTO, Pago, Contado,
                Equipo, NoMostrar, Cheque, Banco, RetIva
            )
            VALUES (
                @CodProveedor,
                @NumPago,
                @FechaDate,
                CAST(@MontoAplicar AS FLOAT),
                0,
                @CodUsuario,
                @CodProveedor,
                'Pago doc ' + @TipoDoc + '-' + @NumDoc,
                @Observaciones,
                1,
                1,
                'API',
                0,
                '',
                '',
                0
            );

            SET @RowIdx = @RowIdx + 1;
        END

        -- ============================================
        -- 5. Recalcular saldos del proveedor en master.Supplier (tabla canonica)
        -- ============================================
        DECLARE @SaldoTotal FLOAT;

        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0)
        FROM P_Pagar
        WHERE CODIGO = @CodProveedor
        AND PAID = 0;

        -- Actualizar TotalBalance en master.Supplier (columna canonica)
        UPDATE master.Supplier
        SET TotalBalance = @SaldoTotal
        WHERE SupplierCode = @CodProveedor
          AND ISNULL(IsDeleted, 0) = 0;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = 'Pago aplicado exitosamente. Pago: ' + @NumPago;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- Verificar creacion
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'usp_CxP_AplicarPago';
