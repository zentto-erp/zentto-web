-- +goose Up
-- Fix broken functions across CRM, Fleet, and Audit modules.
-- Root causes:
--   1) sec."User" has "DisplayName"/"UserName", NOT "FullName"
--   2) fleet."VehicleDocument"."IssuedAt"/"ExpiresAt" are DATE, not TIMESTAMP
--   3) fleet."MaintenanceOrder" has no "MaintenanceType" or "EstimatedCost" column
--   4) usp_crm_lead_findstale param name mismatch (p_days vs p_stale_days)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. usp_crm_lead_findstale — rename p_days → p_stale_days, fix FullName
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_lead_findstale CASCADE;
CREATE OR REPLACE FUNCTION public.usp_crm_lead_findstale(
    p_company_id   INTEGER,
    p_stale_days   INTEGER DEFAULT 7,
    p_pipeline_id  INTEGER DEFAULT NULL
)
RETURNS TABLE(
    "LeadId"                 BIGINT,
    "LeadCode"               VARCHAR,
    "ContactName"            VARCHAR,
    "CompanyName"            VARCHAR,
    "StageName"              VARCHAR,
    "EstimatedValue"         NUMERIC,
    "DaysSinceLastActivity"  INTEGER,
    "AssignedToName"         VARCHAR
)
LANGUAGE plpgsql AS $function$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    WITH last_touch AS (
        SELECT
            l."LeadId",
            GREATEST(
                COALESCE((
                    SELECT MAX(a."CreatedAt")
                    FROM   crm."Activity" a
                    WHERE  a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE
                ), l."CreatedAt"),
                COALESCE((
                    SELECT MAX(h."CreatedAt")
                    FROM   crm."LeadHistory" h
                    WHERE  h."LeadId" = l."LeadId" AND h."ChangeType" = 'STAGE_CHANGE'
                ), l."CreatedAt")
            ) AS last_touch_at
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."Status" = 'OPEN'
          AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    )
    SELECT
        l."LeadId",
        l."LeadCode"::VARCHAR,
        l."ContactName"::VARCHAR,
        l."CompanyName"::VARCHAR,
        s."StageName"::VARCHAR,
        l."EstimatedValue"::NUMERIC,
        (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT AS "DaysSinceLastActivity",
        COALESCE(u."DisplayName", u."UserName", 'Sin asignar')::VARCHAR AS "AssignedToName"
    FROM   crm."Lead" l
    JOIN   last_touch lt          ON lt."LeadId" = l."LeadId"
    JOIN   crm."PipelineStage" s  ON s."StageId" = l."StageId"
    LEFT JOIN sec."User" u        ON u."UserId" = l."AssignedToUserId"
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'OPEN'
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
      AND  (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT >= p_stale_days
    ORDER BY (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT DESC;
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. usp_crm_lead_getdetail — fix FullName → DisplayName/UserName
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_lead_getdetail CASCADE;
CREATE OR REPLACE FUNCTION public.usp_crm_lead_getdetail(
    p_lead_id BIGINT
)
RETURNS TABLE(
    "LeadId"              BIGINT,
    "CompanyId"           INTEGER,
    "BranchId"            INTEGER,
    "PipelineId"          BIGINT,
    "StageId"             BIGINT,
    "LeadCode"            VARCHAR,
    "ContactName"         VARCHAR,
    "CompanyName"         VARCHAR,
    "Email"               VARCHAR,
    "Phone"               VARCHAR,
    "Source"              VARCHAR,
    "AssignedToUserId"    INTEGER,
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
    "CreatedByUserId"     INTEGER,
    "UpdatedByUserId"     INTEGER,
    "RowVer"              INTEGER,
    "StageName"           VARCHAR,
    "StageColor"          VARCHAR,
    "StageProbability"    INTEGER,
    "PipelineName"        VARCHAR,
    "AssignedToName"      VARCHAR,
    "CurrentScore"        INTEGER,
    "DaysInCurrentStage"  INTEGER,
    "TotalActivities"     INTEGER,
    "PendingActivities"   INTEGER,
    "DaysSinceLastActivity" INTEGER
)
LANGUAGE plpgsql AS $function$
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
        COALESCE(u."DisplayName", u."UserName", 'Sin asignar')::VARCHAR AS "AssignedToName",
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
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. usp_crm_lead_gethistory — fix FullName → DisplayName/UserName
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_lead_gethistory CASCADE;
CREATE OR REPLACE FUNCTION public.usp_crm_lead_gethistory(
    p_lead_id BIGINT
)
RETURNS TABLE(
    "HistoryId"      BIGINT,
    "ChangeType"     VARCHAR,
    "FromStageName"  VARCHAR,
    "ToStageName"    VARCHAR,
    "ChangedByName"  VARCHAR,
    "Notes"          VARCHAR,
    "CreatedAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $function$
BEGIN
    RETURN QUERY
    SELECT
        h."HistoryId",
        h."ChangeType"::VARCHAR,
        sf."StageName"::VARCHAR                AS "FromStageName",
        st."StageName"::VARCHAR                AS "ToStageName",
        COALESCE(u."DisplayName", u."UserName", 'Sistema')::VARCHAR AS "ChangedByName",
        h."Notes"::VARCHAR,
        h."CreatedAt"
    FROM   crm."LeadHistory" h
    LEFT JOIN crm."PipelineStage" sf ON sf."StageId" = h."FromStageId"
    LEFT JOIN crm."PipelineStage" st ON st."StageId" = h."ToStageId"
    LEFT JOIN sec."User" u           ON u."UserId" = h."ChangedByUserId"
    WHERE  h."LeadId" = p_lead_id
    ORDER BY h."CreatedAt" DESC;
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. usp_crm_analytics_activityreport — fix FullName → DisplayName/UserName
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_analytics_activityreport CASCADE;
CREATE OR REPLACE FUNCTION public.usp_crm_analytics_activityreport(
    p_company_id  INTEGER,
    p_pipeline_id INTEGER DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL,
    p_date_to     TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "AssignedToUserId"  INTEGER,
    "AssignedToName"    VARCHAR,
    "ActivityType"      VARCHAR,
    "TotalCount"        INTEGER,
    "CompletedCount"    INTEGER,
    "PendingCount"      INTEGER,
    "OverdueCount"      INTEGER
)
LANGUAGE plpgsql AS $function$
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
        COALESCE(u."DisplayName", u."UserName", 'Sin asignar')::VARCHAR AS "AssignedToName",
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
    GROUP BY a."AssignedToUserId", u."DisplayName", u."UserName", a."ActivityType"
    ORDER BY "TotalCount" DESC;
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. usp_crm_report_topperformers — fix FullName → DisplayName/UserName
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_report_topperformers CASCADE;
CREATE OR REPLACE FUNCTION public.usp_crm_report_topperformers(
    p_company_id  INTEGER,
    p_pipeline_id INTEGER DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "UserId"              INTEGER,
    "UserName"            VARCHAR,
    "LeadsAssigned"       INTEGER,
    "LeadsWon"            INTEGER,
    "LeadsLost"           INTEGER,
    "WinRate"             NUMERIC,
    "TotalRevenue"        NUMERIC,
    "ActivitiesCompleted" INTEGER,
    "AvgDaysToClose"      NUMERIC
)
LANGUAGE plpgsql AS $function$
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
        COALESCE(u."DisplayName", u."UserName", 'Sin asignar')::VARCHAR AS "UserName",
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
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. usp_fleet_alerts_get — fix ExpiresAt date→timestamp cast
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_fleet_alerts_get CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fleet_alerts_get(
    p_company_id INTEGER,
    p_branch_id  INTEGER DEFAULT NULL
)
RETURNS TABLE(
    "AlertType"               VARCHAR,
    "ItemId"                  BIGINT,
    "VehicleId"               BIGINT,
    "LicensePlate"            VARCHAR,
    "Brand"                   VARCHAR,
    "Model"                   VARCHAR,
    "DocumentType"            VARCHAR,
    "DocumentNumber"          VARCHAR,
    "MaintenanceTypeName"     VARCHAR,
    "OrderNumber"             VARCHAR,
    "ExpiryDate"              TIMESTAMP,
    "ScheduledDate"           TIMESTAMP,
    "DaysOverdue"             INTEGER,
    "DaysUntilExpiry"         INTEGER,
    "ExpiredDocsCount"        INTEGER,
    "ExpiringSoonDocsCount"   INTEGER,
    "OverdueMaintenanceCount" INTEGER
)
LANGUAGE plpgsql AS $function$
DECLARE
    v_now        TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_in30days   TIMESTAMP := (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days';
    v_expired_docs INT;
    v_expiring_docs INT;
    v_overdue_maint INT;
BEGIN
    -- Calcular conteos
    SELECT COUNT(*)::INT INTO v_expired_docs
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" < v_now::DATE AND vd."ExpiresAt" IS NOT NULL;

    SELECT COUNT(*)::INT INTO v_expiring_docs
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" >= v_now::DATE AND vd."ExpiresAt" <= v_in30days::DATE;

    SELECT COUNT(*)::INT INTO v_overdue_maint
    FROM fleet."MaintenanceOrder" mo
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" = 'SCHEDULED'
      AND mo."ScheduledDate" < v_now
      AND mo."IsDeleted" IS NOT TRUE;

    -- Documentos vencidos
    RETURN QUERY
    SELECT
        'EXPIRED'::VARCHAR,
        vd."VehicleDocumentId",
        vd."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        vd."DocumentType"::VARCHAR,
        vd."DocumentNumber"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        vd."ExpiresAt"::TIMESTAMP,
        NULL::TIMESTAMP,
        EXTRACT(DAY FROM v_now - vd."ExpiresAt"::TIMESTAMP)::INT,
        NULL::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" < v_now::DATE AND vd."ExpiresAt" IS NOT NULL
    ORDER BY vd."ExpiresAt";

    -- Documentos por vencer (30 dias)
    RETURN QUERY
    SELECT
        'EXPIRING_SOON'::VARCHAR,
        vd."VehicleDocumentId",
        vd."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        vd."DocumentType"::VARCHAR,
        vd."DocumentNumber"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        vd."ExpiresAt"::TIMESTAMP,
        NULL::TIMESTAMP,
        NULL::INT,
        EXTRACT(DAY FROM vd."ExpiresAt"::TIMESTAMP - v_now)::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" >= v_now::DATE AND vd."ExpiresAt" <= v_in30days::DATE
    ORDER BY vd."ExpiresAt";

    -- Mantenimientos vencidos
    RETURN QUERY
    SELECT
        'MAINTENANCE_OVERDUE'::VARCHAR,
        mo."MaintenanceOrderId",
        mo."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        mt."TypeName"::VARCHAR,
        mo."OrderNumber"::VARCHAR,
        NULL::TIMESTAMP,
        mo."ScheduledDate",
        EXTRACT(DAY FROM v_now - mo."ScheduledDate")::INT,
        NULL::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" = 'SCHEDULED'
      AND mo."ScheduledDate" < v_now
      AND mo."IsDeleted" IS NOT TRUE
    ORDER BY mo."ScheduledDate";
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. usp_fleet_vehicledocument_list — fix IssuedAt/ExpiresAt date→timestamp
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_fleet_vehicledocument_list CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fleet_vehicledocument_list(
    p_vehicle_id INTEGER
)
RETURNS TABLE(
    "VehicleDocumentId" BIGINT,
    "VehicleId"         BIGINT,
    "DocumentType"      VARCHAR,
    "DocumentNumber"    VARCHAR,
    "Description"       VARCHAR,
    "IssuedAt"          DATE,
    "ExpiresAt"         DATE,
    "FileUrl"           VARCHAR,
    "Notes"             VARCHAR,
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."VehicleDocumentId",
        d."VehicleId",
        d."DocumentType"::VARCHAR,
        d."DocumentNumber"::VARCHAR,
        d."Description"::VARCHAR,
        d."IssuedAt",
        d."ExpiresAt",
        d."FileUrl"::VARCHAR,
        d."Notes"::VARCHAR,
        d."CreatedAt"
    FROM fleet."VehicleDocument" d
    WHERE d."VehicleId" = p_vehicle_id
      AND d."IsDeleted" IS NOT TRUE
    ORDER BY d."ExpiresAt" DESC;
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. usp_fleet_analytics_nextmaintenance — fix MaintenanceType + EstimatedCost
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_fleet_analytics_nextmaintenance CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fleet_analytics_nextmaintenance(
    p_company_id INTEGER
)
RETURNS TABLE(
    "MaintenanceOrderId" BIGINT,
    "OrderNumber"        VARCHAR,
    "LicensePlate"       VARCHAR,
    "BrandModel"         VARCHAR,
    "MaintenanceType"    VARCHAR,
    "ScheduledDate"      TIMESTAMP,
    "EstimatedCost"      NUMERIC,
    "Status"             VARCHAR
)
LANGUAGE plpgsql AS $function$
BEGIN
    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR(30),
        v."LicensePlate"::VARCHAR(20),
        (COALESCE(v."Brand", '') || ' ' || COALESCE(v."Model", ''))::VARCHAR(120),
        COALESCE(mt."TypeName", 'Sin tipo')::VARCHAR(60),
        mo."ScheduledDate",
        COALESCE(mo."TotalCost", 0)::NUMERIC,
        mo."Status"::VARCHAR(20)
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" IN ('PENDING', 'SCHEDULED')
      AND mo."IsDeleted" IS NOT TRUE
      AND v."IsDeleted" IS NOT TRUE
    ORDER BY mo."ScheduledDate" ASC
    LIMIT 5;
END;
$function$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. usp_fleet_vehicledocument_upsert — fix param types timestamp→date
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_fleet_vehicledocument_upsert CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fleet_vehicledocument_upsert(
    p_company_id     INTEGER DEFAULT NULL,
    p_document_id    INTEGER DEFAULT NULL,
    p_vehicle_id     INTEGER DEFAULT NULL,
    p_document_type  VARCHAR DEFAULT NULL,
    p_document_number VARCHAR DEFAULT NULL,
    p_description    VARCHAR DEFAULT NULL,
    p_issue_date     DATE    DEFAULT NULL,
    p_expiry_date    DATE    DEFAULT NULL,
    p_file_path      VARCHAR DEFAULT NULL,
    p_notes          VARCHAR DEFAULT NULL,
    p_user_id        INTEGER DEFAULT NULL
)
RETURNS TABLE(ok INTEGER, mensaje VARCHAR)
LANGUAGE plpgsql AS $function$
BEGIN
    -- p_company_id se ignora (la tabla VehicleDocument no tiene CompanyId)

    IF p_document_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."VehicleDocument" WHERE "VehicleDocumentId" = p_document_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."VehicleDocument" SET
            "DocumentType"     = COALESCE(p_document_type, "DocumentType"),
            "DocumentNumber"   = COALESCE(p_document_number, "DocumentNumber"),
            "Description"      = COALESCE(p_description, "Description"),
            "IssuedAt"         = COALESCE(p_issue_date, "IssuedAt"),
            "ExpiresAt"        = COALESCE(p_expiry_date, "ExpiresAt"),
            "FileUrl"          = COALESCE(p_file_path, "FileUrl"),
            "Notes"            = COALESCE(p_notes, "Notes"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "VehicleDocumentId" = p_document_id;

        RETURN QUERY SELECT 1, 'Documento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."VehicleDocument" (
            "VehicleId", "DocumentType", "DocumentNumber", "Description",
            "IssuedAt", "ExpiresAt", "FileUrl", "Notes",
            "CreatedAt", "CreatedByUserId"
        ) VALUES (
            p_vehicle_id, p_document_type, p_document_number, p_description,
            p_issue_date, p_expiry_date, p_file_path, p_notes,
            NOW() AT TIME ZONE 'UTC', p_user_id
        );

        RETURN QUERY SELECT 1, 'Documento creado'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$function$;
-- +goose StatementEnd

-- +goose Down
-- Rollback: re-create old (broken) versions — not recommended
SELECT 1; -- no-op down migration
