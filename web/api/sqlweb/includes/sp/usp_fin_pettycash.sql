-- =============================================
-- Modulo Financiero: Caja Chica (Petty Cash)
-- Tablas y Stored Procedures
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- Asegurar que el schema fin existe
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'fin')
    EXEC('CREATE SCHEMA fin');
GO

-- =============================================
-- 1. TABLA: fin.PettyCashBox - Definiciones de cajas chicas
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PettyCashBox' AND schema_id = SCHEMA_ID('fin'))
BEGIN
    CREATE TABLE fin.PettyCashBox (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL DEFAULT 1,
        BranchId INT NOT NULL DEFAULT 1,
        Name NVARCHAR(100) NOT NULL,
        AccountCode NVARCHAR(20) NULL,          -- Cuenta contable asociada
        MaxAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        CurrentBalance DECIMAL(18,2) NOT NULL DEFAULT 0,
        Responsible NVARCHAR(100) NULL,
        Status NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT NULL
    );
END
GO

-- =============================================
-- 2. TABLA: fin.PettyCashSession - Sesiones apertura/cierre
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PettyCashSession' AND schema_id = SCHEMA_ID('fin'))
BEGIN
    CREATE TABLE fin.PettyCashSession (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        BoxId INT NOT NULL REFERENCES fin.PettyCashBox(Id),
        OpeningAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        ClosingAmount DECIMAL(18,2) NULL,
        TotalExpenses DECIMAL(18,2) NOT NULL DEFAULT 0,
        Status NVARCHAR(20) NOT NULL DEFAULT 'OPEN',  -- OPEN, CLOSED
        OpenedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ClosedAt DATETIME2 NULL,
        OpenedByUserId INT NULL,
        ClosedByUserId INT NULL,
        Notes NVARCHAR(500) NULL
    );
END
GO

-- =============================================
-- 3. TABLA: fin.PettyCashExpense - Gastos individuales
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PettyCashExpense' AND schema_id = SCHEMA_ID('fin'))
BEGIN
    CREATE TABLE fin.PettyCashExpense (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        SessionId INT NOT NULL REFERENCES fin.PettyCashSession(Id),
        BoxId INT NOT NULL REFERENCES fin.PettyCashBox(Id),
        Category NVARCHAR(50) NOT NULL,          -- TRANSPORTE, MATERIAL_OFICINA, LIMPIEZA, ALIMENTACION, MANTENIMIENTO, MENSAJERIA, OTROS
        Description NVARCHAR(255) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Beneficiary NVARCHAR(150) NULL,
        ReceiptNumber NVARCHAR(50) NULL,
        AccountCode NVARCHAR(20) NULL,           -- Cuenta de gasto contable
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT NULL
    );
END
GO

-- =============================================
-- 4. SP: usp_Fin_PettyCash_Box_List
--    Lista todas las cajas chicas de una empresa
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Box_List' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Box_List
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Box_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.Id,
        b.CompanyId,
        b.BranchId,
        b.Name,
        b.AccountCode,
        b.MaxAmount,
        b.CurrentBalance,
        b.Responsible,
        b.Status,
        b.CreatedAt,
        b.CreatedByUserId
    FROM fin.PettyCashBox b
    WHERE b.CompanyId = @CompanyId
    ORDER BY b.Name;
END
GO

