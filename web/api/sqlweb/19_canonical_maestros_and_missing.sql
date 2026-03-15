-- =============================================================================
-- 19_canonical_maestros_and_missing.sql
-- Tablas canónicas para datos maestros de clasificación y objetos faltantes
-- Mantiene contratos SP idénticos para compatibilidad con API TypeScript
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ============================================================
-- SECCIÓN 1: TABLAS CANÓNICAS EN SCHEMA master.*
-- ============================================================
BEGIN TRY
  BEGIN TRAN;

  -- ----------------------------------------------------------
  -- master.Category  (Categorías de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.Category', N'U') IS NULL
  BEGIN
    CREATE TABLE master.Category (
      CategoryId      INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_Category_CompanyId DEFAULT (1),
      CategoryCode    NVARCHAR(20)  NULL,
      CategoryName    NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      UserCode        NVARCHAR(20)  NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_Category_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_Category_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Category_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Category_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_Category PRIMARY KEY (CategoryId)
    );
    CREATE UNIQUE INDEX UQ_Category_CompanyName
      ON master.Category (CompanyId, CategoryName) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.Brand  (Marcas de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.Brand', N'U') IS NULL
  BEGIN
    CREATE TABLE master.Brand (
      BrandId         INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_Brand_CompanyId DEFAULT (1),
      BrandCode       NVARCHAR(20)  NULL,
      BrandName       NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      UserCode        NVARCHAR(20)  NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_Brand_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_Brand_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Brand_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Brand_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_Brand PRIMARY KEY (BrandId)
    );
    CREATE UNIQUE INDEX UQ_Brand_CompanyName
      ON master.Brand (CompanyId, BrandName) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.Warehouse  (Almacenes)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.Warehouse', N'U') IS NULL
  BEGIN
    CREATE TABLE master.Warehouse (
      WarehouseId     INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_Warehouse_CompanyId DEFAULT (1),
      BranchId        INT           NULL,
      WarehouseCode   NVARCHAR(20)  NOT NULL,
      Description     NVARCHAR(200) NOT NULL,
      WarehouseType   NVARCHAR(20)  NOT NULL CONSTRAINT DF_Warehouse_Type DEFAULT (N'PRINCIPAL'),
      AddressLine     NVARCHAR(250) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_Warehouse_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_Warehouse_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Warehouse_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Warehouse_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_Warehouse PRIMARY KEY (WarehouseId)
    );
    CREATE UNIQUE INDEX UQ_Warehouse_CompanyCode
      ON master.Warehouse (CompanyId, WarehouseCode) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.ProductLine  (Líneas de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.ProductLine', N'U') IS NULL
  BEGIN
    CREATE TABLE master.ProductLine (
      LineId          INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_ProductLine_CompanyId DEFAULT (1),
      LineCode        NVARCHAR(20)  NOT NULL,
      LineName        NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_ProductLine_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_ProductLine_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductLine_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductLine_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_ProductLine PRIMARY KEY (LineId)
    );
  END;

  -- ----------------------------------------------------------
  -- master.ProductClass  (Clases de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.ProductClass', N'U') IS NULL
  BEGIN
    CREATE TABLE master.ProductClass (
      ClassId         INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_ProductClass_CompanyId DEFAULT (1),
      ClassCode       NVARCHAR(20)  NOT NULL,
      ClassName       NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_ProductClass_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_ProductClass_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductClass_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductClass_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_ProductClass PRIMARY KEY (ClassId)
    );
  END;

  -- ----------------------------------------------------------
  -- master.ProductGroup  (Grupos de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.ProductGroup', N'U') IS NULL
  BEGIN
    CREATE TABLE master.ProductGroup (
      GroupId         INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_ProductGroup_CompanyId DEFAULT (1),
      GroupCode       NVARCHAR(20)  NOT NULL,
      GroupName       NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_ProductGroup_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_ProductGroup_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductGroup_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductGroup_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_ProductGroup PRIMARY KEY (GroupId)
    );
  END;

  -- ----------------------------------------------------------
  -- master.ProductType  (Tipos de productos)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.ProductType', N'U') IS NULL
  BEGIN
    CREATE TABLE master.ProductType (
      TypeId          INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_ProductType_CompanyId DEFAULT (1),
      TypeCode        NVARCHAR(20)  NOT NULL,
      TypeName        NVARCHAR(100) NOT NULL,
      CategoryCode    NVARCHAR(50)  NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_ProductType_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_ProductType_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductType_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_ProductType_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_ProductType PRIMARY KEY (TypeId)
    );
  END;

  -- ----------------------------------------------------------
  -- master.UnitOfMeasure  (Unidades de medida)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.UnitOfMeasure', N'U') IS NULL
  BEGIN
    CREATE TABLE master.UnitOfMeasure (
      UnitId          INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_UnitOfMeasure_CompanyId DEFAULT (1),
      UnitCode        NVARCHAR(20)  NOT NULL,
      Description     NVARCHAR(100) NOT NULL,
      Symbol          NVARCHAR(10)  NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_UnitOfMeasure_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_UnitOfMeasure_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_UnitOfMeasure_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_UnitOfMeasure_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_UnitOfMeasure PRIMARY KEY (UnitId)
    );
    CREATE UNIQUE INDEX UQ_UnitOfMeasure_CompanyCode
      ON master.UnitOfMeasure (CompanyId, UnitCode) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.Seller  (Vendedores / Agentes)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.Seller', N'U') IS NULL
  BEGIN
    CREATE TABLE master.Seller (
      SellerId        INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_Seller_CompanyId DEFAULT (1),
      SellerCode      NVARCHAR(10)  NOT NULL,
      SellerName      NVARCHAR(120) NOT NULL,
      Commission      DECIMAL(5,2)  NOT NULL CONSTRAINT DF_Seller_Commission DEFAULT (0),
      Address         NVARCHAR(250) NULL,
      Phone           NVARCHAR(60)  NULL,
      Email           NVARCHAR(150) NULL,
      SellerType      NVARCHAR(20)  NOT NULL CONSTRAINT DF_Seller_SellerType DEFAULT (N'INTERNO'),
      IsActive        BIT           NOT NULL CONSTRAINT DF_Seller_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_Seller_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Seller_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Seller_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_Seller PRIMARY KEY (SellerId)
    );
    CREATE UNIQUE INDEX UQ_Seller_CompanyCode
      ON master.Seller (CompanyId, SellerCode) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.CostCenter  (Centros de costo)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.CostCenter', N'U') IS NULL
  BEGIN
    CREATE TABLE master.CostCenter (
      CostCenterId    INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_CostCenter_CompanyId DEFAULT (1),
      CostCenterCode  NVARCHAR(20)  NOT NULL,
      CostCenterName  NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_CostCenter_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_CostCenter_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_CostCenter_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_CostCenter_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_CostCenter PRIMARY KEY (CostCenterId)
    );
  END;

  -- ----------------------------------------------------------
  -- master.TaxRetention  (Retenciones fiscales)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.TaxRetention', N'U') IS NULL
  BEGIN
    CREATE TABLE master.TaxRetention (
      RetentionId     INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_TaxRetention_CompanyId DEFAULT (1),
      RetentionCode   NVARCHAR(20)  NOT NULL,
      Description     NVARCHAR(200) NOT NULL,
      RetentionType   NVARCHAR(20)  NOT NULL CONSTRAINT DF_TaxRetention_Type DEFAULT (N'ISLR'),
      RetentionRate   DECIMAL(8,4)  NOT NULL CONSTRAINT DF_TaxRetention_Rate DEFAULT (0),
      CountryCode     CHAR(2)       NOT NULL CONSTRAINT DF_TaxRetention_Country DEFAULT (N'VE'),
      IsActive        BIT           NOT NULL CONSTRAINT DF_TaxRetention_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_TaxRetention_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_TaxRetention_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_TaxRetention_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_TaxRetention PRIMARY KEY (RetentionId)
    );
    CREATE UNIQUE INDEX UQ_TaxRetention_CompanyCode
      ON master.TaxRetention (CompanyId, RetentionCode) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.InventoryMovement  (Movimientos de inventario)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.InventoryMovement', N'U') IS NULL
  BEGIN
    CREATE TABLE master.InventoryMovement (
      MovementId      BIGINT        IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_InventoryMovement_CompanyId DEFAULT (1),
      BranchId        INT           NULL,
      ProductCode     NVARCHAR(80)  NOT NULL,
      ProductName     NVARCHAR(250) NULL,
      DocumentRef     NVARCHAR(60)  NULL,
      MovementType    NVARCHAR(20)  NOT NULL CONSTRAINT DF_InventoryMovement_Type DEFAULT (N'ENTRADA'),
      MovementDate    DATE          NOT NULL CONSTRAINT DF_InventoryMovement_Date DEFAULT CAST(SYSUTCDATETIME() AS DATE),
      Quantity        DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryMovement_Qty DEFAULT (0),
      UnitCost        DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryMovement_UnitCost DEFAULT (0),
      TotalCost       DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryMovement_TotalCost DEFAULT (0),
      Notes           NVARCHAR(300) NULL,
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_InventoryMovement_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_InventoryMovement_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_InventoryMovement_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CreatedByUserId INT           NULL,
      UpdatedByUserId INT           NULL,
      CONSTRAINT PK_InventoryMovement PRIMARY KEY (MovementId)
    );
    CREATE INDEX IX_InventoryMovement_ProductDate
      ON master.InventoryMovement (ProductCode, MovementDate DESC) WHERE IsDeleted = 0;
  END;

  -- ----------------------------------------------------------
  -- master.InventoryPeriodSummary  (Cierre mensual inventario)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.InventoryPeriodSummary', N'U') IS NULL
  BEGIN
    CREATE TABLE master.InventoryPeriodSummary (
      SummaryId       BIGINT        IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_InventoryPeriodSummary_CompanyId DEFAULT (1),
      Period          CHAR(6)       NOT NULL,  -- YYYYMM
      ProductCode     NVARCHAR(80)  NOT NULL,
      OpeningQty      DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryPeriodSummary_Opening DEFAULT (0),
      InboundQty      DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryPeriodSummary_Inbound DEFAULT (0),
      OutboundQty     DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryPeriodSummary_Outbound DEFAULT (0),
      ClosingQty      DECIMAL(18,4) NOT NULL CONSTRAINT DF_InventoryPeriodSummary_Closing DEFAULT (0),
      SummaryDate     DATE          NOT NULL CONSTRAINT DF_InventoryPeriodSummary_Date DEFAULT CAST(SYSUTCDATETIME() AS DATE),
      IsClosed        BIT           NOT NULL CONSTRAINT DF_InventoryPeriodSummary_IsClosed DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_InventoryPeriodSummary_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_InventoryPeriodSummary_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_InventoryPeriodSummary PRIMARY KEY (SummaryId)
    );
    CREATE UNIQUE INDEX UQ_InventoryPeriodSummary_Key
      ON master.InventoryPeriodSummary (CompanyId, Period, ProductCode);
  END;

  -- ----------------------------------------------------------
  -- master.SupplierLine  (Líneas de proveedores)
  -- ----------------------------------------------------------
  IF OBJECT_ID(N'master.SupplierLine', N'U') IS NULL
  BEGIN
    CREATE TABLE master.SupplierLine (
      SupplierLineId  INT           IDENTITY(1,1) NOT NULL,
      CompanyId       INT           NOT NULL CONSTRAINT DF_SupplierLine_CompanyId DEFAULT (1),
      LineCode        NVARCHAR(20)  NOT NULL,
      LineName        NVARCHAR(100) NOT NULL,
      Description     NVARCHAR(500) NULL,
      IsActive        BIT           NOT NULL CONSTRAINT DF_SupplierLine_IsActive DEFAULT (1),
      IsDeleted       BIT           NOT NULL CONSTRAINT DF_SupplierLine_IsDeleted DEFAULT (0),
      CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_SupplierLine_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_SupplierLine_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_SupplierLine PRIMARY KEY (SupplierLineId)
    );
  END;

  -- ============================================================
  -- SECCIÓN 2: TABLAS EN SCHEMA cfg.*
  -- ============================================================

  -- cfg.Holiday  (Días feriados)
  IF OBJECT_ID(N'cfg.Holiday', N'U') IS NULL
  BEGIN
    CREATE TABLE cfg.Holiday (
      HolidayId     INT          IDENTITY(1,1) NOT NULL,
      CountryCode   CHAR(2)      NOT NULL CONSTRAINT DF_Holiday_Country DEFAULT (N'VE'),
      HolidayDate   DATE         NOT NULL,
      HolidayName   NVARCHAR(100) NOT NULL,
      IsRecurring   BIT          NOT NULL CONSTRAINT DF_Holiday_IsRecurring DEFAULT (0),
      IsActive      BIT          NOT NULL CONSTRAINT DF_Holiday_IsActive DEFAULT (1),
      CreatedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_Holiday_CreatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_Holiday PRIMARY KEY (HolidayId)
    );
  END;

  -- cfg.DocumentSequence  (Correlativos / Secuencias de documentos)
  IF OBJECT_ID(N'cfg.DocumentSequence', N'U') IS NULL
  BEGIN
    CREATE TABLE cfg.DocumentSequence (
      SequenceId      INT          IDENTITY(1,1) NOT NULL,
      CompanyId       INT          NOT NULL CONSTRAINT DF_DocumentSequence_CompanyId DEFAULT (1),
      BranchId        INT          NULL,
      DocumentType    NVARCHAR(20) NOT NULL,
      Prefix          NVARCHAR(10) NULL,
      Suffix          NVARCHAR(10) NULL,
      CurrentNumber   BIGINT       NOT NULL CONSTRAINT DF_DocumentSequence_Current DEFAULT (1),
      PaddingLength   INT          NOT NULL CONSTRAINT DF_DocumentSequence_Padding DEFAULT (8),
      IsActive        BIT          NOT NULL CONSTRAINT DF_DocumentSequence_IsActive DEFAULT (1),
      CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentSequence_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentSequence_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_DocumentSequence PRIMARY KEY (SequenceId)
    );
    CREATE UNIQUE INDEX UQ_DocumentSequence_NoBranch
      ON cfg.DocumentSequence (CompanyId, DocumentType)
      WHERE BranchId IS NULL;
    CREATE UNIQUE INDEX UQ_DocumentSequence_Branch
      ON cfg.DocumentSequence (CompanyId, BranchId, DocumentType)
      WHERE BranchId IS NOT NULL;
  END;

  -- cfg.Currency  (Catálogo de monedas)
  IF OBJECT_ID(N'cfg.Currency', N'U') IS NULL
  BEGIN
    CREATE TABLE cfg.Currency (
      CurrencyId    INT          IDENTITY(1,1) NOT NULL,
      CurrencyCode  CHAR(3)      NOT NULL,
      CurrencyName  NVARCHAR(60) NOT NULL,
      Symbol        NVARCHAR(10) NULL,
      IsActive      BIT          NOT NULL CONSTRAINT DF_Currency_IsActive DEFAULT (1),
      CreatedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_Currency_CreatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_Currency PRIMARY KEY (CurrencyId),
      CONSTRAINT UQ_Currency_Code UNIQUE (CurrencyCode)
    );
  END;

  -- cfg.ReportTemplate  (Plantillas de reportes)
  IF OBJECT_ID(N'cfg.ReportTemplate', N'U') IS NULL
  BEGIN
    CREATE TABLE cfg.ReportTemplate (
      ReportId      INT           IDENTITY(1,1) NOT NULL,
      CompanyId     INT           NOT NULL CONSTRAINT DF_ReportTemplate_CompanyId DEFAULT (1),
      ReportCode    NVARCHAR(50)  NOT NULL,
      ReportName    NVARCHAR(150) NOT NULL,
      ReportType    NVARCHAR(20)  NOT NULL CONSTRAINT DF_ReportTemplate_Type DEFAULT (N'REPORT'),
      QueryText     NVARCHAR(MAX) NULL,
      Parameters    NVARCHAR(MAX) NULL,
      IsActive      BIT           NOT NULL CONSTRAINT DF_ReportTemplate_IsActive DEFAULT (1),
      IsDeleted     BIT           NOT NULL CONSTRAINT DF_ReportTemplate_IsDeleted DEFAULT (0),
      CreatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_ReportTemplate_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_ReportTemplate_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_ReportTemplate PRIMARY KEY (ReportId)
    );
  END;

  -- cfg.CompanyProfile  (Perfil extendido de empresa)
  IF OBJECT_ID(N'cfg.CompanyProfile', N'U') IS NULL
  BEGIN
    CREATE TABLE cfg.CompanyProfile (
      ProfileId     INT           IDENTITY(1,1) NOT NULL,
      CompanyId     INT           NOT NULL,
      Phone         NVARCHAR(60)  NULL,
      AddressLine   NVARCHAR(250) NULL,
      NitCode       NVARCHAR(50)  NULL,
      AltFiscalId   NVARCHAR(50)  NULL,
      WebSite       NVARCHAR(150) NULL,
      LogoBase64    NVARCHAR(MAX) NULL,
      Notes         NVARCHAR(500) NULL,
      UpdatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_CompanyProfile_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_CompanyProfile PRIMARY KEY (ProfileId),
      CONSTRAINT FK_CompanyProfile_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
    );
    CREATE UNIQUE INDEX UQ_CompanyProfile_CompanyId
      ON cfg.CompanyProfile (CompanyId);
  END;

  -- ============================================================
  -- SECCIÓN 3: TABLA DE COMPATIBILIDAD dbo.AccesoUsuarios
  -- ============================================================
  IF OBJECT_ID(N'dbo.AccesoUsuarios', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AccesoUsuarios (
      Cod_Usuario NVARCHAR(20) NOT NULL,
      Modulo      NVARCHAR(60) NOT NULL,
      Permitido   BIT          NOT NULL CONSTRAINT DF_AccesoUsuarios_Permitido DEFAULT (1),
      CreatedAt   DATETIME2(0) NOT NULL CONSTRAINT DF_AccesoUsuarios_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt   DATETIME2(0) NOT NULL CONSTRAINT DF_AccesoUsuarios_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_AccesoUsuarios PRIMARY KEY (Cod_Usuario, Modulo)
    );
  END;

  -- Inicializar perfil DEFAULT de empresa desde cfg.Company
  IF NOT EXISTS (SELECT 1 FROM cfg.CompanyProfile cp
                 INNER JOIN cfg.Company c ON c.CompanyId = cp.CompanyId
                 WHERE c.CompanyCode = N'DEFAULT')
  BEGIN
    INSERT INTO cfg.CompanyProfile (CompanyId, Phone, AddressLine)
    SELECT TOP 1 c.CompanyId, N'+58 212 555-0000', N'Dirección Principal'
    FROM cfg.Company c
    WHERE c.CompanyCode = N'DEFAULT';
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

-- ============================================================
-- SECCIÓN 4: SEED DATA (datos de referencia)
-- ============================================================
BEGIN TRY
  BEGIN TRAN;

  DECLARE @CompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');

  -- Categorías de productos
  IF NOT EXISTS (SELECT 1 FROM master.Category WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.Category (CompanyId, CategoryCode, CategoryName, Description)
    VALUES
      (@CompanyId, N'PROD',    N'Productos',         N'Artículos de venta general'),
      (@CompanyId, N'SERV',    N'Servicios',          N'Servicios y honorarios'),
      (@CompanyId, N'INSUMOS', N'Insumos',            N'Materiales de producción e insumos'),
      (@CompanyId, N'REPUEST', N'Repuestos',          N'Repuestos y piezas de mantenimiento'),
      (@CompanyId, N'MATERI',  N'Materia Prima',      N'Materias primas industriales'),
      (@CompanyId, N'COMIDA',  N'Alimentos',          N'Productos alimenticios'),
      (@CompanyId, N'BEBIDA',  N'Bebidas',            N'Bebidas y refrescos'),
      (@CompanyId, N'TECNOL',  N'Tecnología',         N'Equipos y periféricos tecnológicos'),
      (@CompanyId, N'OFICI',   N'Oficina',            N'Artículos de oficina y papelería'),
      (@CompanyId, N'LIMPI',   N'Limpieza',           N'Productos de limpieza e higiene');
  END;

  -- Marcas de productos
  IF NOT EXISTS (SELECT 1 FROM master.Brand WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.Brand (CompanyId, BrandCode, BrandName, Description)
    VALUES
      (@CompanyId, N'GEN',    N'Genérico',       N'Marca genérica sin especificar'),
      (@CompanyId, N'PROPI',  N'Marca Propia',   N'Productos con marca de la empresa'),
      (@CompanyId, N'IMPORT', N'Importado',      N'Productos importados');
  END;

  -- Almacenes
  IF NOT EXISTS (SELECT 1 FROM master.Warehouse WHERE CompanyId = @CompanyId)
  BEGIN
    DECLARE @BranchId INT = (SELECT TOP 1 BranchId FROM cfg.Branch WHERE CompanyId = @CompanyId AND BranchCode = N'MAIN');
    INSERT INTO master.Warehouse (CompanyId, BranchId, WarehouseCode, Description, WarehouseType)
    VALUES
      (@CompanyId, @BranchId, N'PRINCIPAL', N'Almacén Principal',     N'PRINCIPAL'),
      (@CompanyId, @BranchId, N'SERVICIO',  N'Almacén Servicio',      N'SERVICIO'),
      (@CompanyId, @BranchId, N'PLANTA',    N'Almacén Planta',        N'PLANTA'),
      (@CompanyId, @BranchId, N'CONSIG',    N'Almacén Consignación',  N'CONSIGNACION'),
      (@CompanyId, @BranchId, N'AVERIA',    N'Almacén Averías/Devoluciones', N'AVERIA');
  END;

  -- Líneas de productos
  IF NOT EXISTS (SELECT 1 FROM master.ProductLine WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.ProductLine (CompanyId, LineCode, LineName)
    VALUES
      (@CompanyId, N'LIN-A',  N'Línea A - Premium'),
      (@CompanyId, N'LIN-B',  N'Línea B - Estándar'),
      (@CompanyId, N'LIN-C',  N'Línea C - Económica'),
      (@CompanyId, N'LIN-S',  N'Línea Servicios'),
      (@CompanyId, N'LIN-I',  N'Línea Importados');
  END;

  -- Clases de productos
  IF NOT EXISTS (SELECT 1 FROM master.ProductClass WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.ProductClass (CompanyId, ClassCode, ClassName)
    VALUES
      (@CompanyId, N'CL-CONS', N'Consumible'),
      (@CompanyId, N'CL-DURA', N'Durable'),
      (@CompanyId, N'CL-SERV', N'Servicio Técnico'),
      (@CompanyId, N'CL-PROM', N'Promocional'),
      (@CompanyId, N'CL-ACTF', N'Activo Fijo');
  END;

  -- Grupos de productos
  IF NOT EXISTS (SELECT 1 FROM master.ProductGroup WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.ProductGroup (CompanyId, GroupCode, GroupName)
    VALUES
      (@CompanyId, N'GR-01', N'Grupo Ventas Directas'),
      (@CompanyId, N'GR-02', N'Grupo Distribución'),
      (@CompanyId, N'GR-03', N'Grupo Exportación'),
      (@CompanyId, N'GR-04', N'Grupo Uso Interno');
  END;

  -- Tipos de productos
  IF NOT EXISTS (SELECT 1 FROM master.ProductType WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.ProductType (CompanyId, TypeCode, TypeName, CategoryCode)
    VALUES
      (@CompanyId, N'TIP-FIN', N'Producto Terminado',   NULL),
      (@CompanyId, N'TIP-SEM', N'Semielaborado',        NULL),
      (@CompanyId, N'TIP-INS', N'Insumo/Materia Prima', N'INSUMOS'),
      (@CompanyId, N'TIP-SER', N'Servicio',             N'SERV'),
      (@CompanyId, N'TIP-REP', N'Repuesto',             N'REPUEST');
  END;

  -- Unidades de medida
  IF NOT EXISTS (SELECT 1 FROM master.UnitOfMeasure WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.UnitOfMeasure (CompanyId, UnitCode, Description, Symbol)
    VALUES
      (@CompanyId, N'UND',  N'Unidad',           N'und'),
      (@CompanyId, N'KG',   N'Kilogramo',        N'kg'),
      (@CompanyId, N'GR',   N'Gramo',            N'gr'),
      (@CompanyId, N'LT',   N'Litro',            N'lt'),
      (@CompanyId, N'ML',   N'Mililitro',        N'ml'),
      (@CompanyId, N'MT',   N'Metro',            N'm'),
      (@CompanyId, N'CM',   N'Centímetro',       N'cm'),
      (@CompanyId, N'PAQ',  N'Paquete',          N'paq'),
      (@CompanyId, N'CAJA', N'Caja',             N'caja'),
      (@CompanyId, N'DOC',  N'Docena',           N'doc'),
      (@CompanyId, N'HRS',  N'Horas',            N'hrs'),
      (@CompanyId, N'DIA',  N'Día',              N'día'),
      (@CompanyId, N'SER',  N'Servicio (global)',N'srv');
  END;

  -- Vendedores
  IF NOT EXISTS (SELECT 1 FROM master.Seller WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.Seller (CompanyId, SellerCode, SellerName, Commission, SellerType, IsActive)
    VALUES
      (@CompanyId, N'V001', N'Vendedor General',     2.00, N'INTERNO', 1),
      (@CompanyId, N'V002', N'Ventas Corporativas',  3.50, N'INTERNO', 1),
      (@CompanyId, N'V003', N'Canal Distribución',   5.00, N'EXTERNO', 1),
      (@CompanyId, N'SHOW', N'Tienda / Mostrador',   0.00, N'MOSTRADOR', 1);
  END;

  -- Centros de costo
  IF NOT EXISTS (SELECT 1 FROM master.CostCenter WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.CostCenter (CompanyId, CostCenterCode, CostCenterName)
    VALUES
      (@CompanyId, N'CC-ADM', N'Administración'),
      (@CompanyId, N'CC-VEN', N'Ventas y Comercial'),
      (@CompanyId, N'CC-OPE', N'Operaciones'),
      (@CompanyId, N'CC-FIN', N'Finanzas'),
      (@CompanyId, N'CC-LOG', N'Logística y Almacén'),
      (@CompanyId, N'CC-TIC', N'Tecnología e Informática'),
      (@CompanyId, N'CC-RRH', N'Recursos Humanos');
  END;

  -- Retenciones fiscales
  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE CompanyId = @CompanyId)
  BEGIN
    INSERT INTO master.TaxRetention (CompanyId, RetentionCode, Description, RetentionType, RetentionRate, CountryCode)
    VALUES
      (@CompanyId, N'ISLR-1',   N'ISLR Servicios Profesionales 3%',   N'ISLR',      3.0000, N'VE'),
      (@CompanyId, N'ISLR-2',   N'ISLR Honorarios Profesionales 5%',  N'ISLR',      5.0000, N'VE'),
      (@CompanyId, N'ISLR-3',   N'ISLR Actividades Comerciales 2%',   N'ISLR',      2.0000, N'VE'),
      (@CompanyId, N'IVA-75',   N'Retención IVA 75%',                 N'IVA',      75.0000, N'VE'),
      (@CompanyId, N'IVA-100',  N'Retención IVA 100%',                N'IVA',     100.0000, N'VE'),
      (@CompanyId, N'MUN-1',    N'Impuesto Municipal Actividad 1%',   N'MUNICIPAL',  1.0000, N'VE'),
      (@CompanyId, N'MUN-2',    N'Impuesto Municipal Actividad 2%',   N'MUNICIPAL',  2.0000, N'VE');
  END;

  -- Monedas
  IF NOT EXISTS (SELECT 1 FROM cfg.Currency)
  BEGIN
    INSERT INTO cfg.Currency (CurrencyCode, CurrencyName, Symbol)
    VALUES
      (N'VES', N'Bolívar Soberano',    N'Bs.S'),
      (N'USD', N'Dólar Estadounidense',N'$'),
      (N'EUR', N'Euro',                N'€'),
      (N'COP', N'Peso Colombiano',     N'$'),
      (N'PEN', N'Sol Peruano',         N'S/.');
  END;

  -- Correlativos de documentos
  IF NOT EXISTS (SELECT 1 FROM cfg.DocumentSequence WHERE CompanyId = @CompanyId)
  BEGIN
    DECLARE @BranchMainId INT = (SELECT TOP 1 BranchId FROM cfg.Branch WHERE CompanyId = @CompanyId AND BranchCode = N'MAIN');
    INSERT INTO cfg.DocumentSequence (CompanyId, BranchId, DocumentType, Prefix, CurrentNumber, PaddingLength)
    VALUES
      (@CompanyId, @BranchMainId, N'FACT',     N'FAC', 1, 8),
      (@CompanyId, @BranchMainId, N'PEDIDO',   N'PED', 1, 8),
      (@CompanyId, @BranchMainId, N'COTIZ',    N'COT', 1, 8),
      (@CompanyId, @BranchMainId, N'PRESUP',   N'PRE', 1, 8),
      (@CompanyId, @BranchMainId, N'NOTACRED', N'NCA', 1, 8),
      (@CompanyId, @BranchMainId, N'NOTADEB',  N'NDE', 1, 8),
      (@CompanyId, @BranchMainId, N'NOTA_ENT', N'NEN', 1, 8),
      (@CompanyId, @BranchMainId, N'COMPRA',   N'COM', 1, 8),
      (@CompanyId, @BranchMainId, N'ORDEN',    N'ORC', 1, 8);
  END;

  -- Feriados Venezuela 2026
  IF NOT EXISTS (SELECT 1 FROM cfg.Holiday WHERE CountryCode = N'VE')
  BEGIN
    INSERT INTO cfg.Holiday (CountryCode, HolidayDate, HolidayName, IsRecurring)
    VALUES
      (N'VE', N'2026-01-01', N'Año Nuevo',                        1),
      (N'VE', N'2026-02-16', N'Lunes de Carnaval',                0),
      (N'VE', N'2026-02-17', N'Martes de Carnaval',               0),
      (N'VE', N'2026-04-02', N'Jueves Santo',                     0),
      (N'VE', N'2026-04-03', N'Viernes Santo',                    0),
      (N'VE', N'2026-04-19', N'Declaración de Independencia',     1),
      (N'VE', N'2026-05-01', N'Día del Trabajador',               1),
      (N'VE', N'2026-06-24', N'Batalla de Carabobo',              1),
      (N'VE', N'2026-07-05', N'Día de la Independencia',          1),
      (N'VE', N'2026-07-24', N'Natalicio de Simón Bolívar',       1),
      (N'VE', N'2026-10-12', N'Día de la Resistencia Indígena',   1),
      (N'VE', N'2026-12-24', N'Nochebuena',                       1),
      (N'VE', N'2026-12-25', N'Navidad',                          1),
      (N'VE', N'2026-12-31', N'Fin de Año',                       1);
  END;

  -- AccesoUsuarios seed para usuarios existentes
  IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Cod_Usuario = N'SUP')
    AND NOT EXISTS (SELECT 1 FROM dbo.AccesoUsuarios WHERE Cod_Usuario = N'SUP')
  BEGIN
    INSERT INTO dbo.AccesoUsuarios (Cod_Usuario, Modulo, Permitido)
    VALUES
      (N'SUP', N'dashboard',        1),
      (N'SUP', N'clientes',         1),
      (N'SUP', N'proveedores',      1),
      (N'SUP', N'inventario',       1),
      (N'SUP', N'articulos',        1),
      (N'SUP', N'facturas',         1),
      (N'SUP', N'documentos-venta', 1),
      (N'SUP', N'documentos-compra',1),
      (N'SUP', N'pedidos',          1),
      (N'SUP', N'cotizaciones',     1),
      (N'SUP', N'presupuestos',     1),
      (N'SUP', N'compras',          1),
      (N'SUP', N'abonos',           1),
      (N'SUP', N'pagos',            1),
      (N'SUP', N'cxc',              1),
      (N'SUP', N'cxp',              1),
      (N'SUP', N'contabilidad',     1),
      (N'SUP', N'cuentas',          1),
      (N'SUP', N'bancos',           1),
      (N'SUP', N'nomina',           1),
      (N'SUP', N'empleados',        1),
      (N'SUP', N'almacen',          1),
      (N'SUP', N'categorias',       1),
      (N'SUP', N'marcas',           1),
      (N'SUP', N'unidades',         1),
      (N'SUP', N'vendedores',       1),
      (N'SUP', N'centro-costo',     1),
      (N'SUP', N'retenciones',      1),
      (N'SUP', N'movinvent',        1),
      (N'SUP', N'config',           1),
      (N'SUP', N'settings',         1),
      (N'SUP', N'reportes',         1),
      (N'SUP', N'pos',              1),
      (N'SUP', N'restaurante',      1),
      (N'SUP', N'fiscal',           1),
      (N'SUP', N'sistema',          1),
      (N'SUP', N'usuarios',         1),
      (N'SUP', N'supervision',      1),
      (N'SUP', N'media',            1),
      (N'SUP', N'empresa',          1);
  END;

  IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Cod_Usuario = N'OPERADOR')
    AND NOT EXISTS (SELECT 1 FROM dbo.AccesoUsuarios WHERE Cod_Usuario = N'OPERADOR')
  BEGIN
    INSERT INTO dbo.AccesoUsuarios (Cod_Usuario, Modulo, Permitido)
    VALUES
      (N'OPERADOR', N'dashboard',         1),
      (N'OPERADOR', N'facturas',          1),
      (N'OPERADOR', N'clientes',          1),
      (N'OPERADOR', N'inventario',        1),
      (N'OPERADOR', N'articulos',         1),
      (N'OPERADOR', N'pagos',             1),
      (N'OPERADOR', N'abonos',            1),
      (N'OPERADOR', N'pos',               1),
      (N'OPERADOR', N'restaurante',       1),
      (N'OPERADOR', N'reportes',          1);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

PRINT N'[19] Tablas canónicas maestras y seed data creados correctamente.';
GO
