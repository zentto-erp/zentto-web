-- +goose Up
-- +goose StatementBegin

-- ============================================================================
-- Migration 00049: Fix compras (purchases) module functions
--
-- Problems fixed:
--   1. Analytics functions reference "Compras" table → should be "DocumentosCompra"
--   2. Analytics KPIs references "P_Pagar" table → doesn't exist, remove fallback
--   3. usp_compras_list references "Compras" with columns NUM_FACT/TIPO/MONTO
--      → should be "DocumentosCompra" with NUM_DOC/TIPO_OPERACION/SUBTOTAL
--   4. usp_compras_getbynumfact same issue as above
--   5. zsys."StudioAddon" and zsys."StudioAddonModule" tables don't exist
--      → CREATE them so studio addon functions work
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Create missing zsys tables for Studio Addons
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS zsys."StudioAddon" (
    "AddonId"     VARCHAR(100) NOT NULL,
    "CompanyId"   INT          NOT NULL,
    "Title"       VARCHAR(200) NOT NULL,
    "Description" VARCHAR(500),
    "Icon"        VARCHAR(100),
    "Config"      TEXT         NOT NULL DEFAULT '{}',
    "IsActive"    BOOLEAN      NOT NULL DEFAULT TRUE,
    "CreatedBy"   INT          NOT NULL DEFAULT 0,
    "CreatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    PRIMARY KEY ("AddonId", "CompanyId")
);

CREATE TABLE IF NOT EXISTS zsys."StudioAddonModule" (
    "AddonId"  VARCHAR(100) NOT NULL,
    "ModuleId" VARCHAR(100) NOT NULL,
    PRIMARY KEY ("AddonId", "ModuleId")
);

-- Grant permissions to app user
GRANT SELECT, INSERT, UPDATE, DELETE ON zsys."StudioAddon" TO zentto_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON zsys."StudioAddonModule" TO zentto_app;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Fix usp_purchases_analytics_kpis — "Compras" → "DocumentosCompra",
--    remove P_Pagar fallback
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION usp_purchases_analytics_kpis(
    p_company_id INT,
    p_from       DATE DEFAULT NULL,
    p_to         DATE DEFAULT NULL
)
RETURNS TABLE(
    "TotalCompras"       INT,
    "MontoTotal"         NUMERIC,
    "ProveedoresActivos" INT,
    "CxPPendiente"       NUMERIC,
    "CxPVencida"         NUMERIC,
    "ComprasMes"         INT,
    "CompraMesAnterior"  INT,
    "PromedioCompra"     NUMERIC,
    "DiasPromPago"       INT,
    "TopProveedor"       VARCHAR,
    "TopProveedorMonto"  NUMERIC
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

    -- Total compras del periodo (canonico)
    SELECT COUNT(*)::INT, COALESCE(SUM(d."TotalAmount"), 0)
    INTO v_total_compras, v_monto_total
    FROM ap."PayableDocument" d
    WHERE d."CompanyId" = p_company_id
      AND d."Status" <> 'VOIDED'
      AND d."IssueDate" >= v_from
      AND d."IssueDate" <= v_to;

    -- Si no hay datos canonicos, intentar legacy (DocumentosCompra)
    IF v_total_compras = 0 THEN
        SELECT COUNT(*)::INT,
               COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0)
        INTO v_total_compras, v_monto_total
        FROM "DocumentosCompra" c
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
        FROM "DocumentosCompra" c
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
        FROM "DocumentosCompra" c
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
        FROM "DocumentosCompra" c
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

    -- Fallback legacy (DocumentosCompra)
    IF v_top_proveedor IS NULL OR v_top_proveedor = '' THEN
        SELECT COALESCE(c."NOMBRE", c."COD_PROVEEDOR")::VARCHAR,
               COALESCE(SUM(COALESCE(c."TOTAL", 0)), 0)
        INTO v_top_proveedor, v_top_proveedor_monto
        FROM "DocumentosCompra" c
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

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Fix usp_purchases_analytics_bymonth — "Compras" → "DocumentosCompra"
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION usp_purchases_analytics_bymonth(
    p_company_id INT,
    p_months     INT DEFAULT 12
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
               COALESCE(SUM(COALESCE(c."TOTAL", 0)::NUMERIC), 0::NUMERIC) AS total
        FROM "DocumentosCompra" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= (DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - ((p_months - 1) || ' months')::INTERVAL)
        GROUP BY DATE_TRUNC('month', c."FECHA")
    ),
    combined AS (
        SELECT m.month_start,
               COALESCE(ca.cnt, 0) + COALESCE(lg.cnt, 0) AS cnt,
               (COALESCE(ca.total, 0::NUMERIC) + COALESCE(lg.total, 0::NUMERIC))::NUMERIC AS total
        FROM months m
        LEFT JOIN canonical ca ON ca.mes = m.month_start
        LEFT JOIN legacy lg ON lg.mes = m.month_start
    )
    SELECT
        TO_CHAR(cb.month_start, 'YYYY-MM')::VARCHAR AS "Month",
        cb.cnt                                       AS "Count",
        ROUND(cb.total::NUMERIC, 2)                  AS "Total",
        ROUND(SUM(cb.total::NUMERIC) OVER (ORDER BY cb.month_start), 2) AS "Accumulated"
    FROM combined cb
    ORDER BY cb.month_start;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Fix usp_purchases_analytics_bysupplier — "Compras" → "DocumentosCompra"
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION usp_purchases_analytics_bysupplier(
    p_company_id INT,
    p_top        INT  DEFAULT 10,
    p_from       DATE DEFAULT NULL,
    p_to         DATE DEFAULT NULL
)
RETURNS TABLE(
    "SupplierCode"  VARCHAR,
    "SupplierName"  VARCHAR,
    "ComprasCount"  INT,
    "Total"         NUMERIC,
    "Percentage"    NUMERIC
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
        -- Fallback legacy (DocumentosCompra)
        SELECT COALESCE(SUM(COALESCE(c."TOTAL", 0)::NUMERIC), 0::NUMERIC)
        INTO v_grand_total
        FROM "DocumentosCompra" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to;

        RETURN QUERY
        SELECT
            COALESCE(c."COD_PROVEEDOR", '')::VARCHAR     AS "SupplierCode",
            COALESCE(c."NOMBRE", c."COD_PROVEEDOR")::VARCHAR AS "SupplierName",
            COUNT(*)::INT                                 AS "ComprasCount",
            ROUND(COALESCE(SUM(COALESCE(c."TOTAL", 0)::NUMERIC), 0::NUMERIC), 2) AS "Total",
            CASE WHEN v_grand_total > 0
                 THEN ROUND(SUM(COALESCE(c."TOTAL", 0)::NUMERIC) * 100.0 / v_grand_total, 2)
                 ELSE 0::NUMERIC
            END                                           AS "Percentage"
        FROM "DocumentosCompra" c
        WHERE COALESCE(c."ANULADA"::TEXT, '0') NOT IN ('1', 'true')
          AND c."FECHA" >= v_from
          AND c."FECHA" <= v_to
        GROUP BY c."COD_PROVEEDOR", c."NOMBRE"
        ORDER BY SUM(COALESCE(c."TOTAL", 0)::NUMERIC) DESC
        LIMIT p_top;
    END IF;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Fix usp_compras_list — "Compras" → "DocumentosCompra",
--    NUM_FACT → NUM_DOC, TIPO → TIPO_OPERACION, MONTO → SUBTOTAL
-- ────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS usp_compras_list(VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT);

CREATE OR REPLACE FUNCTION usp_compras_list(
    p_search      VARCHAR DEFAULT NULL,
    p_proveedor   VARCHAR DEFAULT NULL,
    p_estado      VARCHAR DEFAULT NULL,
    p_fecha_desde DATE    DEFAULT NULL,
    p_fecha_hasta DATE    DEFAULT NULL,
    p_page        INT     DEFAULT 1,
    p_limit       INT     DEFAULT 50
)
RETURNS TABLE(
    "NUM_FACT"       VARCHAR,
    "FECHA"          DATE,
    "COD_PROVEEDOR"  VARCHAR,
    "NOMBRE"         VARCHAR,
    "RIF"            VARCHAR,
    "TIPO"           VARCHAR,
    "MONTO"          NUMERIC,
    "IVA"            NUMERIC,
    "TOTAL"          NUMERIC,
    "TotalCount"     INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM public."DocumentosCompra" co
    WHERE (v_search IS NULL OR (co."NUM_DOC" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO_OPERACION" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        co."NUM_DOC"::VARCHAR        AS "NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR"::VARCHAR,
        co."NOMBRE"::VARCHAR,
        co."RIF"::VARCHAR,
        co."TIPO_OPERACION"::VARCHAR AS "TIPO",
        co."SUBTOTAL"                AS "MONTO",
        co."IVA",
        co."TOTAL",
        v_total                      AS "TotalCount"
    FROM public."DocumentosCompra" co
    WHERE (v_search IS NULL OR (co."NUM_DOC" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO_OPERACION" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta)
    ORDER BY co."FECHA" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 6. Fix usp_compras_getbynumfact — "Compras" → "DocumentosCompra",
--    NUM_FACT → NUM_DOC, TIPO → TIPO_OPERACION, MONTO → SUBTOTAL
-- ────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS usp_compras_getbynumfact(VARCHAR);

CREATE OR REPLACE FUNCTION usp_compras_getbynumfact(
    p_num_fact VARCHAR
)
RETURNS TABLE(
    "NUM_FACT"       VARCHAR,
    "FECHA"          DATE,
    "COD_PROVEEDOR"  VARCHAR,
    "NOMBRE"         VARCHAR,
    "RIF"            VARCHAR,
    "TIPO"           VARCHAR,
    "MONTO"          NUMERIC,
    "IVA"            NUMERIC,
    "TOTAL"          NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        co."NUM_DOC"::VARCHAR        AS "NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR"::VARCHAR,
        co."NOMBRE"::VARCHAR,
        co."RIF"::VARCHAR,
        co."TIPO_OPERACION"::VARCHAR AS "TIPO",
        co."SUBTOTAL"                AS "MONTO",
        co."IVA",
        co."TOTAL"
    FROM public."DocumentosCompra" co
    WHERE co."NUM_DOC" = p_num_fact;
END;
$$;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

DROP TABLE IF EXISTS zsys."StudioAddonModule";
DROP TABLE IF EXISTS zsys."StudioAddon";

-- Revert functions to originals would require old definitions;
-- since these are bugfixes, down migration just drops the fixed versions
-- and they would need to be recreated from baseline.

-- +goose StatementEnd
