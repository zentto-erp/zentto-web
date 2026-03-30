-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_sales_analytics.sql
-- Funciones de analytics del modulo Ventas / CxC
-- Fecha: 2026-03-23
-- ============================================================

-- =============================================================================
--  usp_Sales_Analytics_KPIs
--  KPIs principales del modulo de Ventas / CxC
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_kpis(INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_kpis(
    p_company_id  INT,
    p_from        DATE DEFAULT NULL,
    p_to          DATE DEFAULT NULL
)
RETURNS TABLE(
    "TotalFacturas"      INT,
    "MontoTotal"         NUMERIC,
    "ClientesActivos"    INT,
    "CxCPendiente"       NUMERIC,
    "CxCVencida"         NUMERIC,
    "FacturasMes"        INT,
    "FacturasMesAnterior" INT,
    "PromedioFactura"    NUMERIC,
    "DiasPromCobro"      INT,
    "TopCliente"         VARCHAR,
    "TopClienteMonto"    NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now              TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_from             DATE;
    v_to               DATE;
    v_month_start      DATE := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC')::DATE;
    v_last_month_start DATE := (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month')::DATE;

    v_total_facturas      INT := 0;
    v_monto_total         NUMERIC := 0;
    v_clientes_activos    INT := 0;
    v_cxc_pendiente       NUMERIC := 0;
    v_cxc_vencida         NUMERIC := 0;
    v_facturas_mes        INT := 0;
    v_facturas_mes_ant    INT := 0;
    v_promedio_factura    NUMERIC := 0;
    v_dias_prom_cobro     INT := 0;
    v_top_cliente         VARCHAR := ''::VARCHAR;
    v_top_cliente_monto   NUMERIC := 0;
BEGIN
    v_from := COALESCE(p_from, (v_now - INTERVAL '365 days')::DATE);
    v_to   := COALESCE(p_to, v_now::DATE);

    -- Total facturas del periodo (canonico ar.ReceivableDocument)
    SELECT COUNT(*)::INT, COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_total_facturas, v_monto_total
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    -- Si no hay datos canonicos, intentar legacy via SalesDocument
    IF v_total_facturas = 0 THEN
        SELECT COUNT(*)::INT,
               COALESCE(SUM(COALESCE(s."TotalAmount", 0)), 0)
        INTO v_total_facturas, v_monto_total
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_from
          AND s."DocumentDate" <= v_to;
    END IF;

    -- Clientes activos (con documentos en periodo)
    SELECT COUNT(DISTINCT d."CustomerId")::INT
    INTO v_clientes_activos
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    IF v_clientes_activos = 0 THEN
        SELECT COUNT(DISTINCT s."CustomerCode")::INT
        INTO v_clientes_activos
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_from
          AND s."DocumentDate" <= v_to;
    END IF;

    -- CxC pendiente total (canonico)
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_cxc_pendiente
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" IN ('PENDING', 'PARTIAL');

    -- CxC vencida (DueDate < NOW)
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_cxc_vencida
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" IN ('PENDING', 'PARTIAL')
      AND d."DueDate" IS NOT NULL
      AND d."DueDate" < v_now::DATE;

    -- Facturas este mes (canonico)
    SELECT COUNT(*)::INT
    INTO v_facturas_mes
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_month_start;

    IF v_facturas_mes = 0 THEN
        SELECT COUNT(*)::INT
        INTO v_facturas_mes
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_month_start;
    END IF;

    -- Facturas mes anterior
    SELECT COUNT(*)::INT
    INTO v_facturas_mes_ant
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_last_month_start
      AND d."IssueDate" < v_month_start;

    IF v_facturas_mes_ant = 0 THEN
        SELECT COUNT(*)::INT
        INTO v_facturas_mes_ant
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_last_month_start
          AND s."DocumentDate" < v_month_start;
    END IF;

    -- Promedio por factura
    IF v_total_facturas > 0 THEN
        v_promedio_factura := ROUND(v_monto_total / v_total_facturas, 2);
    END IF;

    -- Dias promedio de cobro (canonico: diferencia entre IssueDate y ApplyDate de cobros)
    SELECT COALESCE(
        AVG(EXTRACT(DAY FROM (a."ApplyDate"::TIMESTAMP - d."IssueDate"::TIMESTAMP)))::INT,
        0
    )
    INTO v_dias_prom_cobro
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    WHERE d."CompanyId" = p_company_id
      AND a."ApplyDate" >= v_from;

    -- Top cliente por monto (canonico)
    SELECT c."CustomerName"::VARCHAR, COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_top_cliente, v_top_cliente_monto
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to
    GROUP BY c."CustomerName"
    ORDER BY SUM(d."TotalAmount") DESC
    LIMIT 1;

    -- Fallback legacy
    IF v_top_cliente IS NULL OR v_top_cliente = '' THEN
        SELECT COALESCE(s."CustomerName", s."CustomerCode")::VARCHAR,
               COALESCE(SUM(COALESCE(s."TotalAmount", 0)), 0)
        INTO v_top_cliente, v_top_cliente_monto
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_from
          AND s."DocumentDate" <= v_to
        GROUP BY COALESCE(s."CustomerName", s."CustomerCode")
        ORDER BY SUM(COALESCE(s."TotalAmount", 0)) DESC
        LIMIT 1;
    END IF;

    v_top_cliente := COALESCE(v_top_cliente, ''::VARCHAR);

    RETURN QUERY
    SELECT v_total_facturas, ROUND(v_monto_total, 2), v_clientes_activos,
           ROUND(v_cxc_pendiente, 2), ROUND(v_cxc_vencida, 2),
           v_facturas_mes, v_facturas_mes_ant, v_promedio_factura,
           v_dias_prom_cobro, v_top_cliente, ROUND(v_top_cliente_monto, 2);
END;
$$;

-- =============================================================================
--  usp_Sales_Analytics_ByMonth
--  Ventas agrupadas por mes con running total (acumulado)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_bymonth(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_bymonth(
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
        FROM ar."ReceivableDocument" d
        WHERE d."CompanyId" = p_company_id
          AND d."Status" <> 'VOIDED'
          AND d."IssueDate" >= (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL)::DATE
        GROUP BY DATE_TRUNC('month', d."IssueDate"::TIMESTAMP)
    ),
    legacy AS (
        SELECT DATE_TRUNC('month', s."DocumentDate") AS mes,
               COUNT(*)::INT AS cnt,
               COALESCE(SUM(COALESCE(s."TotalAmount", 0)), 0) AS total
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL)
        GROUP BY DATE_TRUNC('month', s."DocumentDate")
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
--  usp_Sales_Analytics_ByCustomer
--  Top clientes por monto de ventas
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_bycustomer(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_bycustomer(
    p_company_id  INT,
    p_top         INT DEFAULT 10,
    p_from        DATE DEFAULT NULL,
    p_to          DATE DEFAULT NULL
)
RETURNS TABLE(
    "CustomerCode" VARCHAR,
    "CustomerName" VARCHAR,
    "FacturasCount" INT,
    "Total"        NUMERIC,
    "Percentage"   NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_from        DATE;
    v_to          DATE;
    v_grand_total NUMERIC := 0;
BEGIN
    v_from := COALESCE(p_from, ((NOW() AT TIME ZONE 'UTC') - INTERVAL '365 days')::DATE);
    v_to   := COALESCE(p_to,   (NOW() AT TIME ZONE 'UTC')::DATE);

    -- Calcular gran total (canonico)
    SELECT COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_grand_total
    FROM ar."ReceivableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    IF v_grand_total > 0 THEN
        RETURN QUERY
        SELECT
            c."CustomerCode"::VARCHAR,
            c."CustomerName"::VARCHAR,
            COUNT(*)::INT                              AS "FacturasCount",
            ROUND(COALESCE(SUM(d."TotalAmount"), 0), 2) AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(d."TotalAmount") * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                        AS "Percentage"
        FROM ar."ReceivableDocument" d
        INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
        WHERE d."CompanyId" = p_company_id
          AND d."Status" <> 'VOIDED'
          AND d."IssueDate" >= v_from
          AND d."IssueDate" <= v_to
        GROUP BY c."CustomerCode", c."CustomerName"
        ORDER BY SUM(d."TotalAmount") DESC
        LIMIT p_top;
    ELSE
        -- Fallback legacy
        SELECT COALESCE(SUM(COALESCE(s."TotalAmount", 0)), 0)
        INTO v_grand_total
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_from
          AND s."DocumentDate" <= v_to;

        RETURN QUERY
        SELECT
            COALESCE(s."CustomerCode", '')::VARCHAR         AS "CustomerCode",
            COALESCE(s."CustomerName", s."CustomerCode")::VARCHAR AS "CustomerName",
            COUNT(*)::INT                                    AS "FacturasCount",
            ROUND(COALESCE(SUM(COALESCE(s."TotalAmount", 0)), 0), 2) AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(COALESCE(s."TotalAmount", 0)) * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                              AS "Percentage"
        FROM ar."SalesDocument" s
        WHERE COALESCE(s."IsVoided", FALSE) = FALSE
          AND s."OperationType" = 'FACT'
          AND s."DocumentDate" >= v_from
          AND s."DocumentDate" <= v_to
        GROUP BY s."CustomerCode", s."CustomerName"
        ORDER BY SUM(COALESCE(s."TotalAmount", 0)) DESC
        LIMIT p_top;
    END IF;
END;
$$;

-- =============================================================================
--  usp_Sales_Analytics_AgingAR
--  Aging de CxC en 5 buckets: 0-30, 31-60, 61-90, 91-120, 120+ dias
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_agingar(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_agingar(
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
    -- Gran total CxC pendiente
    SELECT COALESCE(SUM(d."PendingAmount"), 0)
    INTO v_grand_total
    FROM ar."ReceivableDocument" d
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
        FROM ar."ReceivableDocument" d
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
--  usp_Sales_Analytics_CollectionForecast
--  Proyeccion de cobros proximos meses (basado en DueDate de documentos pendientes)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_collectionforecast(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_collectionforecast(
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
        COUNT(d."ReceivableDocumentId")::INT                         AS "DocumentCount"
    FROM months m
    LEFT JOIN ar."ReceivableDocument" d
        ON  d."CompanyId" = p_company_id
        AND d."Status" IN ('PENDING', 'PARTIAL')
        AND d."DueDate" IS NOT NULL
        AND DATE_TRUNC('month', d."DueDate"::TIMESTAMP) = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;

-- =============================================================================
--  usp_Sales_Analytics_ByProduct
--  Top productos mas vendidos (cantidad y monto)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_sales_analytics_byproduct(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_sales_analytics_byproduct(
    p_company_id  INT,
    p_top         INT DEFAULT 10,
    p_from        DATE DEFAULT NULL,
    p_to          DATE DEFAULT NULL
)
RETURNS TABLE(
    "ProductCode"  VARCHAR,
    "ProductName"  VARCHAR,
    "Quantity"     NUMERIC,
    "Total"        NUMERIC,
    "Percentage"   NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_from        DATE;
    v_to          DATE;
    v_grand_total NUMERIC := 0;
BEGIN
    v_from := COALESCE(p_from, ((NOW() AT TIME ZONE 'UTC') - INTERVAL '365 days')::DATE);
    v_to   := COALESCE(p_to,   (NOW() AT TIME ZONE 'UTC')::DATE);

    -- Gran total de ventas del periodo (via SalesDocumentLine + SalesDocument)
    SELECT COALESCE(SUM(COALESCE(l."TotalAmount", 0)), 0)
    INTO v_grand_total
    FROM ar."SalesDocumentLine" l
    INNER JOIN ar."SalesDocument" d
        ON  d."DocumentNumber" = l."DocumentNumber"
        AND d."SerialType" = l."SerialType"
        AND d."OperationType" = l."OperationType"
    WHERE COALESCE(d."IsVoided", FALSE) = FALSE
      AND d."OperationType" = 'FACT'
      AND d."DocumentDate" >= v_from
      AND d."DocumentDate" <= v_to
      AND COALESCE(l."IsVoided", FALSE) = FALSE;

    IF v_grand_total > 0 THEN
        RETURN QUERY
        SELECT
            COALESCE(l."ProductCode", '')::VARCHAR                  AS "ProductCode",
            COALESCE(l."Description", l."ProductCode")::VARCHAR     AS "ProductName",
            ROUND(COALESCE(SUM(l."Quantity"), 0), 2)                AS "Quantity",
            ROUND(COALESCE(SUM(l."TotalAmount"), 0), 2)             AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(COALESCE(l."TotalAmount", 0)) * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                                      AS "Percentage"
        FROM ar."SalesDocumentLine" l
        INNER JOIN ar."SalesDocument" d
            ON  d."DocumentNumber" = l."DocumentNumber"
            AND d."SerialType" = l."SerialType"
            AND d."OperationType" = l."OperationType"
        WHERE COALESCE(d."IsVoided", FALSE) = FALSE
          AND d."OperationType" = 'FACT'
          AND d."DocumentDate" >= v_from
          AND d."DocumentDate" <= v_to
          AND COALESCE(l."IsVoided", FALSE) = FALSE
        GROUP BY l."ProductCode", l."Description"
        ORDER BY SUM(COALESCE(l."TotalAmount", 0)) DESC
        LIMIT p_top;
    ELSE
        -- Return empty set
        RETURN;
    END IF;
END;
$$;
