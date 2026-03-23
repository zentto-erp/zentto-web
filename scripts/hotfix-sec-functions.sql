-- Hotfix: Asegurar columnas y recrear funciones sec
-- Ejecutar como superuser: su -c "psql -d zentto_prod -f hotfix-sec-functions.sql" postgres

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Branch' AND column_name='CountryCode') THEN
    ALTER TABLE cfg."Branch" ADD COLUMN "CountryCode" CHAR(2) NULL;
    RAISE NOTICE 'Added Branch.CountryCode';
  ELSE
    RAISE NOTICE 'Branch.CountryCode already exists';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Country' AND column_name='TimeZoneIana') THEN
    ALTER TABLE cfg."Country" ADD COLUMN "TimeZoneIana" VARCHAR(64) NULL;
    RAISE NOTICE 'Added Country.TimeZoneIana';
  ELSE
    RAISE NOTICE 'Country.TimeZoneIana already exists';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='cfg' AND table_name='Company' AND column_name='TradeName') THEN
    ALTER TABLE cfg."Company" ADD COLUMN "TradeName" VARCHAR(200) NULL;
    RAISE NOTICE 'Added Company.TradeName';
  ELSE
    RAISE NOTICE 'Company.TradeName already exists';
  END IF;
END $$;

DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(VARCHAR);
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default();

CREATE OR REPLACE FUNCTION public.usp_sec_user_listcompanyaccesses(p_cod_usuario VARCHAR)
RETURNS TABLE("companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR, "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR, "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c."CompanyId", c."CompanyCode",
    COALESCE(NULLIF(c."TradeName",''),c."LegalName")::VARCHAR,
    b."BranchId", b."BranchCode", b."BranchName",
    UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode"))::VARCHAR,
    COALESCE(NULLIF(ct."TimeZoneIana",''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode"))
        WHEN 'VE' THEN 'America/Caracas' WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'CO' THEN 'America/Bogota' WHEN 'MX' THEN 'America/Mexico_City'
        ELSE 'UTC' END)::VARCHAR,
    COALESCE(uca."IsDefault",FALSE)
  FROM sec."UserCompanyAccess" uca
  JOIN cfg."Company" c ON c."CompanyId"=uca."CompanyId"
  JOIN cfg."Branch" b ON b."BranchId"=uca."BranchId"
  LEFT JOIN cfg."Country" ct ON ct."CountryCode"=UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode")) AND ct."IsActive"=TRUE
  WHERE uca."CodUsuario"=p_cod_usuario AND uca."IsActive"=TRUE AND c."IsActive"=TRUE AND c."IsDeleted"=FALSE
  ORDER BY CASE WHEN uca."IsDefault"=TRUE THEN 0 ELSE 1 END, c."CompanyId", b."BranchId";
END;
$$;

CREATE OR REPLACE FUNCTION public.usp_sec_user_listcompanyaccesses_default()
RETURNS TABLE("companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR, "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR, "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c."CompanyId", c."CompanyCode",
    COALESCE(NULLIF(c."TradeName",''),c."LegalName")::VARCHAR,
    b."BranchId", b."BranchCode", b."BranchName",
    UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode"))::VARCHAR,
    COALESCE(NULLIF(ct."TimeZoneIana",''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode"))
        WHEN 'VE' THEN 'America/Caracas' WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'CO' THEN 'America/Bogota' WHEN 'MX' THEN 'America/Mexico_City'
        ELSE 'UTC' END)::VARCHAR,
    (c."CompanyCode"='DEFAULT' AND b."BranchCode"='MAIN')
  FROM cfg."Company" c
  JOIN cfg."Branch" b ON b."CompanyId"=c."CompanyId"
  LEFT JOIN cfg."Country" ct ON ct."CountryCode"=UPPER(COALESCE(NULLIF(b."CountryCode",''),c."FiscalCountryCode")) AND ct."IsActive"=TRUE
  WHERE c."IsActive"=TRUE AND c."IsDeleted"=FALSE
  ORDER BY c."CompanyId", b."BranchId";
END;
$$;

ALTER FUNCTION public.usp_sec_user_listcompanyaccesses(VARCHAR) OWNER TO zentto_app;
ALTER FUNCTION public.usp_sec_user_listcompanyaccesses_default() OWNER TO zentto_app;

DO $$ BEGIN RAISE NOTICE 'Hotfix sec functions: OK'; END $$;
