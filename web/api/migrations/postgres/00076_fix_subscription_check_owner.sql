-- +goose Up
-- Migration: fix_subscription_check_owner
-- La suscripcion pertenece al ADMIN (usuario base/dueno de la cuenta).
-- Los usuarios hijos (GERENTE, CAJERO, etc.) heredan la suscripcion del admin.
-- Se valida en el login, no por request ni por empresa.

DROP FUNCTION IF EXISTS public.usp_sys_subscription_checkaccess(integer);
DROP FUNCTION IF EXISTS public.usp_sys_subscription_checkaccess(integer, varchar);
DROP FUNCTION IF EXISTS public.usp_sys_subscription_checkaccess(varchar);

CREATE OR REPLACE FUNCTION public.usp_sys_subscription_checkaccess(
  p_user_code varchar
)
RETURNS TABLE(
  ok boolean,
  reason character varying,
  plan character varying,
  status character varying,
  "expiresAt" timestamp without time zone,
  "daysRemaining" integer
)
LANGUAGE plpgsql AS $function$
DECLARE
  v_admin_code VARCHAR;
  v_company_id INT;
  v_plan       VARCHAR;
  v_status     VARCHAR;
  v_sub        RECORD;
BEGIN
  -- 1. Buscar la empresa base del usuario que hace login
  SELECT u."CompanyId" INTO v_company_id
  FROM sec."User" u
  WHERE u."UserCode" = p_user_code AND u."IsActive" = TRUE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT TRUE, 'EXEMPT'::VARCHAR,
                        'FREE'::VARCHAR, 'active'::VARCHAR,
                        NULL::TIMESTAMP, 999;
    RETURN;
  END IF;

  -- 2. Buscar el ADMIN de esa empresa (el dueno del billing)
  SELECT u."UserCode" INTO v_admin_code
  FROM sec."User" u
  WHERE u."CompanyId" = v_company_id
    AND u."UserType" = 'ADMIN'
    AND u."IsAdmin" = TRUE
    AND u."IsActive" = TRUE
  ORDER BY u."UserId"
  LIMIT 1;

  -- Si no hay admin, el usuario es su propio dueno
  IF NOT FOUND THEN
    v_admin_code := p_user_code;
  END IF;

  -- 3. Buscar el mejor plan entre las empresas del ADMIN
  SELECT c."Plan", c."TenantStatus"
  INTO v_plan, v_status
  FROM sec."UserCompanyAccess" ua
  JOIN cfg."Company" c ON c."CompanyId" = ua."CompanyId"
                       AND c."IsDeleted" = FALSE AND c."IsActive" = TRUE
  WHERE ua."CodUsuario" = v_admin_code AND ua."IsActive" = TRUE
    AND c."Plan" IS NOT NULL
  ORDER BY
    CASE c."Plan"
      WHEN 'ENTERPRISE' THEN 0 WHEN 'PRO' THEN 1
      WHEN 'STARTER' THEN 2 WHEN 'FREE' THEN 3 ELSE 4
    END
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT TRUE, 'EXEMPT'::VARCHAR,
                        'FREE'::VARCHAR, 'active'::VARCHAR,
                        NULL::TIMESTAMP, 999;
    RETURN;
  END IF;

  v_plan   := COALESCE(v_plan, 'FREE');
  v_status := COALESCE(v_status, 'ACTIVE');

  -- 4. FREE o ENTERPRISE: no necesitan Paddle
  IF v_plan IN ('FREE', 'ENTERPRISE') THEN
    RETURN QUERY SELECT TRUE, 'EXEMPT'::VARCHAR,
                        v_plan::VARCHAR, 'active'::VARCHAR,
                        NULL::TIMESTAMP, 999;
    RETURN;
  END IF;

  -- 5. Tenant suspendido/cancelado
  IF v_status IN ('SUSPENDED', 'CANCELLED') THEN
    RETURN QUERY SELECT FALSE, 'TENANT_SUSPENDED'::VARCHAR,
                        v_plan::VARCHAR, v_status::VARCHAR,
                        NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 6. Buscar suscripcion Paddle en las empresas del ADMIN
  SELECT s."Status", s."CurrentPeriodEnd", s."CancelledAt"
  INTO v_sub
  FROM sys."Subscription" s
  JOIN sec."UserCompanyAccess" ua ON ua."CompanyId" = s."CompanyId"
                                  AND ua."CodUsuario" = v_admin_code
                                  AND ua."IsActive" = TRUE
  ORDER BY s."CreatedAt" DESC
  LIMIT 1;

  -- 7. Sin suscripcion Paddle
  IF NOT FOUND THEN
    IF v_status = 'ACTIVE' THEN
      RETURN QUERY SELECT TRUE, 'GRACE_PERIOD'::VARCHAR,
                          v_plan::VARCHAR, 'active'::VARCHAR,
                          NULL::TIMESTAMP, 30;
      RETURN;
    END IF;
    RETURN QUERY SELECT FALSE, 'NO_SUBSCRIPTION'::VARCHAR,
                        v_plan::VARCHAR, 'none'::VARCHAR,
                        NULL::TIMESTAMP, 0;
    RETURN;
  END IF;

  -- 8. Cancelada
  IF v_sub."Status" = 'canceled' THEN
    IF v_sub."CurrentPeriodEnd" IS NOT NULL
       AND v_sub."CurrentPeriodEnd" > (NOW() AT TIME ZONE 'UTC') THEN
      RETURN QUERY SELECT TRUE, 'CANCELING_ACTIVE'::VARCHAR,
                          v_plan::VARCHAR, 'canceled'::VARCHAR,
                          v_sub."CurrentPeriodEnd",
                          GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT);
      RETURN;
    END IF;
    RETURN QUERY SELECT FALSE, 'SUBSCRIPTION_EXPIRED'::VARCHAR,
                        v_plan::VARCHAR, 'expired'::VARCHAR,
                        v_sub."CurrentPeriodEnd", 0;
    RETURN;
  END IF;

  -- 9. Past due
  IF v_sub."Status" = 'past_due' THEN
    RETURN QUERY SELECT TRUE, 'PAST_DUE'::VARCHAR,
                        v_plan::VARCHAR, 'past_due'::VARCHAR,
                        v_sub."CurrentPeriodEnd",
                        COALESCE(GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT), 0);
    RETURN;
  END IF;

  -- 10. Activa
  IF v_sub."Status" IN ('active', 'trialing') THEN
    RETURN QUERY SELECT TRUE, 'ACTIVE'::VARCHAR,
                        v_plan::VARCHAR, v_sub."Status"::VARCHAR,
                        v_sub."CurrentPeriodEnd",
                        COALESCE(GREATEST(0, EXTRACT(DAY FROM v_sub."CurrentPeriodEnd" - (NOW() AT TIME ZONE 'UTC'))::INT), 999);
    RETURN;
  END IF;

  -- 11. Status desconocido
  RETURN QUERY SELECT TRUE, 'UNKNOWN_STATUS'::VARCHAR,
                      v_plan::VARCHAR, v_sub."Status"::VARCHAR,
                      v_sub."CurrentPeriodEnd", 0;
