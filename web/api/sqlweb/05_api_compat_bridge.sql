SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @DefaultBranchId INT = (SELECT TOP 1 BranchId FROM cfg.Branch WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN');

  IF @DefaultCompanyId IS NULL OR @DefaultBranchId IS NULL
    RAISERROR('Missing DEFAULT company/MAIN branch. Run 01_core_foundation.sql first.',16,1);

  IF OBJECT_ID('dbo.Cuentas', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Cuentas(
      Id               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Cod_Cuenta       NVARCHAR(40) NOT NULL,
      Desc_Cta         NVARCHAR(200) NOT NULL,
      Tipo             NCHAR(1) NOT NULL,
      Nivel            INT NOT NULL CONSTRAINT DF_Cuentas_Nivel DEFAULT(1),
      Cod_CtaPadre     NVARCHAR(40) NULL,
      Activo           BIT NOT NULL CONSTRAINT DF_Cuentas_Activo DEFAULT(1),
      Accepta_Detalle  BIT NOT NULL CONSTRAINT DF_Cuentas_Acepta DEFAULT(1),
      CreatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_Cuentas_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_Cuentas_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_Cuentas_CodCuenta UNIQUE (Cod_Cuenta),
      CONSTRAINT CK_Cuentas_Tipo CHECK (Tipo IN (N'A',N'P',N'C',N'I',N'G'))
    );
  END;

  IF OBJECT_ID('dbo.Asientos', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Asientos(
      Id                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Fecha              DATE NOT NULL CONSTRAINT DF_Asientos_Fecha DEFAULT(CAST(SYSUTCDATETIME() AS DATE)),
      Tipo_Asiento       NVARCHAR(20) NOT NULL,
      Concepto           NVARCHAR(400) NOT NULL,
      Referencia         NVARCHAR(120) NULL,
      Estado             NVARCHAR(20) NOT NULL CONSTRAINT DF_Asientos_Estado DEFAULT('APROBADO'),
      Total_Debe         DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asientos_TotalDebe DEFAULT(0),
      Total_Haber        DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asientos_TotalHaber DEFAULT(0),
      Origen_Modulo      NVARCHAR(40) NULL,
      Cod_Usuario        NVARCHAR(120) NULL,
      AsientoContableId  BIGINT NULL,
      FechaCreacion      DATETIME2(0) NOT NULL CONSTRAINT DF_Asientos_FechaCreacion DEFAULT(SYSUTCDATETIME()),
      FechaActualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_Asientos_FechaActualizacion DEFAULT(SYSUTCDATETIME())
    );

    CREATE INDEX IX_Asientos_Fecha ON dbo.Asientos (Fecha DESC, Id DESC);
    CREATE INDEX IX_Asientos_AsientoContableId ON dbo.Asientos (AsientoContableId);
  END;

  IF OBJECT_ID('dbo.Asientos_Detalle', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Asientos_Detalle(
      Id             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Id_Asiento     INT NOT NULL,
      Cod_Cuenta     NVARCHAR(40) NOT NULL,
      Descripcion    NVARCHAR(400) NULL,
      CentroCosto    NVARCHAR(20) NULL,
      AuxiliarTipo   NVARCHAR(30) NULL,
      AuxiliarCodigo NVARCHAR(120) NULL,
      Documento      NVARCHAR(120) NULL,
      Debe           DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientosDetalle_Debe DEFAULT(0),
      Haber          DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientosDetalle_Haber DEFAULT(0),
      FechaCreacion  DATETIME2(0) NOT NULL CONSTRAINT DF_AsientosDetalle_FechaCreacion DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_AsientosDetalle_Asientos FOREIGN KEY (Id_Asiento) REFERENCES dbo.Asientos(Id)
    );

    CREATE INDEX IX_AsientosDetalle_IdAsiento ON dbo.Asientos_Detalle (Id_Asiento, Id);
    CREATE INDEX IX_AsientosDetalle_CodCuenta ON dbo.Asientos_Detalle (Cod_Cuenta);
  END;

  IF OBJECT_ID('dbo.TasasDiarias', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.TasasDiarias(
      Id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Moneda    NVARCHAR(10) NOT NULL,
      Tasa      DECIMAL(18,6) NOT NULL,
      Fecha     DATETIME NOT NULL CONSTRAINT DF_TasasDiarias_Fecha DEFAULT(SYSUTCDATETIME()),
      Origen    NVARCHAR(120) NULL,
      CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_TasasDiarias_CreatedAt DEFAULT(SYSUTCDATETIME())
    );

    CREATE INDEX IX_TasasDiarias_Moneda_Fecha ON dbo.TasasDiarias (Moneda, Fecha DESC);
  END;

  IF OBJECT_ID('dbo.FiscalCountryConfig', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalCountryConfig(
      Id                   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      EmpresaId            INT NOT NULL,
      SucursalId           INT NOT NULL,
      CountryCode          CHAR(2) NOT NULL,
      Currency             CHAR(3) NOT NULL,
      TaxRegime            NVARCHAR(50) NULL,
      DefaultTaxCode       NVARCHAR(30) NULL,
      DefaultTaxRate       DECIMAL(9,4) NOT NULL,
      FiscalPrinterEnabled BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_FPE DEFAULT(0),
      PrinterBrand         NVARCHAR(30) NULL,
      PrinterPort          NVARCHAR(20) NULL,
      VerifactuEnabled     BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_VE DEFAULT(0),
      VerifactuMode        NVARCHAR(10) NULL,
      CertificatePath      NVARCHAR(500) NULL,
      CertificatePassword  NVARCHAR(255) NULL,
      AEATEndpoint         NVARCHAR(500) NULL,
      SenderNIF            NVARCHAR(20) NULL,
      SenderRIF            NVARCHAR(20) NULL,
      SoftwareId           NVARCHAR(100) NULL,
      SoftwareName         NVARCHAR(200) NULL,
      SoftwareVersion      NVARCHAR(20) NULL,
      PosEnabled           BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_Pos DEFAULT(1),
      RestaurantEnabled    BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_Rest DEFAULT(1),
      IsActive             BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_Act DEFAULT(1),
      CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalCountryConfig_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalCountryConfig_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_FiscalCountryConfig UNIQUE (EmpresaId, SucursalId, CountryCode),
      CONSTRAINT FK_FiscalCountryConfig_Company FOREIGN KEY (EmpresaId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_FiscalCountryConfig_Branch FOREIGN KEY (SucursalId) REFERENCES cfg.Branch(BranchId)
    );
  END;

  IF OBJECT_ID('dbo.FiscalTaxRates', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalTaxRates(
      Id                  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode         CHAR(2) NOT NULL,
      Code                NVARCHAR(30) NOT NULL,
      Name                NVARCHAR(120) NOT NULL,
      Rate                DECIMAL(9,4) NOT NULL,
      SurchargeRate       DECIMAL(9,4) NULL,
      AppliesToPOS        BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_POS DEFAULT(1),
      AppliesToRestaurant BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_REST DEFAULT(1),
      IsDefault           BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_DEF DEFAULT(0),
      IsActive            BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_ACT DEFAULT(1),
      SortOrder           INT NOT NULL CONSTRAINT DF_FiscalTaxRates_SORT DEFAULT(0),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalTaxRates_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalTaxRates_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_FiscalTaxRates UNIQUE (CountryCode, Code)
    );
  END;

  IF OBJECT_ID('dbo.FiscalInvoiceTypes', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalInvoiceTypes(
      Id                    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode           CHAR(2) NOT NULL,
      Code                  NVARCHAR(20) NOT NULL,
      Name                  NVARCHAR(120) NOT NULL,
      IsRectificative       BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_Rect DEFAULT(0),
      RequiresRecipientId   BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_ReqRecipient DEFAULT(0),
      MaxAmount             DECIMAL(18,2) NULL,
      RequiresFiscalPrinter BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_ReqPrinter DEFAULT(0),
      IsActive              BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_Act DEFAULT(1),
      SortOrder             INT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_Sort DEFAULT(0),
      CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_FiscalInvoiceTypes UNIQUE (CountryCode, Code)
    );
  END;

  IF OBJECT_ID('dbo.FiscalRecords', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.FiscalRecords(
      Id                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      EmpresaId          INT NOT NULL,
      SucursalId         INT NOT NULL,
      CountryCode        CHAR(2) NOT NULL,
      InvoiceId          INT NOT NULL,
      InvoiceType        NVARCHAR(20) NOT NULL,
      InvoiceNumber      NVARCHAR(50) NOT NULL,
      InvoiceDate        DATE NOT NULL,
      RecipientId        NVARCHAR(20) NULL,
      TotalAmount        DECIMAL(18,2) NOT NULL,
      RecordHash         VARCHAR(64) NOT NULL,
      PreviousRecordHash VARCHAR(64) NULL,
      XmlContent         NVARCHAR(MAX) NULL,
      DigitalSignature   NVARCHAR(MAX) NULL,
      QRCodeData         NVARCHAR(800) NULL,
      SentToAuthority    BIT NOT NULL CONSTRAINT DF_FiscalRecords_Sent DEFAULT(0),
      SentAt             DATETIME2(0) NULL,
      AuthorityResponse  NVARCHAR(MAX) NULL,
      AuthorityStatus    NVARCHAR(20) NULL,
      FiscalPrinterSerial NVARCHAR(30) NULL,
      FiscalControlNumber NVARCHAR(30) NULL,
      ZReportNumber      INT NULL,
      CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_FiscalRecords_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_FiscalRecords_Hash UNIQUE (RecordHash),
      CONSTRAINT FK_FiscalRecords_Config FOREIGN KEY (EmpresaId, SucursalId, CountryCode) REFERENCES dbo.FiscalCountryConfig(EmpresaId, SucursalId, CountryCode)
    );

    CREATE INDEX IX_FiscalRecords_Search ON dbo.FiscalRecords(EmpresaId, SucursalId, CountryCode, Id DESC);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 05_api_compat_bridge.sql (tables): %s',16,1,@Err);
END CATCH;
GO

IF OBJECT_ID('dbo.DtllAsiento', 'V') IS NOT NULL
  DROP VIEW dbo.DtllAsiento;
GO

CREATE VIEW dbo.DtllAsiento
AS
  SELECT
    CAST(Id AS BIGINT) AS Id,
    CAST(Id_Asiento AS BIGINT) AS Id_Asiento,
    Cod_Cuenta,
    Descripcion,
    Debe,
    Haber
  FROM dbo.Asientos_Detalle;
GO

IF OBJECT_ID('dbo.sp_CxC_Documentos_List', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.sp_CxC_Documentos_List AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_CxC_Documentos_List
  @CodCliente NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      c.CustomerCode AS codCliente,
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.TotalAmount AS total,
      d.PendingAmount AS pendiente,
      d.Status AS estado,
      d.Notes AS observacion,
      u.UserCode AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY d.IssueDate DESC, d.DocumentNumber DESC, d.ReceivableDocumentId DESC) AS rn
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    LEFT JOIN sec.[User] u ON u.UserId = d.CreatedByUserId
    WHERE (@CodCliente IS NULL OR c.CustomerCode = @CodCliente)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
  )
  SELECT codCliente, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion, codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;
GO

IF OBJECT_ID('dbo.sp_CxP_Documentos_List', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.sp_CxP_Documentos_List AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_CxP_Documentos_List
  @CodProveedor NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      s.SupplierCode AS codProveedor,
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.TotalAmount AS total,
      d.PendingAmount AS pendiente,
      d.Status AS estado,
      d.Notes AS observacion,
      u.UserCode AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY d.IssueDate DESC, d.DocumentNumber DESC, d.PayableDocumentId DESC) AS rn
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    LEFT JOIN sec.[User] u ON u.UserId = d.CreatedByUserId
    WHERE (@CodProveedor IS NULL OR s.SupplierCode = @CodProveedor)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
  )
  SELECT codProveedor, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion, codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;
GO
IF OBJECT_ID('dbo.TR_Asientos_AI_SyncJournalEntry', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_Asientos_AI_SyncJournalEntry;
GO

CREATE TRIGGER dbo.TR_Asientos_AI_SyncJournalEntry
ON dbo.Asientos
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @DefaultBranchId INT = (SELECT TOP 1 BranchId FROM cfg.Branch WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN');
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  IF @DefaultCompanyId IS NULL OR @DefaultBranchId IS NULL RETURN;

  DECLARE @Map TABLE (LegacyId INT NOT NULL, JournalEntryId BIGINT NOT NULL);

  MERGE acct.JournalEntry AS tgt
  USING (
    SELECT
      i.Id,
      i.Fecha,
      i.Tipo_Asiento,
      i.Referencia,
      i.Concepto,
      i.Estado,
      i.Total_Debe,
      i.Total_Haber,
      i.Origen_Modulo,
      u.UserId AS CreatedByUserId
    FROM inserted i
    LEFT JOIN sec.[User] u ON u.UserCode = LTRIM(RTRIM(i.Cod_Usuario))
    WHERE i.AsientoContableId IS NULL
  ) src
  ON 1 = 0
  WHEN NOT MATCHED THEN
    INSERT (
      CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType,
      ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit,
      Status, SourceModule, SourceDocumentType, SourceDocumentNo, CreatedAt, UpdatedAt,
      CreatedByUserId, UpdatedByUserId, IsDeleted
    )
    VALUES (
      @DefaultCompanyId,
      @DefaultBranchId,
      N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(src.Id AS NVARCHAR(20)), 10),
      src.Fecha,
      CONVERT(NVARCHAR(7), src.Fecha, 120),
      src.Tipo_Asiento,
      src.Referencia,
      src.Concepto,
      N'VES',
      1,
      src.Total_Debe,
      src.Total_Haber,
      CASE WHEN UPPER(src.Estado)=N'ANULADO' THEN N'VOIDED' WHEN UPPER(src.Estado)=N'APROBADO' THEN N'APPROVED' ELSE N'DRAFT' END,
      src.Origen_Modulo,
      src.Tipo_Asiento,
      src.Referencia,
      SYSUTCDATETIME(),
      SYSUTCDATETIME(),
      ISNULL(src.CreatedByUserId, @SystemUserId),
      ISNULL(src.CreatedByUserId, @SystemUserId),
      0
    )
    OUTPUT src.Id, inserted.JournalEntryId INTO @Map(LegacyId, JournalEntryId);

  UPDATE a
  SET a.AsientoContableId = m.JournalEntryId,
      a.FechaActualizacion = SYSUTCDATETIME()
  FROM dbo.Asientos a
  INNER JOIN @Map m ON m.LegacyId = a.Id;
END;
GO

IF OBJECT_ID('dbo.TR_AsientosDetalle_AI_SyncJournalEntryLine', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_AsientosDetalle_AI_SyncJournalEntryLine;
GO

CREATE TRIGGER dbo.TR_AsientosDetalle_AI_SyncJournalEntryLine
ON dbo.Asientos_Detalle
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  IF @DefaultCompanyId IS NULL RETURN;

  ;WITH MissingAccount AS (
    SELECT DISTINCT LTRIM(RTRIM(i.Cod_Cuenta)) AS CodCuenta
    FROM inserted i
    WHERE i.Cod_Cuenta IS NOT NULL
      AND LTRIM(RTRIM(i.Cod_Cuenta)) <> N''
      AND NOT EXISTS (
        SELECT 1 FROM acct.Account a
        WHERE a.CompanyId = @DefaultCompanyId
          AND a.AccountCode = LTRIM(RTRIM(i.Cod_Cuenta))
      )
  )
  INSERT INTO acct.Account (
    CompanyId, AccountCode, AccountName, AccountType, AccountLevel, ParentAccountId,
    AllowsPosting, RequiresAuxiliary, IsActive, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId, IsDeleted
  )
  SELECT
    @DefaultCompanyId,
    m.CodCuenta,
    N'Auto account ' + m.CodCuenta,
    N'G',
    5,
    NULL,
    1,
    0,
    1,
    SYSUTCDATETIME(),
    SYSUTCDATETIME(),
    @SystemUserId,
    @SystemUserId,
    0
  FROM MissingAccount m;

  ;WITH src AS (
    SELECT
      i.Id,
      a.AsientoContableId,
      LTRIM(RTRIM(i.Cod_Cuenta)) AS CodCuenta,
      i.Descripcion,
      i.CentroCosto,
      i.AuxiliarTipo,
      i.AuxiliarCodigo,
      i.Documento,
      i.Debe,
      i.Haber,
      ROW_NUMBER() OVER (PARTITION BY a.AsientoContableId ORDER BY i.Id) AS rn
    FROM inserted i
    INNER JOIN dbo.Asientos a ON a.Id = i.Id_Asiento
    WHERE a.AsientoContableId IS NOT NULL
  )
  INSERT INTO acct.JournalEntryLine (
    JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description,
    DebitAmount, CreditAmount, AuxiliaryType, AuxiliaryCode, CostCenterCode, SourceDocumentNo, CreatedAt, UpdatedAt
  )
  SELECT
    s.AsientoContableId,
    ISNULL(mx.MaxLine,0) + s.rn,
    acc.AccountId,
    s.CodCuenta,
    s.Descripcion,
    ISNULL(s.Debe,0),
    ISNULL(s.Haber,0),
    s.AuxiliarTipo,
    s.AuxiliarCodigo,
    s.CentroCosto,
    s.Documento,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
  FROM src s
  INNER JOIN acct.Account acc ON acc.CompanyId = @DefaultCompanyId AND acc.AccountCode = s.CodCuenta
  OUTER APPLY (
    SELECT MAX(l.LineNumber) AS MaxLine
    FROM acct.JournalEntryLine l
    WHERE l.JournalEntryId = s.AsientoContableId
  ) mx;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asientos_List', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Asientos_List AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Asientos_List
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @TipoAsiento NVARCHAR(20) = NULL,
  @Estado NVARCHAR(20) = NULL,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;
  
  DECLARE @Base TABLE (
    AsientoId BIGINT NOT NULL,
    NumeroAsiento NVARCHAR(40) NOT NULL,
    Fecha DATE NOT NULL,
    TipoAsiento NVARCHAR(20) NOT NULL,
    Referencia NVARCHAR(120) NULL,
    Concepto NVARCHAR(400) NOT NULL,
    Moneda NVARCHAR(10) NOT NULL,
    Tasa DECIMAL(18,6) NOT NULL,
    TotalDebe DECIMAL(18,2) NOT NULL,
    TotalHaber DECIMAL(18,2) NOT NULL,
    Estado NVARCHAR(20) NOT NULL,
    OrigenModulo NVARCHAR(40) NULL,
    CodUsuario NVARCHAR(120) NULL,
    rn INT NOT NULL
  );

  INSERT INTO @Base (
    AsientoId, NumeroAsiento, Fecha, TipoAsiento, Referencia, Concepto,
    Moneda, Tasa, TotalDebe, TotalHaber, Estado, OrigenModulo, CodUsuario, rn
  )
  SELECT
    a.Id AS AsientoId,
    N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(a.Id AS NVARCHAR(20)), 10) AS NumeroAsiento,
    a.Fecha,
    a.Tipo_Asiento AS TipoAsiento,
    a.Referencia,
    a.Concepto,
    N'VES' AS Moneda,
    CAST(1 AS DECIMAL(18,6)) AS Tasa,
    a.Total_Debe AS TotalDebe,
    a.Total_Haber AS TotalHaber,
    a.Estado,
    a.Origen_Modulo AS OrigenModulo,
    a.Cod_Usuario AS CodUsuario,
    ROW_NUMBER() OVER (ORDER BY a.Fecha DESC, a.Id DESC) AS rn
  FROM dbo.Asientos a
  WHERE (@FechaDesde IS NULL OR a.Fecha >= @FechaDesde)
    AND (@FechaHasta IS NULL OR a.Fecha <= @FechaHasta)
    AND (@TipoAsiento IS NULL OR a.Tipo_Asiento = @TipoAsiento)
    AND (@Estado IS NULL OR a.Estado = @Estado)
    AND (@OrigenModulo IS NULL OR a.Origen_Modulo = @OrigenModulo)
    AND (@OrigenDocumento IS NULL OR a.Referencia = @OrigenDocumento);

  SELECT @TotalCount = COUNT(1) FROM @Base;

  SELECT AsientoId, NumeroAsiento, Fecha, TipoAsiento, Referencia, Concepto, Moneda, Tasa,
         TotalDebe, TotalHaber, Estado, OrigenModulo, CodUsuario
  FROM @Base
  WHERE rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Get', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Get AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Asiento_Get
  @AsientoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    a.Id AS AsientoId,
    N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(a.Id AS NVARCHAR(20)), 10) AS NumeroAsiento,
    a.Fecha,
    a.Tipo_Asiento AS TipoAsiento,
    a.Referencia,
    a.Concepto,
    N'VES' AS Moneda,
    CAST(1 AS DECIMAL(18,6)) AS Tasa,
    a.Total_Debe AS TotalDebe,
    a.Total_Haber AS TotalHaber,
    a.Estado,
    a.Origen_Modulo AS OrigenModulo,
    a.Cod_Usuario AS CodUsuario
  FROM dbo.Asientos a
  WHERE a.Id = @AsientoId;

  SELECT
    d.Id,
    d.Id_Asiento AS AsientoId,
    d.Cod_Cuenta AS CodCuenta,
    d.Descripcion,
    d.CentroCosto,
    d.AuxiliarTipo,
    d.AuxiliarCodigo,
    d.Documento,
    d.Debe,
    d.Haber
  FROM dbo.Asientos_Detalle d
  WHERE d.Id_Asiento = @AsientoId
  ORDER BY d.Id;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Crear', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Crear AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Asiento_Crear
  @Fecha DATE,
  @TipoAsiento NVARCHAR(20),
  @Referencia NVARCHAR(120) = NULL,
  @Concepto NVARCHAR(400),
  @Moneda NVARCHAR(10) = N'VES',
  @Tasa DECIMAL(18,6) = 1,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @CodUsuario NVARCHAR(40) = NULL,
  @DetalleXml XML,
  @AsientoId BIGINT OUTPUT,
  @NumeroAsiento NVARCHAR(40) OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    DECLARE @Detalle TABLE (
      CodCuenta NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(400) NULL,
      CentroCosto NVARCHAR(20) NULL,
      AuxiliarTipo NVARCHAR(30) NULL,
      AuxiliarCodigo NVARCHAR(120) NULL,
      Documento NVARCHAR(120) NULL,
      Debe DECIMAL(18,2) NOT NULL,
      Haber DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Detalle (CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber)
    SELECT
      T.X.value('@codCuenta', 'nvarchar(40)'),
      NULLIF(T.X.value('@descripcion', 'nvarchar(400)'), N''),
      NULLIF(T.X.value('@centroCosto', 'nvarchar(20)'), N''),
      NULLIF(T.X.value('@auxiliarTipo', 'nvarchar(30)'), N''),
      NULLIF(T.X.value('@auxiliarCodigo', 'nvarchar(120)'), N''),
      NULLIF(T.X.value('@documento', 'nvarchar(120)'), N''),
      ISNULL(T.X.value('@debe', 'decimal(18,2)'), 0),
      ISNULL(T.X.value('@haber', 'decimal(18,2)'), 0)
    FROM @DetalleXml.nodes('/rows/row') T(X);

    IF NOT EXISTS (SELECT 1 FROM @Detalle)
    BEGIN
      SET @Resultado = 0;
      SET @Mensaje = N'Detalle contable vacio.';
      ROLLBACK TRAN;
      RETURN;
    END;

    DECLARE @TotalDebe DECIMAL(18,2) = (SELECT ISNULL(SUM(Debe),0) FROM @Detalle);
    DECLARE @TotalHaber DECIMAL(18,2) = (SELECT ISNULL(SUM(Haber),0) FROM @Detalle);

    IF @TotalDebe <> @TotalHaber
    BEGIN
      SET @Resultado = 0;
      SET @Mensaje = N'Asiento no balanceado.';
      ROLLBACK TRAN;
      RETURN;
    END;

    INSERT INTO dbo.Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (@Fecha, @TipoAsiento, @Concepto, ISNULL(@OrigenDocumento, @Referencia), N'APROBADO', @TotalDebe, @TotalHaber, @OrigenModulo, ISNULL(@CodUsuario, N'API'));

    SET @AsientoId = SCOPE_IDENTITY();

    INSERT INTO dbo.Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber)
    SELECT @AsientoId, CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber
    FROM @Detalle;

    SET @NumeroAsiento = N'LEG-' + RIGHT(REPLICATE(N'0',10) + CAST(@AsientoId AS NVARCHAR(20)), 10);
    SET @Resultado = 1;
    SET @Mensaje = N'Asiento creado correctamente.';

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Anular', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Anular AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Asiento_Anular
  @AsientoId BIGINT,
  @Motivo NVARCHAR(400),
  @CodUsuario NVARCHAR(40) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM dbo.Asientos WHERE Id = @AsientoId)
  BEGIN
    SET @Resultado = 0;
    SET @Mensaje = N'Asiento no encontrado.';
    RETURN;
  END;

  UPDATE dbo.Asientos
  SET Estado = N'ANULADO',
      Concepto = LEFT(Concepto + N' | ANULADO: ' + ISNULL(@Motivo, N''), 400),
      FechaActualizacion = SYSUTCDATETIME()
  WHERE Id = @AsientoId;

  SET @Resultado = 1;
  SET @Mensaje = N'Asiento anulado.';
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Ajuste_Crear', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Ajuste_Crear AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Ajuste_Crear
  @Fecha DATE,
  @TipoAjuste NVARCHAR(40),
  @Referencia NVARCHAR(120) = NULL,
  @Motivo NVARCHAR(500),
  @CodUsuario NVARCHAR(40) = NULL,
  @DetalleXml XML,
  @AsientoId BIGINT OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  DECLARE @NumeroAsiento NVARCHAR(40);

  EXEC dbo.usp_Contabilidad_Asiento_Crear
    @Fecha = @Fecha,
    @TipoAsiento = @TipoAjuste,
    @Referencia = @Referencia,
    @Concepto = @Motivo,
    @Moneda = N'VES',
    @Tasa = 1,
    @OrigenModulo = N'AJUSTE',
    @OrigenDocumento = @Referencia,
    @CodUsuario = @CodUsuario,
    @DetalleXml = @DetalleXml,
    @AsientoId = @AsientoId OUTPUT,
    @NumeroAsiento = @NumeroAsiento OUTPUT,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Depreciacion_Generar', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Depreciacion_Generar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Depreciacion_Generar
  @Periodo NVARCHAR(7),
  @CodUsuario NVARCHAR(40) = NULL,
  @CentroCosto NVARCHAR(20) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 1;
  SET @Mensaje = N'Proceso de depreciacion preparado (sin reglas cargadas).';
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Libro_Mayor', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Libro_Mayor AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Libro_Mayor
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.Cod_Cuenta AS CodCuenta, c.Desc_Cta AS Descripcion,
         SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber, SUM(d.Debe-d.Haber) AS Saldo
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  LEFT JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
  WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  GROUP BY d.Cod_Cuenta, c.Desc_Cta
  ORDER BY d.Cod_Cuenta;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Mayor_Analitico', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Mayor_Analitico AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Mayor_Analitico
  @CodCuenta NVARCHAR(40),
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT a.Id AS AsientoId, a.Fecha, a.Referencia, a.Concepto,
         d.Descripcion, d.Debe, d.Haber,
         SUM(d.Debe-d.Haber) OVER (ORDER BY a.Fecha, a.Id, d.Id ROWS UNBOUNDED PRECEDING) AS SaldoAcumulado
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  WHERE d.Cod_Cuenta = @CodCuenta
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  ORDER BY a.Fecha, a.Id, d.Id;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Balance_Comprobacion', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Balance_Comprobacion AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Balance_Comprobacion
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.Cod_Cuenta AS CodCuenta, c.Desc_Cta AS Descripcion,
         SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber, SUM(d.Debe-d.Haber) AS Saldo
  FROM dbo.Asientos_Detalle d
  INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
  LEFT JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
  WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
    AND a.Estado <> N'ANULADO'
  GROUP BY d.Cod_Cuenta, c.Desc_Cta
  ORDER BY d.Cod_Cuenta;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Estado_Resultados', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Estado_Resultados AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Estado_Resultados
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS (
    SELECT c.Tipo, d.Cod_Cuenta, c.Desc_Cta,
           SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber,
           SUM(d.Haber-d.Debe) AS SaldoResultado
    FROM dbo.Asientos_Detalle d
    INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
    INNER JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
    WHERE a.Fecha BETWEEN @FechaDesde AND @FechaHasta
      AND a.Estado <> N'ANULADO'
      AND c.Tipo IN (N'I',N'G')
    GROUP BY c.Tipo, d.Cod_Cuenta, c.Desc_Cta
  )
  SELECT Tipo, Cod_Cuenta AS CodCuenta, Desc_Cta AS Descripcion, Debe, Haber, SaldoResultado
  FROM Base
  ORDER BY Cod_Cuenta;

  SELECT
    SUM(CASE WHEN Tipo=N'I' THEN SaldoResultado ELSE 0 END) AS TotalIngresos,
    SUM(CASE WHEN Tipo=N'G' THEN -SaldoResultado ELSE 0 END) AS TotalGastos,
    SUM(CASE WHEN Tipo=N'I' THEN SaldoResultado ELSE 0 END) - SUM(CASE WHEN Tipo=N'G' THEN -SaldoResultado ELSE 0 END) AS UtilidadNeta
  FROM Base;
END;
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Balance_General', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_Contabilidad_Balance_General AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_Contabilidad_Balance_General
  @FechaCorte DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS (
    SELECT c.Tipo, d.Cod_Cuenta, c.Desc_Cta,
           SUM(d.Debe) AS Debe, SUM(d.Haber) AS Haber,
           SUM(d.Debe-d.Haber) AS SaldoNatural
    FROM dbo.Asientos_Detalle d
    INNER JOIN dbo.Asientos a ON a.Id = d.Id_Asiento
    INNER JOIN dbo.Cuentas c ON c.Cod_Cuenta = d.Cod_Cuenta
    WHERE a.Fecha <= @FechaCorte
      AND a.Estado <> N'ANULADO'
      AND c.Tipo IN (N'A',N'P',N'C')
    GROUP BY c.Tipo, d.Cod_Cuenta, c.Desc_Cta
  )
  SELECT Tipo, Cod_Cuenta AS CodCuenta, Desc_Cta AS Descripcion, Debe, Haber,
         CASE WHEN Tipo=N'A' THEN SaldoNatural ELSE -SaldoNatural END AS Saldo
  FROM Base
  ORDER BY Cod_Cuenta;

  SELECT
    SUM(CASE WHEN Tipo=N'A' THEN SaldoNatural ELSE 0 END) AS TotalActivo,
    SUM(CASE WHEN Tipo=N'P' THEN -SaldoNatural ELSE 0 END) AS TotalPasivo,
    SUM(CASE WHEN Tipo=N'C' THEN -SaldoNatural ELSE 0 END) AS TotalPatrimonio
  FROM Base;
END;
GO
IF OBJECT_ID('dbo.TR_Cuentas_AIUD_SyncAccount', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_Cuentas_AIUD_SyncAccount;
GO

CREATE TRIGGER dbo.TR_Cuentas_AIUD_SyncAccount
ON dbo.Cuentas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  IF @DefaultCompanyId IS NULL RETURN;

  ;WITH Src AS (
    SELECT LTRIM(RTRIM(Cod_Cuenta)) AS CodCuenta, Desc_Cta, Tipo, Nivel, NULLIF(LTRIM(RTRIM(Cod_CtaPadre)),N'') AS CodCtaPadre, Activo, Accepta_Detalle
    FROM inserted
    WHERE Cod_Cuenta IS NOT NULL AND LTRIM(RTRIM(Cod_Cuenta)) <> N''
  )
  MERGE acct.Account AS tgt
  USING Src AS src
    ON tgt.CompanyId = @DefaultCompanyId
   AND tgt.AccountCode = src.CodCuenta
  WHEN MATCHED THEN UPDATE
    SET AccountName = src.Desc_Cta,
        AccountType = src.Tipo,
        AccountLevel = ISNULL(src.Nivel,1),
        AllowsPosting = ISNULL(src.Accepta_Detalle,1),
        IsActive = ISNULL(src.Activo,1),
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @SystemUserId
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (CompanyId, AccountCode, AccountName, AccountType, AccountLevel, ParentAccountId, AllowsPosting, RequiresAuxiliary, IsActive, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId, IsDeleted)
    VALUES (@DefaultCompanyId, src.CodCuenta, src.Desc_Cta, src.Tipo, ISNULL(src.Nivel,1), NULL, ISNULL(src.Accepta_Detalle,1), 0, ISNULL(src.Activo,1), SYSUTCDATETIME(), SYSUTCDATETIME(), @SystemUserId, @SystemUserId, 0);

  UPDATE a
  SET ParentAccountId = p.AccountId,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @SystemUserId
  FROM acct.Account a
  INNER JOIN inserted i ON a.CompanyId = @DefaultCompanyId AND a.AccountCode = LTRIM(RTRIM(i.Cod_Cuenta))
  LEFT JOIN acct.Account p ON p.CompanyId = @DefaultCompanyId AND p.AccountCode = NULLIF(LTRIM(RTRIM(i.Cod_CtaPadre)), N'');

  DELETE a
  FROM acct.Account a
  INNER JOIN deleted d ON a.CompanyId = @DefaultCompanyId AND a.AccountCode = LTRIM(RTRIM(d.Cod_Cuenta))
  LEFT JOIN inserted i ON LTRIM(RTRIM(i.Cod_Cuenta)) = LTRIM(RTRIM(d.Cod_Cuenta))
  WHERE i.Cod_Cuenta IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM acct.JournalEntryLine l WHERE l.AccountId = a.AccountId
    );
END;
GO

IF OBJECT_ID('dbo.TR_FiscalCountryConfig_AIUD_SyncCanonical', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_FiscalCountryConfig_AIUD_SyncCanonical;
GO

CREATE TRIGGER dbo.TR_FiscalCountryConfig_AIUD_SyncCanonical
ON dbo.FiscalCountryConfig
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  MERGE fiscal.CountryConfig AS tgt
  USING (
    SELECT
      i.Id,
      i.EmpresaId,
      i.SucursalId,
      i.CountryCode,
      i.Currency,
      i.TaxRegime,
      i.DefaultTaxCode,
      i.DefaultTaxRate,
      i.FiscalPrinterEnabled,
      i.PrinterBrand,
      i.PrinterPort,
      i.VerifactuEnabled,
      i.VerifactuMode,
      i.CertificatePath,
      i.CertificatePassword,
      i.AEATEndpoint,
      i.SenderNIF,
      i.SenderRIF,
      i.SoftwareId,
      i.SoftwareName,
      i.SoftwareVersion,
      i.PosEnabled,
      i.RestaurantEnabled,
      i.IsActive
    FROM inserted i
  ) src
  ON tgt.CompanyId = src.EmpresaId
   AND tgt.BranchId = src.SucursalId
   AND tgt.CountryCode = src.CountryCode
  WHEN MATCHED THEN
    UPDATE SET
      Currency = src.Currency,
      TaxRegime = src.TaxRegime,
      DefaultTaxCode = src.DefaultTaxCode,
      DefaultTaxRate = src.DefaultTaxRate,
      FiscalPrinterEnabled = src.FiscalPrinterEnabled,
      PrinterBrand = src.PrinterBrand,
      PrinterPort = src.PrinterPort,
      VerifactuEnabled = src.VerifactuEnabled,
      VerifactuMode = src.VerifactuMode,
      CertificatePath = src.CertificatePath,
      CertificatePassword = src.CertificatePassword,
      AEATEndpoint = src.AEATEndpoint,
      SenderNIF = src.SenderNIF,
      SenderRIF = src.SenderRIF,
      SoftwareId = src.SoftwareId,
      SoftwareName = src.SoftwareName,
      SoftwareVersion = src.SoftwareVersion,
      PosEnabled = src.PosEnabled,
      RestaurantEnabled = src.RestaurantEnabled,
      IsActive = src.IsActive,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @SystemUserId
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (
      CompanyId, BranchId, CountryCode, Currency, TaxRegime, DefaultTaxCode, DefaultTaxRate,
      FiscalPrinterEnabled, PrinterBrand, PrinterPort, VerifactuEnabled, VerifactuMode,
      CertificatePath, CertificatePassword, AEATEndpoint, SenderNIF, SenderRIF,
      SoftwareId, SoftwareName, SoftwareVersion, PosEnabled, RestaurantEnabled,
      IsActive, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
    )
    VALUES (
      src.EmpresaId, src.SucursalId, src.CountryCode, src.Currency, src.TaxRegime, src.DefaultTaxCode, src.DefaultTaxRate,
      src.FiscalPrinterEnabled, src.PrinterBrand, src.PrinterPort, src.VerifactuEnabled, src.VerifactuMode,
      src.CertificatePath, src.CertificatePassword, src.AEATEndpoint, src.SenderNIF, src.SenderRIF,
      src.SoftwareId, src.SoftwareName, src.SoftwareVersion, src.PosEnabled, src.RestaurantEnabled,
      src.IsActive, SYSUTCDATETIME(), SYSUTCDATETIME(), @SystemUserId, @SystemUserId
    );

  DELETE tgt
  FROM fiscal.CountryConfig tgt
  INNER JOIN deleted d
    ON tgt.CompanyId = d.EmpresaId
   AND tgt.BranchId = d.SucursalId
   AND tgt.CountryCode = d.CountryCode
  LEFT JOIN inserted i
    ON i.Id = d.Id
  WHERE i.Id IS NULL;
END;
GO

IF OBJECT_ID('dbo.TR_FiscalTaxRates_AIUD_SyncCanonical', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_FiscalTaxRates_AIUD_SyncCanonical;
GO

CREATE TRIGGER dbo.TR_FiscalTaxRates_AIUD_SyncCanonical
ON dbo.FiscalTaxRates
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  MERGE fiscal.TaxRate AS tgt
  USING (
    SELECT CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, IsActive, SortOrder
    FROM inserted
  ) src
  ON tgt.CountryCode = src.CountryCode
 AND tgt.TaxCode = src.Code
  WHEN MATCHED THEN
    UPDATE SET
      TaxName = src.Name,
      Rate = src.Rate,
      SurchargeRate = src.SurchargeRate,
      AppliesToPOS = src.AppliesToPOS,
      AppliesToRestaurant = src.AppliesToRestaurant,
      IsDefault = src.IsDefault,
      IsActive = src.IsActive,
      SortOrder = src.SortOrder,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @SystemUserId
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (CountryCode, TaxCode, TaxName, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, IsActive, SortOrder, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId)
    VALUES (src.CountryCode, src.Code, src.Name, src.Rate, src.SurchargeRate, src.AppliesToPOS, src.AppliesToRestaurant, src.IsDefault, src.IsActive, src.SortOrder, SYSUTCDATETIME(), SYSUTCDATETIME(), @SystemUserId, @SystemUserId);

  DELETE tgt
  FROM fiscal.TaxRate tgt
  INNER JOIN deleted d ON tgt.CountryCode = d.CountryCode AND tgt.TaxCode = d.Code
  LEFT JOIN inserted i ON i.Id = d.Id
  WHERE i.Id IS NULL;
END;
GO

IF OBJECT_ID('dbo.TR_FiscalInvoiceTypes_AIUD_SyncCanonical', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_FiscalInvoiceTypes_AIUD_SyncCanonical;
GO

CREATE TRIGGER dbo.TR_FiscalInvoiceTypes_AIUD_SyncCanonical
ON dbo.FiscalInvoiceTypes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  MERGE fiscal.InvoiceType AS tgt
  USING (
    SELECT CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, IsActive, SortOrder
    FROM inserted
  ) src
  ON tgt.CountryCode = src.CountryCode
 AND tgt.InvoiceTypeCode = src.Code
  WHEN MATCHED THEN
    UPDATE SET
      InvoiceTypeName = src.Name,
      IsRectificative = src.IsRectificative,
      RequiresRecipientId = src.RequiresRecipientId,
      MaxAmount = src.MaxAmount,
      RequiresFiscalPrinter = src.RequiresFiscalPrinter,
      IsActive = src.IsActive,
      SortOrder = src.SortOrder,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @SystemUserId
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (CountryCode, InvoiceTypeCode, InvoiceTypeName, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, IsActive, SortOrder, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId)
    VALUES (src.CountryCode, src.Code, src.Name, src.IsRectificative, src.RequiresRecipientId, src.MaxAmount, src.RequiresFiscalPrinter, src.IsActive, src.SortOrder, SYSUTCDATETIME(), SYSUTCDATETIME(), @SystemUserId, @SystemUserId);

  DELETE tgt
  FROM fiscal.InvoiceType tgt
  INNER JOIN deleted d ON tgt.CountryCode = d.CountryCode AND tgt.InvoiceTypeCode = d.Code
  LEFT JOIN inserted i ON i.Id = d.Id
  WHERE i.Id IS NULL;
END;
GO

IF OBJECT_ID('dbo.TR_FiscalRecords_AI_SyncCanonical', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_FiscalRecords_AI_SyncCanonical;
GO

CREATE TRIGGER dbo.TR_FiscalRecords_AI_SyncCanonical
ON dbo.FiscalRecords
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO fiscal.Record (
    CompanyId, BranchId, CountryCode, InvoiceId, InvoiceType, InvoiceNumber, InvoiceDate,
    RecipientId, TotalAmount, RecordHash, PreviousRecordHash, XmlContent, DigitalSignature,
    QRCodeData, SentToAuthority, SentAt, AuthorityResponse, AuthorityStatus,
    FiscalPrinterSerial, FiscalControlNumber, ZReportNumber, CreatedAt
  )
  SELECT
    i.EmpresaId, i.SucursalId, i.CountryCode, i.InvoiceId, i.InvoiceType, i.InvoiceNumber, i.InvoiceDate,
    i.RecipientId, i.TotalAmount, i.RecordHash, i.PreviousRecordHash, i.XmlContent, i.DigitalSignature,
    i.QRCodeData, i.SentToAuthority, i.SentAt, i.AuthorityResponse, i.AuthorityStatus,
    i.FiscalPrinterSerial, i.FiscalControlNumber, i.ZReportNumber, i.CreatedAt
  FROM inserted i
  WHERE NOT EXISTS (
    SELECT 1 FROM fiscal.Record r WHERE r.RecordHash = i.RecordHash
  );
END;
GO
