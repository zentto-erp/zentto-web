-- +goose Up
-- PR D — FIFO / LIFO / WEIGHTED_AVG / LAST_COST / STANDARD real sobre inv.InventoryValuationLayer
--
-- Estado previo:
--   inv.InventoryValuationLayer y inv.InventoryValuationMethod existían pero
--   estaban huérfanos: ninguna función las creaba/consumía. El cost en cada
--   movimiento de salida se hardcodeaba con p_unit_cost = 0 (PR3).
--
-- Solución:
--   1. usp_inv_valuation_layer_create  — crea capa al entrar stock.
--   2. usp_inv_valuation_consume        — consume capas según método del producto.
--   3. usp_inv_valuation_get_method     — lee el método (default WEIGHTED_AVG).
--   4. usp_inv_valuation_set_method     — upsert del método + standard cost.
--   5. usp_inv_product_current_cost     — cost unitario actual según método (reportes).
--
--   6. usp_inv_stock_commit REFACTOR:
--        Si p_unit_cost = 0 → llama usp_inv_valuation_consume para obtener cost real.
--        Si p_unit_cost > 0 → usa el override (compat).
--
--   7. Entradas que crean layer: se documentan aquí pero la integración en
--      `usp_inv_albaran_sign` / compras se deja para PR siguientes para mantener
--      este PR acotado.

