-- ═══════════════════════════════════════════════════════════════
-- Archivo  : sp_nomina_batch.sql
-- Propósito: Stored Procedures para Nómina en Lote (PostgreSQL)
-- Tablas   : hr."PayrollBatch", hr."PayrollBatchLine", hr."PayrollConcept",
--            hr."PayrollRun", hr."PayrollRunLine", master."Employee"
-- Requiere : sp_nomina_sistema.sql, sp_nomina_calculo.sql
-- Origen   : Conversión desde T-SQL (SQL Server 2012+)
-- Fecha    : 2026-03-16
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────
-- 0. Tablas de soporte: hr."PayrollBatch", hr."PayrollBatchLine"
-- ───────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."PayrollBatch" (
    "BatchId"         SERIAL      NOT NULL PRIMARY KEY,
    "CompanyId"       INTEGER     NOT NULL,
    "BranchId"        INTEGER     NOT NULL,
    "PayrollCode"     VARCHAR(15) NOT NULL,
    "FromDate"        DATE        NOT NULL,
    "ToDate"          DATE        NOT NULL,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'BORRADOR',
    "TotalEmployees"  INTEGER     NOT NULL DEFAULT 0,
    "TotalGross"      NUMERIC(18,2) NOT NULL DEFAULT 0,
    "TotalDeductions" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "TotalNet"        NUMERIC(18,2) NOT NULL DEFAULT 0,
    "CreatedBy"       INTEGER     NULL,
    "CreatedAt"       TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "ApprovedBy"      INTEGER     NULL,
    "ApprovedAt"      TIMESTAMP   NULL,
    "UpdatedAt"       TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "CK_hr_PayrollBatch_Status"
        CHECK ("Status" IN ('BORRADOR', 'EN_REVISION', 'APROBADA', 'PROCESADA', 'CERRADA'))
);

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollBatch_Company"
    ON hr."PayrollBatch" ("CompanyId", "PayrollCode", "Status")
    INCLUDE ("FromDate", "ToDate");

CREATE TABLE IF NOT EXISTS hr."PayrollBatchLine" (
    "LineId"        SERIAL        NOT NULL PRIMARY KEY,
    "BatchId"       INTEGER       NOT NULL,
    "EmployeeId"    BIGINT        NULL,
    "EmployeeCode"  VARCHAR(24)   NOT NULL,
    "EmployeeName"  VARCHAR(200)  NOT NULL,
    "ConceptCode"   VARCHAR(20)   NOT NULL,
    "ConceptName"   VARCHAR(120)  NOT NULL,
    "ConceptType"   VARCHAR(15)   NOT NULL DEFAULT 'ASIGNACION',
    "Quantity"      NUMERIC(18,4) NOT NULL DEFAULT 1,
    "Amount"        NUMERIC(18,4) NOT NULL DEFAULT 0,
    "Total"         NUMERIC(18,2) NOT NULL DEFAULT 0,
    "IsModified"    BOOLEAN       NOT NULL DEFAULT FALSE,
    "Notes"         VARCHAR(500)  NULL,
    "UpdatedAt"     TIMESTAMP     NULL,
    CONSTRAINT "FK_hr_PayrollBatchLine_Batch"
        FOREIGN KEY ("BatchId") REFERENCES hr."PayrollBatch"("BatchId") ON DELETE CASCADE,
    CONSTRAINT "CK_hr_PayrollBatchLine_Type"
        CHECK ("ConceptType" IN ('ASIGNACION', 'DEDUCCION', 'BONO'))
);

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollBatchLine_Batch"
    ON hr."PayrollBatchLine" ("BatchId", "EmployeeCode", "ConceptType")
    INCLUDE ("ConceptCode", "Total");

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollBatchLine_Employee"
    ON hr."PayrollBatchLine" ("BatchId", "EmployeeCode")
    INCLUDE ("ConceptType", "Total", "IsModified");


