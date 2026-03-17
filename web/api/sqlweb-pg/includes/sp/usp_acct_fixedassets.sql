-- =============================================================================
--  Archivo : usp_acct_fixedassets.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_acct_fixedassets.sql
--
--  Procedimientos de Activos Fijos (Fixed Assets)
--  Funciones (15):
--   1.  usp_Acct_FixedAssetCategory_List
--   2.  usp_Acct_FixedAssetCategory_Get
--   3.  usp_Acct_FixedAssetCategory_Upsert
--   4.  usp_Acct_FixedAsset_List
--   5.  usp_Acct_FixedAsset_Get
--   6.  usp_Acct_FixedAsset_Insert
--   7.  usp_Acct_FixedAsset_Update
--   8.  usp_Acct_FixedAsset_Dispose
--   9.  usp_Acct_FixedAsset_CalculateDepreciation
--  10.  usp_Acct_FixedAsset_DepreciationHistory
--  11.  usp_Acct_FixedAsset_AddImprovement
--  12.  usp_Acct_FixedAsset_Revalue
--  13.  usp_Acct_FixedAsset_Report_Book
--  14.  usp_Acct_FixedAsset_Report_DepreciationSchedule
--  15.  usp_Acct_FixedAsset_Report_ByCategory
-- =============================================================================

