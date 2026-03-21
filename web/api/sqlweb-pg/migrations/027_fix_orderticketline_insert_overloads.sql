-- =============================================================================
--  Migración 027: Eliminar todos los overloads de usp_rest_orderticketline_insert
--
--  Problema: "function usp_rest_orderticketline_insert(...) is not unique"
--    Al llamar con args nombrados y todos los valores NULL (tipo 'unknown'),
--    PostgreSQL no puede resolver entre múltiples overloads con firmas distintas
--    (INT/BIGINT para p_order_id y p_product_id, distintas precisiones NUMERIC).
--
--  Solución: eliminar TODOS los overloads dinámicamente via pg_proc,
--    luego crear UNA sola versión canónica.
-- =============================================================================

\echo '  [027] Eliminando todos los overloads de usp_rest_orderticketline_insert...'

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT p.oid::regprocedure::text AS sig
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'usp_rest_orderticketline_insert'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
    END LOOP;
END;
$$;

\echo '  [027] Recreando usp_rest_orderticketline_insert (versión única BIGINT)...'

CREATE OR REPLACE FUNCTION usp_rest_orderticketline_insert(
    p_order_id               BIGINT,
    p_line_number            INT,
    p_country_code           VARCHAR(5),
    p_product_id             BIGINT       DEFAULT NULL,
    p_product_code           VARCHAR(60)  DEFAULT NULL,
    p_product_name           VARCHAR(255) DEFAULT NULL,
    p_quantity               NUMERIC(18,4) DEFAULT NULL,
    p_unit_price             NUMERIC(18,4) DEFAULT NULL,
    p_tax_code               VARCHAR(20)  DEFAULT NULL,
    p_tax_rate               NUMERIC(10,6) DEFAULT NULL,
    p_net_amount             NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount             NUMERIC(18,2) DEFAULT NULL,
    p_total_amount           NUMERIC(18,2) DEFAULT NULL,
    p_notes                  VARCHAR(600) DEFAULT NULL,
    p_supervisor_approval_id INT          DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO rest."OrderTicketLine" (
        "OrderTicketId", "LineNumber", "CountryCode",
        "ProductId", "ProductCode", "ProductName",
        "Quantity", "UnitPrice", "TaxCode", "TaxRate",
        "NetAmount", "TaxAmount", "TotalAmount",
        "Notes", "SupervisorApprovalId",
        "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_order_id, p_line_number, p_country_code,
        p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_tax_code, p_tax_rate,
        p_net_amount, p_tax_amount, p_total_amount,
        p_notes, p_supervisor_approval_id,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "OrderTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_insert(
    BIGINT, INT, VARCHAR(5), BIGINT, VARCHAR(60), VARCHAR(255),
    NUMERIC(18,4), NUMERIC(18,4), VARCHAR(20), NUMERIC(10,6),
    NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(600), INT
) TO zentto_app;

\echo '  [027] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('027_fix_orderticketline_insert_overloads', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [027] COMPLETO — un solo overload de usp_rest_orderticketline_insert'
