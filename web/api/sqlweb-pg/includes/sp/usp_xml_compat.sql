-- #############################################################################
-- usp_xml_compat.sql  (PostgreSQL)
-- Stored procedures reescritos. Reemplaza XML por JSONB.
-- Formato JSONB esperado:
--   Objeto unico : {"Key1": "val1", "Key2": "val2"}
--   Array        : [{"K1": "v1"}, {"K1": "v2"}]
-- #############################################################################

-- =============================================================================
-- SP 1: usp_Doc_PurchaseDocument_Upsert (PostgreSQL - JSONB)
-- Crea o reemplaza un documento de compra completo (cabecera + detalle + pagos).
-- Para tipo COMPRA sincroniza ap."PayableDocument" y recalcula saldo proveedor.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_upsert(
    p_tipo_operacion  VARCHAR(20),
    p_header_json     JSONB,
    p_detail_json     JSONB,
    p_payments_json   JSONB DEFAULT NULL,
    p_doc_origen      VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "ok"              BOOLEAN,
    "numDoc"          VARCHAR,
    "detalleRows"     INT,
    "formasPagoRows"  INT,
    "pendingAmount"   DOUBLE PRECISION,
    "mensaje"         VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ok              BOOLEAN := FALSE;
    v_num_doc         VARCHAR(60);
    v_detalle_rows    INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount  DOUBLE PRECISION := 0;
    v_total_amount    DOUBLE PRECISION;
    v_supplier_code   VARCHAR(60);
    v_is_paid         VARCHAR(1);
    v_doc_date        TIMESTAMP;
    v_notes           VARCHAR(500);
    v_user_code       VARCHAR(60);
    v_company_id      INT;
    v_branch_id       INT;
    v_user_id         INT;
    v_supplier_id     BIGINT;
    v_safe_pending    DOUBLE PRECISION;
    v_status          VARCHAR(20);
    v_existing_id     BIGINT;
    r                 JSONB;
BEGIN
    -- Get document number from header
    v_num_doc := TRIM(p_header_json->>'DocumentNumber');

    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, v_num_doc, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de documento requerido (DocumentNumber)'::VARCHAR;
        RETURN;
    END IF;

    -- 1. Delete existing (idempotent)
    DELETE FROM doc."PurchaseDocumentPayment" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;
    DELETE FROM doc."PurchaseDocumentLine" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;
    DELETE FROM doc."PurchaseDocument" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

    -- 2. INSERT header from JSONB
    INSERT INTO doc."PurchaseDocument" (
        "DocumentNumber", "SerialType", "DocumentType",
        "SupplierCode", "SupplierName", "FiscalId",
        "IssueDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectCode", "IsrSubjectAmount", "RetentionRate",
        "ImportAmount", "ImportTax", "ImportBase", "FreightAmount",
        "Notes", "Concept", "OrderNumber", "ReceivedBy", "WarehouseCode",
        "CurrencyCode", "ExchangeRate", "UsdAmount",
        "UserCode", "ShortUserCode", "ReportDate", "HostName",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_num_doc,
        COALESCE(p_header_json->>'SerialType', ''),
        p_tipo_operacion,
        p_header_json->>'SupplierCode',
        p_header_json->>'SupplierName',
        p_header_json->>'FiscalId',
        COALESCE((p_header_json->>'IssueDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        (p_header_json->>'DueDate')::TIMESTAMP,
        (p_header_json->>'ReceiptDate')::TIMESTAMP,
        (p_header_json->>'PaymentDate')::TIMESTAMP,
        COALESCE(p_header_json->>'DocumentTime', TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE((p_header_json->>'SubTotal')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxableAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ExemptAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxRate')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TotalAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'DiscountAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'IsVoided')::BOOLEAN, FALSE),
        COALESCE(p_header_json->>'IsPaid', 'N'),
        COALESCE(p_header_json->>'IsReceived', 'N'),
        COALESCE((p_header_json->>'IsLegal')::BOOLEAN, FALSE),
        COALESCE(p_doc_origen, p_header_json->>'OriginDocumentNumber'),
        p_header_json->>'ControlNumber',
        p_header_json->>'WithholdingCertNumber',
        (p_header_json->>'WithholdingCertDate')::TIMESTAMP,
        COALESCE((p_header_json->>'WithheldTaxAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'IncomeTaxCode',
        COALESCE((p_header_json->>'IncomeTaxAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'IncomeTaxPercent',
        COALESCE((p_header_json->>'IsSubjectToIncomeTax')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'WithholdingRate')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'IsImport')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ImportTaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ImportTaxBase')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'FreightAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'Notes',
        p_header_json->>'Concept',
        p_header_json->>'OrderNumber',
        p_header_json->>'ReceivedBy',
        p_header_json->>'WarehouseCode',
        COALESCE(p_header_json->>'CurrencyCode', 'BS'),
        COALESCE((p_header_json->>'ExchangeRate')::DOUBLE PRECISION, 1),
        COALESCE((p_header_json->>'DollarPrice')::DOUBLE PRECISION, 0),
        COALESCE(p_header_json->>'UserCode', 'API'),
        p_header_json->>'ShortUserCode',
        COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        COALESCE(p_header_json->>'HostName', inet_client_addr()::TEXT),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    );

    -- 3. INSERT detail lines from JSONB array
    INSERT INTO doc."PurchaseDocumentLine" (
        "DocumentNumber", "DocumentType", "LineNumber",
        "ProductCode", "Description",
        "Quantity", "UnitPrice", "UnitCost",
        "SubTotal", "DiscountAmount", "TotalAmount",
        "TaxRate", "TaxAmount",
        "IsVoided", "UserCode", "LineDate",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        v_num_doc,
        p_tipo_operacion,
        (r->>'LineNumber')::INT,
        r->>'ProductCode',
        r->>'Description',
        COALESCE((r->>'Quantity')::DOUBLE PRECISION, 0),
        COALESCE((r->>'UnitPrice')::DOUBLE PRECISION, 0),
        COALESCE((r->>'UnitCost')::DOUBLE PRECISION, 0),
        COALESCE((r->>'SubTotal')::DOUBLE PRECISION, 0),
        COALESCE((r->>'DiscountAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TotalAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TaxRate')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'IsVoided')::BOOLEAN, FALSE),
        r->>'UserCode',
        COALESCE((r->>'LineDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM jsonb_array_elements(p_detail_json) AS r;

    GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;

    -- 4. INSERT payments from JSONB (if provided)
    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
        INSERT INTO doc."PurchaseDocumentPayment" (
            "DocumentNumber", "DocumentType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            v_num_doc,
            p_tipo_operacion,
            r->>'PaymentMethod',
            r->>'BankCode',
            r->>'PaymentNumber',
            COALESCE((r->>'Amount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'PaymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (r->>'DueDate')::TIMESTAMP,
            r->>'ReferenceNumber',
            r->>'UserCode',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_payments_json) AS r;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- 5. Sync ap."PayableDocument" for COMPRA
    IF p_tipo_operacion = 'COMPRA' THEN
        SELECT "TotalAmount", "SupplierCode", COALESCE("IsPaid", 'N'),
               "IssueDate", "Notes", "UserCode"
        INTO v_total_amount, v_supplier_code, v_is_paid,
             v_doc_date, v_notes, v_user_code
        FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

        v_pending_amount := CASE WHEN UPPER(v_is_paid) = 'S' THEN 0 ELSE v_total_amount END;

        IF v_supplier_code IS NOT NULL AND TRIM(v_supplier_code) <> '' THEN
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

            IF v_user_code IS NOT NULL THEN
                SELECT u."UserId" INTO v_user_id
                FROM sec."User" u
                WHERE u."UserCode" = v_user_code AND u."IsDeleted" = FALSE
                LIMIT 1;
            END IF;

            SELECT s."SupplierId" INTO v_supplier_id
            FROM master."Supplier" s
            WHERE s."SupplierCode" = v_supplier_code AND s."CompanyId" = v_company_id AND s."IsDeleted" = FALSE
            LIMIT 1;

            IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
                v_status := CASE
                    WHEN v_safe_pending <= 0 THEN 'PAID'
                    WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                SELECT pd."PayableDocumentId" INTO v_existing_id
                FROM ap."PayableDocument" pd
                WHERE pd."CompanyId" = v_company_id AND pd."BranchId" = v_branch_id
                  AND pd."DocumentType" = p_tipo_operacion AND pd."DocumentNumber" = v_num_doc
                LIMIT 1;

                IF v_existing_id IS NOT NULL THEN
                    UPDATE ap."PayableDocument"
                    SET "SupplierId" = v_supplier_id, "IssueDate" = v_doc_date, "DueDate" = v_doc_date,
                        "TotalAmount" = v_total_amount, "PendingAmount" = v_safe_pending,
                        "PaidFlag" = CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                        "Status" = v_status, "Notes" = v_notes,
                        "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = v_user_id
                    WHERE "PayableDocumentId" = v_existing_id;
                ELSE
                    INSERT INTO ap."PayableDocument" (
                        "CompanyId", "BranchId", "SupplierId",
                        "DocumentType", "DocumentNumber",
                        "IssueDate", "DueDate", "CurrencyCode",
                        "TotalAmount", "PendingAmount", "PaidFlag", "Status", "Notes",
                        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                    )
                    VALUES (
                        v_company_id, v_branch_id, v_supplier_id,
                        p_tipo_operacion, v_num_doc,
                        v_doc_date, v_doc_date, 'USD',
                        v_total_amount, v_safe_pending,
                        CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                        v_status, v_notes,
                        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                    );
                END IF;

                PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
            END IF;
        END IF;
    END IF;

    v_ok := TRUE;

    RETURN QUERY SELECT v_ok, v_num_doc, v_detalle_rows,
                        v_formas_pago_rows, v_pending_amount, ''::VARCHAR;
END;
$$;


-- =============================================================================
-- SP 2: usp_Doc_PurchaseDocument_ConvertOrder (PostgreSQL - JSONB)
-- Convierte una orden de compra en un documento de compra.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_convertorder(
    p_num_doc_orden       VARCHAR(60),
    p_num_doc_compra      VARCHAR(60),
    p_compra_override_json JSONB DEFAULT NULL,
    p_detalle_json        JSONB DEFAULT NULL,
    p_cod_usuario         VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE(
    "ok"              BOOLEAN,
    "orden"           VARCHAR,
    "compra"          VARCHAR,
    "detalleRows"     INT,
    "formasPagoRows"  INT,
    "pendingAmount"   DOUBLE PRECISION,
    "mensaje"         VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ok              BOOLEAN := FALSE;
    v_detalle_rows    INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount  DOUBLE PRECISION := 0;
    v_total_amount    DOUBLE PRECISION;
    v_supplier_code   VARCHAR(60);
    v_is_paid         VARCHAR(1);
    v_doc_date        TIMESTAMP;
    v_notes           VARCHAR(500);
    v_company_id      INT;
    v_branch_id       INT;
    v_user_id         INT;
    v_supplier_id     BIGINT;
    v_safe_pending    DOUBLE PRECISION;
    v_status          VARCHAR(20);
    v_existing_id     BIGINT;
BEGIN
    -- Validate params
    IF p_num_doc_orden IS NULL OR TRIM(p_num_doc_orden) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de orden requerido (@NumDocOrden)'::VARCHAR;
        RETURN;
    END IF;

    IF p_num_doc_compra IS NULL OR TRIM(p_num_doc_compra) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de compra requerido (@NumDocCompra)'::VARCHAR;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     ('Orden de compra no encontrada: ' || p_num_doc_orden)::VARCHAR;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE AND "IsVoided" = TRUE) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     ('La orden esta anulada y no puede convertirse: ' || p_num_doc_orden)::VARCHAR;
        RETURN;
    END IF;

    -- 1. Delete existing purchase (idempotent)
    DELETE FROM doc."PurchaseDocumentPayment" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocumentLine" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';

    -- 2. Copy header from order with overrides
    INSERT INTO doc."PurchaseDocument" (
        "DocumentNumber", "SerialType", "DocumentType",
        "SupplierCode", "SupplierName", "FiscalId",
        "IssueDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectCode", "IsrSubjectAmount", "RetentionRate",
        "ImportAmount", "ImportTax", "ImportBase", "FreightAmount",
        "Notes", "Concept", "OrderNumber", "ReceivedBy", "WarehouseCode",
        "CurrencyCode", "ExchangeRate", "UsdAmount",
        "UserCode", "ShortUserCode", "ReportDate", "HostName",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_compra,
        o."SerialType",
        'COMPRA',
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'SupplierCode' END, o."SupplierCode"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'SupplierName' END, o."SupplierName"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'FiscalId' END, o."FiscalId"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'IssueDate')::TIMESTAMP END, NOW() AT TIME ZONE 'UTC'),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'DueDate')::TIMESTAMP END, o."DueDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'ReceiptDate')::TIMESTAMP END, o."ReceiptDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'PaymentDate')::TIMESTAMP END, o."PaymentDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'DocumentTime' END, TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'SubTotal')::DOUBLE PRECISION END, o."SubTotal"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxableAmount')::DOUBLE PRECISION END, o."TaxableAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'ExemptAmount')::DOUBLE PRECISION END, o."ExemptAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxAmount')::DOUBLE PRECISION END, o."TaxAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxRate')::DOUBLE PRECISION END, o."TaxRate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TotalAmount')::DOUBLE PRECISION END, o."TotalAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'DiscountAmount')::DOUBLE PRECISION END, o."DiscountAmount"),
        FALSE,
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'IsPaid' END, 'N'),
        'N',
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'IsLegal')::BOOLEAN END, o."IsLegal"),
        p_num_doc_orden,
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'ControlNumber' END, o."ControlNumber"),
        o."VoucherNumber", o."VoucherDate", o."RetainedTax",
        o."IsrCode", o."IsrAmount", o."IsrSubjectCode", o."IsrSubjectAmount", o."RetentionRate",
        o."ImportAmount", o."ImportTax", o."ImportBase", o."FreightAmount",
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'Notes' END, o."Notes"),
        o."Concept", o."OrderNumber", o."ReceivedBy",
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'WarehouseCode' END, o."WarehouseCode"),
        COALESCE(o."CurrencyCode", 'BS'),
        COALESCE(o."ExchangeRate", 1),
        o."UsdAmount",
        p_cod_usuario,
        o."ShortUserCode",
        NOW() AT TIME ZONE 'UTC',
        inet_client_addr()::TEXT,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM doc."PurchaseDocument" o
    WHERE o."DocumentNumber" = p_num_doc_orden AND o."DocumentType" = 'ORDEN' AND o."IsDeleted" = FALSE;

    -- 3. Copy detail lines (from JSONB or from order)
    IF p_detalle_json IS NOT NULL AND jsonb_array_length(p_detalle_json) > 0 THEN
        INSERT INTO doc."PurchaseDocumentLine" (
            "DocumentNumber", "DocumentType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra, 'COMPRA',
            (r->>'LineNumber')::INT,
            r->>'ProductCode',
            r->>'Description',
            COALESCE((r->>'Quantity')::DOUBLE PRECISION, 0),
            COALESCE((r->>'UnitPrice')::DOUBLE PRECISION, 0),
            COALESCE((r->>'UnitCost')::DOUBLE PRECISION, 0),
            COALESCE((r->>'SubTotal')::DOUBLE PRECISION, 0),
            COALESCE((r->>'DiscountAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TotalAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TaxRate')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TaxAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'IsVoided')::BOOLEAN, FALSE),
            p_cod_usuario,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_detalle_json) AS r;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    ELSE
        INSERT INTO doc."PurchaseDocumentLine" (
            "DocumentNumber", "DocumentType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra, 'COMPRA',
            ol."LineNumber", ol."ProductCode", ol."Description",
            ol."Quantity", ol."UnitPrice", ol."UnitCost",
            ol."SubTotal", ol."DiscountAmount", ol."TotalAmount",
            ol."TaxRate", ol."TaxAmount",
            FALSE, p_cod_usuario, NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        FROM doc."PurchaseDocumentLine" ol
        WHERE ol."DocumentNumber" = p_num_doc_orden AND ol."DocumentType" = 'ORDEN' AND ol."IsDeleted" = FALSE;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    IF v_detalle_rows = 0 THEN
        RAISE EXCEPTION 'La orden no tiene lineas de detalle: %', p_num_doc_orden;
    END IF;

    -- 4. Mark order as received
    UPDATE doc."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes" = COALESCE("Notes", '') || ' | Convertida a compra ' || p_num_doc_compra
                  || ' el ' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI') || ' por ' || p_cod_usuario,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE;

    -- 5. Sync ap."PayableDocument"
    SELECT "TotalAmount", "SupplierCode", COALESCE("IsPaid", 'N'), "IssueDate", "Notes"
    INTO v_total_amount, v_supplier_code, v_is_paid, v_doc_date, v_notes
    FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';

    v_pending_amount := CASE WHEN UPPER(v_is_paid) = 'S' THEN 0 ELSE v_total_amount END;

    IF v_supplier_code IS NOT NULL AND TRIM(v_supplier_code) <> '' THEN
        SELECT c."CompanyId" INTO v_company_id FROM cfg."Company" c
        WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
        ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId" LIMIT 1;

        SELECT b."BranchId" INTO v_branch_id FROM cfg."Branch" b
        WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
        ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId" LIMIT 1;

        SELECT u."UserId" INTO v_user_id FROM sec."User" u
        WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE LIMIT 1;

        SELECT s."SupplierId" INTO v_supplier_id FROM master."Supplier" s
        WHERE s."SupplierCode" = v_supplier_code AND s."CompanyId" = v_company_id AND s."IsDeleted" = FALSE LIMIT 1;

        IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
            v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
            v_status := CASE
                WHEN v_safe_pending <= 0 THEN 'PAID'
                WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                ELSE 'PENDING'
            END;

            SELECT pd."PayableDocumentId" INTO v_existing_id FROM ap."PayableDocument" pd
            WHERE pd."CompanyId" = v_company_id AND pd."BranchId" = v_branch_id
              AND pd."DocumentType" = 'COMPRA' AND pd."DocumentNumber" = p_num_doc_compra LIMIT 1;

            IF v_existing_id IS NOT NULL THEN
                UPDATE ap."PayableDocument"
                SET "SupplierId" = v_supplier_id, "IssueDate" = v_doc_date, "DueDate" = v_doc_date,
                    "TotalAmount" = v_total_amount, "PendingAmount" = v_safe_pending,
                    "PaidFlag" = CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                    "Status" = v_status, "Notes" = v_notes,
                    "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = v_user_id
                WHERE "PayableDocumentId" = v_existing_id;
            ELSE
                INSERT INTO ap."PayableDocument" (
                    "CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber",
                    "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
                    "PaidFlag", "Status", "Notes",
                    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                )
                VALUES (
                    v_company_id, v_branch_id, v_supplier_id, 'COMPRA', p_num_doc_compra,
                    v_doc_date, v_doc_date, 'USD', v_total_amount, v_safe_pending,
                    CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                    v_status, v_notes,
                    NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                );
            END IF;

            PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
        END IF;
    END IF;

    v_ok := TRUE;

    RETURN QUERY SELECT v_ok, p_num_doc_orden, p_num_doc_compra,
                        v_detalle_rows, v_formas_pago_rows, v_pending_amount, ''::VARCHAR;
END;
$$;


-- =============================================================================
-- SP 3: usp_AR_Receivable_ApplyPayment (PostgreSQL - JSONB)
-- Aplica un cobro transaccional a documentos CxC de un cliente.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_receivable_applypayment(
    p_cod_cliente     VARCHAR(24),
    p_fecha           DATE DEFAULT NULL,
    p_request_id      VARCHAR(120) DEFAULT NULL,
    p_num_recibo      VARCHAR(120) DEFAULT NULL,
    p_documentos_json JSONB DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id BIGINT;
    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);
    v_applied     NUMERIC(18,2) := 0;
    v_doc         RECORD;
    v_doc_id      BIGINT;
    v_pending     NUMERIC(18,2);
    v_apply_amt   NUMERIC(18,2);
BEGIN
    SELECT c."CustomerId" INTO v_customer_id
    FROM master."Customer" c WHERE c."CustomerCode" = p_cod_cliente AND c."IsDeleted" = FALSE
    LIMIT 1;

    IF v_customer_id IS NULL OR v_customer_id <= 0 THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado en esquema canonico'::VARCHAR(500);
        RETURN;
    END IF;

    -- Iterar documentos JSONB
    FOR v_doc IN SELECT * FROM jsonb_array_elements(p_documentos_json) AS r
    LOOP
        v_doc_id := NULL;
        v_pending := NULL;

        SELECT rd."ReceivableDocumentId", rd."PendingAmount"
        INTO v_doc_id, v_pending
        FROM ar."ReceivableDocument" rd
        WHERE rd."CustomerId" = v_customer_id
          AND rd."DocumentType" = v_doc.r->>'tipoDoc'
          AND rd."DocumentNumber" = v_doc.r->>'numDoc'
          AND rd."Status" <> 'VOIDED'
        ORDER BY rd."ReceivableDocumentId" DESC
        LIMIT 1
        FOR UPDATE;

        v_apply_amt := CASE
            WHEN v_pending IS NULL THEN 0
            WHEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2) < v_pending THEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2)
            ELSE v_pending
        END;

        IF v_apply_amt > 0 AND v_doc_id IS NOT NULL THEN
            INSERT INTO ar."ReceivableApplication" (
                "ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"
            ) VALUES (v_doc_id, v_apply_date, v_apply_amt, CONCAT(p_request_id, ':', p_num_recibo));

            UPDATE ar."ReceivableDocument"
            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amt < 0 THEN 0
                                       ELSE "PendingAmount" - v_apply_amt END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amt <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                             WHEN "PendingAmount" - v_apply_amt <= 0 THEN 'PAID'
                             WHEN "PendingAmount" - v_apply_amt < "TotalAmount" THEN 'PARTIAL'
                             ELSE 'PENDING'
                           END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "ReceivableDocumentId" = v_doc_id;

            v_applied := v_applied + v_apply_amt;
        END IF;
    END LOOP;

    IF v_applied <= 0 THEN
        RAISE EXCEPTION 'No hay montos aplicables para cobrar';
    END IF;

    UPDATE master."Customer"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM("PendingAmount"), 0) FROM ar."ReceivableDocument"
            WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED'
        ),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CustomerId" = v_customer_id;

    RETURN QUERY SELECT 1, ('Cobro aplicado exitosamente. Monto: ' || v_applied::TEXT)::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en cobro: ' || SQLERRM)::VARCHAR(500);
