-- +goose Up
-- ===========================================================================
-- 00034_nomina_module.sql
-- Migracion: modulo Nomina completo (funciones + seeds)
-- Corrige errores 500 en /v1/nomina/* endpoints
-- ===========================================================================


-- Source: sp_nomina_batch.sql

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Archivo  : sp_nomina_batch.sql
-- PropÃ³sito: Stored Procedures para NÃ³mina en Lote (PostgreSQL)
-- Tablas   : hr."PayrollBatch", hr."PayrollBatchLine", hr."PayrollConcept",
--            hr."PayrollRun", hr."PayrollRunLine", master."Employee"
-- Requiere : sp_nomina_sistema.sql, sp_nomina_calculo.sql
-- Origen   : ConversiÃ³n desde T-SQL (SQL Server 2012+)
-- Fecha    : 2026-03-16
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 0. Tablas de soporte: hr."PayrollBatch", hr."PayrollBatchLine"
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ALTER TABLE: Agregar columnas faltantes si la tabla fue creada
-- por 08_fin_hr_extensions.sql con esquema incompleto.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DO $$ BEGIN
  -- hr."PayrollBatch" â€” columnas que 08_fin_hr_extensions.sql no incluye
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='BranchId') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "BranchId" INTEGER NOT NULL DEFAULT 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='TotalEmployees') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "TotalEmployees" INTEGER NOT NULL DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='TotalGross') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "TotalGross" NUMERIC(18,2) NOT NULL DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='TotalDeductions') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "TotalDeductions" NUMERIC(18,2) NOT NULL DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='TotalNet') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "TotalNet" NUMERIC(18,2) NOT NULL DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='CreatedBy') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "CreatedBy" INTEGER NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='ApprovedBy') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "ApprovedBy" INTEGER NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='hr' AND table_name='PayrollBatch' AND column_name='ApprovedAt') THEN
    ALTER TABLE hr."PayrollBatch" ADD COLUMN "ApprovedAt" TIMESTAMP NULL;
  END IF;
END $$;
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 1. usp_HR_Payroll_GenerateDraft
--    Genera un borrador de nÃ³mina en lote para todos los empleados activos.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GenerateDraft(INTEGER, INTEGER, VARCHAR(15), DATE, DATE, INTEGER, VARCHAR(100)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GenerateDraft(
    p_company_id        INTEGER,
    p_branch_id         INTEGER,
    p_payroll_code      VARCHAR(15),
    p_from_date         DATE,
    p_to_date           DATE,
    p_user_id           INTEGER,
    p_department_filter VARCHAR(100) DEFAULT NULL,
    OUT p_batch_id      BIGINT,
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
    p_batch_id  := 0::BIGINT;

    -- Validaciones bÃ¡sicas
    IF p_from_date >= p_to_date THEN
        p_resultado := -1;
        p_mensaje   := 'La fecha desde debe ser menor que la fecha hasta.';
        RETURN;
    END IF;

    -- Verificar que no exista un batch BORRADOR duplicado para el mismo perÃ­odo
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
        p_mensaje   := 'Ya existe un borrador de nÃ³mina para este perÃ­odo y tipo.';
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

        -- Insertar lÃ­neas por cada empleado activo + cada concepto activo de la nÃ³mina
        INSERT INTO hr."PayrollBatchLine" (
            "BatchId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total"
        )
        SELECT
            p_batch_id,
            e."EmployeeId",
            e."EmployeeCode",
            COALESCE(e."EmployeeName",''::VARCHAR),
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 2. usp_HR_Payroll_SaveDraftLine
--    Guarda cambios de una celda (autosave).
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_SaveDraftLine(INTEGER, NUMERIC(18,4), NUMERIC(18,4), INTEGER, VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_SaveDraftLine(BIGINT, NUMERIC(18,4), NUMERIC(18,4), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_SaveDraftLine(
    p_line_id   BIGINT,
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
    v_batch_id BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validar que la lÃ­nea existe y pertenece a un batch en BORRADOR
    SELECT bl."BatchId"
    INTO v_batch_id
    FROM hr."PayrollBatchLine" bl
    INNER JOIN hr."PayrollBatch" b ON b."BatchId" = bl."BatchId"
    WHERE bl."LineId" = p_line_id
      AND b."Status"  = 'BORRADOR';

    IF v_batch_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'LÃ­nea no encontrada o el lote no estÃ¡ en estado BORRADOR.';
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
        p_mensaje   := 'LÃ­nea actualizada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 3. usp_HR_Payroll_BatchAddLine
--    Agrega un nuevo concepto a un empleado en el lote.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchAddLine(INTEGER, VARCHAR(24), VARCHAR(20), VARCHAR(120), VARCHAR(15), NUMERIC(18,4), NUMERIC(18,4), INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchAddLine(BIGINT, VARCHAR(24), VARCHAR(20), VARCHAR(120), VARCHAR(15), NUMERIC(18,4), NUMERIC(18,4), INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchAddLine(
    p_batch_id      BIGINT,
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
        p_mensaje   := 'El lote no existe o no estÃ¡ en estado BORRADOR.';
        RETURN;
    END IF;

    -- Obtener nombre del empleado
    SELECT COALESCE(e."EmployeeName",''::VARCHAR), e."EmployeeId"
    INTO v_employee_name, v_employee_id
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."IsActive"     = TRUE
    LIMIT 1;

    IF v_employee_name IS NULL THEN
        -- Intentar obtener de lÃ­neas existentes del batch
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
        p_mensaje   := 'LÃ­nea agregada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 4. usp_HR_Payroll_BatchRemoveLine
--    Elimina una lÃ­nea de concepto del lote.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchRemoveLine(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchRemoveLine(BIGINT, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchRemoveLine(
    p_line_id   BIGINT,
    p_user_id   INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id BIGINT;
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
        p_mensaje   := 'LÃ­nea no encontrada o el lote no estÃ¡ en estado BORRADOR.';
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
        p_mensaje   := 'LÃ­nea eliminada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 5. usp_HR_Payroll_GetDraftSummary
--    Retorna resumen del lote para la vista de pre-nÃ³mina.
--    Tres result sets expuestos como tres funciones separadas en PG:
--      _Header   -> cabecera con totales y comparaciÃ³n con perÃ­odo anterior
--      _ByDept   -> resumen general (sin columna departamento en Employee)
--      _Alerts   -> alertas (sin asignaciones, neto negativo, monto cero)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 5a. Cabecera del batch con totales
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Header(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_Header(
    p_batch_id BIGINT
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
        b."BatchId"::INTEGER,
        b."CompanyId"::INTEGER,
        b."BranchId"::INTEGER,
        b."PayrollCode"::VARCHAR(15),
        b."FromDate"::DATE,
        b."ToDate"::DATE,
        b."Status"::VARCHAR(20),
        b."TotalEmployees"::INTEGER,
        b."TotalGross"::NUMERIC(18,2),
        b."TotalDeductions"::NUMERIC(18,2),
        b."TotalNet"::NUMERIC(18,2),
        b."CreatedBy"::INTEGER,
        b."CreatedAt"::TIMESTAMP,
        b."ApprovedBy"::INTEGER,
        b."ApprovedAt"::TIMESTAMP,
        prev."PrevBatchId"::INTEGER,
        prev."PrevTotalGross"::NUMERIC(18,2),
        prev."PrevTotalDeductions"::NUMERIC(18,2),
        prev."PrevTotalNet"::NUMERIC(18,2),
        CASE WHEN prev."PrevTotalNet" > 0
             THEN CAST(((b."TotalNet" - prev."PrevTotalNet") / prev."PrevTotalNet") * 100 AS NUMERIC(8,2))
             ELSE 0::NUMERIC(8,2)
        END AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN LATERAL (
        SELECT
            pb."BatchId"::INTEGER          AS "PrevBatchId",
            pb."TotalGross"::NUMERIC(18,2)       AS "PrevTotalGross",
            pb."TotalDeductions"::NUMERIC(18,2)  AS "PrevTotalDeductions",
            pb."TotalNet"::NUMERIC(18,2)         AS "PrevTotalNet"
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
-- +goose StatementEnd

-- 5b. Resumen general (sin columna departamento)
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_ByDept(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_ByDept(
    p_batch_id BIGINT
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
-- +goose StatementEnd

-- 5c. Alertas
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Alerts(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary_Alerts(
    p_batch_id BIGINT
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
            'El empleado no tiene conceptos de asignaciÃ³n.'::TEXT  AS "AlertMessage"
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

        -- LÃ­neas con monto cero
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 6. usp_HR_Payroll_GetDraftGrid
--    Retorna los empleados con sus totales para la grilla.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftGrid(INTEGER, VARCHAR(100), VARCHAR(100), BOOLEAN, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftGrid(BIGINT, VARCHAR, VARCHAR, BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftGrid(
    p_batch_id      BIGINT,
    p_search        VARCHAR(100) DEFAULT NULL,
    p_department    VARCHAR(100) DEFAULT NULL,
    p_only_modified BOOLEAN      DEFAULT FALSE,
    p_offset        INTEGER      DEFAULT 0,
    p_limit         INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "EmployeeCode"   VARCHAR,
    "EmployeeName"   VARCHAR,
    "EmployeeId"     BIGINT,
    "DepartmentCode" VARCHAR,
    "DepartmentName" VARCHAR,
    "PositionName"   VARCHAR,
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
        f."EmployeeCode"::VARCHAR,
        f."EmployeeName"::VARCHAR,
        f."EmployeeId",
        ''::VARCHAR           AS "DepartmentCode",
        ''::VARCHAR           AS "DepartmentName",
        ''::VARCHAR           AS "PositionName",
        f."TotalGross",
        f."TotalDeductions",
        f."TotalNet",
        f."HasModified"::BIGINT,
        f."ConceptCount"
    FROM "Filtered" f
    ORDER BY f."EmployeeName"
    OFFSET p_offset
    LIMIT p_limit;
END;
$$;
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 7. usp_HR_Payroll_GetEmployeeLines
--    Retorna todas las lÃ­neas de concepto de un empleado en un lote.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetEmployeeLines(INTEGER, VARCHAR(24)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetEmployeeLines(BIGINT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetEmployeeLines(
    p_batch_id      BIGINT,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE(
    "LineId"       INTEGER,
    "BatchId"      INTEGER,
    "EmployeeId"   BIGINT,
    "EmployeeCode" VARCHAR,
    "EmployeeName" VARCHAR,
    "ConceptCode"  VARCHAR,
    "ConceptName"  VARCHAR,
    "ConceptType"  VARCHAR,
    "Quantity"     NUMERIC,
    "Amount"       NUMERIC,
    "Total"        NUMERIC,
    "IsModified"   BOOLEAN,
    "Notes"        VARCHAR,
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bl."LineId"::INTEGER,
        bl."BatchId"::INTEGER,
        bl."EmployeeId"::BIGINT,
        bl."EmployeeCode"::VARCHAR,
        bl."EmployeeName"::VARCHAR,
        bl."ConceptCode"::VARCHAR,
        bl."ConceptName"::VARCHAR,
        bl."ConceptType"::VARCHAR,
        bl."Quantity"::NUMERIC,
        bl."Amount"::NUMERIC,
        bl."Total"::NUMERIC,
        bl."IsModified"::BOOLEAN,
        bl."Notes"::VARCHAR,
        bl."UpdatedAt"::TIMESTAMP
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 8. usp_HR_Payroll_ApproveDraft
--    Aprueba un borrador de nÃ³mina.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ApproveDraft(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ApproveDraft(BIGINT, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ApproveDraft(
    p_batch_id   BIGINT,
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

    -- Verificar que el lote tiene lÃ­neas
    IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id) THEN
        p_resultado := -3;
        p_mensaje   := 'No se puede aprobar un lote sin lÃ­neas.';
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 9. usp_HR_Payroll_ProcessBatch
--    Procesa un lote aprobado: crea PayrollRun individuales.
--    Nota: el XML de lÃ­neas se construye como JSON en PostgreSQL
--    para compatibilidad con usp_HR_Payroll_UpsertRun.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ProcessBatch(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ProcessBatch(BIGINT, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ProcessBatch(
    p_batch_id  BIGINT,
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
            -- Construir JSON de lÃ­neas para este empleado
            SELECT json_agg(
                json_build_object(
                    'code',        "ConceptCode",
                    'name',        "ConceptName",
                    'type',        "ConceptType",
                    'qty',         "Quantity",
                    'amount',      "Amount",
                    'total',       "Total",
                    'description', COALESCE("Notes",''::VARCHAR)
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 10. usp_HR_Payroll_ListBatches
--     Lista todos los lotes de nÃ³mina con paginaciÃ³n.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
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
-- +goose StatementEnd


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 11. usp_HR_Payroll_BatchBulkUpdate
--     ActualizaciÃ³n masiva: aplica un concepto a mÃºltiples empleados.
--     Nota: el parÃ¡metro XML de T-SQL se reemplaza por JSON array en PG.
--     Formato JSON: '[{"code":"EMP001"},{"code":"EMP002"}]'
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchBulkUpdate(INTEGER, VARCHAR(20), VARCHAR(15), NUMERIC(18,4), INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchBulkUpdate(BIGINT, VARCHAR(20), VARCHAR(15), NUMERIC(18,4), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_BatchBulkUpdate(
    p_batch_id       BIGINT,
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
        p_mensaje   := 'El lote no existe o no estÃ¡ en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        -- Actualizar lÃ­neas existentes que coincidan
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
        p_mensaje   := p_affected_count::TEXT || ' lÃ­neas actualizadas.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;
-- +goose StatementEnd

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- WRAPPER: usp_HR_Payroll_GetDraftSummary
-- La API llama "usp_HR_Payroll_GetDraftSummary" como funciÃ³n Ãºnica.
-- Este wrapper devuelve la cabecera + totales en una sola fila.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_GetDraftSummary(
    p_batch_id BIGINT
)
RETURNS TABLE(
    "BatchId"              INTEGER,
    "CompanyId"            INTEGER,
    "BranchId"             INTEGER,
    "PayrollCode"          VARCHAR(15),
    "FromDate"             DATE,
    "ToDate"               DATE,
    "Status"               VARCHAR(20),
    "TotalEmployees"       INTEGER,
    "TotalGross"           NUMERIC(18,2),
    "TotalDeductions"      NUMERIC(18,2),
    "TotalNet"             NUMERIC(18,2),
    "CreatedBy"            INTEGER,
    "CreatedAt"            TIMESTAMP,
    "ApprovedBy"           INTEGER,
    "ApprovedAt"           TIMESTAMP,
    "PrevBatchId"          INTEGER,
    "PrevTotalGross"       NUMERIC(18,2),
    "PrevTotalDeductions"  NUMERIC(18,2),
    "PrevTotalNet"         NUMERIC(18,2),
    "NetChangePercent"     NUMERIC(8,2),
    "totalAsignaciones"    NUMERIC,
    "totalDeducciones"     NUMERIC,
    "totalNeto"            NUMERIC,
    "totalEmpleados"       BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        h."BatchId", h."CompanyId", h."BranchId",
        h."PayrollCode", h."FromDate", h."ToDate",
        h."Status", h."TotalEmployees",
        h."TotalGross", h."TotalDeductions", h."TotalNet",
        h."CreatedBy", h."CreatedAt",
        h."ApprovedBy", h."ApprovedAt",
        h."PrevBatchId", h."PrevTotalGross",
        h."PrevTotalDeductions", h."PrevTotalNet",
        h."NetChangePercent",
        -- Campos adicionales que la API consume como resumen
        h."TotalGross"::NUMERIC       AS "totalAsignaciones",
        h."TotalDeductions"::NUMERIC  AS "totalDeducciones",
        h."TotalNet"::NUMERIC         AS "totalNeto",
        h."TotalEmployees"::BIGINT    AS "totalEmpleados"
    FROM public.usp_HR_Payroll_GetDraftSummary_Header(p_batch_id) h;
END;
$$;
-- +goose StatementEnd

-- â•â•â• sp_nomina_batch.sql completado exitosamente â•â•â•


-- Source: sp_nomina_calculo.sql

-- =============================================
-- MOTOR DE CALCULO DE NOMINA (CANONICO) - PostgreSQL
-- Requiere: sp_nomina_sistema.sql
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_ReemplazarVariables
-- Reemplaza variables en formula por sus valores
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_reemplazar_variables(VARCHAR(80), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_reemplazar_variables(
  p_session_id VARCHAR(80),
  p_formula TEXT
)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
  v_result TEXT := COALESCE(p_formula,''::VARCHAR);
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT "Variable", CAST("Valor" AS VARCHAR(80)) AS val
    FROM hr."PayrollCalcVariable"
    WHERE "SessionID" = p_session_id
    ORDER BY LENGTH("Variable") DESC
  LOOP
    v_result := REPLACE(v_result, rec."Variable", rec.val);
  END LOOP;

  RETURN v_result;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_EvaluarFormula
-- Evalua una formula matematica con variables
-- Retorna resultado y formula resuelta
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_evaluar_formula(VARCHAR(80), TEXT, NUMERIC(18,6), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_evaluar_formula(
  p_session_id VARCHAR(80),
  p_formula TEXT,
  OUT p_resultado NUMERIC(18,6),
  OUT p_formula_resuelta TEXT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_sql TEXT;
BEGIN
  p_resultado := 0;
  p_formula_resuelta := '';

  IF p_formula IS NULL OR TRIM(p_formula) = '' THEN
    RETURN;
  END IF;

  p_formula_resuelta := sp_nomina_reemplazar_variables(p_session_id, p_formula);

  -- Solo caracteres matematicos permitidos
  IF p_formula_resuelta ~ '[^0-9\.+\-\*/\(\) ]' THEN
    p_resultado := 0;
    RETURN;
  END IF;

  v_sql := 'SELECT CAST((' || p_formula_resuelta || ') AS NUMERIC(18,6))';

  BEGIN
    EXECUTE v_sql INTO p_resultado;
    p_resultado := COALESCE(p_resultado, 0);
  EXCEPTION WHEN OTHERS THEN
    p_resultado := 0;
  END;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularConcepto
-- Calcula un concepto de nomina individual
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_concepto(VARCHAR(80), VARCHAR(32), VARCHAR(20), VARCHAR(20), NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6), VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_concepto(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_co_concepto VARCHAR(20),
  p_co_nomina VARCHAR(20),
  p_cantidad NUMERIC(18,6) DEFAULT NULL,
  OUT p_monto NUMERIC(18,6),
  OUT p_total NUMERIC(18,6),
  OUT p_descripcion VARCHAR(200)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_formula TEXT;
  v_default_value NUMERIC(18,6);
  v_cantidad NUMERIC(18,6);
  v_formula_resuelta TEXT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT pc."Formula", pc."DefaultValue", pc."ConceptName"
  INTO v_formula, v_default_value, p_descripcion
  FROM hr."PayrollConcept" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."PayrollCode" = p_co_nomina
    AND pc."ConceptCode" = p_co_concepto
    AND pc."IsActive" = TRUE
  LIMIT 1;

  v_cantidad := p_cantidad;
  IF v_cantidad IS NULL OR v_cantidad <= 0 THEN v_cantidad := 1; END IF;

  IF v_formula IS NOT NULL AND TRIM(v_formula) <> '' THEN
    SELECT r.p_resultado, r.p_formula_resuelta
    INTO p_monto, v_formula_resuelta
    FROM sp_nomina_evaluar_formula(p_session_id, v_formula) r;
  ELSE
    p_monto := COALESCE(v_default_value, 0);
  END IF;

  p_monto := COALESCE(p_monto, 0);
  p_total := p_monto * v_cantidad;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleado
-- Procesa la nomina completa de un empleado
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_procesar_empleado(VARCHAR(20), VARCHAR(32), DATE, DATE, VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_user_id INT := NULL;
  v_employee_id BIGINT;
  v_employee_name VARCHAR(120);
  v_run_id BIGINT;
  v_session_id VARCHAR(80);
  v_asig NUMERIC(18,6) := 0;
  v_ded NUMERIC(18,6) := 0;
  v_neto NUMERIC(18,6) := 0;
  rec RECORD;
  v_monto NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_desc VARCHAR(200);
  v_var_code VARCHAR(120);
  v_var_total NUMERIC(18,6);
  v_var_desc VARCHAR(255);
BEGIN
  p_resultado := 0;
  p_mensaje := '';
  v_session_id := p_nomina || '_' || p_cedula || '_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');

  BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario AND u."IsDeleted" = FALSE
    LIMIT 1;

    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."EmployeeCode" = p_cedula
      AND e."IsDeleted" = FALSE
      AND e."IsActive" = TRUE
    LIMIT 1;

    IF v_employee_id IS NULL THEN
      p_resultado := 0;
      p_mensaje := 'Empleado no encontrado o inactivo en master.Employee';
      RETURN;
    END IF;

    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, p_nomina, p_fecha_inicio, p_fecha_hasta);

    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
      AND pr."DateFrom" = p_fecha_inicio
      AND pr."DateTo" = p_fecha_hasta
      AND pr."RunSource" = 'SP_LEGACY_COMPAT'
    ORDER BY pr."PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NULL THEN
      INSERT INTO hr."PayrollRun" (
        "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "ProcessDate", "DateFrom", "DateTo", "TotalAssignments", "TotalDeductions", "NetTotal",
        "IsClosed", "PayrollTypeName", "RunSource", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_nomina, v_employee_id, p_cedula, v_employee_name,
        (NOW() AT TIME ZONE 'UTC')::DATE, p_fecha_inicio, p_fecha_hasta, 0, 0, 0,
        FALSE, 'COMPAT', 'SP_LEGACY_COMPAT', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "PayrollRunId" INTO v_run_id;
    ELSE
      UPDATE hr."PayrollRun"
      SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id,
          "ProcessDate" = (NOW() AT TIME ZONE 'UTC')::DATE
      WHERE "PayrollRunId" = v_run_id;

      DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    END IF;

    -- Iterar conceptos (reemplaza CURSOR)
    FOR rec IN
      SELECT "ConceptCode", "ConceptName", "ConceptType", "AccountingAccountCode"
      FROM hr."PayrollConcept"
      WHERE "CompanyId" = v_company_id
        AND "PayrollCode" = p_nomina
        AND "IsActive" = TRUE
      ORDER BY "SortOrder", "ConceptCode"
    LOOP
      SELECT r.p_monto, r.p_total, r.p_descripcion
      INTO v_monto, v_total, v_desc
      FROM sp_nomina_calcular_concepto(
        v_session_id, p_cedula, rec."ConceptCode", p_nomina, 1
      ) r;

      INSERT INTO hr."PayrollRunLine" (
        "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
        "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode", "CreatedAt"
      )
      VALUES (
        v_run_id, rec."ConceptCode", COALESCE(rec."ConceptName", v_desc), COALESCE(rec."ConceptType", 'ASIGNACION'),
        1, COALESCE(v_monto, 0), COALESCE(v_total, 0), v_desc, rec."AccountingAccountCode", NOW() AT TIME ZONE 'UTC'
      );

      IF UPPER(COALESCE(rec."ConceptType",''::VARCHAR)) = 'DEDUCCION' THEN
        v_ded := v_ded + COALESCE(v_total, 0);
      ELSE
        v_asig := v_asig + COALESCE(v_total, 0);
        -- Actualizar TOTAL_ASIGNACIONES para que deducciones legales
        -- (ej. FAOV) puedan calcular sobre gananciales (LOTTT Art. 172)
        PERFORM sp_nomina_set_variable(v_session_id, 'TOTAL_ASIGNACIONES', v_asig, 'Total asignaciones acumuladas');
      END IF;

      v_var_code := 'C' || rec."ConceptCode";
      v_var_total := COALESCE(v_total, 0);
      v_var_desc := COALESCE(rec."ConceptName", v_desc);
      PERFORM sp_nomina_set_variable(v_session_id, v_var_code, v_var_total, v_var_desc);
    END LOOP;

    v_neto := v_asig - v_ded;

    UPDATE hr."PayrollRun"
    SET "TotalAssignments" = v_asig,
        "TotalDeductions" = v_ded,
        "NetTotal" = v_neto,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = v_user_id
    WHERE "PayrollRunId" = v_run_id;

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Procesado canonico. Asig=' || CAST(v_asig AS VARCHAR(40)) || ' Ded=' || CAST(v_ded AS VARCHAR(40)) || ' Neto=' || CAST(v_neto AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ProcesarNomina
-- Procesa la nomina para todos los empleados
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_procesar_nomina(VARCHAR(20), DATE, DATE, VARCHAR(50), BOOLEAN, INT, INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_nomina(
  p_nomina VARCHAR(20),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  p_solo_activos BOOLEAN DEFAULT TRUE,
  OUT p_procesados INT,
  OUT p_errores INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_cedula VARCHAR(32);
  v_res INT;
  v_msg VARCHAR(500);
  rec RECORD;
BEGIN
  p_procesados := 0;
  p_errores := 0;
  p_mensaje := '';

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  FOR rec IN
    SELECT e."EmployeeCode"
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."IsDeleted" = FALSE
      AND (p_solo_activos = FALSE OR e."IsActive" = TRUE)
    ORDER BY e."EmployeeCode"
  LOOP
    SELECT r.p_resultado, r.p_mensaje
    INTO v_res, v_msg
    FROM sp_nomina_procesar_empleado(
      p_nomina, rec."EmployeeCode", p_fecha_inicio, p_fecha_hasta, p_co_usuario
    ) r;

    IF v_res = 1 THEN
      p_procesados := p_procesados + 1;
    ELSE
      p_errores := p_errores + 1;
    END IF;
  END LOOP;

  p_mensaje := 'Proceso completado. Procesados=' || CAST(p_procesados AS VARCHAR(20)) || ' Errores=' || CAST(p_errores AS VARCHAR(20));
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_calculo_regimen.sql

-- =============================================
-- CALCULO POR REGIMEN (CANONICO) - PostgreSQL
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_CargarConstantesRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_cargar_constantes_regimen(VARCHAR(80), VARCHAR(10), VARCHAR(15)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10) DEFAULT 'LOT',
  p_tipo_nomina VARCHAR(15) DEFAULT 'MENSUAL'
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_prefix VARCHAR(20) := UPPER(COALESCE(p_regimen, 'LOT')) || '_';
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  PERFORM sp_nomina_cargar_constantes(p_session_id);

  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  SELECT
    p_session_id,
    REPLACE(pc."ConstantCode", v_prefix,''::VARCHAR),
    pc."ConstantValue",
    (pc."ConstantName" || ' [' || p_regimen || ']')
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."IsActive" = TRUE
    AND pc."ConstantCode" LIKE v_prefix || '%'
    AND NOT EXISTS (
      SELECT 1
      FROM hr."PayrollCalcVariable" v
      WHERE v."SessionID" = p_session_id
        AND v."Variable" = REPLACE(pc."ConstantCode", v_prefix,''::VARCHAR)
    );

  PERFORM sp_nomina_set_variable(p_session_id, 'REGIMEN_ID', 0, p_regimen);

  IF UPPER(p_tipo_nomina) = 'SEMANAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 7, 'Dias periodo semanal');
  ELSIF UPPER(p_tipo_nomina) = 'QUINCENAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 15, 'Dias periodo quincenal');
  END IF;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularVacacionesRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_vacaciones_regimen(VARCHAR(80), VARCHAR(10), INT, INT, NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_vacaciones_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_anios_servicio INT,
  p_meses_periodo INT DEFAULT 12,
  OUT p_dias_vacaciones NUMERIC(18,6),
  OUT p_dias_bono_vacacional NUMERIC(18,6),
  OUT p_dias_bono_post_vacacional NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_vac_base NUMERIC(18,6);
  v_bono_base NUMERIC(18,6);
BEGIN
  v_vac_base := fn_nomina_get_variable(p_session_id, 'DIAS_VACACIONES_BASE');
  v_bono_base := fn_nomina_get_variable(p_session_id, 'DIAS_BONO_VAC_BASE');

  IF v_vac_base <= 0 THEN v_vac_base := 15; END IF;
  IF v_bono_base <= 0 THEN v_bono_base := 15; END IF;

  p_dias_vacaciones := v_vac_base + CASE WHEN p_anios_servicio > 0 THEN (p_anios_servicio - 1) ELSE 0 END;
  p_dias_bono_vacacional := v_bono_base + CASE WHEN p_anios_servicio > 0 THEN (p_anios_servicio - 1) ELSE 0 END;
  p_dias_bono_post_vacacional := 0;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_VACACIONES', p_dias_vacaciones, 'Dias vacaciones (regimen)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_VAC', p_dias_bono_vacacional, 'Dias bono vacacional (regimen)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_POST_VAC', p_dias_bono_post_vacacional, 'Bono post vacacional');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularUtilidadesRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_utilidades_regimen(VARCHAR(80), VARCHAR(10), INT, NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_utilidades_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_dias_trabajados_ano INT,
  p_salario_normal NUMERIC(18,6),
  OUT p_utilidades NUMERIC(18,6)
)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
DECLARE
  v_dias_min NUMERIC(18,6);
  v_dias_max NUMERIC(18,6);
  v_dias_util NUMERIC(18,6);
BEGIN
  v_dias_min := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MIN');
  v_dias_max := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MAX');

  IF v_dias_min <= 0 THEN v_dias_min := 30; END IF;
  IF v_dias_max <= 0 THEN v_dias_max := 120; END IF;

  v_dias_util := CASE
    WHEN p_dias_trabajados_ano >= 365 THEN v_dias_max
    WHEN p_dias_trabajados_ano <= 0 THEN 0
    ELSE (v_dias_max * p_dias_trabajados_ano) / 365.0
  END;

  IF v_dias_util < v_dias_min AND p_dias_trabajados_ano > 0 THEN
    v_dias_util := v_dias_min;
  END IF;

  p_utilidades := p_salario_normal * v_dias_util;
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_UTILIDADES', v_dias_util, 'Dias utilidades');
  PERFORM sp_nomina_set_variable(p_session_id, 'MONTO_UTILIDADES', p_utilidades, 'Monto utilidades');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularPrestacionesRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_prestaciones_regimen(VARCHAR(80), VARCHAR(10), INT, INT, NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_prestaciones_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_anios_servicio INT,
  p_meses_adicionales INT,
  p_salario_integral NUMERIC(18,6),
  OUT p_prestaciones NUMERIC(18,6),
  OUT p_intereses NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_dias_anio NUMERIC(18,6);
  v_interes_anual NUMERIC(18,6);
  v_dias_totales NUMERIC(18,6);
BEGIN
  v_dias_anio := fn_nomina_get_variable(p_session_id, 'PREST_DIAS_ANIO');
  v_interes_anual := fn_nomina_get_variable(p_session_id, 'PREST_INTERES_ANUAL');

  IF v_dias_anio <= 0 THEN v_dias_anio := 30; END IF;
  IF v_interes_anual <= 0 THEN v_interes_anual := 0.15; END IF;

  v_dias_totales := (p_anios_servicio * v_dias_anio) + (p_meses_adicionales * (v_dias_anio / 12.0));
  p_prestaciones := p_salario_integral * v_dias_totales;
  p_intereses := p_prestaciones * v_interes_anual;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PRESTACIONES', v_dias_totales, 'Dias prestaciones');
  PERFORM sp_nomina_set_variable(p_session_id, 'MONTO_PRESTACIONES', p_prestaciones, 'Monto prestaciones');
  PERFORM sp_nomina_set_variable(p_session_id, 'INTERESES_PRESTACIONES', p_intereses, 'Intereses prestaciones');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_PrepararVariablesRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_preparar_variables_regimen(VARCHAR(80), VARCHAR(32), VARCHAR(20), VARCHAR(15), VARCHAR(10), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_preparar_variables_regimen(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_nomina VARCHAR(20),
  p_tipo_nomina VARCHAR(15),
  p_regimen VARCHAR(10) DEFAULT NULL,
  p_fecha_inicio DATE DEFAULT NULL,
  p_fecha_hasta DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina));
BEGIN
  IF v_reg = '' THEN v_reg := 'LOT'; END IF;

  PERFORM sp_nomina_preparar_variables_base(p_session_id, p_cedula, p_nomina, p_fecha_inicio, p_fecha_hasta);
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_reg, p_tipo_nomina);
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleadoRegimen
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_procesar_empleado_regimen(VARCHAR(20), VARCHAR(32), DATE, DATE, VARCHAR(10), VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado_regimen(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_regimen VARCHAR(10) DEFAULT NULL,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina));
  v_tipo_calculo VARCHAR(20) := 'MENSUAL';
  v_session_id VARCHAR(80) := p_nomina || '_' || p_cedula || '_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');
  v_nomina_proceso VARCHAR(20);
BEGIN
  IF UPPER(p_nomina) LIKE '%VAC%' THEN v_tipo_calculo := 'VACACIONES'; END IF;
  IF UPPER(p_nomina) LIKE '%LIQ%' THEN v_tipo_calculo := 'LIQUIDACION'; END IF;

  -- Reusar procesamiento base canonico
  v_nomina_proceso := CASE WHEN v_reg IS NULL OR v_reg = '' THEN p_nomina ELSE v_reg END;

  SELECT r.p_resultado, r.p_mensaje
  INTO p_resultado, p_mensaje
  FROM sp_nomina_procesar_empleado(
    v_nomina_proceso, p_cedula, p_fecha_inicio, p_fecha_hasta, p_co_usuario
  ) r;

  IF p_resultado = 1 THEN
    PERFORM sp_nomina_set_variable(v_session_id, 'TIPO_CALCULO_ID', 0, v_tipo_calculo);
  END IF;
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_conceptolegal_adapter.sql

-- =============================================
-- ADAPTADOR CONCEPTO LEGAL -> MODELO CANONICO - PostgreSQL
-- Base: hr."PayrollConcept" (ConventionCode/CalculationType)
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Vista: vw_ConceptosPorRegimen
-- =============================================
CREATE OR REPLACE VIEW vw_conceptos_por_regimen AS
SELECT
  pc."PayrollConceptId" AS "Id",
  pc."ConventionCode" AS "Convencion",
  pc."CalculationType" AS "TipoCalculo",
  pc."ConceptCode" AS "CO_CONCEPT",
  pc."ConceptName" AS "NB_CONCEPTO",
  pc."Formula" AS "FORMULA",
  pc."BaseExpression" AS "SOBRE",
  pc."ConceptType" AS "TIPO",
  CASE WHEN pc."IsBonifiable" = TRUE THEN 'S' ELSE 'N' END AS "BONIFICABLE",
  pc."LotttArticle" AS "LOTTT_Articulo",
  pc."CcpClause" AS "CCP_Clausula",
  pc."SortOrder" AS "Orden",
  pc."IsActive" AS "Activo",
  pc."PayrollCode" AS "CO_NOMINA",
  pc."CompanyId"
FROM hr."PayrollConcept" pc
WHERE pc."ConventionCode" IS NOT NULL;

-- =============================================
-- Funcion: sp_Nomina_CargarConstantesDesdeConceptoLegal
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_cargar_constantes_desde_concepto_legal(VARCHAR(80), VARCHAR(50), VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes_desde_concepto_legal(
  p_session_id VARCHAR(80),
  p_convencion VARCHAR(50) DEFAULT 'LOT',
  p_tipo_calculo VARCHAR(50) DEFAULT 'MENSUAL'
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_regimen VARCHAR(10) := UPPER(LEFT(COALESCE(p_convencion, 'LOT'), 10));
  v_tipo_nomina VARCHAR(15) := UPPER(CASE WHEN p_tipo_calculo IN ('SEMANAL', 'QUINCENAL') THEN p_tipo_calculo ELSE 'MENSUAL' END);
BEGIN
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_regimen, v_tipo_nomina);
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleadoConceptoLegal
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_procesar_empleado_concepto_legal(VARCHAR(20), VARCHAR(32), DATE, DATE, VARCHAR(50), VARCHAR(50), VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado_concepto_legal(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT 'MENSUAL',
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_regimen VARCHAR(10) := UPPER(COALESCE(p_convencion, p_nomina));
BEGIN
  SELECT r.p_resultado, r.p_mensaje
  INTO p_resultado, p_mensaje
  FROM sp_nomina_procesar_empleado_regimen(
    p_nomina, p_cedula, p_fecha_inicio, p_fecha_hasta, v_regimen, p_co_usuario
  ) r;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ConceptosLegales_List
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_conceptos_legales_list(VARCHAR(50), VARCHAR(50), VARCHAR(15), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_conceptos_legales_list(
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT NULL,
  p_tipo VARCHAR(15) DEFAULT NULL,
  p_activo BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
  "Id" BIGINT,
  "Convencion" VARCHAR,
  "TipoCalculo" VARCHAR,
  "CO_CONCEPT" VARCHAR,
  "NB_CONCEPTO" VARCHAR,
  "Formula" TEXT,
  "SOBRE" TEXT,
  "TIPO" VARCHAR,
  "BONIFICABLE" VARCHAR(1),
  "LOTTT_Articulo" VARCHAR,
  "CCP_Clausula" VARCHAR,
  "Orden" INT,
  "Activo" BOOLEAN,
  "CO_NOMINA" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    pc."PayrollConceptId" AS "Id",
    pc."ConventionCode" AS "Convencion",
    pc."CalculationType" AS "TipoCalculo",
    pc."ConceptCode" AS "CO_CONCEPT",
    pc."ConceptName" AS "NB_CONCEPTO",
    pc."Formula"::TEXT AS "Formula",
    pc."BaseExpression"::TEXT AS "SOBRE",
    pc."ConceptType" AS "TIPO",
    CASE WHEN pc."IsBonifiable" = TRUE THEN 'S'::VARCHAR(1) ELSE 'N'::VARCHAR(1) END AS "BONIFICABLE",
    pc."LotttArticle" AS "LOTTT_Articulo",
    pc."CcpClause" AS "CCP_Clausula",
    pc."SortOrder" AS "Orden",
    pc."IsActive" AS "Activo",
    pc."PayrollCode" AS "CO_NOMINA"
  FROM hr."PayrollConcept" pc
  WHERE pc."ConventionCode" IS NOT NULL
    AND (p_convencion IS NULL OR pc."ConventionCode" = p_convencion)
    AND (p_tipo_calculo IS NULL OR pc."CalculationType" = p_tipo_calculo)
    AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
    AND (p_activo IS NULL OR pc."IsActive" = p_activo)
  ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ValidarFormulasConceptoLegal
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_validar_formulas_concepto_legal(VARCHAR(50), VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_validar_formulas_concepto_legal(
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
  "Id" BIGINT,
  "CO_CONCEPT" VARCHAR,
  "NB_CONCEPTO" VARCHAR,
  "FORMULA" TEXT,
  "Error" VARCHAR(500),
  "EsValida" BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
  rec RECORD;
  v_result NUMERIC(18,6);
  v_formula_resuelta TEXT;
  v_session_test VARCHAR(80) := 'TEST_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');
BEGIN
  -- Crear tabla temporal para resultados
  CREATE TEMP TABLE IF NOT EXISTS tmp_resultados (
    "Id" BIGINT,
    "CO_CONCEPT" VARCHAR(20),
    "NB_CONCEPTO" VARCHAR(120),
    "FORMULA" TEXT,
    "Error" VARCHAR(500),
    "EsValida" BOOLEAN
  ) ON COMMIT DROP;

  DELETE FROM tmp_resultados;

  PERFORM sp_nomina_limpiar_variables(v_session_test);
  PERFORM sp_nomina_set_variable(v_session_test, 'SUELDO', 30000, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'SALARIO_DIARIO', 1000, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'DIAS_PERIODO', 30, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'PCT_SSO', 0.04, 'Test');

  FOR rec IN
    SELECT "PayrollConceptId", "ConceptCode", "ConceptName", "Formula"
    FROM hr."PayrollConcept"
    WHERE "ConventionCode" IS NOT NULL
      AND (p_convencion IS NULL OR "ConventionCode" = p_convencion)
      AND (p_tipo_calculo IS NULL OR "CalculationType" = p_tipo_calculo)
      AND "IsActive" = TRUE
    ORDER BY "ConventionCode", "CalculationType", "SortOrder", "ConceptCode"
  LOOP
    IF rec."Formula" IS NULL OR TRIM(rec."Formula") = '' THEN
      INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", 'Sin formula (usa valor por defecto)', TRUE);
    ELSIF rec."Formula" ~ '[^A-Za-z0-9_\.+\-\*/\(\) ]' THEN
      INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", 'Contiene caracteres no permitidos', FALSE);
    ELSE
      BEGIN
        SELECT r.p_resultado, r.p_formula_resuelta
        INTO v_result, v_formula_resuelta
        FROM sp_nomina_evaluar_formula(v_session_test, rec."Formula") r;

        INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", NULL, TRUE);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", SQLERRM, FALSE);
      END;
    END IF;
  END LOOP;

  PERFORM sp_nomina_limpiar_variables(v_session_test);

  RETURN QUERY SELECT t."Id", t."CO_CONCEPT", t."NB_CONCEPTO", t."FORMULA", t."Error", t."EsValida"
  FROM tmp_resultados t
  ORDER BY t."EsValida" ASC, t."CO_CONCEPT";
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_conceptolegal_crud.sql

-- ============================================================================
-- sp_nomina_conceptolegal_crud.sql
-- Funciones PostgreSQL para conceptos legales de nÃ³mina
-- Equivalentes a usp_HR_LegalConcept_* en SQL Server (usp_misc.sql)
-- ============================================================================

-- =============================================================================
-- 1. usp_HR_LegalConcept_List
--    Lista conceptos legales con filtros opcionales.
-- =============================================================================
-- Nuclear drop: query pg_proc to find ALL overloads and drop them
-- +goose StatementBegin
DO $$
DECLARE _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'usp_hr_legalconcept_list'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $$;
-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_list(
    p_company_id       INT,
    p_convention_code  VARCHAR  DEFAULT NULL,
    p_calculation_type VARCHAR  DEFAULT NULL,
    p_concept_type     VARCHAR  DEFAULT NULL,
    p_solo_activos     INT      DEFAULT 1
)
RETURNS TABLE(
    "id"            BIGINT,
    "convencion"    VARCHAR,
    "tipoCalculo"   VARCHAR,
    "coConcept"     VARCHAR,
    "nbConcepto"    VARCHAR,
    "formula"       VARCHAR,
    "sobre"         VARCHAR,
    "tipo"          VARCHAR,
    "bonificable"   VARCHAR,
    "lotttArticulo" VARCHAR,
    "ccpClausula"   VARCHAR,
    "orden"         INT,
    "activo"        BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."PayrollConceptId"::BIGINT,
        c."ConventionCode"::VARCHAR,
        c."CalculationType"::VARCHAR,
        c."ConceptCode"::VARCHAR,
        c."ConceptName"::VARCHAR,
        c."Formula"::VARCHAR,
        c."BaseExpression"::VARCHAR,
        c."ConceptType"::VARCHAR,
        CASE WHEN c."IsBonifiable" THEN 'S' ELSE 'N' END::VARCHAR,
        c."LotttArticle"::VARCHAR,
        c."CcpClause"::VARCHAR,
        c."SortOrder"::INT,
        c."IsActive"
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."ConventionCode" IS NOT NULL
      AND (p_solo_activos = 0 OR c."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR c."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR c."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR c."ConceptType" = p_concept_type)
    ORDER BY c."ConventionCode", c."CalculationType", c."SortOrder", c."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 2. usp_HR_LegalConcept_ValidateFormulas
--    Retorna conceptos activos con su formula y default para validaciÃ³n.
-- =============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_validateformulas(INT, VARCHAR(30), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_validateformulas(
    p_company_id       INT,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL
)
RETURNS TABLE(
    "coConcept"    VARCHAR(20),
    "nbConcepto"   VARCHAR(120),
    "formula"      VARCHAR(500),
    "defaultValue" NUMERIC(18,4)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."ConceptCode",
        c."ConceptName",
        c."Formula",
        c."DefaultValue"
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."ConventionCode" IS NOT NULL
      AND c."IsActive" = TRUE
      AND (p_convention_code IS NULL OR c."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR c."CalculationType" = p_calculation_type)
    ORDER BY c."SortOrder", c."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. usp_HR_LegalConcept_ListConventions
--    Resumen de convenciones disponibles con conteo por tipo de cÃ¡lculo.
-- =============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_listconventions(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_listconventions(
    p_company_id INT
)
RETURNS TABLE(
    "Convencion"            VARCHAR(50),
    "TotalConceptos"        BIGINT,
    "ConceptosMensual"      BIGINT,
    "ConceptosVacaciones"   BIGINT,
    "ConceptosLiquidacion"  BIGINT,
    "OrdenInicio"           INT,
    "OrdenFin"              INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."ConventionCode",
        COUNT(1),
        COUNT(CASE WHEN c."CalculationType" = 'MENSUAL' THEN 1 END),
        COUNT(CASE WHEN c."CalculationType" = 'VACACIONES' THEN 1 END),
        COUNT(CASE WHEN c."CalculationType" = 'LIQUIDACION' THEN 1 END),
        MIN(c."SortOrder"),
        MAX(c."SortOrder")
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsActive" = TRUE
      AND c."ConventionCode" IS NOT NULL
    GROUP BY c."ConventionCode"
    ORDER BY c."ConventionCode";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN RAISE NOTICE 'sp_nomina_conceptolegal_crud.sql â€” funciones creadas'; END $$;
-- +goose StatementEnd


-- Source: sp_nomina_constantes_convenios.sql

-- =============================================
-- SEMILLA DE CONCEPTOS POR CONVENIO (CANONICO) - PostgreSQL
-- Tabla objetivo: hr."PayrollConcept"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- +goose StatementBegin
DO $$
DECLARE
  v_company_id INT;
BEGIN
  SELECT "CompanyId" INTO v_company_id
  FROM cfg."Company"
  WHERE "IsDeleted" = FALSE
  ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para sembrar conceptos nomina';
  END IF;

  -- Seed PayrollType
  INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedAt", "UpdatedAt")
  VALUES
    (v_company_id, 'LOT', 'Nomina LOTTT', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PETRO', 'Nomina CCT Petrolero', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'CONST', 'Nomina Construccion', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "PayrollCode") DO UPDATE SET
    "PayrollName" = EXCLUDED."PayrollName",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  -- Seed PayrollConcept
  -- LOTTT mensual
  INSERT INTO hr."PayrollConcept" (
    "CompanyId", "PayrollCode", "ConceptCode", "ConceptName", "Formula", "BaseExpression",
    "ConceptClass", "ConceptType", "UsageType", "IsBonifiable", "IsSeniority",
    "AccountingAccountCode", "AppliesFlag", "DefaultValue", "ConventionCode",
    "CalculationType", "LotttArticle", "CcpClause", "SortOrder", "IsActive",
    "CreatedAt", "UpdatedAt"
  )
  VALUES
    (v_company_id, 'LOT', 'ASIG_BASE', 'Salario base mensual', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_FAOV', 'Deduccion FAOV', 'TOTAL_ASIGNACIONES * PCT_FAOV', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 91, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_LRPE', 'Deduccion LRPE', 'SUELDO * PCT_LRPE', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 92, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT vacaciones
    (v_company_id, 'LOT', 'VAC_PAGO', 'Pago vacaciones', 'SALARIO_DIARIO * DIAS_VACACIONES', NULL,
     'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'VACACIONES', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'VAC_BONO', 'Bono vacacional', 'SALARIO_DIARIO * DIAS_BONO_VAC', NULL,
     'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'VACACIONES', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT liquidacion
    (v_company_id, 'LOT', 'LIQ_PREST', 'Prestaciones', 'SALARIO_DIARIO * PREST_DIAS_ANIO', NULL,
     'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'LIQUIDACION', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'LIQ_VAC', 'Vacaciones pendientes', 'SALARIO_DIARIO * DIAS_VACACIONES_BASE', NULL,
     'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'LIQUIDACION', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Petrolero mensual
    (v_company_id, 'PETRO', 'ASIG_BASE', 'Salario base mensual petrolero', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'PETRO', 'BONO_PETRO', 'Bono petrolero', 'SALARIO_DIARIO * 10', NULL,
     'BONO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'PETRO', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Construccion mensual
    (v_company_id, 'CONST', 'ASIG_BASE', 'Salario base construccion', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'CONST', 'BONO_CONST', 'Bono construccion', 'SALARIO_DIARIO * 5', NULL,
     'BONO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'CONST', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')

  ON CONFLICT ("CompanyId", "PayrollCode", "ConceptCode", "ConventionCode", "CalculationType")
  DO UPDATE SET
    "ConceptName" = EXCLUDED."ConceptName",
    "Formula" = EXCLUDED."Formula",
    "BaseExpression" = NULL,
    "ConceptClass" = EXCLUDED."ConceptClass",
    "ConceptType" = EXCLUDED."ConceptType",
    "UsageType" = 'T',
    "IsBonifiable" = CASE WHEN EXCLUDED."ConceptType" = 'ASIGNACION' THEN TRUE ELSE FALSE END,
    "IsSeniority" = FALSE,
    "AccountingAccountCode" = NULL,
    "AppliesFlag" = TRUE,
    "DefaultValue" = EXCLUDED."DefaultValue",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Conceptos por convenio sembrados/actualizados en hr.PayrollConcept';
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_constantes_venezuela.sql

-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_nomina_constantes_venezuela.sql
-- Semilla de constantes nómina Venezuela (canónico).
-- Inserta o actualiza constantes en hr.PayrollConstant.
-- ============================================================

-- +goose StatementBegin
DO $$
DECLARE
    v_company_id INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'No existe cfg.Company activa para sembrar constantes nómina';
    END IF;

    -- Usar INSERT ... ON CONFLICT para simular MERGE
    -- Primero crear tabla temporal con los datos fuente
    CREATE TEMP TABLE tmp_constantes_ve (
        "ConstantCode"  VARCHAR(50),
        "ConstantName"  VARCHAR(120),
        "ConstantValue" NUMERIC(18,6),
        "SourceName"    VARCHAR(80)
    ) ON COMMIT DROP;

    INSERT INTO tmp_constantes_ve VALUES
        ('SALARIO_DIARIO',              'Salario diario base',                    0.000000,   'VE_BASE'),
        ('HORAS_MES',                   'Horas laborales mensuales',            240.000000,   'VE_BASE'),
        ('PCT_SSO',                     'Porcentaje SSO empleado',                0.040000,   'VE_BASE'),
        ('PCT_FAOV',                    'Porcentaje FAOV empleado',               0.010000,   'VE_BASE'),
        ('PCT_LRPE',                    'Porcentaje LRPE empleado',               0.005000,   'VE_BASE'),
        ('RECARGO_HE',                  'Recargo hora extra',                     1.500000,   'VE_BASE'),
        ('RECARGO_NOCTURNO',            'Recargo nocturno',                       1.300000,   'VE_BASE'),
        ('RECARGO_DESCANSO',            'Recargo descanso trabajado',             1.500000,   'VE_BASE'),
        ('RECARGO_FERIADO',             'Recargo feriado trabajado',              2.000000,   'VE_BASE'),
        ('DIAS_VACACIONES_BASE',        'Días vacaciones base',                  15.000000,   'VE_BASE'),
        ('DIAS_BONO_VAC_BASE',          'Días bono vacacional base',             15.000000,   'VE_BASE'),
        ('DIAS_UTILIDADES_MIN',         'Días utilidades mínimo',                30.000000,   'VE_BASE'),
        ('DIAS_UTILIDADES_MAX',         'Días utilidades máximo',               120.000000,   'VE_BASE'),
        ('PREST_DIAS_ANIO',             'Días prestaciones por año',             30.000000,   'VE_BASE'),
        ('PREST_INTERES_ANUAL',         'Interés anual prestaciones',             0.150000,   'VE_BASE'),

        ('LOT_DIAS_VACACIONES_BASE',    'LOTTT: días vacaciones base',           15.000000,   'REGIMEN:LOT'),
        ('LOT_DIAS_BONO_VAC_BASE',      'LOTTT: días bono vacacional base',      15.000000,   'REGIMEN:LOT'),
        ('LOT_DIAS_UTILIDADES',          'LOTTT: días utilidades referencia',     30.000000,   'REGIMEN:LOT'),

        ('PETRO_DIAS_VACACIONES_BASE',  'Petrolero: días vacaciones base',       34.000000,   'REGIMEN:PETRO'),
        ('PETRO_DIAS_BONO_VAC_BASE',    'Petrolero: bono vacacional base',       55.000000,   'REGIMEN:PETRO'),
        ('PETRO_DIAS_UTILIDADES',        'Petrolero: días utilidades',           120.000000,   'REGIMEN:PETRO'),

        ('CONST_DIAS_VACACIONES_BASE',  'Construcción: días vacaciones base',    20.000000,   'REGIMEN:CONST'),
        ('CONST_DIAS_BONO_VAC_BASE',    'Construcción: bono vacacional base',    30.000000,   'REGIMEN:CONST'),
        ('CONST_DIAS_UTILIDADES',        'Construcción: días utilidades',         60.000000,   'REGIMEN:CONST');

    -- Actualizar existentes
    UPDATE hr."PayrollConstant" pc
    SET "ConstantName"  = src."ConstantName",
        "ConstantValue" = src."ConstantValue",
        "SourceName"    = src."SourceName",
        "IsActive"      = TRUE,
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    FROM tmp_constantes_ve src
    WHERE pc."CompanyId"    = v_company_id
      AND pc."ConstantCode" = src."ConstantCode";

    -- Insertar nuevos
    INSERT INTO hr."PayrollConstant"
        ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName",
         "IsActive", "CreatedAt", "UpdatedAt")
    SELECT
        v_company_id,
        src."ConstantCode",
        src."ConstantName",
        src."ConstantValue",
        src."SourceName",
        TRUE,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM tmp_constantes_ve src
    WHERE NOT EXISTS (
        SELECT 1 FROM hr."PayrollConstant" pc
        WHERE pc."CompanyId" = v_company_id
          AND pc."ConstantCode" = src."ConstantCode"
    );

    RAISE NOTICE 'Constantes de nómina Venezuela sembradas/actualizadas en hr.PayrollConstant';
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_consultas.sql

-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_nomina_consultas.sql
-- Consultas nÃ³mina (canÃ³nico): conceptos, nÃ³minas, vacaciones,
-- liquidaciones, constantes.
-- ============================================================

-- =============================================
-- sp_Nomina_Conceptos_List
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Concepto_Save
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_List
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Get (devuelve cabecera + detalle como dos result sets)
-- En PostgreSQL se usa SETOF RECORD o dos funciones separadas.
-- AquÃ­ usamos la cabecera; el detalle se obtiene con sp_Nomina_Get_Lines.
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Get_Lines (detalle de lÃ­neas de la nÃ³mina)
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Cerrar
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Vacaciones_List
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Vacaciones_Get (cabecera)
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Vacaciones_Get_Lines (detalle de lÃ­neas de vacaciones)
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Liquidaciones_List
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Constantes_List
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- =============================================
-- sp_Nomina_Constante_Save
-- =============================================
-- +goose StatementBegin
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
-- +goose StatementEnd


-- Source: sp_nomina_documentos.sql

-- =============================================
-- Archivo  : sp_nomina_documentos.sql
-- PropÃ³sito: Plantillas de Documentos de NÃ³mina (PostgreSQL)
-- Tabla    : hr."DocumentTemplate"
-- Origen   : ConversiÃ³n desde T-SQL (SQL Server 2012 compatible)
-- Fecha    : 2026-03-16
-- =============================================

CREATE SCHEMA IF NOT EXISTS hr;

-- =============================================
-- 1. TABLA hr."DocumentTemplate"
-- =============================================
CREATE TABLE IF NOT EXISTS hr."DocumentTemplate" (
    "TemplateId"   SERIAL        NOT NULL CONSTRAINT "PK_DocumentTemplate" PRIMARY KEY,
    "CompanyId"    INTEGER       NOT NULL,
    "TemplateCode" VARCHAR(80)   NOT NULL,
    "TemplateName" VARCHAR(200)  NOT NULL,
    "TemplateType" VARCHAR(40)   NOT NULL,
    "CountryCode"  CHAR(2)       NOT NULL,
    "PayrollCode"  VARCHAR(20)   NULL,
    "ContentMD"    TEXT          NOT NULL,
    "IsDefault"    BOOLEAN       NOT NULL DEFAULT TRUE,
    "IsSystem"     BOOLEAN       NOT NULL DEFAULT FALSE,
    "IsActive"     BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedAt"    TIMESTAMP(3)  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"    TIMESTAMP(3)  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_DocumentTemplate_Code" UNIQUE ("CompanyId", "TemplateCode")
);

-- Agregar columna IsSystem si la tabla ya existe sin ella (migraciÃ³n)
-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'hr'
          AND table_name   = 'DocumentTemplate'
          AND column_name  = 'IsSystem'
    ) THEN
        ALTER TABLE hr."DocumentTemplate"
            ADD COLUMN "IsSystem" BOOLEAN NOT NULL DEFAULT FALSE;
        RAISE NOTICE '>> Columna IsSystem agregada a hr.DocumentTemplate';
    END IF;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 2. FUNCIONES (equivalentes a los SPs)
-- =============================================

-- Nuclear drop: eliminar TODAS las sobrecargas por OID para evitar
-- el error "function is not unique" que ocurre cuando conviven
-- sobrecargas con firmas (CHAR vs VARCHAR) diferentes.
-- +goose StatementBegin
DO $do$
DECLARE _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname IN (
      'usp_hr_documenttemplate_list',
      'usp_hr_documenttemplate_get',
      'usp_hr_documenttemplate_save',
      'usp_hr_documenttemplate_delete'
    )
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $do$;
-- +goose StatementEnd

-- --------------------------------------------
-- usp_HR_DocumentTemplate_List
-- Firma canÃ³nica: (INT, VARCHAR, VARCHAR) â€” sin CHAR, sin tamaÃ±o
-- --------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_list(
    p_company_id    INT,
    p_country_code  VARCHAR DEFAULT NULL,
    p_template_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "TemplateId"   BIGINT,
    "TemplateCode" VARCHAR,
    "TemplateName" VARCHAR,
    "TemplateType" VARCHAR,
    "CountryCode"  VARCHAR,
    "PayrollCode"  VARCHAR,
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId"::BIGINT,
        t."TemplateCode"::VARCHAR,
        t."TemplateName"::VARCHAR,
        t."TemplateType"::VARCHAR,
        t."CountryCode"::VARCHAR,
        t."PayrollCode"::VARCHAR,
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."UpdatedAt"::TIMESTAMP
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id
      AND t."IsActive"  = TRUE
      AND (p_country_code  IS NULL OR t."CountryCode"  = p_country_code)
      AND (p_template_type IS NULL OR t."TemplateType" = p_template_type)
    ORDER BY t."CountryCode", t."TemplateType", t."TemplateName";
END;
$$;
-- +goose StatementEnd


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Get
-- --------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(
    p_company_id    INT,
    p_template_code VARCHAR
)
RETURNS TABLE(
    "TemplateId"   BIGINT,
    "TemplateCode" VARCHAR,
    "TemplateName" VARCHAR,
    "TemplateType" VARCHAR,
    "CountryCode"  VARCHAR,
    "PayrollCode"  VARCHAR,
    "ContentMD"    TEXT,
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "CreatedAt"    TIMESTAMP,
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId"::BIGINT,
        t."TemplateCode"::VARCHAR,
        t."TemplateName"::VARCHAR,
        t."TemplateType"::VARCHAR,
        t."CountryCode"::VARCHAR,
        t."PayrollCode"::VARCHAR,
        t."ContentMD",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."CreatedAt"::TIMESTAMP,
        t."UpdatedAt"::TIMESTAMP
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId"    = p_company_id
      AND t."TemplateCode" = p_template_code;
END;
$$;
-- +goose StatementEnd


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Save
-- --------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_save(
    p_company_id    INT,
    p_template_code VARCHAR,
    p_template_name VARCHAR,
    p_template_type VARCHAR,
    p_country_code  VARCHAR,
    p_content_md    TEXT,
    p_payroll_code  VARCHAR DEFAULT NULL,
    p_is_default    BOOLEAN DEFAULT FALSE,
    OUT p_resultado INT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := ''::VARCHAR;

    -- Proteger plantillas del sistema
    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede modificar una plantilla del sistema.'::VARCHAR;
        RETURN;
    END IF;

    -- MERGE equivalente en PostgreSQL usando INSERT ... ON CONFLICT
    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault",
        "IsSystem", "IsActive", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_template_code, p_template_name, p_template_type,
        p_country_code, p_payroll_code, p_content_md, COALESCE(p_is_default, FALSE),
        FALSE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = EXCLUDED."TemplateName",
        "TemplateType" = EXCLUDED."TemplateType",
        "CountryCode"  = EXCLUDED."CountryCode",
        "PayrollCode"  = EXCLUDED."PayrollCode",
        "ContentMD"    = EXCLUDED."ContentMD",
        "IsDefault"    = EXCLUDED."IsDefault",
        "IsSystem"     = FALSE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    p_resultado := 1;
    p_mensaje   := 'Plantilla guardada correctamente.'::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Delete
-- --------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_delete(
    p_company_id    INT,
    p_template_code VARCHAR,
    OUT p_resultado INT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := ''::VARCHAR;

    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede eliminar una plantilla del sistema.'::VARCHAR;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Plantilla no encontrada.'::VARCHAR;
        RETURN;
    END IF;

    DELETE FROM hr."DocumentTemplate"
    WHERE "CompanyId"    = p_company_id
      AND "TemplateCode" = p_template_code;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.'::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- =============================================
-- 3. SEED â€” Plantillas legales (IsSystem=TRUE)
-- =============================================
-- +goose StatementBegin
DO $$
DECLARE
    v_seed_company_id INTEGER;
    v_md1 TEXT;
    v_md2 TEXT;
    v_md3 TEXT;
    v_md4 TEXT;
    v_md5 TEXT;
    v_md6 TEXT;
BEGIN
    SELECT "CompanyId"
    INTO v_seed_company_id
    FROM cfg."Company"
    WHERE "IsActive" = TRUE
    ORDER BY "CompanyId"
    LIMIT 1;

    IF v_seed_company_id IS NULL THEN
        RAISE NOTICE '>> SEED: No hay empresa activa en cfg.Company â€” omitiendo seed de plantillas.';
        RETURN;
    END IF;

    -- -----------------------------------------------
    -- PLANTILLA 1: VE_RECIBO_PAGO
    -- -----------------------------------------------
    v_md1 := '# RECIBO DE PAGO DE NÃ“MINA

> **Base Legal:** LOTTT Art. 104 | **RepÃºblica Bolivariana de Venezuela**

---

## Datos del Empleador

| Campo | Valor |
|:------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| DirecciÃ³n | {{empresa.direccion}} |
| Representante Legal | {{empresa.representante}} |

## Datos del Trabajador

| Campo | Valor |
|:------|:------|
| Nombre Completo | {{empleado.nombre}} |
| CÃ©dula de Identidad | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Departamento | {{empleado.departamento}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Tipo de NÃ³mina | {{nomina.tipo}} |

## PerÃ­odo de Pago

| Desde | Hasta | Frecuencia |
|:------|:------|:-----------|
| {{periodo.desde}} | {{periodo.hasta}} | {{periodo.tipo}} |

## Detalle de Asignaciones

{{tabla_asignaciones}}

## Deducciones Legales

{{tabla_deducciones}}

---

## Resumen

| Concepto | Monto (Bs.) |
|:---------|------------:|
| **Total Asignaciones** | **{{nomina.totalAsignaciones}}** |
| **Total Deducciones** | **{{nomina.totalDeducciones}}** |
| **NETO A PAGAR** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, portador(a) de la C.I. NÂ° {{empleado.cedula}}, declaro haber recibido la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) como pago de nÃ³mina correspondiente al perÃ­odo **{{periodo.desde}}** al **{{periodo.hasta}}**.*

*Conforme con lo establecido en el Art. 104 de la Ley OrgÃ¡nica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), este recibo acredita el pago de todos los conceptos descritos.*

&nbsp;

| Firma del Trabajador | Firma del Empleador / Representante |
|:--------------------:|:-----------------------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.nombre}} |

*Generado el {{fecha.generacion}} mediante Sistema DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_RECIBO_PAGO',
        'Recibo de Pago de NÃ³mina â€” LOTTT Art. 104', 'RECIBO_PAGO',
        'VE', NULL, v_md1, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Pago de NÃ³mina â€” LOTTT Art. 104',
        "TemplateType" = 'RECIBO_PAGO',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md1,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 2: VE_RECIBO_VACACIONES
    -- -----------------------------------------------
    v_md2 := '# RECIBO DE DISFRUTE Y PAGO DE VACACIONES

> **Base Legal:** LOTTT Arts. 190, 191, 192 y 219 | **RepÃºblica Bolivariana de Venezuela**

---

## IdentificaciÃ³n

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **CÃ©dula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |

## PerÃ­odo Vacacional

| Concepto | Valor |
|:---------|:------|
| PerÃ­odo de trabajo que origina las vacaciones | {{periodo.desde}} al {{periodo.hasta}} |
| DÃ­as de vacaciones (LOTTT Art. 190) | {{concepto.VAC_PAGO.cantidad}} dÃ­as |
| DÃ­as de bono vacacional (LOTTT Art. 192) | {{concepto.VAC_BONO.cantidad}} dÃ­as |
| **Total dÃ­as de disfrute** | {{concepto.DIAS_TOTALES_VAC}} dÃ­as |

## CÃ¡lculo

{{tabla_todos}}

---

## Resumen

| Concepto | Monto (Bs.) |
|:---------|------------:|
| Pago de Vacaciones | {{concepto.VAC_PAGO.monto}} |
| Bono Vacacional | {{concepto.VAC_BONO.monto}} |
| **Total a Pagar** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. NÂ° {{empleado.cedula}}, recibo conforme la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) por concepto de vacaciones y bono vacacional del perÃ­odo {{periodo.desde}} al {{periodo.hasta}}, segÃºn lo establecido en los Arts. 190 y 192 de la LOTTT.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_RECIBO_VACACIONES',
        'Recibo de Vacaciones â€” LOTTT Arts. 190-192', 'RECIBO_VAC',
        'VE', NULL, v_md2, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Vacaciones â€” LOTTT Arts. 190-192',
        "TemplateType" = 'RECIBO_VAC',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md2,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 3: VE_PARTICIPACION_GANANCIAS
    -- -----------------------------------------------
    v_md3 := '# PLANILLA DE PARTICIPACIÃ“N EN LAS GANANCIAS (UTILIDADES)

> **Base Legal:** LOTTT Arts. 131, 132 y 133 | **Ejercicio Fiscal {{anio}}**

---

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **CÃ©dula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |
| **Fecha de Ingreso** | {{empleado.fechaIngreso}} |

## Base de CÃ¡lculo (LOTTT Art. 131)

| Concepto | Monto |
|:---------|------:|
| Salario Diario Normal | {{concepto.SALARIO_DIARIO.monto}} |
| DÃ­as de Utilidades (mÃ­nimo 30, mÃ¡ximo 120) | {{concepto.DIAS_UTILIDADES.cantidad}} |
| **Total Utilidades** | **{{nomina.neto}}** |

*Las utilidades fueron calculadas sobre el salario normal devengado durante el aÃ±o. El porcentaje mÃ­nimo garantizado es equivalente a **30 dÃ­as de salario** segÃºn el Art. 131 LOTTT.*

---

## CertificaciÃ³n

*La empresa **{{empresa.nombre}}**, RIF {{empresa.rif}}, certifica haber pagado a **{{empleado.nombre}}**, C.I. {{empleado.cedula}}, la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) correspondiente a la ParticipaciÃ³n en las Ganancias del ejercicio {{anio}}, en cumplimiento del Art. 131 de la LOTTT.*

| Recibido Conforme | Representante Empresa |
|:-----------------:|:---------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.nombre}} |

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_PARTICIPACION_GANANCIAS',
        'ParticipaciÃ³n en las Ganancias (Utilidades) â€” LOTTT Art. 131', 'UTILIDADES',
        'VE', NULL, v_md3, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'ParticipaciÃ³n en las Ganancias (Utilidades) â€” LOTTT Art. 131',
        "TemplateType" = 'UTILIDADES',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md3,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 4: VE_LIQUIDACION
    -- -----------------------------------------------
    v_md4 := '# PLANILLA DE LIQUIDACIÃ“N DE PRESTACIONES SOCIALES

> **Base Legal:** LOTTT Arts. 92, 142, 143 y 144 | **RepÃºblica Bolivariana de Venezuela**

---

## Datos de la RelaciÃ³n Laboral

| Concepto | Valor |
|:---------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| Trabajador | {{empleado.nombre}} |
| CÃ©dula | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Fecha de Egreso | {{periodo.hasta}} |
| Causa de TerminaciÃ³n | {{liquidacion.causa}} |
| Tiempo de Servicio | {{empleado.antiguedad}} |

## CÃ¡lculo de Prestaciones y Beneficios

{{tabla_todos}}

---

## Resumen de LiquidaciÃ³n (LOTTT Art. 142)

| Concepto | Monto (Bs.) |
|:---------|------------:|
| GarantÃ­a de Prestaciones Sociales | {{concepto.LIQ_PREST.monto}} |
| Vacaciones Fraccionadas | {{concepto.LIQ_VAC.monto}} |
| Utilidades Fraccionadas | {{concepto.LIQ_UTIL.monto}} |
| Otros Beneficios | {{concepto.LIQ_OTROS.monto}} |
| **TOTAL LIQUIDACIÃ“N** | **{{nomina.totalAsignaciones}}** |
| Deducciones | {{nomina.totalDeducciones}} |
| **NETO A PAGAR** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. NÂ° {{empleado.cedula}}, DECLARO haber recibido de la empresa **{{empresa.nombre}}** la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) en PAGO TOTAL Y DEFINITIVO de todos y cada uno de los conceptos derivados de la relaciÃ³n laboral que me uniÃ³ con dicha empresa desde el {{empleado.fechaIngreso}} hasta el {{periodo.hasta}}, quedando a ambas partes libre de todo compromiso laboral.*

*Este pago incluye todos los beneficios establecidos en la Ley OrgÃ¡nica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), el contrato colectivo vigente y la legislaciÃ³n aplicable.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.rif}} |

*Ante Notario PÃºblico / Inspector del Trabajo si aplica*

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_LIQUIDACION',
        'LiquidaciÃ³n de Prestaciones Sociales â€” LOTTT Arts. 142-143', 'LIQUIDACION',
        'VE', NULL, v_md4, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'LiquidaciÃ³n de Prestaciones Sociales â€” LOTTT Arts. 142-143',
        "TemplateType" = 'LIQUIDACION',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md4,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 5: ES_NOMINA_OFICIAL
    -- -----------------------------------------------
    v_md5 := '# RECIBO DE SALARIOS (NÃ“MINA)

> **Base Legal:** RD 1784/1996 art. 2 | **Reino de EspaÃ±a**

---

## I. DATOS DE LA EMPRESA Y TRABAJADOR

| Empresa | CIF/NIF | Centro de Trabajo |
|:--------|:--------|:------------------|
| {{empresa.nombre}} | {{empresa.rif}} | {{empresa.direccion}} |

| Trabajador | NIF | N.Â° S.S. | CategorÃ­a / Grupo Prof. | AntigÃ¼edad |
|:-----------|:----|:---------|:------------------------|:-----------|
| {{empleado.nombre}} | {{empleado.cedula}} | {{empleado.nss}} | {{empleado.cargo}} | {{empleado.fechaIngreso}} |

**PerÃ­odo de liquidaciÃ³n:** Del {{periodo.desde}} al {{periodo.hasta}}

---

## II. DEVENGOS

{{tabla_asignaciones}}

**TOTAL DEVENGOS** | **{{nomina.totalAsignaciones}} â‚¬**

---

## III. DEDUCCIONES

{{tabla_deducciones}}

**TOTAL DEDUCCIONES** | **{{nomina.totalDeducciones}} â‚¬**

---

## IV. BASES DE COTIZACIÃ“N A LA SEGURIDAD SOCIAL

| Base Contingencias Comunes | Base A.T. y E.P. | Base Horas Extra F.M. | Base H.E. Voluntarias |
|---------------------------:|------------------:|----------------------:|----------------------:|
| {{es.baseCC}} â‚¬ | {{es.baseAT}} â‚¬ | {{es.baseHEFM}} â‚¬ | {{es.baseHEV}} â‚¬ |

| Cuota Obrero S.S. | RetenciÃ³n IRPF | Otras Deducciones |
|------------------:|---------------:|------------------:|
| {{concepto.DED_SS_CC.monto}} + {{concepto.DED_SS_DESEMP.monto}} + {{concepto.DED_SS_FP.monto}} â‚¬ | {{concepto.DED_IRPF.monto}} â‚¬ | â€” |

---

## V. LÃQUIDO A PERCIBIR

| Total Devengos | â€” | Total Deducciones | = | **LÃQUIDO A PERCIBIR** |
|---------------:|:-:|------------------:|:-:|:----------------------:|
| {{nomina.totalAsignaciones}} â‚¬ | â€” | {{nomina.totalDeducciones}} â‚¬ | = | **{{nomina.neto}} â‚¬** |

*Firma y sello de la empresa:* _________________________ *RecibÃ­:* _________________________

*{{empresa.nombre}} â€” {{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_NOMINA_OFICIAL',
        'NÃ³mina Oficial â€” RD 1784/1996 EspaÃ±a', 'NOMINA_ES',
        'ES', NULL, v_md5, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'NÃ³mina Oficial â€” RD 1784/1996 EspaÃ±a',
        "TemplateType" = 'NOMINA_ES',
        "CountryCode"  = 'ES',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md5,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 6: ES_FINIQUITO
    -- -----------------------------------------------
    v_md6 := '# FINIQUITO DE RELACIÃ“N LABORAL

> **Base Legal:** Estatuto de los Trabajadores Art. 49 | **Reino de EspaÃ±a**

---

En **{{empresa.direccion}}**, a {{fecha.generacion}},

**De una parte:** La empresa **{{empresa.nombre}}**, con CIF {{empresa.rif}}, representada por **{{empresa.representante}}**.

**De otra parte:** D./DÃ±a. **{{empleado.nombre}}**, con NIF {{empleado.cedula}}, que ha prestado sus servicios en calidad de **{{empleado.cargo}}**.

---

## Hechos

1. La relaciÃ³n laboral entre las partes dio comienzo el dÃ­a **{{empleado.fechaIngreso}}** y se extingue el **{{periodo.hasta}}**.
2. La causa de extinciÃ³n del contrato es: **{{liquidacion.causa}}**.
3. El trabajador ha prestado sus servicios a jornada **{{empleado.tipoJornada}}**.

## LiquidaciÃ³n

{{tabla_todos}}

| Concepto | Importe (â‚¬) |
|:---------|------------:|
| **Total Devengado** | **{{nomina.totalAsignaciones}}** |
| Retenciones e impuestos | {{nomina.totalDeducciones}} |
| **TOTAL LÃQUIDO** | **{{nomina.neto}}** |

---

## DeclaraciÃ³n

*Con la percepciÃ³n de la cantidad de **{{nomina.neto}} â‚¬** ({{nomina.netoLetras}}), el trabajador/a declara quedar **saldado/a y finiquitado/a** de cuantos derechos y acciones pudieran corresponderle derivados de la relaciÃ³n laboral extinguida, incluyendo salarios, vacaciones, pagas extraordinarias, indemnizaciones y cualquier otro concepto.*

*El trabajador/a dispone de un plazo de 3 dÃ­as para solicitar la presencia de un representante sindical antes de la firma.*

---

| El Trabajador | La Empresa |
|:-------------:|:----------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| NIF: {{empleado.cedula}} | {{empresa.nombre}} |

*DatqBox â€” Sistema de GestiÃ³n Laboral*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_FINIQUITO',
        'Finiquito de RelaciÃ³n Laboral â€” ET Art. 49 EspaÃ±a', 'FINIQUITO_ES',
        'ES', NULL, v_md6, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Finiquito de RelaciÃ³n Laboral â€” ET Art. 49 EspaÃ±a',
        "TemplateType" = 'FINIQUITO_ES',
        "CountryCode"  = 'ES',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md6,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    RAISE NOTICE '>> SEED: 6 plantillas legales aplicadas OK';

END;
$$;
-- +goose StatementEnd

-- >> sp_nomina_documentos.sql â€” despliegue completo OK


-- Source: sp_nomina_sistema.sql

-- =============================================
-- SISTEMA BASE DE NOMINA (CANONICO) - PostgreSQL
-- Modelo objetivo: hr.* + master."Employee"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."PayrollCalcVariable" (
  "SessionID" VARCHAR(80) NOT NULL,
  "Variable" VARCHAR(120) NOT NULL,
  "Valor" NUMERIC(18,6) NOT NULL DEFAULT 0,
  "Descripcion" VARCHAR(255) NULL,
  "CreatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_PayrollCalcVariable" PRIMARY KEY ("SessionID", "Variable")
);

-- =============================================
-- Funcion: fn_EvaluarExpr
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS fn_evaluar_expr(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION fn_evaluar_expr(p_expr TEXT)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN CAST(p_expr AS NUMERIC(18,6));
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: fn_Nomina_GetVariable
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS fn_nomina_get_variable(VARCHAR(80), VARCHAR(120)) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_get_variable(
  p_session_id VARCHAR(80),
  p_variable VARCHAR(120)
)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
DECLARE
  v_valor NUMERIC(18,6) := 0;
BEGIN
  SELECT "Valor" INTO v_valor
  FROM hr."PayrollCalcVariable"
  WHERE "SessionID" = p_session_id AND "Variable" = p_variable
  LIMIT 1;

  RETURN COALESCE(v_valor, 0);
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: fn_Nomina_ContarFeriados
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS fn_nomina_contar_feriados(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_contar_feriados(
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS INT
LANGUAGE plpgsql AS $$
BEGIN
  -- En DatqBoxWeb canonico no se depende de tabla Feriados legacy.
  -- Se deja en 0 y puede ser reemplazado por catalogo canonico si se incorpora.
  RETURN 0;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: fn_Nomina_ContarDomingos
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS fn_nomina_contar_domingos(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_contar_domingos(
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  v_actual DATE := p_fecha_desde;
  v_domingos INT := 0;
BEGIN
  WHILE v_actual <= p_fecha_hasta LOOP
    IF EXTRACT(DOW FROM v_actual) = 0 THEN
      v_domingos := v_domingos + 1;
    END IF;
    v_actual := v_actual + INTERVAL '1 day';
  END LOOP;

  RETURN v_domingos;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_GetScope
-- Retorna CompanyId y BranchId
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_get_scope(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_get_scope(
  OUT p_company_id INT,
  OUT p_branch_id INT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
  SELECT c."CompanyId" INTO p_company_id
  FROM cfg."Company" c
  WHERE c."IsDeleted" = FALSE
  ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
  LIMIT 1;

  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para nomina';
  END IF;

  SELECT b."BranchId" INTO p_branch_id
  FROM cfg."Branch" b
  WHERE b."CompanyId" = p_company_id
    AND b."IsDeleted" = FALSE
  ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
  LIMIT 1;

  IF p_branch_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Branch activa para nomina';
  END IF;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_LimpiarVariables
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_limpiar_variables(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_limpiar_variables(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_SetVariable
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_set_variable(VARCHAR(80), VARCHAR(120), NUMERIC(18,6), VARCHAR(255)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_set_variable(
  p_session_id VARCHAR(80),
  p_variable VARCHAR(120),
  p_valor NUMERIC(18,6),
  p_descripcion VARCHAR(255) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  VALUES (p_session_id, p_variable, p_valor, p_descripcion)
  ON CONFLICT ("SessionID", "Variable") DO UPDATE SET
    "Valor" = EXCLUDED."Valor",
    "Descripcion" = EXCLUDED."Descripcion",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CargarConstantes
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_cargar_constantes(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  SELECT
    p_session_id,
    pc."ConstantCode",
    pc."ConstantValue",
    pc."ConstantName"
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."IsActive" = TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM hr."PayrollCalcVariable" v
      WHERE v."SessionID" = p_session_id
        AND v."Variable" = pc."ConstantCode"
    );
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularAntiguedad
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_antiguedad(VARCHAR(80), VARCHAR(32), DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_antiguedad(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_calculo DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_fecha_ingreso DATE;
  v_dias INT := 0;
  v_anios INT := 0;
  v_meses INT := 0;
  v_total_meses INT := 0;
  v_fecha_calc DATE;
BEGIN
  v_fecha_calc := COALESCE(p_fecha_calculo, (NOW() AT TIME ZONE 'UTC')::DATE);

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT e."HireDate" INTO v_fecha_ingreso
  FROM master."Employee" e
  WHERE e."CompanyId" = v_company_id
    AND e."EmployeeCode" = p_cedula
    AND e."IsDeleted" = FALSE
  LIMIT 1;

  IF v_fecha_ingreso IS NOT NULL THEN
    v_dias := v_fecha_calc - v_fecha_ingreso;
    v_anios := v_dias / 365;
    v_meses := (v_dias % 365) / 30;
    v_total_meses := EXTRACT(YEAR FROM AGE(v_fecha_calc, v_fecha_ingreso)) * 12
                   + EXTRACT(MONTH FROM AGE(v_fecha_calc, v_fecha_ingreso));
  END IF;

  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_ANIOS', v_anios, 'Anios de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_MESES', v_meses, 'Meses de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_DIAS', v_dias, 'Dias de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_TOTAL_MESES', v_total_meses, 'Total meses de antiguedad');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_PrepararVariablesBase
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_preparar_variables_base(VARCHAR(80), VARCHAR(32), VARCHAR(20), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_preparar_variables_base(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_nomina VARCHAR(20),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_dias_periodo INT;
  v_feriados INT;
  v_domingos INT;
  v_salario_diario NUMERIC(18,6);
  v_sueldo NUMERIC(18,6);
  v_salario_hora NUMERIC(18,6);
  v_fecha_inicio_num INT;
  v_fecha_hasta_num INT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  PERFORM sp_nomina_limpiar_variables(p_session_id);
  PERFORM sp_nomina_cargar_constantes(p_session_id);

  v_dias_periodo := (p_fecha_hasta - p_fecha_inicio) + 1;
  v_feriados := fn_nomina_contar_feriados(p_fecha_inicio, p_fecha_hasta);
  v_domingos := fn_nomina_contar_domingos(p_fecha_inicio, p_fecha_hasta);

  SELECT pc."ConstantValue" INTO v_salario_diario
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."ConstantCode" = 'SALARIO_DIARIO'
    AND pc."IsActive" = TRUE;

  IF v_salario_diario IS NULL THEN v_salario_diario := 0; END IF;
  v_sueldo := v_salario_diario * 30;
  v_salario_hora := v_salario_diario / 8.0;
  v_fecha_inicio_num := CAST(to_char(p_fecha_inicio, 'YYYYMMDD') AS INT);
  v_fecha_hasta_num := CAST(to_char(p_fecha_hasta, 'YYYYMMDD') AS INT);

  PERFORM sp_nomina_set_variable(p_session_id, 'FECHA_INICIO_NUM', v_fecha_inicio_num, 'Fecha inicio (yyyymmdd)');
  PERFORM sp_nomina_set_variable(p_session_id, 'FECHA_HASTA_NUM', v_fecha_hasta_num, 'Fecha hasta (yyyymmdd)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', v_dias_periodo, 'Dias del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'FERIADOS', v_feriados, 'Feriados del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'DOMINGOS', v_domingos, 'Domingos del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'SUELDO', v_sueldo, 'Sueldo mensual referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_DIARIO', v_salario_diario, 'Salario diario referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_HORA', v_salario_hora, 'Salario hora referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'HORAS_MES', 240, 'Horas laborales referenciales');

  PERFORM sp_nomina_calcular_antiguedad(p_session_id, p_cedula, p_fecha_hasta);
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_vacaciones_liquidacion.sql

-- =============================================
-- VACACIONES Y LIQUIDACION (CANONICO) - PostgreSQL
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_CalcularSalariosPromedio
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_salarios_promedio(VARCHAR(80), VARCHAR(32), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_salarios_promedio(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_salario_diario NUMERIC(18,6);
  v_base_util NUMERIC(18,6);
  v_salario_normal NUMERIC(18,6);
  v_salario_integral NUMERIC(18,6);
  v_dias INT;
BEGIN
  v_salario_diario := fn_nomina_get_variable(p_session_id, 'SALARIO_DIARIO');
  v_base_util := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MIN');
  v_dias := (p_fecha_hasta - p_fecha_desde) + 1;

  IF v_salario_diario <= 0 THEN v_salario_diario := 0; END IF;
  IF v_base_util <= 0 THEN v_base_util := 30; END IF;

  v_salario_normal := v_salario_diario;
  v_salario_integral := v_salario_diario + (v_salario_diario * (v_base_util / 360.0));

  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_NORMAL', v_salario_normal, 'Salario promedio diario');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_INTEGRAL', v_salario_integral, 'Salario integral diario');
  PERFORM sp_nomina_set_variable(p_session_id, 'BASE_UTIL', v_base_util, 'Base de utilidad');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_CALCULO', v_dias, 'Dias del calculo');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularDiasVacaciones
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_dias_vacaciones(VARCHAR(80), VARCHAR(32), DATE, NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_dias_vacaciones(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_retiro DATE DEFAULT NULL,
  OUT p_dias_vacaciones NUMERIC(18,6),
  OUT p_dias_bono_vacacional NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_fecha_retiro DATE;
  v_company_id INT;
  v_branch_id INT;
  v_hire_date DATE;
  v_years INT := 0;
  v_base_vac NUMERIC(18,6);
  v_base_bono NUMERIC(18,6);
BEGIN
  v_fecha_retiro := COALESCE(p_fecha_retiro, (NOW() AT TIME ZONE 'UTC')::DATE);

  v_base_vac := fn_nomina_get_variable(p_session_id, 'DIAS_VACACIONES_BASE');
  v_base_bono := fn_nomina_get_variable(p_session_id, 'DIAS_BONO_VAC_BASE');

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT e."HireDate" INTO v_hire_date
  FROM master."Employee" e
  WHERE e."CompanyId" = v_company_id
    AND e."EmployeeCode" = p_cedula
    AND e."IsDeleted" = FALSE
  LIMIT 1;

  IF v_base_vac <= 0 THEN v_base_vac := 15; END IF;
  IF v_base_bono <= 0 THEN v_base_bono := 15; END IF;

  IF v_hire_date IS NOT NULL THEN
    v_years := EXTRACT(YEAR FROM AGE(v_fecha_retiro, v_hire_date))::INT;
  END IF;

  IF v_years < 0 THEN v_years := 0; END IF;

  p_dias_vacaciones := v_base_vac + CASE WHEN v_years > 0 THEN (v_years - 1) ELSE 0 END;
  p_dias_bono_vacacional := v_base_bono + CASE WHEN v_years > 0 THEN (v_years - 1) ELSE 0 END;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_VACACIONES', p_dias_vacaciones, 'Dias vacaciones calculados');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_VAC', p_dias_bono_vacacional, 'Dias bono vacacional calculados');
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_ProcesarVacaciones
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_procesar_vacaciones(VARCHAR(50), VARCHAR(32), DATE, DATE, DATE, VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_vacaciones(
  p_vacacion_id VARCHAR(50),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_fecha_reintegro DATE DEFAULT NULL,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_user_id INT := NULL;
  v_employee_id BIGINT;
  v_employee_name VARCHAR(120);
  v_session_id VARCHAR(80) := 'VAC_' || p_vacacion_id;
  v_dias_vac NUMERIC(18,6);
  v_dias_bono NUMERIC(18,6);
  v_salario_integral NUMERIC(18,6);
  v_monto_vac NUMERIC(18,6);
  v_monto_bono NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_vacation_process_id BIGINT;
  v_fecha_desde_salarios DATE;
BEGIN
  p_resultado := 0;
  p_mensaje := '';

  BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario AND u."IsDeleted" = FALSE
    LIMIT 1;

    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."EmployeeCode" = p_cedula
      AND e."IsDeleted" = FALSE
      AND e."IsActive" = TRUE
    LIMIT 1;

    IF v_employee_id IS NULL THEN
      p_mensaje := 'Empleado no encontrado o inactivo';
      RETURN;
    END IF;

    v_fecha_desde_salarios := p_fecha_inicio - INTERVAL '3 months';

    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, 'VACACIONES', p_fecha_inicio, p_fecha_hasta);
    PERFORM sp_nomina_calcular_salarios_promedio(v_session_id, p_cedula, v_fecha_desde_salarios::DATE, p_fecha_inicio);

    SELECT r.p_dias_vacaciones, r.p_dias_bono_vacacional
    INTO v_dias_vac, v_dias_bono
    FROM sp_nomina_calcular_dias_vacaciones(v_session_id, p_cedula, NULL) r;

    v_salario_integral := fn_nomina_get_variable(v_session_id, 'SALARIO_INTEGRAL');
    IF v_salario_integral <= 0 THEN
      v_salario_integral := fn_nomina_get_variable(v_session_id, 'SALARIO_DIARIO');
    END IF;

    v_monto_vac := v_salario_integral * COALESCE(v_dias_vac, 0);
    v_monto_bono := v_salario_integral * COALESCE(v_dias_bono, 0);
    v_total := v_monto_vac + v_monto_bono;

    SELECT vp."VacationProcessId" INTO v_vacation_process_id
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND vp."VacationCode" = p_vacacion_id
    ORDER BY vp."VacationProcessId" DESC
    LIMIT 1;

    IF v_vacation_process_id IS NULL THEN
      INSERT INTO hr."VacationProcess" (
        "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
        "TotalAmount", "CalculatedAmount",
        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_vacacion_id, v_employee_id, p_cedula, v_employee_name,
        p_fecha_inicio, p_fecha_hasta, p_fecha_reintegro, (NOW() AT TIME ZONE 'UTC')::DATE,
        v_total, v_total,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "VacationProcessId" INTO v_vacation_process_id;
    ELSE
      UPDATE hr."VacationProcess"
      SET "EmployeeId" = v_employee_id,
          "EmployeeCode" = p_cedula,
          "EmployeeName" = v_employee_name,
          "StartDate" = p_fecha_inicio,
          "EndDate" = p_fecha_hasta,
          "ReintegrationDate" = p_fecha_reintegro,
          "ProcessDate" = (NOW() AT TIME ZONE 'UTC')::DATE,
          "TotalAmount" = v_total,
          "CalculatedAmount" = v_total,
          "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id
      WHERE "VacationProcessId" = v_vacation_process_id;

      DELETE FROM hr."VacationProcessLine" WHERE "VacationProcessId" = v_vacation_process_id;
    END IF;

    INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount", "CreatedAt")
    VALUES
      (v_vacation_process_id, 'VAC_PAGO', 'Pago vacaciones', v_monto_vac, NOW() AT TIME ZONE 'UTC'),
      (v_vacation_process_id, 'VAC_BONO', 'Bono vacacional', v_monto_bono, NOW() AT TIME ZONE 'UTC');

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Vacaciones procesadas. Total=' || CAST(v_total AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_CalcularLiquidacion
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_liquidacion(VARCHAR(50), VARCHAR(32), DATE, VARCHAR(50), VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_liquidacion(
  p_liquidacion_id VARCHAR(50),
  p_cedula VARCHAR(32),
  p_fecha_retiro DATE,
  p_causa_retiro VARCHAR(50) DEFAULT 'RENUNCIA',
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_user_id INT := NULL;
  v_employee_id BIGINT;
  v_employee_name VARCHAR(120);
  v_hire_date DATE;
  v_session_id VARCHAR(80) := 'LIQ_' || p_liquidacion_id;
  v_service_years INT := 0;
  v_salario_diario NUMERIC(18,6);
  v_prestaciones NUMERIC(18,6);
  v_vac_pendientes NUMERIC(18,6);
  v_bono_salida NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_settlement_process_id BIGINT;
  v_fecha_desde_base DATE;
BEGIN
  p_resultado := 0;
  p_mensaje := '';

  BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario AND u."IsDeleted" = FALSE
    LIMIT 1;

    SELECT e."EmployeeId", e."EmployeeName", e."HireDate"
    INTO v_employee_id, v_employee_name, v_hire_date
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."EmployeeCode" = p_cedula
      AND e."IsDeleted" = FALSE
    LIMIT 1;

    IF v_employee_id IS NULL THEN
      p_mensaje := 'Empleado no encontrado';
      RETURN;
    END IF;

    v_fecha_desde_base := p_fecha_retiro - INTERVAL '1 month';
    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, 'LIQUIDACION', v_fecha_desde_base::DATE, p_fecha_retiro);
    v_salario_diario := fn_nomina_get_variable(v_session_id, 'SALARIO_DIARIO');

    IF v_hire_date IS NOT NULL THEN
      v_service_years := EXTRACT(YEAR FROM AGE(p_fecha_retiro, v_hire_date))::INT;
    END IF;

    IF v_service_years < 0 THEN v_service_years := 0; END IF;
    IF v_salario_diario < 0 THEN v_salario_diario := 0; END IF;

    v_prestaciones := v_service_years * v_salario_diario * 30;
    v_vac_pendientes := v_salario_diario * 15;
    v_bono_salida := CASE WHEN UPPER(p_causa_retiro) = 'DESPIDO' THEN (v_salario_diario * 15) ELSE (v_salario_diario * 10) END;
    v_total := v_prestaciones + v_vac_pendientes + v_bono_salida;

    SELECT sp."SettlementProcessId" INTO v_settlement_process_id
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND sp."SettlementCode" = p_liquidacion_id
    ORDER BY sp."SettlementProcessId" DESC
    LIMIT 1;

    IF v_settlement_process_id IS NULL THEN
      INSERT INTO hr."SettlementProcess" (
        "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "RetirementDate", "RetirementCause", "TotalAmount",
        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_liquidacion_id, v_employee_id, p_cedula, v_employee_name,
        p_fecha_retiro, p_causa_retiro, v_total,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "SettlementProcessId" INTO v_settlement_process_id;
    ELSE
      UPDATE hr."SettlementProcess"
      SET "EmployeeId" = v_employee_id,
          "EmployeeCode" = p_cedula,
          "EmployeeName" = v_employee_name,
          "RetirementDate" = p_fecha_retiro,
          "RetirementCause" = p_causa_retiro,
          "TotalAmount" = v_total,
          "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id
      WHERE "SettlementProcessId" = v_settlement_process_id;

      DELETE FROM hr."SettlementProcessLine" WHERE "SettlementProcessId" = v_settlement_process_id;
    END IF;

    INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount", "CreatedAt")
    VALUES
      (v_settlement_process_id, 'LIQ_PREST', 'Prestaciones', v_prestaciones, NOW() AT TIME ZONE 'UTC'),
      (v_settlement_process_id, 'LIQ_VAC', 'Vacaciones pendientes', v_vac_pendientes, NOW() AT TIME ZONE 'UTC'),
      (v_settlement_process_id, 'LIQ_BONO', 'Bono de salida', v_bono_salida, NOW() AT TIME ZONE 'UTC');

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Liquidacion calculada. Total=' || CAST(v_total AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- Funcion: sp_Nomina_GetLiquidacion
-- Retorna header, lineas y totales
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_get_liquidacion_header(VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_header(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "SettlementProcessId" BIGINT,
  "SettlementCode" VARCHAR,
  "Cedula" VARCHAR,
  "NombreEmpleado" VARCHAR,
  "RetirementDate" DATE,
  "RetirementCause" VARCHAR,
  "TotalAmount" NUMERIC,
  "CreatedAt" TIMESTAMP,
  "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    sp."SettlementProcessId",
    sp."SettlementCode",
    sp."EmployeeCode" AS "Cedula",
    sp."EmployeeName" AS "NombreEmpleado",
    sp."RetirementDate",
    sp."RetirementCause",
    sp."TotalAmount",
    sp."CreatedAt",
    sp."UpdatedAt"
  FROM hr."SettlementProcess" sp
  WHERE sp."SettlementCode" = p_liquidacion_id
  ORDER BY sp."SettlementProcessId" DESC
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_get_liquidacion_lines(VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_lines(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "SettlementProcessLineId" BIGINT,
  "ConceptCode" VARCHAR,
  "ConceptName" VARCHAR,
  "Amount" NUMERIC,
  "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    sl."SettlementProcessLineId",
    sl."ConceptCode",
    sl."ConceptName",
    sl."Amount",
    sl."CreatedAt"
  FROM hr."SettlementProcessLine" sl
  INNER JOIN hr."SettlementProcess" sp ON sp."SettlementProcessId" = sl."SettlementProcessId"
  WHERE sp."SettlementCode" = p_liquidacion_id
  ORDER BY sl."SettlementProcessLineId";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_get_liquidacion_totals(VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_totals(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "TotalAsignaciones" NUMERIC,
  "TotalDeducciones" NUMERIC,
  "TotalNeto" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    SUM(CASE WHEN sl."Amount" > 0 THEN sl."Amount" ELSE 0 END) AS "TotalAsignaciones",
    SUM(CASE WHEN sl."Amount" < 0 THEN sl."Amount" ELSE 0 END) AS "TotalDeducciones",
    SUM(sl."Amount") AS "TotalNeto"
  FROM hr."SettlementProcessLine" sl
  INNER JOIN hr."SettlementProcess" sp ON sp."SettlementProcessId" = sl."SettlementProcessId"
  WHERE sp."SettlementCode" = p_liquidacion_id;
END;
$$;
-- +goose StatementEnd


-- Source: sp_nomina_venezuela_install.sql

-- =============================================
-- INSTALADOR NOMINA VENEZUELA (CANONICO) - PostgreSQL
-- Compatibilidad de nombres sp_Nomina_* sin tablas legacy
-- Traducido de SQL Server a PostgreSQL
-- =============================================

CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."PayrollCalcVariable" (
  "SessionID" VARCHAR(80) NOT NULL,
  "Variable" VARCHAR(120) NOT NULL,
  "Valor" NUMERIC(18,6) NOT NULL DEFAULT 0,
  "Descripcion" VARCHAR(255) NULL,
  "CreatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_PCV" PRIMARY KEY ("SessionID", "Variable")
);

-- Wrappers de compatibilidad por si aun no se ejecuto sp_nomina_sistema.sql
-- En PG usamos CREATE OR REPLACE que es idempotente

-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_limpiar_variables_compat(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_limpiar_variables_compat(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_set_variable_compat(VARCHAR(80), VARCHAR(120), NUMERIC(18,6), VARCHAR(255)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_set_variable_compat(
  p_session_id VARCHAR(80),
  p_variable VARCHAR(120),
  p_valor NUMERIC(18,6),
  p_descripcion VARCHAR(255) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  VALUES (p_session_id, p_variable, p_valor, p_descripcion)
  ON CONFLICT ("SessionID", "Variable") DO UPDATE SET
    "Valor" = EXCLUDED."Valor",
    "Descripcion" = EXCLUDED."Descripcion",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS sp_nomina_calcular_antiguedad_compat(VARCHAR(80), VARCHAR(32), DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_antiguedad_compat(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_calculo DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_fecha_calc DATE;
BEGIN
  v_fecha_calc := COALESCE(p_fecha_calculo, (NOW() AT TIME ZONE 'UTC')::DATE);
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_ANIOS', 0, 'Anios');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_MESES', 0, 'Meses');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_TOTAL_MESES', 0, 'Total meses');
END;
$$;
-- +goose StatementEnd

-- Semilla de constantes base para Venezuela (idempotente)
-- +goose StatementBegin
DO $$
DECLARE
  v_company_id INT;
BEGIN
  SELECT "CompanyId" INTO v_company_id
  FROM cfg."Company"
  WHERE "IsDeleted" = FALSE
  ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa';
  END IF;

  INSERT INTO hr."PayrollConstant" ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName", "IsActive", "CreatedAt", "UpdatedAt")
  VALUES
    (v_company_id, 'SALARIO_DIARIO', 'Salario diario base', 0.00, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'HORAS_MES', 'Horas laborales mensuales', 240.00, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_SSO', 'Porcentaje SSO empleado', 0.040000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_FAOV', 'Porcentaje FAOV empleado', 0.010000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_LRPE', 'Porcentaje LRPE empleado', 0.005000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_VACACIONES_BASE', 'Dias vacaciones base', 15.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_BONO_VAC_BASE', 'Dias bono vacacional base', 15.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_UTILIDADES_MIN', 'Dias utilidades minimo', 30.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_UTILIDADES_MAX', 'Dias utilidades maximo', 120.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "ConstantCode") DO UPDATE SET
    "ConstantName" = EXCLUDED."ConstantName",
    "ConstantValue" = EXCLUDED."ConstantValue",
    "SourceName" = EXCLUDED."SourceName",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Instalacion canonica de nomina completada.';
END;
$$;
-- +goose StatementEnd

-- Verificacion de conteos
SELECT 'PayrollType' AS "Objeto", COUNT(1) AS "Total" FROM hr."PayrollType"
UNION ALL SELECT 'PayrollConstant', COUNT(1) FROM hr."PayrollConstant"
UNION ALL SELECT 'PayrollConcept', COUNT(1) FROM hr."PayrollConcept"
UNION ALL SELECT 'PayrollRun', COUNT(1) FROM hr."PayrollRun"
UNION ALL SELECT 'PayrollCalcVariable', COUNT(1) FROM hr."PayrollCalcVariable";


-- Source: seed_nomina_completo.sql

-- ============================================================================
-- SEED NOMINA COMPLETO (PostgreSQL) — Datos de prueba realistas (empresa venezolana DatqBox)
-- Idempotente: usa INSERT ... ON CONFLICT DO NOTHING o NOT EXISTS
-- Convertido desde SQL Server
-- Fecha: 2026-03-16
-- ============================================================================

-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '=== SEED NOMINA COMPLETO — Inicio ===';

  -- ============================================================================
  -- SECCION 1: EMPLEADOS (8 nuevos en master."Employee")
  -- Existentes: EmployeeId=1 (V-25678901), EmployeeId=2 (V-18901234)
  -- ============================================================================
  RAISE NOTICE '>> 1. Empleados';

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-12345678', 'Maria Elena Gonzalez Perez', 'V-12345678', '2020-01-15', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'V-14567890', '2019-06-01', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-16789012', 'Ana Isabel Martinez Lopez', 'V-16789012', '2021-03-10', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-18234567', 'Jose Manuel Herrera Torres', 'V-18234567', '2018-09-20', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-20456789', 'Luisa Fernanda Castro Diaz', 'V-20456789', '2022-02-01', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-22678901', 'Pedro Antonio Morales Rivas', 'V-22678901', '2017-11-15', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'V-24890123', '2023-01-10', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-24890123');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-26012345', 'Roberto Jose Flores Guzman', 'V-26012345', '2020-07-25', '2025-12-31', false
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-26012345');

  RAISE NOTICE '   8 empleados procesados.';

  -- ============================================================================
  -- SECCION 2: PAYROLL BATCHES (3 lotes)
  -- ============================================================================
  RAISE NOTICE '>> 2. Payroll Batches';

  -- Batch 100: Enero 2026 — CERRADA, 8 empleados activos
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 100) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "PayrollCode", "FromDate", "ToDate",
      "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      100, 1, 'LOT', '2026-01-01', '2026-01-31',
      'CERRADA', 1, 1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 100 (Ene 2026) insertado.';
  END IF;

  -- Batch 101: Febrero 2026 — CERRADA, 8 empleados
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 101) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "PayrollCode", "FromDate", "ToDate",
      "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      101, 1, 'LOT', '2026-02-01', '2026-02-28',
      'CERRADA', 1, 1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 101 (Feb 2026) insertado.';
  END IF;

  -- Batch 102: Marzo 2026 — BORRADOR, 9 empleados (incluye Carmen)
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 102) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "PayrollCode", "FromDate", "ToDate",
      "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      102, 1, 'LOT', '2026-03-01', '2026-03-15',
      'BORRADOR', 1, 1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 102 (Mar 2026) insertado.';
  END IF;

  RAISE NOTICE '>> 2b. Payroll Batch Lines';

  -- Batch 100 lines — 8 empleados activos
  -- Helper: insertar 4 lineas por empleado por batch (ASIG_BASE, DED_SSO, DED_FAOV, DED_LRPE)

  -- V-25678901 (Sueldo: 3500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 140.00, 140.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 35.00, 35.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 17.50, 17.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_LRPE');

  -- V-18901234 (Sueldo: 2800)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 112.00, 112.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 28.00, 28.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 14.00, 14.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_LRPE');

  -- V-12345678 (Sueldo: 4200)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 168.00, 168.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 42.00, 42.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 21.00, 21.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_LRPE');

  -- V-14567890 (Sueldo: 4800)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 192.00, 192.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 48.00, 48.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 24.00, 24.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_LRPE');

  -- V-16789012 (Sueldo: 3000)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 120.00, 120.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 30.00, 30.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 15.00, 15.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_LRPE');

  -- V-18234567 (Sueldo: 5000)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 200.00, 200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 50.00, 50.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 25.00, 25.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_LRPE');

  -- V-20456789 (Sueldo: 2500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 100.00, 100.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 25.00, 25.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 12.50, 12.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_LRPE');

  -- V-22678901 (Sueldo: 4500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 180.00, 180.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 45.00, 45.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 22.50, 22.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_LRPE');

  RAISE NOTICE '   Batch 100 lines completadas.';

  -- Batch 101 lines (Feb 2026) — mismos 8 empleados, mismos montos
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  RAISE NOTICE '   Batch 101 lines completadas (solo ASIG_BASE por brevedad; deductions se omiten en batch duplicado).';

  -- Batch 102 lines (Mar 2026) — 9 empleados (incluye Carmen Rosa Navarro)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  -- Carmen Rosa Navarro (solo batch 102)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2700.00, 2700.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 108.00, 108.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 27.00, 27.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 13.50, 13.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_LRPE');

  RAISE NOTICE '   Batch 102 lines completadas.';

  -- ============================================================================
  -- SECCION 3: VACATION REQUESTS (5) + VacationRequestDay + VacationProcess (2)
  -- ============================================================================
  RAISE NOTICE '>> 3. Solicitudes de Vacaciones';

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 100) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      100, 1, 'V-12345678', '2026-01-20',
      '2026-02-10', '2026-02-24', 15, false, 'PROCESADA',
      'V-18234567', '2026-01-25', 'Vacaciones anuales periodo 2025-2026'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 101) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      101, 1, 'V-14567890', '2026-02-15',
      '2026-03-01', '2026-03-08', 8, false, 'APROBADA',
      'V-18234567', '2026-02-20', 'Dias pendientes periodo anterior'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 102) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status", "Notes"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      102, 1, 'V-16789012', '2026-03-10',
      '2026-04-01', '2026-04-15', 15, false, 'PENDIENTE',
      'Vacaciones anuales completas'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 103) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      103, 1, 'V-18234567', '2025-12-20',
      '2026-01-15', '2026-01-22', 8, false, 'PROCESADA',
      'V-25678901', '2025-12-28', 'Vacaciones parciales inicio de anno'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 104) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "RejectionReason", "Notes"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      104, 1, 'V-20456789', '2026-03-05',
      '2026-05-01', '2026-05-10', 10, false, 'RECHAZADA',
      'Periodo de alta demanda', 'Solicitud rechazada por carga laboral'
    );
  END IF;

  RAISE NOTICE '   5 solicitudes de vacaciones insertadas.';

  -- VacationRequestDay — generar dias individuales usando generate_series
  RAISE NOTICE '>> 3b. Dias de vacaciones';

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 100, d::date, 'COMPLETO'
  FROM generate_series('2026-02-10'::date, '2026-02-24'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 100 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 101, d::date, 'COMPLETO'
  FROM generate_series('2026-03-01'::date, '2026-03-08'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 101 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 102, d::date, 'COMPLETO'
  FROM generate_series('2026-04-01'::date, '2026-04-15'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 102 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 103, d::date, 'COMPLETO'
  FROM generate_series('2026-01-15'::date, '2026-01-22'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 103 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 104, d::date, 'COMPLETO'
  FROM generate_series('2026-05-01'::date, '2026-05-10'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 104 AND "SelectedDate" = d::date);

  RAISE NOTICE '   Dias de vacaciones insertados.';

  -- VacationProcess (2 procesados: Request 100 y 103)
  RAISE NOTICE '>> 3c. VacationProcess';

  IF NOT EXISTS (SELECT 1 FROM hr."VacationProcess" WHERE "CompanyId" = 1 AND "VacationCode" = 'VAC-2026-100') THEN
    INSERT INTO hr."VacationProcess" (
      "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
      "TotalAmount", "CalculatedAmount"
    )
    SELECT 1, 1, 'VAC-2026-100', e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez',
      '2026-02-10', '2026-02-24', '2026-02-25', '2026-02-08',
      4200.00, 4200.00
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationProcess" WHERE "CompanyId" = 1 AND "VacationCode" = 'VAC-2026-103') THEN
    INSERT INTO hr."VacationProcess" (
      "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
      "TotalAmount", "CalculatedAmount"
    )
    SELECT 1, 1, 'VAC-2026-103', e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres',
      '2026-01-15', '2026-01-22', '2026-01-23', '2026-01-13',
      2666.66, 2666.66
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567';
  END IF;

  -- VacationProcessLines
  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_PAGO', 'Pago vacaciones', 2100.00
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-100'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-100' AND vpx."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_BONO', 'Bono vacacional', 2100.00
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-100'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-100' AND vpx."ConceptCode" = 'VAC_BONO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_PAGO', 'Pago vacaciones', 1333.33
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-103'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-103' AND vpx."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_BONO', 'Bono vacacional', 1333.33
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-103'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-103' AND vpx."ConceptCode" = 'VAC_BONO');

  -- Vincular VacationId en requests procesadas
  UPDATE hr."VacationRequest" SET "VacationId" = vp."VacationProcessId"
  FROM hr."VacationProcess" vp WHERE vp."VacationCode" = 'VAC-2026-100'
  AND hr."VacationRequest"."RequestId" = 100 AND hr."VacationRequest"."VacationId" IS NULL;

  UPDATE hr."VacationRequest" SET "VacationId" = vp."VacationProcessId"
  FROM hr."VacationProcess" vp WHERE vp."VacationCode" = 'VAC-2026-103'
  AND hr."VacationRequest"."RequestId" = 103 AND hr."VacationRequest"."VacationId" IS NULL;

  RAISE NOTICE '   VacationProcess y lineas insertadas.';

  -- ============================================================================
  -- SECCION 4: SETTLEMENT PROCESS (liquidacion Roberto Jose Flores Guzman)
  -- ============================================================================
  RAISE NOTICE '>> 4. Liquidacion (Settlement)';

  IF NOT EXISTS (SELECT 1 FROM hr."SettlementProcess" WHERE "CompanyId" = 1 AND "SettlementCode" = 'LIQ-2025-001') THEN
    INSERT INTO hr."SettlementProcess" (
      "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "RetirementDate", "RetirementCause", "TotalAmount"
    )
    SELECT 1, 1, 'LIQ-2025-001', e."EmployeeId", 'V-26012345', 'Roberto Jose Flores Guzman',
      '2025-12-31', 'RENUNCIA', 19200.00
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-26012345';
  END IF;

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'PREST_SOCIAL', 'Prestaciones sociales (5 annos x 30 dias)', 16000.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'PREST_SOCIAL');

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'VAC_PAGO', 'Vacaciones pendientes (15 dias)', 1600.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'UTIL_FRAC', 'Utilidades fraccionadas (6 meses)', 1600.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'UTIL_FRAC');

  RAISE NOTICE '   Liquidacion V-26012345 insertada.';

  -- ============================================================================
  -- SECCION 5: OCCUPATIONAL HEALTH (5 registros)
  -- ============================================================================
  RAISE NOTICE '>> 5. Salud Ocupacional';

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "BodyPartAffected", "DaysLost",
    "Location", "Description", "RootCause", "CorrectiveAction", "Status"
  )
  SELECT 1, 'VE', 'ACCIDENT', e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas',
    '2025-11-10', '2025-11-10', 'LEVE', 'MANO_DERECHA', 3,
    'Almacen principal', 'Corte superficial en mano derecha al manipular cajas',
    'Falta de guantes de proteccion', 'Dotacion de guantes de corte obligatorios', 'CERRADO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "OccurrenceDate" = '2025-11-10');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "BodyPartAffected", "DaysLost",
    "Location", "Description", "RootCause", "Status", "InvestigationDueDate"
  )
  SELECT 1, 'VE', 'ACCIDENT', e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres',
    '2026-01-20', '2026-01-20', 'MODERADO', 'ESPALDA', 8,
    'Oficina administrativa', 'Lesion lumbar al levantar equipos de computo pesados',
    NULL, 'EN_INVEST', '2026-02-20'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "OccurrenceDate" = '2026-01-20');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "CorrectiveAction", "Status"
  )
  SELECT 1, 'VE', 'NEAR_MISS', e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva',
    '2026-02-05', '2026-02-05', 'LEVE', 0,
    'Pasillo principal planta baja', 'Casi-accidente por piso mojado sin senalizacion',
    'Colocar conos de senalizacion inmediatamente despues de trapear', 'CERRADO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "OccurrenceDate" = '2026-02-05');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "Status", "InstitutionReference"
  )
  SELECT 1, 'VE', 'INSPECTION', NULL, 'N/A', 'N/A',
    '2026-01-15', '2026-01-15', NULL, 0,
    'Almacen y deposito general', 'Inspeccion trimestral de condiciones de almacenamiento segun LOPCYMAT',
    'CERRADO', 'INPSASEL-2026-INS-0042'
  WHERE NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "RecordType" = 'INSPECTION' AND "OccurrenceDate" = '2026-01-15');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "Status"
  )
  SELECT 1, 'VE', 'RISK_NOTIFICATION', e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz',
    '2026-02-28', '2026-02-28', NULL, 0,
    'Estacion de trabajo contabilidad', 'Notificacion de riesgo ergonomico por silla inadecuada y monitor a altura incorrecta. Requiere evaluacion de puesto de trabajo.',
    'ABIERTO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789' AND "OccurrenceDate" = '2026-02-28');

  RAISE NOTICE '   5 registros de salud ocupacional insertados.';

  -- ============================================================================
  -- SECCION 6: MEDICAL EXAMS (8 registros)
  -- ============================================================================
  RAISE NOTICE '>> 6. Examenes Medicos';

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'PERIODIC', '2025-06-15', '2026-06-15', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678' AND "ExamDate" = '2025-06-15');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'PERIODIC', '2025-08-20', '2026-08-20', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "ExamDate" = '2025-08-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'PERIODIC', '2025-09-10', '2026-09-10', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012' AND "ExamDate" = '2025-09-10');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'PERIODIC', '2025-07-05', '2026-07-05', 'FIT_RESTRICTED', 'Evitar levantamiento de cargas superiores a 10 kg. Control lumbar cada 6 meses.', 'Dr. Luis Paredes', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "ExamDate" = '2025-07-05');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'PRE_EMPLOYMENT', '2022-01-20', '2023-01-20', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789' AND "ExamDate" = '2022-01-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName", "Notes")
  SELECT 1, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'PERIODIC', '2025-11-25', '2026-11-25', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria', 'Evaluacion post-accidente mano derecha. Recuperacion completa.'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "ExamDate" = '2025-11-25');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'PRE_EMPLOYMENT', '2022-12-20', '2023-12-20', 'FIT', 'Dr. Luis Paredes', 'Policlinica Metropolitana'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-24890123' AND "ExamDate" = '2022-12-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'PERIODIC', '2025-05-10', '2026-05-10', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-25678901' AND "ExamDate" = '2025-05-10');

  RAISE NOTICE '   8 examenes medicos insertados.';

  -- ============================================================================
  -- SECCION 7: MEDICAL ORDERS (5 registros)
  -- ============================================================================
  RAISE NOTICE '>> 7. Ordenes Medicas';

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'MEDICAL', '2026-01-22', 'Lumbalgia mecanica aguda', 'Dr. Luis Paredes', 'Diclofenac 75mg c/12h x 7 dias. Reposo relativo. Control en 2 semanas.', 150.00, 150.00, 'APROBADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "OrderDate" = '2026-01-22');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'PHARMACY', '2025-11-12', 'Herida cortante mano derecha', 'Dr. Rafael Mendoza', 'Amoxicilina 500mg c/8h x 5 dias. Curas locales diarias.', 80.00, 80.00, 'PROCESADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "OrderDate" = '2025-11-12');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "Status")
  SELECT 1, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'LAB', '2026-03-01', 'Chequeo anual de rutina', 'Dra. Carmen Olivares', 'Hematologia completa, glicemia, perfil lipidico, urea, creatinina.', 200.00, 'PENDIENTE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678' AND "OrderDate" = '2026-03-01');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'REFERRAL', '2026-02-10', 'Sindrome de tunel carpiano bilateral', 'Dr. Luis Paredes', 'Referencia a traumatologia para evaluacion quirurgica.', 350.00, 350.00, 'APROBADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "OrderDate" = '2026-02-10');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'MEDICAL', '2026-01-28', 'Cefalea tensional recurrente', 'Dra. Carmen Olivares', 'Ibuprofeno 400mg condicional. Evaluacion de estres laboral.', 120.00, 120.00, 'PROCESADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012' AND "OrderDate" = '2026-01-28');

  RAISE NOTICE '   5 ordenes medicas insertadas.';
  RAISE NOTICE '=== SEED NOMINA COMPLETO — Primera mitad completada ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_nomina_completo.sql: %', SQLERRM;
END $$;
-- +goose StatementEnd


-- Source: seed_nomina_completo_p2.sql

-- ============================================================================
-- SEED NOMINA COMPLETO — PARTE 2 (PostgreSQL)
-- Continua seed_nomina_completo.sql (Part 1)
-- Empleados Id 1-10 ya existen en master."Employee"
-- Idempotente: usa NOT EXISTS en cada INSERT
-- Convertido desde SQL Server
-- Fecha: 2026-03-16
-- ============================================================================

-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '=== SEED NOMINA COMPLETO P2 — Inicio ===';

  -- ============================================================================
  -- 1. TRAINING RECORDS (8 registros) — IDs 5-12
  -- ============================================================================
  RAISE NOTICE '>> 1. Capacitacion (8 registros nuevos)';

  -- 5: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp V-12345678
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 5) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 5, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      e."EmployeeId", 'V-12345678', 'Carlos Mendoza',
      'ISL-PRL-2025-0103', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  -- 6: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp V-14567890
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 6) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 6, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      e."EmployeeId", 'V-14567890', 'Ana Rodriguez',
      'ISL-PRL-2025-0104', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890';
  END IF;

  -- 7: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp V-16789012
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 7) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 7, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      e."EmployeeId", 'V-16789012', 'Maria Lopez',
      'ISL-PRL-2025-0105', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012';
  END IF;

  -- 8: SEGURIDAD — Manejo Sustancias Peligrosas, emp V-12345678
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 8) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 8, 1, 'VE', 'SEGURIDAD', 'Manejo de Sustancias Peligrosas', 'Instituto Seguridad Laboral',
      '2025-09-22', '2025-09-23', 16,
      e."EmployeeId", 'V-12345678', 'Carlos Mendoza',
      'ISL-MSP-2025-0088', NULL, 'APROBADO', true,
      'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias quimicas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  -- 9: SEGURIDAD — Manejo Sustancias Peligrosas, emp V-18234567
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 9) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 9, 1, 'VE', 'SEGURIDAD', 'Manejo de Sustancias Peligrosas', 'Instituto Seguridad Laboral',
      '2025-09-22', '2025-09-23', 16,
      e."EmployeeId", 'V-18234567', 'Pedro Garcia',
      'ISL-MSP-2025-0089', NULL, 'APROBADO', true,
      'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias quimicas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567';
  END IF;

  -- 10: DESARROLLO — Excel Avanzado, emp V-16789012
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 10) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 10, 1, 'VE', 'DESARROLLO', 'Excel Avanzado', 'AcademiaVE',
      '2026-01-13', '2026-01-31', 24,
      e."EmployeeId", 'V-16789012', 'Maria Lopez',
      'AVE-EXC-2026-0045', NULL, 'APROBADO', false,
      'Tablas dinamicas, Power Query, macros VBA, dashboards. Formacion de desarrollo profesional.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012';
  END IF;

  -- 11: DESARROLLO — Excel Avanzado, emp V-20456789
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 11) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 11, 1, 'VE', 'DESARROLLO', 'Excel Avanzado', 'AcademiaVE',
      '2026-01-13', '2026-01-31', 24,
      e."EmployeeId", 'V-20456789', 'Luisa Martinez',
      'AVE-EXC-2026-0046', NULL, 'APROBADO', false,
      'Tablas dinamicas, Power Query, macros VBA, dashboards. Formacion de desarrollo profesional.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789';
  END IF;

  -- 12: INDUCCION — Induccion DatqBox, emp V-24890123
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 12) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 12, 1, 'VE', 'INDUCCION', 'Induccion DatqBox', 'INCES',
      '2025-11-03', '2025-11-07', 40,
      e."EmployeeId", 'V-24890123', 'Roberto Hernandez',
      'INCES-IND-2025-1201', NULL, 'APROBADO', true,
      'Induccion integral: cultura organizacional, procesos, LOPCYMAT, seguridad informatica, herramientas internas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123';
  END IF;

  RAISE NOTICE '   8 registros de capacitacion insertados (IDs 5-12).';

  -- ============================================================================
  -- 2. COMITES DE SEGURIDAD (2) + Miembros + Reuniones
  -- ============================================================================
  RAISE NOTICE '>> 2. Comites de Seguridad';

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommittee" WHERE "SafetyCommitteeId" = 100) THEN
    INSERT INTO hr."SafetyCommittee" (
      "SafetyCommitteeId", "CompanyId", "CountryCode", "CommitteeName",
      "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      100, 1, 'VE', 'Comite de Seguridad y Salud Laboral',
      '2024-01-15', 'MENSUAL', true, (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommittee" WHERE "SafetyCommitteeId" = 101) THEN
    INSERT INTO hr."SafetyCommittee" (
      "SafetyCommitteeId", "CompanyId", "CountryCode", "CommitteeName",
      "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      101, 1, 'VE', 'Comite de Bienestar Social',
      '2024-06-01', 'TRIMESTRAL', true, (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- Miembros Comite 100
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 100) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) OVERRIDING SYSTEM VALUE
    SELECT 100, 100, e."EmployeeId", 'V-22678901', 'Fernando Diaz', 'PRESIDENTE', '2024-01-15', NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 101) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) OVERRIDING SYSTEM VALUE
    SELECT 101, 100, e."EmployeeId", 'V-12345678', 'Carlos Mendoza', 'SECRETARIO', '2024-01-15', NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 102) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) OVERRIDING SYSTEM VALUE
    SELECT 102, 100, e."EmployeeId", 'V-14567890', 'Ana Rodriguez', 'VOCAL', '2024-01-15', NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890';
  END IF;

  -- Miembros Comite 101
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 103) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) OVERRIDING SYSTEM VALUE
    SELECT 103, 101, e."EmployeeId", 'V-16789012', 'Maria Lopez', 'PRESIDENTA', '2024-06-01', NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 104) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) OVERRIDING SYSTEM VALUE
    SELECT 104, 101, e."EmployeeId", 'V-20456789', 'Luisa Martinez', 'SECRETARIA', '2024-06-01', NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789';
  END IF;

  -- Reuniones Comite 100
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 100) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      100, 100, '2026-01-20', NULL,
      '1. Revision accidentes Q4 2025. 2. Plan de capacitacion SST 2026. 3. Auditoria de extintores y senalizacion.',
      '- Programar inspeccion de extintores antes del 31/01. - Actualizar mapa de riesgos del almacen. - Coordinar charla de primeros auxilios con Cruz Roja.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 101) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      101, 100, '2026-02-17', NULL,
      '1. Resultado inspeccion extintores. 2. Estadisticas accidentalidad enero. 3. Dotacion EPP primer trimestre.',
      '- Reemplazar 3 extintores vencidos en planta baja. - Solicitar cotizacion EPP nuevos ingresos. - Fijar fecha simulacro evacuacion marzo.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 102) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      102, 100, '2026-03-16', NULL,
      '1. Simulacro de evacuacion realizado (3 min 20 seg). 2. Revision plan de emergencia. 3. Informe trimestral INPSASEL.',
      '- Documentar resultados simulacro para informe INPSASEL. - Corregir ruta evacuacion piso 2. - Entregar informe trimestral antes del 10/04.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- Reunion Comite 101
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 103) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      103, 101, '2026-01-28', NULL,
      '1. Planificacion actividades recreativas Q1 2026. 2. Fondo de ayuda social: balance y solicitudes pendientes. 3. Convenio farmacia.',
      '- Organizar jornada deportiva para febrero. - Evaluar 2 solicitudes de ayuda economica. - Renovar convenio farmacia antes del 15/02.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  RAISE NOTICE '   2 comites, 5 miembros, 4 reuniones insertados.';

  -- ============================================================================
  -- 3. OBLIGACIONES LEGALES (4 para VE) — Verificar/crear si no existen
  -- ============================================================================
  RAISE NOTICE '>> 3. Obligaciones Legales VE (verificar/crear 4)';

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_SSO', 'Seguro Social Obligatorio', 'IVSS', 'CONTRIBUTION',
      'GROSS_PAYROLL', 10.00000, 4.00000,
      true, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'SSO clase I. Tasa variable segun nivel de riesgo.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_FAOV') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_FAOV', 'Ley de Vivienda y Habitat', 'BANAVIH', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 1.00000,
      false, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'Fondo de Ahorro Obligatorio para la Vivienda.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_LRPE') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_LRPE', 'Regimen Prestacional de Empleo', 'INPSASEL', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 0.50000,
      false, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'Paro forzoso - Ley del Regimen Prestacional de Empleo.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_INCE') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_INCE', 'Capacitacion y Educacion', 'INCES', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 0.00000,
      false, 'QUARTERLY', 'Dentro de los 5 dias habiles despues del cierre del trimestre',
      '2012-01-01', true, 'INCES: 2% patronal sobre nomina. Empleado 0.5% sobre utilidades (separado).'
    );
  END IF;

  RAISE NOTICE '   4 obligaciones legales VE verificadas.';

  -- ============================================================================
  -- 4. EMPLOYEE OBLIGATIONS — Inscribir empleados 3-9 en VE_SSO, VE_FAOV, VE_LRPE, VE_INCE
  -- ============================================================================
  RAISE NOTICE '>> 4. Inscripcion de empleados en obligaciones legales';

  -- VE_SSO para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId", aff_num, 'IVSS',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, 'SSO-012345', '2019-03-15'::date),
    (4, 'SSO-014567', '2018-07-01'::date),
    (5, 'SSO-016789', '2020-01-10'::date),
    (6, 'SSO-018234', '2017-04-01'::date),
    (7, 'SSO-020456', '2022-06-01'::date),
    (8, 'SSO-022678', '2016-02-15'::date),
    (9, 'SSO-024890', '2023-03-01'::date)
  ) AS t(emp_id, aff_num, enroll_date)
  WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_SSO'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_SSO.';

  -- VE_FAOV para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId", aff_num, 'BANAVIH',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, 'FAOV-012345', '2019-03-15'::date),
    (4, 'FAOV-014567', '2018-07-01'::date),
    (5, 'FAOV-016789', '2020-01-10'::date),
    (6, 'FAOV-018234', '2017-04-01'::date),
    (7, 'FAOV-020456', '2022-06-01'::date),
    (8, 'FAOV-022678', '2016-02-15'::date),
    (9, 'FAOV-024890', '2023-03-01'::date)
  ) AS t(emp_id, aff_num, enroll_date)
  WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_FAOV'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_FAOV.';

  -- VE_LRPE para empleados 1-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId",
    'LRPE-0' || emp_id::text || lpad((emp_id * 11111)::text, 5, '0'),
    'INPSASEL',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (1, '2024-03-01'::date),
    (2, '2024-06-01'::date),
    (3, '2019-03-15'::date),
    (4, '2018-07-01'::date),
    (5, '2020-01-10'::date),
    (6, '2017-04-01'::date),
    (7, '2022-06-01'::date),
    (8, '2016-02-15'::date),
    (9, '2023-03-01'::date)
  ) AS t(emp_id, enroll_date)
  WHERE lo."Code" = 'VE_LRPE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_LRPE'
  );

  RAISE NOTICE '   Empleados 1-9 inscritos en VE_LRPE.';

  -- VE_INCE para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId",
    'INCE-0' || emp_id::text || lpad((emp_id * 22222)::text, 5, '0'),
    'INCE',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, '2019-03-15'::date),
    (4, '2018-07-01'::date),
    (5, '2020-01-10'::date),
    (6, '2017-04-01'::date),
    (7, '2022-06-01'::date),
    (8, '2016-02-15'::date),
    (9, '2023-03-01'::date)
  ) AS t(emp_id, enroll_date)
  WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_INCE'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_INCE.';

  -- ============================================================================
  -- 5. OBLIGATION FILINGS — Ene/Feb/Mar 2026 para SSO y FAOV
  -- ============================================================================
  RAISE NOTICE '>> 5. Declaraciones SSO y FAOV (Ene-Mar 2026)';

  -- SSO Enero 2026 (FilingId 10)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 10) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 10, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-10',
      'SSO-2026-01-0001', 3080.00, 1232.00, 4312.00,
      9, 'PAGADA', 1, NULL, 'Declaracion SSO enero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- SSO Febrero 2026 (FilingId 11)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 11) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 11, 1, lo."LegalObligationId",
      '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-08',
      'SSO-2026-02-0001', 3080.00, 1232.00, 4312.00,
      9, 'PAGADA', 1, NULL, 'Declaracion SSO febrero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- SSO Marzo 2026 (FilingId 12) — PENDIENTE
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 12) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 12, 1, lo."LegalObligationId",
      '2026-03-01', '2026-03-31', '2026-04-10', NULL,
      NULL, 3080.00, 1232.00, 4312.00,
      9, 'PENDIENTE', NULL, NULL, 'Declaracion SSO marzo 2026 — pendiente de pago',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- FAOV Enero 2026 (FilingId 13)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 13) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 13, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-09',
      'FAOV-2026-01-0001', 616.00, 308.00, 924.00,
      9, 'PAGADA', 1, NULL, 'Declaracion FAOV enero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  -- FAOV Febrero 2026 (FilingId 14)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 14) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 14, 1, lo."LegalObligationId",
      '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-07',
      'FAOV-2026-02-0001', 616.00, 308.00, 924.00,
      9, 'PAGADA', 1, NULL, 'Declaracion FAOV febrero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  -- FAOV Marzo 2026 (FilingId 15) — PENDIENTE
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 15) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 15, 1, lo."LegalObligationId",
      '2026-03-01', '2026-03-31', '2026-04-10', NULL,
      NULL, 616.00, 308.00, 924.00,
      9, 'PENDIENTE', NULL, NULL, 'Declaracion FAOV marzo 2026 — pendiente de pago',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  RAISE NOTICE '   6 filings (SSO+FAOV x 3 meses) insertados.';

  -- Filing detail por empleado (SSO: 10-12, FAOV: 13-15)
  -- SSO: Patronal=Salary*0.10, Empleado=Salary*0.04
  -- FAOV: Patronal=Salary*0.02, Empleado=Salary*0.01
  INSERT INTO hr."ObligationFilingDetail" (
    "ObligationFilingId", "EmployeeId", "BaseSalary",
    "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
  )
  SELECT f_id, emp_id, salary,
    CAST(salary * 0.10 AS DECIMAL(18,2)),
    CAST(salary * 0.04 AS DECIMAL(18,2)),
    30, 'NONE'
  FROM (VALUES (10), (11), (12)) AS filings(f_id),
  (VALUES
    (1, 3500.00), (2, 2800.00), (3, 3500.00), (4, 4200.00), (5, 3200.00),
    (6, 3800.00), (7, 2800.00), (8, 4500.00), (9, 2500.00)
  ) AS salaries(emp_id, salary)
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."ObligationFilingDetail"
    WHERE "ObligationFilingId" = f_id AND "EmployeeId" = emp_id
  );

  INSERT INTO hr."ObligationFilingDetail" (
    "ObligationFilingId", "EmployeeId", "BaseSalary",
    "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
  )
  SELECT f_id, emp_id, salary,
    CAST(salary * 0.02 AS DECIMAL(18,2)),
    CAST(salary * 0.01 AS DECIMAL(18,2)),
    30, 'NONE'
  FROM (VALUES (13), (14), (15)) AS filings(f_id),
  (VALUES
    (1, 3500.00), (2, 2800.00), (3, 3500.00), (4, 4200.00), (5, 3200.00),
    (6, 3800.00), (7, 2800.00), (8, 4500.00), (9, 2500.00)
  ) AS salaries(emp_id, salary)
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."ObligationFilingDetail"
    WHERE "ObligationFilingId" = f_id AND "EmployeeId" = emp_id
  );

  RAISE NOTICE '   54 registros de detalle de filing insertados (9 emp x 6 filings).';

  -- ============================================================================
  -- 6. CAJA DE AHORRO — Inscribir 6 empleados (IDs 3-8)
  -- ============================================================================
  RAISE NOTICE '>> 6. Caja de Ahorro (6 inscripciones)';

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 3) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 3, 1, e."EmployeeId", 'V-12345678', 'Carlos Mendoza', 10.00, 5.00, '2021-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 4) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 4, 1, e."EmployeeId", 'V-14567890', 'Ana Rodriguez', 8.00, 5.00, '2020-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 5) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 5, 1, e."EmployeeId", 'V-18234567', 'Pedro Garcia', 5.00, 5.00, '2019-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 6) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 6, 1, e."EmployeeId", 'V-22678901', 'Fernando Diaz', 10.00, 5.00, '2018-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 7) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 7, 1, e."EmployeeId", 'V-20456789', 'Luisa Martinez', 7.00, 5.00, '2022-06-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 8) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 8, 1, e."EmployeeId", 'V-24890123', 'Roberto Hernandez', 5.00, 5.00, '2023-03-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123';
  END IF;

  RAISE NOTICE '   6 inscripciones de caja de ahorro insertadas (IDs 3-8).';

  -- ============================================================================
  -- 7. SAVINGS FUND TRANSACTIONS — Ene-Mar 2026 para 6 empleados (IDs 13-48)
  -- SavingsFundId | EmpCode    | Salary | Emp%  | EmpAmt | PatAmt(5%)
  --           3   | V-12345678 | 3500   | 10%   | 350    | 175
  --           4   | V-14567890 | 4200   | 8%    | 336    | 210
  --           5   | V-18234567 | 3800   | 5%    | 190    | 190
  --           6   | V-22678901 | 4500   | 10%   | 450    | 225
  --           7   | V-20456789 | 2800   | 7%    | 196    | 140
  --           8   | V-24890123 | 2500   | 5%    | 125    | 125
  -- ============================================================================
  RAISE NOTICE '>> 7. Transacciones Caja de Ahorro (Ene-Mar 2026)';

  INSERT INTO hr."SavingsFundTransaction" (
    "TransactionId", "SavingsFundId", "TransactionDate", "TransactionType",
    "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
  ) OVERRIDING SYSTEM VALUE
  SELECT txn_id, fund_id, txn_date::date, txn_type,
    amount, balance, ref, NULL, notes, (NOW() AT TIME ZONE 'UTC')
  FROM (VALUES
    -- SavingsFundId=3 (V-12345678, Emp=350, Pat=175)
    (13, 3, '2026-01-31', 'APORTE_EMPLEADO', 350.00, 350.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (14, 3, '2026-01-31', 'APORTE_PATRONAL', 175.00, 525.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (15, 3, '2026-02-28', 'APORTE_EMPLEADO', 350.00, 875.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (16, 3, '2026-02-28', 'APORTE_PATRONAL', 175.00, 1050.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (17, 3, '2026-03-31', 'APORTE_EMPLEADO', 350.00, 1400.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (18, 3, '2026-03-31', 'APORTE_PATRONAL', 175.00, 1575.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=4 (V-14567890, Emp=336, Pat=210)
    (19, 4, '2026-01-31', 'APORTE_EMPLEADO', 336.00, 336.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (20, 4, '2026-01-31', 'APORTE_PATRONAL', 210.00, 546.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (21, 4, '2026-02-28', 'APORTE_EMPLEADO', 336.00, 882.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (22, 4, '2026-02-28', 'APORTE_PATRONAL', 210.00, 1092.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (23, 4, '2026-03-31', 'APORTE_EMPLEADO', 336.00, 1428.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (24, 4, '2026-03-31', 'APORTE_PATRONAL', 210.00, 1638.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=5 (V-18234567, Emp=190, Pat=190)
    (25, 5, '2026-01-31', 'APORTE_EMPLEADO', 190.00, 190.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (26, 5, '2026-01-31', 'APORTE_PATRONAL', 190.00, 380.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (27, 5, '2026-02-28', 'APORTE_EMPLEADO', 190.00, 570.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (28, 5, '2026-02-28', 'APORTE_PATRONAL', 190.00, 760.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (29, 5, '2026-03-31', 'APORTE_EMPLEADO', 190.00, 950.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (30, 5, '2026-03-31', 'APORTE_PATRONAL', 190.00, 1140.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=6 (V-22678901, Emp=450, Pat=225)
    (31, 6, '2026-01-31', 'APORTE_EMPLEADO', 450.00, 450.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (32, 6, '2026-01-31', 'APORTE_PATRONAL', 225.00, 675.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (33, 6, '2026-02-28', 'APORTE_EMPLEADO', 450.00, 1125.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (34, 6, '2026-02-28', 'APORTE_PATRONAL', 225.00, 1350.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (35, 6, '2026-03-31', 'APORTE_EMPLEADO', 450.00, 1800.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (36, 6, '2026-03-31', 'APORTE_PATRONAL', 225.00, 2025.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=7 (V-20456789, Emp=196, Pat=140)
    (37, 7, '2026-01-31', 'APORTE_EMPLEADO', 196.00, 196.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (38, 7, '2026-01-31', 'APORTE_PATRONAL', 140.00, 336.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (39, 7, '2026-02-28', 'APORTE_EMPLEADO', 196.00, 532.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (40, 7, '2026-02-28', 'APORTE_PATRONAL', 140.00, 672.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (41, 7, '2026-03-31', 'APORTE_EMPLEADO', 196.00, 868.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (42, 7, '2026-03-31', 'APORTE_PATRONAL', 140.00, 1008.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=8 (V-24890123, Emp=125, Pat=125)
    (43, 8, '2026-01-31', 'APORTE_EMPLEADO', 125.00, 125.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (44, 8, '2026-01-31', 'APORTE_PATRONAL', 125.00, 250.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (45, 8, '2026-02-28', 'APORTE_EMPLEADO', 125.00, 375.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (46, 8, '2026-02-28', 'APORTE_PATRONAL', 125.00, 500.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (47, 8, '2026-03-31', 'APORTE_EMPLEADO', 125.00, 625.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (48, 8, '2026-03-31', 'APORTE_PATRONAL', 125.00, 750.00, 'NOM-2026-03', 'Aporte patronal marzo 2026')
  ) AS t(txn_id, fund_id, txn_date, txn_type, amount, balance, ref, notes)
  WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "TransactionId" = t.txn_id);

  RAISE NOTICE '   36 transacciones de caja de ahorro insertadas (IDs 13-48).';

  RAISE NOTICE '=== SEED NOMINA COMPLETO P2 — Completado ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_nomina_completo_p2.sql: %', SQLERRM;
END $$;
-- +goose StatementEnd



-- Source: usp_misc.sql

/* ============================================================================
 *  usp_misc.sql  (PostgreSQL)
 *  ---------------------------------------------------------------------------
 *  Funciones miscelaneas para modulos CxC, CxP, Nomina
 *  y Conceptos Legales de Nomina.
 *
 *  Traducido de SQL Server -> PostgreSQL.
 *  Convenciones:
 *    - CxC  : usp_ar_receivable_*, usp_ar_balance_*
 *    - CxP  : usp_ap_payable_*, usp_ap_balance_*
 *    - Nomina: usp_hr_payroll_*, usp_hr_legalconcept_*
 *
 *  Patron: DROP FUNCTION IF EXISTS (idempotente)
 * ============================================================================ */


-- =============================================================================
--  SECCION 1: CUENTAS POR COBRAR (AR - Accounts Receivable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_applypayment
--  Aplica un cobro transaccional a documentos CxC de un cliente.
--  Recibe la lista de documentos como JSON.
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_applypayment(VARCHAR(24), DATE, VARCHAR(120), VARCHAR(120), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_applypayment(
    p_cod_cliente      VARCHAR(24),
    p_fecha            DATE             DEFAULT NULL,
    p_request_id       VARCHAR(120)     DEFAULT NULL,
    p_num_recibo       VARCHAR(120)     DEFAULT NULL,
    p_documentos_json  TEXT             DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id BIGINT;
    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);
    v_applied     NUMERIC(18,2) := 0;
    rec           RECORD;
    v_doc_id      BIGINT;
    v_pending     NUMERIC(18,2);
    v_apply_amount NUMERIC(18,2);
BEGIN
    -- Resolver cliente
    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CustomerCode" = p_cod_cliente
      AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_customer_id IS NULL OR v_customer_id <= 0 THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado en esquema canonico'::TEXT;
        RETURN;
    END IF;

    -- Iterar documentos desde JSON
    FOR rec IN
        SELECT
            elem->>'tipoDoc'      AS tipo_doc,
            elem->>'numDoc'       AS num_doc,
            (elem->>'montoAplicar')::NUMERIC(18,2) AS monto_aplicar
        FROM jsonb_array_elements(p_documentos_json::JSONB) AS elem
    LOOP
        v_doc_id := NULL;
        v_pending := NULL;

        -- Buscar documento con lock
        SELECT rd."ReceivableDocumentId", rd."PendingAmount"
        INTO v_doc_id, v_pending
        FROM ar."ReceivableDocument" rd
        WHERE rd."CustomerId"     = v_customer_id
          AND rd."DocumentType"   = rec.tipo_doc
          AND rd."DocumentNumber" = rec.num_doc
          AND rd."Status" <> 'VOIDED'
        ORDER BY rd."ReceivableDocumentId" DESC
        LIMIT 1
        FOR UPDATE;

        v_apply_amount := CASE
            WHEN v_pending IS NULL THEN 0
            WHEN rec.monto_aplicar < v_pending THEN rec.monto_aplicar
            ELSE v_pending
        END;

        IF v_apply_amount > 0 AND v_doc_id IS NOT NULL THEN
            -- Insertar aplicacion
            INSERT INTO ar."ReceivableApplication" (
                "ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"
            )
            VALUES (
                v_doc_id, v_apply_date, v_apply_amount,
                CONCAT(p_request_id, ':', p_num_recibo)
            );

            -- Actualizar documento
            UPDATE ar."ReceivableDocument"
            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amount < 0 THEN 0
                                       ELSE "PendingAmount" - v_apply_amount END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amount <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                             WHEN "PendingAmount" - v_apply_amount <= 0 THEN 'PAID'
                             WHEN "PendingAmount" - v_apply_amount < "TotalAmount" THEN 'PARTIAL'
                             ELSE 'PENDING'
                           END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "ReceivableDocumentId" = v_doc_id;

            v_applied := v_applied + v_apply_amount;
        END IF;
    END LOOP;

    IF v_applied <= 0 THEN
        RETURN QUERY SELECT -2, 'No hay montos aplicables para cobrar'::TEXT;
        RETURN;
    END IF;

    -- Recalcular saldo del cliente
    UPDATE master."Customer"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM("PendingAmount"), 0)
            FROM ar."ReceivableDocument"
            WHERE "CustomerId" = v_customer_id
              AND "Status" <> 'VOIDED'
        ),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CustomerId" = v_customer_id;

    RETURN QUERY SELECT 1, 'Cobro aplicado en esquema canonico'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error aplicando cobro canonico: ' || SQLERRM)::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_list
--  Lista paginada de documentos CxC.
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_list(VARCHAR(24), VARCHAR(20), VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_list(
    p_cod_cliente   VARCHAR(24)    DEFAULT NULL,
    p_tipo_doc      VARCHAR(20)    DEFAULT NULL,
    p_estado        VARCHAR(20)    DEFAULT NULL,
    p_fecha_desde   DATE           DEFAULT NULL,
    p_fecha_hasta   DATE           DEFAULT NULL,
    p_offset        INT            DEFAULT 0,
    p_limit         INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codCliente" VARCHAR,
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE (p_cod_cliente IS NULL OR c."CustomerCode" = p_cod_cliente)
      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)
      AND (p_estado IS NULL OR d."Status" = p_estado)
      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        c."CustomerCode",
        d."DocumentType",
        d."DocumentNumber",
        d."IssueDate",
        d."TotalAmount",
        d."PendingAmount",
        d."Status",
        d."Notes"
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE (p_cod_cliente IS NULL OR c."CustomerCode" = p_cod_cliente)
      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)
      AND (p_estado IS NULL OR d."Status" = p_estado)
      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta)
    ORDER BY d."IssueDate" DESC, d."ReceivableDocumentId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_getpending
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_getpending(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_getpending(
    p_cod_cliente VARCHAR(24)
)
RETURNS TABLE(
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "pendiente" NUMERIC,
    "total" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."DocumentType",
        d."DocumentNumber",
        d."IssueDate",
        d."PendingAmount",
        d."TotalAmount"
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE c."CustomerCode" = p_cod_cliente
      AND d."PendingAmount" > 0
      AND d."Status" IN ('PENDING', 'PARTIAL')
    ORDER BY d."IssueDate" ASC, d."ReceivableDocumentId" ASC;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_balance_getbycustomer
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_balance_getbycustomer(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_balance_getbycustomer(
    p_cod_cliente VARCHAR(24)
)
RETURNS TABLE(
    "saldoTotal" NUMERIC,
    "saldo30" NUMERIC,
    "saldo60" NUMERIC,
    "saldo90" NUMERIC,
    "saldo91" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(c."TotalBalance", 0)::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2)
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_cod_cliente
      AND c."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 2: CUENTAS POR PAGAR (AP - Accounts Payable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ap_payable_applypayment
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_applypayment(VARCHAR(24), DATE, VARCHAR(120), VARCHAR(120), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_applypayment(
    p_cod_proveedor    VARCHAR(24),
    p_fecha            DATE             DEFAULT NULL,
    p_request_id       VARCHAR(120)     DEFAULT NULL,
    p_num_pago         VARCHAR(120)     DEFAULT NULL,
    p_documentos_json  TEXT             DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_supplier_id BIGINT;
    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);
    v_applied     NUMERIC(18,2) := 0;
    rec           RECORD;
    v_doc_id      BIGINT;
    v_pending     NUMERIC(18,2);
    v_apply_amount NUMERIC(18,2);
BEGIN
    -- Resolver proveedor
    SELECT "SupplierId" INTO v_supplier_id
    FROM master."Supplier"
    WHERE "SupplierCode" = p_cod_proveedor
      AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_supplier_id IS NULL OR v_supplier_id <= 0 THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado en esquema canonico'::TEXT;
        RETURN;
    END IF;

    FOR rec IN
        SELECT
            elem->>'tipoDoc'      AS tipo_doc,
            elem->>'numDoc'       AS num_doc,
            (elem->>'montoAplicar')::NUMERIC(18,2) AS monto_aplicar
        FROM jsonb_array_elements(p_documentos_json::JSONB) AS elem
    LOOP
        v_doc_id := NULL;
        v_pending := NULL;

        SELECT pd."PayableDocumentId", pd."PendingAmount"
        INTO v_doc_id, v_pending
        FROM ap."PayableDocument" pd
        WHERE pd."SupplierId"     = v_supplier_id
          AND pd."DocumentType"   = rec.tipo_doc
          AND pd."DocumentNumber" = rec.num_doc
          AND pd."Status" <> 'VOIDED'
        ORDER BY pd."PayableDocumentId" DESC
        LIMIT 1
        FOR UPDATE;

        v_apply_amount := CASE
            WHEN v_pending IS NULL THEN 0
            WHEN rec.monto_aplicar < v_pending THEN rec.monto_aplicar
            ELSE v_pending
        END;

        IF v_apply_amount > 0 AND v_doc_id IS NOT NULL THEN
            INSERT INTO ap."PayableApplication" (
                "PayableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"
            )
            VALUES (
                v_doc_id, v_apply_date, v_apply_amount,
                CONCAT(p_request_id, ':', p_num_pago)
            );

            UPDATE ap."PayableDocument"
            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amount < 0 THEN 0
                                       ELSE "PendingAmount" - v_apply_amount END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amount <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                             WHEN "PendingAmount" - v_apply_amount <= 0 THEN 'PAID'
                             WHEN "PendingAmount" - v_apply_amount < "TotalAmount" THEN 'PARTIAL'
                             ELSE 'PENDING'
                           END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "PayableDocumentId" = v_doc_id;

            v_applied := v_applied + v_apply_amount;
        END IF;
    END LOOP;

    IF v_applied <= 0 THEN
        RETURN QUERY SELECT -2, 'No hay montos aplicables para pagar'::TEXT;
        RETURN;
    END IF;

    UPDATE master."Supplier"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM("PendingAmount"), 0)
            FROM ap."PayableDocument"
            WHERE "SupplierId" = v_supplier_id
              AND "Status" <> 'VOIDED'
        ),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "SupplierId" = v_supplier_id;

    RETURN QUERY SELECT 1, 'Pago aplicado en esquema canonico'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error aplicando pago canonico: ' || SQLERRM)::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_list
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_list(VARCHAR(24), VARCHAR(20), VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_list(
    p_cod_proveedor  VARCHAR(24)    DEFAULT NULL,
    p_tipo_doc       VARCHAR(20)    DEFAULT NULL,
    p_estado         VARCHAR(20)    DEFAULT NULL,
    p_fecha_desde    DATE           DEFAULT NULL,
    p_fecha_hasta    DATE           DEFAULT NULL,
    p_offset         INT            DEFAULT 0,
    p_limit          INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codProveedor" VARCHAR,
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE (p_cod_proveedor IS NULL OR s."SupplierCode" = p_cod_proveedor)
      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)
      AND (p_estado IS NULL OR d."Status" = p_estado)
      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        s."SupplierCode",
        d."DocumentType",
        d."DocumentNumber",
        d."IssueDate",
        d."TotalAmount",
        d."PendingAmount",
        d."Status",
        d."Notes"
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE (p_cod_proveedor IS NULL OR s."SupplierCode" = p_cod_proveedor)
      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)
      AND (p_estado IS NULL OR d."Status" = p_estado)
      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta)
    ORDER BY d."IssueDate" DESC, d."PayableDocumentId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_getpending
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_getpending(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_getpending(
    p_cod_proveedor VARCHAR(24)
)
RETURNS TABLE(
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "pendiente" NUMERIC,
    "total" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."DocumentType",
        d."DocumentNumber",
        d."IssueDate",
        d."PendingAmount",
        d."TotalAmount"
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE s."SupplierCode" = p_cod_proveedor
      AND d."PendingAmount" > 0
      AND d."Status" IN ('PENDING', 'PARTIAL')
    ORDER BY d."IssueDate" ASC, d."PayableDocumentId" ASC;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_balance_getbysupplier
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_balance_getbysupplier(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_balance_getbysupplier(
    p_cod_proveedor VARCHAR(24)
)
RETURNS TABLE(
    "saldoTotal" NUMERIC,
    "saldo30" NUMERIC,
    "saldo60" NUMERIC,
    "saldo90" NUMERIC,
    "saldo91" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(s."TotalBalance", 0)::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2)
    FROM master."Supplier" s
    WHERE s."SupplierCode" = p_cod_proveedor
      AND s."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 3: CUENTAS POR PAGAR CRUD
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ap_payable_listfull
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_listfull(VARCHAR(200), VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_listfull(
    p_search   VARCHAR(200)  DEFAULT NULL,
    p_codigo   VARCHAR(24)   DEFAULT NULL,
    p_offset   INT           DEFAULT 0,
    p_limit    INT           DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "id" BIGINT,
    "codigo" VARCHAR,
    "nombre" VARCHAR,
    "tipo" VARCHAR,
    "documento" VARCHAR,
    "fecha" DATE,
    "fechaVence" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "moneda" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_total      BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company" WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
    LIMIT 1;

    SELECT "BranchId" INTO v_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId"
    LIMIT 1;

    SELECT COUNT(1) INTO v_total
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE d."CompanyId" = v_company_id
      AND d."BranchId"  = v_branch_id
      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR s."SupplierName" ILIKE v_search_pat))
      AND (p_codigo IS NULL OR s."SupplierCode" = p_codigo);

    RETURN QUERY
    SELECT
        v_total,
        d."PayableDocumentId",
        s."SupplierCode",
        s."SupplierName",
        d."DocumentType",
        d."DocumentNumber",
        d."IssueDate",
        d."DueDate",
        d."TotalAmount",
        d."PendingAmount",
        d."Status",
        d."CurrencyCode"::VARCHAR,
        d."Notes"
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE d."CompanyId" = v_company_id
      AND d."BranchId"  = v_branch_id
      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR s."SupplierName" ILIKE v_search_pat))
      AND (p_codigo IS NULL OR s."SupplierCode" = p_codigo)
    ORDER BY d."IssueDate" DESC, d."PayableDocumentId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_getbyid
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_getbyid(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_getbyid(
    p_id BIGINT
)
RETURNS TABLE(
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."PayableDocumentId", s."SupplierCode", s."SupplierName",
        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",
        d."TotalAmount", d."PendingAmount", d."Status",
        d."CurrencyCode"::VARCHAR, d."Notes"
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE d."PayableDocumentId" = p_id;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_create
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_create(VARCHAR(24), VARCHAR(20), VARCHAR(120), DATE, DATE, VARCHAR(10), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_create(
    p_codigo         VARCHAR(24),
    p_document_type  VARCHAR(20)    DEFAULT 'COMPRA',
    p_document_number VARCHAR(120)  DEFAULT NULL,
    p_issue_date     DATE           DEFAULT NULL,
    p_due_date       DATE           DEFAULT NULL,
    p_currency_code  VARCHAR(10)    DEFAULT 'USD',
    p_total_amount   NUMERIC(18,2)  DEFAULT 0,
    p_pending_amount NUMERIC(18,2)  DEFAULT NULL,
    p_notes          VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_supplier_id BIGINT;
    v_pend       NUMERIC(18,2) := COALESCE(p_pending_amount, p_total_amount);
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company" WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;

    SELECT "BranchId" INTO v_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;

    SELECT "SupplierId" INTO v_supplier_id
    FROM master."Supplier"
    WHERE "CompanyId" = v_company_id AND "SupplierCode" = p_codigo AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_supplier_id IS NULL THEN
        RETURN QUERY SELECT -1, 'proveedor_no_encontrado'::TEXT;
        RETURN;
    END IF;

    INSERT INTO ap."PayableDocument" (
        "CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber",
        "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
        "PaidFlag", "Status", "Notes", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_company_id, v_branch_id, v_supplier_id, p_document_type, p_document_number,
        COALESCE(p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        COALESCE(p_due_date, p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        p_currency_code, p_total_amount, v_pend,
        CASE WHEN v_pend <= 0 THEN TRUE ELSE FALSE END,
        CASE WHEN v_pend <= 0 THEN 'PAID' WHEN v_pend < p_total_amount THEN 'PARTIAL' ELSE 'PENDING' END,
        p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_update
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_update(BIGINT, VARCHAR(20), VARCHAR(120), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), VARCHAR(20), VARCHAR(10), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_update(
    p_id              BIGINT,
    p_document_type   VARCHAR(20)    DEFAULT NULL,
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_total_amount    NUMERIC(18,2)  DEFAULT NULL,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_status          VARCHAR(20)    DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ap."PayableDocument"
    SET "DocumentType"   = COALESCE(p_document_type, "DocumentType"),
        "DocumentNumber" = COALESCE(p_document_number, "DocumentNumber"),
        "IssueDate"      = COALESCE(p_issue_date, "IssueDate"),
        "DueDate"        = COALESCE(p_due_date, "DueDate"),
        "TotalAmount"    = COALESCE(p_total_amount, "TotalAmount"),
        "PendingAmount"  = COALESCE(p_pending_amount, "PendingAmount"),
        "Status"         = COALESCE(p_status, "Status"),
        "CurrencyCode"   = COALESCE(p_currency_code, "CurrencyCode"),
        "Notes"          = COALESCE(p_notes, "Notes"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "PayableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ap_payable_void
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ap_payable_void(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_void(
    p_id BIGINT
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ap."PayableDocument"
    SET "PendingAmount" = 0,
        "PaidFlag"      = TRUE,
        "Status"        = 'VOIDED',
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    WHERE "PayableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 4: CUENTAS POR COBRAR CRUD
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_listfull
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_listfull(VARCHAR(200), VARCHAR(24), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_listfull(
    p_search        VARCHAR(200)  DEFAULT NULL,
    p_codigo        VARCHAR(24)   DEFAULT NULL,
    p_currency_code VARCHAR(10)   DEFAULT NULL,
    p_offset        INT           DEFAULT 0,
    p_limit         INT           DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_total      BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company" WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;

    SELECT "BranchId" INTO v_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;

    SELECT COUNT(1) INTO v_total
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE d."CompanyId" = v_company_id
      AND d."BranchId"  = v_branch_id
      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR c."CustomerName" ILIKE v_search_pat))
      AND (p_codigo IS NULL OR c."CustomerCode" = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code);

    RETURN QUERY
    SELECT
        v_total,
        d."ReceivableDocumentId", c."CustomerCode", c."CustomerName",
        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",
        d."TotalAmount", d."PendingAmount", d."Status",
        d."CurrencyCode"::VARCHAR, d."Notes"
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE d."CompanyId" = v_company_id
      AND d."BranchId"  = v_branch_id
      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR c."CustomerName" ILIKE v_search_pat))
      AND (p_codigo IS NULL OR c."CustomerCode" = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)
    ORDER BY d."IssueDate" DESC, d."ReceivableDocumentId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_getbyid
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_getbyid(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_getbyid(p_id BIGINT)
RETURNS TABLE(
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."ReceivableDocumentId", c."CustomerCode", c."CustomerName",
        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",
        d."TotalAmount", d."PendingAmount", d."Status",
        d."CurrencyCode"::VARCHAR, d."Notes"
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE d."ReceivableDocumentId" = p_id;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_create
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_create(VARCHAR(24), VARCHAR(20), VARCHAR(120), DATE, DATE, VARCHAR(10), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_create(
    p_codigo          VARCHAR(24),
    p_document_type   VARCHAR(20)    DEFAULT 'FACT',
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT 'USD',
    p_total_amount    NUMERIC(18,2)  DEFAULT 0,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id  INT;
    v_branch_id   INT;
    v_customer_id BIGINT;
    v_pend        NUMERIC(18,2) := COALESCE(p_pending_amount, p_total_amount);
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company" WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;

    SELECT "BranchId" INTO v_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;

    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CompanyId" = v_company_id AND "CustomerCode" = p_codigo AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_customer_id IS NULL THEN
        RETURN QUERY SELECT -1, 'cliente_no_encontrado'::TEXT;
        RETURN;
    END IF;

    INSERT INTO ar."ReceivableDocument" (
        "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
        "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
        "PaidFlag", "Status", "Notes", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_company_id, v_branch_id, v_customer_id, p_document_type, p_document_number,
        COALESCE(p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        COALESCE(p_due_date, p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        p_currency_code, p_total_amount, v_pend,
        CASE WHEN v_pend <= 0 THEN TRUE ELSE FALSE END,
        CASE WHEN v_pend <= 0 THEN 'PAID' WHEN v_pend < p_total_amount THEN 'PARTIAL' ELSE 'PENDING' END,
        p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_update
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_update(BIGINT, VARCHAR(20), VARCHAR(120), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), VARCHAR(20), VARCHAR(10), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_update(
    p_id              BIGINT,
    p_document_type   VARCHAR(20)    DEFAULT NULL,
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_total_amount    NUMERIC(18,2)  DEFAULT NULL,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_status          VARCHAR(20)    DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ar."ReceivableDocument"
    SET "DocumentType"   = COALESCE(p_document_type, "DocumentType"),
        "DocumentNumber" = COALESCE(p_document_number, "DocumentNumber"),
        "IssueDate"      = COALESCE(p_issue_date, "IssueDate"),
        "DueDate"        = COALESCE(p_due_date, "DueDate"),
        "TotalAmount"    = COALESCE(p_total_amount, "TotalAmount"),
        "PendingAmount"  = COALESCE(p_pending_amount, "PendingAmount"),
        "Status"         = COALESCE(p_status, "Status"),
        "CurrencyCode"   = COALESCE(p_currency_code, "CurrencyCode"),
        "Notes"          = COALESCE(p_notes, "Notes"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "ReceivableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_void
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_ar_receivable_void(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_void(p_id BIGINT)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ar."ReceivableDocument"
    SET "PendingAmount" = 0,
        "PaidFlag"      = TRUE,
        "Status"        = 'VOIDED',
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    WHERE "ReceivableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 5: NOMINA (HR - Human Resources)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_resolvescope
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_resolvescope() CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_resolvescope()
RETURNS TABLE("companyId" INT, "branchId" INT, "systemUserId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        su."UserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" su
        ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_resolveuser
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_resolveuser(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_resolveuser(
    p_user_code VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE("userId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_user_code IS NOT NULL AND TRIM(p_user_code) <> '' THEN
        RETURN QUERY
        SELECT u."UserId"
        FROM sec."User" u
        WHERE UPPER(u."UserCode") = UPPER(p_user_code)
        ORDER BY u."UserId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u."UserId"
    FROM sec."User" u
    WHERE u."UserCode" = 'SYSTEM'
    ORDER BY u."UserId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getconstant
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getconstant(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getconstant(
    p_company_id INT,
    p_code       VARCHAR(60)
)
RETURNS TABLE("value" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pc."ConstantValue"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConstantCode" = p_code
      AND pc."IsActive" = TRUE
    ORDER BY pc."PayrollConstantId" DESC
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_ensuretype
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_ensuretype(INT, VARCHAR(15), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_ensuretype(
    p_company_id   INT,
    p_payroll_code VARCHAR(15),
    p_user_id      INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollType"
        WHERE "CompanyId" = p_company_id AND "PayrollCode" = p_payroll_code
    ) THEN
        INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
        VALUES (p_company_id, p_payroll_code, 'Nomina ' || p_payroll_code, TRUE, p_user_id, p_user_id);
    END IF;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_ensureemployee
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_ensureemployee(INT, VARCHAR(24), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_ensureemployee(
    p_company_id INT,
    p_document   VARCHAR(24),
    p_user_id    INT DEFAULT NULL
)
RETURNS TABLE("employeeId" BIGINT, "employeeCode" VARCHAR, "employeeName" VARCHAR, "hireDate" DATE)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
          AND ("EmployeeCode" = p_document OR "FiscalId" = p_document)
    ) INTO v_exists;

    IF v_exists THEN
        RETURN QUERY
        SELECT e."EmployeeId", e."EmployeeCode", e."EmployeeName", e."HireDate"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id AND e."IsDeleted" = FALSE
          AND (e."EmployeeCode" = p_document OR e."FiscalId" = p_document)
        ORDER BY e."EmployeeId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    INSERT INTO master."Employee" (
        "CompanyId", "EmployeeCode", "EmployeeName", "FiscalId",
        "HireDate", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_document, 'Empleado ' || p_document, p_document,
        (NOW() AT TIME ZONE 'UTC')::DATE, TRUE, p_user_id, p_user_id
    )
    RETURNING "EmployeeId", "EmployeeCode", "EmployeeName", "HireDate";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listconcepts
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listconcepts(INT, VARCHAR(15), VARCHAR(15), VARCHAR(200), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listconcepts(
    p_company_id   INT,
    p_payroll_code VARCHAR(15)  DEFAULT NULL,
    p_concept_type VARCHAR(15)  DEFAULT NULL,
    p_search       VARCHAR(200) DEFAULT NULL,
    p_offset       INT          DEFAULT 0,
    p_limit        INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codigo" VARCHAR, "codigoNomina" VARCHAR, "nombre" VARCHAR,
    "formula" VARCHAR, "sobre" VARCHAR, "clase" VARCHAR,
    "tipo" VARCHAR, "uso" VARCHAR, "bonificable" VARCHAR,
    "esAntiguedad" VARCHAR, "cuentaContable" VARCHAR,
    "aplica" VARCHAR, "valorDefecto" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "IsActive" = TRUE
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR "ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR ("ConceptCode" ILIKE v_search_pat OR "ConceptName" ILIKE v_search_pat));

    RETURN QUERY
    SELECT
        v_total,
        pc."ConceptCode", pc."PayrollCode", pc."ConceptName",
        pc."Formula", pc."BaseExpression", pc."ConceptClass",
        pc."ConceptType", pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
        CASE WHEN pc."IsSeniority"  THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag"  THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
        pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND (p_payroll_code IS NULL OR pc."PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR (pc."ConceptCode" ILIKE v_search_pat OR pc."ConceptName" ILIKE v_search_pat))
    ORDER BY pc."PayrollCode", pc."SortOrder", pc."ConceptCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_saveconcept
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_saveconcept(INT, VARCHAR(15), VARCHAR(20), VARCHAR(120), VARCHAR(500), VARCHAR(200), VARCHAR(30), VARCHAR(15), VARCHAR(30), BOOLEAN, BOOLEAN, VARCHAR(50), BOOLEAN, NUMERIC(18,4), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_saveconcept(
    p_company_id              INT,
    p_payroll_code            VARCHAR(15),
    p_concept_code            VARCHAR(20),
    p_concept_name            VARCHAR(120),
    p_formula                 VARCHAR(500)  DEFAULT NULL,
    p_base_expression         VARCHAR(200)  DEFAULT NULL,
    p_concept_class           VARCHAR(30)   DEFAULT NULL,
    p_concept_type            VARCHAR(15)   DEFAULT 'ASIGNACION',
    p_usage_type              VARCHAR(30)   DEFAULT NULL,
    p_is_bonifiable           BOOLEAN       DEFAULT FALSE,
    p_is_seniority            BOOLEAN       DEFAULT FALSE,
    p_accounting_account_code VARCHAR(50)   DEFAULT NULL,
    p_applies_flag            BOOLEAN       DEFAULT TRUE,
    p_default_value           NUMERIC(18,4) DEFAULT 0,
    p_user_id                 INT           DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConceptId" INTO v_existing_id
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "ConceptCode" = p_concept_code
      AND "ConventionCode" IS NULL
      AND "CalculationType" IS NULL
    ORDER BY "PayrollConceptId"
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConcept"
        SET "ConceptName"           = p_concept_name,
            "Formula"               = p_formula,
            "BaseExpression"        = p_base_expression,
            "ConceptClass"          = p_concept_class,
            "ConceptType"           = p_concept_type,
            "UsageType"             = p_usage_type,
            "IsBonifiable"          = p_is_bonifiable,
            "IsSeniority"           = p_is_seniority,
            "AccountingAccountCode" = p_accounting_account_code,
            "AppliesFlag"           = p_applies_flag,
            "DefaultValue"          = p_default_value,
            "UpdatedAt"             = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"       = p_user_id
        WHERE "PayrollConceptId" = v_existing_id;
    ELSE
        INSERT INTO hr."PayrollConcept" (
            "CompanyId", "PayrollCode", "ConceptCode", "ConceptName",
            "Formula", "BaseExpression", "ConceptClass", "ConceptType",
            "UsageType", "IsBonifiable", "IsSeniority", "AccountingAccountCode",
            "AppliesFlag", "DefaultValue", "ConventionCode", "CalculationType",
            "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_payroll_code, p_concept_code, p_concept_name,
            p_formula, p_base_expression, p_concept_class, p_concept_type,
            p_usage_type, p_is_bonifiable, p_is_seniority, p_accounting_account_code,
            p_applies_flag, p_default_value, NULL, NULL,
            0, TRUE, p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT 1, 'Concepto guardado'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_loadconceptsforrun
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_loadconceptsforrun(INT, VARCHAR(15), VARCHAR(15), VARCHAR(30), VARCHAR(30), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_loadconceptsforrun(
    p_company_id       INT,
    p_payroll_code     VARCHAR(15),
    p_concept_type     VARCHAR(15)  DEFAULT NULL,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL,
    p_solo_legales     BOOLEAN      DEFAULT FALSE
)
RETURNS TABLE(
    "conceptCode" VARCHAR, "conceptName" VARCHAR, "conceptType" VARCHAR,
    "defaultValue" NUMERIC, "formula" VARCHAR, "accountingAccountCode" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."ConceptType",
        pc."DefaultValue", pc."Formula", pc."AccountingAccountCode"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId"   = p_company_id
      AND pc."PayrollCode" = p_payroll_code
      AND pc."IsActive"    = TRUE
      AND pc."AppliesFlag" = TRUE
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (
            (p_solo_legales AND (
                (p_convention_code IS NOT NULL AND pc."ConventionCode" = p_convention_code)
                OR
                (p_convention_code IS NULL AND pc."ConventionCode" IS NOT NULL)
            ))
            OR
            (NOT p_solo_legales AND (
                (p_convention_code IS NOT NULL AND (pc."ConventionCode" = p_convention_code OR pc."ConventionCode" IS NULL))
                OR
                (p_convention_code IS NULL)
            ))
          )
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type OR pc."CalculationType" IS NULL)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertrun
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertrun(INT, INT, VARCHAR(15), BIGINT, VARCHAR(24), VARCHAR(200), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(50), INT, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertrun(
    p_company_id         INT,
    p_branch_id          INT,
    p_payroll_code       VARCHAR(15),
    p_employee_id        BIGINT,
    p_employee_code      VARCHAR(24),
    p_employee_name      VARCHAR(200),
    p_from_date          DATE,
    p_to_date            DATE,
    p_total_assignments  NUMERIC(18,2),
    p_total_deductions   NUMERIC(18,2),
    p_net_total          NUMERIC(18,2),
    p_payroll_type_name  VARCHAR(50)  DEFAULT NULL,
    p_user_id            INT          DEFAULT NULL,
    p_lines_json         TEXT         DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_run_id BIGINT;
BEGIN
    -- Buscar run existente
    SELECT "PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun"
    WHERE "CompanyId"    = p_company_id
      AND "BranchId"     = p_branch_id
      AND "PayrollCode"  = p_payroll_code
      AND "EmployeeCode" = p_employee_code
      AND "DateFrom"     = p_from_date
      AND "DateTo"       = p_to_date
      AND "RunSource"    = 'MANUAL'
    ORDER BY "PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NOT NULL THEN
        UPDATE hr."PayrollRun"
        SET "ProcessDate"      = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAssignments" = p_total_assignments,
            "TotalDeductions"  = p_total_deductions,
            "NetTotal"         = p_net_total,
            "PayrollTypeName"  = COALESCE(p_payroll_type_name, "PayrollTypeName"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "PayrollRunId" = v_run_id;

        DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    ELSE
        INSERT INTO hr."PayrollRun" (
            "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "PositionName", "ProcessDate", "DateFrom", "DateTo",
            "TotalAssignments", "TotalDeductions", "NetTotal", "PayrollTypeName",
            "RunSource", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_employee_id, p_employee_code,
            p_employee_name, NULL, (NOW() AT TIME ZONE 'UTC')::DATE, p_from_date, p_to_date,
            p_total_assignments, p_total_deductions, p_net_total, p_payroll_type_name,
            'MANUAL', p_user_id, p_user_id
        )
        RETURNING "PayrollRunId" INTO v_run_id;
    END IF;

    -- Insertar lineas desde JSON
    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        INSERT INTO hr."PayrollRunLine" (
            "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode"
        )
        SELECT
            v_run_id,
            elem->>'code',
            elem->>'name',
            elem->>'type',
            (elem->>'quantity')::NUMERIC(18,4),
            (elem->>'amount')::NUMERIC(18,4),
            (elem->>'total')::NUMERIC(18,2),
            elem->>'description',
            elem->>'account'
        FROM jsonb_array_elements(p_lines_json::JSONB) AS elem;
    END IF;

    RETURN QUERY SELECT 1, 'ok'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en upsert run: ' || SQLERRM)::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listactiveemployees
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listactiveemployees(INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listactiveemployees(
    p_company_id   INT,
    p_solo_activos BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("employeeCode" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND e."IsDeleted" = FALSE
      AND (NOT p_solo_activos OR e."IsActive" = TRUE)
    ORDER BY e."EmployeeCode";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listruns
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listruns(INT, VARCHAR(15), VARCHAR(24), DATE, DATE, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listruns(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15)  DEFAULT NULL,
    p_employee_code VARCHAR(24)  DEFAULT NULL,
    p_from_date     DATE         DEFAULT NULL,
    p_to_date       DATE         DEFAULT NULL,
    p_solo_abiertas BOOLEAN      DEFAULT FALSE,
    p_offset        INT          DEFAULT 0,
    p_limit         INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "nomina" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "cargo" VARCHAR, "fechaProceso" DATE, "fechaInicio" DATE, "fechaHasta" DATE,
    "totalAsignaciones" NUMERIC, "totalDeducciones" NUMERIC, "totalNeto" NUMERIC,
    "cerrada" BOOLEAN, "tipoNomina" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollRun"
    WHERE "CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR "DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR "DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR "IsClosed" = FALSE);

    RETURN QUERY
    SELECT
        v_total,
        pr."PayrollCode", pr."EmployeeCode", pr."EmployeeName",
        pr."PositionName", pr."ProcessDate", pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR pr."PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR pr."EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR pr."DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR pr."DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE)
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_closerun
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_closerun(INT, VARCHAR(15), VARCHAR(24), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_closerun(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15),
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_user_id       INT         DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_affected INT;
BEGIN
    UPDATE hr."PayrollRun"
    SET "IsClosed"        = TRUE,
        "ClosedAt"        = NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"  = p_user_id,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId"   = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "IsClosed"    = FALSE
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected > 0 THEN
        RETURN QUERY SELECT v_affected, 'Nomina cerrada'::TEXT;
    ELSE
        RETURN QUERY SELECT 0, 'No se encontraron registros abiertos'::TEXT;
    END IF;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertvacation
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertvacation(INT, INT, VARCHAR(60), BIGINT, VARCHAR(24), VARCHAR(200), DATE, DATE, DATE, NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertvacation(
    p_company_id        INT,
    p_branch_id         INT,
    p_vacation_code     VARCHAR(60),
    p_employee_id       BIGINT,
    p_employee_code     VARCHAR(24),
    p_employee_name     VARCHAR(200),
    p_start_date        DATE,
    p_end_date          DATE,
    p_reintegration_date DATE DEFAULT NULL,
    p_total_amount      NUMERIC(18,2) DEFAULT 0,
    p_user_id           INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_vacation_id BIGINT;
BEGIN
    SELECT "VacationProcessId" INTO v_vacation_id
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id AND "VacationCode" = p_vacation_code
    LIMIT 1;

    IF v_vacation_id IS NOT NULL THEN
        UPDATE hr."VacationProcess"
        SET "EmployeeId"         = p_employee_id,
            "EmployeeCode"       = p_employee_code,
            "EmployeeName"       = p_employee_name,
            "StartDate"          = p_start_date,
            "EndDate"            = p_end_date,
            "ReintegrationDate"  = p_reintegration_date,
            "ProcessDate"        = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAmount"        = p_total_amount,
            "CalculatedAmount"   = p_total_amount,
            "UpdatedAt"          = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"    = p_user_id
        WHERE "VacationProcessId" = v_vacation_id;
    ELSE
        INSERT INTO hr."VacationProcess" (
            "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "StartDate", "EndDate", "ReintegrationDate",
            "ProcessDate", "TotalAmount", "CalculatedAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_vacation_code, p_employee_id, p_employee_code,
            p_employee_name, p_start_date, p_end_date, p_reintegration_date,
            (NOW() AT TIME ZONE 'UTC')::DATE, p_total_amount, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "VacationProcessId" INTO v_vacation_id;
    END IF;

    DELETE FROM hr."VacationProcessLine" WHERE "VacationProcessId" = v_vacation_id;

    INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES (v_vacation_id, 'VACACIONES', 'Pago de vacaciones', p_total_amount);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listvacations
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listvacations(INT, VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listvacations(
    p_company_id    INT,
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_offset        INT         DEFAULT 0,
    p_limit         INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "vacacion" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "inicio" DATE, "hasta" DATE, "reintegro" DATE,
    "fechaCalculo" DATE, "total" NUMERIC, "totalCalculado" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        vp."VacationCode", vp."EmployeeCode", vp."EmployeeName",
        vp."StartDate", vp."EndDate", vp."ReintegrationDate",
        vp."ProcessDate", vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR vp."EmployeeCode" = p_employee_code)
    ORDER BY vp."VacationProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertsettlement
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertsettlement(INT, INT, VARCHAR(60), BIGINT, VARCHAR(24), VARCHAR(200), DATE, VARCHAR(120), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertsettlement(
    p_company_id       INT,
    p_branch_id        INT,
    p_settlement_code  VARCHAR(60),
    p_employee_id      BIGINT,
    p_employee_code    VARCHAR(24),
    p_employee_name    VARCHAR(200),
    p_retirement_date  DATE,
    p_retirement_cause VARCHAR(120) DEFAULT NULL,
    p_total_amount     NUMERIC(18,2) DEFAULT 0,
    p_prestaciones     NUMERIC(18,2) DEFAULT 0,
    p_vac_pendientes   NUMERIC(18,2) DEFAULT 0,
    p_bono_salida      NUMERIC(18,2) DEFAULT 0,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_settlement_id BIGINT;
BEGIN
    SELECT "SettlementProcessId" INTO v_settlement_id
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id AND "SettlementCode" = p_settlement_code
    LIMIT 1;

    IF v_settlement_id IS NOT NULL THEN
        UPDATE hr."SettlementProcess"
        SET "EmployeeId"      = p_employee_id,
            "EmployeeCode"    = p_employee_code,
            "EmployeeName"    = p_employee_name,
            "RetirementDate"  = p_retirement_date,
            "RetirementCause" = p_retirement_cause,
            "TotalAmount"     = p_total_amount,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "SettlementProcessId" = v_settlement_id;
    ELSE
        INSERT INTO hr."SettlementProcess" (
            "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "RetirementDate", "RetirementCause", "TotalAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_settlement_code, p_employee_id, p_employee_code,
            p_employee_name, p_retirement_date, p_retirement_cause, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "SettlementProcessId" INTO v_settlement_id;
    END IF;

    DELETE FROM hr."SettlementProcessLine" WHERE "SettlementProcessId" = v_settlement_id;

    INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES
        (v_settlement_id, 'PRESTACIONES', 'Prestaciones sociales', p_prestaciones),
        (v_settlement_id, 'VACACIONES_PEND', 'Vacaciones pendientes', p_vac_pendientes),
        (v_settlement_id, 'BONO_SALIDA', 'Bono de salida', p_bono_salida);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listsettlements
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listsettlements(INT, VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listsettlements(
    p_company_id    INT,
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_offset        INT         DEFAULT 0,
    p_limit         INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "liquidacion" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "fechaRetiro" DATE, "causaRetiro" VARCHAR, "total" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        sp."SettlementCode", sp."EmployeeCode", sp."EmployeeName",
        sp."RetirementDate", sp."RetirementCause", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR sp."EmployeeCode" = p_employee_code)
    ORDER BY sp."SettlementProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listconstants
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_listconstants(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listconstants(
    p_company_id INT,
    p_offset     INT DEFAULT 0,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codigo" VARCHAR, "nombre" VARCHAR, "valor" NUMERIC,
    "origen" VARCHAR, "activo" BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id;

    RETURN QUERY
    SELECT
        v_total,
        pc."ConstantCode", pc."ConstantName", pc."ConstantValue",
        pc."SourceName", pc."IsActive"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
    ORDER BY pc."ConstantCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_saveconstant
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_saveconstant(INT, VARCHAR(60), VARCHAR(200), NUMERIC(18,4), VARCHAR(120), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_saveconstant(
    p_company_id  INT,
    p_code        VARCHAR(60),
    p_name        VARCHAR(200)   DEFAULT NULL,
    p_value       NUMERIC(18,4)  DEFAULT NULL,
    p_source_name VARCHAR(120)   DEFAULT NULL,
    p_user_id     INT            DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConstantId" INTO v_existing_id
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id AND "ConstantCode" = p_code
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"    = COALESCE(p_name, "ConstantName"),
            "ConstantValue"   = COALESCE(p_value, "ConstantValue"),
            "SourceName"      = COALESCE(p_source_name, "SourceName"),
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "PayrollConstantId" = v_existing_id;

        RETURN QUERY SELECT v_existing_id::INT, 'Constante actualizada'::VARCHAR;
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue",
            "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_code, COALESCE(p_name, p_code), COALESCE(p_value, 0),
            p_source_name, TRUE, p_user_id, p_user_id
        );

        RETURN QUERY SELECT 1::INT, 'Constante creada'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 6: CONCEPTOS LEGALES DE NOMINA
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_list
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_legalconcept_list(INT, VARCHAR(30), VARCHAR(30), VARCHAR(15), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_list(
    p_company_id       INT,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL,
    p_concept_type     VARCHAR(15)  DEFAULT NULL,
    p_solo_activos     BOOLEAN      DEFAULT TRUE
)
RETURNS TABLE(
    "id" BIGINT, "convencion" VARCHAR, "tipoCalculo" VARCHAR,
    "coConcept" VARCHAR, "nbConcepto" VARCHAR, "formula" VARCHAR,
    "sobre" VARCHAR, "tipo" VARCHAR, "bonificable" VARCHAR,
    "lotttArticulo" VARCHAR, "ccpClausula" VARCHAR,
    "orden" INT, "activo" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."PayrollConceptId", pc."ConventionCode", pc."CalculationType",
        pc."ConceptCode", pc."ConceptName", pc."Formula",
        pc."BaseExpression", pc."ConceptType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        pc."LotttArticle", pc."CcpClause",
        pc."SortOrder", pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND (NOT p_solo_activos OR pc."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
    ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_validateformulas
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_legalconcept_validateformulas(INT, VARCHAR(30), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_validateformulas(
    p_company_id       INT,
    p_convention_code  VARCHAR(30) DEFAULT NULL,
    p_calculation_type VARCHAR(30) DEFAULT NULL
)
RETURNS TABLE("coConcept" VARCHAR, "nbConcepto" VARCHAR, "formula" VARCHAR, "defaultValue" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."Formula", pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND pc."IsActive" = TRUE
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_listconventions
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_legalconcept_listconventions(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_listconventions(
    p_company_id INT
)
RETURNS TABLE(
    "Convencion" VARCHAR, "TotalConceptos" BIGINT,
    "ConceptosMensual" BIGINT, "ConceptosVacaciones" BIGINT,
    "ConceptosLiquidacion" BIGINT, "OrdenInicio" INT, "OrdenFin" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConventionCode",
        COUNT(1),
        COUNT(CASE WHEN pc."CalculationType" = 'MENSUAL' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'VACACIONES' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'LIQUIDACION' THEN 1 END),
        MIN(pc."SortOrder"),
        MAX(pc."SortOrder")
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND pc."ConventionCode" IS NOT NULL
    GROUP BY pc."ConventionCode"
    ORDER BY pc."ConventionCode";
END;
$$;
-- +goose StatementEnd


-- =============================================================================
--  SECCION 7: SPs auxiliares para detalle (recordset unico)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getrunheader
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getrunheader(INT, VARCHAR(15), VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getrunheader(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15),
    p_employee_code VARCHAR(24)
)
RETURNS TABLE(
    "runId" BIGINT, "nomina" VARCHAR, "cedula" VARCHAR,
    "nombreEmpleado" VARCHAR, "cargo" VARCHAR, "fechaProceso" DATE,
    "fechaInicio" DATE, "fechaHasta" DATE,
    "totalAsignaciones" NUMERIC, "totalDeducciones" NUMERIC, "totalNeto" NUMERIC,
    "cerrada" BOOLEAN, "tipoNomina" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pr."PayrollRunId", pr."PayrollCode", pr."EmployeeCode",
        pr."EmployeeName", pr."PositionName", pr."ProcessDate",
        pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId"    = p_company_id
      AND pr."PayrollCode"  = p_payroll_code
      AND pr."EmployeeCode" = p_employee_code
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getrunlines
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getrunlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getrunlines(p_run_id BIGINT)
RETURNS TABLE(
    "coConcepto" VARCHAR, "nombreConcepto" VARCHAR, "tipoConcepto" VARCHAR,
    "cantidad" NUMERIC, "monto" NUMERIC, "total" NUMERIC,
    "descripcion" TEXT, "cuentaContable" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        rl."ConceptCode", rl."ConceptName", rl."ConceptType",
        rl."Quantity", rl."Amount", rl."Total",
        rl."DescriptionText", rl."AccountingAccountCode"
    FROM hr."PayrollRunLine" rl
    WHERE rl."PayrollRunId" = p_run_id
    ORDER BY rl."PayrollRunLineId";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getvacationheader
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getvacationheader(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getvacationheader(
    p_company_id   INT,
    p_vacation_code VARCHAR(60)
)
RETURNS TABLE(
    "id" BIGINT, "vacacion" VARCHAR, "cedula" VARCHAR,
    "nombreEmpleado" VARCHAR, "inicio" DATE, "hasta" DATE,
    "reintegro" DATE, "fechaCalculo" DATE,
    "total" NUMERIC, "totalCalculado" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        vp."VacationProcessId", vp."VacationCode", vp."EmployeeCode",
        vp."EmployeeName", vp."StartDate", vp."EndDate",
        vp."ReintegrationDate", vp."ProcessDate",
        vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id AND vp."VacationCode" = p_vacation_code
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getvacationlines
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getvacationlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getvacationlines(p_vacation_process_id BIGINT)
RETURNS TABLE("codigo" VARCHAR, "nombre" VARCHAR, "monto" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT vl."ConceptCode", vl."ConceptName", vl."Amount"
    FROM hr."VacationProcessLine" vl
    WHERE vl."VacationProcessId" = p_vacation_process_id
    ORDER BY vl."VacationProcessLineId";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getsettlementheader
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getsettlementheader(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getsettlementheader(
    p_company_id      INT,
    p_settlement_code VARCHAR(60)
)
RETURNS TABLE("id" BIGINT, "total" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sp."SettlementProcessId", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id AND sp."SettlementCode" = p_settlement_code
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getsettlementlines
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_payroll_getsettlementlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getsettlementlines(p_settlement_process_id BIGINT)
RETURNS TABLE("codigo" VARCHAR, "nombre" VARCHAR, "monto" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sl."ConceptCode", sl."ConceptName", sl."Amount"
    FROM hr."SettlementProcessLine" sl
    WHERE sl."SettlementProcessId" = p_settlement_process_id
    ORDER BY sl."SettlementProcessLineId";
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_DeleteConcept — soft-delete (IsActive = FALSE)
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_hr_payroll_deleteconcept(
    p_company_id   INT,
    p_concept_code VARCHAR(20)
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE hr."PayrollConcept"
    SET "IsActive" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id
      AND "ConceptCode" = p_concept_code
      AND "IsActive" = TRUE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT -1, 'Concepto no encontrado o ya desactivado'::VARCHAR(500);
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Concepto desactivado'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_DeleteConstant — soft-delete (IsActive = FALSE)
-- -----------------------------------------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_hr_payroll_deleteconstant(
    p_company_id    INT,
    p_constant_code VARCHAR(50)
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE hr."PayrollConstant"
    SET "IsActive" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id
      AND "ConstantCode" = p_constant_code
      AND "IsActive" = TRUE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT -1, 'Constante no encontrada o ya desactivada'::VARCHAR(500);
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Constante desactivada'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- Source: sp_vacation_request.sql

-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_vacation_request.sql
-- Flujo de trabajo de solicitudes de vacaciones (RRHH)
-- Depende de: hr.VacationRequest, hr.VacationRequestDay,
--             master.Employee, hr.VacationProcess
-- ============================================================

-- =============================================================
-- 1) usp_hr_vacation_request_create
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_create(INT, INT, VARCHAR, DATE, DATE, INT, BOOLEAN, VARCHAR, JSONB) CASCADE;

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_create(
    p_company_id    INT,
    p_branch_id     INT,
    p_employee_code VARCHAR(60),
    p_start_date    DATE,
    p_end_date      DATE,
    p_total_days    INT,
    p_is_partial    BOOLEAN,
    p_notes         VARCHAR(500),
    p_days          JSONB DEFAULT NULL  -- [{"dt":"2026-03-16", "tp":"COMPLETO"}, ...]
)
RETURNS TABLE (
    "RequestId" BIGINT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_request_id BIGINT;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION 'La fecha fin no puede ser anterior a la fecha inicio.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_total_days <= 0 THEN
        RAISE EXCEPTION 'El total de dias debe ser mayor a cero.'
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO hr."VacationRequest" (
        "CompanyId", "BranchId", "EmployeeCode",
        "StartDate", "EndDate", "TotalDays",
        "IsPartial", "Notes"
    )
    VALUES (
        p_company_id, p_branch_id, p_employee_code,
        p_start_date, p_end_date, p_total_days,
        p_is_partial, p_notes
    )
    RETURNING "RequestId" INTO v_request_id;

    -- Insertar dias desde JSONB: [{"dt":"2026-03-16", "tp":"COMPLETO"}, ...]
    IF p_days IS NOT NULL AND jsonb_array_length(p_days) > 0 THEN
        INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
        SELECT
            v_request_id,
            (elem->>'dt')::DATE,
            COALESCE(NULLIF(elem->>'tp', ''::VARCHAR), 'COMPLETO')
          FROM jsonb_array_elements(p_days) AS elem
         WHERE elem->>'dt' IS NOT NULL;
    END IF;

    RETURN QUERY SELECT v_request_id;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 2) usp_hr_vacation_request_list
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_list(
    p_company_id    INT,
    p_employee_code VARCHAR(60) DEFAULT NULL,
    p_status        VARCHAR(20) DEFAULT NULL,
    p_offset        INT DEFAULT 0,
    p_limit         INT DEFAULT 50
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "ApprovedBy"      VARCHAR,
    "Notes"           VARCHAR,
    "RejectionReason" VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount"      INT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_total_count INT;
BEGIN
    SELECT COUNT(*)
      INTO v_total_count
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status);

    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."RejectionReason"::VARCHAR,
        vr."CreatedAt",
        v_total_count
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status)
     ORDER BY vr."RequestDate" DESC, vr."RequestId" DESC
     LIMIT p_limit
    OFFSET p_offset;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 3) usp_hr_vacation_request_get
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get(
    p_request_id BIGINT
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "CompanyId"       INT,
    "BranchId"        INT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "Notes"           VARCHAR,
    "ApprovedBy"      VARCHAR,
    "ApprovalDate"    TIMESTAMP,
    "RejectionReason" VARCHAR,
    "VacationId"      BIGINT,
    "CreatedAt"       TIMESTAMP,
    "UpdatedAt"       TIMESTAMP
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."CompanyId",
        vr."BranchId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."ApprovalDate",
        vr."RejectionReason"::VARCHAR,
        vr."VacationId",
        vr."CreatedAt",
        vr."UpdatedAt"
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."RequestId" = p_request_id;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 3b) usp_hr_vacation_request_get_days
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get_days(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_days(
    p_request_id BIGINT
)
RETURNS TABLE (
    "DayId"        BIGINT,
    "RequestId"    BIGINT,
    "SelectedDate" VARCHAR,
    "DayType"      VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        d."DayId",
        d."RequestId",
        TO_CHAR(d."SelectedDate", 'YYYY-MM-DD')::VARCHAR AS "SelectedDate",
        d."DayType"::VARCHAR
      FROM hr."VacationRequestDay" d
     WHERE d."RequestId" = p_request_id
     ORDER BY d."SelectedDate";
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 4) usp_hr_vacation_request_approve
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_approve(BIGINT, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_approve(
    p_request_id  BIGINT,
    p_approved_by VARCHAR(60)
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden aprobar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"       = 'APROBADA',
           "ApprovedBy"   = p_approved_by,
           "ApprovalDate" = NOW() AT TIME ZONE 'UTC',
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'APROBADA'::VARCHAR;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 5) usp_hr_vacation_request_reject
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_reject(BIGINT, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_reject(
    p_request_id       BIGINT,
    p_approved_by      VARCHAR(60),
    p_rejection_reason VARCHAR(500)
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden rechazar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"          = 'RECHAZADA',
           "ApprovedBy"      = p_approved_by,
           "ApprovalDate"    = NOW() AT TIME ZONE 'UTC',
           "RejectionReason" = p_rejection_reason,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'RECHAZADA'::VARCHAR;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 6) usp_hr_vacation_request_cancel
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_cancel(BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_cancel(
    p_request_id BIGINT
)
RETURNS TABLE (
    "RequestId" BIGINT,
    "Status"    VARCHAR
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden cancelar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"    = 'CANCELADA',
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'CANCELADA'::VARCHAR;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 7) usp_hr_vacation_request_process
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_process(BIGINT, BIGINT);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_process(
    p_request_id  BIGINT,
    p_vacation_id BIGINT
)
RETURNS TABLE (
    "RequestId"  BIGINT,
    "Status"     VARCHAR,
    "VacationId" BIGINT
)
LANGUAGE plpgsql
AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'APROBADA'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden procesar solicitudes en estado APROBADA.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"     = 'PROCESADA',
           "VacationId" = p_vacation_id,
           "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'APROBADA';

    RETURN QUERY SELECT p_request_id, 'PROCESADA'::VARCHAR, p_vacation_id;
END;
$fn$;
-- +goose StatementEnd


-- =============================================================
-- 8) usp_hr_vacation_request_get_available_days
-- =============================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacation_request_get_available_days(INT, VARCHAR);

CREATE OR REPLACE FUNCTION usp_hr_vacation_request_get_available_days(
    p_company_id    INT,
    p_employee_code VARCHAR(60)
)
RETURNS TABLE (
    "DiasBase"        INT,
    "AnosServicio"    INT,
    "DiasAdicionales" INT,
    "DiasDisponibles" INT,
    "DiasTomados"     INT,
    "DiasPendientes"  INT,
    "DiasSaldo"       INT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_hire_date         DATE;
    v_anos_servicio     INT;
    v_dias_base         INT := 15;
    v_dias_adicionales  INT;
    v_dias_disponibles  INT;
    v_dias_tomados      INT;
    v_dias_pendientes   INT;
BEGIN
    SELECT e."HireDate"
      INTO v_hire_date
      FROM master."Employee" e
     WHERE e."CompanyId" = p_company_id
       AND e."EmployeeCode" = p_employee_code
       AND COALESCE(e."IsDeleted", FALSE) = FALSE;

    IF v_hire_date IS NULL THEN
        RETURN QUERY SELECT
            v_dias_base,
            0,
            0,
            v_dias_base,
            0,
            0,
            v_dias_base;
        RETURN;
    END IF;

    -- Calcular anos de servicio
    v_anos_servicio := EXTRACT(YEAR FROM age(NOW() AT TIME ZONE 'UTC', v_hire_date))::INT;
    IF v_anos_servicio < 0 THEN
        v_anos_servicio := 0;
    END IF;

    v_dias_adicionales := v_anos_servicio;
    v_dias_disponibles := v_dias_base + v_dias_adicionales;

    -- Dias ya procesados (disfrutados) en el ano actual
    SELECT COALESCE(SUM((vp."EndDate" - vp."StartDate") + 1), 0)
      INTO v_dias_tomados
      FROM hr."VacationProcess" vp
     WHERE vp."CompanyId" = p_company_id
       AND vp."EmployeeCode" = p_employee_code
       AND EXTRACT(YEAR FROM vp."StartDate") = EXTRACT(YEAR FROM (NOW() AT TIME ZONE 'UTC'));

    -- Dias en solicitudes pendientes o aprobadas
    SELECT COALESCE(SUM(vr."TotalDays"), 0)
      INTO v_dias_pendientes
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND vr."EmployeeCode" = p_employee_code
       AND vr."Status" IN ('PENDIENTE', 'APROBADA');

    RETURN QUERY SELECT
        v_dias_base,
        v_anos_servicio,
        v_dias_adicionales,
        v_dias_disponibles,
        v_dias_tomados,
        v_dias_pendientes,
        (v_dias_disponibles - COALESCE(v_dias_tomados, 0) - COALESCE(v_dias_pendientes, 0));
END;
$fn$;
-- +goose StatementEnd

-- ================================================================
-- ALIAS: usp_hr_vacationrequest_list
-- Alias for usp_hr_vacation_request_list to match API calling convention
-- (usp_HR_VacationRequest_List â†’ usp_hr_vacationrequest_list)
-- ================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_hr_vacationrequest_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_vacationrequest_list(
    p_company_id    INT,
    p_employee_code VARCHAR(60) DEFAULT NULL,
    p_status        VARCHAR(20) DEFAULT NULL,
    p_offset        INT DEFAULT 0,
    p_limit         INT DEFAULT 50
)
RETURNS TABLE (
    "RequestId"       BIGINT,
    "EmployeeCode"    VARCHAR,
    "EmployeeName"    VARCHAR,
    "RequestDate"     VARCHAR,
    "StartDate"       VARCHAR,
    "EndDate"         VARCHAR,
    "TotalDays"       INT,
    "IsPartial"       BOOLEAN,
    "Status"          VARCHAR,
    "ApprovedBy"      VARCHAR,
    "Notes"           VARCHAR,
    "RejectionReason" VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount"      INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM usp_hr_vacation_request_list(
        p_company_id, p_employee_code, p_status, p_offset, p_limit
    );
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GenerateDraft CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_SaveDraftLine CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchAddLine CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchRemoveLine CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Header CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_ByDept CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary_Alerts CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftGrid CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetEmployeeLines CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ApproveDraft CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ProcessBatch CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ListBatches CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_BatchBulkUpdate CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_GetDraftSummary CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_reemplazar_variables CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_evaluar_formula CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_concepto CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_procesar_empleado CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_procesar_nomina CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_cargar_constantes_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_vacaciones_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_utilidades_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_prestaciones_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_preparar_variables_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_procesar_empleado_regimen CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_cargar_constantes_desde_concepto_legal CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_procesar_empleado_concepto_legal CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_conceptos_legales_list CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_validar_formulas_concepto_legal CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_list CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_validateformulas CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_listconventions CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Conceptos_List CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Concepto_Save CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_List CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Get CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Get_Lines CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Cerrar CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_List CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_Get CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Vacaciones_Get_Lines CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Liquidaciones_List CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Constantes_List CASCADE;
DROP FUNCTION IF EXISTS public.sp_Nomina_Constante_Save CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_list CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_get CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_save CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_delete CASCADE;
DROP FUNCTION IF EXISTS public.fn_evaluar_expr CASCADE;
DROP FUNCTION IF EXISTS public.fn_nomina_get_variable CASCADE;
DROP FUNCTION IF EXISTS public.fn_nomina_contar_feriados CASCADE;
DROP FUNCTION IF EXISTS public.fn_nomina_contar_domingos CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_get_scope CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_limpiar_variables CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_set_variable CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_cargar_constantes CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_antiguedad CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_preparar_variables_base CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_salarios_promedio CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_dias_vacaciones CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_procesar_vacaciones CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_liquidacion CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_get_liquidacion_header CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_get_liquidacion_lines CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_get_liquidacion_totals CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_limpiar_variables_compat CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_set_variable_compat CASCADE;
DROP FUNCTION IF EXISTS public.sp_nomina_calcular_antiguedad_compat CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_applypayment CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_list CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_getpending CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_balance_getbycustomer CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_applypayment CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_list CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_getpending CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_balance_getbysupplier CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_listfull CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_getbyid CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_create CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_update CASCADE;
DROP FUNCTION IF EXISTS public.usp_ap_payable_void CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_listfull CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_getbyid CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_create CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_update CASCADE;
DROP FUNCTION IF EXISTS public.usp_ar_receivable_void CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_resolvescope CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_resolveuser CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getconstant CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_ensuretype CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_ensureemployee CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listconcepts CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_saveconcept CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_loadconceptsforrun CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_upsertrun CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listactiveemployees CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listruns CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_closerun CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_upsertvacation CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listvacations CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_upsertsettlement CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listsettlements CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listconstants CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_saveconstant CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getrunheader CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getrunlines CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getvacationheader CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getvacationlines CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getsettlementheader CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getsettlementlines CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_deleteconcept CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_payroll_deleteconstant CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_create CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_list CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_get CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_get_days CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_approve CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_reject CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_cancel CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_process CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacation_request_get_available_days CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_list CASCADE;
