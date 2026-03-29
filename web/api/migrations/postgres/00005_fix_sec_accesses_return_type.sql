-- +goose Up

-- +goose StatementBegin
-- Fix: "structure of query does not match function result type"
-- DROP forzado + recrear con tipos exactos

DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default();
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(character varying);
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(VARCHAR);
DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(character varying);
DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(VARCHAR);

CREATE FUNCTION public.usp_sec_user_listcompanyaccesses_default()
RETURNS TABLE(
  "companyId" integer,
  "companyCode" character varying,
  "companyName" character varying,
  "branchId" integer,
  "branchCode" character varying,
  "branchName" character varying,
  "countryCode" character varying,
  "timeZone" character varying,
  "isDefault" boolean
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId"::integer,
    c."CompanyCode"::character varying,
    COALESCE(NULLIF(c."TradeName", ''), c."LegalName")::character varying,
    b."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana", ''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
        WHEN 'VE' THEN 'America/Caracas'
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'CO' THEN 'America/Bogota'
        WHEN 'MX' THEN 'America/Mexico_City'
        WHEN 'US' THEN 'America/New_York'
        ELSE 'UTC'
      END
    )::character varying,
    (c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN')::boolean
  FROM cfg."Company" c
  INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
  LEFT JOIN cfg."Country" ct
    ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
    AND ct."IsActive" = TRUE
  WHERE c."IsActive" = TRUE AND c."IsDeleted" = FALSE
  ORDER BY c."CompanyId", b."BranchId";
END;
$$;

CREATE FUNCTION public.usp_sec_user_listcompanyaccesses(p_cod_usuario character varying)
RETURNS TABLE(
  "companyId" integer,
  "companyCode" character varying,
  "companyName" character varying,
  "branchId" integer,
  "branchCode" character varying,
  "branchName" character varying,
  "countryCode" character varying,
  "timeZone" character varying,
  "isDefault" boolean
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId"::integer,
    c."CompanyCode"::character varying,
    COALESCE(NULLIF(c."TradeName", ''), c."LegalName")::character varying,
    b."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana", ''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
        WHEN 'VE' THEN 'America/Caracas'
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'CO' THEN 'America/Bogota'
        WHEN 'MX' THEN 'America/Mexico_City'
        WHEN 'US' THEN 'America/New_York'
        ELSE 'UTC'
      END
    )::character varying,
    COALESCE(uca."IsDefault", FALSE)::boolean
  FROM sec."UserCompanyAccess" uca
  INNER JOIN cfg."Company" c ON c."CompanyId" = uca."CompanyId"
  INNER JOIN cfg."Branch" b ON b."BranchId" = uca."BranchId"
  LEFT JOIN cfg."Country" ct
    ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
    AND ct."IsActive" = TRUE
  WHERE uca."CodUsuario" = p_cod_usuario
    AND uca."IsActive" = TRUE
    AND c."IsActive" = TRUE AND c."IsDeleted" = FALSE
  ORDER BY
    CASE WHEN uca."IsDefault" = TRUE THEN 0 ELSE 1 END,
    c."CompanyId", b."BranchId";
END;
$$;

CREATE FUNCTION public.usp_sec_user_getcompanyaccesses(p_cod_usuario character varying)
RETURNS TABLE(
  "companyId" integer,
  "companyCode" character varying,
  "companyName" character varying,
  "branchId" integer,
  "branchCode" character varying,
  "branchName" character varying,
  "countryCode" character varying,
  "timeZone" character varying,
  "isDefault" boolean
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    a."CompanyId"::integer,
    c."CompanyCode"::character varying,
    COALESCE(NULLIF(c."TradeName", ''), c."LegalName")::character varying,
    a."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana", ''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
        WHEN 'VE' THEN 'America/Caracas'
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'CO' THEN 'America/Bogota'
        WHEN 'MX' THEN 'America/Mexico_City'
        WHEN 'US' THEN 'America/New_York'
        ELSE 'UTC'
      END
    )::character varying,
    a."IsDefault"::boolean
  FROM sec."UserCompanyAccess" a
  INNER JOIN cfg."Company" c ON c."CompanyId" = a."CompanyId" AND c."IsActive" = TRUE AND c."IsDeleted" = FALSE
  INNER JOIN cfg."Branch" b ON b."BranchId" = a."BranchId" AND b."CompanyId" = a."CompanyId" AND b."IsActive" = TRUE AND b."IsDeleted" = FALSE
  LEFT JOIN cfg."Country" ct
    ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
    AND ct."IsActive" = TRUE
  WHERE UPPER(a."CodUsuario") = UPPER(p_cod_usuario)
    AND a."IsActive" = TRUE
  ORDER BY
    CASE WHEN a."IsDefault" = TRUE THEN 0 ELSE 1 END,
    a."CompanyId", a."BranchId";
EXCEPTION WHEN OTHERS THEN
  RETURN;
END;
$$;

-- Ownership
ALTER FUNCTION public.usp_sec_user_listcompanyaccesses_default() OWNER TO zentto_app;
ALTER FUNCTION public.usp_sec_user_listcompanyaccesses(character varying) OWNER TO zentto_app;
ALTER FUNCTION public.usp_sec_user_getcompanyaccesses(character varying) OWNER TO zentto_app;

-- +goose StatementEnd

-- +goose Down
SELECT 1;