END;
$$;


-- =============================================================================
-- SP 4: usp_AP_Payable_ApplyPayment (PostgreSQL - JSONB)
-- Aplica un pago transaccional a documentos CxP de un proveedor.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ap_payable_applypayment(
    p_cod_proveedor   VARCHAR(24),
    p_fecha           DATE DEFAULT NULL,
    p_request_id      VARCHAR(120) DEFAULT NULL,
    p_num_pago        VARCHAR(120) DEFAULT NULL,
    p_documentos_json JSONB DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_supplier_id BIGINT;
    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);
    v_applied     NUMERIC(18,2) := 0;
    v_doc         RECORD;
    v_doc_id      BIGINT;
    v_pending     NUMERIC(18,2);
    v_apply_amt   NUMERIC(18,2);
BEGIN
    SELECT s."SupplierId" INTO v_supplier_id
    FROM master."Supplier" s WHERE s."SupplierCode" = p_cod_proveedor AND s."IsDeleted" = FALSE
    LIMIT 1;

    IF v_supplier_id IS NULL OR v_supplier_id <= 0 THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado en esquema canonico'::VARCHAR(500);
        RETURN;
    END IF;

    -- Iterar documentos JSONB
    FOR v_doc IN SELECT * FROM jsonb_array_elements(p_documentos_json) AS r
    LOOP
        v_doc_id := NULL;
        v_pending := NULL;

        SELECT pd."PayableDocumentId", pd."PendingAmount"
        INTO v_doc_id, v_pending
        FROM ap."PayableDocument" pd
        WHERE pd."SupplierId" = v_supplier_id
          AND pd."DocumentType" = v_doc.r->>'tipoDoc'
          AND pd."DocumentNumber" = v_doc.r->>'numDoc'
          AND pd."Status" <> 'VOIDED'
        ORDER BY pd."PayableDocumentId" DESC
        LIMIT 1
        FOR UPDATE;

        v_apply_amt := CASE
            WHEN v_pending IS NULL THEN 0
            WHEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2) < v_pending THEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2)
            ELSE v_pending
        END;

        IF v_apply_amt > 0 AND v_doc_id IS NOT NULL THEN
            INSERT INTO ap."PayableApplication" (
                "PayableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"
            ) VALUES (v_doc_id, v_apply_date, v_apply_amt, CONCAT(p_request_id, ':', p_num_pago));

            UPDATE ap."PayableDocument"
            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amt < 0 THEN 0
                                       ELSE "PendingAmount" - v_apply_amt END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amt <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                             WHEN "PendingAmount" - v_apply_amt <= 0 THEN 'PAID'
                             WHEN "PendingAmount" - v_apply_amt < "TotalAmount" THEN 'PARTIAL'
                             ELSE 'PENDING'
                           END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "PayableDocumentId" = v_doc_id;

            v_applied := v_applied + v_apply_amt;
        END IF;
    END LOOP;

    IF v_applied <= 0 THEN
        RAISE EXCEPTION 'No hay montos aplicables para pagar';
    END IF;

    UPDATE master."Supplier"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM("PendingAmount"), 0) FROM ap."PayableDocument"
            WHERE "SupplierId" = v_supplier_id AND "Status" <> 'VOIDED'
        ),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "SupplierId" = v_supplier_id;

    RETURN QUERY SELECT 1, ('Pago aplicado exitosamente. Monto: ' || v_applied::TEXT)::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en pago: ' || SQLERRM)::VARCHAR(500);
