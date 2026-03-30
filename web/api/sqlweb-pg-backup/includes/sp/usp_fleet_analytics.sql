-- ============================================================================
--  Fleet Analytics â€” Dashboard Enterprise
--  PostgreSQL functions for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Fleet_Analytics_FuelCostByVehicle
--  Costo combustible por vehiculo (top 5 este mes)
-- ============================================================================
DROP FUNCTION IF EXISTS usp_fleet_analytics_fuelcostbyvehicle(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_analytics_fuelcostbyvehicle(
    p_company_id  INT
)
RETURNS TABLE (
    "VehicleId"    BIGINT,
    "LicensePlate" VARCHAR(20),
    "BrandModel"   VARCHAR(120),
    "TotalCost"    NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_month_start TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
BEGIN
    RETURN QUERY
    SELECT
        v."VehicleId",
        v."LicensePlate"::VARCHAR(20),
        (COALESCE(v."Brand", '') || ' ' || COALESCE(v."Model", ''))::VARCHAR(120) AS "BrandModel",
        COALESCE(SUM(fl."TotalCost"), 0)::NUMERIC AS "TotalCost"
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE fl."CompanyId" = p_company_id
      AND fl."IsDeleted" IS NOT TRUE
      AND fl."FuelDate" >= v_month_start
      AND v."IsDeleted" IS NOT TRUE
    GROUP BY v."VehicleId", v."LicensePlate", v."Brand", v."Model"
    ORDER BY "TotalCost" DESC
    LIMIT 5;
END;
$$;

-- ============================================================================
--  usp_Fleet_Analytics_KmByMonth
--  Km recorridos por mes (ultimos 6 meses)
-- ============================================================================
DROP FUNCTION IF EXISTS usp_fleet_analytics_kmbymonth(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_analytics_kmbymonth(
    p_company_id  INT
)
RETURNS TABLE (
    "Month"       VARCHAR(7),
    "MonthLabel"  VARCHAR(20),
    "TotalKm"     NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    WITH months AS (
        SELECT generate_series(
            DATE_TRUNC('month', v_now) - INTERVAL '5 months',
            DATE_TRUNC('month', v_now),
            '1 month'::INTERVAL
        ) AS month_start
    )
    SELECT
        TO_CHAR(m.month_start, 'YYYY-MM')::VARCHAR(7)    AS "Month",
        TO_CHAR(m.month_start, 'Mon YYYY')::VARCHAR(20)  AS "MonthLabel",
        COALESCE(SUM(t."DistanceKm"), 0)::NUMERIC        AS "TotalKm"
    FROM months m
    LEFT JOIN fleet."Trip" t
        ON t."CompanyId" = p_company_id
        AND t."IsDeleted" IS NOT TRUE
        AND t."Status" = 'COMPLETED'
        AND DATE_TRUNC('month', t."DepartedAt") = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;

-- ============================================================================
--  usp_Fleet_Analytics_NextMaintenance
--  Proximos 5 mantenimientos pendientes
-- ============================================================================
DROP FUNCTION IF EXISTS usp_fleet_analytics_nextmaintenance(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_analytics_nextmaintenance(
    p_company_id  INT
)
RETURNS TABLE (
    "MaintenanceOrderId" BIGINT,
    "OrderNumber"        VARCHAR(30),
    "LicensePlate"       VARCHAR(20),
    "BrandModel"         VARCHAR(120),
    "MaintenanceType"    VARCHAR(60),
    "ScheduledDate"      TIMESTAMP,
    "EstimatedCost"      NUMERIC,
    "Status"             VARCHAR(20)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR(30),
        v."LicensePlate"::VARCHAR(20),
        (COALESCE(v."Brand", '') || ' ' || COALESCE(v."Model", ''))::VARCHAR(120),
        COALESCE(mt."TypeName", mo."MaintenanceType")::VARCHAR(60),
        mo."ScheduledDate",
        COALESCE(mo."EstimatedCost", 0)::NUMERIC,
        mo."Status"::VARCHAR(20)
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" IN ('PENDING', 'SCHEDULED')
      AND mo."IsDeleted" IS NOT TRUE
      AND v."IsDeleted" IS NOT TRUE
    ORDER BY mo."ScheduledDate" ASC
    LIMIT 5;
END;
$$;

-- ============================================================================
--  usp_Fleet_Analytics_TrendCards
--  KPIs extendidos con tendencias
-- ============================================================================
DROP FUNCTION IF EXISTS usp_fleet_analytics_trendcards(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_analytics_trendcards(
    p_company_id  INT
)
RETURNS TABLE (
    "FuelCostThisMonth"    NUMERIC,
    "FuelCostLastMonth"    NUMERIC,
    "KmThisMonth"          NUMERIC,
    "KmLastMonth"          NUMERIC,
    "TripsThisMonth"       INT,
    "TripsLastMonth"       INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_this_start  TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    v_last_start  TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month';
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COALESCE(SUM("TotalCost"), 0) FROM fleet."FuelLog"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "FuelDate" >= v_this_start)::NUMERIC
        AS "FuelCostThisMonth",

        (SELECT COALESCE(SUM("TotalCost"), 0) FROM fleet."FuelLog"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "FuelDate" >= v_last_start AND "FuelDate" < v_this_start)::NUMERIC
        AS "FuelCostLastMonth",

        (SELECT COALESCE(SUM("DistanceKm"), 0) FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "Status" = 'COMPLETED' AND "DepartedAt" >= v_this_start)::NUMERIC
        AS "KmThisMonth",

        (SELECT COALESCE(SUM("DistanceKm"), 0) FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "Status" = 'COMPLETED'
           AND "DepartedAt" >= v_last_start AND "DepartedAt" < v_this_start)::NUMERIC
        AS "KmLastMonth",

        (SELECT COUNT(*)::INT FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "DepartedAt" >= v_this_start)
        AS "TripsThisMonth",

        (SELECT COUNT(*)::INT FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "DepartedAt" >= v_last_start AND "DepartedAt" < v_this_start)
        AS "TripsLastMonth";
END;
$$;
