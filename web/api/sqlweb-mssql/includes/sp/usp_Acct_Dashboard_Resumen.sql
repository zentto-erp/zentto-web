-- ============================================================
-- usp_Acct_Dashboard_Resumen
-- Dashboard resumen de contabilidad: ingresos, gastos, margen,
-- cuentas por pagar, totales de asientos y cuentas activas.
-- Compatible SQL Server 2012+ (compat level 110)
-- ============================================================
IF OBJECT_ID('dbo.usp_Acct_Dashboard_Resumen', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Acct_Dashboard_Resumen;
GO

CREATE PROCEDURE dbo.usp_Acct_Dashboard_Resumen
    @CompanyId   INT,
    @BranchId    INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @totalIngresos    DECIMAL(18,2) = 0;
    DECLARE @totalGastos      DECIMAL(18,2) = 0;
    DECLARE @cuentasPorPagar  DECIMAL(18,2) = 0;
    DECLARE @totalAsientos    INT = 0;
    DECLARE @totalCuentas     INT = 0;
    DECLARE @totalAnulados    INT = 0;

    -- Total Ingresos (account type I)
    SELECT @totalIngresos = ISNULL(SUM(jel.CreditAmount - jel.DebitAmount), 0)
      FROM acct.JournalEntry je
      INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
      INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
     WHERE je.CompanyId = @CompanyId
       AND je.BranchId  = @BranchId
       AND je.EntryDate >= @FechaDesde
       AND je.EntryDate <= @FechaHasta
       AND je.IsDeleted = 0
       AND je.[Status] <> 'VOIDED'
       AND a.AccountType = 'I';

    -- Total Gastos (account type G)
    SELECT @totalGastos = ISNULL(SUM(jel.DebitAmount - jel.CreditAmount), 0)
      FROM acct.JournalEntry je
      INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
      INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
     WHERE je.CompanyId = @CompanyId
       AND je.BranchId  = @BranchId
       AND je.EntryDate >= @FechaDesde
       AND je.EntryDate <= @FechaHasta
       AND je.IsDeleted = 0
       AND je.[Status] <> 'VOIDED'
       AND a.AccountType = 'G';

    -- Cuentas por pagar (account type P, code starts with '2.1')
    SELECT @cuentasPorPagar = ISNULL(SUM(jel.CreditAmount - jel.DebitAmount), 0)
      FROM acct.JournalEntry je
      INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
      INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
     WHERE je.CompanyId = @CompanyId
       AND je.BranchId  = @BranchId
       AND je.EntryDate >= @FechaDesde
       AND je.EntryDate <= @FechaHasta
       AND je.IsDeleted = 0
       AND je.[Status] <> 'VOIDED'
       AND a.AccountType = 'P'
       AND a.AccountCode LIKE '2.1%';

    -- Total asientos activos
    SELECT @totalAsientos = COUNT(*)
      FROM acct.JournalEntry
     WHERE CompanyId = @CompanyId
       AND BranchId  = @BranchId
       AND EntryDate >= @FechaDesde
       AND EntryDate <= @FechaHasta
       AND IsDeleted = 0
       AND [Status] <> 'VOIDED';

    -- Total anulados
    SELECT @totalAnulados = COUNT(*)
      FROM acct.JournalEntry
     WHERE CompanyId = @CompanyId
       AND BranchId  = @BranchId
       AND EntryDate >= @FechaDesde
       AND EntryDate <= @FechaHasta
       AND IsDeleted = 0
       AND [Status] = 'VOIDED';

    -- Total cuentas activas
    SELECT @totalCuentas = COUNT(*)
      FROM acct.Account
     WHERE CompanyId = @CompanyId
       AND IsDeleted = 0
       AND IsActive  = 1;

    SELECT
        @totalIngresos   AS totalIngresos,
        @totalGastos     AS totalGastos,
        CASE WHEN @totalIngresos > 0
             THEN ROUND((@totalIngresos - @totalGastos) / @totalIngresos * 100, 2)
             ELSE 0
        END              AS margenPorcentaje,
        @cuentasPorPagar AS cuentasPorPagar,
        @totalAsientos   AS totalAsientos,
        @totalCuentas    AS totalCuentas,
        @totalAnulados   AS totalAnulados;
END;
GO
