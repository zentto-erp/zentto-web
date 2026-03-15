/*  ═══════════════════════════════════════════════════════════════
    sp_nomina_batch.sql — Stored Procedures para Nómina en Lote
    Tablas: hr.PayrollBatch, hr.PayrollBatchLine, hr.PayrollConcept,
            hr.PayrollRun, hr.PayrollRunLine, master.Employee
    Requiere: sp_nomina_sistema.sql, sp_nomina_calculo.sql
    ═══════════════════════════════════════════════════════════════ */

USE [DatqBoxWeb];
GO
SET NOCOUNT ON;
GO

-- ───────────────────────────────────────────────────────
-- 0. Tablas de soporte: hr.PayrollBatch, hr.PayrollBatchLine
-- ───────────────────────────────────────────────────────

IF SCHEMA_ID('hr') IS NULL EXEC('CREATE SCHEMA hr AUTHORIZATION dbo');
GO

IF OBJECT_ID('hr.PayrollBatch', 'U') IS NULL
BEGIN
    CREATE TABLE hr.PayrollBatch (
        BatchId         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId       INT NOT NULL,
        BranchId        INT NOT NULL,
        PayrollCode     NVARCHAR(15) NOT NULL,
        FromDate        DATE NOT NULL,
        ToDate          DATE NOT NULL,
        Status          NVARCHAR(20) NOT NULL CONSTRAINT DF_hr_PayrollBatch_Status DEFAULT(N'BORRADOR'),
        TotalEmployees  INT NOT NULL CONSTRAINT DF_hr_PayrollBatch_TotalEmp DEFAULT(0),
        TotalGross      DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollBatch_Gross DEFAULT(0),
        TotalDeductions DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollBatch_Deductions DEFAULT(0),
        TotalNet        DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollBatch_Net DEFAULT(0),
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollBatch_CreatedAt DEFAULT(SYSUTCDATETIME()),
        ApprovedBy      INT NULL,
        ApprovedAt      DATETIME2(0) NULL,
        UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollBatch_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT CK_hr_PayrollBatch_Status CHECK (Status IN (N'BORRADOR', N'EN_REVISION', N'APROBADA', N'PROCESADA', N'CERRADA'))
    );

    CREATE NONCLUSTERED INDEX IX_hr_PayrollBatch_Company
        ON hr.PayrollBatch (CompanyId, PayrollCode, Status)
        INCLUDE (FromDate, ToDate);
END;
GO

