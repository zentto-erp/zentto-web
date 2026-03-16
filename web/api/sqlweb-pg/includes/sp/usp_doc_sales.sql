-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_doc_sales.sql
-- Funciones de documentos de venta (esquema doc)
-- Tablas: doc.SalesDocument, doc.SalesDocumentLine, doc.SalesDocumentPayment
-- 7 funciones: List, Get, GetDetail, GetPayments, Void, InvoiceFromOrder, Upsert
-- ============================================================

-- =============================================================================
-- 1. usp_Doc_SalesDocument_List
-- Lista paginada de documentos de venta con filtros.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_list(
    p_tipo_operacion VARCHAR(20),
    p_search         VARCHAR(100)  DEFAULT NULL,
    p_codigo         VARCHAR(60)   DEFAULT NULL,
    p_from_date      DATE          DEFAULT NULL,
    p_to_date        DATE          DEFAULT NULL,
    p_page           INT           DEFAULT 1,
    p_limit          INT           DEFAULT 50
)
RETURNS TABLE(
    "SalesDocumentId"       BIGINT,
    "DocumentNumber"        VARCHAR,
    "SerialType"            VARCHAR,
    "FiscalMemoryNumber"    VARCHAR,
    "OperationType"         VARCHAR,
    "CustomerCode"          VARCHAR,
    "CustomerName"          VARCHAR,
    "FiscalId"              VARCHAR,
    "DocumentDate"          TIMESTAMP,
    "DueDate"               TIMESTAMP,
    "DocumentTime"          VARCHAR,
    "SubTotal"              NUMERIC,
    "TaxableAmount"         NUMERIC,
    "ExemptAmount"          NUMERIC,
    "TaxAmount"             NUMERIC,
    "TaxRate"               NUMERIC,
    "TotalAmount"           NUMERIC,
    "DiscountAmount"        NUMERIC,
    "IsVoided"              BOOLEAN,
    "IsPaid"                VARCHAR,
    "IsInvoiced"            VARCHAR,
    "IsDelivered"           VARCHAR,
    "OriginDocumentNumber"  VARCHAR,
    "OriginDocumentType"    VARCHAR,
    "ControlNumber"         VARCHAR,
    "IsLegal"               VARCHAR,
    "IsPrinted"             BOOLEAN,
    "Notes"                 TEXT,
    "Concept"               VARCHAR,
    "PaymentTerms"          VARCHAR,
    "ShipToAddress"         VARCHAR,
    "SellerCode"            VARCHAR,
    "DepartmentCode"        VARCHAR,
    "LocationCode"          VARCHAR,
    "CurrencyCode"          VARCHAR,
    "ExchangeRate"          NUMERIC,
    "UserCode"              VARCHAR,
    "ReportDate"            TIMESTAMP,
    "HostName"              VARCHAR,
    "VehiclePlate"          VARCHAR,
    "Mileage"               NUMERIC,
    "TollAmount"            NUMERIC,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "IsDeleted"             BOOLEAN,
    "TotalCount"            BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."SalesDocument"
    WHERE "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            "DocumentNumber" LIKE '%' || p_search || '%'
            OR "CustomerName" LIKE '%' || p_search || '%'
            OR "FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR "CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR "DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR "DocumentDate" < (p_to_date + INTERVAL '1 day'));

    RETURN QUERY
    SELECT
        sd."SalesDocumentId",
        sd."DocumentNumber"::VARCHAR,
        sd."SerialType"::VARCHAR,
        sd."FiscalMemoryNumber"::VARCHAR,
        sd."OperationType"::VARCHAR,
        sd."CustomerCode"::VARCHAR,
        sd."CustomerName"::VARCHAR,
        sd."FiscalId"::VARCHAR,
        sd."DocumentDate",
        sd."DueDate",
        sd."DocumentTime"::VARCHAR,
        sd."SubTotal",
        sd."TaxableAmount",
        sd."ExemptAmount",
        sd."TaxAmount",
        sd."TaxRate",
        sd."TotalAmount",
        sd."DiscountAmount",
        sd."IsVoided",
        sd."IsPaid"::VARCHAR,
        sd."IsInvoiced"::VARCHAR,
        sd."IsDelivered"::VARCHAR,
        sd."OriginDocumentNumber"::VARCHAR,
        sd."OriginDocumentType"::VARCHAR,
        sd."ControlNumber"::VARCHAR,
        sd."IsLegal"::VARCHAR,
        sd."IsPrinted",
        sd."Notes"::TEXT,
        sd."Concept"::VARCHAR,
        sd."PaymentTerms"::VARCHAR,
        sd."ShipToAddress"::VARCHAR,
        sd."SellerCode"::VARCHAR,
        sd."DepartmentCode"::VARCHAR,
        sd."LocationCode"::VARCHAR,
        sd."CurrencyCode"::VARCHAR,
        sd."ExchangeRate",
        sd."UserCode"::VARCHAR,
        sd."ReportDate",
        sd."HostName"::VARCHAR,
        sd."VehiclePlate"::VARCHAR,
        sd."Mileage",
        sd."TollAmount",
        sd."CreatedAt",
        sd."UpdatedAt",
        sd."IsDeleted",
        v_total
    FROM doc."SalesDocument" sd
    WHERE sd."OperationType" = p_tipo_operacion
      AND sd."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            sd."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd."CustomerName" LIKE '%' || p_search || '%'
            OR sd."FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR sd."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd."DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR sd."DocumentDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY sd."DocumentDate" DESC, sd."DocumentNumber" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
-- 2. usp_Doc_SalesDocument_Get
-- Obtener un documento de venta individual.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_get(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."SalesDocument"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- =============================================================================
-- 3. usp_Doc_SalesDocument_GetDetail
-- Obtener las lineas de detalle de un documento de venta.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_getdetail(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."SalesDocumentLine"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocumentLine"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    ORDER BY COALESCE("LineNumber", 0), "LineId";
END;
$$;

-- =============================================================================
-- 4. usp_Doc_SalesDocument_GetPayments
-- Obtener las formas de pago de un documento de venta.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_getpayments(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."SalesDocumentPayment"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 5. usp_Doc_SalesDocument_Void
-- Anular un documento de venta. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_void(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60),
    p_cod_usuario    VARCHAR(60)  DEFAULT 'API',
    p_motivo         VARCHAR(500) DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "numFact" VARCHAR, "codCliente" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod_cliente  VARCHAR(60);
    v_company_id   INT;
    v_branch_id    INT;
    v_customer_id  BIGINT;
BEGIN
    -- Validar que el documento existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('Documento no encontrado: ' || p_num_doc || ' / ' || p_tipo_operacion)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta ya anulado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('El documento ya se encuentra anulado: ' || p_num_doc)::TEXT;
        RETURN;
    END IF;

    -- Obtener codigo de cliente
    SELECT "CustomerCode" INTO v_cod_cliente
    FROM doc."SalesDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular cabecera
    UPDATE doc."SalesDocument"
    SET "IsVoided"  = TRUE,
        "Notes"     = CONCAT(COALESCE("Notes", ''), ' | ANULADO ',
                       to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                       ' por ', p_cod_usuario,
                       CASE WHEN p_motivo <> '' THEN ' - Motivo: ' || p_motivo ELSE '' END),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular lineas
    UPDATE doc."SalesDocumentLine"
    SET "IsVoided"  = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Resolver contexto
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
    ORDER BY c."CompanyId"
    LIMIT 1;

    SELECT b."BranchId" INTO v_branch_id
    FROM cfg."Branch" b
    WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
    ORDER BY b."BranchId"
    LIMIT 1;

    -- Resolver CustomerId
    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CustomerCode" = v_cod_cliente
      AND "CompanyId" = v_company_id
      AND "IsDeleted" = FALSE
    LIMIT 1;

    -- Actualizar cuenta por cobrar si existe
    IF v_customer_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
        UPDATE ar."ReceivableDocument"
        SET "PendingAmount" = 0,
            "PaidFlag"      = TRUE,
            "Status"        = 'VOIDED',
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"      = v_company_id
          AND "BranchId"       = v_branch_id
          AND "DocumentNumber" = p_num_doc
          AND "DocumentType"   = p_tipo_operacion
          AND "CustomerId"     = v_customer_id;

        -- Recalcular saldo total del cliente
        UPDATE master."Customer"
        SET "TotalBalance" = COALESCE((
                SELECT SUM("PendingAmount")
                FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id
                  AND "Status" <> 'VOIDED'
            ), 0),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CustomerId" = v_customer_id;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc, v_cod_cliente,
        ('Documento anulado exitosamente: ' || p_num_doc)::TEXT;
END;
$$;

-- =============================================================================
-- 6. usp_Doc_SalesDocument_InvoiceFromOrder
-- Convertir un PEDIDO en FACTURA. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_invoicefromorder(
    p_num_doc_pedido  VARCHAR(60),
    p_num_doc_factura VARCHAR(60),
    p_formas_pago_json JSONB        DEFAULT NULL,
    p_cod_usuario     VARCHAR(60)   DEFAULT 'API'
)
RETURNS TABLE("ok" BOOLEAN, "pedido" VARCHAR, "factura" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_elem JSONB;
BEGIN
    -- Validar que el pedido existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('Pedido no encontrado: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta anulado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido esta anulado y no puede facturarse: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no fue ya facturado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsInvoiced" = 'S'
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido ya fue facturado previamente: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Copiar cabecera del pedido como nueva factura
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "DocumentDate", "DueDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsInvoiced", "IsDelivered",
        "OriginDocumentNumber", "OriginDocumentType",
        "ControlNumber", "IsLegal", "IsPrinted",
        "Notes", "Concept", "PaymentTerms", "ShipToAddress",
        "SellerCode", "DepartmentCode", "LocationCode",
        "CurrencyCode", "ExchangeRate",
        "UserCode", "ReportDate", "HostName",
        "VehiclePlate", "Mileage", "TollAmount",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_factura,
        s."SerialType",
        s."FiscalMemoryNumber",
        'FACT',
        s."CustomerCode", s."CustomerName", s."FiscalId",
        NOW() AT TIME ZONE 'UTC',
        s."DueDate",
        to_char(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
        s."SubTotal", s."TaxableAmount", s."ExemptAmount", s."TaxAmount", s."TaxRate", s."TotalAmount", s."DiscountAmount",
        FALSE,
        'N',
        'N',
        'N',
        p_num_doc_pedido,
        'PEDIDO',
        s."ControlNumber", s."IsLegal", FALSE,
        s."Notes", s."Concept", s."PaymentTerms", s."ShipToAddress",
        s."SellerCode", s."DepartmentCode", s."LocationCode",
        s."CurrencyCode", s."ExchangeRate",
        p_cod_usuario,
        NOW() AT TIME ZONE 'UTC',
        inet_client_addr()::TEXT,
        s."VehiclePlate", s."Mileage", s."TollAmount",
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    FROM doc."SalesDocument" s
    WHERE s."DocumentNumber" = p_num_doc_pedido
      AND s."OperationType" = 'PEDIDO'
      AND s."IsDeleted" = FALSE;

    -- Copiar lineas del pedido a la factura
    INSERT INTO doc."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "LineNumber", "ProductCode", "Description", "AlternateCode",
        "Quantity", "UnitPrice", "DiscountedPrice", "UnitCost",
        "SubTotal", "DiscountAmount", "TotalAmount",
        "TaxRate", "TaxAmount",
        "IsVoided", "RelatedRef",
        "UserCode", "LineDate",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_factura,
        sl."SerialType",
        sl."FiscalMemoryNumber",
        'FACT',
        sl."LineNumber", sl."ProductCode", sl."Description", sl."AlternateCode",
        sl."Quantity", sl."UnitPrice", sl."DiscountedPrice", sl."UnitCost",
        sl."SubTotal", sl."DiscountAmount", sl."TotalAmount",
        sl."TaxRate", sl."TaxAmount",
        FALSE,
        sl."RelatedRef",
        p_cod_usuario,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    FROM doc."SalesDocumentLine" sl
    WHERE sl."DocumentNumber" = p_num_doc_pedido
      AND sl."OperationType" = 'PEDIDO'
      AND sl."IsDeleted" = FALSE;

    -- Insertar formas de pago desde JSONB si se proporcionaron
    IF p_formas_pago_json IS NOT NULL AND jsonb_array_length(p_formas_pago_json) > 0 THEN
        INSERT INTO doc."SalesDocumentPayment" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "AmountBs", "ExchangeRate",
            "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_factura,
            COALESCE(elem->>'serialType', ''),
            COALESCE(elem->>'fiscalMemoryNumber', '1'),
            'FACT',
            elem->>'paymentMethod',
            elem->>'bankCode',
            elem->>'paymentNumber',
            COALESCE((elem->>'amount')::NUMERIC, 0),
            COALESCE((elem->>'amountBs')::NUMERIC, 0),
            COALESCE((elem->>'exchangeRate')::NUMERIC, 1),
            COALESCE((elem->>'paymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (elem->>'dueDate')::TIMESTAMP,
            elem->>'referenceNumber',
            p_cod_usuario,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_formas_pago_json) elem;
    END IF;

    -- Marcar el pedido como facturado
    UPDATE doc."SalesDocument"
    SET "IsInvoiced" = 'S',
        "Notes"      = CONCAT(COALESCE("Notes", ''), ' | Facturado como ', p_num_doc_factura,
                        ' el ', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                        ' por ', p_cod_usuario),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_pedido
      AND "OperationType" = 'PEDIDO'
      AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT TRUE, p_num_doc_pedido, p_num_doc_factura,
        ('Factura ' || p_num_doc_factura || ' generada exitosamente desde pedido ' || p_num_doc_pedido)::TEXT;
END;
$$;

-- =============================================================================
-- 7. usp_Doc_SalesDocument_Upsert
-- Insertar o reemplazar un documento de venta completo.
-- Sincroniza ar.ReceivableDocument para FACT/NOTADEB/NOTACRED.
-- Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_salesdocument_upsert(
    p_tipo_operacion  VARCHAR(20),
    p_header_json     JSONB,
    p_detail_json     JSONB,
    p_payments_json   JSONB          DEFAULT NULL,
    p_doc_origen      VARCHAR(60)    DEFAULT NULL,
    p_tipo_doc_origen VARCHAR(20)    DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "numDoc" VARCHAR, "detalleRows" INT, "formasPagoRows" INT, "pendingAmount" NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_num_doc           VARCHAR(60);
    v_detalle_rows      INT := 0;
    v_formas_pago_rows  INT := 0;
    v_pending_amount    NUMERIC(18,4) := 0;
    -- Header fields
    v_serial_type       VARCHAR(60);
    v_fiscal_memory     VARCHAR(10);
    v_customer_code     VARCHAR(60);
    v_customer_name     VARCHAR(200);
    v_fiscal_id         VARCHAR(60);
    v_document_date     TIMESTAMP;
    v_due_date          TIMESTAMP;
    v_document_time     VARCHAR(20);
    v_sub_total         NUMERIC(18,4);
    v_taxable_amount    NUMERIC(18,4);
    v_exempt_amount     NUMERIC(18,4);
    v_tax_amount        NUMERIC(18,4);
    v_tax_rate          NUMERIC(8,4);
    v_total_amount      NUMERIC(18,4);
    v_discount_amount   NUMERIC(18,4);
    v_is_voided         BOOLEAN;
    v_is_paid           VARCHAR(10);
    v_is_invoiced       VARCHAR(10);
    v_is_delivered      VARCHAR(10);
    v_origin_doc_number VARCHAR(60);
    v_origin_doc_type   VARCHAR(20);
    v_control_number    VARCHAR(60);
    v_is_legal          VARCHAR(10);
    v_is_printed        BOOLEAN;
    v_notes             TEXT;
    v_concept           VARCHAR(200);
    v_payment_terms     VARCHAR(100);
    v_ship_to_address   VARCHAR(500);
    v_seller_code       VARCHAR(60);
    v_department_code   VARCHAR(60);
    v_location_code     VARCHAR(60);
    v_currency_code     VARCHAR(10);
    v_exchange_rate     NUMERIC(18,6);
    v_user_code         VARCHAR(60);
    v_report_date       TIMESTAMP;
    v_host_name         VARCHAR(100);
    v_vehicle_plate     VARCHAR(30);
    v_mileage           NUMERIC(18,2);
    v_toll_amount       NUMERIC(18,4);
    -- AR sync
    v_cod_cliente       VARCHAR(60);
    v_company_id        INT;
    v_branch_id         INT;
    v_customer_id       BIGINT;
    v_user_id           INT;
    v_total_pagado      NUMERIC(18,4) := 0;
    v_ar_status         VARCHAR(20);
    v_ar_paid_flag      BOOLEAN;
BEGIN
    -- Parsear cabecera
    v_num_doc           := TRIM(p_header_json->>'DocumentNumber');
    v_serial_type       := COALESCE(p_header_json->>'SerialType', '');
    v_fiscal_memory     := COALESCE(p_header_json->>'FiscalMemoryNumber', '1');
    v_customer_code     := p_header_json->>'CustomerCode';
    v_customer_name     := p_header_json->>'CustomerName';
    v_fiscal_id         := p_header_json->>'FiscalId';
    v_document_date     := COALESCE((p_header_json->>'DocumentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC');
    v_due_date          := (p_header_json->>'DueDate')::TIMESTAMP;
    v_document_time     := p_header_json->>'DocumentTime';
    v_sub_total         := COALESCE((p_header_json->>'SubTotal')::NUMERIC, 0);
    v_taxable_amount    := (p_header_json->>'TaxableAmount')::NUMERIC;
    v_exempt_amount     := (p_header_json->>'ExemptAmount')::NUMERIC;
    v_tax_amount        := COALESCE((p_header_json->>'TaxAmount')::NUMERIC, 0);
    v_tax_rate          := COALESCE((p_header_json->>'TaxRate')::NUMERIC, 0);
    v_total_amount      := COALESCE((p_header_json->>'TotalAmount')::NUMERIC, 0);
    v_discount_amount   := (p_header_json->>'DiscountAmount')::NUMERIC;
    v_is_voided         := COALESCE((p_header_json->>'IsVoided')::BOOLEAN, FALSE);
    v_is_paid           := COALESCE(p_header_json->>'IsPaid', 'N');
    v_is_invoiced       := COALESCE(p_header_json->>'IsInvoiced', 'N');
    v_is_delivered      := COALESCE(p_header_json->>'IsDelivered', 'N');
    v_origin_doc_number := COALESCE(p_doc_origen, p_header_json->>'OriginDocumentNumber');
    v_origin_doc_type   := COALESCE(p_tipo_doc_origen, p_header_json->>'OriginDocumentType');
    v_control_number    := p_header_json->>'ControlNumber';
    v_is_legal          := p_header_json->>'IsLegal';
    v_is_printed        := (p_header_json->>'IsPrinted')::BOOLEAN;
    v_notes             := p_header_json->>'Notes';
    v_concept           := p_header_json->>'Concept';
    v_payment_terms     := p_header_json->>'PaymentTerms';
    v_ship_to_address   := p_header_json->>'ShipToAddress';
    v_seller_code       := p_header_json->>'SellerCode';
    v_department_code   := p_header_json->>'DepartmentCode';
    v_location_code     := p_header_json->>'LocationCode';
    v_currency_code     := p_header_json->>'CurrencyCode';
    v_exchange_rate     := (p_header_json->>'ExchangeRate')::NUMERIC;
    v_user_code         := p_header_json->>'UserCode';
    v_report_date       := COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC');
    v_host_name         := p_header_json->>'HostName';
    v_vehicle_plate     := p_header_json->>'VehiclePlate';
    v_mileage           := (p_header_json->>'Mileage')::NUMERIC;
    v_toll_amount       := (p_header_json->>'TollAmount')::NUMERIC;

    -- Validar DocumentNumber
    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, 0, 0, 0::NUMERIC;
        RETURN;
    END IF;

    -- DELETE existente (detalle, pagos, cabecera)
    DELETE FROM doc."SalesDocumentLine"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM doc."SalesDocumentPayment"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM doc."SalesDocument"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    -- INSERT cabecera
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "DocumentDate", "DueDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsInvoiced", "IsDelivered",
        "OriginDocumentNumber", "OriginDocumentType",
        "ControlNumber", "IsLegal", "IsPrinted",
        "Notes", "Concept", "PaymentTerms", "ShipToAddress",
        "SellerCode", "DepartmentCode", "LocationCode",
        "CurrencyCode", "ExchangeRate",
        "UserCode", "ReportDate", "HostName",
        "VehiclePlate", "Mileage", "TollAmount",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    )
    VALUES (
        v_num_doc, v_serial_type, v_fiscal_memory, p_tipo_operacion,
        v_customer_code, v_customer_name, v_fiscal_id,
        v_document_date, v_due_date, v_document_time,
        v_sub_total, v_taxable_amount, v_exempt_amount, v_tax_amount, v_tax_rate,
        v_total_amount, v_discount_amount,
        v_is_voided, v_is_paid, v_is_invoiced, v_is_delivered,
        v_origin_doc_number, v_origin_doc_type,
        v_control_number, v_is_legal, v_is_printed,
        v_notes, v_concept, v_payment_terms, v_ship_to_address,
        v_seller_code, v_department_code, v_location_code,
        v_currency_code, v_exchange_rate,
        v_user_code, v_report_date, v_host_name,
        v_vehicle_plate, v_mileage, v_toll_amount,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    );

    -- INSERT lineas de detalle desde JSONB
    IF p_detail_json IS NOT NULL AND jsonb_array_length(p_detail_json) > 0 THEN
        INSERT INTO doc."SalesDocumentLine" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "LineNumber", "ProductCode", "Description", "AlternateCode",
            "Quantity", "UnitPrice", "DiscountedPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "RelatedRef",
            "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        SELECT
            v_num_doc,
            COALESCE(elem->>'SerialType', v_serial_type),
            COALESCE(elem->>'FiscalMemoryNumber', v_fiscal_memory),
            p_tipo_operacion,
            (elem->>'LineNumber')::INT,
            elem->>'ProductCode',
            elem->>'Description',
            elem->>'AlternateCode',
            COALESCE((elem->>'Quantity')::NUMERIC, 0),
            COALESCE((elem->>'UnitPrice')::NUMERIC, 0),
            (elem->>'DiscountedPrice')::NUMERIC,
            (elem->>'UnitCost')::NUMERIC,
            COALESCE((elem->>'SubTotal')::NUMERIC, 0),
            COALESCE((elem->>'DiscountAmount')::NUMERIC, 0),
            COALESCE((elem->>'TotalAmount')::NUMERIC, 0),
            COALESCE((elem->>'TaxRate')::NUMERIC, 0),
            COALESCE((elem->>'TaxAmount')::NUMERIC, 0),
            COALESCE((elem->>'IsVoided')::BOOLEAN, FALSE),
            elem->>'RelatedRef',
            COALESCE(elem->>'UserCode', v_user_code),
            COALESCE((elem->>'LineDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        FROM jsonb_array_elements(p_detail_json) elem;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    -- INSERT formas de pago desde JSONB
    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
        INSERT INTO doc."SalesDocumentPayment" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "AmountBs", "ExchangeRate",
            "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        SELECT
            v_num_doc,
            COALESCE(elem->>'SerialType', v_serial_type),
            COALESCE(elem->>'FiscalMemoryNumber', v_fiscal_memory),
            p_tipo_operacion,
            elem->>'PaymentMethod',
            elem->>'BankCode',
            elem->>'PaymentNumber',
            COALESCE((elem->>'Amount')::NUMERIC, 0),
            COALESCE((elem->>'AmountBs')::NUMERIC, 0),
            COALESCE((elem->>'ExchangeRate')::NUMERIC, 1),
            COALESCE((elem->>'PaymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (elem->>'DueDate')::TIMESTAMP,
            elem->>'ReferenceNumber',
            COALESCE(elem->>'UserCode', v_user_code),
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        FROM jsonb_array_elements(p_payments_json) elem;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- Sincronizar cuenta por cobrar para FACT/NOTADEB/NOTACRED
    IF p_tipo_operacion IN ('FACT', 'NOTADEB', 'NOTACRED') THEN
        v_cod_cliente := TRIM(COALESCE(v_customer_code, ''));

        IF v_cod_cliente <> '' THEN
            -- Resolver contexto canonico
            SELECT c."CompanyId" INTO v_company_id
            FROM cfg."Company" c
            WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
            ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
            LIMIT 1;

            SELECT b."BranchId" INTO v_branch_id
            FROM cfg."Branch" b
            WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
            ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
            LIMIT 1;

            SELECT "CustomerId" INTO v_customer_id
            FROM master."Customer"
            WHERE "CustomerCode" = v_cod_cliente
              AND "CompanyId" = v_company_id
              AND "IsDeleted" = FALSE
            LIMIT 1;

            IF v_customer_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                -- Calcular monto pendiente
                IF UPPER(v_is_paid) = 'S' THEN
                    v_pending_amount := 0;
                ELSE
                    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
                        SELECT COALESCE(SUM(COALESCE((elem->>'Amount')::NUMERIC, 0)), 0)
                        INTO v_total_pagado
                        FROM jsonb_array_elements(p_payments_json) elem
                        WHERE UPPER(COALESCE(elem->>'PaymentMethod', '')) NOT LIKE '%SALDO%';
                    END IF;

                    v_pending_amount := CASE
                        WHEN v_total_amount - v_total_pagado > 0 THEN v_total_amount - v_total_pagado
                        ELSE 0
                    END;
                END IF;

                -- Determinar status
                v_ar_status := CASE
                    WHEN v_pending_amount <= 0              THEN 'PAID'
                    WHEN v_pending_amount < v_total_amount  THEN 'PARTIAL'
                    ELSE                                         'PENDING'
                END;
                v_ar_paid_flag := (v_pending_amount <= 0);

                -- Resolver UserId
                IF v_user_code IS NOT NULL AND v_user_code <> '' THEN
                    SELECT "UserId" INTO v_user_id
                    FROM sec."User"
                    WHERE "UserCode" = v_user_code AND "IsDeleted" = FALSE
                    LIMIT 1;
                END IF;

                -- Upsert ar.ReceivableDocument
                IF EXISTS (
                    SELECT 1 FROM ar."ReceivableDocument"
                    WHERE "CompanyId" = v_company_id
                      AND "BranchId"  = v_branch_id
                      AND "DocumentType"   = p_tipo_operacion
                      AND "DocumentNumber" = v_num_doc
                ) THEN
                    UPDATE ar."ReceivableDocument"
                    SET "CustomerId"      = v_customer_id,
                        "IssueDate"       = v_document_date,
                        "DueDate"         = COALESCE(v_due_date, v_document_date),
                        "TotalAmount"     = v_total_amount,
                        "PendingAmount"   = v_pending_amount,
                        "PaidFlag"        = v_ar_paid_flag,
                        "Status"          = v_ar_status,
                        "Notes"           = v_notes,
                        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
                        "UpdatedByUserId" = v_user_id
                    WHERE "CompanyId"      = v_company_id
                      AND "BranchId"       = v_branch_id
                      AND "DocumentType"   = p_tipo_operacion
                      AND "DocumentNumber" = v_num_doc;
                ELSE
                    INSERT INTO ar."ReceivableDocument" (
                        "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
                        "IssueDate", "DueDate", "CurrencyCode",
                        "TotalAmount", "PendingAmount", "PaidFlag", "Status", "Notes",
                        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                    )
                    VALUES (
                        v_company_id, v_branch_id, v_customer_id, p_tipo_operacion, v_num_doc,
                        v_document_date, COALESCE(v_due_date, v_document_date), COALESCE(v_currency_code, 'USD'),
                        v_total_amount, v_pending_amount, v_ar_paid_flag, v_ar_status, v_notes,
                        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                    );
                END IF;

                -- Actualizar saldo del cliente
                PERFORM usp_master_customer_updatebalance(v_customer_id, v_user_id);
            END IF;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, v_detalle_rows, v_formas_pago_rows, v_pending_amount;
END;
$$;
