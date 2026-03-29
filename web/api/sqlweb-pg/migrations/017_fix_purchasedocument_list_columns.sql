\echo '  [017] Fix usp_doc_purchasedocument_list â€” alias de tabla + columnas reales...'

-- Columnas reales en doc."PurchaseDocument":
--   DocumentId, DocumentNumber, SerialType, FiscalMemoryNumber, DocumentType,
--   SupplierCode, SupplierName, FiscalId, IssueDate, DueDate,
--   Subtotal (float8), TaxableAmount, ExemptAmount, TaxAmount, TaxRate,
--   TotalAmount, DiscountAmount, IsVoided, IsCanceled, Notes, Concept,
--   CurrencyCode, ExchangeRate, LegacyUserCode, CreatedAt, UpdatedAt,
--   CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
--
-- Problemas:
--   1. COUNT sin alias de tabla â†’ "DocumentType" ambiguo con columna RETURNS TABLE
--   2. d."PurchaseDocumentId" no existe â†’ d."DocumentId"::BIGINT
--   3. d."SubTotal" no existe â†’ d."Subtotal" (t minÃºscula)
--   4. Muchas columnas no existen en la tabla â†’ NULL con el tipo correcto

CREATE OR REPLACE FUNCTION public.usp_doc_purchasedocument_list(
    p_tipo_operacion character varying DEFAULT 'COMPRA',
    p_search         character varying DEFAULT NULL,
    p_codigo         character varying DEFAULT NULL,
    p_from_date      date              DEFAULT NULL,
    p_to_date        date              DEFAULT NULL,
    p_page           integer           DEFAULT 1,
    p_limit          integer           DEFAULT 50
)
RETURNS TABLE(
    "PurchaseDocumentId"    BIGINT,
    "DocumentNumber"        CHARACTER VARYING,
    "SerialType"            CHARACTER VARYING,
    "DocumentType"          CHARACTER VARYING,
    "SupplierCode"          CHARACTER VARYING,
    "SupplierName"          CHARACTER VARYING,
    "FiscalId"              CHARACTER VARYING,
    "IssueDate"             TIMESTAMP WITHOUT TIME ZONE,
    "DueDate"               TIMESTAMP WITHOUT TIME ZONE,
    "ReceiptDate"           TIMESTAMP WITHOUT TIME ZONE,
    "PaymentDate"           TIMESTAMP WITHOUT TIME ZONE,
    "DocumentTime"          CHARACTER VARYING,
    "SubTotal"              DOUBLE PRECISION,
    "TaxableAmount"         DOUBLE PRECISION,
    "ExemptAmount"          DOUBLE PRECISION,
    "TaxAmount"             DOUBLE PRECISION,
    "TaxRate"               DOUBLE PRECISION,
    "TotalAmount"           DOUBLE PRECISION,
    "DiscountAmount"        DOUBLE PRECISION,
    "IsVoided"              BOOLEAN,
    "IsPaid"                CHARACTER VARYING,
    "IsReceived"            CHARACTER VARYING,
    "IsLegal"               BOOLEAN,
    "OriginDocumentNumber"  CHARACTER VARYING,
    "ControlNumber"         CHARACTER VARYING,
    "VoucherNumber"         CHARACTER VARYING,
    "VoucherDate"           TIMESTAMP WITHOUT TIME ZONE,
    "RetainedTax"           DOUBLE PRECISION,
    "IsrCode"               CHARACTER VARYING,
    "IsrAmount"             DOUBLE PRECISION,
    "IsrSubjectCode"        CHARACTER VARYING,
    "IsrSubjectAmount"      DOUBLE PRECISION,
    "RetentionRate"         DOUBLE PRECISION,
    "ImportAmount"          DOUBLE PRECISION,
    "ImportTax"             DOUBLE PRECISION,
    "ImportBase"            DOUBLE PRECISION,
    "FreightAmount"         DOUBLE PRECISION,
    "Notes"                 CHARACTER VARYING,
    "Concept"               CHARACTER VARYING,
    "OrderNumber"           CHARACTER VARYING,
    "ReceivedBy"            CHARACTER VARYING,
    "WarehouseCode"         CHARACTER VARYING,
    "CurrencyCode"          CHARACTER VARYING,
    "ExchangeRate"          DOUBLE PRECISION,
    "UsdAmount"             DOUBLE PRECISION,
    "UserCode"              CHARACTER VARYING,
    "ShortUserCode"         CHARACTER VARYING,
    "ReportDate"            TIMESTAMP WITHOUT TIME ZONE,
    "HostName"              CHARACTER VARYING,
    "IsDeleted"             BOOLEAN,
    "CreatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "TotalCount"            BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_page   INT := GREATEST(COALESCE(p_page, 1), 1);
    v_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
BEGIN
    -- FIX: alias pd.* para evitar ambigÃ¼edad con columnas RETURNS TABLE
    SELECT COUNT(*) INTO v_total
    FROM doc."PurchaseDocument" pd
    WHERE pd."DocumentType" = p_tipo_operacion
      AND pd."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            pd."DocumentNumber" ILIKE '%' || p_search || '%'
            OR pd."SupplierName" ILIKE '%' || p_search || '%'
            OR pd."FiscalId"     ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR pd."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR pd."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR pd."IssueDate" < (p_to_date + INTERVAL '1 day'));

    RETURN QUERY
    SELECT
        d."DocumentId"::BIGINT,              -- FIX: PurchaseDocumentId â†’ DocumentId
        d."DocumentNumber",
        d."SerialType",
        d."DocumentType",
        d."SupplierCode",
        d."SupplierName",
        d."FiscalId",
        d."IssueDate",
        d."DueDate",
        NULL::TIMESTAMP WITHOUT TIME ZONE,   -- ReceiptDate (no existe)
        NULL::TIMESTAMP WITHOUT TIME ZONE,   -- PaymentDate (no existe)
        NULL::CHARACTER VARYING,             -- DocumentTime (no existe)
        d."Subtotal",                        -- FIX: SubTotal â†’ Subtotal (t minÃºscula)
        d."TaxableAmount",
        d."ExemptAmount",
        d."TaxAmount",
        d."TaxRate",
        d."TotalAmount",
        d."DiscountAmount",
        d."IsVoided",
        NULL::CHARACTER VARYING,             -- IsPaid (no existe)
        NULL::CHARACTER VARYING,             -- IsReceived (no existe)
        NULL::BOOLEAN,                       -- IsLegal (no existe)
        NULL::CHARACTER VARYING,             -- OriginDocumentNumber (no existe)
        NULL::CHARACTER VARYING,             -- ControlNumber (no existe)
        NULL::CHARACTER VARYING,             -- VoucherNumber (no existe)
        NULL::TIMESTAMP WITHOUT TIME ZONE,   -- VoucherDate (no existe)
        NULL::DOUBLE PRECISION,              -- RetainedTax (no existe)
        NULL::CHARACTER VARYING,             -- IsrCode (no existe)
        NULL::DOUBLE PRECISION,              -- IsrAmount (no existe)
        NULL::CHARACTER VARYING,             -- IsrSubjectCode (no existe)
        NULL::DOUBLE PRECISION,              -- IsrSubjectAmount (no existe)
        NULL::DOUBLE PRECISION,              -- RetentionRate (no existe)
        NULL::DOUBLE PRECISION,              -- ImportAmount (no existe)
        NULL::DOUBLE PRECISION,              -- ImportTax (no existe)
        NULL::DOUBLE PRECISION,              -- ImportBase (no existe)
        NULL::DOUBLE PRECISION,              -- FreightAmount (no existe)
        d."Notes",
        d."Concept",
        NULL::CHARACTER VARYING,             -- OrderNumber (no existe)
        NULL::CHARACTER VARYING,             -- ReceivedBy (no existe)
        NULL::CHARACTER VARYING,             -- WarehouseCode (no existe)
        d."CurrencyCode",
        d."ExchangeRate",
        NULL::DOUBLE PRECISION,              -- UsdAmount (no existe)
        d."LegacyUserCode",                  -- FIX: UserCode â†’ LegacyUserCode
        NULL::CHARACTER VARYING,             -- ShortUserCode (no existe)
        NULL::TIMESTAMP WITHOUT TIME ZONE,   -- ReportDate (no existe)
        NULL::CHARACTER VARYING,             -- HostName (no existe)
        d."IsDeleted",
        d."CreatedAt",
        d."UpdatedAt",
        v_total
    FROM doc."PurchaseDocument" d
    WHERE d."DocumentType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            d."DocumentNumber" ILIKE '%' || p_search || '%'
            OR d."SupplierName" ILIKE '%' || p_search || '%'
            OR d."FiscalId"     ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR d."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR d."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR d."IssueDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY d."IssueDate" DESC, d."DocumentId" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

\echo '  [017] COMPLETO â€” purchasedocument_list columnas reales + alias corregido'
