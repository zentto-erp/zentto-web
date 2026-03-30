-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_vendedores.sql
-- CRUD de Vendedores. Tabla canonica: master."Seller"
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
-- RETURNS TABLE ampliado para compatibilidad con produccion (24 columnas + TotalCount)
-- Columnas legacy sin equivalente en master.Seller retornan NULL
DROP FUNCTION IF EXISTS usp_vendedores_list(VARCHAR, BOOLEAN, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_vendedores_list(
    p_search  VARCHAR  DEFAULT NULL,
    p_status  BOOLEAN  DEFAULT NULL,
    p_tipo    VARCHAR  DEFAULT NULL,
    p_page    INT      DEFAULT 1,
    p_limit   INT      DEFAULT 50
)
RETURNS TABLE(
    "Codigo"              character varying,
    "Nombre"              character varying,
    "Comision"            numeric,
    "Status"              boolean,
    "IsActive"            boolean,
    "IsDeleted"           boolean,
    "CompanyId"           integer,
    "SellerCode"          character varying,
    "SellerName"          character varying,
    "Commission"          numeric,
    "Direccion"           character varying,
    "Telefonos"           character varying,
    "Email"               character varying,
    "Tipo"                character varying,
    "Clave"               character varying,
    "RangoVentasUno"      numeric,
    "ComisionVentasUno"   numeric,
    "RangoVentasDos"      numeric,
    "ComisionVentasDos"   numeric,
    "RangoVentasTres"     numeric,
    "ComisionVentasTres"  numeric,
    "RangoVentasCuatro"   numeric,
    "ComisionVentasCuatro" numeric,
    "TotalCount"          bigint
)
LANGUAGE plpgsql AS $func$
DECLARE
    v_offset       INT;
    v_total        BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0  THEN v_offset := 0;   END IF;
    IF p_limit < 1   THEN p_limit := 50;   END IF;
    IF p_limit > 500 THEN p_limit := 500;  END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo);

    RETURN QUERY
    SELECT s."SellerCode"::VARCHAR,
           s."SellerName"::VARCHAR,
           s."Commission",
           s."IsActive",
           s."IsActive",
           s."IsDeleted",
           s."CompanyId",
           s."SellerCode"::VARCHAR,
           s."SellerName"::VARCHAR,
           s."Commission",
           s."Address"::VARCHAR,
           s."Phone"::VARCHAR,
           s."Email"::VARCHAR,
           s."SellerType"::VARCHAR,
           NULL::VARCHAR,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           NULL::numeric,
           v_total
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo)
    ORDER BY s."SellerCode"
    LIMIT p_limit OFFSET v_offset;
END;
$func$;

