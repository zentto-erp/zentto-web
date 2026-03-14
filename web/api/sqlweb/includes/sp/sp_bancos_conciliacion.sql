-- =============================================
-- Sistema de Conciliacion Bancaria
-- Tablas y Stored Procedures
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- 1. TABLA: ExtractoBancario (Importar datos del banco)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExtractoBancario')
BEGIN
    CREATE TABLE ExtractoBancario (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Nro_Cta NVARCHAR(20) NOT NULL,
        Fecha DATETIME NOT NULL,
        Descripcion NVARCHAR(255) NULL,
        Referencia NVARCHAR(50) NULL,
        Tipo NVARCHAR(10) NULL,              -- DEBITO/CREDITO
        Monto DECIMAL(18,2) NOT NULL,
        Saldo DECIMAL(18,2) NULL,
        Conciliado BIT NULL DEFAULT 0,
        Fecha_Conciliacion DATETIME NULL,
        MovCuentas_ID INT NULL,              -- Vinculo a MovCuentas si existe
        Co_Usuario NVARCHAR(60) NULL DEFAULT 'API',
        Fecha_Reg DATETIME NULL DEFAULT GETDATE()
    );
    
    CREATE INDEX IX_Extracto_NroCta ON ExtractoBancario(Nro_Cta, Fecha);
    CREATE INDEX IX_Extracto_Conciliado ON ExtractoBancario(Conciliado);
    CREATE INDEX IX_Extracto_Ref ON ExtractoBancario(Referencia);
END
GO

-- =============================================
-- 2. TABLA: ConciliacionBancaria
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConciliacionBancaria')
BEGIN
    CREATE TABLE ConciliacionBancaria (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Nro_Cta NVARCHAR(20) NOT NULL,
        Fecha_Desde DATETIME NOT NULL,
        Fecha_Hasta DATETIME NOT NULL,
        Saldo_Inicial_Sistema DECIMAL(18,2) NULL DEFAULT 0,
        Saldo_Final_Sistema DECIMAL(18,2) NULL DEFAULT 0,
        Saldo_Inicial_Banco DECIMAL(18,2) NULL DEFAULT 0,
        Saldo_Final_Banco DECIMAL(18,2) NULL DEFAULT 0,
        Diferencia DECIMAL(18,2) NULL DEFAULT 0,
        Estado NVARCHAR(20) NULL DEFAULT 'PENDIENTE', -- PENDIENTE, CONCILIADO, AJUSTADO
        Observaciones NVARCHAR(500) NULL,
        Co_Usuario NVARCHAR(60) NULL DEFAULT 'API',
        Fecha_Creacion DATETIME NULL DEFAULT GETDATE(),
        Fecha_Cierre DATETIME NULL
    );
    
    CREATE INDEX IX_Conciliacion_NroCta ON ConciliacionBancaria(Nro_Cta, Fecha_Desde);
END
GO

-- =============================================
-- 3. TABLA: ConciliacionDetalle
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConciliacionDetalle')
BEGIN
    CREATE TABLE ConciliacionDetalle (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Conciliacion_ID INT NOT NULL,
        Tipo_Origen NVARCHAR(20) NOT NULL,   -- SISTEMA, BANCO, AJUSTE
        MovCuentas_ID INT NULL,              -- Si es de sistema
        Extracto_ID INT NULL,                -- Si es del banco
        Fecha DATETIME NULL,
        Descripcion NVARCHAR(255) NULL,
        Referencia NVARCHAR(50) NULL,
        Debito DECIMAL(18,2) NULL DEFAULT 0,
        Credito DECIMAL(18,2) NULL DEFAULT 0,
        Conciliado BIT NULL DEFAULT 0,
        Tipo_Ajuste NVARCHAR(20) NULL,       -- NOTA_CREDITO, NOTA_DEBITO, AJUSTE
        Co_Usuario NVARCHAR(60) NULL DEFAULT 'API'
    );
    
    CREATE INDEX IX_ConcDet_Conciliacion ON ConciliacionDetalle(Conciliacion_ID);
END
GO

-- =============================================
-- 4. SP: Generar movimiento bancario desde pago/cobro
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GenerarMovimientoBancario')
    DROP PROCEDURE sp_GenerarMovimientoBancario
GO