END;
$$;


-- =============================================================================
-- SP 5: usp_HR_Payroll_UpsertRun (PostgreSQL - JSONB)
-- Inserta o actualiza un PayrollRun con sus lineas.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertrun(
    p_company_id         INT,
    p_branch_id          INT,
    p_payroll_code       VARCHAR(15),
    p_employee_id        BIGINT,
    p_employee_code      VARCHAR(24),
    p_employee_name      VARCHAR(200),
    p_from_date          DATE,
    p_to_date            DATE,
    p_total_assignments  NUMERIC(18,2),
    p_total_deductions   NUMERIC(18,2),
    p_net_total          NUMERIC(18,2),
    p_payroll_type_name  VARCHAR(50) DEFAULT NULL,
    p_user_id            INT DEFAULT NULL,
    p_lines_json         JSONB DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id BIGINT;
BEGIN
    -- Buscar run existente
    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId"    = p_company_id
      AND pr."BranchId"     = p_branch_id
      AND pr."PayrollCode"  = p_payroll_code
      AND pr."EmployeeCode" = p_employee_code
      AND pr."DateFrom"     = p_from_date
      AND pr."DateTo"       = p_to_date
      AND pr."RunSource"    = 'MANUAL'
    ORDER BY pr."PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NOT NULL THEN
        UPDATE hr."PayrollRun"
        SET "ProcessDate"      = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAssignments" = p_total_assignments,
            "TotalDeductions"  = p_total_deductions,
            "NetTotal"         = p_net_total,
            "PayrollTypeName"  = COALESCE(p_payroll_type_name, "PayrollTypeName"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "PayrollRunId" = v_run_id;

        DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    ELSE
        INSERT INTO hr."PayrollRun" (
            "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "PositionName", "ProcessDate", "DateFrom", "DateTo",
            "TotalAssignments", "TotalDeductions", "NetTotal", "PayrollTypeName",
            "RunSource", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_employee_id, p_employee_code,
            p_employee_name, NULL, (NOW() AT TIME ZONE 'UTC')::DATE, p_from_date, p_to_date,
            p_total_assignments, p_total_deductions, p_net_total, p_payroll_type_name,
            'MANUAL', p_user_id, p_user_id
        )
        RETURNING "PayrollRunId" INTO v_run_id;
    END IF;

    -- Insertar lineas desde JSONB
    IF p_lines_json IS NOT NULL AND jsonb_array_length(p_lines_json) > 0 THEN
        INSERT INTO hr."PayrollRunLine" (
            "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode"
        )
        SELECT
            v_run_id,
            r->>'code',
            r->>'name',
            r->>'type',
            (r->>'quantity')::NUMERIC(18,4),
            (r->>'amount')::NUMERIC(18,4),
            (r->>'total')::NUMERIC(18,2),
            r->>'description',
            r->>'account'
        FROM jsonb_array_elements(p_lines_json) AS r;
    END IF;

    RETURN QUERY SELECT 1, 'ok'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en upsert run: ' || SQLERRM)::VARCHAR(500);
END;
$$;


-- =============================================================================
-- SP 6: usp_Sys_HeaderDetailTx (PostgreSQL - JSONB)
-- Generic header+detail transaction insert.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_sys_headerdetailtx(
    p_header_table    VARCHAR(260),
    p_detail_table    VARCHAR(260),
    p_header_json     JSONB,
    p_details_json    JSONB,
    p_link_fields_csv VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "detailRows" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cols       TEXT;
    v_vals       TEXT;
    v_sql        TEXT;
    v_detail_count INT;
    v_row        JSONB;
    v_key        TEXT;
    v_val        TEXT;
    v_d_cols     TEXT;
    v_d_vals     TEXT;
    v_link_fields TEXT[];
    v_lf         TEXT;
BEGIN
    -- Build header INSERT dynamically from JSONB keys
    v_cols := '';
    v_vals := '';

    FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_header_json)
    LOOP
        IF v_cols <> '' THEN v_cols := v_cols || ', '; v_vals := v_vals || ', '; END IF;
        v_cols := v_cols || quote_ident(v_key);
        v_vals := v_vals || quote_literal(v_val);
    END LOOP;

    v_sql := 'INSERT INTO ' || p_header_table || ' (' || v_cols || ') VALUES (' || v_vals || ')';
    EXECUTE v_sql;

    -- Parse link fields
    IF p_link_fields_csv IS NOT NULL AND LENGTH(p_link_fields_csv) > 0 THEN
        v_link_fields := string_to_array(p_link_fields_csv, ',');
        FOR i IN 1..array_length(v_link_fields, 1) LOOP
            v_link_fields[i] := TRIM(v_link_fields[i]);
        END LOOP;
    ELSE
        v_link_fields := ARRAY[]::TEXT[];
    END IF;

    -- Process each detail row
    v_detail_count := jsonb_array_length(p_details_json);

    FOR i IN 0..v_detail_count-1
    LOOP
        v_row := p_details_json->i;

        -- Add header link fields if missing from detail row
        IF array_length(v_link_fields, 1) > 0 THEN
            FOREACH v_lf IN ARRAY v_link_fields
            LOOP
                IF v_row->>v_lf IS NULL AND p_header_json->>v_lf IS NOT NULL THEN
                    v_row := v_row || jsonb_build_object(v_lf, p_header_json->>v_lf);
                END IF;
            END LOOP;
        END IF;

        -- Build INSERT from row keys
        v_d_cols := '';
        v_d_vals := '';

        FOR v_key, v_val IN SELECT * FROM jsonb_each_text(v_row)
        LOOP
            IF v_d_cols <> '' THEN v_d_cols := v_d_cols || ', '; v_d_vals := v_d_vals || ', '; END IF;
            v_d_cols := v_d_cols || quote_ident(v_key);
            v_d_vals := v_d_vals || quote_literal(v_val);
        END LOOP;

        IF LENGTH(v_d_cols) > 0 THEN
            v_sql := 'INSERT INTO ' || p_detail_table || ' (' || v_d_cols || ') VALUES (' || v_d_vals || ')';
            EXECUTE v_sql;
        END IF;
    END LOOP;

    RETURN QUERY SELECT 1, v_detail_count;
END;
$$;
