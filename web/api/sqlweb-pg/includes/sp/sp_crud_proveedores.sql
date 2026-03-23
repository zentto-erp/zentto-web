-- ============================================================
-- FIX: sp_crud_proveedores.sql - Adapted for production schema
-- master."Supplier" has: SupplierCode, SupplierName, FiscalId,
--   Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, IsDeleted, CompanyId
-- ============================================================

-- ---------- 1. List ----------
DROP FUNCTION IF EXISTS usp_proveedores_list CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_list(
    p_company_id INT         DEFAULT 1,
    p_search   VARCHAR(100) DEFAULT NULL,
    p_estado   VARCHAR(20)  DEFAULT NULL,
    p_vendedor VARCHAR(60)  DEFAULT NULL,
    p_page     INT          DEFAULT 1,
    p_limit    INT          DEFAULT 50
)
RETURNS TABLE(
    "CODIGO"       VARCHAR,
    "NOMBRE"       VARCHAR,
    "RIF"          VARCHAR,
    "NIT"          VARCHAR,
    "DIRECCION"    VARCHAR,
    "TELEFONO"     VARCHAR,
    "FAX"          VARCHAR,
    "CONTACTO"     VARCHAR,
    "VENDEDOR"     VARCHAR,
    "ESTADO"       VARCHAR,
    "CIUDAD"       VARCHAR,
    "CPOSTAL"      VARCHAR,
    "EMAIL"        VARCHAR,
    "PAGINA_WWW"   VARCHAR,
    "COD_USUARIO"  VARCHAR,
    "LIMITE"       DOUBLE PRECISION,
    "CREDITO"      DOUBLE PRECISION,
    "NOTAS"        VARCHAR,
    "TotalCount"   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Supplier" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (p_company_id IS NULL OR s."CompanyId" = p_company_id)
      AND (v_search IS NULL OR (s."SupplierCode" ILIKE v_search OR s."SupplierName" ILIKE v_search OR COALESCE(s."FiscalId",''::VARCHAR) ILIKE v_search));

    RETURN QUERY
    SELECT
        s."SupplierCode"::VARCHAR                       AS "CODIGO",
        s."SupplierName"::VARCHAR                       AS "NOMBRE",
        COALESCE(s."FiscalId",''::VARCHAR)::VARCHAR              AS "RIF",
        NULL::VARCHAR                                   AS "NIT",
        COALESCE(s."AddressLine",''::VARCHAR)::VARCHAR           AS "DIRECCION",
        COALESCE(s."Phone",''::VARCHAR)::VARCHAR                 AS "TELEFONO",
        NULL::VARCHAR                                   AS "FAX",
        NULL::VARCHAR                                   AS "CONTACTO",
        NULL::VARCHAR                                   AS "VENDEDOR",
        CASE WHEN s."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "ESTADO",
        NULL::VARCHAR                                   AS "CIUDAD",
        NULL::VARCHAR                                   AS "CPOSTAL",
        COALESCE(s."Email",''::VARCHAR)::VARCHAR                 AS "EMAIL",
        NULL::VARCHAR                                   AS "PAGINA_WWW",
        NULL::VARCHAR                                   AS "COD_USUARIO",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION   AS "LIMITE",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION   AS "CREDITO",
        NULL::VARCHAR                                   AS "NOTAS",
        v_total                                         AS "TotalCount"
    FROM master."Supplier" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (s."SupplierCode" ILIKE v_search OR s."SupplierName" ILIKE v_search OR COALESCE(s."FiscalId",''::VARCHAR) ILIKE v_search))
    ORDER BY s."SupplierCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
