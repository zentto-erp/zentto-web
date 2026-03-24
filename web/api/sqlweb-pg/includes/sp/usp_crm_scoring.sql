-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm_scoring.sql
-- Funciones de Lead Scoring y Timeline del modulo CRM
-- Fecha: 2026-03-23
-- ============================================================

-- ============================================================
-- Tabla crm."LeadScore" (historial de scores calculados)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."LeadScore" (
    "LeadScoreId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "LeadId" BIGINT NOT NULL REFERENCES crm."Lead"("LeadId"),
    "Score" INT NOT NULL DEFAULT 0,
    "ScoreDate" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "Factors" JSONB DEFAULT '{}',
    "CalculatedByUserId" INT NULL
);
CREATE INDEX IF NOT EXISTS "IX_crm_LeadScore_LeadId" ON crm."LeadScore"("LeadId", "ScoreDate" DESC);

-- =============================================================================
--  usp_CRM_LeadScore_Calculate
--  Calcula score de un lead basado en factores ponderados (0-100)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_leadscore_calculate(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_leadscore_calculate(
    p_lead_id  BIGINT,
    p_user_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "ok"      INT,
    "mensaje" VARCHAR,
    "Score"   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_score        INT := 0;
    v_factors      JSONB := '{}';
    v_now          TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_7d_ago       TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days';
    v_30d_ago      TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '30 days';
    v_lead         RECORD;
    v_act_7d       INT := 0;
    v_act_30d      INT := 0;
    v_act_total    INT := 0;
    v_last_act     TIMESTAMP;
BEGIN
    -- Obtener datos del lead
    SELECT l."LeadId", l."Email", l."Phone", l."CompanyName",
           l."EstimatedValue", l."ExpectedCloseDate", l."Priority",
           l."Status", l."Notes"
    INTO   v_lead
    FROM   crm."Lead" l
    WHERE  l."LeadId" = p_lead_id
      AND  l."IsDeleted" = FALSE;

    IF v_lead."LeadId" IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR, 0;
        RETURN;
    END IF;

    -- Factor: Tiene email (+10)
    IF v_lead."Email" IS NOT NULL AND v_lead."Email" <> '' THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"email": 10}';
    END IF;

    -- Factor: Tiene telefono (+8)
    IF v_lead."Phone" IS NOT NULL AND v_lead."Phone" <> '' THEN
        v_score := v_score + 8;
        v_factors := v_factors || '{"phone": 8}';
    END IF;

    -- Factor: Tiene empresa (+5)
    IF v_lead."CompanyName" IS NOT NULL AND v_lead."CompanyName" <> '' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"companyName": 5}';
    END IF;

    -- Factor: Valor estimado > 0 (+15)
    IF COALESCE(v_lead."EstimatedValue", 0) > 0 THEN
        v_score := v_score + 15;
        v_factors := v_factors || '{"estimatedValue": 15}';
    END IF;

    -- Factor: Valor estimado > 10000 (+10 extra)
    IF COALESCE(v_lead."EstimatedValue", 0) > 10000 THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"highValue": 10}';
    END IF;

    -- Factor: Tiene fecha cierre esperada (+5)
    IF v_lead."ExpectedCloseDate" IS NOT NULL THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"expectedCloseDate": 5}';
    END IF;

    -- Factor: Prioridad HIGH/URGENT (+10)
    IF v_lead."Priority" IN ('HIGH', 'URGENT') THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"highPriority": 10}';
    END IF;

    -- Factor: Status OPEN (+5)
    IF v_lead."Status" = 'OPEN' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"statusOpen": 5}';
    END IF;

    -- Factor: Notas no vacias (+5)
    IF v_lead."Notes" IS NOT NULL AND v_lead."Notes" <> '' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"hasNotes": 5}';
    END IF;

    -- Contar actividades
    SELECT COUNT(*) FILTER (WHERE a."CreatedAt" >= v_7d_ago),
           COUNT(*) FILTER (WHERE a."CreatedAt" >= v_30d_ago AND a."CreatedAt" < v_7d_ago),
           COUNT(*),
           MAX(a."CreatedAt")
    INTO   v_act_7d, v_act_30d, v_act_total, v_last_act
    FROM   crm."Activity" a
    WHERE  a."LeadId" = p_lead_id
      AND  a."IsDeleted" = FALSE;

    -- Factor: Actividades en ultimos 7 dias (+15)
    IF v_act_7d > 0 THEN
        v_score := v_score + 15;
        v_factors := v_factors || '{"recentActivity7d": 15}';
    -- Factor: Actividades en ultimos 30 dias pero no en 7 (+7)
    ELSIF v_act_30d > 0 THEN
        v_score := v_score + 7;
        v_factors := v_factors || '{"recentActivity30d": 7}';
    -- Factor: Sin actividades > 30 dias (-10)
    ELSIF v_act_total > 0 AND v_last_act < v_30d_ago THEN
        v_score := v_score - 10;
        v_factors := v_factors || '{"staleActivity": -10}';
    END IF;

    -- Factor: Total actividades > 5 (+5)
    IF v_act_total > 5 THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"manyActivities": 5}';
    END IF;

    -- Clamp entre 0 y 100
    v_score := GREATEST(0, LEAST(100, v_score));

    -- Insertar en LeadScore
    INSERT INTO crm."LeadScore" ("LeadId", "Score", "ScoreDate", "Factors", "CalculatedByUserId")
    VALUES (p_lead_id, v_score, v_now, v_factors, p_user_id);

    RETURN QUERY SELECT 1, 'Score calculado correctamente'::VARCHAR, v_score;
