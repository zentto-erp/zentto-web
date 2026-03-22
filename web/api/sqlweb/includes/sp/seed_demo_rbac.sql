/*
 * seed_demo_rbac.sql
 * ──────────────────
 * Seed de datos demo para RBAC (Role-Based Access Control) en esquema sec.
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   sec.Permission, sec.Role, sec.RolePermission,
 *   sec.PriceRestriction, sec.ApprovalRule
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: RBAC (sec) ===';
GO

-- ============================================================================
-- SECCION 1: sec.Permission  (15 modulos x 8 acciones = 120 permisos)
-- ============================================================================
PRINT '>> 1. Catalogo de permisos (120 registros)...';

-- Helper: insertar permisos para un modulo
-- Modulos: ventas, compras, inventario, bancos, contabilidad, nomina, rrhh,
--          pos, restaurante, auditoria, crm, manufactura, flota, logistica, permisos

DECLARE @modules TABLE (ModuleName NVARCHAR(50), ModuleLabel NVARCHAR(100));
INSERT INTO @modules VALUES
  (N'ventas',        N'Ventas'),
  (N'compras',       N'Compras'),
  (N'inventario',    N'Inventario'),
  (N'bancos',        N'Bancos'),
  (N'contabilidad',  N'Contabilidad'),
  (N'nomina',        N'Nomina'),
  (N'rrhh',          N'Recursos Humanos'),
  (N'pos',           N'Punto de Venta'),
  (N'restaurante',   N'Restaurante'),
  (N'auditoria',     N'Auditoria'),
  (N'crm',           N'CRM'),
  (N'manufactura',   N'Manufactura'),
  (N'flota',         N'Flota Vehicular'),
  (N'logistica',     N'Logistica'),
  (N'permisos',      N'Permisos');

DECLARE @actions TABLE (ActionCode NVARCHAR(20), ActionLabel NVARCHAR(50));
INSERT INTO @actions VALUES
  (N'VIEW',    N'Ver'),
  (N'CREATE',  N'Crear'),
  (N'EDIT',    N'Editar'),
  (N'DELETE',  N'Eliminar'),
  (N'VOID',    N'Anular'),
  (N'APPROVE', N'Aprobar'),
  (N'EXPORT',  N'Exportar'),
  (N'PRINT',   N'Imprimir');

INSERT INTO sec.Permission (CompanyId, PermissionCode, PermissionName, Module, Action, Description, IsActive, CreatedByUserId, CreatedAt)
SELECT 1,
  m.ModuleName + N'.' + a.ActionCode,
  m.ModuleLabel + N' - ' + a.ActionLabel,
  m.ModuleName,
  a.ActionCode,
  N'Permiso para ' + LOWER(a.ActionLabel) + N' en modulo ' + m.ModuleLabel,
  1, 1, SYSUTCDATETIME()
FROM @modules m
CROSS JOIN @actions a
WHERE NOT EXISTS (
  SELECT 1 FROM sec.Permission
  WHERE CompanyId = 1 AND PermissionCode = m.ModuleName + N'.' + a.ActionCode
);
GO

-- ============================================================================
-- SECCION 2: sec.Role  (5 roles)
-- ============================================================================
PRINT '>> 2. Roles...';

IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'ADMIN')
  INSERT INTO sec.Role (CompanyId, RoleCode, RoleName, Description, IsSystem, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'ADMIN', N'Administrador', N'Acceso total al sistema - todos los permisos', 1, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'GERENTE')
  INSERT INTO sec.Role (CompanyId, RoleCode, RoleName, Description, IsSystem, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'GERENTE', N'Gerente', N'Acceso de supervision y aprobacion con permisos amplios', 0, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'VENDEDOR')
  INSERT INTO sec.Role (CompanyId, RoleCode, RoleName, Description, IsSystem, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'VENDEDOR', N'Vendedor', N'Acceso a ventas y CRM con permisos limitados', 0, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'ALMACENISTA')
  INSERT INTO sec.Role (CompanyId, RoleCode, RoleName, Description, IsSystem, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'ALMACENISTA', N'Almacenista', N'Acceso completo a inventario y logistica', 0, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'CONTADOR')
  INSERT INTO sec.Role (CompanyId, RoleCode, RoleName, Description, IsSystem, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'CONTADOR', N'Contador', N'Acceso completo a contabilidad y bancos', 0, 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 3: sec.RolePermission  (asignacion de permisos a roles)
-- ============================================================================
PRINT '>> 3. Permisos por rol...';

-- 3a. ADMIN: TODOS los permisos (120)
DECLARE @RoleAdmin INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'ADMIN');

IF @RoleAdmin IS NOT NULL
BEGIN
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleAdmin, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleAdmin AND rp.PermissionId = p.PermissionId);
END;

-- 3b. GERENTE: VIEW+EXPORT+PRINT para todos + CREATE+EDIT para ventas,compras,inventario,crm
DECLARE @RoleGerente INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'GERENTE');

IF @RoleGerente IS NOT NULL
BEGIN
  -- VIEW, EXPORT, PRINT para todos los modulos
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleGerente, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Action IN (N'VIEW', N'EXPORT', N'PRINT')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleGerente AND rp.PermissionId = p.PermissionId);

  -- CREATE, EDIT para ventas, compras, inventario, crm
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleGerente, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module IN (N'ventas', N'compras', N'inventario', N'crm')
    AND p.Action IN (N'CREATE', N'EDIT')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleGerente AND rp.PermissionId = p.PermissionId);
END;

-- 3c. VENDEDOR: VIEW para todos + CREATE+EDIT para ventas,crm + PRINT para ventas
DECLARE @RoleVendedor INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'VENDEDOR');

IF @RoleVendedor IS NOT NULL
BEGIN
  -- VIEW para todos los modulos
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleVendedor, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Action = N'VIEW'
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleVendedor AND rp.PermissionId = p.PermissionId);

  -- CREATE, EDIT para ventas, crm
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleVendedor, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module IN (N'ventas', N'crm')
    AND p.Action IN (N'CREATE', N'EDIT')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleVendedor AND rp.PermissionId = p.PermissionId);

  -- PRINT para ventas
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleVendedor, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module = N'ventas'
    AND p.Action = N'PRINT'
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleVendedor AND rp.PermissionId = p.PermissionId);
END;

-- 3d. ALMACENISTA: todos permisos para inventario,logistica + VIEW para compras,ventas
DECLARE @RoleAlmacenista INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'ALMACENISTA');

IF @RoleAlmacenista IS NOT NULL
BEGIN
  -- Todos los permisos para inventario y logistica
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleAlmacenista, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module IN (N'inventario', N'logistica')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleAlmacenista AND rp.PermissionId = p.PermissionId);

  -- VIEW para compras y ventas
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleAlmacenista, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module IN (N'compras', N'ventas')
    AND p.Action = N'VIEW'
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleAlmacenista AND rp.PermissionId = p.PermissionId);
END;

-- 3e. CONTADOR: todos permisos para contabilidad,bancos + VIEW+EXPORT para el resto
DECLARE @RoleContador INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'CONTADOR');

IF @RoleContador IS NOT NULL
BEGIN
  -- Todos los permisos para contabilidad y bancos
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleContador, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module IN (N'contabilidad', N'bancos')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleContador AND rp.PermissionId = p.PermissionId);

  -- VIEW + EXPORT para todo lo demas
  INSERT INTO sec.RolePermission (RoleId, PermissionId, IsGranted, CreatedByUserId, CreatedAt)
  SELECT @RoleContador, p.PermissionId, 1, 1, SYSUTCDATETIME()
  FROM sec.Permission p
  WHERE p.CompanyId = 1
    AND p.Module NOT IN (N'contabilidad', N'bancos')
    AND p.Action IN (N'VIEW', N'EXPORT')
    AND NOT EXISTS (SELECT 1 FROM sec.RolePermission rp WHERE rp.RoleId = @RoleContador AND rp.PermissionId = p.PermissionId);
END;
GO

-- ============================================================================
-- SECCION 4: sec.PriceRestriction  (2 restricciones de precio)
-- ============================================================================
PRINT '>> 4. Restricciones de precio por rol...';

DECLARE @RVendedor INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'VENDEDOR');
DECLARE @RGerente INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'GERENTE');

-- VENDEDOR: MaxDiscount 15%, MinPrice 80%, RequiresApprovalAbove $5000
IF @RVendedor IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sec.PriceRestriction WHERE CompanyId = 1 AND RoleId = @RVendedor)
  INSERT INTO sec.PriceRestriction (CompanyId, RoleId, MaxDiscountPercent, MinPricePercent, RequiresApprovalAbove, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, @RVendedor, 15.00, 80.00, 5000.00, N'Vendedor: descuento max 15%, precio min 80% del lista, aprobacion requerida sobre $5000', 1, 1, SYSUTCDATETIME());

-- GERENTE: MaxDiscount 30%, MinPrice 50%
IF @RGerente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sec.PriceRestriction WHERE CompanyId = 1 AND RoleId = @RGerente)
  INSERT INTO sec.PriceRestriction (CompanyId, RoleId, MaxDiscountPercent, MinPricePercent, RequiresApprovalAbove, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, @RGerente, 30.00, 50.00, NULL, N'Gerente: descuento max 30%, precio min 50% del lista, sin limite de aprobacion', 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 5: sec.ApprovalRule  (2 reglas de aprobacion)
-- ============================================================================
PRINT '>> 5. Reglas de aprobacion...';

DECLARE @RGerente2 INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE CompanyId = 1 AND RoleCode = N'GERENTE');

-- ventas.FACTURA: montos > $5000 requieren aprobacion de GERENTE
IF NOT EXISTS (SELECT 1 FROM sec.ApprovalRule WHERE CompanyId = 1 AND RuleCode = N'APR-VENTAS-5K')
  INSERT INTO sec.ApprovalRule (CompanyId, RuleCode, RuleName, Module, DocumentType, ThresholdAmount, ApproverRoleId, ApprovalLevels, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'APR-VENTAS-5K', N'Aprobacion facturas > $5,000', N'ventas', N'FACTURA', 5000.00, @RGerente2, 1, N'Facturas de venta superiores a $5,000 requieren aprobacion del Gerente', 1, 1, SYSUTCDATETIME());

-- compras.COMPRA: montos > $10000 requieren aprobacion de GERENTE
IF NOT EXISTS (SELECT 1 FROM sec.ApprovalRule WHERE CompanyId = 1 AND RuleCode = N'APR-COMPRAS-10K')
  INSERT INTO sec.ApprovalRule (CompanyId, RuleCode, RuleName, Module, DocumentType, ThresholdAmount, ApproverRoleId, ApprovalLevels, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'APR-COMPRAS-10K', N'Aprobacion compras > $10,000', N'compras', N'COMPRA', 10000.00, @RGerente2, 1, N'Ordenes de compra superiores a $10,000 requieren aprobacion del Gerente', 1, 1, SYSUTCDATETIME());
GO

PRINT '=== Seed RBAC completado ===';
GO
