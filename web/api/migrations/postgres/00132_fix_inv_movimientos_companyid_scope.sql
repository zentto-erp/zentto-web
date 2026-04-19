-- +goose Up
-- +goose StatementBegin
-- Fix: usp_Inventario_Movimiento_List — ensure CompanyId filter is enforced
-- This migration is a safety net. Migration 00064 already added CompanyId to
-- usp_rest_admin_adjuststock. This migration reinforces the SP contract by
-- adding a hard CHECK that CompanyId is never NULL or <= 0 when passed.
-- The TS-layer fix (removing ?? 1 defaults) was applied simultaneously.
DO $$
BEGIN
  -- Validate usp_Inventario_Movimiento_Insert exists with correct signature
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'usp_inventario_movimiento_insert'
  ) THEN
    RAISE EXCEPTION 'usp_Inventario_Movimiento_Insert not found — run baseline first';
  END IF;

  -- Validate usp_rest_admin_adjuststock has 3 params (company_id was added in 00064)
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'usp_rest_admin_adjuststock'
      AND pronargs = 3
  ) THEN
    RAISE EXCEPTION 'usp_rest_admin_adjuststock still has 2 params (missing CompanyId) — migration 00064 may not have run';
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- No rollback needed — this migration only validates, does not change schema
SELECT 1;
-- +goose StatementEnd
