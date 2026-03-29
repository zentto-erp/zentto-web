-- =============================================
-- Funcion: Anular Documento de Compra (Unificado)
-- Maneja: ORDEN, COMPRA
-- Traducido de SQL Server a PostgreSQL
-- DEPRECATED: Usa tablas legacy
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_documento_compra_tx(VARCHAR(60), VARCHAR(20), VARCHAR(60), VARCHAR(500), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_documento_compra_tx(
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
BEGIN
    -- Verificar existencia
    -- TODO: tabla DocumentosCompra es legacy
    SELECT "ANULADA"::BOOLEAN
    INTO v_ya_anulado
    FROM "DocumentosCompra"
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF v_ya_anulado = TRUE THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    -- Validaciones especificas
    IF p_tipo_operacion = 'ORDEN' AND EXISTS (
        SELECT 1 FROM "DocumentosCompra"
        WHERE "DOC_ORIGEN" = p_num_doc AND "TIPO_OPERACION" = 'COMPRA' AND "ANULADA" = FALSE
    ) THEN
        RAISE EXCEPTION 'orden_tiene_compra_asociada';
    END IF;

    -- Cargar detalle para reversion de inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_compra (
        "COD_SERV" VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION,
        "PRECIO"   DOUBLE PRECISION
    ) ON COMMIT DROP;

    DELETE FROM _detalles_compra;

    IF p_revertir_inventario = TRUE AND p_tipo_operacion = 'COMPRA' THEN
        INSERT INTO _detalles_compra
        SELECT "COD_SERV", COALESCE("CANTIDAD", 0), COALESCE("PRECIO", COALESCE("COSTO", 0))
        FROM "DocumentosCompraDetalle"
        WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion AND COALESCE("ANULADA"::INT, 0) = 0;
    END IF;

    -- Marcar como anulado
    UPDATE "DocumentosCompra" SET
        "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV",''::VARCHAR) || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || COALESCE(' - ' || p_motivo,''::VARCHAR) || ']'
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Anular detalle
    UPDATE "DocumentosCompraDetalle" SET "ANULADA" = TRUE
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Reversar inventario en master.Product si era compra
    IF p_revertir_inventario = TRUE AND p_tipo_operacion = 'COMPRA' THEN
        -- Restar inventario
        WITH "Totales" AS (
            SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
            FROM _detalles_compra
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        )
        UPDATE master."Product" i
        SET "StockQty" = COALESCE(i."StockQty", 0) - t."TOTAL"
        FROM "Totales" t
        WHERE t."COD_SERV" = i."ProductCode";

        -- Registrar movimiento de reversion
        INSERT INTO "MovInvent" ("CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA")
        SELECT d."COD_SERV", d."COD_SERV", p_num_doc || '_ANUL', v_fecha_anulacion,
            'Anulacion COMPRA:' || p_num_doc, 'Egreso',
            COALESCE(i."StockQty", 0) + d."CANTIDAD",
            d."CANTIDAD",
            COALESCE(i."StockQty", 0),
            p_cod_usuario,
            COALESCE(d."PRECIO", 0),
            0,
            COALESCE(i."SalesPrice", 0)
        FROM _detalles_compra d
        INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;
    END IF;

    -- Reversar CxP si era compra
    IF p_tipo_operacion = 'COMPRA' THEN
        UPDATE "P_Pagar" SET
            "ANULADA" = TRUE,
            "SALDO" = 0,
            "OBSERVACION" = COALESCE("OBSERVACION",''::VARCHAR) || ' [ANULADO]'
        WHERE "FACTURA" = p_num_doc AND "ANULADA" = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_doc, p_tipo_operacion, 'Documento anulado'::VARCHAR, p_revertir_inventario;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
