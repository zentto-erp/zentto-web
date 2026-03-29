-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm_analytics.sql
-- Funciones de analytics del modulo CRM
-- Fecha: 2026-03-23
-- ============================================================

-- =============================================================================
--  usp_CRM_Analytics_KPIs
--  KPIs principales del pipeline CRM
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_kpis(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_kpis(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "OpenCount"         INT,
    "OpenValue"         NUMERIC,
    "WonCount"          INT,
    "WonValue"          NUMERIC,
    "LostCount"         INT,
    "ConversionRate"    NUMERIC,
    "AvgDealSize"       NUMERIC,
    "AvgDaysToClose"    NUMERIC,
    "ActivitiesPending" INT,
    "ActivitiesOverdue" INT,
    "NewLeadsThisMonth" INT,
    "NewLeadsLastMonth" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now            TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_30d_ago        TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '30 days';
    v_90d_ago        TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '90 days';
    v_month_start    TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    v_last_month_start TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') - INTERVAL '1 month';

    v_open_count         INT := 0;
    v_open_value         NUMERIC := 0;
    v_won_count          INT := 0;
    v_won_value          NUMERIC := 0;
    v_lost_count         INT := 0;
    v_conversion_rate    NUMERIC := 0;
    v_avg_deal_size      NUMERIC := 0;
    v_avg_days_to_close  NUMERIC := 0;
    v_act_pending        INT := 0;
    v_act_overdue        INT := 0;
    v_new_this_month     INT := 0;
    v_new_last_month     INT := 0;
BEGIN
    -- Leads abiertos
    SELECT COUNT(*)::INT, COALESCE(SUM(l."EstimatedValue"), 0)
    INTO   v_open_count, v_open_value
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'OPEN'
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Leads ganados ultimos 30 dias
    SELECT COUNT(*)::INT, COALESCE(SUM(l."EstimatedValue"), 0)
    INTO   v_won_count, v_won_value
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'WON'
      AND  l."WonAt" >= v_30d_ago
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Leads perdidos ultimos 30 dias
    SELECT COUNT(*)::INT
    INTO   v_lost_count
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'LOST'
      AND  l."LostAt" >= v_30d_ago
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Tasa de conversion
    IF (v_won_count + v_lost_count) > 0 THEN
        v_conversion_rate := ROUND(v_won_count * 100.0 / (v_won_count + v_lost_count), 2);
    END IF;

    -- Tamano promedio de deal ganado (90 dias)
    SELECT COALESCE(AVG(l."EstimatedValue"), 0)
    INTO   v_avg_deal_size
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'WON'
      AND  l."WonAt" >= v_90d_ago
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Dias promedio para cerrar (leads WON)
    SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (l."WonAt" - l."CreatedAt")) / 86400.0), 0)
    INTO   v_avg_days_to_close
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'WON'
      AND  l."WonAt" IS NOT NULL
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Actividades pendientes (DueDate <= NOW)
    SELECT COUNT(*)::INT
    INTO   v_act_pending
    FROM   crm."Activity" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  a."IsCompleted" = FALSE
      AND  a."DueDate" <= v_now
      AND  (p_pipeline_id IS NULL OR EXISTS (
           SELECT 1 FROM crm."Lead" l WHERE l."LeadId" = a."LeadId" AND l."PipelineId" = p_pipeline_id
      ));

    -- Actividades vencidas (DueDate < NOW)
    SELECT COUNT(*)::INT
    INTO   v_act_overdue
    FROM   crm."Activity" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  a."IsCompleted" = FALSE
      AND  a."DueDate" < v_now
      AND  (p_pipeline_id IS NULL OR EXISTS (
           SELECT 1 FROM crm."Lead" l WHERE l."LeadId" = a."LeadId" AND l."PipelineId" = p_pipeline_id
      ));

    -- Leads nuevos este mes
    SELECT COUNT(*)::INT
    INTO   v_new_this_month
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."CreatedAt" >= v_month_start
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    -- Leads nuevos mes pasado
    SELECT COUNT(*)::INT
    INTO   v_new_last_month
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."CreatedAt" >= v_last_month_start
      AND  l."CreatedAt" < v_month_start
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    RETURN QUERY
    SELECT v_open_count, v_open_value, v_won_count, v_won_value,
           v_lost_count, v_conversion_rate,
           ROUND(v_avg_deal_size, 2), ROUND(v_avg_days_to_close, 2),
           v_act_pending, v_act_overdue,
           v_new_this_month, v_new_last_month;
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_Forecast
--  Forecast ponderado por probabilidad de etapa, por mes futuro
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_forecast(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_forecast(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_months      INT DEFAULT 6
)
RETURNS TABLE(
    "Month"          VARCHAR,
    "WeightedValue"  NUMERIC,
    "TotalValue"     NUMERIC,
    "LeadCount"      INT,
    "AvgProbability" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(m.month_start, 'YYYY-MM')::VARCHAR                    AS "Month",
        COALESCE(SUM(l."EstimatedValue" * s."Probability" / 100.0), 0) AS "WeightedValue",
        COALESCE(SUM(l."EstimatedValue"), 0)                           AS "TotalValue",
        COUNT(l."LeadId")::INT                                         AS "LeadCount",
        COALESCE(ROUND(AVG(s."Probability"), 2), 0)                    AS "AvgProbability"
    FROM generate_series(
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC'),
            DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC') + ((p_months - 1) || ' months')::INTERVAL,
            '1 month'::INTERVAL
         ) AS m(month_start)
    LEFT JOIN crm."Lead" l
        ON  l."CompanyId" = p_company_id
        AND l."IsDeleted" = FALSE
        AND l."Status" = 'OPEN'
        AND l."ExpectedCloseDate" IS NOT NULL
        AND DATE_TRUNC('month', l."ExpectedCloseDate"::TIMESTAMP) = m.month_start
        AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    LEFT JOIN crm."PipelineStage" s
        ON  s."StageId" = l."StageId"
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_Funnel
--  Embudo: leads por etapa con valor, dias promedio y conversion a siguiente
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_funnel(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_funnel(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "StageId"          INT,
    "StageName"        VARCHAR,
    "StageOrder"       INT,
    "Color"            VARCHAR,
    "LeadCount"        INT,
    "TotalValue"       NUMERIC,
    "AvgDaysInStage"   NUMERIC,
    "ConversionToNext" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pipeline_id INT;
BEGIN
    v_pipeline_id := p_pipeline_id;
    IF v_pipeline_id IS NULL THEN
        SELECT p."PipelineId" INTO v_pipeline_id
        FROM   crm."Pipeline" p
        WHERE  p."CompanyId" = p_company_id AND p."IsDefault" = TRUE AND p."IsActive" = TRUE
        LIMIT 1;
    END IF;

    RETURN QUERY
    WITH stage_leads AS (
        SELECT s."StageId"    AS sid,
               COUNT(l."LeadId")::INT AS lead_count,
               COALESCE(SUM(l."EstimatedValue"), 0) AS total_value
        FROM   crm."PipelineStage" s
        LEFT JOIN crm."Lead" l
            ON  l."StageId" = s."StageId"
            AND l."CompanyId" = p_company_id
            AND l."IsDeleted" = FALSE
            AND l."Status" = 'OPEN'
        WHERE  s."PipelineId" = v_pipeline_id AND s."IsDeleted" = FALSE
        GROUP BY s."StageId"
    ),
    stage_days AS (
        -- Promedio de dias que los leads pasaron en cada etapa (usando historial)
        SELECT h."FromStageId" AS sid,
               ROUND(AVG(EXTRACT(EPOCH FROM (
                   COALESCE(h_next."CreatedAt", NOW() AT TIME ZONE 'UTC') - h."CreatedAt"
               )) / 86400.0), 2) AS avg_days
        FROM   crm."LeadHistory" h
        JOIN   crm."Lead" l ON l."LeadId" = h."LeadId"
            AND l."CompanyId" = p_company_id AND l."IsDeleted" = FALSE
        LEFT JOIN LATERAL (
            SELECT h2."CreatedAt"
            FROM   crm."LeadHistory" h2
            WHERE  h2."LeadId" = h."LeadId"
              AND  h2."HistoryId" > h."HistoryId"
            ORDER BY h2."HistoryId"
            LIMIT 1
        ) h_next ON TRUE
        WHERE  h."ChangeType" = 'STAGE_CHANGE'
          AND  h."FromStageId" IS NOT NULL
          AND  (v_pipeline_id IS NULL OR l."PipelineId" = v_pipeline_id)
        GROUP BY h."FromStageId"
    ),
    stage_conversion AS (
        -- % leads que pasaron de esta etapa a la siguiente
        SELECT h."FromStageId" AS sid,
               COUNT(DISTINCT h."LeadId")::NUMERIC AS moved_out,
               -- Total que alguna vez entraron a esa etapa
               (SELECT COUNT(DISTINCT h3."LeadId")
                FROM crm."LeadHistory" h3
                JOIN crm."Lead" l3 ON l3."LeadId" = h3."LeadId" AND l3."CompanyId" = p_company_id
                WHERE h3."ToStageId" = h."FromStageId"
               )::NUMERIC AS entered
        FROM   crm."LeadHistory" h
        JOIN   crm."Lead" l ON l."LeadId" = h."LeadId"
            AND l."CompanyId" = p_company_id AND l."IsDeleted" = FALSE
        WHERE  h."ChangeType" = 'STAGE_CHANGE'
          AND  h."FromStageId" IS NOT NULL
          AND  (v_pipeline_id IS NULL OR l."PipelineId" = v_pipeline_id)
        GROUP BY h."FromStageId"
    )
    SELECT
        s."StageId"::INT,
        s."StageName"::VARCHAR,
        s."StageOrder",
        s."Color"::VARCHAR,
        COALESCE(sl.lead_count, 0),
        COALESCE(sl.total_value, 0),
        COALESCE(sd.avg_days, 0),
        CASE WHEN COALESCE(sc.entered, 0) > 0
             THEN ROUND(sc.moved_out * 100.0 / sc.entered, 2)
             ELSE 0::NUMERIC
        END
    FROM   crm."PipelineStage" s
    LEFT JOIN stage_leads      sl ON sl.sid = s."StageId"
    LEFT JOIN stage_days       sd ON sd.sid = s."StageId"
    LEFT JOIN stage_conversion sc ON sc.sid = s."StageId"
    WHERE  s."PipelineId" = v_pipeline_id AND s."IsDeleted" = FALSE
    ORDER BY s."StageOrder";
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_WinLoss_ByPeriod
--  Win/Loss agrupado por mes
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_winloss_byperiod(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_winloss_byperiod(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL,
    p_date_to     TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "Period"    VARCHAR,
    "WonCount"  INT,
    "WonValue"  NUMERIC,
    "LostCount" INT,
    "LostValue" NUMERIC,
    "WinRate"   NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_date_from TIMESTAMP;
    v_date_to   TIMESTAMP;
BEGIN
    v_date_from := COALESCE(p_date_from, (NOW() AT TIME ZONE 'UTC') - INTERVAL '90 days');
    v_date_to   := COALESCE(p_date_to,   NOW() AT TIME ZONE 'UTC');

    RETURN QUERY
    SELECT
        TO_CHAR(DATE_TRUNC('month', COALESCE(l."WonAt", l."LostAt")), 'YYYY-MM')::VARCHAR AS "Period",
        COUNT(*) FILTER (WHERE l."Status" = 'WON')::INT   AS "WonCount",
        COALESCE(SUM(l."EstimatedValue") FILTER (WHERE l."Status" = 'WON'), 0)  AS "WonValue",
        COUNT(*) FILTER (WHERE l."Status" = 'LOST')::INT  AS "LostCount",
        COALESCE(SUM(l."EstimatedValue") FILTER (WHERE l."Status" = 'LOST'), 0) AS "LostValue",
        CASE WHEN COUNT(*) > 0
             THEN ROUND(
                 COUNT(*) FILTER (WHERE l."Status" = 'WON') * 100.0 / COUNT(*),
             2) ELSE 0::NUMERIC
        END AS "WinRate"
    FROM crm."Lead" l
    WHERE l."CompanyId" = p_company_id
      AND l."IsDeleted" = FALSE
      AND l."Status" IN ('WON', 'LOST')
      AND COALESCE(l."WonAt", l."LostAt") >= v_date_from
      AND COALESCE(l."WonAt", l."LostAt") <= v_date_to
      AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    GROUP BY DATE_TRUNC('month', COALESCE(l."WonAt", l."LostAt"))
    ORDER BY DATE_TRUNC('month', COALESCE(l."WonAt", l."LostAt"));
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_WinLoss_BySource
--  Win/Loss agrupado por fuente (Source)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_winloss_bysource(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_winloss_bysource(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL,
    p_date_to     TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "Source"   VARCHAR,
    "WonCount" INT,
    "LostCount" INT,
    "WinRate"  NUMERIC,
    "AvgValue" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_date_from TIMESTAMP;
    v_date_to   TIMESTAMP;
BEGIN
    v_date_from := COALESCE(p_date_from, (NOW() AT TIME ZONE 'UTC') - INTERVAL '90 days');
    v_date_to   := COALESCE(p_date_to,   NOW() AT TIME ZONE 'UTC');

    RETURN QUERY
    SELECT
        COALESCE(l."Source", 'Sin fuente')::VARCHAR AS "Source",
        COUNT(*) FILTER (WHERE l."Status" = 'WON')::INT  AS "WonCount",
        COUNT(*) FILTER (WHERE l."Status" = 'LOST')::INT AS "LostCount",
        CASE WHEN COUNT(*) > 0
             THEN ROUND(
                 COUNT(*) FILTER (WHERE l."Status" = 'WON') * 100.0 / COUNT(*),
             2) ELSE 0::NUMERIC
        END AS "WinRate",
        COALESCE(ROUND(AVG(l."EstimatedValue"), 2), 0) AS "AvgValue"
    FROM crm."Lead" l
    WHERE l."CompanyId" = p_company_id
      AND l."IsDeleted" = FALSE
      AND l."Status" IN ('WON', 'LOST')
      AND COALESCE(l."WonAt", l."LostAt") >= v_date_from
      AND COALESCE(l."WonAt", l."LostAt") <= v_date_to
      AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    GROUP BY l."Source"
    ORDER BY "WonCount" DESC;
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_Velocity
--  Velocidad del pipeline: dias promedio y mediana por etapa
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_velocity(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_velocity(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "StageName"          VARCHAR,
    "StageOrder"         INT,
    "Color"              VARCHAR,
    "AvgDaysInStage"     NUMERIC,
    "MedianDaysInStage"  NUMERIC,
    "LeadsThroughStage"  INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pipeline_id INT;
BEGIN
    v_pipeline_id := p_pipeline_id;
    IF v_pipeline_id IS NULL THEN
        SELECT p."PipelineId" INTO v_pipeline_id
        FROM   crm."Pipeline" p
        WHERE  p."CompanyId" = p_company_id AND p."IsDefault" = TRUE AND p."IsActive" = TRUE
        LIMIT 1;
    END IF;

    RETURN QUERY
    WITH stage_durations AS (
        -- Calcular dias que cada lead paso en cada etapa (desde que entro hasta que salio)
        SELECT
            h."FromStageId" AS sid,
            EXTRACT(EPOCH FROM (
                COALESCE(h_next."CreatedAt", NOW() AT TIME ZONE 'UTC') - h."CreatedAt"
            )) / 86400.0 AS days_in_stage
        FROM crm."LeadHistory" h
        JOIN crm."Lead" l ON l."LeadId" = h."LeadId"
            AND l."CompanyId" = p_company_id
            AND l."IsDeleted" = FALSE
            AND (v_pipeline_id IS NULL OR l."PipelineId" = v_pipeline_id)
        LEFT JOIN LATERAL (
            SELECT h2."CreatedAt"
            FROM   crm."LeadHistory" h2
            WHERE  h2."LeadId" = h."LeadId"
              AND  h2."HistoryId" > h."HistoryId"
            ORDER BY h2."HistoryId"
            LIMIT 1
        ) h_next ON TRUE
        WHERE h."ChangeType" = 'STAGE_CHANGE'
          AND h."FromStageId" IS NOT NULL
    )
    SELECT
        s."StageName"::VARCHAR,
        s."StageOrder",
        s."Color"::VARCHAR,
        COALESCE(ROUND(AVG(sd.days_in_stage), 2), 0)                             AS "AvgDaysInStage",
        COALESCE(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sd.days_in_stage)::NUMERIC, 2), 0) AS "MedianDaysInStage",
        COUNT(sd.sid)::INT                                                         AS "LeadsThroughStage"
    FROM crm."PipelineStage" s
    LEFT JOIN stage_durations sd ON sd.sid = s."StageId"
    WHERE s."PipelineId" = v_pipeline_id AND s."IsDeleted" = FALSE
    GROUP BY s."StageId", s."StageName", s."StageOrder", s."Color"
    ORDER BY s."StageOrder";
END;
$$;

-- =============================================================================
--  usp_CRM_Analytics_ActivityReport
--  Reporte de actividades por usuario y tipo
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_analytics_activityreport(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_analytics_activityreport(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL,
    p_date_to     TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "AssignedToUserId" INT,
    "AssignedToName"   VARCHAR,
    "ActivityType"     VARCHAR,
    "TotalCount"       INT,
    "CompletedCount"   INT,
    "PendingCount"     INT,
    "OverdueCount"     INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_date_from TIMESTAMP;
    v_date_to   TIMESTAMP;
    v_now       TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    v_date_from := COALESCE(p_date_from, (NOW() AT TIME ZONE 'UTC') - INTERVAL '90 days');
    v_date_to   := COALESCE(p_date_to,   NOW() AT TIME ZONE 'UTC');

    RETURN QUERY
    SELECT
        a."AssignedToUserId",
        COALESCE(u."FullName", 'Sin asignar')::VARCHAR AS "AssignedToName",
        COALESCE(a."ActivityType", ''::VARCHAR)         AS "ActivityType",
        COUNT(*)::INT                                   AS "TotalCount",
        COUNT(*) FILTER (WHERE a."IsCompleted" = TRUE)::INT  AS "CompletedCount",
        COUNT(*) FILTER (WHERE a."IsCompleted" = FALSE)::INT AS "PendingCount",
        COUNT(*) FILTER (WHERE a."IsCompleted" = FALSE AND a."DueDate" < v_now)::INT AS "OverdueCount"
    FROM crm."Activity" a
    LEFT JOIN sec."User" u ON u."UserId" = a."AssignedToUserId"
    WHERE a."CompanyId" = p_company_id
      AND a."IsDeleted" = FALSE
      AND a."CreatedAt" >= v_date_from
      AND a."CreatedAt" <= v_date_to
      AND (p_pipeline_id IS NULL OR EXISTS (
           SELECT 1 FROM crm."Lead" l
           WHERE l."LeadId" = a."LeadId" AND l."PipelineId" = p_pipeline_id
      ))
    GROUP BY a."AssignedToUserId", u."FullName", a."ActivityType"
    ORDER BY "TotalCount" DESC;
END;
$$;
