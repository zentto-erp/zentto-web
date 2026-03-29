-- ============================================================
-- Zentto SQL Server — Shipping Module Stored Procedures
-- Portal de paquetería para clientes
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- DDL: Tablas shipping (si no existen)
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logistics') EXEC('CREATE SCHEMA logistics');
GO

-- 1. ShippingCustomer
IF OBJECT_ID('logistics.ShippingCustomer', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShippingCustomer(
    ShippingCustomerId    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CompanyId             INT NOT NULL,
    Email                 NVARCHAR(200) NOT NULL,
    PasswordHash          NVARCHAR(200) NOT NULL,
    DisplayName           NVARCHAR(200) NOT NULL,
    Phone                 NVARCHAR(60) NULL,
    FiscalId              NVARCHAR(30) NULL,
    CompanyName           NVARCHAR(200) NULL,
    CountryCode           NVARCHAR(3) NULL,
    PreferredLanguage     NVARCHAR(5) NOT NULL CONSTRAINT DF_ShipCust_Lang DEFAULT('es'),
    IsActive              BIT NOT NULL CONSTRAINT DF_ShipCust_Active DEFAULT(1),
    IsEmailVerified       BIT NOT NULL CONSTRAINT DF_ShipCust_Verified DEFAULT(0),
    LastLoginAt           DATETIME2(0) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_ShipCust_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_ShipCust_UpdatedAt DEFAULT(SYSUTCDATETIME()),
    RowVer                ROWVERSION NOT NULL
  );
  CREATE UNIQUE INDEX UQ_ShipCust_Email ON logistics.ShippingCustomer(CompanyId, Email);
  CREATE INDEX IX_ShipCust_Active ON logistics.ShippingCustomer(CompanyId, IsActive);
END;
GO

-- 2. ShippingAddress
IF OBJECT_ID('logistics.ShippingAddress', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShippingAddress(
    ShippingAddressId     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShippingCustomerId    BIGINT NOT NULL REFERENCES logistics.ShippingCustomer(ShippingCustomerId),
    Label                 NVARCHAR(60) NOT NULL CONSTRAINT DF_ShipAddr_Label DEFAULT('Principal'),
    ContactName           NVARCHAR(150) NOT NULL,
    Phone                 NVARCHAR(60) NULL,
    AddressLine1          NVARCHAR(300) NOT NULL,
    AddressLine2          NVARCHAR(300) NULL,
    City                  NVARCHAR(100) NOT NULL,
    [State]               NVARCHAR(100) NULL,
    PostalCode            NVARCHAR(20) NULL,
    CountryCode           NVARCHAR(3) NOT NULL CONSTRAINT DF_ShipAddr_Country DEFAULT('VE'),
    Latitude              DECIMAL(10,7) NULL,
    Longitude             DECIMAL(10,7) NULL,
    IsDefault             BIT NOT NULL CONSTRAINT DF_ShipAddr_Default DEFAULT(0),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_ShipAddr_CreatedAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE INDEX IX_ShipAddr_Customer ON logistics.ShippingAddress(ShippingCustomerId);
END;
GO

-- 3. CarrierConfig
IF OBJECT_ID('logistics.CarrierConfig', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.CarrierConfig(
    CarrierConfigId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CompanyId             INT NOT NULL,
    CarrierCode           NVARCHAR(30) NOT NULL,
    CarrierName           NVARCHAR(100) NOT NULL,
    CarrierType           NVARCHAR(20) NOT NULL CONSTRAINT DF_CarrierCfg_Type DEFAULT('API'),
    ApiBaseUrl            NVARCHAR(500) NULL,
    ApiKey                NVARCHAR(500) NULL,
    ApiSecret             NVARCHAR(500) NULL,
    AccountNumber         NVARCHAR(100) NULL,
    ExtraConfig           NVARCHAR(MAX) NULL,
    SupportedCountries    NVARCHAR(100) NULL,
    IsActive              BIT NOT NULL CONSTRAINT DF_CarrierCfg_Active DEFAULT(1),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_CarrierCfg_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_CarrierCfg_UpdatedAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE UNIQUE INDEX UQ_CarrierCfg_Code ON logistics.CarrierConfig(CompanyId, CarrierCode);
END;
GO

-- 4. Shipment
IF OBJECT_ID('logistics.Shipment', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.Shipment(
    ShipmentId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CompanyId             INT NOT NULL,
    ShippingCustomerId    BIGINT NULL REFERENCES logistics.ShippingCustomer(ShippingCustomerId),
    ShipmentNumber        NVARCHAR(30) NOT NULL,
    TrackingNumber        NVARCHAR(100) NULL,
    CarrierConfigId       BIGINT NULL REFERENCES logistics.CarrierConfig(CarrierConfigId),
    CarrierCode           NVARCHAR(30) NULL,
    CarrierTrackingUrl    NVARCHAR(500) NULL,
    OriginContactName     NVARCHAR(150) NOT NULL,
    OriginPhone           NVARCHAR(60) NULL,
    OriginAddress         NVARCHAR(500) NOT NULL,
    OriginCity            NVARCHAR(100) NOT NULL,
    OriginState           NVARCHAR(100) NULL,
    OriginPostalCode      NVARCHAR(20) NULL,
    OriginCountryCode     NVARCHAR(3) NOT NULL CONSTRAINT DF_Ship_OriginCC DEFAULT('VE'),
    DestContactName       NVARCHAR(150) NOT NULL,
    DestPhone             NVARCHAR(60) NULL,
    DestAddress           NVARCHAR(500) NOT NULL,
    DestCity              NVARCHAR(100) NOT NULL,
    DestState             NVARCHAR(100) NULL,
    DestPostalCode        NVARCHAR(20) NULL,
    DestCountryCode       NVARCHAR(3) NOT NULL CONSTRAINT DF_Ship_DestCC DEFAULT('VE'),
    ServiceType           NVARCHAR(30) NOT NULL CONSTRAINT DF_Ship_Service DEFAULT('STANDARD'),
    PaymentMethod         NVARCHAR(30) NOT NULL CONSTRAINT DF_Ship_PayMethod DEFAULT('PREPAID'),
    DeclaredValue         DECIMAL(18,2) NULL,
    Currency              NVARCHAR(3) NOT NULL CONSTRAINT DF_Ship_Currency DEFAULT('USD'),
    InsuredAmount         DECIMAL(18,2) NULL,
    ShippingCost          DECIMAL(18,2) NULL,
    TotalWeight           DECIMAL(10,3) NULL,
    Description           NVARCHAR(500) NULL,
    Notes                 NVARCHAR(500) NULL,
    Reference             NVARCHAR(100) NULL,
    [Status]              NVARCHAR(30) NOT NULL CONSTRAINT DF_Ship_Status DEFAULT('DRAFT'),
    EstimatedDelivery     DATE NULL,
    ActualDelivery        DATETIME2(0) NULL,
    DeliveredToName       NVARCHAR(150) NULL,
    DeliverySignature     NVARCHAR(MAX) NULL,
    LabelUrl              NVARCHAR(500) NULL,
    IsInternational       BIT NOT NULL CONSTRAINT DF_Ship_Intl DEFAULT(0),
    CustomsStatus         NVARCHAR(30) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Ship_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Ship_UpdatedAt DEFAULT(SYSUTCDATETIME()),
    RowVer                ROWVERSION NOT NULL
  );
  CREATE UNIQUE INDEX UQ_Ship_Number ON logistics.Shipment(CompanyId, ShipmentNumber);
  CREATE INDEX IX_Ship_Customer ON logistics.Shipment(ShippingCustomerId, [Status]);
  CREATE INDEX IX_Ship_Tracking ON logistics.Shipment(TrackingNumber) WHERE TrackingNumber IS NOT NULL;
  CREATE INDEX IX_Ship_Status ON logistics.Shipment(CompanyId, [Status], CreatedAt DESC);
END;
GO

-- 5. ShipmentPackage
IF OBJECT_ID('logistics.ShipmentPackage', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShipmentPackage(
    ShipmentPackageId     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShipmentId            BIGINT NOT NULL REFERENCES logistics.Shipment(ShipmentId),
    PackageNumber         INT NOT NULL CONSTRAINT DF_ShipPkg_Num DEFAULT(1),
    Weight                DECIMAL(10,3) NOT NULL CONSTRAINT DF_ShipPkg_Weight DEFAULT(0),
    WeightUnit            NVARCHAR(5) NOT NULL CONSTRAINT DF_ShipPkg_WU DEFAULT('kg'),
    Length                DECIMAL(10,2) NULL,
    Width                 DECIMAL(10,2) NULL,
    Height                DECIMAL(10,2) NULL,
    DimensionUnit         NVARCHAR(5) NOT NULL CONSTRAINT DF_ShipPkg_DU DEFAULT('cm'),
    ContentDescription    NVARCHAR(300) NULL,
    DeclaredValue         DECIMAL(18,2) NULL,
    HsCode                NVARCHAR(20) NULL,
    CountryOfOrigin       NVARCHAR(3) NULL
  );
  CREATE INDEX IX_ShipPkg_Shipment ON logistics.ShipmentPackage(ShipmentId);
END;
GO

-- 6. ShipmentEvent
IF OBJECT_ID('logistics.ShipmentEvent', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShipmentEvent(
    ShipmentEventId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShipmentId            BIGINT NOT NULL REFERENCES logistics.Shipment(ShipmentId),
    EventType             NVARCHAR(30) NOT NULL,
    [Status]              NVARCHAR(30) NOT NULL,
    [Description]         NVARCHAR(500) NOT NULL,
    Location              NVARCHAR(200) NULL,
    City                  NVARCHAR(100) NULL,
    CountryCode           NVARCHAR(3) NULL,
    CarrierEventCode      NVARCHAR(50) NULL,
    [Source]              NVARCHAR(20) NOT NULL CONSTRAINT DF_ShipEvt_Src DEFAULT('SYSTEM'),
    EventAt               DATETIME2(0) NOT NULL CONSTRAINT DF_ShipEvt_EventAt DEFAULT(SYSUTCDATETIME()),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_ShipEvt_CreatedAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE INDEX IX_ShipEvt_Shipment ON logistics.ShipmentEvent(ShipmentId, EventAt DESC);
END;
GO

-- 7. ShipmentRate
IF OBJECT_ID('logistics.ShipmentRate', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShipmentRate(
    ShipmentRateId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShipmentId            BIGINT NOT NULL REFERENCES logistics.Shipment(ShipmentId),
    CarrierCode           NVARCHAR(30) NOT NULL,
    CarrierName           NVARCHAR(100) NOT NULL,
    ServiceType           NVARCHAR(30) NOT NULL,
    ServiceName           NVARCHAR(100) NULL,
    Price                 DECIMAL(18,2) NOT NULL,
    Currency              NVARCHAR(3) NOT NULL CONSTRAINT DF_ShipRate_Currency DEFAULT('USD'),
    EstimatedDays         INT NULL,
    EstimatedDelivery     DATE NULL,
    IsSelected            BIT NOT NULL CONSTRAINT DF_ShipRate_Selected DEFAULT(0),
    ExpiresAt             DATETIME2(0) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_ShipRate_CreatedAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE INDEX IX_ShipRate_Shipment ON logistics.ShipmentRate(ShipmentId);
END;
GO

-- 8. CustomsDeclaration
IF OBJECT_ID('logistics.CustomsDeclaration', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.CustomsDeclaration(
    CustomsDeclarationId  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShipmentId            BIGINT NOT NULL REFERENCES logistics.Shipment(ShipmentId),
    DeclarationNumber     NVARCHAR(50) NULL,
    [Status]              NVARCHAR(30) NOT NULL CONSTRAINT DF_Customs_Status DEFAULT('PENDING'),
    ContentType           NVARCHAR(30) NOT NULL CONSTRAINT DF_Customs_ContentType DEFAULT('MERCHANDISE'),
    TotalDeclaredValue    DECIMAL(18,2) NOT NULL,
    Currency              NVARCHAR(3) NOT NULL CONSTRAINT DF_Customs_Currency DEFAULT('USD'),
    ExporterName          NVARCHAR(200) NULL,
    ExporterFiscalId      NVARCHAR(30) NULL,
    ImporterName          NVARCHAR(200) NULL,
    ImporterFiscalId      NVARCHAR(30) NULL,
    OriginCountryCode     NVARCHAR(3) NOT NULL,
    DestCountryCode       NVARCHAR(3) NOT NULL,
    HsCode                NVARCHAR(20) NULL,
    ItemDescription       NVARCHAR(500) NOT NULL,
    Quantity              INT NOT NULL CONSTRAINT DF_Customs_Qty DEFAULT(1),
    WeightKg              DECIMAL(10,3) NULL,
    DocumentsJson         NVARCHAR(MAX) NULL,
    Notes                 NVARCHAR(500) NULL,
    SubmittedAt           DATETIME2(0) NULL,
    ClearedAt             DATETIME2(0) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Customs_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Customs_UpdatedAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE UNIQUE INDEX IX_Customs_Shipment ON logistics.CustomsDeclaration(ShipmentId);
END;
GO

-- 9. ShipmentNotification
IF OBJECT_ID('logistics.ShipmentNotification', 'U') IS NULL
BEGIN
  CREATE TABLE logistics.ShipmentNotification(
    ShipmentNotificationId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShipmentId             BIGINT NOT NULL REFERENCES logistics.Shipment(ShipmentId),
    Channel                NVARCHAR(20) NOT NULL,
    Recipient              NVARCHAR(200) NOT NULL,
    EventType              NVARCHAR(30) NOT NULL,
    [Subject]              NVARCHAR(300) NULL,
    [Status]               NVARCHAR(20) NOT NULL CONSTRAINT DF_ShipNotif_Status DEFAULT('SENT'),
    ExternalMessageId      NVARCHAR(100) NULL,
    SentAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_ShipNotif_SentAt DEFAULT(SYSUTCDATETIME())
  );
  CREATE INDEX IX_ShipNotif_Shipment ON logistics.ShipmentNotification(ShipmentId);
END;
GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- ─── Customer Register ──────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Customer_Register
  @CompanyId      INT,
  @Email          NVARCHAR(200),
  @PasswordHash   NVARCHAR(200),
  @DisplayName    NVARCHAR(200),
  @Phone          NVARCHAR(60) = NULL,
  @FiscalId       NVARCHAR(30) = NULL,
  @CompanyName    NVARCHAR(200) = NULL,
  @CountryCode    NVARCHAR(3) = NULL,
  @Resultado      INT OUTPUT,
  @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM logistics.ShippingCustomer WHERE CompanyId = @CompanyId AND LOWER(Email) = LOWER(@Email))
  BEGIN
    SET @Resultado = 0; SET @Mensaje = N'Email ya registrado'; RETURN;
  END;

  INSERT INTO logistics.ShippingCustomer (CompanyId, Email, PasswordHash, DisplayName, Phone, FiscalId, CompanyName, CountryCode)
  VALUES (@CompanyId, LOWER(LTRIM(RTRIM(@Email))), @PasswordHash, @DisplayName, @Phone, @FiscalId, @CompanyName, @CountryCode);

  SET @Resultado = 1; SET @Mensaje = N'Registro exitoso';
END;
GO

-- ─── Customer Login (get by email) ─────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Customer_Login
  @CompanyId INT = NULL,
  @Email     NVARCHAR(200)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    ShippingCustomerId, CompanyId, Email, PasswordHash, DisplayName,
    Phone, FiscalId, CompanyName, CountryCode, PreferredLanguage,
    IsActive, IsEmailVerified, LastLoginAt
  FROM logistics.ShippingCustomer
  WHERE LOWER(Email) = LOWER(@Email)
    AND (@CompanyId IS NULL OR CompanyId = @CompanyId);
END;
GO

-- ─── Customer Profile ───────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Customer_Profile
  @ShippingCustomerId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    ShippingCustomerId, CompanyId, Email, DisplayName, Phone,
    FiscalId, CompanyName, CountryCode, PreferredLanguage,
    IsActive, IsEmailVerified, LastLoginAt, CreatedAt
  FROM logistics.ShippingCustomer
  WHERE ShippingCustomerId = @ShippingCustomerId;
END;
GO

-- ─── Address List ───────────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Address_List
  @ShippingCustomerId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT * FROM logistics.ShippingAddress
  WHERE ShippingCustomerId = @ShippingCustomerId
  ORDER BY IsDefault DESC, CreatedAt DESC;
END;
GO

-- ─── Address Upsert ─────────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Address_Upsert
  @ShippingAddressId   BIGINT = NULL,
  @ShippingCustomerId  BIGINT,
  @Label               NVARCHAR(60),
  @ContactName         NVARCHAR(150),
  @Phone               NVARCHAR(60) = NULL,
  @AddressLine1        NVARCHAR(300),
  @AddressLine2        NVARCHAR(300) = NULL,
  @City                NVARCHAR(100),
  @State               NVARCHAR(100) = NULL,
  @PostalCode          NVARCHAR(20) = NULL,
  @CountryCode         NVARCHAR(3) = 'VE',
  @IsDefault           BIT = 0,
  @Resultado           INT OUTPUT,
  @Mensaje             NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @IsDefault = 1
    UPDATE logistics.ShippingAddress SET IsDefault = 0 WHERE ShippingCustomerId = @ShippingCustomerId;

  IF @ShippingAddressId IS NULL OR @ShippingAddressId = 0
  BEGIN
    INSERT INTO logistics.ShippingAddress (ShippingCustomerId, Label, ContactName, Phone, AddressLine1, AddressLine2, City, [State], PostalCode, CountryCode, IsDefault)
    VALUES (@ShippingCustomerId, @Label, @ContactName, @Phone, @AddressLine1, @AddressLine2, @City, @State, @PostalCode, @CountryCode, @IsDefault);
    SET @Resultado = 1; SET @Mensaje = N'Dirección creada';
  END
  ELSE
  BEGIN
    UPDATE logistics.ShippingAddress SET
      Label = @Label, ContactName = @ContactName, Phone = @Phone,
      AddressLine1 = @AddressLine1, AddressLine2 = @AddressLine2,
      City = @City, [State] = @State, PostalCode = @PostalCode,
      CountryCode = @CountryCode, IsDefault = @IsDefault
    WHERE ShippingAddressId = @ShippingAddressId AND ShippingCustomerId = @ShippingCustomerId;
    SET @Resultado = 1; SET @Mensaje = N'Dirección actualizada';
  END;
END;
GO

-- ─── Carrier Config List ────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_CarrierConfig_List
  @CompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT CarrierConfigId, CompanyId, CarrierCode, CarrierName, CarrierType,
         SupportedCountries, IsActive
  FROM logistics.CarrierConfig
  WHERE CompanyId = @CompanyId AND IsActive = 1
  ORDER BY CarrierName;
END;
GO

-- ─── Shipment Create ────────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Shipment_Create
  @CompanyId            INT,
  @ShippingCustomerId   BIGINT,
  @CarrierCode          NVARCHAR(30) = NULL,
  @ServiceType          NVARCHAR(30) = 'STANDARD',
  @OriginContactName    NVARCHAR(150),
  @OriginPhone          NVARCHAR(60) = NULL,
  @OriginAddress        NVARCHAR(500),
  @OriginCity           NVARCHAR(100),
  @OriginState          NVARCHAR(100) = NULL,
  @OriginPostalCode     NVARCHAR(20) = NULL,
  @OriginCountryCode    NVARCHAR(3) = 'VE',
  @DestContactName      NVARCHAR(150),
  @DestPhone            NVARCHAR(60) = NULL,
  @DestAddress          NVARCHAR(500),
  @DestCity             NVARCHAR(100),
  @DestState            NVARCHAR(100) = NULL,
  @DestPostalCode       NVARCHAR(20) = NULL,
  @DestCountryCode      NVARCHAR(3) = 'VE',
  @DeclaredValue        DECIMAL(18,2) = NULL,
  @Currency             NVARCHAR(3) = 'USD',
  @Description          NVARCHAR(500) = NULL,
  @Notes                NVARCHAR(500) = NULL,
  @Reference            NVARCHAR(100) = NULL,
  @PackagesJson         NVARCHAR(MAX) = NULL,
  @Resultado            INT OUTPUT,
  @Mensaje              NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @ShipmentNumber NVARCHAR(30);
  DECLARE @Seq INT;
  SELECT @Seq = ISNULL(MAX(ShipmentId), 0) + 1 FROM logistics.Shipment;
  SET @ShipmentNumber = 'ZS-' + RIGHT('000000' + CAST(@Seq AS NVARCHAR), 6);

  DECLARE @IsIntl BIT = CASE WHEN @OriginCountryCode <> @DestCountryCode THEN 1 ELSE 0 END;

  BEGIN TRAN;

  INSERT INTO logistics.Shipment (
    CompanyId, ShippingCustomerId, ShipmentNumber, CarrierCode,
    OriginContactName, OriginPhone, OriginAddress, OriginCity, OriginState, OriginPostalCode, OriginCountryCode,
    DestContactName, DestPhone, DestAddress, DestCity, DestState, DestPostalCode, DestCountryCode,
    ServiceType, DeclaredValue, Currency, Description, Notes, Reference, IsInternational
  ) VALUES (
    @CompanyId, @ShippingCustomerId, @ShipmentNumber, @CarrierCode,
    @OriginContactName, @OriginPhone, @OriginAddress, @OriginCity, @OriginState, @OriginPostalCode, @OriginCountryCode,
    @DestContactName, @DestPhone, @DestAddress, @DestCity, @DestState, @DestPostalCode, @DestCountryCode,
    @ServiceType, @DeclaredValue, @Currency, @Description, @Notes, @Reference, @IsIntl
  );

  DECLARE @NewId BIGINT = SCOPE_IDENTITY();

  -- Insert packages from JSON
  IF @PackagesJson IS NOT NULL AND LEN(@PackagesJson) > 2
  BEGIN
    INSERT INTO logistics.ShipmentPackage (ShipmentId, PackageNumber, Weight, WeightUnit, Length, Width, Height, DimensionUnit, ContentDescription, DeclaredValue, HsCode, CountryOfOrigin)
    SELECT @NewId,
      JSON_VALUE(j.value, '$.packageNumber'),
      ISNULL(JSON_VALUE(j.value, '$.weight'), 0),
      ISNULL(JSON_VALUE(j.value, '$.weightUnit'), 'kg'),
      JSON_VALUE(j.value, '$.length'),
      JSON_VALUE(j.value, '$.width'),
      JSON_VALUE(j.value, '$.height'),
      ISNULL(JSON_VALUE(j.value, '$.dimensionUnit'), 'cm'),
      JSON_VALUE(j.value, '$.contentDescription'),
      JSON_VALUE(j.value, '$.declaredValue'),
      JSON_VALUE(j.value, '$.hsCode'),
      JSON_VALUE(j.value, '$.countryOfOrigin')
    FROM OPENJSON(@PackagesJson) j;
  END;

  -- Insert creation event
  INSERT INTO logistics.ShipmentEvent (ShipmentId, EventType, [Status], [Description], [Source])
  VALUES (@NewId, 'CREATED', 'DRAFT', N'Envío creado', 'CUSTOMER');

  -- Calculate total weight
  UPDATE logistics.Shipment
  SET TotalWeight = (SELECT ISNULL(SUM(Weight), 0) FROM logistics.ShipmentPackage WHERE ShipmentId = @NewId)
  WHERE ShipmentId = @NewId;

  COMMIT;

  SET @Resultado = @NewId;
  SET @Mensaje = @ShipmentNumber;
END;
GO

-- ─── Shipment List (by customer) ────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Shipment_List
  @ShippingCustomerId BIGINT,
  @Status             NVARCHAR(30) = NULL,
  @Search             NVARCHAR(100) = NULL,
  @Page               INT = 1,
  @Limit              INT = 20,
  @TotalCount         INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page < 1 SET @Page = 1;
  IF @Limit < 1 OR @Limit > 100 SET @Limit = 20;

  SELECT @TotalCount = COUNT(*)
  FROM logistics.Shipment
  WHERE ShippingCustomerId = @ShippingCustomerId
    AND (@Status IS NULL OR [Status] = @Status)
    AND (@Search IS NULL OR ShipmentNumber LIKE '%' + @Search + '%' OR TrackingNumber LIKE '%' + @Search + '%' OR DestContactName LIKE '%' + @Search + '%');

  SELECT
    s.ShipmentId, s.ShipmentNumber, s.TrackingNumber, s.CarrierCode,
    s.OriginCity, s.OriginCountryCode, s.DestCity, s.DestCountryCode,
    s.DestContactName, s.ServiceType, s.[Status], s.ShippingCost, s.Currency,
    s.TotalWeight, s.EstimatedDelivery, s.ActualDelivery, s.IsInternational,
    s.CustomsStatus, s.LabelUrl, s.CreatedAt,
    (SELECT TOP 1 e.[Description] FROM logistics.ShipmentEvent e WHERE e.ShipmentId = s.ShipmentId ORDER BY e.EventAt DESC) AS LastEvent
  FROM logistics.Shipment s
  WHERE s.ShippingCustomerId = @ShippingCustomerId
    AND (@Status IS NULL OR s.[Status] = @Status)
    AND (@Search IS NULL OR s.ShipmentNumber LIKE '%' + @Search + '%' OR s.TrackingNumber LIKE '%' + @Search + '%' OR s.DestContactName LIKE '%' + @Search + '%')
  ORDER BY s.CreatedAt DESC
  OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ─── Shipment Get (detail) ──────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Shipment_Get
  @ShipmentId         BIGINT,
  @ShippingCustomerId BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- Main shipment
  SELECT * FROM logistics.Shipment
  WHERE ShipmentId = @ShipmentId
    AND (@ShippingCustomerId IS NULL OR ShippingCustomerId = @ShippingCustomerId);

  -- Packages
  SELECT * FROM logistics.ShipmentPackage WHERE ShipmentId = @ShipmentId ORDER BY PackageNumber;

  -- Events (timeline)
  SELECT * FROM logistics.ShipmentEvent WHERE ShipmentId = @ShipmentId ORDER BY EventAt DESC;

  -- Rates
  SELECT * FROM logistics.ShipmentRate WHERE ShipmentId = @ShipmentId ORDER BY Price;

  -- Customs
  SELECT * FROM logistics.CustomsDeclaration WHERE ShipmentId = @ShipmentId;

  -- Notifications
  SELECT * FROM logistics.ShipmentNotification WHERE ShipmentId = @ShipmentId ORDER BY SentAt DESC;
END;
GO

-- ─── Shipment Update Status ─────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Shipment_UpdateStatus
  @ShipmentId      BIGINT,
  @NewStatus       NVARCHAR(30),
  @EventDescription NVARCHAR(500),
  @Location        NVARCHAR(200) = NULL,
  @City            NVARCHAR(100) = NULL,
  @CountryCode     NVARCHAR(3) = NULL,
  @CarrierEventCode NVARCHAR(50) = NULL,
  @Source          NVARCHAR(20) = 'SYSTEM',
  @Resultado       INT OUTPUT,
  @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF NOT EXISTS (SELECT 1 FROM logistics.Shipment WHERE ShipmentId = @ShipmentId)
  BEGIN SET @Resultado = 0; SET @Mensaje = N'Envío no encontrado'; RETURN; END;

  BEGIN TRAN;

  UPDATE logistics.Shipment
  SET [Status] = @NewStatus,
      UpdatedAt = SYSUTCDATETIME(),
      ActualDelivery = CASE WHEN @NewStatus = 'DELIVERED' THEN SYSUTCDATETIME() ELSE ActualDelivery END,
      CustomsStatus = CASE WHEN @NewStatus IN ('IN_CUSTOMS','CUSTOMS_HELD','CUSTOMS_CLEARED') THEN @NewStatus ELSE CustomsStatus END
  WHERE ShipmentId = @ShipmentId;

  INSERT INTO logistics.ShipmentEvent (ShipmentId, EventType, [Status], [Description], Location, City, CountryCode, CarrierEventCode, [Source])
  VALUES (@ShipmentId, @NewStatus, @NewStatus, @EventDescription, @Location, @City, @CountryCode, @CarrierEventCode, @Source);

  COMMIT;

  SET @Resultado = 1; SET @Mensaje = N'Estado actualizado';
END;
GO

-- ─── Track by tracking number (public) ──────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Track
  @TrackingNumber NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    s.ShipmentId, s.ShipmentNumber, s.TrackingNumber, s.CarrierCode,
    s.OriginCity, s.OriginCountryCode, s.DestCity, s.DestCountryCode,
    s.[Status], s.ServiceType, s.EstimatedDelivery, s.ActualDelivery,
    s.DeliveredToName, s.CreatedAt
  FROM logistics.Shipment s
  WHERE s.TrackingNumber = @TrackingNumber OR s.ShipmentNumber = @TrackingNumber;

  SELECT
    e.ShipmentEventId, e.EventType, e.[Status], e.[Description],
    e.Location, e.City, e.CountryCode, e.EventAt
  FROM logistics.ShipmentEvent e
  INNER JOIN logistics.Shipment s ON s.ShipmentId = e.ShipmentId
  WHERE s.TrackingNumber = @TrackingNumber OR s.ShipmentNumber = @TrackingNumber
  ORDER BY e.EventAt DESC;
END;
GO

-- ─── Customs Upsert ─────────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Customs_Upsert
  @ShipmentId          BIGINT,
  @ContentType         NVARCHAR(30) = 'MERCHANDISE',
  @TotalDeclaredValue  DECIMAL(18,2),
  @Currency            NVARCHAR(3) = 'USD',
  @ExporterName        NVARCHAR(200) = NULL,
  @ExporterFiscalId    NVARCHAR(30) = NULL,
  @ImporterName        NVARCHAR(200) = NULL,
  @ImporterFiscalId    NVARCHAR(30) = NULL,
  @OriginCountryCode   NVARCHAR(3),
  @DestCountryCode     NVARCHAR(3),
  @HsCode              NVARCHAR(20) = NULL,
  @ItemDescription     NVARCHAR(500),
  @Quantity            INT = 1,
  @WeightKg            DECIMAL(10,3) = NULL,
  @Notes               NVARCHAR(500) = NULL,
  @Resultado           INT OUTPUT,
  @Mensaje             NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM logistics.CustomsDeclaration WHERE ShipmentId = @ShipmentId)
  BEGIN
    UPDATE logistics.CustomsDeclaration SET
      ContentType = @ContentType, TotalDeclaredValue = @TotalDeclaredValue, Currency = @Currency,
      ExporterName = @ExporterName, ExporterFiscalId = @ExporterFiscalId,
      ImporterName = @ImporterName, ImporterFiscalId = @ImporterFiscalId,
      OriginCountryCode = @OriginCountryCode, DestCountryCode = @DestCountryCode,
      HsCode = @HsCode, ItemDescription = @ItemDescription, Quantity = @Quantity,
      WeightKg = @WeightKg, Notes = @Notes, UpdatedAt = SYSUTCDATETIME()
    WHERE ShipmentId = @ShipmentId;
    SET @Resultado = 1; SET @Mensaje = N'Declaración actualizada';
  END
  ELSE
  BEGIN
    INSERT INTO logistics.CustomsDeclaration (
      ShipmentId, ContentType, TotalDeclaredValue, Currency,
      ExporterName, ExporterFiscalId, ImporterName, ImporterFiscalId,
      OriginCountryCode, DestCountryCode, HsCode, ItemDescription, Quantity, WeightKg, Notes
    ) VALUES (
      @ShipmentId, @ContentType, @TotalDeclaredValue, @Currency,
      @ExporterName, @ExporterFiscalId, @ImporterName, @ImporterFiscalId,
      @OriginCountryCode, @DestCountryCode, @HsCode, @ItemDescription, @Quantity, @WeightKg, @Notes
    );
    SET @Resultado = 1; SET @Mensaje = N'Declaración creada';
  END;
END;
GO

-- ─── Shipping Dashboard ─────────────────────────────────────
CREATE OR ALTER PROCEDURE logistics.usp_Shipping_Dashboard
  @ShippingCustomerId BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    COUNT(*) AS TotalShipments,
    SUM(CASE WHEN [Status] = 'DRAFT' THEN 1 ELSE 0 END) AS DraftCount,
    SUM(CASE WHEN [Status] IN ('PICKED_UP','IN_TRANSIT','OUT_FOR_DELIVERY') THEN 1 ELSE 0 END) AS InTransitCount,
    SUM(CASE WHEN [Status] = 'DELIVERED' THEN 1 ELSE 0 END) AS DeliveredCount,
    SUM(CASE WHEN [Status] IN ('IN_CUSTOMS','CUSTOMS_HELD') THEN 1 ELSE 0 END) AS InCustomsCount,
    SUM(CASE WHEN [Status] = 'EXCEPTION' THEN 1 ELSE 0 END) AS ExceptionCount,
    SUM(ISNULL(ShippingCost, 0)) AS TotalSpent,
    MAX(Currency) AS Currency
  FROM logistics.Shipment
  WHERE ShippingCustomerId = @ShippingCustomerId;
END;
GO
