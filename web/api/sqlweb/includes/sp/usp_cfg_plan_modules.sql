-- ============================================================
-- usp_cfg_plan_modules.sql — Módulos por plan + apply a tenant
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_cfg_plan_modules.sql
-- ============================================================

-- SP: obtener módulos de un plan
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Plan_GetModules
  @Plan NVARCHAR(30)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Count INT;
  SELECT @Count = COUNT(*)
  FROM cfg.PlanModule
  WHERE PlanCode = @Plan AND IsEnabled = 1;

  IF @Count > 0
  BEGIN
    -- Usar datos de la tabla
    SELECT ModuleCode, SortOrder
    FROM cfg.PlanModule
    WHERE PlanCode = @Plan AND IsEnabled = 1
    ORDER BY SortOrder;
  END
  ELSE
  BEGIN
    -- Fallback hardcoded
    SELECT ModuleCode, SortOrder
    FROM (
      SELECT 'dashboard' AS ModuleCode, 1 AS SortOrder
      UNION ALL SELECT 'facturas', 2
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'abonos' ELSE NULL END, 3
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'cxc' ELSE NULL END, 4
      UNION ALL SELECT CASE WHEN @Plan IN ('FREE','STARTER','PRO','ENTERPRISE') THEN 'clientes' ELSE NULL END, 5
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'compras' ELSE NULL END, 6
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'cxp' ELSE NULL END, 7
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'cuentas-por-pagar' ELSE NULL END, 8
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'proveedores' ELSE NULL END, 9
      UNION ALL SELECT CASE WHEN @Plan IN ('FREE','STARTER','PRO','ENTERPRISE') THEN 'inventario' ELSE NULL END, 10
      UNION ALL SELECT CASE WHEN @Plan IN ('FREE','STARTER','PRO','ENTERPRISE') THEN 'articulos' ELSE NULL END, 11
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'pagos' ELSE NULL END, 12
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'bancos' ELSE NULL END, 13
      UNION ALL SELECT CASE WHEN @Plan IN ('FREE','STARTER','PRO','ENTERPRISE') THEN 'reportes' ELSE NULL END, 14
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'configuracion' ELSE NULL END, 15
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'usuarios' ELSE NULL END, 16
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'contabilidad' ELSE NULL END, 17
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'nomina' ELSE NULL END, 18
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'pos' ELSE NULL END, 19
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'restaurante' ELSE NULL END, 20
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'ecommerce' ELSE NULL END, 21
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'auditoria' ELSE NULL END, 22
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'logistica' ELSE NULL END, 23
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'crm' ELSE NULL END, 24
      UNION ALL SELECT CASE WHEN @Plan IN ('PRO','ENTERPRISE') THEN 'shipping' ELSE NULL END, 25
      UNION ALL SELECT CASE WHEN @Plan = 'ENTERPRISE' THEN 'manufactura' ELSE NULL END, 26
      UNION ALL SELECT CASE WHEN @Plan = 'ENTERPRISE' THEN 'flota' ELSE NULL END, 27
    ) t WHERE ModuleCode IS NOT NULL
    ORDER BY SortOrder;
  END
END
GO

-- SP: aplicar módulos de un plan al usuario admin del tenant
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Plan_ApplyModules
  @CompanyId INT,
  @Plan      NVARCHAR(30),
  @Ok        INT OUTPUT,
  @Mensaje   NVARCHAR(200) OUTPUT,
  @ModulesApplied INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @AdminCode NVARCHAR(30);
  SET @ModulesApplied = 0;

  -- Obtener usuario admin del tenant
  SELECT TOP 1 @AdminCode = UserCode
  FROM sec.[User]
  WHERE CompanyId = @CompanyId
    AND IsAdmin = 1
    AND IsDeleted = 0;

  IF @AdminCode IS NULL
  BEGIN
    SET @Ok = 0;
    SET @Mensaje = 'ADMIN_NOT_FOUND';
    RETURN;
  END

  -- Limpiar accesos anteriores
  DELETE FROM sec.UserModuleAccess WHERE UserCode = @AdminCode;

  -- Crear tabla temporal con módulos del plan
  CREATE TABLE #PlanModules (ModuleCode NVARCHAR(60), SortOrder SMALLINT);

  DECLARE @Count INT;
  SELECT @Count = COUNT(*) FROM cfg.PlanModule WHERE PlanCode = @Plan AND IsEnabled = 1;

  IF @Count > 0
  BEGIN
    INSERT INTO #PlanModules (ModuleCode, SortOrder)
    SELECT ModuleCode, SortOrder FROM cfg.PlanModule
    WHERE PlanCode = @Plan AND IsEnabled = 1;
  END
  ELSE
  BEGIN
    -- Fallback inline
    INSERT INTO #PlanModules (ModuleCode, SortOrder)
    SELECT ModuleCode, SortOrder FROM (
      SELECT 'dashboard',1 UNION ALL SELECT 'facturas',2
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'abonos' ELSE NULL END,3
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'clientes' ELSE NULL END,5
      UNION ALL SELECT CASE WHEN @Plan IN ('STARTER','PRO','ENTERPRISE') THEN 'inventario' ELSE NULL END,10
    ) t(ModuleCode, SortOrder) WHERE ModuleCode IS NOT NULL;
  END

  -- Insertar accesos
  INSERT INTO sec.UserModuleAccess (UserCode, ModuleCode, IsAllowed)
  SELECT @AdminCode, ModuleCode, 1
  FROM #PlanModules;

  SET @ModulesApplied = @@ROWCOUNT;
  DROP TABLE #PlanModules;

  SET @Ok = 1;
  SET @Mensaje = 'MODULES_APPLIED';
END
GO
