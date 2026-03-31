-- +goose Up

-- Fix: usp_sys_backup_tenantinfo generaba nombre de BD inexistente.
-- Ahora verifica que la BD exista en pg_database; si no, usa current_database().
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_backup_tenantinfo(p_company_id bigint)
RETURNS TABLE("CompanyCode" character varying, "DbName" character varying)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyCode"::VARCHAR,
    COALESCE(
      td."DbName",
      (SELECT d.datname::VARCHAR FROM pg_database d WHERE d.datname = 'zentto_tenant_' || LOWER(c."CompanyCode")),
      current_database()::VARCHAR
    ) AS "DbName"
  FROM cfg."Company" c
  LEFT JOIN sys."TenantDatabase" td ON td."CompanyId" = c."CompanyId"
  WHERE c."CompanyId" = p_company_id
    AND c."IsActive" = TRUE
  LIMIT 1;
END;
$fn$;
-- +goose StatementEnd

-- +goose Down
SELECT 1;
