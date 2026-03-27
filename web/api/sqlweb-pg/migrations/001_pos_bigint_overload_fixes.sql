-- ============================================================
-- 001_pos_bigint_overload_fixes.sql
-- Elimina overloads INT obsoletos en funciones POS y garantiza
-- que solo existe la version BIGINT correcta.
-- Contexto: pos."WaitTicket"."WaitTicketId" es BIGINT; si
-- se acumulan overloads INT se produce:
--   "structure of query does not match function result type"
-- ============================================================

-- 1. usp_pos_waitticket_create
DROP FUNCTION IF EXISTS usp_pos_waitticket_create(
    INT, INT, VARCHAR, VARCHAR, VARCHAR, INT, INT, VARCHAR, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC, NUMERIC
) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticket_create(
    p_company_id          INT,
    p_branch_id           INT,
    p_country_code        VARCHAR(5),
    p_cash_register_code  VARCHAR(20),
    p_station_name        VARCHAR(100) DEFAULT NULL,
    p_created_by_user_id  INT DEFAULT NULL,
    p_customer_id         INT DEFAULT NULL,
    p_customer_code       VARCHAR(50) DEFAULT NULL,
    p_customer_name       VARCHAR(255) DEFAULT NULL,
    p_customer_fiscal_id  VARCHAR(50) DEFAULT NULL,
    p_price_tier          VARCHAR(50) DEFAULT 'Detal',
    p_reason              VARCHAR(500) DEFAULT NULL,
    p_net_amount          NUMERIC(18,2) DEFAULT 0,
    p_discount_amount     NUMERIC(18,2) DEFAULT 0,
    p_tax_amount          NUMERIC(18,2) DEFAULT 0,
    p_total_amount        NUMERIC(18,2) DEFAULT 0
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO pos."WaitTicket" (
        "CompanyId", "BranchId", "CountryCode", "CashRegisterCode", "StationName",
        "CreatedByUserId", "CustomerId", "CustomerCode", "CustomerName", "CustomerFiscalId",
        "PriceTier", "Reason", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount",
        "Status", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_branch_id, p_country_code, p_cash_register_code, p_station_name,
        p_created_by_user_id, p_customer_id, p_customer_code, p_customer_name, p_customer_fiscal_id,
        p_price_tier, p_reason, p_net_amount, p_discount_amount, p_tax_amount, p_total_amount,
        'WAITING', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "WaitTicketId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

-- 2. usp_pos_waitticketline_insert (drops both INT and BIGINT to ensure clean slate)
DROP FUNCTION IF EXISTS usp_pos_waitticketline_insert(
    INT, INT, VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC,
    VARCHAR, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, TEXT
) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticketline_insert(
    BIGINT, INT, VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC,
    VARCHAR, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, TEXT
) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticketline_insert(
    p_wait_ticket_id         BIGINT,
    p_line_number            INT,
    p_country_code           VARCHAR(5),
    p_product_id             INT DEFAULT NULL,
    p_product_code           VARCHAR(60) DEFAULT NULL,
    p_product_name           VARCHAR(255) DEFAULT NULL,
    p_quantity               NUMERIC(18,4) DEFAULT NULL,
    p_unit_price             NUMERIC(18,4) DEFAULT NULL,
    p_discount_amount        NUMERIC(18,2) DEFAULT 0,
    p_tax_code               VARCHAR(20) DEFAULT NULL,
    p_tax_rate               NUMERIC(10,6) DEFAULT NULL,
    p_net_amount             NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount             NUMERIC(18,2) DEFAULT NULL,
    p_total_amount           NUMERIC(18,2) DEFAULT NULL,
    p_supervisor_approval_id INT DEFAULT NULL,
    p_line_meta_json         TEXT DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO pos."WaitTicketLine" (
        "WaitTicketId", "LineNumber", "CountryCode", "ProductId", "ProductCode", "ProductName",
        "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate",
        "NetAmount", "TaxAmount", "TotalAmount",
        "SupervisorApprovalId", "LineMetaJson", "CreatedAt"
    ) VALUES (
        p_wait_ticket_id, p_line_number, p_country_code, p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_discount_amount, p_tax_code, p_tax_rate,
        p_net_amount, p_tax_amount, p_total_amount,
        p_supervisor_approval_id, p_line_meta_json, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "WaitTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

-- 3. usp_pos_waitticket_getheader
DROP FUNCTION IF EXISTS usp_pos_waitticket_getheader(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticket_getheader(INT, INT, BIGINT) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticket_getheader(
    p_company_id     INT,
    p_branch_id      INT,
    p_wait_ticket_id BIGINT
)
RETURNS TABLE(
    "id"             BIGINT,
    "cajaId"         CHARACTER VARYING,
    "estacionNombre" CHARACTER VARYING,
    "clienteId"      CHARACTER VARYING,
    "clienteNombre"  CHARACTER VARYING,
    "clienteRif"     CHARACTER VARYING,
    "tipoPrecio"     CHARACTER VARYING,
    motivo           CHARACTER VARYING,
    subtotal         NUMERIC,
    impuestos        NUMERIC,
    total            NUMERIC,
    estado           CHARACTER VARYING,
    "fechaCreacion"  TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId",
           wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerCode"::VARCHAR, wt."CustomerName"::VARCHAR, wt."CustomerFiscalId"::VARCHAR,
           wt."PriceTier"::VARCHAR, wt."Reason"::VARCHAR,
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount",
           wt."Status"::VARCHAR, wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$$;

-- 4. usp_pos_waitticket_recover
DROP FUNCTION IF EXISTS usp_pos_waitticket_recover(INT, INT, INT, INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticket_recover(INT, INT, BIGINT, INT, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticket_recover(
    p_company_id            INT,
    p_branch_id             INT,
    p_wait_ticket_id        BIGINT,
    p_recovered_by_user_id  INT DEFAULT NULL,
    p_recovered_at_register VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pos."WaitTicket"
    SET "Status" = 'RECOVERED',
        "RecoveredByUserId" = p_recovered_by_user_id,
        "RecoveredAtRegister" = p_recovered_at_register,
        "RecoveredAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id
      AND "BranchId" = p_branch_id
      AND "WaitTicketId" = p_wait_ticket_id;
    RETURN QUERY SELECT 1::BIGINT, 'OK'::VARCHAR(500);
END;
$$;

-- 5. usp_pos_waitticketline_getitems
DROP FUNCTION IF EXISTS usp_pos_waitticketline_getitems(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticketline_getitems(BIGINT) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticketline_getitems(
    p_wait_ticket_id BIGINT
)
RETURNS TABLE(
    "id"                   BIGINT,
    "productoId"           VARCHAR,
    "codigo"               VARCHAR,
    "nombre"               VARCHAR,
    "cantidad"             NUMERIC,
    "precioUnitario"       NUMERIC,
    "descuento"            NUMERIC,
    "iva"                  NUMERIC,
    "subtotal"             NUMERIC,
    "total"                NUMERIC,
    "supervisorApprovalId" INT,
    "lineMetaJson"         TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT wl."WaitTicketLineId",
        COALESCE(wl."ProductId"::TEXT, wl."ProductCode")::VARCHAR,
        wl."ProductCode", wl."ProductName",
        wl."Quantity", wl."UnitPrice", wl."DiscountAmount",
        CASE WHEN wl."TaxRate" > 1 THEN wl."TaxRate" ELSE wl."TaxRate" * 100 END,
        wl."NetAmount", wl."TotalAmount",
        wl."SupervisorApprovalId", wl."LineMetaJson"
    FROM pos."WaitTicketLine" wl
    WHERE wl."WaitTicketId" = p_wait_ticket_id
    ORDER BY wl."LineNumber";
END;
$$;

-- 6. usp_pos_waitticket_void
DROP FUNCTION IF EXISTS usp_pos_waitticket_void(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_waitticket_void(INT, INT, BIGINT) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_waitticket_void(
    p_company_id     INT,
    p_branch_id      INT,
    p_wait_ticket_id BIGINT
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pos."WaitTicket"
    SET "Status" = 'VOIDED', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id
      AND "BranchId" = p_branch_id
      AND "WaitTicketId" = p_wait_ticket_id
      AND "Status" = 'WAITING';
    RETURN QUERY SELECT 1::BIGINT, 'OK'::VARCHAR(500);
END;
$$;

-- 7. usp_pos_saleticketline_insert
DROP FUNCTION IF EXISTS usp_pos_saleticketline_insert(
    INT, INT, VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC,
    VARCHAR, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, TEXT
) CASCADE;
DROP FUNCTION IF EXISTS usp_pos_saleticketline_insert(
    BIGINT, INT, VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC,
    VARCHAR, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT, TEXT
) CASCADE;

CREATE OR REPLACE FUNCTION usp_pos_saleticketline_insert(
    p_sale_ticket_id         BIGINT,
    p_line_number            INT,
    p_country_code           VARCHAR(5),
    p_product_id             INT DEFAULT NULL,
    p_product_code           VARCHAR(60) DEFAULT NULL,
    p_product_name           VARCHAR(255) DEFAULT NULL,
    p_quantity               NUMERIC(18,4) DEFAULT NULL,
    p_unit_price             NUMERIC(18,4) DEFAULT NULL,
    p_discount_amount        NUMERIC(18,2) DEFAULT 0,
    p_tax_code               VARCHAR(20) DEFAULT NULL,
    p_tax_rate               NUMERIC(10,6) DEFAULT NULL,
    p_net_amount             NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount             NUMERIC(18,2) DEFAULT NULL,
    p_total_amount           NUMERIC(18,2) DEFAULT NULL,
    p_supervisor_approval_id INT DEFAULT NULL,
    p_line_meta_json         TEXT DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO pos."SaleTicketLine" (
        "SaleTicketId", "LineNumber", "CountryCode", "ProductId", "ProductCode", "ProductName",
        "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate",
        "NetAmount", "TaxAmount", "TotalAmount",
        "SupervisorApprovalId", "LineMetaJson"
    ) VALUES (
        p_sale_ticket_id, p_line_number, p_country_code, p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_discount_amount, p_tax_code, p_tax_rate,
        p_net_amount, p_tax_amount, p_total_amount,
        p_supervisor_approval_id, p_line_meta_json
    )
    RETURNING "SaleTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;
