-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_nomina_consultas.sql
-- Consultas nómina (canónico): conceptos, nóminas, vacaciones,
-- liquidaciones, constantes.
-- ============================================================

-- =============================================
-- sp_Nomina_Conceptos_List
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Conceptos_List(VARCHAR, VARCHAR, VARCHAR, INT, INT);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Conceptos_List(
    p_co_nomina VARCHAR(20) DEFAULT NULL,
    p_tipo      VARCHAR(20) DEFAULT NULL,
    p_search    VARCHAR(120) DEFAULT NULL,
    p_page      INT DEFAULT 1,
    p_limit     INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"   INT,
    "Codigo"       VARCHAR,
    "CodigoNomina" VARCHAR,
    "Nombre"       VARCHAR,
    "Formula"      TEXT,
    "Sobre"        VARCHAR,
    "Clase"        VARCHAR,
    "Tipo"         VARCHAR,
    "Uso"          VARCHAR,
    "Bonificable"  VARCHAR,
    "Antiguedad"   VARCHAR,
    "Contable"     VARCHAR,
    "Aplica"       VARCHAR,
    "Defecto"      DOUBLE PRECISION,
    "Convencion"   VARCHAR,
    "TipoCalculo"  VARCHAR,
    "Orden"        INT,
    "Activo"       BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = v_company_id
      AND (p_co_nomina IS NULL OR pc."PayrollCode" = p_co_nomina)
      AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
      AND (
          p_search IS NULL
          OR pc."ConceptName" ILIKE '%' || p_search || '%'
          OR pc."ConceptCode" ILIKE '%' || p_search || '%'
      );

    RETURN QUERY
    SELECT
        v_total,
        pc."ConceptCode",
        pc."PayrollCode",
        pc."ConceptName",
        pc."Formula",
        pc."BaseExpression",
        pc."ConceptClass",
        pc."ConceptType",
        pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        CASE WHEN pc."IsSeniority"  THEN 'S' ELSE 'N' END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag"  THEN 'S' ELSE 'N' END,
        pc."DefaultValue"::DOUBLE PRECISION,
        pc."ConventionCode",
        pc."CalculationType",
        pc."SortOrder",
        pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = v_company_id
      AND (p_co_nomina IS NULL OR pc."PayrollCode" = p_co_nomina)
      AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
      AND (
          p_search IS NULL
          OR pc."ConceptName" ILIKE '%' || p_search || '%'
          OR pc."ConceptCode" ILIKE '%' || p_search || '%'
      )
    ORDER BY pc."PayrollCode", pc."SortOrder", pc."ConceptCode"
    LIMIT p_limit OFFSET v_offset;
END;
$$;


-- =============================================
-- sp_Nomina_Concepto_Save
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Concepto_Save(VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Concepto_Save(
    p_co_concept  VARCHAR(20),
    p_co_nomina   VARCHAR(20),
    p_nb_concepto VARCHAR(120),
    p_formula     TEXT          DEFAULT NULL,
    p_sobre       VARCHAR(255)  DEFAULT NULL,
    p_clase       VARCHAR(20)   DEFAULT NULL,
    p_tipo        VARCHAR(20)   DEFAULT NULL,
    p_uso         VARCHAR(20)   DEFAULT NULL,
    p_bonificable VARCHAR(1)    DEFAULT NULL,
    p_antiguedad  VARCHAR(1)    DEFAULT NULL,
    p_contable    VARCHAR(50)   DEFAULT NULL,
    p_aplica      VARCHAR(1)    DEFAULT 'S',
    p_defecto     DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id  INT;
    v_branch_id   INT;
    v_resultado   INT := 0;
    v_mensaje     VARCHAR(500) := '';
    v_bonif       BOOLEAN;
    v_antig       BOOLEAN;
    v_aplica_flag BOOLEAN;
    v_defecto_val NUMERIC(18,6);
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    v_bonif       := UPPER(COALESCE(p_bonificable, 'S')) IN ('S', '1');
    v_antig       := UPPER(COALESCE(p_antiguedad, 'N')) IN ('S', '1');
    v_aplica_flag := UPPER(COALESCE(p_aplica, 'S')) IN ('S', '1');
    v_defecto_val := COALESCE(p_defecto::NUMERIC(18,6), 0);

    IF EXISTS (
        SELECT 1 FROM hr."PayrollConcept"
        WHERE "CompanyId" = v_company_id
          AND "PayrollCode" = p_co_nomina
          AND "ConceptCode" = p_co_concept
          AND COALESCE("ConventionCode",''::VARCHAR) = ''
          AND COALESCE("CalculationType",''::VARCHAR) = ''
    ) THEN
        UPDATE hr."PayrollConcept"
        SET "ConceptName"           = p_nb_concepto,
            "Formula"               = p_formula,
            "BaseExpression"        = p_sobre,
            "ConceptClass"          = p_clase,
            "ConceptType"           = COALESCE(p_tipo, 'ASIGNACION'),
            "UsageType"             = p_uso,
            "IsBonifiable"          = v_bonif,
            "IsSeniority"           = v_antig,
            "AccountingAccountCode" = p_contable,
            "AppliesFlag"           = v_aplica_flag,
            "DefaultValue"          = v_defecto_val,
            "UpdatedAt"             = NOW() AT TIME ZONE 'UTC',
            "IsActive"              = TRUE
        WHERE "CompanyId" = v_company_id
          AND "PayrollCode" = p_co_nomina
          AND "ConceptCode" = p_co_concept
          AND COALESCE("ConventionCode",''::VARCHAR) = ''
          AND COALESCE("CalculationType",''::VARCHAR) = '';

        v_resultado := 1;
        v_mensaje   := 'Concepto actualizado';
    ELSE
        INSERT INTO hr."PayrollConcept" (
            "CompanyId", "PayrollCode", "ConceptCode", "ConceptName",
            "Formula", "BaseExpression", "ConceptClass", "ConceptType",
            "UsageType", "IsBonifiable", "IsSeniority",
            "AccountingAccountCode", "AppliesFlag", "DefaultValue",
            "ConventionCode", "CalculationType", "LotttArticle", "CcpClause",
            "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_company_id, p_co_nomina, p_co_concept, p_nb_concepto,
            p_formula, p_sobre, p_clase, COALESCE(p_tipo, 'ASIGNACION'),
            p_uso, v_bonif, v_antig,
            p_contable, v_aplica_flag, v_defecto_val,
            NULL, NULL, NULL, NULL,
            0, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        );

        v_resultado := 1;
        v_mensaje   := 'Concepto creado';
    END IF;

    RETURN QUERY SELECT v_resultado, v_mensaje;
END;
$$;


-- =============================================
-- sp_Nomina_List
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_List(VARCHAR, VARCHAR, DATE, DATE, BOOLEAN, INT, INT);

CREATE OR REPLACE FUNCTION public.sp_Nomina_List(
    p_nomina       VARCHAR(20) DEFAULT NULL,
    p_cedula       VARCHAR(32) DEFAULT NULL,
    p_fecha_desde  DATE        DEFAULT NULL,
    p_fecha_hasta  DATE        DEFAULT NULL,
    p_solo_abiertas BOOLEAN    DEFAULT FALSE,
    p_page         INT         DEFAULT 1,
    p_limit        INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"   INT,
    "PayrollRunId" BIGINT,
    "NOMINA"       VARCHAR,
    "CEDULA"       VARCHAR,
    "NOMBRE"       VARCHAR,
    "FECHA"        TIMESTAMP,
    "INICIO"       DATE,
    "HASTA"        DATE,
    "ASIGNACION"   NUMERIC,
    "DEDUCCION"    NUMERIC,
    "TOTAL"        NUMERIC,
    "CERRADA"      BOOLEAN,
    "TipoNomina"   VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND (p_nomina IS NULL OR pr."PayrollCode" = p_nomina)
      AND (p_cedula IS NULL OR pr."EmployeeCode" = p_cedula)
      AND (p_fecha_desde IS NULL OR pr."DateFrom" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR pr."DateTo" <= p_fecha_hasta)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE);

    RETURN QUERY
    SELECT
        v_total,
        pr."PayrollRunId",
        pr."PayrollCode",
        pr."EmployeeCode",
        pr."EmployeeName",
        pr."ProcessDate",
        pr."DateFrom",
        pr."DateTo",
        pr."TotalAssignments",
        pr."TotalDeductions",
        pr."NetTotal",
        pr."IsClosed",
        pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND (p_nomina IS NULL OR pr."PayrollCode" = p_nomina)
      AND (p_cedula IS NULL OR pr."EmployeeCode" = p_cedula)
      AND (p_fecha_desde IS NULL OR pr."DateFrom" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR pr."DateTo" <= p_fecha_hasta)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE)
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;


-- =============================================
-- sp_Nomina_Get (devuelve cabecera + detalle como dos result sets)
-- En PostgreSQL se usa SETOF RECORD o dos funciones separadas.
-- Aquí usamos la cabecera; el detalle se obtiene con sp_Nomina_Get_Lines.
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Get(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Get(
    p_nomina VARCHAR(20),
    p_cedula VARCHAR(32)
)
RETURNS TABLE(
    "PayrollRunId"   BIGINT,
    "NOMINA"         VARCHAR,
    "CEDULA"         VARCHAR,
    "NombreEmpleado" VARCHAR,
    "FECHA"          TIMESTAMP,
    "INICIO"         DATE,
    "HASTA"          DATE,
    "ASIGNACION"     NUMERIC,
    "DEDUCCION"      NUMERIC,
    "TOTAL"          NUMERIC,
    "CERRADA"        BOOLEAN,
    "TipoNomina"     VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    RETURN QUERY
    SELECT
        pr."PayrollRunId",
        pr."PayrollCode",
        pr."EmployeeCode",
        pr."EmployeeName",
        pr."ProcessDate",
        pr."DateFrom",
        pr."DateTo",
        pr."TotalAssignments",
        pr."TotalDeductions",
        pr."NetTotal",
        pr."IsClosed",
        pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;
END;
$$;


-- =============================================
-- sp_Nomina_Get_Lines (detalle de líneas de la nómina)
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Get_Lines(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Get_Lines(
    p_nomina VARCHAR(20),
    p_cedula VARCHAR(32)
)
RETURNS TABLE(
    "PayrollRunLineId" BIGINT,
    "CO_CONCEPTO"      VARCHAR,
    "NombreConcepto"   VARCHAR,
    "TIPO"             VARCHAR,
    "CANTIDAD"         NUMERIC,
    "MONTO"            NUMERIC,
    "Total"            NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_run_id     BIGINT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;

    RETURN QUERY
    SELECT
        rl."PayrollRunLineId",
        rl."ConceptCode",
        rl."ConceptName",
        rl."ConceptType",
        rl."Quantity",
        rl."Amount",
        rl."Total"
    FROM hr."PayrollRunLine" rl
    WHERE rl."PayrollRunId" = v_run_id
    ORDER BY rl."PayrollRunLineId";
END;
$$;


-- =============================================
-- sp_Nomina_Cerrar
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Cerrar(VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Cerrar(
    p_nomina     VARCHAR(20),
    p_cedula     VARCHAR(32)  DEFAULT NULL,
    p_co_usuario VARCHAR(50)  DEFAULT 'API'
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_user_id    INT := NULL;
    v_rows       INT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario
      AND u."IsDeleted" = FALSE
    LIMIT 1;

    UPDATE hr."PayrollRun"
    SET "IsClosed"        = TRUE,
        "ClosedAt"        = NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"  = v_user_id,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = v_user_id
    WHERE "CompanyId" = v_company_id
      AND "BranchId" = v_branch_id
      AND "PayrollCode" = p_nomina
      AND (p_cedula IS NULL OR "EmployeeCode" = p_cedula)
      AND "IsClosed" = FALSE;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RETURN QUERY SELECT 1, ('Registros cerrados: ' || v_rows::VARCHAR)::VARCHAR;
END;
$$;


-- =============================================
-- sp_Nomina_Vacaciones_List
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_List(VARCHAR, INT, INT);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Vacaciones_List(
    p_cedula VARCHAR(32) DEFAULT NULL,
    p_page   INT         DEFAULT 1,
    p_limit  INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"          INT,
    "VacationProcessId"   BIGINT,
    "Vacacion"            VARCHAR,
    "Cedula"              VARCHAR,
    "NombreEmpleado"      VARCHAR,
    "Inicio"              DATE,
    "Hasta"               DATE,
    "Reintegro"           DATE,
    "Fecha_Calculo"       TIMESTAMP,
    "Total"               NUMERIC,
    "TotalCalculado"      NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR vp."EmployeeCode" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        vp."VacationProcessId",
        vp."VacationCode",
        vp."EmployeeCode",
        vp."EmployeeName",
        vp."StartDate",
        vp."EndDate",
        vp."ReintegrationDate",
        vp."ProcessDate",
        vp."TotalAmount",
        vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR vp."EmployeeCode" = p_cedula)
    ORDER BY vp."ProcessDate" DESC, vp."VacationProcessId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;


-- =============================================
-- sp_Nomina_Vacaciones_Get (cabecera)
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_Get(VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Vacaciones_Get(
    p_vacacion_id VARCHAR(50)
)
RETURNS TABLE(
    "VacationProcessId"   BIGINT,
    "VacationCode"        VARCHAR,
    "CompanyId"           INT,
    "BranchId"            INT,
    "EmployeeCode"        VARCHAR,
    "EmployeeName"        VARCHAR,
    "StartDate"           DATE,
    "EndDate"             DATE,
    "ReintegrationDate"   DATE,
    "ProcessDate"         TIMESTAMP,
    "TotalAmount"         NUMERIC,
    "CalculatedAmount"    NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        vp."VacationProcessId",
        vp."VacationCode",
        vp."CompanyId",
        vp."BranchId",
        vp."EmployeeCode",
        vp."EmployeeName",
        vp."StartDate",
        vp."EndDate",
        vp."ReintegrationDate",
        vp."ProcessDate",
        vp."TotalAmount",
        vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."VacationCode" = p_vacacion_id
    LIMIT 1;
END;
$$;


-- =============================================
-- sp_Nomina_Vacaciones_Get_Lines (detalle de líneas de vacaciones)
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_Get_Lines(VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Vacaciones_Get_Lines(
    p_vacacion_id VARCHAR(50)
)
RETURNS TABLE(
    "VacationProcessLineId" BIGINT,
    "VacationProcessId"     BIGINT,
    "ConceptCode"           VARCHAR,
    "ConceptName"           VARCHAR,
    "Quantity"              NUMERIC,
    "Amount"                NUMERIC,
    "Total"                 NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        vl."VacationProcessLineId",
        vl."VacationProcessId",
        vl."ConceptCode",
        vl."ConceptName",
        vl."Quantity",
        vl."Amount",
        vl."Total"
    FROM hr."VacationProcessLine" vl
    INNER JOIN hr."VacationProcess" vp ON vp."VacationProcessId" = vl."VacationProcessId"
    WHERE vp."VacationCode" = p_vacacion_id
    ORDER BY vl."VacationProcessLineId";
END;
$$;


-- =============================================
-- sp_Nomina_Liquidaciones_List
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Liquidaciones_List(VARCHAR, INT, INT);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Liquidaciones_List(
    p_cedula VARCHAR(32) DEFAULT NULL,
    p_page   INT         DEFAULT 1,
    p_limit  INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"           INT,
    "SettlementProcessId"  BIGINT,
    "Liquidacion"          VARCHAR,
    "Cedula"               VARCHAR,
    "NombreEmpleado"       VARCHAR,
    "FechaRetiro"          DATE,
    "CausaRetiro"          VARCHAR,
    "TotalLiquidacion"     NUMERIC,
    "FechaCalculo"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR sp."EmployeeCode" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        sp."SettlementProcessId",
        sp."SettlementCode",
        sp."EmployeeCode",
        sp."EmployeeName",
        sp."RetirementDate",
        sp."RetirementCause",
        sp."TotalAmount",
        sp."CreatedAt"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR sp."EmployeeCode" = p_cedula)
    ORDER BY sp."CreatedAt" DESC, sp."SettlementProcessId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;


-- =============================================
-- sp_Nomina_Constantes_List
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Constantes_List(INT, INT);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Constantes_List(
    p_page  INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" INT,
    "Codigo"     VARCHAR,
    "Nombre"     VARCHAR,
    "Valor"      NUMERIC,
    "Origen"     VARCHAR,
    "IsActive"   BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = v_company_id;

    RETURN QUERY
    SELECT
        v_total,
        pc."ConstantCode",
        pc."ConstantName",
        pc."ConstantValue",
        pc."SourceName",
        pc."IsActive"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = v_company_id
    ORDER BY pc."ConstantCode"
    LIMIT p_limit OFFSET v_offset;
END;
$$;


-- =============================================
-- sp_Nomina_Constante_Save
-- =============================================
DROP FUNCTION IF EXISTS public.sp_Nomina_Constante_Save(VARCHAR, VARCHAR, DOUBLE PRECISION, VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_Nomina_Constante_Save(
    p_codigo VARCHAR(50),
    p_nombre VARCHAR(120) DEFAULT NULL,
    p_valor  DOUBLE PRECISION DEFAULT NULL,
    p_origen VARCHAR(80)  DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_resultado  INT := 0;
    v_mensaje    VARCHAR(500) := '';
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    IF EXISTS (
        SELECT 1 FROM hr."PayrollConstant"
        WHERE "CompanyId" = v_company_id
          AND "ConstantCode" = p_codigo
    ) THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"  = COALESCE(p_nombre, "ConstantName"),
            "ConstantValue" = COALESCE(p_valor::NUMERIC(18,6), "ConstantValue"),
            "SourceName"    = COALESCE(p_origen, "SourceName"),
            "IsActive"      = TRUE,
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = v_company_id
          AND "ConstantCode" = p_codigo;

        v_resultado := 1;
        v_mensaje   := 'Constante actualizada';
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName",
            "IsActive", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_company_id,
            p_codigo,
            COALESCE(p_nombre, p_codigo),
            COALESCE(p_valor::NUMERIC(18,6), 0),
            p_origen,
            TRUE,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        );

        v_resultado := 1;
        v_mensaje   := 'Constante creada';
    END IF;

    RETURN QUERY SELECT v_resultado, v_mensaje;
END;
$$;
