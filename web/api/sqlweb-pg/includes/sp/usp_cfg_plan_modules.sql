-- ============================================================
-- usp_cfg_plan_modules.sql â€” MÃ³dulos por plan + apply a tenant
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_cfg_plan_modules.sql
-- ============================================================

-- SP: obtener mÃ³dulos de un plan
DROP FUNCTION IF EXISTS public.usp_cfg_plan_getmodules(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_cfg_plan_getmodules(p_plan VARCHAR)
RETURNS TABLE("ModuleCode" VARCHAR, "SortOrder" SMALLINT)
LANGUAGE plpgsql AS $$
DECLARE
  v_count INT;
BEGIN
  -- Verificar si hay datos en la tabla
  SELECT COUNT(*) INTO v_count
  FROM cfg."PlanModule"
  WHERE "PlanCode" = p_plan AND "IsEnabled" = TRUE;

  IF v_count > 0 THEN
    -- Usar datos de la tabla
    RETURN QUERY
      SELECT pm."ModuleCode"::VARCHAR, pm."SortOrder"
      FROM cfg."PlanModule" pm
      WHERE pm."PlanCode" = p_plan AND pm."IsEnabled" = TRUE
      ORDER BY pm."SortOrder";
  ELSE
    -- Fallback hardcoded por si la tabla estÃ¡ vacÃ­a
    RETURN QUERY
      SELECT t.code::VARCHAR, t.ord::SMALLINT
      FROM unnest(
        CASE p_plan
          WHEN 'FREE' THEN ARRAY['dashboard','facturas','clientes','inventario','articulos','reportes']
          WHEN 'STARTER' THEN ARRAY['dashboard','facturas','abonos','cxc','clientes','compras','cxp',
                                    'cuentas-por-pagar','proveedores','inventario','articulos','pagos',
                                    'bancos','reportes','configuracion','usuarios']
          WHEN 'PRO' THEN ARRAY['dashboard','facturas','abonos','cxc','clientes','compras','cxp',
                                'cuentas-por-pagar','proveedores','inventario','articulos','pagos',
                                'bancos','reportes','configuracion','usuarios','contabilidad','nomina',
                                'pos','restaurante','ecommerce','auditoria','logistica','crm','shipping']
          WHEN 'ENTERPRISE' THEN ARRAY['dashboard','facturas','abonos','cxc','clientes','compras','cxp',
                                       'cuentas-por-pagar','proveedores','inventario','articulos','pagos',
                                       'bancos','reportes','configuracion','usuarios','contabilidad','nomina',
                                       'pos','restaurante','ecommerce','auditoria','logistica','crm',
                                       'shipping','manufactura','flota']
          ELSE ARRAY['dashboard']::TEXT[]
        END
      ) WITH ORDINALITY AS t(code, ord)
      ORDER BY t.ord::SMALLINT;
  END IF;
END; $$;

-- SP: aplicar mÃ³dulos de un plan al usuario admin del tenant
DROP FUNCTION IF EXISTS public.usp_cfg_plan_applymodules(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_cfg_plan_applymodules(
  p_company_id INT,
  p_plan       VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "modules_applied" INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_admin_code VARCHAR(30);
  v_count      INT := 0;
  v_module     RECORD;
BEGIN
  -- Obtener usuario admin del tenant
  SELECT "UserCode" INTO v_admin_code
  FROM sec."User"
  WHERE "CompanyId" = p_company_id
    AND "IsAdmin" = TRUE
    AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_admin_code IS NULL THEN
    RETURN QUERY SELECT FALSE, 'ADMIN_NOT_FOUND'::VARCHAR, 0;
    RETURN;
  END IF;

  -- Limpiar accesos anteriores del admin
  DELETE FROM sec."UserModuleAccess"
  WHERE "UserCode" = v_admin_code;

  -- Insertar mÃ³dulos del plan
  FOR v_module IN
    SELECT m."ModuleCode", m."SortOrder"
    FROM usp_cfg_plan_getmodules(p_plan) m
  LOOP
    INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
    VALUES (v_admin_code, v_module."ModuleCode", TRUE)
    ON CONFLICT ("UserCode", "ModuleCode") DO UPDATE SET "IsAllowed" = TRUE;
    v_count := v_count + 1;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'MODULES_APPLIED'::VARCHAR, v_count;
END; $$;
