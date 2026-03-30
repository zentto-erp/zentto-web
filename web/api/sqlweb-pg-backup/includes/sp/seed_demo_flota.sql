/*
 * seed_demo_flota.sql (PostgreSQL)
 * ─────────────────────────────────
 * Seed de datos demo para el modulo de flota vehicular (fleet).
 * Idempotente: ON CONFLICT DO NOTHING / WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   fleet."Vehicle", fleet."MaintenanceType", fleet."MaintenanceOrder",
 *   fleet."MaintenanceOrderLine", fleet."FuelLog", fleet."Trip"
 */

DO $$
DECLARE
  v_veh_toyota BIGINT;
  v_veh_ford   BIGINT;
  v_veh_chev   BIGINT;
  v_veh_honda  BIGINT;
  v_mt_ace     BIGINT;
  v_mt_rep     BIGINT;
  v_mt_fre     BIGINT;
  v_mnt_id     BIGINT;
BEGIN
  RAISE NOTICE '=== Seed demo: Flota Vehicular (fleet) ===';

  -- ============================================================================
  -- SECCION 1: fleet."Vehicle"  (4 vehiculos)
  -- ============================================================================
  RAISE NOTICE '>> 1. Vehiculos...';

  INSERT INTO fleet."Vehicle" ("CompanyId", "VehicleCode", "LicensePlate", "Brand", "Model", "Year", "VehicleType", "FuelType", "CurrentOdometer", "Status", "Color", "VinNumber", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'VEH-001', 'ABC-123', 'Toyota', 'Hilux', 2024, 'TRUCK', 'DIESEL', 45000.00, 'ACTIVE', 'Blanco', 'JTFHX02P3M0000001', 'Vehiculo de carga liviana - uso logistica', TRUE, 1)
  ON CONFLICT ("CompanyId", "LicensePlate") DO NOTHING;

  INSERT INTO fleet."Vehicle" ("CompanyId", "VehicleCode", "LicensePlate", "Brand", "Model", "Year", "VehicleType", "FuelType", "CurrentOdometer", "Status", "Color", "VinNumber", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'VEH-002', 'DEF-456', 'Ford', 'Fiesta', 2023, 'CAR', 'GASOLINE', 28000.00, 'ACTIVE', 'Rojo', 'WF0XXXGCDXM000002', 'Vehiculo ejecutivo - uso gerencia', TRUE, 1)
  ON CONFLICT ("CompanyId", "LicensePlate") DO NOTHING;

  INSERT INTO fleet."Vehicle" ("CompanyId", "VehicleCode", "LicensePlate", "Brand", "Model", "Year", "VehicleType", "FuelType", "CurrentOdometer", "Status", "Color", "VinNumber", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'VEH-003', 'GHI-789', 'Chevrolet', 'NHR', 2022, 'VAN', 'DIESEL', 85000.00, 'IN_MAINTENANCE', 'Azul', '9BGKT08DXNG000003', 'Camion de reparto - actualmente en taller', TRUE, 1)
  ON CONFLICT ("CompanyId", "LicensePlate") DO NOTHING;

  INSERT INTO fleet."Vehicle" ("CompanyId", "VehicleCode", "LicensePlate", "Brand", "Model", "Year", "VehicleType", "FuelType", "CurrentOdometer", "Status", "Color", "VinNumber", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'VEH-004', 'JKL-012', 'Honda', 'CB150 Invicta', 2024, 'MOTORCYCLE', 'GASOLINE', 12000.00, 'ACTIVE', 'Negro', 'MLHJC5170M5000004', 'Moto mensajeria - entregas rapidas', TRUE, 1)
  ON CONFLICT ("CompanyId", "LicensePlate") DO NOTHING;

  SELECT "VehicleId" INTO v_veh_toyota FROM fleet."Vehicle" WHERE "CompanyId" = 1 AND "LicensePlate" = 'ABC-123' LIMIT 1;
  SELECT "VehicleId" INTO v_veh_ford   FROM fleet."Vehicle" WHERE "CompanyId" = 1 AND "LicensePlate" = 'DEF-456' LIMIT 1;
  SELECT "VehicleId" INTO v_veh_chev   FROM fleet."Vehicle" WHERE "CompanyId" = 1 AND "LicensePlate" = 'GHI-789' LIMIT 1;
  SELECT "VehicleId" INTO v_veh_honda  FROM fleet."Vehicle" WHERE "CompanyId" = 1 AND "LicensePlate" = 'JKL-012' LIMIT 1;

  -- ============================================================================
  -- SECCION 2: fleet."MaintenanceType"  (3 tipos)
  -- ============================================================================
  RAISE NOTICE '>> 2. Tipos de mantenimiento...';

  INSERT INTO fleet."MaintenanceType" ("CompanyId", "TypeCode", "TypeName", "Category", "DefaultIntervalKm", "DefaultIntervalDays", "IsActive", "CreatedByUserId")
  VALUES (1, 'MT-ACE', 'Cambio de aceite', 'PREVENTIVE', 5000, 90, TRUE, 1)
  ON CONFLICT ("CompanyId", "TypeCode") DO NOTHING;

  INSERT INTO fleet."MaintenanceType" ("CompanyId", "TypeCode", "TypeName", "Category", "DefaultIntervalKm", "DefaultIntervalDays", "IsActive", "CreatedByUserId")
  VALUES (1, 'MT-FRE', 'Revision de frenos', 'PREVENTIVE', 20000, 180, TRUE, 1)
  ON CONFLICT ("CompanyId", "TypeCode") DO NOTHING;

  INSERT INTO fleet."MaintenanceType" ("CompanyId", "TypeCode", "TypeName", "Category", "IsActive", "CreatedByUserId")
  VALUES (1, 'MT-REP', 'Reparacion general', 'CORRECTIVE', TRUE, 1)
  ON CONFLICT ("CompanyId", "TypeCode") DO NOTHING;

  SELECT "MaintenanceTypeId" INTO v_mt_ace FROM fleet."MaintenanceType" WHERE "CompanyId" = 1 AND "TypeCode" = 'MT-ACE' LIMIT 1;
  SELECT "MaintenanceTypeId" INTO v_mt_rep FROM fleet."MaintenanceType" WHERE "CompanyId" = 1 AND "TypeCode" = 'MT-REP' LIMIT 1;
  SELECT "MaintenanceTypeId" INTO v_mt_fre FROM fleet."MaintenanceType" WHERE "CompanyId" = 1 AND "TypeCode" = 'MT-FRE' LIMIT 1;

  -- ============================================================================
  -- SECCION 3: fleet."MaintenanceOrder" + Lines  (3 ordenes)
  -- ============================================================================
  RAISE NOTICE '>> 3. Ordenes de mantenimiento...';

  -- MNT-2026-001: Toyota, cambio aceite, COMPLETED
  IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-001') THEN
    INSERT INTO fleet."MaintenanceOrder" ("CompanyId", "VehicleId", "MaintenanceTypeId", "OrderNumber", "Status",
      "OdometerAtService", "TotalCost", "ScheduledDate", "CompletedAt", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_toyota, v_mt_ace, 'MNT-2026-001', 'COMPLETED', 45000, 45.00,
      (NOW() AT TIME ZONE 'UTC') - INTERVAL '10 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '10 days',
      'Cambio de aceite y filtro completado', 1);

    SELECT "MaintenanceOrderId" INTO v_mnt_id FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-001' LIMIT 1;

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 10, 'Aceite motor 10W-40 4L', 'PART', 1, 25.00, 25.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 20, 'Filtro de aceite', 'PART', 1, 8.00, 8.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 30, 'Mano de obra cambio aceite', 'LABOR', 1, 12.00, 12.00);
  END IF;

  -- MNT-2026-002: Chevrolet, reparacion, IN_PROGRESS
  IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-002') THEN
    INSERT INTO fleet."MaintenanceOrder" ("CompanyId", "VehicleId", "MaintenanceTypeId", "OrderNumber", "Status",
      "OdometerAtService", "ScheduledDate", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_chev, v_mt_rep, 'MNT-2026-002', 'IN_PROGRESS', 85000,
      (NOW() AT TIME ZONE 'UTC') - INTERVAL '3 days',
      'Reparacion de caja de cambios - diagnostico en curso', 1);

    SELECT "MaintenanceOrderId" INTO v_mnt_id FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-002' LIMIT 1;

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 10, 'Kit reparacion caja cambios', 'PART', 1, 220.00, 220.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 20, 'Aceite transmision', 'PART', 2, 15.00, 30.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 30, 'Mano de obra mecanica', 'LABOR', 8, 12.50, 100.00);
  END IF;

  -- MNT-2026-003: Ford, revision frenos, SCHEDULED
  IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-003') THEN
    INSERT INTO fleet."MaintenanceOrder" ("CompanyId", "VehicleId", "MaintenanceTypeId", "OrderNumber", "Status",
      "OdometerAtService", "ScheduledDate", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_ford, v_mt_fre, 'MNT-2026-003', 'SCHEDULED', 28000,
      (NOW() AT TIME ZONE 'UTC') + INTERVAL '5 days',
      'Revision preventiva de frenos programada', 1);

    SELECT "MaintenanceOrderId" INTO v_mnt_id FROM fleet."MaintenanceOrder" WHERE "CompanyId" = 1 AND "OrderNumber" = 'MNT-2026-003' LIMIT 1;

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 10, 'Pastillas de freno delanteras', 'PART', 1, 45.00, 45.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 20, 'Liquido de frenos DOT4', 'PART', 1, 15.00, 15.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 30, 'Mano de obra revision frenos', 'LABOR', 2, 12.50, 25.00);

    INSERT INTO fleet."MaintenanceOrderLine" ("MaintenanceOrderId", "LineNumber", "Description", "LineType", "Quantity", "UnitCost", "TotalCost")
    VALUES (v_mnt_id, 40, 'Rectificado de discos', 'LABOR', 1, 35.00, 35.00);
  END IF;

  -- ============================================================================
  -- SECCION 4: fleet."FuelLog"  (8 registros, 2 por vehiculo)
  -- ============================================================================
  RAISE NOTICE '>> 4. Registros de combustible...';

  IF v_veh_toyota IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet."FuelLog" WHERE "VehicleId" = v_veh_toyota) THEN
    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_toyota, (NOW() AT TIME ZONE 'UTC') - INTERVAL '20 days', 44200, 55.000, 0.85, 46.75, 'DIESEL', 'PDV Av. Bolivar', 'Tanque lleno', 1);

    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_toyota, (NOW() AT TIME ZONE 'UTC') - INTERVAL '5 days', 45000, 52.000, 0.85, 44.20, 'DIESEL', 'PDV Autopista Regional', 'Tanque lleno', 1);
  END IF;

  IF v_veh_ford IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet."FuelLog" WHERE "VehicleId" = v_veh_ford) THEN
    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_ford, (NOW() AT TIME ZONE 'UTC') - INTERVAL '15 days', 27500, 40.000, 0.50, 20.00, 'GASOLINE', 'Shell La Trinidad', 'Tanque lleno', 1);

    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_ford, (NOW() AT TIME ZONE 'UTC') - INTERVAL '2 days', 28000, 38.000, 0.50, 19.00, 'GASOLINE', 'PDV Chuao', 'Tanque lleno', 1);
  END IF;

  IF v_veh_chev IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet."FuelLog" WHERE "VehicleId" = v_veh_chev) THEN
    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_chev, (NOW() AT TIME ZONE 'UTC') - INTERVAL '25 days', 83500, 70.000, 0.85, 59.50, 'DIESEL', 'PDV Zona Industrial', 'Tanque lleno antes de ruta', 1);

    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_chev, (NOW() AT TIME ZONE 'UTC') - INTERVAL '8 days', 85000, 68.000, 0.85, 57.80, 'DIESEL', 'PDV Av. Intercomunal', 'Ultimo tanqueo antes de taller', 1);
  END IF;

  IF v_veh_honda IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fleet."FuelLog" WHERE "VehicleId" = v_veh_honda) THEN
    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_honda, (NOW() AT TIME ZONE 'UTC') - INTERVAL '12 days', 11500, 12.000, 0.50, 6.00, 'GASOLINE', 'Shell Altamira', 'Tanque lleno', 1);

    INSERT INTO fleet."FuelLog" ("CompanyId", "VehicleId", "FuelDate", "OdometerReading", "Quantity", "UnitPrice", "TotalCost", "FuelType", "StationName", "Notes", "CreatedByUserId")
    VALUES (1, v_veh_honda, (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 day', 12000, 11.500, 0.50, 5.75, 'GASOLINE', 'PDV El Rosal', 'Tanque lleno', 1);
  END IF;

  -- ============================================================================
  -- SECCION 5: fleet."Trip"  (3 viajes)
  -- ============================================================================
  RAISE NOTICE '>> 5. Viajes...';

  INSERT INTO fleet."Trip" ("CompanyId", "VehicleId", "TripNumber", "TripDate", "Origin", "Destination", "Status", "DistanceKm",
    "DepartedAt", "ArrivedAt", "Notes", "CreatedByUserId")
  SELECT 1, v_veh_toyota, 'TRIP-001', (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days',
    'Caracas', 'Valencia', 'COMPLETED', 180.00,
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '164 hours',
    'Entrega de mercancia a cliente en Valencia', 1
  WHERE NOT EXISTS (SELECT 1 FROM fleet."Trip" WHERE "CompanyId" = 1 AND "TripNumber" = 'TRIP-001');

  INSERT INTO fleet."Trip" ("CompanyId", "VehicleId", "TripNumber", "TripDate", "Origin", "Destination", "Status", "DistanceKm",
    "DepartedAt", "ArrivedAt", "Notes", "CreatedByUserId")
  SELECT 1, v_veh_chev, 'TRIP-002', (NOW() AT TIME ZONE 'UTC') - INTERVAL '12 days',
    'Caracas', 'Maracay', 'COMPLETED', 120.00,
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '12 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '12 days',
    'Recoleccion de materia prima en Maracay', 1
  WHERE NOT EXISTS (SELECT 1 FROM fleet."Trip" WHERE "CompanyId" = 1 AND "TripNumber" = 'TRIP-002');

  INSERT INTO fleet."Trip" ("CompanyId", "VehicleId", "TripNumber", "TripDate", "Origin", "Destination", "Status", "DistanceKm",
    "Notes", "CreatedByUserId")
  SELECT 1, v_veh_ford, 'TRIP-003', (NOW() AT TIME ZONE 'UTC') + INTERVAL '3 days',
    'Caracas', 'Guarenas', 'PLANNED', 35.00,
    'Visita a proveedor en Guarenas', 1
  WHERE NOT EXISTS (SELECT 1 FROM fleet."Trip" WHERE "CompanyId" = 1 AND "TripNumber" = 'TRIP-003');

  RAISE NOTICE '=== Seed flota vehicular completado ===';
END $$;
