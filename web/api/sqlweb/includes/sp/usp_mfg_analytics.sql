-- ============================================================================
--  Manufacturing Analytics — Dashboard Enterprise
--  SQL Server stored procedures for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Mfg_Analytics_Dashboard
--  KPIs extendidos para manufactura
-- ============================================================================
IF OBJECT_ID('dbo.usp_Mfg_Analytics_Dashboard', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Mfg_Analytics_Dashboard;
GO
CREATE PROCEDURE dbo.usp_Mfg_Analytics_Dashboard
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThisStart DATETIME2 = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @LastStart DATETIME2 = DATEADD(MONTH, -1, @ThisStart);

    SELECT
        (SELECT COUNT(*) FROM mfg.BillOfMaterials
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'ACTIVE')
        AS BOMsActivos,

        (SELECT COUNT(*) FROM mfg.WorkCenter
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND IsActive = 1)
        AS CentrosTrabajo,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'IN_PROGRESS')
        AS OrdenesEnProceso,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'COMPLETED')
        AS OrdenesCompletadas,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'COMPLETED'
           AND ActualEndDate >= @ThisStart)
        AS CompletadasEsteMes,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'COMPLETED'
           AND ActualEndDate >= @LastStart AND ActualEndDate < @ThisStart)
        AS CompletadasMesAnterior,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND [Status] = 'COMPLETED'
           AND ActualEndDate >= @ThisStart
           AND ActualEndDate <= PlannedEndDate)
        AS OrdenesATiempo,

        (SELECT COUNT(*) FROM mfg.WorkOrder
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND [Status] IN ('IN_PROGRESS', 'COMPLETED')
           AND CreatedAt >= @ThisStart)
        AS OrdenesTotalesMes;
END;
GO

-- ============================================================================
--  usp_Mfg_Analytics_ProductionByProduct
--  Produccion por producto (top 5 este mes)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Mfg_Analytics_ProductionByProduct', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Mfg_Analytics_ProductionByProduct;
GO
CREATE PROCEDURE dbo.usp_Mfg_Analytics_ProductionByProduct
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThisStart DATETIME2 = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));

    SELECT TOP 5
        wo.ProductId,
        ISNULL(p.ProductName, N'Sin nombre')    AS ProductName,
        ISNULL(SUM(wo.ProducedQuantity), 0)     AS TotalQuantity,
        COUNT(*)                                 AS OrderCount
    FROM mfg.WorkOrder wo
    LEFT JOIN master.Product p ON p.ProductId = wo.ProductId
    WHERE wo.CompanyId = @CompanyId
      AND wo.IsDeleted = 0
      AND wo.[Status] IN ('IN_PROGRESS', 'COMPLETED')
      AND wo.CreatedAt >= @ThisStart
    GROUP BY wo.ProductId, p.ProductName
    ORDER BY TotalQuantity DESC;
END;
GO

-- ============================================================================
--  usp_Mfg_Analytics_OrdersByStatus
--  Ordenes por estado (para grafico de dona)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Mfg_Analytics_OrdersByStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Mfg_Analytics_OrdersByStatus;
GO
CREATE PROCEDURE dbo.usp_Mfg_Analytics_OrdersByStatus
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        wo.[Status]                           AS [Status],
        CASE wo.[Status]
            WHEN 'DRAFT' THEN N'Borrador'
            WHEN 'CONFIRMED' THEN N'Confirmada'
            WHEN 'IN_PROGRESS' THEN N'En Proceso'
            WHEN 'COMPLETED' THEN N'Completada'
            WHEN 'CANCELLED' THEN N'Cancelada'
            ELSE wo.[Status]
        END                                   AS StatusLabel,
        COUNT(*)                              AS [Count]
    FROM mfg.WorkOrder wo
    WHERE wo.CompanyId = @CompanyId
      AND wo.IsDeleted = 0
    GROUP BY wo.[Status]
    ORDER BY [Count] DESC;
END;
GO

-- ============================================================================
--  usp_Mfg_Analytics_RecentOrders
--  Ultimas 10 ordenes de produccion
-- ============================================================================
IF OBJECT_ID('dbo.usp_Mfg_Analytics_RecentOrders', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Mfg_Analytics_RecentOrders;
GO
CREATE PROCEDURE dbo.usp_Mfg_Analytics_RecentOrders
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10
        wo.WorkOrderId,
        wo.WorkOrderNumber,
        ISNULL(p.ProductName, N'Sin nombre')  AS ProductName,
        wo.PlannedQuantity,
        wo.ProducedQuantity,
        wo.[Status],
        CASE wo.[Status]
            WHEN 'DRAFT' THEN N'Borrador'
            WHEN 'CONFIRMED' THEN N'Confirmada'
            WHEN 'IN_PROGRESS' THEN N'En Proceso'
            WHEN 'COMPLETED' THEN N'Completada'
            WHEN 'CANCELLED' THEN N'Cancelada'
            ELSE wo.[Status]
        END                                   AS StatusLabel,
        wo.PlannedStartDate                   AS PlannedStart,
        wo.PlannedEndDate                     AS PlannedEnd
    FROM mfg.WorkOrder wo
    LEFT JOIN master.Product p ON p.ProductId = wo.ProductId
    WHERE wo.CompanyId = @CompanyId
      AND wo.IsDeleted = 0
    ORDER BY wo.CreatedAt DESC;
END;
GO