CREATE PROCEDURE sp_GenerarMovimientoBancario
    @Nro_Cta NVARCHAR(20),
    @Tipo NVARCHAR(10),              -- PCH, DEP, NCR, NDB
    @Nro_Ref NVARCHAR(30),
    @Beneficiario NVARCHAR(255),
    @Monto DECIMAL(18,2),
    @Concepto NVARCHAR(100),
    @Categoria NVARCHAR(50) = NULL,
    @Co_Usuario NVARCHAR(60) = 'API',
    @Documento_Relacionado NVARCHAR(60) = NULL,  -- FACT, COMPRA, etc.
    @Tipo_Doc_Rel NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @Gastos DECIMAL(18,2) = 0;
    DECLARE @Ingresos DECIMAL(18,2) = 0;
    DECLARE @Saldo_Actual DECIMAL(18,2);
    DECLARE @Saldo_Dia DECIMAL(18,2);
    
    -- Validar cuenta existe
    IF NOT EXISTS (SELECT 1 FROM CuentasBank WHERE Nro_Cta = @Nro_Cta)
    BEGIN
        RAISERROR('cuenta_bancaria_no_existe', 16, 1);
        RETURN;
    END
    
    -- Determinar si es gasto o ingreso segun tipo
    -- PCH (cheque), NDB (nota debito) = Gasto
    -- DEP (deposito), NCR (nota credito) = Ingreso
    IF @Tipo IN ('PCH', 'NDB', 'IDB') 
        SET @Gastos = @Monto;
    ELSE IF @Tipo IN ('DEP', 'NCR')
        SET @Ingresos = @Monto;
    
    -- Obtener saldo actual
    SELECT @Saldo_Actual = ISNULL(Saldo, 0) FROM CuentasBank WHERE Nro_Cta = @Nro_Cta;
    
    -- Calcular nuevo saldo
    SET @Saldo_Actual = @Saldo_Actual + @Ingresos - @Gastos;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar en MovCuentas
        INSERT INTO MovCuentas (Nro_Cta, Fecha, Tipo, Nro_Ref, Beneficiario, Categoria, 
                                 Gastos, Ingresos, Saldo_Dia, Saldo, Confirmada, 
                                 Co_Usuario, Concepto, Fecha_Banco)
        SELECT @Nro_Cta, GETDATE(), @Tipo, @Nro_Ref, @Beneficiario, @Categoria,
               @Gastos, @Ingresos, @Saldo_Actual, @Saldo_Actual, 0, 
               @Co_Usuario, @Concepto, NULL;
        
        -- Actualizar saldo en CuentasBank
        UPDATE CuentasBank SET 
            Saldo = @Saldo_Actual,
            Saldo_Disponible = @Saldo_Actual
        WHERE Nro_Cta = @Nro_Cta;
        
        -- Si hay documento relacionado, insertar en Movimiento_Cuenta para control contable
        IF @Documento_Relacionado IS NOT NULL
        BEGIN
            DECLARE @Debe FLOAT = CASE WHEN @Gastos > 0 THEN @Gastos ELSE 0 END;
            DECLARE @Haber FLOAT = CASE WHEN @Ingresos > 0 THEN @Ingresos ELSE 0 END;
            
            INSERT INTO Movimiento_Cuenta (COD_CUENTA, COD_OPER, FECHA, DEBE, HABER, 
                                            COD_USUARIO, DESCRIPCION, CONCEPTO, Banco, Cheque)
            VALUES (@Nro_Cta, @Tipo_Doc_Rel, GETDATE(), @Debe, @Haber, 
                    @Co_Usuario, @Concepto, @Documento_Relacionado, 
                    (SELECT Banco FROM CuentasBank WHERE Nro_Cta = @Nro_Cta), @Nro_Ref);
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, SCOPE_IDENTITY() AS movimientoId, @Saldo_Actual AS saldoNuevo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 5. SP: Crear conciliacion bancaria
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CrearConciliacion')
    DROP PROCEDURE sp_CrearConciliacion
GO

CREATE PROCEDURE sp_CrearConciliacion
    @Nro_Cta NVARCHAR(20),
    @Fecha_Desde DATETIME,
    @Fecha_Hasta DATETIME,
    @Co_Usuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Saldo_Inicial DECIMAL(18,2) = 0;
    DECLARE @Saldo_Final DECIMAL(18,2) = 0;
    
    -- Obtener saldo inicial (al inicio del periodo)
    SELECT TOP 1 @Saldo_Inicial = ISNULL(Saldo, 0)
    FROM MovCuentas 
    WHERE Nro_Cta = @Nro_Cta AND Fecha < @Fecha_Desde
    ORDER BY Fecha DESC, id DESC;
    
    -- Si no hay movimientos previos, tomar saldo apertura de CuentasBank
    IF @Saldo_Inicial IS NULL
        SELECT @Saldo_Inicial = ISNULL(Saldo_Apertura, 0) FROM CuentasBank WHERE Nro_Cta = @Nro_Cta;
    
    -- Obtener saldo final (movimientos hasta fecha hasta)
    SELECT TOP 1 @Saldo_Final = ISNULL(Saldo, 0)
    FROM MovCuentas 
    WHERE Nro_Cta = @Nro_Cta AND Fecha <= @Fecha_Hasta
    ORDER BY Fecha DESC, id DESC;
    
    IF @Saldo_Final IS NULL SET @Saldo_Final = @Saldo_Inicial;
    
    -- Crear conciliacion
    INSERT INTO ConciliacionBancaria (Nro_Cta, Fecha_Desde, Fecha_Hasta, 
                                       Saldo_Inicial_Sistema, Saldo_Final_Sistema,
                                       Estado, Co_Usuario, Fecha_Creacion)
    VALUES (@Nro_Cta, @Fecha_Desde, @Fecha_Hasta, 
            @Saldo_Inicial, @Saldo_Final, 'PENDIENTE', @Co_Usuario, GETDATE());
    
    DECLARE @Conciliacion_ID INT = SCOPE_IDENTITY();
    
    -- Insertar movimientos del sistema no conciliados
    INSERT INTO ConciliacionDetalle (Conciliacion_ID, Tipo_Origen, MovCuentas_ID, 
                                      Fecha, Descripcion, Referencia, Debito, Credito, Conciliado)
    SELECT @Conciliacion_ID, 'SISTEMA', id, Fecha, Concepto, Nro_Ref, 
           ISNULL(Gastos, 0), ISNULL(Ingresos, 0), Confirmada
    FROM MovCuentas 
    WHERE Nro_Cta = @Nro_Cta 
      AND Fecha BETWEEN @Fecha_Desde AND @Fecha_Hasta
      AND Confirmada = 0;  -- Solo no conciliados
    
    SELECT @Conciliacion_ID AS conciliacionId, @Saldo_Inicial AS saldoInicial, @Saldo_Final AS saldoFinal;
END
GO

-- =============================================
-- 6. SP: Importar extracto bancario
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ImportarExtracto')
    DROP PROCEDURE sp_ImportarExtracto
GO

CREATE PROCEDURE sp_ImportarExtracto
    @ExtractoXml NVARCHAR(MAX),  -- XML con datos del extracto
    @Nro_Cta NVARCHAR(20),
    @Co_Usuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @x XML = CAST(@ExtractoXml AS XML);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO ExtractoBancario (Nro_Cta, Fecha, Descripcion, Referencia, Tipo, Monto, Saldo, Conciliado, Co_Usuario)
        SELECT 
            @Nro_Cta,
            CASE WHEN ISDATE(X.value('@Fecha', 'nvarchar(50)')) = 1 
                 THEN CAST(X.value('@Fecha', 'nvarchar(50)') AS DATETIME) 
                 ELSE GETDATE() END,
            NULLIF(X.value('@Descripcion', 'nvarchar(255)'), ''),
            NULLIF(X.value('@Referencia', 'nvarchar(50)'), ''),
            NULLIF(X.value('@Tipo', 'nvarchar(10)'), ''),  -- DEBITO/CREDITO
            CASE WHEN ISNUMERIC(X.value('@Monto', 'nvarchar(50)')) = 1 
                 THEN CAST(X.value('@Monto', 'nvarchar(50)') AS DECIMAL(18,2)) 
                 ELSE 0 END,
            CASE WHEN ISNUMERIC(X.value('@Saldo', 'nvarchar(50)')) = 1 
                 THEN CAST(X.value('@Saldo', 'nvarchar(50)') AS DECIMAL(18,2)) 
                 ELSE NULL END,
            0,  -- No conciliado
            @Co_Usuario
        FROM @x.nodes('/extracto/row') T(X);
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, 
               (SELECT COUNT(1) FROM @x.nodes('/extracto/row') T(X)) AS registrosImportados;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 7. SP: Conciliar movimientos
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ConciliarMovimientos')
    DROP PROCEDURE sp_ConciliarMovimientos
GO

