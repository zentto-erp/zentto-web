-- usp_bancos_delete
DROP FUNCTION IF EXISTS public.usp_bancos_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bancos_delete(p_nombre character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM dbo."Bancos" WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_bancos_getbynombre
DROP FUNCTION IF EXISTS public.usp_bancos_getbynombre(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bancos_getbynombre(p_nombre character varying)
 RETURNS TABLE("Nombre" character varying, "Contacto" character varying, "Direccion" character varying, "Telefonos" character varying, "Co_Usuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT b."Nombre", b."Contacto", b."Direccion", b."Telefonos", b."Co_Usuario"
    FROM dbo."Bancos" b
    WHERE b."Nombre" = p_nombre;
END;
$function$
;

-- usp_bancos_insert
DROP FUNCTION IF EXISTS public.usp_bancos_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bancos_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nombre VARCHAR(50);
BEGIN
    v_nombre := NULLIF(p_row_json->>'Nombre', ''::character varying);

    IF EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = v_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO dbo."Bancos" ("Nombre", "Contacto", "Direccion", "Telefonos", "Co_Usuario")
        VALUES (
            v_nombre,
            NULLIF(p_row_json->>'Contacto', ''::character varying),
            NULLIF(p_row_json->>'Direccion', ''::character varying),
            NULLIF(p_row_json->>'Telefonos', ''::character varying),
            NULLIF(p_row_json->>'Co_Usuario', ''::character varying)
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_bancos_list
DROP FUNCTION IF EXISTS public.usp_bancos_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bancos_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Nombre" character varying, "Contacto" character varying, "Direccion" character varying, "Telefonos" character varying, "Co_Usuario" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset   INT;
    v_limit    INT;
    v_search   VARCHAR(100);
    v_total    BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    ELSE
        v_search := NULL;
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM dbo."Bancos" b
    WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search);

    RETURN QUERY
    SELECT
        b."Nombre",
        b."Contacto",
        b."Direccion",
        b."Telefonos",
        b."Co_Usuario",
        v_total
    FROM dbo."Bancos" b
    WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search)
    ORDER BY b."Nombre"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_bancos_update
DROP FUNCTION IF EXISTS public.usp_bancos_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bancos_update(p_nombre character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE dbo."Bancos"
        SET "Contacto"   = COALESCE(NULLIF(p_row_json->>'Contacto', ''::character varying), "Contacto")::character varying,
            "Direccion"  = COALESCE(NULLIF(p_row_json->>'Direccion', ''::character varying), "Direccion")::character varying,
            "Telefonos"  = COALESCE(NULLIF(p_row_json->>'Telefonos', ''::character varying), "Telefonos")::character varying,
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''::character varying), "Co_Usuario")::character varying
        WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_categorias_delete
DROP FUNCTION IF EXISTS public.usp_categorias_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_categorias_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Categoria" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Categoria" WHERE "Codigo" = p_codigo;
        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_categorias_getbycodigo
DROP FUNCTION IF EXISTS public.usp_categorias_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_categorias_getbycodigo(p_codigo integer)
 RETURNS TABLE("Codigo" integer, "Nombre" character varying, "Co_Usuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."Codigo", c."Nombre", c."Co_Usuario"
    FROM public."Categoria" c
    WHERE c."Codigo" = p_codigo;
END;
$function$
;

-- usp_categorias_insert
DROP FUNCTION IF EXISTS public.usp_categorias_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_categorias_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nuevo_codigo INT;
BEGIN
    BEGIN
        INSERT INTO public."Categoria" ("Nombre", "Co_Usuario")
        VALUES (
            NULLIF(p_row_json->>'Nombre', ''::character varying),
            NULLIF(p_row_json->>'Co_Usuario', ''::character varying)
        )
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR, 0;
    END;
END;
$function$
;

-- usp_categorias_list
DROP FUNCTION IF EXISTS public.usp_categorias_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_categorias_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "Codigo" integer, "Nombre" character varying, "Co_Usuario" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Categoria"
    WHERE (v_search IS NULL OR
           "Nombre"::TEXT LIKE v_search OR "Codigo"::TEXT LIKE v_search);

    RETURN QUERY
    SELECT
        v_total,
        c."Codigo",
        c."Nombre",
        c."Co_Usuario"
    FROM public."Categoria" c
    WHERE (v_search IS NULL OR
           c."Nombre"::TEXT LIKE v_search OR c."Codigo"::TEXT LIKE v_search)
    ORDER BY c."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_categorias_update
DROP FUNCTION IF EXISTS public.usp_categorias_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_categorias_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Categoria" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Categoria" SET
            "Nombre"     = COALESCE(NULLIF(p_row_json->>'Nombre', ''::character varying), "Nombre")::character varying,
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''::character varying), "Co_Usuario")::character varying
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_centrocosto_delete
DROP FUNCTION IF EXISTS public.usp_centrocosto_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Centro_Costo" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_centrocosto_getbycodigo
DROP FUNCTION IF EXISTS public.usp_centrocosto_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_getbycodigo(p_codigo character varying)
 RETURNS TABLE("Codigo" character varying, "Descripcion" character varying, "Presupuestado" character varying, "Saldo_Real" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        cc."Codigo",
        cc."Descripcion",
        cc."Presupuestado",
        cc."Saldo_Real"
    FROM public."Centro_Costo" cc
    WHERE cc."Codigo" = p_codigo;
END;
$function$
;

-- usp_centrocosto_insert
DROP FUNCTION IF EXISTS public.usp_centrocosto_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_codigo        VARCHAR(50);
    v_descripcion   VARCHAR(100);
    v_presupuestado VARCHAR(50);
    v_saldo_real    VARCHAR(50);
BEGIN
    v_codigo        := NULLIF(p_row_json->>'Codigo', ''::character varying);
    v_descripcion   := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', ''::character varying);
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', ''::character varying);

    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = v_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Centro_Costo" (
        "Codigo", "Descripcion", "Presupuestado", "Saldo_Real"
    )
    VALUES (v_codigo, v_descripcion, v_presupuestado, v_saldo_real);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_centrocosto_list
