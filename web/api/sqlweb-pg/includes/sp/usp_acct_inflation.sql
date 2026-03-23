-- =============================================================================
--  Archivo : usp_acct_inflation.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_acct_inflation.sql
--
--  Esquema : acct (contabilidad legal - ajuste por inflacion)
--  Descripcion:
--    Stored procedures para el modulo de ajuste por inflacion.
--    Implementa el metodo NGP (Nivel General de Precios) segun:
--      - BA VEN-NIF 2 (criterios inflacion en estados financieros)
--      - NIC 29 (informacion financiera en economias hiperinflacionarias)
--      - DPC-10 (declaracion de principios contables N 10)
--      - LISLR Art. 173-193 (ajuste fiscal por inflacion)
--
--  Funciones (11):
--    usp_Acct_InflationIndex_List, usp_Acct_InflationIndex_Upsert,
--    usp_Acct_InflationIndex_BulkLoad,
--    usp_Acct_AccountMonetaryClass_List, usp_Acct_AccountMonetaryClass_Upsert,
--    usp_Acct_AccountMonetaryClass_AutoClassify,
--    usp_Acct_Inflation_Calculate, usp_Acct_Inflation_Post,
--    usp_Acct_Inflation_Void,
--    usp_Acct_Report_BalanceReexpresado, usp_Acct_Report_REME
-- =============================================================================

