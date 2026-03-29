-- +goose Up

-- +goose StatementBegin
-- Fix: TIMESTAMPTZÃ¢â€ â€™TIMESTAMP casts in pettycash functions + ambiguous column in committee meetings

-- 1. usp_fin_pettycash_session_getactive Ã¢â‚¬â€ add ::TIMESTAMP casts
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_getactive(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_getactive(
    p_box_id INT
)
RETURNS TABLE(
    "Id" INT, "BoxId" INT, "OpeningAmount" NUMERIC(18,2), "ClosingAmount" NUMERIC(18,2),
    "TotalExpenses" NUMERIC(18,2), "Status" VARCHAR(20), "OpenedAt" TIMESTAMP,
    "ClosedAt" TIMESTAMP, "OpenedByUserId" INT, "ClosedByUserId" INT,
    "Notes" VARCHAR(500), "AvailableBalance" NUMERIC(18,2), "ExpenseCount" BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."Id", s."BoxId", s."OpeningAmount", s."ClosingAmount",
        s."TotalExpenses", s."Status", s."OpenedAt"::TIMESTAMP, s."ClosedAt"::TIMESTAMP,
        s."OpenedByUserId", s."ClosedByUserId", s."Notes",
        (s."OpeningAmount" - s."TotalExpenses")::NUMERIC(18,2),
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashSession" s
    WHERE s."BoxId" = p_box_id AND s."Status" = 'OPEN';
END;
$$;

-- 2. usp_fin_pettycash_expense_list Ã¢â‚¬â€ add ::TIMESTAMP cast
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_expense_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_list(
    p_box_id INT, p_session_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "SessionId" INT, "BoxId" INT, "Category" VARCHAR(50),
    "Description" VARCHAR(255), "Amount" NUMERIC(18,2), "Beneficiary" VARCHAR(150),
    "ReceiptNumber" VARCHAR(50), "AccountCode" VARCHAR(20),
    "CreatedAt" TIMESTAMP, "CreatedByUserId" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."Id", e."SessionId", e."BoxId", e."Category", e."Description",
        e."Amount", e."Beneficiary", e."ReceiptNumber", e."AccountCode",
        e."CreatedAt"::TIMESTAMP, e."CreatedByUserId"
    FROM fin."PettyCashExpense" e
    WHERE e."BoxId" = p_box_id AND (p_session_id IS NULL OR e."SessionId" = p_session_id)
    ORDER BY e."CreatedAt" DESC;
END;
$$;

-- 3. fin.usp_fin_pettycash_summary Ã¢â‚¬â€ add ::TIMESTAMP + ::VARCHAR casts
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_summary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION fin.usp_fin_pettycash_summary(p_box_id INTEGER)
RETURNS TABLE(
    "BoxId" INTEGER, "BoxName" VARCHAR, "MaxAmount" NUMERIC, "CurrentBalance" NUMERIC,
    "Status" VARCHAR, "SessionId" INTEGER, "OpeningAmount" NUMERIC, "TotalExpenses" NUMERIC,
    "AvailableBalance" NUMERIC, "OpenedAt" TIMESTAMP, "ExpenseCount" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT b."Id", b."Name"::VARCHAR, b."MaxAmount", b."CurrentBalance", b."Status"::VARCHAR,
        s."Id", s."OpeningAmount", s."TotalExpenses",
        COALESCE(s."OpeningAmount" - s."TotalExpenses", 0::NUMERIC),
        s."OpenedAt"::TIMESTAMP,
        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")
    FROM fin."PettyCashBox" b
    LEFT JOIN fin."PettyCashSession" s ON s."BoxId" = b."Id" AND s."Status" = 'OPEN'
    WHERE b."Id" = p_box_id;
END;
$$;

-- Recreate fin wrappers dropped by CASCADE
CREATE OR REPLACE FUNCTION fin.usp_fin_pettycash_session_getactive(p_box_id INTEGER)
RETURNS TABLE("Id" INTEGER,"BoxId" INTEGER,"OpeningAmount" NUMERIC,"ClosingAmount" NUMERIC,
    "TotalExpenses" NUMERIC,"Status" VARCHAR,"OpenedAt" TIMESTAMP,"ClosedAt" TIMESTAMP,
    "OpenedByUserId" INTEGER,"ClosedByUserId" INTEGER,"Notes" VARCHAR,
    "AvailableBalance" NUMERIC,"ExpenseCount" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN RETURN QUERY SELECT * FROM public.usp_fin_pettycash_session_getactive(p_box_id); END;
$$;

CREATE OR REPLACE FUNCTION fin.usp_fin_pettycash_expense_list(
    p_box_id INTEGER, p_session_id INTEGER DEFAULT NULL)
RETURNS TABLE("Id" INTEGER,"SessionId" INTEGER,"BoxId" INTEGER,"Category" VARCHAR,
    "Description" VARCHAR,"Amount" NUMERIC,"Beneficiary" VARCHAR,"ReceiptNumber" VARCHAR,
    "AccountCode" VARCHAR,"CreatedAt" TIMESTAMP,"CreatedByUserId" INTEGER)
LANGUAGE plpgsql AS $$
BEGIN RETURN QUERY SELECT * FROM public.usp_fin_pettycash_expense_list(p_box_id, p_session_id); END;
$$;

-- 4. usp_HR_Committee_GetMeetings Ã¢â‚¬â€ fix ambiguous SafetyCommitteeId
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER, INTEGER, DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_GetMeetings(
    p_committee_id INTEGER, p_company_id INTEGER DEFAULT NULL,
    p_from_date DATE DEFAULT NULL, p_to_date DATE DEFAULT NULL,
    p_page INTEGER DEFAULT 1, p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    p_total_count BIGINT, "MeetingId" INTEGER, "SafetyCommitteeId" INTEGER,
    "MeetingDate" TIMESTAMP, "MinutesUrl" VARCHAR(500), "TopicsSummary" TEXT,
    "ActionItems" TEXT, "CreatedAt" TIMESTAMP, "CommitteeName" VARCHAR(200)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_page < 1 THEN p_page := 1; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    IF p_company_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee" c2
        WHERE c2."SafetyCommitteeId" = p_committee_id AND c2."CompanyId" = p_company_id
    ) THEN RETURN; END IF;

    RETURN QUERY
    SELECT COUNT(*) OVER()::BIGINT, m."MeetingId", m."SafetyCommitteeId",
        m."MeetingDate", m."MinutesUrl"::VARCHAR(500), m."TopicsSummary",
        m."ActionItems", m."CreatedAt"::TIMESTAMP, sc."CommitteeName"::VARCHAR(200)
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_summary(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_session_getactive(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS fin.usp_fin_pettycash_expense_list(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_getactive(INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_expense_list(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER, INTEGER, DATE, DATE, INTEGER, INTEGER) CASCADE;
