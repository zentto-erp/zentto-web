\echo '  [014] Fix usp_doc_salesdocument_list â€” columnas reales + alias de tabla...'

-- Columnas reales en doc."SalesDocument":
--   DocumentId, DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
--   CustomerCode, CustomerName, FiscalId, IssueDate (no DocumentDate), DueDate,
--   DocumentTime, Subtotal (no SubTotal), TaxableAmount, ExemptAmount, TaxAmount,
--   TaxRate, TotalAmount, DiscountAmount, IsVoided, IsCanceled, IsInvoiced,
--   IsDelivered, SourceDocumentNumber, SourceDocumentType, ControlNumber, Notes,
--   Concept, CurrencyCode, ExchangeRate, LegacyUserCode, CreatedAt, UpdatedAt,
--   CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
--
-- Columnas inexistentes en la tabla â†’ devuelven NULL para mantener contrato de la API.

CREATE OR REPLACE FUNCTION public.usp_doc_salesdocument_list(
    p_tipo_operacion character varying,
    p_search         character varying DEFAULT NULL,
    p_codigo         character varying DEFAULT NULL,
    p_from_date      date DEFAULT NULL,
    p_to_date        date DEFAULT NULL,
    p_page           integer DEFAULT 1,
    p_limit          integer DEFAULT 50
)
RETURNS TABLE(
    "SalesDocumentId"       BIGINT,
    "DocumentNumber"        CHARACTER VARYING,
    "SerialType"            CHARACTER VARYING,
    "FiscalMemoryNumber"    CHARACTER VARYING,
    "OperationType"         CHARACTER VARYING,
    "CustomerCode"          CHARACTER VARYING,
    "CustomerName"          CHARACTER VARYING,
    "FiscalId"              CHARACTER VARYING,
    "DocumentDate"          TIMESTAMP WITHOUT TIME ZONE,
    "DueDate"               TIMESTAMP WITHOUT TIME ZONE,
    "DocumentTime"          CHARACTER VARYING,
    "SubTotal"              NUMERIC,
    "TaxableAmount"         NUMERIC,
    "ExemptAmount"          NUMERIC,
    "TaxAmount"             NUMERIC,
    "TaxRate"               NUMERIC,
    "TotalAmount"           NUMERIC,
    "DiscountAmount"        NUMERIC,
    "IsVoided"              BOOLEAN,
    "IsPaid"                CHARACTER VARYING,
    "IsInvoiced"            CHARACTER VARYING,
    "IsDelivered"           CHARACTER VARYING,
    "OriginDocumentNumber"  CHARACTER VARYING,
    "OriginDocumentType"    CHARACTER VARYING,
    "ControlNumber"         CHARACTER VARYING,
    "IsLegal"               CHARACTER VARYING,
    "IsPrinted"             BOOLEAN,
    "Notes"                 CHARACTER VARYING,
    "Concept"               CHARACTER VARYING,
    "PaymentTerms"          CHARACTER VARYING,
    "ShipToAddress"         CHARACTER VARYING,
    "SellerCode"            CHARACTER VARYING,
    "DepartmentCode"        CHARACTER VARYING,
    "LocationCode"          CHARACTER VARYING,
    "CurrencyCode"          CHARACTER VARYING,
    "ExchangeRate"          NUMERIC,
    "UserCode"              CHARACTER VARYING,
    "ReportDate"            TIMESTAMP WITHOUT TIME ZONE,
    "HostName"              CHARACTER VARYING,
    "VehiclePlate"          CHARACTER VARYING,
    "Mileage"               NUMERIC,
    "TollAmount"            NUMERIC,
    "CreatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"             TIMESTAMP WITHOUT TIME ZONE,
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
    FROM doc."SalesDocument" sd
    WHERE sd."OperationType" = p_tipo_operacion
      AND sd."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            sd."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd."CustomerName" LIKE '%' || p_search || '%'
            OR sd."FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR sd."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd."IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR sd."IssueDate" < (p_to_date + INTERVAL '1 day'));

    RETURN QUERY
    SELECT
        sd."DocumentId"::BIGINT,                      -- SalesDocumentId
        sd."DocumentNumber"::VARCHAR,
        sd."SerialType"::VARCHAR,
        sd."FiscalMemoryNumber"::VARCHAR,
        sd."OperationType"::VARCHAR,
        sd."CustomerCode"::VARCHAR,
        sd."CustomerName"::VARCHAR,
        sd."FiscalId"::VARCHAR,
        sd."IssueDate",                               -- DocumentDate
        sd."DueDate",
        sd."DocumentTime"::VARCHAR,
        sd."Subtotal"::NUMERIC,                       -- SubTotal (float8â†’numeric)
        sd."TaxableAmount"::NUMERIC,
        sd."ExemptAmount"::NUMERIC,
        sd."TaxAmount"::NUMERIC,
        sd."TaxRate"::NUMERIC,
        sd."TotalAmount"::NUMERIC,
        sd."DiscountAmount"::NUMERIC,
        sd."IsVoided",
        NULL::VARCHAR,                                -- IsPaid (no existe)
        sd."IsInvoiced"::VARCHAR,
        sd."IsDelivered"::VARCHAR,
        sd."SourceDocumentNumber"::VARCHAR,           -- OriginDocumentNumber
        sd."SourceDocumentType"::VARCHAR,             -- OriginDocumentType
        sd."ControlNumber"::VARCHAR,
        NULL::VARCHAR,                                -- IsLegal (no existe)
        NULL::BOOLEAN,                                -- IsPrinted (no existe)
        sd."Notes"::VARCHAR,
        sd."Concept"::VARCHAR,
        NULL::VARCHAR,                                -- PaymentTerms (no existe)
        NULL::VARCHAR,                                -- ShipToAddress (no existe)
        NULL::VARCHAR,                                -- SellerCode (no existe)
        NULL::VARCHAR,                                -- DepartmentCode (no existe)
        NULL::VARCHAR,                                -- LocationCode (no existe)
        sd."CurrencyCode"::VARCHAR,
        sd."ExchangeRate"::NUMERIC,
        sd."LegacyUserCode"::VARCHAR,                 -- UserCode
        NULL::TIMESTAMP WITHOUT TIME ZONE,            -- ReportDate (no existe)
        NULL::VARCHAR,                                -- HostName (no existe)
        NULL::VARCHAR,                                -- VehiclePlate (no existe)
        NULL::NUMERIC,                                -- Mileage (no existe)
        NULL::NUMERIC,                                -- TollAmount (no existe)
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
      AND (p_from_date IS NULL OR sd."IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR sd."IssueDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY sd."IssueDate" DESC, sd."DocumentId" DESC
    LIMIT v_limit OFFSET ((v_page - 1) * v_limit);
END;
$$;

\echo '  [014] COMPLETO â€” usp_doc_salesdocument_list corregido'
