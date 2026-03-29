-- +goose Up
-- Agregar filtro por estado (Emitida/Pagada/Anulada) a usp_doc_salesdocument_list

DROP FUNCTION IF EXISTS usp_doc_salesdocument_list(VARCHAR, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS usp_doc_salesdocument_list(VARCHAR(20), VARCHAR(100), VARCHAR(60), DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_doc_salesdocument_list(VARCHAR, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_doc_salesdocument_list(
    p_tipo_operacion  VARCHAR    DEFAULT NULL,
    p_page            INT        DEFAULT 1,
    p_limit           INT        DEFAULT 50,
    p_search          VARCHAR    DEFAULT NULL,
    p_codigo          VARCHAR    DEFAULT NULL,
    p_from_date       TIMESTAMP  DEFAULT NULL,
    p_to_date         TIMESTAMP  DEFAULT NULL,
    p_estado          VARCHAR    DEFAULT NULL
)
RETURNS TABLE(
    "SalesDocumentId"       bigint,
    "DocumentNumber"        character varying,
    "SerialType"            character varying,
    "FiscalMemoryNumber"    character varying,
    "OperationType"         character varying,
    "CustomerCode"          character varying,
    "CustomerName"          character varying,
    "FiscalId"              character varying,
    "DocumentDate"          timestamp without time zone,
    "DueDate"               timestamp without time zone,
    "DocumentTime"          character varying,
    "SubTotal"              numeric,
    "TaxableAmount"         numeric,
    "ExemptAmount"          numeric,
    "TaxAmount"             numeric,
    "TaxRate"               numeric,
    "TotalAmount"           numeric,
    "DiscountAmount"        numeric,
    "IsVoided"              boolean,
    "IsPaid"                character varying,
    "IsInvoiced"            character varying,
    "IsDelivered"           character varying,
    "OriginDocumentNumber"  character varying,
    "OriginDocumentType"    character varying,
    "ControlNumber"         character varying,
    "IsLegal"               character varying,
    "IsPrinted"             boolean,
    "Notes"                 character varying,
    "Concept"               character varying,
    "PaymentTerms"          character varying,
    "ShipToAddress"         character varying,
    "SellerCode"            character varying,
    "DepartmentCode"        character varying,
    "LocationCode"          character varying,
    "CurrencyCode"          character varying,
    "ExchangeRate"          numeric,
    "UserCode"              character varying,
    "ReportDate"            timestamp without time zone,
    "HostName"              character varying,
    "VehiclePlate"          character varying,
    "Mileage"               numeric,
    "TollAmount"            numeric,
    "CreatedAt"             timestamp without time zone,
    "UpdatedAt"             timestamp without time zone,
    "IsDeleted"             boolean,
    "TotalCount"            bigint
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $func$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."SalesDocument" sd_c
    WHERE COALESCE(sd_c."IsDeleted", FALSE) = FALSE
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
$func$;
-- +goose StatementEnd

-- +goose Down
-- Restaurar funcion sin filtro de estado
DROP FUNCTION IF EXISTS usp_doc_salesdocument_list(VARCHAR, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_doc_salesdocument_list(
    p_tipo_operacion  VARCHAR    DEFAULT NULL,
    p_page            INT        DEFAULT 1,
    p_limit           INT        DEFAULT 50,
    p_search          VARCHAR    DEFAULT NULL,
    p_codigo          VARCHAR    DEFAULT NULL,
    p_from_date       TIMESTAMP  DEFAULT NULL,
    p_to_date         TIMESTAMP  DEFAULT NULL
)
RETURNS TABLE(
    "SalesDocumentId"       bigint,
    "DocumentNumber"        character varying,
    "SerialType"            character varying,
    "FiscalMemoryNumber"    character varying,
    "OperationType"         character varying,
    "CustomerCode"          character varying,
    "CustomerName"          character varying,
    "FiscalId"              character varying,
    "DocumentDate"          timestamp without time zone,
    "DueDate"               timestamp without time zone,
    "DocumentTime"          character varying,
    "SubTotal"              numeric,
    "TaxableAmount"         numeric,
    "ExemptAmount"          numeric,
    "TaxAmount"             numeric,
    "TaxRate"               numeric,
    "TotalAmount"           numeric,
    "DiscountAmount"        numeric,
    "IsVoided"              boolean,
    "IsPaid"                character varying,
    "IsInvoiced"            character varying,
    "IsDelivered"           character varying,
    "OriginDocumentNumber"  character varying,
    "OriginDocumentType"    character varying,
    "ControlNumber"         character varying,
    "IsLegal"               character varying,
    "IsPrinted"             boolean,
    "Notes"                 character varying,
    "Concept"               character varying,
    "PaymentTerms"          character varying,
    "ShipToAddress"         character varying,
    "SellerCode"            character varying,
    "DepartmentCode"        character varying,
    "LocationCode"          character varying,
    "CurrencyCode"          character varying,
    "ExchangeRate"          numeric,
    "UserCode"              character varying,
    "ReportDate"            timestamp without time zone,
    "HostName"              character varying,
    "VehiclePlate"          character varying,
    "Mileage"               numeric,
    "TollAmount"            numeric,
    "CreatedAt"             timestamp without time zone,
    "UpdatedAt"             timestamp without time zone,
    "IsDeleted"             boolean,
    "TotalCount"            bigint
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $func$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."SalesDocument" sd_c
    WHERE COALESCE(sd_c."IsDeleted", FALSE) = FALSE
      AND (p_tipo_operacion IS NULL OR sd_c."OperationType" = p_tipo_operacion)
      AND (p_search IS NULL OR (
            sd_c."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd_c."CustomerName" LIKE '%' || p_search || '%'
            OR sd_c."FiscalId"     LIKE '%' || p_search || '%'
           ))
      AND (p_codigo    IS NULL OR sd_c."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd_c."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR sd_c."IssueDate" <  (p_to_date + INTERVAL '1 day'));

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
      AND (p_tipo_operacion IS NULL OR sd."OperationType" = p_tipo_operacion)
      AND (p_search IS NULL OR (
            sd."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd."CustomerName" LIKE '%' || p_search || '%'
            OR sd."FiscalId"     LIKE '%' || p_search || '%'
           ))
      AND (p_codigo    IS NULL OR sd."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd."IssueDate" >= p_from_date)
      AND (p_to_date   IS NULL OR sd."IssueDate" <  (p_to_date + INTERVAL '1 day'))
    ORDER BY sd."IssueDate" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$func$;
-- +goose StatementEnd

