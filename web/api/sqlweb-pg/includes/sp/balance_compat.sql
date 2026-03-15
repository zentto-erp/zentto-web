-- =============================================================================
-- usp_master_balance.sql - PostgreSQL
-- Funciones para recalcular saldos de clientes y proveedores
-- desde las tablas canonicas ar."ReceivableDocument" / ap."PayableDocument".
-- Traducido de SQL Server a PostgreSQL
-- =============================================================================

-- =============================================================================
-- 1. usp_Master_Customer_UpdateBalance
--    Recalcula el saldo total de un cliente sumando los montos pendientes
--    de todos sus documentos por cobrar que no esten anulados.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Master_Customer_UpdateBalance(BIGINT, INT);

CREATE OR REPLACE FUNCTION usp_Master_Customer_UpdateBalance(
    p_customer_id       BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
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
DROP FUNCTION IF EXISTS usp_Master_Supplier_UpdateBalance(BIGINT, INT);

CREATE OR REPLACE FUNCTION usp_Master_Supplier_UpdateBalance(
    p_supplier_id       BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
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
           "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId"  = p_updated_by_user_id
     WHERE "SupplierId" = p_supplier_id;
END;
$$;
