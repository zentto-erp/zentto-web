-- =============================================================================
--  MigraciÃƒÂ³n 025: Fix BIGINT en todas las funciones de OrderTicket/OrderTicketLine
--  Motivo: rest."OrderTicket"."OrderTicketId" y rest."OrderTicketLine"."OrderTicketLineId"
--          son BIGINT GENERATED ALWAYS AS IDENTITY, pero las funciones declaraban
--          RETURNS TABLE("id" INT), DECLARE v_id INT, y parÃƒÂ¡metros p_pedido_id INT,
--          causando "returned type bigint does not match expected type integer" en runtime.
-- =============================================================================

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_GetOpenByTable...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getopenbytable(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getopenbytable(
    p_company_id INT, p_branch_id INT, p_table_number VARCHAR(20)
)
RETURNS TABLE("id" BIGINT, "status" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."Status"
    FROM rest."OrderTicket" ot
    WHERE ot."CompanyId" = p_company_id AND ot."BranchId" = p_branch_id
      AND ot."TableNumber" = p_table_number AND ot."Status" IN ('OPEN', 'SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getopenbytable(INT, INT, VARCHAR(20)) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_Create...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_create(INT, INT, VARCHAR(5), VARCHAR(20), INT, VARCHAR(255), VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_create(
    p_company_id INT, p_branch_id INT, p_country_code VARCHAR(5), p_table_number VARCHAR(20),
    p_opened_by_user_id INT DEFAULT NULL, p_customer_name VARCHAR(255) DEFAULT NULL,
    p_customer_fiscal_id VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO rest."OrderTicket" (
        "CompanyId","BranchId","CountryCode","TableNumber","OpenedByUserId",
        "CustomerName","CustomerFiscalId","Status","NetAmount","TaxAmount","TotalAmount","OpenedAt"
    ) VALUES (
        p_company_id,p_branch_id,p_country_code,p_table_number,p_opened_by_user_id,
        p_customer_name,p_customer_fiscal_id,'OPEN',0,0,0,NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "OrderTicketId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_create(INT, INT, VARCHAR(5), VARCHAR(20), INT, VARCHAR(255), VARCHAR(50)) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_GetById...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getbyid(p_pedido_id BIGINT)
RETURNS TABLE("orderId" BIGINT, "companyId" INT, "branchId" INT, "countryCode" VARCHAR, "status" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."CompanyId", ot."BranchId", ot."CountryCode", ot."Status"
    FROM rest."OrderTicket" ot WHERE ot."OrderTicketId" = p_pedido_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getbyid(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicketLine_NextLineNumber...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_nextlinenumber(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_nextlinenumber(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_nextlinenumber(p_order_id BIGINT)
RETURNS TABLE("nextLine" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT COALESCE(MAX("LineNumber"), 0) + 1
    FROM rest."OrderTicketLine" WHERE "OrderTicketId" = p_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_nextlinenumber(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicketLine_Insert...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_insert(INT, INT, VARCHAR(5), INT, VARCHAR(60), VARCHAR(255), NUMERIC(18,4), NUMERIC(18,4), VARCHAR(20), NUMERIC(10,6), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(600), INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_insert(BIGINT, INT, VARCHAR(5), BIGINT, VARCHAR(60), VARCHAR(255), NUMERIC(18,4), NUMERIC(18,4), VARCHAR(20), NUMERIC(10,6), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(600), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_insert(
    p_order_id BIGINT, p_line_number INT, p_country_code VARCHAR(5),
    p_product_id BIGINT DEFAULT NULL, p_product_code VARCHAR(60) DEFAULT NULL,
    p_product_name VARCHAR(255) DEFAULT NULL, p_quantity NUMERIC(18,4) DEFAULT NULL,
    p_unit_price NUMERIC(18,4) DEFAULT NULL, p_tax_code VARCHAR(20) DEFAULT NULL,
    p_tax_rate NUMERIC(10,6) DEFAULT NULL, p_net_amount NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount NUMERIC(18,2) DEFAULT NULL, p_total_amount NUMERIC(18,2) DEFAULT NULL,
    p_notes VARCHAR(600) DEFAULT NULL, p_supervisor_approval_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO rest."OrderTicketLine" (
        "OrderTicketId","LineNumber","CountryCode",
        "ProductId","ProductCode","ProductName","Quantity","UnitPrice","TaxCode","TaxRate",
        "NetAmount","TaxAmount","TotalAmount","Notes","SupervisorApprovalId","CreatedAt","UpdatedAt"
    ) VALUES (
        p_order_id,p_line_number,p_country_code,p_product_id,p_product_code,p_product_name,
        p_quantity,p_unit_price,p_tax_code,p_tax_rate,p_net_amount,p_tax_amount,p_total_amount,
        p_notes,p_supervisor_approval_id,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "OrderTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_insert(BIGINT, INT, VARCHAR(5), BIGINT, VARCHAR(60), VARCHAR(255), NUMERIC(18,4), NUMERIC(18,4), VARCHAR(20), NUMERIC(10,6), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(600), INT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_RecalcTotals...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_recalctotals(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_recalctotals(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_recalctotals(p_order_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_net NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("NetAmount"),0), COALESCE(SUM("TaxAmount"),0), COALESCE(SUM("TotalAmount"),0)
    INTO v_net, v_tax, v_total
    FROM rest."OrderTicketLine" WHERE "OrderTicketId" = p_order_id;
    UPDATE rest."OrderTicket"
    SET "NetAmount" = v_net, "TaxAmount" = v_tax, "TotalAmount" = v_total,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_recalctotals(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_CheckPriorVoid...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_checkpriorvoid(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_checkpriorvoid(BIGINT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_checkpriorvoid(p_pedido_id BIGINT, p_item_id BIGINT)
RETURNS TABLE("alreadyVoided" INT) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT 1 FROM sec."SupervisorOverride"
    WHERE "ModuleCode" = 'RESTAURANTE' AND "ActionCode" = 'ORDER_LINE_VOID' AND "Status" = 'CONSUMED'
      AND "SourceDocumentId" = p_pedido_id AND "SourceLineId" = p_item_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_checkpriorvoid(BIGINT, BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicketLine_GetById...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(BIGINT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getbyid(p_pedido_id BIGINT, p_item_id BIGINT)
RETURNS TABLE(
    "itemId" BIGINT, "lineNumber" INT, "countryCode" VARCHAR, "productId" BIGINT,
    "productCode" VARCHAR, "nombre" VARCHAR, "cantidad" NUMERIC, "unitPrice" NUMERIC,
    "taxCode" VARCHAR, "taxRate" NUMERIC, "netAmount" NUMERIC, "taxAmount" NUMERIC, "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."LineNumber", ol."CountryCode", ol."ProductId",
        ol."ProductCode", ol."ProductName", ol."Quantity", ol."UnitPrice", ol."TaxCode", ol."TaxRate",
        ol."NetAmount", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id AND ol."OrderTicketLineId" = p_item_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getbyid(BIGINT, BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_SendToKitchen...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_sendtokitchen(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_sendtokitchen(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_sendtokitchen(p_pedido_id BIGINT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500)) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "Status" = CASE WHEN "Status" = 'OPEN' THEN 'SENT' ELSE "Status" END,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_sendtokitchen(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_GetHeaderForClose...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getheaderforclose(p_pedido_id BIGINT)
RETURNS TABLE(
    "id" BIGINT, "empresaId" INT, "sucursalId" INT, "countryCode" VARCHAR, "mesaId" BIGINT,
    "clienteNombre" VARCHAR, "clienteRif" VARCHAR, "estado" VARCHAR, "total" NUMERIC,
    "fechaCierre" TIMESTAMP, "codUsuario" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId", o."CountryCode", dt."DiningTableId",
        o."CustomerName", o."CustomerFiscalId", o."Status", o."TotalAmount", o."ClosedAt",
        COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt
        ON dt."CompanyId" = o."CompanyId" AND dt."BranchId" = o."BranchId"
        AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getheaderforclose(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_Close...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_close(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_close(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_close(p_pedido_id BIGINT, p_closed_by_user_id INT DEFAULT NULL)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500)) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "Status" = 'CLOSED', "ClosedByUserId" = p_closed_by_user_id,
        "ClosedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_close(BIGINT, INT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicketLine_GetFiscalBreakdown...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getfiscalbreakdown(p_pedido_id BIGINT)
RETURNS TABLE(
    "itemId" BIGINT, "productoId" VARCHAR, "nombre" VARCHAR, "quantity" NUMERIC,
    "unitPrice" NUMERIC, "baseAmount" NUMERIC, "taxCode" VARCHAR, "taxRate" NUMERIC,
    "taxAmount" NUMERIC, "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."ProductCode", ol."ProductName",
        ol."Quantity", ol."UnitPrice", ol."NetAmount", ol."TaxCode", ol."TaxRate",
        ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id ORDER BY ol."LineNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getfiscalbreakdown(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_GetByMesaHeader...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getbymesaheader(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getbymesaheader(p_company_id INT, p_branch_id INT, p_table_number VARCHAR(20))
RETURNS TABLE("id" BIGINT, "clienteNombre" VARCHAR, "clienteRif" VARCHAR, "estado" VARCHAR, "total" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."CustomerName", ot."CustomerFiscalId", ot."Status", ot."TotalAmount"
    FROM rest."OrderTicket" ot
    WHERE ot."CompanyId" = p_company_id AND ot."BranchId" = p_branch_id
      AND ot."TableNumber" = p_table_number AND ot."Status" IN ('OPEN', 'SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getbymesaheader(INT, INT, VARCHAR(20)) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicketLine_GetByPedido...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getbypedido(p_pedido_id BIGINT)
RETURNS TABLE(
    "id" BIGINT, "productoId" VARCHAR, "nombre" VARCHAR, "cantidad" NUMERIC,
    "precioUnitario" NUMERIC, "subtotal" NUMERIC, "iva" NUMERIC, "taxCode" VARCHAR,
    "impuesto" NUMERIC, "total" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."ProductCode", ol."ProductName", ol."Quantity",
        ol."UnitPrice", ol."NetAmount",
        CASE WHEN ol."TaxRate" > 1 THEN ol."TaxRate" ELSE ol."TaxRate" * 100 END,
        ol."TaxCode", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id ORDER BY ol."LineNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getbypedido(BIGINT) TO zentto_app;

\echo '  [025] Fix BIGINT: usp_Rest_OrderTicket_UpdateTimestamp...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_updatetimestamp(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_updatetimestamp(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_updatetimestamp(p_pedido_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_updatetimestamp(BIGINT) TO zentto_app;

\echo '  [025] Registrando migraciÃƒÂ³n...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('025_fix_orderticket_bigint', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [025] COMPLETO Ã¢â‚¬â€ BIGINT corregido en 14 funciones OrderTicket/OrderTicketLine'
