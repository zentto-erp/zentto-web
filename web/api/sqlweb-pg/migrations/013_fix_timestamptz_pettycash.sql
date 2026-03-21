\echo '  [013] Fix TIMESTAMPTZ→TIMESTAMP en funciones pettycash...'

-- Las tablas fin."PettyCashBox", fin."PettyCashExpense" y fin."PettyCashSession"
-- tienen columnas TIMESTAMPTZ en producción, pero las funciones declaran TIMESTAMP
-- en RETURNS TABLE. Se agrega ::TIMESTAMP en cada SELECT afectado.

-- 1. usp_fin_pettycash_box_list
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_box_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_box_list(
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
    "CreatedAt"       TIMESTAMP,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."Id", b."CompanyId", b."BranchId", b."Name",
        b."AccountCode", b."MaxAmount", b."CurrentBalance",
        b."Responsible", b."Status",
        b."CreatedAt"::TIMESTAMP,
        b."CreatedByUserId"
    FROM fin."PettyCashBox" b
    WHERE b."CompanyId" = p_company_id
    ORDER BY b."Name";
END;
$$;

-- 2. usp_fin_pettycash_expense_list
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_expense_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_list(
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
    "CreatedAt"       TIMESTAMP,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Id", e."SessionId", e."BoxId", e."Category", e."Description",
        e."Amount", e."Beneficiary", e."ReceiptNumber", e."AccountCode",
        e."CreatedAt"::TIMESTAMP,
        e."CreatedByUserId"
    FROM fin."PettyCashExpense" e
    WHERE e."BoxId" = p_box_id
      AND (p_session_id IS NULL OR e."SessionId" = p_session_id)
    ORDER BY e."CreatedAt" DESC;
END;
$$;

-- 3. usp_fin_pettycash_summary_box
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_summary_box(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_summary_box(
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
    "CreatedAt"       TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."Id", b."CompanyId", b."BranchId", b."Name",
        b."AccountCode", b."MaxAmount", b."CurrentBalance",
        b."Responsible", b."Status",
        b."CreatedAt"::TIMESTAMP
    FROM fin."PettyCashBox" b
    WHERE b."Id" = p_box_id;
END;
$$;

-- 4. usp_fin_pettycash_session_getactive
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_getactive(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_getactive(
    p_box_id INT
)
RETURNS TABLE(
    "Id"               INT,
    "BoxId"            INT,
    "OpeningAmount"    NUMERIC(18,2),
    "ClosingAmount"    NUMERIC(18,2),
    "TotalExpenses"    NUMERIC(18,2),
    "Status"           VARCHAR(20),
    "OpenedAt"         TIMESTAMP,
    "ClosedAt"         TIMESTAMP,
    "OpenedByUserId"   INT,
    "ClosedByUserId"   INT,
    "Notes"            VARCHAR(500),
    "AvailableBalance" NUMERIC(18,2),
    "ExpenseCount"     BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."Id", s."BoxId", s."OpeningAmount", s."ClosingAmount",
        s."TotalExpenses", s."Status",
        s."OpenedAt"::TIMESTAMP,
        s."ClosedAt"::TIMESTAMP,
        s."OpenedByUserId", s."ClosedByUserId", s."Notes",
        (s."OpeningAmount" - s."TotalExpenses"),
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id
      AND s."Status" = 'OPEN';
END;
$$;

-- 5. usp_fin_pettycash_summary_session
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_summary_session(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_summary_session(
    p_box_id INT
)
RETURNS TABLE(
    "SessionId"        INT,
    "OpeningAmount"    NUMERIC(18,2),
    "TotalExpenses"    NUMERIC(18,2),
    "AvailableBalance" NUMERIC(18,2),
    "OpenedAt"         TIMESTAMP,
    "OpenedByUserId"   INT,
    "ExpenseCount"     BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."Id",
        s."OpeningAmount",
        s."TotalExpenses",
        (s."OpeningAmount" - s."TotalExpenses"),
        s."OpenedAt"::TIMESTAMP,
        s."OpenedByUserId",
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id
      AND s."Status" = 'OPEN';
END;
$$;

\echo '  [013] Registrando migración...'
INSERT INTO sys."MigrationLog" ("MigrationId", "Description", "AppliedAt")
VALUES ('013', 'Fix TIMESTAMPTZ→TIMESTAMP casts en 5 funciones public.* pettycash', NOW())
ON CONFLICT ("MigrationId") DO NOTHING;

\echo '  [013] COMPLETO — pettycash TIMESTAMPTZ corregido'
