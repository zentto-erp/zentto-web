/*
 * ============================================================================
 *  Archivo : usp_logistics.sql
 *  Esquema : logistics (logistica)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados de logistica: transportistas, conductores,
 *    recepciones de mercancia, devoluciones y notas de entrega.
 *
 *  Compatibilidad: SQL Server 2012+
 *  Patron: IF EXISTS DROP + CREATE PROCEDURE
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
--  Schema: logistics
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logistics')
    EXEC('CREATE SCHEMA logistics');
GO

-- ============================================================================
--  Tabla: logistics.Carrier
-- ============================================================================
IF OBJECT_ID('logistics.Carrier', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.Carrier (
        CarrierId       INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL,
        CarrierCode     NVARCHAR(20) NOT NULL,
        CarrierName     NVARCHAR(100) NOT NULL,
        FiscalId        NVARCHAR(30) NULL,
        ContactName     NVARCHAR(100) NULL,
        Phone           NVARCHAR(50) NULL,
        Email           NVARCHAR(100) NULL,
        AddressLine     NVARCHAR(250) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy       INT NULL,
        UpdatedAt       DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Carrier_Code
        ON logistics.Carrier(CompanyId, CarrierCode);
END
GO

-- ============================================================================
--  Tabla: logistics.Driver
-- ============================================================================
IF OBJECT_ID('logistics.Driver', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.Driver (
        DriverId        INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL,
        CarrierId       INT NULL REFERENCES logistics.Carrier(CarrierId),
        DriverCode      NVARCHAR(20) NOT NULL,
        DriverName      NVARCHAR(100) NOT NULL,
        FiscalId        NVARCHAR(30) NULL,
        LicenseNumber   NVARCHAR(30) NULL,
        LicenseExpiry   DATE NULL,
        Phone           NVARCHAR(50) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy       INT NULL,
        UpdatedAt       DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Driver_Code
        ON logistics.Driver(CompanyId, DriverCode);
END
GO

-- ============================================================================
--  Tabla: logistics.GoodsReceipt
-- ============================================================================
IF OBJECT_ID('logistics.GoodsReceipt', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.GoodsReceipt (
        GoodsReceiptId          INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId               INT NOT NULL,
        BranchId                INT NOT NULL,
        ReceiptNumber           NVARCHAR(20) NOT NULL,
        PurchaseDocumentNumber  NVARCHAR(30) NULL,
        SupplierId              INT NULL,
        WarehouseId             INT NOT NULL,
        ReceiptDate             DATETIME2(0) NOT NULL,
        CarrierId               INT NULL REFERENCES logistics.Carrier(CarrierId),
        DriverName              NVARCHAR(100) NULL,
        VehiclePlate            NVARCHAR(20) NULL,
        Notes                   NVARCHAR(500) NULL,
        Status                  NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',  -- DRAFT, COMPLETE, CANCELLED
        CreatedBy               INT NULL,
        CreatedAt               DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        ApprovedBy              INT NULL,
        ApprovedAt              DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Receipt_Number
        ON logistics.GoodsReceipt(CompanyId, ReceiptNumber);

    CREATE INDEX IX_Receipt_Date
        ON logistics.GoodsReceipt(CompanyId, BranchId, ReceiptDate DESC);
END
GO

-- ============================================================================
--  Tabla: logistics.GoodsReceiptLine
-- ============================================================================
IF OBJECT_ID('logistics.GoodsReceiptLine', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.GoodsReceiptLine (
        LineId          INT IDENTITY(1,1) PRIMARY KEY,
        GoodsReceiptId  INT NOT NULL REFERENCES logistics.GoodsReceipt(GoodsReceiptId),
        ProductId       INT NOT NULL,
        ExpectedQty     DECIMAL(18,4) NOT NULL DEFAULT 0,
        ReceivedQty     DECIMAL(18,4) NOT NULL DEFAULT 0,
        UnitCost        DECIMAL(18,4) NULL,
        LotNumber       NVARCHAR(50) NULL,
        BinId           INT NULL,
        Notes           NVARCHAR(250) NULL
    );
END
GO

-- ============================================================================
--  Tabla: logistics.GoodsReceiptSerial
-- ============================================================================
IF OBJECT_ID('logistics.GoodsReceiptSerial', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.GoodsReceiptSerial (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        LineId          INT NOT NULL REFERENCES logistics.GoodsReceiptLine(LineId),
        SerialNumber    NVARCHAR(100) NOT NULL
    );
END
GO

-- ============================================================================
--  Tabla: logistics.GoodsReturn
-- ============================================================================
IF OBJECT_ID('logistics.GoodsReturn', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.GoodsReturn (
        GoodsReturnId       INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        BranchId            INT NOT NULL,
        ReturnNumber        NVARCHAR(20) NOT NULL,
        GoodsReceiptId      INT NULL REFERENCES logistics.GoodsReceipt(GoodsReceiptId),
        SupplierId          INT NULL,
        WarehouseId         INT NOT NULL,
        ReturnDate          DATETIME2(0) NOT NULL,
        Reason              NVARCHAR(250) NULL,
        Status              NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',  -- DRAFT, COMPLETE, CANCELLED
        CreatedBy           INT NULL,
        CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        ApprovedBy          INT NULL,
        ApprovedAt          DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Return_Number
        ON logistics.GoodsReturn(CompanyId, ReturnNumber);
END
GO

-- ============================================================================
--  Tabla: logistics.GoodsReturnLine
-- ============================================================================
IF OBJECT_ID('logistics.GoodsReturnLine', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.GoodsReturnLine (
        LineId          INT IDENTITY(1,1) PRIMARY KEY,
        GoodsReturnId   INT NOT NULL REFERENCES logistics.GoodsReturn(GoodsReturnId),
        ProductId       INT NOT NULL,
        Quantity        DECIMAL(18,4) NOT NULL DEFAULT 0,
        UnitCost        DECIMAL(18,4) NULL,
        LotNumber       NVARCHAR(50) NULL,
        SerialNumber    NVARCHAR(100) NULL,
        Notes           NVARCHAR(250) NULL
    );
END
GO

-- ============================================================================
--  Tabla: logistics.DeliveryNote
-- ============================================================================
IF OBJECT_ID('logistics.DeliveryNote', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.DeliveryNote (
        DeliveryNoteId          INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId               INT NOT NULL,
        BranchId                INT NOT NULL,
        DeliveryNumber          NVARCHAR(20) NOT NULL,
        SalesDocumentNumber     NVARCHAR(30) NULL,
        CustomerId              INT NULL,
        WarehouseId             INT NOT NULL,
        DeliveryDate            DATETIME2(0) NOT NULL,
        CarrierId               INT NULL REFERENCES logistics.Carrier(CarrierId),
        DriverId                INT NULL REFERENCES logistics.Driver(DriverId),
        VehiclePlate            NVARCHAR(20) NULL,
        ShipToAddress           NVARCHAR(500) NULL,
        ShipToContact           NVARCHAR(100) NULL,
        EstimatedDelivery       DATETIME2(0) NULL,
        Status                  NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',  -- DRAFT, DISPATCHED, DELIVERED, CANCELLED
        DeliveredToName         NVARCHAR(100) NULL,
        DeliverySignature       NVARCHAR(MAX) NULL,
        CreatedBy               INT NULL,
        CreatedAt               DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        DispatchedBy            INT NULL,
        DispatchedAt            DATETIME2(0) NULL,
        DeliveredBy             INT NULL,
        DeliveredAt             DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Delivery_Number
        ON logistics.DeliveryNote(CompanyId, DeliveryNumber);

    CREATE INDEX IX_Delivery_Date
        ON logistics.DeliveryNote(CompanyId, BranchId, DeliveryDate DESC);
END
GO

-- ============================================================================
--  Tabla: logistics.DeliveryNoteLine
-- ============================================================================
IF OBJECT_ID('logistics.DeliveryNoteLine', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.DeliveryNoteLine (
        LineId          INT IDENTITY(1,1) PRIMARY KEY,
        DeliveryNoteId  INT NOT NULL REFERENCES logistics.DeliveryNote(DeliveryNoteId),
        ProductId       INT NOT NULL,
        Quantity        DECIMAL(18,4) NOT NULL DEFAULT 0,
        UnitCost        DECIMAL(18,4) NULL,
        LotNumber       NVARCHAR(50) NULL,
        BinId           INT NULL,
        Notes           NVARCHAR(250) NULL
    );
END
GO

-- ============================================================================
--  Tabla: logistics.DeliveryNoteSerial
-- ============================================================================
IF OBJECT_ID('logistics.DeliveryNoteSerial', 'U') IS NULL
BEGIN
    CREATE TABLE logistics.DeliveryNoteSerial (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        LineId          INT NOT NULL REFERENCES logistics.DeliveryNoteLine(LineId),
        SerialNumber    NVARCHAR(100) NOT NULL
    );
END
GO


-- ============================================================================
--  SP: usp_Logistics_Carrier_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Carrier_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_Carrier_List;
GO
CREATE PROCEDURE dbo.usp_Logistics_Carrier_List
    @CompanyId   INT,
    @Search      NVARCHAR(100) = NULL,
    @Page        INT = 1,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM logistics.Carrier
    WHERE CompanyId = @CompanyId
      AND (@Search IS NULL
           OR CarrierCode LIKE '%' + @Search + '%'
           OR CarrierName LIKE '%' + @Search + '%'
           OR FiscalId LIKE '%' + @Search + '%');

    SELECT CarrierId, CompanyId, CarrierCode, CarrierName, FiscalId,
           ContactName, Phone, Email, AddressLine, IsActive, CreatedAt, UpdatedAt
    FROM logistics.Carrier
    WHERE CompanyId = @CompanyId
      AND (@Search IS NULL
           OR CarrierCode LIKE '%' + @Search + '%'
           OR CarrierName LIKE '%' + @Search + '%'
           OR FiscalId LIKE '%' + @Search + '%')
    ORDER BY CarrierName
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Logistics_Carrier_Upsert
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Carrier_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_Carrier_Upsert;
GO
CREATE PROCEDURE dbo.usp_Logistics_Carrier_Upsert
    @CompanyId      INT,
    @CarrierId      INT = NULL,
    @CarrierCode    NVARCHAR(20),
    @CarrierName    NVARCHAR(100),
    @FiscalId       NVARCHAR(30) = NULL,
    @ContactName    NVARCHAR(100) = NULL,
    @Phone          NVARCHAR(50) = NULL,
    @Email          NVARCHAR(100) = NULL,
    @AddressLine    NVARCHAR(250) = NULL,
    @IsActive       BIT = 1,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM logistics.Carrier
        WHERE CompanyId = @CompanyId AND CarrierCode = @CarrierCode
          AND (@CarrierId IS NULL OR CarrierId <> @CarrierId)
    )
    BEGIN
        SELECT 0 AS ok, N'El codigo de transportista ya existe' AS mensaje;
        RETURN;
    END

    IF @CarrierId IS NULL
    BEGIN
        INSERT INTO logistics.Carrier (CompanyId, CarrierCode, CarrierName, FiscalId, ContactName, Phone, Email, AddressLine, IsActive, CreatedBy, CreatedAt)
        VALUES (@CompanyId, @CarrierCode, @CarrierName, @FiscalId, @ContactName, @Phone, @Email, @AddressLine, @IsActive, @UserId, SYSUTCDATETIME());

        SELECT 1 AS ok, N'Transportista creado' AS mensaje;
    END
    ELSE
    BEGIN
        UPDATE logistics.Carrier
        SET CarrierCode = @CarrierCode,
            CarrierName = @CarrierName,
            FiscalId    = @FiscalId,
            ContactName = @ContactName,
            Phone       = @Phone,
            Email       = @Email,
            AddressLine = @AddressLine,
            IsActive    = @IsActive,
            UpdatedBy   = @UserId,
            UpdatedAt   = SYSUTCDATETIME()
        WHERE CarrierId = @CarrierId AND CompanyId = @CompanyId;

        SELECT 1 AS ok, N'Transportista actualizado' AS mensaje;
    END
END
GO

-- ============================================================================
--  SP: usp_Logistics_Driver_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Driver_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_Driver_List;
GO
CREATE PROCEDURE dbo.usp_Logistics_Driver_List
    @CompanyId   INT,
    @CarrierId   INT = NULL,
    @Search      NVARCHAR(100) = NULL,
    @Page        INT = 1,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM logistics.Driver
    WHERE CompanyId = @CompanyId
      AND (@CarrierId IS NULL OR CarrierId = @CarrierId)
      AND (@Search IS NULL
           OR DriverCode LIKE '%' + @Search + '%'
           OR DriverName LIKE '%' + @Search + '%');

    SELECT d.DriverId, d.CompanyId, d.CarrierId, d.DriverCode, d.DriverName,
           d.FiscalId, d.LicenseNumber, d.LicenseExpiry, d.Phone, d.IsActive,
           d.CreatedAt, d.UpdatedAt,
           c.CarrierName
    FROM logistics.Driver d
    LEFT JOIN logistics.Carrier c ON d.CarrierId = c.CarrierId
    WHERE d.CompanyId = @CompanyId
      AND (@CarrierId IS NULL OR d.CarrierId = @CarrierId)
      AND (@Search IS NULL
           OR d.DriverCode LIKE '%' + @Search + '%'
           OR d.DriverName LIKE '%' + @Search + '%')
    ORDER BY d.DriverName
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Logistics_Driver_Upsert
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Driver_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_Driver_Upsert;
GO
CREATE PROCEDURE dbo.usp_Logistics_Driver_Upsert
    @CompanyId      INT,
    @DriverId       INT = NULL,
    @CarrierId      INT = NULL,
    @DriverCode     NVARCHAR(20),
    @DriverName     NVARCHAR(100),
    @FiscalId       NVARCHAR(30) = NULL,
    @LicenseNumber  NVARCHAR(30) = NULL,
    @LicenseExpiry  DATE = NULL,
    @Phone          NVARCHAR(50) = NULL,
    @IsActive       BIT = 1,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM logistics.Driver
        WHERE CompanyId = @CompanyId AND DriverCode = @DriverCode
          AND (@DriverId IS NULL OR DriverId <> @DriverId)
    )
    BEGIN
        SELECT 0 AS ok, N'El codigo de conductor ya existe' AS mensaje;
        RETURN;
    END

    IF @DriverId IS NULL
    BEGIN
        INSERT INTO logistics.Driver (CompanyId, CarrierId, DriverCode, DriverName, FiscalId, LicenseNumber, LicenseExpiry, Phone, IsActive, CreatedBy, CreatedAt)
        VALUES (@CompanyId, @CarrierId, @DriverCode, @DriverName, @FiscalId, @LicenseNumber, @LicenseExpiry, @Phone, @IsActive, @UserId, SYSUTCDATETIME());

        SELECT 1 AS ok, N'Conductor creado' AS mensaje;
    END
    ELSE
    BEGIN
        UPDATE logistics.Driver
        SET CarrierId      = @CarrierId,
            DriverCode     = @DriverCode,
            DriverName     = @DriverName,
            FiscalId       = @FiscalId,
            LicenseNumber  = @LicenseNumber,
            LicenseExpiry  = @LicenseExpiry,
            Phone          = @Phone,
            IsActive       = @IsActive,
            UpdatedBy      = @UserId,
            UpdatedAt      = SYSUTCDATETIME()
        WHERE DriverId = @DriverId AND CompanyId = @CompanyId;

        SELECT 1 AS ok, N'Conductor actualizado' AS mensaje;
    END
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReceipt_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReceipt_List;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReceipt_List
    @CompanyId    INT,
    @BranchId     INT,
    @SupplierId   INT = NULL,
    @Status       NVARCHAR(20) = NULL,
    @FechaDesde   DATE = NULL,
    @FechaHasta   DATE = NULL,
    @Page         INT = 1,
    @Limit        INT = 50,
    @TotalCount   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM logistics.GoodsReceipt
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND (@SupplierId IS NULL OR SupplierId = @SupplierId)
      AND (@Status IS NULL OR Status = @Status)
      AND (@FechaDesde IS NULL OR CAST(ReceiptDate AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(ReceiptDate AS DATE) <= @FechaHasta);

    SELECT gr.GoodsReceiptId, gr.CompanyId, gr.BranchId, gr.ReceiptNumber,
           gr.PurchaseDocumentNumber, gr.SupplierId, gr.WarehouseId,
           gr.ReceiptDate, gr.CarrierId, gr.DriverName, gr.VehiclePlate,
           gr.Notes, gr.Status, gr.CreatedAt, gr.ApprovedAt,
           c.CarrierName
    FROM logistics.GoodsReceipt gr
    LEFT JOIN logistics.Carrier c ON gr.CarrierId = c.CarrierId
    WHERE gr.CompanyId = @CompanyId AND gr.BranchId = @BranchId
      AND (@SupplierId IS NULL OR gr.SupplierId = @SupplierId)
      AND (@Status IS NULL OR gr.Status = @Status)
      AND (@FechaDesde IS NULL OR CAST(gr.ReceiptDate AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(gr.ReceiptDate AS DATE) <= @FechaHasta)
    ORDER BY gr.ReceiptDate DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReceipt_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReceipt_Get;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReceipt_Get
    @GoodsReceiptId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT gr.GoodsReceiptId, gr.CompanyId, gr.BranchId, gr.ReceiptNumber,
           gr.PurchaseDocumentNumber, gr.SupplierId, gr.WarehouseId,
           gr.ReceiptDate, gr.CarrierId, gr.DriverName, gr.VehiclePlate,
           gr.Notes, gr.Status, gr.CreatedAt, gr.ApprovedAt,
           c.CarrierName
    FROM logistics.GoodsReceipt gr
    LEFT JOIN logistics.Carrier c ON gr.CarrierId = c.CarrierId
    WHERE gr.GoodsReceiptId = @GoodsReceiptId;

    -- Lines
    SELECT l.LineId, l.GoodsReceiptId, l.ProductId, l.ExpectedQty, l.ReceivedQty,
           l.UnitCost, l.LotNumber, l.BinId, l.Notes
    FROM logistics.GoodsReceiptLine l
    WHERE l.GoodsReceiptId = @GoodsReceiptId
    ORDER BY l.LineId;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Create
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReceipt_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReceipt_Create;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReceipt_Create
    @CompanyId              INT,
    @BranchId               INT,
    @PurchaseDocumentNumber NVARCHAR(30) = NULL,
    @SupplierId             INT = NULL,
    @WarehouseId            INT,
    @ReceiptDate            DATETIME2(0),
    @CarrierId              INT = NULL,
    @DriverName             NVARCHAR(100) = NULL,
    @VehiclePlate           NVARCHAR(20) = NULL,
    @Notes                  NVARCHAR(500) = NULL,
    @LinesJson              NVARCHAR(MAX),
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReceiptNumber NVARCHAR(20);
    DECLARE @NewId INT;
    DECLARE @Seq INT;

    -- Generar numero de recepcion
    SELECT @Seq = ISNULL(MAX(CAST(RIGHT(ReceiptNumber, 8) AS INT)), 0) + 1
    FROM logistics.GoodsReceipt
    WHERE CompanyId = @CompanyId;

    SET @ReceiptNumber = 'REC-' + RIGHT('00000000' + CAST(@Seq AS NVARCHAR), 8);

    INSERT INTO logistics.GoodsReceipt (CompanyId, BranchId, ReceiptNumber, PurchaseDocumentNumber,
        SupplierId, WarehouseId, ReceiptDate, CarrierId, DriverName, VehiclePlate, Notes,
        Status, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @BranchId, @ReceiptNumber, @PurchaseDocumentNumber,
        @SupplierId, @WarehouseId, @ReceiptDate, @CarrierId, @DriverName, @VehiclePlate, @Notes,
        'DRAFT', @UserId, SYSUTCDATETIME());

    SET @NewId = SCOPE_IDENTITY();

    -- Insertar lineas desde JSON
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, ProductId, ExpectedQty, ReceivedQty, UnitCost, LotNumber, BinId, Notes)
    SELECT @NewId,
           JSON_VALUE(j.[value], '$.ProductId'),
           ISNULL(JSON_VALUE(j.[value], '$.ExpectedQty'), 0),
           ISNULL(JSON_VALUE(j.[value], '$.ReceivedQty'), 0),
           JSON_VALUE(j.[value], '$.UnitCost'),
           JSON_VALUE(j.[value], '$.LotNumber'),
           JSON_VALUE(j.[value], '$.BinId'),
           JSON_VALUE(j.[value], '$.Notes')
    FROM OPENJSON(@LinesJson) j;

    SELECT 1 AS ok, N'Recepcion creada' AS mensaje, @NewId AS GoodsReceiptId, @ReceiptNumber AS ReceiptNumber;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Approve
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReceipt_Approve', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReceipt_Approve;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReceipt_Approve
    @GoodsReceiptId INT,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT, @WarehouseId INT;

    SELECT @CompanyId = CompanyId, @BranchId = BranchId, @WarehouseId = WarehouseId
    FROM logistics.GoodsReceipt
    WHERE GoodsReceiptId = @GoodsReceiptId AND Status = 'DRAFT';

    IF @CompanyId IS NULL
    BEGIN
        SELECT 0 AS ok, N'Recepcion no encontrada o ya aprobada' AS mensaje;
        RETURN;
    END

    -- Cambiar estado
    UPDATE logistics.GoodsReceipt
    SET Status = 'COMPLETE', ApprovedBy = @UserId, ApprovedAt = SYSUTCDATETIME()
    WHERE GoodsReceiptId = @GoodsReceiptId;

    -- Crear movimientos de inventario por cada linea
    INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, ToWarehouseId, ToBinId,
        MovementType, Quantity, UnitCost, SourceDocumentType, SourceDocumentNumber, CreatedBy, CreatedAt)
    SELECT @CompanyId, @BranchId, l.ProductId, @WarehouseId, l.BinId,
           'PURCHASE_IN', l.ReceivedQty, l.UnitCost, 'GOODS_RECEIPT',
           gr.ReceiptNumber, @UserId, SYSUTCDATETIME()
    FROM logistics.GoodsReceiptLine l
    INNER JOIN logistics.GoodsReceipt gr ON l.GoodsReceiptId = gr.GoodsReceiptId
    WHERE l.GoodsReceiptId = @GoodsReceiptId AND l.ReceivedQty > 0;

    SELECT 1 AS ok, N'Recepcion aprobada y movimientos de inventario generados' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReturn_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReturn_List;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReturn_List
    @CompanyId   INT,
    @BranchId    INT,
    @Status      NVARCHAR(20) = NULL,
    @Page        INT = 1,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM logistics.GoodsReturn
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND (@Status IS NULL OR Status = @Status);

    SELECT GoodsReturnId, CompanyId, BranchId, ReturnNumber, GoodsReceiptId,
           SupplierId, WarehouseId, ReturnDate, Reason, Status,
           CreatedAt, ApprovedAt
    FROM logistics.GoodsReturn
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND (@Status IS NULL OR Status = @Status)
    ORDER BY ReturnDate DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_Create
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReturn_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReturn_Create;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReturn_Create
    @CompanyId       INT,
    @BranchId        INT,
    @GoodsReceiptId  INT = NULL,
    @SupplierId      INT = NULL,
    @WarehouseId     INT,
    @ReturnDate      DATETIME2(0),
    @Reason          NVARCHAR(250) = NULL,
    @LinesJson       NVARCHAR(MAX),
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReturnNumber NVARCHAR(20);
    DECLARE @NewId INT;
    DECLARE @Seq INT;

    SELECT @Seq = ISNULL(MAX(CAST(RIGHT(ReturnNumber, 8) AS INT)), 0) + 1
    FROM logistics.GoodsReturn
    WHERE CompanyId = @CompanyId;

    SET @ReturnNumber = 'DEV-' + RIGHT('00000000' + CAST(@Seq AS NVARCHAR), 8);

    INSERT INTO logistics.GoodsReturn (CompanyId, BranchId, ReturnNumber, GoodsReceiptId,
        SupplierId, WarehouseId, ReturnDate, Reason, Status, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @BranchId, @ReturnNumber, @GoodsReceiptId,
        @SupplierId, @WarehouseId, @ReturnDate, @Reason, 'DRAFT', @UserId, SYSUTCDATETIME());

    SET @NewId = SCOPE_IDENTITY();

    INSERT INTO logistics.GoodsReturnLine (GoodsReturnId, ProductId, Quantity, UnitCost, LotNumber, SerialNumber, Notes)
    SELECT @NewId,
           JSON_VALUE(j.[value], '$.ProductId'),
           ISNULL(JSON_VALUE(j.[value], '$.Quantity'), 0),
           JSON_VALUE(j.[value], '$.UnitCost'),
           JSON_VALUE(j.[value], '$.LotNumber'),
           JSON_VALUE(j.[value], '$.SerialNumber'),
           JSON_VALUE(j.[value], '$.Notes')
    FROM OPENJSON(@LinesJson) j;

    SELECT 1 AS ok, N'Devolucion creada' AS mensaje, @ReturnNumber AS ReturnNumber;
END
GO

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_Approve
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_GoodsReturn_Approve', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_GoodsReturn_Approve;
GO
CREATE PROCEDURE dbo.usp_Logistics_GoodsReturn_Approve
    @GoodsReturnId INT,
    @UserId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT, @WarehouseId INT;

    SELECT @CompanyId = CompanyId, @BranchId = BranchId, @WarehouseId = WarehouseId
    FROM logistics.GoodsReturn
    WHERE GoodsReturnId = @GoodsReturnId AND Status = 'DRAFT';

    IF @CompanyId IS NULL
    BEGIN
        SELECT 0 AS ok, N'Devolucion no encontrada o ya aprobada' AS mensaje;
        RETURN;
    END

    UPDATE logistics.GoodsReturn
    SET Status = 'COMPLETE', ApprovedBy = @UserId, ApprovedAt = SYSUTCDATETIME()
    WHERE GoodsReturnId = @GoodsReturnId;

    -- Crear movimientos de inventario (salida)
    INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, FromWarehouseId,
        MovementType, Quantity, UnitCost, SourceDocumentType, SourceDocumentNumber, CreatedBy, CreatedAt)
    SELECT @CompanyId, @BranchId, l.ProductId, @WarehouseId,
           'RETURN_OUT', l.Quantity, l.UnitCost, 'GOODS_RETURN',
           gr.ReturnNumber, @UserId, SYSUTCDATETIME()
    FROM logistics.GoodsReturnLine l
    INNER JOIN logistics.GoodsReturn gr ON l.GoodsReturnId = gr.GoodsReturnId
    WHERE l.GoodsReturnId = @GoodsReturnId AND l.Quantity > 0;

    SELECT 1 AS ok, N'Devolucion aprobada y movimientos de inventario generados' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_DeliveryNote_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_DeliveryNote_List;
GO
CREATE PROCEDURE dbo.usp_Logistics_DeliveryNote_List
    @CompanyId    INT,
    @BranchId     INT,
    @CustomerId   INT = NULL,
    @Status       NVARCHAR(20) = NULL,
    @FechaDesde   DATE = NULL,
    @FechaHasta   DATE = NULL,
    @Page         INT = 1,
    @Limit        INT = 50,
    @TotalCount   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM logistics.DeliveryNote
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND (@CustomerId IS NULL OR CustomerId = @CustomerId)
      AND (@Status IS NULL OR Status = @Status)
      AND (@FechaDesde IS NULL OR CAST(DeliveryDate AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(DeliveryDate AS DATE) <= @FechaHasta);

    SELECT dn.DeliveryNoteId, dn.CompanyId, dn.BranchId, dn.DeliveryNumber,
           dn.SalesDocumentNumber, dn.CustomerId, dn.WarehouseId,
           dn.DeliveryDate, dn.CarrierId, dn.DriverId, dn.VehiclePlate,
           dn.ShipToAddress, dn.ShipToContact, dn.EstimatedDelivery,
           dn.Status, dn.DeliveredToName, dn.CreatedAt,
           dn.DispatchedAt, dn.DeliveredAt,
           c.CarrierName, d.DriverName
    FROM logistics.DeliveryNote dn
    LEFT JOIN logistics.Carrier c ON dn.CarrierId = c.CarrierId
    LEFT JOIN logistics.Driver d ON dn.DriverId = d.DriverId
    WHERE dn.CompanyId = @CompanyId AND dn.BranchId = @BranchId
      AND (@CustomerId IS NULL OR dn.CustomerId = @CustomerId)
      AND (@Status IS NULL OR dn.Status = @Status)
      AND (@FechaDesde IS NULL OR CAST(dn.DeliveryDate AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(dn.DeliveryDate AS DATE) <= @FechaHasta)
    ORDER BY dn.DeliveryDate DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_DeliveryNote_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_DeliveryNote_Get;
GO
CREATE PROCEDURE dbo.usp_Logistics_DeliveryNote_Get
    @DeliveryNoteId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT dn.DeliveryNoteId, dn.CompanyId, dn.BranchId, dn.DeliveryNumber,
           dn.SalesDocumentNumber, dn.CustomerId, dn.WarehouseId,
           dn.DeliveryDate, dn.CarrierId, dn.DriverId, dn.VehiclePlate,
           dn.ShipToAddress, dn.ShipToContact, dn.EstimatedDelivery,
           dn.Status, dn.DeliveredToName, dn.DeliverySignature,
           dn.CreatedAt, dn.DispatchedAt, dn.DeliveredAt,
           c.CarrierName, d.DriverName
    FROM logistics.DeliveryNote dn
    LEFT JOIN logistics.Carrier c ON dn.CarrierId = c.CarrierId
    LEFT JOIN logistics.Driver d ON dn.DriverId = d.DriverId
    WHERE dn.DeliveryNoteId = @DeliveryNoteId;

    -- Lines
    SELECT l.LineId, l.DeliveryNoteId, l.ProductId, l.Quantity,
           l.UnitCost, l.LotNumber, l.BinId, l.Notes
    FROM logistics.DeliveryNoteLine l
    WHERE l.DeliveryNoteId = @DeliveryNoteId
    ORDER BY l.LineId;

    -- Serials
    SELECT s.Id, s.LineId, s.SerialNumber
    FROM logistics.DeliveryNoteSerial s
    INNER JOIN logistics.DeliveryNoteLine l ON s.LineId = l.LineId
    WHERE l.DeliveryNoteId = @DeliveryNoteId;
END
GO

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Create
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_DeliveryNote_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_DeliveryNote_Create;
GO
CREATE PROCEDURE dbo.usp_Logistics_DeliveryNote_Create
    @CompanyId              INT,
    @BranchId               INT,
    @SalesDocumentNumber    NVARCHAR(30) = NULL,
    @CustomerId             INT = NULL,
    @WarehouseId            INT,
    @DeliveryDate           DATETIME2(0),
    @CarrierId              INT = NULL,
    @DriverId               INT = NULL,
    @VehiclePlate           NVARCHAR(20) = NULL,
    @ShipToAddress          NVARCHAR(500) = NULL,
    @ShipToContact          NVARCHAR(100) = NULL,
    @EstimatedDelivery      DATETIME2(0) = NULL,
    @LinesJson              NVARCHAR(MAX),
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeliveryNumber NVARCHAR(20);
    DECLARE @NewId INT;
    DECLARE @Seq INT;

    SELECT @Seq = ISNULL(MAX(CAST(RIGHT(DeliveryNumber, 8) AS INT)), 0) + 1
    FROM logistics.DeliveryNote
    WHERE CompanyId = @CompanyId;

    SET @DeliveryNumber = 'NDE-' + RIGHT('00000000' + CAST(@Seq AS NVARCHAR), 8);

    INSERT INTO logistics.DeliveryNote (CompanyId, BranchId, DeliveryNumber, SalesDocumentNumber,
        CustomerId, WarehouseId, DeliveryDate, CarrierId, DriverId, VehiclePlate,
        ShipToAddress, ShipToContact, EstimatedDelivery, Status, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @BranchId, @DeliveryNumber, @SalesDocumentNumber,
        @CustomerId, @WarehouseId, @DeliveryDate, @CarrierId, @DriverId, @VehiclePlate,
        @ShipToAddress, @ShipToContact, @EstimatedDelivery, 'DRAFT', @UserId, SYSUTCDATETIME());

    SET @NewId = SCOPE_IDENTITY();

    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, ProductId, Quantity, UnitCost, LotNumber, BinId, Notes)
    SELECT @NewId,
           JSON_VALUE(j.[value], '$.ProductId'),
           ISNULL(JSON_VALUE(j.[value], '$.Quantity'), 0),
           JSON_VALUE(j.[value], '$.UnitCost'),
           JSON_VALUE(j.[value], '$.LotNumber'),
           JSON_VALUE(j.[value], '$.BinId'),
           JSON_VALUE(j.[value], '$.Notes')
    FROM OPENJSON(@LinesJson) j;

    SELECT 1 AS ok, N'Nota de entrega creada' AS mensaje, @NewId AS DeliveryNoteId, @DeliveryNumber AS DeliveryNumber;
END
GO

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Dispatch
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_DeliveryNote_Dispatch', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_DeliveryNote_Dispatch;
GO
CREATE PROCEDURE dbo.usp_Logistics_DeliveryNote_Dispatch
    @DeliveryNoteId INT,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT, @WarehouseId INT;

    SELECT @CompanyId = CompanyId, @BranchId = BranchId, @WarehouseId = WarehouseId
    FROM logistics.DeliveryNote
    WHERE DeliveryNoteId = @DeliveryNoteId AND Status = 'DRAFT';

    IF @CompanyId IS NULL
    BEGIN
        SELECT 0 AS ok, N'Nota de entrega no encontrada o no esta en borrador' AS mensaje;
        RETURN;
    END

    UPDATE logistics.DeliveryNote
    SET Status = 'DISPATCHED', DispatchedBy = @UserId, DispatchedAt = SYSUTCDATETIME()
    WHERE DeliveryNoteId = @DeliveryNoteId;

    -- Crear movimientos de inventario (salida por venta)
    INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, FromWarehouseId, FromBinId,
        MovementType, Quantity, UnitCost, SourceDocumentType, SourceDocumentNumber, CreatedBy, CreatedAt)
    SELECT @CompanyId, @BranchId, l.ProductId, @WarehouseId, l.BinId,
           'SALE_OUT', l.Quantity, l.UnitCost, 'DELIVERY_NOTE',
           dn.DeliveryNumber, @UserId, SYSUTCDATETIME()
    FROM logistics.DeliveryNoteLine l
    INNER JOIN logistics.DeliveryNote dn ON l.DeliveryNoteId = dn.DeliveryNoteId
    WHERE l.DeliveryNoteId = @DeliveryNoteId AND l.Quantity > 0;

    SELECT 1 AS ok, N'Nota de entrega despachada y movimientos de inventario generados' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Deliver
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_DeliveryNote_Deliver', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_DeliveryNote_Deliver;
GO
CREATE PROCEDURE dbo.usp_Logistics_DeliveryNote_Deliver
    @DeliveryNoteId     INT,
    @DeliveredToName    NVARCHAR(100) = NULL,
    @DeliverySignature  NVARCHAR(MAX) = NULL,
    @UserId             INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM logistics.DeliveryNote
        WHERE DeliveryNoteId = @DeliveryNoteId AND Status = 'DISPATCHED'
    )
    BEGIN
        SELECT 0 AS ok, N'Nota de entrega no encontrada o no esta despachada' AS mensaje;
        RETURN;
    END

    UPDATE logistics.DeliveryNote
    SET Status = 'DELIVERED',
        DeliveredToName = @DeliveredToName,
        DeliverySignature = @DeliverySignature,
        DeliveredBy = @UserId,
        DeliveredAt = SYSUTCDATETIME()
    WHERE DeliveryNoteId = @DeliveryNoteId;

    SELECT 1 AS ok, N'Entrega confirmada' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Logistics_Dashboard_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Dashboard_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logistics_Dashboard_Get;
GO
CREATE PROCEDURE dbo.usp_Logistics_Dashboard_Get
    @CompanyId  INT,
    @BranchId   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*)
         FROM logistics.GoodsReceipt
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId
           AND Status IN ('DRAFT','PARTIAL')
           AND IsDeleted = 0
        ) AS RecepcionesPendientes,

        (SELECT COUNT(*)
         FROM logistics.GoodsReturn
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId
           AND Status IN ('DRAFT','APPROVED')
           AND IsDeleted = 0
        ) AS DevolucionesEnProceso,

        (SELECT COUNT(*)
         FROM logistics.DeliveryNote
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId
           AND Status IN ('DISPATCHED','IN_TRANSIT')
           AND IsDeleted = 0
        ) AS AlbaranesEnTransito,

        (SELECT COUNT(*)
         FROM logistics.Carrier
         WHERE CompanyId = @CompanyId
           AND IsActive = 1
        ) AS TransportistasActivos;
END
GO
