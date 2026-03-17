-- ============================================================
-- FIX: sp_crud_empleados.sql - Adapted for production schema
-- master."Employee" has: EmployeeCode, EmployeeName, FiscalId,
--   HireDate, TerminationDate, PositionName, DepartmentName,
--   Salary, IsActive, IsDeleted, CompanyId
-- Service expects: CEDULA, GRUPO, NOMBRE, CARGO, SUELDO, INGRESO, RETIRO, STATUS
-- ============================================================

-- ---------- 1. List ----------
DROP FUNCTION IF EXISTS usp_empleados_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_empleados_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_grupo  VARCHAR(60)  DEFAULT NULL,
    p_status VARCHAR(20)  DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "CEDULA"        VARCHAR,
    "GRUPO"         VARCHAR,
    "NOMBRE"        VARCHAR,
    "DIRECCION"     VARCHAR,
    "TELEFONO"      VARCHAR,
    "NACIMIENTO"    DATE,
    "CARGO"         VARCHAR,
    "NOMINA"        VARCHAR,
    "SUELDO"        DOUBLE PRECISION,
    "INGRESO"       DATE,
    "RETIRO"        DATE,
    "STATUS"        VARCHAR,
    "COMISION"      DOUBLE PRECISION,
    "UTILIDAD"      DOUBLE PRECISION,
    "CO_Usuario"    VARCHAR,
    "SEXO"          VARCHAR,
    "NACIONALIDAD"  VARCHAR,
    "Autoriza"      BOOLEAN,
    "Apodo"         VARCHAR,
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "TotalCount"    INT
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
    FROM master."Employee" e
    WHERE COALESCE(e."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (e."EmployeeCode" ILIKE v_search OR e."EmployeeName" ILIKE v_search))
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR COALESCE(e."DepartmentName",'') ILIKE '%' || p_grupo || '%')
      AND (p_status IS NULL OR TRIM(p_status) = '' OR
           CASE WHEN p_status = 'A' THEN e."IsActive" = TRUE
                WHEN p_status = 'I' THEN e."IsActive" = FALSE
                ELSE TRUE END);

    RETURN QUERY
    SELECT
        e."EmployeeCode"::VARCHAR                AS "CEDULA",
        COALESCE(e."DepartmentName",'')::VARCHAR AS "GRUPO",
        e."EmployeeName"::VARCHAR                AS "NOMBRE",
        NULL::VARCHAR                            AS "DIRECCION",
        NULL::VARCHAR                            AS "TELEFONO",
        NULL::DATE                               AS "NACIMIENTO",
        COALESCE(e."PositionName",'')::VARCHAR   AS "CARGO",
        NULL::VARCHAR                            AS "NOMINA",
        COALESCE(e."Salary",0)::DOUBLE PRECISION AS "SUELDO",
        e."HireDate"                             AS "INGRESO",
        e."TerminationDate"                      AS "RETIRO",
        CASE WHEN e."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "STATUS",
        NULL::DOUBLE PRECISION                   AS "COMISION",
        NULL::DOUBLE PRECISION                   AS "UTILIDAD",
        NULL::VARCHAR                            AS "CO_Usuario",
        NULL::VARCHAR                            AS "SEXO",
        NULL::VARCHAR                            AS "NACIONALIDAD",
        FALSE                                    AS "Autoriza",
        NULL::VARCHAR                            AS "Apodo",
        e."IsActive",
        e."IsDeleted",
        e."CompanyId",
        e."EmployeeCode"::VARCHAR,
        e."EmployeeName"::VARCHAR,
        v_total                                  AS "TotalCount"
    FROM master."Employee" e
    WHERE COALESCE(e."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (e."EmployeeCode" ILIKE v_search OR e."EmployeeName" ILIKE v_search))
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR COALESCE(e."DepartmentName",'') ILIKE '%' || p_grupo || '%')
      AND (p_status IS NULL OR TRIM(p_status) = '' OR
           CASE WHEN p_status = 'A' THEN e."IsActive" = TRUE
                WHEN p_status = 'I' THEN e."IsActive" = FALSE
                ELSE TRUE END)
    ORDER BY e."EmployeeCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Cedula ----------
