-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_cotizacion.sql
-- Cotizacion: List + Get
-- Tabla: public."Cotizacion"
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_cotizacion_list(VARCHAR(100), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_cotizacion_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_codigo VARCHAR(10)  DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "NUM_FACT" VARCHAR(20),
    "FECHA"    DATE,
    "CODIGO"   VARCHAR(10),
    "NOMBRE"   VARCHAR(255),
    "RIF"      VARCHAR(20),
    "MONTO"    NUMERIC,
    "IVA"      NUMERIC,
    "TOTAL"    NUMERIC,
    "TotalCount" INT
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
    FROM public."Cotizacion" ct
    WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        ct."NUM_FACT",
        ct."FECHA",
        ct."CODIGO",
        ct."NOMBRE",
        ct."RIF",
        ct."MONTO",
        ct."IVA",
        ct."TOTAL",
        v_total AS "TotalCount"
    FROM public."Cotizacion" ct
    WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo)
    ORDER BY ct."FECHA" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by NUM_FACT ----------
DROP FUNCTION IF EXISTS usp_cotizacion_getbynumfact(VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_cotizacion_getbynumfact(
    p_num_fact VARCHAR(20)
)
RETURNS TABLE(
    "NUM_FACT" VARCHAR(20),
    "FECHA"    DATE,
    "CODIGO"   VARCHAR(10),
    "NOMBRE"   VARCHAR(255),
    "RIF"      VARCHAR(20),
    "MONTO"    NUMERIC,
    "IVA"      NUMERIC,
    "TOTAL"    NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        ct."NUM_FACT",
        ct."FECHA",
        ct."CODIGO",
        ct."NOMBRE",
        ct."RIF",
        ct."MONTO",
        ct."IVA",
        ct."TOTAL"
    FROM public."Cotizacion" ct
    WHERE ct."NUM_FACT" = p_num_fact;
END;
$$;
