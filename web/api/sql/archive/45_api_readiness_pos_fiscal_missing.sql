SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Completa readiness de objetos faltantes POS/FISCAL:
  - dbo.PosVentasEnEsperaDetalle
  - dbo.FiscalTaxRates
  - dbo.FiscalInvoiceTypes
*/

BEGIN TRY
  BEGIN TRAN;

  /* -------------------------------------------------------------------------- */
  /* POS: PosVentasEnEsperaDetalle                                              */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.PosVentasEnEsperaDetalle', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.PosVentasEnEsperaDetalle (
      Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      VentaEsperaId   INT NOT NULL,
      ProductoId      NVARCHAR(80) NOT NULL,
      Codigo          NVARCHAR(30) NULL,
      Nombre          NVARCHAR(200) NOT NULL,
      Cantidad        DECIMAL(10,3) NOT NULL,
      PrecioUnitario  DECIMAL(18,2) NOT NULL,
      Descuento       DECIMAL(18,2) NOT NULL CONSTRAINT DF_PosEspDet_Descuento DEFAULT(0),
      IVA             DECIMAL(5,2) NOT NULL CONSTRAINT DF_PosEspDet_IVA DEFAULT(16),
      Subtotal        DECIMAL(18,2) NOT NULL,
      Orden           INT NOT NULL CONSTRAINT DF_PosEspDet_Orden DEFAULT(0),
      CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_PosEspDet_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_PosEspDet_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedBy       NVARCHAR(120) NULL,
      UpdatedBy       NVARCHAR(120) NULL,
      IsDeleted       BIT NOT NULL CONSTRAINT DF_PosEspDet_IsDeleted DEFAULT(0),
      DeletedAt       DATETIME2(0) NULL,
      DeletedBy       NVARCHAR(120) NULL,
      RowVer          ROWVERSION NOT NULL
    );
  END;

  IF OBJECT_ID('dbo.FK_PosEsperaDetalle_Espera', 'F') IS NULL
  BEGIN
    ALTER TABLE dbo.PosVentasEnEsperaDetalle WITH CHECK
      ADD CONSTRAINT FK_PosEsperaDetalle_Espera
      FOREIGN KEY (VentaEsperaId) REFERENCES dbo.PosVentasEnEspera(Id) ON DELETE CASCADE;
  END;

  IF OBJECT_ID('dbo.FK_PosEsperaDetalle_Producto', 'F') IS NULL
  BEGIN
    ALTER TABLE dbo.PosVentasEnEsperaDetalle WITH CHECK
      ADD CONSTRAINT FK_PosEsperaDetalle_Producto
      FOREIGN KEY (ProductoId) REFERENCES dbo.Inventario(CODIGO);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.PosVentasEnEsperaDetalle')
      AND name = 'IX_PosEspDet_VentaEsperaId'
  )
  BEGIN
    CREATE INDEX IX_PosEspDet_VentaEsperaId
      ON dbo.PosVentasEnEsperaDetalle (VentaEsperaId, Orden);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.PosVentasEnEsperaDetalle')
      AND name = 'IX_PosEspDet_ProductoId'
  )
  BEGIN
    CREATE INDEX IX_PosEspDet_ProductoId
      ON dbo.PosVentasEnEsperaDetalle (ProductoId);
  END;

  /* -------------------------------------------------------------------------- */
  /* FISCAL: FiscalTaxRates                                                     */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.FiscalTaxRates', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalTaxRates (
      Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode         CHAR(2) NOT NULL,
      Code                VARCHAR(30) NOT NULL,
      Name                NVARCHAR(100) NOT NULL,
      Rate                DECIMAL(5,4) NOT NULL,
      SurchargeRate       DECIMAL(5,4) NULL,
      AppliesToPOS        BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_AppliesToPOS DEFAULT(1),
      AppliesToRestaurant BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_AppliesToRestaurant DEFAULT(1),
      IsDefault           BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_IsDefault DEFAULT(0),
      IsActive            BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_IsActive DEFAULT(1),
      SortOrder           INT NOT NULL CONSTRAINT DF_FiscalTaxRates_SortOrder DEFAULT(0),
      CreatedAt           DATETIME NOT NULL CONSTRAINT DF_FiscalTaxRates_CreatedAt DEFAULT(GETDATE()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalTaxRates_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedBy           NVARCHAR(120) NULL,
      UpdatedBy           NVARCHAR(120) NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedBy           NVARCHAR(120) NULL,
      RowVer              ROWVERSION NOT NULL
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.FiscalTaxRates')
      AND name = 'UQ_FiscalTaxRates_Code'
  )
  BEGIN
    CREATE UNIQUE INDEX UQ_FiscalTaxRates_Code
      ON dbo.FiscalTaxRates (CountryCode, Code);
  END;

  /* -------------------------------------------------------------------------- */
  /* FISCAL: FiscalInvoiceTypes                                                 */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.FiscalInvoiceTypes', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalInvoiceTypes (
      Id                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode           CHAR(2) NOT NULL,
      Code                  VARCHAR(20) NOT NULL,
      Name                  NVARCHAR(100) NOT NULL,
      IsRectificative       BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_IsRectificative DEFAULT(0),
      RequiresRecipientId   BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_RequiresRecipientId DEFAULT(0),
      MaxAmount             DECIMAL(18,2) NULL,
      RequiresFiscalPrinter BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_RequiresFiscalPrinter DEFAULT(0),
      IsActive              BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_IsActive DEFAULT(1),
      SortOrder             INT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_SortOrder DEFAULT(0),
      CreatedAt             DATETIME NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_CreatedAt DEFAULT(GETDATE()),
      UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedBy             NVARCHAR(120) NULL,
      UpdatedBy             NVARCHAR(120) NULL,
      IsDeleted             BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_IsDeleted DEFAULT(0),
      DeletedAt             DATETIME2(0) NULL,
      DeletedBy             NVARCHAR(120) NULL,
      RowVer                ROWVERSION NOT NULL
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.FiscalInvoiceTypes')
      AND name = 'UQ_FiscalInvoiceTypes_Code'
  )
  BEGIN
    CREATE UNIQUE INDEX UQ_FiscalInvoiceTypes_Code
      ON dbo.FiscalInvoiceTypes (CountryCode, Code);
  END;

  /* -------------------------------------------------------------------------- */
  /* Seeds fiscales VE / ES (idempotente)                                       */
  /* -------------------------------------------------------------------------- */
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='VE' AND Code='IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','IVA_GENERAL',N'IVA General',0.1600,1,1,1,10,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='VE' AND Code='IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','IVA_REDUCIDO',N'IVA Reducido',0.0800,0,1,1,20,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='VE' AND Code='IVA_ADICIONAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','IVA_ADICIONAL',N'IVA Adicional',0.3100,0,1,0,30,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='VE' AND Code='EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','EXENTO',N'Exento',0.0000,0,1,1,40,N'governance-readiness',N'governance-readiness');

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','IVA_GENERAL',N'IVA General',0.2100,1,1,0,10,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','IVA_REDUCIDO',N'IVA Reducido',0.1000,0,1,1,20,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='IVA_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','IVA_SUPERREDUCIDO',N'IVA Superreducido',0.0400,0,1,0,30,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','EXENTO',N'Exento',0.0000,0,1,0,40,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='RE_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','RE_GENERAL',N'Recargo Equivalencia General',0.0520,0.0520,0,1,0,50,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='RE_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','RE_REDUCIDO',N'Recargo Equivalencia Reducido',0.0140,0.0140,0,1,0,60,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode='ES' AND Code='RE_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, IsDefault, AppliesToPOS, AppliesToRestaurant, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','RE_SUPERREDUCIDO',N'Recargo Equivalencia Superreducido',0.0050,0.0050,0,0,0,70,N'governance-readiness',N'governance-readiness');

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='VE' AND Code='FACTURA')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','FACTURA',N'Factura Fiscal',0,1,1,10,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='VE' AND Code='NOTA_CREDITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','NOTA_CREDITO',N'Nota de Credito Fiscal',1,1,1,20,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='VE' AND Code='NOTA_DEBITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','NOTA_DEBITO',N'Nota de Debito Fiscal',0,1,1,30,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='VE' AND Code='NOTA_ENTREGA')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('VE','NOTA_ENTREGA',N'Nota de Entrega',0,0,0,40,N'governance-readiness',N'governance-readiness');

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='F1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','F1',N'Factura Completa',0,1,NULL,0,10,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='F2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','F2',N'Factura Simplificada',0,0,400.00,0,20,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='F3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','F3',N'Factura Sustitucion Simplificada',0,1,NULL,0,30,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='R1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','R1',N'Rectificativa R1',1,1,NULL,0,40,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='R2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','R2',N'Rectificativa R2',1,1,NULL,0,50,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='R3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','R3',N'Rectificativa R3',1,1,NULL,0,60,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='R4')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','R4',N'Rectificativa R4',1,1,NULL,0,70,N'governance-readiness',N'governance-readiness');
  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode='ES' AND Code='R5')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder, CreatedBy, UpdatedBy)
    VALUES ('ES','R5',N'Rectificativa R5',1,0,NULL,0,80,N'governance-readiness',N'governance-readiness');

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 45_api_readiness_pos_fiscal_missing.sql: %s', 16, 1, @Err);
END CATCH;
GO
