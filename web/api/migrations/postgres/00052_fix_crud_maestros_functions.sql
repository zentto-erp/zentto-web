-- +goose Up
-- +goose StatementBegin
/*
 * Migration 00052: Fix ALL CRUD maestro functions referencing legacy tables
 *
 * Legacy table → Canonical table mapping:
 *   public."Lineas"       → master."ProductLine"
 *   public."Clases"       → master."ProductClass"
 *   public."Grupos"       → master."ProductGroup"
 *   public."Centro_Costo" → master."CostCenter"
 *   public."Feriados"     → cfg."Holiday"
 *   public."Moneda"       → cfg."Currency"
 *   public."Empresa"      → cfg."Company" + cfg."CompanyProfile"
 *   public."Vehiculos"    → fleet."Vehicle"
 *   master."Seller" legacy columns → canonical columns only
 */

-- ============================================================
-- 1. LINEAS → master."ProductLine"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_lineas_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "CODIGO"      INT,
    "DESCRIPCION" VARCHAR,
    "TotalCount"  BIGINT
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductLine" l
    WHERE COALESCE(l."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR l."LineId"::TEXT ILIKE v_search
           OR l."LineName" ILIKE v_search
           OR l."LineCode" ILIKE v_search);

    RETURN QUERY
    SELECT
        l."LineId"::INT       AS "CODIGO",
        l."LineName"::VARCHAR AS "DESCRIPCION",
        v_total               AS "TotalCount"
    FROM master."ProductLine" l
    WHERE COALESCE(l."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR l."LineId"::TEXT ILIKE v_search
           OR l."LineName" ILIKE v_search
           OR l."LineCode" ILIKE v_search)
    ORDER BY l."LineId"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_lineas_getbycodigo(p_codigo INT)
RETURNS TABLE("CODIGO" INT, "DESCRIPCION" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT l."LineId"::INT, l."LineName"::VARCHAR
    FROM master."ProductLine" l
    WHERE l."LineId" = p_codigo
      AND COALESCE(l."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_lineas_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR, "NuevoCodigo" INT)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre     VARCHAR(100);
    v_company_id INT;
    v_new_id     INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'DESCRIPCION',
        p_row_json->>'Descripcion',
        p_row_json->>'LineName',
        ''
    )), '');

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Descripcion requerida'::VARCHAR(500), 0;
        RETURN;
    END IF;

    INSERT INTO master."ProductLine" (
        "CompanyId", "LineCode", "LineName", "IsActive", "IsDeleted"
    ) VALUES (
        v_company_id,
        COALESCE(LEFT(UPPER(REPLACE(v_nombre, ' ', '-')), 20), 'LIN-NEW'),
        v_nombre, TRUE, FALSE
    )
    RETURNING "LineId" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Linea creada exitosamente'::VARCHAR(500), v_new_id;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_lineas_update(p_codigo INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(100);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductLine"
        WHERE "LineId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'DESCRIPCION',
        p_row_json->>'Descripcion',
        p_row_json->>'LineName',
        ''
    )), '');

    UPDATE master."ProductLine" SET
        "LineName"  = COALESCE(v_nombre, "LineName"),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LineId" = p_codigo;

    RETURN QUERY SELECT 1, 'Linea actualizada exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_lineas_delete(p_codigo INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductLine"
        WHERE "LineId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."ProductLine"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LineId" = p_codigo;

    RETURN QUERY SELECT 1, 'Linea eliminada exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 2. CLASES → master."ProductClass"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_clases_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE("Codigo" INT, "Descripcion" VARCHAR, "TotalCount" INT)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductClass" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR c."ClassId"::TEXT ILIKE v_search
           OR c."ClassName" ILIKE v_search
           OR c."ClassCode" ILIKE v_search);

    RETURN QUERY
    SELECT
        c."ClassId"::INT       AS "Codigo",
        c."ClassName"::VARCHAR AS "Descripcion",
        v_total                AS "TotalCount"
    FROM master."ProductClass" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR c."ClassId"::TEXT ILIKE v_search
           OR c."ClassName" ILIKE v_search
           OR c."ClassCode" ILIKE v_search)
    ORDER BY c."ClassId"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_clases_getbycodigo(p_codigo INT)
