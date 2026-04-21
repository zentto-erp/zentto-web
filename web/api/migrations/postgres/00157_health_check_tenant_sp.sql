-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Lote 4.A — cierre gap G-08 v2 del audit del Lote 1 multinicho.
--
-- Crea usp_Sys_HealthCheck_Tenant(p_company_code) que devuelve un snapshot
-- operativo del tenant: identidad, suscripcion, usuarios activos, leads
-- recientes, BD por-tenant. Usado por GET /v1/status?tenant=<subdomain>
-- cuando el caller pide detalle operativo.
--
-- Idempotente (CREATE OR REPLACE). Solo PostgreSQL (D-002).
-- ══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_Sys_HealthCheck_Tenant(
    p_company_code VARCHAR DEFAULT NULL,
    p_subdomain    VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "CompanyId"              INTEGER,
    "CompanyCode"             VARCHAR,
    "LegalName"               VARCHAR,
    "TenantSubdomain"         VARCHAR,
    "Plan"                    VARCHAR,
    "TenantStatus"            VARCHAR,
    "OwnerEmail"              VARCHAR,
    "IsActive"                BOOLEAN,
    "SubscriptionStatus"      VARCHAR,
    "SubscriptionSource"      VARCHAR,
    "TrialEndsAt"             TIMESTAMP,
    "CurrentPeriodEnd"        TIMESTAMP,
    "MonthlyRecurringRevenue" NUMERIC,
    "ActiveUserCount"         INTEGER,
    "LastUserActivityAt"      TIMESTAMP,
    "LeadsLast24h"            INTEGER,
    "LeadsConverted"          INTEGER,
    "TenantDbProvisioned"     BOOLEAN,
    "TenantDbName"            VARCHAR,
    "SnapshotAt"              TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INTEGER;
BEGIN
    -- Resolver el tenant por codigo o subdominio (cualquiera que venga).
    IF p_company_code IS NOT NULL AND p_company_code <> '' THEN
        SELECT c."CompanyId" INTO v_company_id
          FROM cfg."Company" c
         WHERE LOWER(c."CompanyCode") = LOWER(p_company_code)
         LIMIT 1;
    ELSIF p_subdomain IS NOT NULL AND p_subdomain <> '' THEN
        SELECT c."CompanyId" INTO v_company_id
          FROM cfg."Company" c
         WHERE LOWER(c."TenantSubdomain") = LOWER(p_subdomain)
         LIMIT 1;
    END IF;

    -- Si no se encuentra, retornar cero filas; el caller debe manejar el vacio
    -- como tenant_not_found y subir overall a degraded.
    IF v_company_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        c."CompanyId"::INTEGER,
        c."CompanyCode"::VARCHAR,
        c."LegalName"::VARCHAR,
        c."TenantSubdomain"::VARCHAR,
        c."Plan"::VARCHAR,
        c."TenantStatus"::VARCHAR,
        c."OwnerEmail"::VARCHAR,
        c."IsActive"::BOOLEAN,
        s."Status"::VARCHAR                    AS "SubscriptionStatus",
        s."Source"::VARCHAR                    AS "SubscriptionSource",
        s."TrialEndsAt"::TIMESTAMP,
        s."CurrentPeriodEnd"::TIMESTAMP,
        COALESCE(s."MonthlyRecurringRevenue", 0)::NUMERIC,
        (
            SELECT COUNT(*)::INTEGER
              FROM sec."User" u
             WHERE u."CompanyId" = c."CompanyId"
               AND u."IsActive"  = TRUE
               AND COALESCE(u."IsDeleted", FALSE) = FALSE
        )                                      AS "ActiveUserCount",
        (
            SELECT MAX(u."LastLoginAt")::TIMESTAMP
              FROM sec."User" u
             WHERE u."CompanyId" = c."CompanyId"
        )                                      AS "LastUserActivityAt",
        (
            SELECT COUNT(*)::INTEGER
              FROM public."Lead" l
             WHERE l."ConvertedToCompanyId" = c."CompanyId"
               AND l."CreatedAt" >= NOW() - INTERVAL '24 hours'
        )                                      AS "LeadsLast24h",
        (
            SELECT COUNT(*)::INTEGER
              FROM public."Lead" l
             WHERE l."ConvertedToCompanyId" = c."CompanyId"
               AND l."Status" = 'converted'
        )                                      AS "LeadsConverted",
        (
            SELECT COALESCE(td."IsActive", FALSE)
              FROM sys."TenantDatabase" td
             WHERE td."CompanyId" = c."CompanyId"
             LIMIT 1
        )                                      AS "TenantDbProvisioned",
        (
            SELECT td."DbName"::VARCHAR
              FROM sys."TenantDatabase" td
             WHERE td."CompanyId" = c."CompanyId"
             LIMIT 1
        )                                      AS "TenantDbName",
        NOW()                                  AS "SnapshotAt"
      FROM cfg."Company" c
      LEFT JOIN sys."Subscription" s
             ON s."CompanyId" = c."CompanyId"
            AND s."Status" IN ('trialing', 'active', 'past_due', 'paused')
     WHERE c."CompanyId" = v_company_id
     ORDER BY s."CreatedAt" DESC NULLS LAST
     LIMIT 1;
END;
$$;
-- +goose StatementEnd

COMMENT ON FUNCTION usp_Sys_HealthCheck_Tenant IS
'Snapshot operativo por-tenant. Cierra gap G-08 v2 del audit multinicho. Llamar con company_code o subdomain (cualquiera). Si el tenant no existe, retorna 0 filas.';

-- +goose Down
DROP FUNCTION IF EXISTS usp_Sys_HealthCheck_Tenant(VARCHAR, VARCHAR);
