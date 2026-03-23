-- Hotfix: DROP CASCADE + recrear funciones sec
-- Ejecutar como superuser postgres

-- 1. Asegurar columnas
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Branch' AND column_name='CountryCode') THEN
    ALTER TABLE cfg."Branch" ADD COLUMN "CountryCode" CHAR(2) NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Country' AND column_name='TimeZoneIana') THEN
    ALTER TABLE cfg."Country" ADD COLUMN "TimeZoneIana" VARCHAR(64) NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Company' AND column_name='TradeName') THEN
    ALTER TABLE cfg."Company" ADD COLUMN "TradeName" VARCHAR(200) NULL;
  END IF;
END $$;

-- 2. DROP todas las versiones posibles (con CASCADE)
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default() CASCADE;
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(varchar) CASCADE;
DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(varchar) CASCADE;

-- 3. Recrear con tipos exactos (character varying, integer, boolean)
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
    COALESCE(NULLIF(c."TradeName"::VARCHAR, ''::VARCHAR), c."LegalName"::VARCHAR)::character varying,
    b."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode"::VARCHAR, ''::VARCHAR), c."FiscalCountryCode"::VARCHAR))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana"::VARCHAR, ''::VARCHAR),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR))
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
  LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR)) AND ct."IsActive" = TRUE
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
    COALESCE(NULLIF(c."TradeName"::VARCHAR, ''::VARCHAR), c."LegalName"::VARCHAR)::character varying,
    b."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode"::VARCHAR, ''::VARCHAR), c."FiscalCountryCode"::VARCHAR))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana"::VARCHAR, ''::VARCHAR),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR))
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
  LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR)) AND ct."IsActive" = TRUE
  WHERE uca."CodUsuario" = p_cod_usuario AND uca."IsActive" = TRUE AND c."IsActive" = TRUE AND c."IsDeleted" = FALSE
  ORDER BY CASE WHEN uca."IsDefault" = TRUE THEN 0 ELSE 1 END, c."CompanyId", b."BranchId";
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
    COALESCE(NULLIF(c."TradeName"::VARCHAR, ''::VARCHAR), c."LegalName"::VARCHAR)::character varying,
    a."BranchId"::integer,
    b."BranchCode"::character varying,
    b."BranchName"::character varying,
    UPPER(COALESCE(NULLIF(b."CountryCode"::VARCHAR, ''::VARCHAR), c."FiscalCountryCode"::VARCHAR))::character varying,
    COALESCE(
      NULLIF(ct."TimeZoneIana"::VARCHAR, ''::VARCHAR),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR))
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
  LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"::VARCHAR)) AND ct."IsActive" = TRUE
  WHERE UPPER(a."CodUsuario") = UPPER(p_cod_usuario) AND a."IsActive" = TRUE
  ORDER BY CASE WHEN a."IsDefault" = TRUE THEN 0 ELSE 1 END, a."CompanyId", a."BranchId";
EXCEPTION WHEN OTHERS THEN
  RETURN;
END;
$$;

-- 4. Ownership
ALTER FUNCTION public.usp_sec_user_listcompanyaccesses_default() OWNER TO zentto_app;
ALTER FUNCTION public.usp_sec_user_listcompanyaccesses(character varying) OWNER TO zentto_app;
ALTER FUNCTION public.usp_sec_user_getcompanyaccesses(character varying) OWNER TO zentto_app;

-- 5. Matar conexiones activas para forzar reconexión (limpia cached plans)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
  AND usename = 'zentto_app';

DO $$ BEGIN RAISE NOTICE 'Hotfix sec functions v3: OK (connections reset)'; END $$;
