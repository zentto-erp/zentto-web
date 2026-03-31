-- +goose Up
-- Migración 00060: Agregar filtro CompanyId a SPs de FIN (banking/pettycash)
-- Las tablas fin."BankMovement", fin."BankStatementLine", fin."PettyCashExpense",
-- fin."PettyCashSession", fin."BankReconciliationMatch" ahora tienen columna "CompanyId"
-- (agregada en migración 00058). Esta migración actualiza los SPs para filtrar por CompanyId.

-- ============================================================
-- 1. usp_bank_movement_create
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_movement_create(
    p_company_id INTEGER,
    p_bank_account_id bigint,
    p_movement_type character varying,
    p_movement_sign smallint,
    p_amount numeric,
    p_net_amount numeric,
    p_reference_no character varying DEFAULT NULL::character varying,
    p_beneficiary character varying DEFAULT NULL::character varying,
    p_concept character varying DEFAULT NULL::character varying,
    p_category_code character varying DEFAULT NULL::character varying,
    p_related_document_no character varying DEFAULT NULL::character varying,
    p_related_document_type character varying DEFAULT NULL::character varying,
    p_created_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "movementId" bigint, "newBalance" numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_balance NUMERIC(18,2); v_current_available NUMERIC(18,2);
    v_new_balance NUMERIC(18,2); v_new_available NUMERIC(18,2); v_movement_id BIGINT;
BEGIN
    SELECT "Balance","AvailableBalance" INTO v_current_balance,v_current_available
    FROM fin."BankAccount" WHERE "BankAccountId"=p_bank_account_id AND "CompanyId"=p_company_id FOR UPDATE;

    IF v_current_balance IS NULL THEN
        RETURN QUERY SELECT 0, 'Cuenta bancaria no encontrada'::VARCHAR(500), 0::BIGINT, 0::NUMERIC;
        RETURN;
    END IF;

    v_new_balance := ROUND(v_current_balance+p_net_amount,2);
    v_new_available := ROUND(COALESCE(v_current_available,v_current_balance)+p_net_amount,2);

    UPDATE fin."BankAccount" SET "Balance"=v_new_balance,"AvailableBalance"=v_new_available,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "BankAccountId"=p_bank_account_id AND "CompanyId"=p_company_id;

    INSERT INTO fin."BankMovement" ("BankAccountId","MovementDate","MovementType","MovementSign",
        "Amount","NetAmount","ReferenceNo","Beneficiary","Concept","CategoryCode",
        "RelatedDocumentNo","RelatedDocumentType","BalanceAfter","CreatedByUserId","CompanyId")
    VALUES (p_bank_account_id,NOW() AT TIME ZONE 'UTC',p_movement_type,p_movement_sign,
        p_amount,p_net_amount,p_reference_no,p_beneficiary,p_concept,p_category_code,
        p_related_document_no,p_related_document_type,v_new_balance,p_created_by_user_id,p_company_id)
    RETURNING "BankMovementId" INTO v_movement_id;

    RETURN QUERY SELECT v_movement_id, v_new_balance::TEXT::VARCHAR(500), v_movement_id, v_new_balance;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 2. usp_bank_movement_linkjournalentry
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_movement_linkjournalentry(
    p_company_id INTEGER,
    p_movement_id bigint,
    p_journal_entry_id bigint
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE fin."BankMovement"
    SET "JournalEntryId" = p_journal_entry_id
    WHERE "BankMovementId" = p_movement_id
      AND "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Movimiento no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 3. usp_bank_reconciliation_close
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_close(
    p_company_id INTEGER,
    p_id integer,
    p_bank_closing numeric,
    p_notes character varying DEFAULT NULL::character varying,
    p_closed_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying, diferencia numeric, estado character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_bank_account_id BIGINT; v_system_closing NUMERIC(18,2);
    v_difference NUMERIC(18,2); v_status VARCHAR(30);
BEGIN
    SELECT br."BankAccountId" INTO v_bank_account_id FROM fin."BankReconciliation" br
    WHERE br."BankReconciliationId"=p_id AND br."CompanyId"=p_company_id LIMIT 1;

    IF v_bank_account_id IS NULL THEN
        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500),0::NUMERIC,''::VARCHAR; RETURN;
    END IF;

    SELECT ba."Balance" INTO v_system_closing FROM fin."BankAccount" ba
    WHERE ba."BankAccountId"=v_bank_account_id AND ba."CompanyId"=p_company_id LIMIT 1;

    v_difference := ROUND(p_bank_closing-v_system_closing,2);
    v_status := CASE WHEN ABS(v_difference)<=0.01 THEN 'CLOSED' ELSE 'CLOSED_WITH_DIFF' END;

    UPDATE fin."BankReconciliation" SET "ClosingSystemBalance"=v_system_closing,
        "ClosingBankBalance"=p_bank_closing,"DifferenceAmount"=v_difference,"Status"=v_status,
        "Notes"=COALESCE(p_notes,"Notes"),"ClosedAt"=NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"=p_closed_by_user_id,"UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "BankReconciliationId"=p_id AND "CompanyId"=p_company_id;

    RETURN QUERY SELECT 1,'OK'::VARCHAR(500),v_difference,v_status;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 4. usp_bank_reconciliation_getaccountnobyid
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getaccountnobyid(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE("accountNo" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT ba."AccountNumber" FROM fin."BankReconciliation" r
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"
    WHERE r."BankReconciliationId"=p_id AND r."CompanyId"=p_company_id LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 5. usp_bank_reconciliation_getlinkedentries
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getlinkedentries(
    p_company_id INTEGER,
    p_reconciliation_id bigint
) RETURNS TABLE("JournalEntryId" bigint, "EntryNumber" character varying, "EntryDate" date, "Concept" character varying, "TotalDebit" numeric, "TotalCredit" numeric, "Status" character varying, "SourceModule" character varying, "SourceDocumentNo" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        je."JournalEntryId",
        je."EntryNumber",
        je."EntryDate",
        je."Concept",
        je."TotalDebit",
        je."TotalCredit",
        je."Status",
        je."SourceModule",
        je."SourceDocumentNo"
    FROM fin."BankMovement" m
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = m."JournalEntryId"
    WHERE m."ReconciliationId" = p_reconciliation_id
      AND m."CompanyId" = p_company_id
      AND m."JournalEntryId" IS NOT NULL
      AND je."IsDeleted" = FALSE

    UNION

    SELECT
        je2."JournalEntryId",
        je2."EntryNumber",
        je2."EntryDate",
        je2."Concept",
        je2."TotalDebit",
        je2."TotalCredit",
        je2."Status",
        je2."SourceModule",
        je2."SourceDocumentNo"
    FROM acct."DocumentLink" dl
    INNER JOIN acct."JournalEntry" je2 ON je2."JournalEntryId" = dl."JournalEntryId"
    WHERE dl."ModuleCode"       = 'BANCOS'
      AND dl."DocumentType"     = 'CONCILIACION'
      AND dl."NativeDocumentId" = p_reconciliation_id
      AND je2."IsDeleted" = FALSE

    ORDER BY "EntryDate" DESC, "JournalEntryId" DESC;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 6. usp_bank_reconciliation_getnettotal
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getnettotal(
    p_company_id INTEGER,
    p_bank_account_id bigint,
    p_from_date date,
    p_to_date date
) RETURNS TABLE("netTotal" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT COALESCE(SUM("NetAmount"),0) FROM fin."BankMovement"
    WHERE "BankAccountId"=p_bank_account_id
      AND "CompanyId"=p_company_id
      AND ("MovementDate")::DATE BETWEEN p_from_date AND p_to_date;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 7. usp_bank_reconciliation_getpendingstatements
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getpendingstatements(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE(id bigint, "Fecha" timestamp without time zone, "Descripcion" character varying, "Referencia" character varying, "Tipo" character varying, "Monto" numeric, "Saldo" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT sl."StatementLineId",sl."StatementDate",sl."DescriptionText",sl."ReferenceNo",
        sl."EntryType",sl."Amount",sl."Balance"
    FROM fin."BankStatementLine" sl
    WHERE sl."ReconciliationId"=p_id
      AND sl."CompanyId"=p_company_id
      AND sl."IsMatched"=FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 8. usp_bank_reconciliation_getsystemmovements
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getsystemmovements(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE(id bigint, "Fecha" timestamp without time zone, "Tipo" character varying, "Nro_Ref" character varying, "Beneficiario" character varying, "Concepto" character varying, "Monto" numeric, "MontoNeto" numeric, "SaldoPosterior" numeric, "Conciliado" boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT m."BankMovementId",m."MovementDate",m."MovementType",m."ReferenceNo",
        m."Beneficiary",m."Concept",m."Amount",m."NetAmount",m."BalanceAfter",m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId"=m."BankAccountId"
    WHERE r."BankReconciliationId"=p_id
      AND m."CompanyId"=p_company_id
      AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 9. usp_bank_reconciliation_matchmovement
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_matchmovement(
    p_company_id INTEGER,
    p_reconciliation_id bigint,
    p_movement_id bigint,
    p_statement_id bigint DEFAULT NULL::bigint,
    p_matched_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_account_id BIGINT; v_expected_type VARCHAR(12); v_move_amount NUMERIC(18,2);
BEGIN
    SELECT br."BankAccountId" INTO v_account_id FROM fin."BankReconciliation" br
    WHERE br."BankReconciliationId"=p_reconciliation_id AND br."CompanyId"=p_company_id LIMIT 1;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500); RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM fin."BankMovement"
        WHERE "BankMovementId"=p_movement_id AND "BankAccountId"=v_account_id AND "CompanyId"=p_company_id) THEN
        RETURN QUERY SELECT 0,'Movimiento no encontrado'::VARCHAR(500); RETURN;
    END IF;

    IF p_statement_id IS NULL OR p_statement_id=0 THEN
        SELECT CASE WHEN "MovementSign"<0 THEN 'DEBITO' ELSE 'CREDITO' END, "Amount"
        INTO v_expected_type, v_move_amount FROM fin."BankMovement"
        WHERE "BankMovementId"=p_movement_id AND "CompanyId"=p_company_id LIMIT 1;

        SELECT sl."StatementLineId" INTO p_statement_id FROM fin."BankStatementLine" sl
        WHERE sl."ReconciliationId"=p_reconciliation_id AND sl."IsMatched"=FALSE
          AND sl."CompanyId"=p_company_id
          AND sl."EntryType"=v_expected_type AND ABS(sl."Amount"-v_move_amount)<=0.01
        ORDER BY sl."StatementDate", sl."StatementLineId" LIMIT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM fin."BankReconciliationMatch"
        WHERE "ReconciliationId"=p_reconciliation_id AND "BankMovementId"=p_movement_id
          AND "CompanyId"=p_company_id) THEN
        INSERT INTO fin."BankReconciliationMatch" ("ReconciliationId","BankMovementId","StatementLineId","MatchedByUserId","CompanyId")
        VALUES (p_reconciliation_id, p_movement_id,
                CASE WHEN p_statement_id>0 THEN p_statement_id ELSE NULL END, p_matched_by_user_id, p_company_id);
    END IF;

    UPDATE fin."BankMovement" SET "IsReconciled"=TRUE,"ReconciledAt"=NOW() AT TIME ZONE 'UTC',
        "ReconciliationId"=p_reconciliation_id
    WHERE "BankMovementId"=p_movement_id AND "CompanyId"=p_company_id;

    IF p_statement_id IS NOT NULL AND p_statement_id>0 THEN
        UPDATE fin."BankStatementLine" SET "IsMatched"=TRUE,"MatchedAt"=NOW() AT TIME ZONE 'UTC'
        WHERE "StatementLineId"=p_statement_id AND "CompanyId"=p_company_id;
    END IF;

    RETURN QUERY SELECT 1,'Movimiento conciliado'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 10. usp_bank_statementline_insert
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_bank_statementline_insert(
    p_company_id INTEGER,
    p_reconciliation_id bigint,
    p_statement_date timestamp without time zone,
    p_description_text character varying DEFAULT NULL::character varying,
    p_reference_no character varying DEFAULT NULL::character varying,
    p_entry_type character varying DEFAULT NULL::character varying,
    p_amount numeric DEFAULT NULL::numeric,
    p_balance numeric DEFAULT NULL::numeric,
    p_created_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO fin."BankStatementLine" ("ReconciliationId","StatementDate","DescriptionText","ReferenceNo",
        "EntryType","Amount","Balance","CreatedByUserId","CompanyId")
    VALUES (p_reconciliation_id,p_statement_date,p_description_text,p_reference_no,
        p_entry_type,p_amount,p_balance,p_created_by_user_id,p_company_id)
    RETURNING "StatementLineId" INTO v_id;
    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 11. usp_fin_pettycash_expense_add
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_add(
    p_company_id INTEGER,
    p_session_id integer,
    p_box_id integer,
    p_category character varying,
    p_description character varying,
    p_amount numeric,
    p_beneficiary character varying DEFAULT NULL::character varying,
    p_receipt_number character varying DEFAULT NULL::character varying,
    p_account_code character varying DEFAULT NULL::character varying,
    p_created_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_opening_amount NUMERIC(18,2);
    v_total_expenses NUMERIC(18,2);
    v_new_id         INT;
BEGIN
    -- Validar que la sesion existe y esta abierta
    IF NOT EXISTS (
        SELECT 1 FROM fin."PettyCashSession"
        WHERE "Id" = p_session_id AND "BoxId" = p_box_id AND "Status" = 'OPEN'
          AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'La sesion no existe, no pertenece a esta caja o ya esta cerrada.'::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar monto positivo
    IF p_amount <= 0 THEN
        RETURN QUERY SELECT -2, 'El monto del gasto debe ser mayor a cero.'::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que haya saldo suficiente
    SELECT "OpeningAmount", "TotalExpenses"
    INTO v_opening_amount, v_total_expenses
    FROM fin."PettyCashSession"
    WHERE "Id" = p_session_id AND "CompanyId" = p_company_id;

    IF (v_total_expenses + p_amount) > v_opening_amount THEN
        RETURN QUERY SELECT -3, ('El monto del gasto excede el saldo disponible en la sesion. Disponible: ' || (v_opening_amount - v_total_expenses)::TEXT)::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        -- Insertar el gasto
        INSERT INTO fin."PettyCashExpense" (
            "SessionId", "BoxId", "Category", "Description", "Amount",
            "Beneficiary", "ReceiptNumber", "AccountCode", "CreatedAt", "CreatedByUserId", "CompanyId"
        )
        VALUES (
            p_session_id, p_box_id, p_category, p_description, p_amount,
            p_beneficiary, p_receipt_number, p_account_code,
            NOW() AT TIME ZONE 'UTC', p_created_by_user_id, p_company_id
        )
        RETURNING "Id" INTO v_new_id;

        -- Actualizar total de gastos en la sesion
        UPDATE fin."PettyCashSession"
        SET "TotalExpenses" = "TotalExpenses" + p_amount
        WHERE "Id" = p_session_id AND "CompanyId" = p_company_id;

        -- Actualizar saldo actual en la caja (restar gasto)
        UPDATE fin."PettyCashBox"
        SET "CurrentBalance" = "CurrentBalance" - p_amount
        WHERE "Id" = p_box_id;

        RETURN QUERY SELECT v_new_id, 'Gasto registrado exitosamente.'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 12. usp_fin_pettycash_expense_list
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_list(
    p_company_id INTEGER,
    p_box_id integer,
    p_session_id integer DEFAULT NULL::integer
) RETURNS TABLE("Id" integer, "SessionId" integer, "BoxId" integer, "Category" character varying, "Description" character varying, "Amount" numeric, "Beneficiary" character varying, "ReceiptNumber" character varying, "AccountCode" character varying, "CreatedAt" timestamp without time zone, "CreatedByUserId" integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Id", e."SessionId", e."BoxId", e."Category", e."Description",
        e."Amount", e."Beneficiary", e."ReceiptNumber", e."AccountCode",
        e."CreatedAt"::TIMESTAMP, e."CreatedByUserId"
    FROM fin."PettyCashExpense" e
    WHERE e."BoxId" = p_box_id
      AND e."CompanyId" = p_company_id
      AND (p_session_id IS NULL OR e."SessionId" = p_session_id)
    ORDER BY e."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 13. usp_fin_pettycash_session_close
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_close(
    p_company_id INTEGER,
    p_box_id integer,
    p_closed_by_user_id integer DEFAULT NULL::integer,
    p_notes character varying DEFAULT NULL::character varying
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_id     INT;
    v_opening_amount NUMERIC(18,2);
    v_total_expenses NUMERIC(18,2);
    v_closing_amount NUMERIC(18,2);
BEGIN
    -- Buscar la sesion abierta para esta caja
    SELECT "Id", "OpeningAmount", "TotalExpenses"
    INTO v_session_id, v_opening_amount, v_total_expenses
    FROM fin."PettyCashSession"
    WHERE "BoxId" = p_box_id AND "Status" = 'OPEN' AND "CompanyId" = p_company_id;

    IF v_session_id IS NULL THEN
        RETURN QUERY SELECT -1, 'No existe una sesion abierta para esta caja chica.'::VARCHAR(500);
        RETURN;
    END IF;

    -- Calcular monto de cierre
    v_closing_amount := v_opening_amount - v_total_expenses;

    BEGIN
        -- Cerrar la sesion
        UPDATE fin."PettyCashSession"
        SET "Status" = 'CLOSED',
            "ClosingAmount" = v_closing_amount,
            "ClosedAt" = NOW() AT TIME ZONE 'UTC',
            "ClosedByUserId" = p_closed_by_user_id,
            "Notes" = p_notes
        WHERE "Id" = v_session_id AND "CompanyId" = p_company_id;

        -- Actualizar saldo en la caja
        UPDATE fin."PettyCashBox"
        SET "CurrentBalance" = v_closing_amount
        WHERE "Id" = p_box_id;

        RETURN QUERY SELECT v_session_id, ('Sesion cerrada exitosamente. Monto de cierre: ' || v_closing_amount::TEXT)::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 14. usp_fin_pettycash_session_getactive
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_getactive(
    p_company_id INTEGER,
    p_box_id integer
) RETURNS TABLE("Id" integer, "BoxId" integer, "OpeningAmount" numeric, "ClosingAmount" numeric, "TotalExpenses" numeric, "Status" character varying, "OpenedAt" timestamp without time zone, "ClosedAt" timestamp without time zone, "OpenedByUserId" integer, "ClosedByUserId" integer, "Notes" character varying, "AvailableBalance" numeric, "ExpenseCount" bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."Id", s."BoxId", s."OpeningAmount", s."ClosingAmount",
        s."TotalExpenses", s."Status",
        s."OpenedAt"::TIMESTAMP,
        s."ClosedAt"::TIMESTAMP,
        s."OpenedByUserId", s."ClosedByUserId", s."Notes",
        (s."OpeningAmount" - s."TotalExpenses")::NUMERIC(18,2),
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id" AND e."CompanyId" = p_company_id)
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id
      AND s."CompanyId" = p_company_id
      AND s."Status" = 'OPEN';
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 15. usp_fin_pettycash_session_open
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_open(
    p_company_id INTEGER,
    p_box_id integer,
    p_opening_amount numeric,
    p_opened_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_max_amount NUMERIC(18,2);
    v_new_id     INT;
BEGIN
    -- Validar que la caja existe y esta activa
    IF NOT EXISTS (SELECT 1 FROM fin."PettyCashBox" WHERE "Id" = p_box_id AND "Status" = 'ACTIVE') THEN
        RETURN QUERY SELECT -1, 'La caja chica no existe o no esta activa.'::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que no haya otra sesion abierta para esta caja
    IF EXISTS (SELECT 1 FROM fin."PettyCashSession" WHERE "BoxId" = p_box_id AND "Status" = 'OPEN' AND "CompanyId" = p_company_id) THEN
        RETURN QUERY SELECT -2, 'Ya existe una sesion abierta para esta caja chica. Debe cerrarla primero.'::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que el monto de apertura no exceda el maximo permitido
    SELECT "MaxAmount" INTO v_max_amount FROM fin."PettyCashBox" WHERE "Id" = p_box_id;

    IF v_max_amount > 0 AND p_opening_amount > v_max_amount THEN
        RETURN QUERY SELECT -3, ('El monto de apertura excede el monto maximo permitido para esta caja chica (' || v_max_amount::TEXT || ').')::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        -- Crear la sesion
        INSERT INTO fin."PettyCashSession" (
            "BoxId", "OpeningAmount", "ClosingAmount", "TotalExpenses",
            "Status", "OpenedAt", "OpenedByUserId", "CompanyId"
        )
        VALUES (
            p_box_id, p_opening_amount, NULL, 0,
            'OPEN', NOW() AT TIME ZONE 'UTC', p_opened_by_user_id, p_company_id
        )
        RETURNING "Id" INTO v_new_id;

        -- Actualizar el saldo actual de la caja
        UPDATE fin."PettyCashBox"
        SET "CurrentBalance" = p_opening_amount
        WHERE "Id" = p_box_id;

        RETURN QUERY SELECT v_new_id, 'Sesion de caja chica abierta exitosamente.'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- Rollback: restaurar funciones originales sin p_company_id
-- No se ejecuta automaticamente — requiere recrear las funciones originales manualmente si es necesario.
