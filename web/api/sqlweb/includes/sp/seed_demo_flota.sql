/*
 * seed_demo_flota.sql
 * ───────────────────
 * Seed de datos demo para el modulo de flota vehicular (fleet).
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   fleet.Vehicle, fleet.MaintenanceType, fleet.MaintenanceOrder,
 *   fleet.MaintenanceOrderLine, fleet.FuelLog, fleet.Trip,
 *   fleet.VehicleDocument
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: Flota Vehicular (fleet) ===';
GO

-- ============================================================================
-- SECCION 1: fleet.Vehicle  (4 vehiculos)
-- ============================================================================
PRINT '>> 1. Vehiculos...';

IF NOT EXISTS (SELECT 1 FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'ABC-123')
  INSERT INTO fleet.Vehicle (CompanyId, BranchId, LicensePlate, VehicleName, Brand, Model, Year, VehicleType, FuelType, CurrentMileage, Status, Color, VIN, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'ABC-123', N'Toyota Hilux 2024', N'Toyota', N'Hilux', 2024, N'TRUCK', N'DIESEL', 45000.00, N'ACTIVE', N'Blanco', N'JTFHX02P3M0000001', N'Vehiculo de carga liviana - uso logistica', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'DEF-456')
  INSERT INTO fleet.Vehicle (CompanyId, BranchId, LicensePlate, VehicleName, Brand, Model, Year, VehicleType, FuelType, CurrentMileage, Status, Color, VIN, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'DEF-456', N'Ford Fiesta 2023', N'Ford', N'Fiesta', 2023, N'CAR', N'GASOLINE', 28000.00, N'ACTIVE', N'Rojo', N'WF0XXXGCDXM000002', N'Vehiculo ejecutivo - uso gerencia', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'GHI-789')
  INSERT INTO fleet.Vehicle (CompanyId, BranchId, LicensePlate, VehicleName, Brand, Model, Year, VehicleType, FuelType, CurrentMileage, Status, Color, VIN, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'GHI-789', N'Chevrolet NHR 2022', N'Chevrolet', N'NHR', 2022, N'VAN', N'DIESEL', 85000.00, N'MAINTENANCE', N'Azul', N'9BGKT08DXNG000003', N'Camion de reparto - actualmente en taller', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'JKL-012')
  INSERT INTO fleet.Vehicle (CompanyId, BranchId, LicensePlate, VehicleName, Brand, Model, Year, VehicleType, FuelType, CurrentMileage, Status, Color, VIN, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'JKL-012', N'Honda CB150 2024', N'Honda', N'CB150 Invicta', 2024, N'MOTORCYCLE', N'GASOLINE', 12000.00, N'ACTIVE', N'Negro', N'MLHJC5170M5000004', N'Moto mensajeria - entregas rapidas', 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 2: fleet.MaintenanceType  (3 tipos)
-- ============================================================================
PRINT '>> 2. Tipos de mantenimiento...';

IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-ACE')
  INSERT INTO fleet.MaintenanceType (CompanyId, MaintenanceTypeCode, MaintenanceTypeName, Category, IntervalKm, IntervalDays, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'MT-ACE', N'Cambio de aceite', N'PREVENTIVE', 5000, 90, N'Cambio de aceite de motor y filtro', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-FRE')
  INSERT INTO fleet.MaintenanceType (CompanyId, MaintenanceTypeCode, MaintenanceTypeName, Category, IntervalKm, IntervalDays, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'MT-FRE', N'Revision de frenos', N'PREVENTIVE', 20000, 180, N'Revision de pastillas, discos y liquido de frenos', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-REP')
  INSERT INTO fleet.MaintenanceType (CompanyId, MaintenanceTypeCode, MaintenanceTypeName, Category, IntervalKm, IntervalDays, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, N'MT-REP', N'Reparacion general', N'CORRECTIVE', NULL, NULL, N'Reparacion correctiva segun diagnostico', 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 3: fleet.MaintenanceOrder + Lines  (3 ordenes)
-- ============================================================================
PRINT '>> 3. Ordenes de mantenimiento...';

DECLARE @VehToyota INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'ABC-123');
DECLARE @VehChev INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'GHI-789');
DECLARE @VehFord INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'DEF-456');
DECLARE @MTAce INT = (SELECT TOP 1 MaintenanceTypeId FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-ACE');
DECLARE @MTRep INT = (SELECT TOP 1 MaintenanceTypeId FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-REP');
DECLARE @MTFre INT = (SELECT TOP 1 MaintenanceTypeId FROM fleet.MaintenanceType WHERE CompanyId = 1 AND MaintenanceTypeCode = N'MT-FRE');

-- MNT-2026-001: Toyota, cambio aceite, COMPLETED
IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceOrder WHERE CompanyId = 1 AND MaintenanceOrderCode = N'MNT-2026-001')
BEGIN
  INSERT INTO fleet.MaintenanceOrder (CompanyId, BranchId, MaintenanceOrderCode, VehicleId, MaintenanceTypeId, Status, MileageAtService, TotalCost,
    ScheduledDate, CompletedDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'MNT-2026-001', @VehToyota, @MTAce, N'COMPLETED', 45000, 45.00,
    DATEADD(DAY, -10, SYSUTCDATETIME()), DATEADD(DAY, -10, SYSUTCDATETIME()),
    N'Cambio de aceite y filtro completado', 1, SYSUTCDATETIME());

  DECLARE @MntId1 INT = SCOPE_IDENTITY();

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId1, 10, N'Aceite motor 10W-40 4L', N'PART', 1, 25.00, 25.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId1, 20, N'Filtro de aceite', N'PART', 1, 8.00, 8.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId1, 30, N'Mano de obra cambio aceite', N'LABOR', 1, 12.00, 12.00);
END;

-- MNT-2026-002: Chevrolet, reparacion, IN_PROGRESS
IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceOrder WHERE CompanyId = 1 AND MaintenanceOrderCode = N'MNT-2026-002')
BEGIN
  INSERT INTO fleet.MaintenanceOrder (CompanyId, BranchId, MaintenanceOrderCode, VehicleId, MaintenanceTypeId, Status, MileageAtService, EstimatedCost,
    ScheduledDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'MNT-2026-002', @VehChev, @MTRep, N'IN_PROGRESS', 85000, 350.00,
    DATEADD(DAY, -3, SYSUTCDATETIME()),
    N'Reparacion de caja de cambios - diagnostico en curso', 1, SYSUTCDATETIME());

  DECLARE @MntId2 INT = SCOPE_IDENTITY();

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId2, 10, N'Kit reparacion caja cambios', N'PART', 1, 220.00, 220.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId2, 20, N'Aceite transmision', N'PART', 2, 15.00, 30.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId2, 30, N'Mano de obra mecanica', N'LABOR', 8, 12.50, 100.00);
END;

-- MNT-2026-003: Ford, revision frenos, SCHEDULED
IF NOT EXISTS (SELECT 1 FROM fleet.MaintenanceOrder WHERE CompanyId = 1 AND MaintenanceOrderCode = N'MNT-2026-003')
BEGIN
  INSERT INTO fleet.MaintenanceOrder (CompanyId, BranchId, MaintenanceOrderCode, VehicleId, MaintenanceTypeId, Status, MileageAtService, EstimatedCost,
    ScheduledDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'MNT-2026-003', @VehFord, @MTFre, N'SCHEDULED', 28000, 120.00,
    DATEADD(DAY, 5, SYSUTCDATETIME()),
    N'Revision preventiva de frenos programada', 1, SYSUTCDATETIME());

  DECLARE @MntId3 INT = SCOPE_IDENTITY();

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId3, 10, N'Pastillas de freno delanteras', N'PART', 1, 45.00, 45.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId3, 20, N'Liquido de frenos DOT4', N'PART', 1, 15.00, 15.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId3, 30, N'Mano de obra revision frenos', N'LABOR', 2, 12.50, 25.00);

  INSERT INTO fleet.MaintenanceOrderLine (MaintenanceOrderId, LineNumber, Description, LineType, Quantity, UnitPrice, TotalPrice)
  VALUES (@MntId3, 40, N'Rectificado de discos', N'LABOR', 1, 35.00, 35.00);
END;
GO

-- ============================================================================
-- SECCION 4: fleet.FuelLog  (8 registros, 2 por vehiculo)
-- ============================================================================
PRINT '>> 4. Registros de combustible...';

DECLARE @VToy INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'ABC-123');
DECLARE @VFor INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'DEF-456');
DECLARE @VChe INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'GHI-789');
DECLARE @VHon INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'JKL-012');

-- Toyota Hilux (diesel)
IF @VToy IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet.FuelLog WHERE VehicleId = @VToy)
BEGIN
  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VToy, DATEADD(DAY, -20, SYSUTCDATETIME()), 44200, 55.00, 0.85, 46.75, N'DIESEL', N'PDV Av. Bolivar', N'Tanque lleno', 1, SYSUTCDATETIME());

  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VToy, DATEADD(DAY, -5, SYSUTCDATETIME()), 45000, 52.00, 0.85, 44.20, N'DIESEL', N'PDV Autopista Regional', N'Tanque lleno', 1, SYSUTCDATETIME());
END;

-- Ford Fiesta (gasolina)
IF @VFor IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet.FuelLog WHERE VehicleId = @VFor)
BEGIN
  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VFor, DATEADD(DAY, -15, SYSUTCDATETIME()), 27500, 40.00, 0.50, 20.00, N'GASOLINE', N'Shell La Trinidad', N'Tanque lleno', 1, SYSUTCDATETIME());

  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VFor, DATEADD(DAY, -2, SYSUTCDATETIME()), 28000, 38.00, 0.50, 19.00, N'GASOLINE', N'PDV Chuao', N'Tanque lleno', 1, SYSUTCDATETIME());
END;

-- Chevrolet NHR (diesel)
IF @VChe IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet.FuelLog WHERE VehicleId = @VChe)
BEGIN
  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VChe, DATEADD(DAY, -25, SYSUTCDATETIME()), 83500, 70.00, 0.85, 59.50, N'DIESEL', N'PDV Zona Industrial', N'Tanque lleno antes de ruta', 1, SYSUTCDATETIME());

  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VChe, DATEADD(DAY, -8, SYSUTCDATETIME()), 85000, 68.00, 0.85, 57.80, N'DIESEL', N'PDV Av. Intercomunal', N'Ultimo tanqueo antes de taller', 1, SYSUTCDATETIME());
END;

-- Honda CB150 (gasolina)
IF @VHon IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet.FuelLog WHERE VehicleId = @VHon)
BEGIN
  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VHon, DATEADD(DAY, -12, SYSUTCDATETIME()), 11500, 12.00, 0.50, 6.00, N'GASOLINE', N'Shell Altamira', N'Tanque lleno', 1, SYSUTCDATETIME());

  INSERT INTO fleet.FuelLog (CompanyId, VehicleId, FuelDate, Mileage, Liters, PricePerLiter, TotalCost, FuelType, Station, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VHon, DATEADD(DAY, -1, SYSUTCDATETIME()), 12000, 11.50, 0.50, 5.75, N'GASOLINE', N'PDV El Rosal', N'Tanque lleno', 1, SYSUTCDATETIME());
END;
GO

-- ============================================================================
-- SECCION 5: fleet.Trip  (3 viajes)
-- ============================================================================
PRINT '>> 5. Viajes...';

DECLARE @VToy2 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'ABC-123');
DECLARE @VChe2 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'GHI-789');
DECLARE @VFor2 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'DEF-456');

IF NOT EXISTS (SELECT 1 FROM fleet.Trip WHERE CompanyId = 1 AND TripCode = N'TRIP-001')
  INSERT INTO fleet.Trip (CompanyId, BranchId, TripCode, VehicleId, Origin, Destination, Status, DistanceKm, FuelUsedLiters,
    DepartureDate, ArrivalDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'TRIP-001', @VToy2, N'Caracas', N'Valencia', N'COMPLETED', 180.00, 15.00,
    DATEADD(DAY, -7, SYSUTCDATETIME()), DATEADD(HOUR, -164, SYSUTCDATETIME()),
    N'Entrega de mercancia a cliente en Valencia', 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.Trip WHERE CompanyId = 1 AND TripCode = N'TRIP-002')
  INSERT INTO fleet.Trip (CompanyId, BranchId, TripCode, VehicleId, Origin, Destination, Status, DistanceKm, FuelUsedLiters,
    DepartureDate, ArrivalDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'TRIP-002', @VChe2, N'Caracas', N'Maracay', N'COMPLETED', 120.00, 12.00,
    DATEADD(DAY, -12, SYSUTCDATETIME()), DATEADD(DAY, -12, SYSUTCDATETIME()),
    N'Recoleccion de materia prima en Maracay', 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM fleet.Trip WHERE CompanyId = 1 AND TripCode = N'TRIP-003')
  INSERT INTO fleet.Trip (CompanyId, BranchId, TripCode, VehicleId, Origin, Destination, Status, DistanceKm, FuelUsedLiters,
    DepartureDate, ArrivalDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'TRIP-003', @VFor2, N'Caracas', N'Guarenas', N'PLANNED', 35.00, NULL,
    DATEADD(DAY, 3, SYSUTCDATETIME()), NULL,
    N'Visita a proveedor en Guarenas', 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 6: fleet.VehicleDocument  (4 documentos)
-- ============================================================================
PRINT '>> 6. Documentos de vehiculos...';

DECLARE @VToy3 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'ABC-123');
DECLARE @VFor3 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'DEF-456');
DECLARE @VChe3 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'GHI-789');
DECLARE @VHon3 INT = (SELECT TOP 1 VehicleId FROM fleet.Vehicle WHERE CompanyId = 1 AND LicensePlate = N'JKL-012');

-- Seguro Toyota (vigente)
IF NOT EXISTS (SELECT 1 FROM fleet.VehicleDocument WHERE CompanyId = 1 AND VehicleId = @VToy3 AND DocumentType = N'INSURANCE')
  INSERT INTO fleet.VehicleDocument (CompanyId, VehicleId, DocumentType, DocumentNumber, Description, IssueDate, ExpiryDate, Status, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VToy3, N'INSURANCE', N'POL-2026-44521', N'Poliza todo riesgo Seguros Caracas', DATEADD(MONTH, -6, SYSUTCDATETIME()), DATEADD(MONTH, 6, SYSUTCDATETIME()), N'ACTIVE', N'Cobertura amplia con deducible $200', 1, SYSUTCDATETIME());

-- Revision tecnica Ford (por vencer pronto - alerta)
IF NOT EXISTS (SELECT 1 FROM fleet.VehicleDocument WHERE CompanyId = 1 AND VehicleId = @VFor3 AND DocumentType = N'TECHNICAL_REVIEW')
  INSERT INTO fleet.VehicleDocument (CompanyId, VehicleId, DocumentType, DocumentNumber, Description, IssueDate, ExpiryDate, Status, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VFor3, N'TECHNICAL_REVIEW', N'RTV-2025-78903', N'Revision tecnica vehicular INTT', DATEADD(YEAR, -1, SYSUTCDATETIME()), DATEADD(DAY, 10, SYSUTCDATETIME()), N'ACTIVE', N'Vence pronto - programar renovacion', 1, SYSUTCDATETIME());

-- Seguro Chevrolet (por vencer - alerta critica)
IF NOT EXISTS (SELECT 1 FROM fleet.VehicleDocument WHERE CompanyId = 1 AND VehicleId = @VChe3 AND DocumentType = N'INSURANCE')
  INSERT INTO fleet.VehicleDocument (CompanyId, VehicleId, DocumentType, DocumentNumber, Description, IssueDate, ExpiryDate, Status, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VChe3, N'INSURANCE', N'POL-2025-33210', N'Poliza responsabilidad civil Mapfre', DATEADD(YEAR, -1, SYSUTCDATETIME()), DATEADD(DAY, 5, SYSUTCDATETIME()), N'ACTIVE', N'URGENTE: vence en 5 dias - vehiculo en taller', 1, SYSUTCDATETIME());

-- Revision tecnica Honda (vigente)
IF NOT EXISTS (SELECT 1 FROM fleet.VehicleDocument WHERE CompanyId = 1 AND VehicleId = @VHon3 AND DocumentType = N'TECHNICAL_REVIEW')
  INSERT INTO fleet.VehicleDocument (CompanyId, VehicleId, DocumentType, DocumentNumber, Description, IssueDate, ExpiryDate, Status, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, @VHon3, N'TECHNICAL_REVIEW', N'RTV-2026-12045', N'Revision tecnica vehicular INTT', DATEADD(MONTH, -2, SYSUTCDATETIME()), DATEADD(MONTH, 10, SYSUTCDATETIME()), N'ACTIVE', N'Vigente hasta diciembre 2026', 1, SYSUTCDATETIME());
GO

PRINT '=== Seed flota vehicular completado ===';
GO