IF OBJECT_ID('hr.PayrollBatchLine', 'U') IS NULL
BEGIN
    CREATE TABLE hr.PayrollBatchLine (
        LineId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        BatchId         INT NOT NULL,
        EmployeeId      BIGINT NULL,
        EmployeeCode    NVARCHAR(24) NOT NULL,
        EmployeeName    NVARCHAR(200) NOT NULL,
        ConceptCode     NVARCHAR(20) NOT NULL,
        ConceptName     NVARCHAR(120) NOT NULL,
        ConceptType     NVARCHAR(15) NOT NULL CONSTRAINT DF_hr_PayrollBatchLine_Type DEFAULT(N'ASIGNACION'),
        Quantity        DECIMAL(18,4) NOT NULL CONSTRAINT DF_hr_PayrollBatchLine_Qty DEFAULT(1),
        Amount          DECIMAL(18,4) NOT NULL CONSTRAINT DF_hr_PayrollBatchLine_Amount DEFAULT(0),
        Total           DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollBatchLine_Total DEFAULT(0),
        IsModified      BIT NOT NULL CONSTRAINT DF_hr_PayrollBatchLine_IsMod DEFAULT(0),
        Notes           NVARCHAR(500) NULL,
        UpdatedAt       DATETIME2(0) NULL,
        CONSTRAINT FK_hr_PayrollBatchLine_Batch FOREIGN KEY (BatchId) REFERENCES hr.PayrollBatch(BatchId) ON DELETE CASCADE,
        CONSTRAINT CK_hr_PayrollBatchLine_Type CHECK (ConceptType IN (N'ASIGNACION', N'DEDUCCION', N'BONO'))
    );

    CREATE NONCLUSTERED INDEX IX_hr_PayrollBatchLine_Batch
        ON hr.PayrollBatchLine (BatchId, EmployeeCode, ConceptType)
        INCLUDE (ConceptCode, Total);

    CREATE NONCLUSTERED INDEX IX_hr_PayrollBatchLine_Employee
        ON hr.PayrollBatchLine (BatchId, EmployeeCode)
        INCLUDE (ConceptType, Total, IsModified);
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 1. usp_HR_Payroll_GenerateDraft
--    Genera un borrador de nómina en lote para todos los empleados activos.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GenerateDraft
    @CompanyId          INT,
    @BranchId           INT,
    @PayrollCode        NVARCHAR(15),
    @FromDate           DATE,
    @ToDate             DATE,
    @DepartmentFilter   NVARCHAR(100) = NULL,
    @UserId             INT,
    @BatchId            INT           OUTPUT,
    @Resultado          INT           OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';
    SET @BatchId   = 0;

    -- Validaciones básicas
    IF @FromDate >= @ToDate
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'La fecha desde debe ser menor que la fecha hasta.';
        RETURN;
    END;

    -- Verificar que no exista un batch BORRADOR duplicado para el mismo período
    IF EXISTS (
        SELECT 1 FROM hr.PayrollBatch
        WHERE CompanyId   = @CompanyId
          AND BranchId    = @BranchId
          AND PayrollCode = @PayrollCode
          AND FromDate    = @FromDate
          AND ToDate      = @ToDate
          AND Status      = N'BORRADOR'
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje   = N'Ya existe un borrador de nómina para este período y tipo.';
        RETURN;
    END;

    DECLARE @EmpCount INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Crear el batch
        INSERT INTO hr.PayrollBatch (
            CompanyId, BranchId, PayrollCode, FromDate, ToDate,
            Status, CreatedBy
        )
        VALUES (
            @CompanyId, @BranchId, @PayrollCode, @FromDate, @ToDate,
            N'BORRADOR', @UserId
        );

        SET @BatchId = SCOPE_IDENTITY();

        -- Insertar líneas por cada empleado activo + cada concepto activo de la nómina
        INSERT INTO hr.PayrollBatchLine (
            BatchId, EmployeeId, EmployeeCode, EmployeeName,
            ConceptCode, ConceptName, ConceptType,
            Quantity, Amount, Total
        )
        SELECT
            @BatchId,
            e.EmployeeId,
            e.EmployeeCode,
            ISNULL(e.FirstName + N' ', N'') + ISNULL(e.LastName, N''),
            pc.ConceptCode,
            pc.ConceptName,
            pc.ConceptType,
            1,                                             -- Cantidad default
            ISNULL(pc.DefaultValue, 0),                    -- Monto por defecto del concepto
            ISNULL(pc.DefaultValue, 0)                     -- Total = Qty(1) * Amount
        FROM [master].Employee e
        CROSS JOIN hr.PayrollConcept pc
        WHERE e.CompanyId   = @CompanyId
          AND e.IsActive    = 1
          AND pc.CompanyId  = @CompanyId
          AND pc.PayrollCode = @PayrollCode
          AND pc.IsActive   = 1
          AND (@DepartmentFilter IS NULL OR e.DepartmentCode = @DepartmentFilter);

        SET @EmpCount = (
            SELECT COUNT(DISTINCT EmployeeCode)
            FROM hr.PayrollBatchLine
            WHERE BatchId = @BatchId
        );

        -- Actualizar totales del batch
        UPDATE hr.PayrollBatch
        SET TotalEmployees = @EmpCount,
            TotalGross     = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0),
            TotalDeductions= ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            TotalNet       = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0)
                           - ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Borrador generado exitosamente con ' + CAST(@EmpCount AS NVARCHAR(10)) + N' empleados.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 2. usp_HR_Payroll_SaveDraftLine
