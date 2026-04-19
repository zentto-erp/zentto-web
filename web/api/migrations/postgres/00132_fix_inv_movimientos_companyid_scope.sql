-- +goose Up
-- +goose StatementBegin
-- Validate usp_Inventario_Movimiento_Insert exists (baseline guard).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'usp_inventario_movimiento_insert'
  ) THEN
    RAISE EXCEPTION 'usp_Inventario_Movimiento_Insert not found — run baseline first';
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Ensure usp_rest_admin_adjuststock has 3 params (company_id).
-- Migration 00064 added company_id but the 2-param baseline could overwrite it.
-- Using CREATE OR REPLACE so this migration is always idempotent.
CREATE OR REPLACE FUNCTION public.usp_rest_admin_adjuststock(
    p_company_id integer,
    p_product_id bigint,
    p_delta_qty  numeric
) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN
        RETURN;
    END IF;
    UPDATE master."Product"
    SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ProductId" = p_product_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_adjuststock(p_product_id bigint, p_delta_qty numeric) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN RETURN; END IF;
    UPDATE master."Product"
    SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ProductId" = p_product_id;
END;
$$;
-- +goose StatementEnd
