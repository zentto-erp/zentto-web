-- =============================================
-- Modulo Financiero: Caja Chica (Petty Cash)  (PostgreSQL)
-- Tablas y Funciones
-- =============================================

-- =============================================
-- Asegurar que el schema fin existe
-- =============================================
CREATE SCHEMA IF NOT EXISTS fin;

-- =============================================
-- 1. TABLA: fin."PettyCashBox" - Definiciones de cajas chicas
-- =============================================
CREATE TABLE IF NOT EXISTS fin."PettyCashBox" (
    "Id"              SERIAL PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "BranchId"        INT NOT NULL DEFAULT 1,
    "Name"            VARCHAR(100) NOT NULL,
    "AccountCode"     VARCHAR(20),
    "MaxAmount"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "CurrentBalance"  NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Responsible"     VARCHAR(100),
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT
);

-- =============================================
-- 2. TABLA: fin."PettyCashSession" - Sesiones apertura/cierre
-- =============================================
CREATE TABLE IF NOT EXISTS fin."PettyCashSession" (
    "Id"              SERIAL PRIMARY KEY,
    "BoxId"           INT NOT NULL REFERENCES fin."PettyCashBox"("Id"),
    "OpeningAmount"   NUMERIC(18,2) NOT NULL DEFAULT 0,
    "ClosingAmount"   NUMERIC(18,2),
    "TotalExpenses"   NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    "OpenedAt"        TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "ClosedAt"        TIMESTAMPTZ,
    "OpenedByUserId"  INT,
    "ClosedByUserId"  INT,
    "Notes"           VARCHAR(500)
);

-- =============================================
-- 3. TABLA: fin."PettyCashExpense" - Gastos individuales
-- =============================================
CREATE TABLE IF NOT EXISTS fin."PettyCashExpense" (
    "Id"              SERIAL PRIMARY KEY,
    "SessionId"       INT NOT NULL REFERENCES fin."PettyCashSession"("Id"),
    "BoxId"           INT NOT NULL REFERENCES fin."PettyCashBox"("Id"),
    "Category"        VARCHAR(50) NOT NULL,
    "Description"     VARCHAR(255) NOT NULL,
    "Amount"          NUMERIC(18,2) NOT NULL,
    "Beneficiary"     VARCHAR(150),
    "ReceiptNumber"   VARCHAR(50),
    "AccountCode"     VARCHAR(20),
    "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT
);

