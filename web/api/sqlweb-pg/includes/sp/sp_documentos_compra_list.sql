-- =============================================
-- Funcion: Listar Documentos de Compra
-- Compatible con: PostgreSQL 14+
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS sp_documentoscompra_list(VARCHAR(20), VARCHAR(100), VARCHAR(60), DATE, DATE, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_documentoscompra_list(
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_search         VARCHAR(100) DEFAULT NULL,
    p_cod_proveedor  VARCHAR(60) DEFAULT NULL,
    p_desde          DATE DEFAULT NULL,
    p_hasta          DATE DEFAULT NULL,
    p_anulada        BOOLEAN DEFAULT NULL,
    p_page           INT DEFAULT 1,
    p_limit          INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"       BIGINT,
    "ID"               INT,
    "NUM_DOC"          VARCHAR,
    "SERIALTIPO"       VARCHAR,
    "TIPO_OPERACION"   VARCHAR,
    "COD_PROVEEDOR"    VARCHAR,
    "NOMBRE"           VARCHAR,
    "RIF"              VARCHAR,
    "FECHA"            TIMESTAMP,
    "FECHA_VENCE"      TIMESTAMP,
    "FECHA_RECIBO"     TIMESTAMP,
    "HORA"             VARCHAR,
    "SUBTOTAL"         DOUBLE PRECISION,
    "MONTO_GRA"        DOUBLE PRECISION,
    "MONTO_EXE"        DOUBLE PRECISION,
    "EXENTO"           DOUBLE PRECISION,
    "IVA"              DOUBLE PRECISION,
    "ALICUOTA"         DOUBLE PRECISION,
    "TOTAL"            DOUBLE PRECISION,
    "ANULADA"          INT,
    "CANCELADA"        VARCHAR,
    "RECIBIDA"         VARCHAR,
    "DOC_ORIGEN"       VARCHAR,
    "NUM_CONTROL"      VARCHAR,
    "LEGAL"            INT,
    "CONCEPTO"         VARCHAR,
    "OBSERV"           VARCHAR,
    "ALMACEN"          VARCHAR,
    "IVA_RETENIDO"     DOUBLE PRECISION,
    "ISLR"             VARCHAR,
    "MONTO_ISLR"       DOUBLE PRECISION,
    "COD_USUARIO"      VARCHAR,
    "FECHA_REPORTE"    TIMESTAMP,
    "ESTADO"           TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM "DocumentosCompra"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_DOC" LIKE '%' || p_search || '%'
           OR "NOMBRE" LIKE '%' || p_search || '%'
           OR "RIF" LIKE '%' || p_search || '%'
           OR "COD_PROVEEDOR" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR "COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR ("ANULADA" = 1) = p_anulada);

    -- Devolver resultados paginados
    RETURN QUERY
    SELECT
        v_total,
        d."ID", d."NUM_DOC", d."SERIALTIPO", d."TIPO_OPERACION",
        d."COD_PROVEEDOR", d."NOMBRE", d."RIF",
        d."FECHA", d."FECHA_VENCE", d."FECHA_RECIBO", d."HORA",
        d."SUBTOTAL", d."MONTO_GRA", d."MONTO_EXE", d."EXENTO",
        d."IVA", d."ALICUOTA", d."TOTAL",
        d."ANULADA", d."CANCELADA", d."RECIBIDA",
        d."DOC_ORIGEN", d."NUM_CONTROL", d."LEGAL",
        d."CONCEPTO", d."OBSERV", d."ALMACEN",
        d."IVA_RETENIDO", d."ISLR", d."MONTO_ISLR",
        d."COD_USUARIO", d."FECHA_REPORTE",
        CASE
            WHEN d."ANULADA" = 1 THEN 'ANULADO'
            WHEN d."CANCELADA" = 'S' THEN 'PAGADO'
            WHEN d."RECIBIDA" = 'S' THEN 'RECIBIDO'
            ELSE 'PENDIENTE'
        END::TEXT
    FROM "DocumentosCompra" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_DOC" LIKE '%' || p_search || '%'
           OR d."NOMBRE" LIKE '%' || p_search || '%'
           OR d."RIF" LIKE '%' || p_search || '%'
           OR d."COD_PROVEEDOR" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR d."COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR (d."ANULADA" = 1) = p_anulada)
    ORDER BY d."FECHA" DESC, d."ID" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get documento especifico con detalle ----------
DROP FUNCTION IF EXISTS sp_documentoscompra_get(VARCHAR(60), VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION sp_documentoscompra_get(
    p_num_doc        VARCHAR(60),
    p_tipo_operacion VARCHAR(20)
)
RETURNS TABLE (
    "result_set" INT,
    "data"       JSONB
) LANGUAGE plpgsql AS $$
BEGIN
    -- Cabecera (result_set = 1)
    RETURN QUERY
    SELECT 1,
           ROW_TO_JSON(d)::JSONB
    FROM "DocumentosCompra" d
    WHERE d."NUM_DOC" = p_num_doc AND d."TIPO_OPERACION" = p_tipo_operacion;

    -- Detalle (result_set = 2)
    RETURN QUERY
    SELECT 2,
           ROW_TO_JSON(dd)::JSONB
    FROM "DocumentosCompraDetalle" dd
    WHERE dd."NUM_DOC" = p_num_doc AND dd."TIPO_OPERACION" = p_tipo_operacion
    ORDER BY dd."RENGLON";

    -- Pagos (result_set = 3)
    RETURN QUERY
    SELECT 3,
           ROW_TO_JSON(dp)::JSONB
    FROM "DocumentosCompraPago" dp
    WHERE dp."NUM_DOC" = p_num_doc AND dp."TIPO_OPERACION" = p_tipo_operacion;
END;
$$;
