-- +goose Up
-- Fix: CHAR→VARCHAR casts, BIGINT→INT mismatches, missing p_company_id params,
-- wrong table/schema references across multiple functions

-- 1. payments/config — CountryCode CHAR(2)→VARCHAR, TIMESTAMPTZ→TIMESTAMP
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id INT, p_branch_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT, "CountryCode" VARCHAR,
    "ProviderId" INT, "ProviderCode" VARCHAR, "ProviderName" VARCHAR, "ProviderType" VARCHAR,
    "Environment" VARCHAR, "ClientId" VARCHAR, "ClientSecret" VARCHAR,
    "MerchantId" VARCHAR, "TerminalId" VARCHAR, "IntegratorId" VARCHAR,
    "CertificatePath" VARCHAR, "ExtraConfig" VARCHAR,
    "AutoCapture" BOOLEAN, "AllowRefunds" BOOLEAN, "MaxRefundDays" INT,
    "IsActive" BOOLEAN, "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."ClientId"::VARCHAR, cc."ClientSecret"::VARCHAR,
           cc."MerchantId"::VARCHAR, cc."TerminalId"::VARCHAR, cc."IntegratorId"::VARCHAR,
           cc."CertificatePath"::VARCHAR, cc."ExtraConfig"::VARCHAR,
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt"::TIMESTAMP, cc."UpdatedAt"::TIMESTAMP
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$fn$;

