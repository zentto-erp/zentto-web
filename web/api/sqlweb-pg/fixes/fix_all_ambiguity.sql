-- ============================================================
-- fix_all_ambiguity.sql
-- Fix ALL column ambiguity issues in PostgreSQL functions
-- Run as: psql -U zentto_app -d zentto_prod -f fix_all_ambiguity.sql
-- ============================================================

-- 1. usp_acct_costcenter_list
DROP FUNCTION IF EXISTS usp_acct_costcenter_list(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_costcenter_list(
  p_company_id INT,
  p_search     VARCHAR DEFAULT NULL,
  p_page       INT DEFAULT 1,
  p_limit      INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount"         BIGINT,
  "CostCenterId"       INT,
  "CostCenterCode"     VARCHAR,
  "CostCenterName"     VARCHAR,
  "ParentCostCenterId" INT,
  "Level"              SMALLINT,
  "IsActive"           BOOLEAN
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
  IF p_page < 1    THEN p_page  := 1;   END IF;
  IF p_limit < 1   THEN p_limit := 50;  END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  SELECT COUNT(*) INTO v_total
  FROM acct."CostCenter" cc2
  WHERE cc2."CompanyId" = p_company_id
    AND cc2."IsDeleted" = FALSE
    AND (p_search IS NULL
         OR cc2."CostCenterCode" ILIKE '%' || p_search || '%'
         OR cc2."CostCenterName"  ILIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT v_total, cc."CostCenterId", cc."CostCenterCode",
         cc."CostCenterName", cc."ParentCostCenterId",
         cc."Level", cc."IsActive"
  FROM acct."CostCenter" cc
  WHERE cc."CompanyId" = p_company_id
    AND cc."IsDeleted" = FALSE
    AND (p_search IS NULL
         OR cc."CostCenterCode" ILIKE '%' || p_search || '%'
         OR cc."CostCenterName"  ILIKE '%' || p_search || '%')
  ORDER BY cc."CostCenterCode"
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_costcenter_list(INT,VARCHAR,INT,INT) TO zentto_app;

-- 2. usp_acct_budget_list
DROP FUNCTION IF EXISTS usp_acct_budget_list(integer, smallint, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_budget_list(
  p_company_id INT,
  p_fiscal_year SMALLINT DEFAULT NULL,
  p_status      VARCHAR  DEFAULT NULL,
  p_page        INT DEFAULT 1,
  p_limit       INT DEFAULT 50
) RETURNS TABLE(
  "BudgetId"     INT,
  "CompanyId"    INT,
  "BudgetName"   VARCHAR,
  "FiscalYear"   SMALLINT,
  "Status"       VARCHAR,
  "CostCenterCode" VARCHAR,
  "Notes"        VARCHAR,
  "TotalCount"   BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT; v_offset INT;
BEGIN
  IF p_page < 1    THEN p_page  := 1;   END IF;
  IF p_limit < 1   THEN p_limit := 50;  END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;
  v_offset := (p_page - 1) * p_limit;

  SELECT COUNT(*) INTO v_total
  FROM acct."Budget" b2
  WHERE b2."CompanyId" = p_company_id
    AND b2."IsDeleted" = FALSE
    AND (p_fiscal_year IS NULL OR b2."FiscalYear" = p_fiscal_year)
    AND (p_status IS NULL OR b2."Status"::VARCHAR = p_status);

  RETURN QUERY
  SELECT b."BudgetId", b."CompanyId", b."BudgetName",
         b."FiscalYear", b."Status"::VARCHAR,
         b."CostCenterCode", b."Notes", v_total
  FROM acct."Budget" b
  WHERE b."CompanyId" = p_company_id
    AND b."IsDeleted" = FALSE
    AND (p_fiscal_year IS NULL OR b."FiscalYear" = p_fiscal_year)
    AND (p_status IS NULL OR b."Status"::VARCHAR = p_status)
  ORDER BY b."FiscalYear" DESC, b."BudgetName"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_budget_list(INT,SMALLINT,VARCHAR,INT,INT) TO zentto_app;

-- 3. usp_sys_notificacion_list (ensure TEXT)
DROP FUNCTION IF EXISTS usp_sys_notificacion_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sys_notificacion_list(
  p_usuario_id VARCHAR DEFAULT NULL
) RETURNS TABLE(
  "Id" INT, "Tipo" VARCHAR, "Titulo" VARCHAR, "Mensaje" TEXT,
  "Leido" BOOLEAN, "FechaCreacion" TIMESTAMP, "RutaNavegacion" VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT n."Id", n."Tipo", n."Titulo", n."Mensaje"::TEXT,
         n."Leido", n."FechaCreacion", n."RutaNavegacion"
  FROM "Sys_Notificaciones" n
  WHERE n."UsuarioId" IS NULL OR n."UsuarioId" = p_usuario_id
  ORDER BY n."FechaCreacion" DESC LIMIT 50;
END; $$;
GRANT EXECUTE ON FUNCTION usp_sys_notificacion_list(VARCHAR) TO zentto_app;

-- 4. usp_sys_tarea_list (ensure TEXT)
DROP FUNCTION IF EXISTS usp_sys_tarea_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sys_tarea_list(
  p_asignado_a VARCHAR DEFAULT NULL
) RETURNS TABLE(
  "Id" INT, "Titulo" VARCHAR, "Descripcion" TEXT, "Progreso" INT,
  "Color" VARCHAR, "AsignadoA" VARCHAR, "FechaVencimiento" DATE,
  "Completado" BOOLEAN, "FechaCreacion" TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t."Id", t."Titulo", t."Descripcion"::TEXT, t."Progreso",
         t."Color", t."AsignadoA", t."FechaVencimiento",
         t."Completado", t."FechaCreacion"
  FROM "Sys_Tareas" t
  WHERE (t."AsignadoA" IS NULL OR t."AsignadoA" = p_asignado_a)
    AND t."Completado" = FALSE
  ORDER BY t."FechaCreacion" DESC LIMIT 50;
END; $$;
GRANT EXECUTE ON FUNCTION usp_sys_tarea_list(VARCHAR) TO zentto_app;

-- 5. usp_sys_mensaje_list (ensure TEXT)
DROP FUNCTION IF EXISTS usp_sys_mensaje_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sys_mensaje_list(
  p_destinatario_id VARCHAR
) RETURNS TABLE(
  "Id" INT, "RemitenteId" VARCHAR, "RemitenteNombre" VARCHAR,
  "Asunto" VARCHAR, "Cuerpo" TEXT, "Leido" BOOLEAN, "FechaEnvio" TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT m."Id", m."RemitenteId", m."RemitenteNombre",
         m."Asunto", m."Cuerpo"::TEXT, m."Leido", m."FechaEnvio"
  FROM "Sys_Mensajes" m
  WHERE m."DestinatarioId" = p_destinatario_id
  ORDER BY m."FechaEnvio" DESC LIMIT 50;
END; $$;
GRANT EXECUTE ON FUNCTION usp_sys_mensaje_list(VARCHAR) TO zentto_app;

-- 6. usp_acct_account_list — alias a. en todas las columnas + ParentAccountId
DROP FUNCTION IF EXISTS usp_acct_account_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_list(
  p_company_id INT,
  p_search     VARCHAR DEFAULT NULL,
  p_tipo       VARCHAR DEFAULT NULL,
  p_grupo      VARCHAR DEFAULT NULL,
  p_page       INT DEFAULT 1,
  p_limit      INT DEFAULT 50
) RETURNS TABLE(
  "AccountId"       BIGINT,
  "AccountCode"     VARCHAR,
  "AccountName"     VARCHAR,
  "AccountType"     VARCHAR,
  "AccountLevel"    INT,
  "ParentAccountId" BIGINT,
  "AllowsPosting"   BOOLEAN,
  "IsActive"        BOOLEAN,
  "TotalCount"      BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_total BIGINT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * LEAST(GREATEST(p_limit, 1), 500);
  SELECT COUNT(*) INTO v_total
  FROM acct."Account" a2
  WHERE a2."CompanyId" = p_company_id AND a2."IsDeleted" = FALSE
    AND (p_search IS NULL OR a2."AccountCode" LIKE '%' || p_search || '%' OR a2."AccountName" LIKE '%' || p_search || '%')
    AND (p_tipo IS NULL OR a2."AccountType"::VARCHAR = p_tipo)
    AND (p_grupo IS NULL OR a2."AccountCode" LIKE p_grupo || '%');
  RETURN QUERY
  SELECT a."AccountId", a."AccountCode", a."AccountName", a."AccountType"::VARCHAR,
         a."AccountLevel", a."ParentAccountId", a."AllowsPosting", a."IsActive", v_total
  FROM acct."Account" a
  WHERE a."CompanyId" = p_company_id AND a."IsDeleted" = FALSE
    AND (p_search IS NULL OR a."AccountCode" LIKE '%' || p_search || '%' OR a."AccountName" LIKE '%' || p_search || '%')
    AND (p_tipo IS NULL OR a."AccountType"::VARCHAR = p_tipo)
    AND (p_grupo IS NULL OR a."AccountCode" LIKE p_grupo || '%')
  ORDER BY a."AccountCode"
  LIMIT LEAST(GREATEST(p_limit,1),500) OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_account_list(INT,VARCHAR,VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 7. usp_acct_period_list — alias fp. en todas las columnas
DROP FUNCTION IF EXISTS usp_acct_period_list(integer, smallint, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_period_list(
  p_company_id INT, p_year SMALLINT DEFAULT NULL, p_status VARCHAR DEFAULT NULL,
  p_page INT DEFAULT 1, p_limit INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount" BIGINT, "FiscalPeriodId" INT, "PeriodCode" VARCHAR, "PeriodName" VARCHAR,
  "YearCode" SMALLINT, "MonthCode" SMALLINT, "StartDate" DATE, "EndDate" DATE,
  "Status" VARCHAR, "ClosedAt" TIMESTAMP, "ClosedByUserId" INT, "Notes" VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
  IF p_page < 1 THEN p_page := 1; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;
  SELECT COUNT(*) INTO v_total FROM acct."FiscalPeriod" fp2
  WHERE fp2."CompanyId" = p_company_id
    AND (p_year IS NULL OR fp2."YearCode" = p_year)
    AND (p_status IS NULL OR fp2."Status" = p_status);
  RETURN QUERY
  SELECT v_total, fp."FiscalPeriodId", fp."PeriodCode"::VARCHAR, fp."PeriodName",
         fp."YearCode", fp."MonthCode", fp."StartDate", fp."EndDate",
         fp."Status"::VARCHAR, fp."ClosedAt", fp."ClosedByUserId", fp."Notes"
  FROM acct."FiscalPeriod" fp
  WHERE fp."CompanyId" = p_company_id
    AND (p_year IS NULL OR fp."YearCode" = p_year)
    AND (p_status IS NULL OR fp."Status" = p_status)
  ORDER BY fp."PeriodCode"
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_period_list(INT,SMALLINT,VARCHAR,INT,INT) TO zentto_app;

-- 8. usp_acct_recurringentry_list — columnas reales de la tabla
DROP FUNCTION IF EXISTS usp_acct_recurringentry_list(integer, boolean, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_recurringentry_list(
  p_company_id INT, p_is_active BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1, p_limit INT DEFAULT 50
) RETURNS TABLE(
  "RecurringEntryId" INT, "CompanyId" INT, "TemplateName" VARCHAR,
  "TipoAsiento" VARCHAR, "Concepto" VARCHAR, "Frequency" VARCHAR,
  "NextExecutionDate" DATE, "IsActive" BOOLEAN, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT; v_offset INT;
BEGIN
  IF p_page < 1 THEN p_page := 1; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;
  v_offset := (p_page - 1) * p_limit;
  SELECT COUNT(*) INTO v_total FROM acct."RecurringEntry" re2
  WHERE re2."CompanyId" = p_company_id AND re2."IsDeleted" = FALSE
    AND (p_is_active IS NULL OR re2."IsActive" = p_is_active);
  RETURN QUERY
  SELECT re."RecurringEntryId", re."CompanyId", re."TemplateName",
         re."TipoAsiento", re."Concepto", re."Frequency",
         re."NextExecutionDate", re."IsActive", v_total
  FROM acct."RecurringEntry" re
  WHERE re."CompanyId" = p_company_id AND re."IsDeleted" = FALSE
    AND (p_is_active IS NULL OR re."IsActive" = p_is_active)
  ORDER BY re."NextExecutionDate"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_recurringentry_list(INT,BOOLEAN,INT,INT) TO zentto_app;

-- 9. usp_acct_recurringentry_getdue — columnas reales
DROP FUNCTION IF EXISTS usp_acct_recurringentry_getdue(integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_recurringentry_getdue(p_company_id INT)
RETURNS TABLE(
  "RecurringEntryId" INT, "TemplateName" VARCHAR, "TipoAsiento" VARCHAR,
  "Concepto" VARCHAR, "Frequency" VARCHAR, "NextExecutionDate" DATE
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT re."RecurringEntryId", re."TemplateName", re."TipoAsiento",
         re."Concepto", re."Frequency", re."NextExecutionDate"
  FROM acct."RecurringEntry" re
  WHERE re."CompanyId" = p_company_id AND re."IsActive" = TRUE
    AND re."IsDeleted" = FALSE AND re."NextExecutionDate" <= CURRENT_DATE
  ORDER BY re."NextExecutionDate";
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_recurringentry_getdue(INT) TO zentto_app;

-- 10. usp_acct_fixedassetcategory_list — alias fac. en CategoryCode/CategoryName
DROP FUNCTION IF EXISTS usp_acct_fixedassetcategory_list(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_fixedassetcategory_list(
  p_company_id INT, p_search VARCHAR DEFAULT NULL,
  p_page INT DEFAULT 1, p_limit INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount" BIGINT, "CategoryId" INT, "CategoryCode" VARCHAR, "CategoryName" VARCHAR,
  "DefaultUsefulLifeMonths" INT, "DefaultDepreciationMethod" VARCHAR,
  "DefaultResidualPercent" NUMERIC, "DefaultAssetAccountCode" VARCHAR,
  "DefaultDeprecAccountCode" VARCHAR, "DefaultExpenseAccountCode" VARCHAR,
  "CountryCode" VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
  IF p_page < 1 THEN p_page := 1; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;
  SELECT COUNT(*) INTO v_total FROM acct."FixedAssetCategory" fac2
  WHERE fac2."CompanyId" = p_company_id AND fac2."IsDeleted" = FALSE
    AND (p_search IS NULL
         OR fac2."CategoryCode" LIKE '%' || p_search || '%'
         OR fac2."CategoryName" LIKE '%' || p_search || '%');
  RETURN QUERY
  SELECT v_total, fac."CategoryId", fac."CategoryCode", fac."CategoryName",
         fac."DefaultUsefulLifeMonths", fac."DefaultDepreciationMethod"::VARCHAR,
         fac."DefaultResidualPercent", fac."DefaultAssetAccountCode",
         fac."DefaultDeprecAccountCode", fac."DefaultExpenseAccountCode",
         fac."CountryCode"
  FROM acct."FixedAssetCategory" fac
  WHERE fac."CompanyId" = p_company_id AND fac."IsDeleted" = FALSE
    AND (p_search IS NULL
         OR fac."CategoryCode" LIKE '%' || p_search || '%'
         OR fac."CategoryName" LIKE '%' || p_search || '%')
  ORDER BY fac."CategoryCode"
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_fixedassetcategory_list(INT,VARCHAR,INT,INT) TO zentto_app;

-- ============================================================
-- FISCAL FUNCTIONS — fix column ambiguity (alias tbe/td/wv)
-- ============================================================

-- 11. usp_fiscal_taxbook_list
DROP FUNCTION IF EXISTS public.usp_fiscal_taxbook_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_taxbook_list(
  p_company_id  INT,
  p_book_type   VARCHAR,
  p_period_code VARCHAR,
  p_country_code VARCHAR,
  p_page        INT DEFAULT 1,
  p_limit       INT DEFAULT 100
) RETURNS TABLE(
  p_total_count       BIGINT,
  "EntryId"           BIGINT,
  "CompanyId"         INT,
  "BookType"          VARCHAR,
  "PeriodCode"        VARCHAR,
  "EntryDate"         DATE,
  "DocumentNumber"    VARCHAR,
  "DocumentType"      VARCHAR,
  "ControlNumber"     VARCHAR,
  "ThirdPartyId"      VARCHAR,
  "ThirdPartyName"    VARCHAR,
  "TaxableBase"       NUMERIC,
  "ExemptAmount"      NUMERIC,
  "TaxRate"           NUMERIC,
  "TaxAmount"         NUMERIC,
  "WithholdingRate"   NUMERIC,
  "WithholdingAmount" NUMERIC,
  "TotalAmount"       NUMERIC,
  "SourceDocumentId"  BIGINT,
  "SourceModule"      VARCHAR,
  "CountryCode"       VARCHAR,
  "DeclarationId"     BIGINT,
  "CreatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_page  < 1   THEN p_page  := 1;   END IF;
  IF p_limit < 1   THEN p_limit := 100; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  RETURN QUERY
  SELECT COUNT(*) OVER()       AS p_total_count,
         tbe."EntryId", tbe."CompanyId", tbe."BookType", tbe."PeriodCode",
         tbe."EntryDate", tbe."DocumentNumber", tbe."DocumentType",
         tbe."ControlNumber", tbe."ThirdPartyId", tbe."ThirdPartyName",
         tbe."TaxableBase", tbe."ExemptAmount", tbe."TaxRate", tbe."TaxAmount",
         tbe."WithholdingRate", tbe."WithholdingAmount", tbe."TotalAmount",
         tbe."SourceDocumentId", tbe."SourceModule", tbe."CountryCode",
         tbe."DeclarationId", tbe."CreatedAt"
  FROM fiscal."TaxBookEntry" tbe
  WHERE tbe."CompanyId"    = p_company_id
    AND tbe."BookType"     = p_book_type
    AND tbe."PeriodCode"   = p_period_code
    AND tbe."CountryCode"  = p_country_code
  ORDER BY tbe."EntryDate", tbe."DocumentNumber"
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_taxbook_list(INT,VARCHAR,VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 12. usp_fiscal_taxbook_summary
DROP FUNCTION IF EXISTS public.usp_fiscal_taxbook_summary(integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_taxbook_summary(
  p_company_id   INT,
  p_book_type    VARCHAR,
  p_period_code  VARCHAR,
  p_country_code VARCHAR
) RETURNS TABLE(
  "TaxRate"           NUMERIC,
  "TaxableBase"       NUMERIC,
  "ExemptAmount"      NUMERIC,
  "TaxAmount"         NUMERIC,
  "WithholdingAmount" NUMERIC,
  "TotalAmount"       NUMERIC,
  "EntryCount"        BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT tbe."TaxRate",
         SUM(tbe."TaxableBase")       AS "TaxableBase",
         SUM(tbe."ExemptAmount")      AS "ExemptAmount",
         SUM(tbe."TaxAmount")         AS "TaxAmount",
         SUM(tbe."WithholdingAmount") AS "WithholdingAmount",
         SUM(tbe."TotalAmount")       AS "TotalAmount",
         COUNT(*)                     AS "EntryCount"
  FROM fiscal."TaxBookEntry" tbe
  WHERE tbe."CompanyId"   = p_company_id
    AND tbe."BookType"    = p_book_type
    AND tbe."PeriodCode"  = p_period_code
    AND tbe."CountryCode" = p_country_code
  GROUP BY tbe."TaxRate"
  ORDER BY tbe."TaxRate";
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_taxbook_summary(INT,VARCHAR,VARCHAR,VARCHAR) TO zentto_app;

-- 13. usp_fiscal_declaration_list
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_list(integer, character varying, integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_list(
  p_company_id       INT,
  p_declaration_type VARCHAR DEFAULT NULL,
  p_year             INT     DEFAULT NULL,
  p_status           VARCHAR DEFAULT NULL,
  p_page             INT     DEFAULT 1,
  p_limit            INT     DEFAULT 50
) RETURNS TABLE(
  p_total_count       BIGINT,
  "DeclarationId"     BIGINT,
  "CompanyId"         INT,
  "BranchId"          INT,
  "CountryCode"       VARCHAR,
  "DeclarationType"   VARCHAR,
  "PeriodCode"        VARCHAR,
  "PeriodStart"       DATE,
  "PeriodEnd"         DATE,
  "SalesBase"         NUMERIC,
  "SalesTax"          NUMERIC,
  "PurchasesBase"     NUMERIC,
  "PurchasesTax"      NUMERIC,
  "TaxableBase"       NUMERIC,
  "TaxAmount"         NUMERIC,
  "WithholdingsCredit" NUMERIC,
  "PreviousBalance"   NUMERIC,
  "NetPayable"        NUMERIC,
  "Status"            VARCHAR,
  "SubmittedAt"       TIMESTAMP,
  "SubmittedFile"     VARCHAR,
  "AuthorityResponse" TEXT,
  "PaidAt"            TIMESTAMP,
  "PaymentReference"  VARCHAR,
  "JournalEntryId"    BIGINT,
  "Notes"             VARCHAR,
  "CreatedBy"         VARCHAR,
  "UpdatedBy"         VARCHAR,
  "CreatedAt"         TIMESTAMP,
  "UpdatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_page  < 1   THEN p_page  := 1;   END IF;
  IF p_limit < 1   THEN p_limit := 50;  END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  RETURN QUERY
  SELECT COUNT(*) OVER() AS p_total_count,
         td."DeclarationId", td."CompanyId", td."BranchId", td."CountryCode",
         td."DeclarationType", td."PeriodCode", td."PeriodStart", td."PeriodEnd",
         td."SalesBase", td."SalesTax", td."PurchasesBase", td."PurchasesTax",
         td."TaxableBase", td."TaxAmount", td."WithholdingsCredit",
         td."PreviousBalance", td."NetPayable", td."Status",
         td."SubmittedAt", td."SubmittedFile", td."AuthorityResponse"::TEXT,
         td."PaidAt", td."PaymentReference", td."JournalEntryId", td."Notes",
         td."CreatedBy", td."UpdatedBy", td."CreatedAt", td."UpdatedAt"
  FROM fiscal."TaxDeclaration" td
  WHERE td."CompanyId" = p_company_id
    AND (p_declaration_type IS NULL OR td."DeclarationType" = p_declaration_type)
    AND (p_year IS NULL OR LEFT(td."PeriodCode", 4) = CAST(p_year AS VARCHAR(4)))
    AND (p_status IS NULL OR td."Status" = p_status)
  ORDER BY td."PeriodCode" DESC
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_declaration_list(INT,VARCHAR,INT,VARCHAR,INT,INT) TO zentto_app;

-- 14. usp_fiscal_withholding_list
DROP FUNCTION IF EXISTS public.usp_fiscal_withholding_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_withholding_list(
  p_company_id      INT,
  p_withholding_type VARCHAR DEFAULT NULL,
  p_period_code      VARCHAR DEFAULT NULL,
  p_country_code     VARCHAR DEFAULT NULL,
  p_page             INT     DEFAULT 1,
  p_limit            INT     DEFAULT 50
) RETURNS TABLE(
  p_total_count       BIGINT,
  "VoucherId"         BIGINT,
  "CompanyId"         INT,
  "VoucherNumber"     VARCHAR,
  "VoucherDate"       DATE,
  "WithholdingType"   VARCHAR,
  "ThirdPartyId"      VARCHAR,
  "ThirdPartyName"    VARCHAR,
  "DocumentNumber"    VARCHAR,
  "DocumentDate"      DATE,
  "TaxableBase"       NUMERIC,
  "WithholdingRate"   NUMERIC,
  "WithholdingAmount" NUMERIC,
  "PeriodCode"        VARCHAR,
  "Status"            VARCHAR,
  "CountryCode"       VARCHAR,
  "JournalEntryId"    BIGINT,
  "CreatedBy"         VARCHAR,
  "CreatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_page  < 1   THEN p_page  := 1;   END IF;
  IF p_limit < 1   THEN p_limit := 50;  END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  RETURN QUERY
  SELECT COUNT(*) OVER() AS p_total_count,
         wv."VoucherId", wv."CompanyId", wv."VoucherNumber", wv."VoucherDate",
         wv."WithholdingType", wv."ThirdPartyId", wv."ThirdPartyName",
         wv."DocumentNumber", wv."DocumentDate", wv."TaxableBase",
         wv."WithholdingRate", wv."WithholdingAmount", wv."PeriodCode",
         wv."Status", wv."CountryCode", wv."JournalEntryId",
         wv."CreatedBy", wv."CreatedAt"
  FROM fiscal."WithholdingVoucher" wv
  WHERE wv."CompanyId" = p_company_id
    AND (p_withholding_type IS NULL OR wv."WithholdingType" = p_withholding_type)
    AND (p_period_code      IS NULL OR wv."PeriodCode"      = p_period_code)
    AND (p_country_code     IS NULL OR wv."CountryCode"     = p_country_code)
  ORDER BY wv."VoucherDate" DESC
  LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_withholding_list(INT,VARCHAR,VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 15. usp_fiscal_withholding_get
DROP FUNCTION IF EXISTS public.usp_fiscal_withholding_get(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_withholding_get(
  p_company_id INT,
  p_voucher_id BIGINT
) RETURNS TABLE(
  "VoucherId"         BIGINT,
  "CompanyId"         INT,
  "VoucherNumber"     VARCHAR,
  "VoucherDate"       DATE,
  "WithholdingType"   VARCHAR,
  "ThirdPartyId"      VARCHAR,
  "ThirdPartyName"    VARCHAR,
  "DocumentNumber"    VARCHAR,
  "DocumentDate"      DATE,
  "TaxableBase"       NUMERIC,
  "WithholdingRate"   NUMERIC,
  "WithholdingAmount" NUMERIC,
  "PeriodCode"        VARCHAR,
  "Status"            VARCHAR,
  "CountryCode"       VARCHAR,
  "JournalEntryId"    BIGINT,
  "CreatedBy"         VARCHAR,
  "CreatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT wv."VoucherId", wv."CompanyId", wv."VoucherNumber", wv."VoucherDate",
         wv."WithholdingType", wv."ThirdPartyId", wv."ThirdPartyName",
         wv."DocumentNumber", wv."DocumentDate", wv."TaxableBase",
         wv."WithholdingRate", wv."WithholdingAmount", wv."PeriodCode",
         wv."Status", wv."CountryCode", wv."JournalEntryId",
         wv."CreatedBy", wv."CreatedAt"
  FROM fiscal."WithholdingVoucher" wv
  WHERE wv."CompanyId" = p_company_id
    AND wv."VoucherId" = p_voucher_id
  LIMIT 1;
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_withholding_get(INT,BIGINT) TO zentto_app;

-- 16. usp_fiscal_export_taxbook
DROP FUNCTION IF EXISTS public.usp_fiscal_export_taxbook(integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_export_taxbook(
  p_company_id   INT,
  p_book_type    VARCHAR,
  p_period_code  VARCHAR,
  p_country_code VARCHAR
) RETURNS TABLE(
  "EntryId"           BIGINT,
  "CompanyId"         INT,
  "BookType"          VARCHAR,
  "PeriodCode"        VARCHAR,
  "EntryDate"         DATE,
  "DocumentNumber"    VARCHAR,
  "DocumentType"      VARCHAR,
  "ControlNumber"     VARCHAR,
  "ThirdPartyId"      VARCHAR,
  "ThirdPartyName"    VARCHAR,
  "TaxableBase"       NUMERIC,
  "ExemptAmount"      NUMERIC,
  "TaxRate"           NUMERIC,
  "TaxAmount"         NUMERIC,
  "WithholdingRate"   NUMERIC,
  "WithholdingAmount" NUMERIC,
  "TotalAmount"       NUMERIC,
  "SourceDocumentId"  BIGINT,
  "SourceModule"      VARCHAR,
  "CountryCode"       VARCHAR,
  "DeclarationId"     BIGINT,
  "CreatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT tbe."EntryId", tbe."CompanyId", tbe."BookType", tbe."PeriodCode",
         tbe."EntryDate", tbe."DocumentNumber", tbe."DocumentType",
         tbe."ControlNumber", tbe."ThirdPartyId", tbe."ThirdPartyName",
         tbe."TaxableBase", tbe."ExemptAmount", tbe."TaxRate", tbe."TaxAmount",
         tbe."WithholdingRate", tbe."WithholdingAmount", tbe."TotalAmount",
         tbe."SourceDocumentId", tbe."SourceModule", tbe."CountryCode",
         tbe."DeclarationId", tbe."CreatedAt"
  FROM fiscal."TaxBookEntry" tbe
  WHERE tbe."CompanyId"   = p_company_id
    AND tbe."BookType"    = p_book_type
    AND tbe."PeriodCode"  = p_period_code
    AND tbe."CountryCode" = p_country_code
  ORDER BY tbe."EntryDate", tbe."DocumentNumber";
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_export_taxbook(INT,VARCHAR,VARCHAR,VARCHAR) TO zentto_app;

-- ============================================================
-- NUEVAS CORRECCIONES — Ambiguedad + type mismatch + cast bug
-- ============================================================

-- 17. usp_acct_equitymovement_list — alias em. elimina ambiguedad; tipos corregidos
DROP FUNCTION IF EXISTS usp_acct_equitymovement_list(integer, integer, smallint) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_equitymovement_list(
  p_company_id  INT,
  p_branch_id   INT,
  p_fiscal_year SMALLINT
) RETURNS TABLE(
  p_total_count      BIGINT,
  "EquityMovementId" INT,
  "AccountId"        BIGINT,
  "AccountCode"      VARCHAR,
  "AccountName"      VARCHAR,
  "MovementType"     VARCHAR,
  "MovementDate"     DATE,
  "Amount"           NUMERIC,
  "JournalEntryId"   BIGINT,
  "Description"      VARCHAR,
  "CreatedAt"        TIMESTAMP,
  "UpdatedAt"        TIMESTAMP
) LANGUAGE plpgsql AS $$
DECLARE v_total_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total_count
  FROM acct."EquityMovement" em2
  WHERE em2."CompanyId" = p_company_id
    AND em2."BranchId"  = p_branch_id
    AND em2."FiscalYear" = p_fiscal_year;

  RETURN QUERY
  SELECT v_total_count,
         em."EquityMovementId",
         em."AccountId",
         em."AccountCode",
         em."AccountName",
         em."MovementType",
         em."MovementDate",
         em."Amount",
         em."JournalEntryId",
         em."Description",
         em."CreatedAt",
         em."UpdatedAt"
  FROM acct."EquityMovement" em
  WHERE em."CompanyId"  = p_company_id
    AND em."BranchId"   = p_branch_id
    AND em."FiscalYear" = p_fiscal_year
  ORDER BY em."MovementDate", em."AccountCode";
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_equitymovement_list(INT,INT,SMALLINT) TO zentto_app;

-- 18. usp_acct_inflationindex_list — alias ii. elimina ambiguedad
DROP FUNCTION IF EXISTS usp_acct_inflationindex_list(integer, character, character varying, smallint, smallint) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_inflationindex_list(
  p_company_id   INT,
  p_country_code CHARACTER DEFAULT 'VE',
  p_index_name   VARCHAR   DEFAULT 'INPC',
  p_year_from    SMALLINT  DEFAULT NULL,
  p_year_to      SMALLINT  DEFAULT NULL
) RETURNS TABLE(
  p_total_count      BIGINT,
  "InflationIndexId" INT,
  "CountryCode"      CHARACTER,
  "IndexName"        VARCHAR,
  "PeriodCode"       CHARACTER,
  "IndexValue"       NUMERIC,
  "SourceReference"  VARCHAR,
  "CreatedAt"        TIMESTAMP,
  "UpdatedAt"        TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*) OVER()          AS p_total_count,
         ii."InflationIndexId",
         ii."CountryCode",
         ii."IndexName",
         ii."PeriodCode",
         ii."IndexValue",
         ii."SourceReference",
         ii."CreatedAt",
         ii."UpdatedAt"
  FROM acct."InflationIndex" ii
  WHERE ii."CompanyId"   = p_company_id
    AND ii."CountryCode" = p_country_code
    AND ii."IndexName"   = p_index_name
    AND (p_year_from IS NULL OR CAST(LEFT(ii."PeriodCode"::VARCHAR, 4) AS SMALLINT) >= p_year_from)
    AND (p_year_to   IS NULL OR CAST(LEFT(ii."PeriodCode"::VARCHAR, 4) AS SMALLINT) <= p_year_to)
  ORDER BY ii."PeriodCode";
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_inflationindex_list(INT,CHARACTER,VARCHAR,SMALLINT,SMALLINT) TO zentto_app;

-- 19. usp_acct_accountmonetaryclass_list — fix type mismatch: AccountLevel INT vs SMALLINT
DROP FUNCTION IF EXISTS usp_acct_accountmonetaryclass_list(integer, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_accountmonetaryclass_list(
  p_company_id     INT,
  p_classification VARCHAR DEFAULT NULL,
  p_search         VARCHAR DEFAULT NULL
) RETURNS TABLE(
  p_total_count            BIGINT,
  "AccountMonetaryClassId" INT,
  "AccountId"              BIGINT,
  "AccountCode"            VARCHAR,
  "AccountName"            VARCHAR,
  "AccountType"            CHARACTER,
  "AccountLevel"           INT,
  "AllowsPosting"          BOOLEAN,
  "Classification"         VARCHAR,
  "SubClassification"      VARCHAR,
  "ReexpressionAccountId"  BIGINT,
  "IsActive"               BOOLEAN,
  "UpdatedAt"              TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*) OVER()            AS p_total_count,
         mc."AccountMonetaryClassId",
         a."AccountId",
         a."AccountCode",
         a."AccountName",
         a."AccountType",
         a."AccountLevel"::INT,
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
END; $$;
GRANT EXECUTE ON FUNCTION usp_acct_accountmonetaryclass_list(INT,VARCHAR,VARCHAR) TO zentto_app;

-- 20. usp_tax_retention_list — fix type mismatch: CountryCode CHAR(2) cast a VARCHAR
DROP FUNCTION IF EXISTS usp_tax_retention_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_tax_retention_list(
  p_search VARCHAR DEFAULT NULL,
  p_tipo   VARCHAR DEFAULT NULL,
  p_offset INT     DEFAULT 0,
  p_limit  INT     DEFAULT 50
) RETURNS TABLE(
  "RetentionId" INT,
  "Codigo"      VARCHAR,
  "Descripcion" VARCHAR,
  "Tipo"        VARCHAR,
  "Porcentaje"  NUMERIC,
  "Pais"        VARCHAR,
  "IsActive"    BOOLEAN
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT tr."RetentionId",
         tr."RetentionCode",
         tr."Description",
         tr."RetentionType",
         tr."RetentionRate",
         tr."CountryCode"::VARCHAR,
         tr."IsActive"
  FROM master."TaxRetention" tr
  WHERE tr."IsDeleted" = FALSE
    AND (p_search IS NULL OR (tr."RetentionCode" ILIKE '%' || p_search || '%' OR tr."Description" ILIKE '%' || p_search || '%'))
    AND (p_tipo IS NULL OR tr."RetentionType" = p_tipo)
  ORDER BY tr."RetentionCode"
  LIMIT p_limit OFFSET p_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_tax_retention_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 21. usp_almacen_list — fix cast bug ::character varying en aritmetica
DROP FUNCTION IF EXISTS usp_almacen_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_list(
  p_search VARCHAR DEFAULT NULL,
  p_tipo   VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"        VARCHAR,
  "Descripcion"   VARCHAR,
  "Tipo"          VARCHAR,
  "IsActive"      BOOLEAN,
  "IsDeleted"     BOOLEAN,
  "CompanyId"     INT,
  "WarehouseCode" VARCHAR,
  "Description"   VARCHAR,
  "WarehouseType" VARCHAR,
  "TotalCount"    INT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1  THEN v_limit := 50;  END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM master."Warehouse" w
  WHERE COALESCE(w."IsDeleted", FALSE) = FALSE
    AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo);

  RETURN QUERY
  SELECT w."WarehouseCode" AS "Codigo",
         w."Description"   AS "Descripcion",
         w."WarehouseType" AS "Tipo",
         w."IsActive",
         w."IsDeleted",
         w."CompanyId",
         w."WarehouseCode",
         w."Description",
         w."WarehouseType",
         v_total           AS "TotalCount"
  FROM master."Warehouse" w
  WHERE COALESCE(w."IsDeleted", FALSE) = FALSE
    AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo)
  ORDER BY w."WarehouseCode"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_almacen_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 22. usp_bancos_list — fix cast bug ::character varying en aritmetica
DROP FUNCTION IF EXISTS usp_bancos_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Nombre"     VARCHAR,
  "Contacto"   VARCHAR,
  "Direccion"  VARCHAR,
  "Telefonos"  VARCHAR,
  "Co_Usuario" VARCHAR,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  BIGINT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  ELSE
    v_search := NULL;
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM dbo."Bancos" b
  WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search);

  RETURN QUERY
  SELECT b."Nombre", b."Contacto", b."Direccion", b."Telefonos", b."Co_Usuario", v_total
  FROM dbo."Bancos" b
  WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search)
  ORDER BY b."Nombre"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_bancos_list(VARCHAR,INT,INT) TO zentto_app;

-- 23. usp_categorias_list — fix cast bug
DROP FUNCTION IF EXISTS usp_categorias_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount" BIGINT,
  "Codigo"     INT,
  "Nombre"     VARCHAR,
  "Co_Usuario" VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_total  BIGINT;
  v_search VARCHAR(100);
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Categoria"
  WHERE (v_search IS NULL OR "Nombre"::TEXT LIKE v_search OR "Codigo"::TEXT LIKE v_search);

  RETURN QUERY
  SELECT v_total, c."Codigo", c."Nombre", c."Co_Usuario"
  FROM public."Categoria" c
  WHERE (v_search IS NULL OR c."Nombre"::TEXT LIKE v_search OR c."Codigo"::TEXT LIKE v_search)
  ORDER BY c."Codigo"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_categorias_list(VARCHAR,INT,INT) TO zentto_app;

-- 24. usp_centrocosto_list — fix cast bug
DROP FUNCTION IF EXISTS usp_centrocosto_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_centrocosto_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"        VARCHAR,
  "Descripcion"   VARCHAR,
  "Presupuestado" VARCHAR,
  "Saldo_Real"    VARCHAR,
  "TotalCount"    INT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1  THEN v_limit := 50;  END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Centro_Costo" cc
  WHERE v_search IS NULL OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search);

  RETURN QUERY
  SELECT cc."Codigo", cc."Descripcion", cc."Presupuestado", cc."Saldo_Real",
         v_total AS "TotalCount"
  FROM public."Centro_Costo" cc
  WHERE v_search IS NULL OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search)
  ORDER BY cc."Codigo"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_centrocosto_list(VARCHAR,INT,INT) TO zentto_app;

-- 25. usp_clases_list — fix cast bug
DROP FUNCTION IF EXISTS usp_clases_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_clases_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"      INT,
  "Descripcion" VARCHAR,
  "TotalCount"  INT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1  THEN v_limit := 50;  END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Clases" cl
  WHERE v_search IS NULL OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search);

  RETURN QUERY
  SELECT cl."Codigo", cl."Descripcion", v_total AS "TotalCount"
  FROM public."Clases" cl
  WHERE v_search IS NULL OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search)
  ORDER BY cl."Codigo"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_clases_list(VARCHAR,INT,INT) TO zentto_app;

-- 26. usp_compras_list — fix cast bug
DROP FUNCTION IF EXISTS usp_compras_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_compras_list(
  p_search      VARCHAR DEFAULT NULL,
  p_proveedor   VARCHAR DEFAULT NULL,
  p_estado      VARCHAR DEFAULT NULL,
  p_fecha_desde DATE    DEFAULT NULL,
  p_fecha_hasta DATE    DEFAULT NULL,
  p_page        INT DEFAULT 1,
  p_limit       INT DEFAULT 50
) RETURNS TABLE(
  "NUM_FACT"      VARCHAR,
  "FECHA"         DATE,
  "COD_PROVEEDOR" VARCHAR,
  "NOMBRE"        VARCHAR,
  "RIF"           VARCHAR,
  "TIPO"          VARCHAR,
  "MONTO"         NUMERIC,
  "IVA"           NUMERIC,
  "TOTAL"         NUMERIC,
  "TotalCount"    INT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1  THEN v_limit := 50;  END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Compras" co
  WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
    AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
    AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
    AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
    AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta);

  RETURN QUERY
  SELECT co."NUM_FACT", co."FECHA", co."COD_PROVEEDOR", co."NOMBRE", co."RIF",
         co."TIPO", co."MONTO", co."IVA", co."TOTAL", v_total AS "TotalCount"
  FROM public."Compras" co
  WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
    AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
    AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
    AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
    AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta)
  ORDER BY co."FECHA" DESC
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_compras_list(VARCHAR,VARCHAR,VARCHAR,DATE,DATE,INT,INT) TO zentto_app;

-- 27. usp_cotizacion_list — fix cast bug
DROP FUNCTION IF EXISTS usp_cotizacion_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_cotizacion_list(
  p_search VARCHAR DEFAULT NULL,
  p_codigo VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "NUM_FACT"   VARCHAR,
  "FECHA"      DATE,
  "CODIGO"     VARCHAR,
  "NOMBRE"     VARCHAR,
  "RIF"        VARCHAR,
  "MONTO"      NUMERIC,
  "IVA"        NUMERIC,
  "TOTAL"      NUMERIC,
  "TotalCount" INT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1  THEN v_limit := 50;  END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Cotizacion" ct
  WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
    AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo);

  RETURN QUERY
  SELECT ct."NUM_FACT", ct."FECHA", ct."CODIGO", ct."NOMBRE", ct."RIF",
         ct."MONTO", ct."IVA", ct."TOTAL", v_total AS "TotalCount"
  FROM public."Cotizacion" ct
  WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
    AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo)
  ORDER BY ct."FECHA" DESC
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_cotizacion_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 28. usp_facturas_list — fix cast bug + col mismatch (Id→DocumentId, ClientCode→CustomerCode, etc.)
DROP FUNCTION IF EXISTS usp_facturas_list(character varying, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_facturas_list(
  p_num_fact    VARCHAR DEFAULT NULL,
  p_cod_usuario VARCHAR DEFAULT NULL,
  p_from        DATE    DEFAULT NULL,
  p_to          DATE    DEFAULT NULL,
  p_page        INT DEFAULT 1,
  p_limit       INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount"     INT,
  "Id"             INT,
  "DocumentNumber" VARCHAR,
  "OperationType"  VARCHAR,
  "DocumentDate"   TIMESTAMP,
  "UserCode"       VARCHAR,
  "ClientCode"     VARCHAR,
  "ClientName"     VARCHAR,
  "SubTotal"       NUMERIC,
  "TaxAmount"      NUMERIC,
  "TotalAmount"    NUMERIC,
  "Currency"       VARCHAR,
  "ExchangeRate"   NUMERIC,
  "Notes"          VARCHAR,
  "IsDeleted"      BOOLEAN,
  "CreatedAt"      TIMESTAMP,
  "UpdatedAt"      TIMESTAMP
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  SELECT COUNT(1) INTO v_total
  FROM ar."SalesDocument" sd
  WHERE sd."OperationType" = 'FACT'
    AND sd."IsDeleted" = FALSE
    AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
    AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
    AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
    AND (p_to IS NULL OR sd."DocumentDate" <= p_to);

  RETURN QUERY
  SELECT v_total,
         sd."DocumentId",
         sd."DocumentNumber",
         sd."OperationType",
         sd."DocumentDate",
         sd."UserCode",
         sd."CustomerCode",
         sd."CustomerName",
         sd."SubTotal",
         sd."TaxAmount",
         sd."TotalAmount",
         sd."CurrencyCode",
         sd."ExchangeRate",
         sd."Notes",
         sd."IsDeleted",
         sd."CreatedAt",
         sd."UpdatedAt"
  FROM ar."SalesDocument" sd
  WHERE sd."OperationType" = 'FACT'
    AND sd."IsDeleted" = FALSE
    AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
    AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
    AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
    AND (p_to IS NULL OR sd."DocumentDate" <= p_to)
  ORDER BY sd."DocumentDate" DESC
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_facturas_list(VARCHAR,VARCHAR,DATE,DATE,INT,INT) TO zentto_app;

-- 29. usp_feriados_list — fix cast bug
DROP FUNCTION IF EXISTS usp_feriados_list(character varying, integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_feriados_list(
  p_search VARCHAR DEFAULT NULL,
  p_anio   INT     DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount"  INT,
  "Fecha"       DATE,
  "Descripcion" VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_search VARCHAR(100);
  v_total  INT;
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Feriados" f
  WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
    AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio);

  RETURN QUERY
  SELECT v_total, f."Fecha"::DATE, f."Descripcion"
  FROM public."Feriados" f
  WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
    AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio)
  ORDER BY f."Fecha"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_feriados_list(VARCHAR,INT,INT,INT) TO zentto_app;

-- 30. usp_lineas_list — fix cast bug
DROP FUNCTION IF EXISTS usp_lineas_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_lineas_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "CODIGO"      INT,
  "DESCRIPCION" VARCHAR,
  "TotalCount"  BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_total  BIGINT;
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Lineas"
  WHERE (p_search IS NULL
         OR CAST("CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
         OR "DESCRIPCION" LIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT l."CODIGO", l."DESCRIPCION", v_total AS "TotalCount"
  FROM public."Lineas" l
  WHERE (p_search IS NULL
         OR CAST(l."CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
         OR l."DESCRIPCION" LIKE '%' || p_search || '%')
  ORDER BY l."CODIGO"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_lineas_list(VARCHAR,INT,INT) TO zentto_app;

-- 31. usp_marcas_list — fix cast bug
DROP FUNCTION IF EXISTS usp_marcas_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"      INT,
  "Descripcion" VARCHAR,
  "TotalCount"  BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset       INT;
  v_total        BIGINT;
  v_search_param VARCHAR(100);
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  v_search_param := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search_param := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total FROM public."Marcas" m
  WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param);

  RETURN QUERY
  SELECT m."Codigo", m."Descripcion", v_total AS "TotalCount"
  FROM public."Marcas" m
  WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param)
  ORDER BY m."Codigo"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_marcas_list(VARCHAR,INT,INT) TO zentto_app;

-- 32. usp_moneda_list — fix cast bug
DROP FUNCTION IF EXISTS usp_moneda_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_moneda_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Nombre"     VARCHAR,
  "Simbolo"    VARCHAR,
  "Tasa_Local" DOUBLE PRECISION,
  "Local_Tasa" DOUBLE PRECISION,
  "Local"      VARCHAR,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset       INT;
  v_total        BIGINT;
  v_search_param VARCHAR(100);
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  v_search_param := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search_param := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Moneda" m
  WHERE (v_search_param IS NULL OR m."Nombre" LIKE v_search_param OR m."Simbolo" LIKE v_search_param);

  RETURN QUERY
  SELECT m."Nombre", m."Simbolo", m."Tasa_Local", m."Local_Tasa", m."Local",
         v_total AS "TotalCount"
  FROM public."Moneda" m
  WHERE (v_search_param IS NULL OR m."Nombre" LIKE v_search_param OR m."Simbolo" LIKE v_search_param)
  ORDER BY m."Nombre"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_moneda_list(VARCHAR,INT,INT) TO zentto_app;

-- 33. usp_pedidos_list — fix cast bug
DROP FUNCTION IF EXISTS usp_pedidos_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_pedidos_list(
  p_search VARCHAR DEFAULT NULL,
  p_codigo VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "NUM_FACT"   VARCHAR,
  "CODIGO"     VARCHAR,
  "NOMBRE"     VARCHAR,
  "RIF"        VARCHAR,
  "FECHA"      TIMESTAMP,
  "SUBTOTAL"   NUMERIC,
  "IMPUESTO"   NUMERIC,
  "TOTAL"      NUMERIC,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset       INT;
  v_total        BIGINT;
  v_search_param VARCHAR(100);
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  v_search_param := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search_param := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Pedidos" p
  WHERE (v_search_param IS NULL OR p."NUM_FACT" LIKE v_search_param OR p."NOMBRE" LIKE v_search_param OR p."RIF" LIKE v_search_param)
    AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo);

  RETURN QUERY
  SELECT p."NUM_FACT", p."CODIGO", p."NOMBRE", p."RIF", p."FECHA",
         p."SUBTOTAL", p."IMPUESTO", p."TOTAL", v_total AS "TotalCount"
  FROM public."Pedidos" p
  WHERE (v_search_param IS NULL OR p."NUM_FACT" LIKE v_search_param OR p."NOMBRE" LIKE v_search_param OR p."RIF" LIKE v_search_param)
    AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo)
  ORDER BY p."FECHA" DESC
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_pedidos_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 34. usp_tipos_list — fix cast bug
DROP FUNCTION IF EXISTS usp_tipos_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_tipos_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"     INT,
  "Nombre"     VARCHAR,
  "Categoria"  VARCHAR,
  "Co_Usuario" VARCHAR,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_total  BIGINT;
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Tipos"
  WHERE (p_search IS NULL
         OR CAST("Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
         OR "Nombre" LIKE '%' || p_search || '%'
         OR "Categoria" LIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT t."Codigo", t."Nombre", t."Categoria", t."Co_Usuario", v_total AS "TotalCount"
  FROM public."Tipos" t
  WHERE (p_search IS NULL
         OR CAST(t."Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
         OR t."Nombre" LIKE '%' || p_search || '%'
         OR t."Categoria" LIKE '%' || p_search || '%')
  ORDER BY t."Codigo"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_tipos_list(VARCHAR,INT,INT) TO zentto_app;

-- 35. usp_unidades_list — fix cast bug
DROP FUNCTION IF EXISTS usp_unidades_list(character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_list(
  p_search VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Id"         INT,
  "Unidad"     VARCHAR,
  "Cantidad"   DOUBLE PRECISION,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset       INT;
  v_total        BIGINT;
  v_search_param VARCHAR(100);
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  v_search_param := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search_param := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total FROM public."Unidades" u
  WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param);

  RETURN QUERY
  SELECT u."Id", u."Unidad", u."Cantidad", v_total AS "TotalCount"
  FROM public."Unidades" u
  WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param)
  ORDER BY u."Id"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_unidades_list(VARCHAR,INT,INT) TO zentto_app;

-- 36. usp_usuarios_list — fix cast bug; Avatar es TEXT en sec."User"
DROP FUNCTION IF EXISTS usp_usuarios_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_usuarios_list(
  p_search VARCHAR DEFAULT NULL,
  p_tipo   VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount"   BIGINT,
  "Cod_Usuario"  VARCHAR,
  "Password"     VARCHAR,
  "Nombre"       VARCHAR,
  "Tipo"         VARCHAR,
  "Updates"      BOOLEAN,
  "Addnews"      BOOLEAN,
  "Deletes"      BOOLEAN,
  "Creador"      BOOLEAN,
  "Cambiar"      BOOLEAN,
  "PrecioMinimo" BOOLEAN,
  "Credito"      BOOLEAN,
  "IsAdmin"      BOOLEAN,
  "Avatar"       TEXT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_total  BIGINT;
  v_search VARCHAR(100);
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM sec."User"
  WHERE "IsDeleted" = FALSE
    AND (v_search IS NULL OR "UserCode" LIKE v_search OR "UserName" LIKE v_search)
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR "UserType" = p_tipo);

  RETURN QUERY
  SELECT v_total,
         u."UserCode"       AS "Cod_Usuario",
         u."PasswordHash"   AS "Password",
         u."UserName"       AS "Nombre",
         u."UserType"       AS "Tipo",
         u."CanUpdate"      AS "Updates",
         u."CanCreate"      AS "Addnews",
         u."CanDelete"      AS "Deletes",
         u."IsCreator"      AS "Creador",
         u."CanChangePwd"   AS "Cambiar",
         u."CanChangePrice" AS "PrecioMinimo",
         u."CanGiveCredit"  AS "Credito",
         u."IsAdmin",
         u."Avatar"
  FROM sec."User" u
  WHERE u."IsDeleted" = FALSE
    AND (v_search IS NULL OR u."UserCode" LIKE v_search OR u."UserName" LIKE v_search)
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR u."UserType" = p_tipo)
  ORDER BY u."UserCode"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_usuarios_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 37. usp_vehiculos_list — fix cast bug
DROP FUNCTION IF EXISTS usp_vehiculos_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_vehiculos_list(
  p_search VARCHAR DEFAULT NULL,
  p_cedula VARCHAR DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "TotalCount" BIGINT,
  "Placa"      VARCHAR,
  "Cedula"     VARCHAR,
  "Marca"      VARCHAR,
  "Anio"       VARCHAR,
  "Cauchos"    VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT;
  v_limit  INT;
  v_total  BIGINT;
  v_search VARCHAR(100);
BEGIN
  v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
  IF v_limit < 1 THEN v_limit := 50; END IF;
  IF v_limit > 500 THEN v_limit := 500; END IF;
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  v_search := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM public."Vehiculos"
  WHERE (v_search IS NULL OR "Placa" LIKE v_search OR "Marca" LIKE v_search)
    AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR "Cedula" = p_cedula);

  RETURN QUERY
  SELECT v_total, v."Placa", v."Cedula", v."Marca", v."Anio", v."Cauchos"
  FROM public."Vehiculos" v
  WHERE (v_search IS NULL OR v."Placa" LIKE v_search OR v."Marca" LIKE v_search)
    AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR v."Cedula" = p_cedula)
  ORDER BY v."Placa"
  LIMIT v_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_vehiculos_list(VARCHAR,VARCHAR,INT,INT) TO zentto_app;

-- 38. usp_vendedores_list — fix cast bug + col mismatch vs master."Seller" real schema
DROP FUNCTION IF EXISTS usp_vendedores_list(character varying, boolean, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_vendedores_list(
  p_search VARCHAR  DEFAULT NULL,
  p_status BOOLEAN  DEFAULT NULL,
  p_tipo   VARCHAR  DEFAULT NULL,
  p_page   INT DEFAULT 1,
  p_limit  INT DEFAULT 50
) RETURNS TABLE(
  "Codigo"     VARCHAR,
  "Nombre"     VARCHAR,
  "Comision"   NUMERIC,
  "Status"     BOOLEAN,
  "IsActive"   BOOLEAN,
  "IsDeleted"  BOOLEAN,
  "CompanyId"  INT,
  "SellerCode" VARCHAR,
  "SellerName" VARCHAR,
  "Commission" NUMERIC,
  "Direccion"  VARCHAR,
  "Telefonos"  VARCHAR,
  "Email"      VARCHAR,
  "SellerType" VARCHAR,
  "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_offset       INT;
  v_total        BIGINT;
  v_search_param VARCHAR(100);
BEGIN
  v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
  IF v_offset < 0 THEN v_offset := 0; END IF;
  IF p_limit < 1 THEN p_limit := 50; END IF;
  IF p_limit > 500 THEN p_limit := 500; END IF;

  v_search_param := NULL;
  IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
    v_search_param := '%' || p_search || '%';
  END IF;

  SELECT COUNT(1) INTO v_total
  FROM master."Seller" s
  WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
    AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
    AND (p_status IS NULL OR s."IsActive" = p_status)
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo);

  RETURN QUERY
  SELECT s."SellerCode" AS "Codigo",
         s."SellerName" AS "Nombre",
         s."Commission" AS "Comision",
         s."IsActive"   AS "Status",
         s."IsActive",
         s."IsDeleted",
         s."CompanyId",
         s."SellerCode",
         s."SellerName",
         s."Commission",
         s."Address"    AS "Direccion",
         s."Phone"      AS "Telefonos",
         s."Email",
         s."SellerType",
         v_total        AS "TotalCount"
  FROM master."Seller" s
  WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
    AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
    AND (p_status IS NULL OR s."IsActive" = p_status)
    AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo)
  ORDER BY s."SellerCode"
  LIMIT p_limit OFFSET v_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_vendedores_list(VARCHAR,BOOLEAN,VARCHAR,INT,INT) TO zentto_app;

-- 17. usp_fiscal_declaration_get — AuthorityResponse TEXT fix + aliases
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_get(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_get(
  p_company_id     INT,
  p_declaration_id BIGINT
) RETURNS TABLE(
  "DeclarationId"      BIGINT,
  "CompanyId"          INT,
  "BranchId"           INT,
  "CountryCode"        VARCHAR,
  "DeclarationType"    VARCHAR,
  "PeriodCode"         VARCHAR,
  "PeriodStart"        DATE,
  "PeriodEnd"          DATE,
  "SalesBase"          NUMERIC,
  "SalesTax"           NUMERIC,
  "PurchasesBase"      NUMERIC,
  "PurchasesTax"       NUMERIC,
  "TaxableBase"        NUMERIC,
  "TaxAmount"          NUMERIC,
  "WithholdingsCredit" NUMERIC,
  "PreviousBalance"    NUMERIC,
  "NetPayable"         NUMERIC,
  "Status"             VARCHAR,
  "SubmittedAt"        TIMESTAMP,
  "SubmittedFile"      VARCHAR,
  "AuthorityResponse"  TEXT,
  "PaidAt"             TIMESTAMP,
  "PaymentReference"   VARCHAR,
  "JournalEntryId"     BIGINT,
  "Notes"              VARCHAR,
  "CreatedBy"          VARCHAR,
  "UpdatedBy"          VARCHAR,
  "CreatedAt"          TIMESTAMP,
  "UpdatedAt"          TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT td."DeclarationId", td."CompanyId", td."BranchId", td."CountryCode",
         td."DeclarationType", td."PeriodCode", td."PeriodStart", td."PeriodEnd",
         td."SalesBase", td."SalesTax", td."PurchasesBase", td."PurchasesTax",
         td."TaxableBase", td."TaxAmount", td."WithholdingsCredit",
         td."PreviousBalance", td."NetPayable", td."Status",
         td."SubmittedAt", td."SubmittedFile", td."AuthorityResponse"::TEXT,
         td."PaidAt", td."PaymentReference", td."JournalEntryId", td."Notes",
         td."CreatedBy", td."UpdatedBy", td."CreatedAt", td."UpdatedAt"
  FROM fiscal."TaxDeclaration" td
  WHERE td."CompanyId"     = p_company_id
    AND td."DeclarationId" = p_declaration_id
  LIMIT 1;
END; $$;
GRANT EXECUTE ON FUNCTION usp_fiscal_declaration_get(INT,BIGINT) TO zentto_app;

-- ============================================================
-- Fix bancos: CHAR vs VARCHAR, TIMESTAMP vs TIMESTAMPTZ
-- ============================================================

-- usp_bank_account_list: CurrencyCode CHAR(3) → ::VARCHAR cast
DROP FUNCTION IF EXISTS public.usp_bank_account_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_account_list(p_company_id integer)
RETURNS TABLE(
  "Nro_Cta" character varying, "Banco" character varying,
  "Descripcion" character varying, "Moneda" character varying,
  "Saldo" numeric, "Saldo_Disponible" numeric, "BancoNombre" character varying
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT ba."AccountNumber"::VARCHAR, b."BankName"::VARCHAR,
         ba."AccountName"::VARCHAR, ba."CurrencyCode"::VARCHAR,
         ba."Balance", ba."AvailableBalance", b."BankName"::VARCHAR
  FROM fin."BankAccount" ba
  INNER JOIN fin."Bank" b ON b."BankId" = ba."BankId"
  WHERE ba."CompanyId" = p_company_id
    AND ba."IsActive" = TRUE AND b."IsActive" = TRUE
  ORDER BY b."BankName", ba."AccountNumber";
END; $$;
GRANT EXECUTE ON FUNCTION usp_bank_account_list(integer) TO zentto_app;

-- usp_bank_movement_listbyaccount: TIMESTAMPTZ → TIMESTAMP fix
DROP FUNCTION IF EXISTS public.usp_bank_movement_listbyaccount(integer, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_movement_listbyaccount(
  p_company_id integer, p_nro_cta character varying,
  p_from_date date DEFAULT NULL, p_to_date date DEFAULT NULL,
  p_offset integer DEFAULT 0, p_limit integer DEFAULT 50
) RETURNS TABLE(
  id bigint, "Nro_Cta" character varying,
  "Fecha" timestamp without time zone,
  "Tipo" character varying, "Nro_Ref" character varying,
  "Beneficiario" character varying, "Monto" numeric, "MontoNeto" numeric,
  "Concepto" character varying, "Categoria" character varying,
  "Documento_Relacionado" character varying, "Tipo_Doc_Rel" character varying,
  "SaldoPosterior" numeric, "Conciliado" boolean, "TotalCount" bigint
) LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
  SELECT COUNT(1) INTO v_total
  FROM fin."BankMovement" m
  INNER JOIN fin."BankAccount" ba ON ba."BankAccountId" = m."BankAccountId"
  WHERE ba."CompanyId" = p_company_id AND ba."AccountNumber" = p_nro_cta
    AND (p_from_date IS NULL OR m."MovementDate" >= p_from_date)
    AND (p_to_date   IS NULL OR m."MovementDate" <= p_to_date);
  RETURN QUERY
  SELECT m."BankMovementId", ba."AccountNumber"::VARCHAR, m."MovementDate",
         m."MovementType"::VARCHAR, m."ReferenceNo"::VARCHAR,
         m."Beneficiary"::VARCHAR, m."Amount", m."NetAmount",
         m."Concept"::VARCHAR, m."CategoryCode"::VARCHAR,
         m."RelatedDocumentNo"::VARCHAR, m."RelatedDocumentType"::VARCHAR,
         m."BalanceAfter", m."IsReconciled", v_total
  FROM fin."BankMovement" m
  INNER JOIN fin."BankAccount" ba ON ba."BankAccountId" = m."BankAccountId"
  WHERE ba."CompanyId" = p_company_id AND ba."AccountNumber" = p_nro_cta
    AND (p_from_date IS NULL OR m."MovementDate" >= p_from_date)
    AND (p_to_date   IS NULL OR m."MovementDate" <= p_to_date)
  ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC
  LIMIT p_limit OFFSET p_offset;
END; $$;
GRANT EXECUTE ON FUNCTION usp_bank_movement_listbyaccount(integer,varchar,date,date,integer,integer) TO zentto_app;
-- ============================================================
-- fix_timestamp_type_mismatches.sql
-- Barrido completo: corrige TIMESTAMPTZ vs TIMESTAMP en funciones PG
-- Las tablas subyacentes usan TIMESTAMP WITHOUT TIME ZONE, pero las
-- funciones declaraban TIMESTAMP WITH TIME ZONE -> "structure of query
-- does not match function result type".
-- Fix: cambiar RETURNS TABLE a TIMESTAMP (sin tz) en todas las
-- funciones afectadas.
-- Run as: psql -U postgres -d zentto_prod -f fix_timestamp_type_mismatches.sql
-- Fecha: 2026-03-17
-- ============================================================

-- --------------------------------------------------------
-- 1. usp_bank_reconciliation_getpendingstatements
-- Tabla: fin.BankStatementLine.StatementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getpendingstatements(p_id integer)
  RETURNS TABLE(
    id            bigint,
    "Fecha"       timestamp without time zone,
    "Descripcion" character varying,
    "Referencia"  character varying,
    "Tipo"        character varying,
    "Monto"       numeric,
    "Saldo"       numeric
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sl."StatementLineId", sl."StatementDate", sl."DescriptionText", sl."ReferenceNo",
           sl."EntryType", sl."Amount", sl."Balance"
    FROM fin."BankStatementLine" sl
    WHERE sl."ReconciliationId" = p_id AND sl."IsMatched" = FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 2. usp_bank_reconciliation_getsystemmovements
-- Tabla: fin.BankMovement.MovementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getsystemmovements(p_id integer)
  RETURNS TABLE(
    id              bigint,
    "Fecha"         timestamp without time zone,
    "Tipo"          character varying,
    "Nro_Ref"       character varying,
    "Beneficiario"  character varying,
    "Concepto"      character varying,
    "Monto"         numeric,
    "MontoNeto"     numeric,
    "SaldoPosterior" numeric,
    "Conciliado"    boolean
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."BankMovementId", m."MovementDate", m."MovementType", m."ReferenceNo",
           m."Beneficiary", m."Concept", m."Amount", m."NetAmount", m."BalanceAfter", m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId" = m."BankAccountId"
    WHERE r."BankReconciliationId" = p_id
      AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 3. usp_inv_movement_getbyid
-- Tabla: master.InventoryMovement.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_getbyid(p_id integer)
  RETURNS TABLE(
    "MovementId"  integer,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       timestamp without time zone,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."MovementId", m."ProductCode", m."ProductName", m."DocumentRef",
           m."MovementType", m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes"
    FROM master."InventoryMovement" m
    WHERE m."MovementId" = p_id AND m."IsDeleted" = FALSE;
END;
$function$;

-- --------------------------------------------------------
-- 4. usp_inv_movement_list
-- Tabla: master.InventoryMovement.MovementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_list(
    p_search character varying DEFAULT NULL,
    p_tipo   character varying DEFAULT NULL,
    p_offset integer DEFAULT 0,
    p_limit  integer DEFAULT 50
)
  RETURNS TABLE(
    "MovementId"  integer,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       timestamp without time zone,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryMovement"
    WHERE "IsDeleted" = FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search OR "DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR "MovementType" = p_tipo);

    RETURN QUERY
    SELECT m."MovementId", m."ProductCode", m."ProductName", m."DocumentRef",
           m."MovementType", m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes", v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted" = FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType" = p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- --------------------------------------------------------
-- 5. usp_inv_movement_listperiodsummary
-- Tabla: master.InventoryPeriodSummary.SummaryDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo character varying DEFAULT NULL,
    p_codigo  character varying DEFAULT NULL,
    p_offset  integer DEFAULT 0,
    p_limit   integer DEFAULT 50
)
  RETURNS TABLE(
    "SummaryId"   integer,
    "Periodo"     character varying,
    "Codigo"      character varying,
    "OpeningQty"  numeric,
    "InboundQty"  numeric,
    "OutboundQty" numeric,
    "ClosingQty"  numeric,
    fecha         timestamp without time zone,
    "IsClosed"    boolean,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period" = p_periodo)
      AND (p_codigo IS NULL OR "ProductCode" = p_codigo);

    RETURN QUERY
    SELECT s."SummaryId", s."Period", s."ProductCode", s."OpeningQty",
           s."InboundQty", s."OutboundQty", s."ClosingQty", s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period" = p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- --------------------------------------------------------
-- 6. usp_pay_cardreader_list
-- Tabla: pay.CardReaderDevices.LastSeenAt, CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE (p_company_id IS NULL OR cr."EmpresaId" = p_company_id)
    ORDER BY cr."EmpresaId", cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 7. usp_pay_cardreader_listbycompany
-- Tabla: pay.CardReaderDevices.LastSeenAt, CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE cr."EmpresaId" = p_company_id
      AND cr."IsActive" = TRUE
      AND (p_branch_id IS NULL OR cr."SucursalId" = p_branch_id)
    ORDER BY cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 8. usp_pay_companyconfig_list
-- Tabla: pay.CompanyPaymentConfig.CreatedAt, UpdatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"            integer,
    "EmpresaId"     integer,
    "SucursalId"    integer,
    "CountryCode"   character varying,
    "ProviderId"    integer,
    "ProviderCode"  character varying,
    "ProviderName"  character varying,
    "ProviderType"  character varying,
    "Environment"   character varying,
    "AutoCapture"   boolean,
    "AllowRefunds"  boolean,
    "MaxRefundDays" integer,
    "IsActive"      boolean,
    "CreatedAt"     timestamp without time zone,
    "UpdatedAt"     timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
           cc."Environment", cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$function$;

-- --------------------------------------------------------
-- 9. usp_pay_companyconfig_listbycompany
-- Tabla: pay.CompanyPaymentConfig.CreatedAt, UpdatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "CountryCode"      character varying,
    "ProviderId"       integer,
    "ProviderCode"     character varying,
    "ProviderName"     character varying,
    "ProviderType"     character varying,
    "Environment"      character varying,
    "ClientId"         character varying,
    "ClientSecret"     character varying,
    "MerchantId"       character varying,
    "TerminalId"       character varying,
    "IntegratorId"     character varying,
    "CertificatePath"  character varying,
    "ExtraConfig"      character varying,
    "AutoCapture"      boolean,
    "AllowRefunds"     boolean,
    "MaxRefundDays"    integer,
    "IsActive"         boolean,
    "CreatedAt"        timestamp without time zone,
    "UpdatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
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
$function$;

-- --------------------------------------------------------
-- 10. usp_pay_provider_get
-- Tabla: pay.PaymentProviders.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_provider_get(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_provider_get(p_provider_code character varying)
  RETURNS TABLE(
    "Id"             integer,
    "Code"           character varying,
    "Name"           character varying,
    "CountryCode"    character varying,
    "ProviderType"   character varying,
    "BaseUrlSandbox" character varying,
    "BaseUrlProd"    character varying,
    "AuthType"       character varying,
    "DocsUrl"        character varying,
    "LogoUrl"        character varying,
    "IsActive"       boolean,
    "CreatedAt"      timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode",
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl",
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 11. usp_pos_report_ventas
-- Tabla: pos.SaleTicket.SoldAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_report_ventas(integer, integer, date, date, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_report_ventas(
    p_company_id integer,
    p_branch_id  integer,
    p_from_date  date,
    p_to_date    date,
    p_caja_id    character varying DEFAULT NULL,
    p_limit      integer DEFAULT 200
)
  RETURNS TABLE(
    id                   integer,
    "numFactura"         character varying,
    fecha                timestamp without time zone,
    cliente              character varying,
    "cajaId"             character varying,
    total                numeric,
    estado               character varying,
    "metodoPago"         character varying,
    "tramaFiscal"        character varying,
    "serialFiscal"       character varying,
    "correlativoFiscal"  integer
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId",
        v."InvoiceNumber",
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::character varying::VARCHAR,
        v."CashRegisterCode",
        v."TotalAmount",
        'Completada'::VARCHAR,
        v."PaymentMethod",
        v."FiscalPayload",
        corr."SerialFiscal",
        corr."CurrentNumber"
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal", fc."CurrentNumber"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode")::character varying, 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode")::character varying THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    ORDER BY v."SoldAt" DESC, v."SaleTicketId" DESC
    LIMIT p_limit;
END;
$function$;

-- --------------------------------------------------------
-- 12. usp_pos_waitticket_getheader
-- Tabla: pos.WaitTicket.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_getheader(integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_getheader(
    p_company_id     integer,
    p_branch_id      integer,
    p_wait_ticket_id integer
)
  RETURNS TABLE(
    id               integer,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteId"      character varying,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    "tipoPrecio"     character varying,
    motivo           character varying,
    subtotal         numeric,
    impuestos        numeric,
    total            numeric,
    estado           character varying,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName", wt."CustomerCode",
           wt."CustomerName", wt."CustomerFiscalId", wt."PriceTier", wt."Reason",
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 13. usp_pos_waitticket_list
-- Tabla: pos.WaitTicket.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_list(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_list(p_company_id integer, p_branch_id integer)
  RETURNS TABLE(
    id               integer,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteNombre"  character varying,
    motivo           character varying,
    total            numeric,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName",
           wt."CustomerName", wt."Reason", wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$function$;

-- --------------------------------------------------------
-- 14. usp_rest_admin_compra_getdetalle_header
-- Tabla: rest.Purchase.PurchaseDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_getdetalle_header(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(p_compra_id integer)
  RETURNS TABLE(
    id                integer,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying,
    "codUsuario"      character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes",
        u."UserCode"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 15. usp_rest_admin_compra_list
-- Tabla: rest.Purchase.PurchaseDate -> timestamp without time zone
-- Parametros: cambiados de TIMESTAMPTZ a TIMESTAMP para consistencia
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp with time zone, timestamp with time zone) CASCADE;
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp without time zone, timestamp without time zone) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_list(
    p_company_id integer,
    p_branch_id  integer,
    p_status     character varying DEFAULT NULL,
    p_from_date  timestamp without time zone DEFAULT NULL,
    p_to_date    timestamp without time zone DEFAULT NULL
)
  RETURNS TABLE(
    id                integer,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_from_date IS NULL OR p."PurchaseDate" >= p_from_date)
      AND (p_to_date IS NULL OR p."PurchaseDate" <= p_to_date)
    ORDER BY p."PurchaseDate" DESC, p."PurchaseId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 16. usp_rest_orderticket_getheaderforclose
-- Tabla: rest.OrderTicket.ClosedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_getheaderforclose(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(p_pedido_id integer)
  RETURNS TABLE(
    id               integer,
    "empresaId"      integer,
    "sucursalId"     integer,
    "countryCode"    character varying,
    "mesaId"         integer,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    estado           character varying,
    total            numeric,
    "fechaCierre"    timestamp without time zone,
    "codUsuario"     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId", o."CountryCode", dt."DiningTableId",
           o."CustomerName", o."CustomerFiscalId", o."Status", o."TotalAmount", o."ClosedAt",
           COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId" = o."CompanyId"
      AND dt."BranchId" = o."BranchId" AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id
    LIMIT 1;
END;
$function$;

-- ============================================================
-- FIN del barrido de type mismatches TIMESTAMP
-- Funciones corregidas: 16
-- Fecha: 2026-03-17
-- ============================================================
-- ============================================================
-- fix_inv_movement_types.sql
-- Corrige tipos en usp_inv_movement_*
-- MovementId -> bigint (no integer)
-- MovementDate -> date (no timestamp)
-- SummaryDate -> date (no timestamp)
-- SummaryId -> bigint (no integer)
-- Period -> VARCHAR (es CHAR en tabla, necesita cast)
-- ============================================================

-- 1. usp_inv_movement_getbyid
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_getbyid(p_id integer)
  RETURNS TABLE(
    "MovementId"  bigint,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       date,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."MovementId", m."ProductCode"::VARCHAR, m."ProductName"::VARCHAR, m."DocumentRef"::VARCHAR,
           m."MovementType"::VARCHAR, m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes"::VARCHAR
    FROM master."InventoryMovement" m
    WHERE m."MovementId" = p_id AND m."IsDeleted" = FALSE;
END;
$function$;

-- 2. usp_inv_movement_list
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_list(
    p_search character varying DEFAULT NULL,
    p_tipo   character varying DEFAULT NULL,
    p_offset integer DEFAULT 0,
    p_limit  integer DEFAULT 50
)
  RETURNS TABLE(
    "MovementId"  bigint,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       date,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryMovement"
    WHERE "IsDeleted" = FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search OR "DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR "MovementType" = p_tipo);

    RETURN QUERY
    SELECT m."MovementId", m."ProductCode"::VARCHAR, m."ProductName"::VARCHAR, m."DocumentRef"::VARCHAR,
           m."MovementType"::VARCHAR, m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost",
           m."Notes"::VARCHAR, v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted" = FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType" = p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- 3. usp_inv_movement_listperiodsummary
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo character varying DEFAULT NULL,
    p_codigo  character varying DEFAULT NULL,
    p_offset  integer DEFAULT 0,
    p_limit   integer DEFAULT 50
)
  RETURNS TABLE(
    "SummaryId"   bigint,
    "Periodo"     character varying,
    "Codigo"      character varying,
    "OpeningQty"  numeric,
    "InboundQty"  numeric,
    "OutboundQty" numeric,
    "ClosingQty"  numeric,
    fecha         date,
    "IsClosed"    boolean,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR "ProductCode" = p_codigo);

    RETURN QUERY
    SELECT s."SummaryId", s."Period"::VARCHAR, s."ProductCode"::VARCHAR, s."OpeningQty",
           s."InboundQty", s."OutboundQty", s."ClosingQty", s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$;
-- ============================================================
-- fix_bank_reconciliation_timestamps.sql
-- Corrige RETURNS TABLE de usp_bank_reconciliation_getpendingstatements
-- y usp_bank_reconciliation_getsystemmovements
-- De TIMESTAMP WITH TIME ZONE a TIMESTAMP WITHOUT TIME ZONE
-- porque fin.BankStatementLine.StatementDate y fin.BankMovement.MovementDate
-- son TIMESTAMP WITHOUT TIME ZONE
-- ============================================================

-- Para cambiar el tipo en RETURNS TABLE con CREATE OR REPLACE, primero
-- hay que DROP la firma exacta, luego recrear.

-- 1. usp_bank_reconciliation_getpendingstatements
-- Firma exacta: (p_id integer)
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getpendingstatements(p_id integer)
  RETURNS TABLE(
    id            bigint,
    "Fecha"       timestamp without time zone,
    "Descripcion" character varying,
    "Referencia"  character varying,
    "Tipo"        character varying,
    "Monto"       numeric,
    "Saldo"       numeric
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sl."StatementLineId", sl."StatementDate", sl."DescriptionText"::VARCHAR, sl."ReferenceNo"::VARCHAR,
           sl."EntryType"::VARCHAR, sl."Amount", sl."Balance"
    FROM fin."BankStatementLine" sl
    WHERE sl."ReconciliationId" = p_id AND sl."IsMatched" = FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END;
$function$;

-- 2. usp_bank_reconciliation_getsystemmovements
-- Firma exacta: (p_id integer)
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getsystemmovements(p_id integer)
  RETURNS TABLE(
    id               bigint,
    "Fecha"          timestamp without time zone,
    "Tipo"           character varying,
    "Nro_Ref"        character varying,
    "Beneficiario"   character varying,
    "Concepto"       character varying,
    "Monto"          numeric,
    "MontoNeto"      numeric,
    "SaldoPosterior" numeric,
    "Conciliado"     boolean
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."BankMovementId", m."MovementDate", m."MovementType"::VARCHAR, m."ReferenceNo"::VARCHAR,
           m."Beneficiary"::VARCHAR, m."Concept"::VARCHAR, m."Amount", m."NetAmount", m."BalanceAfter", m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId" = m."BankAccountId"
    WHERE r."BankReconciliationId" = p_id
      AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END;
$function$;
-- ============================================================
-- fix_bigint_and_char_mismatches.sql
-- Segunda ronda de fixes post-barrido TIMESTAMP:
-- - INTEGER -> BIGINT en PK/FK de tipo bigint
-- - CHARACTER(n) -> VARCHAR con cast ::VARCHAR en RETURNS TABLE + SELECT
-- - TIMESTAMP WITH TIME ZONE -> TIMESTAMP WITHOUT TIME ZONE para pay.* restantes
-- ============================================================

-- --------------------------------------------------------
-- 1. usp_pay_cardreader_list
-- pay.CardReaderDevices: Id=int4, LastSeenAt=timestamp(notz), CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId"::VARCHAR,
           cr."DeviceName"::VARCHAR, cr."DeviceType"::VARCHAR, cr."ConnectionType"::VARCHAR,
           cr."ConnectionConfig"::VARCHAR, cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE (p_company_id IS NULL OR cr."EmpresaId" = p_company_id)
    ORDER BY cr."EmpresaId", cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 2. usp_pay_cardreader_listbycompany
-- pay.CardReaderDevices: LastSeenAt=timestamp(notz), CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId"::VARCHAR,
           cr."DeviceName"::VARCHAR, cr."DeviceType"::VARCHAR, cr."ConnectionType"::VARCHAR,
           cr."ConnectionConfig"::VARCHAR, cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE cr."EmpresaId" = p_company_id
      AND cr."IsActive" = TRUE
      AND (p_branch_id IS NULL OR cr."SucursalId" = p_branch_id)
    ORDER BY cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 3. usp_pay_companyconfig_list
-- pay.CompanyPaymentConfig: CountryCode=CHAR(2) -> ::VARCHAR
-- pay.CompanyPaymentConfig: CreatedAt/UpdatedAt = timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"            integer,
    "EmpresaId"     integer,
    "SucursalId"    integer,
    "CountryCode"   character varying,
    "ProviderId"    integer,
    "ProviderCode"  character varying,
    "ProviderName"  character varying,
    "ProviderType"  character varying,
    "Environment"   character varying,
    "AutoCapture"   boolean,
    "AllowRefunds"  boolean,
    "MaxRefundDays" integer,
    "IsActive"      boolean,
    "CreatedAt"     timestamp without time zone,
    "UpdatedAt"     timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$function$;

-- --------------------------------------------------------
-- 4. usp_pay_companyconfig_listbycompany
-- pay.CompanyPaymentConfig: CountryCode=CHAR(2) -> ::VARCHAR
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "CountryCode"      character varying,
    "ProviderId"       integer,
    "ProviderCode"     character varying,
    "ProviderName"     character varying,
    "ProviderType"     character varying,
    "Environment"      character varying,
    "ClientId"         character varying,
    "ClientSecret"     character varying,
    "MerchantId"       character varying,
    "TerminalId"       character varying,
    "IntegratorId"     character varying,
    "CertificatePath"  character varying,
    "ExtraConfig"      character varying,
    "AutoCapture"      boolean,
    "AllowRefunds"     boolean,
    "MaxRefundDays"    integer,
    "IsActive"         boolean,
    "CreatedAt"        timestamp without time zone,
    "UpdatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."ClientId"::VARCHAR, cc."ClientSecret"::VARCHAR,
           cc."MerchantId"::VARCHAR, cc."TerminalId"::VARCHAR, cc."IntegratorId"::VARCHAR,
           cc."CertificatePath"::VARCHAR, cc."ExtraConfig"::VARCHAR,
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$function$;

-- --------------------------------------------------------
-- 5. usp_pay_provider_get
-- pay.PaymentProviders: CountryCode=CHAR(2) -> ::VARCHAR
-- pay.PaymentProviders: CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_provider_get(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_provider_get(p_provider_code character varying)
  RETURNS TABLE(
    "Id"             integer,
    "Code"           character varying,
    "Name"           character varying,
    "CountryCode"    character varying,
    "ProviderType"   character varying,
    "BaseUrlSandbox" character varying,
    "BaseUrlProd"    character varying,
    "AuthType"       character varying,
    "DocsUrl"        character varying,
    "LogoUrl"        character varying,
    "IsActive"       boolean,
    "CreatedAt"      timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code"::VARCHAR, pp."Name"::VARCHAR, pp."CountryCode"::VARCHAR,
           pp."ProviderType"::VARCHAR, pp."BaseUrlSandbox"::VARCHAR, pp."BaseUrlProd"::VARCHAR,
           pp."AuthType"::VARCHAR, pp."DocsUrl"::VARCHAR, pp."LogoUrl"::VARCHAR,
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 6. usp_pos_report_ventas
-- pos.SaleTicket: SaleTicketId=bigint, SoldAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_report_ventas(integer, integer, date, date, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_report_ventas(
    p_company_id integer,
    p_branch_id  integer,
    p_from_date  date,
    p_to_date    date,
    p_caja_id    character varying DEFAULT NULL,
    p_limit      integer DEFAULT 200
)
  RETURNS TABLE(
    id                   bigint,
    "numFactura"         character varying,
    fecha                timestamp without time zone,
    cliente              character varying,
    "cajaId"             character varying,
    total                numeric,
    estado               character varying,
    "metodoPago"         character varying,
    "tramaFiscal"        character varying,
    "serialFiscal"       character varying,
    "correlativoFiscal"  integer
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId",
        v."InvoiceNumber"::VARCHAR,
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::VARCHAR,
        v."CashRegisterCode"::VARCHAR,
        v."TotalAmount",
        'Completada'::VARCHAR,
        v."PaymentMethod"::VARCHAR,
        v."FiscalPayload"::VARCHAR,
        corr."SerialFiscal"::VARCHAR,
        corr."CurrentNumber"
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal", fc."CurrentNumber"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode")::character varying, 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode")::character varying THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    ORDER BY v."SoldAt" DESC, v."SaleTicketId" DESC
    LIMIT p_limit;
END;
$function$;

-- --------------------------------------------------------
-- 7. usp_pos_waitticket_getheader
-- pos.WaitTicket: WaitTicketId=bigint, CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_getheader(integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_getheader(
    p_company_id     integer,
    p_branch_id      integer,
    p_wait_ticket_id integer
)
  RETURNS TABLE(
    id               bigint,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteId"      character varying,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    "tipoPrecio"     character varying,
    motivo           character varying,
    subtotal         numeric,
    impuestos        numeric,
    total            numeric,
    estado           character varying,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerCode"::VARCHAR, wt."CustomerName"::VARCHAR, wt."CustomerFiscalId"::VARCHAR,
           wt."PriceTier"::VARCHAR, wt."Reason"::VARCHAR,
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status"::VARCHAR, wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 8. usp_pos_waitticket_list
-- pos.WaitTicket: WaitTicketId=bigint, CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_list(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_list(p_company_id integer, p_branch_id integer)
  RETURNS TABLE(
    id               bigint,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteNombre"  character varying,
    motivo           character varying,
    total            numeric,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerName"::VARCHAR, wt."Reason"::VARCHAR, wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$function$;

-- --------------------------------------------------------
-- 9. usp_rest_admin_compra_getdetalle_header
-- rest.Purchase: PurchaseId=bigint, PurchaseDate=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_getdetalle_header(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(p_compra_id integer)
  RETURNS TABLE(
    id                bigint,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying,
    "codUsuario"      character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber"::VARCHAR,
        s."SupplierCode"::VARCHAR,
        s."SupplierName"::VARCHAR,
        p."PurchaseDate",
        p."Status"::VARCHAR,
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"::VARCHAR,
        u."UserCode"::VARCHAR
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 10. usp_rest_admin_compra_list
-- rest.Purchase: PurchaseId=bigint, PurchaseDate=timestamp(notz)
-- Nota: la vieja version tenia parametros TIMESTAMPTZ, la nueva los tiene TIMESTAMP
-- Hay que eliminar AMBAS versiones si existen
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp with time zone, timestamp with time zone) CASCADE;
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp without time zone, timestamp without time zone) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_list(
    p_company_id integer,
    p_branch_id  integer,
    p_status     character varying DEFAULT NULL,
    p_from_date  timestamp without time zone DEFAULT NULL,
    p_to_date    timestamp without time zone DEFAULT NULL
)
  RETURNS TABLE(
    id                bigint,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber"::VARCHAR,
        s."SupplierCode"::VARCHAR,
        s."SupplierName"::VARCHAR,
        p."PurchaseDate",
        p."Status"::VARCHAR,
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"::VARCHAR
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_from_date IS NULL OR p."PurchaseDate" >= p_from_date)
      AND (p_to_date IS NULL OR p."PurchaseDate" <= p_to_date)
    ORDER BY p."PurchaseDate" DESC, p."PurchaseId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 11. usp_rest_orderticket_getheaderforclose
-- rest.OrderTicket: OrderTicketId=bigint, ClosedAt=timestamp(notz)
-- rest.DiningTable: DiningTableId=bigint
-- rest.OrderTicket: CountryCode=CHAR(2) -> ::VARCHAR
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_getheaderforclose(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(p_pedido_id integer)
  RETURNS TABLE(
    id               bigint,
    "empresaId"      integer,
    "sucursalId"     integer,
    "countryCode"    character varying,
    "mesaId"         bigint,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    estado           character varying,
    total            numeric,
    "fechaCierre"    timestamp without time zone,
    "codUsuario"     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId", o."CountryCode"::VARCHAR, dt."DiningTableId",
           o."CustomerName"::VARCHAR, o."CustomerFiscalId"::VARCHAR, o."Status"::VARCHAR,
           o."TotalAmount", o."ClosedAt",
           COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId" = o."CompanyId"
      AND dt."BranchId" = o."BranchId" AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id
    LIMIT 1;
END;
$function$;
