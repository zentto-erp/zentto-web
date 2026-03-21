\echo '  [016] Fix bpchar CountryCode en usp_pay_companyconfig_listbycompany...'

-- pay."CompanyPaymentConfig"."CountryCode" es character(2)/bpchar en producción
-- pero RETURNS TABLE lo declara como character varying.
-- Fix: agregar ::VARCHAR cast en el SELECT.

DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
RETURNS TABLE(
    "Id"              INTEGER,
    "EmpresaId"       INTEGER,
    "SucursalId"      INTEGER,
    "CountryCode"     CHARACTER VARYING,
    "ProviderId"      INTEGER,
    "ProviderCode"    CHARACTER VARYING,
    "ProviderName"    CHARACTER VARYING,
    "ProviderType"    CHARACTER VARYING,
    "Environment"     CHARACTER VARYING,
    "ClientId"        CHARACTER VARYING,
    "ClientSecret"    CHARACTER VARYING,
    "MerchantId"      CHARACTER VARYING,
    "TerminalId"      CHARACTER VARYING,
    "IntegratorId"    CHARACTER VARYING,
    "CertificatePath" CHARACTER VARYING,
    "ExtraConfig"     CHARACTER VARYING,
    "AutoCapture"     BOOLEAN,
    "AllowRefunds"    BOOLEAN,
    "MaxRefundDays"   INTEGER,
    "IsActive"        BOOLEAN,
    "CreatedAt"       TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"       TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc."Id", cc."EmpresaId", cc."SucursalId",
        cc."CountryCode"::VARCHAR,   -- FIX: bpchar(2) → varchar
        cc."ProviderId", p."Code", p."Name", p."ProviderType",
        cc."Environment", cc."ClientId", cc."ClientSecret",
        cc."MerchantId", cc."TerminalId", cc."IntegratorId",
        cc."CertificatePath", cc."ExtraConfig"::VARCHAR,   -- FIX: text → varchar
        cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
        cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$$;

\echo '  [016] COMPLETO — payments config CountryCode bpchar corregido'
