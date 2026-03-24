-- ============================================================
-- 00027_license_plan_control.sql — Sistema de licencias Zentto
-- Motor: SQL Server
-- Paridad: web/api/migrations/postgres/00027_license_plan_control.sql
-- ============================================================

-- ─── cfg.PlanModule ──────────────────────────────────────────────────────────
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'cfg' AND TABLE_NAME = 'PlanModule'
)
BEGIN
  CREATE TABLE cfg.PlanModule (
    PlanModuleId INT IDENTITY(1,1) PRIMARY KEY,
    PlanCode     NVARCHAR(30) NOT NULL,
    ModuleCode   NVARCHAR(60) NOT NULL,
    IsEnabled    BIT NOT NULL DEFAULT 1,
    SortOrder    SMALLINT NOT NULL DEFAULT 0,
    CreatedAt    DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_PlanModule UNIQUE (PlanCode, ModuleCode)
  );
END
GO

-- ─── sys.License ─────────────────────────────────────────────────────────────
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'sys' AND TABLE_NAME = 'License'
)
BEGIN
  CREATE TABLE sys.License (
    LicenseId       BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId       BIGINT NOT NULL,
    LicenseType     NVARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
    Plan            NVARCHAR(30) NOT NULL DEFAULT 'STARTER',
    LicenseKey      NVARCHAR(64) NOT NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    StartsAt        DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ExpiresAt       DATETIME2 NULL,
    PaddleSubId     NVARCHAR(100) NULL,
    ContractRef     NVARCHAR(100) NULL,
    MaxUsers        INT NULL,
    MaxBranches     INT NULL,
    Notes           NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_License_Key UNIQUE (LicenseKey)
  );

  CREATE INDEX idx_license_company ON sys.License (CompanyId);
  CREATE INDEX idx_license_key     ON sys.License (LicenseKey);
  CREATE INDEX idx_license_status  ON sys.License (Status)
    WHERE Status = 'ACTIVE';
END
GO

-- ─── cfg.Company: agregar LicenseKey ─────────────────────────────────────────
IF COL_LENGTH('cfg.Company', 'LicenseKey') IS NULL
BEGIN
  ALTER TABLE cfg.Company ADD LicenseKey NVARCHAR(64) NULL;
END
GO

-- ─── SEED: plan → módulos ─────────────────────────────────────────────────────

-- FREE
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='dashboard')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','dashboard',1);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='facturas')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','facturas',2);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='clientes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','clientes',3);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='inventario')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','inventario',4);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='articulos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','articulos',5);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='FREE' AND ModuleCode='reportes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('FREE','reportes',6);

-- STARTER
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='dashboard')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','dashboard',1);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='facturas')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','facturas',2);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='abonos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','abonos',3);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='cxc')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','cxc',4);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='clientes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','clientes',5);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='compras')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','compras',6);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='cxp')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','cxp',7);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='cuentas-por-pagar')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','cuentas-por-pagar',8);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='proveedores')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','proveedores',9);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='inventario')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','inventario',10);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='articulos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','articulos',11);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='pagos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','pagos',12);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='bancos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','bancos',13);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='reportes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','reportes',14);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='configuracion')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','configuracion',15);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='STARTER' AND ModuleCode='usuarios')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('STARTER','usuarios',16);

-- PRO
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='dashboard')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','dashboard',1);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='facturas')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','facturas',2);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='abonos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','abonos',3);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='cxc')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','cxc',4);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='clientes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','clientes',5);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='compras')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','compras',6);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='cxp')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','cxp',7);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='cuentas-por-pagar')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','cuentas-por-pagar',8);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='proveedores')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','proveedores',9);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='inventario')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','inventario',10);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='articulos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','articulos',11);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='pagos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','pagos',12);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='bancos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','bancos',13);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='reportes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','reportes',14);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='configuracion')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','configuracion',15);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='usuarios')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','usuarios',16);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='contabilidad')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','contabilidad',17);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='nomina')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','nomina',18);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='pos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','pos',19);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='restaurante')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','restaurante',20);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='ecommerce')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','ecommerce',21);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='auditoria')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','auditoria',22);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='logistica')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','logistica',23);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='crm')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','crm',24);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='PRO' AND ModuleCode='shipping')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('PRO','shipping',25);

-- ENTERPRISE
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='dashboard')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','dashboard',1);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='facturas')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','facturas',2);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='abonos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','abonos',3);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='cxc')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','cxc',4);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='clientes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','clientes',5);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='compras')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','compras',6);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='cxp')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','cxp',7);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='cuentas-por-pagar')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','cuentas-por-pagar',8);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='proveedores')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','proveedores',9);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='inventario')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','inventario',10);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='articulos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','articulos',11);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='pagos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','pagos',12);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='bancos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','bancos',13);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='reportes')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','reportes',14);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='configuracion')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','configuracion',15);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='usuarios')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','usuarios',16);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='contabilidad')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','contabilidad',17);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='nomina')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','nomina',18);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='pos')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','pos',19);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='restaurante')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','restaurante',20);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='ecommerce')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','ecommerce',21);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='auditoria')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','auditoria',22);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='logistica')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','logistica',23);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='crm')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','crm',24);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='shipping')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','shipping',25);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='manufactura')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','manufactura',26);
IF NOT EXISTS (SELECT 1 FROM cfg.PlanModule WHERE PlanCode='ENTERPRISE' AND ModuleCode='flota')
  INSERT INTO cfg.PlanModule (PlanCode, ModuleCode, SortOrder) VALUES ('ENTERPRISE','flota',27);
GO
