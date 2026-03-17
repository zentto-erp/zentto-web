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