DROP FUNCTION IF EXISTS public.usp_centrocosto_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" character varying, "Descripcion" character varying, "Presupuestado" character varying, "Saldo_Real" character varying, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
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
    FROM public."Centro_Costo" cc
    WHERE v_search IS NULL
       OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        cc."Codigo",
        cc."Descripcion",
        cc."Presupuestado",
        cc."Saldo_Real",
        v_total AS "TotalCount"
    FROM public."Centro_Costo" cc
    WHERE v_search IS NULL
       OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search)
    ORDER BY cc."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_centrocosto_update
DROP FUNCTION IF EXISTS public.usp_centrocosto_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion   VARCHAR(100);
    v_presupuestado VARCHAR(50);
    v_saldo_real    VARCHAR(50);
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion   := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', ''::character varying);
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', ''::character varying);

    UPDATE public."Centro_Costo" SET
        "Descripcion"   = COALESCE(v_descripcion, "Descripcion"),
        "Presupuestado" = COALESCE(v_presupuestado, "Presupuestado"),
        "Saldo_Real"    = COALESCE(v_saldo_real, "Saldo_Real")
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_clases_delete
DROP FUNCTION IF EXISTS public.usp_clases_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clases_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Clases" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Clases" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase eliminada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_clases_getbycodigo
DROP FUNCTION IF EXISTS public.usp_clases_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clases_getbycodigo(p_codigo integer)
 RETURNS TABLE("Codigo" integer, "Descripcion" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        cl."Codigo",
        cl."Descripcion"
    FROM public."Clases" cl
    WHERE cl."Codigo" = p_codigo;
END;
$function$
;

-- usp_clases_insert
DROP FUNCTION IF EXISTS public.usp_clases_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clases_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion VARCHAR(25);
    v_new_id      INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::character varying);

    INSERT INTO public."Clases" ("Descripcion")
    VALUES (v_descripcion)
    RETURNING "Codigo" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Clase creada exitosamente'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$function$
;

-- usp_clases_list
DROP FUNCTION IF EXISTS public.usp_clases_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clases_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" integer, "Descripcion" character varying, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
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
    FROM public."Clases" cl
    WHERE v_search IS NULL
       OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        cl."Codigo",
        cl."Descripcion",
        v_total AS "TotalCount"
    FROM public."Clases" cl
    WHERE v_search IS NULL
       OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search)
    ORDER BY cl."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_clases_update