-- =============================================================================
--  SP 1: usp_Acct_InflationIndex_List
--  Descripcion : Lista indices de precios por pais y rango de periodos.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_InflationIndex_List(INTEGER, CHAR(2), VARCHAR(30), SMALLINT, SMALLINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_InflationIndex_List(
    p_company_id   INTEGER,
    p_country_code CHAR(2)      DEFAULT 'VE',
    p_index_name   VARCHAR(30)  DEFAULT 'INPC',
    p_year_from    SMALLINT     DEFAULT NULL,
    p_year_to      SMALLINT     DEFAULT NULL
)
RETURNS TABLE(
    p_total_count      BIGINT,
    "InflationIndexId" INTEGER,
    "CountryCode"      CHAR(2),
    "IndexName"        VARCHAR(30),
    "PeriodCode"       CHAR(6),
    "IndexValue"       NUMERIC(18,6),
    "SourceReference"  VARCHAR(200),
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()          AS p_total_count,
           "InflationIndexId",
           "CountryCode",
           "IndexName",
           "PeriodCode",
           "IndexValue",
           "SourceReference",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = p_country_code
      AND "IndexName"   = p_index_name
      AND (p_year_from IS NULL OR CAST(LEFT("PeriodCode", 4) AS SMALLINT) >= p_year_from)
      AND (p_year_to   IS NULL OR CAST(LEFT("PeriodCode", 4) AS SMALLINT) <= p_year_to)
    ORDER BY "PeriodCode";
END;
$$;

-- =============================================================================
--  SP 2: usp_Acct_InflationIndex_Upsert
--  Descripcion : Inserta o actualiza un indice mensual.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_InflationIndex_Upsert(INTEGER, CHAR(2), VARCHAR(30), CHAR(6), NUMERIC(18,6), VARCHAR(200), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_InflationIndex_Upsert(
    p_company_id       INTEGER,
    p_country_code     CHAR(2),
    p_index_name       VARCHAR(30),
    p_period_code      CHAR(6),
    p_index_value      NUMERIC(18,6),
    p_source_reference VARCHAR(200) DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_index_value <= 0 THEN
        p_mensaje := 'El valor del indice debe ser mayor a cero.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."InflationIndex"
        WHERE "CompanyId"   = p_company_id
          AND "CountryCode" = p_country_code
          AND "IndexName"   = p_index_name
          AND "PeriodCode"  = p_period_code
    ) THEN
        UPDATE acct."InflationIndex"
        SET "IndexValue"      = p_index_value,
            "SourceReference" = COALESCE(p_source_reference, "SourceReference"),
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"   = p_company_id
          AND "CountryCode" = p_country_code
          AND "IndexName"   = p_index_name
          AND "PeriodCode"  = p_period_code;

        p_resultado := 1;
        p_mensaje   := 'Indice actualizado correctamente.';
    ELSE
        INSERT INTO acct."InflationIndex" (
            "CompanyId", "CountryCode", "IndexName", "PeriodCode", "IndexValue", "SourceReference"
        )
        VALUES (p_company_id, p_country_code, p_index_name, p_period_code, p_index_value, p_source_reference);

        p_resultado := 1;
        p_mensaje   := 'Indice creado correctamente.';
    END IF;
END;
$$;

-- =============================================================================
--  SP 3: usp_Acct_InflationIndex_BulkLoad
--  Descripcion : Carga masiva de indices via JSON.
--  JSON format : [{"periodCode":"202601","indexValue":1234.56,"source":"BCV"}]
--  Nota PG: Se usa json_to_recordset en lugar de OPENXML/MERGE de SQL Server.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_InflationIndex_BulkLoad(INTEGER, CHAR(2), VARCHAR(30), TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_InflationIndex_BulkLoad(
    p_company_id   INTEGER,
    p_country_code CHAR(2),
    p_index_name   VARCHAR(30),
    p_json_data    TEXT,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_processed INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        INSERT INTO acct."InflationIndex" (
            "CompanyId", "CountryCode", "IndexName", "PeriodCode", "IndexValue", "SourceReference"
        )
        SELECT p_company_id, p_country_code, p_index_name,
               r."periodCode", r."indexValue", r."source"
        FROM json_to_recordset(p_json_data::json) AS r(
            "periodCode" CHAR(6),
            "indexValue" NUMERIC(18,6),
            "source"     VARCHAR(200)
        )
        ON CONFLICT ("CompanyId", "CountryCode", "IndexName", "PeriodCode")
        DO UPDATE SET
            "IndexValue"      = EXCLUDED."IndexValue",
            "SourceReference" = COALESCE(EXCLUDED."SourceReference", acct."InflationIndex"."SourceReference"),
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC');

        GET DIAGNOSTICS v_processed = ROW_COUNT;

        p_resultado := 1;
        p_mensaje   := 'Carga masiva completada: ' || v_processed::TEXT || ' registros procesados.';
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 4: usp_Acct_AccountMonetaryClass_List
--  Descripcion : Lista la clasificacion monetaria de cuentas contables.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_AccountMonetaryClass_List(INTEGER, VARCHAR(20), VARCHAR(100)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_AccountMonetaryClass_List(
    p_company_id    INTEGER,
    p_classification VARCHAR(20)  DEFAULT NULL,
    p_search        VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE(
    p_total_count                BIGINT,
    "AccountMonetaryClassId"     INTEGER,
    "AccountId"                  BIGINT,
    "AccountCode"                VARCHAR(30),
    "AccountName"                VARCHAR(200),
    "AccountType"                CHAR(1),
    "AccountLevel"               SMALLINT,
    "AllowsPosting"              BOOLEAN,
    "Classification"             VARCHAR(20),
    "SubClassification"          VARCHAR(40),
    "ReexpressionAccountId"      BIGINT,
    "IsActive"                   BOOLEAN,
    "UpdatedAt"                  TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()          AS p_total_count,
           mc."AccountMonetaryClassId",
           a."AccountId",
           a."AccountCode",
           a."AccountName",
           a."AccountType",
           a."AccountLevel",
           a."AllowsPosting",
           mc."Classification",
           mc."SubClassification",
           mc."ReexpressionAccountId",
           mc."IsActive",
           mc."UpdatedAt"
    FROM acct."AccountMonetaryClass" mc
    JOIN acct."Account" a ON a."AccountId" = mc."AccountId" AND a."CompanyId" = mc."CompanyId"
    WHERE mc."CompanyId" = p_company_id
      AND mc."IsActive"  = TRUE
      AND (p_classification IS NULL OR mc."Classification" = p_classification)
      AND (p_search IS NULL
           OR a."AccountCode" LIKE '%' || p_search || '%'
           OR a."AccountName" LIKE '%' || p_search || '%')
    ORDER BY a."AccountCode";
END;
$$;

-- =============================================================================
--  SP 5: usp_Acct_AccountMonetaryClass_Upsert
--  Descripcion : Clasificar una cuenta como monetaria o no monetaria.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_AccountMonetaryClass_Upsert(INTEGER, BIGINT, VARCHAR(20), VARCHAR(40), BIGINT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_AccountMonetaryClass_Upsert(
    p_company_id              INTEGER,
    p_account_id              BIGINT,
    p_classification          VARCHAR(20),
    p_sub_classification      VARCHAR(40) DEFAULT NULL,
    p_reexpression_account_id BIGINT      DEFAULT NULL,
    OUT p_resultado            INTEGER,
    OUT p_mensaje              TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_classification NOT IN ('MONETARY', 'NON_MONETARY') THEN
        p_mensaje := 'Clasificacion invalida. Usar MONETARY o NON_MONETARY.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "AccountId" = p_account_id AND "CompanyId" = p_company_id
    ) THEN
        p_mensaje := 'Cuenta contable no encontrada.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."AccountMonetaryClass"
        WHERE "CompanyId" = p_company_id AND "AccountId" = p_account_id
    ) THEN
        UPDATE acct."AccountMonetaryClass"
        SET "Classification"       = p_classification,
            "SubClassification"    = p_sub_classification,
            "ReexpressionAccountId" = p_reexpression_account_id,
            "UpdatedAt"            = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId" = p_company_id AND "AccountId" = p_account_id;
    ELSE
        INSERT INTO acct."AccountMonetaryClass" (
            "CompanyId", "AccountId", "Classification", "SubClassification", "ReexpressionAccountId"
        )
        VALUES (p_company_id, p_account_id, p_classification, p_sub_classification, p_reexpression_account_id);
    END IF;

    p_resultado := 1;
    p_mensaje   := 'Clasificacion guardada correctamente.';
END;
$$;

-- =============================================================================
--  SP 6: usp_Acct_AccountMonetaryClass_AutoClassify
--  Descripcion : Auto-clasifica cuentas segun tipo contable.
--    Ref DPC-10 parrafos 15-22.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_AccountMonetaryClass_AutoClassify(INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_AccountMonetaryClass_AutoClassify(
    p_company_id INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_processed INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    INSERT INTO acct."AccountMonetaryClass" (
        "CompanyId", "AccountId", "Classification", "SubClassification"
    )
    SELECT a."CompanyId",
           a."AccountId",
           CASE
               WHEN a."AccountType" = 'A' AND (
                   a."AccountCode" LIKE '1.1.01%' OR
                   a."AccountCode" LIKE '1.1.02%' OR
                   a."AccountCode" LIKE '1.1.03%' OR
                   a."AccountCode" LIKE '1.1.04%' OR
                   a."AccountCode" LIKE '1.1.05%' OR
                   a."AccountCode" LIKE '1.1.06%' OR
                   a."AccountName" ILIKE '%caja%' OR
                   a."AccountName" ILIKE '%banco%' OR
                   a."AccountName" ILIKE '%cobrar%'
               ) THEN 'MONETARY'
               WHEN a."AccountType" = 'A' AND (
                   a."AccountCode" LIKE '1.1.07%' OR
                   a."AccountCode" LIKE '1.2%' OR
                   a."AccountName" ILIKE '%inventar%' OR
                   a."AccountName" ILIKE '%equipo%' OR
                   a."AccountName" ILIKE '%terreno%' OR
                   a."AccountName" ILIKE '%edificio%' OR
                   a."AccountName" ILIKE '%vehiculo%' OR
                   a."AccountName" ILIKE '%mobiliario%' OR
                   a."AccountName" ILIKE '%intangible%'
               ) THEN 'NON_MONETARY'
               WHEN a."AccountType" = 'P' THEN 'MONETARY'
               WHEN a."AccountType" = 'C' THEN 'NON_MONETARY'
               WHEN a."AccountType" IN ('I', 'G') THEN 'MONETARY'
               ELSE 'MONETARY'
           END,
           CASE
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.01%' OR a."AccountCode" LIKE '1.1.02%' OR a."AccountName" ILIKE '%caja%' OR a."AccountName" ILIKE '%banco%') THEN 'CASH'
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.04%' OR a."AccountName" ILIKE '%cobrar%') THEN 'RECEIVABLE'
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.07%' OR a."AccountName" ILIKE '%inventar%') THEN 'INVENTORY'
               WHEN a."AccountType" = 'A' AND a."AccountCode" LIKE '1.2%' THEN 'FIXED_ASSET'
               WHEN a."AccountType" = 'P' AND (a."AccountName" ILIKE '%pagar%' OR a."AccountName" ILIKE '%proveedor%') THEN 'PAYABLE'
               WHEN a."AccountType" = 'C' THEN 'EQUITY'
               ELSE NULL
           END
    FROM acct."Account" a
    WHERE a."CompanyId"     = p_company_id
      AND a."AllowsPosting" = TRUE
      AND a."IsActive"      = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND NOT EXISTS (
              SELECT 1 FROM acct."AccountMonetaryClass" mc
              WHERE mc."CompanyId" = p_company_id AND mc."AccountId" = a."AccountId"
          );

    GET DIAGNOSTICS v_processed = ROW_COUNT;

    p_resultado := 1;
    p_mensaje   := 'Auto-clasificacion completada: ' || v_processed::TEXT || ' cuentas clasificadas.';
END;
$$;

-- =============================================================================
--  SP 7: usp_Acct_Inflation_Calculate
--  Descripcion : Calcula ajuste por inflacion para un periodo usando metodo NGP.
--    Ref: BA VEN-NIF 2, NIC 29 parrafos 11-28
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Inflation_Calculate(INTEGER, INTEGER, CHAR(6), SMALLINT, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Inflation_Calculate(
    p_company_id  INTEGER,
    p_branch_id   INTEGER,
    p_period_code CHAR(6),
    p_fiscal_year SMALLINT,
    p_user_id     INTEGER  DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_period    CHAR(6);
    v_base_index     NUMERIC(18,6);
    v_end_index      NUMERIC(18,6);
    v_factor         NUMERIC(18,8);
    v_accum_infl     NUMERIC(18,6);
    v_fecha_corte    DATE;
    v_adj_id         INTEGER;
    v_total_adj      NUMERIC(18,2);
    v_reme           NUMERIC(18,2);
    v_line_count     INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."InflationAdjustment"
        WHERE "CompanyId"  = p_company_id
          AND "BranchId"   = p_branch_id
          AND "PeriodCode" = p_period_code
          AND "Status"     <> 'VOIDED'
    ) THEN
        p_mensaje := 'Ya existe un ajuste para este periodo. Anulelo primero.';
        RETURN;
    END IF;

    v_base_period := CAST(p_fiscal_year AS CHAR(4)) || '01';

    SELECT "IndexValue" INTO v_base_index
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = 'VE'
      AND "IndexName"   = 'INPC'
      AND "PeriodCode"  = v_base_period;

    SELECT "IndexValue" INTO v_end_index
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = 'VE'
      AND "IndexName"   = 'INPC'
      AND "PeriodCode"  = p_period_code;

    IF v_base_index IS NULL THEN
        p_mensaje := 'No se encontro el indice INPC para el periodo base ' || v_base_period;
        RETURN;
    END IF;
    IF v_end_index IS NULL THEN
        p_mensaje := 'No se encontro el indice INPC para el periodo ' || p_period_code;
        RETURN;
    END IF;
    IF v_base_index = 0 THEN
        p_mensaje := 'El indice INPC base no puede ser cero.';
        RETURN;
    END IF;

    v_factor      := v_end_index / v_base_index;
    v_accum_infl  := (v_factor - 1.0) * 100.0;
    v_fecha_corte := (DATE_TRUNC('month',
        MAKE_DATE(p_fiscal_year, CAST(RIGHT(p_period_code, 2) AS INTEGER), 1))
        + INTERVAL '1 month - 1 day')::DATE;

    BEGIN
        -- Insertar cabecera
        INSERT INTO acct."InflationAdjustment" (
            "CompanyId", "BranchId", "CountryCode", "PeriodCode", "FiscalYear",
            "AdjustmentDate", "BaseIndexValue", "EndIndexValue",
            "AccumulatedInflation", "ReexpressionFactor", "Status", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, 'VE', p_period_code, p_fiscal_year,
            v_fecha_corte, v_base_index, v_end_index,
            v_accum_infl, v_factor, 'DRAFT', p_user_id
        )
        RETURNING "InflationAdjustmentId" INTO v_adj_id;

        -- Calcular saldos historicos y ajustar cuentas no monetarias
        INSERT INTO acct."InflationAdjustmentLine" (
            "InflationAdjustmentId", "AccountId", "AccountCode", "AccountName",
            "Classification", "HistoricalBalance", "ReexpressionFactor",
            "AdjustedBalance", "AdjustmentAmount"
        )
        SELECT v_adj_id,
               a."AccountId",
               a."AccountCode",
               a."AccountName",
               mc."Classification",
               COALESCE(SUM(
                   CASE WHEN a."AccountType" IN ('A','G')
                        THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                        ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                   END
               ), 0),
               CASE WHEN mc."Classification" = 'NON_MONETARY' THEN v_factor ELSE 1.0 END,
               CASE WHEN mc."Classification" = 'NON_MONETARY'
                    THEN ROUND(COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0) * v_factor, 2)
                    ELSE COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0)
               END,
               CASE WHEN mc."Classification" = 'NON_MONETARY'
                    THEN ROUND(COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0) * (v_factor - 1.0), 2)
                    ELSE 0
               END
        FROM acct."Account" a
        JOIN acct."AccountMonetaryClass" mc ON mc."AccountId" = a."AccountId" AND mc."CompanyId" = a."CompanyId"
        LEFT JOIN acct."JournalEntryLine" jl ON jl."AccountId" = a."AccountId"
        LEFT JOIN acct."JournalEntry" je ON je."JournalEntryId" = jl."JournalEntryId"
                                       AND je."CompanyId"       = p_company_id
                                       AND je."Status"          = 'APPROVED'
                                       AND je."EntryDate"       <= v_fecha_corte
        WHERE a."CompanyId"     = p_company_id
          AND a."AllowsPosting" = TRUE
          AND a."IsActive"      = TRUE
          AND mc."IsActive"     = TRUE
        GROUP BY a."AccountId", a."AccountCode", a."AccountName", a."AccountType", mc."Classification"
        HAVING COALESCE(SUM(
            CASE WHEN a."AccountType" IN ('A','G')
                 THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                 ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
            END
        ), 0) <> 0;

        SELECT COALESCE(SUM("AdjustmentAmount"), 0)
        INTO v_total_adj
        FROM acct."InflationAdjustmentLine"
        WHERE "InflationAdjustmentId" = v_adj_id
          AND "Classification"        = 'NON_MONETARY';

        SELECT COUNT(*) INTO v_line_count
        FROM acct."InflationAdjustmentLine"
        WHERE "InflationAdjustmentId" = v_adj_id;

        v_reme := -v_total_adj;

        UPDATE acct."InflationAdjustment"
        SET "TotalAdjustmentAmount" = v_total_adj,
            "TotalMonetaryGainLoss" = v_reme,
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = v_adj_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste calculado. Factor: ' || ROUND(v_factor, 8)::TEXT
                     || ', REME: ' || ROUND(v_reme, 2)::TEXT
                     || ', Lineas: ' || v_line_count::TEXT;
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 8: usp_Acct_Inflation_Post
--  Descripcion : Publica el ajuste generando un asiento contable.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Inflation_Post(INTEGER, INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Inflation_Post(
    p_company_id    INTEGER,
    p_adjustment_id INTEGER,
    p_user_id       INTEGER DEFAULT NULL,
    OUT p_resultado  INTEGER,
    OUT p_mensaje    TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_status         VARCHAR(20);
    v_period_code    CHAR(6);
    v_adj_date       DATE;
    v_reme           NUMERIC(18,2);
    v_entry_number   VARCHAR(30);
    v_journal_id     BIGINT;
    v_total_debit    NUMERIC(18,2) := 0;
    v_total_credit   NUMERIC(18,2) := 0;
    v_reme_acct_id   BIGINT;
    v_reme_acc_code  VARCHAR(30);
    v_diff           NUMERIC(18,2);
    v_reme_debit     NUMERIC(18,2) := 0;
    v_reme_credit    NUMERIC(18,2) := 0;
    v_branch_id      INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "PeriodCode", "AdjustmentDate", "TotalMonetaryGainLoss", "BranchId"
    INTO v_status, v_period_code, v_adj_date, v_reme, v_branch_id
    FROM acct."InflationAdjustment"
    WHERE "InflationAdjustmentId" = p_adjustment_id
      AND "CompanyId"             = p_company_id;

    IF v_status IS NULL THEN
        p_mensaje := 'Ajuste no encontrado.';
        RETURN;
    END IF;
    IF v_status <> 'DRAFT' THEN
        p_mensaje := 'Solo se pueden publicar ajustes en estado DRAFT. Estado actual: ' || v_status;
        RETURN;
    END IF;

    BEGIN
        v_entry_number := 'AJI-' || TO_CHAR((NOW() AT TIME ZONE 'UTC'), 'YYYYMMDDHHMMSS');

        -- Insertar cabecera de asiento
        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType",
            "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status", "SourceModule",
            "SourceDocumentType", "SourceDocumentNo"
        )
        SELECT "CompanyId", "BranchId", v_entry_number, v_adj_date,
               LEFT(v_period_code, 4) || '-' || RIGHT(v_period_code, 2),
               'AJUSTE_INFLACION', NULL,
               'Ajuste por inflacion periodo ' || v_period_code || ' - BA VEN-NIF 2 / NIC 29',
               'VES', 1.0, 0, 0, 'APPROVED', 'INFLACION', NULL, p_adjustment_id::TEXT
        FROM acct."InflationAdjustment"
        WHERE "InflationAdjustmentId" = p_adjustment_id
        RETURNING "JournalEntryId" INTO v_journal_id;

        -- Insertar lineas de detalle
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount"
        )
        SELECT v_journal_id,
               ROW_NUMBER() OVER (ORDER BY l."AccountCode"),
               l."AccountId",
               l."AccountCode",
               'Ajuste inflacion - ' || l."AccountName",
               CASE WHEN l."AdjustmentAmount" > 0 THEN l."AdjustmentAmount" ELSE 0 END,
               CASE WHEN l."AdjustmentAmount" < 0 THEN ABS(l."AdjustmentAmount") ELSE 0 END
        FROM acct."InflationAdjustmentLine" l
        WHERE l."InflationAdjustmentId" = p_adjustment_id
          AND l."Classification"        = 'NON_MONETARY'
          AND l."AdjustmentAmount"      <> 0;

        SELECT COALESCE(SUM("DebitAmount"), 0), COALESCE(SUM("CreditAmount"), 0)
        INTO v_total_debit, v_total_credit
        FROM acct."JournalEntryLine"
        WHERE "JournalEntryId" = v_journal_id;

        -- Buscar cuenta REME
        SELECT "AccountId", "AccountCode" INTO v_reme_acct_id, v_reme_acc_code
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND ("AccountName" ILIKE '%resultado monetario%'
               OR "AccountName" ILIKE '%REME%'
               OR "AccountCode" LIKE '5.4%')
          AND "AllowsPosting" = TRUE
        LIMIT 1;

        IF v_reme_acct_id IS NOT NULL THEN
            v_diff := v_total_debit - v_total_credit;
            IF v_diff > 0 THEN v_reme_credit := v_diff; END IF;
            IF v_diff < 0 THEN v_reme_debit  := ABS(v_diff); END IF;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount"
            )
            VALUES (
                v_journal_id,
                (SELECT COALESCE(MAX("LineNumber"), 0) + 1 FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_journal_id),
                v_reme_acct_id, v_reme_acc_code,
                'Resultado Monetario del Ejercicio (REME) - NIC 29',
                v_reme_debit, v_reme_credit
            );

            v_total_debit  := v_total_debit  + v_reme_debit;
            v_total_credit := v_total_credit + v_reme_credit;
        END IF;

        UPDATE acct."JournalEntry"
        SET "TotalDebit"  = v_total_debit,
            "TotalCredit" = v_total_credit
        WHERE "JournalEntryId" = v_journal_id;

        UPDATE acct."InflationAdjustment"
        SET "Status"         = 'POSTED',
            "JournalEntryId" = v_journal_id,
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = p_adjustment_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste publicado. Asiento: ' || v_entry_number
                     || ', Debe: ' || ROUND(v_total_debit, 2)::TEXT
                     || ', Haber: ' || ROUND(v_total_credit, 2)::TEXT;
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 9: usp_Acct_Inflation_Void
--  Descripcion : Anula un ajuste por inflacion y su asiento asociado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Inflation_Void(INTEGER, INTEGER, VARCHAR(200), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Inflation_Void(
    p_company_id    INTEGER,
    p_adjustment_id INTEGER,
    p_motivo        VARCHAR(200) DEFAULT NULL,
    OUT p_resultado  INTEGER,
    OUT p_mensaje    TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_status         VARCHAR(20);
    v_journal_id     BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "JournalEntryId"
    INTO v_status, v_journal_id
    FROM acct."InflationAdjustment"
    WHERE "InflationAdjustmentId" = p_adjustment_id
      AND "CompanyId"             = p_company_id;

    IF v_status IS NULL THEN
        p_mensaje := 'Ajuste no encontrado.';
        RETURN;
    END IF;

    BEGIN
        IF v_journal_id IS NOT NULL THEN
            UPDATE acct."JournalEntry"
            SET "Status"    = 'VOIDED',
                "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
            WHERE "JournalEntryId" = v_journal_id;
        END IF;

        UPDATE acct."InflationAdjustment"
        SET "Status"    = 'VOIDED',
            "Notes"     = COALESCE("Notes" || ' | ',''::VARCHAR) || 'ANULADO: ' || COALESCE(p_motivo, 'Sin motivo'),
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = p_adjustment_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste anulado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 10: usp_Acct_Report_BalanceReexpresado
--  Descripcion : Balance General con columnas historico + reexpresado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_BalanceReexpresado(INTEGER, INTEGER, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_BalanceReexpresado(
    p_company_id INTEGER,
    p_branch_id  INTEGER,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "AccountCode"        VARCHAR(30),
    "AccountName"        VARCHAR(200),
    "AccountType"        CHAR(1),
    "AccountLevel"       SMALLINT,
    "historicalBalance"  NUMERIC(18,2),
    "classification"     VARCHAR(20),
    "adjustedBalance"    NUMERIC(18,2),
    "adjustmentAmount"   NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_code CHAR(6);
    v_factor      NUMERIC(18,8) := 1.0;
BEGIN
    v_period_code := TO_CHAR(p_fecha_corte, 'YYYYMM');

    SELECT "ReexpressionFactor" INTO v_factor
    FROM acct."InflationAdjustment"
    WHERE "CompanyId"  = p_company_id
      AND "BranchId"   = p_branch_id
      AND "PeriodCode" <= v_period_code
      AND "Status"     = 'POSTED'
    ORDER BY "PeriodCode" DESC
    LIMIT 1;

    IF v_factor IS NULL THEN v_factor := 1.0; END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           a."AccountLevel",
           COALESCE(SUM(
               CASE WHEN a."AccountType" IN ('A','G')
                    THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                    ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
               END
           ), 0) AS "historicalBalance",
           COALESCE(mc."Classification", 'MONETARY') AS "classification",
           CASE WHEN COALESCE(mc."Classification", 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0) * v_factor, 2)
                ELSE COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0)
           END AS "adjustedBalance",
           CASE WHEN COALESCE(mc."Classification", 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0) * (v_factor - 1.0), 2)
                ELSE 0
           END AS "adjustmentAmount"
    FROM acct."Account" a
    LEFT JOIN acct."JournalEntryLine" jl ON jl."AccountId" = a."AccountId"
    LEFT JOIN acct."JournalEntry" je ON je."JournalEntryId" = jl."JournalEntryId"
                                   AND je."CompanyId"       = p_company_id
                                   AND je."Status"          = 'APPROVED'
                                   AND je."EntryDate"       <= p_fecha_corte
    LEFT JOIN acct."AccountMonetaryClass" mc ON mc."AccountId" = a."AccountId"
                                            AND mc."CompanyId" = a."CompanyId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsActive"   = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountType" IN ('A','P','C')
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", a."AccountLevel", mc."Classification"
    HAVING COALESCE(SUM(
        CASE WHEN a."AccountType" IN ('A','G')
             THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
             ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
        END
    ), 0) <> 0
    ORDER BY a."AccountCode";
END;
$$;

-- =============================================================================
--  SP 11: usp_Acct_Report_REME
--  Descripcion : Reporte del Resultado Monetario del Periodo.
--  Ref: BA VEN-NIF 2, NIC 29 parrafos 27-28
--  Nota PG: retorna cabecera de ajustes. Para detalle de lineas
--           usar usp_Acct_Report_REME_Detail.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_REME(INTEGER, INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_REME(
    p_company_id   INTEGER,
    p_branch_id    INTEGER,
    p_fecha_desde  DATE,
    p_fecha_hasta  DATE
)
RETURNS TABLE(
    "InflationAdjustmentId"  INTEGER,
    "PeriodCode"             CHAR(6),
    "AdjustmentDate"         DATE,
    "inpcInicio"             NUMERIC(18,6),
    "inpcFin"                NUMERIC(18,6),
    "factorReexpresion"      NUMERIC(18,8),
    "inflacionAcumulada"     NUMERIC(18,6),
    "reme"                   NUMERIC(18,2),
    "totalAjustes"           NUMERIC(18,2),
    "Status"                 VARCHAR(20),
    "JournalEntryId"         BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ia."InflationAdjustmentId",
           ia."PeriodCode",
           ia."AdjustmentDate",
           ia."BaseIndexValue"       AS "inpcInicio",
           ia."EndIndexValue"        AS "inpcFin",
           ia."ReexpressionFactor"   AS "factorReexpresion",
           ia."AccumulatedInflation" AS "inflacionAcumulada",
           ia."TotalMonetaryGainLoss" AS "reme",
           ia."TotalAdjustmentAmount" AS "totalAjustes",
           ia."Status",
           ia."JournalEntryId"
    FROM acct."InflationAdjustment" ia
    WHERE ia."CompanyId"      = p_company_id
      AND ia."BranchId"       = p_branch_id
      AND ia."AdjustmentDate" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND ia."Status"         <> 'VOIDED'
    ORDER BY ia."PeriodCode";
END;
$$;

-- Detalle por cuenta del ultimo ajuste del rango
DROP FUNCTION IF EXISTS usp_Acct_Report_REME_Detail(INTEGER, INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_REME_Detail(
    p_company_id   INTEGER,
    p_branch_id    INTEGER,
    p_fecha_desde  DATE,
    p_fecha_hasta  DATE
)
RETURNS TABLE(
    "AccountCode"       VARCHAR(30),
    "AccountName"       VARCHAR(200),
    "Classification"    VARCHAR(20),
    "HistoricalBalance" NUMERIC(18,2),
    "ReexpressionFactor" NUMERIC(18,8),
    "AdjustedBalance"   NUMERIC(18,2),
    "AdjustmentAmount"  NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_adj_id INTEGER;
BEGIN
    SELECT "InflationAdjustmentId" INTO v_last_adj_id
    FROM acct."InflationAdjustment"
    WHERE "CompanyId"      = p_company_id
      AND "BranchId"       = p_branch_id
      AND "AdjustmentDate" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND "Status"         <> 'VOIDED'
    ORDER BY "PeriodCode" DESC
    LIMIT 1;

    IF v_last_adj_id IS NOT NULL THEN
        RETURN QUERY
        SELECT l."AccountCode",
               l."AccountName",
               l."Classification",
               l."HistoricalBalance",
               l."ReexpressionFactor",
               l."AdjustedBalance",
               l."AdjustmentAmount"
        FROM acct."InflationAdjustmentLine" l
        WHERE l."InflationAdjustmentId" = v_last_adj_id
        ORDER BY l."AccountCode";
    END IF;
END;
$$;