END;
$function$;

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_sys_subscription_checkaccess(varchar);
CREATE OR REPLACE FUNCTION public.usp_sys_subscription_checkaccess(p_company_id integer)
RETURNS TABLE(ok boolean, reason character varying, plan character varying, status character varying, "expiresAt" timestamp without time zone, "daysRemaining" integer)
LANGUAGE plpgsql AS $function$
DECLARE v_company RECORD; v_sub RECORD;
BEGIN
  SELECT c."CompanyId",c."Plan",c."TenantStatus",c."IsActive" INTO v_company FROM cfg."Company" c WHERE c."CompanyId"=p_company_id AND c."IsDeleted"=FALSE;
  IF NOT FOUND THEN RETURN QUERY SELECT FALSE,'COMPANY_NOT_FOUND'::VARCHAR,NULL::VARCHAR,NULL::VARCHAR,NULL::TIMESTAMP,0; RETURN; END IF;
  IF v_company."IsActive"=FALSE THEN RETURN QUERY SELECT FALSE,'COMPANY_INACTIVE'::VARCHAR,v_company."Plan"::VARCHAR,'inactive'::VARCHAR,NULL::TIMESTAMP,0; RETURN; END IF;
  IF p_company_id<=1 OR v_company."Plan" IN ('FREE','ENTERPRISE') THEN RETURN QUERY SELECT TRUE,'EXEMPT'::VARCHAR,v_company."Plan"::VARCHAR,'active'::VARCHAR,NULL::TIMESTAMP,999; RETURN; END IF;
  IF v_company."TenantStatus" IN ('SUSPENDED','CANCELLED') THEN RETURN QUERY SELECT FALSE,'TENANT_SUSPENDED'::VARCHAR,v_company."Plan"::VARCHAR,v_company."TenantStatus"::VARCHAR,NULL::TIMESTAMP,0; RETURN; END IF;
  SELECT s."Status",s."CurrentPeriodEnd",s."CancelledAt" INTO v_sub FROM sys."Subscription" s WHERE s."CompanyId"=p_company_id ORDER BY s."CreatedAt" DESC LIMIT 1;
  IF NOT FOUND THEN IF v_company."TenantStatus"='ACTIVE' THEN RETURN QUERY SELECT TRUE,'GRACE_PERIOD'::VARCHAR,v_company."Plan"::VARCHAR,'active'::VARCHAR,NULL::TIMESTAMP,30; RETURN; END IF; RETURN QUERY SELECT FALSE,'NO_SUBSCRIPTION'::VARCHAR,v_company."Plan"::VARCHAR,'none'::VARCHAR,NULL::TIMESTAMP,0; RETURN; END IF;
  IF v_sub."Status"='canceled' THEN IF v_sub."CurrentPeriodEnd" IS NOT NULL AND v_sub."CurrentPeriodEnd">(NOW() AT TIME ZONE 'UTC') THEN RETURN QUERY SELECT TRUE,'CANCELING_ACTIVE'::VARCHAR,v_company."Plan"::VARCHAR,'canceled'::VARCHAR,v_sub."CurrentPeriodEnd",GREATEST(0,EXTRACT(DAY FROM v_sub."CurrentPeriodEnd"-(NOW() AT TIME ZONE 'UTC'))::INT); RETURN; END IF; RETURN QUERY SELECT FALSE,'SUBSCRIPTION_EXPIRED'::VARCHAR,v_company."Plan"::VARCHAR,'expired'::VARCHAR,v_sub."CurrentPeriodEnd",0; RETURN; END IF;
  IF v_sub."Status"='past_due' THEN RETURN QUERY SELECT TRUE,'PAST_DUE'::VARCHAR,v_company."Plan"::VARCHAR,'past_due'::VARCHAR,v_sub."CurrentPeriodEnd",COALESCE(GREATEST(0,EXTRACT(DAY FROM v_sub."CurrentPeriodEnd"-(NOW() AT TIME ZONE 'UTC'))::INT),0); RETURN; END IF;
  IF v_sub."Status" IN ('active','trialing') THEN RETURN QUERY SELECT TRUE,'ACTIVE'::VARCHAR,v_company."Plan"::VARCHAR,v_sub."Status"::VARCHAR,v_sub."CurrentPeriodEnd",COALESCE(GREATEST(0,EXTRACT(DAY FROM v_sub."CurrentPeriodEnd"-(NOW() AT TIME ZONE 'UTC'))::INT),999); RETURN; END IF;
  RETURN QUERY SELECT TRUE,'UNKNOWN_STATUS'::VARCHAR,v_company."Plan"::VARCHAR,v_sub."Status"::VARCHAR,v_sub."CurrentPeriodEnd",0;
END;
$function$;