-- 2. retenciones/{codigo} — CountryCode CHAR(2)→VARCHAR
DROP FUNCTION IF EXISTS public.usp_tax_retention_getbycode(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tax_retention_getbycode(p_codigo VARCHAR)
RETURNS TABLE(
    "RetentionId" INT, "RetentionCode" VARCHAR, "Description" VARCHAR,
    "RetentionType" VARCHAR, "RetentionRate" NUMERIC, "CountryCode" VARCHAR, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT tr."RetentionId", tr."RetentionCode"::VARCHAR, tr."Description"::VARCHAR,
           tr."RetentionType"::VARCHAR, tr."RetentionRate", tr."CountryCode"::VARCHAR, tr."IsActive"
    FROM master."TaxRetention" tr
    WHERE tr."RetentionCode" = p_codigo AND tr."IsDeleted" = FALSE
    LIMIT 1;
END;
$fn$;

-- 3. vendedores/{codigo} — Direccion→Address, Telefonos→Phone
DROP FUNCTION IF EXISTS public.usp_vendedores_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_vendedores_getbycodigo(p_codigo VARCHAR)
RETURNS TABLE(
    "Codigo" VARCHAR, "Nombre" VARCHAR, "Comision" NUMERIC, "Status" BOOLEAN,
    "IsActive" BOOLEAN, "IsDeleted" BOOLEAN, "CompanyId" INT,
    "SellerCode" VARCHAR, "SellerName" VARCHAR, "Commission" NUMERIC,
    "Direccion" VARCHAR, "Telefonos" VARCHAR, "Email" VARCHAR,
    "Tipo" VARCHAR, "Clave" VARCHAR,
    "RangoVentasUno" NUMERIC, "ComisionVentasUno" NUMERIC,
    "RangoVentasDos" NUMERIC, "ComisionVentasDos" NUMERIC,
    "RangoVentasTres" NUMERIC, "ComisionVentasTres" NUMERIC,
    "RangoVentasCuatro" NUMERIC, "ComisionVentasCuatro" NUMERIC
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        s."SellerCode"::VARCHAR, s."SellerName"::VARCHAR, s."Commission", s."IsActive",
        s."IsActive", s."IsDeleted", s."CompanyId",
        s."SellerCode"::VARCHAR, s."SellerName"::VARCHAR, s."Commission",
        s."Address"::VARCHAR, s."Phone"::VARCHAR, s."Email"::VARCHAR,
        s."SellerType"::VARCHAR, ''::VARCHAR,
        0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC,
        0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$fn$;

-- 4. centro-costo/{codigo} — public.Centro_Costo→master.CostCenter
DROP FUNCTION IF EXISTS public.usp_centrocosto_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_centrocosto_getbycodigo(p_codigo VARCHAR)
RETURNS TABLE("Codigo" VARCHAR, "Descripcion" VARCHAR, "Presupuestado" NUMERIC, "Saldo_Real" NUMERIC)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT cc."CostCenterCode"::VARCHAR, cc."CostCenterName"::VARCHAR, 0::NUMERIC, 0::NUMERIC
    FROM master."CostCenter" cc
    WHERE cc."CostCenterCode" = p_codigo AND COALESCE(cc."IsDeleted", FALSE) = FALSE;
END;
$fn$;

-- 5. empresa — public.Empresa→cfg.Company
DROP FUNCTION IF EXISTS public.usp_empresa_get() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_empresa_get()
RETURNS TABLE("Empresa" VARCHAR, "RIF" VARCHAR, "Nit" VARCHAR, "Telefono" VARCHAR, "Direccion" VARCHAR, "Rifs" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT c."TradeName"::VARCHAR, c."FiscalId"::VARCHAR, ''::VARCHAR,
           c."Phone"::VARCHAR, c."Address"::VARCHAR, c."FiscalId"::VARCHAR
    FROM cfg."Company" c LIMIT 1;
END;
$fn$;

-- 6. movinvent/mes — SummaryId BIGINT→INT
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo VARCHAR, p_codigo VARCHAR, p_offset INT, p_limit INT
)
RETURNS TABLE(
    "SummaryId" INT, "Period" VARCHAR, "ProductCode" VARCHAR,
    "OpeningQty" NUMERIC, "InboundQty" NUMERIC, "OutboundQty" NUMERIC,
    "ClosingQty" NUMERIC, "SummaryDate" TIMESTAMP, "IsClosed" BOOLEAN, "TotalCount" INT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_total INT;
BEGIN
    SELECT COUNT(*)::INT INTO v_total FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period" = p_periodo) AND (p_codigo IS NULL OR s."ProductCode" = p_codigo);
    RETURN QUERY
    SELECT s."SummaryId"::INT, s."Period"::VARCHAR, s."ProductCode"::VARCHAR,
           s."OpeningQty", s."InboundQty", s."OutboundQty",
           s."ClosingQty", s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period" = p_periodo) AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode" LIMIT p_limit OFFSET p_offset;
END;
$fn$;

-- 7. fideicomiso/summary — p_fiscal_year→p_year, flat rows
DROP FUNCTION IF EXISTS public.usp_hr_trust_getsummary(INT, INT, SMALLINT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_trust_getsummary(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_trust_getsummary(
    p_company_id INT, p_year INT, p_quarter INT
)
RETURNS TABLE(
    "TotalEmployees" BIGINT, "TotalDeposits" NUMERIC, "TotalInterest" NUMERIC,
    "TotalBonusDays" NUMERIC, "TotalAccumulatedBalance" NUMERIC, "Status" VARCHAR
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT COUNT(*)::BIGINT, COALESCE(SUM(t."DepositAmount"),0::NUMERIC),
           COALESCE(SUM(t."InterestAmount"),0::NUMERIC), COALESCE(SUM(t."BonusDays"),0::NUMERIC),
           COALESCE(SUM(t."AccumulatedBalance"),0::NUMERIC), t."Status"::VARCHAR
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_year AND t."Quarter" = p_quarter
    GROUP BY t."Status";
END;
$fn$;

-- 8-9. clientes — agregar p_company_id
DROP FUNCTION IF EXISTS public.usp_clientes_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_list(
    p_company_id INT DEFAULT NULL, p_search VARCHAR DEFAULT NULL,
    p_estado VARCHAR DEFAULT NULL, p_vendedor VARCHAR DEFAULT NULL,
    p_page INT DEFAULT 1, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "CODIGO" VARCHAR, "NOMBRE" VARCHAR, "RIF" VARCHAR,
    "SALDO_TOT" DOUBLE PRECISION, "LIMITE" DOUBLE PRECISION,
    "IsActive" BOOLEAN, "IsDeleted" BOOLEAN, "CompanyId" INT,
    "CustomerCode" VARCHAR, "CustomerName" VARCHAR, "FiscalId" VARCHAR,
    "TotalBalance" DOUBLE PRECISION, "CreditLimit" DOUBLE PRECISION,
    "NIT" VARCHAR, "Direccion" VARCHAR, "Telefono" VARCHAR,
    "Contacto" VARCHAR, "SalespersonCode" VARCHAR, "PriceListCode" VARCHAR,
    "Ciudad" VARCHAR, "CodPostal" VARCHAR, "Email" VARCHAR,
    "PaginaWww" VARCHAR, "CodUsuario" VARCHAR, "Credito" DOUBLE PRECISION,
    "TotalCount" INT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_offset INT; v_limit INT; v_search VARCHAR(100); v_total INT;
BEGIN
    v_limit := COALESCE(NULLIF(p_limit,0),50);
    IF v_limit<1 THEN v_limit:=50; END IF; IF v_limit>500 THEN v_limit:=500; END IF;
    v_offset := (COALESCE(NULLIF(p_page,0),1)-1)*v_limit; IF v_offset<0 THEN v_offset:=0; END IF;
    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search)<>'' THEN v_search:='%'||p_search||'%'; END IF;
    SELECT COUNT(1) INTO v_total FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted",FALSE)=FALSE AND (p_company_id IS NULL OR c."CompanyId"=p_company_id)
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR COALESCE(c."FiscalId",''::VARCHAR) ILIKE v_search));
    RETURN QUERY
    SELECT c."CustomerCode"::VARCHAR, c."CustomerName"::VARCHAR, COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION, COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        c."IsActive", c."IsDeleted", c."CompanyId",
        c."CustomerCode"::VARCHAR, c."CustomerName"::VARCHAR, COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION, COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        NULL::VARCHAR, COALESCE(c."AddressLine",''::VARCHAR)::VARCHAR, COALESCE(c."Phone",''::VARCHAR)::VARCHAR,
        NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR,
        COALESCE(c."Email",''::VARCHAR)::VARCHAR, NULL::VARCHAR, NULL::VARCHAR,
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION, v_total
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted",FALSE)=FALSE AND (p_company_id IS NULL OR c."CompanyId"=p_company_id)
      AND (v_search IS NULL OR (c."CustomerCode" ILIKE v_search OR c."CustomerName" ILIKE v_search OR COALESCE(c."FiscalId",''::VARCHAR) ILIKE v_search))
    ORDER BY c."CustomerCode" LIMIT v_limit OFFSET v_offset;
END;
$fn$;

DROP FUNCTION IF EXISTS public.usp_clientes_getbycodigo(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_clientes_getbycodigo(
    p_company_id INT DEFAULT NULL, p_codigo VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "CODIGO" VARCHAR, "NOMBRE" VARCHAR, "RIF" VARCHAR,
    "SALDO_TOT" DOUBLE PRECISION, "LIMITE" DOUBLE PRECISION,
    "IsActive" BOOLEAN, "IsDeleted" BOOLEAN, "CompanyId" INT,
    "CustomerCode" VARCHAR, "CustomerName" VARCHAR, "FiscalId" VARCHAR,
    "TotalBalance" DOUBLE PRECISION, "CreditLimit" DOUBLE PRECISION,
    "NIT" VARCHAR, "Direccion" VARCHAR, "Telefono" VARCHAR,
    "Contacto" VARCHAR, "SalespersonCode" VARCHAR, "PriceListCode" VARCHAR,
    "Ciudad" VARCHAR, "CodPostal" VARCHAR, "Email" VARCHAR,
    "PaginaWww" VARCHAR, "CodUsuario" VARCHAR, "Credito" DOUBLE PRECISION,
    "TotalCount" INT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT c."CustomerCode"::VARCHAR, c."CustomerName"::VARCHAR, COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION, COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        c."IsActive", c."IsDeleted", c."CompanyId",
        c."CustomerCode"::VARCHAR, c."CustomerName"::VARCHAR, COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION, COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        NULL::VARCHAR, COALESCE(c."AddressLine",''::VARCHAR)::VARCHAR, COALESCE(c."Phone",''::VARCHAR)::VARCHAR,
        NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR,
        COALESCE(c."Email",''::VARCHAR)::VARCHAR, NULL::VARCHAR, NULL::VARCHAR,
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION, 1
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_codigo AND COALESCE(c."IsDeleted",FALSE)=FALSE LIMIT 1;
END;
$fn$;

-- 10-11. document templates — TemplateId INT→BIGINT, CountryCode CHAR→VARCHAR
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_list(INT, CHARACTER, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_list(INT, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_list(
    p_company_id INT, p_country_code VARCHAR DEFAULT NULL, p_template_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "TemplateId" BIGINT, "TemplateCode" VARCHAR, "TemplateName" VARCHAR,
    "TemplateType" VARCHAR, "CountryCode" VARCHAR, "PayrollCode" VARCHAR,
    "IsDefault" BOOLEAN, "IsSystem" BOOLEAN, "IsActive" BOOLEAN, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT t."TemplateId", t."TemplateCode"::VARCHAR, t."TemplateName"::VARCHAR,
           t."TemplateType"::VARCHAR, t."CountryCode"::VARCHAR, t."PayrollCode"::VARCHAR,
           t."IsDefault", t."IsSystem", t."IsActive", t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id AND t."IsActive" = TRUE
      AND (p_country_code IS NULL OR t."CountryCode" = p_country_code)
      AND (p_template_type IS NULL OR t."TemplateType" = p_template_type)
    ORDER BY t."CountryCode", t."TemplateType", t."TemplateName";
END;
$fn$;

DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_get(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(
    p_company_id INT, p_template_code VARCHAR
)
RETURNS TABLE(
    "TemplateId" BIGINT, "TemplateCode" VARCHAR, "TemplateName" VARCHAR,
    "TemplateType" VARCHAR, "CountryCode" VARCHAR, "PayrollCode" VARCHAR,
    "ContentMD" TEXT, "IsDefault" BOOLEAN, "IsSystem" BOOLEAN, "IsActive" BOOLEAN,
    "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT t."TemplateId", t."TemplateCode"::VARCHAR, t."TemplateName"::VARCHAR,
           t."TemplateType"::VARCHAR, t."CountryCode"::VARCHAR, t."PayrollCode"::VARCHAR,
           t."ContentMD", t."IsDefault", t."IsSystem", t."IsActive", t."CreatedAt", t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id AND t."TemplateCode" = p_template_code;
END;
$fn$;

-- Save function — p_country_code CHAR→VARCHAR
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_save(INT, VARCHAR, VARCHAR, VARCHAR, CHARACTER, TEXT, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_save(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_save(
    p_company_id INT, p_template_code VARCHAR, p_template_name VARCHAR,
    p_template_type VARCHAR, p_country_code VARCHAR, p_content_md TEXT,
    p_payroll_code VARCHAR DEFAULT NULL, p_is_default BOOLEAN DEFAULT FALSE,
    OUT p_resultado INT, OUT p_mensaje TEXT
)
LANGUAGE plpgsql AS $fn$
DECLARE v_id BIGINT;
BEGIN
    p_resultado := 0; p_mensaje := '';
    IF EXISTS (SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId" = p_company_id AND "TemplateCode" = p_template_code AND "IsSystem" = TRUE
    ) THEN
        p_resultado := -1; p_mensaje := 'No se puede modificar una plantilla del sistema.'; RETURN;
    END IF;
    INSERT INTO hr."DocumentTemplate"(
        "CompanyId","TemplateCode","TemplateName","TemplateType","CountryCode","PayrollCode",
        "ContentMD","IsDefault","IsSystem","IsActive","CreatedAt","UpdatedAt"
    ) VALUES (
        p_company_id, p_template_code, p_template_name, p_template_type,
        p_country_code, p_payroll_code, p_content_md, COALESCE(p_is_default,FALSE),
        FALSE, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("CompanyId","TemplateCode") DO UPDATE
    SET "TemplateName"=EXCLUDED."TemplateName", "TemplateType"=EXCLUDED."TemplateType",
        "CountryCode"=EXCLUDED."CountryCode", "PayrollCode"=EXCLUDED."PayrollCode",
        "ContentMD"=EXCLUDED."ContentMD", "IsDefault"=EXCLUDED."IsDefault",
        "IsSystem"=FALSE, "UpdatedAt"=NOW() AT TIME ZONE 'UTC';
    p_resultado := 1; p_mensaje := 'Plantilla guardada correctamente.';
END;
$fn$;

-- +goose Down
-- No rollback needed — these are type-safety fixes
