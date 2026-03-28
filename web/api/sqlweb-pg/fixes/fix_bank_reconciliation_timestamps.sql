-- ============================================================
-- fix_bank_reconciliation_timestamps.sql
-- Corrige RETURNS TABLE de usp_bank_reconciliation_getpendingstatements
-- y usp_bank_reconciliation_getsystemmovements
-- De TIMESTAMP WITH TIME ZONE a TIMESTAMP WITHOUT TIME ZONE
-- porque fin.BankStatementLine.StatementDate y fin.BankMovement.MovementDate
-- son TIMESTAMP WITHOUT TIME ZONE
-- ============================================================

-- Para cambiar el tipo en RETURNS TABLE con CREATE OR REPLACE, primero
-- hay que DROP la firma exacta, luego recrear.

-- 1. usp_bank_reconciliation_getpendingstatements
-- Firma exacta: (p_id integer)
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(integer) CASCADE;

DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(p_id integer)
  RETURNS TABLE(
    id            bigint,
    "Fecha"       timestamp without time zone,
    "Descripcion" character varying,
    "Referencia"  character varying,
    "Tipo"        character varying,
    "Monto"       numeric,
    "Saldo"       numeric
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sl."StatementLineId", sl."StatementDate", sl."DescriptionText"::VARCHAR, sl."ReferenceNo"::VARCHAR,
           sl."EntryType"::VARCHAR, sl."Amount", sl."Balance"
    FROM fin."BankStatementLine" sl
    WHERE sl."ReconciliationId" = p_id AND sl."IsMatched" = FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END;
$function$;

-- 2. usp_bank_reconciliation_getsystemmovements
-- Firma exacta: (p_id integer)
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(integer) CASCADE;

DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(p_id integer)
  RETURNS TABLE(
    id               bigint,
    "Fecha"          timestamp without time zone,
    "Tipo"           character varying,
    "Nro_Ref"        character varying,
    "Beneficiario"   character varying,
    "Concepto"       character varying,
    "Monto"          numeric,
    "MontoNeto"      numeric,
    "SaldoPosterior" numeric,
    "Conciliado"     boolean
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."BankMovementId", m."MovementDate", m."MovementType"::VARCHAR, m."ReferenceNo"::VARCHAR,
           m."Beneficiary"::VARCHAR, m."Concept"::VARCHAR, m."Amount", m."NetAmount", m."BalanceAfter", m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId" = m."BankAccountId"
    WHERE r."BankReconciliationId" = p_id
      AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END;
$function$;
