SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Matriz de dependencias para mantener endpoints operativos
  - Tabla de dependencias por modulo
  - Vista de readiness por objeto
  - Vista resumen por modulo
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('dbo.EndpointDependency', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.EndpointDependency (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ModuleName NVARCHAR(60) NOT NULL,
      ObjectType NVARCHAR(10) NOT NULL,     -- TABLE / PROC / VIEW
      ObjectName NVARCHAR(256) NOT NULL,    -- dbo.Tabla o dbo.usp_X
      IsCritical BIT NOT NULL DEFAULT(1),
      SourceTag NVARCHAR(40) NOT NULL DEFAULT('governance_core'),
      Notes NVARCHAR(300) NULL,
      CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      CONSTRAINT UQ_EndpointDependency UNIQUE (ModuleName, ObjectType, ObjectName, SourceTag)
    );
  END

  DELETE FROM dbo.EndpointDependency
  WHERE SourceTag = 'governance_core';

  INSERT INTO dbo.EndpointDependency (ModuleName, ObjectType, ObjectName, IsCritical, SourceTag, Notes)
  VALUES
    -- POS (canonic)
    ('POS', 'TABLE', 'cfg.Company', 1, 'governance_core', 'Scope de empresa'),
    ('POS', 'TABLE', 'cfg.Branch', 1, 'governance_core', 'Scope de sucursal'),
    ('POS', 'TABLE', 'sec.[User]', 1, 'governance_core', 'Usuarios operativos'),
    ('POS', 'TABLE', 'master.Product', 1, 'governance_core', 'Catalogo de productos'),
    ('POS', 'TABLE', 'master.Customer', 1, 'governance_core', 'Catalogo de clientes'),
    ('POS', 'TABLE', 'fiscal.TaxRate', 1, 'governance_core', 'Tasas fiscales por pais'),
    ('POS', 'TABLE', 'pos.FiscalCorrelative', 1, 'governance_core', 'Correlativos fiscales POS'),
    ('POS', 'TABLE', 'pos.WaitTicket', 1, 'governance_core', 'Header de ventas en espera'),
    ('POS', 'TABLE', 'pos.WaitTicketLine', 1, 'governance_core', 'Detalle de ventas en espera'),
    ('POS', 'TABLE', 'pos.SaleTicket', 1, 'governance_core', 'Header de ventas'),
    ('POS', 'TABLE', 'pos.SaleTicketLine', 1, 'governance_core', 'Detalle de ventas'),

    -- RESTAURANTE (canonic)
    ('RESTAURANTE', 'TABLE', 'cfg.Company', 1, 'governance_core', 'Scope de empresa'),
    ('RESTAURANTE', 'TABLE', 'cfg.Branch', 1, 'governance_core', 'Scope de sucursal'),
    ('RESTAURANTE', 'TABLE', 'sec.[User]', 1, 'governance_core', 'Usuarios operativos'),
    ('RESTAURANTE', 'TABLE', 'master.Product', 1, 'governance_core', 'Catalogo de productos'),
    ('RESTAURANTE', 'TABLE', 'fiscal.TaxRate', 1, 'governance_core', 'Tasas fiscales por pais'),
    ('RESTAURANTE', 'TABLE', 'rest.DiningTable', 1, 'governance_core', 'Mesas de restaurante'),
    ('RESTAURANTE', 'TABLE', 'rest.OrderTicket', 1, 'governance_core', 'Header de pedidos'),
    ('RESTAURANTE', 'TABLE', 'rest.OrderTicketLine', 1, 'governance_core', 'Detalle de pedidos'),

    -- CONTABILIDAD (canonic + compat API)
    ('CONTABILIDAD', 'TABLE', 'acct.Account', 1, 'governance_core', 'Plan de cuentas canonico'),
    ('CONTABILIDAD', 'TABLE', 'acct.AccountingPolicy', 1, 'governance_core', 'Politicas contables'),
    ('CONTABILIDAD', 'TABLE', 'acct.JournalEntry', 1, 'governance_core', 'Asientos contables cabecera'),
    ('CONTABILIDAD', 'TABLE', 'acct.JournalEntryLine', 1, 'governance_core', 'Asientos contables detalle'),
    ('CONTABILIDAD', 'TABLE', 'acct.DocumentLink', 1, 'governance_core', 'Trazabilidad documento-asiento'),
    ('CONTABILIDAD', 'PROC', 'dbo.usp_Contabilidad_Asientos_List', 1, 'governance_core', 'Listado API'),
    ('CONTABILIDAD', 'PROC', 'dbo.usp_Contabilidad_Asiento_Get', 1, 'governance_core', 'Detalle API'),
    ('CONTABILIDAD', 'PROC', 'dbo.usp_Contabilidad_Asiento_Crear', 1, 'governance_core', 'Creacion API'),
    ('CONTABILIDAD', 'PROC', 'dbo.usp_Contabilidad_Asiento_Anular', 1, 'governance_core', 'Anulacion API'),

    -- FISCAL (canonic)
    ('FISCAL', 'TABLE', 'fiscal.CountryConfig', 1, 'governance_core', 'Configuracion fiscal por pais'),
    ('FISCAL', 'TABLE', 'fiscal.TaxRate', 1, 'governance_core', 'Tasas fiscales'),
    ('FISCAL', 'TABLE', 'fiscal.InvoiceType', 1, 'governance_core', 'Tipos de documento fiscal'),
    ('FISCAL', 'TABLE', 'fiscal.Record', 1, 'governance_core', 'Registro fiscal emitido'),

    -- BANCOS (canonic)
    ('BANCOS', 'TABLE', 'fin.Bank', 1, 'governance_core', 'Catalogo de bancos'),
    ('BANCOS', 'TABLE', 'fin.BankAccount', 1, 'governance_core', 'Cuentas bancarias'),
    ('BANCOS', 'TABLE', 'fin.BankMovement', 1, 'governance_core', 'Movimientos bancarios'),
    ('BANCOS', 'TABLE', 'fin.BankReconciliation', 1, 'governance_core', 'Conciliaciones bancarias'),
    ('BANCOS', 'TABLE', 'fin.BankStatementLine', 1, 'governance_core', 'Lineas de extracto bancario'),
    ('BANCOS', 'TABLE', 'fin.BankReconciliationMatch', 1, 'governance_core', 'Cruce conciliacion movimiento/extracto'),

    -- NOMINA (canonic)
    ('NOMINA', 'TABLE', 'master.Employee', 1, 'governance_core', 'Maestro de empleados'),
    ('NOMINA', 'TABLE', 'hr.PayrollType', 1, 'governance_core', 'Tipos de nomina'),
    ('NOMINA', 'TABLE', 'hr.PayrollConcept', 1, 'governance_core', 'Conceptos de nomina'),
    ('NOMINA', 'TABLE', 'hr.PayrollRun', 1, 'governance_core', 'Procesos de nomina cabecera'),
    ('NOMINA', 'TABLE', 'hr.PayrollRunLine', 1, 'governance_core', 'Procesos de nomina detalle'),
    ('NOMINA', 'TABLE', 'hr.PayrollConstant', 1, 'governance_core', 'Constantes de nomina'),
    ('NOMINA', 'TABLE', 'hr.VacationProcess', 1, 'governance_core', 'Procesos de vacaciones'),
    ('NOMINA', 'TABLE', 'hr.SettlementProcess', 1, 'governance_core', 'Procesos de liquidacion'),

    -- RESTAURANTE ADMIN (canonic)
    ('RESTAURANTE_ADMIN', 'TABLE', 'master.Supplier', 1, 'governance_core', 'Proveedores para compras de restaurante'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'master.Product', 1, 'governance_core', 'Catalogo de productos/insumos'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuEnvironment', 1, 'governance_core', 'Ambientes de menu'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuCategory', 1, 'governance_core', 'Categorias de menu'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuProduct', 1, 'governance_core', 'Productos de menu'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuComponent', 1, 'governance_core', 'Componentes de menu'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuOption', 1, 'governance_core', 'Opciones de componentes'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.MenuRecipe', 1, 'governance_core', 'Recetas de menu'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.Purchase', 1, 'governance_core', 'Compras de restaurante cabecera'),
    ('RESTAURANTE_ADMIN', 'TABLE', 'rest.PurchaseLine', 1, 'governance_core', 'Compras de restaurante detalle');

  IF OBJECT_ID('dbo.vw_Governance_EndpointReadiness', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Governance_EndpointReadiness;

  EXEC('
  CREATE VIEW dbo.vw_Governance_EndpointReadiness
  AS
  SELECT
    d.Id,
    d.ModuleName,
    d.ObjectType,
    d.ObjectName,
    d.IsCritical,
    d.SourceTag,
    d.Notes,
    CASE
      WHEN d.ObjectType = ''TABLE'' AND OBJECT_ID(d.ObjectName, ''U'') IS NOT NULL THEN CAST(1 AS BIT)
      WHEN d.ObjectType = ''PROC''  AND OBJECT_ID(d.ObjectName, ''P'') IS NOT NULL THEN CAST(1 AS BIT)
      WHEN d.ObjectType = ''VIEW''  AND OBJECT_ID(d.ObjectName, ''V'') IS NOT NULL THEN CAST(1 AS BIT)
      ELSE CAST(0 AS BIT)
    END AS ObjectExists
  FROM dbo.EndpointDependency d;
  ');

  IF OBJECT_ID('dbo.vw_Governance_EndpointReadinessSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Governance_EndpointReadinessSummary;

  EXEC('
  CREATE VIEW dbo.vw_Governance_EndpointReadinessSummary
  AS
  SELECT
    ModuleName,
    COUNT(1) AS TotalDependencies,
    SUM(CASE WHEN ObjectExists = 1 THEN 1 ELSE 0 END) AS AvailableDependencies,
    SUM(CASE WHEN ObjectExists = 0 THEN 1 ELSE 0 END) AS MissingDependencies,
    SUM(CASE WHEN ObjectExists = 0 AND IsCritical = 1 THEN 1 ELSE 0 END) AS MissingCritical
  FROM dbo.vw_Governance_EndpointReadiness
  GROUP BY ModuleName;
  ');

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 20_endpoint_dependency_readiness.sql: %s', 16, 1, @Err);
END CATCH;
GO