--    Guarda cambios de una celda (autosave).
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_SaveDraftLine
    @LineId       INT,
    @Quantity     DECIMAL(18,4),
    @Amount       DECIMAL(18,4),
    @Notes        NVARCHAR(500) = NULL,
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Validar que la línea existe y pertenece a un batch en BORRADOR
    DECLARE @BatchId INT;
    SELECT @BatchId = bl.BatchId
    FROM hr.PayrollBatchLine bl
    INNER JOIN hr.PayrollBatch b ON b.BatchId = bl.BatchId
    WHERE bl.LineId = @LineId
      AND b.Status = N'BORRADOR';

    IF @BatchId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE hr.PayrollBatchLine
        SET Quantity   = @Quantity,
            Amount     = @Amount,
            Total      = @Quantity * @Amount,
            IsModified = 1,
            Notes      = @Notes,
            UpdatedAt  = SYSUTCDATETIME()
        WHERE LineId = @LineId;

        -- Recalcular totales del batch
        UPDATE hr.PayrollBatch
        SET TotalGross     = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0),
            TotalDeductions= ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            TotalNet       = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0)
                           - ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Línea actualizada correctamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 3. usp_HR_Payroll_BatchAddLine
--    Agrega un nuevo concepto a un empleado en el lote.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_BatchAddLine
    @BatchId      INT,
    @EmployeeCode NVARCHAR(24),
    @ConceptCode  NVARCHAR(20),
    @ConceptName  NVARCHAR(120),
    @ConceptType  NVARCHAR(15),
    @Quantity     DECIMAL(18,4),
    @Amount       DECIMAL(18,4),
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatch WHERE BatchId = @BatchId AND Status = N'BORRADOR')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END;

    -- Obtener nombre del empleado
    DECLARE @EmployeeName NVARCHAR(200);
    DECLARE @EmployeeId   BIGINT;

    SELECT TOP 1
        @EmployeeName = ISNULL(e.FirstName + N' ', N'') + ISNULL(e.LastName, N''),
        @EmployeeId   = e.EmployeeId
    FROM [master].Employee e
    WHERE e.EmployeeCode = @EmployeeCode
      AND e.IsActive = 1;

    IF @EmployeeName IS NULL
    BEGIN
        -- Intentar obtener de líneas existentes del batch
        SELECT TOP 1
            @EmployeeName = bl.EmployeeName,
            @EmployeeId   = bl.EmployeeId
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId AND bl.EmployeeCode = @EmployeeCode;
    END;

    IF @EmployeeName IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje   = N'Empleado no encontrado.';
        RETURN;
    END;

    -- Verificar que no exista ya ese concepto para el empleado en este lote
    IF EXISTS (
        SELECT 1 FROM hr.PayrollBatchLine
        WHERE BatchId = @BatchId
          AND EmployeeCode = @EmployeeCode
          AND ConceptCode  = @ConceptCode
    )
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje   = N'El concepto ya existe para este empleado en el lote.';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO hr.PayrollBatchLine (
            BatchId, EmployeeId, EmployeeCode, EmployeeName,
            ConceptCode, ConceptName, ConceptType,
            Quantity, Amount, Total, IsModified, UpdatedAt
        )
        VALUES (
            @BatchId, @EmployeeId, @EmployeeCode, @EmployeeName,
            @ConceptCode, @ConceptName, @ConceptType,
            @Quantity, @Amount, @Quantity * @Amount, 1, SYSUTCDATETIME()
        );

        -- Recalcular totales del batch
        UPDATE hr.PayrollBatch
        SET TotalEmployees = (SELECT COUNT(DISTINCT EmployeeCode) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId),
            TotalGross     = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0),
            TotalDeductions= ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            TotalNet       = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0)
                           - ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Línea agregada correctamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 4. usp_HR_Payroll_BatchRemoveLine
