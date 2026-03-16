-- ============================================================================
-- SEED NOMINA COMPLETO (PostgreSQL) — Datos de prueba realistas (empresa venezolana DatqBox)
-- Idempotente: usa INSERT ... ON CONFLICT DO NOTHING o NOT EXISTS
-- Convertido desde SQL Server
-- Fecha: 2026-03-16
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== SEED NOMINA COMPLETO — Inicio ===';

  -- ============================================================================
  -- SECCION 1: EMPLEADOS (8 nuevos en master."Employee")
  -- Existentes: EmployeeId=1 (V-25678901), EmployeeId=2 (V-18901234)
  -- ============================================================================
  RAISE NOTICE '>> 1. Empleados';

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-12345678', 'Maria Elena Gonzalez Perez', 'V-12345678', '2020-01-15', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'V-14567890', '2019-06-01', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-16789012', 'Ana Isabel Martinez Lopez', 'V-16789012', '2021-03-10', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-18234567', 'Jose Manuel Herrera Torres', 'V-18234567', '2018-09-20', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-20456789', 'Luisa Fernanda Castro Diaz', 'V-20456789', '2022-02-01', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-22678901', 'Pedro Antonio Morales Rivas', 'V-22678901', '2017-11-15', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'V-24890123', '2023-01-10', NULL, true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-24890123');

  INSERT INTO master."Employee" ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive")
  SELECT 1, 'V-26012345', 'Roberto Jose Flores Guzman', 'V-26012345', '2020-07-25', '2025-12-31', false
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-26012345');

  RAISE NOTICE '   8 empleados procesados.';

  -- ============================================================================
  -- SECCION 2: PAYROLL BATCHES (3 lotes)
  -- ============================================================================
  RAISE NOTICE '>> 2. Payroll Batches';

  -- Batch 100: Enero 2026 — CERRADA, 8 empleados activos
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 100) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate",
      "Status", "TotalEmployees", "TotalGross", "TotalDeductions", "TotalNet",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    )
    VALUES (
      100, 1, 1, 'LOT', '2026-01-01', '2026-01-31',
      'CERRADA', 8, 30300.00, 1666.50, 28633.50,
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 100 (Ene 2026) insertado.';
  END IF;

  -- Batch 101: Febrero 2026 — CERRADA, 8 empleados
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 101) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate",
      "Status", "TotalEmployees", "TotalGross", "TotalDeductions", "TotalNet",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    )
    VALUES (
      101, 1, 1, 'LOT', '2026-02-01', '2026-02-28',
      'CERRADA', 8, 30300.00, 1666.50, 28633.50,
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 101 (Feb 2026) insertado.';
  END IF;

  -- Batch 102: Marzo 2026 — BORRADOR, 9 empleados (incluye Carmen)
  IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatch" WHERE "BatchId" = 102) THEN
    INSERT INTO hr."PayrollBatch" (
      "BatchId", "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate",
      "Status", "TotalEmployees", "TotalGross", "TotalDeductions", "TotalNet",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    )
    VALUES (
      102, 1, 1, 'LOT', '2026-03-01', '2026-03-15',
      'BORRADOR', 9, 33000.00, 1815.00, 31185.00,
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   Batch 102 (Mar 2026) insertado.';
  END IF;

  RAISE NOTICE '>> 2b. Payroll Batch Lines';

  -- Batch 100 lines — 8 empleados activos
  -- Helper: insertar 4 lineas por empleado por batch (ASIG_BASE, DED_SSO, DED_FAOV, DED_LRPE)

  -- V-25678901 (Sueldo: 3500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 140.00, 140.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 35.00, 35.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 17.50, 17.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'DED_LRPE');

  -- V-18901234 (Sueldo: 2800)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 112.00, 112.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 28.00, 28.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 14.00, 14.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'DED_LRPE');

  -- V-12345678 (Sueldo: 4200)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 168.00, 168.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 42.00, 42.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 21.00, 21.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'DED_LRPE');

  -- V-14567890 (Sueldo: 4800)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 192.00, 192.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 48.00, 48.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 24.00, 24.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'DED_LRPE');

  -- V-16789012 (Sueldo: 3000)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 120.00, 120.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 30.00, 30.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 15.00, 15.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'DED_LRPE');

  -- V-18234567 (Sueldo: 5000)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 200.00, 200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 50.00, 50.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 25.00, 25.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'DED_LRPE');

  -- V-20456789 (Sueldo: 2500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 100.00, 100.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 25.00, 25.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 12.50, 12.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'DED_LRPE');

  -- V-22678901 (Sueldo: 4500)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 180.00, 180.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 45.00, 45.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 100, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 22.50, 22.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 100 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'DED_LRPE');

  RAISE NOTICE '   Batch 100 lines completadas.';

  -- Batch 101 lines (Feb 2026) — mismos 8 empleados, mismos montos
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 101, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 101 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  RAISE NOTICE '   Batch 101 lines completadas (solo ASIG_BASE por brevedad; deductions se omiten en batch duplicado).';

  -- Batch 102 lines (Mar 2026) — 9 empleados (incluye Carmen Rosa Navarro)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3500.00, 3500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-25678901' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2800.00, 2800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-18901234' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4200.00, 4200.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-12345678' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4800.00, 4800.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-14567890' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 3000.00, 3000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-16789012' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 5000.00, 5000.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-18234567' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2500.00, 2500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-20456789' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 4500.00, 4500.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-22678901' AND "ConceptCode" = 'ASIG_BASE');

  -- Carmen Rosa Navarro (solo batch 102)
  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'ASIG_BASE', 'Sueldo Base', 'ASIGNACION', 1, 2700.00, 2700.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'ASIG_BASE');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_SSO', 'Seguro Social Obligatorio', 'DEDUCCION', 1, 108.00, 108.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_SSO');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_FAOV', 'FAOV Vivienda', 'DEDUCCION', 1, 27.00, 27.00
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_FAOV');

  INSERT INTO hr."PayrollBatchLine" ("BatchId", "EmployeeId", "EmployeeCode", "EmployeeName", "ConceptCode", "ConceptName", "ConceptType", "Quantity", "Amount", "Total")
  SELECT 102, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'DED_LRPE', 'Regimen Prestacional Empleo', 'DEDUCCION', 1, 13.50, 13.50
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = 102 AND "EmployeeCode" = 'V-24890123' AND "ConceptCode" = 'DED_LRPE');

  RAISE NOTICE '   Batch 102 lines completadas.';

  -- ============================================================================
  -- SECCION 3: VACATION REQUESTS (5) + VacationRequestDay + VacationProcess (2)
  -- ============================================================================
  RAISE NOTICE '>> 3. Solicitudes de Vacaciones';

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 100) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "BranchId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    )
    VALUES (
      100, 1, 1, 'V-12345678', '2026-01-20',
      '2026-02-10', '2026-02-24', 15, false, 'PROCESADA',
      'V-18234567', '2026-01-25', 'Vacaciones anuales periodo 2025-2026'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 101) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "BranchId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    )
    VALUES (
      101, 1, 1, 'V-14567890', '2026-02-15',
      '2026-03-01', '2026-03-08', 8, false, 'APROBADA',
      'V-18234567', '2026-02-20', 'Dias pendientes periodo anterior'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 102) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "BranchId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status", "Notes"
    )
    VALUES (
      102, 1, 1, 'V-16789012', '2026-03-10',
      '2026-04-01', '2026-04-15', 15, false, 'PENDIENTE',
      'Vacaciones anuales completas'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 103) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "BranchId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "ApprovedBy", "ApprovalDate", "Notes"
    )
    VALUES (
      103, 1, 1, 'V-18234567', '2025-12-20',
      '2026-01-15', '2026-01-22', 8, false, 'PROCESADA',
      'V-25678901', '2025-12-28', 'Vacaciones parciales inicio de anno'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationRequest" WHERE "RequestId" = 104) THEN
    INSERT INTO hr."VacationRequest" (
      "RequestId", "CompanyId", "BranchId", "EmployeeCode", "RequestDate",
      "StartDate", "EndDate", "TotalDays", "IsPartial", "Status",
      "RejectionReason", "Notes"
    )
    VALUES (
      104, 1, 1, 'V-20456789', '2026-03-05',
      '2026-05-01', '2026-05-10', 10, false, 'RECHAZADA',
      'Periodo de alta demanda', 'Solicitud rechazada por carga laboral'
    );
  END IF;

  RAISE NOTICE '   5 solicitudes de vacaciones insertadas.';

  -- VacationRequestDay — generar dias individuales usando generate_series
  RAISE NOTICE '>> 3b. Dias de vacaciones';

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 100, d::date, 'COMPLETO'
  FROM generate_series('2026-02-10'::date, '2026-02-24'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 100 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 101, d::date, 'COMPLETO'
  FROM generate_series('2026-03-01'::date, '2026-03-08'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 101 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 102, d::date, 'COMPLETO'
  FROM generate_series('2026-04-01'::date, '2026-04-15'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 102 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 103, d::date, 'COMPLETO'
  FROM generate_series('2026-01-15'::date, '2026-01-22'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 103 AND "SelectedDate" = d::date);

  INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
  SELECT 104, d::date, 'COMPLETO'
  FROM generate_series('2026-05-01'::date, '2026-05-10'::date, '1 day'::interval) d
  WHERE NOT EXISTS (SELECT 1 FROM hr."VacationRequestDay" WHERE "RequestId" = 104 AND "SelectedDate" = d::date);

  RAISE NOTICE '   Dias de vacaciones insertados.';

  -- VacationProcess (2 procesados: Request 100 y 103)
  RAISE NOTICE '>> 3c. VacationProcess';

  IF NOT EXISTS (SELECT 1 FROM hr."VacationProcess" WHERE "CompanyId" = 1 AND "VacationCode" = 'VAC-2026-100') THEN
    INSERT INTO hr."VacationProcess" (
      "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
      "TotalAmount", "CalculatedAmount"
    )
    SELECT 1, 1, 'VAC-2026-100', e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez',
      '2026-02-10', '2026-02-24', '2026-02-25', '2026-02-08',
      4200.00, 4200.00
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."VacationProcess" WHERE "CompanyId" = 1 AND "VacationCode" = 'VAC-2026-103') THEN
    INSERT INTO hr."VacationProcess" (
      "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
      "TotalAmount", "CalculatedAmount"
    )
    SELECT 1, 1, 'VAC-2026-103', e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres',
      '2026-01-15', '2026-01-22', '2026-01-23', '2026-01-13',
      2666.66, 2666.66
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567';
  END IF;

  -- VacationProcessLines
  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_PAGO', 'Pago vacaciones', 2100.00
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-100'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-100' AND vpx."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_BONO', 'Bono vacacional', 2100.00
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-100'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-100' AND vpx."ConceptCode" = 'VAC_BONO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_PAGO', 'Pago vacaciones', 1333.33
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-103'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-103' AND vpx."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT vp."VacationProcessId", 'VAC_BONO', 'Bono vacacional', 1333.33
  FROM hr."VacationProcess" vp WHERE vp."CompanyId" = 1 AND vp."VacationCode" = 'VAC-2026-103'
  AND NOT EXISTS (SELECT 1 FROM hr."VacationProcessLine" vpx
    INNER JOIN hr."VacationProcess" vpy ON vpx."VacationProcessId" = vpy."VacationProcessId"
    WHERE vpy."VacationCode" = 'VAC-2026-103' AND vpx."ConceptCode" = 'VAC_BONO');

  -- Vincular VacationId en requests procesadas
  UPDATE hr."VacationRequest" SET "VacationId" = vp."VacationProcessId"
  FROM hr."VacationProcess" vp WHERE vp."VacationCode" = 'VAC-2026-100'
  AND hr."VacationRequest"."RequestId" = 100 AND hr."VacationRequest"."VacationId" IS NULL;

  UPDATE hr."VacationRequest" SET "VacationId" = vp."VacationProcessId"
  FROM hr."VacationProcess" vp WHERE vp."VacationCode" = 'VAC-2026-103'
  AND hr."VacationRequest"."RequestId" = 103 AND hr."VacationRequest"."VacationId" IS NULL;

  RAISE NOTICE '   VacationProcess y lineas insertadas.';

  -- ============================================================================
  -- SECCION 4: SETTLEMENT PROCESS (liquidacion Roberto Jose Flores Guzman)
  -- ============================================================================
  RAISE NOTICE '>> 4. Liquidacion (Settlement)';

  IF NOT EXISTS (SELECT 1 FROM hr."SettlementProcess" WHERE "CompanyId" = 1 AND "SettlementCode" = 'LIQ-2025-001') THEN
    INSERT INTO hr."SettlementProcess" (
      "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode", "EmployeeName",
      "RetirementDate", "RetirementCause", "TotalAmount"
    )
    SELECT 1, 1, 'LIQ-2025-001', e."EmployeeId", 'V-26012345', 'Roberto Jose Flores Guzman',
      '2025-12-31', 'RENUNCIA', 19200.00
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-26012345';
  END IF;

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'PREST_SOCIAL', 'Prestaciones sociales (5 annos x 30 dias)', 16000.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'PREST_SOCIAL');

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'VAC_PAGO', 'Vacaciones pendientes (15 dias)', 1600.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'VAC_PAGO');

  INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
  SELECT sp."SettlementProcessId", 'UTIL_FRAC', 'Utilidades fraccionadas (6 meses)', 1600.00
  FROM hr."SettlementProcess" sp WHERE sp."CompanyId" = 1 AND sp."SettlementCode" = 'LIQ-2025-001'
  AND NOT EXISTS (SELECT 1 FROM hr."SettlementProcessLine" spl INNER JOIN hr."SettlementProcess" spp ON spl."SettlementProcessId" = spp."SettlementProcessId"
    WHERE spp."SettlementCode" = 'LIQ-2025-001' AND spl."ConceptCode" = 'UTIL_FRAC');

  RAISE NOTICE '   Liquidacion V-26012345 insertada.';

  -- ============================================================================
  -- SECCION 5: OCCUPATIONAL HEALTH (5 registros)
  -- ============================================================================
  RAISE NOTICE '>> 5. Salud Ocupacional';

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "BodyPartAffected", "DaysLost",
    "Location", "Description", "RootCause", "CorrectiveAction", "Status"
  )
  SELECT 1, 'VE', 'ACCIDENT', e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas',
    '2025-11-10', '2025-11-10', 'LEVE', 'MANO_DERECHA', 3,
    'Almacen principal', 'Corte superficial en mano derecha al manipular cajas',
    'Falta de guantes de proteccion', 'Dotacion de guantes de corte obligatorios', 'CERRADO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "OccurrenceDate" = '2025-11-10');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "BodyPartAffected", "DaysLost",
    "Location", "Description", "RootCause", "Status", "InvestigationDueDate"
  )
  SELECT 1, 'VE', 'ACCIDENT', e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres',
    '2026-01-20', '2026-01-20', 'MODERADO', 'ESPALDA', 8,
    'Oficina administrativa', 'Lesion lumbar al levantar equipos de computo pesados',
    NULL, 'EN_INVESTIGACION', '2026-02-20'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "OccurrenceDate" = '2026-01-20');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "CorrectiveAction", "Status"
  )
  SELECT 1, 'VE', 'NEAR_MISS', e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva',
    '2026-02-05', '2026-02-05', 'LEVE', 0,
    'Pasillo principal planta baja', 'Casi-accidente por piso mojado sin senalizacion',
    'Colocar conos de senalizacion inmediatamente despues de trapear', 'CERRADO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "OccurrenceDate" = '2026-02-05');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "Status", "InstitutionReference"
  )
  SELECT 1, 'VE', 'INSPECTION', NULL, 'N/A', 'N/A',
    '2026-01-15', '2026-01-15', NULL, 0,
    'Almacen y deposito general', 'Inspeccion trimestral de condiciones de almacenamiento segun LOPCYMAT',
    'CERRADO', 'INPSASEL-2026-INS-0042'
  WHERE NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "RecordType" = 'INSPECTION' AND "OccurrenceDate" = '2026-01-15');

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId", "CountryCode", "RecordType", "EmployeeId", "EmployeeCode", "EmployeeName",
    "OccurrenceDate", "ReportedDate", "Severity", "DaysLost",
    "Location", "Description", "Status"
  )
  SELECT 1, 'VE', 'RISK_NOTIFICATION', e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz',
    '2026-02-28', '2026-02-28', NULL, 0,
    'Estacion de trabajo contabilidad', 'Notificacion de riesgo ergonomico por silla inadecuada y monitor a altura incorrecta. Requiere evaluacion de puesto de trabajo.',
    'ABIERTO'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789' AND "OccurrenceDate" = '2026-02-28');

  RAISE NOTICE '   5 registros de salud ocupacional insertados.';

  -- ============================================================================
  -- SECCION 6: MEDICAL EXAMS (8 registros)
  -- ============================================================================
  RAISE NOTICE '>> 6. Examenes Medicos';

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'PERIODIC', '2025-06-15', '2026-06-15', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678' AND "ExamDate" = '2025-06-15');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'PERIODIC', '2025-08-20', '2026-08-20', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "ExamDate" = '2025-08-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'PERIODIC', '2025-09-10', '2026-09-10', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012' AND "ExamDate" = '2025-09-10');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'PERIODIC', '2025-07-05', '2026-07-05', 'FIT_WITH_RESTRICTIONS', 'Evitar levantamiento de cargas superiores a 10 kg. Control lumbar cada 6 meses.', 'Dr. Luis Paredes', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "ExamDate" = '2025-07-05');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-20456789', 'Luisa Fernanda Castro Diaz', 'PRE_EMPLOYMENT', '2022-01-20', '2023-01-20', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-20456789'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-20456789' AND "ExamDate" = '2022-01-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName", "Notes")
  SELECT 1, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'PERIODIC', '2025-11-25', '2026-11-25', 'FIT', 'Dr. Rafael Mendoza', 'Clinica Santa Maria', 'Evaluacion post-accidente mano derecha. Recuperacion completa.'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "ExamDate" = '2025-11-25');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-24890123', 'Carmen Rosa Navarro Mendoza', 'PRE_EMPLOYMENT', '2022-12-20', '2023-12-20', 'FIT', 'Dr. Luis Paredes', 'Policlinica Metropolitana'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-24890123'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-24890123' AND "ExamDate" = '2022-12-20');

  INSERT INTO hr."MedicalExam" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "ExamType", "ExamDate", "NextDueDate", "Result", "PhysicianName", "ClinicName")
  SELECT 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 'PERIODIC', '2025-05-10', '2026-05-10', 'FIT', 'Dra. Carmen Olivares', 'Centro Medico El Avila'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-25678901' AND "ExamDate" = '2025-05-10');

  RAISE NOTICE '   8 examenes medicos insertados.';

  -- ============================================================================
  -- SECCION 7: MEDICAL ORDERS (5 registros)
  -- ============================================================================
  RAISE NOTICE '>> 7. Ordenes Medicas';

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-18234567', 'Jose Manuel Herrera Torres', 'MEDICAL', '2026-01-22', 'Lumbalgia mecanica aguda', 'Dr. Luis Paredes', 'Diclofenac 75mg c/12h x 7 dias. Reposo relativo. Control en 2 semanas.', 150.00, 150.00, 'APROBADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18234567'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-18234567' AND "OrderDate" = '2026-01-22');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-22678901', 'Pedro Antonio Morales Rivas', 'PHARMACY', '2025-11-12', 'Herida cortante mano derecha', 'Dr. Rafael Mendoza', 'Amoxicilina 500mg c/8h x 5 dias. Curas locales diarias.', 80.00, 80.00, 'PROCESADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-22678901'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-22678901' AND "OrderDate" = '2025-11-12');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "Status")
  SELECT 1, e."EmployeeId", 'V-12345678', 'Maria Elena Gonzalez Perez', 'LAB', '2026-03-01', 'Chequeo anual de rutina', 'Dra. Carmen Olivares', 'Hematologia completa, glicemia, perfil lipidico, urea, creatinina.', 200.00, 'PENDIENTE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-12345678'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-12345678' AND "OrderDate" = '2026-03-01');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-14567890', 'Carlos Alberto Rodriguez Silva', 'REFERRAL', '2026-02-10', 'Sindrome de tunel carpiano bilateral', 'Dr. Luis Paredes', 'Referencia a traumatologia para evaluacion quirurgica.', 350.00, 350.00, 'APROBADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-14567890'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-14567890' AND "OrderDate" = '2026-02-10');

  INSERT INTO hr."MedicalOrder" ("CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName", "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions", "EstimatedCost", "ApprovedAmount", "Status")
  SELECT 1, e."EmployeeId", 'V-16789012', 'Ana Isabel Martinez Lopez', 'MEDICAL', '2026-01-28', 'Cefalea tensional recurrente', 'Dra. Carmen Olivares', 'Ibuprofeno 400mg condicional. Evaluacion de estres laboral.', 120.00, 120.00, 'PROCESADA'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-16789012'
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId" = 1 AND "EmployeeCode" = 'V-16789012' AND "OrderDate" = '2026-01-28');

  RAISE NOTICE '   5 ordenes medicas insertadas.';
  RAISE NOTICE '=== SEED NOMINA COMPLETO — Primera mitad completada ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_nomina_completo.sql: %', SQLERRM;
END $$;
