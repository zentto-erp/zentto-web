-- ============================================================
-- DatqBoxWeb PostgreSQL - 09_canonical_maestros.sql
-- Tablas maestras canonicas: master.*, cfg.* y seed data
-- Fuente: 19_canonical_maestros_and_missing.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECCION 1: TABLAS CANONICAS EN SCHEMA master
-- ============================================================

-- master.Category (Categorias de productos)
CREATE TABLE IF NOT EXISTS master."Category" (
  "CategoryId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "CategoryCode"    VARCHAR(20)   NULL,
  "CategoryName"    VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "UserCode"        VARCHAR(20)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Category_CompanyName"
  ON master."Category" ("CompanyId", "CategoryName") WHERE "IsDeleted" = FALSE;

-- master.Brand (Marcas de productos)
CREATE TABLE IF NOT EXISTS master."Brand" (
  "BrandId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "BrandCode"       VARCHAR(20)   NULL,
  "BrandName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "UserCode"        VARCHAR(20)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Brand_CompanyName"
  ON master."Brand" ("CompanyId", "BrandName") WHERE "IsDeleted" = FALSE;

-- master.Warehouse (Almacenes)
CREATE TABLE IF NOT EXISTS master."Warehouse" (
  "WarehouseId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "BranchId"        INT           NULL,
  "WarehouseCode"   VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(200)  NOT NULL,
  "WarehouseType"   VARCHAR(20)   NOT NULL DEFAULT 'PRINCIPAL',
  "AddressLine"     VARCHAR(250)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Warehouse_CompanyCode"
  ON master."Warehouse" ("CompanyId", "WarehouseCode") WHERE "IsDeleted" = FALSE;

-- master.ProductLine (Lineas de productos)
CREATE TABLE IF NOT EXISTS master."ProductLine" (
  "LineId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "LineCode"        VARCHAR(20)   NOT NULL,
  "LineName"        VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductClass (Clases de productos)
CREATE TABLE IF NOT EXISTS master."ProductClass" (
  "ClassId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "ClassCode"       VARCHAR(20)   NOT NULL,
  "ClassName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductGroup (Grupos de productos)
CREATE TABLE IF NOT EXISTS master."ProductGroup" (
  "GroupId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "GroupCode"       VARCHAR(20)   NOT NULL,
  "GroupName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductType (Tipos de productos)
CREATE TABLE IF NOT EXISTS master."ProductType" (
  "TypeId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "TypeCode"        VARCHAR(20)   NOT NULL,
  "TypeName"        VARCHAR(100)  NOT NULL,
  "CategoryCode"    VARCHAR(50)   NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.UnitOfMeasure (Unidades de medida)
CREATE TABLE IF NOT EXISTS master."UnitOfMeasure" (
  "UnitId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "UnitCode"        VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(100)  NOT NULL,
  "Symbol"          VARCHAR(10)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_UnitOfMeasure_CompanyCode"
  ON master."UnitOfMeasure" ("CompanyId", "UnitCode") WHERE "IsDeleted" = FALSE;

-- master.Seller (Vendedores / Agentes)
CREATE TABLE IF NOT EXISTS master."Seller" (
  "SellerId"        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "SellerCode"      VARCHAR(10)   NOT NULL,
  "SellerName"      VARCHAR(120)  NOT NULL,
  "Commission"      NUMERIC(5,2)  NOT NULL DEFAULT 0,
  "Address"         VARCHAR(250)  NULL,
  "Phone"           VARCHAR(60)   NULL,
  "Email"           VARCHAR(150)  NULL,
  "SellerType"      VARCHAR(20)   NOT NULL DEFAULT 'INTERNO',
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Seller_CompanyCode"
  ON master."Seller" ("CompanyId", "SellerCode") WHERE "IsDeleted" = FALSE;

-- master.CostCenter (Centros de costo)
CREATE TABLE IF NOT EXISTS master."CostCenter" (
  "CostCenterId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "CostCenterCode"  VARCHAR(20)   NOT NULL,
  "CostCenterName"  VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.TaxRetention (Retenciones fiscales)
CREATE TABLE IF NOT EXISTS master."TaxRetention" (
  "RetentionId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "RetentionCode"   VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(200)  NOT NULL,
  "RetentionType"   VARCHAR(20)   NOT NULL DEFAULT 'ISLR',
  "RetentionRate"   NUMERIC(8,4)  NOT NULL DEFAULT 0,
  "CountryCode"     CHAR(2)       NOT NULL DEFAULT 'VE',
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_TaxRetention_CompanyCode"
  ON master."TaxRetention" ("CompanyId", "RetentionCode") WHERE "IsDeleted" = FALSE;

-- master.InventoryMovement (Movimientos de inventario)
CREATE TABLE IF NOT EXISTS master."InventoryMovement" (
  "MovementId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT            NOT NULL DEFAULT 1,
  "BranchId"        INT            NULL,
  "ProductCode"     VARCHAR(80)    NOT NULL,
  "ProductName"     VARCHAR(250)   NULL,
  "DocumentRef"     VARCHAR(60)    NULL,
  "MovementType"    VARCHAR(20)    NOT NULL DEFAULT 'ENTRADA',
  "MovementDate"    DATE           NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
  "Quantity"        NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "UnitCost"        NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "TotalCost"       NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "Notes"           VARCHAR(300)   NULL,
  "IsDeleted"       BOOLEAN        NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT            NULL,
  "UpdatedByUserId" INT            NULL
);

CREATE INDEX IF NOT EXISTS "IX_InventoryMovement_ProductDate"
  ON master."InventoryMovement" ("ProductCode", "MovementDate" DESC) WHERE "IsDeleted" = FALSE;

-- master.InventoryPeriodSummary (Cierre mensual inventario)
CREATE TABLE IF NOT EXISTS master."InventoryPeriodSummary" (
  "SummaryId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT            NOT NULL DEFAULT 1,
  "Period"      CHAR(6)        NOT NULL,  -- YYYYMM
  "ProductCode" VARCHAR(80)    NOT NULL,
  "OpeningQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "InboundQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "OutboundQty" NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "ClosingQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "SummaryDate" DATE           NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
  "IsClosed"    BOOLEAN        NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_InventoryPeriodSummary_Key"
  ON master."InventoryPeriodSummary" ("CompanyId", "Period", "ProductCode");

-- master.SupplierLine (Lineas de proveedores)
CREATE TABLE IF NOT EXISTS master."SupplierLine" (
  "SupplierLineId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "LineCode"        VARCHAR(20)   NOT NULL,
  "LineName"        VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- SECCION 2: TABLAS EN SCHEMA cfg
-- ============================================================

-- cfg.Holiday (Dias feriados)
CREATE TABLE IF NOT EXISTS cfg."Holiday" (
  "HolidayId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CountryCode"  CHAR(2)      NOT NULL DEFAULT 'VE',
  "HolidayDate"  DATE         NOT NULL,
  "HolidayName"  VARCHAR(100) NOT NULL,
  "IsRecurring"  BOOLEAN      NOT NULL DEFAULT FALSE,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- cfg.DocumentSequence (Correlativos / Secuencias de documentos)
CREATE TABLE IF NOT EXISTS cfg."DocumentSequence" (
  "SequenceId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "BranchId"      INT          NULL,
  "DocumentType"  VARCHAR(20)  NOT NULL,
  "Prefix"        VARCHAR(10)  NULL,
  "Suffix"        VARCHAR(10)  NULL,
  "CurrentNumber" BIGINT       NOT NULL DEFAULT 1,
  "PaddingLength" INT          NOT NULL DEFAULT 8,
  "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DocumentSequence_NoBranch"
  ON cfg."DocumentSequence" ("CompanyId", "DocumentType")
  WHERE "BranchId" IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DocumentSequence_Branch"
  ON cfg."DocumentSequence" ("CompanyId", "BranchId", "DocumentType")
  WHERE "BranchId" IS NOT NULL;

-- cfg.Currency (Catalogo de monedas)
CREATE TABLE IF NOT EXISTS cfg."Currency" (
  "CurrencyId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CurrencyCode" CHAR(3)      NOT NULL,
  "CurrencyName" VARCHAR(60)  NOT NULL,
  "Symbol"       VARCHAR(10)  NULL,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_Currency_Code" UNIQUE ("CurrencyCode")
);

-- cfg.ReportTemplate (Plantillas de reportes)
CREATE TABLE IF NOT EXISTS cfg."ReportTemplate" (
  "ReportId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT           NOT NULL DEFAULT 1,
  "ReportCode"  VARCHAR(50)   NOT NULL,
  "ReportName"  VARCHAR(150)  NOT NULL,
  "ReportType"  VARCHAR(20)   NOT NULL DEFAULT 'REPORT',
  "QueryText"   TEXT          NULL,
  "Parameters"  TEXT          NULL,
  "IsActive"    BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"   BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- cfg.CompanyProfile (Perfil extendido de empresa)
CREATE TABLE IF NOT EXISTS cfg."CompanyProfile" (
  "ProfileId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT           NOT NULL,
  "Phone"       VARCHAR(60)   NULL,
  "AddressLine" VARCHAR(250)  NULL,
  "NitCode"     VARCHAR(50)   NULL,
  "AltFiscalId" VARCHAR(50)   NULL,
  "WebSite"     VARCHAR(150)  NULL,
  "LogoBase64"  TEXT          NULL,
  "Notes"       VARCHAR(500)  NULL,
  "UpdatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_CompanyProfile_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CompanyProfile_CompanyId"
  ON cfg."CompanyProfile" ("CompanyId");

-- ============================================================
-- SECCION 3: TABLA DE COMPATIBILIDAD public.AccesoUsuarios
-- ============================================================
CREATE TABLE IF NOT EXISTS public."AccesoUsuarios" (
  "Cod_Usuario" VARCHAR(20)  NOT NULL,
  "Modulo"      VARCHAR(60)  NOT NULL,
  "Permitido"   BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  PRIMARY KEY ("Cod_Usuario", "Modulo")
);

-- ============================================================
-- Inicializar perfil DEFAULT de empresa
-- ============================================================
INSERT INTO cfg."CompanyProfile" ("CompanyId", "Phone", "AddressLine")
SELECT c."CompanyId", '+58 212 555-0000', 'Direccion Principal'
FROM cfg."Company" c
WHERE c."CompanyCode" = 'DEFAULT'
  AND NOT EXISTS (
    SELECT 1 FROM cfg."CompanyProfile" cp WHERE cp."CompanyId" = c."CompanyId"
  )
LIMIT 1;

-- ============================================================
-- SECCION 4: SEED DATA (datos de referencia)
-- ============================================================
DO $$
DECLARE
  v_CompanyId INT;
  v_BranchId  INT;
BEGIN
  SELECT "CompanyId" INTO v_CompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

  IF v_CompanyId IS NULL THEN RETURN; END IF;

  SELECT "BranchId" INTO v_BranchId
    FROM cfg."Branch" WHERE "CompanyId" = v_CompanyId AND "BranchCode" = 'MAIN' LIMIT 1;

  -- Categorias de productos
  IF NOT EXISTS (SELECT 1 FROM master."Category" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Category" ("CompanyId", "CategoryCode", "CategoryName", "Description") VALUES
      (v_CompanyId, 'PROD',    'Productos',         'Articulos de venta general'),
      (v_CompanyId, 'SERV',    'Servicios',          'Servicios y honorarios'),
      (v_CompanyId, 'INSUMOS', 'Insumos',            'Materiales de produccion e insumos'),
      (v_CompanyId, 'REPUEST', 'Repuestos',          'Repuestos y piezas de mantenimiento'),
      (v_CompanyId, 'MATERI',  'Materia Prima',      'Materias primas industriales'),
      (v_CompanyId, 'COMIDA',  'Alimentos',          'Productos alimenticios'),
      (v_CompanyId, 'BEBIDA',  'Bebidas',            'Bebidas y refrescos'),
      (v_CompanyId, 'TECNOL',  'Tecnologia',         'Equipos y perifericos tecnologicos'),
      (v_CompanyId, 'OFICI',   'Oficina',            'Articulos de oficina y papeleria'),
      (v_CompanyId, 'LIMPI',   'Limpieza',           'Productos de limpieza e higiene');
  END IF;

  -- Marcas
  IF NOT EXISTS (SELECT 1 FROM master."Brand" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Brand" ("CompanyId", "BrandCode", "BrandName", "Description") VALUES
      (v_CompanyId, 'GEN',    'Generico',       'Marca generica sin especificar'),
      (v_CompanyId, 'PROPI',  'Marca Propia',   'Productos con marca de la empresa'),
      (v_CompanyId, 'IMPORT', 'Importado',      'Productos importados');
  END IF;

  -- Almacenes
  IF NOT EXISTS (SELECT 1 FROM master."Warehouse" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "Description", "WarehouseType") VALUES
      (v_CompanyId, v_BranchId, 'PRINCIPAL', 'Almacen Principal',              'PRINCIPAL'),
      (v_CompanyId, v_BranchId, 'SERVICIO',  'Almacen Servicio',               'SERVICIO'),
      (v_CompanyId, v_BranchId, 'PLANTA',    'Almacen Planta',                 'PLANTA'),
      (v_CompanyId, v_BranchId, 'CONSIG',    'Almacen Consignacion',           'CONSIGNACION'),
      (v_CompanyId, v_BranchId, 'AVERIA',    'Almacen Averias/Devoluciones',   'AVERIA');
  END IF;

  -- Lineas de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductLine" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductLine" ("CompanyId", "LineCode", "LineName") VALUES
      (v_CompanyId, 'LIN-A', 'Linea A - Premium'),
      (v_CompanyId, 'LIN-B', 'Linea B - Estandar'),
      (v_CompanyId, 'LIN-C', 'Linea C - Economica'),
      (v_CompanyId, 'LIN-S', 'Linea Servicios'),
      (v_CompanyId, 'LIN-I', 'Linea Importados');
  END IF;

  -- Clases de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductClass" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductClass" ("CompanyId", "ClassCode", "ClassName") VALUES
      (v_CompanyId, 'CL-CONS', 'Consumible'),
      (v_CompanyId, 'CL-DURA', 'Durable'),
      (v_CompanyId, 'CL-SERV', 'Servicio Tecnico'),
      (v_CompanyId, 'CL-PROM', 'Promocional'),
      (v_CompanyId, 'CL-ACTF', 'Activo Fijo');
  END IF;

  -- Grupos de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductGroup" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductGroup" ("CompanyId", "GroupCode", "GroupName") VALUES
      (v_CompanyId, 'GR-01', 'Grupo Ventas Directas'),
      (v_CompanyId, 'GR-02', 'Grupo Distribucion'),
      (v_CompanyId, 'GR-03', 'Grupo Exportacion'),
      (v_CompanyId, 'GR-04', 'Grupo Uso Interno');
  END IF;

  -- Tipos de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductType" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductType" ("CompanyId", "TypeCode", "TypeName", "CategoryCode") VALUES
      (v_CompanyId, 'TIP-FIN', 'Producto Terminado',   NULL),
      (v_CompanyId, 'TIP-SEM', 'Semielaborado',        NULL),
      (v_CompanyId, 'TIP-INS', 'Insumo/Materia Prima', 'INSUMOS'),
      (v_CompanyId, 'TIP-SER', 'Servicio',             'SERV'),
      (v_CompanyId, 'TIP-REP', 'Repuesto',             'REPUEST');
  END IF;

  -- Unidades de medida
  IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."UnitOfMeasure" ("CompanyId", "UnitCode", "Description", "Symbol") VALUES
      (v_CompanyId, 'UND',  'Unidad',            'und'),
      (v_CompanyId, 'KG',   'Kilogramo',         'kg'),
      (v_CompanyId, 'GR',   'Gramo',             'gr'),
      (v_CompanyId, 'LT',   'Litro',             'lt'),
      (v_CompanyId, 'ML',   'Mililitro',         'ml'),
      (v_CompanyId, 'MT',   'Metro',             'm'),
      (v_CompanyId, 'CM',   'Centimetro',        'cm'),
      (v_CompanyId, 'PAQ',  'Paquete',           'paq'),
      (v_CompanyId, 'CAJA', 'Caja',              'caja'),
      (v_CompanyId, 'DOC',  'Docena',            'doc'),
      (v_CompanyId, 'HRS',  'Horas',             'hrs'),
      (v_CompanyId, 'DIA',  'Dia',               'dia'),
      (v_CompanyId, 'SER',  'Servicio (global)', 'srv');
  END IF;

  -- Vendedores
  IF NOT EXISTS (SELECT 1 FROM master."Seller" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Seller" ("CompanyId", "SellerCode", "SellerName", "Commission", "SellerType", "IsActive") VALUES
      (v_CompanyId, 'V001', 'Vendedor General',     2.00, 'INTERNO', TRUE),
      (v_CompanyId, 'V002', 'Ventas Corporativas',  3.50, 'INTERNO', TRUE),
      (v_CompanyId, 'V003', 'Canal Distribucion',   5.00, 'EXTERNO', TRUE),
      (v_CompanyId, 'SHOW', 'Tienda / Mostrador',   0.00, 'MOSTRADOR', TRUE);
  END IF;

  -- Centros de costo
  IF NOT EXISTS (SELECT 1 FROM master."CostCenter" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName") VALUES
      (v_CompanyId, 'CC-ADM', 'Administracion'),
      (v_CompanyId, 'CC-VEN', 'Ventas y Comercial'),
      (v_CompanyId, 'CC-OPE', 'Operaciones'),
      (v_CompanyId, 'CC-FIN', 'Finanzas'),
      (v_CompanyId, 'CC-LOG', 'Logistica y Almacen'),
      (v_CompanyId, 'CC-TIC', 'Tecnologia e Informatica'),
      (v_CompanyId, 'CC-RRH', 'Recursos Humanos');
  END IF;

  -- Retenciones fiscales
  IF NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."TaxRetention" ("CompanyId", "RetentionCode", "Description", "RetentionType", "RetentionRate", "CountryCode") VALUES
      (v_CompanyId, 'ISLR-1',   'ISLR Servicios Profesionales 3%',   'ISLR',      3.0000, 'VE'),
      (v_CompanyId, 'ISLR-2',   'ISLR Honorarios Profesionales 5%',  'ISLR',      5.0000, 'VE'),
      (v_CompanyId, 'ISLR-3',   'ISLR Actividades Comerciales 2%',   'ISLR',      2.0000, 'VE'),
      (v_CompanyId, 'IVA-75',   'Retencion IVA 75%',                 'IVA',      75.0000, 'VE'),
      (v_CompanyId, 'IVA-100',  'Retencion IVA 100%',                'IVA',     100.0000, 'VE'),
      (v_CompanyId, 'MUN-1',    'Impuesto Municipal Actividad 1%',   'MUNICIPAL',  1.0000, 'VE'),
      (v_CompanyId, 'MUN-2',    'Impuesto Municipal Actividad 2%',   'MUNICIPAL',  2.0000, 'VE');
  END IF;

  -- Monedas
  IF NOT EXISTS (SELECT 1 FROM cfg."Currency") THEN
    INSERT INTO cfg."Currency" ("CurrencyCode", "CurrencyName", "Symbol") VALUES
      ('VES', 'Bolivar Soberano',      'Bs.S'),
      ('USD', 'Dolar Estadounidense',  '$'),
      ('EUR', 'Euro',                  'E'),
      ('COP', 'Peso Colombiano',       '$'),
      ('PEN', 'Sol Peruano',           'S/.');
  END IF;

  -- Correlativos de documentos
  IF NOT EXISTS (SELECT 1 FROM cfg."DocumentSequence" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO cfg."DocumentSequence" ("CompanyId", "BranchId", "DocumentType", "Prefix", "CurrentNumber", "PaddingLength") VALUES
      (v_CompanyId, v_BranchId, 'FACT',     'FAC', 1, 8),
      (v_CompanyId, v_BranchId, 'PEDIDO',   'PED', 1, 8),
      (v_CompanyId, v_BranchId, 'COTIZ',    'COT', 1, 8),
      (v_CompanyId, v_BranchId, 'PRESUP',   'PRE', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTACRED', 'NCA', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTADEB',  'NDE', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTA_ENT', 'NEN', 1, 8),
      (v_CompanyId, v_BranchId, 'COMPRA',   'COM', 1, 8),
      (v_CompanyId, v_BranchId, 'ORDEN',    'ORC', 1, 8);
  END IF;

  -- Feriados Venezuela 2026
  IF NOT EXISTS (SELECT 1 FROM cfg."Holiday" WHERE "CountryCode" = 'VE') THEN
    INSERT INTO cfg."Holiday" ("CountryCode", "HolidayDate", "HolidayName", "IsRecurring") VALUES
      ('VE', '2026-01-01', 'Anio Nuevo',                        TRUE),
      ('VE', '2026-02-16', 'Lunes de Carnaval',                 FALSE),
      ('VE', '2026-02-17', 'Martes de Carnaval',                FALSE),
      ('VE', '2026-04-02', 'Jueves Santo',                      FALSE),
      ('VE', '2026-04-03', 'Viernes Santo',                     FALSE),
      ('VE', '2026-04-19', 'Declaracion de Independencia',      TRUE),
      ('VE', '2026-05-01', 'Dia del Trabajador',                TRUE),
      ('VE', '2026-06-24', 'Batalla de Carabobo',               TRUE),
      ('VE', '2026-07-05', 'Dia de la Independencia',           TRUE),
      ('VE', '2026-07-24', 'Natalicio de Simon Bolivar',        TRUE),
      ('VE', '2026-10-12', 'Dia de la Resistencia Indigena',    TRUE),
      ('VE', '2026-12-24', 'Nochebuena',                        TRUE),
      ('VE', '2026-12-25', 'Navidad',                           TRUE),
      ('VE', '2026-12-31', 'Fin de Anio',                       TRUE);
  END IF;

  -- AccesoUsuarios seed para SUP
  IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = 'SUP' AND "IsDeleted" = FALSE)
    AND NOT EXISTS (SELECT 1 FROM public."AccesoUsuarios" WHERE "Cod_Usuario" = 'SUP')
  THEN
    INSERT INTO public."AccesoUsuarios" ("Cod_Usuario", "Modulo", "Permitido") VALUES
      ('SUP', 'dashboard',         TRUE), ('SUP', 'clientes',         TRUE),
      ('SUP', 'proveedores',       TRUE), ('SUP', 'inventario',       TRUE),
      ('SUP', 'articulos',         TRUE), ('SUP', 'facturas',         TRUE),
      ('SUP', 'documentos-venta',  TRUE), ('SUP', 'documentos-compra',TRUE),
      ('SUP', 'pedidos',           TRUE), ('SUP', 'cotizaciones',     TRUE),
      ('SUP', 'presupuestos',      TRUE), ('SUP', 'compras',          TRUE),
      ('SUP', 'abonos',            TRUE), ('SUP', 'pagos',            TRUE),
      ('SUP', 'cxc',               TRUE), ('SUP', 'cxp',              TRUE),
      ('SUP', 'contabilidad',      TRUE), ('SUP', 'cuentas',          TRUE),
      ('SUP', 'bancos',            TRUE), ('SUP', 'nomina',           TRUE),
      ('SUP', 'empleados',         TRUE), ('SUP', 'almacen',          TRUE),
      ('SUP', 'categorias',        TRUE), ('SUP', 'marcas',           TRUE),
      ('SUP', 'unidades',          TRUE), ('SUP', 'vendedores',       TRUE),
      ('SUP', 'centro-costo',      TRUE), ('SUP', 'retenciones',      TRUE),
      ('SUP', 'movinvent',         TRUE), ('SUP', 'config',           TRUE),
      ('SUP', 'settings',          TRUE), ('SUP', 'reportes',         TRUE),
      ('SUP', 'pos',               TRUE), ('SUP', 'restaurante',      TRUE),
      ('SUP', 'fiscal',            TRUE), ('SUP', 'sistema',          TRUE),
      ('SUP', 'usuarios',          TRUE), ('SUP', 'supervision',      TRUE),
      ('SUP', 'media',             TRUE), ('SUP', 'empresa',          TRUE);
  END IF;

  -- AccesoUsuarios seed para OPERADOR
  IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = 'OPERADOR' AND "IsDeleted" = FALSE)
    AND NOT EXISTS (SELECT 1 FROM public."AccesoUsuarios" WHERE "Cod_Usuario" = 'OPERADOR')
  THEN
    INSERT INTO public."AccesoUsuarios" ("Cod_Usuario", "Modulo", "Permitido") VALUES
      ('OPERADOR', 'dashboard',    TRUE), ('OPERADOR', 'facturas',     TRUE),
      ('OPERADOR', 'clientes',     TRUE), ('OPERADOR', 'inventario',   TRUE),
      ('OPERADOR', 'articulos',    TRUE), ('OPERADOR', 'pagos',        TRUE),
      ('OPERADOR', 'abonos',       TRUE), ('OPERADOR', 'pos',          TRUE),
      ('OPERADOR', 'restaurante',  TRUE), ('OPERADOR', 'reportes',     TRUE);
  END IF;

END $$;

COMMIT;