--    Elimina una línea de concepto del lote.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_BatchRemoveLine
    @LineId       INT,
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @BatchId INT;

    SELECT @BatchId = bl.BatchId
    FROM hr.PayrollBatchLine bl
    INNER JOIN hr.PayrollBatch b ON b.BatchId = bl.BatchId
    WHERE bl.LineId = @LineId
      AND b.Status = N'BORRADOR';

    IF @BatchId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM hr.PayrollBatchLine WHERE LineId = @LineId;

        -- Recalcular totales del batch
        UPDATE hr.PayrollBatch
        SET TotalEmployees = (SELECT COUNT(DISTINCT EmployeeCode) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId),
            TotalGross     = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0),
            TotalDeductions= ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            TotalNet       = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0)
                           - ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Línea eliminada correctamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 5. usp_HR_Payroll_GetDraftSummary
--    Retorna resumen del lote para la vista de pre-nómina.
--    RS1: Cabecera con totales
--    RS2: Resumen por departamento
--    RS3: Alertas
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetDraftSummary
    @BatchId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- RS1: Cabecera del batch con totales
    SELECT
        b.BatchId,
        b.CompanyId,
        b.BranchId,
        b.PayrollCode,
        b.FromDate,
        b.ToDate,
        b.Status,
        b.TotalEmployees,
        b.TotalGross,
        b.TotalDeductions,
        b.TotalNet,
        b.CreatedBy,
        b.CreatedAt,
        b.ApprovedBy,
        b.ApprovedAt,
        -- Comparación con período anterior
        prev.PrevBatchId,
        prev.PrevTotalGross,
        prev.PrevTotalDeductions,
        prev.PrevTotalNet,
        CASE WHEN prev.PrevTotalNet > 0
             THEN CAST(((b.TotalNet - prev.PrevTotalNet) / prev.PrevTotalNet) * 100 AS DECIMAL(8,2))
             ELSE 0
        END AS NetChangePercent
    FROM hr.PayrollBatch b
    OUTER APPLY (
        SELECT TOP 1
            pb.BatchId   AS PrevBatchId,
            pb.TotalGross      AS PrevTotalGross,
            pb.TotalDeductions AS PrevTotalDeductions,
            pb.TotalNet        AS PrevTotalNet
        FROM hr.PayrollBatch pb
        WHERE pb.CompanyId   = b.CompanyId
          AND pb.BranchId    = b.BranchId
          AND pb.PayrollCode = b.PayrollCode
          AND pb.ToDate      < b.FromDate
          AND pb.Status      IN (N'PROCESADA', N'CERRADA')
        ORDER BY pb.ToDate DESC
    ) prev
    WHERE b.BatchId = @BatchId;

    -- RS2: Resumen por departamento
    SELECT
        ISNULL(e.DepartmentCode, N'SIN_DEPTO') AS DepartmentCode,
        ISNULL(e.DepartmentName, N'Sin Departamento') AS DepartmentName,
        COUNT(DISTINCT bl.EmployeeCode) AS EmployeeCount,
        ISNULL(SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END), 0) AS DeptGross,
        ISNULL(SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END), 0) AS DeptDeductions,
        ISNULL(SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END), 0)
        - ISNULL(SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END), 0) AS DeptNet
    FROM hr.PayrollBatchLine bl
    LEFT JOIN [master].Employee e ON e.EmployeeCode = bl.EmployeeCode AND e.IsActive = 1
    WHERE bl.BatchId = @BatchId
    GROUP BY ISNULL(e.DepartmentCode, N'SIN_DEPTO'),
             ISNULL(e.DepartmentName, N'Sin Departamento')
    ORDER BY DeptNet DESC;

    -- RS3: Alertas
    SELECT
        AlertType,
        EmployeeCode,
        EmployeeName,
        AlertMessage
    FROM (
        -- Empleados sin asignaciones
        SELECT
            N'SIN_ASIGNACIONES' AS AlertType,
            bl.EmployeeCode,
            bl.EmployeeName,
            N'El empleado no tiene conceptos de asignación.' AS AlertMessage
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId
        GROUP BY bl.EmployeeCode, bl.EmployeeName
        HAVING SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN 1 ELSE 0 END) = 0

        UNION ALL

        -- Empleados con neto negativo
        SELECT
            N'NETO_NEGATIVO' AS AlertType,
            bl.EmployeeCode,
            bl.EmployeeName,
            N'El neto del empleado es negativo: ' +
            CAST(
                SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END)
              - SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END)
            AS NVARCHAR(20)) AS AlertMessage
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId
        GROUP BY bl.EmployeeCode, bl.EmployeeName
        HAVING (SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END)
              - SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END)) < 0

        UNION ALL

        -- Líneas con monto cero
        SELECT
            N'MONTO_CERO' AS AlertType,
            bl.EmployeeCode,
            bl.EmployeeName,
            N'Concepto ' + bl.ConceptCode + N' tiene monto cero.' AS AlertMessage
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId
          AND bl.Total = 0
          AND bl.ConceptType IN (N'ASIGNACION', N'BONO')

        UNION ALL

        -- Empleados sin datos de cuenta bancaria (si la columna existe)
        SELECT
            N'SIN_CUENTA_BANCARIA' AS AlertType,
            bl.EmployeeCode,
            bl.EmployeeName,
            N'El empleado no tiene cuenta bancaria registrada.' AS AlertMessage
        FROM (
            SELECT DISTINCT EmployeeCode, EmployeeName
            FROM hr.PayrollBatchLine
            WHERE BatchId = @BatchId
        ) bl
        INNER JOIN [master].Employee e ON e.EmployeeCode = bl.EmployeeCode AND e.IsActive = 1
        WHERE (e.BankAccountNumber IS NULL OR LEN(LTRIM(RTRIM(e.BankAccountNumber))) = 0)
    ) alerts
    ORDER BY AlertType, EmployeeCode;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 6. usp_HR_Payroll_GetDraftGrid
