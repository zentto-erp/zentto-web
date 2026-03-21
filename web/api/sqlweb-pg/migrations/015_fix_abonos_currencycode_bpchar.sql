\echo '  [015] Fix character(3)→VARCHAR en usp_ar_application_listbycontext...'

-- d."CurrencyCode" es character(3) (bpchar) en ar."ReceivableDocument"
-- pero RETURNS TABLE lo declara como character varying.
-- Fix: agregar ::VARCHAR cast en el SELECT.

CREATE OR REPLACE FUNCTION public.usp_ar_application_listbycontext(
    p_company_id     integer,
    p_branch_id      integer,
    p_search         character varying DEFAULT NULL,
    p_codigo         character varying DEFAULT NULL,
    p_currency_code  character varying DEFAULT NULL,
    p_page           integer DEFAULT 1,
    p_limit          integer DEFAULT 50
)
RETURNS TABLE(
    "Id"          BIGINT,
    "ApplicationId" BIGINT,
    "DocumentoId" BIGINT,
    "CODIGO"      CHARACTER VARYING,
    "Codigo"      CHARACTER VARYING,
    "NOMBRE"      CHARACTER VARYING,
    "TIPO_DOC"    CHARACTER VARYING,
    "TipoDoc"     CHARACTER VARYING,
    "DOCUMENTO"   CHARACTER VARYING,
    "Num_fact"    CHARACTER VARYING,
    "FECHA"       DATE,
    "Fecha"       DATE,
    "MONTO"       NUMERIC,
    "Monto"       NUMERIC,
    "MONEDA"      CHARACTER VARYING,
    "REFERENCIA"  CHARACTER VARYING,
    "Concepto"    CHARACTER VARYING,
    "PENDIENTE"   NUMERIC,
    "TOTAL"       NUMERIC,
    "ESTADO_DOC"  CHARACTER VARYING,
    "TotalCount"  BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_page           INT := GREATEST(COALESCE(p_page, 1), 1);
    v_limit          INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);
    v_offset         INT := (v_page - 1) * v_limit;
    v_search_pattern VARCHAR(102);
    v_total          BIGINT;
BEGIN
    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN
        v_search_pattern := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(*) INTO v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE d."CompanyId" = p_company_id
      AND d."BranchId"  = p_branch_id
      AND (v_search_pattern IS NULL
           OR d."DocumentNumber"    ILIKE v_search_pattern
           OR c."CustomerName"      ILIKE v_search_pattern
           OR a."PaymentReference"  ILIKE v_search_pattern)
      AND (p_codigo        IS NULL OR c."CustomerCode"  = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode"::VARCHAR = p_currency_code);

    RETURN QUERY
    SELECT
        a."ReceivableApplicationId",
        a."ReceivableApplicationId",
        d."ReceivableDocumentId",
        c."CustomerCode",
        c."CustomerCode",
        c."CustomerName",
        d."DocumentType",
        d."DocumentType",
        d."DocumentNumber",
        d."DocumentNumber",
        a."ApplyDate",
        a."ApplyDate",
        a."AppliedAmount",
        a."AppliedAmount",
        d."CurrencyCode"::VARCHAR,   -- FIX: bpchar → varchar
        a."PaymentReference",
        a."PaymentReference",
        d."PendingAmount",
        d."TotalAmount",
        d."Status",
        v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE d."CompanyId" = p_company_id
      AND d."BranchId"  = p_branch_id
      AND (v_search_pattern IS NULL
           OR d."DocumentNumber"    ILIKE v_search_pattern
           OR c."CustomerName"      ILIKE v_search_pattern
           OR a."PaymentReference"  ILIKE v_search_pattern)
      AND (p_codigo        IS NULL OR c."CustomerCode"  = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode"::VARCHAR = p_currency_code)
    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

\echo '  [015] COMPLETO — abonos CurrencyCode bpchar corregido'
