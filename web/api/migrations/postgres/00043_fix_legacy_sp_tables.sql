-- +goose Up
-- Fix 6 stored procedures that reference legacy tables (public."Clases", public."Grupos",
-- public."Lineas", public."Centro_Costo", public."Empresa") instead of canonical tables
-- (master."ProductClass", master."ProductGroup", master."ProductLine", master."CostCenter",
-- cfg."Company", master."Seller").
-- Also fixes vendedores getbycodigo referencing non-existent columns on master."Seller".

-- ============================================================
-- 1. sp_crud_clases → master."ProductClass"
-- ============================================================

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_clases_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"      INT,
    "Descripcion" VARCHAR(100),
    "TotalCount"  INT
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
    FROM master."ProductClass" pc
    WHERE COALESCE(pc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
       OR pc."ClassId"::VARCHAR ILIKE v_search
       OR pc."ClassName" ILIKE v_search
       OR pc."ClassCode" ILIKE v_search);

    RETURN QUERY
    SELECT
        pc."ClassId",
        pc."ClassName"::VARCHAR(100),
        v_total AS "TotalCount"
    FROM master."ProductClass" pc
    WHERE COALESCE(pc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
       OR pc."ClassId"::VARCHAR ILIKE v_search
       OR pc."ClassName" ILIKE v_search
       OR pc."ClassCode" ILIKE v_search)
    ORDER BY pc."ClassId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_clases_getbycodigo(INT) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_clases_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"      INT,
    "Descripcion" VARCHAR(100)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ClassId",
        pc."ClassName"::VARCHAR(100)
    FROM master."ProductClass" pc
    WHERE pc."ClassId" = p_codigo
      AND COALESCE(pc."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_clases_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(100);
    v_new_id      INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    INSERT INTO master."ProductClass" ("ClassCode", "ClassName", "CompanyId")
    VALUES (
        COALESCE(NULLIF(p_row_json->>'ClassCode', ''::VARCHAR), 'AUTO'),
        v_descripcion,
        1
    )
    RETURNING "ClassId" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Clase creada exitosamente'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_clases_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(100);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductClass" WHERE "ClassId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    UPDATE master."ProductClass"
    SET "ClassName"  = COALESCE(v_descripcion, "ClassName"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "ClassId" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase actualizada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_clases_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductClass" WHERE "ClassId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."ProductClass"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ClassId" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase eliminada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- ============================================================
-- 2. sp_crud_grupos → master."ProductGroup"
-- ============================================================

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_grupos_list(
    p_search  VARCHAR(100) DEFAULT NULL,
    p_page    INT          DEFAULT 1,
    p_limit   INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"    INT,
    "Codigo"        INT,
    "Descripcion"   VARCHAR(100),
    "Co_Usuario"    VARCHAR(10),
    "Porcentaje"    DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset  INT;
    v_total   INT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500  THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductGroup" g
    WHERE COALESCE(g."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR g."GroupId"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."GroupName" LIKE '%' || p_search || '%'
           OR g."GroupCode" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        v_total,
        g."GroupId",
        g."GroupName"::VARCHAR(100),
        NULL::VARCHAR(10),
        NULL::DOUBLE PRECISION
    FROM master."ProductGroup" g
    WHERE COALESCE(g."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR g."GroupId"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."GroupName" LIKE '%' || p_search || '%'
           OR g."GroupCode" LIKE '%' || p_search || '%')
    ORDER BY g."GroupId"
    LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_grupos_getbycodigo(INT) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_grupos_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"        INT,
    "Descripcion"   VARCHAR(100),
    "Co_Usuario"    VARCHAR(10),
    "Porcentaje"    DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        g."GroupId",
        g."GroupName"::VARCHAR(100),
        NULL::VARCHAR(10),
        NULL::DOUBLE PRECISION
    FROM master."ProductGroup" g
    WHERE g."GroupId" = p_codigo
      AND COALESCE(g."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_grupos_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion  VARCHAR(100);
    v_nuevo_codigo INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    INSERT INTO master."ProductGroup" ("GroupCode", "GroupName", "CompanyId")
    VALUES (
        COALESCE(NULLIF(p_row_json->>'GroupCode', ''::VARCHAR), 'AUTO'),
        v_descripcion,
        1
    )
    RETURNING "GroupId" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'Grupo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_grupos_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion  VARCHAR(100);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductGroup" WHERE "GroupId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    UPDATE master."ProductGroup" SET
        "GroupName"  = COALESCE(v_descripcion, "GroupName"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "GroupId" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo actualizado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_grupos_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductGroup" WHERE "GroupId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."ProductGroup"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GroupId" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo eliminado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- ============================================================
-- 3. sp_crud_lineas → master."ProductLine"
-- ============================================================

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_lineas_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "CODIGO" INT,
    "DESCRIPCION" VARCHAR(100),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductLine" l
    WHERE COALESCE(l."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR CAST(l."LineId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR l."LineName" LIKE '%' || p_search || '%'
           OR l."LineCode" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        l."LineId",
        l."LineName"::VARCHAR(100),
        v_total AS "TotalCount"
    FROM master."ProductLine" l
    WHERE COALESCE(l."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR CAST(l."LineId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR l."LineName" LIKE '%' || p_search || '%'
           OR l."LineCode" LIKE '%' || p_search || '%')
    ORDER BY l."LineId"
    LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_lineas_getbycodigo(INT) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_lineas_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "CODIGO" INT,
    "DESCRIPCION" VARCHAR(100)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT l."LineId", l."LineName"::VARCHAR(100)
    FROM master."ProductLine" l
    WHERE l."LineId" = p_codigo
      AND COALESCE(l."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_lineas_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(100);
    v_nuevo_codigo INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', ''::VARCHAR);

    BEGIN
        INSERT INTO master."ProductLine" ("LineCode", "LineName", "CompanyId")
        VALUES (
            COALESCE(NULLIF(p_row_json->>'LineCode', ''::VARCHAR), 'AUTO'),
            v_descripcion,
            1
        )
        RETURNING "LineId" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Linea creada exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_lineas_update(
    p_codigo INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(100);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductLine" WHERE "LineId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', ''::VARCHAR);

    BEGIN
        UPDATE master."ProductLine"
        SET "LineName"  = COALESCE(v_descripcion, "LineName"),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "LineId" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea actualizada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_lineas_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductLine" WHERE "LineId" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."ProductLine"
        SET "IsDeleted" = TRUE, "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "LineId" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea eliminada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd


-- ============================================================
-- 4. sp_crud_centro_costo → master."CostCenter"
--    (list usaba acct."CostCenter" que no existe, ahora master."CostCenter")
--    (getbycodigo/insert/update/delete usaban public."Centro_Costo")
-- ============================================================

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_centrocosto_list(VARCHAR, INT, INT) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_centrocosto_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "Codigo"        character varying,
    "Descripcion"   character varying,
    "Presupuestado" character varying,
    "Saldo_Real"    character varying,
    "TotalCount"    integer
)
LANGUAGE plpgsql AS $func$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR cc."CostCenterCode" ILIKE v_search OR cc."CostCenterName" ILIKE v_search);

    RETURN QUERY
    SELECT
        cc."CostCenterCode"::VARCHAR,
        cc."CostCenterName"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        v_total::INT
    FROM master."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR cc."CostCenterCode" ILIKE v_search OR cc."CostCenterName" ILIKE v_search)
    ORDER BY cc."CostCenterCode"
    LIMIT v_limit OFFSET v_offset;
END;
$func$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_centrocosto_getbycodigo(VARCHAR) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_centrocosto_getbycodigo(
    p_codigo VARCHAR(50)
)
RETURNS TABLE(
    "Codigo"        VARCHAR,
    "Descripcion"   VARCHAR,
    "Presupuestado" VARCHAR,
    "Saldo_Real"    VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_centrocosto_insert(JSONB) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_centrocosto_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_codigo        VARCHAR(50);
    v_descripcion   VARCHAR(100);
BEGIN
    v_codigo        := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);
    v_descripcion   := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    IF EXISTS (SELECT 1 FROM master."CostCenter" WHERE "CostCenterCode" = v_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Centro de costo ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."CostCenter" (
        "CostCenterCode", "CostCenterName", "CompanyId"
    )
    VALUES (v_codigo, v_descripcion, 1);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_centrocosto_update(VARCHAR, JSONB) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_centrocosto_update(
    p_codigo   VARCHAR(50),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion   VARCHAR(100);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CostCenter" WHERE "CostCenterCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    UPDATE master."CostCenter" SET
        "CostCenterName" = COALESCE(v_descripcion, "CostCenterName"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "CostCenterCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_centrocosto_delete(VARCHAR) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_centrocosto_delete(
    p_codigo VARCHAR(50)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CostCenter" WHERE "CostCenterCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE) THEN
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
$$;
-- +goose StatementEnd


-- ============================================================
-- 5. sp_crud_empresa → cfg."Company"
-- ============================================================

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_empresa_get()
RETURNS TABLE(
    "Empresa"    VARCHAR(200),
    "RIF"        VARCHAR(30),
    "Nit"        VARCHAR(50),
    "Telefono"   VARCHAR(50),
    "Direccion"  VARCHAR(500),
    "Rifs"       VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."LegalName"::VARCHAR(200),
        e."FiscalId"::VARCHAR(30),
        NULL::VARCHAR(50),
        e."Phone"::VARCHAR(50),
        e."Address"::VARCHAR(500),
        NULL::VARCHAR(50)
    FROM cfg."Company" e
    WHERE COALESCE(e."IsDeleted", FALSE) = FALSE
    ORDER BY e."CompanyId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_empresa_update(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE
    ORDER BY "CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Empresa no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE cfg."Company" SET
        "LegalName" = COALESCE(NULLIF(p_row_json->>'Empresa', ''::VARCHAR), "LegalName"),
        "FiscalId"  = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "FiscalId"),
        "Phone"     = COALESCE(NULLIF(p_row_json->>'Telefono', ''::VARCHAR), "Phone"),
        "Address"   = COALESCE(NULLIF(p_row_json->>'Direccion', ''::VARCHAR), "Address"),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = v_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- ============================================================
-- 6. sp_crud_vendedores — fix getbycodigo + insert + update
--    getbycodigo referenciaba s."Direccion", s."Telefonos", s."Tipo", s."Clave" etc.
--    que no existen en canonical — usa "Address", "Phone", "SellerType"
--    insert referenciaba columnas legacy que no existen en master."Seller"
-- ============================================================

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_vendedores_getbycodigo(VARCHAR) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
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
        s."SellerCode"::VARCHAR   AS "Codigo",
        s."SellerName"::VARCHAR   AS "Nombre",
        s."Commission"::DOUBLE PRECISION AS "Comision",
        s."IsActive"              AS "Status",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SellerCode"::VARCHAR,
        s."SellerName"::VARCHAR,
        s."Commission"::DOUBLE PRECISION,
        s."Address"::VARCHAR,
        s."Phone"::VARCHAR,
        s."Email"::VARCHAR,
        s."SellerType"::VARCHAR,
        NULL::VARCHAR,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION,
        NULL::DOUBLE PRECISION
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
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
            "Address", "Phone", "Email",
            "IsActive", "SellerType", "IsDeleted", "CompanyId"
        )
        VALUES (
            v_codigo,
            NULLIF(p_row_json->>'Nombre', ''::VARCHAR),
            CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = '' THEN 0
                 ELSE (p_row_json->>'Comision')::NUMERIC(5,2) END,
            NULLIF(p_row_json->>'Direccion', ''::VARCHAR),
            NULLIF(p_row_json->>'Telefonos', ''::VARCHAR),
            NULLIF(p_row_json->>'Email', ''::VARCHAR),
            COALESCE((p_row_json->>'Status')::BOOLEAN, TRUE),
            COALESCE(NULLIF(p_row_json->>'Tipo', ''::VARCHAR), 'INTERNO'),
            FALSE,
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
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
                                ELSE (p_row_json->>'Comision')::NUMERIC(5,2) END,
            "Address"    = COALESCE(NULLIF(p_row_json->>'Direccion', ''::VARCHAR), "Address"),
            "Phone"      = COALESCE(NULLIF(p_row_json->>'Telefonos', ''::VARCHAR), "Phone"),
            "Email"      = COALESCE(NULLIF(p_row_json->>'Email', ''::VARCHAR), "Email"),
            "IsActive"   = COALESCE((p_row_json->>'Status')::BOOLEAN, "IsActive"),
            "SellerType" = COALESCE(NULLIF(p_row_json->>'Tipo', ''::VARCHAR), "SellerType"),
            "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
        WHERE "SellerCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- Rollback would require restoring legacy table references which is not desirable.
-- The legacy tables (public."Clases", public."Grupos", etc.) do not exist in canonical DB.
-- No-op down migration.