--    Retorna los empleados con sus totales para la grilla.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetDraftGrid
    @BatchId      INT,
    @Search       NVARCHAR(100) = NULL,
    @Department   NVARCHAR(100) = NULL,
    @OnlyModified BIT           = 0,
    @Offset       INT           = 0,
    @Limit        INT           = 50,
    @TotalCount   INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE con empleados filtrados
    ;WITH EmployeeSummary AS (
        SELECT
            bl.EmployeeCode,
            bl.EmployeeName,
            bl.EmployeeId,
            SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END) AS TotalGross,
            SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END) AS TotalDeductions,
            SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END)
            - SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END) AS TotalNet,
            MAX(CAST(bl.IsModified AS INT)) AS HasModified,
            COUNT(*) AS ConceptCount
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId
        GROUP BY bl.EmployeeCode, bl.EmployeeName, bl.EmployeeId
    )
    SELECT @TotalCount = COUNT(*)
    FROM EmployeeSummary es
    LEFT JOIN [master].Employee e ON e.EmployeeCode = es.EmployeeCode AND e.IsActive = 1
    WHERE (@Search IS NULL
           OR es.EmployeeCode LIKE N'%' + @Search + N'%'
           OR es.EmployeeName LIKE N'%' + @Search + N'%')
      AND (@Department IS NULL OR e.DepartmentCode = @Department)
      AND (@OnlyModified = 0 OR es.HasModified = 1);

    ;WITH EmployeeSummary AS (
        SELECT
            bl.EmployeeCode,
            bl.EmployeeName,
            bl.EmployeeId,
            SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END) AS TotalGross,
            SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END) AS TotalDeductions,
            SUM(CASE WHEN bl.ConceptType IN (N'ASIGNACION', N'BONO') THEN bl.Total ELSE 0 END)
            - SUM(CASE WHEN bl.ConceptType = N'DEDUCCION' THEN bl.Total ELSE 0 END) AS TotalNet,
            MAX(CAST(bl.IsModified AS INT)) AS HasModified,
            COUNT(*) AS ConceptCount
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId = @BatchId
        GROUP BY bl.EmployeeCode, bl.EmployeeName, bl.EmployeeId
    )
    SELECT
        es.EmployeeCode,
        es.EmployeeName,
        es.EmployeeId,
        ISNULL(e.DepartmentCode, N'') AS DepartmentCode,
        ISNULL(e.DepartmentName, N'') AS DepartmentName,
        ISNULL(e.PositionName, N'')   AS PositionName,
        es.TotalGross,
        es.TotalDeductions,
        es.TotalNet,
        es.HasModified,
        es.ConceptCount
    FROM EmployeeSummary es
    LEFT JOIN [master].Employee e ON e.EmployeeCode = es.EmployeeCode AND e.IsActive = 1
    WHERE (@Search IS NULL
           OR es.EmployeeCode LIKE N'%' + @Search + N'%'
           OR es.EmployeeName LIKE N'%' + @Search + N'%')
      AND (@Department IS NULL OR e.DepartmentCode = @Department)
      AND (@OnlyModified = 0 OR es.HasModified = 1)
    ORDER BY es.EmployeeName
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 7. usp_HR_Payroll_GetEmployeeLines
--    Retorna todas las líneas de concepto de un empleado en un lote.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetEmployeeLines
    @BatchId      INT,
    @EmployeeCode NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bl.LineId,
        bl.BatchId,
        bl.EmployeeId,
        bl.EmployeeCode,
        bl.EmployeeName,
        bl.ConceptCode,
        bl.ConceptName,
        bl.ConceptType,
        bl.Quantity,
        bl.Amount,
        bl.Total,
        bl.IsModified,
        bl.Notes,
        bl.UpdatedAt
    FROM hr.PayrollBatchLine bl
    WHERE bl.BatchId = @BatchId
      AND bl.EmployeeCode = @EmployeeCode
    ORDER BY
        CASE bl.ConceptType
            WHEN N'ASIGNACION' THEN 1
            WHEN N'BONO'       THEN 2
            WHEN N'DEDUCCION'  THEN 3
        END,
        bl.ConceptCode;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 8. usp_HR_Payroll_ApproveDraft