-- =============================================
-- 4. usp_Fin_PettyCash_Box_List
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_box_list(
    p_company_id INT
)
RETURNS TABLE(
    "Id"              INT,
    "CompanyId"       INT,
    "BranchId"        INT,
    "Name"            VARCHAR(100),
    "AccountCode"     VARCHAR(20),
    "MaxAmount"       NUMERIC(18,2),
    "CurrentBalance"  NUMERIC(18,2),
    "Responsible"     VARCHAR(100),
    "Status"          VARCHAR(20),
    "CreatedAt"       TIMESTAMPTZ,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."Id", b."CompanyId", b."BranchId", b."Name",
        b."AccountCode", b."MaxAmount", b."CurrentBalance",
        b."Responsible", b."Status", b."CreatedAt", b."CreatedByUserId"
    FROM fin."PettyCashBox" b
    WHERE b."CompanyId" = p_company_id
    ORDER BY b."Name";
END;
$$;

-- =============================================
-- 5. usp_Fin_PettyCash_Box_Create
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_box_create(
    p_company_id       INT,
    p_branch_id        INT,
    p_name             VARCHAR(100),
    p_account_code     VARCHAR(20) DEFAULT NULL,
    p_max_amount       NUMERIC(18,2) DEFAULT 0,
    p_responsible      VARCHAR(100) DEFAULT NULL,
    p_created_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM fin."PettyCashBox"
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "Name" = p_name
          AND "Status" = 'ACTIVE'
    ) THEN
        RETURN QUERY SELECT -1, 'Ya existe una caja chica activa con ese nombre en esta sucursal.'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO fin."PettyCashBox" (
            "CompanyId", "BranchId", "Name", "AccountCode", "MaxAmount",
            "CurrentBalance", "Responsible", "Status", "CreatedAt", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_name, p_account_code, p_max_amount,
            0, p_responsible, 'ACTIVE', NOW() AT TIME ZONE 'UTC', p_created_by_user_id
        )
        RETURNING "Id" INTO v_new_id;

        RETURN QUERY SELECT v_new_id, 'Caja chica creada exitosamente.'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- =============================================
-- 6. usp_Fin_PettyCash_Session_Open
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_session_open(
    p_box_id          INT,
    p_opening_amount  NUMERIC(18,2),
    p_opened_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
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
    IF EXISTS (SELECT 1 FROM fin."PettyCashSession" WHERE "BoxId" = p_box_id AND "Status" = 'OPEN') THEN
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
            "Status", "OpenedAt", "OpenedByUserId"
        )
        VALUES (
            p_box_id, p_opening_amount, NULL, 0,
            'OPEN', NOW() AT TIME ZONE 'UTC', p_opened_by_user_id
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

-- =============================================
-- 7. usp_Fin_PettyCash_Session_Close
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_session_close(
    p_box_id           INT,
    p_closed_by_user_id INT DEFAULT NULL,
    p_notes            VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
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
    WHERE "BoxId" = p_box_id AND "Status" = 'OPEN';

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
        WHERE "Id" = v_session_id;

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

-- =============================================
-- 8. usp_Fin_PettyCash_Session_GetActive
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_session_getactive(
    p_box_id INT
)
RETURNS TABLE(
    "Id"               INT,
    "BoxId"            INT,
    "OpeningAmount"    NUMERIC(18,2),
    "ClosingAmount"    NUMERIC(18,2),
    "TotalExpenses"    NUMERIC(18,2),
    "Status"           VARCHAR(20),
    "OpenedAt"         TIMESTAMPTZ,
    "ClosedAt"         TIMESTAMPTZ,
    "OpenedByUserId"   INT,
    "ClosedByUserId"   INT,
    "Notes"            VARCHAR(500),
    "AvailableBalance" NUMERIC(18,2),
    "ExpenseCount"     BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."Id", s."BoxId", s."OpeningAmount", s."ClosingAmount",
        s."TotalExpenses", s."Status", s."OpenedAt", s."ClosedAt",
        s."OpenedByUserId", s."ClosedByUserId", s."Notes",
        (s."OpeningAmount" - s."TotalExpenses"),
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id
      AND s."Status" = 'OPEN';
END;
$$;

-- =============================================
-- 9. usp_Fin_PettyCash_Expense_Add
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_expense_add(
    p_session_id       INT,
    p_box_id           INT,
    p_category         VARCHAR(50),
    p_description      VARCHAR(255),
    p_amount           NUMERIC(18,2),
    p_beneficiary      VARCHAR(150) DEFAULT NULL,
    p_receipt_number   VARCHAR(50) DEFAULT NULL,
    p_account_code     VARCHAR(20) DEFAULT NULL,
    p_created_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
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
    WHERE "Id" = p_session_id;

    IF (v_total_expenses + p_amount) > v_opening_amount THEN
        RETURN QUERY SELECT -3, ('El monto del gasto excede el saldo disponible en la sesion. Disponible: ' || (v_opening_amount - v_total_expenses)::TEXT)::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        -- Insertar el gasto
        INSERT INTO fin."PettyCashExpense" (
            "SessionId", "BoxId", "Category", "Description", "Amount",
            "Beneficiary", "ReceiptNumber", "AccountCode", "CreatedAt", "CreatedByUserId"
        )
        VALUES (
            p_session_id, p_box_id, p_category, p_description, p_amount,
            p_beneficiary, p_receipt_number, p_account_code,
            NOW() AT TIME ZONE 'UTC', p_created_by_user_id
        )
        RETURNING "Id" INTO v_new_id;

        -- Actualizar total de gastos en la sesion
        UPDATE fin."PettyCashSession"
        SET "TotalExpenses" = "TotalExpenses" + p_amount
        WHERE "Id" = p_session_id;

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

-- =============================================
-- 10. usp_Fin_PettyCash_Expense_List
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_expense_list(
    p_box_id     INT,
    p_session_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Id"              INT,
    "SessionId"       INT,
    "BoxId"           INT,
    "Category"        VARCHAR(50),
    "Description"     VARCHAR(255),
    "Amount"          NUMERIC(18,2),
    "Beneficiary"     VARCHAR(150),
    "ReceiptNumber"   VARCHAR(50),
    "AccountCode"     VARCHAR(20),
    "CreatedAt"       TIMESTAMPTZ,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Id", e."SessionId", e."BoxId", e."Category", e."Description",
        e."Amount", e."Beneficiary", e."ReceiptNumber", e."AccountCode",
        e."CreatedAt", e."CreatedByUserId"
    FROM fin."PettyCashExpense" e
    WHERE e."BoxId" = p_box_id
      AND (p_session_id IS NULL OR e."SessionId" = p_session_id)
    ORDER BY e."CreatedAt" DESC;
END;
$$;

-- =============================================
-- 11. usp_Fin_PettyCash_Summary
-- =============================================
CREATE OR REPLACE FUNCTION usp_fin_pettycash_summary_box(
    p_box_id INT
)
RETURNS TABLE(
    "Id"              INT,
    "CompanyId"       INT,
    "BranchId"        INT,
    "Name"            VARCHAR(100),
    "AccountCode"     VARCHAR(20),
    "MaxAmount"       NUMERIC(18,2),
    "CurrentBalance"  NUMERIC(18,2),
    "Responsible"     VARCHAR(100),
    "Status"          VARCHAR(20),
    "CreatedAt"       TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."Id", b."CompanyId", b."BranchId", b."Name",
        b."AccountCode", b."MaxAmount", b."CurrentBalance",
        b."Responsible", b."Status", b."CreatedAt"
    FROM fin."PettyCashBox" b
    WHERE b."Id" = p_box_id;
END;
$$;

CREATE OR REPLACE FUNCTION usp_fin_pettycash_summary_session(
    p_box_id INT
)
RETURNS TABLE(
    "SessionId"        INT,
    "OpeningAmount"    NUMERIC(18,2),
    "TotalExpenses"    NUMERIC(18,2),
    "AvailableBalance" NUMERIC(18,2),
    "OpenedAt"         TIMESTAMPTZ,
    "OpenedByUserId"   INT,
    "ExpenseCount"     BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."Id",
        s."OpeningAmount",
        s."TotalExpenses",
        (s."OpeningAmount" - s."TotalExpenses"),
        s."OpenedAt",
        s."OpenedByUserId",
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id
      AND s."Status" = 'OPEN';
END;
$$;

CREATE OR REPLACE FUNCTION usp_fin_pettycash_summary_categories(
    p_box_id INT
)
RETURNS TABLE(
    "Category"     VARCHAR(50),
    "ExpenseCount" BIGINT,
    "TotalAmount"  NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Category",
        COUNT(1),
        SUM(e."Amount")
    FROM fin."PettyCashExpense" e
    INNER JOIN fin."PettyCashSession" s ON s."Id" = e."SessionId"
    WHERE e."BoxId" = p_box_id
      AND s."Status" = 'OPEN'
    GROUP BY e."Category"
    ORDER BY SUM(e."Amount") DESC;
END;
$$;

-- Verificacion
DO $$ BEGIN RAISE NOTICE 'Modulo de Caja Chica (Petty Cash) creado exitosamente'; END $$;
