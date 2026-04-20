-- +goose Up
-- PR C — Cablear consumo de recetas en restaurante
--
-- Problema previo:
--   Al cerrar (`usp_rest_orderticket_close`) un pedido de restaurante, el service
--   TS hacía un "best-effort" dentro de try/catch:
--     - por cada línea, obtenía ingredientes de rest.MenuRecipe
--     - llamaba usp_Inv_Movement_Create con warehouseId manual
--   Problemas:
--     1) Silencioso: errores enmascarados, stock descuadrado
--     2) No usa reserva → oversell posible si la cocina ya empezó
--     3) Depende de warehouseId → sin warehouse no descuenta
--     4) No usa inv.StockReservation → sin trazabilidad ni cleanup
--
-- Solución:
--   usp_rest_orderticket_commit_recipe_stock(p_order_id, p_company_id, p_user_id):
--     Itera rest.OrderTicketLine del pedido. Para cada línea:
--       JOIN rest.MenuRecipe → ingrediente + cantidad × line.Quantity
--       JOIN master.Product → ProductCode del ingrediente
--       usp_inv_stock_reserve (TTL 10 min) → usp_inv_stock_commit
--     Si falla la reserva de cualquier ingrediente → RAISE EXCEPTION → rollback.
--
--   ReferenceType='REST_ORDER', ReferenceId=OrderTicketId-LineId-IngredientId.
--
--   Productos sin receta (ej. bebidas compradas ya procesadas) también descuentan
--   directo: se reserva el producto vendido con Quantity=line.Quantity.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_commit_recipe_stock(
    p_order_id   BIGINT,
    p_company_id INTEGER,
    p_user_id    INTEGER DEFAULT NULL
) RETURNS TABLE(
    "Resultado"              INTEGER,
    "Mensaje"                VARCHAR,
    "LineasProcesadas"       INTEGER,
    "IngredientesProcesados" INTEGER,
    "MovimientosGenerados"   INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_line          RECORD;
    v_ingredient    RECORD;
    v_resv          RECORD;
    v_commit        RECORD;
    v_lines         INTEGER := 0;
    v_ingredients   INTEGER := 0;
    v_movs          INTEGER := 0;
    v_has_recipe    BOOLEAN;
    v_order_exists  INTEGER;
BEGIN
    -- Validar
    SELECT COUNT(*)::INT INTO v_order_exists
      FROM rest."OrderTicket"
     WHERE "OrderTicketId" = p_order_id
       AND "CompanyId"     = p_company_id;

    IF v_order_exists = 0 THEN
        RETURN QUERY SELECT 0,
            ('OrderTicket ' || p_order_id::TEXT || ' not found for CompanyId ' || p_company_id::TEXT)::VARCHAR,
            0, 0, 0;
        RETURN;
    END IF;

    -- Iterar líneas del pedido
    FOR v_line IN
        SELECT
            l."OrderTicketLineId",
            l."ProductId",
            l."ProductCode",
            l."Quantity"
          FROM rest."OrderTicketLine" l
         WHERE l."OrderTicketId" = p_order_id
           AND l."Quantity" > 0
         ORDER BY l."LineNumber"
    LOOP
        v_lines := v_lines + 1;

        -- ¿Tiene receta?
        SELECT EXISTS(
            SELECT 1 FROM rest."MenuRecipe"
             WHERE "MenuProductId" = v_line."ProductId"
               AND "IsActive"      = TRUE
        ) INTO v_has_recipe;

        IF v_has_recipe THEN
            -- Consumir ingredientes según receta
            FOR v_ingredient IN
                SELECT
                    r."MenuRecipeId",
                    r."IngredientProductId",
                    p."ProductCode"::VARCHAR AS "IngredientCode",
                    (r."Quantity" * v_line."Quantity")::NUMERIC AS "ConsumeQty"
                  FROM rest."MenuRecipe" r
                  JOIN master."Product" p ON p."ProductId" = r."IngredientProductId"
                 WHERE r."MenuProductId" = v_line."ProductId"
                   AND r."IsActive"      = TRUE
                   AND p."CompanyId"     = p_company_id
            LOOP
                v_ingredients := v_ingredients + 1;

                SELECT * INTO v_resv
                  FROM usp_inv_stock_reserve(
                    p_company_id,
                    v_ingredient."IngredientCode",
                    v_ingredient."ConsumeQty",
                    'REST_ORDER'::VARCHAR,
                    (p_order_id::TEXT || '-L' || v_line."OrderTicketLineId"::TEXT ||
                     '-I' || v_ingredient."IngredientProductId"::TEXT)::VARCHAR,
                    10,
                    p_user_id
                  );

                IF NOT v_resv.ok THEN
                    RAISE EXCEPTION 'Stock insuficiente para ingrediente % (producto %, receta %): % — disponible=%',
                        v_ingredient."IngredientCode",
                        v_line."ProductCode",
                        v_ingredient."MenuRecipeId",
                        v_resv.mensaje,
                        v_resv."Disponible";
                END IF;

                SELECT * INTO v_commit
                  FROM usp_inv_stock_commit(v_resv."ReservationId", p_company_id, 0::NUMERIC, p_user_id);

                IF v_commit.ok THEN
                    v_movs := v_movs + 1;
                ELSE
                    RAISE EXCEPTION 'Commit de reserva falló para ingrediente % en pedido %: %',
                        v_ingredient."IngredientCode", p_order_id, v_commit.mensaje;
                END IF;
            END LOOP;
        ELSE
            -- Sin receta → descuenta el producto vendido directo
            SELECT * INTO v_resv
              FROM usp_inv_stock_reserve(
                p_company_id,
                v_line."ProductCode"::VARCHAR,
                v_line."Quantity"::NUMERIC,
                'REST_ORDER'::VARCHAR,
                (p_order_id::TEXT || '-L' || v_line."OrderTicketLineId"::TEXT || '-DIRECT')::VARCHAR,
                10,
                p_user_id
              );

            IF NOT v_resv.ok THEN
                RAISE EXCEPTION 'Stock insuficiente para producto % (sin receta): % — disponible=%',
                    v_line."ProductCode", v_resv.mensaje, v_resv."Disponible";
            END IF;

            SELECT * INTO v_commit
              FROM usp_inv_stock_commit(v_resv."ReservationId", p_company_id, 0::NUMERIC, p_user_id);

            IF v_commit.ok THEN
                v_movs := v_movs + 1;
            ELSE
                RAISE EXCEPTION 'Commit de reserva falló para producto % en pedido %: %',
                    v_line."ProductCode", p_order_id, v_commit.mensaje;
            END IF;
        END IF;
    END LOOP;

    RETURN QUERY SELECT 1,
        ('OrderTicket ' || p_order_id::TEXT || ' recipe stock committed')::VARCHAR,
        v_lines,
        v_ingredients,
        v_movs;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_commit_recipe_stock(BIGINT, INTEGER, INTEGER);
-- +goose StatementEnd
