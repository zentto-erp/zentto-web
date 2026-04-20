-- +goose Up
-- PR E — Cablear usp_inv_valuation_layer_create en las entradas reales
--
-- Complementa PR D (#446). Sin este wiring, inv.InventoryValuationLayer queda
-- vacía y las ventas consumen con cost=0.
--
-- Entradas cubiertas:
--   1. usp_inv_albaran_sign (tipo='RECEPCION')       → PURCHASE_IN + layer
--   2. usp_inv_conteo_fisico_close (Diferencia > 0)   → ADJUSTMENT_IN + layer
--   3. usp_inv_traslado_advance (action='RECIBIR')    → TRANSFER_IN + layer
--
-- Compras (usp_ap_*, usp_compras_*) no descuentan stock hoy — usan albaranes.
-- Cuando existan SPs de compra que generen entradas reales, habrá otro PR.
--
-- Nota: la tabla inv.InventoryValuationLayer usa ProductId (BIGINT) pero los
-- SPs actuales trabajan con ProductCode (VARCHAR). Se hace JOIN con master.Product.
-- Si el producto no existe en master.Product, el layer se omite silenciosamente
-- (el StockMovement sí se crea — la valuación queda en 0 para ese producto).

-- =============================================================================
-- 1. usp_inv_albaran_sign — layer en RECEPCION
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_inv_albaran_sign(
    p_albaran_id  INT,
    p_company_id  INT,
    p_user_id     INT,
    p_firmante    VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "MovimientosGenerados" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado       VARCHAR(20);
    v_tipo         VARCHAR(20);
    v_whfrom       VARCHAR(20);
    v_whto         VARCHAR(20);
    v_albnum       VARCHAR(40);
    v_movs         INT := 0;
    rec            RECORD;
    v_movtype      VARCHAR(30);
    v_whcode       VARCHAR(20);
    v_product_id   BIGINT;
BEGIN
    SELECT "Estado","Tipo","WarehouseFrom","WarehouseTo","Numero"
    INTO v_estado, v_tipo, v_whfrom, v_whto, v_albnum
    FROM inv."Albaran"
    WHERE "AlbaranId" = p_albaran_id AND "CompanyId" = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, 'Albarán no encontrado';
        RETURN;
    END IF;
    IF v_estado <> 'EMITIDO' THEN
        RETURN QUERY SELECT FALSE, 0, 'Solo se puede firmar desde estado EMITIDO';
        RETURN;
    END IF;

    IF v_tipo = 'DESPACHO' THEN
        v_movtype := 'SALE_OUT';
        v_whcode  := COALESCE(v_whfrom, 'PRINCIPAL');
    ELSIF v_tipo = 'RECEPCION' THEN
        v_movtype := 'PURCHASE_IN';
        v_whcode  := COALESCE(v_whto, 'PRINCIPAL');
    ELSE
        v_movtype := NULL;
        v_whcode  := NULL;
    END IF;

    IF v_movtype IS NOT NULL THEN
        FOR rec IN
            SELECT l."ProductCode", l."Cantidad", l."CostoUnitario"
            FROM inv."AlbaranLinea" l
            WHERE l."AlbaranId" = p_albaran_id
        LOOP
            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", v_movtype,
                rec."Cantidad", rec."CostoUnitario",
                v_whcode, 'ALBARAN', p_albaran_id,
                NOW(), p_user_id, 'Albarán ' || v_albnum
            );
            v_movs := v_movs + 1;

            -- Valuation layer solo para entradas (RECEPCION)
            IF v_tipo = 'RECEPCION' AND COALESCE(rec."Cantidad", 0) > 0 THEN
                SELECT "ProductId" INTO v_product_id
                  FROM master."Product"
                 WHERE "ProductCode" = rec."ProductCode"
                   AND "CompanyId"   = p_company_id
                 LIMIT 1;

                IF v_product_id IS NOT NULL THEN
                    PERFORM usp_inv_valuation_layer_create(
                        p_company_id,
                        v_product_id,
                        rec."Cantidad"::NUMERIC,
                        COALESCE(rec."CostoUnitario", 0)::NUMERIC,
                        'ALBARAN'::VARCHAR,
                        p_albaran_id::VARCHAR,
                        NULL::BIGINT,
                        CURRENT_DATE
                    );
                END IF;
            END IF;
        END LOOP;
    END IF;

    UPDATE inv."Albaran"
    SET "Estado"          = 'FIRMADO',
        "FechaFirma"      = NOW(),
        "FirmadoPorId"    = p_user_id,
        "FirmadoPorNombre" = COALESCE(p_firmante, 'Usuario #' || p_user_id)
    WHERE "AlbaranId" = p_albaran_id;

    RETURN QUERY SELECT TRUE, v_movs, 'Albarán firmado. Movimientos generados: ' || v_movs;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
-- 2. usp_inv_conteo_fisico_close — layer cuando Diferencia > 0 (ADJUSTMENT_IN)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_inv_conteo_fisico_close(
    p_hoja_conteo_id  INT,
    p_company_id      INT,
    p_user_id         INT
)
RETURNS TABLE("ok" BOOLEAN, "AjustesGenerados" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_ajustes    INT := 0;
    v_estado     VARCHAR(20);
    v_warehouse  VARCHAR(20);
    v_product_id BIGINT;
    rec          RECORD;
BEGIN
    SELECT h."Estado", h."WarehouseCode"
    INTO v_estado, v_warehouse
    FROM inv."HojaConteo" h
    WHERE h."HojaConteoId" = p_hoja_conteo_id
      AND h."CompanyId"    = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, 'Hoja de conteo no encontrada';
        RETURN;
    END IF;

    IF v_estado NOT IN ('BORRADOR','EN_PROCESO','APROBADA') THEN
        RETURN QUERY SELECT FALSE, 0, 'La hoja no puede cerrarse desde estado: ' || v_estado;
        RETURN;
    END IF;

    FOR rec IN
        SELECT l."ProductCode", l."Diferencia", l."UnitCost"
        FROM inv."HojaConteoLinea" l
        WHERE l."HojaConteoId" = p_hoja_conteo_id
          AND l."StockFisico"  IS NOT NULL
          AND l."Diferencia"   <> 0
    LOOP
        INSERT INTO inv."StockMovement"
            ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
             "WarehouseCode","SourceDocumentType","SourceDocumentId",
             "MovementDate","CreatedByUserId","Notes")
        VALUES (
            p_company_id,
            rec."ProductCode",
            CASE WHEN rec."Diferencia" > 0 THEN 'ADJUSTMENT_IN' ELSE 'ADJUSTMENT_OUT' END,
            ABS(rec."Diferencia"),
            rec."UnitCost",
            v_warehouse,
            'CONTEO_FISICO',
            p_hoja_conteo_id,
            NOW(),
            p_user_id,
            'Ajuste por conteo físico CNT#' || p_hoja_conteo_id
        );
        v_ajustes := v_ajustes + 1;

        -- Valuation layer solo para ADJUSTMENT_IN (diferencia positiva = stock físico > sistema)
        IF rec."Diferencia" > 0 THEN
            SELECT "ProductId" INTO v_product_id
              FROM master."Product"
             WHERE "ProductCode" = rec."ProductCode"
               AND "CompanyId"   = p_company_id
             LIMIT 1;

            IF v_product_id IS NOT NULL THEN
                PERFORM usp_inv_valuation_layer_create(
                    p_company_id,
                    v_product_id,
                    rec."Diferencia"::NUMERIC,
                    COALESCE(rec."UnitCost", 0)::NUMERIC,
                    'CONTEO_FISICO'::VARCHAR,
                    p_hoja_conteo_id::VARCHAR,
                    NULL::BIGINT,
                    CURRENT_DATE
                );
            END IF;
        END IF;
    END LOOP;

    UPDATE inv."HojaConteo"
    SET "Estado" = 'CERRADA', "FechaCierre" = NOW()
    WHERE "HojaConteoId" = p_hoja_conteo_id;

    RETURN QUERY SELECT TRUE, v_ajustes, 'Conteo cerrado. Ajustes generados: ' || v_ajustes;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
-- 3. usp_inv_traslado_advance — layer cuando action='RECIBIR' (TRANSFER_IN)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_inv_traslado_advance(
    p_traslado_id  INT,
    p_company_id   INT,
    p_user_id      INT,
    p_action       VARCHAR(20)   -- APROBAR | DESPACHAR | RECIBIR | CANCELAR
)
RETURNS TABLE("ok" BOOLEAN, "NuevoEstado" VARCHAR, "AlbaranId" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_whfrom      VARCHAR(20);
    v_whto        VARCHAR(20);
    v_numero      VARCHAR(40);
    v_alb_id      INT;
    v_nuevo_est   VARCHAR(20);
    v_product_id  BIGINT;
    rec           RECORD;
BEGIN
    SELECT "Estado", "WarehouseFrom", "WarehouseTo", "Numero"
    INTO v_estado, v_whfrom, v_whto, v_numero
    FROM inv."TrasladoMultiPaso"
    WHERE "TrasladoId" = p_traslado_id AND "CompanyId" = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, NULL::INT, 'Traslado no encontrado';
        RETURN;
    END IF;

    IF p_action = 'APROBAR' AND v_estado = 'BORRADOR' THEN
        v_nuevo_est := 'PENDIENTE';
        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'PENDIENTE', "AprobadoPorId" = p_user_id
        WHERE "TrasladoId" = p_traslado_id;

    ELSIF p_action = 'DESPACHAR' AND v_estado = 'PENDIENTE' THEN
        SELECT a."AlbaranId" INTO v_alb_id
        FROM usp_inv_albaran_create(
            p_company_id, 'TRASLADO', v_whfrom, v_whto,
            NULL, NULL, 'TRASLADO', p_traslado_id, 'Salida TRL ' || v_numero, p_user_id
        ) a;

        FOR rec IN
            SELECT l."ProductCode", l."CantidadSolicitada", l."CostoUnitario"
            FROM inv."TrasladoMultiPasoLinea" l
            WHERE l."TrasladoId" = p_traslado_id
        LOOP
            PERFORM usp_inv_albaran_add_linea(v_alb_id, rec."ProductCode", rec."CantidadSolicitada", NULL, rec."CostoUnitario");

            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", 'TRANSFER_OUT',
                rec."CantidadSolicitada", rec."CostoUnitario",
                v_whfrom, 'TRASLADO', p_traslado_id,
                NOW(), p_user_id, 'Salida traslado ' || v_numero
            );

            UPDATE inv."TrasladoMultiPasoLinea"
            SET "CantidadDespachada" = "CantidadSolicitada"
            WHERE "TrasladoId" = p_traslado_id AND "ProductCode" = rec."ProductCode";
        END LOOP;

        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'EN_TRANSITO', "FechaSalida" = NOW(),
            "AlbaranSalidaId" = v_alb_id
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'EN_TRANSITO';

    ELSIF p_action = 'RECIBIR' AND v_estado = 'EN_TRANSITO' THEN
        SELECT a."AlbaranId" INTO v_alb_id
        FROM usp_inv_albaran_create(
            p_company_id, 'TRASLADO', v_whfrom, v_whto,
            NULL, NULL, 'TRASLADO', p_traslado_id, 'Entrada TRL ' || v_numero, p_user_id
        ) a;

        FOR rec IN
            SELECT l."ProductCode", l."CantidadDespachada", l."CostoUnitario"
            FROM inv."TrasladoMultiPasoLinea" l
            WHERE l."TrasladoId" = p_traslado_id
        LOOP
            PERFORM usp_inv_albaran_add_linea(v_alb_id, rec."ProductCode", COALESCE(rec."CantidadDespachada",0), NULL, rec."CostoUnitario");

            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", 'TRANSFER_IN',
                COALESCE(rec."CantidadDespachada",0), rec."CostoUnitario",
                v_whto, 'TRASLADO', p_traslado_id,
                NOW(), p_user_id, 'Entrada traslado ' || v_numero
            );

            -- Valuation layer en warehouse destino
            IF COALESCE(rec."CantidadDespachada", 0) > 0 THEN
                SELECT "ProductId" INTO v_product_id
                  FROM master."Product"
                 WHERE "ProductCode" = rec."ProductCode"
                   AND "CompanyId"   = p_company_id
                 LIMIT 1;

                IF v_product_id IS NOT NULL THEN
                    PERFORM usp_inv_valuation_layer_create(
                        p_company_id,
                        v_product_id,
                        rec."CantidadDespachada"::NUMERIC,
                        COALESCE(rec."CostoUnitario", 0)::NUMERIC,
                        'TRASLADO'::VARCHAR,
                        p_traslado_id::VARCHAR,
                        NULL::BIGINT,
                        CURRENT_DATE
                    );
                END IF;
            END IF;

            UPDATE inv."TrasladoMultiPasoLinea"
            SET "CantidadRecibida" = "CantidadDespachada"
            WHERE "TrasladoId" = p_traslado_id AND "ProductCode" = rec."ProductCode";
        END LOOP;

        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'RECIBIDO', "FechaRecepcion" = NOW(),
            "AlbaranEntradaId" = v_alb_id, "RecibidoPorId" = p_user_id
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'RECIBIDO';

    ELSIF p_action = 'CANCELAR' AND v_estado IN ('BORRADOR','PENDIENTE') THEN
        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'CANCELADO'
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'CANCELADO';

    ELSE
        RETURN QUERY SELECT FALSE, v_estado, NULL::INT,
            'Acción ' || p_action || ' no válida desde estado ' || v_estado;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, v_nuevo_est, v_alb_id, 'Traslado avanzado a ' || v_nuevo_est;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
-- Los tres SPs se mantienen con CREATE OR REPLACE; Down no revierte.
-- Para revertir, restaurar las versiones previas desde 00135_inv_conteo_fisico_albaranes.sql.
SELECT 1;
-- +goose StatementEnd
