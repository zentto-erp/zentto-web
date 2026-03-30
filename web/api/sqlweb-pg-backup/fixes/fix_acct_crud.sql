-- Fix: usp_acct_account_insert - change "Mensaje" return type to TEXT
DROP FUNCTION IF EXISTS usp_acct_account_insert(INT, VARCHAR(20), VARCHAR(200), VARCHAR(1), INT, INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_insert(
    p_company_id        INT,
    p_account_code      VARCHAR(20),
    p_account_name      VARCHAR(200),
    p_account_type      VARCHAR(1)   DEFAULT 'A',
    p_account_level     INT          DEFAULT NULL,
    p_parent_account_id INT          DEFAULT NULL,
    p_allows_posting    BOOLEAN      DEFAULT TRUE
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_level    INT := p_account_level;
    v_parent   BIGINT := p_parent_account_id;
    v_parent_code VARCHAR(20);
BEGIN
    -- Validar que no exista duplicado
    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, ('Ya existe una cuenta con el codigo ' || p_account_code || ' para esta empresa.')::TEXT;
        RETURN;
    END IF;

    -- Auto-resolver nivel desde AccountCode si no se proporciono
    IF v_level IS NULL OR v_level < 1 THEN
        v_level := LENGTH(p_account_code) - LENGTH(REPLACE(p_account_code, '.', '')) + 1;
        IF v_level < 1 THEN v_level := 1; END IF;
    END IF;

    -- Auto-resolver cuenta padre desde AccountCode si no se proporciono
    IF v_parent IS NULL AND POSITION('.' IN p_account_code) > 0 THEN
        v_parent_code := LEFT(p_account_code,
            LENGTH(p_account_code) - POSITION('.' IN REVERSE(p_account_code)));

        SELECT "AccountId" INTO v_parent
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = v_parent_code
          AND "IsDeleted" = FALSE
        LIMIT 1;

        IF v_parent IS NULL THEN
            RETURN QUERY SELECT 0, ('Cuenta padre ' || v_parent_code || ' no encontrada.')::TEXT;
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."Account" (
            "CompanyId", "AccountCode", "AccountName", "AccountType",
            "AccountLevel", "ParentAccountId", "AllowsPosting",
            "RequiresAuxiliary", "IsActive",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        VALUES (
            p_company_id, p_account_code, p_account_name, p_account_type,
            v_level, v_parent, p_allows_posting,
            FALSE, TRUE,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        );

        RETURN QUERY SELECT 1, ('Cuenta ' || p_account_code || ' creada exitosamente.')::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, ('Error al insertar cuenta: ' || SQLERRM)::TEXT;
    END;
END;
$$;

-- Fix: usp_acct_account_update - change "Mensaje" return type to TEXT
DROP FUNCTION IF EXISTS usp_acct_account_update(INT, VARCHAR(20), VARCHAR(200), VARCHAR(1), INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_update(
    p_company_id     INT,
    p_account_code   VARCHAR(20),
    p_account_name   VARCHAR(200) DEFAULT NULL,
    p_account_type   VARCHAR(1)   DEFAULT NULL,
    p_account_level  INT          DEFAULT NULL,
    p_allows_posting BOOLEAN      DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, ('No se encontro la cuenta con codigo ' || p_account_code || '.')::TEXT;
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "AccountName"   = COALESCE(p_account_name,   "AccountName"),
            "AccountType"   = COALESCE(p_account_type,   "AccountType"),
            "AccountLevel"  = COALESCE(p_account_level,  "AccountLevel"),
            "AllowsPosting" = COALESCE(p_allows_posting, "AllowsPosting"),
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"   = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted"   = FALSE;

        RETURN QUERY SELECT 1, ('Cuenta ' || p_account_code || ' actualizada exitosamente.')::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, ('Error al actualizar cuenta: ' || SQLERRM)::TEXT;
    END;
END;
$$;

-- Fix: usp_acct_account_delete - change "Mensaje" return type to TEXT
DROP FUNCTION IF EXISTS usp_acct_account_delete(INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_delete(
    p_company_id   INT,
    p_account_code VARCHAR(20)
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_account_id BIGINT;
BEGIN
    SELECT "AccountId" INTO v_account_id
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id
      AND "AccountCode" = p_account_code
      AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT 0, ('No se encontro la cuenta con codigo ' || p_account_code || ' o ya fue eliminada.')::TEXT;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "ParentAccountId" = v_account_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'No se puede eliminar: la cuenta tiene cuentas hijas activas.'::TEXT;
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "AccountId" = v_account_id
          AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, ('Cuenta ' || p_account_code || ' eliminada exitosamente.')::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, ('Error al eliminar cuenta: ' || SQLERRM)::TEXT;
    END;
END;
$$;
