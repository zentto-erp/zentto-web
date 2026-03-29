/*
 * ============================================================================
 *  Archivo : usp_fleet.sql
 *  Esquema : fleet (tablas), dbo (procedimientos)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados para el modulo de Control de Flota.
 *    Vehiculos, Combustible, Mantenimiento, Viajes, Documentos, Dashboard.
 *
 *  Convenciones:
 *    - Nombrado: usp_Fleet_[Entity]_[Action]
 *    - Patron: CREATE OR ALTER (idempotente)
 *    - Listas paginadas: @TotalCount OUTPUT
 *    - Escrituras: @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SECCION 1: VEHICULOS
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_Vehicle_List
--  Lista paginada de vehiculos con filtros opcionales.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Vehicle_List
    @CompanyId      INT,
    @Status         NVARCHAR(20)  = NULL,
    @VehicleType    NVARCHAR(30)  = NULL,
    @Search         NVARCHAR(100) = NULL,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*)
    FROM fleet.Vehicle
    WHERE CompanyId = @CompanyId
      AND (@Status IS NULL OR (
            (@Status = 'ACTIVE' AND IsActive = 1)
            OR (@Status = 'INACTIVE' AND IsActive = 0)
          ))
      AND (@VehicleType IS NULL OR VehicleType = @VehicleType)
      AND (@Search IS NULL OR (
            VehiclePlate LIKE '%' + @Search + '%'
            OR Brand LIKE '%' + @Search + '%'
            OR Model LIKE '%' + @Search + '%'
            OR VIN LIKE '%' + @Search + '%'
          ));

    SELECT
        v.VehicleId,
        v.VehiclePlate,
        v.VIN,
        v.Brand,
        v.Model,
        v.[Year],
        v.Color,
        v.VehicleType,
        v.FuelType,
        v.CurrentMileage,
        v.IsActive,
        v.AssignedDriverId,
        v.AssignedBranchId,
        v.InsuranceExpiry,
        v.TechnicalReviewExpiry,
        v.PermitExpiry,
        v.CreatedAt
    FROM fleet.Vehicle v
    WHERE v.CompanyId = @CompanyId
      AND (@Status IS NULL OR (
            (@Status = 'ACTIVE' AND v.IsActive = 1)
            OR (@Status = 'INACTIVE' AND v.IsActive = 0)
          ))
      AND (@VehicleType IS NULL OR v.VehicleType = @VehicleType)
      AND (@Search IS NULL OR (
            v.VehiclePlate LIKE '%' + @Search + '%'
            OR v.Brand LIKE '%' + @Search + '%'
            OR v.Model LIKE '%' + @Search + '%'
            OR v.VIN LIKE '%' + @Search + '%'
          ))
    ORDER BY v.VehiclePlate
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_Vehicle_Get
--  Detalle de vehiculo + documentos + mantenimientos proximos.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Vehicle_Get
    @VehicleId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Vehiculo
    SELECT
        v.VehicleId,
        v.CompanyId,
        v.VehiclePlate,
        v.VIN,
        v.Brand,
        v.Model,
        v.[Year],
        v.Color,
        v.VehicleType,
        v.FuelType,
        v.CurrentMileage,
        v.PurchaseDate,
        v.PurchaseCost,
        v.InsurancePolicy,
        v.InsuranceExpiry,
        v.TechnicalReviewExpiry,
        v.PermitExpiry,
        v.AssignedDriverId,
        v.AssignedBranchId,
        v.Notes,
        v.IsActive,
        v.CreatedAt,
        v.UpdatedAt
    FROM fleet.Vehicle v
    WHERE v.VehicleId = @VehicleId;

    -- Recordset 2: Documentos del vehiculo
    SELECT
        d.DocumentId,
        d.DocumentType,
        d.DocumentNumber,
        d.IssueDate,
        d.ExpiryDate,
        d.FilePath,
        d.Notes
    FROM fleet.VehicleDocument d
    WHERE d.VehicleId = @VehicleId
    ORDER BY d.ExpiryDate DESC;

    -- Recordset 3: Mantenimientos proximos (pendientes/programados)
    SELECT TOP 5
        mo.MaintenanceOrderId,
        mo.OrderNumber,
        mt.TypeName,
        mo.ScheduledDate,
        mo.EstimatedCost,
        mo.[Status]
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.MaintenanceType mt ON mt.MaintenanceTypeId = mo.MaintenanceTypeId
    WHERE mo.VehicleId = @VehicleId
      AND mo.[Status] IN ('PENDING', 'SCHEDULED')
    ORDER BY mo.ScheduledDate;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_Vehicle_Upsert
--  Crea o actualiza un vehiculo.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Vehicle_Upsert
    @CompanyId              INT,
    @VehicleId              INT = NULL,
    @VehiclePlate           NVARCHAR(20),
    @VIN                    NVARCHAR(50) = NULL,
    @Brand                  NVARCHAR(50),
    @Model                  NVARCHAR(50),
    @Year                   INT,
    @Color                  NVARCHAR(30) = NULL,
    @VehicleType            NVARCHAR(30),
    @FuelType               NVARCHAR(20),
    @CurrentMileage         DECIMAL(12,2),
    @PurchaseDate           DATETIME2 = NULL,
    @PurchaseCost           DECIMAL(18,2) = NULL,
    @InsurancePolicy        NVARCHAR(100) = NULL,
    @InsuranceExpiry        DATETIME2 = NULL,
    @TechnicalReviewExpiry  DATETIME2 = NULL,
    @PermitExpiry           DATETIME2 = NULL,
    @AssignedDriverId       INT = NULL,
    @AssignedBranchId       INT = NULL,
    @Notes                  NVARCHAR(500) = NULL,
    @IsActive               BIT = 1,
    @UserId                 INT,
    @Resultado              INT OUTPUT,
    @VehicleIdOut           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @VehicleId IS NOT NULL AND EXISTS (SELECT 1 FROM fleet.Vehicle WHERE VehicleId = @VehicleId)
        BEGIN
            UPDATE fleet.Vehicle SET
                VehiclePlate           = @VehiclePlate,
                VIN                    = @VIN,
                Brand                  = @Brand,
                Model                  = @Model,
                [Year]                 = @Year,
                Color                  = @Color,
                VehicleType            = @VehicleType,
                FuelType               = @FuelType,
                CurrentMileage         = @CurrentMileage,
                PurchaseDate           = @PurchaseDate,
                PurchaseCost           = @PurchaseCost,
                InsurancePolicy        = @InsurancePolicy,
                InsuranceExpiry        = @InsuranceExpiry,
                TechnicalReviewExpiry  = @TechnicalReviewExpiry,
                PermitExpiry           = @PermitExpiry,
                AssignedDriverId       = @AssignedDriverId,
                AssignedBranchId       = @AssignedBranchId,
                Notes                  = @Notes,
                IsActive               = @IsActive,
                UpdatedAt              = SYSUTCDATETIME(),
                UpdatedBy              = @UserId
            WHERE VehicleId = @VehicleId;

            SET @VehicleIdOut = @VehicleId;
            SET @Resultado = 1;
        END
        ELSE
        BEGIN
            INSERT INTO fleet.Vehicle (
                CompanyId, VehiclePlate, VIN, Brand, Model, [Year], Color,
                VehicleType, FuelType, CurrentMileage, PurchaseDate, PurchaseCost,
                InsurancePolicy, InsuranceExpiry, TechnicalReviewExpiry, PermitExpiry,
                AssignedDriverId, AssignedBranchId, Notes, IsActive,
                CreatedAt, CreatedBy
            ) VALUES (
                @CompanyId, @VehiclePlate, @VIN, @Brand, @Model, @Year, @Color,
                @VehicleType, @FuelType, @CurrentMileage, @PurchaseDate, @PurchaseCost,
                @InsurancePolicy, @InsuranceExpiry, @TechnicalReviewExpiry, @PermitExpiry,
                @AssignedDriverId, @AssignedBranchId, @Notes, @IsActive,
                SYSUTCDATETIME(), @UserId
            );

            SET @VehicleIdOut = SCOPE_IDENTITY();
            SET @Resultado = 1;
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @VehicleIdOut = 0;
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 2: COMBUSTIBLE (Fuel Logs)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_FuelLog_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_FuelLog_List
    @CompanyId      INT,
    @VehicleId      INT = NULL,
    @FechaDesde     DATETIME2,
    @FechaHasta     DATETIME2,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*)
    FROM fleet.FuelLog fl
    INNER JOIN fleet.Vehicle v ON v.VehicleId = fl.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR fl.VehicleId = @VehicleId)
      AND fl.LogDate >= @FechaDesde
      AND fl.LogDate <= @FechaHasta;

    SELECT
        fl.FuelLogId,
        fl.VehicleId,
        v.VehiclePlate,
        fl.LogDate,
        fl.Mileage,
        fl.FuelType,
        fl.Liters,
        fl.PricePerLiter,
        fl.TotalCost,
        fl.StationName,
        fl.DriverId,
        fl.Notes,
        fl.CreatedAt
    FROM fleet.FuelLog fl
    INNER JOIN fleet.Vehicle v ON v.VehicleId = fl.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR fl.VehicleId = @VehicleId)
      AND fl.LogDate >= @FechaDesde
      AND fl.LogDate <= @FechaHasta
    ORDER BY fl.LogDate DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_FuelLog_Create
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_FuelLog_Create
    @CompanyId      INT,
    @VehicleId      INT,
    @LogDate        DATETIME2,
    @Mileage        DECIMAL(12,2),
    @FuelType       NVARCHAR(20),
    @Liters         DECIMAL(10,3),
    @PricePerLiter  DECIMAL(10,4),
    @TotalCost      DECIMAL(18,2),
    @StationName    NVARCHAR(100) = NULL,
    @DriverId       INT = NULL,
    @Notes          NVARCHAR(500) = NULL,
    @UserId         INT,
    @Resultado      INT OUTPUT,
    @FuelLogId      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO fleet.FuelLog (
            VehicleId, LogDate, Mileage, FuelType, Liters, PricePerLiter,
            TotalCost, StationName, DriverId, Notes, CreatedAt, CreatedBy
        ) VALUES (
            @VehicleId, @LogDate, @Mileage, @FuelType, @Liters, @PricePerLiter,
            @TotalCost, @StationName, @DriverId, @Notes, SYSUTCDATETIME(), @UserId
        );

        SET @FuelLogId = SCOPE_IDENTITY();

        -- Actualizar kilometraje si es mayor al actual
        UPDATE fleet.Vehicle
        SET CurrentMileage = @Mileage, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @UserId
        WHERE VehicleId = @VehicleId AND CurrentMileage < @Mileage;

        SET @Resultado = 1;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @FuelLogId = 0;
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 3: TIPOS DE MANTENIMIENTO
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceType_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceType_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MaintenanceTypeId,
        TypeCode,
        TypeName,
        Category,
        DefaultIntervalKm,
        DefaultIntervalDays,
        IsActive,
        CreatedAt
    FROM fleet.MaintenanceType
    WHERE CompanyId = @CompanyId
    ORDER BY TypeName;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceType_Upsert
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceType_Upsert
    @CompanyId              INT,
    @MaintenanceTypeId      INT = NULL,
    @TypeCode               NVARCHAR(20),
    @TypeName               NVARCHAR(100),
    @Category               NVARCHAR(50),
    @DefaultIntervalKm      DECIMAL(12,2) = NULL,
    @DefaultIntervalDays    INT = NULL,
    @IsActive               BIT = 1,
    @UserId                 INT,
    @Resultado              INT OUTPUT,
    @Mensaje                NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @MaintenanceTypeId IS NOT NULL AND EXISTS (SELECT 1 FROM fleet.MaintenanceType WHERE MaintenanceTypeId = @MaintenanceTypeId)
        BEGIN
            UPDATE fleet.MaintenanceType SET
                TypeCode            = @TypeCode,
                TypeName            = @TypeName,
                Category            = @Category,
                DefaultIntervalKm   = @DefaultIntervalKm,
                DefaultIntervalDays = @DefaultIntervalDays,
                IsActive            = @IsActive,
                UpdatedAt           = SYSUTCDATETIME(),
                UpdatedBy           = @UserId
            WHERE MaintenanceTypeId = @MaintenanceTypeId;

            SET @Resultado = 1;
            SET @Mensaje = N'Tipo de mantenimiento actualizado';
        END
        ELSE
        BEGIN
            INSERT INTO fleet.MaintenanceType (
                CompanyId, TypeCode, TypeName, Category,
                DefaultIntervalKm, DefaultIntervalDays, IsActive,
                CreatedAt, CreatedBy
            ) VALUES (
                @CompanyId, @TypeCode, @TypeName, @Category,
                @DefaultIntervalKm, @DefaultIntervalDays, @IsActive,
                SYSUTCDATETIME(), @UserId
            );

            SET @Resultado = 1;
            SET @Mensaje = N'Tipo de mantenimiento creado';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 4: ORDENES DE MANTENIMIENTO
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceOrder_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceOrder_List
    @CompanyId      INT,
    @VehicleId      INT = NULL,
    @Status         NVARCHAR(20) = NULL,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*)
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR mo.VehicleId = @VehicleId)
      AND (@Status IS NULL OR mo.[Status] = @Status);

    SELECT
        mo.MaintenanceOrderId,
        mo.OrderNumber,
        mo.VehicleId,
        v.VehiclePlate,
        mt.TypeName AS MaintenanceTypeName,
        mo.MileageAtService,
        mo.ScheduledDate,
        mo.EstimatedCost,
        mo.ActualCost,
        mo.CompletedDate,
        mo.[Status],
        mo.Description,
        mo.CreatedAt
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
    INNER JOIN fleet.MaintenanceType mt ON mt.MaintenanceTypeId = mo.MaintenanceTypeId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR mo.VehicleId = @VehicleId)
      AND (@Status IS NULL OR mo.[Status] = @Status)
    ORDER BY mo.ScheduledDate DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceOrder_Get
--  Detalle de orden + lineas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceOrder_Get
    @MaintenanceOrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    SELECT
        mo.MaintenanceOrderId,
        mo.OrderNumber,
        mo.VehicleId,
        v.VehiclePlate,
        v.Brand,
        v.Model,
        mt.TypeName AS MaintenanceTypeName,
        mt.Category,
        mo.MileageAtService,
        mo.ScheduledDate,
        mo.SupplierId,
        mo.EstimatedCost,
        mo.ActualCost,
        mo.CompletedDate,
        mo.[Status],
        mo.Description,
        mo.BranchId,
        mo.CreatedAt,
        mo.UpdatedAt
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
    INNER JOIN fleet.MaintenanceType mt ON mt.MaintenanceTypeId = mo.MaintenanceTypeId
    WHERE mo.MaintenanceOrderId = @MaintenanceOrderId;

    -- Lines
    SELECT
        mol.LineId,
        mol.Description AS LineDescription,
        mol.PartNumber,
        mol.Quantity,
        mol.UnitCost,
        mol.TotalCost,
        mol.LineType
    FROM fleet.MaintenanceOrderLine mol
    WHERE mol.MaintenanceOrderId = @MaintenanceOrderId
    ORDER BY mol.LineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceOrder_Create
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceOrder_Create
    @CompanyId          INT,
    @BranchId           INT,
    @VehicleId          INT,
    @MaintenanceTypeId  INT,
    @MileageAtService   DECIMAL(12,2),
    @ScheduledDate      DATETIME2,
    @SupplierId         INT = NULL,
    @EstimatedCost      DECIMAL(18,2),
    @Description        NVARCHAR(500),
    @LinesJson          NVARCHAR(MAX) = NULL,
    @UserId             INT,
    @Resultado          INT OUTPUT,
    @MaintenanceOrderId INT OUTPUT,
    @OrderNumber        NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Generar numero de orden
        DECLARE @Seq INT;
        SELECT @Seq = ISNULL(MAX(
            TRY_CAST(RIGHT(OrderNumber, LEN(OrderNumber) - 3) AS INT)
        ), 0) + 1
        FROM fleet.MaintenanceOrder
        WHERE VehicleId = @VehicleId;

        SET @OrderNumber = N'MO-' + RIGHT('000000' + CAST(@Seq AS NVARCHAR), 6);

        INSERT INTO fleet.MaintenanceOrder (
            CompanyId, BranchId, VehicleId, MaintenanceTypeId, OrderNumber,
            MileageAtService, ScheduledDate, SupplierId, EstimatedCost,
            Description, [Status], CreatedAt, CreatedBy
        ) VALUES (
            @CompanyId, @BranchId, @VehicleId, @MaintenanceTypeId, @OrderNumber,
            @MileageAtService, @ScheduledDate, @SupplierId, @EstimatedCost,
            @Description, N'PENDING', SYSUTCDATETIME(), @UserId
        );

        SET @MaintenanceOrderId = SCOPE_IDENTITY();

        -- Insertar lineas si vienen
        IF @LinesJson IS NOT NULL AND LEN(@LinesJson) > 2
        BEGIN
            INSERT INTO fleet.MaintenanceOrderLine (
                MaintenanceOrderId, Description, PartNumber, Quantity, UnitCost, TotalCost, LineType
            )
            SELECT
                @MaintenanceOrderId,
                j.[Description],
                j.PartNumber,
                j.Quantity,
                j.UnitCost,
                j.Quantity * j.UnitCost,
                j.LineType
            FROM OPENJSON(@LinesJson)
            WITH (
                [Description] NVARCHAR(200) '$.description',
                PartNumber    NVARCHAR(50)  '$.partNumber',
                Quantity      DECIMAL(10,2) '$.quantity',
                UnitCost      DECIMAL(18,2) '$.unitCost',
                LineType      NVARCHAR(20)  '$.lineType'
            ) j;
        END;

        SET @Resultado = 1;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @MaintenanceOrderId = 0;
        SET @OrderNumber = N'';
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceOrder_Complete
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceOrder_Complete
    @MaintenanceOrderId INT,
    @ActualCost         DECIMAL(18,2),
    @CompletedDate      DATETIME2,
    @UserId             INT,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceOrder WHERE MaintenanceOrderId = @MaintenanceOrderId AND [Status] IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS'))
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Orden no encontrada o no se puede completar';
        RETURN;
    END;

    UPDATE fleet.MaintenanceOrder SET
        ActualCost    = @ActualCost,
        CompletedDate = @CompletedDate,
        [Status]      = N'COMPLETED',
        UpdatedAt     = SYSUTCDATETIME(),
        UpdatedBy     = @UserId
    WHERE MaintenanceOrderId = @MaintenanceOrderId;

    SET @Resultado = 1;
    SET @Mensaje = N'Orden completada';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_MaintenanceOrder_Cancel
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_MaintenanceOrder_Cancel
    @MaintenanceOrderId INT,
    @UserId             INT,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceOrder WHERE MaintenanceOrderId = @MaintenanceOrderId AND [Status] IN ('PENDING', 'SCHEDULED'))
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Orden no encontrada o no se puede cancelar';
        RETURN;
    END;

    UPDATE fleet.MaintenanceOrder SET
        [Status]  = N'CANCELLED',
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @UserId
    WHERE MaintenanceOrderId = @MaintenanceOrderId;

    SET @Resultado = 1;
    SET @Mensaje = N'Orden cancelada';
END;
GO

-- =============================================================================
--  SECCION 5: VIAJES (Trips)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_Trip_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Trip_List
    @CompanyId      INT,
    @VehicleId      INT = NULL,
    @Status         NVARCHAR(20) = NULL,
    @FechaDesde     DATETIME2,
    @FechaHasta     DATETIME2,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*)
    FROM fleet.Trip t
    INNER JOIN fleet.Vehicle v ON v.VehicleId = t.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR t.VehicleId = @VehicleId)
      AND (@Status IS NULL OR t.[Status] = @Status)
      AND t.DepartureDate >= @FechaDesde
      AND t.DepartureDate <= @FechaHasta;

    SELECT
        t.TripId,
        t.TripNumber,
        t.VehicleId,
        v.VehiclePlate,
        t.DriverId,
        t.Origin,
        t.Destination,
        t.DepartureDate,
        t.ArrivalDate,
        t.StartMileage,
        t.EndMileage,
        t.FuelUsed,
        t.DeliveryNoteId,
        t.[Status],
        t.Notes,
        t.CreatedAt
    FROM fleet.Trip t
    INNER JOIN fleet.Vehicle v ON v.VehicleId = t.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND (@VehicleId IS NULL OR t.VehicleId = @VehicleId)
      AND (@Status IS NULL OR t.[Status] = @Status)
      AND t.DepartureDate >= @FechaDesde
      AND t.DepartureDate <= @FechaHasta
    ORDER BY t.DepartureDate DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_Trip_Create
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Trip_Create
    @CompanyId      INT,
    @VehicleId      INT,
    @DriverId       INT = NULL,
    @Origin         NVARCHAR(200),
    @Destination    NVARCHAR(200),
    @DepartureDate  DATETIME2,
    @StartMileage   DECIMAL(12,2),
    @DeliveryNoteId INT = NULL,
    @Notes          NVARCHAR(500) = NULL,
    @UserId         INT,
    @Resultado      INT OUTPUT,
    @TripId         INT OUTPUT,
    @TripNumber     NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Seq INT;
        SELECT @Seq = ISNULL(MAX(
            TRY_CAST(RIGHT(TripNumber, LEN(TripNumber) - 3) AS INT)
        ), 0) + 1
        FROM fleet.Trip t
        INNER JOIN fleet.Vehicle v ON v.VehicleId = t.VehicleId
        WHERE v.CompanyId = @CompanyId;

        SET @TripNumber = N'TR-' + RIGHT('000000' + CAST(@Seq AS NVARCHAR), 6);

        INSERT INTO fleet.Trip (
            VehicleId, DriverId, TripNumber, Origin, Destination,
            DepartureDate, StartMileage, DeliveryNoteId, Notes,
            [Status], CreatedAt, CreatedBy
        ) VALUES (
            @VehicleId, @DriverId, @TripNumber, @Origin, @Destination,
            @DepartureDate, @StartMileage, @DeliveryNoteId, @Notes,
            N'IN_PROGRESS', SYSUTCDATETIME(), @UserId
        );

        SET @TripId = SCOPE_IDENTITY();
        SET @Resultado = 1;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @TripId = 0;
        SET @TripNumber = N'';
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_Trip_Complete
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Trip_Complete
    @TripId         INT,
    @EndMileage     DECIMAL(12,2),
    @ArrivalDate    DATETIME2,
    @FuelUsed       DECIMAL(10,3) = NULL,
    @UserId         INT,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VehicleId INT;

    SELECT @VehicleId = VehicleId
    FROM fleet.Trip
    WHERE TripId = @TripId AND [Status] = N'IN_PROGRESS';

    IF @VehicleId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Viaje no encontrado o ya completado';
        RETURN;
    END;

    UPDATE fleet.Trip SET
        EndMileage   = @EndMileage,
        ArrivalDate  = @ArrivalDate,
        FuelUsed     = @FuelUsed,
        [Status]     = N'COMPLETED',
        UpdatedAt    = SYSUTCDATETIME(),
        UpdatedBy    = @UserId
    WHERE TripId = @TripId;

    -- Actualizar kilometraje del vehiculo
    UPDATE fleet.Vehicle
    SET CurrentMileage = @EndMileage, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @UserId
    WHERE VehicleId = @VehicleId AND CurrentMileage < @EndMileage;

    SET @Resultado = 1;
    SET @Mensaje = N'Viaje completado';
END;
GO

-- =============================================================================
--  SECCION 6: DOCUMENTOS DE VEHICULO
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_VehicleDocument_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_VehicleDocument_List
    @VehicleId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DocumentId,
        VehicleId,
        DocumentType,
        DocumentNumber,
        IssueDate,
        ExpiryDate,
        FilePath,
        Notes,
        CreatedAt
    FROM fleet.VehicleDocument
    WHERE VehicleId = @VehicleId
    ORDER BY ExpiryDate DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Fleet_VehicleDocument_Upsert
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_VehicleDocument_Upsert
    @CompanyId      INT,
    @DocumentId     INT = NULL,
    @VehicleId      INT,
    @DocumentType   NVARCHAR(50),
    @DocumentNumber NVARCHAR(50) = NULL,
    @IssueDate      DATETIME2,
    @ExpiryDate     DATETIME2 = NULL,
    @FilePath       NVARCHAR(500) = NULL,
    @Notes          NVARCHAR(500) = NULL,
    @UserId         INT,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @DocumentId IS NOT NULL AND EXISTS (SELECT 1 FROM fleet.VehicleDocument WHERE DocumentId = @DocumentId)
        BEGIN
            UPDATE fleet.VehicleDocument SET
                DocumentType   = @DocumentType,
                DocumentNumber = @DocumentNumber,
                IssueDate      = @IssueDate,
                ExpiryDate     = @ExpiryDate,
                FilePath       = @FilePath,
                Notes          = @Notes,
                UpdatedAt      = SYSUTCDATETIME(),
                UpdatedBy      = @UserId
            WHERE DocumentId = @DocumentId;

            SET @Resultado = 1;
            SET @Mensaje = N'Documento actualizado';
        END
        ELSE
        BEGIN
            INSERT INTO fleet.VehicleDocument (
                VehicleId, DocumentType, DocumentNumber, IssueDate, ExpiryDate,
                FilePath, Notes, CreatedAt, CreatedBy
            ) VALUES (
                @VehicleId, @DocumentType, @DocumentNumber, @IssueDate, @ExpiryDate,
                @FilePath, @Notes, SYSUTCDATETIME(), @UserId
            );

            SET @Resultado = 1;
            SET @Mensaje = N'Documento creado';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 7: ALERTAS
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_Alerts_Get
--  Documentos vencidos, por vencer (30d), mantenimientos vencidos, licencias.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Alerts_Get
    @CompanyId  INT,
    @BranchId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    DECLARE @In30Days DATETIME2 = DATEADD(DAY, 30, @Now);

    -- Conteos precalculados
    DECLARE @ExpiredDocs INT, @ExpiringSoonDocs INT, @OverdueMaint INT;

    SELECT @ExpiredDocs = COUNT(*)
    FROM fleet.VehicleDocument vd
    INNER JOIN fleet.Vehicle v ON v.VehicleId = vd.VehicleId
    WHERE v.CompanyId = @CompanyId AND v.IsActive = 1
      AND vd.ExpiryDate < @Now AND vd.ExpiryDate IS NOT NULL;

    SELECT @ExpiringSoonDocs = COUNT(*)
    FROM fleet.VehicleDocument vd
    INNER JOIN fleet.Vehicle v ON v.VehicleId = vd.VehicleId
    WHERE v.CompanyId = @CompanyId AND v.IsActive = 1
      AND vd.ExpiryDate >= @Now AND vd.ExpiryDate <= @In30Days;

    SELECT @OverdueMaint = COUNT(*)
    FROM fleet.MaintenanceOrder mo
    INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND mo.[Status] = N'SCHEDULED' AND mo.ScheduledDate < @Now;

    -- Recordset unico: todas las alertas unificadas
    SELECT * FROM (
        -- Documentos vencidos
        SELECT
            N'EXPIRED' AS AlertType,
            CAST(vd.DocumentId AS BIGINT) AS ItemId,
            CAST(vd.VehicleId AS BIGINT) AS VehicleId,
            v.VehiclePlate AS LicensePlate,
            v.Brand,
            v.Model,
            vd.DocumentType,
            vd.DocumentNumber,
            CAST(NULL AS NVARCHAR(100)) AS MaintenanceTypeName,
            CAST(NULL AS NVARCHAR(20)) AS OrderNumber,
            vd.ExpiryDate,
            CAST(NULL AS DATETIME2) AS ScheduledDate,
            DATEDIFF(DAY, vd.ExpiryDate, @Now) AS DaysOverdue,
            CAST(NULL AS INT) AS DaysUntilExpiry,
            @ExpiredDocs AS ExpiredDocsCount,
            @ExpiringSoonDocs AS ExpiringSoonDocsCount,
            @OverdueMaint AS OverdueMaintenanceCount
        FROM fleet.VehicleDocument vd
        INNER JOIN fleet.Vehicle v ON v.VehicleId = vd.VehicleId
        WHERE v.CompanyId = @CompanyId
          AND v.IsActive = 1
          AND vd.ExpiryDate < @Now
          AND vd.ExpiryDate IS NOT NULL

        UNION ALL

        -- Documentos por vencer (proximos 30 dias)
        SELECT
            N'EXPIRING_SOON',
            CAST(vd.DocumentId AS BIGINT),
            CAST(vd.VehicleId AS BIGINT),
            v.VehiclePlate,
            v.Brand,
            v.Model,
            vd.DocumentType,
            vd.DocumentNumber,
            NULL,
            NULL,
            vd.ExpiryDate,
            NULL,
            NULL,
            DATEDIFF(DAY, @Now, vd.ExpiryDate),
            @ExpiredDocs,
            @ExpiringSoonDocs,
            @OverdueMaint
        FROM fleet.VehicleDocument vd
        INNER JOIN fleet.Vehicle v ON v.VehicleId = vd.VehicleId
        WHERE v.CompanyId = @CompanyId
          AND v.IsActive = 1
          AND vd.ExpiryDate >= @Now
          AND vd.ExpiryDate <= @In30Days

        UNION ALL

        -- Mantenimientos vencidos
        SELECT
            N'MAINTENANCE_OVERDUE',
            CAST(mo.MaintenanceOrderId AS BIGINT),
            CAST(mo.VehicleId AS BIGINT),
            v.VehiclePlate,
            v.Brand,
            v.Model,
            NULL,
            NULL,
            mt.TypeName,
            mo.OrderNumber,
            NULL,
            mo.ScheduledDate,
            DATEDIFF(DAY, mo.ScheduledDate, @Now),
            NULL,
            @ExpiredDocs,
            @ExpiringSoonDocs,
            @OverdueMaint
        FROM fleet.MaintenanceOrder mo
        INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
        INNER JOIN fleet.MaintenanceType mt ON mt.MaintenanceTypeId = mo.MaintenanceTypeId
        WHERE v.CompanyId = @CompanyId
          AND mo.[Status] = N'SCHEDULED'
          AND mo.ScheduledDate < @Now
    ) AS alerts
    ORDER BY
        CASE AlertType
            WHEN 'EXPIRED' THEN 1
            WHEN 'EXPIRING_SOON' THEN 2
            WHEN 'MAINTENANCE_OVERDUE' THEN 3
        END,
        COALESCE(ExpiryDate, ScheduledDate);
END;
GO

-- =============================================================================
--  SECCION 8: REPORTES
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_Report_FuelMonthly
--  Consumo de combustible agrupado por vehiculo y mes.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Report_FuelMonthly
    @CompanyId  INT,
    @BranchId   INT = NULL,
    @Year       INT,
    @Month      INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        fl.VehicleId,
        v.VehiclePlate       AS LicensePlate,
        v.Brand,
        v.Model,
        ISNULL(SUM(fl.Liters), 0)         AS TotalLiters,
        ISNULL(SUM(fl.TotalCost), 0)      AS TotalCost,
        CASE
            WHEN SUM(fl.Liters) > 0 THEN SUM(fl.TotalCost) / SUM(fl.Liters)
            ELSE 0
        END                                AS AvgCostPerLiter
    FROM fleet.FuelLog fl
    INNER JOIN fleet.Vehicle v ON v.VehicleId = fl.VehicleId
    WHERE v.CompanyId = @CompanyId
      AND YEAR(fl.LogDate) = @Year
      AND MONTH(fl.LogDate) = @Month
    GROUP BY fl.VehicleId, v.VehiclePlate, v.Brand, v.Model
    ORDER BY v.VehiclePlate;
END;
GO

-- =============================================================================
--  SECCION 9: DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Fleet_Dashboard
--  KPIs: total vehiculos, docs por vencer, mant. pendiente, costo combustible mes
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Fleet_Dashboard
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    DECLARE @In30Days DATETIME2 = DATEADD(DAY, 30, @Now);
    DECLARE @MonthStart DATETIME2 = DATEFROMPARTS(YEAR(@Now), MONTH(@Now), 1);

    SELECT
        (SELECT COUNT(*) FROM fleet.Vehicle WHERE CompanyId = @CompanyId AND IsActive = 1) AS TotalActiveVehicles,
        (SELECT COUNT(*) FROM fleet.Vehicle WHERE CompanyId = @CompanyId) AS TotalVehicles,
        (SELECT COUNT(*) FROM fleet.VehicleDocument vd
         INNER JOIN fleet.Vehicle v ON v.VehicleId = vd.VehicleId
         WHERE v.CompanyId = @CompanyId AND vd.ExpiryDate <= @In30Days AND vd.ExpiryDate >= @Now
        ) AS DocsExpiringSoon,
        (SELECT COUNT(*) FROM fleet.MaintenanceOrder mo
         INNER JOIN fleet.Vehicle v ON v.VehicleId = mo.VehicleId
         WHERE v.CompanyId = @CompanyId AND mo.[Status] IN ('PENDING', 'SCHEDULED')
        ) AS MaintenancePending,
        (SELECT ISNULL(SUM(fl.TotalCost), 0) FROM fleet.FuelLog fl
         INNER JOIN fleet.Vehicle v ON v.VehicleId = fl.VehicleId
         WHERE v.CompanyId = @CompanyId AND fl.LogDate >= @MonthStart
        ) AS FuelCostThisMonth,
        (SELECT COUNT(*) FROM fleet.Trip t
         INNER JOIN fleet.Vehicle v ON v.VehicleId = t.VehicleId
         WHERE v.CompanyId = @CompanyId AND t.[Status] = 'IN_PROGRESS'
        ) AS ActiveTrips;
END;
GO
