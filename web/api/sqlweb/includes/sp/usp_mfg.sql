/*
 * ============================================================================
 *  Archivo : usp_mfg.sql
 *  Esquema : mfg (Manufacturing / Manufactura)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados para el modulo de Manufactura.
 *    - BOMs (Bills of Materials)
 *    - Work Centers (Centros de trabajo)
 *    - Routing (Rutas de produccion)
 *    - Work Orders (Ordenes de trabajo)
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  usp_Mfg_BOM_List
--  Listado paginado de listas de materiales.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_BOM_List
    @CompanyId  INT,
    @Status     NVARCHAR(20)  = NULL,
    @Search     NVARCHAR(200) = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 50,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   mfg.BillOfMaterials b
    WHERE  b.CompanyId = @CompanyId
      AND  (@Status IS NULL OR b.Status = @Status)
      AND  (@Search IS NULL OR b.BOMCode LIKE '%' + @Search + '%'
                            OR b.BOMName LIKE '%' + @Search + '%');

    SELECT
        b.BOMId, b.BOMCode, b.BOMName,
        b.ProductId, b.OutputQuantity,
        b.Status, b.CreatedAt, b.UpdatedAt,
        (SELECT COUNT(*) FROM mfg.BOMLine bl WHERE bl.BOMId = b.BOMId) AS LineCount
    FROM   mfg.BillOfMaterials b
    WHERE  b.CompanyId = @CompanyId
      AND  (@Status IS NULL OR b.Status = @Status)
      AND  (@Search IS NULL OR b.BOMCode LIKE '%' + @Search + '%'
                            OR b.BOMName LIKE '%' + @Search + '%')
    ORDER BY b.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_Mfg_BOM_Get
--  Detalle de un BOM con sus lineas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_BOM_Get
    @BOMId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT
        b.BOMId, b.BOMCode, b.BOMName, b.CompanyId,
        b.ProductId, b.OutputQuantity,
        b.Status, b.CreatedAt, b.UpdatedAt
    FROM mfg.BillOfMaterials b
    WHERE b.BOMId = @BOMId;

    -- Lines
    SELECT
        bl.BOMLineId, bl.BOMId, bl.ComponentProductId,
        bl.Quantity, bl.UnitOfMeasure, bl.LineNumber,
        bl.WastePercent, bl.IsOptional, bl.Notes
    FROM mfg.BOMLine bl
    WHERE bl.BOMId = @BOMId
    ORDER BY bl.LineNumber;
END;
GO

-- =============================================================================
--  usp_Mfg_BOM_Create
--  Crea un BOM con lineas (JSON).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_BOM_Create
    @CompanyId        INT,
    @ProductId        INT,
    @BOMCode          NVARCHAR(30),
    @BOMName          NVARCHAR(200),
    @OutputQuantity   DECIMAL(18,4) = 1,
    @LinesJson        NVARCHAR(MAX) = NULL,
    @UserId           INT,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT,
    @BOMId            INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @BOMId = 0;

    BEGIN TRY
        -- Verificar duplicado
        IF EXISTS (SELECT 1 FROM mfg.BillOfMaterials WHERE CompanyId = @CompanyId AND BOMCode = @BOMCode)
        BEGIN
            SET @Mensaje = N'Ya existe un BOM con el codigo ' + @BOMCode;
            RETURN;
        END;

        INSERT INTO mfg.BillOfMaterials (
            CompanyId, ProductId, BOMCode, BOMName,
            OutputQuantity, Status,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        ) VALUES (
            @CompanyId, @ProductId, @BOMCode, @BOMName,
            @OutputQuantity, 'DRAFT',
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @BOMId = SCOPE_IDENTITY();

        -- Insertar lineas desde JSON
        IF @LinesJson IS NOT NULL AND LEN(@LinesJson) > 2
        BEGIN
            INSERT INTO mfg.BOMLine (BOMId, LineNumber, ComponentProductId, Quantity, UnitOfMeasure, WastePercent, IsOptional, Notes)
            SELECT
                @BOMId,
                CAST(ISNULL(j.LineNumber, '0') AS INT),
                CAST(j.ComponentProductId AS INT),
                CAST(j.Quantity AS DECIMAL(18,4)),
                j.UnitOfMeasure,
                CAST(ISNULL(j.WastePercent, '0') AS DECIMAL(5,2)),
                CAST(ISNULL(j.IsOptional, '0') AS BIT),
                j.Notes
            FROM OPENJSON(@LinesJson) WITH (
                LineNumber           INT            '$.LineNumber',
                ComponentProductId   INT            '$.ComponentProductId',
                Quantity             NVARCHAR(50)   '$.Quantity',
                UnitOfMeasure        NVARCHAR(20)   '$.UnitOfMeasure',
                WastePercent         NVARCHAR(20)   '$.WastePercent',
                IsOptional           NVARCHAR(10)   '$.IsOptional',
                Notes                NVARCHAR(500)  '$.Notes'
            ) j;
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_BOM_Activate
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_BOM_Activate
    @BOMId     INT,
    @UserId    INT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        UPDATE mfg.BillOfMaterials
        SET    Status          = 'ACTIVE',
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  BOMId = @BOMId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_BOM_Obsolete
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_BOM_Obsolete
    @BOMId     INT,
    @UserId    INT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        UPDATE mfg.BillOfMaterials
        SET    Status          = 'OBSOLETE',
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  BOMId = @BOMId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkCenter_List
--  Listado paginado de centros de trabajo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkCenter_List
    @CompanyId  INT,
    @Search     NVARCHAR(200) = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 50,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   mfg.WorkCenter w
    WHERE  w.CompanyId = @CompanyId
      AND  (@Search IS NULL OR w.WorkCenterCode LIKE '%' + @Search + '%'
                            OR w.WorkCenterName LIKE '%' + @Search + '%');

    SELECT
        w.WorkCenterId, w.WorkCenterCode, w.WorkCenterName,
        w.CostPerHour, w.Capacity, w.IsActive,
        w.CreatedAt, w.UpdatedAt
    FROM   mfg.WorkCenter w
    WHERE  w.CompanyId = @CompanyId
      AND  (@Search IS NULL OR w.WorkCenterCode LIKE '%' + @Search + '%'
                            OR w.WorkCenterName LIKE '%' + @Search + '%')
    ORDER BY w.WorkCenterName
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkCenter_Upsert
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkCenter_Upsert
    @CompanyId      INT,
    @WorkCenterId   INT           = NULL,
    @WorkCenterCode NVARCHAR(30),
    @WorkCenterName NVARCHAR(120),
    @CostPerHour    DECIMAL(18,2) = 0,
    @Capacity       INT           = 1,
    @IsActive       BIT           = 1,
    @UserId         INT,
    @Resultado      INT           OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @WorkCenterId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM mfg.WorkCenter WHERE CompanyId = @CompanyId AND WorkCenterCode = @WorkCenterCode)
            BEGIN
                SET @Mensaje = N'Ya existe un centro de trabajo con el codigo ' + @WorkCenterCode;
                RETURN;
            END;

            INSERT INTO mfg.WorkCenter (CompanyId, WorkCenterCode, WorkCenterName, CostPerHour, Capacity, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@CompanyId, @WorkCenterCode, @WorkCenterName, @CostPerHour, @Capacity, @IsActive, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE mfg.WorkCenter
            SET    WorkCenterCode  = @WorkCenterCode,
                   WorkCenterName  = @WorkCenterName,
                   CostPerHour     = @CostPerHour,
                   Capacity        = @Capacity,
                   IsActive        = @IsActive,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  WorkCenterId = @WorkCenterId AND CompanyId = @CompanyId;
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_Routing_List
--  Lista operaciones de un BOM ordenadas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_Routing_List
    @BOMId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.RoutingId, r.BOMId, r.OperationNumber,
        r.WorkCenterId, wc.WorkCenterName,
        r.OperationName, r.SetupTimeMinutes, r.RunTimeMinutes,
        r.Notes
    FROM   mfg.Routing r
    LEFT JOIN mfg.WorkCenter wc ON wc.WorkCenterId = r.WorkCenterId
    WHERE  r.BOMId = @BOMId
    ORDER BY r.OperationNumber;
END;
GO

-- =============================================================================
--  usp_Mfg_Routing_Upsert
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_Routing_Upsert
    @BOMId           INT,
    @RoutingId       INT           = NULL,
    @OperationNumber INT,
    @WorkCenterId    INT,
    @OperationName   NVARCHAR(200),
    @SetupTimeMinutes DECIMAL(10,2) = 0,
    @RunTimeMinutes   DECIMAL(10,2) = 0,
    @Notes            NVARCHAR(500) = NULL,
    @UserId          INT,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @RoutingId IS NULL
        BEGIN
            INSERT INTO mfg.Routing (BOMId, OperationNumber, WorkCenterId, OperationName, SetupTimeMinutes, RunTimeMinutes, Notes, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@BOMId, @OperationNumber, @WorkCenterId, @OperationName, @SetupTimeMinutes, @RunTimeMinutes, @Notes, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE mfg.Routing
            SET    OperationNumber = @OperationNumber,
                   WorkCenterId    = @WorkCenterId,
                   OperationName    = @OperationName,
                   SetupTimeMinutes = @SetupTimeMinutes,
                   RunTimeMinutes   = @RunTimeMinutes,
                   Notes            = @Notes,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  RoutingId = @RoutingId AND BOMId = @BOMId;
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_List
--  Listado paginado de ordenes de trabajo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_List
    @CompanyId  INT,
    @Status     NVARCHAR(20)  = NULL,
    @FechaDesde DATETIME2     = NULL,
    @FechaHasta DATETIME2     = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 50,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   mfg.WorkOrder wo
    WHERE  wo.CompanyId = @CompanyId
      AND  (@Status     IS NULL OR wo.Status      = @Status)
      AND  (@FechaDesde IS NULL OR wo.PlannedStartDate >= @FechaDesde)
      AND  (@FechaHasta IS NULL OR wo.PlannedEndDate   <= @FechaHasta);

    SELECT
        wo.WorkOrderId, wo.WorkOrderNumber,
        wo.BOMId, wo.ProductId,
        wo.PlannedQuantity, wo.ProducedQuantity,
        wo.Status, wo.Priority,
        wo.PlannedStartDate, wo.PlannedEndDate,
        wo.ActualStartDate, wo.ActualEndDate,
        wo.WarehouseId, wo.AssignedToUserId,
        wo.Notes, wo.CreatedAt, wo.UpdatedAt
    FROM   mfg.WorkOrder wo
    WHERE  wo.CompanyId = @CompanyId
      AND  (@Status     IS NULL OR wo.Status      = @Status)
      AND  (@FechaDesde IS NULL OR wo.PlannedStartDate >= @FechaDesde)
      AND  (@FechaHasta IS NULL OR wo.PlannedEndDate   <= @FechaHasta)
    ORDER BY wo.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_Get
--  Detalle de una orden de trabajo con materiales y salidas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_Get
    @WorkOrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT
        wo.WorkOrderId, wo.WorkOrderNumber, wo.CompanyId, wo.BranchId,
        wo.BOMId, wo.ProductId,
        wo.PlannedQuantity, wo.ProducedQuantity,
        wo.Status, wo.Priority,
        wo.PlannedStartDate, wo.PlannedEndDate, wo.ActualStartDate, wo.ActualEndDate,
        wo.WarehouseId, wo.AssignedToUserId,
        wo.Notes, wo.CreatedAt, wo.UpdatedAt
    FROM mfg.WorkOrder wo
    WHERE wo.WorkOrderId = @WorkOrderId;

    -- Materials consumed
    SELECT
        wm.MaterialId, wm.WorkOrderId, wm.ProductId,
        wm.Quantity, wm.LotNumber, wm.WarehouseId,
        wm.ConsumedAt
    FROM mfg.WorkOrderMaterial wm
    WHERE wm.WorkOrderId = @WorkOrderId
    ORDER BY wm.ConsumedAt;

    -- Outputs
    SELECT
        wo2.OutputId, wo2.WorkOrderId,
        wo2.Quantity, wo2.LotNumber,
        wo2.WarehouseId, wo2.BinId,
        wo2.ProducedAt
    FROM mfg.WorkOrderOutput wo2
    WHERE wo2.WorkOrderId = @WorkOrderId
    ORDER BY wo2.ProducedAt;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_Create
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_Create
    @CompanyId        INT,
    @BranchId         INT,
    @BOMId            INT,
    @ProductId        INT,
    @PlannedQuantity  DECIMAL(18,4),
    @PlannedStartDate     DATETIME2,
    @PlannedEndDate       DATETIME2,
    @Priority         NVARCHAR(20) = 'MEDIUM',
    @WarehouseId      INT          = NULL,
    @Notes            NVARCHAR(MAX)= NULL,
    @AssignedToUserId INT          = NULL,
    @UserId           INT,
    @Resultado        INT          OUTPUT,
    @Mensaje          NVARCHAR(500)OUTPUT,
    @WorkOrderId      INT          OUTPUT,
    @WorkOrderNumber  NVARCHAR(30) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @WorkOrderId = 0;

    BEGIN TRY
        -- Generar numero secuencial: WO-000001
        DECLARE @Seq INT;
        SELECT @Seq = ISNULL(MAX(WorkOrderId), 0) + 1 FROM mfg.WorkOrder WHERE CompanyId = @CompanyId;
        SET @WorkOrderNumber = 'WO-' + RIGHT('000000' + CAST(@Seq AS VARCHAR), 6);

        INSERT INTO mfg.WorkOrder (
            CompanyId, BranchId, WorkOrderNumber,
            BOMId, ProductId, PlannedQuantity, ProducedQuantity,
            Status, Priority,
            PlannedStartDate, PlannedEndDate,
            WarehouseId, AssignedToUserId, Notes,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        ) VALUES (
            @CompanyId, @BranchId, @WorkOrderNumber,
            @BOMId, @ProductId, @PlannedQuantity, 0,
            'PLANNED', @Priority,
            @PlannedStartDate, @PlannedEndDate,
            @WarehouseId, @AssignedToUserId, @Notes,
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @WorkOrderId = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_Start
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_Start
    @WorkOrderId INT,
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        DECLARE @CurrentStatus NVARCHAR(20);
        SELECT @CurrentStatus = Status FROM mfg.WorkOrder WHERE WorkOrderId = @WorkOrderId;

        IF @CurrentStatus <> 'PLANNED'
        BEGIN
            SET @Mensaje = N'Solo se puede iniciar una orden en estado PLANNED. Estado actual: ' + ISNULL(@CurrentStatus, 'NULL');
            RETURN;
        END;

        UPDATE mfg.WorkOrder
        SET    Status          = 'IN_PROGRESS',
               ActualStartDate     = SYSUTCDATETIME(),
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  WorkOrderId = @WorkOrderId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_ConsumeMaterial
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_ConsumeMaterial
    @WorkOrderId INT,
    @ProductId   INT,
    @Quantity    DECIMAL(18,4),
    @LotNumber   NVARCHAR(50) = NULL,
    @WarehouseId INT          = NULL,
    @UserId      INT,
    @Resultado   INT          OUTPUT,
    @Mensaje     NVARCHAR(500)OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        INSERT INTO mfg.WorkOrderMaterial (WorkOrderId, ProductId, Quantity, LotNumber, WarehouseId, ConsumedAt, CreatedByUserId)
        VALUES (@WorkOrderId, @ProductId, @Quantity, @LotNumber, @WarehouseId, SYSUTCDATETIME(), @UserId);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_ReportOutput
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_ReportOutput
    @WorkOrderId INT,
    @Quantity    DECIMAL(18,4),
    @LotNumber   NVARCHAR(50) = NULL,
    @WarehouseId INT          = NULL,
    @BinId       INT          = NULL,
    @UserId      INT,
    @Resultado   INT          OUTPUT,
    @Mensaje     NVARCHAR(500)OUTPUT,
    @OutputId    INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @OutputId = 0;

    BEGIN TRY
        INSERT INTO mfg.WorkOrderOutput (WorkOrderId, Quantity, LotNumber, WarehouseId, BinId, ProducedAt, CreatedByUserId)
        VALUES (@WorkOrderId, @Quantity, @LotNumber, @WarehouseId, @BinId, SYSUTCDATETIME(), @UserId);

        SET @OutputId = SCOPE_IDENTITY();

        -- Actualizar cantidad producida
        UPDATE mfg.WorkOrder
        SET    ProducedQuantity = ISNULL(ProducedQuantity, 0) + @Quantity,
               UpdatedByUserId  = @UserId,
               UpdatedAt        = SYSUTCDATETIME()
        WHERE  WorkOrderId = @WorkOrderId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_Complete
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_Complete
    @WorkOrderId INT,
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        DECLARE @CurrentStatus NVARCHAR(20);
        SELECT @CurrentStatus = Status FROM mfg.WorkOrder WHERE WorkOrderId = @WorkOrderId;

        IF @CurrentStatus <> 'IN_PROGRESS'
        BEGIN
            SET @Mensaje = N'Solo se puede completar una orden en estado IN_PROGRESS. Estado actual: ' + ISNULL(@CurrentStatus, 'NULL');
            RETURN;
        END;

        UPDATE mfg.WorkOrder
        SET    Status          = 'COMPLETED',
               ActualEndDate       = SYSUTCDATETIME(),
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  WorkOrderId = @WorkOrderId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_Mfg_WorkOrder_Cancel
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Mfg_WorkOrder_Cancel
    @WorkOrderId INT,
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        DECLARE @CurrentStatus NVARCHAR(20);
        SELECT @CurrentStatus = Status FROM mfg.WorkOrder WHERE WorkOrderId = @WorkOrderId;

        IF @CurrentStatus IN ('COMPLETED', 'CANCELLED')
        BEGIN
            SET @Mensaje = N'No se puede cancelar una orden en estado ' + @CurrentStatus;
            RETURN;
        END;

        UPDATE mfg.WorkOrder
        SET    Status          = 'CANCELLED',
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  WorkOrderId = @WorkOrderId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO
