-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_pedidos.sql
-- Pedidos (List + Get). PK: NUM_FACT VARCHAR(20)
-- ============================================================

-- LIST
DROP FUNCTION IF EXISTS usp_pedidos_list(VARCHAR(100), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pedidos_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_codigo VARCHAR(10) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "NUM_FACT" VARCHAR(20),
    "CODIGO" VARCHAR(10),
    "NOMBRE" VARCHAR(255),
    "RIF" VARCHAR(20),
    "FECHA" TIMESTAMP,
    "SUBTOTAL" NUMERIC,
    "IMPUESTO" NUMERIC,
    "TOTAL" NUMERIC,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Pedidos" p
    WHERE (v_search_param IS NULL
           OR p."NUM_FACT" LIKE v_search_param
           OR p."NOMBRE" LIKE v_search_param
           OR p."RIF" LIKE v_search_param)
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo);

    RETURN QUERY
    SELECT
        p."NUM_FACT",
        p."CODIGO",
        p."NOMBRE",
        p."RIF",
        p."FECHA",
        p."SUBTOTAL",
        p."IMPUESTO",
        p."TOTAL",
        v_total AS "TotalCount"
    FROM public."Pedidos" p
    WHERE (v_search_param IS NULL
           OR p."NUM_FACT" LIKE v_search_param
           OR p."NOMBRE" LIKE v_search_param
           OR p."RIF" LIKE v_search_param)
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo)
    ORDER BY p."FECHA" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY NUM_FACT
DROP FUNCTION IF EXISTS usp_pedidos_getbynumfact(VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pedidos_getbynumfact(
    p_num_fact VARCHAR(20)
)
RETURNS TABLE(
    "NUM_FACT" VARCHAR(20),
    "CODIGO" VARCHAR(10),
    "NOMBRE" VARCHAR(255),
    "RIF" VARCHAR(20),
    "FECHA" TIMESTAMP,
    "SUBTOTAL" NUMERIC,
    "IMPUESTO" NUMERIC,
    "TOTAL" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."NUM_FACT",
        p."CODIGO",
        p."NOMBRE",
        p."RIF",
        p."FECHA",
        p."SUBTOTAL",
        p."IMPUESTO",
        p."TOTAL"
    FROM public."Pedidos" p
    WHERE p."NUM_FACT" = p_num_fact;
END;
$$;