DROP FUNCTION IF EXISTS public.usp_clases_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clases_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion VARCHAR(25);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Clases" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::character varying);

    UPDATE public."Clases"
    SET "Descripcion" = v_descripcion
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase actualizada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_clientes_delete
DROP FUNCTION IF EXISTS public.usp_clientes_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_clientes_getbycodigo
DROP FUNCTION IF EXISTS public.usp_clientes_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_getbycodigo(p_codigo character varying)
 RETURNS TABLE("CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "SALDO_TOT" double precision, "LIMITE" double precision, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "CustomerCode" character varying, "CustomerName" character varying, "FiscalId" character varying, "TotalBalance" double precision, "CreditLimit" double precision, "NIT" character varying, "Direccion" character varying, "Telefono" character varying, "Contacto" character varying, "SalespersonCode" character varying, "PriceListCode" character varying, "Ciudad" character varying, "CodPostal" character varying, "Email" character varying, "PaginaWww" character varying, "CodUsuario" character varying, "Credito" double precision)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_clientes_insert
DROP FUNCTION IF EXISTS public.usp_clientes_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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

    v_codigo := NULLIF(p_row_json->>'CODIGO', ''::character varying);

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
        NULLIF(p_row_json->>'NOMBRE', ''::character varying),
        NULLIF(p_row_json->>'RIF', ''::character varying),
        NULLIF(p_row_json->>'NIT', ''::character varying),
        NULLIF(p_row_json->>'DIRECCION', ''::character varying),
        NULLIF(p_row_json->>'DIRECCION1', ''::character varying),
        NULLIF(p_row_json->>'SUCURSAL', ''::character varying),
        NULLIF(p_row_json->>'TELEFONO', ''::character varying),
        NULLIF(p_row_json->>'CONTACTO', ''::character varying),
        NULLIF(p_row_json->>'VENDEDOR', ''::character varying),
        NULLIF(p_row_json->>'ESTADO', ''::character varying),
        NULLIF(p_row_json->>'CIUDAD', ''::character varying),
        NULLIF(p_row_json->>'CPOSTAL', ''::character varying),
        NULLIF(p_row_json->>'EMAIL', ''::character varying),
        NULLIF(p_row_json->>'PAGINA_WWW', ''::character varying),
        NULLIF(p_row_json->>'COD_USUARIO', ''::character varying),
        CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
             THEN NULL
             ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
        CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
             THEN NULL
             ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
        CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
             THEN NULL
             ELSE NULLIF(p_row_json->>'LISTA_PRECIO', ''::character varying) END,
        TRUE,   -- IsActive
        FALSE,  -- IsDeleted
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_clientes_list
DROP FUNCTION IF EXISTS public.usp_clientes_list(character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_list(p_search character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_vendedor character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "SALDO_TOT" double precision, "LIMITE" double precision, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "CustomerCode" character varying, "CustomerName" character varying, "FiscalId" character varying, "TotalBalance" double precision, "CreditLimit" double precision, "NIT" character varying, "Direccion" character varying, "Telefono" character varying, "Contacto" character varying, "SalespersonCode" character varying, "PriceListCode" character varying, "Ciudad" character varying, "CodPostal" character varying, "Email" character varying, "PaginaWww" character varying, "CodUsuario" character varying, "Credito" double precision, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_clientes_update
DROP FUNCTION IF EXISTS public.usp_clientes_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
        "CustomerName"    = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''::character varying), "CustomerName")::character varying,
        "FiscalId"        = COALESCE(NULLIF(p_row_json->>'RIF', ''::character varying), "FiscalId")::character varying,
        "NIT"             = COALESCE(NULLIF(p_row_json->>'NIT', ''::character varying), "NIT")::character varying,
        "Direccion"       = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''::character varying), "Direccion")::character varying,
        "Direccion1"      = COALESCE(NULLIF(p_row_json->>'DIRECCION1', ''::character varying), "Direccion1")::character varying,
        "Sucursal"        = COALESCE(NULLIF(p_row_json->>'SUCURSAL', ''::character varying), "Sucursal")::character varying,
        "Telefono"        = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''::character varying), "Telefono")::character varying,
        "Contacto"        = COALESCE(NULLIF(p_row_json->>'CONTACTO', ''::character varying), "Contacto")::character varying,
        "SalespersonCode" = COALESCE(NULLIF(p_row_json->>'VENDEDOR', ''::character varying), "SalespersonCode")::character varying,
        "ESTADO"          = COALESCE(NULLIF(p_row_json->>'ESTADO', ''::character varying), "ESTADO")::character varying,
        "Ciudad"          = COALESCE(NULLIF(p_row_json->>'CIUDAD', ''::character varying), "Ciudad")::character varying,
        "CodPostal"       = COALESCE(NULLIF(p_row_json->>'CPOSTAL', ''::character varying), "CodPostal")::character varying,
        "Email"           = COALESCE(NULLIF(p_row_json->>'EMAIL', ''::character varying), "Email")::character varying,
        "PaginaWww"       = COALESCE(NULLIF(p_row_json->>'PAGINA_WWW', ''::character varying), "PaginaWww")::character varying,
        "CodUsuario"      = COALESCE(NULLIF(p_row_json->>'COD_USUARIO', ''::character varying), "CodUsuario")::character varying,
        "CreditLimit"     = CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
                                 THEN "CreditLimit"
                                 ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
        "Credito"         = CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
                                 THEN "Credito"
                                 ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
        "PriceListCode"   = CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
                                 THEN "PriceListCode"
                                 ELSE NULLIF(p_row_json->>'LISTA_PRECIO', ''::character varying) END
    WHERE "CustomerCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_grupos_delete
