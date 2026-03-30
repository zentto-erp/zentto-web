DROP FUNCTION IF EXISTS usp_acct_account_list(INT, VARCHAR(100), VARCHAR(1), VARCHAR(20), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_list(
    p_company_id   INT,
    p_search       VARCHAR(100)  DEFAULT NULL,
    p_tipo         VARCHAR(1)    DEFAULT NULL,
    p_grupo        VARCHAR(20)   DEFAULT NULL,
    p_page         INT           DEFAULT 1,
    p_limit        INT           DEFAULT 50
)
RETURNS TABLE(
    "AccountId"      BIGINT,
    "AccountCode"    VARCHAR(20),
    "AccountName"    VARCHAR(200),
    "AccountType"    VARCHAR(1),
    "AccountLevel"   INT,
    "AllowsPosting"  BOOLEAN,
    "IsActive"       BOOLEAN,
    "TotalCount"     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   acct."Account" a2
    WHERE  a2."CompanyId" = p_company_id
      AND  a2."IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR a2."AccountCode" LIKE '%' || p_search || '%'
            OR a2."AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR a2."AccountType"::VARCHAR(1) = p_tipo)
      AND  (p_grupo IS NULL OR a2."AccountCode" LIKE p_grupo || '%');

    RETURN QUERY
    SELECT a."AccountId",
           a."AccountCode",
           a."AccountName",
           a."AccountType"::VARCHAR(1),
           a."AccountLevel",
           a."AllowsPosting",
           a."IsActive",
           v_total
    FROM   acct."Account" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR a."AccountCode" LIKE '%' || p_search || '%'
            OR a."AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR a."AccountType"::VARCHAR(1) = p_tipo)
      AND  (p_grupo IS NULL OR a."AccountCode" LIKE p_grupo || '%')
    ORDER BY a."AccountCode"
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;
