-- =============================================
-- Funcion: Emitir Compra (Compras) - PostgreSQL
-- Descripcion: Emite una compra con inventario y CxP
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DROP FUNCTION IF EXISTS sp_emitir_compra_tx(JSONB, JSONB, BOOLEAN, BOOLEAN, BOOLEAN);

CREATE OR REPLACE FUNCTION sp_emitir_compra_tx(
    p_compra_json   JSONB,
    p_detalle_json  JSONB,
    p_actualizar_inventario      BOOLEAN DEFAULT TRUE,
    p_generar_cxp                BOOLEAN DEFAULT TRUE,
    p_actualizar_saldos_proveedor BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "ok"               BOOLEAN,
    "numFact"          VARCHAR(60),
    "detalleRows"      INT,
    "inventoryUpdated" BOOLEAN,
    "cxpGenerated"     BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    v_num_fact        VARCHAR(60);
    v_cod_proveedor   VARCHAR(60);
    v_fecha           TIMESTAMP;
    v_total           NUMERIC(18,4);
    v_cod_usuario     VARCHAR(60);
    v_tipo            VARCHAR(30);
    v_nombre          VARCHAR(200);
    v_rif             VARCHAR(50);
    v_concepto        VARCHAR(500);
    v_detalle_rows    INT;
    v_saldo_previo    DOUBLE PRECISION;
    v_saldo_total     DOUBLE PRECISION;
BEGIN
    -- Extraer datos de la compra
    v_num_fact      := NULLIF(TRIM(p_compra_json->>'NUM_FACT'), ''::VARCHAR);
    v_cod_proveedor := NULLIF(TRIM(p_compra_json->>'COD_PROVEEDOR'), ''::VARCHAR);
    v_cod_usuario   := COALESCE(NULLIF(TRIM(p_compra_json->>'COD_USUARIO'), ''::VARCHAR), 'API');
    v_tipo          := UPPER(COALESCE(NULLIF(TRIM(p_compra_json->>'TIPO'), ''::VARCHAR), 'CONTADO'));
    v_nombre        := COALESCE(NULLIF(TRIM(p_compra_json->>'NOMBRE'), ''::VARCHAR),''::VARCHAR);
    v_rif           := COALESCE(NULLIF(TRIM(p_compra_json->>'RIF'), ''::VARCHAR),''::VARCHAR);
    v_concepto      := NULLIF(TRIM(p_compra_json->>'CONCEPTO'), ''::VARCHAR);

    BEGIN
        v_fecha := (p_compra_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    v_total := COALESCE((p_compra_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Verificar que la compra no existe (tabla legacy "Compras")
    IF EXISTS (SELECT 1 FROM "Compras" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'compra_already_exists';
    END IF;

    -- 1. Insertar cabecera en Compras (legacy)
    INSERT INTO "Compras" (
        "NUM_FACT", "COD_PROVEEDOR", "FECHA", "NOMBRE", "RIF", "TOTAL",
        "TIPO", "CONCEPTO", "COD_USUARIO", "ANULADA", "FECHARECIBO"
    )
    VALUES (
        v_num_fact, v_cod_proveedor, v_fecha, v_nombre, v_rif, v_total,
        v_tipo, v_concepto, v_cod_usuario, 0, v_fecha
    );

    -- 2. Insertar detalle en Detalle_Compras (legacy)
    INSERT INTO "Detalle_Compras" (
        "NUM_FACT", "CODIGO", "Referencia", "DESCRIPCION", "FECHA", "CANTIDAD",
        "PRECIO_COSTO", "Alicuota", "Co_Usuario"
    )
    SELECT
        v_num_fact,
        NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR),
        NULLIF(TRIM(d->>'REFERENCIA'), ''::VARCHAR),
        NULLIF(TRIM(d->>'DESCRIPCION'), ''::VARCHAR),
        v_fecha,
        COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
        COALESCE((d->>'PRECIO_COSTO')::NUMERIC(18,4), 0),
        COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
        v_cod_usuario
    FROM jsonb_array_elements(p_detalle_json) AS d;

    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Actualizar master."Product" — Ingreso
    IF p_actualizar_inventario THEN
        -- Insertar en MovInvent (historial)
        INSERT INTO "MovInvent" (
            "DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA"
        )
        SELECT
            v_num_fact,
            NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR),
            NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR),
            v_fecha,
            'Compra:' || v_num_fact,
            'Ingreso',
            COALESCE(inv."StockQty", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(inv."StockQty", 0) + COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            v_cod_usuario,
            COALESCE((d->>'PRECIO_COSTO')::NUMERIC(18,4), 0),
            COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
            COALESCE(inv."SalesPrice", 0)
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" inv ON inv."ProductCode" = NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR)
        WHERE NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR) IS NOT NULL
          AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        -- Actualizar existencias
        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) + agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR) AS cod_serv,
                     SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR) IS NOT NULL
               GROUP BY NULLIF(TRIM(d->>'CODIGO'), ''::VARCHAR)
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;
    END IF;

    -- 4. Generar CxP (si es credito) — tabla legacy "P_Pagar"
    IF p_generar_cxp AND v_tipo = 'CREDITO' AND v_total > 0 THEN
        -- Obtener saldo previo del proveedor
        SELECT COALESCE("SALDO", 0) INTO v_saldo_previo
          FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor
         ORDER BY "FECHA" DESC
         LIMIT 1;
        v_saldo_previo := COALESCE(v_saldo_previo, 0);

        -- Eliminar CxP previa del documento
        DELETE FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor
           AND "DOCUMENTO" = v_num_fact
           AND "TIPO" = 'FACT';

        -- Insertar nueva CxP
        INSERT INTO "P_Pagar" (
            "CODIGO", "FECHA", "DOCUMENTO", "TIPO", "DEBE", "HABER", "PEND", "SALDO", "ISRL", "OBS"
        )
        VALUES (
            v_cod_proveedor, v_fecha, v_num_fact, 'FACT', 0, v_total::DOUBLE PRECISION,
            v_total::DOUBLE PRECISION, v_saldo_previo + v_total::DOUBLE PRECISION, '', ''
        );
    END IF;

    -- 5. Actualizar saldos del proveedor en master."Supplier"
    IF p_actualizar_saldos_proveedor AND v_cod_proveedor IS NOT NULL AND TRIM(v_cod_proveedor) <> '' THEN
        SELECT COALESCE(SUM(CASE WHEN "TIPO" = 'FACT' THEN COALESCE("PEND", 0) ELSE 0 END), 0)
          INTO v_saldo_total
          FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor;

        UPDATE master."Supplier"
           SET "TotalBalance" = v_saldo_total
         WHERE "SupplierCode" = v_cod_proveedor
           AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows",
        p_actualizar_inventario AS "inventoryUpdated",
        (p_generar_cxp AND v_tipo = 'CREDITO') AS "cxpGenerated";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
