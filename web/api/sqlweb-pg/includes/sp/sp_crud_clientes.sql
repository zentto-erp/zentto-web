-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_clientes.sql
-- CRUD de Clientes (master."Customer")
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_clientes_list(VARCHAR(100), VARCHAR(20), VARCHAR(60), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_list(
    p_search   VARCHAR(100) DEFAULT NULL,
    p_estado   VARCHAR(20)  DEFAULT NULL,
    p_vendedor VARCHAR(60)  DEFAULT NULL,
    p_page     INT          DEFAULT 1,
    p_limit    INT          DEFAULT 50
)
RETURNS TABLE(
    "CODIGO"          VARCHAR(12),
    "NOMBRE"          VARCHAR(255),
    "RIF"             VARCHAR(20),
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR(12),
    "CustomerName"    VARCHAR(255),
    "FiscalId"        VARCHAR(20),
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR(20),
    "Direccion"       VARCHAR(255),
    "Telefono"        VARCHAR(60),
    "Contacto"        VARCHAR(30),
    "SalespersonCode" VARCHAR(4),
    "PriceListCode"   VARCHAR(50),
    "Ciudad"          VARCHAR(20),
    "CodPostal"       VARCHAR(10),
    "Email"           VARCHAR(50),
    "PaginaWww"       VARCHAR(50),
    "CodUsuario"      VARCHAR(10),
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
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR c."FiscalId" ILIKE v_search))
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR c."ESTADO" = p_estado)
      AND (p_vendedor IS NULL OR TRIM(p_vendedor) = '' OR c."SalespersonCode" = p_vendedor);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        c."CustomerCode"    AS "CODIGO",
        c."CustomerName"    AS "NOMBRE",
        c."FiscalId"        AS "RIF",
        c."TotalBalance"    AS "SALDO_TOT",
        c."CreditLimit"     AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode",
        c."CustomerName",
        c."FiscalId",
        c."TotalBalance",
        c."CreditLimit",
        c."NIT",
        c."Direccion",
        c."Telefono",
        c."Contacto",
        c."SalespersonCode",
        c."PriceListCode",
        c."Ciudad",
        c."CodPostal",
        c."Email",
        c."PaginaWww",
        c."CodUsuario",
        c."Credito",
        v_total             AS "TotalCount"
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR c."FiscalId" ILIKE v_search))
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR c."ESTADO" = p_estado)
      AND (p_vendedor IS NULL OR TRIM(p_vendedor) = '' OR c."SalespersonCode" = p_vendedor)
    ORDER BY c."CustomerCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
