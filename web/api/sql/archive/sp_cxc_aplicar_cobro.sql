-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Este SP (v1) ha sido supersedido por sp_cxc_aplicar_cobro_v2.sql
-- que ya usa master.Customer directamente desde el API TypeScript.
-- Mantener solo como referencia historica.
-- =============================================
-- Stored Procedure: Aplicar Cobro (CxC)
-- Descripcion: Aplica un cobro a documentos pendientes
--              Genera movimientos bancarios automaticamente
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_CxC_AplicarCobro')
    DROP PROCEDURE usp_CxC_AplicarCobro
GO

CREATE PROCEDURE usp_CxC_AplicarCobro
    @RequestId VARCHAR(100),
    @CodCliente VARCHAR(20),
    @Fecha VARCHAR(10),
    @MontoTotal DECIMAL(18,2),
    @CodUsuario VARCHAR(20),
    @Observaciones VARCHAR(500) = '',
    @DocumentosXml NVARCHAR(MAX),
    @FormasPagoXml NVARCHAR(MAX),
    @NumRecibo VARCHAR(50) OUTPUT,
    @Resultado INT OUTPUT,
    @Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    DECLARE @StartedTran BIT;
    DECLARE @SaveName SYSNAME;
    SET @StartedTran = 0;
    SET @SaveName = N'usp_CxC_AplicarCobro_save';

    DECLARE @dx XML;
    DECLARE @px XML;
    DECLARE @FechaDate DATETIME;
    DECLARE @Timestamp VARCHAR(20);
    DECLARE @ProxRecnum INT;
    DECLARE @NombreCliente NVARCHAR(255);

    -- Inicializar salidas
    SET @Resultado = 0;
    SET @Mensaje = '';
    SET @NumRecibo = '';

    BEGIN TRY
        -- Convertir XML
        SET @dx = CAST(@DocumentosXml AS XML);
        SET @px = CAST(@FormasPagoXml AS XML);
        SET @FechaDate = CAST(@Fecha AS DATETIME);

        -- Generar numero de recibo
        SET @Timestamp = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), '-', ''), ' ', ''), ':', '');
        SET @NumRecibo = 'RC' + LEFT(@Timestamp, 12);

        -- Obtener proximo RECNUM para Pagos
        -- TODO: tabla Pagos es legacy; migrar a tabla canonica de cobros en el API
        SELECT @ProxRecnum = ISNULL(MAX(CAST(RECNUM AS INT)), 0) + 1 FROM Pagos;

        -- Validar que el cliente existe en master.Customer (tabla canonica)
        SELECT @NombreCliente = CustomerName
        FROM master.Customer
        WHERE CustomerCode = @CodCliente
          AND ISNULL(IsDeleted, 0) = 0;

        IF @NombreCliente IS NULL
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = 'Cliente no encontrado: ' + @CodCliente;
            RETURN;
        END

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @StartedTran = 1;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION @SaveName;
        END

        -- ============================================
        -- 1. Insertar cabecera en Pagos (Recibo)
        -- TODO: tabla Pagos es legacy; migrar a tabla canonica en el API
        -- ============================================
        INSERT INTO Pagos (
            CODIGO, RECNUM, FECHA, DOCUMENTO, PEND, APLICADO, SALDO, CANC,
            PAGO, CHEQUE, BANCO, NOMBRE, COD_USUARIO, Tipo, Legal,
            obs, ANULADO, NOTA, CONTROL, PORCENTAJEDESCUENTO
        )
        VALUES (
            @CodCliente,
            @ProxRecnum,
            @FechaDate,
            @NumRecibo,
            0,  -- PEND
            @MontoTotal,  -- APLICADO
            0,  -- SALDO
            0,  -- CANC
            'CONTADO',
            0,  -- CHEQUE
            '',  -- BANCO
            @NombreCliente,
            @CodUsuario,
            '',  -- Tipo
            0,  -- Legal
            @Observaciones,
            0,  -- ANULADO
            '',  -- NOTA
            '',  -- CONTROL
            0   -- PORCENTAJEDESCUENTO
        );

        -- ============================================
        -- 2. Insertar formas de pago en Pagos_Detalle
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
                    IN ('CHEQUE', 'TRANSFERENCIA', 'DEPOSITO', 'TARJETA', 'ACH', 'DEP')
                THEN 1 ELSE 0
            END
        FROM @px.nodes('/formasPago/row') T(X);

        -- TODO: tabla Pagos_Detalle es legacy; migrar a tabla canonica en el API
        -- Insertar en Pagos_Detalle
        INSERT INTO Pagos_Detalle (
            RECNUM, FECHA, TIPO, CUENTA, NUMERO, MONTO,
            ANULADO, BANCO, CODIGO
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
            @CodCliente
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
                    -- Para cobros (ingresos): DEP (deposito) o NCR (nota credito)
                    SET @TipoMovBank = CASE @FpFormaPago
                        WHEN 'CHEQUE' THEN 'NCR'  -- Cheque de terceros = nota credito
                        WHEN 'TRANSFERENCIA' THEN 'DEP'
                        WHEN 'ACH' THEN 'DEP'
                        WHEN 'DEPOSITO' THEN 'DEP'
                        WHEN 'DEP' THEN 'DEP'
                        WHEN 'TARJETA' THEN 'DEP'
                        ELSE 'DEP'
                    END;

                    -- Generar movimiento bancario (ingreso)
                    EXEC sp_GenerarMovimientoBancario
                        @Nro_Cta = @NroCta,
                        @Tipo = @TipoMovBank,
                        @Nro_Ref = ISNULL(NULLIF(@FpNumCheque, ''), @NumRecibo),
                        @Beneficiario = @NombreCliente,
                        @Monto = @FpMonto,
                        @Concepto = 'Cobro a cliente: ' + @NumRecibo + ' - ' + LEFT(@Observaciones, 50),
                        @Categoria = 'CLIENTES',
                        @Co_Usuario = @CodUsuario,
                        @Documento_Relacionado = @NumRecibo,
                        @Tipo_Doc_Rel = 'COBRO_CLI';
                END
            END

            SET @FpRowNum = @FpRowNum + 1;
        END

        -- ============================================
        -- 4. Procesar documentos (P_Cobrar)
        -- TODO: tabla P_Cobrar es legacy; migrar a tabla canonica en el API
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

            -- Verificar que el documento existe en P_Cobrar
            IF NOT EXISTS (
                SELECT 1 FROM P_Cobrar
                WHERE DOCUMENTO = @NumDoc
                AND TIPO = @TipoDoc
                AND CODIGO = @CodCliente
            )
            BEGIN
                SET @Resultado = -2;
                SET @Mensaje = 'Documento no encontrado: ' + @TipoDoc + '-' + @NumDoc;
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Obtener pendiente actual
            SELECT @PendienteActual = ISNULL(PEND, ISNULL(SALDO, 0))
            FROM P_Cobrar
            WHERE DOCUMENTO = @NumDoc
            AND TIPO = @TipoDoc
            AND CODIGO = @CodCliente;

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

            -- Actualizar P_Cobrar
            UPDATE P_Cobrar
            SET PEND = @NuevoPendiente,
                SALDO = @NuevoPendiente,
                PAID = CASE WHEN @NuevoPendiente <= 0 THEN 1 ELSE 0 END,
                HABER = ISNULL(HABER, 0) + CAST(@MontoAplicar AS FLOAT)
            WHERE DOCUMENTO = @NumDoc
            AND TIPO = @TipoDoc
            AND CODIGO = @CodCliente;

            -- TODO: tabla Movimiento_Cuenta es legacy; migrar a tabla canonica en el API
            -- Insertar en Movimiento_Cuenta (por cada documento)
            INSERT INTO Movimiento_Cuenta (
                COD_CUENTA, COD_OPER, FECHA, DEBE, HABER, COD_USUARIO,
                COD_PROVEEDOR, DESCRIPCION, CONCEPTO, Pago, Contado,
                Equipo, NoMostrar, Cheque, Banco, RetIva
            )
            VALUES (
                @CodCliente,
                @NumRecibo,
                @FechaDate,
                0,
                CAST(@MontoAplicar AS FLOAT),
                @CodUsuario,
                @CodCliente,
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
        -- 5. Recalcular saldos del cliente en master.Customer (tabla canonica)
        -- ============================================
        DECLARE @SaldoTotal FLOAT;

        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0)
        FROM P_Cobrar
        WHERE CODIGO = @CodCliente
        AND PAID = 0;

        -- Actualizar TotalBalance en master.Customer (columna canonica)
        UPDATE master.Customer
        SET TotalBalance = @SaldoTotal
        WHERE CustomerCode = @CodCliente
          AND ISNULL(IsDeleted, 0) = 0;

        IF @StartedTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = 'Cobro aplicado exitosamente. Recibo: ' + @NumRecibo;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @StartedTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION @SaveName;
        END

        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- Verificar creacion
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'usp_CxC_AplicarCobro';
