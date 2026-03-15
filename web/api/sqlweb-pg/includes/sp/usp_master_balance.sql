-- =============================================================================
-- usp_master_balance.sql  (PostgreSQL)
-- Funciones para recalcular saldos de clientes y proveedores
-- desde las tablas canonicas ar."ReceivableDocument" / ap."PayableDocument".
--
-- Tablas afectadas:
--   master."Customer"  ("TotalBalance")
--   master."Supplier"  ("TotalBalance")
--
-- Fecha creacion: 2026-03-14
-- =============================================================================

-- =============================================================================
-- 1. usp_Master_Customer_UpdateBalance
--    Recalcula el saldo total de un cliente sumando los montos pendientes
--    de todos sus documentos por cobrar que no esten anulados.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_master_customer_updatebalance(
    p_customer_id       BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_customer_id IS NULL THEN
        RAISE EXCEPTION '@CustomerId no puede ser NULL.';
    END IF;

    UPDATE master."Customer"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(rd."PendingAmount"), 0)
            FROM ar."ReceivableDocument" rd
            WHERE rd."CustomerId" = p_customer_id
              AND rd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId"  = p_updated_by_user_id
    WHERE "CustomerId" = p_customer_id;
END;
$$;

-- =============================================================================
-- 2. usp_Master_Supplier_UpdateBalance
--    Recalcula el saldo total de un proveedor sumando los montos pendientes
--    de todos sus documentos por pagar que no esten anulados.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_master_supplier_updatebalance(
    p_supplier_id       BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_supplier_id IS NULL THEN
        RAISE EXCEPTION '@SupplierId no puede ser NULL.';
    END IF;

    UPDATE master."Supplier"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(pd."PendingAmount"), 0)
            FROM ap."PayableDocument" pd
            WHERE pd."SupplierId" = p_supplier_id
              AND pd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId"  = p_updated_by_user_id
    WHERE "SupplierId" = p_supplier_id;
END;
$$;

-- Verificacion
DO $$ BEGIN RAISE NOTICE '[usp_master_balance] Funciones de recalculo de balance creadas correctamente.'; END $$;