CREATE PROCEDURE sp_ConciliarMovimientos
    @Conciliacion_ID INT,
    @MovimientoSistema_ID INT,      -- ID de ConciliacionDetalle (Tipo_Origen = SISTEMA)
    @Extracto_ID INT = NULL,         -- ID de ExtractoBancario (opcional, para match manual)
    @Co_Usuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Marcar como conciliado en detalle
        UPDATE ConciliacionDetalle SET 
            Conciliado = 1,
            Extracto_ID = @Extracto_ID
        WHERE ID = @MovimientoSistema_ID AND Conciliacion_ID = @Conciliacion_ID;
        
        -- Marcar MovCuentas como confirmado
        UPDATE MovCuentas SET Confirmada = 1 
        WHERE id = (SELECT MovCuentas_ID FROM ConciliacionDetalle WHERE ID = @MovimientoSistema_ID);
        
        -- Si hay extracto, marcarlo como conciliado
        IF @Extracto_ID IS NOT NULL
        BEGIN
            UPDATE ExtractoBancario SET 
                Conciliado = 1,
                Fecha_Conciliacion = GETDATE(),
                MovCuentas_ID = (SELECT MovCuentas_ID FROM ConciliacionDetalle WHERE ID = @MovimientoSistema_ID)
            WHERE ID = @Extracto_ID;
        END
        
        -- Recalcular diferencia
        DECLARE @Sistema_Debito DECIMAL(18,2), @Sistema_Credito DECIMAL(18,2);
        DECLARE @Banco_Debito DECIMAL(18,2), @Banco_Credito DECIMAL(18,2);
        
        SELECT @Sistema_Debito = SUM(Debito), @Sistema_Credito = SUM(Credito)
        FROM ConciliacionDetalle 
        WHERE Conciliacion_ID = @Conciliacion_ID AND Tipo_Origen = 'SISTEMA' AND Conciliado = 1;
        
        SELECT @Banco_Debito = SUM(CASE WHEN Tipo = 'DEBITO' THEN Monto ELSE 0 END),
               @Banco_Credito = SUM(CASE WHEN Tipo = 'CREDITO' THEN Monto ELSE 0 END)
        FROM ExtractoBancario e
        INNER JOIN ConciliacionDetalle d ON e.ID = d.Extracto_ID
        WHERE d.Conciliacion_ID = @Conciliacion_ID AND d.Conciliado = 1;
        
        -- Actualizar conciliacion
        UPDATE ConciliacionBancaria SET 
            Diferencia = (ISNULL(@Sistema_Credito, 0) - ISNULL(@Sistema_Debito, 0)) - 
                         (ISNULL(@Banco_Credito, 0) - ISNULL(@Banco_Debito, 0))
        WHERE ID = @Conciliacion_ID;
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, 'Movimiento conciliado' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 8. SP: Generar ajuste bancario (Nota Credito/Debito)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GenerarAjusteBancario')
    DROP PROCEDURE sp_GenerarAjusteBancario
GO

