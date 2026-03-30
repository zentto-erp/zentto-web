-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_purchases_analytics.sql
-- Funciones de analytics del modulo Compras
-- Fecha: 2026-03-23
-- ============================================================

-- =============================================================================
--  usp_Purchases_Analytics_KPIs
--  KPIs principales del modulo de Compras / CxP
-- =============================================================================
DROP FUNCTION IF EXISTS usp_purchases_analytics_kpis(INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_purchases_analytics_kpis(
    p_company_id  INT,
    p_from        DATE DEFAULT NULL,
    p_to          DATE DEFAULT NULL
)
RETURNS TABLE(
    "TotalCompras"      INT,
    "MontoTotal"        NUMERIC,
    "ProveedoresActivos" INT,
    "CxPPendiente"      NUMERIC,
    "CxPVencida"        NUMERIC,
    "ComprasMes"        INT,
    "CompraMesAnterior" INT,
    "PromedioCompra"    NUMERIC,
    "DiasPromPago"      INT,
    "TopProveedor"      VARCHAR,
    "TopProveedorMonto" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now              TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_from             DATE;
    v_to               DATE;
    v_month_start      DATE := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC')::DATE;
    v_last_month_start DATE := (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month')::DATE;

    v_total_compras       INT := 0;
    v_monto_total         NUMERIC := 0;
    v_proveedores_activos INT := 0;
    v_cxp_pendiente       NUMERIC := 0;
    v_cxp_vencida         NUMERIC := 0;
    v_compras_mes         INT := 0;
    v_compra_mes_anterior INT := 0;
    v_promedio_compra     NUMERIC := 0;
    v_dias_prom_pago      INT := 0;
    v_top_proveedor       VARCHAR := ''::VARCHAR;
    v_top_proveedor_monto NUMERIC := 0;
BEGIN
    v_from := COALESCE(p_from, (v_now - INTERVAL '365 days')::DATE);
    v_to   := COALESCE(p_to, v_now::DATE);

    -- Total compras del periodo (canonico + legacy)
    SELECT COUNT(*)::INT, COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_total_compras, v_monto_total
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    -- Si no hay datos canonicos, intentar legacy
    IF v_total_compras = 0 THEN
        SELECT COUNT(*)::INT,
               COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0)
        INTO v_total_compras, v_monto_total
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to;
    END IF;

    -- Proveedores activos (con documentos en periodo)
    SELECT COUNT(DISTINCT d."SupplierId")::INT
    INTO v_proveedores_activos
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    IF v_proveedores_activos = 0 THEN
        SELECT COUNT(DISTINCT c."COD_PROVEEDOR")::INT
        INTO v_proveedores_activos
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to;
    END IF;

    -- CxP pendiente total (canonico)
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_cxp_pendiente
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" IN ('PENDING', 'PARTIAL');

    -- Si no hay canonico, usar legacy
    IF v_cxp_pendiente = 0 THEN
        SELECT COALESCE(SUM(COALESCE(p."PEND", 0)), 0)
        INTO v_cxp_pendiente
        FROM "P_Pagar" p
        WHERE COALESCE(p."PAID", 0) = 0
          AND COALESCE(p."PEND", 0) > 0;
    END IF;

    -- CxP vencida (DueDate < NOW)
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_cxp_vencida
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" IN ('PENDING', 'PARTIAL')
      AND d."DueDate" IS NOT NULL
      AND d."DueDate" < v_now::DATE;

    -- Compras este mes (canonico)
    SELECT COUNT(*)::INT
    INTO v_compras_mes
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_month_start;

    IF v_compras_mes = 0 THEN
        SELECT COUNT(*)::INT
        INTO v_compras_mes
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_month_start;
    END IF;

    -- Compras mes anterior
    SELECT COUNT(*)::INT
    INTO v_compra_mes_anterior
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_last_month_start
      AND d."IssueDate" < v_month_start;

    IF v_compra_mes_anterior = 0 THEN
        SELECT COUNT(*)::INT
        INTO v_compra_mes_anterior
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_last_month_start
          AND c."FECHA" < v_month_start;
    END IF;

    -- Promedio por compra
    IF v_total_compras > 0 THEN
        v_promedio_compra := ROUND(v_monto_total / v_total_compras, 2);
    END IF;

    -- Dias promedio de pago (canonico: diferencia entre IssueDate y ApplyDate de pagos)
    SELECT COALESCE(
        AVG(EXTRACT(DAY FROM (a."ApplyDate"::TIMESTAMP - d."IssueDate"::TIMESTAMP)))::INT,
        0
    )
    INTO v_dias_prom_pago
    FROM ap."PayableApplication" a
    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"
    WHERE d."CompanyId" = p_company_id
      AND a."ApplyDate" >= v_from;

    -- Top proveedor por monto (canonico)
    SELECT s."SupplierName"::VARCHAR, COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_top_proveedor, v_top_proveedor_monto
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to
    GROUP BY s."SupplierName"
    ORDER BY SUM(d."TotalAmount") DESC
    LIMIT 1;

    -- Fallback legacy
    IF v_top_proveedor IS NULL OR v_top_proveedor = '' THEN
        SELECT COALESCE(c."NOMBRE", c."COD_PROVEEDOR")::VARCHAR,
               COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0)
        INTO v_top_proveedor, v_top_proveedor_monto
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to
        GROUP BY COALESCE(c."NOMBRE", c."COD_PROVEEDOR")
        ORDER BY SUM(COALESCE(c."TOTAL", 0)) DESC
        LIMIT 1;
    END IF;

    v_top_proveedor := COALESCE(v_top_proveedor, ''::VARCHAR);

    RETURN QUERY
    SELECT v_total_compras, ROUND(v_monto_total, 2), v_proveedores_activos,
           ROUND(v_cxp_pendiente, 2), ROUND(v_cxp_vencida, 2),
           v_compras_mes, v_compra_mes_anterior, v_promedio_compra,
           v_dias_prom_pago, v_top_proveedor, ROUND(v_top_proveedor_monto, 2);
END;
$$;

-- =============================================================================
--  usp_Purchases_Analytics_ByMonth
--  Compras agrupadas por mes con running total (acumulado)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_purchases_analytics_bymonth(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_purchases_analytics_bymonth(
    p_company_id  INT,
    p_months      INT DEFAULT 12
)
RETURNS TABLE(
    "Month"       VARCHAR,
    "Count"       INT,
    "Total"       NUMERIC,
    "Accumulated" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH months AS (
        SELECT m.month_start
        FROM generate_series(
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL,
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC'),
            '1 month'::INTERVAL
        ) AS m(month_start)
    ),
    canonical AS (
        SELECT DATE_TRUNC('month', d."IssueDate"::TIMESTAMP) AS mes,
               COUNT(*)::INT AS cnt,
               COALESCE(SUM(d."TotalAmount"), 0) AS total
        FROM ap."PayableDocument" d
        WHERE d."CompanyId" = p_company_id
          AND d."Status" <> 'VOIDED'
          AND d."IssueDate" >= (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL)::DATE
        GROUP BY DATE_TRUNC('month', d."IssueDate"::TIMESTAMP)
    ),
    legacy AS (
        SELECT DATE_TRUNC('month', c."FECHA") AS mes,
               COUNT(*)::INT AS cnt,
               COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0) AS total
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL)
        GROUP BY DATE_TRUNC('month', c."FECHA")
    ),
    combined AS (
        SELECT m.month_start,
               COALESCE(ca.cnt, 0) + COALESCE(lg.cnt, 0) AS cnt,
               COALESCE(ca.total, 0) + COALESCE(lg.total, 0) AS total
        FROM months m
        LEFT JOIN canonical ca ON ca.mes = m.month_start
        LEFT JOIN legacy lg ON lg.mes = m.month_start
    )
    SELECT
        TO_CHAR(c.month_start, 'YYYY-MM')::VARCHAR AS "Month",
        c.cnt                                       AS "Count",
        ROUND(c.total, 2)                           AS "Total",
        ROUND(SUM(c.total) OVER (ORDER BY c.month_start), 2) AS "Accumulated"
    FROM combined c
    ORDER BY c.month_start;
END;
$$;

-- =============================================================================
--  usp_Purchases_Analytics_BySupplier
--  Top proveedores por monto de compras
-- =============================================================================
DROP FUNCTION IF EXISTS usp_purchases_analytics_bysupplier(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_purchases_analytics_bysupplier(
    p_company_id  INT,
    p_top         INT DEFAULT 10,
    p_from        DATE DEFAULT NULL,
    p_to          DATE DEFAULT NULL
)
RETURNS TABLE(
    "SupplierCode" VARCHAR,
    "SupplierName" VARCHAR,
    "ComprasCount" INT,
    "Total"        NUMERIC,
    "Percentage"   NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_from       DATE;
    v_to         DATE;
    v_grand_total NUMERIC := 0;
BEGIN
    v_from := COALESCE(p_from, ((NOW() AT TIME ZONE 'UTC') - INTERVAL '365 days')::DATE);
    v_to   := COALESCE(p_to,   (NOW() AT TIME ZONE 'UTC')::DATE);

    -- Calcular gran total
    SELECT COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_grand_total
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    -- Si hay datos canonicos
    IF v_grand_total > 0 THEN
        RETURN QUERY
        SELECT
            s."SupplierCode"::VARCHAR,
            s."SupplierName"::VARCHAR,
            COUNT(*)::INT                              AS "ComprasCount",
            ROUND(COALESCE(SUM(d."TotalAmount"), 0), 2) AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(d."TotalAmount") * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                        AS "Percentage"
        FROM ap."PayableDocument" d
        INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
        WHERE d."CompanyId" = p_company_id
          AND d."Status" <> 'VOIDED'
          AND d."IssueDate" >= v_from
          AND d."IssueDate" <= v_to
        GROUP BY s."SupplierCode", s."SupplierName"
        ORDER BY SUM(d."TotalAmount") DESC
        LIMIT p_top;
    ELSE
        -- Fallback legacy
        SELECT COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0)
        INTO v_grand_total
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to;

        RETURN QUERY
        SELECT
            COALESCE(c."COD_PROVEEDOR", '')::VARCHAR     AS "SupplierCode",
            COALESCE(c."NOMBRE", c."COD_PROVEEDOR")::VARCHAR AS "SupplierName",
            COUNT(*)::INT                                 AS "ComprasCount",
            ROUND(COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0), 2) AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(COALESCE(c."TOTAL", 0)) * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                           AS "Percentage"
        FROM "Compras" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to
        GROUP BY c."COD_PROVEEDOR", c."NOMBRE"
        ORDER BY SUM(COALESCE(c."TOTAL", 0)) DESC
        LIMIT p_top;
    END IF;
END;
$$;

-- =============================================================================
--  usp_Purchases_Analytics_AgingAP
--  Aging de CxP en 5 buckets: 0-30, 31-60, 61-90, 91-120, 120+ dias
-- =============================================================================
DROP FUNCTION IF EXISTS usp_purchases_analytics_agingap(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_purchases_analytics_agingap(
    p_company_id  INT
)
RETURNS TABLE(
    "Bucket"     VARCHAR,
    "Count"      INT,
    "Total"      NUMERIC,
    "Percentage" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_grand_total NUMERIC := 0;
BEGIN
    -- Gran total CxP pendiente
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_grand_total
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" IN ('PENDING', 'PARTIAL');

    RETURN QUERY
    WITH aging AS (
        SELECT
            CASE
                WHEN EXTRACT(DAY FROM (NOW() AT TIME ZONE 'UTC' - d."DueDate"::TIMESTAMP)) <= 30
                    THEN '0-30'
                WHEN EXTRACT(DAY FROM (NOW() AT TIME ZONE 'UTC' - d."DueDate"::TIMESTAMP)) <= 60
                    THEN '31-60'
                WHEN EXTRACT(DAY FROM (NOW() AT TIME ZONE 'UTC' - d."DueDate"::TIMESTAMP)) <= 90
                    THEN '61-90'
                WHEN EXTRACT(DAY FROM (NOW() AT TIME ZONE 'UTC' - d."DueDate"::TIMESTAMP)) <= 120
                    THEN '91-120'
                ELSE '120+'
            END AS bucket,
            d."PendingAmount"
        FROM ap."PayableDocument" d
        WHERE d."CompanyId" = p_company_id
          AND d."Status" IN ('PENDING', 'PARTIAL')
          AND d."DueDate" IS NOT NULL
    ),
    buckets AS (
        SELECT b.bucket_name, b.sort_order
        FROM (VALUES
            ('0-30', 1), ('31-60', 2), ('61-90', 3), ('91-120', 4), ('120+', 5)
        ) AS b(bucket_name, sort_order)
    )
    SELECT
        bk.bucket_name::VARCHAR                       AS "Bucket",
        COALESCE(COUNT(a.bucket), 0)::INT              AS "Count",
        ROUND(COALESCE(SUM(a."PendingAmount"), 0), 2)  AS "Total",
        CASE WHEN v_grand_total > 0
             THEN ROUND(COALESCE(SUM(a."PendingAmount"), 0) * 100.0 / v_grand_total, 2)
             ELSE 0::NUMERIC
        END                                            AS "Percentage"
    FROM buckets bk
    LEFT JOIN aging a ON a.bucket = bk.bucket_name
    GROUP BY bk.bucket_name, bk.sort_order
    ORDER BY bk.sort_order;
END;
$$;

-- =============================================================================
--  usp_Purchases_Analytics_PaymentSchedule
--  Proyeccion de pagos proximos meses (basado en DueDate de documentos pendientes)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_purchases_analytics_paymentschedule(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_purchases_analytics_paymentschedule(
    p_company_id  INT,
    p_months      INT DEFAULT 3
)
RETURNS TABLE(
    "Month"         VARCHAR,
    "DueAmount"     NUMERIC,
    "DocumentCount" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH months AS (
        SELECT m.month_start
        FROM generate_series(
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC'),
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') + ((p_months - 1) || ' months')::INTERVAL,
            '1 month'::INTERVAL
        ) AS m(month_start)
    )
    SELECT
        TO_CHAR(m.month_start, 'YYYY-MM')::VARCHAR                 AS "Month",
        ROUND(COALESCE(SUM(d."PendingAmount"), 0), 2)               AS "DueAmount",
        COUNT(d."PayableDocumentId")::INT                            AS "DocumentCount"
    FROM months m
    LEFT JOIN ap."PayableDocument" d
        ON  d."CompanyId" = p_company_id
        AND d."Status" IN ('PENDING', 'PARTIAL')
        AND d."DueDate" IS NOT NULL
        AND DATE_TRUNC('month', d."DueDate"::TIMESTAMP) = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;