-- =============================================================================
-- 1. usp_Acct_FixedAssetCategory_List
--    Listado paginado de categorias de activos fijos.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAssetCategory_List(INTEGER, VARCHAR(100), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAssetCategory_List(
    p_company_id INTEGER,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_page       INTEGER      DEFAULT 1,
    p_limit      INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count              BIGINT,
    "CategoryId"               INTEGER,
    "CategoryCode"             VARCHAR(20),
    "CategoryName"             VARCHAR(200),
    "DefaultUsefulLifeMonths"  INTEGER,
    "DefaultDepreciationMethod" VARCHAR(20),
    "DefaultResidualPercent"   NUMERIC(5,2),
    "DefaultAssetAccountCode"  VARCHAR(20),
    "DefaultDeprecAccountCode" VARCHAR(20),
    "DefaultExpenseAccountCode" VARCHAR(20),
    "CountryCode"              VARCHAR(2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"  = p_company_id
      AND "IsDeleted"  = FALSE
      AND (p_search IS NULL
           OR "CategoryCode" LIKE '%' || p_search || '%'
           OR "CategoryName" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           "CategoryId", "CategoryCode", "CategoryName",
           "DefaultUsefulLifeMonths", "DefaultDepreciationMethod",
           "DefaultResidualPercent",
           "DefaultAssetAccountCode", "DefaultDeprecAccountCode",
           "DefaultExpenseAccountCode", "CountryCode"
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"  = p_company_id
      AND "IsDeleted"  = FALSE
      AND (p_search IS NULL
           OR "CategoryCode" LIKE '%' || p_search || '%'
           OR "CategoryName" LIKE '%' || p_search || '%')
    ORDER BY "CategoryCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 2. usp_Acct_FixedAssetCategory_Get
--    Detalle de una categoria de activo fijo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAssetCategory_Get(INTEGER, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAssetCategory_Get(
    p_company_id   INTEGER,
    p_category_code VARCHAR(20)
)
RETURNS SETOF acct."FixedAssetCategory"
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"    = p_company_id
      AND "CategoryCode" = p_category_code
      AND "IsDeleted"    = FALSE
    LIMIT 1;
END;
$$;

-- =============================================================================
-- 3. usp_Acct_FixedAssetCategory_Upsert
--    Crear o actualizar una categoria de activo fijo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAssetCategory_Upsert(INTEGER, VARCHAR(20), VARCHAR(200), INTEGER, VARCHAR(20), NUMERIC(5,2), VARCHAR(20), VARCHAR(20), VARCHAR(20), VARCHAR(2), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAssetCategory_Upsert(
    p_company_id                  INTEGER,
    p_category_code               VARCHAR(20),
    p_category_name               VARCHAR(200),
    p_default_useful_life_months  INTEGER,
    p_default_depreciation_method VARCHAR(20)  DEFAULT 'STRAIGHT_LINE',
    p_default_residual_percent    NUMERIC(5,2) DEFAULT 0,
    p_default_asset_account_code  VARCHAR(20)  DEFAULT NULL,
    p_default_deprec_account_code VARCHAR(20)  DEFAULT NULL,
    p_default_expense_account_code VARCHAR(20) DEFAULT NULL,
    p_country_code                VARCHAR(2)   DEFAULT NULL,
    OUT p_resultado                INTEGER,
    OUT p_mensaje                  TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."FixedAssetCategory"
        WHERE "CompanyId"    = p_company_id
          AND "CategoryCode" = p_category_code
          AND "IsDeleted"    = FALSE
    ) THEN
        UPDATE acct."FixedAssetCategory"
        SET "CategoryName"              = p_category_name,
            "DefaultUsefulLifeMonths"   = p_default_useful_life_months,
            "DefaultDepreciationMethod" = p_default_depreciation_method,
            "DefaultResidualPercent"    = p_default_residual_percent,
            "DefaultAssetAccountCode"   = p_default_asset_account_code,
            "DefaultDeprecAccountCode"  = p_default_deprec_account_code,
            "DefaultExpenseAccountCode" = p_default_expense_account_code,
            "CountryCode"               = p_country_code
        WHERE "CompanyId"    = p_company_id
          AND "CategoryCode" = p_category_code
          AND "IsDeleted"    = FALSE;
    ELSE
        INSERT INTO acct."FixedAssetCategory" (
            "CompanyId", "CategoryCode", "CategoryName",
            "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent",
            "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode",
            "CountryCode", "IsDeleted", "CreatedAt"
        )
        VALUES (
            p_company_id, p_category_code, p_category_name,
            p_default_useful_life_months, p_default_depreciation_method, p_default_residual_percent,
            p_default_asset_account_code, p_default_deprec_account_code, p_default_expense_account_code,
            p_country_code, FALSE, (NOW() AT TIME ZONE 'UTC')
        );
    END IF;

    p_resultado := 1;
    p_mensaje   := 'Categoria guardada';
END;
$$;

-- =============================================================================
-- 4. usp_Acct_FixedAsset_List
--    Listado paginado de activos fijos con valor en libros calculado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_List(INTEGER, INTEGER, VARCHAR(20), VARCHAR(20), VARCHAR(20), VARCHAR(100), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_List(
    p_company_id      INTEGER,
    p_branch_id       INTEGER      DEFAULT NULL,
    p_category_code   VARCHAR(20)  DEFAULT NULL,
    p_status          VARCHAR(20)  DEFAULT NULL,
    p_cost_center_code VARCHAR(20) DEFAULT NULL,
    p_search          VARCHAR(100) DEFAULT NULL,
    p_page            INTEGER      DEFAULT 1,
    p_limit           INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count             BIGINT,
    "AssetId"                 BIGINT,
    "AssetCode"               VARCHAR(40),
    "Description"             VARCHAR(250),
    "BranchId"                INTEGER,
    "CategoryId"              INTEGER,
    "CategoryCode"            VARCHAR(20),
    "CategoryName"            VARCHAR(200),
    "AcquisitionDate"         DATE,
    "AcquisitionCost"         NUMERIC(18,2),
    "ResidualValue"           NUMERIC(18,2),
    "UsefulLifeMonths"        INTEGER,
    "DepreciationMethod"      VARCHAR(20),
    "Status"                  VARCHAR(20),
    "CostCenterCode"          VARCHAR(20),
    "Location"                VARCHAR(200),
    "SerialNumber"            VARCHAR(100),
    "CurrencyCode"            VARCHAR(3),
    "AccumulatedDepreciation" NUMERIC(18,2),
    "BookValue"               NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsDeleted"  = FALSE
      AND (p_branch_id        IS NULL OR a."BranchId"       = p_branch_id)
      AND (p_category_code    IS NULL OR c."CategoryCode"   = p_category_code)
      AND (p_status           IS NULL OR a."Status"         = p_status)
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code)
      AND (p_search IS NULL
           OR a."AssetCode"   LIKE '%' || p_search || '%'
           OR a."Description" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           a."AssetId", a."AssetCode", a."Description",
           a."BranchId",
           c."CategoryId", c."CategoryCode", c."CategoryName",
           a."AcquisitionDate", a."AcquisitionCost", a."ResidualValue",
           a."UsefulLifeMonths", a."DepreciationMethod",
           a."Status", a."CostCenterCode", a."Location",
           a."SerialNumber", a."CurrencyCode",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId" = a."AssetId"
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost"
               - COALESCE((SELECT SUM(d2."Amount") FROM acct."FixedAssetDepreciation" d2 WHERE d2."AssetId" = a."AssetId"), 0)
               + COALESCE((SELECT SUM(im."Amount") FROM acct."FixedAssetImprovement" im WHERE im."AssetId" = a."AssetId"), 0)
               AS "BookValue"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsDeleted"  = FALSE
      AND (p_branch_id        IS NULL OR a."BranchId"       = p_branch_id)
      AND (p_category_code    IS NULL OR c."CategoryCode"   = p_category_code)
      AND (p_status           IS NULL OR a."Status"         = p_status)
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code)
      AND (p_search IS NULL
           OR a."AssetCode"   LIKE '%' || p_search || '%'
           OR a."Description" LIKE '%' || p_search || '%')
    ORDER BY a."AssetCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 5. usp_Acct_FixedAsset_Get
--    Detalle completo de un activo fijo con valor en libros calculado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Get(INTEGER, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Get(
    p_company_id INTEGER,
    p_asset_id   BIGINT
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a.*,
           c."CategoryCode",
           c."CategoryName",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId" = a."AssetId"
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost"
               - COALESCE((SELECT SUM(d2."Amount") FROM acct."FixedAssetDepreciation" d2 WHERE d2."AssetId" = a."AssetId"), 0)
               + COALESCE((SELECT SUM(im."Amount") FROM acct."FixedAssetImprovement" im WHERE im."AssetId" = a."AssetId"), 0)
               AS "BookValue"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId" = p_company_id
      AND a."AssetId"   = p_asset_id
      AND a."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
-- 6. usp_Acct_FixedAsset_Insert
--    Registrar un nuevo activo fijo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Insert(INTEGER, INTEGER, VARCHAR(40), VARCHAR(250), INTEGER, DATE, NUMERIC(18,2), NUMERIC(18,2), INTEGER, VARCHAR(20), VARCHAR(20), VARCHAR(20), VARCHAR(20), VARCHAR(20), VARCHAR(200), VARCHAR(100), INTEGER, VARCHAR(3), VARCHAR(40), BIGINT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Insert(
    p_company_id          INTEGER,
    p_branch_id           INTEGER,
    p_asset_code          VARCHAR(40),
    p_description         VARCHAR(250),
    p_category_id         INTEGER,
    p_acquisition_date    DATE,
    p_acquisition_cost    NUMERIC(18,2),
    p_residual_value      NUMERIC(18,2)  DEFAULT 0,
    p_useful_life_months  INTEGER        DEFAULT NULL,
    p_depreciation_method VARCHAR(20)    DEFAULT 'STRAIGHT_LINE',
    p_asset_account_code  VARCHAR(20)    DEFAULT NULL,
    p_deprec_account_code VARCHAR(20)    DEFAULT NULL,
    p_expense_account_code VARCHAR(20)   DEFAULT NULL,
    p_cost_center_code    VARCHAR(20)    DEFAULT NULL,
    p_location            VARCHAR(200)   DEFAULT NULL,
    p_serial_number       VARCHAR(100)   DEFAULT NULL,
    p_units_capacity      INTEGER        DEFAULT NULL,
    p_currency_code       VARCHAR(3)     DEFAULT 'VES',
    p_cod_usuario         VARCHAR(40)    DEFAULT NULL,
    OUT p_asset_id         BIGINT,
    OUT p_resultado        INTEGER,
    OUT p_mensaje          TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_asset_id  := 0;
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetCode" = p_asset_code
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'El codigo de activo ya existe en esta empresa';
        RETURN;
    END IF;

    INSERT INTO acct."FixedAsset" (
        "CompanyId", "BranchId", "AssetCode", "Description", "CategoryId",
        "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths",
        "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode",
        "CostCenterCode", "Location", "SerialNumber", "UnitsCapacity",
        "CurrencyCode", "Status", "IsDeleted", "CreatedAt", "CreatedBy"
    )
    VALUES (
        p_company_id, p_branch_id, p_asset_code, p_description, p_category_id,
        p_acquisition_date, p_acquisition_cost, p_residual_value, p_useful_life_months,
        p_depreciation_method, p_asset_account_code, p_deprec_account_code, p_expense_account_code,
        p_cost_center_code, p_location, p_serial_number, p_units_capacity,
        p_currency_code, 'ACTIVE', FALSE, (NOW() AT TIME ZONE 'UTC'), p_cod_usuario
    )
    RETURNING "AssetId" INTO p_asset_id;

    p_resultado := 1;
    p_mensaje   := 'Activo fijo registrado';
END;
$$;

-- =============================================================================
-- 7. usp_Acct_FixedAsset_Update
--    Actualizar campos editables de un activo fijo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Update(INTEGER, BIGINT, VARCHAR(250), VARCHAR(200), VARCHAR(100), VARCHAR(20), VARCHAR(3), VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Update(
    p_company_id       INTEGER,
    p_asset_id         BIGINT,
    p_description      VARCHAR(250) DEFAULT NULL,
    p_location         VARCHAR(200) DEFAULT NULL,
    p_serial_number    VARCHAR(100) DEFAULT NULL,
    p_cost_center_code VARCHAR(20)  DEFAULT NULL,
    p_currency_code    VARCHAR(3)   DEFAULT NULL,
    p_cod_usuario      VARCHAR(40)  DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado';
        RETURN;
    END IF;

    UPDATE acct."FixedAsset"
    SET "Description"   = COALESCE(p_description,      "Description"),
        "Location"      = COALESCE(p_location,         "Location"),
        "SerialNumber"  = COALESCE(p_serial_number,    "SerialNumber"),
        "CostCenterCode" = COALESCE(p_cost_center_code, "CostCenterCode"),
        "CurrencyCode"  = COALESCE(p_currency_code,    "CurrencyCode"),
        "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"     = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Activo fijo actualizado';
END;
$$;

-- =============================================================================
-- 8. usp_Acct_FixedAsset_Dispose
--    Desincorporar un activo fijo (cambiar estado a DISPOSED).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Dispose(INTEGER, BIGINT, DATE, NUMERIC(18,2), VARCHAR(500), VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Dispose(
    p_company_id     INTEGER,
    p_asset_id       BIGINT,
    p_disposal_date  DATE,
    p_disposal_amount NUMERIC(18,2) DEFAULT 0,
    p_disposal_reason VARCHAR(500)  DEFAULT NULL,
    p_cod_usuario    VARCHAR(40)    DEFAULT NULL,
    OUT p_resultado   INTEGER,
    OUT p_mensaje     TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "Status"    = 'ACTIVE'
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END IF;

    UPDATE acct."FixedAsset"
    SET "Status"         = 'DISPOSED',
        "DisposalDate"   = p_disposal_date,
        "DisposalAmount" = p_disposal_amount,
        "DisposalReason" = p_disposal_reason,
        "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"      = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Activo desincorporado';
END;
$$;

-- =============================================================================
-- 9. usp_Acct_FixedAsset_CalculateDepreciation
--    Calcular depreciacion mensual para activos fijos de una empresa/sucursal.
--    Soporta metodos STRAIGHT_LINE y DOUBLE_DECLINING.
--    p_preview = TRUE solo devuelve preview sin insertar registros.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_CalculateDepreciation(INTEGER, INTEGER, VARCHAR(7), VARCHAR(20), BOOLEAN, VARCHAR(40), INTEGER, TEXT, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_CalculateDepreciation(
    p_company_id       INTEGER,
    p_branch_id        INTEGER,
    p_period_code      VARCHAR(7),
    p_cost_center_code VARCHAR(20)  DEFAULT NULL,
    p_preview          BOOLEAN      DEFAULT FALSE,
    p_cod_usuario      VARCHAR(40)  DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT,
    OUT p_entries_generated INTEGER
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_start  DATE;
    v_period_end    DATE;
BEGIN
    p_resultado        := 0;
    p_mensaje          := '';
    p_entries_generated := 0;

    v_period_start := CAST(p_period_code || '-01' AS DATE);
    v_period_end   := (DATE_TRUNC('month', v_period_start) + INTERVAL '1 month - 1 day')::DATE;

    -- Tabla temporal para calculo de depreciacion
    CREATE TEMP TABLE _depreciation_calc (
        asset_id              BIGINT,
        asset_code            VARCHAR(40),
        description           VARCHAR(250),
        acquisition_cost      NUMERIC(18,2),
        residual_value        NUMERIC(18,2),
        useful_life_months    INTEGER,
        depreciation_method   VARCHAR(20),
        expense_account_code  VARCHAR(20),
        deprec_account_code   VARCHAR(20),
        previous_accum        NUMERIC(18,2),
        months_depreciated    INTEGER,
        calc_amount           NUMERIC(18,2),
        new_accum             NUMERIC(18,2),
        new_book_value        NUMERIC(18,2)
    ) ON COMMIT DROP;

    -- Insertar activos elegibles
    INSERT INTO _depreciation_calc (
        asset_id, asset_code, description, acquisition_cost, residual_value,
        useful_life_months, depreciation_method, expense_account_code, deprec_account_code,
        previous_accum, months_depreciated, calc_amount, new_accum, new_book_value
    )
    SELECT
        a."AssetId",
        a."AssetCode",
        a."Description",
        a."AcquisitionCost",
        a."ResidualValue",
        a."UsefulLifeMonths",
        a."DepreciationMethod",
        a."ExpenseAccountCode",
        a."DeprecAccountCode",
        COALESCE((SELECT SUM(d."Amount") FROM acct."FixedAssetDepreciation" d WHERE d."AssetId" = a."AssetId"), 0),
        COALESCE((SELECT COUNT(*) FROM acct."FixedAssetDepreciation" d WHERE d."AssetId" = a."AssetId"), 0),
        0, 0, 0
    FROM acct."FixedAsset" a
    WHERE a."CompanyId"          = p_company_id
      AND a."BranchId"           = p_branch_id
      AND a."Status"             = 'ACTIVE'
      AND a."IsDeleted"          = FALSE
      AND a."DepreciationMethod" <> 'NONE'
      AND a."AcquisitionDate"    <= v_period_end
      AND NOT EXISTS (
          SELECT 1 FROM acct."FixedAssetDepreciation" d
          WHERE d."AssetId"   = a."AssetId"
            AND d."PeriodCode" = p_period_code
      )
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code);

    -- STRAIGHT_LINE
    UPDATE _depreciation_calc
    SET calc_amount = ROUND((acquisition_cost - residual_value) / useful_life_months, 2)
    WHERE depreciation_method = 'STRAIGHT_LINE'
      AND useful_life_months > 0;

    -- DOUBLE_DECLINING
    UPDATE _depreciation_calc
    SET calc_amount = ROUND((2.0 / useful_life_months) * (acquisition_cost - previous_accum), 2)
    WHERE depreciation_method = 'DOUBLE_DECLINING'
      AND useful_life_months > 0;

    -- Aplicar tope: no depreciar por debajo del valor residual
    UPDATE _depreciation_calc
    SET calc_amount = acquisition_cost - residual_value - previous_accum
    WHERE previous_accum + calc_amount > acquisition_cost - residual_value;

    -- Eliminar filas donde no hay monto a depreciar
    DELETE FROM _depreciation_calc WHERE calc_amount <= 0;

    -- Calcular nuevos acumulados
    UPDATE _depreciation_calc
    SET new_accum      = previous_accum + calc_amount,
        new_book_value = acquisition_cost - (previous_accum + calc_amount);

    GET DIAGNOSTICS p_entries_generated = ROW_COUNT;

    -- Si es preview, solo retornar sin insertar
    IF p_preview THEN
        -- El caller debe hacer SELECT * FROM _depreciation_calc ORDER BY asset_code
        p_resultado := 1;
        p_mensaje   := 'Preview de depreciacion: ' || p_entries_generated::TEXT || ' asientos';
        RETURN;
    END IF;

    -- Insertar registros de depreciacion
    INSERT INTO acct."FixedAssetDepreciation" (
        "AssetId", "PeriodCode", "DepreciationDate", "Amount",
        "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt"
    )
    SELECT asset_id, p_period_code, v_period_end,
           calc_amount, new_accum, new_book_value,
           'POSTED', (NOW() AT TIME ZONE 'UTC')
    FROM _depreciation_calc;

    GET DIAGNOSTICS p_entries_generated = ROW_COUNT;

    p_resultado := 1;
    p_mensaje   := 'Depreciacion generada: ' || p_entries_generated::TEXT || ' asientos';
END;
$$;

-- =============================================================================
-- 10. usp_Acct_FixedAsset_DepreciationHistory
--     Historial de depreciacion de un activo fijo, paginado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_DepreciationHistory(INTEGER, BIGINT, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_DepreciationHistory(
    p_company_id INTEGER,
    p_asset_id   BIGINT,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
)
RETURNS TABLE(
    p_total_count            BIGINT,
    "DepreciationId"         BIGINT,
    "AssetId"                BIGINT,
    "PeriodCode"             VARCHAR(7),
    "DepreciationDate"       DATE,
    "Amount"                 NUMERIC(18,2),
    "AccumulatedDepreciation" NUMERIC(18,2),
    "BookValue"              NUMERIC(18,2),
    "JournalEntryId"         BIGINT,
    "Status"                 VARCHAR(20),
    "CreatedAt"              TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAssetDepreciation" d
    INNER JOIN acct."FixedAsset" a ON d."AssetId" = a."AssetId"
    WHERE a."CompanyId" = p_company_id
      AND d."AssetId"   = p_asset_id;

    RETURN QUERY
    SELECT v_total_count,
           d."DepreciationId", d."AssetId", d."PeriodCode",
           d."DepreciationDate", d."Amount",
           d."AccumulatedDepreciation", d."BookValue",
           d."JournalEntryId", d."Status", d."CreatedAt"
    FROM acct."FixedAssetDepreciation" d
    INNER JOIN acct."FixedAsset" a ON d."AssetId" = a."AssetId"
    WHERE a."CompanyId" = p_company_id
      AND d."AssetId"   = p_asset_id
    ORDER BY d."PeriodCode" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 11. usp_Acct_FixedAsset_AddImprovement
--     Registrar una mejora/adicion a un activo fijo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_AddImprovement(INTEGER, BIGINT, DATE, VARCHAR(500), NUMERIC(18,2), INTEGER, VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_AddImprovement(
    p_company_id          INTEGER,
    p_asset_id            BIGINT,
    p_improvement_date    DATE,
    p_description         VARCHAR(500),
    p_amount              NUMERIC(18,2),
    p_additional_life_months INTEGER    DEFAULT 0,
    p_cod_usuario         VARCHAR(40)   DEFAULT NULL,
    OUT p_resultado        INTEGER,
    OUT p_mensaje          TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "Status"    = 'ACTIVE'
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END IF;

    INSERT INTO acct."FixedAssetImprovement" (
        "AssetId", "ImprovementDate", "Description", "Amount",
        "AdditionalLifeMonths", "CreatedAt", "CreatedBy"
    )
    VALUES (
        p_asset_id, p_improvement_date, p_description, p_amount,
        p_additional_life_months, (NOW() AT TIME ZONE 'UTC'), p_cod_usuario
    );

    UPDATE acct."FixedAsset"
    SET "AcquisitionCost"  = "AcquisitionCost" + p_amount,
        "UsefulLifeMonths" = "UsefulLifeMonths" + p_additional_life_months,
        "UpdatedAt"        = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"        = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Mejora registrada';
END;
$$;

-- =============================================================================
-- 12. usp_Acct_FixedAsset_Revalue
--     Revaluacion de un activo fijo por indice multiplicador.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Revalue(INTEGER, BIGINT, DATE, NUMERIC(12,6), VARCHAR(2), VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Revalue(
    p_company_id       INTEGER,
    p_asset_id         BIGINT,
    p_revaluation_date DATE,
    p_index_factor     NUMERIC(12,6),
    p_country_code     VARCHAR(2),
    p_cod_usuario      VARCHAR(40),
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_cost        NUMERIC(18,2);
    v_old_accum       NUMERIC(18,2);
    v_new_cost        NUMERIC(18,2);
    v_new_accum       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "AcquisitionCost" INTO v_old_cost
    FROM acct."FixedAsset"
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    IF v_old_cost IS NULL THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado';
        RETURN;
    END IF;

    SELECT COALESCE(SUM("Amount"), 0) INTO v_old_accum
    FROM acct."FixedAssetDepreciation"
    WHERE "AssetId" = p_asset_id;

    v_new_cost  := ROUND(v_old_cost * p_index_factor, 2);
    v_new_accum := ROUND(v_old_accum * p_index_factor, 2);

    INSERT INTO acct."FixedAssetRevaluation" (
        "AssetId", "RevaluationDate",
        "PreviousCost", "NewCost", "PreviousAccumDeprec", "NewAccumDeprec",
        "IndexFactor", "CountryCode", "CreatedBy", "CreatedAt"
    )
    VALUES (
        p_asset_id, p_revaluation_date,
        v_old_cost, v_new_cost, v_old_accum, v_new_accum,
        p_index_factor, p_country_code, p_cod_usuario, (NOW() AT TIME ZONE 'UTC')
    );

    UPDATE acct."FixedAsset"
    SET "AcquisitionCost" = v_new_cost,
        "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"       = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Revaluacion aplicada';
END;
$$;

-- =============================================================================
-- 13. usp_Acct_FixedAsset_Report_Book
--     Libro de activos fijos a una fecha de corte.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Report_Book(INTEGER, INTEGER, DATE, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Report_Book(
    p_company_id   INTEGER,
    p_branch_id    INTEGER,
    p_fecha_corte  DATE,
    p_category_code VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE(
    "AssetCode"               VARCHAR(40),
    "Description"             VARCHAR(250),
    "CategoryName"            VARCHAR(200),
    "AcquisitionDate"         DATE,
    "AcquisitionCost"         NUMERIC(18,2),
    "AccumulatedDepreciation" NUMERIC(18,2),
    "BookValue"               NUMERIC(18,2),
    "Status"                  VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a."AssetCode",
           a."Description",
           c."CategoryName",
           a."AcquisitionDate",
           a."AcquisitionCost",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId"          = a."AssetId"
                 AND d."DepreciationDate" <= p_fecha_corte
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost" - COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId"          = a."AssetId"
                 AND d."DepreciationDate" <= p_fecha_corte
           ), 0) AS "BookValue",
           a."Status"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"       = p_company_id
      AND a."BranchId"        = p_branch_id
      AND a."IsDeleted"       = FALSE
      AND a."AcquisitionDate" <= p_fecha_corte
      AND a."Status"          IN ('ACTIVE', 'FULLY_DEPRECIATED')
      AND (p_category_code IS NULL OR c."CategoryCode" = p_category_code)
    ORDER BY c."CategoryName", a."AssetCode";
END;
$$;

-- =============================================================================
-- 14. usp_Acct_FixedAsset_Report_DepreciationSchedule
--     Proyeccion de depreciacion mensual para un activo fijo.
--     Genera tabla de meses desde fecha de adquisicion hasta fin de vida util.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Report_DepreciationSchedule(INTEGER, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Report_DepreciationSchedule(
    p_company_id INTEGER,
    p_asset_id   BIGINT
)
RETURNS TABLE(
    "AssetCode"              VARCHAR(40),
    "Description"            VARCHAR(250),
    "MonthNumber"            INTEGER,
    "PeriodCode"             VARCHAR(7),
    "DepreciationDate"       DATE,
    "MonthlyAmount"          NUMERIC(18,2),
    "AccumulatedDepreciation" NUMERIC(18,2),
    "BookValue"              NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_acquisition_date    DATE;
    v_acquisition_cost    NUMERIC(18,2);
    v_residual_value      NUMERIC(18,2);
    v_useful_life_months  INTEGER;
    v_depreciation_method VARCHAR(20);
    v_asset_code          VARCHAR(40);
    v_description         VARCHAR(250);
    v_monthly_amount      NUMERIC(18,2);
    v_depreciable_base    NUMERIC(18,2);
BEGIN
    SELECT "AcquisitionDate", "AcquisitionCost", "ResidualValue",
           "UsefulLifeMonths", "DepreciationMethod", "AssetCode", "Description"
    INTO v_acquisition_date, v_acquisition_cost, v_residual_value,
         v_useful_life_months, v_depreciation_method, v_asset_code, v_description
    FROM acct."FixedAsset"
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    IF v_acquisition_date IS NULL THEN
        RETURN;
    END IF;

    v_depreciable_base := v_acquisition_cost - v_residual_value;

    -- For STRAIGHT_LINE: constant monthly amount
    IF v_depreciation_method = 'STRAIGHT_LINE' AND v_useful_life_months > 0 THEN
        v_monthly_amount := ROUND(v_depreciable_base / v_useful_life_months, 2);
    ELSE
        v_monthly_amount := 0;
    END IF;

    RETURN QUERY
    WITH months AS (
        SELECT generate_series(1, v_useful_life_months) AS n
    )
    SELECT v_asset_code,
           v_description,
           m.n AS "MonthNumber",
           TO_CHAR(v_acquisition_date + (m.n || ' month')::INTERVAL, 'YYYY-MM') AS "PeriodCode",
           (v_acquisition_date + (m.n || ' month')::INTERVAL)::DATE AS "DepreciationDate",
           CASE
               WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                   GREATEST(0, LEAST(v_monthly_amount,
                       v_depreciable_base - (v_monthly_amount * (m.n - 1))
                   ))
               ELSE 0
           END AS "MonthlyAmount",
           LEAST(v_depreciable_base,
               CASE
                   WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                       v_monthly_amount * m.n
                   ELSE 0
               END
           ) AS "AccumulatedDepreciation",
           GREATEST(v_residual_value,
               v_acquisition_cost - LEAST(v_depreciable_base,
                   CASE
                       WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                           v_monthly_amount * m.n
                       ELSE 0
                   END
               )
           ) AS "BookValue"
    FROM months m
    ORDER BY m.n;
END;
$$;

-- =============================================================================
-- 15. usp_Acct_FixedAsset_Report_ByCategory
--     Resumen de activos fijos agrupados por categoria a una fecha de corte.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_FixedAsset_Report_ByCategory(INTEGER, INTEGER, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_FixedAsset_Report_ByCategory(
    p_company_id  INTEGER,
    p_branch_id   INTEGER,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "CategoryCode"                VARCHAR(20),
    "CategoryName"                VARCHAR(200),
    "AssetCount"                  BIGINT,
    "TotalAcquisitionCost"        NUMERIC(18,2),
    "TotalAccumulatedDepreciation" NUMERIC(18,2),
    "TotalBookValue"              NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH asset_deprec AS (
        SELECT a."AssetId",
               a."CategoryId",
               a."AcquisitionCost",
               COALESCE((
                   SELECT SUM(d."Amount")
                   FROM acct."FixedAssetDepreciation" d
                   WHERE d."AssetId"          = a."AssetId"
                     AND d."DepreciationDate" <= p_fecha_corte
               ), 0) AS accum_depreciation
        FROM acct."FixedAsset" a
        WHERE a."CompanyId"       = p_company_id
          AND a."BranchId"        = p_branch_id
          AND a."IsDeleted"       = FALSE
          AND a."AcquisitionDate" <= p_fecha_corte
    )
    SELECT c."CategoryCode",
           c."CategoryName",
           COUNT(ad."AssetId")                              AS "AssetCount",
           SUM(ad."AcquisitionCost")                       AS "TotalAcquisitionCost",
           SUM(ad.accum_depreciation)                      AS "TotalAccumulatedDepreciation",
           SUM(ad."AcquisitionCost" - ad.accum_depreciation) AS "TotalBookValue"
    FROM asset_deprec ad
    INNER JOIN acct."FixedAssetCategory" c ON ad."CategoryId" = c."CategoryId"
    GROUP BY c."CategoryCode", c."CategoryName"
    ORDER BY c."CategoryCode";
END;
$$;