DROP FUNCTION IF EXISTS public.usp_grupos_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_grupos_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Grupos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Grupos" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo eliminado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_grupos_getbycodigo
DROP FUNCTION IF EXISTS public.usp_grupos_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_grupos_getbycodigo(p_codigo integer)
 RETURNS TABLE("Codigo" integer, "Descripcion" character varying, "Co_Usuario" character varying, "Porcentaje" double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        g."Codigo",
        g."Descripcion",
        g."Co_Usuario",
        g."Porcentaje"
    FROM public."Grupos" g
    WHERE g."Codigo" = p_codigo;
END;
$function$
;

-- usp_grupos_insert
DROP FUNCTION IF EXISTS public.usp_grupos_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_grupos_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion  VARCHAR(50);
    v_co_usuario   VARCHAR(10);
    v_porcentaje_str VARCHAR(50);
    v_porcentaje   DOUBLE PRECISION;
    v_nuevo_codigo INT;
BEGIN
    v_descripcion    := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_co_usuario     := NULLIF(p_row_json->>'Co_Usuario', ''::character varying);
    v_porcentaje_str := NULLIF(p_row_json->>'Porcentaje', ''::character varying);
    v_porcentaje     := CASE
                            WHEN v_porcentaje_str IS NOT NULL AND v_porcentaje_str ~ '^\d+(\.\d+)?$'
                            THEN v_porcentaje_str::DOUBLE PRECISION
                            ELSE 0
                        END;

    INSERT INTO public."Grupos" ("Descripcion", "Co_Usuario", "Porcentaje")
    VALUES (v_descripcion, v_co_usuario, v_porcentaje)
    RETURNING "Codigo" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'Grupo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$function$
;

-- usp_grupos_list
DROP FUNCTION IF EXISTS public.usp_grupos_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_grupos_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "Codigo" integer, "Descripcion" character varying, "Co_Usuario" character varying, "Porcentaje" double precision)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_total   INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Grupos" g
    WHERE (p_search IS NULL
           OR g."Codigo"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."Descripcion" LIKE '%' || p_search || '%');

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        g."Codigo",
        g."Descripcion",
        g."Co_Usuario",
        g."Porcentaje"
    FROM public."Grupos" g
    WHERE (p_search IS NULL
           OR g."Codigo"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."Descripcion" LIKE '%' || p_search || '%')
    ORDER BY g."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_grupos_update