--    Aprueba un borrador de nómina.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ApproveDraft
    @BatchId    INT,
    @ApprovedBy INT,
    @UserId     INT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @CurrentStatus NVARCHAR(20);

    SELECT @CurrentStatus = Status
    FROM hr.PayrollBatch
    WHERE BatchId = @BatchId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'Lote no encontrado.';
        RETURN;
    END;

    IF @CurrentStatus NOT IN (N'BORRADOR', N'EN_REVISION')
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje   = N'Solo se pueden aprobar lotes en estado BORRADOR o EN_REVISION. Estado actual: ' + @CurrentStatus;
        RETURN;
    END;

    -- Verificar que el lote tiene líneas
    IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = @BatchId)
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje   = N'No se puede aprobar un lote sin líneas.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE hr.PayrollBatch
        SET Status     = N'APROBADA',
            ApprovedBy = @ApprovedBy,
            ApprovedAt = SYSUTCDATETIME(),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Lote aprobado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 9. usp_HR_Payroll_ProcessBatch
--    Procesa un lote aprobado: crea PayrollRun individuales.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ProcessBatch
    @BatchId    INT,
    @UserId     INT,
    @Procesados INT           OUTPUT,
    @Errores    INT           OUTPUT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Procesados = 0;
    SET @Errores    = 0;
    SET @Resultado  = 0;
    SET @Mensaje    = N'';

    -- Validar estado
    DECLARE @CompanyId    INT;
    DECLARE @BranchId     INT;
    DECLARE @PayrollCode  NVARCHAR(15);
    DECLARE @FromDate     DATE;
    DECLARE @ToDate       DATE;
    DECLARE @Status       NVARCHAR(20);

    SELECT
        @CompanyId   = CompanyId,
        @BranchId    = BranchId,
        @PayrollCode = PayrollCode,
        @FromDate    = FromDate,
        @ToDate      = ToDate,
        @Status      = Status
    FROM hr.PayrollBatch
    WHERE BatchId = @BatchId;

    IF @Status IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'Lote no encontrado.';
        RETURN;
    END;

    IF @Status <> N'APROBADA'
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje   = N'Solo se pueden procesar lotes en estado APROBADA. Estado actual: ' + @Status;
        RETURN;
    END;

    -- Cursor de empleados en el lote
    DECLARE @EmpCode   NVARCHAR(24);
    DECLARE @EmpName   NVARCHAR(200);
    DECLARE @EmpId     BIGINT;
    DECLARE @EmpGross  DECIMAL(18,2);
    DECLARE @EmpDeduct DECIMAL(18,2);
    DECLARE @EmpNet    DECIMAL(18,2);
    DECLARE @RunRes    INT;
    DECLARE @RunMsg    NVARCHAR(500);
    DECLARE @LinesJson NVARCHAR(MAX);

    DECLARE emp_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            EmployeeCode,
            MAX(EmployeeName),
            MAX(EmployeeId),
            ISNULL(SUM(CASE WHEN ConceptType IN (N'ASIGNACION', N'BONO') THEN Total ELSE 0 END), 0),
            ISNULL(SUM(CASE WHEN ConceptType = N'DEDUCCION' THEN Total ELSE 0 END), 0),
            ISNULL(SUM(CASE WHEN ConceptType IN (N'ASIGNACION', N'BONO') THEN Total ELSE 0 END), 0)
            - ISNULL(SUM(CASE WHEN ConceptType = N'DEDUCCION' THEN Total ELSE 0 END), 0)
        FROM hr.PayrollBatchLine
        WHERE BatchId = @BatchId
        GROUP BY EmployeeCode;

    BEGIN TRY
        BEGIN TRANSACTION;

        OPEN emp_cur;
        FETCH NEXT FROM emp_cur INTO @EmpCode, @EmpName, @EmpId, @EmpGross, @EmpDeduct, @EmpNet;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Construir JSON de líneas para este empleado
            SET @LinesJson = (
                SELECT
                    ConceptCode  AS [code],
                    ConceptName  AS [name],
                    ConceptType  AS [type],
                    Quantity     AS [qty],
                    Amount       AS [amount],
                    Total        AS [total],
                    Notes        AS [description]
                FROM hr.PayrollBatchLine
                WHERE BatchId = @BatchId
                  AND EmployeeCode = @EmpCode
                FOR JSON PATH
            );

            BEGIN TRY
                EXEC dbo.usp_HR_Payroll_UpsertRun
                    @CompanyId        = @CompanyId,
                    @BranchId         = @BranchId,
                    @PayrollCode      = @PayrollCode,
                    @EmployeeId       = @EmpId,
                    @EmployeeCode     = @EmpCode,
                    @EmployeeName     = @EmpName,
                    @FromDate         = @FromDate,
                    @ToDate           = @ToDate,
                    @TotalAssignments = @EmpGross,
                    @TotalDeductions  = @EmpDeduct,
                    @NetTotal         = @EmpNet,
                    @PayrollTypeName  = NULL,
                    @UserId           = @UserId,
                    @LinesJson        = @LinesJson,
                    @Resultado        = @RunRes OUTPUT,
                    @Mensaje          = @RunMsg OUTPUT;

                IF @RunRes > 0
                    SET @Procesados = @Procesados + 1;
                ELSE
                    SET @Errores = @Errores + 1;
            END TRY
            BEGIN CATCH
                SET @Errores = @Errores + 1;
            END CATCH;

            FETCH NEXT FROM emp_cur INTO @EmpCode, @EmpName, @EmpId, @EmpGross, @EmpDeduct, @EmpNet;
        END;

        CLOSE emp_cur;
        DEALLOCATE emp_cur;

        -- Actualizar estado del batch
        UPDATE hr.PayrollBatch
        SET Status    = N'PROCESADA',
            UpdatedAt = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Lote procesado: ' + CAST(@Procesados AS NVARCHAR(10)) + N' empleados procesados, '
                       + CAST(@Errores AS NVARCHAR(10)) + N' errores.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        IF CURSOR_STATUS('local', 'emp_cur') >= 0
        BEGIN
            CLOSE emp_cur;
            DEALLOCATE emp_cur;
        END;

        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 10. usp_HR_Payroll_ListBatches