-- ═══════════════════════════════════════════════════════════════
-- 1. usp_HR_Payroll_GenerateDraft
--    Genera un borrador de nómina en lote para todos los empleados activos.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GenerateDraft(INTEGER, INTEGER, VARCHAR(15), DATE, DATE, INTEGER, VARCHAR(100), INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GenerateDraft(
    p_company_id        INTEGER,
    p_branch_id         INTEGER,
    p_payroll_code      VARCHAR(15),
    p_from_date         DATE,
    p_to_date           DATE,
    p_user_id           INTEGER,
    p_department_filter VARCHAR(100) DEFAULT NULL,
    OUT p_batch_id      INTEGER,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_emp_count INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';
    p_batch_id  := 0;

    -- Validaciones básicas
    IF p_from_date >= p_to_date THEN
        p_resultado := -1;
        p_mensaje   := 'La fecha desde debe ser menor que la fecha hasta.';
        RETURN;
    END IF;

    -- Verificar que no exista un batch BORRADOR duplicado para el mismo período
    IF EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "CompanyId"   = p_company_id
          AND "BranchId"    = p_branch_id
          AND "PayrollCode" = p_payroll_code
          AND "FromDate"    = p_from_date
          AND "ToDate"      = p_to_date
          AND "Status"      = 'BORRADOR'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un borrador de nómina para este período y tipo.';
        RETURN;
    END IF;

    BEGIN
        -- Crear el batch
        INSERT INTO hr."PayrollBatch" (
            "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate",
            "Status", "CreatedBy"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_from_date, p_to_date,
            'BORRADOR', p_user_id
        )
        RETURNING "BatchId" INTO p_batch_id;

        -- Insertar líneas por cada empleado activo + cada concepto activo de la nómina
        INSERT INTO hr."PayrollBatchLine" (
            "BatchId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total"
        )
        SELECT
            p_batch_id,
            e."EmployeeId",
            e."EmployeeCode",
            COALESCE(e."EmployeeName", ''),
            pc."ConceptCode",
            pc."ConceptName",
            pc."ConceptType",
            1,
            COALESCE(pc."DefaultValue", 0),
            COALESCE(pc."DefaultValue", 0)
        FROM master."Employee" e
        CROSS JOIN hr."PayrollConcept" pc
        WHERE e."CompanyId"    = p_company_id
          AND e."IsActive"     = TRUE
          AND pc."CompanyId"   = p_company_id
          AND pc."PayrollCode" = p_payroll_code
          AND pc."IsActive"    = TRUE;

        SELECT COUNT(DISTINCT "EmployeeCode")
        INTO v_emp_count
        FROM hr."PayrollBatchLine"
        WHERE "BatchId" = p_batch_id;

        -- Actualizar totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = v_emp_count,
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Borrador generado exitosamente con ' || v_emp_count::TEXT || ' empleados.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 2. usp_HR_Payroll_SaveDraftLine
--    Guarda cambios de una celda (autosave).
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_SaveDraftLine(INTEGER, NUMERIC(18,4), NUMERIC(18,4), INTEGER, VARCHAR(500), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_SaveDraftLine(
    p_line_id   INTEGER,
    p_quantity  NUMERIC(18,4),
    p_amount    NUMERIC(18,4),
    p_user_id   INTEGER,
    p_notes     VARCHAR(500) DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validar que la línea existe y pertenece a un batch en BORRADOR
    SELECT bl."BatchId"
    INTO v_batch_id
    FROM hr."PayrollBatchLine" bl
    INNER JOIN hr."PayrollBatch" b ON b."BatchId" = bl."BatchId"
    WHERE bl."LineId" = p_line_id
      AND b."Status"  = 'BORRADOR';

    IF v_batch_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."PayrollBatchLine"
        SET "Quantity"   = p_quantity,
            "Amount"     = p_amount,
            "Total"      = p_quantity * p_amount,
            "IsModified" = TRUE,
            "Notes"      = p_notes,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "LineId" = p_line_id;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = v_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea actualizada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 3. usp_HR_Payroll_BatchAddLine
--    Agrega un nuevo concepto a un empleado en el lote.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchAddLine(INTEGER, VARCHAR(24), VARCHAR(20), VARCHAR(120), VARCHAR(15), NUMERIC(18,4), NUMERIC(18,4), INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchAddLine(
    p_batch_id      INTEGER,
    p_employee_code VARCHAR(24),
    p_concept_code  VARCHAR(20),
    p_concept_name  VARCHAR(120),
    p_concept_type  VARCHAR(15),
    p_quantity      NUMERIC(18,4),
    p_amount        NUMERIC(18,4),
    p_user_id       INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_name VARCHAR(200);
    v_employee_id   BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "BatchId" = p_batch_id AND "Status" = 'BORRADOR'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END IF;

    -- Obtener nombre del empleado
    SELECT COALESCE(e."EmployeeName", ''), e."EmployeeId"
    INTO v_employee_name, v_employee_id
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."IsActive"     = TRUE
    LIMIT 1;

    IF v_employee_name IS NULL THEN
        -- Intentar obtener de líneas existentes del batch
        SELECT bl."EmployeeName", bl."EmployeeId"
        INTO v_employee_name, v_employee_id
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId"      = p_batch_id
          AND bl."EmployeeCode" = p_employee_code
        LIMIT 1;
    END IF;

    IF v_employee_name IS NULL THEN
        p_resultado := -2;
        p_mensaje   := 'Empleado no encontrado.';
        RETURN;
    END IF;

    -- Verificar que no exista ya ese concepto para el empleado en este lote
    IF EXISTS (
        SELECT 1 FROM hr."PayrollBatchLine"
        WHERE "BatchId"      = p_batch_id
          AND "EmployeeCode" = p_employee_code
          AND "ConceptCode"  = p_concept_code
    ) THEN
        p_resultado := -3;
        p_mensaje   := 'El concepto ya existe para este empleado en el lote.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."PayrollBatchLine" (
            "BatchId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "IsModified", "UpdatedAt"
        )
        VALUES (
            p_batch_id, v_employee_id, p_employee_code, v_employee_name,
            p_concept_code, p_concept_name, p_concept_type,
            p_quantity, p_amount, p_quantity * p_amount, TRUE,
            (NOW() AT TIME ZONE 'UTC')
        );

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = (SELECT COUNT(DISTINCT "EmployeeCode") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id),
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea agregada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 4. usp_HR_Payroll_BatchRemoveLine
--    Elimina una línea de concepto del lote.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchRemoveLine(INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchRemoveLine(
    p_line_id   INTEGER,
    p_user_id   INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT bl."BatchId"
    INTO v_batch_id
    FROM hr."PayrollBatchLine" bl
    INNER JOIN hr."PayrollBatch" b ON b."BatchId" = bl."BatchId"
    WHERE bl."LineId" = p_line_id
      AND b."Status"  = 'BORRADOR';

    IF v_batch_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        DELETE FROM hr."PayrollBatchLine" WHERE "LineId" = p_line_id;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = (SELECT COUNT(DISTINCT "EmployeeCode") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id),
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = v_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea eliminada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 5. usp_HR_Payroll_GetDraftSummary
--    Retorna resumen del lote para la vista de pre-nómina.
--    Tres result sets expuestos como tres funciones separadas en PG:
--      _Header   -> cabecera con totales y comparación con período anterior
--      _ByDept   -> resumen general (sin columna departamento en Employee)
--      _Alerts   -> alertas (sin asignaciones, neto negativo, monto cero)
-- ═══════════════════════════════════════════════════════════════

-- 5a. Cabecera del batch con totales
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Header(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_Header(
    p_batch_id INTEGER
)
RETURNS TABLE(
    "BatchId"          INTEGER,
    "CompanyId"        INTEGER,
    "BranchId"         INTEGER,
    "PayrollCode"      VARCHAR(15),
    "FromDate"         DATE,
    "ToDate"           DATE,
    "Status"           VARCHAR(20),
    "TotalEmployees"   INTEGER,
    "TotalGross"       NUMERIC(18,2),
    "TotalDeductions"  NUMERIC(18,2),
    "TotalNet"         NUMERIC(18,2),
    "CreatedBy"        INTEGER,
    "CreatedAt"        TIMESTAMP,
    "ApprovedBy"       INTEGER,
    "ApprovedAt"       TIMESTAMP,
    "PrevBatchId"      INTEGER,
    "PrevTotalGross"   NUMERIC(18,2),
    "PrevTotalDeductions" NUMERIC(18,2),
    "PrevTotalNet"     NUMERIC(18,2),
    "NetChangePercent" NUMERIC(8,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BatchId",
        b."CompanyId",
        b."BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        b."TotalEmployees",
        b."TotalGross",
        b."TotalDeductions",
        b."TotalNet",
        b."CreatedBy",
        b."CreatedAt",
        b."ApprovedBy",
        b."ApprovedAt",
        prev."PrevBatchId",
        prev."PrevTotalGross",
        prev."PrevTotalDeductions",
        prev."PrevTotalNet",
        CASE WHEN prev."PrevTotalNet" > 0
             THEN CAST(((b."TotalNet" - prev."PrevTotalNet") / prev."PrevTotalNet") * 100 AS NUMERIC(8,2))
             ELSE 0::NUMERIC(8,2)
        END AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN LATERAL (
        SELECT
            pb."BatchId"          AS "PrevBatchId",
            pb."TotalGross"       AS "PrevTotalGross",
            pb."TotalDeductions"  AS "PrevTotalDeductions",
            pb."TotalNet"         AS "PrevTotalNet"
        FROM hr."PayrollBatch" pb
        WHERE pb."CompanyId"   = b."CompanyId"
          AND pb."BranchId"    = b."BranchId"
          AND pb."PayrollCode" = b."PayrollCode"
          AND pb."ToDate"      < b."FromDate"
          AND pb."Status"      IN ('PROCESADA', 'CERRADA')
        ORDER BY pb."ToDate" DESC
        LIMIT 1
    ) prev ON TRUE
    WHERE b."BatchId" = p_batch_id;
END;
$$;

-- 5b. Resumen general (sin columna departamento)
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_ByDept(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_ByDept(
    p_batch_id INTEGER
)
RETURNS TABLE(
    "DepartmentCode" TEXT,
    "DepartmentName" TEXT,
    "EmployeeCount"  BIGINT,
    "DeptGross"      NUMERIC,
    "DeptDeductions" NUMERIC,
    "DeptNet"        NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        'GENERAL'::TEXT                                                          AS "DepartmentCode",
        'General'::TEXT                                                          AS "DepartmentName",
        COUNT(DISTINCT bl."EmployeeCode")                                        AS "EmployeeCount",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0) AS "DeptGross",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)             AS "DeptDeductions",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)           AS "DeptNet"
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId" = p_batch_id;
END;
$$;

-- 5c. Alertas
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Alerts(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_Alerts(
    p_batch_id INTEGER
)
RETURNS TABLE(
    "AlertType"    TEXT,
    "EmployeeCode" VARCHAR(24),
    "EmployeeName" VARCHAR(200),
    "AlertMessage" TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        alerts."AlertType",
        alerts."EmployeeCode",
        alerts."EmployeeName",
        alerts."AlertMessage"
    FROM (
        -- Empleados sin asignaciones
        SELECT
            'SIN_ASIGNACIONES'::TEXT                               AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            'El empleado no tiene conceptos de asignación.'::TEXT  AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN 1 ELSE 0 END) = 0

        UNION ALL

        -- Empleados con neto negativo
        SELECT
            'NETO_NEGATIVO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('El neto del empleado es negativo: ' ||
             (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END))::TEXT
            )::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
              - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)) < 0

        UNION ALL

        -- Líneas con monto cero
        SELECT
            'MONTO_CERO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('Concepto ' || bl."ConceptCode" || ' tiene monto cero.')::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId"     = p_batch_id
          AND bl."Total"       = 0
          AND bl."ConceptType" IN ('ASIGNACION', 'BONO')

    ) alerts
    ORDER BY alerts."AlertType", alerts."EmployeeCode";
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 6. usp_HR_Payroll_GetDraftGrid
--    Retorna los empleados con sus totales para la grilla.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftGrid(INTEGER, VARCHAR(100), VARCHAR(100), BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftGrid(
    p_batch_id      INTEGER,
    p_search        VARCHAR(100) DEFAULT NULL,
    p_department    VARCHAR(100) DEFAULT NULL,
    p_only_modified BOOLEAN      DEFAULT FALSE,
    p_offset        INTEGER      DEFAULT 0,
    p_limit         INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "EmployeeCode"   VARCHAR(24),
    "EmployeeName"   VARCHAR(200),
    "EmployeeId"     BIGINT,
    "DepartmentCode" TEXT,
    "DepartmentName" TEXT,
    "PositionName"   TEXT,
    "TotalGross"     NUMERIC,
    "TotalDeductions" NUMERIC,
    "TotalNet"       NUMERIC,
    "HasModified"    BIGINT,
    "ConceptCount"   BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH "EmployeeSummary" AS (
        SELECT
            bl."EmployeeCode",
            bl."EmployeeName",
            bl."EmployeeId",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END) AS "TotalGross",
            SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)              AS "TotalDeductions",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)            AS "TotalNet",
            MAX(CASE WHEN bl."IsModified" THEN 1 ELSE 0 END)                                      AS "HasModified",
            COUNT(*)                                                                                AS "ConceptCount"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName", bl."EmployeeId"
    ), "Filtered" AS (
        SELECT es.*
        FROM "EmployeeSummary" es
        WHERE (p_search IS NULL
               OR es."EmployeeCode" ILIKE '%' || p_search || '%'
               OR es."EmployeeName" ILIKE '%' || p_search || '%')
          AND (NOT p_only_modified OR es."HasModified" = 1)
    )
    SELECT
        COUNT(*) OVER()       AS p_total_count,
        f."EmployeeCode",
        f."EmployeeName",
        f."EmployeeId",
        ''::TEXT              AS "DepartmentCode",
        ''::TEXT              AS "DepartmentName",
        ''::TEXT              AS "PositionName",
        f."TotalGross",
        f."TotalDeductions",
        f."TotalNet",
        f."HasModified",
        f."ConceptCount"
    FROM "Filtered" f
    ORDER BY f."EmployeeName"
    OFFSET p_offset
    LIMIT p_limit;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 7. usp_HR_Payroll_GetEmployeeLines
--    Retorna todas las líneas de concepto de un empleado en un lote.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetEmployeeLines(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetEmployeeLines(
    p_batch_id      INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE(
    "LineId"       INTEGER,
    "BatchId"      INTEGER,
    "EmployeeId"   BIGINT,
    "EmployeeCode" VARCHAR(24),
    "EmployeeName" VARCHAR(200),
    "ConceptCode"  VARCHAR(20),
    "ConceptName"  VARCHAR(120),
    "ConceptType"  VARCHAR(15),
    "Quantity"     NUMERIC(18,4),
    "Amount"       NUMERIC(18,4),
    "Total"        NUMERIC(18,2),
    "IsModified"   BOOLEAN,
    "Notes"        VARCHAR(500),
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bl."LineId",
        bl."BatchId",
        bl."EmployeeId",
        bl."EmployeeCode",
        bl."EmployeeName",
        bl."ConceptCode",
        bl."ConceptName",
        bl."ConceptType",
        bl."Quantity",
        bl."Amount",
        bl."Total",
        bl."IsModified",
        bl."Notes",
        bl."UpdatedAt"
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId"      = p_batch_id
      AND bl."EmployeeCode" = p_employee_code
    ORDER BY
        CASE bl."ConceptType"
            WHEN 'ASIGNACION' THEN 1
            WHEN 'BONO'       THEN 2
            WHEN 'DEDUCCION'  THEN 3
        END,
        bl."ConceptCode";
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 8. usp_HR_Payroll_ApproveDraft
--    Aprueba un borrador de nómina.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ApproveDraft(INTEGER, INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ApproveDraft(
    p_batch_id   INTEGER,
    p_approved_by INTEGER,
    p_user_id    INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM hr."PayrollBatch"
    WHERE "BatchId" = p_batch_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Lote no encontrado.';
        RETURN;
    END IF;

    IF v_current_status NOT IN ('BORRADOR', 'EN_REVISION') THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar lotes en estado BORRADOR o EN_REVISION. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    -- Verificar que el lote tiene líneas
    IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id) THEN
        p_resultado := -3;
        p_mensaje   := 'No se puede aprobar un lote sin líneas.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."PayrollBatch"
        SET "Status"     = 'APROBADA',
            "ApprovedBy" = p_approved_by,
            "ApprovedAt" = (NOW() AT TIME ZONE 'UTC'),
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Lote aprobado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 9. usp_HR_Payroll_ProcessBatch
--    Procesa un lote aprobado: crea PayrollRun individuales.
--    Nota: el XML de líneas se construye como JSON en PostgreSQL
--    para compatibilidad con usp_HR_Payroll_UpsertRun.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ProcessBatch(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ProcessBatch(
    p_batch_id  INTEGER,
    p_user_id   INTEGER,
    OUT p_procesados INTEGER,
    OUT p_errores    INTEGER,
    OUT p_resultado  INTEGER,
    OUT p_mensaje    TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id   INTEGER;
    v_branch_id    INTEGER;
    v_payroll_code VARCHAR(15);
    v_from_date    DATE;
    v_to_date      DATE;
    v_status       VARCHAR(20);

    v_emp_code   VARCHAR(24);
    v_emp_name   VARCHAR(200);
    v_emp_id     BIGINT;
    v_emp_gross  NUMERIC(18,2);
    v_emp_deduct NUMERIC(18,2);
    v_emp_net    NUMERIC(18,2);

    v_run_res    INTEGER;
    v_run_msg    TEXT;
    v_lines_json TEXT;

    emp_rec RECORD;
BEGIN
    p_procesados := 0;
    p_errores    := 0;
    p_resultado  := 0;
    p_mensaje    := '';

    -- Validar estado
    SELECT "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate", "Status"
    INTO v_company_id, v_branch_id, v_payroll_code, v_from_date, v_to_date, v_status
    FROM hr."PayrollBatch"
    WHERE "BatchId" = p_batch_id;

    IF v_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Lote no encontrado.';
        RETURN;
    END IF;

    IF v_status <> 'APROBADA' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden procesar lotes en estado APROBADA. Estado actual: ' || v_status;
        RETURN;
    END IF;

    BEGIN
        -- Iterar empleados en el lote (equivalente al cursor T-SQL)
        FOR emp_rec IN
            SELECT
                "EmployeeCode",
                MAX("EmployeeName")                                                                                           AS "EmployeeName",
                MAX("EmployeeId")                                                                                             AS "EmployeeId",
                COALESCE(SUM(CASE WHEN "ConceptType" IN ('ASIGNACION', 'BONO') THEN "Total" ELSE 0 END), 0)                  AS "EmpGross",
                COALESCE(SUM(CASE WHEN "ConceptType" = 'DEDUCCION' THEN "Total" ELSE 0 END), 0)                              AS "EmpDeduct",
                COALESCE(SUM(CASE WHEN "ConceptType" IN ('ASIGNACION', 'BONO') THEN "Total" ELSE 0 END), 0)
                - COALESCE(SUM(CASE WHEN "ConceptType" = 'DEDUCCION' THEN "Total" ELSE 0 END), 0)                            AS "EmpNet"
            FROM hr."PayrollBatchLine"
            WHERE "BatchId" = p_batch_id
            GROUP BY "EmployeeCode"
        LOOP
            -- Construir JSON de líneas para este empleado
            SELECT json_agg(
                json_build_object(
                    'code',        "ConceptCode",
                    'name',        "ConceptName",
                    'type',        "ConceptType",
                    'qty',         "Quantity",
                    'amount',      "Amount",
                    'total',       "Total",
                    'description', COALESCE("Notes", '')
                )
            )::TEXT
            INTO v_lines_json
            FROM hr."PayrollBatchLine"
            WHERE "BatchId"      = p_batch_id
              AND "EmployeeCode" = emp_rec."EmployeeCode";

            BEGIN
                SELECT r.p_resultado, r.p_mensaje
                INTO v_run_res, v_run_msg
                FROM public.usp_HR_Payroll_UpsertRun(
                    p_company_id        => v_company_id,
                    p_branch_id         => v_branch_id,
                    p_payroll_code      => v_payroll_code,
                    p_employee_id       => emp_rec."EmployeeId",
                    p_employee_code     => emp_rec."EmployeeCode",
                    p_employee_name     => emp_rec."EmployeeName",
                    p_from_date         => v_from_date,
                    p_to_date           => v_to_date,
                    p_total_assignments => emp_rec."EmpGross",
                    p_total_deductions  => emp_rec."EmpDeduct",
                    p_net_total         => emp_rec."EmpNet",
                    p_payroll_type_name => NULL,
                    p_user_id           => p_user_id,
                    p_lines_json        => v_lines_json
                ) r;

                IF v_run_res > 0 THEN
                    p_procesados := p_procesados + 1;
                ELSE
                    p_errores := p_errores + 1;
                END IF;

            EXCEPTION WHEN OTHERS THEN
                p_errores := p_errores + 1;
            END;
        END LOOP;

        -- Actualizar estado del batch
        UPDATE hr."PayrollBatch"
        SET "Status"    = 'PROCESADA',
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Lote procesado: ' || p_procesados::TEXT || ' empleados procesados, '
                     || p_errores::TEXT || ' errores.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 10. usp_HR_Payroll_ListBatches
--     Lista todos los lotes de nómina con paginación.
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ListBatches(INTEGER, VARCHAR(20), VARCHAR(20), INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ListBatches(INTEGER, VARCHAR(15), VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ListBatches(
    p_company_id   INTEGER,
    p_payroll_code VARCHAR(20) DEFAULT NULL,
    p_status       VARCHAR(20) DEFAULT NULL,
    p_offset       INTEGER     DEFAULT 0,
    p_limit        INTEGER     DEFAULT 25
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "BatchId"        BIGINT,
    "CompanyId"      INTEGER,
    "PayrollCode"    VARCHAR(20),
    "FromDate"       DATE,
    "ToDate"         DATE,
    "Status"         VARCHAR(20),
    "Notes"          VARCHAR(500),
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP,
    "CreatedByUserId" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()  AS p_total_count,
        b."BatchId",
        b."CompanyId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        b."Notes",
        b."CreatedAt",
        b."UpdatedAt",
        b."CreatedByUserId"
    FROM hr."PayrollBatch" b
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND (p_payroll_code IS NULL OR b."PayrollCode" = p_payroll_code)
      AND (p_status       IS NULL OR b."Status"      = p_status)
    ORDER BY b."CreatedAt" DESC
    OFFSET p_offset
    LIMIT p_limit;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- 11. usp_HR_Payroll_BatchBulkUpdate
--     Actualización masiva: aplica un concepto a múltiples empleados.
--     Nota: el parámetro XML de T-SQL se reemplaza por JSON array en PG.
--     Formato JSON: '[{"code":"EMP001"},{"code":"EMP002"}]'
-- ═══════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchBulkUpdate(INTEGER, VARCHAR(20), VARCHAR(15), NUMERIC(18,4), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchBulkUpdate(
    p_batch_id       INTEGER,
    p_concept_code   VARCHAR(20),
    p_concept_type   VARCHAR(15),
    p_amount         NUMERIC(18,4),
    p_user_id        INTEGER,
    p_employee_codes TEXT         DEFAULT NULL,  -- JSON array: '[{"code":"EMP001"},...]'
    OUT p_affected_count INTEGER,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    p_affected_count := 0;
    p_resultado      := 0;
    p_mensaje        := '';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "BatchId" = p_batch_id AND "Status" = 'BORRADOR'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        -- Actualizar líneas existentes que coincidan
        UPDATE hr."PayrollBatchLine" bl
        SET "Amount"     = p_amount,
            "Total"      = bl."Quantity" * p_amount,
            "IsModified" = TRUE,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE bl."BatchId"     = p_batch_id
          AND bl."ConceptCode" = p_concept_code
          AND bl."ConceptType" = p_concept_type
          AND (
              p_employee_codes IS NULL
              OR bl."EmployeeCode" IN (
                  SELECT t.code
                  FROM json_to_recordset(p_employee_codes::json) AS t(code VARCHAR(24))
              )
          );

        GET DIAGNOSTICS v_count = ROW_COUNT;
        p_affected_count := v_count;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := p_affected_count::TEXT || ' líneas actualizadas.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;

-- ═══ sp_nomina_batch.sql completado exitosamente ═══
