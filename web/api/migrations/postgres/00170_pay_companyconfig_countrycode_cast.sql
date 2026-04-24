-- +goose Up
-- +goose StatementBegin

-- usp_pay_companyconfig_list / usp_pay_companyconfig_listbycompany:
-- la tabla pay."CompanyPaymentConfig"."CountryCode" es CHAR(2) pero el
-- RETURNS TABLE de ambas funciones declara "CountryCode" character varying.
-- En tiempo de ejecucion PG lanza:
--   "Returned type character(2) does not match expected type character varying in column 4"
-- y el endpoint GET /v1/payments/config responde 500.
-- Fix: cast explicito a VARCHAR en el SELECT de ambas funciones. El tipo
-- declarado en RETURNS TABLE se mantiene (clientes consumen varchar).

CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_list(
    p_company_id integer DEFAULT NULL::integer
)
RETURNS TABLE(
    "Id" integer,
    "EmpresaId" integer,
    "SucursalId" integer,
    "CountryCode" character varying,
    "ProviderId" integer,
    "ProviderCode" character varying,
    "ProviderName" character varying,
    "ProviderType" character varying,
    "Environment" character varying,
    "AutoCapture" boolean,
    "AllowRefunds" boolean,
    "MaxRefundDays" integer,
    "IsActive" boolean,
    "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId",
           cc."CountryCode"::varchar,
           cc."ProviderId",
           p."Code"::varchar, p."Name"::varchar, p."ProviderType"::varchar,
           cc."Environment", cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$$;

CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id integer DEFAULT NULL::integer
)
RETURNS TABLE(
    "Id" integer,
    "EmpresaId" integer,
    "SucursalId" integer,
    "CountryCode" character varying,
    "ProviderId" integer,
    "ProviderCode" character varying,
    "ProviderName" character varying,
    "ProviderType" character varying,
    "Environment" character varying,
    "ClientId" character varying,
    "ClientSecret" character varying,
    "MerchantId" character varying,
    "TerminalId" character varying,
    "IntegratorId" character varying,
    "CertificatePath" character varying,
    "ExtraConfig" text,
    "AutoCapture" boolean,
    "AllowRefunds" boolean,
    "MaxRefundDays" integer,
    "IsActive" boolean,
    "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId",
           cc."CountryCode"::varchar,
           cc."ProviderId",
           p."Code"::varchar, p."Name"::varchar, p."ProviderType"::varchar,
           cc."Environment", cc."ClientId", cc."ClientSecret",
           cc."MerchantId", cc."TerminalId", cc."IntegratorId",
           cc."CertificatePath", cc."ExtraConfig",
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$$;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Down no revierte: el cast es idempotente y mas correcto que la version previa.
-- Dejar un no-op para que goose down no rompa.
SELECT 1;
-- +goose StatementEnd