RETURNS TABLE("Codigo" INT, "Descripcion" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT c."ClassId"::INT, c."ClassName"::VARCHAR
    FROM master."ProductClass" c
    WHERE c."ClassId" = p_codigo
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_clases_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR, "NuevoCodigo" INT)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre     VARCHAR(100);
    v_company_id INT;
    v_new_id     INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'Descripcion',
        p_row_json->>'ClassName',
        ''
    )), '');

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Descripcion requerida'::VARCHAR(500), 0;
        RETURN;
    END IF;

    INSERT INTO master."ProductClass" (
        "CompanyId", "ClassCode", "ClassName", "IsActive", "IsDeleted"
    ) VALUES (
        v_company_id,
        COALESCE(LEFT(UPPER(REPLACE(v_nombre, ' ', '-')), 20), 'CLS-NEW'),
        v_nombre, TRUE, FALSE
    )
    RETURNING "ClassId" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Clase creada exitosamente'::VARCHAR(500), v_new_id;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_clases_update(p_codigo INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(100);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductClass"
        WHERE "ClassId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'Descripcion',
        p_row_json->>'ClassName',
        ''
    )), '');

    UPDATE master."ProductClass" SET
        "ClassName"  = COALESCE(v_nombre, "ClassName"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "ClassId" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase actualizada exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_clases_delete(p_codigo INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductClass"
        WHERE "ClassId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."ProductClass"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ClassId" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase eliminada exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 3. GRUPOS → master."ProductGroup"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_grupos_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"  INT,
    "Codigo"      INT,
    "Descripcion" VARCHAR,
    "Co_Usuario"  VARCHAR,
    "Porcentaje"  DOUBLE PRECISION
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductGroup" g
    WHERE COALESCE(g."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR g."GroupId"::TEXT ILIKE v_search
           OR g."GroupName" ILIKE v_search
           OR g."GroupCode" ILIKE v_search);

    RETURN QUERY
    SELECT
        v_total                AS "TotalCount",
        g."GroupId"::INT       AS "Codigo",
        g."GroupName"::VARCHAR AS "Descripcion",
        g."GroupCode"::VARCHAR AS "Co_Usuario",
        0.0::DOUBLE PRECISION  AS "Porcentaje"
    FROM master."ProductGroup" g
    WHERE COALESCE(g."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR g."GroupId"::TEXT ILIKE v_search
           OR g."GroupName" ILIKE v_search
           OR g."GroupCode" ILIKE v_search)
    ORDER BY g."GroupId"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_grupos_getbycodigo(p_codigo INT)
RETURNS TABLE("Codigo" INT, "Descripcion" VARCHAR, "Co_Usuario" VARCHAR, "Porcentaje" DOUBLE PRECISION)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        g."GroupId"::INT,
        g."GroupName"::VARCHAR,
        g."GroupCode"::VARCHAR,
        0.0::DOUBLE PRECISION
    FROM master."ProductGroup" g
    WHERE g."GroupId" = p_codigo
      AND COALESCE(g."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_grupos_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR, "NuevoCodigo" INT)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre     VARCHAR(100);
    v_code       VARCHAR(20);
    v_company_id INT;
    v_new_id     INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'Descripcion',
        p_row_json->>'GroupName',
        ''
    )), '');
    v_code := NULLIF(TRIM(COALESCE(
        p_row_json->>'Co_Usuario',
        p_row_json->>'GroupCode',
        ''
    )), '');

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Descripcion requerida'::VARCHAR(500), 0;
        RETURN;
    END IF;

    INSERT INTO master."ProductGroup" (
        "CompanyId", "GroupCode", "GroupName", "IsActive", "IsDeleted"
    ) VALUES (
        v_company_id,
        COALESCE(v_code, LEFT(UPPER(REPLACE(v_nombre, ' ', '-')), 20)),
        v_nombre, TRUE, FALSE
    )
    RETURNING "GroupId" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Grupo creado exitosamente'::VARCHAR(500), v_new_id;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_grupos_update(p_codigo INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(100);
    v_code   VARCHAR(20);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductGroup"
        WHERE "GroupId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(
        p_row_json->>'Descripcion',
        p_row_json->>'GroupName',
        ''
    )), '');
    v_code := NULLIF(TRIM(COALESCE(
        p_row_json->>'Co_Usuario',
        p_row_json->>'GroupCode',
        ''
    )), '');

    UPDATE master."ProductGroup" SET
        "GroupName"  = COALESCE(v_nombre, "GroupName"),
        "GroupCode"  = COALESCE(v_code, "GroupCode"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "GroupId" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo actualizado exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_grupos_delete(p_codigo INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."ProductGroup"
        WHERE "GroupId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."ProductGroup"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GroupId" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo eliminado exitosamente'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 4. CENTRO_COSTO → master."CostCenter"
--    (list ya usaba acct."CostCenter" — unificamos a master."CostCenter")
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_centrocosto_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "Codigo"       VARCHAR,
    "Descripcion"  VARCHAR,
    "Presupuestado" VARCHAR,
    "Saldo_Real"   VARCHAR,
    "TotalCount"   INT
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR cc."CostCenterCode" ILIKE v_search
           OR cc."CostCenterName" ILIKE v_search);

    RETURN QUERY
    SELECT
        cc."CostCenterCode"::VARCHAR AS "Codigo",
        cc."CostCenterName"::VARCHAR AS "Descripcion",
        NULL::VARCHAR                AS "Presupuestado",
        NULL::VARCHAR                AS "Saldo_Real",
        v_total                      AS "TotalCount"
    FROM master."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR cc."CostCenterCode" ILIKE v_search
           OR cc."CostCenterName" ILIKE v_search)
    ORDER BY cc."CostCenterCode"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_centrocosto_getbycodigo(p_codigo VARCHAR)
