-- +goose Up

-- +goose StatementBegin
-- Nuclear DROP de sobrecargas en funciones de documentos de compra
-- Corrige "function is not unique" al existir firmas antiguas en produccion

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

-- Re-crear funcion principal con firma canonica
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
    "DocumentId"           INT,
    "DocumentNumber"       VARCHAR(60),
    "SerialType"           VARCHAR(60),
    "OperationType"        VARCHAR(20),
    "SupplierCode"         VARCHAR(60),
    "SupplierName"         VARCHAR(255),
    "FiscalId"             VARCHAR(15),
    "DocumentDate"         TIMESTAMP,
    "DueDate"              TIMESTAMP,
    "ReceiptDate"          TIMESTAMP,
    "PaymentDate"          TIMESTAMP,
    "DocumentTime"         VARCHAR(20),
    "SubTotal"             NUMERIC,
    "TaxableAmount"        NUMERIC,
    "ExemptAmount"         NUMERIC,
    "TaxAmount"            NUMERIC,
    "TaxRate"              NUMERIC,
    "TotalAmount"          NUMERIC,
    "DiscountAmount"       NUMERIC,
    "IsVoided"             BOOLEAN,
    "IsPaid"               VARCHAR(1),
    "IsReceived"           VARCHAR(1),
    "IsLegal"              BOOLEAN,
    "OriginDocumentNumber" VARCHAR(60),
    "ControlNumber"        VARCHAR(60),
    "VoucherNumber"        VARCHAR(50),
    "VoucherDate"          TIMESTAMP,
    "RetainedTax"          NUMERIC,
    "IsrCode"              VARCHAR(50),
    "IsrAmount"            NUMERIC,
    "IsrSubjectCode"       VARCHAR(50),
    "IsrSubjectAmount"     NUMERIC,
    "RetentionRate"        NUMERIC,
    "ImportAmount"         NUMERIC,
    "ImportTax"            NUMERIC,
    "ImportBase"           NUMERIC,
    "FreightAmount"        NUMERIC,
    "Notes"                VARCHAR(500),
    "Concept"              VARCHAR(255),
    "OrderNumber"          VARCHAR(20),
    "ReceivedBy"           VARCHAR(20),
    "WarehouseCode"        VARCHAR(50),
    "CurrencyCode"         VARCHAR(20),
    "ExchangeRate"         NUMERIC,
    "UsdAmount"            NUMERIC,
    "UserCode"             VARCHAR(60),
    "ShortUserCode"        VARCHAR(10),
    "ReportDate"           TIMESTAMP,
    "HostName"             VARCHAR(255),
    "IsDeleted"            BOOLEAN,
    "CreatedAt"            TIMESTAMP,
    "UpdatedAt"            TIMESTAMP,
    "TotalCount"           BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM ap."PurchaseDocument" pd_c
    WHERE COALESCE(pd_c."IsDeleted", FALSE) = FALSE
      AND pd_c."OperationType" = p_tipo_operacion
      AND (p_search   IS NULL OR pd_c."DocumentNumber" ILIKE '%' || p_search || '%'
                               OR pd_c."SupplierName"  ILIKE '%' || p_search || '%')
      AND (p_codigo   IS NULL OR pd_c."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR pd_c."DocumentDate"::DATE >= p_from_date)
      AND (p_to_date   IS NULL OR pd_c."DocumentDate"::DATE <= p_to_date);

    RETURN QUERY
    SELECT
        pd."DocumentId"::INT,
        pd."DocumentNumber"::VARCHAR(60),
        pd."SerialType"::VARCHAR(60),
        pd."OperationType"::VARCHAR(20),
        pd."SupplierCode"::VARCHAR(60),
        pd."SupplierName"::VARCHAR(255),
        pd."FiscalId"::VARCHAR(15),
        pd."DocumentDate",
        pd."DueDate",
        pd."ReceiptDate",
        pd."PaymentDate",
        pd."DocumentTime"::VARCHAR(20),
        pd."SubTotal"::NUMERIC,
        pd."TaxableAmount"::NUMERIC,
        pd."ExemptAmount"::NUMERIC,
        pd."TaxAmount"::NUMERIC,
        pd."TaxRate"::NUMERIC,
        pd."TotalAmount"::NUMERIC,
        pd."DiscountAmount"::NUMERIC,
        pd."IsVoided",
        pd."IsPaid"::VARCHAR(1),
        pd."IsReceived"::VARCHAR(1),
        pd."IsLegal",
        pd."OriginDocumentNumber"::VARCHAR(60),
        pd."ControlNumber"::VARCHAR(60),
        pd."VoucherNumber"::VARCHAR(50),
        pd."VoucherDate",
        pd."RetainedTax"::NUMERIC,
        pd."IsrCode"::VARCHAR(50),
        pd."IsrAmount"::NUMERIC,
        pd."IsrSubjectCode"::VARCHAR(50),
        pd."IsrSubjectAmount"::NUMERIC,
        pd."RetentionRate"::NUMERIC,
        pd."ImportAmount"::NUMERIC,
        pd."ImportTax"::NUMERIC,
        pd."ImportBase"::NUMERIC,
        pd."FreightAmount"::NUMERIC,
        pd."Notes"::VARCHAR(500),
        pd."Concept"::VARCHAR(255),
        pd."OrderNumber"::VARCHAR(20),
        pd."ReceivedBy"::VARCHAR(20),
        pd."WarehouseCode"::VARCHAR(50),
        pd."CurrencyCode"::VARCHAR(20),
        pd."ExchangeRate"::NUMERIC,
        pd."UsdAmount"::NUMERIC,
        pd."UserCode"::VARCHAR(60),
        pd."ShortUserCode"::VARCHAR(10),
        pd."ReportDate",
        pd."HostName"::VARCHAR(255),
        COALESCE(pd."IsDeleted", FALSE),
        pd."CreatedAt",
        pd."UpdatedAt",
        v_total::BIGINT
    FROM ap."PurchaseDocument" pd
    WHERE COALESCE(pd."IsDeleted", FALSE) = FALSE
      AND pd."OperationType" = p_tipo_operacion
      AND (p_search   IS NULL OR pd."DocumentNumber" ILIKE '%' || p_search || '%'
                               OR pd."SupplierName"  ILIKE '%' || p_search || '%')
      AND (p_codigo   IS NULL OR pd."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR pd."DocumentDate"::DATE >= p_from_date)
      AND (p_to_date   IS NULL OR pd."DocumentDate"::DATE <= p_to_date)
    ORDER BY pd."DocumentDate" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_doc_purchasedocument_list(VARCHAR(20), VARCHAR(100), VARCHAR(60), DATE, DATE, INT, INT) CASCADE;