--     Lista todos los lotes de nómina con paginación.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListBatches
    @CompanyId    INT,
    @PayrollCode  NVARCHAR(15) = NULL,
    @Status       NVARCHAR(20) = NULL,
    @Offset       INT          = 0,
    @Limit        INT          = 25,
    @TotalCount   INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.PayrollBatch
    WHERE CompanyId = @CompanyId
      AND (@PayrollCode IS NULL OR PayrollCode = @PayrollCode)
      AND (@Status IS NULL OR Status = @Status);

    SELECT
        b.BatchId,
        b.CompanyId,
        b.BranchId,
        b.PayrollCode,
        b.FromDate,
        b.ToDate,
        b.Status,
        b.TotalEmployees,
        b.TotalGross,
        b.TotalDeductions,
        b.TotalNet,
        b.CreatedBy,
        b.CreatedAt,
        b.ApprovedBy,
        b.ApprovedAt,
        b.UpdatedAt
    FROM hr.PayrollBatch b
    WHERE b.CompanyId = @CompanyId
      AND (@PayrollCode IS NULL OR b.PayrollCode = @PayrollCode)
      AND (@Status IS NULL OR b.Status = @Status)
    ORDER BY b.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- 11. usp_HR_Payroll_BatchBulkUpdate
--     Actualización masiva: aplica un concepto a múltiples empleados.
-- ═══════════════════════════════════════════════════════════════
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_BatchBulkUpdate
    @BatchId        INT,
    @ConceptCode    NVARCHAR(20),
    @ConceptType    NVARCHAR(15),
    @Amount         DECIMAL(18,4),
    @EmployeeCodes  XML           = NULL,   -- <codes><code>EMP001</code>...</codes>
    @UserId         INT,
    @AffectedCount  INT           OUTPUT,
    @Resultado      INT           OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @AffectedCount = 0;
    SET @Resultado     = 0;
    SET @Mensaje       = N'';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatch WHERE BatchId = @BatchId AND Status = N'BORRADOR')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = N'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END;

    -- Parsear códigos de empleado si se proporcionan
    DECLARE @FilteredEmployees TABLE (EmployeeCode NVARCHAR(24));

    IF @EmployeeCodes IS NOT NULL
    BEGIN
        INSERT INTO @FilteredEmployees (EmployeeCode)
        SELECT T.c.value('.', 'NVARCHAR(24)')
        FROM @EmployeeCodes.nodes('/codes/code') AS T(c);
    END;

    BEGIN TRY
        -- Actualizar líneas existentes que coincidan
        UPDATE bl
        SET bl.Amount     = @Amount,
            bl.Total      = bl.Quantity * @Amount,
            bl.IsModified = 1,
            bl.UpdatedAt  = SYSUTCDATETIME()
        FROM hr.PayrollBatchLine bl
        WHERE bl.BatchId     = @BatchId
          AND bl.ConceptCode = @ConceptCode
          AND bl.ConceptType = @ConceptType
          AND (@EmployeeCodes IS NULL
               OR bl.EmployeeCode IN (SELECT EmployeeCode FROM @FilteredEmployees));

        SET @AffectedCount = @@ROWCOUNT;

        -- Recalcular totales del batch
        UPDATE hr.PayrollBatch
        SET TotalGross     = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0),
            TotalDeductions= ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            TotalNet       = ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType IN (N'ASIGNACION', N'BONO')), 0)
                           - ISNULL((SELECT SUM(Total) FROM hr.PayrollBatchLine WHERE BatchId = @BatchId AND ConceptType = N'DEDUCCION'), 0),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE BatchId = @BatchId;

        SET @Resultado = 1;
        SET @Mensaje   = CAST(@AffectedCount AS NVARCHAR(10)) + N' líneas actualizadas.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

PRINT N'═══ sp_nomina_batch.sql completado exitosamente ═══';
GO
