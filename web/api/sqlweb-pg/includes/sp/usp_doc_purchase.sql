-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_doc_purchase.sql
-- Funciones de documentos de compra (esquema doc)
-- Tablas: doc.PurchaseDocument, doc.PurchaseDocumentLine, doc.PurchaseDocumentPayment
-- 9 funciones: List, Get, GetDetail, GetPayments, GetIndicadores, Void,
--              ReceiveOrder, Upsert, ConvertOrder
-- ============================================================

-- =============================================================================
-- 1. usp_Doc_PurchaseDocument_List
-- Lista paginada de documentos de compra con filtros.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_list(
    p_tipo_operacion VARCHAR(20)  DEFAULT 'COMPRA',
    p_search         VARCHAR(100) DEFAULT NULL,
    p_codigo         VARCHAR(60)  DEFAULT NULL,
    p_from_date      DATE         DEFAULT NULL,
    p_to_date        DATE         DEFAULT NULL,
    p_page           INT          DEFAULT 1,
    p_limit          INT          DEFAULT 50
)
RETURNS TABLE(
    "PurchaseDocumentId"    BIGINT,
    "DocumentNumber"        VARCHAR,
    "SerialType"            VARCHAR,
    "DocumentType"          VARCHAR,
    "SupplierCode"          VARCHAR,
    "SupplierName"          VARCHAR,
    "FiscalId"              VARCHAR,
    "IssueDate"             TIMESTAMP,
    "DueDate"               TIMESTAMP,
    "SubTotal"              NUMERIC,
    "TaxAmount"             NUMERIC,
    "TotalAmount"           NUMERIC,
    "IsVoided"              BOOLEAN,
    "IsPaid"                VARCHAR,
    "IsReceived"            VARCHAR,
    "Notes"                 TEXT,
    "CurrencyCode"          VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "TotalCount"            BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."PurchaseDocument"
    WHERE "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            "DocumentNumber" LIKE '%' || p_search || '%'
            OR "SupplierName" LIKE '%' || p_search || '%'
            OR "FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR "SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR "IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR "IssueDate" < (p_to_date + INTERVAL '1 day'));

    RETURN QUERY
    SELECT
        pd."PurchaseDocumentId",
        pd."DocumentNumber"::VARCHAR,
        pd."SerialType"::VARCHAR,
        pd."DocumentType"::VARCHAR,
        pd."SupplierCode"::VARCHAR,
        pd."SupplierName"::VARCHAR,
        pd."FiscalId"::VARCHAR,
        pd."IssueDate",
        pd."DueDate",
        pd."SubTotal",
        pd."TaxAmount",
        pd."TotalAmount",
        pd."IsVoided",
        pd."IsPaid"::VARCHAR,
        pd."IsReceived"::VARCHAR,
        pd."Notes"::TEXT,
        pd."CurrencyCode"::VARCHAR,
        pd."CreatedAt",
        pd."UpdatedAt",
        v_total
    FROM doc."PurchaseDocument" pd
    WHERE pd."DocumentType" = p_tipo_operacion
      AND pd."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            pd."DocumentNumber" LIKE '%' || p_search || '%'
            OR pd."SupplierName" LIKE '%' || p_search || '%'
            OR pd."FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR pd."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR pd."IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR pd."IssueDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY pd."IssueDate" DESC, pd."DocumentNumber" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
-- 2. usp_Doc_PurchaseDocument_Get
-- Obtener un documento de compra individual.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_get(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."PurchaseDocument"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- =============================================================================
-- 3. usp_Doc_PurchaseDocument_GetDetail
-- Obtener las lineas de detalle.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_getdetail(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."PurchaseDocumentLine"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM doc."PurchaseDocumentLine"
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    ORDER BY COALESCE("LineNumber", 0), "LineId";
END;
$$;

-- =============================================================================
-- 4. usp_Doc_PurchaseDocument_GetPayments
-- Obtener las formas de pago.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_getpayments(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS SETOF doc."PurchaseDocumentPayment"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM doc."PurchaseDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 5. usp_Doc_PurchaseDocument_GetIndicadores
-- Obtener indicadores clave: IsVoided, IsPaid, IsReceived.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_getindicadores(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60)
)
RETURNS TABLE("IsVoided" BOOLEAN, "IsPaid" VARCHAR, "IsReceived" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pd."IsVoided", pd."IsPaid"::VARCHAR, pd."IsReceived"::VARCHAR
    FROM doc."PurchaseDocument" pd
    WHERE pd."DocumentNumber" = p_num_doc
      AND pd."DocumentType" = p_tipo_operacion
      AND pd."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 6. usp_Doc_PurchaseDocument_Void
-- Anular un documento de compra. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_void(
    p_tipo_operacion VARCHAR(20),
    p_num_doc        VARCHAR(60),
    p_cod_usuario    VARCHAR(60)  DEFAULT 'API',
    p_motivo         VARCHAR(500) DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "numDoc" VARCHAR, "codProveedor" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod_proveedor VARCHAR(60);
    v_company_id    INT;
    v_branch_id     INT;
    v_supplier_id   BIGINT;
BEGIN
    -- Validar que el documento existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('Documento no encontrado: ' || p_num_doc || ' / ' || p_tipo_operacion)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta ya anulado
    IF EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('El documento ya se encuentra anulado: ' || p_num_doc)::TEXT;
        RETURN;
    END IF;

    -- Obtener codigo de proveedor
    SELECT "SupplierCode" INTO v_cod_proveedor
    FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular cabecera
    UPDATE doc."PurchaseDocument"
    SET "IsVoided"  = TRUE,
        "Notes"     = CONCAT(COALESCE("Notes", ''), ' | ANULADO ',
                       to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                       ' por ', p_cod_usuario,
                       CASE WHEN p_motivo <> '' THEN ' - Motivo: ' || p_motivo ELSE '' END),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular lineas
    UPDATE doc."PurchaseDocumentLine"
    SET "IsVoided"  = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Resolver contexto
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
    ORDER BY c."CompanyId" LIMIT 1;

    SELECT b."BranchId" INTO v_branch_id
    FROM cfg."Branch" b
    WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
    ORDER BY b."BranchId" LIMIT 1;

    SELECT "SupplierId" INTO v_supplier_id
    FROM master."Supplier"
    WHERE "SupplierCode" = v_cod_proveedor
      AND "CompanyId" = v_company_id
      AND "IsDeleted" = FALSE
    LIMIT 1;

    -- Actualizar cuenta por pagar si existe
    IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
        UPDATE ap."PayableDocument"
        SET "PendingAmount" = 0,
            "PaidFlag"      = TRUE,
            "Status"        = 'VOIDED',
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"      = v_company_id
          AND "BranchId"       = v_branch_id
          AND "DocumentNumber" = p_num_doc
          AND "DocumentType"   = p_tipo_operacion
          AND "SupplierId"     = v_supplier_id;

        -- Recalcular saldo total del proveedor
        UPDATE master."Supplier"
        SET "TotalBalance" = COALESCE((
                SELECT SUM("PendingAmount")
                FROM ap."PayableDocument"
                WHERE "SupplierId" = v_supplier_id
                  AND "Status" <> 'VOIDED'
            ), 0),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "SupplierId" = v_supplier_id;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc, v_cod_proveedor,
        ('Documento anulado exitosamente: ' || p_num_doc)::TEXT;
END;
$$;

-- =============================================================================
-- 7. usp_Doc_PurchaseDocument_ReceiveOrder
-- Marcar una orden de compra como recibida.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_receiveorder(
    p_num_doc     VARCHAR(60),
    p_cod_usuario VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE("ok" BOOLEAN, "numDoc" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('Orden de compra no encontrada: ' || p_num_doc)::TEXT;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('La orden esta anulada y no puede marcarse como recibida: ' || p_num_doc)::TEXT;
        RETURN;
    END IF;

    UPDATE doc."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes"      = CONCAT(COALESCE("Notes", ''), ' | Recibido ',
                        to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                        ' por ', p_cod_usuario),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = 'ORDEN'
      AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT TRUE, p_num_doc,
        ('Orden marcada como recibida exitosamente: ' || p_num_doc)::TEXT;
END;
$$;

-- =============================================================================
-- 8. usp_Doc_PurchaseDocument_Upsert
-- Crea o reemplaza un documento de compra completo.
-- Sincroniza ap.PayableDocument para tipo COMPRA.
-- Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_upsert(
    p_tipo_operacion VARCHAR(20),
    p_header_json    JSONB,
    p_detail_json    JSONB,
    p_payments_json  JSONB         DEFAULT NULL,
    p_doc_origen     VARCHAR(60)   DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "numDoc" VARCHAR, "detalleRows" INT, "formasPagoRows" INT, "pendingAmount" NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_num_doc          VARCHAR(60);
    v_detalle_rows     INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount   NUMERIC := 0;
    -- AP sync vars
    v_total_amount     NUMERIC;
    v_supplier_code    VARCHAR(60);
    v_is_paid          VARCHAR(1);
    v_doc_date         TIMESTAMP;
    v_notes            VARCHAR(500);
    v_user_code        VARCHAR(60);
    v_company_id       INT;
    v_branch_id        INT;
    v_user_id          INT;
    v_supplier_id      BIGINT;
    v_safe_pending     NUMERIC;
    v_status           VARCHAR(20);
    v_existing_id      BIGINT;
BEGIN
    -- Parsear numero de documento
    v_num_doc := TRIM(p_header_json->>'DocumentNumber');

    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, 0, 0, 0::NUMERIC;
        RETURN;
    END IF;

    -- DELETE existente
    DELETE FROM doc."PurchaseDocumentPayment"
    WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

    DELETE FROM doc."PurchaseDocumentLine"
    WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

    DELETE FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

    -- INSERT cabecera desde JSONB
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
        COALESCE(p_header_json->>'DocumentTime', to_char(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE((p_header_json->>'SubTotal')::NUMERIC, 0),
        COALESCE((p_header_json->>'TaxableAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'ExemptAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'TaxAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'TaxRate')::NUMERIC, 0),
        COALESCE((p_header_json->>'TotalAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'DiscountAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'IsVoided')::BOOLEAN, FALSE),
        COALESCE(p_header_json->>'IsPaid', 'N'),
        COALESCE(p_header_json->>'IsReceived', 'N'),
        COALESCE((p_header_json->>'IsLegal')::BOOLEAN, FALSE),
        COALESCE(p_doc_origen, p_header_json->>'OriginDocumentNumber'),
        p_header_json->>'ControlNumber',
        p_header_json->>'WithholdingCertNumber',
        (p_header_json->>'WithholdingCertDate')::TIMESTAMP,
        COALESCE((p_header_json->>'WithheldTaxAmount')::NUMERIC, 0),
        p_header_json->>'IncomeTaxCode',
        COALESCE((p_header_json->>'IncomeTaxAmount')::NUMERIC, 0),
        p_header_json->>'IncomeTaxPercent',
        COALESCE((p_header_json->>'IsSubjectToIncomeTax')::NUMERIC, 0),
        COALESCE((p_header_json->>'WithholdingRate')::NUMERIC, 0),
        COALESCE((p_header_json->>'IsImport')::NUMERIC, 0),
        COALESCE((p_header_json->>'ImportTaxAmount')::NUMERIC, 0),
        COALESCE((p_header_json->>'ImportTaxBase')::NUMERIC, 0),
        COALESCE((p_header_json->>'FreightAmount')::NUMERIC, 0),
        p_header_json->>'Notes',
        p_header_json->>'Concept',
        p_header_json->>'OrderNumber',
        p_header_json->>'ReceivedBy',
        p_header_json->>'WarehouseCode',
        COALESCE(p_header_json->>'CurrencyCode', 'BS'),
        COALESCE((p_header_json->>'ExchangeRate')::NUMERIC, 1),
        COALESCE((p_header_json->>'DollarPrice')::NUMERIC, 0),
        COALESCE(p_header_json->>'UserCode', 'API'),
        p_header_json->>'ShortUserCode',
        COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        COALESCE(p_header_json->>'HostName', inet_client_addr()::TEXT),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC';

    -- INSERT lineas de detalle
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
        (elem->>'LineNumber')::INT,
        elem->>'ProductCode',
        elem->>'Description',
        COALESCE((elem->>'Quantity')::NUMERIC, 0),
        COALESCE((elem->>'UnitPrice')::NUMERIC, 0),
        COALESCE((elem->>'UnitCost')::NUMERIC, 0),
        COALESCE((elem->>'SubTotal')::NUMERIC, 0),
        COALESCE((elem->>'DiscountAmount')::NUMERIC, 0),
        COALESCE((elem->>'TotalAmount')::NUMERIC, 0),
        COALESCE((elem->>'TaxRate')::NUMERIC, 0),
        COALESCE((elem->>'TaxAmount')::NUMERIC, 0),
        COALESCE((elem->>'IsVoided')::BOOLEAN, FALSE),
        elem->>'UserCode',
        COALESCE((elem->>'LineDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM jsonb_array_elements(p_detail_json) elem;

    GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;

    -- INSERT formas de pago
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
            elem->>'PaymentMethod',
            elem->>'BankCode',
            elem->>'PaymentNumber',
            COALESCE((elem->>'Amount')::NUMERIC, 0),
            COALESCE((elem->>'PaymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (elem->>'DueDate')::TIMESTAMP,
            elem->>'ReferenceNumber',
            elem->>'UserCode',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_payments_json) elem;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- Sincronizar ap.PayableDocument para tipo COMPRA
    IF p_tipo_operacion = 'COMPRA' THEN
        SELECT pd."TotalAmount", pd."SupplierCode",
               COALESCE(pd."IsPaid", 'N'), pd."IssueDate",
               pd."Notes", pd."UserCode"
        INTO v_total_amount, v_supplier_code,
             v_is_paid, v_doc_date, v_notes, v_user_code
        FROM doc."PurchaseDocument" pd
        WHERE pd."DocumentNumber" = v_num_doc
          AND pd."DocumentType" = p_tipo_operacion;

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
                SELECT "UserId" INTO v_user_id
                FROM sec."User" WHERE "UserCode" = v_user_code AND "IsDeleted" = FALSE
                LIMIT 1;
            END IF;

            SELECT "SupplierId" INTO v_supplier_id
            FROM master."Supplier"
            WHERE "SupplierCode" = v_supplier_code
              AND "CompanyId" = v_company_id
              AND "IsDeleted" = FALSE
            LIMIT 1;

            IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
                v_status := CASE
                    WHEN v_safe_pending <= 0 THEN 'PAID'
                    WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                SELECT "PayableDocumentId" INTO v_existing_id
                FROM ap."PayableDocument"
                WHERE "CompanyId" = v_company_id
                  AND "BranchId" = v_branch_id
                  AND "DocumentType" = p_tipo_operacion
                  AND "DocumentNumber" = v_num_doc
                LIMIT 1;

                IF v_existing_id IS NOT NULL THEN
                    UPDATE ap."PayableDocument"
                    SET "SupplierId"       = v_supplier_id,
                        "IssueDate"        = v_doc_date,
                        "DueDate"          = v_doc_date,
                        "TotalAmount"      = v_total_amount,
                        "PendingAmount"    = v_safe_pending,
                        "PaidFlag"         = (v_safe_pending <= 0),
                        "Status"           = v_status,
                        "Notes"            = v_notes,
                        "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
                        "UpdatedByUserId"  = v_user_id
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
                        (v_safe_pending <= 0),
                        v_status, v_notes,
                        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                    );
                END IF;

                PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
            END IF;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, v_detalle_rows, v_formas_pago_rows, v_pending_amount;
END;
$$;

-- =============================================================================
-- 9. usp_Doc_PurchaseDocument_ConvertOrder
-- Convierte una orden de compra en un documento de compra.
-- Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_doc_purchasedocument_convertorder(
    p_num_doc_orden        VARCHAR(60),
    p_num_doc_compra       VARCHAR(60),
    p_compra_override_json JSONB         DEFAULT NULL,
    p_detalle_json         JSONB         DEFAULT NULL,
    p_cod_usuario          VARCHAR(60)   DEFAULT 'API'
)
RETURNS TABLE(
    "ok"             BOOLEAN,
    "orden"          VARCHAR,
    "compra"         VARCHAR,
    "detalleRows"    INT,
    "formasPagoRows" INT,
    "pendingAmount"  NUMERIC,
    "mensaje"        TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_detalle_rows     INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount   NUMERIC := 0;
    v_ov               JSONB;
    -- AP sync
    v_total_amount     NUMERIC;
    v_supplier_code    VARCHAR(60);
    v_is_paid          VARCHAR(1);
    v_doc_date         TIMESTAMP;
    v_c_notes          VARCHAR(500);
    v_company_id       INT;
    v_branch_id        INT;
    v_user_id          INT;
    v_supplier_id      BIGINT;
    v_safe_pending     NUMERIC;
    v_status           VARCHAR(20);
    v_existing_id      BIGINT;
BEGIN
    -- Validar parametros
    IF p_num_doc_orden IS NULL OR TRIM(p_num_doc_orden) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, 'Numero de orden requerido (@NumDocOrden)'::TEXT;
        RETURN;
    END IF;

    IF p_num_doc_compra IS NULL OR TRIM(p_num_doc_compra) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, 'Numero de compra requerido (@NumDocCompra)'::TEXT;
        RETURN;
    END IF;

    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc_orden
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, ('Orden de compra no encontrada: ' || p_num_doc_orden)::TEXT;
        RETURN;
    END IF;

    -- Validar que la orden no esta anulada
    IF EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc_orden
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, ('La orden esta anulada y no puede convertirse: ' || p_num_doc_orden)::TEXT;
        RETURN;
    END IF;

    v_ov := COALESCE(p_compra_override_json, '{}'::JSONB);

    -- Eliminar compra existente (idempotente)
    DELETE FROM doc."PurchaseDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocumentLine"
    WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';

    -- Copiar cabecera de la orden como nueva compra
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
        COALESCE(v_ov->>'SupplierCode', o."SupplierCode"),
        COALESCE(v_ov->>'SupplierName', o."SupplierName"),
        COALESCE(v_ov->>'FiscalId', o."FiscalId"),
        COALESCE((v_ov->>'IssueDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        COALESCE((v_ov->>'DueDate')::TIMESTAMP, o."DueDate"),
        COALESCE((v_ov->>'ReceiptDate')::TIMESTAMP, o."ReceiptDate"),
        COALESCE((v_ov->>'PaymentDate')::TIMESTAMP, o."PaymentDate"),
        COALESCE(v_ov->>'DocumentTime', to_char(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE((v_ov->>'SubTotal')::NUMERIC, o."SubTotal"),
        COALESCE((v_ov->>'TaxableAmount')::NUMERIC, o."TaxableAmount"),
        COALESCE((v_ov->>'ExemptAmount')::NUMERIC, o."ExemptAmount"),
        COALESCE((v_ov->>'TaxAmount')::NUMERIC, o."TaxAmount"),
        COALESCE((v_ov->>'TaxRate')::NUMERIC, o."TaxRate"),
        COALESCE((v_ov->>'TotalAmount')::NUMERIC, o."TotalAmount"),
        COALESCE((v_ov->>'DiscountAmount')::NUMERIC, o."DiscountAmount"),
        FALSE,
        COALESCE(v_ov->>'IsPaid', 'N'),
        'N',
        COALESCE((v_ov->>'IsLegal')::BOOLEAN, o."IsLegal"),
        p_num_doc_orden,
        COALESCE(v_ov->>'ControlNumber', o."ControlNumber"),
        o."VoucherNumber",
        o."VoucherDate",
        o."RetainedTax",
        o."IsrCode",
        o."IsrAmount",
        o."IsrSubjectCode",
        o."IsrSubjectAmount",
        o."RetentionRate",
        o."ImportAmount",
        o."ImportTax",
        o."ImportBase",
        o."FreightAmount",
        COALESCE(v_ov->>'Notes', o."Notes"),
        o."Concept",
        o."OrderNumber",
        o."ReceivedBy",
        COALESCE(v_ov->>'WarehouseCode', o."WarehouseCode"),
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
    WHERE o."DocumentNumber" = p_num_doc_orden
      AND o."DocumentType" = 'ORDEN'
      AND o."IsDeleted" = FALSE;

    -- Copiar lineas de detalle
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
            (elem->>'LineNumber')::INT,
            elem->>'ProductCode',
            elem->>'Description',
            COALESCE((elem->>'Quantity')::NUMERIC, 0),
            COALESCE((elem->>'UnitPrice')::NUMERIC, 0),
            COALESCE((elem->>'UnitCost')::NUMERIC, 0),
            COALESCE((elem->>'SubTotal')::NUMERIC, 0),
            COALESCE((elem->>'DiscountAmount')::NUMERIC, 0),
            COALESCE((elem->>'TotalAmount')::NUMERIC, 0),
            COALESCE((elem->>'TaxRate')::NUMERIC, 0),
            COALESCE((elem->>'TaxAmount')::NUMERIC, 0),
            COALESCE((elem->>'IsVoided')::BOOLEAN, FALSE),
            p_cod_usuario,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_detalle_json) elem;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    ELSE
        -- Copiar lineas de la orden
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
            FALSE, p_cod_usuario,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM doc."PurchaseDocumentLine" ol
        WHERE ol."DocumentNumber" = p_num_doc_orden
          AND ol."DocumentType" = 'ORDEN'
          AND ol."IsDeleted" = FALSE;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    -- Validar que se copiaron lineas
    IF v_detalle_rows = 0 THEN
        RAISE EXCEPTION 'La orden no tiene lineas de detalle: %', p_num_doc_orden;
    END IF;

    -- Marcar la orden como recibida
    UPDATE doc."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes"      = CONCAT(COALESCE("Notes", ''), ' | Convertida a compra ', p_num_doc_compra,
                        ' el ', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                        ' por ', p_cod_usuario),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_orden
      AND "DocumentType" = 'ORDEN'
      AND "IsDeleted" = FALSE;

    -- Sincronizar ap.PayableDocument
    SELECT pd."TotalAmount", pd."SupplierCode",
           COALESCE(pd."IsPaid", 'N'), pd."IssueDate", pd."Notes"
    INTO v_total_amount, v_supplier_code, v_is_paid, v_doc_date, v_c_notes
    FROM doc."PurchaseDocument" pd
    WHERE pd."DocumentNumber" = p_num_doc_compra
      AND pd."DocumentType" = 'COMPRA';

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

        SELECT "UserId" INTO v_user_id
        FROM sec."User" WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE
        LIMIT 1;

        SELECT "SupplierId" INTO v_supplier_id
        FROM master."Supplier"
        WHERE "SupplierCode" = v_supplier_code
          AND "CompanyId" = v_company_id
          AND "IsDeleted" = FALSE
        LIMIT 1;

        IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
            v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
            v_status := CASE
                WHEN v_safe_pending <= 0 THEN 'PAID'
                WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                ELSE 'PENDING'
            END;

            SELECT "PayableDocumentId" INTO v_existing_id
            FROM ap."PayableDocument"
            WHERE "CompanyId" = v_company_id
              AND "BranchId" = v_branch_id
              AND "DocumentType" = 'COMPRA'
              AND "DocumentNumber" = p_num_doc_compra
            LIMIT 1;

            IF v_existing_id IS NOT NULL THEN
                UPDATE ap."PayableDocument"
                SET "SupplierId" = v_supplier_id,
                    "IssueDate" = v_doc_date, "DueDate" = v_doc_date,
                    "TotalAmount" = v_total_amount,
                    "PendingAmount" = v_safe_pending,
                    "PaidFlag" = (v_safe_pending <= 0),
                    "Status" = v_status,
                    "Notes" = v_c_notes,
                    "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
                    "UpdatedByUserId" = v_user_id
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
                    'COMPRA', p_num_doc_compra,
                    v_doc_date, v_doc_date, 'USD',
                    v_total_amount, v_safe_pending,
                    (v_safe_pending <= 0),
                    v_status, v_c_notes,
                    NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                );
            END IF;

            PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc_orden, p_num_doc_compra,
        v_detalle_rows, v_formas_pago_rows, v_pending_amount,
        ('Compra ' || p_num_doc_compra || ' generada exitosamente desde orden ' || p_num_doc_orden)::TEXT;
END;
$$;
