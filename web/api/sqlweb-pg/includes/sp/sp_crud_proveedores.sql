-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_proveedores.sql
-- CRUD de Proveedores. Tabla canonica: master."Supplier"
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_proveedores_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_estado VARCHAR(60) DEFAULT NULL,
    p_vendedor VARCHAR(2) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "CODIGO" VARCHAR(10),
    "NOMBRE" VARCHAR(255),
    "RIF" VARCHAR(20),
    "SALDO_TOT" DOUBLE PRECISION,
    "LIMITE" DOUBLE PRECISION,
    "IsActive" BOOLEAN,
    "IsDeleted" BOOLEAN,
    "CompanyId" INT,
    "SupplierCode" VARCHAR(10),
    "SupplierName" VARCHAR(255),
    "FiscalId" VARCHAR(20),
    "TotalBalance" DOUBLE PRECISION,
    "CreditLimit" DOUBLE PRECISION,
    "NIT" VARCHAR(20),
    "Direccion" VARCHAR(255),
    "Direccion1" VARCHAR(255),
    "Sucursal" VARCHAR(50),
    "Telefono" VARCHAR(60),
    "Fax" VARCHAR(10),
    "Contacto" VARCHAR(30),
    "VENDEDOR" VARCHAR(2),
    "ESTADO" VARCHAR(60),
    "Ciudad" VARCHAR(30),
    "CodPostal" VARCHAR(10),
    "Email" VARCHAR(50),
    "PaginaWww" VARCHAR(50),
    "CodUsuario" VARCHAR(10),
    "Credito" DOUBLE PRECISION,
    "ListaPrecio" INT,
    "Notas" VARCHAR(50),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Supplier" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL
           OR s."SupplierCode" LIKE v_search_param
           OR s."SupplierName" LIKE v_search_param
           OR s."FiscalId" LIKE v_search_param)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR s."ESTADO" = p_estado)
      AND (p_vendedor IS NULL OR TRIM(p_vendedor) = '' OR s."VENDEDOR" = p_vendedor);

    RETURN QUERY
    SELECT
        s."SupplierCode"  AS "CODIGO",
        s."SupplierName"  AS "NOMBRE",
        s."FiscalId"      AS "RIF",
        s."TotalBalance"  AS "SALDO_TOT",
        s."CreditLimit"   AS "LIMITE",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SupplierCode",
        s."SupplierName",
        s."FiscalId",
        s."TotalBalance",
        s."CreditLimit",
        s."NIT",
        s."Direccion",
        s."Direccion1",
        s."Sucursal",
        s."Telefono",
        s."Fax",
        s."Contacto",
        s."VENDEDOR",
        s."ESTADO",
        s."Ciudad",
        s."CodPostal",
        s."Email",
        s."PaginaWww",
        s."CodUsuario",
        s."Credito",
        s."ListaPrecio",
        s."Notas",
        v_total AS "TotalCount"
    FROM master."Supplier" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL
           OR s."SupplierCode" LIKE v_search_param
           OR s."SupplierName" LIKE v_search_param
           OR s."FiscalId" LIKE v_search_param)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR s."ESTADO" = p_estado)
      AND (p_vendedor IS NULL OR TRIM(p_vendedor) = '' OR s."VENDEDOR" = p_vendedor)
    ORDER BY s."SupplierCode"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_proveedores_getbycodigo(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "CODIGO" VARCHAR(10),
    "NOMBRE" VARCHAR(255),
    "RIF" VARCHAR(20),
    "SALDO_TOT" DOUBLE PRECISION,
    "LIMITE" DOUBLE PRECISION,
    "IsActive" BOOLEAN,
    "IsDeleted" BOOLEAN,
    "CompanyId" INT,
    "SupplierCode" VARCHAR(10),
    "SupplierName" VARCHAR(255),
    "FiscalId" VARCHAR(20),
    "TotalBalance" DOUBLE PRECISION,
    "CreditLimit" DOUBLE PRECISION,
    "NIT" VARCHAR(20),
    "Direccion" VARCHAR(255),
    "Direccion1" VARCHAR(255),
    "Sucursal" VARCHAR(50),
    "Telefono" VARCHAR(60),
    "Fax" VARCHAR(10),
    "Contacto" VARCHAR(30),
    "VENDEDOR" VARCHAR(2),
    "ESTADO" VARCHAR(60),
    "Ciudad" VARCHAR(30),
    "CodPostal" VARCHAR(10),
    "Email" VARCHAR(50),
    "PaginaWww" VARCHAR(50),
    "CodUsuario" VARCHAR(10),
    "Credito" DOUBLE PRECISION,
    "ListaPrecio" INT,
    "Notas" VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SupplierCode"  AS "CODIGO",
        s."SupplierName"  AS "NOMBRE",
        s."FiscalId"      AS "RIF",
        s."TotalBalance"  AS "SALDO_TOT",
        s."CreditLimit"   AS "LIMITE",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SupplierCode",
        s."SupplierName",
        s."FiscalId",
        s."TotalBalance",
        s."CreditLimit",
        s."NIT",
        s."Direccion",
        s."Direccion1",
        s."Sucursal",
        s."Telefono",
        s."Fax",
        s."Contacto",
        s."VENDEDOR",
        s."ESTADO",
        s."Ciudad",
        s."CodPostal",
        s."Email",
        s."PaginaWww",
        s."CodUsuario",
        s."Credito",
        s."ListaPrecio",
        s."Notas"
    FROM master."Supplier" s
    WHERE s."SupplierCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert (fila como JSONB) ----------
CREATE OR REPLACE FUNCTION usp_proveedores_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_codigo VARCHAR(10);
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE
    ORDER BY "CompanyId"
    LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(p_row_json->>'CODIGO', '');

    IF EXISTS (SELECT 1 FROM master."Supplier" WHERE "SupplierCode" = v_codigo AND "CompanyId" = v_company_id) THEN
        RETURN QUERY SELECT -1, 'Proveedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO master."Supplier" (
            "SupplierCode", "SupplierName", "FiscalId", "NIT",
            "Direccion", "Direccion1", "Sucursal", "Telefono", "Fax",
            "Contacto", "VENDEDOR", "ESTADO", "Ciudad", "CodPostal",
            "Email", "PaginaWww", "CodUsuario", "CreditLimit", "Credito",
            "ListaPrecio", "Notas", "IsActive", "IsDeleted", "CompanyId"
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
            NULLIF(p_row_json->>'FAX', ''),
            NULLIF(p_row_json->>'CONTACTO', ''),
            NULLIF(p_row_json->>'VENDEDOR', ''),
            NULLIF(p_row_json->>'ESTADO', ''),
            NULLIF(p_row_json->>'CIUDAD', ''),
            NULLIF(p_row_json->>'CPOSTAL', ''),
            NULLIF(p_row_json->>'EMAIL', ''),
            NULLIF(p_row_json->>'PAGINA_WWW', ''),
            NULLIF(p_row_json->>'COD_USUARIO', ''),
            CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = '' THEN NULL
                 ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = '' THEN NULL
                 ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = '' THEN 0
                 ELSE (p_row_json->>'LISTA_PRECIO')::INT END,
            NULLIF(p_row_json->>'NOTAS', ''),
            TRUE,   -- IsActive
            FALSE,  -- IsDeleted
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_proveedores_update(
    p_codigo VARCHAR(10),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Supplier" WHERE "SupplierCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Supplier"
        SET
            "SupplierName" = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''), "SupplierName"),
            "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''), "FiscalId"),
            "NIT"          = COALESCE(NULLIF(p_row_json->>'NIT', ''), "NIT"),
            "Direccion"    = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''), "Direccion"),
            "Direccion1"   = COALESCE(NULLIF(p_row_json->>'DIRECCION1', ''), "Direccion1"),
            "Sucursal"     = COALESCE(NULLIF(p_row_json->>'SUCURSAL', ''), "Sucursal"),
            "Telefono"     = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''), "Telefono"),
            "Fax"          = COALESCE(NULLIF(p_row_json->>'FAX', ''), "Fax"),
            "Contacto"     = COALESCE(NULLIF(p_row_json->>'CONTACTO', ''), "Contacto"),
            "VENDEDOR"     = COALESCE(NULLIF(p_row_json->>'VENDEDOR', ''), "VENDEDOR"),
            "ESTADO"       = COALESCE(NULLIF(p_row_json->>'ESTADO', ''), "ESTADO"),
            "Ciudad"       = COALESCE(NULLIF(p_row_json->>'CIUDAD', ''), "Ciudad"),
            "CodPostal"    = COALESCE(NULLIF(p_row_json->>'CPOSTAL', ''), "CodPostal"),
            "Email"        = COALESCE(NULLIF(p_row_json->>'EMAIL', ''), "Email"),
            "PaginaWww"    = COALESCE(NULLIF(p_row_json->>'PAGINA_WWW', ''), "PaginaWww"),
            "CodUsuario"   = COALESCE(NULLIF(p_row_json->>'COD_USUARIO', ''), "CodUsuario"),
            "CreditLimit"  = CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
                                  THEN "CreditLimit"
                                  ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
            "Credito"      = CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
                                  THEN "Credito"
                                  ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
            "ListaPrecio"  = CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
                                  THEN "ListaPrecio"
                                  ELSE (p_row_json->>'LISTA_PRECIO')::INT END,
            "Notas"        = COALESCE(NULLIF(p_row_json->>'NOTAS', ''), "Notas")
        WHERE "SupplierCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
CREATE OR REPLACE FUNCTION usp_proveedores_delete(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Supplier" WHERE "SupplierCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Supplier"
        SET "IsDeleted" = TRUE, "IsActive" = FALSE
        WHERE "SupplierCode" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