END;
$$;

-- =============================================================================
--  usp_CRM_LeadScore_BulkCalculate
--  Calcula score para todos los leads OPEN de la empresa (logica inline)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_leadscore_bulkcalculate(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_leadscore_bulkcalculate(
    p_company_id  INT,
    p_user_id     INT DEFAULT NULL
)
RETURNS TABLE(
    "LeadId"      BIGINT,
    "LeadCode"    VARCHAR,
    "ContactName" VARCHAR,
    "Score"       INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now     TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_7d_ago  TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days';
    v_30d_ago TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '30 days';
BEGIN
    -- Calcular e insertar scores en batch
    WITH lead_data AS (
        SELECT
            l."LeadId",
            l."LeadCode",
            l."ContactName",
            l."Email",
            l."Phone",
            l."CompanyName",
            l."EstimatedValue",
            l."ExpectedCloseDate",
            l."Priority",
            l."Status",
            l."Notes"
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."Status" = 'OPEN'
    ),
    activity_stats AS (
        SELECT
            a."LeadId",
            COUNT(*) FILTER (WHERE a."CreatedAt" >= v_7d_ago) AS act_7d,
            COUNT(*) FILTER (WHERE a."CreatedAt" >= v_30d_ago AND a."CreatedAt" < v_7d_ago) AS act_30d,
            COUNT(*) AS act_total,
            MAX(a."CreatedAt") AS last_act
        FROM crm."Activity" a
        WHERE a."IsDeleted" = FALSE
          AND a."LeadId" IN (SELECT ld."LeadId" FROM lead_data ld)
        GROUP BY a."LeadId"
    ),
    scored AS (
        SELECT
            ld."LeadId",
            ld."LeadCode"::VARCHAR,
            ld."ContactName"::VARCHAR,
            GREATEST(0, LEAST(100,
                -- email +10
                CASE WHEN ld."Email" IS NOT NULL AND ld."Email" <> '' THEN 10 ELSE 0 END
                -- phone +8
                + CASE WHEN ld."Phone" IS NOT NULL AND ld."Phone" <> '' THEN 8 ELSE 0 END
                -- companyName +5
                + CASE WHEN ld."CompanyName" IS NOT NULL AND ld."CompanyName" <> '' THEN 5 ELSE 0 END
                -- estimatedValue > 0 +15
                + CASE WHEN COALESCE(ld."EstimatedValue", 0) > 0 THEN 15 ELSE 0 END
                -- estimatedValue > 10000 +10
                + CASE WHEN COALESCE(ld."EstimatedValue", 0) > 10000 THEN 10 ELSE 0 END
                -- expectedCloseDate +5
                + CASE WHEN ld."ExpectedCloseDate" IS NOT NULL THEN 5 ELSE 0 END
                -- priority HIGH/URGENT +10
                + CASE WHEN ld."Priority" IN ('HIGH', 'URGENT') THEN 10 ELSE 0 END
                -- status OPEN +5
                + CASE WHEN ld."Status" = 'OPEN' THEN 5 ELSE 0 END
                -- notes +5
                + CASE WHEN ld."Notes" IS NOT NULL AND ld."Notes" <> '' THEN 5 ELSE 0 END
                -- actividades 7d +15
                + CASE WHEN COALESCE(ast.act_7d, 0) > 0 THEN 15
                       WHEN COALESCE(ast.act_30d, 0) > 0 THEN 7
                       WHEN COALESCE(ast.act_total, 0) > 0 AND ast.last_act < v_30d_ago THEN -10
                       ELSE 0 END
                -- total actividades > 5 +5
                + CASE WHEN COALESCE(ast.act_total, 0) > 5 THEN 5 ELSE 0 END
            ))::INT AS calculated_score
        FROM lead_data ld
        LEFT JOIN activity_stats ast ON ast."LeadId" = ld."LeadId"
    ),
    inserted AS (
        INSERT INTO crm."LeadScore" ("LeadId", "Score", "ScoreDate", "Factors", "CalculatedByUserId")
        SELECT s."LeadId", s.calculated_score, v_now, '{}'::JSONB, p_user_id
        FROM scored s
        RETURNING crm."LeadScore"."LeadId", crm."LeadScore"."Score"
    )
    RETURN QUERY
    SELECT s."LeadId", s."LeadCode", s."ContactName", s.calculated_score
    FROM scored s
    ORDER BY s.calculated_score DESC;
END;
$$;

-- =============================================================================
--  usp_CRM_LeadScore_Get
--  Retorna el score mas reciente de un lead
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_leadscore_get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_leadscore_get(
    p_lead_id  BIGINT
)
RETURNS TABLE(
    "Score"     INT,
    "ScoreDate" TIMESTAMP,
    "Factors"   JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ls."Score", ls."ScoreDate", ls."Factors"
    FROM   crm."LeadScore" ls
    WHERE  ls."LeadId" = p_lead_id
    ORDER BY ls."ScoreDate" DESC
    LIMIT 1;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_GetDetail
--  Detalle completo de un lead con datos enriquecidos
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_getdetail(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_getdetail(
    p_lead_id  BIGINT
)
RETURNS TABLE(
    "LeadId"              BIGINT,
    "CompanyId"           INT,
    "BranchId"            INT,
    "PipelineId"          BIGINT,
    "StageId"             BIGINT,
    "LeadCode"            VARCHAR,
    "ContactName"         VARCHAR,
    "CompanyName"         VARCHAR,
    "Email"               VARCHAR,
    "Phone"               VARCHAR,
    "Source"              VARCHAR,
    "AssignedToUserId"    INT,
    "CustomerId"          BIGINT,
    "EstimatedValue"      NUMERIC,
    "CurrencyCode"        VARCHAR,
    "ExpectedCloseDate"   DATE,
    "LostReason"          VARCHAR,
    "Notes"               TEXT,
    "Tags"                VARCHAR,
    "Priority"            VARCHAR,
    "Status"              VARCHAR,
    "WonAt"               TIMESTAMP,
    "LostAt"              TIMESTAMP,
    "CreatedAt"           TIMESTAMP,
    "UpdatedAt"           TIMESTAMP,
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "RowVer"              INT,
    "StageName"           VARCHAR,
    "StageColor"          VARCHAR,
    "StageProbability"    INT,
    "PipelineName"        VARCHAR,
    "AssignedToName"      VARCHAR,
    "CurrentScore"        INT,
    "DaysInCurrentStage"  INT,
    "TotalActivities"     INT,
    "PendingActivities"   INT,
    "DaysSinceLastActivity" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    SELECT
        l."LeadId",
        l."CompanyId",
        l."BranchId",
        l."PipelineId",
        l."StageId",
        l."LeadCode"::VARCHAR,
        l."ContactName"::VARCHAR,
        l."CompanyName"::VARCHAR,
        l."Email"::VARCHAR,
        l."Phone"::VARCHAR,
        l."Source"::VARCHAR,
        l."AssignedToUserId",
        l."CustomerId",
        l."EstimatedValue"::NUMERIC,
        l."CurrencyCode"::VARCHAR,
        l."ExpectedCloseDate",
        l."LostReason"::VARCHAR,
        l."Notes",
        l."Tags"::VARCHAR,
        l."Priority"::VARCHAR,
        l."Status"::VARCHAR,
        l."WonAt",
        l."LostAt",
        l."CreatedAt",
        l."UpdatedAt",
        l."CreatedByUserId",
        l."UpdatedByUserId",
        l."RowVer",
        s."StageName"::VARCHAR,
        s."Color"::VARCHAR                     AS "StageColor",
        s."Probability"::INT                   AS "StageProbability",
        p."PipelineName"::VARCHAR,
        u."FullName"::VARCHAR                  AS "AssignedToName",
        -- Score mas reciente
        COALESCE((
            SELECT ls."Score"
            FROM   crm."LeadScore" ls
            WHERE  ls."LeadId" = l."LeadId"
            ORDER BY ls."ScoreDate" DESC
            LIMIT 1
        ), 0)::INT                             AS "CurrentScore",
        -- Dias en etapa actual
        COALESCE((
            SELECT EXTRACT(EPOCH FROM (v_now - h."CreatedAt"))::INT / 86400
            FROM   crm."LeadHistory" h
            WHERE  h."LeadId" = l."LeadId"
              AND  h."ChangeType" = 'STAGE_CHANGE'
            ORDER BY h."CreatedAt" DESC
            LIMIT 1
        ), EXTRACT(EPOCH FROM (v_now - l."CreatedAt"))::INT / 86400)::INT AS "DaysInCurrentStage",
        -- Total actividades
        (SELECT COUNT(*)::INT FROM crm."Activity" a
         WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE) AS "TotalActivities",
        -- Actividades pendientes
        (SELECT COUNT(*)::INT FROM crm."Activity" a
         WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE AND a."IsCompleted" = FALSE) AS "PendingActivities",
        -- Dias desde ultima actividad
        COALESCE((
            SELECT EXTRACT(EPOCH FROM (v_now - MAX(a."CreatedAt")))::INT / 86400
            FROM   crm."Activity" a
            WHERE  a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE
        ), -1)::INT                            AS "DaysSinceLastActivity"
    FROM   crm."Lead" l
    JOIN   crm."PipelineStage" s ON s."StageId" = l."StageId"
    JOIN   crm."Pipeline" p      ON p."PipelineId" = l."PipelineId"
    LEFT JOIN sec."User" u       ON u."UserId" = l."AssignedToUserId"
    WHERE  l."LeadId" = p_lead_id
      AND  l."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_Timeline
--  Retorna leads con fechas para renderizar en Gantt/Timeline
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_timeline(INT, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_timeline(
    p_company_id   INT,
    p_pipeline_id  INT DEFAULT NULL,
    p_status       VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "LeadId"            BIGINT,
    "LeadCode"          VARCHAR,
    "ContactName"       VARCHAR,
    "CompanyName"       VARCHAR,
    "EstimatedValue"    NUMERIC,
    "Status"            VARCHAR,
    "Priority"          VARCHAR,
    "StageId"           INT,
    "StageName"         VARCHAR,
    "StageColor"        VARCHAR,
    "CreatedAt"         TIMESTAMP,
    "ExpectedCloseDate" TIMESTAMP,
    "WonAt"             TIMESTAMP,
    "LostAt"            TIMESTAMP,
    "CurrentScore"      INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."LeadId",
        l."LeadCode"::VARCHAR,
        l."ContactName"::VARCHAR,
        l."CompanyName"::VARCHAR,
        l."EstimatedValue"::NUMERIC,
        l."Status"::VARCHAR,
        l."Priority"::VARCHAR,
        l."StageId"::INT,
        s."StageName"::VARCHAR,
        s."Color"::VARCHAR                     AS "StageColor",
        l."CreatedAt",
        l."ExpectedCloseDate"::TIMESTAMP,
        l."WonAt",
        l."LostAt",
        COALESCE((
            SELECT ls."Score"
            FROM   crm."LeadScore" ls
            WHERE  ls."LeadId" = l."LeadId"
            ORDER BY ls."ScoreDate" DESC
            LIMIT 1
        ), 0)::INT                             AS "CurrentScore"
    FROM   crm."Lead" l
    JOIN   crm."PipelineStage" s ON s."StageId" = l."StageId"
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
      AND  (p_status IS NULL OR l."Status" = p_status)
    ORDER BY l."CreatedAt";
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_GetHistory
--  Historial de cambios de un lead con nombres resueltos
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_gethistory(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_gethistory(
    p_lead_id  BIGINT
)
RETURNS TABLE(
    "HistoryId"     BIGINT,
    "ChangeType"    VARCHAR,
    "FromStageName" VARCHAR,
    "ToStageName"   VARCHAR,
    "ChangedByName" VARCHAR,
    "Notes"         VARCHAR,
    "CreatedAt"     TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        h."HistoryId",
        h."ChangeType"::VARCHAR,
        sf."StageName"::VARCHAR                AS "FromStageName",
        st."StageName"::VARCHAR                AS "ToStageName",
        u."FullName"::VARCHAR                  AS "ChangedByName",
        h."Notes"::VARCHAR,
        h."CreatedAt"
    FROM   crm."LeadHistory" h
    LEFT JOIN crm."PipelineStage" sf ON sf."StageId" = h."FromStageId"
    LEFT JOIN crm."PipelineStage" st ON st."StageId" = h."ToStageId"
    LEFT JOIN sec."User" u           ON u."UserId" = h."ChangedByUserId"
    WHERE  h."LeadId" = p_lead_id
    ORDER BY h."CreatedAt" DESC;
END;
$$;