-- =============================================
-- 5. SP: usp_Fin_PettyCash_Box_Create
--    Crea una nueva caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Box_Create' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Box_Create
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Box_Create
    @CompanyId INT,
    @BranchId INT,
    @Name NVARCHAR(100),
    @AccountCode NVARCHAR(20) = NULL,
    @MaxAmount DECIMAL(18,2) = 0,
    @Responsible NVARCHAR(100) = NULL,
    @CreatedByUserId INT = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que no exista otra caja con el mismo nombre en la misma empresa/sucursal
    IF EXISTS (
        SELECT 1 FROM fin.PettyCashBox
        WHERE CompanyId = @CompanyId
          AND BranchId = @BranchId
          AND Name = @Name
          AND Status = 'ACTIVE'
    )
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Ya existe una caja chica activa con ese nombre en esta sucursal.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO fin.PettyCashBox (CompanyId, BranchId, Name, AccountCode, MaxAmount, CurrentBalance, Responsible, Status, CreatedAt, CreatedByUserId)
        VALUES (@CompanyId, @BranchId, @Name, @AccountCode, @MaxAmount, 0, @Responsible, 'ACTIVE', SYSUTCDATETIME(), @CreatedByUserId);

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = N'Caja chica creada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 6. SP: usp_Fin_PettyCash_Session_Open
--    Abre una nueva sesion de caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Session_Open' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Session_Open
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Session_Open
    @BoxId INT,
    @OpeningAmount DECIMAL(18,2),
    @OpenedByUserId INT = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validar que la caja existe y esta activa
    IF NOT EXISTS (SELECT 1 FROM fin.PettyCashBox WHERE Id = @BoxId AND Status = 'ACTIVE')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'La caja chica no existe o no esta activa.';
        RETURN;
    END

    -- Validar que no haya otra sesion abierta para esta caja
    IF EXISTS (SELECT 1 FROM fin.PettyCashSession WHERE BoxId = @BoxId AND Status = 'OPEN')
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = N'Ya existe una sesion abierta para esta caja chica. Debe cerrarla primero.';
        RETURN;
    END

    -- Validar que el monto de apertura no exceda el maximo permitido
    DECLARE @MaxAmount DECIMAL(18,2);
    SELECT @MaxAmount = MaxAmount FROM fin.PettyCashBox WHERE Id = @BoxId;

    IF @MaxAmount > 0 AND @OpeningAmount > @MaxAmount
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = N'El monto de apertura excede el monto maximo permitido para esta caja chica (' + CAST(@MaxAmount AS NVARCHAR(20)) + N').';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Crear la sesion
        INSERT INTO fin.PettyCashSession (BoxId, OpeningAmount, ClosingAmount, TotalExpenses, Status, OpenedAt, OpenedByUserId)
        VALUES (@BoxId, @OpeningAmount, NULL, 0, 'OPEN', SYSUTCDATETIME(), @OpenedByUserId);

        SET @Resultado = SCOPE_IDENTITY();

        -- Actualizar el saldo actual de la caja
        UPDATE fin.PettyCashBox
        SET CurrentBalance = @OpeningAmount
        WHERE Id = @BoxId;

        COMMIT TRANSACTION;

        SET @Mensaje = N'Sesion de caja chica abierta exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 7. SP: usp_Fin_PettyCash_Session_Close