-- =============================================================================
-- 1. usp_inv_valuation_get_method
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_valuation_get_method(
    p_company_id INTEGER,
    p_product_id BIGINT
) RETURNS TABLE(
    "Method"       VARCHAR,
    "StandardCost" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_method        VARCHAR(20);
    v_standard_cost NUMERIC(18,4);
BEGIN
    SELECT "Method", "StandardCost"
      INTO v_method, v_standard_cost
      FROM inv."InventoryValuationMethod"
     WHERE "CompanyId" = p_company_id
       AND "ProductId" = p_product_id
       AND COALESCE("IsDeleted", FALSE) = FALSE
     LIMIT 1;

    IF v_method IS NULL THEN
        v_method := 'WEIGHTED_AVG';
        v_standard_cost := 0;
    END IF;

    RETURN QUERY SELECT v_method::VARCHAR, COALESCE(v_standard_cost, 0)::NUMERIC;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 2. usp_inv_valuation_set_method
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_valuation_set_method(
    p_company_id    INTEGER,
    p_product_id    BIGINT,
    p_method        VARCHAR,
    p_standard_cost NUMERIC DEFAULT 0,
    p_user_id       INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_id BIGINT;
BEGIN
    IF p_method NOT IN ('FIFO', 'LIFO', 'WEIGHTED_AVG', 'LAST_COST', 'STANDARD') THEN
        RETURN QUERY SELECT FALSE,
            ('Método inválido: ' || p_method || '. Valores: FIFO|LIFO|WEIGHTED_AVG|LAST_COST|STANDARD')::VARCHAR;
        RETURN;
    END IF;

    UPDATE inv."InventoryValuationMethod"
       SET "Method"          = p_method,
           "StandardCost"    = p_standard_cost,
           "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC'),
           "UpdatedByUserId" = p_user_id,
           "IsDeleted"       = FALSE,
           "DeletedAt"       = NULL,
           "RowVer"          = "RowVer" + 1
     WHERE "CompanyId" = p_company_id
       AND "ProductId" = p_product_id;

    IF NOT FOUND THEN
        SELECT COALESCE(MAX("ValuationMethodId"), 0) + 1 INTO v_new_id
          FROM inv."InventoryValuationMethod";

        INSERT INTO inv."InventoryValuationMethod" (
            "ValuationMethodId", "CompanyId", "ProductId",
            "Method", "StandardCost",
            "CreatedByUserId", "UpdatedByUserId"
        ) VALUES (
            v_new_id, p_company_id, p_product_id,
            p_method, p_standard_cost,
            p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT TRUE, 'Método actualizado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. usp_inv_valuation_layer_create — crea capa al entrar stock
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_valuation_layer_create(
    p_company_id            INTEGER,
    p_product_id            BIGINT,
    p_quantity              NUMERIC,
    p_unit_cost             NUMERIC,
    p_source_document_type  VARCHAR DEFAULT NULL,
    p_source_document_number VARCHAR DEFAULT NULL,
    p_lot_id                BIGINT  DEFAULT NULL,
    p_layer_date            DATE    DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "LayerId" BIGINT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_layer_id BIGINT;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RETURN QUERY SELECT FALSE, 0::BIGINT, 'Quantity debe ser > 0'::VARCHAR;
        RETURN;
    END IF;

    SELECT COALESCE(MAX("LayerId"), 0) + 1 INTO v_layer_id
      FROM inv."InventoryValuationLayer";

    INSERT INTO inv."InventoryValuationLayer" (
        "LayerId", "CompanyId", "ProductId", "LotId",
        "LayerDate", "RemainingQuantity", "UnitCost",
        "SourceDocumentType", "SourceDocumentNumber"
    ) VALUES (
        v_layer_id, p_company_id, p_product_id, p_lot_id,
        COALESCE(p_layer_date, CURRENT_DATE), p_quantity, COALESCE(p_unit_cost, 0),
        p_source_document_type, p_source_document_number
    );

    RETURN QUERY SELECT TRUE, v_layer_id, 'Layer creada'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 4. usp_inv_valuation_consume — consume capas según método del producto
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_valuation_consume(
    p_company_id INTEGER,
    p_product_id BIGINT,
    p_quantity   NUMERIC
) RETURNS TABLE(
    "ok"             BOOLEAN,
    "UnitCost"       NUMERIC,
    "TotalCost"      NUMERIC,
    "LayersConsumed" INTEGER,
    "Method"         VARCHAR,
    "mensaje"        VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_method        VARCHAR(20);
    v_standard_cost NUMERIC(18,4);
    v_remaining     NUMERIC := p_quantity;
    v_total_cost    NUMERIC := 0;
    v_layers        INTEGER := 0;
    v_layer_rec     RECORD;
    v_take          NUMERIC;
    v_total_avail   NUMERIC := 0;
    v_weighted_cost NUMERIC := 0;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RETURN QUERY SELECT FALSE, 0::NUMERIC, 0::NUMERIC, 0,
            'WEIGHTED_AVG'::VARCHAR, 'Quantity debe ser > 0'::VARCHAR;
        RETURN;
    END IF;

    -- Método
    SELECT m."Method", m."StandardCost"
      INTO v_method, v_standard_cost
      FROM usp_inv_valuation_get_method(p_company_id, p_product_id) AS m;

    -- STANDARD: retorna el cost fijo sin tocar layers
    IF v_method = 'STANDARD' THEN
        v_total_cost := p_quantity * COALESCE(v_standard_cost, 0);
        RETURN QUERY SELECT TRUE,
            COALESCE(v_standard_cost, 0)::NUMERIC,
            v_total_cost,
            0,
            v_method::VARCHAR,
            'STANDARD cost aplicado'::VARCHAR;
        RETURN;
    END IF;

    -- WEIGHTED_AVG: cost = SUM(remaining*cost)/SUM(remaining) sobre todas las capas abiertas
    IF v_method = 'WEIGHTED_AVG' THEN
        SELECT COALESCE(SUM("RemainingQuantity"), 0),
               COALESCE(SUM("RemainingQuantity" * "UnitCost"), 0)
          INTO v_total_avail, v_weighted_cost
          FROM inv."InventoryValuationLayer"
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
           AND "RemainingQuantity" > 0;

        IF v_total_avail = 0 THEN
            RETURN QUERY SELECT TRUE, 0::NUMERIC, 0::NUMERIC, 0,
                v_method::VARCHAR, 'Sin capas disponibles, cost=0'::VARCHAR;
            RETURN;
        END IF;

        v_total_cost := p_quantity * (v_weighted_cost / v_total_avail);

        -- Decrementa proporcional todas las capas
        UPDATE inv."InventoryValuationLayer"
           SET "RemainingQuantity" = GREATEST(
               "RemainingQuantity" - (p_quantity * "RemainingQuantity" / v_total_avail),
               0
           )
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
           AND "RemainingQuantity" > 0;

        GET DIAGNOSTICS v_layers = ROW_COUNT;

        RETURN QUERY SELECT TRUE,
            (v_weighted_cost / v_total_avail)::NUMERIC,
            v_total_cost,
            v_layers,
            v_method::VARCHAR,
            'WEIGHTED_AVG consumido'::VARCHAR;
        RETURN;
    END IF;

    -- LAST_COST: toma el último layer ingresado
    IF v_method = 'LAST_COST' THEN
        SELECT "UnitCost" INTO v_weighted_cost
          FROM inv."InventoryValuationLayer"
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
         ORDER BY "LayerDate" DESC, "LayerId" DESC
         LIMIT 1;

        v_total_cost := p_quantity * COALESCE(v_weighted_cost, 0);
        RETURN QUERY SELECT TRUE,
            COALESCE(v_weighted_cost, 0)::NUMERIC,
            v_total_cost,
            0,
            v_method::VARCHAR,
            'LAST_COST aplicado'::VARCHAR;
        RETURN;
    END IF;

    -- FIFO/LIFO: consume capas por orden
    FOR v_layer_rec IN
        SELECT "LayerId", "RemainingQuantity", "UnitCost"
          FROM inv."InventoryValuationLayer"
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
           AND "RemainingQuantity" > 0
         ORDER BY CASE
             WHEN v_method = 'FIFO' THEN "LayerDate"
             ELSE NULL
         END ASC,
         CASE
             WHEN v_method = 'LIFO' THEN "LayerDate"
             ELSE NULL
         END DESC,
         CASE
             WHEN v_method = 'FIFO' THEN "LayerId"
             ELSE NULL
         END ASC,
         CASE
             WHEN v_method = 'LIFO' THEN "LayerId"
             ELSE NULL
         END DESC
         FOR UPDATE
    LOOP
        EXIT WHEN v_remaining <= 0;

        v_take := LEAST(v_layer_rec."RemainingQuantity", v_remaining);
        v_total_cost := v_total_cost + (v_take * v_layer_rec."UnitCost");
        v_remaining := v_remaining - v_take;
        v_layers := v_layers + 1;

        UPDATE inv."InventoryValuationLayer"
           SET "RemainingQuantity" = "RemainingQuantity" - v_take
         WHERE "LayerId" = v_layer_rec."LayerId";
    END LOOP;

    IF v_remaining > 0 THEN
        -- No había suficiente stock en layers; cost=0 para la porción faltante
        RETURN QUERY SELECT TRUE,
            CASE WHEN p_quantity > 0 THEN (v_total_cost / p_quantity) ELSE 0 END::NUMERIC,
            v_total_cost,
            v_layers,
            v_method::VARCHAR,
            ('Stock parcial en capas; faltaron ' || v_remaining::TEXT || ' unidades')::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE,
        (v_total_cost / p_quantity)::NUMERIC,
        v_total_cost,
        v_layers,
        v_method::VARCHAR,
        (v_method || ' consumido')::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 5. usp_inv_product_current_cost — cost actual para reports
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_product_current_cost(
    p_company_id INTEGER,
    p_product_id BIGINT
) RETURNS TABLE("UnitCost" NUMERIC, "Method" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_method        VARCHAR(20);
    v_standard_cost NUMERIC(18,4);
    v_cost          NUMERIC := 0;
    v_total_avail   NUMERIC := 0;
    v_weighted_cost NUMERIC := 0;
BEGIN
    SELECT m."Method", m."StandardCost"
      INTO v_method, v_standard_cost
      FROM usp_inv_valuation_get_method(p_company_id, p_product_id) AS m;

    IF v_method = 'STANDARD' THEN
        v_cost := COALESCE(v_standard_cost, 0);
    ELSIF v_method = 'LAST_COST' THEN
        SELECT "UnitCost" INTO v_cost
          FROM inv."InventoryValuationLayer"
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
         ORDER BY "LayerDate" DESC, "LayerId" DESC
         LIMIT 1;
        v_cost := COALESCE(v_cost, 0);
    ELSIF v_method IN ('WEIGHTED_AVG', 'FIFO', 'LIFO') THEN
        -- Para reportes, todos usan el weighted average de capas abiertas
        SELECT COALESCE(SUM("RemainingQuantity"), 0),
               COALESCE(SUM("RemainingQuantity" * "UnitCost"), 0)
          INTO v_total_avail, v_weighted_cost
          FROM inv."InventoryValuationLayer"
         WHERE "CompanyId" = p_company_id
           AND "ProductId" = p_product_id
           AND "RemainingQuantity" > 0;

        v_cost := CASE WHEN v_total_avail > 0 THEN v_weighted_cost / v_total_avail ELSE 0 END;
    END IF;

    RETURN QUERY SELECT v_cost, v_method::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 6. usp_inv_stock_commit REFACTOR — usa valuation cuando no hay cost override
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_commit(
    p_reservation_id BIGINT,
    p_company_id     INTEGER,
    p_unit_cost      NUMERIC  DEFAULT 0,
    p_user_id        INTEGER  DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "MovementId" BIGINT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_resv         inv."StockReservation"%ROWTYPE;
    v_product_id   BIGINT;
    v_product_name VARCHAR(250);
    v_mov_id       BIGINT;
    v_final_cost   NUMERIC := 0;
    v_consume      RECORD;
BEGIN
    SELECT r.* INTO v_resv
    FROM inv."StockReservation" r
    WHERE r."ReservationId" = p_reservation_id
      AND r."CompanyId"     = p_company_id
      AND r."IsCommitted"   = FALSE
      AND r."IsReleased"    = FALSE
    FOR UPDATE;

    IF v_resv."ReservationId" IS NULL THEN
        RETURN QUERY SELECT FALSE, 0::BIGINT, 'Reserva no encontrada o ya procesada'::VARCHAR;
        RETURN;
    END IF;

    -- Producto
    SELECT "ProductId", "ProductName"
      INTO v_product_id, v_product_name
      FROM master."Product"
     WHERE "ProductCode" = v_resv."ProductCode"
       AND "CompanyId"   = p_company_id
     LIMIT 1;

    -- Cost: si p_unit_cost > 0 → override; si no → valuation según método del producto
    IF COALESCE(p_unit_cost, 0) > 0 THEN
        v_final_cost := p_unit_cost;
    ELSIF v_product_id IS NOT NULL THEN
        SELECT * INTO v_consume
          FROM usp_inv_valuation_consume(p_company_id, v_product_id, v_resv."Quantity");
        IF v_consume.ok THEN
            v_final_cost := v_consume."UnitCost";
        END IF;
    END IF;

    -- Movimiento de salida
    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId",
        "SourceDocumentType", "SourceDocumentId"
    ) VALUES (
        p_company_id,
        v_resv."ProductCode",
        COALESCE(v_product_name, v_resv."ProductCode"),
        'SALIDA',
        v_resv."Quantity",
        v_final_cost,
        v_resv."Quantity" * v_final_cost,
        v_resv."ReferenceId",
        'Confirmación de reserva ' || p_reservation_id::TEXT,
        COALESCE(p_user_id, v_resv."CreatedByUserId"),
        v_resv."ReferenceType",
        p_reservation_id
    )
    RETURNING "MovementId" INTO v_mov_id;

    -- Decrementa StockQty en master.Product
    UPDATE master."Product"
       SET "StockQty" = GREATEST(COALESCE("StockQty", 0) - v_resv."Quantity", 0)
     WHERE "ProductCode" = v_resv."ProductCode"
       AND "CompanyId"   = p_company_id;

    -- Marca la reserva confirmada
    UPDATE inv."StockReservation"
       SET "IsCommitted" = TRUE,
           "CommittedAt" = (NOW() AT TIME ZONE 'UTC')
     WHERE "ReservationId" = p_reservation_id;

    RETURN QUERY SELECT TRUE, v_mov_id, 'Stock confirmado'::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inv_product_current_cost(INTEGER, BIGINT);
DROP FUNCTION IF EXISTS public.usp_inv_valuation_consume(INTEGER, BIGINT, NUMERIC);
DROP FUNCTION IF EXISTS public.usp_inv_valuation_layer_create(INTEGER, BIGINT, NUMERIC, NUMERIC, VARCHAR, VARCHAR, BIGINT, DATE);
DROP FUNCTION IF EXISTS public.usp_inv_valuation_set_method(INTEGER, BIGINT, VARCHAR, NUMERIC, INTEGER);
DROP FUNCTION IF EXISTS public.usp_inv_valuation_get_method(INTEGER, BIGINT);
-- usp_inv_stock_commit se mantiene (CREATE OR REPLACE no revierte). Para revertir
-- a la versión pre-PR-D, restaurar desde 00134_inv_stock_reservation_atomic.sql.
-- +goose StatementEnd
