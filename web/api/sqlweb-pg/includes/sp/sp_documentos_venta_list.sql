-- =============================================
-- Funcion: Listar Documentos de Venta
-- Compatible con: PostgreSQL 14+
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION sp_documentosventa_list(
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_search         VARCHAR(100) DEFAULT NULL,
    p_codigo         VARCHAR(60) DEFAULT NULL,
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
    "CODIGO"           VARCHAR,
    "NOMBRE"           VARCHAR,
    "RIF"              VARCHAR,
    "FECHA"            TIMESTAMP,
    "FECHA_VENCE"      TIMESTAMP,
    "HORA"             VARCHAR,
    "SUBTOTAL"         DOUBLE PRECISION,
    "MONTO_GRA"        DOUBLE PRECISION,
    "MONTO_EXE"        DOUBLE PRECISION,
    "IVA"              DOUBLE PRECISION,
    "ALICUOTA"         DOUBLE PRECISION,
    "TOTAL"            DOUBLE PRECISION,
    "DESCUENTO"        DOUBLE PRECISION,
    "ANULADA"          INT,
    "CANCELADA"        VARCHAR,
    "FACTURADA"        VARCHAR,
    "ENTREGADA"        VARCHAR,
    "DOC_ORIGEN"       VARCHAR,
    "TIPO_DOC_ORIGEN"  VARCHAR,
    "NUM_CONTROL"      VARCHAR,
    "LEGAL"            INT,
    "OBSERV"           VARCHAR,
    "VENDEDOR"         VARCHAR,
    "MONEDA"           VARCHAR,
    "TASA_CAMBIO"      DOUBLE PRECISION,
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
    FROM "DocumentosVenta"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_DOC" LIKE '%' || p_search || '%'
           OR "NOMBRE" LIKE '%' || p_search || '%'
           OR "RIF" LIKE '%' || p_search || '%'
           OR "CODIGO" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR "CODIGO" = p_codigo)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR ("ANULADA" = 1) = p_anulada);

    -- Devolver resultados paginados
    RETURN QUERY
    SELECT
        v_total,
        d."ID", d."NUM_DOC", d."SERIALTIPO", d."TIPO_OPERACION", d."CODIGO", d."NOMBRE", d."RIF",
        d."FECHA", d."FECHA_VENCE", d."HORA",
        d."SUBTOTAL", d."MONTO_GRA", d."MONTO_EXE", d."IVA", d."ALICUOTA", d."TOTAL", d."DESCUENTO",
        d."ANULADA", d."CANCELADA", d."FACTURADA", d."ENTREGADA",
        d."DOC_ORIGEN", d."TIPO_DOC_ORIGEN", d."NUM_CONTROL", d."LEGAL",
        d."OBSERV", d."VENDEDOR", d."MONEDA", d."TASA_CAMBIO",
        d."COD_USUARIO", d."FECHA_REPORTE",
        CASE
            WHEN d."ANULADA" = 1 THEN 'ANULADO'
            WHEN d."CANCELADA" = 'S' THEN 'PAGADO'
            WHEN d."FACTURADA" = 'S' THEN 'FACTURADO'
            ELSE 'PENDIENTE'
        END::TEXT
    FROM "DocumentosVenta" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_DOC" LIKE '%' || p_search || '%'
           OR d."NOMBRE" LIKE '%' || p_search || '%'
           OR d."RIF" LIKE '%' || p_search || '%'
           OR d."CODIGO" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR d."CODIGO" = p_codigo)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR (d."ANULADA" = 1) = p_anulada)
    ORDER BY d."FECHA" DESC, d."ID" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get documento especifico con detalle ----------
CREATE OR REPLACE FUNCTION sp_documentosventa_get(
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
    FROM "DocumentosVenta" d
    WHERE d."NUM_DOC" = p_num_doc AND d."TIPO_OPERACION" = p_tipo_operacion;

    -- Detalle (result_set = 2)
    RETURN QUERY
    SELECT 2,
           ROW_TO_JSON(dd)::JSONB
    FROM "DocumentosVentaDetalle" dd
    WHERE dd."NUM_DOC" = p_num_doc AND dd."TIPO_OPERACION" = p_tipo_operacion
    ORDER BY dd."RENGLON";

    -- Pagos (result_set = 3)
    RETURN QUERY
    SELECT 3,
           ROW_TO_JSON(dp)::JSONB
    FROM "DocumentosVentaPago" dp
    WHERE dp."NUM_DOC" = p_num_doc AND dp."TIPO_OPERACION" = p_tipo_operacion;
END;
$$;

-- ---------- 3. Tipos de operacion disponibles ----------
CREATE OR REPLACE FUNCTION sp_documentosventa_tipos()
RETURNS TABLE (
    "codigo"   VARCHAR,
    "nombre"   TEXT,
    "cantidad" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."TIPO_OPERACION" AS "codigo",
        CASE d."TIPO_OPERACION"
            WHEN 'FACT' THEN 'Factura'
            WHEN 'PRESUP' THEN 'Presupuesto'
            WHEN 'PEDIDO' THEN 'Pedido'
            WHEN 'COTIZ' THEN 'Cotizacion'
            WHEN 'NOTACRED' THEN 'Nota de Credito'
            WHEN 'NOTADEB' THEN 'Nota de Debito'
            WHEN 'NOTA_ENTREGA' THEN 'Nota de Entrega'
            ELSE d."TIPO_OPERACION"
        END::TEXT AS "nombre",
        COUNT(*)
    FROM "DocumentosVenta" d
    WHERE d."ANULADA" = 0
    GROUP BY d."TIPO_OPERACION"
    ORDER BY d."TIPO_OPERACION";
END;
$$;
