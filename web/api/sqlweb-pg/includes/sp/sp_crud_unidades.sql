-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_unidades.sql
-- CRUD de Unidades (master."UnitOfMeasure")
-- Production schema: UnitId (PK), UnitCode, Description, Symbol, IsActive, IsDeleted, CompanyId
-- Service expects: Id (INT), Unidad, Cantidad
-- ============================================================

-- LIST
DROP FUNCTION IF EXISTS usp_unidades_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Id"         INT,
    "Unidad"     VARCHAR,
    "Cantidad"   DOUBLE PRECISION,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
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
    FROM master."UnitOfMeasure" u
    WHERE COALESCE(u."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR u."UnitCode"::TEXT ILIKE v_search OR u."Description"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        u."UnitId"::INT         AS "Id",
        u."UnitCode"::VARCHAR   AS "Unidad",
        1.0::DOUBLE PRECISION   AS "Cantidad",
        v_total                 AS "TotalCount"
    FROM master."UnitOfMeasure" u
    WHERE COALESCE(u."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR u."UnitCode"::TEXT ILIKE v_search OR u."Description"::TEXT ILIKE v_search)
    ORDER BY u."UnitId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- GET BY ID
DROP FUNCTION IF EXISTS usp_unidades_getbyid(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_unidades_getbyid(p_id INT)
RETURNS TABLE("Id" INT, "Unidad" VARCHAR, "Cantidad" DOUBLE PRECISION)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UnitId"::INT, u."UnitCode"::VARCHAR, 1.0::DOUBLE PRECISION
    FROM master."UnitOfMeasure" u
    WHERE u."UnitId" = p_id AND COALESCE(u."IsDeleted", FALSE) = FALSE;
END;
$$;

-- INSERT
DROP FUNCTION IF EXISTS usp_unidades_insert(JSONB) CASCADE;
DROP FUNCTION IF EXISTS usp_unidades_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "NuevoId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_id   INT;
    v_company_id INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE ORDER BY "CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    INSERT INTO master."UnitOfMeasure" ("UnitCode", "Description", "CompanyId", "IsActive", "IsDeleted")
    VALUES (
        NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'),''::VARCHAR),
        COALESCE(NULLIF(p_row_json->>'Descripcion',''::VARCHAR), NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'),''::VARCHAR), 'SIN DESCRIPCION'),
        v_company_id, TRUE, FALSE
    )
    RETURNING "UnitId" INTO v_nuevo_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_id;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

-- UPDATE
DROP FUNCTION IF EXISTS usp_unidades_update(INT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS usp_unidades_update(p_id INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "UnitId" = p_id AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."UnitOfMeasure" SET
        "UnitCode"    = COALESCE(NULLIF(COALESCE(p_row_json->>'Unidad',p_row_json->>'UnitCode'),''::VARCHAR), "UnitCode"),
        "Description" = COALESCE(NULLIF(p_row_json->>'Descripcion',''::VARCHAR), "Description")
    WHERE "UnitId" = p_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- DELETE
DROP FUNCTION IF EXISTS usp_unidades_delete(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_unidades_delete(p_id INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "UnitId" = p_id AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."UnitOfMeasure" SET "IsDeleted" = TRUE, "IsActive" = FALSE WHERE "UnitId" = p_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