DROP FUNCTION IF EXISTS public.usp_grupos_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_grupos_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion  VARCHAR(50);
    v_co_usuario   VARCHAR(10);
    v_porcentaje_str VARCHAR(50);
    v_porcentaje   DOUBLE PRECISION;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Grupos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion    := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_co_usuario     := NULLIF(p_row_json->>'Co_Usuario', ''::character varying);
    v_porcentaje_str := NULLIF(p_row_json->>'Porcentaje', ''::character varying);
    v_porcentaje     := CASE
                            WHEN v_porcentaje_str IS NOT NULL AND v_porcentaje_str ~ '^\d+(\.\d+)?$'
                            THEN v_porcentaje_str::DOUBLE PRECISION
                            ELSE 0
                        END;

    UPDATE public."Grupos" SET
        "Descripcion" = v_descripcion,
        "Co_Usuario"  = v_co_usuario,
        "Porcentaje"  = v_porcentaje
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo actualizado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_lineas_delete
DROP FUNCTION IF EXISTS public.usp_lineas_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_lineas_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Lineas" WHERE "CODIGO" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Lineas" WHERE "CODIGO" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea eliminada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_lineas_getbycodigo
DROP FUNCTION IF EXISTS public.usp_lineas_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_lineas_getbycodigo(p_codigo integer)
 RETURNS TABLE("CODIGO" integer, "DESCRIPCION" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT l."CODIGO", l."DESCRIPCION"
    FROM public."Lineas" l
    WHERE l."CODIGO" = p_codigo;
END;
$function$
;

-- usp_lineas_insert
DROP FUNCTION IF EXISTS public.usp_lineas_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_lineas_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion VARCHAR(50);
    v_nuevo_codigo INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', ''::character varying);

    BEGIN
        INSERT INTO public."Lineas" ("DESCRIPCION")
        VALUES (v_descripcion)
        RETURNING "CODIGO" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Linea creada exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$function$
;

-- usp_lineas_list
DROP FUNCTION IF EXISTS public.usp_lineas_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_lineas_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("CODIGO" integer, "DESCRIPCION" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Lineas"
    WHERE (p_search IS NULL
           OR CAST("CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR "DESCRIPCION" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        l."CODIGO",
        l."DESCRIPCION",
        v_total AS "TotalCount"
    FROM public."Lineas" l
    WHERE (p_search IS NULL
           OR CAST(l."CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR l."DESCRIPCION" LIKE '%' || p_search || '%')
    ORDER BY l."CODIGO"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_lineas_update
DROP FUNCTION IF EXISTS public.usp_lineas_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_lineas_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_descripcion VARCHAR(50);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Lineas" WHERE "CODIGO" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', ''::character varying);

    BEGIN
        UPDATE public."Lineas"
        SET "DESCRIPCION" = v_descripcion
        WHERE "CODIGO" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea actualizada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_marcas_delete
DROP FUNCTION IF EXISTS public.usp_marcas_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_marcas_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Marcas" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Marcas" WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_marcas_getbycodigo
DROP FUNCTION IF EXISTS public.usp_marcas_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_marcas_getbycodigo(p_codigo integer)
 RETURNS TABLE("Codigo" integer, "Descripcion" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."Codigo", m."Descripcion"
    FROM public."Marcas" m
    WHERE m."Codigo" = p_codigo;
END;
$function$
;

-- usp_marcas_insert
DROP FUNCTION IF EXISTS public.usp_marcas_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_marcas_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nuevo_codigo INT;
BEGIN
    BEGIN
        INSERT INTO public."Marcas" ("Descripcion")
        VALUES (NULLIF(p_row_json->>'Descripcion', ''::character varying))
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
    END;
END;
$function$
;

-- usp_marcas_list
DROP FUNCTION IF EXISTS public.usp_marcas_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_marcas_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" integer, "Descripcion" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
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
    FROM public."Marcas" m
    WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param);

    RETURN QUERY
    SELECT
        m."Codigo",
        m."Descripcion",
        v_total AS "TotalCount"
    FROM public."Marcas" m
    WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param)
    ORDER BY m."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_marcas_update
DROP FUNCTION IF EXISTS public.usp_marcas_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_marcas_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Marcas" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Marcas"
        SET "Descripcion" = COALESCE(NULLIF(p_row_json->>'Descripcion', ''::character varying), "Descripcion")::character varying
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_proveedores_delete
DROP FUNCTION IF EXISTS public.usp_proveedores_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_proveedores_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_proveedores_getbycodigo
DROP FUNCTION IF EXISTS public.usp_proveedores_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_proveedores_getbycodigo(p_codigo character varying)
 RETURNS TABLE("CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "SALDO_TOT" double precision, "LIMITE" double precision, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "TotalBalance" double precision, "CreditLimit" double precision, "NIT" character varying, "Direccion" character varying, "Direccion1" character varying, "Sucursal" character varying, "Telefono" character varying, "Fax" character varying, "Contacto" character varying, "VENDEDOR" character varying, "ESTADO" character varying, "Ciudad" character varying, "CodPostal" character varying, "Email" character varying, "PaginaWww" character varying, "CodUsuario" character varying, "Credito" double precision, "ListaPrecio" integer, "Notas" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_proveedores_insert
DROP FUNCTION IF EXISTS public.usp_proveedores_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_proveedores_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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

    v_codigo := NULLIF(p_row_json->>'CODIGO', ''::character varying);

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
            NULLIF(p_row_json->>'NOMBRE', ''::character varying),
            NULLIF(p_row_json->>'RIF', ''::character varying),
            NULLIF(p_row_json->>'NIT', ''::character varying),
            NULLIF(p_row_json->>'DIRECCION', ''::character varying),
            NULLIF(p_row_json->>'DIRECCION1', ''::character varying),
            NULLIF(p_row_json->>'SUCURSAL', ''::character varying),
            NULLIF(p_row_json->>'TELEFONO', ''::character varying),
            NULLIF(p_row_json->>'FAX', ''::character varying),
            NULLIF(p_row_json->>'CONTACTO', ''::character varying),
            NULLIF(p_row_json->>'VENDEDOR', ''::character varying),
            NULLIF(p_row_json->>'ESTADO', ''::character varying),
            NULLIF(p_row_json->>'CIUDAD', ''::character varying),
            NULLIF(p_row_json->>'CPOSTAL', ''::character varying),
            NULLIF(p_row_json->>'EMAIL', ''::character varying),
            NULLIF(p_row_json->>'PAGINA_WWW', ''::character varying),
            NULLIF(p_row_json->>'COD_USUARIO', ''::character varying),
            CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = '' THEN NULL
                 ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = '' THEN NULL
                 ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = '' THEN 0
                 ELSE (p_row_json->>'LISTA_PRECIO')::INT END,
            NULLIF(p_row_json->>'NOTAS', ''::character varying),
            TRUE,   -- IsActive
            FALSE,  -- IsDeleted
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_proveedores_list
DROP FUNCTION IF EXISTS public.usp_proveedores_list(character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_proveedores_list(p_search character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_vendedor character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "SALDO_TOT" double precision, "LIMITE" double precision, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "TotalBalance" double precision, "CreditLimit" double precision, "NIT" character varying, "Direccion" character varying, "Direccion1" character varying, "Sucursal" character varying, "Telefono" character varying, "Fax" character varying, "Contacto" character varying, "VENDEDOR" character varying, "ESTADO" character varying, "Ciudad" character varying, "CodPostal" character varying, "Email" character varying, "PaginaWww" character varying, "CodUsuario" character varying, "Credito" double precision, "ListaPrecio" integer, "Notas" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_proveedores_update
DROP FUNCTION IF EXISTS public.usp_proveedores_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_proveedores_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Supplier" WHERE "SupplierCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Supplier"
        SET
            "SupplierName" = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''::character varying), "SupplierName")::character varying,
            "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''::character varying), "FiscalId")::character varying,
            "NIT"          = COALESCE(NULLIF(p_row_json->>'NIT', ''::character varying), "NIT")::character varying,
            "Direccion"    = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''::character varying), "Direccion")::character varying,
            "Direccion1"   = COALESCE(NULLIF(p_row_json->>'DIRECCION1', ''::character varying), "Direccion1")::character varying,
            "Sucursal"     = COALESCE(NULLIF(p_row_json->>'SUCURSAL', ''::character varying), "Sucursal")::character varying,
            "Telefono"     = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''::character varying), "Telefono")::character varying,
            "Fax"          = COALESCE(NULLIF(p_row_json->>'FAX', ''::character varying), "Fax")::character varying,
            "Contacto"     = COALESCE(NULLIF(p_row_json->>'CONTACTO', ''::character varying), "Contacto")::character varying,
            "VENDEDOR"     = COALESCE(NULLIF(p_row_json->>'VENDEDOR', ''::character varying), "VENDEDOR")::character varying,
            "ESTADO"       = COALESCE(NULLIF(p_row_json->>'ESTADO', ''::character varying), "ESTADO")::character varying,
            "Ciudad"       = COALESCE(NULLIF(p_row_json->>'CIUDAD', ''::character varying), "Ciudad")::character varying,
            "CodPostal"    = COALESCE(NULLIF(p_row_json->>'CPOSTAL', ''::character varying), "CodPostal")::character varying,
            "Email"        = COALESCE(NULLIF(p_row_json->>'EMAIL', ''::character varying), "Email")::character varying,
            "PaginaWww"    = COALESCE(NULLIF(p_row_json->>'PAGINA_WWW', ''::character varying), "PaginaWww")::character varying,
            "CodUsuario"   = COALESCE(NULLIF(p_row_json->>'COD_USUARIO', ''::character varying), "CodUsuario")::character varying,
            "CreditLimit"  = CASE WHEN p_row_json->>'LIMITE' IS NULL OR p_row_json->>'LIMITE' = ''
                                  THEN "CreditLimit"
                                  ELSE (p_row_json->>'LIMITE')::DOUBLE PRECISION END,
            "Credito"      = CASE WHEN p_row_json->>'CREDITO' IS NULL OR p_row_json->>'CREDITO' = ''
                                  THEN "Credito"
                                  ELSE (p_row_json->>'CREDITO')::DOUBLE PRECISION END,
            "ListaPrecio"  = CASE WHEN p_row_json->>'LISTA_PRECIO' IS NULL OR p_row_json->>'LISTA_PRECIO' = ''
                                  THEN "ListaPrecio"
                                  ELSE (p_row_json->>'LISTA_PRECIO')::INT END,
            "Notas"        = COALESCE(NULLIF(p_row_json->>'NOTAS', ''::character varying), "Notas")::character varying
        WHERE "SupplierCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_tipos_delete
DROP FUNCTION IF EXISTS public.usp_tipos_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tipos_delete(p_codigo integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Tipos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Tipos" WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo eliminado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_tipos_getbycodigo
DROP FUNCTION IF EXISTS public.usp_tipos_getbycodigo(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tipos_getbycodigo(p_codigo integer)
 RETURNS TABLE("Codigo" integer, "Nombre" character varying, "Categoria" character varying, "Co_Usuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t."Codigo", t."Nombre", t."Categoria", t."Co_Usuario"
    FROM public."Tipos" t
    WHERE t."Codigo" = p_codigo;
END;
$function$
;

-- usp_tipos_insert
DROP FUNCTION IF EXISTS public.usp_tipos_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tipos_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoCodigo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nombre VARCHAR(50);
    v_categoria VARCHAR(50);
    v_co_usuario VARCHAR(10);
    v_nuevo_codigo INT;
BEGIN
    v_nombre     := NULLIF(p_row_json->>'Nombre', ''::character varying);
    v_categoria  := NULLIF(p_row_json->>'Categoria', ''::character varying);
    v_co_usuario := NULLIF(p_row_json->>'Co_Usuario', ''::character varying);

    BEGIN
        INSERT INTO public."Tipos" ("Nombre", "Categoria", "Co_Usuario")
        VALUES (v_nombre, v_categoria, v_co_usuario)
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Tipo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$function$
;

-- usp_tipos_list
DROP FUNCTION IF EXISTS public.usp_tipos_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tipos_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" integer, "Nombre" character varying, "Categoria" character varying, "Co_Usuario" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Tipos"
    WHERE (p_search IS NULL
           OR CAST("Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR "Nombre" LIKE '%' || p_search || '%'
           OR "Categoria" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        t."Codigo",
        t."Nombre",
        t."Categoria",
        t."Co_Usuario",
        v_total AS "TotalCount"
    FROM public."Tipos" t
    WHERE (p_search IS NULL
           OR CAST(t."Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR t."Nombre" LIKE '%' || p_search || '%'
           OR t."Categoria" LIKE '%' || p_search || '%')
    ORDER BY t."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_tipos_update
DROP FUNCTION IF EXISTS public.usp_tipos_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tipos_update(p_codigo integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nombre VARCHAR(50);
    v_categoria VARCHAR(50);
    v_co_usuario VARCHAR(10);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Tipos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre     := NULLIF(p_row_json->>'Nombre', ''::character varying);
    v_categoria  := NULLIF(p_row_json->>'Categoria', ''::character varying);
    v_co_usuario := NULLIF(p_row_json->>'Co_Usuario', ''::character varying);

    BEGIN
        UPDATE public."Tipos"
        SET "Nombre" = v_nombre,
            "Categoria" = v_categoria,
            "Co_Usuario" = v_co_usuario
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo actualizado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_unidades_delete
DROP FUNCTION IF EXISTS public.usp_unidades_delete(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_unidades_delete(p_id integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Unidades" WHERE "Id" = p_id) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Unidades" WHERE "Id" = p_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_unidades_getbyid
DROP FUNCTION IF EXISTS public.usp_unidades_getbyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_unidades_getbyid(p_id integer)
 RETURNS TABLE("Id" integer, "Unidad" character varying, "Cantidad" double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."Id", u."Unidad", u."Cantidad"
    FROM public."Unidades" u
    WHERE u."Id" = p_id;
END;
$function$
;

-- usp_unidades_insert
DROP FUNCTION IF EXISTS public.usp_unidades_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_unidades_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NuevoId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nuevo_id INT;
BEGIN
    BEGIN
        INSERT INTO public."Unidades" ("Unidad", "Cantidad")
        VALUES (
            NULLIF(p_row_json->>'Unidad', ''::character varying),
            CASE WHEN p_row_json->>'Cantidad' IS NULL OR p_row_json->>'Cantidad' = '' THEN NULL
                 ELSE (p_row_json->>'Cantidad')::DOUBLE PRECISION END
        )
        RETURNING "Id" INTO v_nuevo_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
    END;
END;
$function$
;

-- usp_unidades_list
DROP FUNCTION IF EXISTS public.usp_unidades_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_unidades_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Id" integer, "Unidad" character varying, "Cantidad" double precision, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
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
    FROM public."Unidades" u
    WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param);

    RETURN QUERY
    SELECT
        u."Id",
        u."Unidad",
        u."Cantidad",
        v_total AS "TotalCount"
    FROM public."Unidades" u
    WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param)
    ORDER BY u."Id"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_unidades_update
DROP FUNCTION IF EXISTS public.usp_unidades_update(integer, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_unidades_update(p_id integer, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Unidades" WHERE "Id" = p_id) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Unidades"
        SET
            "Unidad"   = COALESCE(NULLIF(p_row_json->>'Unidad', ''::character varying), "Unidad")::character varying,
            "Cantidad" = CASE WHEN p_row_json->>'Cantidad' IS NULL OR p_row_json->>'Cantidad' = ''
                              THEN "Cantidad"
                              ELSE (p_row_json->>'Cantidad')::DOUBLE PRECISION END
        WHERE "Id" = p_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_vehiculos_delete
DROP FUNCTION IF EXISTS public.usp_vehiculos_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vehiculos_delete(p_placa character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = p_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Vehiculos" WHERE "Placa" = p_placa;
        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_vehiculos_getbyplaca
DROP FUNCTION IF EXISTS public.usp_vehiculos_getbyplaca(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vehiculos_getbyplaca(p_placa character varying)
 RETURNS TABLE("Placa" character varying, "Cedula" character varying, "Marca" character varying, "Anio" character varying, "Cauchos" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT v."Placa", v."Cedula", v."Marca", v."Anio", v."Cauchos"
    FROM public."Vehiculos" v
    WHERE v."Placa" = p_placa;
END;
$function$
;

-- usp_vehiculos_insert
DROP FUNCTION IF EXISTS public.usp_vehiculos_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vehiculos_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_placa VARCHAR(20);
BEGIN
    v_placa := NULLIF(p_row_json->>'Placa', ''::character varying);

    IF EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = v_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        INSERT INTO public."Vehiculos" ("Placa", "Cedula", "Marca", "Anio", "Cauchos")
        VALUES (
            v_placa,
            NULLIF(p_row_json->>'Cedula', ''::character varying),
            NULLIF(p_row_json->>'Marca', ''::character varying),
            NULLIF(p_row_json->>'Anio', ''::character varying),
            NULLIF(p_row_json->>'Cauchos', ''::character varying)
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_vehiculos_list
DROP FUNCTION IF EXISTS public.usp_vehiculos_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vehiculos_list(p_search character varying DEFAULT NULL::character varying, p_cedula character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "Placa" character varying, "Cedula" character varying, "Marca" character varying, "Anio" character varying, "Cauchos" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Vehiculos"
    WHERE (v_search IS NULL OR "Placa" LIKE v_search OR "Marca" LIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR "Cedula" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        v."Placa",
        v."Cedula",
        v."Marca",
        v."Anio",
        v."Cauchos"
    FROM public."Vehiculos" v
    WHERE (v_search IS NULL OR v."Placa" LIKE v_search OR v."Marca" LIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR v."Cedula" = p_cedula)
    ORDER BY v."Placa"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_vehiculos_update
DROP FUNCTION IF EXISTS public.usp_vehiculos_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vehiculos_update(p_placa character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = p_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Vehiculos" SET
            "Cedula"  = COALESCE(NULLIF(p_row_json->>'Cedula', ''::character varying), "Cedula")::character varying,
            "Marca"   = COALESCE(NULLIF(p_row_json->>'Marca', ''::character varying), "Marca")::character varying,
            "Anio"    = COALESCE(NULLIF(p_row_json->>'Anio', ''::character varying), "Anio")::character varying,
            "Cauchos" = COALESCE(NULLIF(p_row_json->>'Cauchos', ''::character varying), "Cauchos")::character varying
        WHERE "Placa" = p_placa;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_vendedores_delete
DROP FUNCTION IF EXISTS public.usp_vendedores_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_vendedores_getbycodigo
DROP FUNCTION IF EXISTS public.usp_vendedores_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_getbycodigo(p_codigo character varying)
 RETURNS TABLE("Codigo" character varying, "Nombre" character varying, "Comision" double precision, "Status" boolean, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "SellerCode" character varying, "SellerName" character varying, "Commission" double precision, "Direccion" character varying, "Telefonos" character varying, "Email" character varying, "Tipo" character varying, "Clave" character varying, "RangoVentasUno" double precision, "ComisionVentasUno" double precision, "RangoVentasDos" double precision, "ComisionVentasDos" double precision, "RangoVentasTres" double precision, "ComisionVentasTres" double precision, "RangoVentasCuatro" double precision, "ComisionVentasCuatro" double precision)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_vendedores_insert
DROP FUNCTION IF EXISTS public.usp_vendedores_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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

    v_codigo := NULLIF(p_row_json->>'Codigo', ''::character varying);

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
            NULLIF(p_row_json->>'Nombre', ''::character varying),
            CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = '' THEN NULL
                 ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'Direccion', ''::character varying),
            NULLIF(p_row_json->>'Telefonos', ''::character varying),
            NULLIF(p_row_json->>'Email', ''::character varying),
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
            NULLIF(p_row_json->>'Tipo', ''::character varying),
            NULLIF(p_row_json->>'clave', ''::character varying),
            FALSE,  -- IsDeleted
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_vendedores_list
DROP FUNCTION IF EXISTS public.usp_vendedores_list(character varying, boolean, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_list(p_search character varying DEFAULT NULL::character varying, p_status boolean DEFAULT NULL::boolean, p_tipo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" character varying, "Nombre" character varying, "Comision" double precision, "Status" boolean, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "SellerCode" character varying, "SellerName" character varying, "Commission" double precision, "Direccion" character varying, "Telefonos" character varying, "Email" character varying, "Tipo" character varying, "Clave" character varying, "RangoVentasUno" double precision, "ComisionVentasUno" double precision, "RangoVentasDos" double precision, "ComisionVentasDos" double precision, "RangoVentasTres" double precision, "ComisionVentasTres" double precision, "RangoVentasCuatro" double precision, "ComisionVentasCuatro" double precision, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
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
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL
           OR s."SellerCode" LIKE v_search_param
           OR s."SellerName" LIKE v_search_param
           OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."Tipo" = p_tipo);

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
        s."ComisionVentasCuatro",
        v_total AS "TotalCount"
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND (v_search_param IS NULL
           OR s."SellerCode" LIKE v_search_param
           OR s."SellerName" LIKE v_search_param
           OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."Tipo" = p_tipo)
    ORDER BY s."SellerCode"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_vendedores_update
DROP FUNCTION IF EXISTS public.usp_vendedores_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Seller" WHERE "SellerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Seller"
        SET
            "SellerName" = COALESCE(NULLIF(p_row_json->>'Nombre', ''::character varying), "SellerName")::character varying,
            "Commission" = CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = ''
                                THEN "Commission"
                                ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            "Direccion"  = COALESCE(NULLIF(p_row_json->>'Direccion', ''::character varying), "Direccion")::character varying,
            "Telefonos"  = COALESCE(NULLIF(p_row_json->>'Telefonos', ''::character varying), "Telefonos")::character varying,
            "Email"      = COALESCE(NULLIF(p_row_json->>'Email', ''::character varying), "Email")::character varying,
            "IsActive"   = COALESCE((p_row_json->>'Status')::BOOLEAN, "IsActive"),
            "Tipo"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::character varying), "Tipo")::character varying,
            "Clave"      = COALESCE(NULLIF(p_row_json->>'clave', ''::character varying), "Clave")::character varying
        WHERE "SellerCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

