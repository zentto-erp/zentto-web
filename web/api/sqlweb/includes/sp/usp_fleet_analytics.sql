-- ============================================================================
--  Fleet Analytics — Dashboard Enterprise
--  SQL Server stored procedures for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Fleet_Analytics_FuelCostByVehicle
--  Costo combustible por vehiculo (top 5 este mes)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Fleet_Analytics_FuelCostByVehicle', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Fleet_Analytics_FuelCostByVehicle;
GO
CREATE PROCEDURE dbo.usp_Fleet_Analytics_FuelCostByVehicle
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthStart DATE = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));

    SELECT TOP 5
        v.VehicleId,
        v.LicensePlate,
        ISNULL(v.Brand, '') + ' ' + ISNULL(v.Model, '')  AS BrandModel,
        ISNULL(SUM(fl.TotalCost), 0)                      AS TotalCost
    FROM fleet.FuelLog fl
    INNER JOIN fleet.Vehicle v ON v.VehicleId = fl.VehicleId
    WHERE fl.CompanyId = @CompanyId
      AND fl.IsDeleted = 0
      AND fl.FuelDate >= @MonthStart
      AND v.IsDeleted = 0
    GROUP BY v.VehicleId, v.LicensePlate, v.Brand, v.Model
    ORDER BY TotalCost DESC;
END;
GO

-- ============================================================================
--  usp_Fleet_Analytics_KmByMonth
--  Km recorridos por mes (ultimos 6 meses)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Fleet_Analytics_KmByMonth', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Fleet_Analytics_KmByMonth;
GO
CREATE PROCEDURE dbo.usp_Fleet_Analytics_KmByMonth
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH months AS (
        SELECT DATEADD(MONTH, -n, DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE))) AS month_start
        FROM (VALUES (0),(1),(2),(3),(4),(5)) AS t(n)
    )
    SELECT
        FORMAT(m.month_start, 'yyyy-MM')    AS [Month],
        FORMAT(m.month_start, 'MMM yyyy')   AS [MonthLabel],
        ISNULL(SUM(t.DistanceKm), 0)        AS TotalKm
    FROM months m
    LEFT JOIN fleet.Trip t
        ON t.CompanyId = @CompanyId
        AND t.IsDeleted = 0
        AND t.[Status] = 'COMPLETED'
        AND DATEADD(DAY, 1 - DAY(t.DepartedAt), CAST(t.DepartedAt AS DATE)) = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
GO

-- ============================================================================
--  usp_Fleet_Analytics_NextMaintenance
--  Proximos 5 mantenimientos pendientes
-- ============================================================================
IF OBJECT_ID('dbo.usp_Fleet_Analytics_NextMaintenance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Fleet_Analytics_NextMaintenance;
GO
CREATE PROCEDURE dbo.usp_Fleet_Analytics_NextMaintenance
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 5
        mo.MaintenanceOrderId,
        mo.OrderNumber,
        v.LicensePlate,
        ISNULL(v.Brand, '') + ' ' + ISNULL(v.Model, '')  AS BrandModel,
        ISNULL(mt.TypeName, mo.MaintenanceType)           AS MaintenanceType,
        mo.ScheduledDate,
        ISNULL(mo.EstimatedCost, 0)                       AS EstimatedCost,
        mo.[Status]
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
    LEFT JOIN fleet.MaintenanceType mt ON mt.MaintenanceTypeId = mo.MaintenanceTypeId
    WHERE mo.CompanyId = @CompanyId
      AND mo.[Status] IN ('PENDING', 'SCHEDULED')
      AND mo.IsDeleted = 0
      AND v.IsDeleted = 0
    ORDER BY mo.ScheduledDate ASC;
END;
GO

-- ============================================================================
--  usp_Fleet_Analytics_TrendCards
--  KPIs extendidos con tendencias
-- ============================================================================
IF OBJECT_ID('dbo.usp_Fleet_Analytics_TrendCards', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Fleet_Analytics_TrendCards;
GO
CREATE PROCEDURE dbo.usp_Fleet_Analytics_TrendCards
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThisStart DATE = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @LastStart DATE = DATEADD(MONTH, -1, @ThisStart);

    SELECT
        (SELECT ISNULL(SUM(TotalCost), 0) FROM fleet.FuelLog
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND FuelDate >= @ThisStart) AS FuelCostThisMonth,

        (SELECT ISNULL(SUM(TotalCost), 0) FROM fleet.FuelLog
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND FuelDate >= @LastStart AND FuelDate < @ThisStart) AS FuelCostLastMonth,

        (SELECT ISNULL(SUM(DistanceKm), 0) FROM fleet.Trip
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND [Status] = 'COMPLETED' AND DepartedAt >= @ThisStart) AS KmThisMonth,

        (SELECT ISNULL(SUM(DistanceKm), 0) FROM fleet.Trip
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND [Status] = 'COMPLETED'
           AND DepartedAt >= @LastStart AND DepartedAt < @ThisStart) AS KmLastMonth,

        (SELECT COUNT(*) FROM fleet.Trip
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND DepartedAt >= @ThisStart) AS TripsThisMonth,

        (SELECT COUNT(*) FROM fleet.Trip
         WHERE CompanyId = @CompanyId AND IsDeleted = 0
           AND DepartedAt >= @LastStart AND DepartedAt < @ThisStart) AS TripsLastMonth;
END;
GO
