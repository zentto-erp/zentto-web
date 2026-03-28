-- +goose Up
-- +goose StatementBegin
-- Fix: INT → BIGINT en parámetros y columnas RETURNS TABLE de entidades
-- Afecta: usp_crm, usp_fleet, usp_inv, usp_logistics, usp_mfg, usp_bank

-- ── usp_bank_statementline_insert: TIMESTAMPTZ → TIMESTAMP ──────────────────
DROP FUNCTION IF EXISTS public.usp_bank_statementline_insert(bigint, timestamp with time zone, character varying, character varying, character varying, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_bank_statementline_insert(bigint, timestamp, character varying, character varying, character varying, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_bank_statementline_insert(p_reconciliation_id bigint, p_statement_date timestamp, p_description_text character varying DEFAULT NULL::character varying, p_reference_no character varying DEFAULT NULL::character varying, p_entry_type character varying DEFAULT NULL::character varying, p_amount numeric DEFAULT NULL::numeric, p_balance numeric DEFAULT NULL::numeric, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE v_id INT;
BEGIN
    INSERT INTO fin."BankStatementLine" ("ReconciliationId","StatementDate","DescriptionText","ReferenceNo",
        "EntryType","Amount","Balance","CreatedByUserId")
    VALUES (p_reconciliation_id,p_statement_date,p_description_text,p_reference_no,
        p_entry_type,p_amount,p_balance,p_created_by_user_id)
    RETURNING "StatementLineId" INTO v_id;
    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);
END; $function$;

-- ── usp_crm_lead_close: p_customer_id INT → BIGINT ──────────────────────────
DROP FUNCTION IF EXISTS usp_crm_lead_close(INT, BOOLEAN, VARCHAR, INT, INT) CASCADE;

-- ── usp_crm_activity_list: p_customer_id INT → BIGINT ───────────────────────
DROP FUNCTION IF EXISTS usp_crm_activity_list(INT, INT, INT, BOOLEAN, TIMESTAMP, INT, INT) CASCADE;

-- ── usp_crm_activity_create: p_customer_id INT → BIGINT ─────────────────────
DROP FUNCTION IF EXISTS usp_crm_activity_create(INT, INT, INT, VARCHAR, VARCHAR, TEXT, TIMESTAMP, INT, VARCHAR, INT) CASCADE;

-- ── usp_fleet_maintenanceorder_create: p_supplier_id INT → BIGINT ────────────
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_create CASCADE;

-- ── usp_inv: multiple product_id / movement_id / customer_id INT → BIGINT ────
DROP FUNCTION IF EXISTS usp_Inv_BinStock_List(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Lot_List(INT, INT, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Lot_Get(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Lot_Create(INT, INT, VARCHAR, DATE, DATE, VARCHAR, VARCHAR, DECIMAL, DECIMAL, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Serial_List(INT, INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Serial_Register(INT, INT, VARCHAR, INT, INT, INT, VARCHAR, DECIMAL, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Serial_Get(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Serial_UpdateStatus CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Movement_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Movement_Create(INT, INT, INT, INT, INT, INT, INT, INT, INT, VARCHAR, DECIMAL, DECIMAL, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Valuation_GetMethod(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Inv_Valuation_SetMethod(INT, INT, VARCHAR, DECIMAL, INT) CASCADE;

-- ── usp_logistics: p_supplier_id / p_customer_id INT → BIGINT ────────────────
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_Create CASCADE;
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReturn_Create CASCADE;
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_Create CASCADE;

-- ── usp_mfg: p_product_id INT → BIGINT ───────────────────────────────────────
DROP FUNCTION IF EXISTS usp_mfg_bom_create CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_workorder_create CASCADE;
DROP FUNCTION IF EXISTS usp_mfg_workorder_consumematerial CASCADE;

-- ── usp_inv_integracion ───────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS usp_inv_serial_reserveforsale CASCADE;
DROP FUNCTION IF EXISTS usp_inv_lot_validateforsale CASCADE;

-- ── usp_inv_movement_list: renombrar versión ops (VARCHAR search) → usp_movinvent_list ─────
-- Evita conflicto con usp_inv.sql que tiene usp_inv_movement_list(p_company_id, p_product_id, ...)
DROP FUNCTION IF EXISTS usp_inv_movement_list(VARCHAR, VARCHAR, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_movinvent_list(VARCHAR, VARCHAR, INT, INT) CASCADE;
-- +goose StatementEnd

-- Re-create from updated SP files (ejecutado por goose-deploy-all.sh via run-functions.sql)
-- Las funciones se recargan automáticamente con run-functions.sql en el deploy

-- +goose Down
-- No hay rollback automatico — los tipos anteriores son incompatibles con datos existentes
