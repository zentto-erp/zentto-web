-- +goose Up
-- PR B — Cablear reserve+commit en POS checkout
--
-- Problema previo:
--   usp_pos_saleticket_create y usp_pos_saleticketline_insert no tocaban inventario.
--   Las ventas POS cerradas NO descontaban stock → los reportes de stock estaban
--   desincronizados con la caja.
--
-- Solución:
--   Nuevo usp_pos_saleticket_commit_stock(p_sale_ticket_id, p_company_id, p_user_id).
--   Se llama desde la API tras insertar todas las líneas del ticket.
--   Por cada línea NO-void:
--     1. usp_inv_stock_reserve (TTL 5 min — POS es pago inmediato, TTL corto como guardia)
--     2. usp_inv_stock_commit (convierte en InventoryMovement SALIDA + decrementa StockQty)
--   Si cualquier reserva falla → RAISE EXCEPTION → toda la tx de POS hace rollback.
--
--   Líneas anuladas (LineMetaJson contiene {"isVoid":true,...}) se ignoran.
--   ReferenceType='POS_TICKET', ReferenceId=SaleTicketId::TEXT.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_saleticket_commit_stock(
    p_sale_ticket_id BIGINT,
    p_company_id     INTEGER,
    p_user_id        INTEGER DEFAULT NULL
) RETURNS TABLE(
    "Resultado"   INTEGER,
    "Mensaje"     VARCHAR,
    "LineasProcesadas" INTEGER,
    "MovimientosGenerados" INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_line          RECORD;
    v_resv          RECORD;
    v_commit        RECORD;
    v_lines         INTEGER := 0;
    v_movs          INTEGER := 0;
    v_ticket_exists INTEGER;
BEGIN
    -- Validar que el ticket existe y pertenece al tenant
    SELECT COUNT(*)::INT INTO v_ticket_exists
      FROM pos."SaleTicket"
     WHERE "SaleTicketId" = p_sale_ticket_id
       AND "CompanyId"    = p_company_id;

    IF v_ticket_exists = 0 THEN
        RETURN QUERY SELECT 0,
            ('SaleTicket ' || p_sale_ticket_id::TEXT || ' not found for CompanyId ' || p_company_id::TEXT)::VARCHAR,
            0, 0;
        RETURN;
    END IF;

    -- Iterar líneas no anuladas
    FOR v_line IN
        SELECT l."ProductCode", l."Quantity"
          FROM pos."SaleTicketLine" l
         WHERE l."SaleTicketId" = p_sale_ticket_id
           AND (
                l."LineMetaJson" IS NULL
                OR l."LineMetaJson" = ''
                OR COALESCE(
                    NULLIF(l."LineMetaJson", '')::JSONB->>'isVoid',
                    'false'
                ) <> 'true'
           )
           AND l."Quantity" > 0
         ORDER BY l."LineNumber"
    LOOP
        v_lines := v_lines + 1;

        -- Reservar (TTL corto, 5 min)
        SELECT * INTO v_resv
          FROM usp_inv_stock_reserve(
            p_company_id,
            v_line."ProductCode"::VARCHAR,
            v_line."Quantity"::NUMERIC,
            'POS_TICKET'::VARCHAR,
            (p_sale_ticket_id::TEXT || '-' || v_lines::TEXT)::VARCHAR,
            5,
            p_user_id
          );

        IF NOT v_resv.ok THEN
            RAISE EXCEPTION 'Stock insuficiente en ticket POS % línea % (producto %): % — disponible=%',
                p_sale_ticket_id, v_lines, v_line."ProductCode",
                v_resv.mensaje, v_resv."Disponible";
        END IF;

        -- Commit inmediato → genera InventoryMovement + decrementa StockQty
        SELECT * INTO v_commit
          FROM usp_inv_stock_commit(
            v_resv."ReservationId",
            p_company_id,
            0::NUMERIC,
            p_user_id
          );

        IF v_commit.ok THEN
            v_movs := v_movs + 1;
        ELSE
            RAISE EXCEPTION 'Commit de reserva falló en ticket POS % línea %: %',
                p_sale_ticket_id, v_lines, v_commit.mensaje;
        END IF;
    END LOOP;

    RETURN QUERY SELECT 1,
        ('POS ticket ' || p_sale_ticket_id::TEXT || ' stock committed')::VARCHAR,
        v_lines,
        v_movs;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_pos_saleticket_commit_stock(BIGINT, INTEGER, INTEGER);
-- +goose StatementEnd
