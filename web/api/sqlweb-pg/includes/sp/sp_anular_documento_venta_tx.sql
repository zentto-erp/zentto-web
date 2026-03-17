-- =============================================
-- Funcion: Anular Documento de Venta (Unificado)
-- Maneja: FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
-- Traducido de SQL Server a PostgreSQL
-- DEPRECATED: Usa tablas legacy
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_documento_venta_tx(VARCHAR(60), VARCHAR(20), VARCHAR(60), VARCHAR(500), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_documento_venta_tx(
    p_num_doc             VARCHAR(60),
    p_tipo_operacion      VARCHAR(20),
    p_cod_usuario         VARCHAR(60) DEFAULT 'API',
    p_motivo              VARCHAR(500) DEFAULT '',
    p_revertir_inventario BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "ok"                  BOOLEAN,
    "numDoc"              VARCHAR,
    "tipoOperacion"       VARCHAR,
    "mensaje"             VARCHAR,
    "inventarioRevertido" BOOLEAN
) LANGUAGE plpgsql AS $$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_ya_anulado      BOOLEAN;
    v_fecha_doc       TIMESTAMP;
BEGIN
    -- Verificar existencia
    -- TODO: tabla DocumentosVenta es legacy
    SELECT "ANULADA"::BOOLEAN, "FECHA"
    INTO v_ya_anulado, v_fecha_doc
    FROM "DocumentosVenta"
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF v_ya_anulado = TRUE THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    -- Validaciones especificas por tipo
    IF p_tipo_operacion = 'PEDIDO' AND EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "DOC_ORIGEN" = p_num_doc AND "ANULADA" = FALSE) THEN
        RAISE EXCEPTION 'pedido_tiene_factura_asociada';
    END IF;

    -- Cargar detalle para reversion de inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_venta (
        "COD_SERV" VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION,
        "PRECIO"   DOUBLE PRECISION,
        "ALICUOTA" DOUBLE PRECISION
    ) ON COMMIT DROP;

    DELETE FROM _detalles_venta;

    IF p_revertir_inventario = TRUE AND p_tipo_operacion IN ('PEDIDO', 'NOTA_ENTREGA') THEN
        INSERT INTO _detalles_venta
        SELECT "COD_SERV", COALESCE("CANTIDAD", 0), COALESCE("PRECIO", 0), COALESCE("ALICUOTA", 0)
        FROM "DocumentosVentaDetalle"
        WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion AND COALESCE("ANULADA"::INT, 0) = 0;
    END IF;

    -- Marcar como anulado
    UPDATE "DocumentosVenta" SET
        "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || COALESCE(' - ' || p_motivo, '') || ']'
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Anular detalle
    UPDATE "DocumentosVentaDetalle" SET "ANULADA" = TRUE
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Reversar inventario en master.Product si aplica
    IF p_revertir_inventario = TRUE AND p_tipo_operacion IN ('PEDIDO', 'NOTA_ENTREGA') THEN
        -- Devolver inventario
        WITH "Totales" AS (
            SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
            FROM _detalles_venta
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        )
        UPDATE master."Product" i
        SET "StockQty" = COALESCE(i."StockQty", 0) + t."TOTAL"
        FROM "Totales" t
        WHERE t."COD_SERV" = i."ProductCode";

        -- Registrar movimiento de reversion
        INSERT INTO "MovInvent" ("CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA")
        SELECT d."COD_SERV", d."COD_SERV", p_num_doc || '_ANUL', v_fecha_anulacion,
            'Anulacion ' || p_tipo_operacion || ':' || p_num_doc, 'Ingreso',
            COALESCE(i."StockQty", 0) - d."CANTIDAD",
            d."CANTIDAD",
            COALESCE(i."StockQty", 0),
            p_cod_usuario,
            COALESCE(i."COSTO_REFERENCIA", 0),
            COALESCE(d."ALICUOTA", 0),
            COALESCE(d."PRECIO", 0)
        FROM _detalles_venta d
        INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;
    END IF;

    -- Reversar CxC si era factura
    IF p_tipo_operacion = 'FACT' THEN
        UPDATE "P_Cobrar" SET
            "ANULADA" = TRUE,
            "SALDO" = 0,
            "OBSERVACION" = COALESCE("OBSERVACION", '') || ' [ANULADO]'
        WHERE "FACTURA" = p_num_doc AND "ANULADA" = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_doc, p_tipo_operacion, 'Documento anulado'::VARCHAR, p_revertir_inventario;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
