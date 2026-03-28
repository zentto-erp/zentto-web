-- =============================================================================
-- sp_rrhh_salud_ocupacional.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_salud_ocupacional.sql
-- Fecha conversiÃ³n: 2026-03-16
--
-- Salud Ocupacional / Occupational Health
-- Cubre: INPSASEL (VE), OSHA (US), PRL (ES), SG-SST (CO)
-- Tablas: hr.OccupationalHealth, hr.MedicalExam, hr.MedicalOrder,
--         hr.TrainingRecord, hr.SafetyCommittee, hr.SafetyCommitteeMember,
--         hr.SafetyCommitteeMeeting
--
-- Funciones (19 en total):
--   1.  usp_HR_OccHealth_Create                   - Crear registro de salud ocupacional
--   2.  usp_HR_OccHealth_Update                   - Actualizar registro
--   3.  usp_HR_OccHealth_List                     - Listado paginado
--   4.  usp_HR_OccHealth_Get                      - Obtener por ID
--   5.  usp_HR_MedExam_Save                       - Crear/actualizar examen mÃ©dico
--   6.  usp_HR_MedExam_List                       - Listado paginado
--   7.  usp_HR_MedExam_GetPending                 - ExÃ¡menes vencidos/por vencer
--   8.  usp_HR_MedOrder_Create                    - Crear orden mÃ©dica
--   9.  usp_HR_MedOrder_Approve                   - Aprobar/rechazar orden
--   10. usp_HR_MedOrder_List                      - Listado paginado
--   11. usp_HR_Training_Save                      - Crear/actualizar capacitaciÃ³n
--   12. usp_HR_Training_List                      - Listado paginado
--   13. usp_HR_Training_GetEmployeeCertifications - Certificaciones de empleado
--   14. usp_HR_Committee_Save                     - Crear/actualizar comitÃ©
--   15. usp_HR_Committee_AddMember                - Agregar miembro
--   16. usp_HR_Committee_RemoveMember             - Remover miembro
--   17. usp_HR_Committee_RecordMeeting            - Registrar reuniÃ³n
--   18. usp_HR_Committee_List                     - Listado paginado de comitÃ©s
--   19. usp_HR_Committee_GetMeetings              - Reuniones paginadas de un comitÃ©
-- =============================================================================

