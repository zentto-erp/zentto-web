-- ============================================================================
--  Manufacturing Analytics â€” Dashboard Enterprise
--  PostgreSQL functions for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Mfg_Analytics_Dashboard
--  KPIs extendidos para manufactura (reemplaza el approach client-side)
-- ============================================================================
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
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'ACTIVE')
        AS "BOMsActivos",

        (SELECT COUNT(*)::INT FROM mfg."WorkCenter"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE)
        AS "CentrosTrabajo",

        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'IN_PROGRESS')
        AS "OrdenesEnProceso",

        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED')
        AS "OrdenesCompletadas",

        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_this_start)
        AS "CompletadasEsteMes",

        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_last_start AND "ActualEndDate" < v_this_start)
        AS "CompletadasMesAnterior",

        -- Ordenes completadas a tiempo (ActualEndDate <= PlannedEndDate)
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'COMPLETED'
           AND "ActualEndDate" >= v_this_start
           AND "ActualEndDate" <= "PlannedEndDate")
        AS "OrdenesATiempo",

        -- Total de ordenes completadas + en proceso este mes
        (SELECT COUNT(*)::INT FROM mfg."WorkOrder"
         WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
           AND "Status" IN ('IN_PROGRESS', 'COMPLETED')
           AND "CreatedAt" >= v_this_start)
        AS "OrdenesTotalesMes";
END;
$$;

-- ============================================================================
--  usp_Mfg_Analytics_ProductionByProduct
--  Produccion por producto (top 5 este mes)
-- ============================================================================
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
        COALESCE(p."ProductName", 'Sin nombre')::VARCHAR(200) AS "ProductName",
        COALESCE(SUM(wo."ProducedQuantity"), 0)::NUMERIC      AS "TotalQuantity",
        COUNT(*)::INT                                          AS "OrderCount"
    FROM mfg."WorkOrder" wo
    LEFT JOIN master."Product" p ON p."ProductId" = wo."ProductId"
    WHERE wo."CompanyId" = p_company_id
      AND wo."IsDeleted" = FALSE
      AND wo."Status" IN ('IN_PROGRESS', 'COMPLETED')
      AND wo."CreatedAt" >= v_this_start
    GROUP BY wo."ProductId", p."ProductName"
    ORDER BY "TotalQuantity" DESC
    LIMIT 5;
END;
$$;

-- ============================================================================
--  usp_Mfg_Analytics_OrdersByStatus
--  Ordenes por estado (para grafico de dona)
-- ============================================================================
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
        wo."Status"::VARCHAR(20)               AS "Status",
        CASE wo."Status"
            WHEN 'DRAFT' THEN 'Borrador'
            WHEN 'CONFIRMED' THEN 'Confirmada'
            WHEN 'IN_PROGRESS' THEN 'En Proceso'
            WHEN 'COMPLETED' THEN 'Completada'
            WHEN 'CANCELLED' THEN 'Cancelada'
            ELSE wo."Status"
        END::VARCHAR(40)                       AS "StatusLabel",
        COUNT(*)::INT                          AS "Count"
    FROM mfg."WorkOrder" wo
    WHERE wo."CompanyId" = p_company_id
      AND wo."IsDeleted" = FALSE
    GROUP BY wo."Status"
    ORDER BY "Count" DESC;
END;
$$;

-- ============================================================================
--  usp_Mfg_Analytics_RecentOrders
--  Ultimas 10 ordenes de produccion
-- ============================================================================
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
            WHEN 'DRAFT' THEN 'Borrador'
            WHEN 'CONFIRMED' THEN 'Confirmada'
            WHEN 'IN_PROGRESS' THEN 'En Proceso'
            WHEN 'COMPLETED' THEN 'Completada'
            WHEN 'CANCELLED' THEN 'Cancelada'
            ELSE wo."Status"
        END::VARCHAR(40),
        wo."PlannedStartDate",
        wo."PlannedEndDate"
    FROM mfg."WorkOrder" wo
    LEFT JOIN master."Product" p ON p."ProductId" = wo."ProductId"
    WHERE wo."CompanyId" = p_company_id
      AND wo."IsDeleted" = FALSE
    ORDER BY wo."CreatedAt" DESC
    LIMIT 10;
END;
$$;
