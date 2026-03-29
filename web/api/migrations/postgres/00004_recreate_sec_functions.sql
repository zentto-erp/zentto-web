-- +goose Up

-- +goose StatementBegin
-- Recrear funciones sec que dependen de columnas aÃƒÂ±adidas en 00003.
-- Las funciones existentes pueden estar "rotas" si fueron compiladas
-- antes de que las columnas existieran.

-- Recrear usp_sec_user_listcompanyaccesses (versiÃƒÂ³n con parÃƒÂ¡metro)
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(VARCHAR);
CREATE OR REPLACE FUNCTION public.usp_sec_user_listcompanyaccesses(p_cod_usuario VARCHAR)
RETURNS TABLE(
  "companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR,
  "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR,
  "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId",
    c."CompanyCode",
    COALESCE(NULLIF(c."TradeName", ''), c."LegalName")::VARCHAR,
    b."BranchId",
    b."BranchCode",
    b."BranchName",
    UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::VARCHAR,
    COALESCE(
      NULLIF(ct."TimeZoneIana", ''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'VE' THEN 'America/Caracas'
        WHEN 'CO' THEN 'America/Bogota'
        WHEN 'MX' THEN 'America/Mexico_City'
        WHEN 'US' THEN 'America/New_York'
        ELSE 'UTC'
      END
    )::VARCHAR,
    COALESCE(uca."IsDefault", FALSE)
  FROM sec."UserCompanyAccess" uca
  INNER JOIN cfg."Company" c ON c."CompanyId" = uca."CompanyId"
  INNER JOIN cfg."Branch" b ON b."BranchId" = uca."BranchId"
  LEFT JOIN cfg."Country" ct
    ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
    AND ct."IsActive" = TRUE
  WHERE uca."CodUsuario" = p_cod_usuario
    AND uca."IsActive" = TRUE
    AND c."IsActive" = TRUE
    AND c."IsDeleted" = FALSE
  ORDER BY
    CASE WHEN uca."IsDefault" = TRUE THEN 0 ELSE 1 END,
    c."CompanyId", b."BranchId";
END;
$$;

-- Recrear usp_sec_user_listcompanyaccesses_default (versiÃƒÂ³n sin parÃƒÂ¡metro)
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default();
CREATE OR REPLACE FUNCTION public.usp_sec_user_listcompanyaccesses_default()
RETURNS TABLE(
  "companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR,
  "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR,
  "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId",
    c."CompanyCode",
    COALESCE(NULLIF(c."TradeName", ''), c."LegalName")::VARCHAR,
    b."BranchId",
    b."BranchCode",
    b."BranchName",
    UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::VARCHAR,
    COALESCE(
      NULLIF(ct."TimeZoneIana", ''),
      CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'VE' THEN 'America/Caracas'
        WHEN 'CO' THEN 'America/Bogota'
        WHEN 'MX' THEN 'America/Mexico_City'
        WHEN 'US' THEN 'America/New_York'
        ELSE 'UTC'
      END
    )::VARCHAR,
    (c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN')
  FROM cfg."Company" c
  INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
  LEFT JOIN cfg."Country" ct
    ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))
    AND ct."IsActive" = TRUE
  WHERE c."IsActive" = TRUE
    AND c."IsDeleted" = FALSE
  ORDER BY c."CompanyId", b."BranchId";
END;
$$;

-- +goose StatementEnd

-- +goose Down
-- Las funciones se mantienen (se sobreescribirÃƒÂ¡n en futuras migraciones)
SELECT 1;