DROP FUNCTION IF EXISTS usp_clientes_getbycodigo(VARCHAR(12)) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_getbycodigo(
    p_codigo VARCHAR(12)
)
RETURNS TABLE(
    "CODIGO"          VARCHAR(12),
    "NOMBRE"          VARCHAR(255),
    "RIF"             VARCHAR(20),
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR(12),
    "CustomerName"    VARCHAR(255),
    "FiscalId"        VARCHAR(20),
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR(20),
    "Direccion"       VARCHAR(255),
    "Telefono"        VARCHAR(60),
    "Contacto"        VARCHAR(30),
    "SalespersonCode" VARCHAR(4),
    "PriceListCode"   VARCHAR(50),
    "Ciudad"          VARCHAR(20),
    "CodPostal"       VARCHAR(10),
    "Email"           VARCHAR(50),
    "PaginaWww"       VARCHAR(50),
    "CodUsuario"      VARCHAR(10),
    "Credito"         DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode"    AS "CODIGO",
        c."CustomerName"    AS "NOMBRE",
        c."FiscalId"        AS "RIF",
        c."TotalBalance"    AS "SALDO_TOT",
        c."CreditLimit"     AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode",
        c."CustomerName",
        c."FiscalId",
        c."TotalBalance",
        c."CreditLimit",
        c."NIT",
        c."Direccion",
        c."Telefono",
        c."Contacto",
        c."SalespersonCode",
        c."PriceListCode",
        c."Ciudad",
        c."CodPostal",
        c."Email",
        c."PaginaWww",
        c."CodUsuario",
        c."Credito"
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
    v_codigo     VARCHAR(12);
BEGIN
    -- Obtener CompanyId por defecto
    SELECT co."CompanyId" INTO v_company_id
    FROM cfg."Company" co
    WHERE COALESCE(co."IsDeleted", FALSE) = FALSE
    ORDER BY co."CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(p_row_json->>'CODIGO', '');

    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Customer" (
        "CustomerCode", "CustomerName", "FiscalId", "NIT",
        "Direccion", "Direccion1", "Sucursal", "Telefono",
        "Contacto", "SalespersonCode", "ESTADO", "Ciudad",
        "CodPostal", "Email", "PaginaWww", "CodUsuario",
        "CreditLimit", "Credito", "PriceListCode",
        "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_codigo,
        NULLIF(p_row_json->>'NOMBRE', ''),
        NULLIF(p_row_json->>'RIF', ''),
        NULLIF(p_row_json->>'NIT', ''),
        NULLIF(p_row_json->>'DIRECCION', ''),
        NULLIF(p_row_json->>'DIRECCION1', ''),
        NULLIF(p_row_json->>'SUCURSAL', ''),
        NULLIF(p_row_json->>'TELEFONO', ''),
        NULLIF(p_row_json->>'CONTACTO', ''),
        NULLIF(p_row_json->>'VENDEDOR', ''),
        NULLIF(p_row_json->>'ESTADO', ''),
        NULLIF(p_row_json->>'CIUDAD', ''),
        NULLIF(p_row_json->>'CPOSTAL', ''),
        NULLIF(p_row_json->>'EMAIL', ''),
        NULLIF(p_row_json->>'PAGINA_WWW', ''),
        NULLIF(p_row_json->>'COD_USUARIO', ''),
        CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
             THEN NULL
             ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
        CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
             THEN NULL
             ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
        CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
             THEN NULL
             ELSE NULLIF(p_row_json->>'LISTA_PRECIO', '') END,
        TRUE,   -- IsActive
        FALSE,  -- IsDeleted
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
DROP FUNCTION IF EXISTS usp_clientes_update(VARCHAR(12), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_update(
    p_codigo   VARCHAR(12),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Customer" SET
        "CustomerName"    = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''), "CustomerName"),
        "FiscalId"        = COALESCE(NULLIF(p_row_json->>'RIF', ''), "FiscalId"),
        "NIT"             = COALESCE(NULLIF(p_row_json->>'NIT', ''), "NIT"),
        "Direccion"       = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''), "Direccion"),
        "Direccion1"      = COALESCE(NULLIF(p_row_json->>'DIRECCION1', ''), "Direccion1"),
        "Sucursal"        = COALESCE(NULLIF(p_row_json->>'SUCURSAL', ''), "Sucursal"),
        "Telefono"        = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''), "Telefono"),
        "Contacto"        = COALESCE(NULLIF(p_row_json->>'CONTACTO', ''), "Contacto"),
        "SalespersonCode" = COALESCE(NULLIF(p_row_json->>'VENDEDOR', ''), "SalespersonCode"),
        "ESTADO"          = COALESCE(NULLIF(p_row_json->>'ESTADO', ''), "ESTADO"),
        "Ciudad"          = COALESCE(NULLIF(p_row_json->>'CIUDAD', ''), "Ciudad"),
        "CodPostal"       = COALESCE(NULLIF(p_row_json->>'CPOSTAL', ''), "CodPostal"),
        "Email"           = COALESCE(NULLIF(p_row_json->>'EMAIL', ''), "Email"),
        "PaginaWww"       = COALESCE(NULLIF(p_row_json->>'PAGINA_WWW', ''), "PaginaWww"),
        "CodUsuario"      = COALESCE(NULLIF(p_row_json->>'COD_USUARIO', ''), "CodUsuario"),
        "CreditLimit"     = CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
                                 THEN "CreditLimit"
                                 ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
        "Credito"         = CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
                                 THEN "Credito"
                                 ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
        "PriceListCode"   = CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
                                 THEN "PriceListCode"
                                 ELSE NULLIF(p_row_json->>'LISTA_PRECIO', '') END
    WHERE "CustomerCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
DROP FUNCTION IF EXISTS usp_clientes_delete(VARCHAR(12)) CASCADE;
CREATE OR REPLACE FUNCTION usp_clientes_delete(
    p_codigo VARCHAR(12)
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
