-- ============================================================
-- usp_Cfg_Tenant_Provision
-- Aprovisiona un nuevo tenant: Company + Branch + User admin +
-- UserCompanyAccess + seed moneda base
-- Transaccional: si falla cualquier paso hace ROLLBACK
-- ============================================================
DROP FUNCTION IF EXISTS usp_Cfg_Tenant_Provision(
  VARCHAR, VARCHAR, VARCHAR, CHAR(2), CHAR(3), VARCHAR, VARCHAR, VARCHAR, VARCHAR
) CASCADE;

CREATE OR REPLACE FUNCTION usp_Cfg_Tenant_Provision(
  p_company_code            VARCHAR(20),
  p_legal_name              VARCHAR(200),
  p_owner_email             VARCHAR(150),
  p_country_code            CHAR(2),
  p_base_currency           CHAR(3),
  p_admin_user_code         VARCHAR(40),
  p_admin_password_hash     VARCHAR(255),
  p_plan                    VARCHAR(30)   DEFAULT 'STARTER',
  p_paddle_subscription_id  VARCHAR(100)  DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "CompanyId" INT, "UserId" INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id   INT;
  v_branch_id    INT;
  v_user_id      INT;
  v_system_id    INT := 1;
BEGIN
  -- Obtener UserId del usuario SYSTEM
  SELECT "UserId" INTO v_system_id
  FROM sec."User" WHERE "UserCode" = 'SYSTEM' LIMIT 1;

  -- 0. Validar unicidad
  IF EXISTS (
    SELECT 1 FROM cfg."Company"
    WHERE LOWER("OwnerEmail") = LOWER(p_owner_email) AND "IsDeleted" = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'EMAIL_ALREADY_EXISTS'::VARCHAR, 0, 0;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM cfg."Company"
    WHERE UPPER("CompanyCode") = UPPER(p_company_code) AND "IsDeleted" = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_CODE_ALREADY_EXISTS'::VARCHAR, 0, 0;
    RETURN;
  END IF;

  -- 1. Crear cfg.Company
  INSERT INTO cfg."Company" (
    "CompanyCode", "LegalName", "FiscalCountryCode", "BaseCurrency",
    "IsActive", "Plan", "TenantStatus", "OwnerEmail", "ProvisionedAt",
    "PaddleSubscriptionId", "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    UPPER(p_company_code), p_legal_name, UPPER(p_country_code), UPPER(p_base_currency),
    TRUE, UPPER(p_plan), 'ACTIVE', LOWER(p_owner_email),
    NOW() AT TIME ZONE 'UTC', p_paddle_subscription_id, v_system_id, v_system_id
  ) RETURNING "CompanyId" INTO v_company_id;

  -- 2. Crear cfg.Branch principal
  INSERT INTO cfg."Branch" (
    "CompanyId", "BranchCode", "BranchName",
    "IsActive", "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    v_company_id, 'MAIN', 'Principal',
    TRUE, v_system_id, v_system_id
  ) RETURNING "BranchId" INTO v_branch_id;

  -- 3. Crear sec.User admin del tenant
  INSERT INTO sec."User" (
    "UserCode", "UserName", "PasswordHash", "Email",
    "IsAdmin", "IsActive", "UserType", "Role",
    "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
    "CanChangePwd", "CanChangePrice", "CanGiveCredit",
    "CompanyId", "DisplayName",
    "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    UPPER(p_admin_user_code), p_legal_name,
    p_admin_password_hash, LOWER(p_owner_email),
    TRUE, TRUE, 'ADMIN', 'admin',
    TRUE, TRUE, TRUE, TRUE,
    TRUE, FALSE, FALSE,
    v_company_id, 'Administrador',
    v_system_id, v_system_id
  ) RETURNING "UserId" INTO v_user_id;

  -- 4. Acceso multi-tenant (IsDefault = TRUE)
  INSERT INTO sec."UserCompanyAccess"
    ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
  VALUES
    (UPPER(p_admin_user_code), v_company_id, v_branch_id, TRUE, TRUE)
  ON CONFLICT ("CodUsuario", "CompanyId", "BranchId")
  DO UPDATE SET
    "IsActive"  = TRUE,
    "IsDefault" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  -- 5. Seed: tasa de cambio base (1.0) si no existe
  INSERT INTO cfg."ExchangeRateDaily"
    ("CurrencyCode", "RateToBase", "RateDate", "SourceName", "CreatedByUserId")
  VALUES
    (UPPER(p_base_currency), 1.000000, CURRENT_DATE, 'PROVISION_SEED', v_system_id)
  ON CONFLICT DO NOTHING;

  -- 6. Generar subdomain: companycode en minusculas
  UPDATE cfg."Company"
  SET "TenantSubdomain" = LOWER(p_company_code)
  WHERE "CompanyId" = v_company_id;

  RETURN QUERY SELECT TRUE, 'TENANT_PROVISIONED'::VARCHAR, v_company_id, v_user_id;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, SQLERRM::VARCHAR, 0, 0;
END;
$$;