DROP FUNCTION IF EXISTS usp_proveedores_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_getbycodigo(
    p_codigo VARCHAR(24)
)
RETURNS TABLE(
    "CODIGO"       VARCHAR,
    "NOMBRE"       VARCHAR,
    "RIF"          VARCHAR,
    "NIT"          VARCHAR,
    "DIRECCION"    VARCHAR,
    "TELEFONO"     VARCHAR,
    "FAX"          VARCHAR,
    "CONTACTO"     VARCHAR,
    "VENDEDOR"     VARCHAR,
    "ESTADO"       VARCHAR,
    "CIUDAD"       VARCHAR,
    "CPOSTAL"      VARCHAR,
    "EMAIL"        VARCHAR,
    "PAGINA_WWW"   VARCHAR,
    "COD_USUARIO"  VARCHAR,
    "LIMITE"       DOUBLE PRECISION,
    "CREDITO"      DOUBLE PRECISION,
    "NOTAS"        VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SupplierCode"::VARCHAR                       AS "CODIGO",
        s."SupplierName"::VARCHAR                       AS "NOMBRE",
        COALESCE(s."FiscalId",''::VARCHAR)::VARCHAR              AS "RIF",
        NULL::VARCHAR                                   AS "NIT",
        COALESCE(s."AddressLine",''::VARCHAR)::VARCHAR           AS "DIRECCION",
        COALESCE(s."Phone",''::VARCHAR)::VARCHAR                 AS "TELEFONO",
        NULL::VARCHAR                                   AS "FAX",
        NULL::VARCHAR                                   AS "CONTACTO",
        NULL::VARCHAR                                   AS "VENDEDOR",
        CASE WHEN s."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "ESTADO",
        NULL::VARCHAR                                   AS "CIUDAD",
        NULL::VARCHAR                                   AS "CPOSTAL",
        COALESCE(s."Email",''::VARCHAR)::VARCHAR                 AS "EMAIL",
        NULL::VARCHAR                                   AS "PAGINA_WWW",
        NULL::VARCHAR                                   AS "COD_USUARIO",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION   AS "LIMITE",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION   AS "CREDITO",
        NULL::VARCHAR                                   AS "NOTAS"
    FROM master."Supplier" s
    WHERE s."SupplierCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert ----------
DROP FUNCTION IF EXISTS usp_proveedores_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(24);
BEGIN
    SELECT co."CompanyId" INTO v_company_id
    FROM cfg."Company" co
    WHERE COALESCE(co."IsDeleted", FALSE) = FALSE
    ORDER BY co."CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'CODIGO', ''::VARCHAR)),''::VARCHAR);

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'CODIGO requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Supplier" (
        "SupplierCode", "SupplierName", "FiscalId",
        "Email", "Phone", "AddressLine",
        "CreditLimit", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_codigo,
        COALESCE(NULLIF(p_row_json->>'NOMBRE',''::VARCHAR), v_codigo),
        NULLIF(p_row_json->>'RIF', ''::VARCHAR),
        NULLIF(p_row_json->>'EMAIL', ''::VARCHAR),
        NULLIF(p_row_json->>'TELEFONO', ''::VARCHAR),
        NULLIF(p_row_json->>'DIRECCION', ''::VARCHAR),
        CASE WHEN COALESCE(p_row_json->>'LIMITE',''::VARCHAR) = '' THEN 0
             ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        TRUE,
        FALSE,
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
DROP FUNCTION IF EXISTS usp_proveedores_update(VARCHAR, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_update(
    p_codigo   VARCHAR(24),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Supplier" SET
        "SupplierName" = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''::VARCHAR), "SupplierName"),
        "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "FiscalId"),
        "Email"        = COALESCE(NULLIF(p_row_json->>'EMAIL', ''::VARCHAR), "Email"),
        "Phone"        = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''::VARCHAR), "Phone"),
        "AddressLine"  = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''::VARCHAR), "AddressLine"),
        "CreditLimit"  = CASE WHEN COALESCE(p_row_json->>'LIMITE',''::VARCHAR) = '' THEN "CreditLimit"
                              ELSE (p_row_json->>'LIMITE')::NUMERIC END
    WHERE "SupplierCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
DROP FUNCTION IF EXISTS usp_proveedores_delete(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_delete(
    p_codigo VARCHAR(24)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Supplier"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "SupplierCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