CREATE PROCEDURE sp_GenerarAjusteBancario
    @Conciliacion_ID INT,
    @Tipo_Ajuste NVARCHAR(20),       -- NOTA_CREDITO, NOTA_DEBITO
    @Monto DECIMAL(18,2),
    @Descripcion NVARCHAR(255),
    @Co_Usuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @Nro_Cta NVARCHAR(20);
    DECLARE @Tipo_Mov NVARCHAR(10);
    DECLARE @Debito DECIMAL(18,2) = 0;
    DECLARE @Credito DECIMAL(18,2) = 0;
    
    SELECT @Nro_Cta = Nro_Cta FROM ConciliacionBancaria WHERE ID = @Conciliacion_ID;
    
    IF @Nro_Cta IS NULL
    BEGIN
        RAISERROR('conciliacion_no_existe', 16, 1);
        RETURN;
    END
    
    -- Determinar tipo
    IF @Tipo_Ajuste = 'NOTA_CREDITO' 
    BEGIN
        SET @Tipo_Mov = 'NCR';
        SET @Credito = @Monto;
    END
    ELSE IF @Tipo_Ajuste = 'NOTA_DEBITO'
    BEGIN
        SET @Tipo_Mov = 'NDB';
        SET @Debito = @Monto;
    END
    ELSE
    BEGIN
        RAISERROR('tipo_ajuste_invalido', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Generar movimiento bancario
        EXEC sp_GenerarMovimientoBancario 
            @Nro_Cta = @Nro_Cta,
            @Tipo = @Tipo_Mov,
            @Nro_Ref = 'AJUSTE-' + CAST(@Conciliacion_ID AS NVARCHAR),
            @Beneficiario = 'AJUSTE CONCILIACION',
            @Monto = @Monto,
            @Concepto = @Descripcion,
            @Co_Usuario = @Co_Usuario;
        
        -- Insertar en detalle de conciliacion como ajuste
        INSERT INTO ConciliacionDetalle (Conciliacion_ID, Tipo_Origen, Fecha, Descripcion, 
                                          Referencia, Debito, Credito, Conciliado, Tipo_Ajuste, Co_Usuario)
        VALUES (@Conciliacion_ID, 'AJUSTE', GETDATE(), @Descripcion, 
                'AJUSTE-' + CAST(@Conciliacion_ID AS NVARCHAR), @Debito, @Credito, 1, @Tipo_Ajuste, @Co_Usuario);
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, 'Ajuste generado' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 9. SP: Cerrar conciliacion
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CerrarConciliacion')
    DROP PROCEDURE sp_CerrarConciliacion
GO

CREATE PROCEDURE sp_CerrarConciliacion
    @Conciliacion_ID INT,
    @Saldo_Final_Banco DECIMAL(18,2),
    @Observaciones NVARCHAR(500) = NULL,
    @Co_Usuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Saldo_Final_Sistema DECIMAL(18,2);
    DECLARE @Diferencia DECIMAL(18,2);
    
    SELECT @Saldo_Final_Sistema = Saldo_Final_Sistema 
    FROM ConciliacionBancaria WHERE ID = @Conciliacion_ID;
    
    SET @Diferencia = @Saldo_Final_Sistema - @Saldo_Final_Banco;
    
    UPDATE ConciliacionBancaria SET 
        Saldo_Final_Banco = @Saldo_Final_Banco,
        Diferencia = @Diferencia,
        Observaciones = @Observaciones,
        Estado = CASE WHEN ABS(@Diferencia) < 0.01 THEN 'CONCILIADO' ELSE 'DIFERENCIA' END,
        Fecha_Cierre = GETDATE(),
        Co_Usuario = @Co_Usuario
    WHERE ID = @Conciliacion_ID;
    
    SELECT CAST(1 AS BIT) AS ok, 
           @Diferencia AS diferencia,
           CASE WHEN ABS(@Diferencia) < 0.01 THEN 'CONCILIADO' ELSE 'DIFERENCIA' END AS estado;
END
GO

-- =============================================
-- 10. SP: Listar conciliaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Conciliacion_List')
    DROP PROCEDURE sp_Conciliacion_List
GO

CREATE PROCEDURE sp_Conciliacion_List
    @Nro_Cta NVARCHAR(20) = NULL,
    @Estado NVARCHAR(20) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM ConciliacionBancaria
    WHERE (@Nro_Cta IS NULL OR Nro_Cta = @Nro_Cta)
      AND (@Estado IS NULL OR Estado = @Estado);
    
    SELECT c.*, 
           b.Banco,
           (SELECT COUNT(1) FROM ConciliacionDetalle d WHERE d.Conciliacion_ID = c.ID AND d.Conciliado = 0) AS Pendientes,
           (SELECT COUNT(1) FROM ConciliacionDetalle d WHERE d.Conciliacion_ID = c.ID AND d.Conciliado = 1) AS Conciliados
    FROM ConciliacionBancaria c
    LEFT JOIN CuentasBank b ON b.Nro_Cta = c.Nro_Cta
    WHERE (@Nro_Cta IS NULL OR c.Nro_Cta = @Nro_Cta)
      AND (@Estado IS NULL OR c.Estado = @Estado)
    ORDER BY c.Fecha_Creacion DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 11. SP: Obtener detalle de conciliacion
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Conciliacion_Get')
    DROP PROCEDURE sp_Conciliacion_Get
GO

CREATE PROCEDURE sp_Conciliacion_Get
    @Conciliacion_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT c.*, b.Banco, b.Descripcion
    FROM ConciliacionBancaria c
    LEFT JOIN CuentasBank b ON b.Nro_Cta = c.Nro_Cta
    WHERE c.ID = @Conciliacion_ID;
    
    -- Detalle sistema
    SELECT d.*, m.Nro_Ref, m.Fecha as MovFecha
    FROM ConciliacionDetalle d
    LEFT JOIN MovCuentas m ON m.id = d.MovCuentas_ID
    WHERE d.Conciliacion_ID = @Conciliacion_ID AND d.Tipo_Origen = 'SISTEMA'
    ORDER BY d.Fecha;
    
    -- Extracto no conciliado
    SELECT * FROM ExtractoBancario 
    WHERE Nro_Cta = (SELECT Nro_Cta FROM ConciliacionBancaria WHERE ID = @Conciliacion_ID)
      AND Conciliado = 0
      AND Fecha BETWEEN (SELECT Fecha_Desde FROM ConciliacionBancaria WHERE ID = @Conciliacion_ID)
                    AND (SELECT Fecha_Hasta FROM ConciliacionBancaria WHERE ID = @Conciliacion_ID)
    ORDER BY Fecha;
END
GO

SELECT 'Sistema de conciliacion bancaria creado exitosamente' AS mensaje;