-- =============================================================================
-- 1. usp_HR_OccHealth_Create
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Create(INTEGER, CHAR(2), VARCHAR(25), BIGINT, VARCHAR(24), VARCHAR(200), TIMESTAMP, TIMESTAMP, TIMESTAMP, VARCHAR(15), VARCHAR(100), INTEGER, VARCHAR(200), TEXT, VARCHAR(500), VARCHAR(500), DATE, VARCHAR(100), VARCHAR(500), VARCHAR(500), INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Create(
    p_company_id                INTEGER,
    p_country_code              CHAR(2),
    p_record_type               VARCHAR(25),
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_occurrence_date           TIMESTAMP       DEFAULT NULL,
    p_report_deadline           TIMESTAMP       DEFAULT NULL,
    p_reported_date             TIMESTAMP       DEFAULT NULL,
    p_severity                  VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected        VARCHAR(100)    DEFAULT NULL,
    p_days_lost                 INTEGER         DEFAULT NULL,
    p_location                  VARCHAR(200)    DEFAULT NULL,
    p_description               TEXT            DEFAULT NULL,
    p_root_cause                VARCHAR(500)    DEFAULT NULL,
    p_corrective_action         VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date    DATE            DEFAULT NULL,
    p_institution_reference     VARCHAR(100)    DEFAULT NULL,
    p_document_url              VARCHAR(500)    DEFAULT NULL,
    p_notes                     VARCHAR(500)    DEFAULT NULL,
    p_created_by                INTEGER         DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 2. usp_HR_OccHealth_Update
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Update(INTEGER, INTEGER, TIMESTAMP, VARCHAR(15), VARCHAR(100), INTEGER, VARCHAR(200), TEXT, VARCHAR(500), VARCHAR(500), DATE, DATE, VARCHAR(100), VARCHAR(15), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Update(
    p_occupational_health_id        INTEGER,
    p_company_id                    INTEGER,
    p_reported_date                 TIMESTAMP       DEFAULT NULL,
    p_severity                      VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected            VARCHAR(100)    DEFAULT NULL,
    p_days_lost                     INTEGER         DEFAULT NULL,
    p_location                      VARCHAR(200)    DEFAULT NULL,
    p_description                   TEXT            DEFAULT NULL,
    p_root_cause                    VARCHAR(500)    DEFAULT NULL,
    p_corrective_action             VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date        DATE            DEFAULT NULL,
    p_investigation_completed_date  DATE            DEFAULT NULL,
    p_institution_reference         VARCHAR(100)    DEFAULT NULL,
    p_status                        VARCHAR(15)     DEFAULT NULL,
    p_document_url                  VARCHAR(500)    DEFAULT NULL,
    p_notes                         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado                 INTEGER,
    OUT p_mensaje                   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."OccupationalHealth"
        WHERE "OccupationalHealthId" = p_occupational_health_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Registro no encontrado.';
        RETURN;
    END IF;

    IF p_status IS NOT NULL AND p_status NOT IN ('OPEN','REPORTED','INVESTIGATING','CLOSED') THEN
        p_resultado := -1;
        p_mensaje   := 'Estado no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."OccupationalHealth"
        SET
            "ReportedDate"               = COALESCE(p_reported_date,              "ReportedDate"),
            "Severity"                   = COALESCE(p_severity,                   "Severity"),
            "BodyPartAffected"           = COALESCE(p_body_part_affected,         "BodyPartAffected"),
            "DaysLost"                   = COALESCE(p_days_lost,                  "DaysLost"),
            "Location"                   = COALESCE(p_location,                   "Location"),
            "Description"                = COALESCE(p_description,                "Description"),
            "RootCause"                  = COALESCE(p_root_cause,                 "RootCause"),
            "CorrectiveAction"           = COALESCE(p_corrective_action,          "CorrectiveAction"),
            "InvestigationDueDate"       = COALESCE(p_investigation_due_date,     "InvestigationDueDate"),
            "InvestigationCompletedDate" = COALESCE(p_investigation_completed_date, "InvestigationCompletedDate"),
            "InstitutionReference"       = COALESCE(p_institution_reference,      "InstitutionReference"),
            "Status"                     = COALESCE(p_status,                     "Status"),
            "DocumentUrl"                = COALESCE(p_document_url,               "DocumentUrl"),
            "Notes"                      = COALESCE(p_notes,                      "Notes"),
            "UpdatedAt"                  = (NOW() AT TIME ZONE 'UTC')
        WHERE "OccupationalHealthId" = p_occupational_health_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_occupational_health_id;
        p_mensaje   := 'Registro actualizado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 3. usp_HR_OccHealth_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_List(INTEGER, VARCHAR(25), VARCHAR(15), VARCHAR(24), CHAR(2), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_List(
    p_company_id    INTEGER,
    p_record_type   VARCHAR(25)     DEFAULT NULL,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_country_code  CHAR(2)         DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count                   BIGINT,
    "OccupationalHealthId"          INTEGER,
    "CompanyId"                     INTEGER,
    "CountryCode"                   CHAR(2),
    "RecordType"                    VARCHAR(25),
    "EmployeeId"                    BIGINT,
    "EmployeeCode"                  VARCHAR(24),
    "EmployeeName"                  VARCHAR(200),
    "OccurrenceDate"                TIMESTAMP,
    "ReportDeadline"                TIMESTAMP,
    "ReportedDate"                  TIMESTAMP,
    "Severity"                      VARCHAR(15),
    "BodyPartAffected"              VARCHAR(100),
    "DaysLost"                      INTEGER,
    "Location"                      VARCHAR(200),
    "Description"                   TEXT,
    "RootCause"                     VARCHAR(500),
    "CorrectiveAction"              VARCHAR(500),
    "InvestigationDueDate"          DATE,
    "InvestigationCompletedDate"    DATE,
    "InstitutionReference"          VARCHAR(100),
    "Status"                        VARCHAR(15),
    "DocumentUrl"                   VARCHAR(500),
    "Notes"                         VARCHAR(500),
    "CreatedBy"                     INTEGER,
    "CreatedAt"                     TIMESTAMP,
    "UpdatedAt"                     TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "OccupationalHealthId",
        "CompanyId",
        "CountryCode",
        "RecordType",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OccurrenceDate",
        "ReportDeadline",
        "ReportedDate",
        "Severity",
        "BodyPartAffected",
        "DaysLost",
        "Location",
        "Description",
        "RootCause",
        "CorrectiveAction",
        "InvestigationDueDate",
        "InvestigationCompletedDate",
        "InstitutionReference",
        "Status",
        "DocumentUrl",
        "Notes",
        "CreatedBy",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."OccupationalHealth"
    WHERE "CompanyId" = p_company_id
      AND (p_record_type   IS NULL OR "RecordType"   = p_record_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"   = p_country_code)
      AND (p_from_date     IS NULL OR "OccurrenceDate" >= p_from_date)
      AND (p_to_date       IS NULL OR "OccurrenceDate" <= p_to_date)
    ORDER BY "OccurrenceDate" DESC, "OccupationalHealthId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 4. usp_HR_OccHealth_Get
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Get(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Get(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Get(
    p_record_id                 INTEGER,
    p_company_id                INTEGER  DEFAULT NULL
)
RETURNS TABLE (
    "OccupationalHealthId"          INTEGER,
    "CompanyId"                     INTEGER,
    "CountryCode"                   VARCHAR,
    "RecordType"                    VARCHAR,
    "EmployeeId"                    BIGINT,
    "EmployeeCode"                  VARCHAR(24),
    "EmployeeName"                  VARCHAR(200),
    "OccurrenceDate"                TIMESTAMP,
    "ReportDeadline"                TIMESTAMP,
    "ReportedDate"                  TIMESTAMP,
    "Severity"                      VARCHAR(15),
    "BodyPartAffected"              VARCHAR(100),
    "DaysLost"                      INTEGER,
    "Location"                      VARCHAR(200),
    "Description"                   TEXT,
    "RootCause"                     VARCHAR(500),
    "CorrectiveAction"              VARCHAR(500),
    "InvestigationDueDate"          DATE,
    "InvestigationCompletedDate"    DATE,
    "InstitutionReference"          VARCHAR(100),
    "Status"                        VARCHAR(15),
    "DocumentUrl"                   VARCHAR(500),
    "Notes"                         VARCHAR(500),
    "CreatedBy"                     INTEGER,
    "CreatedAt"                     TIMESTAMP,
    "UpdatedAt"                     TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o."OccupationalHealthId",
        o."CompanyId",
        o."CountryCode"::VARCHAR,
        o."RecordType"::VARCHAR,
        o."EmployeeId",
        o."EmployeeCode",
        o."EmployeeName",
        o."OccurrenceDate",
        o."ReportDeadline",
        o."ReportedDate",
        o."Severity",
        o."BodyPartAffected",
        o."DaysLost",
        o."Location",
        o."Description",
        o."RootCause",
        o."CorrectiveAction",
        o."InvestigationDueDate",
        o."InvestigationCompletedDate",
        o."InstitutionReference",
        o."Status",
        o."DocumentUrl",
        o."Notes",
        o."CreatedBy",
        o."CreatedAt",
        o."UpdatedAt"
    FROM hr."OccupationalHealth" o
    WHERE o."OccupationalHealthId" = p_record_id
      AND (p_company_id IS NULL OR o."CompanyId" = p_company_id);
END;
$$;

-- =============================================================================
-- 5. usp_HR_MedExam_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_Save(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, DATE, VARCHAR(20), VARCHAR(500), VARCHAR(200), VARCHAR(200), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_Save(
    p_medical_exam_id   INTEGER         DEFAULT NULL,
    p_company_id        INTEGER         DEFAULT NULL,
    p_employee_id       BIGINT          DEFAULT NULL,
    p_employee_code     VARCHAR(24)     DEFAULT NULL,
    p_employee_name     VARCHAR(200)    DEFAULT NULL,
    p_exam_type         VARCHAR(20)     DEFAULT NULL,
    p_exam_date         DATE            DEFAULT NULL,
    p_next_due_date     DATE            DEFAULT NULL,
    p_result            VARCHAR(20)     DEFAULT 'PENDING',
    p_restrictions      VARCHAR(500)    DEFAULT NULL,
    p_physician_name    VARCHAR(200)    DEFAULT NULL,
    p_clinic_name       VARCHAR(200)    DEFAULT NULL,
    p_document_url      VARCHAR(500)    DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_exam_type NOT IN ('PRE_EMPLOYMENT','PERIODIC','POST_VACATION','EXIT','SPECIAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de examen no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_result NOT IN ('FIT','FIT_WITH_RESTRICTIONS','UNFIT','PENDING') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado de examen no vÃ¡lido.';
        RETURN;
    END IF;

    BEGIN
        IF p_medical_exam_id IS NULL THEN
            INSERT INTO hr."MedicalExam" (
                "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
                "ExamType", "ExamDate", "NextDueDate", "Result",
                "Restrictions", "PhysicianName", "ClinicName",
                "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_employee_id, p_employee_code, p_employee_name,
                p_exam_type, p_exam_date, p_next_due_date, p_result,
                p_restrictions, p_physician_name, p_clinic_name,
                p_document_url, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "MedicalExamId" INTO p_resultado;

            p_mensaje := 'Examen mÃ©dico creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."MedicalExam"
                WHERE "MedicalExamId" = p_medical_exam_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Examen mÃ©dico no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."MedicalExam"
            SET
                "EmployeeId"    = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"  = p_employee_code,
                "EmployeeName"  = p_employee_name,
                "ExamType"      = p_exam_type,
                "ExamDate"      = p_exam_date,
                "NextDueDate"   = p_next_due_date,
                "Result"        = p_result,
                "Restrictions"  = p_restrictions,
                "PhysicianName" = p_physician_name,
                "ClinicName"    = p_clinic_name,
                "DocumentUrl"   = p_document_url,
                "Notes"         = p_notes,
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "MedicalExamId" = p_medical_exam_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_medical_exam_id;
            p_mensaje   := 'Examen mÃ©dico actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_MedExam_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_List(INTEGER, VARCHAR(20), VARCHAR(20), VARCHAR(24), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_List(
    p_company_id    INTEGER,
    p_exam_type     VARCHAR(20)     DEFAULT NULL,
    p_result        VARCHAR(20)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalExamId"     INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "ExamType"          VARCHAR(20),
    "ExamDate"          DATE,
    "NextDueDate"       DATE,
    "Result"            VARCHAR(20),
    "Restrictions"      VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "ClinicName"        VARCHAR(200),
    "DocumentUrl"       VARCHAR(500),
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalExamId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "ExamType",
        "ExamDate",
        "NextDueDate",
        "Result",
        "Restrictions",
        "PhysicianName",
        "ClinicName",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalExam"
    WHERE "CompanyId" = p_company_id
      AND (p_exam_type     IS NULL OR "ExamType"     = p_exam_type)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "ExamDate"     >= p_from_date)
      AND (p_to_date       IS NULL OR "ExamDate"     <= p_to_date)
    ORDER BY "ExamDate" DESC, "MedicalExamId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 7. usp_HR_MedExam_GetPending
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_GetPending(INTEGER, DATE, INTEGER, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_GetPending(
    p_company_id    INTEGER,
    p_as_of_date    DATE        DEFAULT NULL,
    p_days_ahead    INTEGER     DEFAULT 30,
    p_page          INTEGER     DEFAULT 1,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalExamId"     INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "ExamType"          VARCHAR(20),
    "ExamDate"          DATE,
    "NextDueDate"       DATE,
    "Result"            VARCHAR(20),
    "Restrictions"      VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "ClinicName"        VARCHAR(200),
    "IsOverdue"         BOOLEAN,
    "DaysUntilDue"      INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_as_of_date IS NULL THEN p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    WITH "LatestExam" AS (
        SELECT me."MedicalExamId", me."CompanyId", me."EmployeeId",
               me."EmployeeCode", me."EmployeeName", me."ExamType",
               me."ExamDate", me."NextDueDate", me."Result",
               me."Restrictions", me."PhysicianName", me."ClinicName",
               ROW_NUMBER() OVER (PARTITION BY me."EmployeeCode" ORDER BY me."ExamDate" DESC) AS rn
        FROM hr."MedicalExam" me
        WHERE me."CompanyId"  = p_company_id
          AND me."ExamType"   = 'PERIODIC'
          AND me."NextDueDate" IS NOT NULL
          AND me."NextDueDate" <= p_as_of_date + p_days_ahead
    )
    SELECT
        COUNT(*) OVER()                                     AS p_total_count,
        le."MedicalExamId",
        le."CompanyId",
        le."EmployeeId",
        le."EmployeeCode",
        le."EmployeeName",
        le."ExamType",
        le."ExamDate",
        le."NextDueDate",
        le."Result",
        le."Restrictions",
        le."PhysicianName",
        le."ClinicName",
        (le."NextDueDate" < p_as_of_date)                  AS "IsOverdue",
        (le."NextDueDate" - p_as_of_date)::INTEGER         AS "DaysUntilDue"
    FROM "LatestExam" le
    WHERE le.rn = 1
    ORDER BY le."NextDueDate" ASC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 8. usp_HR_MedOrder_Create
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Create(INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, VARCHAR(500), VARCHAR(200), TEXT, NUMERIC(18,2), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_Create(
    p_company_id    INTEGER,
    p_employee_id   BIGINT          DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_employee_name VARCHAR(200)    DEFAULT NULL,
    p_order_type    VARCHAR(20)     DEFAULT NULL,
    p_order_date    DATE            DEFAULT NULL,
    p_diagnosis     VARCHAR(500)    DEFAULT NULL,
    p_physician_name VARCHAR(200)   DEFAULT NULL,
    p_prescriptions TEXT            DEFAULT NULL,
    p_estimated_cost NUMERIC(18,2)  DEFAULT NULL,
    p_document_url  VARCHAR(500)    DEFAULT NULL,
    p_notes         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_order_type NOT IN ('MEDICAL','PHARMACY','LAB','REFERRAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de orden no vÃ¡lido.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."MedicalOrder" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "OrderType", "OrderDate", "Diagnosis", "PhysicianName",
            "Prescriptions", "EstimatedCost", "Status",
            "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_order_type, p_order_date, p_diagnosis, p_physician_name,
            p_prescriptions, p_estimated_cost, 'PENDIENTE',
            p_document_url, p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MedicalOrderId" INTO p_resultado;

        p_mensaje := 'Orden mÃ©dica creada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 9. usp_HR_MedOrder_Approve
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Approve(INTEGER, INTEGER, VARCHAR(15), NUMERIC(18,2), INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_Approve(
    p_medical_order_id  INTEGER,
    p_company_id        INTEGER,
    p_action            VARCHAR(15),
    p_approved_amount   NUMERIC(18,2)   DEFAULT NULL,
    p_approved_by       INTEGER         DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_action NOT IN ('APROBADA','RECHAZADA') THEN
        p_resultado := -1;
        p_mensaje   := 'AcciÃ³n no vÃ¡lida. Use APROBADA o RECHAZADA.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Orden mÃ©dica no encontrada.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
          AND "Status" = 'PENDIENTE'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La orden no estÃ¡ en estado PENDIENTE.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."MedicalOrder"
        SET
            "Status"         = p_action,
            "ApprovedAmount" = CASE WHEN p_action = 'APROBADA'
                                    THEN COALESCE(p_approved_amount, "EstimatedCost")
                                    ELSE NULL END,
            "ApprovedBy"     = p_approved_by,
            "ApprovedAt"     = (NOW() AT TIME ZONE 'UTC'),
            "Notes"          = COALESCE(p_notes, "Notes"),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "MedicalOrderId" = p_medical_order_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_medical_order_id;
        p_mensaje   := CASE WHEN p_action = 'APROBADA'
                            THEN 'Orden mÃ©dica aprobada exitosamente.'
                            ELSE 'Orden mÃ©dica rechazada.' END;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_MedOrder_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_List(INTEGER, VARCHAR(20), VARCHAR(15), VARCHAR(24), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_List(
    p_company_id    INTEGER,
    p_order_type    VARCHAR(20)     DEFAULT NULL,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalOrderId"    INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "OrderType"         VARCHAR(20),
    "OrderDate"         DATE,
    "Diagnosis"         VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "Prescriptions"     TEXT,
    "EstimatedCost"     NUMERIC(18,2),
    "ApprovedAmount"    NUMERIC(18,2),
    "Status"            VARCHAR(15),
    "ApprovedBy"        INTEGER,
    "ApprovedAt"        TIMESTAMP,
    "DocumentUrl"       VARCHAR(500),
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalOrderId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OrderType",
        "OrderDate",
        "Diagnosis",
        "PhysicianName",
        "Prescriptions",
        "EstimatedCost",
        "ApprovedAmount",
        "Status",
        "ApprovedBy",
        "ApprovedAt",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalOrder"
    WHERE "CompanyId" = p_company_id
      AND (p_order_type    IS NULL OR "OrderType"    = p_order_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "OrderDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "OrderDate"    <= p_to_date)
    ORDER BY "OrderDate" DESC, "MedicalOrderId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 11. usp_HR_Training_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(25), VARCHAR(200), VARCHAR(200), DATE, DATE, NUMERIC(6,2), BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(100), VARCHAR(500), VARCHAR(15), BOOLEAN, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_Save(
    p_training_record_id    INTEGER         DEFAULT NULL,
    p_company_id            INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_training_type         VARCHAR(25)     DEFAULT NULL,
    p_title                 VARCHAR(200)    DEFAULT NULL,
    p_provider              VARCHAR(200)    DEFAULT NULL,
    p_start_date            DATE            DEFAULT NULL,
    p_end_date              DATE            DEFAULT NULL,
    p_duration_hours        NUMERIC(6,2)    DEFAULT NULL,
    p_employee_id           BIGINT          DEFAULT NULL,
    p_employee_code         VARCHAR(24)     DEFAULT NULL,
    p_employee_name         VARCHAR(200)    DEFAULT NULL,
    p_certificate_number    VARCHAR(100)    DEFAULT NULL,
    p_certificate_url       VARCHAR(500)    DEFAULT NULL,
    p_result                VARCHAR(15)     DEFAULT NULL,
    p_is_regulatory         BOOLEAN         DEFAULT FALSE,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_training_type NOT IN ('SAFETY','REGULATORY','TECHNICAL','APPRENTICESHIP','INDUCTION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de capacitaciÃ³n no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_result IS NOT NULL AND p_result NOT IN ('PASSED','FAILED','IN_PROGRESS','ATTENDED') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_duration_hours <= 0 THEN
        p_resultado := -1;
        p_mensaje   := 'La duraciÃ³n en horas debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        IF p_training_record_id IS NULL THEN
            INSERT INTO hr."TrainingRecord" (
                "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
                "StartDate", "EndDate", "DurationHours",
                "EmployeeId", "EmployeeCode", "EmployeeName",
                "CertificateNumber", "CertificateUrl", "Result",
                "IsRegulatory", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_training_type, p_title, p_provider,
                p_start_date, p_end_date, p_duration_hours,
                p_employee_id, p_employee_code, p_employee_name,
                p_certificate_number, p_certificate_url, p_result,
                p_is_regulatory, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "TrainingRecordId" INTO p_resultado;

            p_mensaje := 'Registro de capacitaciÃ³n creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."TrainingRecord"
                WHERE "TrainingRecordId" = p_training_record_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Registro de capacitaciÃ³n no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."TrainingRecord"
            SET
                "CountryCode"       = p_country_code,
                "TrainingType"      = p_training_type,
                "Title"             = p_title,
                "Provider"          = p_provider,
                "StartDate"         = p_start_date,
                "EndDate"           = p_end_date,
                "DurationHours"     = p_duration_hours,
                "EmployeeId"        = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"      = p_employee_code,
                "EmployeeName"      = p_employee_name,
                "CertificateNumber" = p_certificate_number,
                "CertificateUrl"    = p_certificate_url,
                "Result"            = p_result,
                "IsRegulatory"      = p_is_regulatory,
                "Notes"             = p_notes,
                "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
            WHERE "TrainingRecordId" = p_training_record_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_training_record_id;
            p_mensaje   := 'Registro de capacitaciÃ³n actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 12. usp_HR_Training_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_List(INTEGER, VARCHAR(25), VARCHAR(24), CHAR(2), BOOLEAN, VARCHAR(15), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_List(
    p_company_id    INTEGER,
    p_training_type VARCHAR(25)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_country_code  CHAR(2)         DEFAULT NULL,
    p_is_regulatory BOOLEAN         DEFAULT NULL,
    p_result        VARCHAR(15)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "TrainingRecordId"      INTEGER,
    "CompanyId"             INTEGER,
    "CountryCode"           CHAR(2),
    "TrainingType"          VARCHAR(25),
    "Title"                 VARCHAR(200),
    "Provider"              VARCHAR(200),
    "StartDate"             DATE,
    "EndDate"               DATE,
    "DurationHours"         NUMERIC(6,2),
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "CertificateNumber"     VARCHAR(100),
    "CertificateUrl"        VARCHAR(500),
    "Result"                VARCHAR(15),
    "IsRegulatory"          BOOLEAN,
    "Notes"                 VARCHAR(500),
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "TrainingRecordId",
        "CompanyId",
        "CountryCode",
        "TrainingType",
        "Title",
        "Provider",
        "StartDate",
        "EndDate",
        "DurationHours",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "CertificateNumber",
        "CertificateUrl",
        "Result",
        "IsRegulatory",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."TrainingRecord"
    WHERE "CompanyId" = p_company_id
      AND (p_training_type IS NULL OR "TrainingType" = p_training_type)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"  = p_country_code)
      AND (p_is_regulatory IS NULL OR "IsRegulatory" = p_is_regulatory)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_from_date     IS NULL OR "StartDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "StartDate"    <= p_to_date)
    ORDER BY "StartDate" DESC, "TrainingRecordId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 13. usp_HR_Training_GetEmployeeCertifications
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_GetEmployeeCertifications(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_GetEmployeeCertifications(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    "TrainingRecordId"  INTEGER,
    "CompanyId"         INTEGER,
    "CountryCode"       CHAR(2),
    "TrainingType"      VARCHAR(25),
    "Title"             VARCHAR(200),
    "Provider"          VARCHAR(200),
    "StartDate"         DATE,
    "EndDate"           DATE,
    "DurationHours"     NUMERIC(6,2),
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "CertificateNumber" VARCHAR(100),
    "CertificateUrl"    VARCHAR(500),
    "Result"            VARCHAR(15),
    "IsRegulatory"      BOOLEAN,
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TrainingRecordId",
        t."CompanyId",
        t."CountryCode",
        t."TrainingType",
        t."Title",
        t."Provider",
        t."StartDate",
        t."EndDate",
        t."DurationHours",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."CertificateNumber",
        t."CertificateUrl",
        t."Result",
        t."IsRegulatory",
        t."Notes",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."TrainingRecord" t
    WHERE t."CompanyId"         = p_company_id
      AND t."EmployeeCode"      = p_employee_code
      AND t."Result"            = 'PASSED'
      AND t."CertificateNumber" IS NOT NULL
    ORDER BY t."StartDate" DESC;
END;
$$;

-- =============================================================================
-- 14. usp_HR_Committee_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(200), DATE, VARCHAR(15), BOOLEAN, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_Save(
    p_safety_committee_id   INTEGER         DEFAULT NULL,
    p_company_id            INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_committee_name        VARCHAR(200)    DEFAULT NULL,
    p_formation_date        DATE            DEFAULT NULL,
    p_meeting_frequency     VARCHAR(15)     DEFAULT 'MONTHLY',
    p_is_active             BOOLEAN         DEFAULT TRUE,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        IF p_safety_committee_id IS NULL THEN
            INSERT INTO hr."SafetyCommittee" (
                "CompanyId", "CountryCode", "CommitteeName",
                "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_committee_name,
                p_formation_date, p_meeting_frequency, p_is_active,
                (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "SafetyCommitteeId" INTO p_resultado;

            p_mensaje := 'ComitÃ© de seguridad creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."SafetyCommittee"
                WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'ComitÃ© no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."SafetyCommittee"
            SET
                "CountryCode"      = p_country_code,
                "CommitteeName"    = p_committee_name,
                "FormationDate"    = p_formation_date,
                "MeetingFrequency" = p_meeting_frequency,
                "IsActive"         = p_is_active
            WHERE "SafetyCommitteeId" = p_safety_committee_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_safety_committee_id;
            p_mensaje   := 'ComitÃ© de seguridad actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 15. usp_HR_Committee_AddMember
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_AddMember(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(25), DATE, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_AddMember(
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_employee_id           BIGINT          DEFAULT NULL,
    p_employee_code         VARCHAR(24)     DEFAULT NULL,
    p_employee_name         VARCHAR(200)    DEFAULT NULL,
    p_role                  VARCHAR(25)     DEFAULT NULL,
    p_start_date            DATE            DEFAULT NULL,
    p_end_date              DATE            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_role NOT IN ('PRESIDENT','SECRETARY','DELEGATE','EMPLOYER_REP') THEN
        p_resultado := -1;
        p_mensaje   := 'Rol no vÃ¡lido.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "SafetyCommitteeId" = p_safety_committee_id
          AND "EmployeeCode" = p_employee_code
          AND ("EndDate" IS NULL OR "EndDate" >= p_start_date)
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya es miembro activo de este comitÃ©.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMember" (
            "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "Role", "StartDate", "EndDate"
        )
        VALUES (
            p_safety_committee_id, p_employee_id, p_employee_code, p_employee_name,
            p_role, p_start_date, p_end_date
        )
        RETURNING "MemberId" INTO p_resultado;

        p_mensaje := 'Miembro agregado exitosamente al comitÃ©.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 16. usp_HR_Committee_RemoveMember
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RemoveMember(INTEGER, INTEGER, INTEGER, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_RemoveMember(
    p_member_id             INTEGER,
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_end_date              DATE            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_end_date IS NULL THEN
        p_end_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "MemberId" = p_member_id AND "SafetyCommitteeId" = p_safety_committee_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Miembro no encontrado en este comitÃ©.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."SafetyCommitteeMember"
        SET "EndDate" = p_end_date
        WHERE "MemberId" = p_member_id
          AND "SafetyCommitteeId" = p_safety_committee_id;

        p_resultado := p_member_id;
        p_mensaje   := 'Miembro removido del comitÃ© exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 17. usp_HR_Committee_RecordMeeting
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RecordMeeting(INTEGER, INTEGER, TIMESTAMP, VARCHAR(500), TEXT, TEXT, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_RecordMeeting(
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_meeting_date          TIMESTAMP,
    p_minutes_url           VARCHAR(500)    DEFAULT NULL,
    p_topics_summary        TEXT            DEFAULT NULL,
    p_action_items          TEXT            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMeeting" (
            "SafetyCommitteeId", "MeetingDate", "MinutesUrl",
            "TopicsSummary", "ActionItems", "CreatedAt"
        )
        VALUES (
            p_safety_committee_id, p_meeting_date, p_minutes_url,
            p_topics_summary, p_action_items,
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MeetingId" INTO p_resultado;

        p_mensaje := 'ReuniÃ³n registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 18. usp_HR_Committee_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_List(INTEGER, CHAR(2), BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_List(
    p_company_id    INTEGER,
    p_country_code  CHAR(2)     DEFAULT NULL,
    p_is_active     BOOLEAN     DEFAULT NULL,
    p_page          INTEGER     DEFAULT 1,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "SafetyCommitteeId"     INTEGER,
    "CompanyId"             INTEGER,
    "CountryCode"           CHAR(2),
    "CommitteeName"         VARCHAR(200),
    "FormationDate"         DATE,
    "MeetingFrequency"      VARCHAR(15),
    "IsActive"              BOOLEAN,
    "CreatedAt"             TIMESTAMP,
    "ActiveMemberCount"     BIGINT,
    "TotalMeetings"         BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sc."SafetyCommitteeId",
        sc."CompanyId",
        sc."CountryCode",
        sc."CommitteeName",
        sc."FormationDate",
        sc."MeetingFrequency",
        sc."IsActive",
        sc."CreatedAt",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMember" m
            WHERE m."SafetyCommitteeId" = sc."SafetyCommitteeId"
              AND (m."EndDate" IS NULL OR m."EndDate" >= CAST((NOW() AT TIME ZONE 'UTC') AS DATE))
        )::BIGINT AS "ActiveMemberCount",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" mt
            WHERE mt."SafetyCommitteeId" = sc."SafetyCommitteeId"
        )::BIGINT AS "TotalMeetings"
    FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (p_country_code IS NULL OR sc."CountryCode" = p_country_code)
      AND (p_is_active    IS NULL OR sc."IsActive"    = p_is_active)
    ORDER BY sc."IsActive" DESC, sc."FormationDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 19. usp_HR_Committee_GetMeetings
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER, INTEGER, DATE, DATE, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_GetMeetings(
    p_committee_id          INTEGER,
    p_company_id            INTEGER     DEFAULT NULL,
    p_from_date             DATE        DEFAULT NULL,
    p_to_date               DATE        DEFAULT NULL,
    p_page                  INTEGER     DEFAULT 1,
    p_limit                 INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "MeetingId"             INTEGER,
    "SafetyCommitteeId"     INTEGER,
    "MeetingDate"           TIMESTAMP,
    "MinutesUrl"            VARCHAR(500),
    "TopicsSummary"         TEXT,
    "ActionItems"           TEXT,
    "CreatedAt"             TIMESTAMP,
    "CommitteeName"         VARCHAR(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    -- Verificar que el comitÃ© pertenece a la empresa
    IF p_company_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee" c2
        WHERE c2."SafetyCommitteeId" = p_committee_id AND c2."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()::BIGINT,
        m."MeetingId",
        m."SafetyCommitteeId",
        m."MeetingDate",
        m."MinutesUrl"::VARCHAR(500),
        m."TopicsSummary",
        m."ActionItems",
        m."CreatedAt"::TIMESTAMP,
        sc."CommitteeName"::VARCHAR(200)
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date   IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;


-- =============================================================================
-- SERVICE BRIDGE WRAPPERS
-- These wrappers bridge the gap between the service parameter names
-- (converted via toSnakeParam) and the underlying function signatures.
-- =============================================================================

-- Internal alias for usp_HR_OccHealth_Create (avoids overload ambiguity)
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create_internal(
    p_company_id                INTEGER,
    p_country_code              CHAR(2),
    p_record_type               VARCHAR(25),
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_occurrence_date           TIMESTAMP       DEFAULT NULL,
    p_report_deadline           TIMESTAMP       DEFAULT NULL,
    p_reported_date             TIMESTAMP       DEFAULT NULL,
    p_severity                  VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected        VARCHAR(100)    DEFAULT NULL,
    p_days_lost                 INTEGER         DEFAULT NULL,
    p_location                  VARCHAR(200)    DEFAULT NULL,
    p_description               TEXT            DEFAULT NULL,
    p_root_cause                VARCHAR(500)    DEFAULT NULL,
    p_corrective_action         VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date    DATE            DEFAULT NULL,
    p_institution_reference     VARCHAR(100)    DEFAULT NULL,
    p_document_url              VARCHAR(500)    DEFAULT NULL,
    p_notes                     VARCHAR(500)    DEFAULT NULL,
    p_created_by                INTEGER         DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- Service wrapper: usp_HR_OccHealth_Create
-- Service sends: p_company_id, p_branch_id, p_employee_code, p_record_type,
--                p_incident_date (DATE), p_description, p_severity, p_user_id
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, CHAR, VARCHAR, BIGINT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, TIMESTAMP, VARCHAR, VARCHAR, INTEGER, VARCHAR, TEXT, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, INTEGER, VARCHAR, VARCHAR, TIMESTAMP, TEXT, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, TEXT, VARCHAR, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_record_type   VARCHAR     DEFAULT NULL,
    p_incident_date DATE        DEFAULT NULL,
    p_description   TEXT        DEFAULT NULL,
    p_severity      VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_occhealth_create_internal(
        p_company_id      := p_company_id,
        p_country_code    := v_country_code,
        p_record_type     := UPPER(COALESCE(p_record_type, 'ACCIDENT')),
        p_employee_code   := p_employee_code,
        p_occurrence_date := p_incident_date::TIMESTAMP,
        p_description     := p_description,
        p_severity        := UPPER(p_severity),
        p_created_by      := p_user_id
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_MedExam_Save
-- Service sends: p_company_id, p_branch_id, p_exam_id, p_employee_code,
--                p_exam_type, p_exam_date, p_result, p_notes, p_next_due_date, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_Save(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, DATE, VARCHAR(20), VARCHAR(500), VARCHAR(200), VARCHAR(200), VARCHAR(500), VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, DATE, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_exam_id       INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_exam_type     VARCHAR     DEFAULT NULL,
    p_exam_date     DATE        DEFAULT NULL,
    p_result        VARCHAR     DEFAULT NULL,
    p_notes         VARCHAR     DEFAULT NULL,
    p_next_due_date DATE        DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
    v_employee_id  BIGINT;
    v_employee_name VARCHAR(200);
BEGIN
    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."CompanyId" = p_company_id
    LIMIT 1;

    IF v_employee_name IS NULL THEN
        v_employee_name := p_employee_code;
    END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_medexam_save(
        p_medical_exam_id := p_exam_id,
        p_company_id      := p_company_id,
        p_employee_id     := v_employee_id,
        p_employee_code   := p_employee_code,
        p_employee_name   := v_employee_name,
        p_exam_type       := UPPER(COALESCE(p_exam_type, 'PERIODIC')),
        p_exam_date       := p_exam_date,
        p_result          := UPPER(COALESCE(p_result, 'PENDING')),
        p_notes           := p_notes,
        p_next_due_date   := p_next_due_date
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_Training_Save
-- Service sends: p_company_id, p_branch_id, p_training_id, p_name, p_description,
--                p_start_date, p_end_date, p_instructor, p_hours, p_participants, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_Training_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(25), VARCHAR(200), VARCHAR(200), DATE, DATE, NUMERIC(6,2), BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(100), VARCHAR(500), VARCHAR(15), BOOLEAN, VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_training_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, VARCHAR, NUMERIC, VARCHAR, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_training_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_training_id   INTEGER     DEFAULT NULL,
    p_name          VARCHAR     DEFAULT NULL,
    p_description   VARCHAR     DEFAULT NULL,
    p_start_date    DATE        DEFAULT NULL,
    p_end_date      DATE        DEFAULT NULL,
    p_instructor    VARCHAR     DEFAULT NULL,
    p_hours         NUMERIC     DEFAULT NULL,
    p_participants  VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_training_save(
        p_training_record_id := p_training_id,
        p_company_id         := p_company_id,
        p_country_code       := v_country_code,
        p_training_type      := 'TECHNICAL',
        p_title              := p_name,
        p_provider           := p_instructor,
        p_start_date         := p_start_date,
        p_end_date           := p_end_date,
        p_duration_hours     := COALESCE(p_hours, 1),
        p_employee_code      := COALESCE(p_participants, 'GENERAL'),
        p_employee_name      := COALESCE(p_participants, p_name, 'GENERAL'),
        p_notes              := p_description
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_Committee_Save
-- Service sends: p_company_id, p_branch_id, p_committee_id, p_name,
--                p_committee_type, p_start_date, p_end_date, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_Committee_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(200), DATE, VARCHAR(15), BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_committee_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_save(
    p_company_id     INTEGER,
    p_branch_id      INTEGER     DEFAULT NULL,
    p_committee_id   INTEGER     DEFAULT NULL,
    p_name           VARCHAR     DEFAULT NULL,
    p_committee_type VARCHAR     DEFAULT NULL,
    p_start_date     DATE        DEFAULT NULL,
    p_end_date       DATE        DEFAULT NULL,
    p_user_id        INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
    v_meeting_freq VARCHAR(15);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    v_meeting_freq := CASE UPPER(COALESCE(p_committee_type,''::VARCHAR))
        WHEN 'MONTHLY'   THEN 'MONTHLY'
        WHEN 'QUARTERLY' THEN 'QUARTERLY'
        WHEN 'BIMONTHLY' THEN 'BIMONTHLY'
        WHEN 'WEEKLY'    THEN 'WEEKLY'
        ELSE 'MONTHLY'
    END;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_committee_save(
        p_safety_committee_id := p_committee_id,
        p_company_id          := p_company_id,
        p_country_code        := v_country_code,
        p_committee_name      := p_name,
        p_formation_date      := p_start_date,
        p_meeting_frequency   := v_meeting_freq,
        p_is_active           := TRUE
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;
