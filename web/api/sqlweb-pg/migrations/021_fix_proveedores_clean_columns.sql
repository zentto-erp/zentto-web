-- =============================================================================
--  Migración 021: Limpiar columnas canónicas expuestas en usp_Proveedores_*
--  Motivo: usp_proveedores_list y usp_proveedores_getbycodigo devolvían
--          columnas canónicas crudas (IsActive, IsDeleted, CompanyId,
--          SupplierCode, SupplierName, FiscalId, TotalBalance, CreditLimit)
--          además de los alias legacy, causando que el frontend mostrara
--          columnas internas de la tabla master."Supplier".
--  Fix: RETURNS TABLE solo con campos legacy (CODIGO, NOMBRE, RIF, etc.)
-- =============================================================================

\echo '  [021] Limpiando columnas canónicas en usp_proveedores_list...'

DROP FUNCTION IF EXISTS usp_proveedores_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_proveedores_list(
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
      AND (v_search IS NULL OR (s."SupplierCode" ILIKE v_search OR s."SupplierName" ILIKE v_search OR COALESCE(s."FiscalId",'') ILIKE v_search));

    RETURN QUERY
    SELECT
        s."SupplierCode"::VARCHAR                            AS "CODIGO",
        s."SupplierName"::VARCHAR                            AS "NOMBRE",
        COALESCE(s."FiscalId",'')::VARCHAR                   AS "RIF",
        NULL::VARCHAR                                        AS "NIT",
        COALESCE(s."AddressLine",'')::VARCHAR                AS "DIRECCION",
        COALESCE(s."Phone",'')::VARCHAR                      AS "TELEFONO",
        NULL::VARCHAR                                        AS "FAX",
        NULL::VARCHAR                                        AS "CONTACTO",
        NULL::VARCHAR                                        AS "VENDEDOR",
        CASE WHEN s."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "ESTADO",
        NULL::VARCHAR                                        AS "CIUDAD",
        NULL::VARCHAR                                        AS "CPOSTAL",
        COALESCE(s."Email",'')::VARCHAR                      AS "EMAIL",
        NULL::VARCHAR                                        AS "PAGINA_WWW",
        NULL::VARCHAR                                        AS "COD_USUARIO",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION        AS "LIMITE",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION        AS "CREDITO",
        NULL::VARCHAR                                        AS "NOTAS",
        v_total                                              AS "TotalCount"
    FROM master."Supplier" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (s."SupplierCode" ILIKE v_search OR s."SupplierName" ILIKE v_search OR COALESCE(s."FiscalId",'') ILIKE v_search))
    ORDER BY s."SupplierCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_proveedores_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) TO zentto_app;

\echo '  [021] Limpiando columnas canónicas en usp_proveedores_getbycodigo...'

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
        s."SupplierCode"::VARCHAR                            AS "CODIGO",
        s."SupplierName"::VARCHAR                            AS "NOMBRE",
        COALESCE(s."FiscalId",'')::VARCHAR                   AS "RIF",
        NULL::VARCHAR                                        AS "NIT",
        COALESCE(s."AddressLine",'')::VARCHAR                AS "DIRECCION",
        COALESCE(s."Phone",'')::VARCHAR                      AS "TELEFONO",
        NULL::VARCHAR                                        AS "FAX",
        NULL::VARCHAR                                        AS "CONTACTO",
        NULL::VARCHAR                                        AS "VENDEDOR",
        CASE WHEN s."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "ESTADO",
        NULL::VARCHAR                                        AS "CIUDAD",
        NULL::VARCHAR                                        AS "CPOSTAL",
        COALESCE(s."Email",'')::VARCHAR                      AS "EMAIL",
        NULL::VARCHAR                                        AS "PAGINA_WWW",
        NULL::VARCHAR                                        AS "COD_USUARIO",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION        AS "LIMITE",
        COALESCE(s."CreditLimit",0)::DOUBLE PRECISION        AS "CREDITO",
        NULL::VARCHAR                                        AS "NOTAS"
    FROM master."Supplier" s
    WHERE s."SupplierCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_proveedores_getbycodigo(VARCHAR) TO zentto_app;

\echo '  [021] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('021_fix_proveedores_clean_columns', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [021] COMPLETO — usp_Proveedores_List y GetByCodigo sin columnas canónicas expuestas'
