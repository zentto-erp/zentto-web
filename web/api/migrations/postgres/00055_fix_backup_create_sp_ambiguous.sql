-- +goose Up

-- Fix: "column reference BackupId is ambiguous" en usp_sys_backup_create
-- El RETURNS TABLE("BackupId") colisionaba con la columna de TenantBackup.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_backup_create(
  p_company_id bigint,
  p_db_name character varying,
  p_created_by character varying DEFAULT 'backoffice'
)
RETURNS TABLE("BackupId" bigint)
LANGUAGE plpgsql AS $fn$
DECLARE
  v_backup_id BIGINT;
BEGIN
  INSERT INTO sys."TenantBackup" (
    "CompanyId", "DbName", "Status", "StartedAt", "CreatedBy"
  ) VALUES (
    p_company_id, p_db_name, 'RUNNING', NOW() AT TIME ZONE 'UTC', COALESCE(p_created_by, 'backoffice')
  )
  RETURNING sys."TenantBackup"."BackupId" INTO v_backup_id;

  RETURN QUERY SELECT v_backup_id AS "BackupId";
END;
$fn$;
-- +goose StatementEnd

-- +goose Down
-- No-op: el SP anterior también funciona (solo falla en ambigüedad)
SELECT 1;
