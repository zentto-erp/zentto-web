-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_doc_purchase.sql
-- Funciones de documentos de compra (ap.PurchaseDocument,
-- ap.PurchaseDocumentLine, ap.PurchaseDocumentPayment)
-- ============================================================

-- =============================================================================
-- 0. Nuclear cleanup de sobrecargas (DROP por OID — elimina TODAS las firmas)
-- =============================================================================
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS sig FROM pg_proc
    WHERE proname IN (
      'usp_doc_purchasedocument_list',
      'usp_doc_purchasedocument_get',
      'usp_doc_purchasedocument_getdetail',
      'usp_doc_purchasedocument_getpayments',
      'usp_doc_purchasedocument_getindicadores',
      'usp_doc_purchasedocument_void',
      'usp_doc_purchasedocument_receiveorder',
      'usp_doc_purchasedocument_upsert',
      'usp_doc_purchasedocument_convertorder'
    )
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END $$;

-- =============================================================================
-- 1. usp_Doc_PurchaseDocument_List
-- Lista paginada de documentos de compra con filtros por tipo, busqueda,
-- codigo de proveedor, y rango de fechas.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_List(
    p_tipo_operacion  VARCHAR(20)  DEFAULT 'COMPRA',
    p_search          VARCHAR(100) DEFAULT NULL,
    p_codigo          VARCHAR(60)  DEFAULT NULL,
    p_from_date       DATE         DEFAULT NULL,
    p_to_date         DATE         DEFAULT NULL,
    p_page            INT          DEFAULT 1,
    p_limit           INT          DEFAULT 50
)
RETURNS TABLE (
    "DocumentId" INT,
    "DocumentNumber"     VARCHAR(60),
    "SerialType"         VARCHAR(60),
    "OperationType"       VARCHAR(20),
    "SupplierCode"       VARCHAR(60),
    "SupplierName"       VARCHAR(255),
    "FiscalId"           VARCHAR(15),
    "DocumentDate"          TIMESTAMP,
    "DueDate"            TIMESTAMP,
    "ReceiptDate"        TIMESTAMP,
    "PaymentDate"        TIMESTAMP,
    "DocumentTime"       VARCHAR(20),
    "SubTotal"           NUMERIC,
    "TaxableAmount"      NUMERIC,
    "ExemptAmount"       NUMERIC,
    "TaxAmount"          NUMERIC,
    "TaxRate"            NUMERIC,
    "TotalAmount"        NUMERIC,
    "DiscountAmount"     NUMERIC,
    "IsVoided"           BOOLEAN,
    "IsPaid"             VARCHAR(1),
    "IsReceived"         VARCHAR(1),
    "IsLegal"            BOOLEAN,
    "OriginDocumentNumber" VARCHAR(60),
    "ControlNumber"      VARCHAR(60),
    "VoucherNumber"      VARCHAR(50),
    "VoucherDate"        TIMESTAMP,
    "RetainedTax"        NUMERIC,
    "IsrCode"            VARCHAR(50),
    "IsrAmount"          NUMERIC,
    "IsrSubjectCode"     VARCHAR(50),
    "IsrSubjectAmount"   NUMERIC,
    "RetentionRate"      NUMERIC,
    "ImportAmount"       NUMERIC,
    "ImportTax"          NUMERIC,
    "ImportBase"         NUMERIC,
    "FreightAmount"      NUMERIC,
    "Notes"              VARCHAR(500),
    "Concept"            VARCHAR(255),
    "OrderNumber"        VARCHAR(20),
    "ReceivedBy"         VARCHAR(20),
    "WarehouseCode"      VARCHAR(50),
    "CurrencyCode"       VARCHAR(20),
    "ExchangeRate"       NUMERIC,
    "UsdAmount"          NUMERIC,
    "UserCode"           VARCHAR(60),
    "ShortUserCode"      VARCHAR(10),
    "ReportDate"         TIMESTAMP,
    "HostName"           VARCHAR(255),
    "IsDeleted"          BOOLEAN,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP,
    "TotalCount"         BIGINT
)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
-- 2. usp_Doc_PurchaseDocument_Get
-- Obtener un documento de compra individual por numero y tipo de operacion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Get;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Get(VARCHAR(20), VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_Get(
    p_tipo_operacion  VARCHAR(20),
    p_num_doc         VARCHAR(60)
)
RETURNS TABLE (
    "DocumentId" INT,
    "DocumentNumber"     VARCHAR(60),
    "SerialType"         VARCHAR(60),
    "OperationType"       VARCHAR(20),
    "SupplierCode"       VARCHAR(60),
    "SupplierName"       VARCHAR(255),
    "FiscalId"           VARCHAR(15),
    "DocumentDate"          TIMESTAMP,
    "DueDate"            TIMESTAMP,
    "ReceiptDate"        TIMESTAMP,
    "PaymentDate"        TIMESTAMP,
    "DocumentTime"       VARCHAR(20),
    "SubTotal"           NUMERIC,
    "TaxableAmount"      NUMERIC,
    "ExemptAmount"       NUMERIC,
    "TaxAmount"          NUMERIC,
    "TaxRate"            NUMERIC,
    "TotalAmount"        NUMERIC,
    "DiscountAmount"     NUMERIC,
    "IsVoided"           BOOLEAN,
    "IsPaid"             VARCHAR(1),
    "IsReceived"         VARCHAR(1),
    "IsLegal"            BOOLEAN,
    "OriginDocumentNumber" VARCHAR(60),
    "ControlNumber"      VARCHAR(60),
    "VoucherNumber"      VARCHAR(50),
    "VoucherDate"        TIMESTAMP,
    "RetainedTax"        NUMERIC,
    "IsrCode"            VARCHAR(50),
    "IsrAmount"          NUMERIC,
    "IsrSubjectCode"     VARCHAR(50),
    "IsrSubjectAmount"   NUMERIC,
    "RetentionRate"      NUMERIC,
    "ImportAmount"       NUMERIC,
    "ImportTax"          NUMERIC,
    "ImportBase"         NUMERIC,
    "FreightAmount"      NUMERIC,
    "Notes"              VARCHAR(500),
    "Concept"            VARCHAR(255),
    "OrderNumber"        VARCHAR(20),
    "ReceivedBy"         VARCHAR(20),
    "WarehouseCode"      VARCHAR(50),
    "CurrencyCode"       VARCHAR(20),
    "ExchangeRate"       NUMERIC,
    "UsdAmount"          NUMERIC,
    "UserCode"           VARCHAR(60),
    "ShortUserCode"      VARCHAR(10),
    "ReportDate"         TIMESTAMP,
    "HostName"           VARCHAR(255),
    "IsDeleted"          BOOLEAN,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql AS $$
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
    LIMIT 1;
END;
$$;

-- =============================================================================
-- 3. usp_Doc_PurchaseDocument_GetDetail
-- Obtener las lineas de detalle de un documento de compra.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetDetail;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetDetail(VARCHAR(20), VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_GetDetail(
    p_tipo_operacion  VARCHAR(20),
    p_num_doc         VARCHAR(60)
)
RETURNS TABLE (
    "LineId"           INT,
    "DocumentNumber"   VARCHAR(60),
    "OperationType"     VARCHAR(20),
    "LineNumber"       INT,
    "ProductCode"      VARCHAR(60),
    "Description"      VARCHAR(255),
    "Quantity"         NUMERIC,
    "UnitPrice"        NUMERIC,
    "UnitCost"         NUMERIC,
    "SubTotal"         NUMERIC,
    "DiscountAmount"   NUMERIC,
    "TotalAmount"      NUMERIC,
    "TaxRate"          NUMERIC,
    "TaxAmount"        NUMERIC,
    "IsVoided"         BOOLEAN,
    "IsDeleted"        BOOLEAN,
    "UserCode"         VARCHAR(60),
    "LineDate"         TIMESTAMP,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
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
    ORDER BY COALESCE(l."LineNumber", 0), l."LineId";
END;
$$;

-- =============================================================================
-- 4. usp_Doc_PurchaseDocument_GetPayments
-- Obtener las formas de pago de un documento de compra.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetPayments;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetPayments(VARCHAR(20), VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_GetPayments(
    p_tipo_operacion  VARCHAR(20),
    p_num_doc         VARCHAR(60)
)
RETURNS TABLE (
    "PaymentId"        INT,
    "DocumentNumber"   VARCHAR(60),
    "OperationType"     VARCHAR(20),
    "PaymentMethod"    VARCHAR(30),
    "BankCode"         VARCHAR(60),
    "PaymentNumber"    VARCHAR(60),
    "Amount"           NUMERIC,
    "PaymentDate"      TIMESTAMP,
    "DueDate"          TIMESTAMP,
    "ReferenceNumber"  VARCHAR(100),
    "UserCode"         VARCHAR(60),
    "IsDeleted"        BOOLEAN,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
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
      AND p."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 5. usp_Doc_PurchaseDocument_GetIndicadores
-- Obtener indicadores clave de un documento de compra:
-- IsVoided, IsPaid, IsReceived.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetIndicadores;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_GetIndicadores(VARCHAR(20), VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_GetIndicadores(
    p_tipo_operacion  VARCHAR(20),
    p_num_doc         VARCHAR(60)
)
RETURNS TABLE (
    "IsVoided"    BOOLEAN,
    "IsPaid"      VARCHAR(1),
    "IsReceived"  VARCHAR(1)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."IsVoided",
        d."IsPaid",
        d."IsReceived"
    FROM ap."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."OperationType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 6. usp_Doc_PurchaseDocument_Void
-- Anular un documento de compra. Actualiza el documento, sus lineas,
-- la cuenta por pagar (ap.PayableDocument) y el saldo del proveedor.
-- Operacion transaccional.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Void;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Void(VARCHAR(20), VARCHAR(60), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_Void(
    p_tipo_operacion  VARCHAR(20),
    p_num_doc         VARCHAR(60),
    p_cod_usuario     VARCHAR(60)  DEFAULT 'API',
    p_motivo          VARCHAR(500) DEFAULT ''
)
RETURNS TABLE (
    "ok"            BOOLEAN,
    "numDoc"        VARCHAR(60),
    "codProveedor"  VARCHAR(60),
    "mensaje"       VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_ok             BOOLEAN := FALSE;
    v_cod_proveedor  VARCHAR(60) := NULL;
    v_company_id     INT;
    v_branch_id      INT;
    v_supplier_id    BIGINT;
BEGIN
    -- Validar que el documento existe y no esta eliminado
    IF NOT EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, v_cod_proveedor,
            ('Documento no encontrado: ' || p_num_doc || ' / ' || p_tipo_operacion)::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que no este ya anulado
    IF EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, v_cod_proveedor,
            ('El documento ya se encuentra anulado: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Obtener codigo de proveedor
    SELECT d."SupplierCode" INTO v_cod_proveedor
    FROM ap."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."OperationType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE;

    -- Anular cabecera del documento
    UPDATE ap."PurchaseDocument"
    SET "IsVoided"  = TRUE,
        "Notes"     = COALESCE("Notes",''::VARCHAR) || ' | ANULADO '
                      || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI')
                      || ' por ' || p_cod_usuario
                      || CASE WHEN p_motivo <> '' THEN ' - Motivo: ' || p_motivo ELSE '' END,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular lineas del documento
    UPDATE ap."PurchaseDocumentLine"
    SET "IsVoided"  = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Resolver contexto: CompanyId y BranchId
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

    -- Resolver SupplierId desde master.Supplier
    SELECT s."SupplierId" INTO v_supplier_id
    FROM master."Supplier" s
    WHERE s."SupplierCode" = v_cod_proveedor
      AND s."CompanyId" = v_company_id
      AND s."IsDeleted" = FALSE
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
        ('Documento anulado exitosamente: ' || p_num_doc)::VARCHAR(500);
END;
$$;

-- =============================================================================
-- 7. usp_Doc_PurchaseDocument_ReceiveOrder
-- Marcar una orden de compra como recibida.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_ReceiveOrder;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_ReceiveOrder(VARCHAR(60), VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_ReceiveOrder(
    p_num_doc      VARCHAR(60),
    p_cod_usuario  VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"       BOOLEAN,
    "numDoc"   VARCHAR(60),
    "mensaje"  VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = 'ORDEN'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('Orden de compra no encontrada: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que la orden no esta anulada
    IF EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = 'ORDEN'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('La orden esta anulada y no puede marcarse como recibida: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Marcar como recibida
    UPDATE ap."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes"      = COALESCE("Notes",''::VARCHAR) || ' | Recibido '
                       || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI')
                       || ' por ' || p_cod_usuario,
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = 'ORDEN'
      AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT TRUE, p_num_doc,
        ('Orden marcada como recibida exitosamente: ' || p_num_doc)::VARCHAR(500);
END;
$$;

-- =============================================================================
-- 8. usp_Doc_PurchaseDocument_Upsert
-- Crea o reemplaza un documento de compra completo (cabecera + detalle + pagos).
-- Para tipo COMPRA sincroniza ap.PayableDocument y recalcula saldo proveedor.
-- Operacion transaccional.
--
-- Retorna: ok, numDoc, detalleRows, formasPagoRows, pendingAmount
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Upsert;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_Upsert(VARCHAR(20), JSONB, JSONB, JSONB, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_Upsert(
    p_tipo_operacion  VARCHAR(20),
    p_header_json     JSONB,
    p_detail_json     JSONB,
    p_payments_json   JSONB DEFAULT NULL,
    p_doc_origen      VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE (
    "ok"              BOOLEAN,
    "numDoc"          VARCHAR(60),
    "detalleRows"     INT,
    "formasPagoRows"  INT,
    "pendingAmount"   NUMERIC,
    "mensaje"         TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_num_doc          VARCHAR(60);
    v_detalle_rows     INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount   NUMERIC := 0;
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
    v_existing_payable_id BIGINT;
    v_now              TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    -- Parsear numero de documento desde JSON
    v_num_doc := TRIM(p_header_json->>'DocumentNumber');

    -- Validar numero de documento
    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, v_num_doc, 0, 0, 0::NUMERIC,
            'Numero de documento requerido (DocumentNumber)'::TEXT;
        RETURN;
    END IF;

    -- 1. Eliminar datos existentes (detalle, pagos, cabecera)
    DELETE FROM ap."PurchaseDocumentPayment"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM ap."PurchaseDocumentLine"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM ap."PurchaseDocument"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    -- 2. INSERT cabecera desde JSON
    INSERT INTO ap."PurchaseDocument" (
        "DocumentNumber", "SerialType", "OperationType",
        "SupplierCode", "SupplierName", "FiscalId",
        "DocumentDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectAmount", "RetentionRate",
        "ImportAmount", "ImportTax", "ImportBase", "FreightAmount",
        "Notes", "Concept", "OrderNumber", "ReceivedBy", "WarehouseCode",
        "CurrencyCode", "ExchangeRate", "UsdAmount",
        "UserCode", "ShortUserCode", "ReportDate", "HostName",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_num_doc,
        COALESCE(p_header_json->>'SerialType',''::VARCHAR),
        p_tipo_operacion,
        p_header_json->>'SupplierCode',
        p_header_json->>'SupplierName',
        p_header_json->>'FiscalId',
        COALESCE((p_header_json->>'IssueDate')::TIMESTAMP, v_now),
        (p_header_json->>'DueDate')::TIMESTAMP,
        (p_header_json->>'ReceiptDate')::TIMESTAMP,
        (p_header_json->>'PaymentDate')::TIMESTAMP,
        COALESCE(p_header_json->>'DocumentTime', TO_CHAR(v_now, 'HH24:MI:SS')),
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
        COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, v_now),
        COALESCE(p_header_json->>'HostName', inet_client_addr()::TEXT),
        v_now,
        v_now
    );

    -- 3. INSERT lineas de detalle desde JSON
    INSERT INTO ap."PurchaseDocumentLine" (
        "DocumentNumber", "OperationType", "LineNumber",
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
        COALESCE((elem->>'LineDate')::TIMESTAMP, v_now),
        v_now,
        v_now
    FROM jsonb_array_elements(p_detail_json) elem;

    GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;

    -- 4. INSERT formas de pago desde JSON (si se proporcionaron)
    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
        INSERT INTO ap."PurchaseDocumentPayment" (
            "DocumentNumber", "OperationType",
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
            COALESCE((elem->>'PaymentDate')::TIMESTAMP, v_now),
            (elem->>'DueDate')::TIMESTAMP,
            elem->>'ReferenceNumber',
            elem->>'UserCode',
            v_now,
            v_now
        FROM jsonb_array_elements(p_payments_json) elem;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- 5. Sincronizar ap.PayableDocument para tipo COMPRA
    IF p_tipo_operacion = 'COMPRA' THEN
        -- Leer valores de la cabecera recien insertada
        SELECT d."TotalAmount", d."SupplierCode", COALESCE(d."IsPaid", 'N'),
               d."DocumentDate", d."Notes", d."UserCode"
        INTO v_total_amount, v_supplier_code, v_is_paid,
             v_doc_date, v_notes, v_user_code
        FROM ap."PurchaseDocument" d
        WHERE d."DocumentNumber" = v_num_doc
          AND d."OperationType" = p_tipo_operacion;

        -- Calcular monto pendiente
        v_pending_amount := CASE WHEN UPPER(v_is_paid) = 'S' THEN 0 ELSE v_total_amount END;

        -- Solo sincronizar si hay proveedor
        IF v_supplier_code IS NOT NULL AND TRIM(v_supplier_code) <> '' THEN
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

            v_user_id := NULL;
            IF v_user_code IS NOT NULL THEN
                SELECT u."UserId" INTO v_user_id
                FROM sec."User" u
                WHERE u."UserCode" = v_user_code AND u."IsDeleted" = FALSE
                LIMIT 1;
            END IF;

            -- Resolver SupplierId
            SELECT s."SupplierId" INTO v_supplier_id
            FROM master."Supplier" s
            WHERE s."SupplierCode" = v_supplier_code
              AND s."CompanyId" = v_company_id
              AND s."IsDeleted" = FALSE
            LIMIT 1;

            IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                -- Calcular status del documento por pagar
                v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
                v_status := CASE
                    WHEN v_safe_pending <= 0 THEN 'PAID'
                    WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                -- Verificar si ya existe documento por pagar
                SELECT pd."PayableDocumentId" INTO v_existing_payable_id
                FROM ap."PayableDocument" pd
                WHERE pd."CompanyId"      = v_company_id
                  AND pd."BranchId"       = v_branch_id
                  AND pd."OperationType"   = p_tipo_operacion
                  AND pd."DocumentNumber" = v_num_doc
                LIMIT 1;

                IF v_existing_payable_id IS NOT NULL THEN
                    UPDATE ap."PayableDocument"
                    SET "SupplierId"       = v_supplier_id,
                        "IssueDate"        = v_doc_date,
                        "DueDate"          = v_doc_date,
                        "TotalAmount"      = v_total_amount,
                        "PendingAmount"    = v_safe_pending,
                        "PaidFlag"         = (v_safe_pending <= 0),
                        "Status"           = v_status,
                        "Notes"            = v_notes,
                        "UpdatedAt"        = v_now,
                        "UpdatedByUserId"  = v_user_id
                    WHERE "PayableDocumentId" = v_existing_payable_id;
                ELSE
                    INSERT INTO ap."PayableDocument" (
                        "CompanyId", "BranchId", "SupplierId",
                        "OperationType", "DocumentNumber",
                        "DocumentDate", "DueDate", "CurrencyCode",
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
                        v_now, v_now, v_user_id, v_user_id
                    );
                END IF;

                -- Recalcular saldo total del proveedor
                PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, v_user_id);
            END IF;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, v_detalle_rows, v_formas_pago_rows,
        v_pending_amount, NULL::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, v_num_doc, 0, 0, 0::NUMERIC, SQLERRM::TEXT;
END;
$$;

-- =============================================================================
-- 9. usp_Doc_PurchaseDocument_ConvertOrder
-- Convierte una orden de compra en un documento de compra.
-- Copia cabecera y lineas de la orden, crea la compra, marca la orden como
-- recibida, y sincroniza ap.PayableDocument.
-- Operacion transaccional.
--
-- Retorna: ok, orden, compra, detalleRows, formasPagoRows, pendingAmount, mensaje
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_ConvertOrder;
DROP FUNCTION IF EXISTS usp_Doc_PurchaseDocument_ConvertOrder(VARCHAR(60), VARCHAR(60), JSONB, JSONB, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Doc_PurchaseDocument_ConvertOrder(
    p_num_doc_orden         VARCHAR(60),
    p_num_doc_compra        VARCHAR(60),
    p_compra_override_json  JSONB DEFAULT NULL,
    p_detalle_json          JSONB DEFAULT NULL,
    p_cod_usuario           VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"              BOOLEAN,
    "orden"           VARCHAR(60),
    "compra"          VARCHAR(60),
    "detalleRows"     INT,
    "formasPagoRows"  INT,
    "pendingAmount"   NUMERIC,
    "mensaje"         VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_detalle_rows      INT := 0;
    v_formas_pago_rows  INT := 0;
    v_pending_amount    NUMERIC := 0;
    v_total_amount      NUMERIC;
    v_supplier_code     VARCHAR(60);
    v_is_paid           VARCHAR(1);
    v_doc_date          TIMESTAMP;
    v_notes             VARCHAR(500);
    v_company_id        INT;
    v_branch_id         INT;
    v_user_id           INT;
    v_supplier_id       BIGINT;
    v_safe_pending      NUMERIC;
    v_status            VARCHAR(20);
    v_existing_payable_id BIGINT;
    v_now               TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_override          JSONB;
BEGIN
    -- Validar parametros
    IF p_num_doc_orden IS NULL OR TRIM(p_num_doc_orden) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, 'Numero de orden requerido (p_num_doc_orden)'::VARCHAR(500);
        RETURN;
    END IF;

    IF p_num_doc_compra IS NULL OR TRIM(p_num_doc_compra) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, 'Numero de compra requerido (p_num_doc_compra)'::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc_orden
          AND "OperationType" = 'ORDEN'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, ('Orden de compra no encontrada: ' || p_num_doc_orden)::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que la orden no esta anulada
    IF EXISTS (
        SELECT 1 FROM ap."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc_orden
          AND "OperationType" = 'ORDEN'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
            0, 0, 0::NUMERIC, ('La orden esta anulada y no puede convertirse: ' || p_num_doc_orden)::VARCHAR(500);
        RETURN;
    END IF;

    v_override := COALESCE(p_compra_override_json, '{}'::JSONB);

    -- 1. Eliminar compra existente si la hubiera (idempotente)
    DELETE FROM ap."PurchaseDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc_compra AND "OperationType" = 'COMPRA';

    DELETE FROM ap."PurchaseDocumentLine"
    WHERE "DocumentNumber" = p_num_doc_compra AND "OperationType" = 'COMPRA';

    DELETE FROM ap."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc_compra AND "OperationType" = 'COMPRA';

    -- 2. Copiar cabecera de la orden como nueva compra con overrides
    INSERT INTO ap."PurchaseDocument" (
        "DocumentNumber", "SerialType", "OperationType",
        "SupplierCode", "SupplierName", "FiscalId",
        "DocumentDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectAmount", "RetentionRate",
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
        COALESCE(v_override->>'SupplierCode', o."SupplierCode"),
        COALESCE(v_override->>'SupplierName', o."SupplierName"),
        COALESCE(v_override->>'FiscalId', o."FiscalId"),
        COALESCE((v_override->>'IssueDate')::TIMESTAMP, v_now),
        COALESCE((v_override->>'DueDate')::TIMESTAMP, o."DueDate"),
        COALESCE((v_override->>'ReceiptDate')::TIMESTAMP, o."ReceiptDate"),
        COALESCE((v_override->>'PaymentDate')::TIMESTAMP, o."PaymentDate"),
        COALESCE(v_override->>'DocumentTime', TO_CHAR(v_now, 'HH24:MI:SS')),
        COALESCE((v_override->>'SubTotal')::NUMERIC, o."SubTotal"),
        COALESCE((v_override->>'TaxableAmount')::NUMERIC, o."TaxableAmount"),
        COALESCE((v_override->>'ExemptAmount')::NUMERIC, o."ExemptAmount"),
        COALESCE((v_override->>'TaxAmount')::NUMERIC, o."TaxAmount"),
        COALESCE((v_override->>'TaxRate')::NUMERIC, o."TaxRate"),
        COALESCE((v_override->>'TotalAmount')::NUMERIC, o."TotalAmount"),
        COALESCE((v_override->>'DiscountAmount')::NUMERIC, o."DiscountAmount"),
        FALSE,                                             -- IsVoided = No
        COALESCE(v_override->>'IsPaid', 'N'),
        'N',                                               -- IsReceived
        COALESCE((v_override->>'IsLegal')::BOOLEAN, o."IsLegal"),
        p_num_doc_orden,                                   -- OriginDocumentNumber
        COALESCE(v_override->>'ControlNumber', o."ControlNumber"),
        o."VoucherNumber",
        o."VoucherDate",
        o."RetainedTax",
        o."IsrCode",
        o."IsrAmount",
        o."IsrSubjectAmount",
        o."RetentionRate",
        o."ImportAmount",
        o."ImportTax",
        o."ImportBase",
        o."FreightAmount",
        COALESCE(v_override->>'Notes', o."Notes"),
        o."Concept",
        o."OrderNumber",
        o."ReceivedBy",
        COALESCE(v_override->>'WarehouseCode', o."WarehouseCode"),
        COALESCE(o."CurrencyCode", 'BS'),
        COALESCE(o."ExchangeRate", 1),
        o."UsdAmount",
        p_cod_usuario,
        o."ShortUserCode",
        v_now,
        COALESCE(inet_client_addr()::TEXT, 'localhost'),
        v_now,
        v_now
    FROM ap."PurchaseDocument" o
    WHERE o."DocumentNumber" = p_num_doc_orden
      AND o."OperationType" = 'ORDEN'
      AND o."IsDeleted" = FALSE;

    -- 3. Copiar lineas de detalle (desde JSON o desde la orden)
    IF p_detalle_json IS NOT NULL AND jsonb_array_length(p_detalle_json) > 0 THEN
        -- Usar detalle proporcionado
        INSERT INTO ap."PurchaseDocumentLine" (
            "DocumentNumber", "OperationType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra,
            'COMPRA',
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
            v_now,
            v_now,
            v_now
        FROM jsonb_array_elements(p_detalle_json) elem;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    ELSE
        -- Copiar lineas de la orden
        INSERT INTO ap."PurchaseDocumentLine" (
            "DocumentNumber", "OperationType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra,
            'COMPRA',
            ol."LineNumber",
            ol."ProductCode",
            ol."Description",
            ol."Quantity",
            ol."UnitPrice",
            ol."UnitCost",
            ol."SubTotal",
            ol."DiscountAmount",
            ol."TotalAmount",
            ol."TaxRate",
            ol."TaxAmount",
            FALSE,                          -- IsVoided = No
            p_cod_usuario,
            v_now,
            v_now,
            v_now
        FROM ap."PurchaseDocumentLine" ol
        WHERE ol."DocumentNumber" = p_num_doc_orden
          AND ol."OperationType" = 'ORDEN'
          AND ol."IsDeleted" = FALSE;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    -- Validar que se copiaron lineas
    IF v_detalle_rows = 0 THEN
        RAISE EXCEPTION 'La orden no tiene lineas de detalle: %', p_num_doc_orden;
    END IF;

    -- 4. Marcar la orden como recibida
    UPDATE ap."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes"      = COALESCE("Notes",''::VARCHAR) || ' | Convertida a compra ' || p_num_doc_compra
                       || ' el ' || TO_CHAR(v_now, 'YYYY-MM-DD HH24:MI')
                       || ' por ' || p_cod_usuario,
        "UpdatedAt"  = v_now
    WHERE "DocumentNumber" = p_num_doc_orden
      AND "OperationType" = 'ORDEN'
      AND "IsDeleted" = FALSE;

    -- 5. Sincronizar ap.PayableDocument para la compra creada
    SELECT d."TotalAmount", d."SupplierCode", COALESCE(d."IsPaid", 'N'),
           d."DocumentDate", d."Notes"
    INTO v_total_amount, v_supplier_code, v_is_paid,
         v_doc_date, v_notes
    FROM ap."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc_compra
      AND d."OperationType" = 'COMPRA';

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

        SELECT u."UserId" INTO v_user_id
        FROM sec."User" u
        WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE
        LIMIT 1;

        SELECT s."SupplierId" INTO v_supplier_id
        FROM master."Supplier" s
        WHERE s."SupplierCode" = v_supplier_code
          AND s."CompanyId" = v_company_id
          AND s."IsDeleted" = FALSE
        LIMIT 1;

        IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
            v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
            v_status := CASE
                WHEN v_safe_pending <= 0 THEN 'PAID'
                WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                ELSE 'PENDING'
            END;

            -- Verificar si ya existe
            SELECT pd."PayableDocumentId" INTO v_existing_payable_id
            FROM ap."PayableDocument" pd
            WHERE pd."CompanyId"      = v_company_id
              AND pd."BranchId"       = v_branch_id
              AND pd."OperationType"   = 'COMPRA'
              AND pd."DocumentNumber" = p_num_doc_compra
            LIMIT 1;

            IF v_existing_payable_id IS NOT NULL THEN
                UPDATE ap."PayableDocument"
                SET "SupplierId"       = v_supplier_id,
                    "IssueDate"        = v_doc_date,
                    "DueDate"          = v_doc_date,
                    "TotalAmount"      = v_total_amount,
                    "PendingAmount"    = v_safe_pending,
                    "PaidFlag"         = (v_safe_pending <= 0),
                    "Status"           = v_status,
                    "Notes"            = v_notes,
                    "UpdatedAt"        = v_now,
                    "UpdatedByUserId"  = v_user_id
                WHERE "PayableDocumentId" = v_existing_payable_id;
            ELSE
                INSERT INTO ap."PayableDocument" (
                    "CompanyId", "BranchId", "SupplierId",
                    "OperationType", "DocumentNumber",
                    "DocumentDate", "DueDate", "CurrencyCode",
                    "TotalAmount", "PendingAmount", "PaidFlag", "Status", "Notes",
                    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                )
                VALUES (
                    v_company_id, v_branch_id, v_supplier_id,
                    'COMPRA', p_num_doc_compra,
                    v_doc_date, v_doc_date, 'USD',
                    v_total_amount, v_safe_pending,
                    (v_safe_pending <= 0),
                    v_status, v_notes,
                    v_now, v_now, v_user_id, v_user_id
                );
            END IF;

            -- Recalcular saldo total del proveedor
            PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, v_user_id);
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc_orden, p_num_doc_compra,
        v_detalle_rows, v_formas_pago_rows, v_pending_amount,
        ('Compra ' || p_num_doc_compra || ' generada exitosamente desde orden ' || p_num_doc_orden)::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra,
        0, 0, 0::NUMERIC, SQLERRM::VARCHAR(500);
END;
$$;
