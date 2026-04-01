-- +goose Up
-- Migration: Add CompanyId filtering to AR/AP stored procedures
-- The tables ar."SalesDocument", ap."PurchaseDocument" and their related line/payment
-- tables now have a "CompanyId" column (added in migration 00058).
-- This migration updates all GET/LIST/detail/payment functions to filter by CompanyId.

-- ============================================================================
-- 1) usp_doc_salesdocument_get
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_get(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS SETOF ar."SalesDocument"
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM ar."SalesDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND "CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 2) usp_doc_salesdocument_getdetail
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_getdetail(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS SETOF ar."SalesDocumentLine"
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM ar."SalesDocumentLine"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND "CompanyId" = p_company_id
    ORDER BY COALESCE("LineNumber", 0), "LineId";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 3) usp_doc_salesdocument_getpayments
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_getpayments(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS SETOF ar."SalesDocumentPayment"
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM ar."SalesDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 4) usp_doc_salesdocument_invoicefromorder
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_invoicefromorder(
    p_company_id INTEGER,
    p_num_doc_pedido character varying,
    p_num_doc_factura character varying,
    p_formas_pago_json jsonb DEFAULT NULL::jsonb,
    p_cod_usuario character varying DEFAULT 'API'::character varying
) RETURNS TABLE(ok boolean, pedido character varying, factura character varying, mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_elem JSONB;
BEGIN
    -- Validar que el pedido existe
    IF NOT EXISTS (
        SELECT 1 FROM ar."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('Pedido no encontrado: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta anulado
    IF EXISTS (
        SELECT 1 FROM ar."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
          AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido esta anulado y no puede facturarse: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no fue ya facturado
    IF EXISTS (
        SELECT 1 FROM ar."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsInvoiced" = 'S'
          AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido ya fue facturado previamente: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Copiar cabecera del pedido como nueva factura
    INSERT INTO ar."SalesDocument" (
        "CompanyId",
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
        p_company_id,
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
    FROM ar."SalesDocument" s
    WHERE s."DocumentNumber" = p_num_doc_pedido
      AND s."OperationType" = 'PEDIDO'
      AND s."IsDeleted" = FALSE
      AND s."CompanyId" = p_company_id;

    -- Copiar lineas del pedido a la factura
    INSERT INTO ar."SalesDocumentLine" (
        "CompanyId",
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
        p_company_id,
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
    FROM ar."SalesDocumentLine" sl
    WHERE sl."DocumentNumber" = p_num_doc_pedido
      AND sl."OperationType" = 'PEDIDO'
      AND sl."IsDeleted" = FALSE
      AND sl."CompanyId" = p_company_id;

    -- Insertar formas de pago desde JSONB si se proporcionaron
    IF p_formas_pago_json IS NOT NULL AND jsonb_array_length(p_formas_pago_json) > 0 THEN
        INSERT INTO ar."SalesDocumentPayment" (
            "CompanyId",
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "AmountBs", "ExchangeRate",
            "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_company_id,
            p_num_doc_factura,
            COALESCE(elem->>'serialType',''::VARCHAR),
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
    UPDATE ar."SalesDocument"
    SET "IsInvoiced" = 'S',
        "Notes"      = CONCAT(COALESCE("Notes",''::VARCHAR), ' | Facturado como ', p_num_doc_factura,
                        ' el ', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                        ' por ', p_cod_usuario),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_pedido
      AND "OperationType" = 'PEDIDO'
      AND "IsDeleted" = FALSE
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT TRUE, p_num_doc_pedido, p_num_doc_factura,
        ('Factura ' || p_num_doc_factura || ' generada exitosamente desde pedido ' || p_num_doc_pedido)::TEXT;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 5) usp_doc_salesdocument_list
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_list(
    p_company_id INTEGER,
    p_tipo_operacion character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50,
    p_search character varying DEFAULT NULL::character varying,
    p_codigo character varying DEFAULT NULL::character varying,
    p_from_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
    p_to_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
    p_estado character varying DEFAULT NULL::character varying
) RETURNS TABLE("SalesDocumentId" bigint, "DocumentNumber" character varying, "SerialType" character varying, "FiscalMemoryNumber" character varying, "OperationType" character varying, "CustomerCode" character varying, "CustomerName" character varying, "FiscalId" character varying, "DocumentDate" timestamp without time zone, "DueDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" numeric, "TaxableAmount" numeric, "ExemptAmount" numeric, "TaxAmount" numeric, "TaxRate" numeric, "TotalAmount" numeric, "DiscountAmount" numeric, "IsVoided" boolean, "IsPaid" character varying, "IsInvoiced" character varying, "IsDelivered" character varying, "OriginDocumentNumber" character varying, "OriginDocumentType" character varying, "ControlNumber" character varying, "IsLegal" character varying, "IsPrinted" boolean, "Notes" character varying, "Concept" character varying, "PaymentTerms" character varying, "ShipToAddress" character varying, "SellerCode" character varying, "DepartmentCode" character varying, "LocationCode" character varying, "CurrencyCode" character varying, "ExchangeRate" numeric, "UserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "VehiclePlate" character varying, "Mileage" numeric, "TollAmount" numeric, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "IsDeleted" boolean, "TotalCount" bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."SalesDocument" sd_c
    WHERE COALESCE(sd_c."IsDeleted", FALSE) = FALSE
      AND sd_c."CompanyId" = p_company_id
      AND (p_tipo_operacion IS NULL OR sd_c."OperationType" = p_tipo_operacion)
      AND (p_search IS NULL OR (
            sd_c."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd_c."CustomerName" LIKE '%' || p_search || '%'
            OR sd_c."FiscalId"     LIKE '%' || p_search || '%'
           ))
      AND (p_codigo    IS NULL OR sd_c."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd_c."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR sd_c."IssueDate" <  (p_to_date + INTERVAL '1 day'))
      AND (p_estado IS NULL OR
        CASE
          WHEN sd_c."IsVoided" = TRUE THEN 'Anulada'
          WHEN sd_c."IsCanceled" = 'S' THEN 'Pagada'
          ELSE 'Emitida'
        END = p_estado);

    RETURN QUERY
    SELECT
        sd."DocumentId"::bigint,
        sd."DocumentNumber"::VARCHAR,
        sd."SerialType"::VARCHAR,
        sd."FiscalMemoryNumber"::VARCHAR,
        sd."OperationType"::VARCHAR,
        sd."CustomerCode"::VARCHAR,
        sd."CustomerName"::VARCHAR,
        sd."FiscalId"::VARCHAR,
        sd."IssueDate",
        sd."DueDate",
        sd."DocumentTime"::VARCHAR,
        sd."Subtotal"::numeric,
        sd."TaxableAmount"::numeric,
        sd."ExemptAmount"::numeric,
        sd."TaxAmount"::numeric,
        sd."TaxRate"::numeric,
        sd."TotalAmount"::numeric,
        sd."DiscountAmount"::numeric,
        sd."IsVoided",
        sd."IsCanceled"::VARCHAR,
        sd."IsInvoiced"::VARCHAR,
        sd."IsDelivered"::VARCHAR,
        sd."SourceDocumentNumber"::VARCHAR,
        sd."SourceDocumentType"::VARCHAR,
        sd."ControlNumber"::VARCHAR,
        NULL::VARCHAR,
        NULL::boolean,
        sd."Notes"::VARCHAR,
        sd."Concept"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        sd."CurrencyCode"::VARCHAR,
        sd."ExchangeRate"::numeric,
        sd."LegacyUserCode"::VARCHAR,
        NULL::timestamp,
        NULL::VARCHAR,
        NULL::VARCHAR,
        NULL::numeric,
        NULL::numeric,
        sd."CreatedAt",
        sd."UpdatedAt",
        COALESCE(sd."IsDeleted", FALSE),
        v_total
    FROM doc."SalesDocument" sd
    WHERE COALESCE(sd."IsDeleted", FALSE) = FALSE
      AND sd."CompanyId" = p_company_id
      AND (p_tipo_operacion IS NULL OR sd."OperationType" = p_tipo_operacion)
      AND (p_search IS NULL OR (
            sd."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd."CustomerName" LIKE '%' || p_search || '%'
            OR sd."FiscalId"     LIKE '%' || p_search || '%'
           ))
      AND (p_codigo    IS NULL OR sd."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR sd."IssueDate" <  (p_to_date + INTERVAL '1 day'))
      AND (p_estado IS NULL OR
        CASE
          WHEN sd."IsVoided" = TRUE THEN 'Anulada'
          WHEN sd."IsCanceled" = 'S' THEN 'Pagada'
          ELSE 'Emitida'
        END = p_estado)
    ORDER BY sd."IssueDate" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 6) usp_doc_purchasedocument_get
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_get(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS TABLE("DocumentId" integer, "DocumentNumber" character varying, "SerialType" character varying, "OperationType" character varying, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "DocumentDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReceiptDate" timestamp without time zone, "PaymentDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" numeric, "TaxableAmount" numeric, "ExemptAmount" numeric, "TaxAmount" numeric, "TaxRate" numeric, "TotalAmount" numeric, "DiscountAmount" numeric, "IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying, "IsLegal" boolean, "OriginDocumentNumber" character varying, "ControlNumber" character varying, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "RetainedTax" numeric, "IsrCode" character varying, "IsrAmount" numeric, "IsrSubjectCode" character varying, "IsrSubjectAmount" numeric, "RetentionRate" numeric, "ImportAmount" numeric, "ImportTax" numeric, "ImportBase" numeric, "FreightAmount" numeric, "Notes" character varying, "Concept" character varying, "OrderNumber" character varying, "ReceivedBy" character varying, "WarehouseCode" character varying, "CurrencyCode" character varying, "ExchangeRate" numeric, "UsdAmount" numeric, "UserCode" character varying, "ShortUserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."DocumentId",
        d."DocumentNumber",
        d."SerialType",
        d."OperationType",
        d."SupplierCode",
        d."SupplierName",
        d."FiscalId",
        d."DocumentDate",
        d."DueDate",
        d."ReceiptDate",
        d."PaymentDate",
        d."DocumentTime",
        d."SubTotal",
        d."TaxableAmount",
        d."ExemptAmount",
        d."TaxAmount",
        d."TaxRate",
        d."TotalAmount",
        d."DiscountAmount",
        d."IsVoided",
        d."IsPaid",
        d."IsReceived",
        d."IsLegal",
        d."OriginDocumentNumber",
        d."ControlNumber",
        d."VoucherNumber",
        d."VoucherDate",
        d."RetainedTax",
        d."IsrCode",
        d."IsrAmount",
        NULL::VARCHAR,
        d."IsrSubjectAmount",
        d."RetentionRate",
        d."ImportAmount",
        d."ImportTax",
        d."ImportBase",
        d."FreightAmount",
        d."Notes",
        d."Concept",
        d."OrderNumber",
        d."ReceivedBy",
        d."WarehouseCode",
        d."CurrencyCode",
        d."ExchangeRate",
        d."UsdAmount",
        d."UserCode",
        d."ShortUserCode",
        d."ReportDate",
        d."HostName",
        d."IsDeleted",
        d."CreatedAt",
        d."UpdatedAt"
    FROM ap."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."OperationType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
      AND d."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 7) usp_doc_purchasedocument_getdetail
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_getdetail(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS TABLE("LineId" integer, "DocumentNumber" character varying, "OperationType" character varying, "LineNumber" integer, "ProductCode" character varying, "Description" character varying, "Quantity" numeric, "UnitPrice" numeric, "UnitCost" numeric, "SubTotal" numeric, "DiscountAmount" numeric, "TotalAmount" numeric, "TaxRate" numeric, "TaxAmount" numeric, "IsVoided" boolean, "IsDeleted" boolean, "UserCode" character varying, "LineDate" timestamp without time zone, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."LineId",
        l."DocumentNumber",
        l."OperationType",
        l."LineNumber",
        l."ProductCode",
        l."Description",
        l."Quantity",
        l."UnitPrice",
        l."UnitCost",
        l."SubTotal",
        l."DiscountAmount",
        l."TotalAmount",
        l."TaxRate",
        l."TaxAmount",
        l."IsVoided",
        l."IsDeleted",
        l."UserCode",
        l."LineDate",
        l."CreatedAt",
        l."UpdatedAt"
    FROM ap."PurchaseDocumentLine" l
    WHERE l."DocumentNumber" = p_num_doc
      AND l."OperationType" = p_tipo_operacion
      AND l."IsDeleted" = FALSE
      AND l."CompanyId" = p_company_id
    ORDER BY COALESCE(l."LineNumber", 0), l."LineId";
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 8) usp_doc_purchasedocument_getpayments
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_getpayments(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS TABLE("PaymentId" integer, "DocumentNumber" character varying, "OperationType" character varying, "PaymentMethod" character varying, "BankCode" character varying, "PaymentNumber" character varying, "Amount" numeric, "PaymentDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReferenceNumber" character varying, "UserCode" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PaymentId",
        p."DocumentNumber",
        p."OperationType",
        p."PaymentMethod",
        p."BankCode",
        p."PaymentNumber",
        p."Amount",
        p."PaymentDate",
        p."DueDate",
        p."ReferenceNumber",
        p."UserCode",
        p."IsDeleted",
        p."CreatedAt",
        p."UpdatedAt"
    FROM ap."PurchaseDocumentPayment" p
    WHERE p."DocumentNumber" = p_num_doc
      AND p."OperationType" = p_tipo_operacion
      AND p."IsDeleted" = FALSE
      AND p."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 9) usp_doc_purchasedocument_list
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_list(
    p_company_id INTEGER,
    p_tipo_operacion character varying DEFAULT 'COMPRA'::character varying,
    p_search character varying DEFAULT NULL::character varying,
    p_codigo character varying DEFAULT NULL::character varying,
    p_from_date date DEFAULT NULL::date,
    p_to_date date DEFAULT NULL::date,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
) RETURNS TABLE("DocumentId" integer, "DocumentNumber" character varying, "SerialType" character varying, "OperationType" character varying, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "DocumentDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReceiptDate" timestamp without time zone, "PaymentDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" numeric, "TaxableAmount" numeric, "ExemptAmount" numeric, "TaxAmount" numeric, "TaxRate" numeric, "TotalAmount" numeric, "DiscountAmount" numeric, "IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying, "IsLegal" boolean, "OriginDocumentNumber" character varying, "ControlNumber" character varying, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "RetainedTax" numeric, "IsrCode" character varying, "IsrAmount" numeric, "IsrSubjectCode" character varying, "IsrSubjectAmount" numeric, "RetentionRate" numeric, "ImportAmount" numeric, "ImportTax" numeric, "ImportBase" numeric, "FreightAmount" numeric, "Notes" character varying, "Concept" character varying, "OrderNumber" character varying, "ReceivedBy" character varying, "WarehouseCode" character varying, "CurrencyCode" character varying, "ExchangeRate" numeric, "UsdAmount" numeric, "UserCode" character varying, "ShortUserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "TotalCount" bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_page   INT := GREATEST(COALESCE(p_page, 1), 1);
    v_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
BEGIN
    -- Contar total de registros que coinciden con los filtros
    SELECT COUNT(*) INTO v_total
    FROM ap."PurchaseDocument" pd_cnt
    WHERE pd_cnt."OperationType" = p_tipo_operacion
      AND pd_cnt."IsDeleted" = FALSE
      AND pd_cnt."CompanyId" = p_company_id
      AND (p_search IS NULL OR (
            pd_cnt."DocumentNumber" ILIKE '%' || p_search || '%'
            OR pd_cnt."SupplierName" ILIKE '%' || p_search || '%'
            OR pd_cnt."FiscalId" ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR pd_cnt."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR pd_cnt."DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR pd_cnt."DocumentDate" < (p_to_date + INTERVAL '1 day'));

    -- Retornar pagina de resultados
    RETURN QUERY
    SELECT
        d."DocumentId",
        d."DocumentNumber",
        d."SerialType",
        d."OperationType",
        d."SupplierCode",
        d."SupplierName",
        d."FiscalId",
        d."DocumentDate",
        d."DueDate",
        d."ReceiptDate",
        d."PaymentDate",
        d."DocumentTime",
        d."SubTotal",
        d."TaxableAmount",
        d."ExemptAmount",
        d."TaxAmount",
        d."TaxRate",
        d."TotalAmount",
        d."DiscountAmount",
        d."IsVoided",
        d."IsPaid",
        d."IsReceived",
        d."IsLegal",
        d."OriginDocumentNumber",
        d."ControlNumber",
        d."VoucherNumber",
        d."VoucherDate",
        d."RetainedTax",
        d."IsrCode",
        d."IsrAmount",
        NULL::VARCHAR,
        d."IsrSubjectAmount",
        d."RetentionRate",
        d."ImportAmount",
        d."ImportTax",
        d."ImportBase",
        d."FreightAmount",
        d."Notes",
        d."Concept",
        d."OrderNumber",
        d."ReceivedBy",
        d."WarehouseCode",
        d."CurrencyCode",
        d."ExchangeRate",
        d."UsdAmount",
        d."UserCode",
        d."ShortUserCode",
        d."ReportDate",
        d."HostName",
        d."IsDeleted",
        d."CreatedAt",
        d."UpdatedAt",
        v_total
    FROM ap."PurchaseDocument" d
    WHERE d."OperationType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
      AND d."CompanyId" = p_company_id
      AND (p_search IS NULL OR (
            d."DocumentNumber" ILIKE '%' || p_search || '%'
            OR d."SupplierName" ILIKE '%' || p_search || '%'
            OR d."FiscalId" ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR d."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR d."DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR d."DocumentDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY d."DocumentDate" DESC, d."DocumentNumber" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================================
-- 10) usp_doc_purchasedocument_getindicadores
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_getindicadores(
    p_company_id INTEGER,
    p_tipo_operacion character varying,
    p_num_doc character varying
) RETURNS TABLE("IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."IsVoided",
        d."IsPaid",
        d."IsReceived"
    FROM ap."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."OperationType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
      AND d."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Rollback requires restoring previous function signatures (without p_company_id parameter).
-- Since CREATE OR REPLACE was used with a different parameter list, PostgreSQL creates
-- new function overloads. To fully rollback, DROP the new overloads and ensure the
-- original functions (without p_company_id) are restored from the baseline.
-- This is a manual rollback step — restore from 005_functions.sql baseline if needed.
