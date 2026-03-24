-- ============================================================================
--  Logistics Analytics — Dashboard Enterprise
--  PostgreSQL functions for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Logistics_Analytics_ReceiptsByMonth
--  Recepciones por mes (ultimos 6 meses)
-- ============================================================================
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

-- ============================================================================
--  usp_Logistics_Analytics_DeliveryByStatus
--  Albaranes por estado (para grafico de dona)
-- ============================================================================
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

-- ============================================================================
--  usp_Logistics_Analytics_RecentActivity
--  Ultimos 10 movimientos (recepciones + despachos)
-- ============================================================================
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
            gr."GoodsReceiptId"::BIGINT       AS "ActivityId",
            'RECEIPT'::VARCHAR(20)             AS "ActivityType",
            gr."ReceiptNumber"::VARCHAR(40)    AS "DocNumber",
            COALESCE(s."SupplierName", '')::VARCHAR(200) AS "EntityName",
            gr."ReceiptDate"::TIMESTAMP        AS "ActivityDate",
            gr."Status"::VARCHAR(20)           AS "Status",
            CASE gr."Status"
                WHEN 'DRAFT' THEN 'Borrador'
                WHEN 'PARTIAL' THEN 'Parcial'
                WHEN 'COMPLETE' THEN 'Completa'
                WHEN 'VOIDED' THEN 'Anulada'
                ELSE gr."Status"
            END::VARCHAR(40)                   AS "StatusLabel"
        FROM logistics."GoodsReceipt" gr
        LEFT JOIN master."Supplier" s ON s."SupplierId" = gr."SupplierId"
        WHERE gr."CompanyId" = p_company_id
          AND gr."BranchId" = p_branch_id
          AND gr."IsDeleted" = FALSE
        ORDER BY gr."ReceiptDate" DESC
        LIMIT 10
    )
    UNION ALL
    (
        SELECT
            dn."DeliveryNoteId"::BIGINT        AS "ActivityId",
            'DELIVERY'::VARCHAR(20)            AS "ActivityType",
            dn."DeliveryNumber"::VARCHAR(40)   AS "DocNumber",
            COALESCE(c."CustomerName", '')::VARCHAR(200) AS "EntityName",
            dn."DeliveryDate"::TIMESTAMP       AS "ActivityDate",
            dn."Status"::VARCHAR(20)           AS "Status",
            CASE dn."Status"
                WHEN 'DRAFT' THEN 'Borrador'
                WHEN 'CONFIRMED' THEN 'Confirmado'
                WHEN 'PICKING' THEN 'En Picking'
                WHEN 'PACKED' THEN 'Empacado'
                WHEN 'DISPATCHED' THEN 'Despachado'
                WHEN 'DELIVERED' THEN 'Entregado'
                WHEN 'VOIDED' THEN 'Anulado'
                ELSE dn."Status"
            END::VARCHAR(40)                   AS "StatusLabel"
        FROM logistics."DeliveryNote" dn
        LEFT JOIN master."Customer" c ON c."CustomerId" = dn."CustomerId"
        WHERE dn."CompanyId" = p_company_id
          AND dn."BranchId" = p_branch_id
          AND dn."IsDeleted" = FALSE
        ORDER BY dn."DeliveryDate" DESC
        LIMIT 10
    )
    ORDER BY "ActivityDate" DESC
    LIMIT 10;
END;
$$;

-- ============================================================================
--  usp_Logistics_Analytics_TrendCards
--  Recepciones este mes vs anterior (% cambio)
-- ============================================================================
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
    v_now          TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_this_start   TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    v_last_start   TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month';
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT FROM logistics."GoodsReceipt"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE AND "ReceiptDate"::TIMESTAMP >= v_this_start)
        AS "ReceiptsThisMonth",

        (SELECT COUNT(*)::INT FROM logistics."GoodsReceipt"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE
           AND "ReceiptDate"::TIMESTAMP >= v_last_start
           AND "ReceiptDate"::TIMESTAMP < v_this_start)
        AS "ReceiptsLastMonth",

        (SELECT COUNT(*)::INT FROM logistics."DeliveryNote"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE AND "DeliveryDate"::TIMESTAMP >= v_this_start)
        AS "DeliveriesThisMonth",

        (SELECT COUNT(*)::INT FROM logistics."DeliveryNote"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE
           AND "DeliveryDate"::TIMESTAMP >= v_last_start
           AND "DeliveryDate"::TIMESTAMP < v_this_start)
        AS "DeliveriesLastMonth",

        (SELECT COUNT(*)::INT FROM logistics."GoodsReturn"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE AND "ReturnDate"::TIMESTAMP >= v_this_start)
        AS "ReturnsThisMonth",

        (SELECT COUNT(*)::INT FROM logistics."GoodsReturn"
         WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
           AND "IsDeleted" = FALSE
           AND "ReturnDate"::TIMESTAMP >= v_last_start
           AND "ReturnDate"::TIMESTAMP < v_this_start)
        AS "ReturnsLastMonth";
END;
$$;
