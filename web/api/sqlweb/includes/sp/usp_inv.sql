/*
 * ============================================================================
 *  Archivo : usp_inv.sql
 *  Esquema : inv (inventario avanzado)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados de inventario avanzado: almacenes, zonas,
 *    ubicaciones, lotes, seriales, stock por ubicacion, valoracion y
 *    movimientos de inventario.
 *
 *  Compatibilidad: SQL Server 2012+
 *  Patron: IF EXISTS DROP + CREATE PROCEDURE
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
--  Schema: inv
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'inv')
    EXEC('CREATE SCHEMA inv');
GO

-- ============================================================================
--  Tabla: inv.Warehouse
-- ============================================================================
IF OBJECT_ID('inv.Warehouse', 'U') IS NULL
BEGIN
    CREATE TABLE inv.Warehouse (
        WarehouseId     INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL,
        BranchId        INT NOT NULL,
        WarehouseCode   NVARCHAR(20) NOT NULL,
        WarehouseName   NVARCHAR(100) NOT NULL,
        AddressLine     NVARCHAR(250) NULL,
        ContactName     NVARCHAR(100) NULL,
        Phone           NVARCHAR(50) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy       INT NULL,
        UpdatedAt       DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Warehouse_Code
        ON inv.Warehouse(CompanyId, WarehouseCode);
END
GO

-- ============================================================================
--  Tabla: inv.WarehouseZone
-- ============================================================================
IF OBJECT_ID('inv.WarehouseZone', 'U') IS NULL
BEGIN
    CREATE TABLE inv.WarehouseZone (
        ZoneId          INT IDENTITY(1,1) PRIMARY KEY,
        WarehouseId     INT NOT NULL REFERENCES inv.Warehouse(WarehouseId),
        ZoneCode        NVARCHAR(20) NOT NULL,
        ZoneName        NVARCHAR(100) NOT NULL,
        ZoneType        NVARCHAR(30) NULL,      -- STORAGE, RECEIVING, SHIPPING, QUARANTINE
        Temperature     NVARCHAR(20) NULL,       -- AMBIENT, COLD, FROZEN
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy       INT NULL,
        UpdatedAt       DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Zone_Code
        ON inv.WarehouseZone(WarehouseId, ZoneCode);
END
GO

-- ============================================================================
--  Tabla: inv.WarehouseBin
-- ============================================================================
IF OBJECT_ID('inv.WarehouseBin', 'U') IS NULL
BEGIN
    CREATE TABLE inv.WarehouseBin (
        BinId           INT IDENTITY(1,1) PRIMARY KEY,
        ZoneId          INT NOT NULL REFERENCES inv.WarehouseZone(ZoneId),
        BinCode         NVARCHAR(20) NOT NULL,
        BinName         NVARCHAR(100) NOT NULL,
        MaxWeight       DECIMAL(12,2) NULL,
        MaxVolume       DECIMAL(12,2) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedBy       INT NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy       INT NULL,
        UpdatedAt       DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Bin_Code
        ON inv.WarehouseBin(ZoneId, BinCode);
END
GO

-- ============================================================================
--  Tabla: inv.ProductLot
-- ============================================================================
IF OBJECT_ID('inv.ProductLot', 'U') IS NULL
BEGIN
    CREATE TABLE inv.ProductLot (
        LotId               INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        ProductId           INT NOT NULL,
        LotNumber           NVARCHAR(50) NOT NULL,
        ManufactureDate     DATE NULL,
        ExpiryDate          DATE NULL,
        SupplierCode        NVARCHAR(30) NULL,
        PurchaseDocumentNumber NVARCHAR(30) NULL,
        InitialQuantity     DECIMAL(18,4) NOT NULL DEFAULT 0,
        CurrentQuantity     DECIMAL(18,4) NOT NULL DEFAULT 0,
        UnitCost            DECIMAL(18,4) NULL,
        Status              NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE, DEPLETED, EXPIRED, QUARANTINE
        CreatedBy           INT NULL,
        CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE UNIQUE INDEX UX_Lot_Number
        ON inv.ProductLot(CompanyId, ProductId, LotNumber);

    CREATE INDEX IX_Lot_Product
        ON inv.ProductLot(CompanyId, ProductId, Status);
END
GO

-- ============================================================================
--  Tabla: inv.ProductSerial
-- ============================================================================
IF OBJECT_ID('inv.ProductSerial', 'U') IS NULL
BEGIN
    CREATE TABLE inv.ProductSerial (
        SerialId                INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId               INT NOT NULL,
        ProductId               INT NOT NULL,
        SerialNumber            NVARCHAR(100) NOT NULL,
        LotId                   INT NULL REFERENCES inv.ProductLot(LotId),
        WarehouseId             INT NULL REFERENCES inv.Warehouse(WarehouseId),
        BinId                   INT NULL REFERENCES inv.WarehouseBin(BinId),
        Status                  NVARCHAR(20) NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE, RESERVED, SOLD, RETURNED, DEFECTIVE
        PurchaseDocumentNumber  NVARCHAR(30) NULL,
        SalesDocumentNumber     NVARCHAR(30) NULL,
        CustomerId              INT NULL,
        UnitCost                DECIMAL(18,4) NULL,
        CreatedBy               INT NULL,
        CreatedAt               DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedBy               INT NULL,
        UpdatedAt               DATETIME2(0) NULL
    );

    CREATE UNIQUE INDEX UX_Serial_Number
        ON inv.ProductSerial(CompanyId, SerialNumber);

    CREATE INDEX IX_Serial_Product
        ON inv.ProductSerial(CompanyId, ProductId, Status);
END
GO

-- ============================================================================
--  Tabla: inv.ProductBinStock
-- ============================================================================
IF OBJECT_ID('inv.ProductBinStock', 'U') IS NULL
BEGIN
    CREATE TABLE inv.ProductBinStock (
        ProductBinStockId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        ProductId           INT NOT NULL,
        WarehouseId         INT NOT NULL REFERENCES inv.Warehouse(WarehouseId),
        ZoneId              INT NULL REFERENCES inv.WarehouseZone(ZoneId),
        BinId               INT NULL REFERENCES inv.WarehouseBin(BinId),
        LotId               INT NULL REFERENCES inv.ProductLot(LotId),
        Quantity            DECIMAL(18,4) NOT NULL DEFAULT 0,
        ReservedQuantity    DECIMAL(18,4) NOT NULL DEFAULT 0,
        UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE UNIQUE INDEX UX_BinStock
        ON inv.ProductBinStock(CompanyId, ProductId, WarehouseId, ISNULL(ZoneId, 0), ISNULL(BinId, 0), ISNULL(LotId, 0));
END
GO

-- ============================================================================
--  Tabla: inv.InventoryValuationMethod
-- ============================================================================
IF OBJECT_ID('inv.InventoryValuationMethod', 'U') IS NULL
BEGIN
    CREATE TABLE inv.InventoryValuationMethod (
        ValuationMethodId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        ProductId           INT NOT NULL,
        Method              NVARCHAR(20) NOT NULL DEFAULT 'WEIGHTED_AVG', -- WEIGHTED_AVG, FIFO, LIFO, STANDARD
        StandardCost        DECIMAL(18,4) NULL,
        UpdatedBy           INT NULL,
        UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE UNIQUE INDEX UX_Valuation
        ON inv.InventoryValuationMethod(CompanyId, ProductId);
END
GO

-- ============================================================================
--  Tabla: inv.StockMovement
-- ============================================================================
IF OBJECT_ID('inv.StockMovement', 'U') IS NULL
BEGIN
    CREATE TABLE inv.StockMovement (
        MovementId              INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId               INT NOT NULL,
        BranchId                INT NOT NULL,
        ProductId               INT NOT NULL,
        LotId                   INT NULL REFERENCES inv.ProductLot(LotId),
        SerialId                INT NULL REFERENCES inv.ProductSerial(SerialId),
        FromWarehouseId         INT NULL REFERENCES inv.Warehouse(WarehouseId),
        ToWarehouseId           INT NULL REFERENCES inv.Warehouse(WarehouseId),
        FromBinId               INT NULL REFERENCES inv.WarehouseBin(BinId),
        ToBinId                 INT NULL REFERENCES inv.WarehouseBin(BinId),
        MovementType            NVARCHAR(30) NOT NULL,  -- PURCHASE_IN, SALE_OUT, TRANSFER, ADJUSTMENT, RETURN_IN, RETURN_OUT
        Quantity                DECIMAL(18,4) NOT NULL,
        UnitCost                DECIMAL(18,4) NULL,
        SourceDocumentType      NVARCHAR(30) NULL,
        SourceDocumentNumber    NVARCHAR(30) NULL,
        Notes                   NVARCHAR(500) NULL,
        CreatedBy               INT NULL,
        CreatedAt               DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_Movement_Company
        ON inv.StockMovement(CompanyId, CreatedAt DESC);

    CREATE INDEX IX_Movement_Product
        ON inv.StockMovement(CompanyId, ProductId, CreatedAt DESC);
END
GO


-- ============================================================================
--  SP: usp_Inv_Warehouse_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Warehouse_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Warehouse_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Warehouse_List
    @CompanyId   INT,
    @Search      NVARCHAR(100) = NULL,
    @Page        INT = 1,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM inv.Warehouse
    WHERE CompanyId = @CompanyId
      AND (@Search IS NULL
           OR WarehouseCode LIKE '%' + @Search + '%'
           OR WarehouseName LIKE '%' + @Search + '%');

    SELECT WarehouseId, CompanyId, BranchId, WarehouseCode, WarehouseName,
           AddressLine, ContactName, Phone, IsActive, CreatedAt, UpdatedAt
    FROM inv.Warehouse
    WHERE CompanyId = @CompanyId
      AND (@Search IS NULL
           OR WarehouseCode LIKE '%' + @Search + '%'
           OR WarehouseName LIKE '%' + @Search + '%')
    ORDER BY WarehouseName
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Inv_Warehouse_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Warehouse_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Warehouse_Get;
GO
CREATE PROCEDURE dbo.usp_Inv_Warehouse_Get
    @CompanyId    INT,
    @WarehouseId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT WarehouseId, CompanyId, BranchId, WarehouseCode, WarehouseName,
           AddressLine, ContactName, Phone, IsActive, CreatedAt, UpdatedAt
    FROM inv.Warehouse
    WHERE CompanyId = @CompanyId AND WarehouseId = @WarehouseId;
END
GO

-- ============================================================================
--  SP: usp_Inv_Warehouse_Upsert
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Warehouse_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Warehouse_Upsert;
GO
CREATE PROCEDURE dbo.usp_Inv_Warehouse_Upsert
    @CompanyId      INT,
    @BranchId       INT,
    @WarehouseId    INT = NULL,
    @WarehouseCode  NVARCHAR(20),
    @WarehouseName  NVARCHAR(100),
    @AddressLine    NVARCHAR(250) = NULL,
    @ContactName    NVARCHAR(100) = NULL,
    @Phone          NVARCHAR(50) = NULL,
    @IsActive       BIT = 1,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar codigo unico
    IF EXISTS (
        SELECT 1 FROM inv.Warehouse
        WHERE CompanyId = @CompanyId
          AND WarehouseCode = @WarehouseCode
          AND (@WarehouseId IS NULL OR WarehouseId <> @WarehouseId)
    )
    BEGIN
        SELECT 0 AS ok, N'El codigo de almacen ya existe' AS mensaje, NULL AS WarehouseId;
        RETURN;
    END

    IF @WarehouseId IS NULL
    BEGIN
        INSERT INTO inv.Warehouse (CompanyId, BranchId, WarehouseCode, WarehouseName, AddressLine, ContactName, Phone, IsActive, CreatedBy, CreatedAt)
        VALUES (@CompanyId, @BranchId, @WarehouseCode, @WarehouseName, @AddressLine, @ContactName, @Phone, @IsActive, @UserId, SYSUTCDATETIME());

        SELECT 1 AS ok, N'Almacen creado' AS mensaje, SCOPE_IDENTITY() AS WarehouseId;
    END
    ELSE
    BEGIN
        UPDATE inv.Warehouse
        SET WarehouseCode = @WarehouseCode,
            WarehouseName = @WarehouseName,
            AddressLine   = @AddressLine,
            ContactName   = @ContactName,
            Phone         = @Phone,
            IsActive      = @IsActive,
            UpdatedBy     = @UserId,
            UpdatedAt     = SYSUTCDATETIME()
        WHERE WarehouseId = @WarehouseId AND CompanyId = @CompanyId;

        SELECT 1 AS ok, N'Almacen actualizado' AS mensaje, @WarehouseId AS WarehouseId;
    END
END
GO

-- ============================================================================
--  SP: usp_Inv_Zone_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Zone_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Zone_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Zone_List
    @WarehouseId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ZoneId, WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, IsActive, CreatedAt, UpdatedAt
    FROM inv.WarehouseZone
    WHERE WarehouseId = @WarehouseId
    ORDER BY ZoneCode;
END
GO

-- ============================================================================
--  SP: usp_Inv_Zone_Upsert
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Zone_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Zone_Upsert;
GO
CREATE PROCEDURE dbo.usp_Inv_Zone_Upsert
    @ZoneId       INT = NULL,
    @WarehouseId  INT,
    @ZoneCode     NVARCHAR(20),
    @ZoneName     NVARCHAR(100),
    @ZoneType     NVARCHAR(30) = NULL,
    @Temperature  NVARCHAR(20) = NULL,
    @IsActive     BIT = 1,
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inv.WarehouseZone
        WHERE WarehouseId = @WarehouseId
          AND ZoneCode = @ZoneCode
          AND (@ZoneId IS NULL OR ZoneId <> @ZoneId)
    )
    BEGIN
        SELECT 0 AS ok, N'El codigo de zona ya existe en este almacen' AS mensaje;
        RETURN;
    END

    IF @ZoneId IS NULL
    BEGIN
        INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, IsActive, CreatedBy, CreatedAt)
        VALUES (@WarehouseId, @ZoneCode, @ZoneName, @ZoneType, @Temperature, @IsActive, @UserId, SYSUTCDATETIME());

        SELECT 1 AS ok, N'Zona creada' AS mensaje;
    END
    ELSE
    BEGIN
        UPDATE inv.WarehouseZone
        SET ZoneCode    = @ZoneCode,
            ZoneName    = @ZoneName,
            ZoneType    = @ZoneType,
            Temperature = @Temperature,
            IsActive    = @IsActive,
            UpdatedBy   = @UserId,
            UpdatedAt   = SYSUTCDATETIME()
        WHERE ZoneId = @ZoneId;

        SELECT 1 AS ok, N'Zona actualizada' AS mensaje;
    END
END
GO

-- ============================================================================
--  SP: usp_Inv_Bin_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Bin_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Bin_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Bin_List
    @ZoneId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT BinId, ZoneId, BinCode, BinName, MaxWeight, MaxVolume, IsActive, CreatedAt, UpdatedAt
    FROM inv.WarehouseBin
    WHERE ZoneId = @ZoneId
    ORDER BY BinCode;
END
GO

-- ============================================================================
--  SP: usp_Inv_Bin_Upsert
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Bin_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Bin_Upsert;
GO
CREATE PROCEDURE dbo.usp_Inv_Bin_Upsert
    @BinId      INT = NULL,
    @ZoneId     INT,
    @BinCode    NVARCHAR(20),
    @BinName    NVARCHAR(100),
    @MaxWeight  DECIMAL(12,2) = NULL,
    @MaxVolume  DECIMAL(12,2) = NULL,
    @IsActive   BIT = 1,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inv.WarehouseBin
        WHERE ZoneId = @ZoneId
          AND BinCode = @BinCode
          AND (@BinId IS NULL OR BinId <> @BinId)
    )
    BEGIN
        SELECT 0 AS ok, N'El codigo de ubicacion ya existe en esta zona' AS mensaje;
        RETURN;
    END

    IF @BinId IS NULL
    BEGIN
        INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, IsActive, CreatedBy, CreatedAt)
        VALUES (@ZoneId, @BinCode, @BinName, @MaxWeight, @MaxVolume, @IsActive, @UserId, SYSUTCDATETIME());

        SELECT 1 AS ok, N'Ubicacion creada' AS mensaje;
    END
    ELSE
    BEGIN
        UPDATE inv.WarehouseBin
        SET BinCode   = @BinCode,
            BinName   = @BinName,
            MaxWeight = @MaxWeight,
            MaxVolume = @MaxVolume,
            IsActive  = @IsActive,
            UpdatedBy = @UserId,
            UpdatedAt = SYSUTCDATETIME()
        WHERE BinId = @BinId;

        SELECT 1 AS ok, N'Ubicacion actualizada' AS mensaje;
    END
END
GO

-- ============================================================================
--  SP: usp_Inv_Lot_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Lot_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Lot_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Lot_List
    @CompanyId  INT,
    @ProductId  INT = NULL,
    @Status     NVARCHAR(20) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM inv.ProductLot
    WHERE CompanyId = @CompanyId
      AND (@ProductId IS NULL OR ProductId = @ProductId)
      AND (@Status IS NULL OR Status = @Status);

    SELECT LotId, CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate,
           SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity,
           UnitCost, Status, CreatedAt
    FROM inv.ProductLot
    WHERE CompanyId = @CompanyId
      AND (@ProductId IS NULL OR ProductId = @ProductId)
      AND (@Status IS NULL OR Status = @Status)
    ORDER BY CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Inv_Lot_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Lot_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Lot_Get;
GO
CREATE PROCEDURE dbo.usp_Inv_Lot_Get
    @LotId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT LotId, CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate,
           SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity,
           UnitCost, Status, CreatedAt
    FROM inv.ProductLot
    WHERE LotId = @LotId;
END
GO

-- ============================================================================
--  SP: usp_Inv_Lot_Create
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Lot_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Lot_Create;
GO
CREATE PROCEDURE dbo.usp_Inv_Lot_Create
    @CompanyId              INT,
    @ProductId              INT,
    @LotNumber              NVARCHAR(50),
    @ManufactureDate        DATE = NULL,
    @ExpiryDate             DATE = NULL,
    @SupplierCode           NVARCHAR(30) = NULL,
    @PurchaseDocumentNumber NVARCHAR(30) = NULL,
    @InitialQuantity        DECIMAL(18,4) = 0,
    @UnitCost               DECIMAL(18,4) = NULL,
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inv.ProductLot
        WHERE CompanyId = @CompanyId AND ProductId = @ProductId AND LotNumber = @LotNumber
    )
    BEGIN
        SELECT 0 AS ok, N'El numero de lote ya existe para este producto' AS mensaje, NULL AS LotId;
        RETURN;
    END

    INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate,
        SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @ProductId, @LotNumber, @ManufactureDate, @ExpiryDate,
        @SupplierCode, @PurchaseDocumentNumber, @InitialQuantity, @InitialQuantity, @UnitCost, 'ACTIVE', @UserId, SYSUTCDATETIME());

    SELECT 1 AS ok, N'Lote creado' AS mensaje, SCOPE_IDENTITY() AS LotId;
END
GO

-- ============================================================================
--  SP: usp_Inv_Serial_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Serial_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Serial_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Serial_List
    @CompanyId   INT,
    @ProductId   INT = NULL,
    @Status      NVARCHAR(20) = NULL,
    @Search      NVARCHAR(100) = NULL,
    @Page        INT = 1,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM inv.ProductSerial
    WHERE CompanyId = @CompanyId
      AND (@ProductId IS NULL OR ProductId = @ProductId)
      AND (@Status IS NULL OR Status = @Status)
      AND (@Search IS NULL OR SerialNumber LIKE '%' + @Search + '%');

    SELECT s.SerialId, s.CompanyId, s.ProductId, s.SerialNumber, s.LotId,
           s.WarehouseId, s.BinId, s.Status,
           s.PurchaseDocumentNumber, s.SalesDocumentNumber, s.CustomerId,
           s.UnitCost, s.CreatedAt, s.UpdatedAt,
           w.WarehouseName, b.BinCode
    FROM inv.ProductSerial s
    LEFT JOIN inv.Warehouse w ON s.WarehouseId = w.WarehouseId
    LEFT JOIN inv.WarehouseBin b ON s.BinId = b.BinId
    WHERE s.CompanyId = @CompanyId
      AND (@ProductId IS NULL OR s.ProductId = @ProductId)
      AND (@Status IS NULL OR s.Status = @Status)
      AND (@Search IS NULL OR s.SerialNumber LIKE '%' + @Search + '%')
    ORDER BY s.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Inv_Serial_Get
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Serial_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Serial_Get;
GO
CREATE PROCEDURE dbo.usp_Inv_Serial_Get
    @SerialId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT s.SerialId, s.CompanyId, s.ProductId, s.SerialNumber, s.LotId,
           s.WarehouseId, s.BinId, s.Status,
           s.PurchaseDocumentNumber, s.SalesDocumentNumber, s.CustomerId,
           s.UnitCost, s.CreatedAt, s.UpdatedAt,
           w.WarehouseName, b.BinCode, l.LotNumber
    FROM inv.ProductSerial s
    LEFT JOIN inv.Warehouse w ON s.WarehouseId = w.WarehouseId
    LEFT JOIN inv.WarehouseBin b ON s.BinId = b.BinId
    LEFT JOIN inv.ProductLot l ON s.LotId = l.LotId
    WHERE s.SerialId = @SerialId;

    -- Movement history
    SELECT m.MovementId, m.MovementType, m.Quantity, m.UnitCost,
           m.SourceDocumentType, m.SourceDocumentNumber, m.Notes, m.CreatedAt
    FROM inv.StockMovement m
    WHERE m.SerialId = @SerialId
    ORDER BY m.CreatedAt DESC;
END
GO

-- ============================================================================
--  SP: usp_Inv_Serial_Register
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Serial_Register', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Serial_Register;
GO
CREATE PROCEDURE dbo.usp_Inv_Serial_Register
    @CompanyId              INT,
    @ProductId              INT,
    @SerialNumber           NVARCHAR(100),
    @LotId                  INT = NULL,
    @WarehouseId            INT,
    @BinId                  INT = NULL,
    @PurchaseDocumentNumber NVARCHAR(30) = NULL,
    @UnitCost               DECIMAL(18,4) = NULL,
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inv.ProductSerial
        WHERE CompanyId = @CompanyId AND SerialNumber = @SerialNumber
    )
    BEGIN
        SELECT 0 AS ok, N'El numero de serie ya existe' AS mensaje, NULL AS SerialId;
        RETURN;
    END

    INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, LotId, WarehouseId, BinId,
        Status, PurchaseDocumentNumber, UnitCost, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @ProductId, @SerialNumber, @LotId, @WarehouseId, @BinId,
        'AVAILABLE', @PurchaseDocumentNumber, @UnitCost, @UserId, SYSUTCDATETIME());

    SELECT 1 AS ok, N'Serial registrado' AS mensaje, SCOPE_IDENTITY() AS SerialId;
END
GO

-- ============================================================================
--  SP: usp_Inv_Serial_UpdateStatus
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Serial_UpdateStatus', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Serial_UpdateStatus;
GO
CREATE PROCEDURE dbo.usp_Inv_Serial_UpdateStatus
    @SerialId               INT,
    @Status                 NVARCHAR(20),
    @SalesDocumentNumber    NVARCHAR(30) = NULL,
    @CustomerId             INT = NULL,
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE SerialId = @SerialId)
    BEGIN
        SELECT 0 AS ok, N'Serial no encontrado' AS mensaje;
        RETURN;
    END

    UPDATE inv.ProductSerial
    SET Status               = @Status,
        SalesDocumentNumber  = ISNULL(@SalesDocumentNumber, SalesDocumentNumber),
        CustomerId           = ISNULL(@CustomerId, CustomerId),
        UpdatedBy            = @UserId,
        UpdatedAt            = SYSUTCDATETIME()
    WHERE SerialId = @SerialId;

    SELECT 1 AS ok, N'Estado de serial actualizado' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Inv_BinStock_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_BinStock_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_BinStock_List;
GO
CREATE PROCEDURE dbo.usp_Inv_BinStock_List
    @CompanyId    INT,
    @WarehouseId  INT = NULL,
    @ProductId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT bs.ProductBinStockId, bs.CompanyId, bs.ProductId,
           bs.WarehouseId, bs.ZoneId, bs.BinId, bs.LotId,
           bs.Quantity, bs.ReservedQuantity,
           (bs.Quantity - bs.ReservedQuantity) AS AvailableQuantity,
           w.WarehouseName, w.WarehouseCode,
           z.ZoneName, z.ZoneCode,
           b.BinName, b.BinCode,
           l.LotNumber
    FROM inv.ProductBinStock bs
    INNER JOIN inv.Warehouse w ON bs.WarehouseId = w.WarehouseId
    LEFT JOIN inv.WarehouseZone z ON bs.ZoneId = z.ZoneId
    LEFT JOIN inv.WarehouseBin b ON bs.BinId = b.BinId
    LEFT JOIN inv.ProductLot l ON bs.LotId = l.LotId
    WHERE bs.CompanyId = @CompanyId
      AND (@WarehouseId IS NULL OR bs.WarehouseId = @WarehouseId)
      AND (@ProductId IS NULL OR bs.ProductId = @ProductId)
    ORDER BY w.WarehouseName, z.ZoneCode, b.BinCode;
END
GO

-- ============================================================================
--  SP: usp_Inv_Valuation_GetMethod
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Valuation_GetMethod', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Valuation_GetMethod;
GO
CREATE PROCEDURE dbo.usp_Inv_Valuation_GetMethod
    @CompanyId  INT,
    @ProductId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ValuationMethodId, CompanyId, ProductId, Method, StandardCost, UpdatedAt
    FROM inv.InventoryValuationMethod
    WHERE CompanyId = @CompanyId AND ProductId = @ProductId;
END
GO

-- ============================================================================
--  SP: usp_Inv_Valuation_SetMethod
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Valuation_SetMethod', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Valuation_SetMethod;
GO
CREATE PROCEDURE dbo.usp_Inv_Valuation_SetMethod
    @CompanyId     INT,
    @ProductId     INT,
    @Method        NVARCHAR(20),
    @StandardCost  DECIMAL(18,4) = NULL,
    @UserId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inv.InventoryValuationMethod WHERE CompanyId = @CompanyId AND ProductId = @ProductId)
    BEGIN
        UPDATE inv.InventoryValuationMethod
        SET Method       = @Method,
            StandardCost = @StandardCost,
            UpdatedBy    = @UserId,
            UpdatedAt    = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId AND ProductId = @ProductId;
    END
    ELSE
    BEGIN
        INSERT INTO inv.InventoryValuationMethod (CompanyId, ProductId, Method, StandardCost, UpdatedBy, UpdatedAt)
        VALUES (@CompanyId, @ProductId, @Method, @StandardCost, @UserId, SYSUTCDATETIME());
    END

    SELECT 1 AS ok, N'Metodo de valoracion actualizado' AS mensaje;
END
GO

-- ============================================================================
--  SP: usp_Inv_Movement_List
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Movement_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Movement_List;
GO
CREATE PROCEDURE dbo.usp_Inv_Movement_List
    @CompanyId      INT,
    @ProductId      INT = NULL,
    @WarehouseId    INT = NULL,
    @MovementType   NVARCHAR(30) = NULL,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM inv.StockMovement
    WHERE CompanyId = @CompanyId
      AND (@ProductId IS NULL OR ProductId = @ProductId)
      AND (@WarehouseId IS NULL OR FromWarehouseId = @WarehouseId OR ToWarehouseId = @WarehouseId)
      AND (@MovementType IS NULL OR MovementType = @MovementType)
      AND (@FechaDesde IS NULL OR CAST(CreatedAt AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(CreatedAt AS DATE) <= @FechaHasta);

    SELECT m.MovementId, m.CompanyId, m.BranchId, m.ProductId,
           m.LotId, m.SerialId,
           m.FromWarehouseId, m.ToWarehouseId, m.FromBinId, m.ToBinId,
           m.MovementType, m.Quantity, m.UnitCost,
           m.SourceDocumentType, m.SourceDocumentNumber, m.Notes, m.CreatedAt,
           fw.WarehouseName AS FromWarehouseName,
           tw.WarehouseName AS ToWarehouseName
    FROM inv.StockMovement m
    LEFT JOIN inv.Warehouse fw ON m.FromWarehouseId = fw.WarehouseId
    LEFT JOIN inv.Warehouse tw ON m.ToWarehouseId = tw.WarehouseId
    WHERE m.CompanyId = @CompanyId
      AND (@ProductId IS NULL OR m.ProductId = @ProductId)
      AND (@WarehouseId IS NULL OR m.FromWarehouseId = @WarehouseId OR m.ToWarehouseId = @WarehouseId)
      AND (@MovementType IS NULL OR m.MovementType = @MovementType)
      AND (@FechaDesde IS NULL OR CAST(m.CreatedAt AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(m.CreatedAt AS DATE) <= @FechaHasta)
    ORDER BY m.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ============================================================================
--  SP: usp_Inv_Movement_Create
-- ============================================================================
IF OBJECT_ID('dbo.usp_Inv_Movement_Create', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Inv_Movement_Create;
GO
CREATE PROCEDURE dbo.usp_Inv_Movement_Create
    @CompanyId              INT,
    @BranchId               INT,
    @ProductId              INT,
    @LotId                  INT = NULL,
    @SerialId               INT = NULL,
    @FromWarehouseId        INT = NULL,
    @ToWarehouseId          INT = NULL,
    @FromBinId              INT = NULL,
    @ToBinId                INT = NULL,
    @MovementType           NVARCHAR(30),
    @Quantity               DECIMAL(18,4),
    @UnitCost               DECIMAL(18,4) = NULL,
    @SourceDocumentType     NVARCHAR(30) = NULL,
    @SourceDocumentNumber   NVARCHAR(30) = NULL,
    @Notes                  NVARCHAR(500) = NULL,
    @UserId                 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, LotId, SerialId,
        FromWarehouseId, ToWarehouseId, FromBinId, ToBinId,
        MovementType, Quantity, UnitCost,
        SourceDocumentType, SourceDocumentNumber, Notes, CreatedBy, CreatedAt)
    VALUES (@CompanyId, @BranchId, @ProductId, @LotId, @SerialId,
        @FromWarehouseId, @ToWarehouseId, @FromBinId, @ToBinId,
        @MovementType, @Quantity, @UnitCost,
        @SourceDocumentType, @SourceDocumentNumber, @Notes, @UserId, SYSUTCDATETIME());

    -- Actualizar stock en ubicacion destino (si aplica)
    IF @ToWarehouseId IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM inv.ProductBinStock
            WHERE CompanyId = @CompanyId AND ProductId = @ProductId
              AND WarehouseId = @ToWarehouseId
              AND ISNULL(ZoneId, 0) = ISNULL(
                  (SELECT ZoneId FROM inv.WarehouseBin WHERE BinId = @ToBinId), 0)
              AND ISNULL(BinId, 0) = ISNULL(@ToBinId, 0)
              AND ISNULL(LotId, 0) = ISNULL(@LotId, 0)
        )
        BEGIN
            UPDATE inv.ProductBinStock
            SET Quantity  = Quantity + @Quantity,
                UpdatedAt = SYSUTCDATETIME()
            WHERE CompanyId = @CompanyId AND ProductId = @ProductId
              AND WarehouseId = @ToWarehouseId
              AND ISNULL(ZoneId, 0) = ISNULL(
                  (SELECT ZoneId FROM inv.WarehouseBin WHERE BinId = @ToBinId), 0)
              AND ISNULL(BinId, 0) = ISNULL(@ToBinId, 0)
              AND ISNULL(LotId, 0) = ISNULL(@LotId, 0);
        END
        ELSE
        BEGIN
            INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, ZoneId, BinId, LotId, Quantity, ReservedQuantity, UpdatedAt)
            VALUES (@CompanyId, @ProductId, @ToWarehouseId,
                (SELECT ZoneId FROM inv.WarehouseBin WHERE BinId = @ToBinId),
                @ToBinId, @LotId, @Quantity, 0, SYSUTCDATETIME());
        END
    END

    -- Descontar stock de ubicacion origen (si aplica)
    IF @FromWarehouseId IS NOT NULL
    BEGIN
        UPDATE inv.ProductBinStock
        SET Quantity  = Quantity - @Quantity,
            UpdatedAt = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId AND ProductId = @ProductId
          AND WarehouseId = @FromWarehouseId
          AND ISNULL(BinId, 0) = ISNULL(@FromBinId, 0)
          AND ISNULL(LotId, 0) = ISNULL(@LotId, 0);
    END

    SELECT 1 AS ok, N'Movimiento registrado' AS mensaje, SCOPE_IDENTITY() AS MovementId;
END
GO