DROP FUNCTION IF EXISTS usp_empleados_getbycodigo(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_empleados_getbycedula(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_empleados_getbycedula(
    p_cedula VARCHAR(24)
)
RETURNS TABLE(
    "CEDULA"        VARCHAR,
    "GRUPO"         VARCHAR,
    "NOMBRE"        VARCHAR,
    "DIRECCION"     VARCHAR,
    "TELEFONO"      VARCHAR,
    "NACIMIENTO"    DATE,
    "CARGO"         VARCHAR,
    "NOMINA"        VARCHAR,
    "SUELDO"        DOUBLE PRECISION,
    "INGRESO"       DATE,
    "RETIRO"        DATE,
    "STATUS"        VARCHAR,
    "COMISION"      DOUBLE PRECISION,
    "UTILIDAD"      DOUBLE PRECISION,
    "CO_Usuario"    VARCHAR,
    "SEXO"          VARCHAR,
    "NACIONALIDAD"  VARCHAR,
    "Autoriza"      BOOLEAN,
    "Apodo"         VARCHAR,
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."EmployeeCode"::VARCHAR                AS "CEDULA",
        COALESCE(e."DepartmentName",'')::VARCHAR AS "GRUPO",
        e."EmployeeName"::VARCHAR                AS "NOMBRE",
        NULL::VARCHAR                            AS "DIRECCION",
        NULL::VARCHAR                            AS "TELEFONO",
        NULL::DATE                               AS "NACIMIENTO",
        COALESCE(e."PositionName",'')::VARCHAR   AS "CARGO",
        NULL::VARCHAR                            AS "NOMINA",
        COALESCE(e."Salary",0)::DOUBLE PRECISION AS "SUELDO",
        e."HireDate"                             AS "INGRESO",
        e."TerminationDate"                      AS "RETIRO",
        CASE WHEN e."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "STATUS",
        NULL::DOUBLE PRECISION                   AS "COMISION",
        NULL::DOUBLE PRECISION                   AS "UTILIDAD",
        NULL::VARCHAR                            AS "CO_Usuario",
        NULL::VARCHAR                            AS "SEXO",
        NULL::VARCHAR                            AS "NACIONALIDAD",
        FALSE                                    AS "Autoriza",
        NULL::VARCHAR                            AS "Apodo",
        e."IsActive",
        e."IsDeleted",
        e."CompanyId",
        e."EmployeeCode"::VARCHAR,
        e."EmployeeName"::VARCHAR
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_cedula
      AND COALESCE(e."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert ----------
DROP FUNCTION IF EXISTS usp_empleados_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_empleados_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_cedula     VARCHAR(24);
    v_nombre     VARCHAR(200);
BEGIN
    SELECT co."CompanyId" INTO v_company_id
    FROM cfg."Company" co
    WHERE COALESCE(co."IsDeleted", FALSE) = FALSE
    ORDER BY co."CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_cedula := NULLIF(TRIM(COALESCE(p_row_json->>'CEDULA', '')), '');
    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'NOMBRE', '')), '');

    IF v_cedula IS NULL THEN
        RETURN QUERY SELECT -1, 'CEDULA requerida'::VARCHAR(500);
        RETURN;
    END IF;

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'NOMBRE requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = v_cedula AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Employee" (
        "EmployeeCode", "EmployeeName", "FiscalId",
        "PositionName", "DepartmentName", "Salary",
        "HireDate", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_cedula,
        v_nombre,
        NULLIF(p_row_json->>'CEDULA', ''),
        NULLIF(p_row_json->>'CARGO', ''),
        NULLIF(p_row_json->>'GRUPO', ''),
        CASE WHEN COALESCE(p_row_json->>'SUELDO','') = '' THEN NULL
             ELSE (p_row_json->>'SUELDO')::NUMERIC END,
        CASE WHEN COALESCE(p_row_json->>'INGRESO','') = '' THEN NULL
             ELSE (p_row_json->>'INGRESO')::DATE END,
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
DROP FUNCTION IF EXISTS usp_empleados_update(VARCHAR, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_empleados_update(
    p_cedula   VARCHAR(24),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = p_cedula AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Employee" SET
        "EmployeeName"   = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''), "EmployeeName"),
        "PositionName"   = COALESCE(NULLIF(p_row_json->>'CARGO', ''), "PositionName"),
        "DepartmentName" = COALESCE(NULLIF(p_row_json->>'GRUPO', ''), "DepartmentName"),
        "Salary"         = CASE WHEN COALESCE(p_row_json->>'SUELDO','') = '' THEN "Salary"
                                ELSE (p_row_json->>'SUELDO')::NUMERIC END,
        "IsActive"       = CASE WHEN p_row_json->>'STATUS' = 'A' THEN TRUE
                                WHEN p_row_json->>'STATUS' = 'I' THEN FALSE
                                ELSE "IsActive" END
    WHERE "EmployeeCode" = p_cedula
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
DROP FUNCTION IF EXISTS usp_empleados_delete(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_empleados_delete(
    p_cedula VARCHAR(24)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = p_cedula AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Employee"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "EmployeeCode" = p_cedula;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
