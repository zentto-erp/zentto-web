-- +goose Up
-- +goose StatementBegin
-- Analytics functions for Logistics, Fleet, and Manufacturing dashboards

-- ============================================================================
--  LOGISTICS ANALYTICS
-- ============================================================================

-- Recepciones por mes (ultimos 6 meses)
DROP FUNCTION IF EXISTS usp_logistics_analytics_receiptsbymonth(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_logistics_analytics_receiptsbymonth(
    p_company_id  INT,
    p_branch_id   INT
)
RETURNS TABLE (
    "Month"       VARCHAR(7),
    "MonthLabel"  VARCHAR(20),
    "Total"       INT
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
        TO_CHAR(m.month_start, 'YYYY-MM')::VARCHAR(7)       AS "Month",
        TO_CHAR(m.month_start, 'Mon YYYY')::VARCHAR(20)     AS "MonthLabel",
        COALESCE(COUNT(gr."GoodsReceiptId"), 0)::INT         AS "Total"
    FROM months m
    LEFT JOIN logistics."GoodsReceipt" gr
        ON gr."CompanyId" = p_company_id
        AND gr."BranchId" = p_branch_id
        AND gr."IsDeleted" = FALSE
        AND DATE_TRUNC('month', gr."ReceiptDate"::TIMESTAMP) = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;

-- Albaranes por estado
DROP FUNCTION IF EXISTS usp_logistics_analytics_deliverybystatus(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_logistics_analytics_deliverybystatus(
    p_company_id  INT,
    p_branch_id   INT
)
RETURNS TABLE (
    "Status"      VARCHAR(20),
    "StatusLabel" VARCHAR(40),
    "Count"       INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        dn."Status"::VARCHAR(20)                        AS "Status",
        CASE dn."Status"
            WHEN 'DRAFT' THEN 'Borrador'
            WHEN 'CONFIRMED' THEN 'Confirmado'
            WHEN 'PICKING' THEN 'En Picking'
            WHEN 'PACKED' THEN 'Empacado'
            WHEN 'DISPATCHED' THEN 'Despachado'
            WHEN 'DELIVERED' THEN 'Entregado'
            WHEN 'VOIDED' THEN 'Anulado'
            ELSE dn."Status"
        END::VARCHAR(40)                                AS "StatusLabel",
        COUNT(*)::INT                                   AS "Count"
    FROM logistics."DeliveryNote" dn
    WHERE dn."CompanyId" = p_company_id
      AND dn."BranchId" = p_branch_id
      AND dn."IsDeleted" = FALSE
    GROUP BY dn."Status"
    ORDER BY "Count" DESC;
END;
$$;

-- Actividad reciente (recepciones + despachos)
DROP FUNCTION IF EXISTS usp_logistics_analytics_recentactivity(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_logistics_analytics_recentactivity(
    p_company_id  INT,
    p_branch_id   INT
)
RETURNS TABLE (
    "ActivityId"   BIGINT,
    "ActivityType" VARCHAR(20),
    "DocNumber"    VARCHAR(40),
    "EntityName"   VARCHAR(200),
    "ActivityDate" TIMESTAMP,
    "Status"       VARCHAR(20),
    "StatusLabel"  VARCHAR(40)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    (
        SELECT
            gr."GoodsReceiptId"::BIGINT,
            'RECEIPT'::VARCHAR(20),
            gr."ReceiptNumber"::VARCHAR(40),
            COALESCE(s."SupplierName", '')::VARCHAR(200),
            gr."ReceiptDate"::TIMESTAMP,
            gr."Status"::VARCHAR(20),
            CASE gr."Status"
                WHEN 'DRAFT' THEN 'Borrador' WHEN 'PARTIAL' THEN 'Parcial'
                WHEN 'COMPLETE' THEN 'Completa' WHEN 'VOIDED' THEN 'Anulada'
                ELSE gr."Status"
            END::VARCHAR(40)
        FROM logistics."GoodsReceipt" gr
        LEFT JOIN master."Supplier" s ON s."SupplierId" = gr."SupplierId"
        WHERE gr."CompanyId" = p_company_id AND gr."BranchId" = p_branch_id AND gr."IsDeleted" = FALSE
        ORDER BY gr."ReceiptDate" DESC LIMIT 10
    )
    UNION ALL
    (
        SELECT
            dn."DeliveryNoteId"::BIGINT,
            'DELIVERY'::VARCHAR(20),
            dn."DeliveryNumber"::VARCHAR(40),
            COALESCE(c."CustomerName", '')::VARCHAR(200),
            dn."DeliveryDate"::TIMESTAMP,
            dn."Status"::VARCHAR(20),
            CASE dn."Status"
                WHEN 'DRAFT' THEN 'Borrador' WHEN 'CONFIRMED' THEN 'Confirmado'
                WHEN 'PICKING' THEN 'En Picking' WHEN 'PACKED' THEN 'Empacado'
                WHEN 'DISPATCHED' THEN 'Despachado' WHEN 'DELIVERED' THEN 'Entregado'
                WHEN 'VOIDED' THEN 'Anulado' ELSE dn."Status"
            END::VARCHAR(40)
        FROM logistics."DeliveryNote" dn
        LEFT JOIN master."Customer" c ON c."CustomerId" = dn."CustomerId"
        WHERE dn."CompanyId" = p_company_id AND dn."BranchId" = p_branch_id AND dn."IsDeleted" = FALSE
        ORDER BY dn."DeliveryDate" DESC LIMIT 10
    )
    ORDER BY "ActivityDate" DESC LIMIT 10;
END;
$$;

-- Tendencias mes actual vs anterior
DROP FUNCTION IF EXISTS usp_logistics_analytics_trendcards(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_logistics_analytics_trendcards(
    p_company_id  INT,
    p_branch_id   INT
)
RETURNS TABLE (
    "ReceiptsThisMonth"     INT,
    "ReceiptsLastMonth"     INT,
    "DeliveriesThisMonth"   INT,
    "DeliveriesLastMonth"   INT,
    "ReturnsThisMonth"      INT,
    "ReturnsLastMonth"      INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_this_start   TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    v_last_start   TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month';
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT FROM logistics."GoodsReceipt"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "ReceiptDate"::TIMESTAMP >= v_this_start),
        (SELECT COUNT(*)::INT FROM logistics."GoodsReceipt"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "ReceiptDate"::TIMESTAMP >= v_last_start AND "ReceiptDate"::TIMESTAMP < v_this_start),
        (SELECT COUNT(*)::INT FROM logistics."DeliveryNote"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "DeliveryDate"::TIMESTAMP >= v_this_start),
        (SELECT COUNT(*)::INT FROM logistics."DeliveryNote"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "DeliveryDate"::TIMESTAMP >= v_last_start AND "DeliveryDate"::TIMESTAMP < v_this_start),
        (SELECT COUNT(*)::INT FROM logistics."GoodsReturn"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "ReturnDate"::TIMESTAMP >= v_this_start),
        (SELECT COUNT(*)::INT FROM logistics."GoodsReturn"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "IsDeleted" = FALSE
           AND "ReturnDate"::TIMESTAMP >= v_last_start AND "ReturnDate"::TIMESTAMP < v_this_start);
END;
$$;

-- ============================================================================
--  FLEET ANALYTICS
-- ============================================================================

-- Costo combustible por vehiculo (top 5)
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
        (COALESCE(v."Brand", '') || ' ' || COALESCE(v."Model", ''))::VARCHAR(120),
        COALESCE(SUM(fl."TotalCost"), 0)::NUMERIC
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE fl."CompanyId" = p_company_id AND fl."IsDeleted" IS NOT TRUE
      AND fl."FuelDate" >= v_month_start AND v."IsDeleted" IS NOT TRUE
    GROUP BY v."VehicleId", v."LicensePlate", v."Brand", v."Model"
    ORDER BY "TotalCost" DESC LIMIT 5;
END;
$$;

-- Km recorridos por mes (ultimos 6 meses)
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
        TO_CHAR(m.month_start, 'YYYY-MM')::VARCHAR(7),
        TO_CHAR(m.month_start, 'Mon YYYY')::VARCHAR(20),
        COALESCE(SUM(t."DistanceKm"), 0)::NUMERIC
    FROM months m
    LEFT JOIN fleet."Trip" t
        ON t."CompanyId" = p_company_id AND t."IsDeleted" IS NOT TRUE
        AND t."Status" = 'COMPLETED'
        AND DATE_TRUNC('month', t."DepartedAt") = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;

-- Proximos 5 mantenimientos
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
      AND mo."IsDeleted" IS NOT TRUE AND v."IsDeleted" IS NOT TRUE
    ORDER BY mo."ScheduledDate" ASC LIMIT 5;
END;
$$;

-- Tendencias fleet
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
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE AND "FuelDate" >= v_this_start)::NUMERIC,
        (SELECT COALESCE(SUM("TotalCost"), 0) FROM fleet."FuelLog"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "FuelDate" >= v_last_start AND "FuelDate" < v_this_start)::NUMERIC,
        (SELECT COALESCE(SUM("DistanceKm"), 0) FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "Status" = 'COMPLETED' AND "DepartedAt" >= v_this_start)::NUMERIC,
        (SELECT COALESCE(SUM("DistanceKm"), 0) FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "Status" = 'COMPLETED' AND "DepartedAt" >= v_last_start AND "DepartedAt" < v_this_start)::NUMERIC,
        (SELECT COUNT(*)::INT FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE AND "DepartedAt" >= v_this_start),
        (SELECT COUNT(*)::INT FROM fleet."Trip"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE
           AND "DepartedAt" >= v_last_start AND "DepartedAt" < v_this_start);
END;
$$;

-- ============================================================================
--  MANUFACTURING ANALYTICS
-- ============================================================================

-- Dashboard extendido
DROP FUNCTION IF EXISTS usp_mfg_analytics_dashboard(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_analytics_dashboard(
    p_company_id  INT
)
RETURNS TABLE (
    "BOMsActivos"           INT,
    "CentrosTrabajo"        INT,
    "OrdenesEnProceso"      INT,
    "OrdenesCompletadas"    INT,
    "CompletadasEsteMes"    INT,
    "CompletadasMesAnterior" INT,
    "OrdenesATiempo"        INT,
    "OrdenesTotalesMes"     INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_this_start  TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    v_last_start  TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month';
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT FROM mfg."BillOfMaterials"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'ACTIVE'),
        (SELECT COUNT(*)::INT FROM mfg."WorkCenter"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'IN_PROGRESS'),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_this_start),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_last_start AND "ActualEndDate" < v_this_start),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_this_start AND "ActualEndDate" <= "PlannedEndDate"),
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
           AND "Status" IN ('IN_PROGRESS', 'COMPLETED') AND "CreatedAt" >= v_this_start);
END;
$$;

-- Produccion por producto (top 5)
DROP FUNCTION IF EXISTS usp_mfg_analytics_productionbyproduct(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_analytics_productionbyproduct(
    p_company_id  INT
)
RETURNS TABLE (
    "ProductId"     BIGINT,
    "ProductName"   VARCHAR(200),
    "TotalQuantity" NUMERIC,
    "OrderCount"    INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_this_start TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
BEGIN
    RETURN QUERY
    SELECT
        wo."ProductId",
        COALESCE(p."ProductName", 'Sin nombre')::VARCHAR(200),
        COALESCE(SUM(wo."ProducedQuantity"), 0)::NUMERIC,
        COUNT(*)::INT
    FROM mfg."WorkOrder" wo
    LEFT JOIN master."Product" p ON p."ProductId" = wo."ProductId"
    WHERE wo."CompanyId" = p_company_id AND wo."IsDeleted" = FALSE
      AND wo."Status" IN ('IN_PROGRESS', 'COMPLETED') AND wo."CreatedAt" >= v_this_start
    GROUP BY wo."ProductId", p."ProductName"
    ORDER BY "TotalQuantity" DESC LIMIT 5;
END;
$$;

-- Ordenes por estado
DROP FUNCTION IF EXISTS usp_mfg_analytics_ordersbystatus(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_analytics_ordersbystatus(
    p_company_id  INT
)
RETURNS TABLE (
    "Status"       VARCHAR(20),
    "StatusLabel"  VARCHAR(40),
    "Count"        INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        wo."Status"::VARCHAR(20),
        CASE wo."Status"
            WHEN 'DRAFT' THEN 'Borrador' WHEN 'CONFIRMED' THEN 'Confirmada'
            WHEN 'IN_PROGRESS' THEN 'En Proceso' WHEN 'COMPLETED' THEN 'Completada'
            WHEN 'CANCELLED' THEN 'Cancelada' ELSE wo."Status"
        END::VARCHAR(40),
        COUNT(*)::INT
    FROM mfg."WorkOrder" wo
    WHERE wo."CompanyId" = p_company_id AND wo."IsDeleted" = FALSE
    GROUP BY wo."Status" ORDER BY "Count" DESC;
END;
$$;

-- Ordenes recientes
DROP FUNCTION IF EXISTS usp_mfg_analytics_recentorders(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_analytics_recentorders(
    p_company_id  INT
)
RETURNS TABLE (
    "WorkOrderId"     BIGINT,
    "WorkOrderNumber" VARCHAR(30),
    "ProductName"     VARCHAR(200),
    "PlannedQuantity" NUMERIC,
    "ProducedQuantity" NUMERIC,
    "Status"          VARCHAR(20),
    "StatusLabel"     VARCHAR(40),
    "PlannedStart"    TIMESTAMP,
    "PlannedEnd"      TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        wo."WorkOrderId",
        wo."WorkOrderNumber"::VARCHAR(30),
        COALESCE(p."ProductName", 'Sin nombre')::VARCHAR(200),
        wo."PlannedQuantity",
        wo."ProducedQuantity",
        wo."Status"::VARCHAR(20),
        CASE wo."Status"
            WHEN 'DRAFT' THEN 'Borrador' WHEN 'CONFIRMED' THEN 'Confirmada'
            WHEN 'IN_PROGRESS' THEN 'En Proceso' WHEN 'COMPLETED' THEN 'Completada'
            WHEN 'CANCELLED' THEN 'Cancelada' ELSE wo."Status"
        END::VARCHAR(40),
        wo."PlannedStartDate",
        wo."PlannedEndDate"
    FROM mfg."WorkOrder" wo
    LEFT JOIN master."Product" p ON p."ProductId" = wo."ProductId"
    WHERE wo."CompanyId" = p_company_id AND wo."IsDeleted" = FALSE
    ORDER BY wo."CreatedAt" DESC LIMIT 10;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_logistics_analytics_receiptsbymonth(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_logistics_analytics_deliverybystatus(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_logistics_analytics_recentactivity(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_logistics_analytics_trendcards(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_fleet_analytics_fuelcostbyvehicle(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_fleet_analytics_kmbymonth(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_fleet_analytics_nextmaintenance(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_fleet_analytics_trendcards(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_analytics_dashboard(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_analytics_productionbyproduct(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_analytics_ordersbystatus(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_analytics_recentorders(INT) CASCADE;
