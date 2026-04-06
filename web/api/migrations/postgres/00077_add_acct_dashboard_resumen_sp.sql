-- +goose Up
-- Migration: Create usp_acct_dashboard_resumen function
-- This function was in the baseline but never deployed via goose migration.
-- It powers the GET /v1/contabilidad/dashboard/resumen endpoint.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_dashboard_resumen(
    p_company_id bigint,
    p_branch_id  bigint,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE(
    "totalIngresos"    numeric,
    "totalGastos"      numeric,
    "margenPorcentaje" numeric,
    "cuentasPorPagar"  numeric,
    "totalAsientos"    integer,
    "totalCuentas"     integer,
    "totalAnulados"    integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_ingresos    NUMERIC(18,2) := 0;
    v_total_gastos      NUMERIC(18,2) := 0;
    v_cuentas_por_pagar NUMERIC(18,2) := 0;
    v_total_asientos    INT := 0;
    v_total_cuentas     INT := 0;
    v_total_anulados    INT := 0;
BEGIN
    -- Total Ingresos (account type I)
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0)
      INTO v_total_ingresos
      FROM acct."JournalEntry" je
      INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
      INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
     WHERE je."CompanyId" = p_company_id
       AND je."BranchId"  = p_branch_id
       AND je."EntryDate" >= p_fecha_desde
       AND je."EntryDate" <= p_fecha_hasta
       AND je."IsDeleted" = FALSE
       AND je."Status"   <> 'VOIDED'
       AND a."AccountType" = 'I';

    -- Total Gastos (account type G)
    SELECT COALESCE(SUM(jel."DebitAmount" - jel."CreditAmount"), 0)
      INTO v_total_gastos
      FROM acct."JournalEntry" je
      INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
      INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
     WHERE je."CompanyId" = p_company_id
       AND je."BranchId"  = p_branch_id
       AND je."EntryDate" >= p_fecha_desde
       AND je."EntryDate" <= p_fecha_hasta
       AND je."IsDeleted" = FALSE
       AND je."Status"   <> 'VOIDED'
       AND a."AccountType" = 'G';

    -- Cuentas por pagar (account type P, code starts with '2.1')
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0)
      INTO v_cuentas_por_pagar
      FROM acct."JournalEntry" je
      INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
      INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
     WHERE je."CompanyId" = p_company_id
       AND je."BranchId"  = p_branch_id
       AND je."EntryDate" >= p_fecha_desde
       AND je."EntryDate" <= p_fecha_hasta
       AND je."IsDeleted" = FALSE
       AND je."Status"   <> 'VOIDED'
       AND a."AccountType" = 'P'
       AND a."AccountCode" LIKE '2.1%';

    -- Total asientos activos
    SELECT COUNT(*)::INT INTO v_total_asientos
      FROM acct."JournalEntry"
     WHERE "CompanyId" = p_company_id
       AND "BranchId"  = p_branch_id
       AND "EntryDate" >= p_fecha_desde
       AND "EntryDate" <= p_fecha_hasta
       AND "IsDeleted" = FALSE
       AND "Status"   <> 'VOIDED';

    -- Total anulados
    SELECT COUNT(*)::INT INTO v_total_anulados
      FROM acct."JournalEntry"
     WHERE "CompanyId" = p_company_id
       AND "BranchId"  = p_branch_id
       AND "EntryDate" >= p_fecha_desde
       AND "EntryDate" <= p_fecha_hasta
       AND "IsDeleted" = FALSE
       AND "Status"    = 'VOIDED';

    -- Total cuentas activas
    SELECT COUNT(*)::INT INTO v_total_cuentas
      FROM acct."Account"
     WHERE "CompanyId" = p_company_id
       AND "IsDeleted" = FALSE
       AND "IsActive"  = TRUE;

    RETURN QUERY
    SELECT
        v_total_ingresos,
        v_total_gastos,
        CASE WHEN v_total_ingresos > 0
             THEN ROUND((v_total_ingresos - v_total_gastos) / v_total_ingresos * 100, 2)
             ELSE 0::numeric
        END,
        v_cuentas_por_pagar,
        v_total_asientos,
        v_total_cuentas,
        v_total_anulados;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_acct_dashboard_resumen(bigint, bigint, date, date);
