-- ============================================================
-- FIX: sp_crud_clientes.sql - Adapted for production schema
-- master."Customer" has: CustomerCode, CustomerName, FiscalId,
--   Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, IsDeleted, CompanyId
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_clientes_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_list(
    p_search   VARCHAR(100) DEFAULT NULL,
    p_estado   VARCHAR(20)  DEFAULT NULL,
    p_vendedor VARCHAR(60)  DEFAULT NULL,
    p_page     INT          DEFAULT 1,
    p_limit    INT          DEFAULT 50
)
RETURNS TABLE(
    "CODIGO"          VARCHAR,
    "NOMBRE"          VARCHAR,
    "RIF"             VARCHAR,
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR,
    "CustomerName"    VARCHAR,
    "FiscalId"        VARCHAR,
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR,
    "Direccion"       VARCHAR,
    "Telefono"        VARCHAR,
    "Contacto"        VARCHAR,
    "SalespersonCode" VARCHAR,
    "PriceListCode"   VARCHAR,
    "Ciudad"          VARCHAR,
    "CodPostal"       VARCHAR,
    "Email"           VARCHAR,
    "PaginaWww"       VARCHAR,
    "CodUsuario"      VARCHAR,
    "Credito"         DOUBLE PRECISION,
    "TotalCount"      INT
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

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR COALESCE(c."FiscalId",'') ILIKE v_search));

    -- Resultados paginados
    RETURN QUERY
    SELECT
        c."CustomerCode"::VARCHAR                        AS "CODIGO",
        c."CustomerName"::VARCHAR                        AS "NOMBRE",
        COALESCE(c."FiscalId",'')::VARCHAR               AS "RIF",
        COALESCE(c."TotalBalance",0)::DOUBLE PRECISION   AS "SALDO_TOT",
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION    AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        COALESCE(c."FiscalId",'')::VARCHAR,
        COALESCE(c."TotalBalance",0)::DOUBLE PRECISION,
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION,
        NULL::VARCHAR                                    AS "NIT",
        COALESCE(c."AddressLine",'')::VARCHAR            AS "Direccion",
        COALESCE(c."Phone",'')::VARCHAR                  AS "Telefono",
        NULL::VARCHAR                                    AS "Contacto",
        NULL::VARCHAR                                    AS "SalespersonCode",
        NULL::VARCHAR                                    AS "PriceListCode",
        NULL::VARCHAR                                    AS "Ciudad",
        NULL::VARCHAR                                    AS "CodPostal",
        COALESCE(c."Email",'')::VARCHAR                  AS "Email",
        NULL::VARCHAR                                    AS "PaginaWww",
        NULL::VARCHAR                                    AS "CodUsuario",
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION    AS "Credito",
        v_total                                          AS "TotalCount"
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR COALESCE(c."FiscalId",'') ILIKE v_search))
    ORDER BY c."CustomerCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
DROP FUNCTION IF EXISTS usp_clientes_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_getbycodigo(
    p_codigo VARCHAR(24)
)
RETURNS TABLE(
    "CODIGO"          VARCHAR,
    "NOMBRE"          VARCHAR,
    "RIF"             VARCHAR,
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR,
    "CustomerName"    VARCHAR,
    "FiscalId"        VARCHAR,
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR,
    "Direccion"       VARCHAR,
    "Telefono"        VARCHAR,
    "Contacto"        VARCHAR,
    "SalespersonCode" VARCHAR,
    "PriceListCode"   VARCHAR,
    "Ciudad"          VARCHAR,
    "CodPostal"       VARCHAR,
    "Email"           VARCHAR,
    "PaginaWww"       VARCHAR,
    "CodUsuario"      VARCHAR,
    "Credito"         DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode"::VARCHAR                        AS "CODIGO",
        c."CustomerName"::VARCHAR                        AS "NOMBRE",
        COALESCE(c."FiscalId",'')::VARCHAR               AS "RIF",
        COALESCE(c."TotalBalance",0)::DOUBLE PRECISION   AS "SALDO_TOT",
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION    AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        COALESCE(c."FiscalId",'')::VARCHAR,
        COALESCE(c."TotalBalance",0)::DOUBLE PRECISION,
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION,
        NULL::VARCHAR                                    AS "NIT",
        COALESCE(c."AddressLine",'')::VARCHAR            AS "Direccion",
        COALESCE(c."Phone",'')::VARCHAR                  AS "Telefono",
        NULL::VARCHAR                                    AS "Contacto",
        NULL::VARCHAR                                    AS "SalespersonCode",
        NULL::VARCHAR                                    AS "PriceListCode",
        NULL::VARCHAR                                    AS "Ciudad",
        NULL::VARCHAR                                    AS "CodPostal",
        COALESCE(c."Email",'')::VARCHAR                  AS "Email",
        NULL::VARCHAR                                    AS "PaginaWww",
        NULL::VARCHAR                                    AS "CodUsuario",
        COALESCE(c."CreditLimit",0)::DOUBLE PRECISION    AS "Credito"
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_codigo
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert ----------
DROP FUNCTION IF EXISTS usp_clientes_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_insert(
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

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'CODIGO', p_row_json->>'CodCliente',''::VARCHAR)),''::VARCHAR);

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'CODIGO requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Customer" (
        "CustomerCode", "CustomerName", "FiscalId",
        "Email", "Phone", "AddressLine",
        "CreditLimit", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_codigo,
        COALESCE(NULLIF(COALESCE(p_row_json->>'NOMBRE', p_row_json->>'Nombre'),''::VARCHAR), v_codigo),
        NULLIF(p_row_json->>'RIF', ''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'EMAIL', p_row_json->>'Email'),''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'TELEFONO', p_row_json->>'Telefono'),''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'DIRECCION', p_row_json->>'Direccion'),''::VARCHAR),
        CASE WHEN COALESCE(p_row_json->>'LIMITE','') = '' THEN 0
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
DROP FUNCTION IF EXISTS usp_clientes_update(VARCHAR, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_update(
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
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Customer" SET
        "CustomerName" = COALESCE(NULLIF(COALESCE(p_row_json->>'NOMBRE', p_row_json->>'Nombre'),''::VARCHAR), "CustomerName"),
        "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "FiscalId"),
        "Email"        = COALESCE(NULLIF(COALESCE(p_row_json->>'EMAIL', p_row_json->>'Email'),''::VARCHAR), "Email"),
        "Phone"        = COALESCE(NULLIF(COALESCE(p_row_json->>'TELEFONO', p_row_json->>'Telefono'),''::VARCHAR), "Phone"),
        "AddressLine"  = COALESCE(NULLIF(COALESCE(p_row_json->>'DIRECCION', p_row_json->>'Direccion'),''::VARCHAR), "AddressLine"),
        "CreditLimit"  = CASE WHEN COALESCE(p_row_json->>'LIMITE','') = '' THEN "CreditLimit"
                              ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        "IsActive"     = CASE WHEN p_row_json->>'Activo' = 'true' OR p_row_json->>'ESTADO' = 'A' THEN TRUE
                              WHEN p_row_json->>'Activo' = 'false' OR p_row_json->>'ESTADO' = 'I' THEN FALSE
                              ELSE "IsActive" END
    WHERE "CustomerCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
DROP FUNCTION IF EXISTS usp_clientes_delete(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_delete(
    p_codigo VARCHAR(24)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Customer"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "CustomerCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
