-- =============================================================================
-- usp_master_balance.sql
-- Procedimientos para recalcular saldos de clientes y proveedores
-- desde las tablas canonicas ar.ReceivableDocument / ap.PayableDocument.
--
-- Tablas afectadas:
--   [master].Customer  (TotalBalance)
--   [master].Supplier  (TotalBalance)
--
-- Fecha creacion: 2026-03-14
-- =============================================================================
USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_Master_Customer_UpdateBalance
--    Recalcula el saldo total de un cliente sumando los montos pendientes
--    de todos sus documentos por cobrar que no esten anulados.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Master_Customer_UpdateBalance') IS NOT NULL DROP PROCEDURE dbo.usp_Master_Customer_UpdateBalance;
GO
CREATE PROCEDURE dbo.usp_Master_Customer_UpdateBalance
    @CustomerId       BIGINT,
    @UpdatedByUserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CustomerId IS NULL
    BEGIN
        RAISERROR(N'@CustomerId no puede ser NULL.', 16, 1);
        RETURN;
    END

    UPDATE [master].Customer
    SET TotalBalance = (
            SELECT ISNULL(SUM(rd.PendingAmount), 0)
            FROM ar.ReceivableDocument rd
            WHERE rd.CustomerId = @CustomerId
              AND rd.Status <> N'VOIDED'
        ),
        UpdatedAt        = SYSUTCDATETIME(),
        UpdatedByUserId  = @UpdatedByUserId
    WHERE CustomerId = @CustomerId;
END;
GO

-- =============================================================================
-- 2. usp_Master_Supplier_UpdateBalance
--    Recalcula el saldo total de un proveedor sumando los montos pendientes
--    de todos sus documentos por pagar que no esten anulados.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Master_Supplier_UpdateBalance') IS NOT NULL DROP PROCEDURE dbo.usp_Master_Supplier_UpdateBalance;
GO
CREATE PROCEDURE dbo.usp_Master_Supplier_UpdateBalance
    @SupplierId       BIGINT,
    @UpdatedByUserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @SupplierId IS NULL
    BEGIN
        RAISERROR(N'@SupplierId no puede ser NULL.', 16, 1);
        RETURN;
    END

    UPDATE [master].Supplier
    SET TotalBalance = (
            SELECT ISNULL(SUM(pd.PendingAmount), 0)
            FROM ap.PayableDocument pd
            WHERE pd.SupplierId = @SupplierId
              AND pd.Status <> N'VOIDED'
        ),
        UpdatedAt        = SYSUTCDATETIME(),
        UpdatedByUserId  = @UpdatedByUserId
    WHERE SupplierId = @SupplierId;
END;
GO

PRINT '[usp_master_balance] Procedimientos de recalculo de balance creados correctamente.';
GO
