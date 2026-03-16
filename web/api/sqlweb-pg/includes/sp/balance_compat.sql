-- ============================================================
-- DatqBoxWeb PostgreSQL - balance_compat.sql
-- Funciones para recalcular saldos de clientes y proveedores
-- desde las tablas canonicas ar.ReceivableDocument /
-- ap.PayableDocument.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS master;

-- 1. usp_Master_Customer_UpdateBalance
CREATE OR REPLACE FUNCTION public.usp_master_customer_updatebalance(
    p_customer_id        BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $body$
BEGIN
    IF p_customer_id IS NULL THEN
        RAISE EXCEPTION 'p_customer_id no puede ser NULL.';
    END IF;

    UPDATE master."Customer"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(rd."PendingAmount"), 0)
            FROM ar."ReceivableDocument" rd
            WHERE rd."CustomerId" = p_customer_id
              AND rd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_updated_by_user_id
    WHERE "CustomerId" = p_customer_id;
END;
$body$;

-- 2. usp_Master_Supplier_UpdateBalance
CREATE OR REPLACE FUNCTION public.usp_master_supplier_updatebalance(
    p_supplier_id        BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $body$
BEGIN
    IF p_supplier_id IS NULL THEN
        RAISE EXCEPTION 'p_supplier_id no puede ser NULL.';
    END IF;

    UPDATE master."Supplier"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(pd."PendingAmount"), 0)
            FROM ap."PayableDocument" pd
            WHERE pd."SupplierId" = p_supplier_id
              AND pd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_updated_by_user_id
    WHERE "SupplierId" = p_supplier_id;
END;
$body$;
