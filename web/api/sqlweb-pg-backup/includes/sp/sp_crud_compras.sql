-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_compras.sql
-- Compras: List + Get (emitir usa sp_emitir_compra_tx)
-- Tabla: public."Compras"
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_compras_list(VARCHAR(100), VARCHAR(10), VARCHAR(50), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_compras_list(
    p_search      VARCHAR(100) DEFAULT NULL,
    p_proveedor   VARCHAR(10)  DEFAULT NULL,
    p_estado      VARCHAR(50)  DEFAULT NULL,
    p_fecha_desde DATE         DEFAULT NULL,
    p_fecha_hasta DATE         DEFAULT NULL,
    p_page        INT          DEFAULT 1,
    p_limit       INT          DEFAULT 50
)
RETURNS TABLE(
    "NUM_FACT"      VARCHAR(25),
    "FECHA"         DATE,
    "COD_PROVEEDOR" VARCHAR(10),
    "NOMBRE"        VARCHAR(255),
    "RIF"           VARCHAR(20),
    "TIPO"          VARCHAR(50),
    "MONTO"         NUMERIC,
    "IVA"           NUMERIC,
    "TOTAL"         NUMERIC,
    "TotalCount"    INT
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
    FROM public."Compras" co
    WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        co."NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR",
        co."NOMBRE",
        co."RIF",
        co."TIPO",
        co."MONTO",
        co."IVA",
        co."TOTAL",
        v_total AS "TotalCount"
    FROM public."Compras" co
    WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta)
    ORDER BY co."FECHA" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by NUM_FACT ----------
DROP FUNCTION IF EXISTS usp_compras_getbynumfact(VARCHAR(25)) CASCADE;
CREATE OR REPLACE FUNCTION usp_compras_getbynumfact(
    p_num_fact VARCHAR(25)
)
RETURNS TABLE(
    "NUM_FACT"      VARCHAR(25),
    "FECHA"         DATE,
    "COD_PROVEEDOR" VARCHAR(10),
    "NOMBRE"        VARCHAR(255),
    "RIF"           VARCHAR(20),
    "TIPO"          VARCHAR(50),
    "MONTO"         NUMERIC,
    "IVA"           NUMERIC,
    "TOTAL"         NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        co."NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR",
        co."NOMBRE",
        co."RIF",
        co."TIPO",
        co."MONTO",
        co."IVA",
        co."TOTAL"
    FROM public."Compras" co
    WHERE co."NUM_FACT" = p_num_fact;
END;
$$;