--    Cierra una sesion activa de caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Session_Close' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Session_Close
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Session_Close
    @BoxId INT,
    @ClosedByUserId INT = NULL,
    @Notes NVARCHAR(500) = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SessionId INT;
    DECLARE @OpeningAmount DECIMAL(18,2);
    DECLARE @TotalExpenses DECIMAL(18,2);
    DECLARE @ClosingAmount DECIMAL(18,2);

    -- Buscar la sesion abierta para esta caja
    SELECT
        @SessionId = Id,
        @OpeningAmount = OpeningAmount,
        @TotalExpenses = TotalExpenses
    FROM fin.PettyCashSession
    WHERE BoxId = @BoxId AND Status = 'OPEN';

    IF @SessionId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'No existe una sesion abierta para esta caja chica.';
        RETURN;
    END

    -- Calcular monto de cierre
    SET @ClosingAmount = @OpeningAmount - @TotalExpenses;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Cerrar la sesion
        UPDATE fin.PettyCashSession
        SET Status = 'CLOSED',
            ClosingAmount = @ClosingAmount,
            ClosedAt = SYSUTCDATETIME(),
            ClosedByUserId = @ClosedByUserId,
            Notes = @Notes
        WHERE Id = @SessionId;

        -- Actualizar saldo en la caja
        UPDATE fin.PettyCashBox
        SET CurrentBalance = @ClosingAmount
        WHERE Id = @BoxId;

        COMMIT TRANSACTION;

        SET @Resultado = @SessionId;
        SET @Mensaje = N'Sesion cerrada exitosamente. Monto de cierre: ' + CAST(@ClosingAmount AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 8. SP: usp_Fin_PettyCash_Session_GetActive
--    Obtiene la sesion activa de una caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Session_GetActive' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Session_GetActive
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Session_GetActive
    @BoxId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.BoxId,
        s.OpeningAmount,
        s.ClosingAmount,
        s.TotalExpenses,
        s.Status,
        s.OpenedAt,
        s.ClosedAt,
        s.OpenedByUserId,
        s.ClosedByUserId,
        s.Notes,
        (s.OpeningAmount - s.TotalExpenses) AS AvailableBalance,
        (SELECT COUNT(1) FROM fin.PettyCashExpense e WHERE e.SessionId = s.Id) AS ExpenseCount
    FROM fin.PettyCashSession s
    WHERE s.BoxId = @BoxId
      AND s.Status = 'OPEN';
END
GO

-- =============================================
-- 9. SP: usp_Fin_PettyCash_Expense_Add
--    Agrega un gasto a la caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Expense_Add' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Expense_Add
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Expense_Add
    @SessionId INT,
    @BoxId INT,
    @Category NVARCHAR(50),
    @Description NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Beneficiary NVARCHAR(150) = NULL,
    @ReceiptNumber NVARCHAR(50) = NULL,
    @AccountCode NVARCHAR(20) = NULL,
    @CreatedByUserId INT = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validar que la sesion existe y esta abierta
    IF NOT EXISTS (SELECT 1 FROM fin.PettyCashSession WHERE Id = @SessionId AND BoxId = @BoxId AND Status = 'OPEN')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'La sesion no existe, no pertenece a esta caja o ya esta cerrada.';
        RETURN;
    END

    -- Validar monto positivo
    IF @Amount <= 0
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = N'El monto del gasto debe ser mayor a cero.';
        RETURN;
    END

    -- Validar que haya saldo suficiente
    DECLARE @OpeningAmount DECIMAL(18,2);
    DECLARE @TotalExpenses DECIMAL(18,2);

    SELECT @OpeningAmount = OpeningAmount, @TotalExpenses = TotalExpenses
    FROM fin.PettyCashSession
    WHERE Id = @SessionId;

    IF (@TotalExpenses + @Amount) > @OpeningAmount
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = N'El monto del gasto excede el saldo disponible en la sesion. Disponible: ' + CAST((@OpeningAmount - @TotalExpenses) AS NVARCHAR(20));
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insertar el gasto
        INSERT INTO fin.PettyCashExpense (SessionId, BoxId, Category, Description, Amount, Beneficiary, ReceiptNumber, AccountCode, CreatedAt, CreatedByUserId)
        VALUES (@SessionId, @BoxId, @Category, @Description, @Amount, @Beneficiary, @ReceiptNumber, @AccountCode, SYSUTCDATETIME(), @CreatedByUserId);

        SET @Resultado = SCOPE_IDENTITY();

        -- Actualizar total de gastos en la sesion
        UPDATE fin.PettyCashSession
        SET TotalExpenses = TotalExpenses + @Amount
        WHERE Id = @SessionId;

        -- Actualizar saldo actual en la caja (restar gasto)
        UPDATE fin.PettyCashBox
        SET CurrentBalance = CurrentBalance - @Amount
        WHERE Id = @BoxId;

        COMMIT TRANSACTION;

        SET @Mensaje = N'Gasto registrado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 10. SP: usp_Fin_PettyCash_Expense_List
--     Lista gastos de una caja (opcionalmente filtrado por sesion)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Expense_List' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Expense_List
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Expense_List
    @BoxId INT,
    @SessionId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.Id,
        e.SessionId,
        e.BoxId,
        e.Category,
        e.Description,
        e.Amount,
        e.Beneficiary,
        e.ReceiptNumber,
        e.AccountCode,
        e.CreatedAt,
        e.CreatedByUserId
    FROM fin.PettyCashExpense e
    WHERE e.BoxId = @BoxId
      AND (@SessionId IS NULL OR e.SessionId = @SessionId)
    ORDER BY e.CreatedAt DESC;
END
GO

-- =============================================
-- 11. SP: usp_Fin_PettyCash_Summary
--     Resumen dashboard de una caja chica
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Fin_PettyCash_Summary' AND schema_id = SCHEMA_ID('fin'))
    DROP PROCEDURE fin.usp_Fin_PettyCash_Summary
GO

CREATE PROCEDURE fin.usp_Fin_PettyCash_Summary
    @BoxId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultado 1: Informacion de la caja
    SELECT
        b.Id,
        b.CompanyId,
        b.BranchId,
        b.Name,
        b.AccountCode,
        b.MaxAmount,
        b.CurrentBalance,
        b.Responsible,
        b.Status,
        b.CreatedAt
    FROM fin.PettyCashBox b
    WHERE b.Id = @BoxId;

    -- Resultado 2: Sesion activa (si existe)
    SELECT
        s.Id AS SessionId,
        s.OpeningAmount,
        s.TotalExpenses,
        (s.OpeningAmount - s.TotalExpenses) AS AvailableBalance,
        s.OpenedAt,
        s.OpenedByUserId,
        (SELECT COUNT(1) FROM fin.PettyCashExpense e WHERE e.SessionId = s.Id) AS ExpenseCount
    FROM fin.PettyCashSession s
    WHERE s.BoxId = @BoxId
      AND s.Status = 'OPEN';

    -- Resultado 3: Total de gastos por categoria (sesion activa)
    SELECT
        e.Category,
        COUNT(1) AS ExpenseCount,
        SUM(e.Amount) AS TotalAmount
    FROM fin.PettyCashExpense e
    INNER JOIN fin.PettyCashSession s ON s.Id = e.SessionId
    WHERE e.BoxId = @BoxId
      AND s.Status = 'OPEN'
    GROUP BY e.Category
    ORDER BY SUM(e.Amount) DESC;
END
GO

SELECT 'Modulo de Caja Chica (Petty Cash) creado exitosamente' AS mensaje;
