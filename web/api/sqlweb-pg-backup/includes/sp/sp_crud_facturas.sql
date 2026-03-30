-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_facturas.sql
-- Facturas (solo List + Get; emitir usa sp_emitir_factura_tx)
-- Migrado a ar."SalesDocument" (OperationType = 'FACT')
-- ============================================================

-- ---------- 1. List (paginado: documentNumber, userCode, from, to) ----------
DROP FUNCTION IF EXISTS usp_facturas_list(VARCHAR(60), VARCHAR(60), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_facturas_list(
    p_num_fact    VARCHAR(60) DEFAULT NULL,
    p_cod_usuario VARCHAR(60) DEFAULT NULL,
    p_from        DATE        DEFAULT NULL,
    p_to          DATE        DEFAULT NULL,
    p_page        INT         DEFAULT 1,
    p_limit       INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"       INT,
    "Id"               INT,
    "DocumentNumber"   VARCHAR(60),
    "OperationType"    VARCHAR(20),
    "DocumentDate"     TIMESTAMP,
    "UserCode"         VARCHAR(60),
    "ClientCode"       VARCHAR(60),
    "ClientName"       VARCHAR(200),
    "SubTotal"         NUMERIC,
    "TaxAmount"        NUMERIC,
    "TotalAmount"      NUMERIC,
    "Currency"         VARCHAR(10),
    "ExchangeRate"     NUMERIC,
    "Notes"            TEXT,
    "IsDeleted"        BOOLEAN,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM ar."SalesDocument" sd
    WHERE sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE
      AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
      AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
      AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
      AND (p_to IS NULL OR sd."DocumentDate" <= p_to);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        sd."Id",
        sd."DocumentNumber",
        sd."OperationType",
        sd."DocumentDate",
        sd."UserCode",
        sd."ClientCode",
        sd."ClientName",
        sd."SubTotal",
        sd."TaxAmount",
        sd."TotalAmount",
        sd."Currency",
        sd."ExchangeRate",
        sd."Notes",
        sd."IsDeleted",
        sd."CreatedAt",
        sd."UpdatedAt"
    FROM ar."SalesDocument" sd
    WHERE sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE
      AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
      AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
      AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
      AND (p_to IS NULL OR sd."DocumentDate" <= p_to)
    ORDER BY sd."DocumentDate" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by DocumentNumber ----------
DROP FUNCTION IF EXISTS usp_facturas_getbynumfact(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_facturas_getbynumfact(
    p_num_fact VARCHAR(60)
)
RETURNS TABLE(
    "Id"               INT,
    "DocumentNumber"   VARCHAR(60),
    "OperationType"    VARCHAR(20),
    "DocumentDate"     TIMESTAMP,
    "UserCode"         VARCHAR(60),
    "ClientCode"       VARCHAR(60),
    "ClientName"       VARCHAR(200),
    "SubTotal"         NUMERIC,
    "TaxAmount"        NUMERIC,
    "TotalAmount"      NUMERIC,
    "Currency"         VARCHAR(10),
    "ExchangeRate"     NUMERIC,
    "Notes"            TEXT,
    "IsDeleted"        BOOLEAN,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        sd."Id",
        sd."DocumentNumber",
        sd."OperationType",
        sd."DocumentDate",
        sd."UserCode",
        sd."ClientCode",
        sd."ClientName",
        sd."SubTotal",
        sd."TaxAmount",
        sd."TotalAmount",
        sd."Currency",
        sd."ExchangeRate",
        sd."Notes",
        sd."IsDeleted",
        sd."CreatedAt",
        sd."UpdatedAt"
    FROM ar."SalesDocument" sd
    WHERE sd."DocumentNumber" = p_num_fact
      AND sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE;
END;
$$;
