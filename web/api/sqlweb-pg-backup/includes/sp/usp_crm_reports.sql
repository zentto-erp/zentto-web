-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm_reports.sql
-- Funciones de reportes avanzados del modulo CRM
-- Fecha: 2026-03-23
-- ============================================================

-- =============================================================================
--  usp_CRM_Report_SalesByPeriod
--  Ventas cerradas (WON) agrupadas por periodo con running total
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_report_salesbyperiod(INT, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_report_salesbyperiod(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_group_by    VARCHAR DEFAULT 'month'  -- 'day', 'week', 'month'
)
RETURNS TABLE(
    "Period"          VARCHAR,
    "WonCount"        INT,
    "WonValue"        NUMERIC,
    "CumulativeValue" NUMERIC,
    "AvgDealSize"     NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_12m_ago TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '12 months';
BEGIN
    RETURN QUERY
    WITH raw_data AS (
        SELECT
            DATE_TRUNC(p_group_by, l."WonAt") AS period,
            COUNT(*)::INT                      AS won_count,
            COALESCE(SUM(l."EstimatedValue"), 0) AS won_value
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."Status" = 'WON'
          AND l."WonAt" IS NOT NULL
          AND l."WonAt" >= v_12m_ago
          AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
        GROUP BY DATE_TRUNC(p_group_by, l."WonAt")
    )
    SELECT
        CASE p_group_by
            WHEN 'day'   THEN TO_CHAR(rd.period, 'YYYY-MM-DD')
            WHEN 'week'  THEN TO_CHAR(rd.period, 'IYYY-"W"IW')
            ELSE               TO_CHAR(rd.period, 'YYYY-MM')
        END::VARCHAR                                                              AS "Period",
        rd.won_count                                                              AS "WonCount",
        ROUND(rd.won_value, 2)                                                    AS "WonValue",
        ROUND(SUM(rd.won_value) OVER (ORDER BY rd.period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS "CumulativeValue",
        CASE WHEN rd.won_count > 0
             THEN ROUND(rd.won_value / rd.won_count, 2)
             ELSE 0::NUMERIC
        END                                                                       AS "AvgDealSize"
    FROM raw_data rd
    ORDER BY rd.period;
END;
$$;

-- =============================================================================
--  usp_CRM_Report_LeadAging
--  Distribucion de leads abiertos por antiguedad (dias sin actividad)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_report_leadaging(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_report_leadaging(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Bucket"     VARCHAR,
    "LeadCount"  INT,
    "TotalValue" NUMERIC,
    "AvgValue"   NUMERIC,
    "Percentage" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now        TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_total_open INT := 0;
BEGIN
    -- Contar total de leads abiertos para calcular porcentaje
    SELECT COUNT(*)::INT INTO v_total_open
    FROM crm."Lead" l
    WHERE l."CompanyId" = p_company_id
      AND l."IsDeleted" = FALSE
      AND l."Status" = 'OPEN'
      AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id);

    RETURN QUERY
    WITH lead_aging AS (
        SELECT
            l."LeadId",
            l."EstimatedValue",
            EXTRACT(DAY FROM (v_now - COALESCE(
                (SELECT MAX(a."CreatedAt")
                 FROM crm."Activity" a
                 WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE),
                l."CreatedAt"
            )))::INT AS days_inactive
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."Status" = 'OPEN'
          AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    ),
    bucketed AS (
        SELECT
            CASE
                WHEN la.days_inactive BETWEEN 0  AND 7  THEN '0-7 dias'
                WHEN la.days_inactive BETWEEN 8  AND 14 THEN '8-14 dias'
                WHEN la.days_inactive BETWEEN 15 AND 30 THEN '15-30 dias'
                WHEN la.days_inactive BETWEEN 31 AND 60 THEN '31-60 dias'
                ELSE '60+ dias'
            END AS bucket,
            CASE
                WHEN la.days_inactive BETWEEN 0  AND 7  THEN 1
                WHEN la.days_inactive BETWEEN 8  AND 14 THEN 2
                WHEN la.days_inactive BETWEEN 15 AND 30 THEN 3
                WHEN la.days_inactive BETWEEN 31 AND 60 THEN 4
                ELSE 5
            END AS bucket_order,
            la."EstimatedValue"
        FROM lead_aging la
    )
    SELECT
        b.bucket::VARCHAR                                      AS "Bucket",
        COUNT(*)::INT                                          AS "LeadCount",
        COALESCE(ROUND(SUM(b."EstimatedValue"), 2), 0)        AS "TotalValue",
        COALESCE(ROUND(AVG(b."EstimatedValue"), 2), 0)        AS "AvgValue",
        CASE WHEN v_total_open > 0
             THEN ROUND(COUNT(*) * 100.0 / v_total_open, 2)
             ELSE 0::NUMERIC
        END                                                    AS "Percentage"
    FROM bucketed b
    GROUP BY b.bucket, b.bucket_order
    ORDER BY b.bucket_order;
END;
$$;

-- =============================================================================
--  usp_CRM_Report_ConversionBySource
--  Conversion y metricas por fuente de origen del lead
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_report_conversionbysource(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_report_conversionbysource(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Source"         VARCHAR,
    "TotalLeads"     INT,
    "WonLeads"       INT,
    "LostLeads"      INT,
    "OpenLeads"      INT,
    "ConversionRate" NUMERIC,
    "AvgDaysToClose" NUMERIC,
    "TotalValue"     NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(l."Source", 'Sin fuente')::VARCHAR           AS "Source",
        COUNT(*)::INT                                         AS "TotalLeads",
        COUNT(*) FILTER (WHERE l."Status" = 'WON')::INT      AS "WonLeads",
        COUNT(*) FILTER (WHERE l."Status" = 'LOST')::INT     AS "LostLeads",
        COUNT(*) FILTER (WHERE l."Status" = 'OPEN')::INT     AS "OpenLeads",
        CASE WHEN COUNT(*) > 0
             THEN ROUND(
                 COUNT(*) FILTER (WHERE l."Status" = 'WON') * 100.0 / COUNT(*),
             2)
             ELSE 0::NUMERIC
        END                                                   AS "ConversionRate",
        COALESCE(ROUND(
            AVG(
                EXTRACT(EPOCH FROM (l."WonAt" - l."CreatedAt")) / 86400.0
            ) FILTER (WHERE l."Status" = 'WON' AND l."WonAt" IS NOT NULL),
        2), 0)                                                AS "AvgDaysToClose",
        COALESCE(ROUND(
            SUM(l."EstimatedValue") FILTER (WHERE l."Status" = 'WON'),
        2), 0)                                                AS "TotalValue"
    FROM crm."Lead" l
    WHERE l."CompanyId" = p_company_id
      AND l."IsDeleted" = FALSE
      AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    GROUP BY l."Source"
    ORDER BY "WonLeads" DESC, "TotalLeads" DESC;
END;
$$;

-- =============================================================================
--  usp_CRM_Report_TopPerformers
--  Rendimiento de vendedores/usuarios asignados a leads
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_report_topperformers(INT, INT, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_report_topperformers(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "UserId"              INT,
    "UserName"            VARCHAR,
    "LeadsAssigned"       INT,
    "LeadsWon"            INT,
    "LeadsLost"           INT,
    "WinRate"             NUMERIC,
    "TotalRevenue"        NUMERIC,
    "ActivitiesCompleted" INT,
    "AvgDaysToClose"      NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_date_from TIMESTAMP;
BEGIN
    v_date_from := COALESCE(p_date_from, (NOW() AT TIME ZONE 'UTC') - INTERVAL '90 days');

    RETURN QUERY
    WITH user_leads AS (
        SELECT
            l."AssignedToUserId" AS uid,
            COUNT(*)::INT                                      AS leads_assigned,
            COUNT(*) FILTER (WHERE l."Status" = 'WON')::INT   AS leads_won,
            COUNT(*) FILTER (WHERE l."Status" = 'LOST')::INT  AS leads_lost,
            COALESCE(ROUND(
                SUM(l."EstimatedValue") FILTER (WHERE l."Status" = 'WON'),
            2), 0)                                             AS total_revenue,
            COALESCE(ROUND(
                AVG(
                    EXTRACT(EPOCH FROM (l."WonAt" - l."CreatedAt")) / 86400.0
                ) FILTER (WHERE l."Status" = 'WON' AND l."WonAt" IS NOT NULL),
            2), 0)                                             AS avg_days_to_close
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."AssignedToUserId" IS NOT NULL
          AND l."CreatedAt" >= v_date_from
          AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
        GROUP BY l."AssignedToUserId"
    ),
    user_activities AS (
        SELECT
            a."AssignedToUserId" AS uid,
            COUNT(*) FILTER (WHERE a."IsCompleted" = TRUE)::INT AS activities_completed
        FROM crm."Activity" a
        WHERE a."CompanyId" = p_company_id
          AND a."IsDeleted" = FALSE
          AND a."CreatedAt" >= v_date_from
          AND (p_pipeline_id IS NULL OR EXISTS (
               SELECT 1 FROM crm."Lead" l
               WHERE l."LeadId" = a."LeadId" AND l."PipelineId" = p_pipeline_id
          ))
        GROUP BY a."AssignedToUserId"
    )
    SELECT
        ul.uid                                                 AS "UserId",
        COALESCE(u."FullName", 'Sin asignar')::VARCHAR         AS "UserName",
        ul.leads_assigned                                      AS "LeadsAssigned",
        ul.leads_won                                           AS "LeadsWon",
        ul.leads_lost                                          AS "LeadsLost",
        CASE WHEN (ul.leads_won + ul.leads_lost) > 0
             THEN ROUND(ul.leads_won * 100.0 / (ul.leads_won + ul.leads_lost), 2)
             ELSE 0::NUMERIC
        END                                                    AS "WinRate",
        ul.total_revenue                                       AS "TotalRevenue",
        COALESCE(ua.activities_completed, 0)                   AS "ActivitiesCompleted",
        ul.avg_days_to_close                                   AS "AvgDaysToClose"
    FROM user_leads ul
    LEFT JOIN sec."User" u ON u."UserId" = ul.uid
    LEFT JOIN user_activities ua ON ua.uid = ul.uid
    ORDER BY ul.total_revenue DESC, ul.leads_won DESC;
END;
$$;