RETURNS TABLE("Codigo" VARCHAR, "Descripcion" VARCHAR, "Presupuestado" VARCHAR, "Saldo_Real" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        cc."CostCenterCode"::VARCHAR,
        cc."CostCenterName"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR
    FROM master."CostCenter" cc
    WHERE cc."CostCenterCode" = p_codigo
      AND COALESCE(cc."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_centrocosto_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_codigo     VARCHAR(50);
    v_nombre     VARCHAR(100);
    v_company_id INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'Codigo', p_row_json->>'CostCenterCode', '')), '');
    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Descripcion', p_row_json->>'CostCenterName', '')), '');

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'Codigo requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."CostCenter"
        WHERE "CostCenterCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Centro de costo ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."CostCenter" (
        "CompanyId", "CostCenterCode", "CostCenterName", "IsActive", "IsDeleted"
    ) VALUES (
        v_company_id, v_codigo, COALESCE(v_nombre, v_codigo), TRUE, FALSE
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_centrocosto_update(p_codigo VARCHAR, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(100);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."CostCenter"
        WHERE "CostCenterCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Descripcion', p_row_json->>'CostCenterName', '')), '');

    UPDATE master."CostCenter" SET
        "CostCenterName" = COALESCE(v_nombre, "CostCenterName"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "CostCenterCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_centrocosto_delete(p_codigo VARCHAR)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."CostCenter"
        WHERE "CostCenterCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CostCenter"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CostCenterCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 5. FERIADOS → cfg."Holiday"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_feriados_list(
    p_search VARCHAR DEFAULT NULL,
    p_anio   INT     DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE("TotalCount" INT, "Fecha" DATE, "Descripcion" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM cfg."Holiday" h
    WHERE COALESCE(h."IsActive", TRUE) = TRUE
      AND (v_search IS NULL OR h."HolidayName" ILIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM h."HolidayDate") = p_anio);

    RETURN QUERY
    SELECT
        v_total             AS "TotalCount",
        h."HolidayDate"     AS "Fecha",
        h."HolidayName"::VARCHAR AS "Descripcion"
    FROM cfg."Holiday" h
    WHERE COALESCE(h."IsActive", TRUE) = TRUE
      AND (v_search IS NULL OR h."HolidayName" ILIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM h."HolidayDate") = p_anio)
    ORDER BY h."HolidayDate"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_feriados_getbyfecha(p_fecha DATE)
RETURNS TABLE("Fecha" DATE, "Descripcion" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT h."HolidayDate", h."HolidayName"::VARCHAR
    FROM cfg."Holiday" h
    WHERE h."HolidayDate" = p_fecha;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_feriados_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_fecha DATE;
    v_nombre VARCHAR(200);
BEGIN
    v_fecha  := (p_row_json->>'Fecha')::DATE;
    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Descripcion', p_row_json->>'HolidayName', '')), '');

    IF v_fecha IS NULL THEN
        RETURN QUERY SELECT -1, 'Fecha requerida'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM cfg."Holiday"
        WHERE "HolidayDate" = v_fecha
    ) THEN
        RETURN QUERY SELECT -1, 'Feriado ya existe para esta fecha'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO cfg."Holiday" ("HolidayDate", "HolidayName", "IsActive", "IsRecurring")
    VALUES (v_fecha, v_nombre, TRUE, FALSE);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_feriados_update(p_fecha DATE, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(200);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cfg."Holiday" WHERE "HolidayDate" = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Descripcion', p_row_json->>'HolidayName', '')), '');

    UPDATE cfg."Holiday" SET
        "HolidayName" = COALESCE(v_nombre, "HolidayName")
    WHERE "HolidayDate" = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_feriados_delete(p_fecha DATE)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cfg."Holiday" WHERE "HolidayDate" = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM cfg."Holiday" WHERE "HolidayDate" = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 6. MONEDA → cfg."Currency"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_moneda_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "Nombre"     VARCHAR,
    "Simbolo"    VARCHAR,
    "Tasa_Local" DOUBLE PRECISION,
    "Local_Tasa" DOUBLE PRECISION,
    "Local"      VARCHAR,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM cfg."Currency" m
    WHERE COALESCE(m."IsActive", TRUE) = TRUE
      AND (v_search IS NULL
           OR m."CurrencyName" ILIKE v_search
           OR m."Symbol" ILIKE v_search
           OR m."CurrencyCode"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        m."CurrencyName"::VARCHAR          AS "Nombre",
        m."Symbol"::VARCHAR                AS "Simbolo",
        1.0::DOUBLE PRECISION              AS "Tasa_Local",
        1.0::DOUBLE PRECISION              AS "Local_Tasa",
        m."CurrencyCode"::VARCHAR          AS "Local",
        v_total                            AS "TotalCount"
    FROM cfg."Currency" m
    WHERE COALESCE(m."IsActive", TRUE) = TRUE
      AND (v_search IS NULL
           OR m."CurrencyName" ILIKE v_search
           OR m."Symbol" ILIKE v_search
           OR m."CurrencyCode"::TEXT ILIKE v_search)
    ORDER BY m."CurrencyName"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_moneda_getbynombre(p_nombre VARCHAR)
RETURNS TABLE(
    "Nombre"     VARCHAR,
    "Simbolo"    VARCHAR,
    "Tasa_Local" DOUBLE PRECISION,
    "Local_Tasa" DOUBLE PRECISION,
    "Local"      VARCHAR
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        m."CurrencyName"::VARCHAR,
        m."Symbol"::VARCHAR,
        1.0::DOUBLE PRECISION,
        1.0::DOUBLE PRECISION,
        m."CurrencyCode"::VARCHAR
    FROM cfg."Currency" m
    WHERE m."CurrencyName" = p_nombre
       OR m."CurrencyCode"::TEXT = p_nombre;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_moneda_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_nombre VARCHAR(100);
    v_symbol VARCHAR(10);
    v_code   CHAR(3);
BEGIN
    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'CurrencyName', '')), '');
    v_symbol := NULLIF(TRIM(COALESCE(p_row_json->>'Simbolo', p_row_json->>'Symbol', '')), '');
    v_code   := NULLIF(TRIM(COALESCE(p_row_json->>'Local', p_row_json->>'CurrencyCode', '')), '');

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Nombre requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM cfg."Currency" WHERE "CurrencyName" = v_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO cfg."Currency" ("CurrencyCode", "CurrencyName", "Symbol", "IsActive")
    VALUES (COALESCE(v_code, LEFT(UPPER(v_nombre), 3))::CHAR(3), v_nombre, v_symbol, TRUE);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_moneda_update(p_nombre VARCHAR, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM cfg."Currency"
        WHERE "CurrencyName" = p_nombre OR "CurrencyCode"::TEXT = p_nombre
    ) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE cfg."Currency" SET
        "Symbol" = COALESCE(
            NULLIF(TRIM(COALESCE(p_row_json->>'Simbolo', p_row_json->>'Symbol', '')), ''),
            "Symbol"
        )
    WHERE "CurrencyName" = p_nombre OR "CurrencyCode"::TEXT = p_nombre;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_moneda_delete(p_nombre VARCHAR)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM cfg."Currency"
        WHERE "CurrencyName" = p_nombre OR "CurrencyCode"::TEXT = p_nombre
    ) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE cfg."Currency" SET "IsActive" = FALSE
    WHERE "CurrencyName" = p_nombre OR "CurrencyCode"::TEXT = p_nombre;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 7. EMPRESA → cfg."Company" + cfg."CompanyProfile"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_empresa_get()
RETURNS TABLE(
    "Empresa"   VARCHAR,
    "RIF"       VARCHAR,
    "Nit"       VARCHAR,
    "Telefono"  VARCHAR,
    "Direccion" VARCHAR,
    "Rifs"      VARCHAR
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        c."LegalName"::VARCHAR              AS "Empresa",
        c."FiscalId"::VARCHAR               AS "RIF",
        COALESCE(p."NitCode", '')::VARCHAR  AS "Nit",
        COALESCE(c."Phone", '')::VARCHAR    AS "Telefono",
        COALESCE(c."Address", '')::VARCHAR  AS "Direccion",
        COALESCE(c."FiscalId", '')::VARCHAR AS "Rifs"
    FROM cfg."Company" c
    LEFT JOIN cfg."CompanyProfile" p ON p."CompanyId" = c."CompanyId"
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId"
    LIMIT 1;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_empresa_update(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_company_id INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;

    IF v_company_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Empresa no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE cfg."Company" SET
        "LegalName" = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Empresa', '')), ''), "LegalName"),
        "FiscalId"  = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'RIF', '')), ''), "FiscalId"),
        "Phone"     = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Telefono', '')), ''), "Phone"),
        "Address"   = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Direccion', '')), ''), "Address"),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = v_company_id;

    -- Upsert profile for Nit
    INSERT INTO cfg."CompanyProfile" ("CompanyId", "NitCode")
    VALUES (v_company_id, NULLIF(TRIM(COALESCE(p_row_json->>'Nit', '')), ''))
    ON CONFLICT ("CompanyId") DO UPDATE SET
        "NitCode"   = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Nit', '')), ''), cfg."CompanyProfile"."NitCode"),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 8. VEHICULOS → fleet."Vehicle"
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_vehiculos_list(
    p_search VARCHAR DEFAULT NULL,
    p_cedula VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "Placa"      VARCHAR,
    "Cedula"     VARCHAR,
    "Marca"      VARCHAR,
    "Anio"       VARCHAR,
    "Cauchos"    VARCHAR
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
BEGIN
    v_limit := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM fleet."Vehicle" v
    WHERE COALESCE(v."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR v."LicensePlate" ILIKE v_search
           OR v."Brand" ILIKE v_search
           OR v."Model" ILIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR v."VinNumber" = p_cedula);

    RETURN QUERY
    SELECT
        v_total                           AS "TotalCount",
        vv."LicensePlate"::VARCHAR        AS "Placa",
        COALESCE(vv."VinNumber", '')::VARCHAR AS "Cedula",
        COALESCE(vv."Brand", '')::VARCHAR AS "Marca",
        COALESCE(vv."Year"::TEXT, '')::VARCHAR AS "Anio",
        COALESCE(vv."Notes", '')::VARCHAR AS "Cauchos"
    FROM fleet."Vehicle" vv
    WHERE COALESCE(vv."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR vv."LicensePlate" ILIKE v_search
           OR vv."Brand" ILIKE v_search
           OR vv."Model" ILIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR vv."VinNumber" = p_cedula)
    ORDER BY vv."LicensePlate"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vehiculos_getbyplaca(p_placa VARCHAR)
RETURNS TABLE("Placa" VARCHAR, "Cedula" VARCHAR, "Marca" VARCHAR, "Anio" VARCHAR, "Cauchos" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        v."LicensePlate"::VARCHAR,
        COALESCE(v."VinNumber", '')::VARCHAR,
        COALESCE(v."Brand", '')::VARCHAR,
        COALESCE(v."Year"::TEXT, '')::VARCHAR,
        COALESCE(v."Notes", '')::VARCHAR
    FROM fleet."Vehicle" v
    WHERE v."LicensePlate" = p_placa
      AND COALESCE(v."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vehiculos_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_placa      VARCHAR(20);
    v_company_id INT;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_placa := NULLIF(TRIM(COALESCE(p_row_json->>'Placa', p_row_json->>'LicensePlate', '')), '');

    IF v_placa IS NULL THEN
        RETURN QUERY SELECT -1, 'Placa requerida'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM fleet."Vehicle"
        WHERE "LicensePlate" = v_placa AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Vehiculo ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO fleet."Vehicle" (
        "CompanyId", "VehicleCode", "LicensePlate", "VinNumber",
        "Brand", "Year", "Notes", "Status", "IsActive", "IsDeleted"
    ) VALUES (
        v_company_id,
        v_placa,
        v_placa,
        NULLIF(TRIM(COALESCE(p_row_json->>'Cedula', '')), ''),
        NULLIF(TRIM(COALESCE(p_row_json->>'Marca', '')), ''),
        CASE WHEN p_row_json->>'Anio' ~ '^\d+$' THEN (p_row_json->>'Anio')::INT ELSE NULL END,
        NULLIF(TRIM(COALESCE(p_row_json->>'Cauchos', '')), ''),
        'active', TRUE, FALSE
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vehiculos_update(p_placa VARCHAR, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM fleet."Vehicle"
        WHERE "LicensePlate" = p_placa AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE fleet."Vehicle" SET
        "VinNumber" = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Cedula', '')), ''), "VinNumber"),
        "Brand"     = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Marca', '')), ''), "Brand"),
        "Year"      = CASE WHEN p_row_json->>'Anio' ~ '^\d+$' THEN (p_row_json->>'Anio')::INT ELSE "Year" END,
        "Notes"     = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Cauchos', '')), ''), "Notes"),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LicensePlate" = p_placa;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vehiculos_delete(p_placa VARCHAR)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM fleet."Vehicle"
        WHERE "LicensePlate" = p_placa AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE fleet."Vehicle"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LicensePlate" = p_placa;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 9. VENDEDORES — fix legacy column references
--    master."Seller" only has: SellerId, CompanyId, SellerCode,
--    SellerName, Commission, Address, Phone, Email, SellerType,
--    IsActive, IsDeleted, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
-- ============================================================

CREATE OR REPLACE FUNCTION public.usp_vendedores_getbycodigo(p_codigo VARCHAR)
RETURNS TABLE(
    "Codigo"   VARCHAR, "Nombre"  VARCHAR, "Comision" DOUBLE PRECISION,
    "Status"   BOOLEAN, "IsActive" BOOLEAN, "IsDeleted" BOOLEAN,
    "CompanyId" INT, "SellerCode" VARCHAR, "SellerName" VARCHAR,
    "Commission" DOUBLE PRECISION,
    "Direccion" VARCHAR, "Telefonos" VARCHAR, "Email" VARCHAR,
    "Tipo" VARCHAR, "Clave" VARCHAR,
    "RangoVentasUno" DOUBLE PRECISION, "ComisionVentasUno" DOUBLE PRECISION,
    "RangoVentasDos" DOUBLE PRECISION, "ComisionVentasDos" DOUBLE PRECISION,
    "RangoVentasTres" DOUBLE PRECISION, "ComisionVentasTres" DOUBLE PRECISION,
    "RangoVentasCuatro" DOUBLE PRECISION, "ComisionVentasCuatro" DOUBLE PRECISION
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        s."SellerCode"::VARCHAR      AS "Codigo",
        s."SellerName"::VARCHAR      AS "Nombre",
        s."Commission"::DOUBLE PRECISION AS "Comision",
        s."IsActive"                 AS "Status",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SellerCode"::VARCHAR,
        s."SellerName"::VARCHAR,
        s."Commission"::DOUBLE PRECISION,
        COALESCE(s."Address", '')::VARCHAR  AS "Direccion",
        COALESCE(s."Phone", '')::VARCHAR    AS "Telefonos",
        COALESCE(s."Email", '')::VARCHAR    AS "Email",
        COALESCE(s."SellerType", '')::VARCHAR AS "Tipo",
        ''::VARCHAR                         AS "Clave",
        NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION, NULL::DOUBLE PRECISION
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vendedores_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(20);
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'Codigo', p_row_json->>'SellerCode', '')), '');

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'Codigo requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Seller"
        WHERE "SellerCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Vendedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Seller" (
        "SellerCode", "SellerName", "Commission",
        "Address", "Phone", "Email", "SellerType",
        "IsActive", "IsDeleted", "CompanyId"
    ) VALUES (
        v_codigo,
        NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'SellerName', '')), ''),
        CASE WHEN p_row_json->>'Comision' ~ '^\d+(\.\d+)?$'
             THEN (p_row_json->>'Comision')::NUMERIC ELSE NULL END,
        NULLIF(TRIM(COALESCE(p_row_json->>'Direccion', '')), ''),
        NULLIF(TRIM(COALESCE(p_row_json->>'Telefonos', '')), ''),
        NULLIF(TRIM(COALESCE(p_row_json->>'Email', '')), ''),
        NULLIF(TRIM(COALESCE(p_row_json->>'Tipo', p_row_json->>'SellerType', '')), ''),
        COALESCE((p_row_json->>'Status')::BOOLEAN, TRUE),
        FALSE,
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_vendedores_update(p_codigo VARCHAR, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Seller"
        WHERE "SellerCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Seller" SET
        "SellerName"  = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'SellerName', '')), ''), "SellerName"),
        "Commission"  = CASE WHEN p_row_json->>'Comision' ~ '^\d+(\.\d+)?$'
                             THEN (p_row_json->>'Comision')::NUMERIC ELSE "Commission" END,
        "Address"     = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Direccion', '')), ''), "Address"),
        "Phone"       = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Telefonos', '')), ''), "Phone"),
        "Email"       = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Email', '')), ''), "Email"),
        "SellerType"  = COALESCE(NULLIF(TRIM(COALESCE(p_row_json->>'Tipo', p_row_json->>'SellerType', '')), ''), "SellerType"),
        "IsActive"    = COALESCE((p_row_json->>'Status')::BOOLEAN, "IsActive"),
        "UpdatedAt"   = NOW() AT TIME ZONE 'UTC'
    WHERE "SellerCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$fn$;

-- ============================================================
-- 10. FIX vendedores_list — reference "Address" not "Direccion"
--     Already mostly OK but references s."Address" which is correct.
--     Just ensure it compiles cleanly (already uses canonical columns).
-- ============================================================

-- vendedores_list is already fixed in prior migration — skip.

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Down migration intentionally empty — functions are idempotent CREATE OR REPLACE
-- +goose StatementEnd