-- ---------- 2. Get by Codigo ----------
DROP FUNCTION IF EXISTS usp_vendedores_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_vendedores_getbycodigo(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "Codigo" VARCHAR,
    "Nombre" VARCHAR,
    "Comision" DOUBLE PRECISION,
    "Status" BOOLEAN,
    "IsActive" BOOLEAN,
    "IsDeleted" BOOLEAN,
    "CompanyId" INT,
    "SellerCode" VARCHAR,
    "SellerName" VARCHAR,
    "Commission" DOUBLE PRECISION,
    "Direccion" VARCHAR,
    "Telefonos" VARCHAR,
    "Email" VARCHAR,
    "Tipo" VARCHAR,
    "Clave" VARCHAR,
    "RangoVentasUno" DOUBLE PRECISION,
    "ComisionVentasUno" DOUBLE PRECISION,
    "RangoVentasDos" DOUBLE PRECISION,
    "ComisionVentasDos" DOUBLE PRECISION,
    "RangoVentasTres" DOUBLE PRECISION,
    "ComisionVentasTres" DOUBLE PRECISION,
    "RangoVentasCuatro" DOUBLE PRECISION,
    "ComisionVentasCuatro" DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SellerCode"  AS "Codigo",
        s."SellerName"  AS "Nombre",
        s."Commission"  AS "Comision",
        s."IsActive"    AS "Status",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SellerCode",
        s."SellerName",
        s."Commission",
        s."Direccion",
        s."Telefonos",
        s."Email",
        s."Tipo",
        s."Clave",
        s."RangoVentasUno",
        s."ComisionVentasUno",
        s."RangoVentasDos",
        s."ComisionVentasDos",
        s."RangoVentasTres",
        s."ComisionVentasTres",
        s."RangoVentasCuatro",
        s."ComisionVentasCuatro"
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_vendedores_insert(
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

    v_codigo := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);

    IF EXISTS (SELECT 1 FROM master."Seller" WHERE "SellerCode" = v_codigo AND "CompanyId" = v_company_id) THEN
        RETURN QUERY SELECT -1, 'Vendedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO master."Seller" (
            "SellerCode", "SellerName", "Commission",
            "Direccion", "Telefonos", "Email",
            "RangoVentasUno", "ComisionVentasUno",
            "RangoVentasDos", "ComisionVentasDos",
            "RangoVentasTres", "ComisionVentasTres",
            "RangoVentasCuatro", "ComisionVentasCuatro",
            "IsActive", "Tipo", "Clave", "IsDeleted", "CompanyId"
        )
        VALUES (
            v_codigo,
            NULLIF(p_row_json->>'Nombre', ''::VARCHAR),
            CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = '' THEN NULL
                 ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'Direccion', ''::VARCHAR),
            NULLIF(p_row_json->>'Telefonos', ''::VARCHAR),
            NULLIF(p_row_json->>'Email', ''::VARCHAR),
            CASE WHEN p_row_json->>'Rango_ventas_Uno' IS NULL OR p_row_json->>'Rango_ventas_Uno' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_Uno')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_Uno' IS NULL OR p_row_json->>'Comision_ventas_Uno' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_Uno')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_dos' IS NULL OR p_row_json->>'Rango_ventas_dos' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_dos')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_dos' IS NULL OR p_row_json->>'Comision_ventas_dos' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_dos')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_tres' IS NULL OR p_row_json->>'Rango_ventas_tres' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_tres')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_tres' IS NULL OR p_row_json->>'Comision_ventas_tres' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_tres')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_Cuatro' IS NULL OR p_row_json->>'Rango_ventas_Cuatro' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_Cuatro')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_Cuatro' IS NULL OR p_row_json->>'Comision_ventas_Cuatro' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_Cuatro')::DOUBLE PRECISION END,
            COALESCE((p_row_json->>'Status')::BOOLEAN, TRUE),
            NULLIF(p_row_json->>'Tipo', ''::VARCHAR),
            NULLIF(p_row_json->>'clave', ''::VARCHAR),
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
CREATE OR REPLACE FUNCTION usp_vendedores_update(
    p_codigo VARCHAR(10),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Seller" WHERE "SellerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Seller"
        SET
            "SellerName" = COALESCE(NULLIF(p_row_json->>'Nombre', ''::VARCHAR), "SellerName"),
            "Commission" = CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = ''
                                THEN "Commission"
                                ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            "Direccion"  = COALESCE(NULLIF(p_row_json->>'Direccion', ''::VARCHAR), "Direccion"),
            "Telefonos"  = COALESCE(NULLIF(p_row_json->>'Telefonos', ''::VARCHAR), "Telefonos"),
            "Email"      = COALESCE(NULLIF(p_row_json->>'Email', ''::VARCHAR), "Email"),
            "IsActive"   = COALESCE((p_row_json->>'Status')::BOOLEAN, "IsActive"),
            "Tipo"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::VARCHAR), "Tipo"),
            "Clave"      = COALESCE(NULLIF(p_row_json->>'clave', ''::VARCHAR), "Clave")
        WHERE "SellerCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
CREATE OR REPLACE FUNCTION usp_vendedores_delete(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Seller" WHERE "SellerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Seller"
        SET "IsDeleted" = TRUE, "IsActive" = FALSE
        WHERE "SellerCode" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
