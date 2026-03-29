-- =============================================================================
-- usp_fiscal_retenciones.sql (PostgreSQL)
-- SPs para mÃ³dulo de retenciones fiscales automÃ¡ticas.
-- =============================================================================

-- =============================================================================
-- 1. usp_Fiscal_Withholding_Calculate
--    Calcula la retenciÃ³n aplicable a un pago segÃºn tipo de proveedor y actividad.
--    Retorna: rate, amount, concept_code, subtrahend
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Withholding_Calculate(INT, VARCHAR, NUMERIC, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Withholding_Calculate(
    p_company_id       INT,
    p_supplier_code    VARCHAR(24),
    p_taxable_base     NUMERIC(18,2),
    p_withholding_type VARCHAR(20) DEFAULT 'ISLR',
    p_country_code     VARCHAR(2)  DEFAULT 'VE'
)
RETURNS TABLE(
    "Rate"          NUMERIC(8,4),
    "Amount"        NUMERIC(18,2),
    "ConceptCode"   VARCHAR(20),
    "Subtrahend"    NUMERIC(18,2),
    "Description"   VARCHAR(200)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_supplier_type    VARCHAR(20);
    v_business_activity VARCHAR(30);
    v_default_ret_code VARCHAR(20);
    v_rate             NUMERIC(8,4) := 0;
    v_subtrahend_ut    NUMERIC(8,4) := 0;
    v_min_base_ut      NUMERIC(8,4) := 0;
    v_concept_code     VARCHAR(20) := '';
    v_description      VARCHAR(200) := '';
    v_ut_value         NUMERIC(18,4) := 1;
    v_subtrahend_amount NUMERIC(18,2) := 0;
    v_retention_amount NUMERIC(18,2) := 0;
BEGIN
    -- 1. Obtener datos fiscales del proveedor
    SELECT s."SupplierType", s."BusinessActivity", s."DefaultRetentionCode"
    INTO v_supplier_type, v_business_activity, v_default_ret_code
    FROM master."Supplier" s
    WHERE s."CompanyId" = p_company_id
      AND s."SupplierCode" = p_supplier_code
      AND s."IsDeleted" = FALSE;

    IF v_supplier_type IS NULL THEN
        v_supplier_type := 'JURIDICA';
    END IF;

    -- 2. Obtener valor UT vigente
    SELECT tu."UnitValue" INTO v_ut_value
    FROM cfg."TaxUnit" tu
    WHERE tu."CountryCode" = p_country_code
      AND tu."IsActive" = TRUE
    ORDER BY tu."EffectiveDate" DESC
    LIMIT 1;

    IF v_ut_value IS NULL OR v_ut_value <= 0 THEN
        v_ut_value := 1;
    END IF;

    -- 3. Buscar concepto por actividad + tipo persona
    SELECT wc."Rate", wc."SubtrahendUT", wc."MinBaseUT", wc."ConceptCode", wc."Description"
    INTO v_rate, v_subtrahend_ut, v_min_base_ut, v_concept_code, v_description
    FROM fiscal."WithholdingConcept" wc
    WHERE wc."CompanyId" = p_company_id
      AND wc."CountryCode" = p_country_code
      AND wc."RetentionType" = p_withholding_type
      AND (wc."SupplierType" = v_supplier_type OR wc."SupplierType" = 'AMBOS')
      AND (v_business_activity IS NULL OR wc."ActivityCode" = v_business_activity)
      AND wc."IsActive" = TRUE
      AND wc."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN wc."SupplierType" = v_supplier_type THEN 0 ELSE 1 END,
        CASE WHEN wc."ActivityCode" = v_business_activity THEN 0 ELSE 1 END
    LIMIT 1;

    -- 4. Fallback: buscar por DefaultRetentionCode del proveedor
    IF v_rate IS NULL OR v_rate <= 0 THEN
        IF v_default_ret_code IS NOT NULL THEN
            SELECT wc."Rate", wc."SubtrahendUT", wc."MinBaseUT", wc."ConceptCode", wc."Description"
            INTO v_rate, v_subtrahend_ut, v_min_base_ut, v_concept_code, v_description
            FROM fiscal."WithholdingConcept" wc
            WHERE wc."ConceptCode" = v_default_ret_code
              AND wc."CountryCode" = p_country_code
              AND wc."IsActive" = TRUE
              AND wc."IsDeleted" = FALSE
            LIMIT 1;
        END IF;
    END IF;

    -- 5. Si no hay concepto, no retener
    IF v_rate IS NULL OR v_rate <= 0 THEN
        RETURN QUERY SELECT 0::NUMERIC(8,4), 0::NUMERIC(18,2), ''::VARCHAR(20), 0::NUMERIC(18,2), 'Sin retenciÃ³n aplicable'::VARCHAR(200);
        RETURN;
    END IF;

    -- 6. Verificar umbral mÃ­nimo (en UT)
    IF v_min_base_ut > 0 AND p_taxable_base < (v_min_base_ut * v_ut_value) THEN
        RETURN QUERY SELECT 0::NUMERIC(8,4), 0::NUMERIC(18,2), v_concept_code, 0::NUMERIC(18,2),
            ('Base inferior al mÃ­nimo de ' || v_min_base_ut || ' UT')::VARCHAR(200);
        RETURN;
    END IF;

    -- 7. Calcular retenciÃ³n
    v_subtrahend_amount := ROUND(v_subtrahend_ut * v_ut_value, 2);
    v_retention_amount := ROUND(p_taxable_base * v_rate / 100.0, 2) - v_subtrahend_amount;

    -- No puede ser negativa
    IF v_retention_amount < 0 THEN
        v_retention_amount := 0;
    END IF;

    RETURN QUERY SELECT v_rate, v_retention_amount, v_concept_code, v_subtrahend_amount, v_description;
END; $$;

-- =============================================================================
-- 2. usp_Fiscal_ISLR_CalcTariff
--    Calcula ISLR progresivo sobre enriquecimiento neto en UT.
--    Usa fiscal.ISLRTariff.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_ISLR_CalcTariff(NUMERIC, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_ISLR_CalcTariff(
    p_net_income_ut   NUMERIC(18,2),
    p_country_code    VARCHAR(2) DEFAULT 'VE',
    p_tax_year        INT DEFAULT 2026
)
RETURNS TABLE("TaxAmount" NUMERIC(18,2), "Rate" NUMERIC(5,2), "Subtrahend" NUMERIC(18,2))
LANGUAGE plpgsql AS $$
DECLARE
    v_rate        NUMERIC(5,2) := 0;
    v_subtrahend  NUMERIC(18,2) := 0;
    v_tax         NUMERIC(18,2) := 0;
BEGIN
    IF p_net_income_ut <= 0 THEN
        RETURN QUERY SELECT 0::NUMERIC(18,2), 0::NUMERIC(5,2), 0::NUMERIC(18,2);
        RETURN;
    END IF;

    SELECT t."Rate", t."Subtrahend"
    INTO v_rate, v_subtrahend
    FROM fiscal."ISLRTariff" t
    WHERE t."CountryCode" = p_country_code
      AND t."TaxYear" = p_tax_year
      AND t."IsActive" = TRUE
      AND p_net_income_ut >= t."BracketFrom"
      AND (t."BracketTo" IS NULL OR p_net_income_ut <= t."BracketTo")
    ORDER BY t."BracketFrom" DESC
    LIMIT 1;

    v_tax := GREATEST(0, ROUND(p_net_income_ut * v_rate / 100.0 - COALESCE(v_subtrahend, 0), 2));

    RETURN QUERY SELECT v_tax, v_rate, COALESCE(v_subtrahend, 0::NUMERIC(18,2));
END; $$;

-- =============================================================================
-- 3. usp_Fiscal_WithholdingConcept_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_WithholdingConcept_List(INT, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_WithholdingConcept_List(
    p_company_id      INT,
    p_country_code    VARCHAR(2) DEFAULT NULL,
    p_retention_type  VARCHAR(20) DEFAULT NULL,
    p_search          VARCHAR(100) DEFAULT NULL,
    p_page            INT DEFAULT 1,
    p_limit           INT DEFAULT 50
)
RETURNS TABLE(
    p_total BIGINT, "ConceptId" INT, "ConceptCode" VARCHAR(20), "Description" VARCHAR(200),
    "SupplierType" VARCHAR(20), "ActivityCode" VARCHAR(30), "RetentionType" VARCHAR(20),
    "Rate" NUMERIC(8,4), "SubtrahendUT" NUMERIC(8,4), "MinBaseUT" NUMERIC(8,4),
    "SeniatCode" VARCHAR(10), "CountryCode" CHAR(2), "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM fiscal."WithholdingConcept" wc
    WHERE wc."CompanyId" = p_company_id AND wc."IsDeleted" = FALSE
      AND (p_country_code IS NULL OR wc."CountryCode" = p_country_code)
      AND (p_retention_type IS NULL OR wc."RetentionType" = p_retention_type)
      AND (p_search IS NULL OR wc."Description" ILIKE '%' || p_search || '%' OR wc."ConceptCode" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total, wc."ConceptId", wc."ConceptCode", wc."Description",
           wc."SupplierType", wc."ActivityCode", wc."RetentionType",
           wc."Rate", wc."SubtrahendUT", wc."MinBaseUT",
           wc."SeniatCode", wc."CountryCode", wc."IsActive"
    FROM fiscal."WithholdingConcept" wc
    WHERE wc."CompanyId" = p_company_id AND wc."IsDeleted" = FALSE
      AND (p_country_code IS NULL OR wc."CountryCode" = p_country_code)
      AND (p_retention_type IS NULL OR wc."RetentionType" = p_retention_type)
      AND (p_search IS NULL OR wc."Description" ILIKE '%' || p_search || '%' OR wc."ConceptCode" ILIKE '%' || p_search || '%')
    ORDER BY wc."CountryCode", wc."RetentionType", wc."ConceptCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;

-- =============================================================================
-- 4. usp_Fiscal_WithholdingConcept_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_WithholdingConcept_Upsert(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, NUMERIC, NUMERIC, NUMERIC, VARCHAR, INT, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_WithholdingConcept_Upsert(
    p_company_id      INT,
    p_country_code    VARCHAR(2),
    p_concept_code    VARCHAR(20),
    p_description     VARCHAR(200),
    p_supplier_type   VARCHAR(20) DEFAULT 'AMBOS',
    p_activity_code   VARCHAR(30) DEFAULT NULL,
    p_retention_type  VARCHAR(20) DEFAULT 'ISLR',
    p_rate            NUMERIC(8,4) DEFAULT 0,
    p_subtrahend_ut   NUMERIC(8,4) DEFAULT 0,
    p_min_base_ut     NUMERIC(8,4) DEFAULT 0,
    p_seniat_code     VARCHAR(10) DEFAULT NULL,
    OUT p_resultado    INT,
    OUT p_mensaje      TEXT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
    p_resultado := 0;
    IF EXISTS (SELECT 1 FROM fiscal."WithholdingConcept" WHERE "CompanyId"=p_company_id AND "CountryCode"=p_country_code AND "ConceptCode"=p_concept_code AND "IsDeleted"=FALSE) THEN
        UPDATE fiscal."WithholdingConcept"
        SET "Description"=p_description, "SupplierType"=p_supplier_type, "ActivityCode"=p_activity_code,
            "RetentionType"=p_retention_type, "Rate"=p_rate, "SubtrahendUT"=p_subtrahend_ut,
            "MinBaseUT"=p_min_base_ut, "SeniatCode"=p_seniat_code, "UpdatedAt"=(NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"=p_company_id AND "CountryCode"=p_country_code AND "ConceptCode"=p_concept_code;
        p_resultado := 1; p_mensaje := 'Concepto actualizado';
    ELSE
        INSERT INTO fiscal."WithholdingConcept"("CompanyId","CountryCode","ConceptCode","Description","SupplierType","ActivityCode","RetentionType","Rate","SubtrahendUT","MinBaseUT","SeniatCode")
        VALUES(p_company_id, p_country_code, p_concept_code, p_description, p_supplier_type, p_activity_code, p_retention_type, p_rate, p_subtrahend_ut, p_min_base_ut, p_seniat_code);
        p_resultado := 1; p_mensaje := 'Concepto creado';
    END IF;
END; $$;

-- =============================================================================
-- 5. usp_Cfg_TaxUnit_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Cfg_TaxUnit_List(VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_TaxUnit_List(
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_tax_year     INT DEFAULT NULL
)
RETURNS TABLE("TaxUnitId" INT, "CountryCode" CHAR(2), "TaxYear" INT, "UnitValue" NUMERIC(18,4), "Currency" CHAR(3), "EffectiveDate" DATE, "IsActive" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT tu."TaxUnitId", tu."CountryCode", tu."TaxYear", tu."UnitValue", tu."Currency", tu."EffectiveDate", tu."IsActive"
    FROM cfg."TaxUnit" tu
    WHERE (p_country_code IS NULL OR tu."CountryCode" = p_country_code)
      AND (p_tax_year IS NULL OR tu."TaxYear" = p_tax_year)
    ORDER BY tu."CountryCode", tu."TaxYear" DESC, tu."EffectiveDate" DESC;
END; $$;

-- =============================================================================
-- 6. usp_Cfg_TaxUnit_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Cfg_TaxUnit_Upsert(VARCHAR, INT, NUMERIC, VARCHAR, DATE, INT, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_TaxUnit_Upsert(
    p_country_code  VARCHAR(2),
    p_tax_year      INT,
    p_unit_value    NUMERIC(18,4),
    p_currency      VARCHAR(3) DEFAULT 'VES',
    p_effective_date DATE DEFAULT NULL,
    OUT p_resultado  INT,
    OUT p_mensaje    TEXT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
    p_resultado := 0;
    IF p_effective_date IS NULL THEN p_effective_date := (p_tax_year || '-01-01')::DATE; END IF;

    IF EXISTS (SELECT 1 FROM cfg."TaxUnit" WHERE "CountryCode"=p_country_code AND "TaxYear"=p_tax_year AND "EffectiveDate"=p_effective_date) THEN
        UPDATE cfg."TaxUnit" SET "UnitValue"=p_unit_value, "Currency"=p_currency, "UpdatedAt"=(NOW() AT TIME ZONE 'UTC')
        WHERE "CountryCode"=p_country_code AND "TaxYear"=p_tax_year AND "EffectiveDate"=p_effective_date;
        p_resultado := 1; p_mensaje := 'UT actualizada';
    ELSE
        INSERT INTO cfg."TaxUnit"("CountryCode","TaxYear","UnitValue","Currency","EffectiveDate")
        VALUES(p_country_code, p_tax_year, p_unit_value, p_currency, p_effective_date);
        p_resultado := 1; p_mensaje := 'UT creada';
    END IF;
END; $$;

DO $$ BEGIN RAISE NOTICE '>>> usp_fiscal_retenciones.sql ejecutado correctamente <<<'; END $$;
