-- ============================================================
-- usp_sys_Subscription_CheckAccess
-- Verifica si una empresa tiene suscripcion activa
-- Retorna: ok=true si puede acceder, ok=false si no
-- Empresas con Plan='FREE' o CompanyId <= 1 siempre tienen acceso
-- ============================================================
DROP FUNCTION IF EXISTS usp_sys_Subscription_CheckAccess(INT) CASCADE;

CREATE OR REPLACE FUNCTION usp_sys_Subscription_CheckAccess(
  p_company_id INT
)
RETURNS TABLE(
  "ok"              BOOLEAN,
  "reason"          VARCHAR,
  "plan"            VARCHAR,
  "status"          VARCHAR,
  "expiresAt"       TIMESTAMP,
  "daysRemaining"   INT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_company RECORD;
  v_sub RECORD;
BEGIN
  -- 1. Buscar la empresa
  SELECT c."CompanyId", c."Plan", c."TenantStatus", c."IsActive"
  INTO v_company
  FROM cfg."Company" c
  WHERE c."CompanyId" = p_company_id AND c."IsDeleted" = FALSE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_NOT_FOUND'::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 2. Empresa inactiva
  IF v_company."IsActive" = FALSE THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_INACTIVE'::VARCHAR, v_company."Plan"::VARCHAR, 'inactive'::VARCHAR, NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 3. Empresa DEFAULT (CompanyId=1), plan FREE o ENTERPRISE: siempre acceso
  IF p_company_id <= 1 OR v_company."Plan" IN ('FREE', 'ENTERPRISE') THEN
    RETURN QUERY SELECT TRUE, 'EXEMPT'::VARCHAR, v_company."Plan"::VARCHAR, 'active'::VARCHAR, NULL::TIMESTAMP, 999;
    RETURN;
  END IF;

  -- 4. TenantStatus suspendido
  IF v_company."TenantStatus" IN ('SUSPENDED', 'CANCELLED') THEN
    RETURN QUERY SELECT FALSE, 'TENANT_SUSPENDED'::VARCHAR, v_company."Plan"::VARCHAR, v_company."TenantStatus"::VARCHAR, NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 5. Buscar suscripcion activa
  SELECT s."Status", s."CurrentPeriodEnd", s."CancelledAt"
  INTO v_sub
  FROM sys."Subscription" s
  WHERE s."CompanyId" = p_company_id
  ORDER BY s."CreatedAt" DESC
  LIMIT 1;

  -- 6. No hay suscripcion registrada pero fue provisionado (grace period)
  IF NOT FOUND THEN
    -- Si fue provisionado hace menos de 30 dias, dar acceso (grace period)
    IF v_company."TenantStatus" = 'ACTIVE' THEN
      RETURN QUERY SELECT TRUE, 'GRACE_PERIOD'::VARCHAR, v_company."Plan"::VARCHAR, 'active'::VARCHAR, NULL::TIMESTAMP, 30;
      RETURN;
    END IF;
    RETURN QUERY SELECT FALSE, 'NO_SUBSCRIPTION'::VARCHAR, v_company."Plan"::VARCHAR, 'none'::VARCHAR, NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 7. Suscripcion cancelada
  IF v_sub."Status" = 'canceled' THEN
    -- Si CurrentPeriodEnd aun no pasó, permitir acceso hasta que expire
    IF v_sub."CurrentPeriodEnd" IS NOT NULL AND v_sub."CurrentPeriodEnd" > (NOW() AT TIME ZONE 'UTC') THEN
      RETURN QUERY SELECT TRUE, 'CANCELING_ACTIVE'::VARCHAR, v_company."Plan"::VARCHAR, 'canceled'::VARCHAR,
        v_sub."CurrentPeriodEnd",
        GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT);
      RETURN;
    END IF;
    RETURN QUERY SELECT FALSE, 'SUBSCRIPTION_EXPIRED'::VARCHAR, v_company."Plan"::VARCHAR, 'expired'::VARCHAR,
      v_sub."CurrentPeriodEnd", 0;
    RETURN;
  END IF;

  -- 8. Suscripcion past_due
  IF v_sub."Status" = 'past_due' THEN
    RETURN QUERY SELECT TRUE, 'PAST_DUE'::VARCHAR, v_company."Plan"::VARCHAR, 'past_due'::VARCHAR,
      v_sub."CurrentPeriodEnd",
      COALESCE(GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT), 0);
    RETURN;
  END IF;

  -- 9. Suscripcion activa
  IF v_sub."Status" IN ('active', 'trialing') THEN
    RETURN QUERY SELECT TRUE, 'ACTIVE'::VARCHAR, v_company."Plan"::VARCHAR, v_sub."Status"::VARCHAR,
      v_sub."CurrentPeriodEnd",
      COALESCE(GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT), 999);
    RETURN;
  END IF;

  -- 10. Status desconocido - permitir por seguridad
  RETURN QUERY SELECT TRUE, 'UNKNOWN_STATUS'::VARCHAR, v_company."Plan"::VARCHAR, v_sub."Status"::VARCHAR, v_sub."CurrentPeriodEnd", 0;
END;
$$;
