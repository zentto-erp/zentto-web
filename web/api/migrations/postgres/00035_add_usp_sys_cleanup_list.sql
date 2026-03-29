-- +goose Up
-- Crea usp_sys_cleanup_list que faltaba en PostgreSQL (existia solo en SQL Server).
-- Requerida por GET /v1/backoffice/dashboard.

CREATE OR REPLACE FUNCTION usp_sys_cleanup_list(
  p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE(
  "CompanyId"       BIGINT,
  "CompanyCode"     VARCHAR,
  "LegalName"       VARCHAR,
  "Plan"            VARCHAR,
  "Reason"          VARCHAR,
  "Status"          VARCHAR,
  "FlaggedAt"       TIMESTAMP,
  "DeleteAfter"     TIMESTAMP,
  "DbSizeMB"        NUMERIC,
  "LastLoginAt"     TIMESTAMP,
  "DaysUntilDelete"  INT
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId"::BIGINT,
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    c."Plan"::VARCHAR,
    q."Reason"::VARCHAR,
    q."Status"::VARCHAR,
    q."FlaggedAt",
    q."DeleteAfter",
    COALESCE(rl."DbSizeMB", NULL::NUMERIC),
    rl."LastLoginAt",
    CASE
      WHEN q."DeleteAfter" IS NULL THEN NULL::INT
      ELSE EXTRACT(DAY FROM q."DeleteAfter" - NOW())::INT
    END
  FROM sys."CleanupQueue" q
  JOIN cfg."Company" c ON c."CompanyId" = q."CompanyId"
  LEFT JOIN LATERAL (
    SELECT r."DbSizeMB", r."LastLoginAt"
    FROM sys."TenantResourceLog" r
    WHERE r."CompanyId" = q."CompanyId"
    ORDER BY r."RecordedAt" DESC
    LIMIT 1
  ) rl ON TRUE
  WHERE (p_status IS NULL OR q."Status" = p_status)
  ORDER BY q."FlaggedAt" DESC;
END; $$;

-- +goose Down
DROP FUNCTION IF EXISTS usp_sys_cleanup_list(VARCHAR);
