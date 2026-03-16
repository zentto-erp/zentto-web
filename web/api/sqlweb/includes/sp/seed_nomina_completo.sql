USE DatqBoxWeb;
GO
SET NOCOUNT ON;
GO

-- ============================================================================
-- SEED NOMINA COMPLETO — Datos de prueba realistas (empresa venezolana DatqBox)
-- Idempotente: usa IF NOT EXISTS en cada INSERT
-- Compatible: SQL Server 2012+ (sin CREATE OR ALTER, sin OPENJSON)
-- Fecha: 2026-03-16
-- ============================================================================

PRINT '=== SEED NOMINA COMPLETO — Inicio ===';

-- ============================================================================
-- SECCION 1: EMPLEADOS (8 nuevos en master.Employee)
-- Existentes: EmployeeId=1 (V-25678901), EmployeeId=2 (V-18901234)
-- ============================================================================
PRINT '>> 1. Empleados';

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-12345678', N'Maria Elena Gonzalez Perez', N'V-12345678', '2020-01-15', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'V-14567890', '2019-06-01', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-16789012', N'Ana Isabel Martinez Lopez', N'V-16789012', '2021-03-10', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-18234567', N'Jose Manuel Herrera Torres', N'V-18234567', '2018-09-20', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'V-20456789', '2022-02-01', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-22678901', N'Pedro Antonio Morales Rivas', N'V-22678901', '2017-11-15', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-24890123')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'V-24890123', '2023-01-10', NULL, 1);

IF NOT EXISTS (SELECT 1 FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-26012345')
    INSERT INTO [master].Employee (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive)
    VALUES (1, N'V-26012345', N'Roberto Jose Flores Guzman', N'V-26012345', '2020-07-25', '2025-12-31', 0);

PRINT '   8 empleados procesados.';
GO

-- ============================================================================
-- SECCION 2: PAYROLL BATCHES (3 lotes) + BATCH LINES
-- Salarios base por empleado:
--   V-25678901: 3500  V-18901234: 2800  V-12345678: 4200  V-14567890: 4800
--   V-16789012: 3000  V-18234567: 5000  V-20456789: 2500  V-22678901: 4500
--   V-24890123: 2700  V-26012345: 3200 (retirado, solo batch 102 si aplica)
-- Deducciones: SSO=4%, FAOV=1%, LRPE=0.5%
-- ============================================================================
PRINT '>> 2. Payroll Batches';

-- Variables para EmployeeIds (se resuelven dinamicamente)
DECLARE @EmpId_25678901 BIGINT;
DECLARE @EmpId_18901234 BIGINT;
DECLARE @EmpId_12345678 BIGINT;
DECLARE @EmpId_14567890 BIGINT;
DECLARE @EmpId_16789012 BIGINT;
DECLARE @EmpId_18234567 BIGINT;
DECLARE @EmpId_20456789 BIGINT;
DECLARE @EmpId_22678901 BIGINT;
DECLARE @EmpId_24890123 BIGINT;
DECLARE @EmpId_26012345 BIGINT;

SELECT @EmpId_25678901 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-25678901';
SELECT @EmpId_18901234 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18901234';
SELECT @EmpId_12345678 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678';
SELECT @EmpId_14567890 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890';
SELECT @EmpId_16789012 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012';
SELECT @EmpId_18234567 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567';
SELECT @EmpId_20456789 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789';
SELECT @EmpId_22678901 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901';
SELECT @EmpId_24890123 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-24890123';
SELECT @EmpId_26012345 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-26012345';

-- ---------------------------------------------------------------
-- Batch 100: Enero 2026 — CERRADA, 8 empleados activos (sin Roberto ni Carmen nueva)
-- TotalGross = 3500+2800+4200+4800+3000+5000+2500+4500 = 30300
-- TotalDed   = 30300*(0.04+0.01+0.005) = 30300*0.055 = 1666.50
-- TotalNet   = 30300 - 1666.50 = 28633.50
-- ---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatch WHERE BatchId = 100)
BEGIN
    SET IDENTITY_INSERT hr.PayrollBatch ON;
    INSERT INTO hr.PayrollBatch (
        BatchId, CompanyId, BranchId, PayrollCode, FromDate, ToDate,
        Status, TotalEmployees, TotalGross, TotalDeductions, TotalNet,
        CreatedBy, CreatedAt, UpdatedAt
    )
    VALUES (
        100, 1, 1, N'LOT', '2026-01-01', '2026-01-31',
        N'CERRADA', 8, 30300.00, 1666.50, 28633.50,
        1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
    SET IDENTITY_INSERT hr.PayrollBatch OFF;
    PRINT '   Batch 100 (Ene 2026) insertado.';
END;

-- Batch 101: Febrero 2026 — CERRADA, 8 empleados
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatch WHERE BatchId = 101)
BEGIN
    SET IDENTITY_INSERT hr.PayrollBatch ON;
    INSERT INTO hr.PayrollBatch (
        BatchId, CompanyId, BranchId, PayrollCode, FromDate, ToDate,
        Status, TotalEmployees, TotalGross, TotalDeductions, TotalNet,
        CreatedBy, CreatedAt, UpdatedAt
    )
    VALUES (
        101, 1, 1, N'LOT', '2026-02-01', '2026-02-28',
        N'CERRADA', 8, 30300.00, 1666.50, 28633.50,
        1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
    SET IDENTITY_INSERT hr.PayrollBatch OFF;
    PRINT '   Batch 101 (Feb 2026) insertado.';
END;

-- Batch 102: Marzo 2026 — BORRADOR, 9 empleados (incluye Carmen)
-- TotalGross = 30300 + 2700 = 33000
-- TotalDed   = 33000*0.055 = 1815.00
-- TotalNet   = 33000 - 1815.00 = 31185.00
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatch WHERE BatchId = 102)
BEGIN
    SET IDENTITY_INSERT hr.PayrollBatch ON;
    INSERT INTO hr.PayrollBatch (
        BatchId, CompanyId, BranchId, PayrollCode, FromDate, ToDate,
        Status, TotalEmployees, TotalGross, TotalDeductions, TotalNet,
        CreatedBy, CreatedAt, UpdatedAt
    )
    VALUES (
        102, 1, 1, N'LOT', '2026-03-01', '2026-03-15',
        N'BORRADOR', 9, 33000.00, 1815.00, 31185.00,
        1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
    SET IDENTITY_INSERT hr.PayrollBatch OFF;
    PRINT '   Batch 102 (Mar 2026) insertado.';
END;

-- ---------------------------------------------------------------
-- Batch Lines — Macro para cada empleado por batch
-- Empleados batch 100 y 101: 8 activos (sin Carmen, sin Roberto)
-- Empleados batch 102: 9 activos (con Carmen)
-- Conceptos: ASIG_BASE, DED_SSO (4%), DED_FAOV (1%), DED_LRPE (0.5%)
-- ---------------------------------------------------------------
PRINT '>> 2b. Payroll Batch Lines';

-- Helper: insertar 4 lineas por empleado por batch
-- Batch 100 lines
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3500.00, 3500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 140.00, 140.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 35.00, 35.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 17.50, 17.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2800.00, 2800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 112.00, 112.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 28.00, 28.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 14.00, 14.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4200.00, 4200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 168.00, 168.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 42.00, 42.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 21.00, 21.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4800.00, 4800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 192.00, 192.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 48.00, 48.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 24.00, 24.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3000.00, 3000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 120.00, 120.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 30.00, 30.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 15.00, 15.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 5000.00, 5000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 200.00, 200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 50.00, 50.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 25.00, 25.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2500.00, 2500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 100.00, 100.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 25.00, 25.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 12.50, 12.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4500.00, 4500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 180.00, 180.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 45.00, 45.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 100 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (100, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 22.50, 22.50);

PRINT '   Batch 100 lines completadas.';

-- Batch 101 lines (Feb 2026) — mismos 8 empleados, mismos montos
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3500.00, 3500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 140.00, 140.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 35.00, 35.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 17.50, 17.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2800.00, 2800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 112.00, 112.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 28.00, 28.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 14.00, 14.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4200.00, 4200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 168.00, 168.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 42.00, 42.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 21.00, 21.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4800.00, 4800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 192.00, 192.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 48.00, 48.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 24.00, 24.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3000.00, 3000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 120.00, 120.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 30.00, 30.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 15.00, 15.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 5000.00, 5000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 200.00, 200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 50.00, 50.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 25.00, 25.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2500.00, 2500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 100.00, 100.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 25.00, 25.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 12.50, 12.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4500.00, 4500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 180.00, 180.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 45.00, 45.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 101 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (101, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 22.50, 22.50);

PRINT '   Batch 101 lines completadas.';

-- Batch 102 lines (Mar 2026) — 9 empleados (incluye Carmen Rosa Navarro)
-- Primero los mismos 8 del batch 100/101:
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3500.00, 3500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 140.00, 140.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 35.00, 35.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-25678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_25678901, N'V-25678901', N'Empleado V-25678901', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 17.50, 17.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2800.00, 2800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 112.00, 112.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 28.00, 28.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18901234' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18901234, N'V-18901234', N'Empleado V-18901234', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 14.00, 14.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4200.00, 4200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 168.00, 168.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 42.00, 42.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-12345678' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_12345678, N'V-12345678', N'Maria Elena Gonzalez Perez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 21.00, 21.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4800.00, 4800.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 192.00, 192.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 48.00, 48.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-14567890' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_14567890, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 24.00, 24.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 3000.00, 3000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 120.00, 120.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 30.00, 30.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-16789012' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_16789012, N'V-16789012', N'Ana Isabel Martinez Lopez', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 15.00, 15.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 5000.00, 5000.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 200.00, 200.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 50.00, 50.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-18234567' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_18234567, N'V-18234567', N'Jose Manuel Herrera Torres', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 25.00, 25.00);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2500.00, 2500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 100.00, 100.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 25.00, 25.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-20456789' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_20456789, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 12.50, 12.50);

IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 4500.00, 4500.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 180.00, 180.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 45.00, 45.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-22678901' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_22678901, N'V-22678901', N'Pedro Antonio Morales Rivas', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 22.50, 22.50);

-- Carmen Rosa Navarro (solo batch 102)
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-24890123' AND ConceptCode = N'ASIG_BASE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_24890123, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'ASIG_BASE', N'Sueldo Base', N'ASIGNACION', 1, 2700.00, 2700.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-24890123' AND ConceptCode = N'DED_SSO')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_24890123, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'DED_SSO', N'Seguro Social Obligatorio', N'DEDUCCION', 1, 108.00, 108.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-24890123' AND ConceptCode = N'DED_FAOV')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_24890123, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'DED_FAOV', N'FAOV Vivienda', N'DEDUCCION', 1, 27.00, 27.00);
IF NOT EXISTS (SELECT 1 FROM hr.PayrollBatchLine WHERE BatchId = 102 AND EmployeeCode = N'V-24890123' AND ConceptCode = N'DED_LRPE')
    INSERT INTO hr.PayrollBatchLine (BatchId, EmployeeId, EmployeeCode, EmployeeName, ConceptCode, ConceptName, ConceptType, Quantity, Amount, Total)
    VALUES (102, @EmpId_24890123, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'DED_LRPE', N'Regimen Prestacional Empleo', N'DEDUCCION', 1, 13.50, 13.50);

PRINT '   Batch 102 lines completadas.';
GO

-- ============================================================================
-- SECCION 3: VACATION REQUESTS (5) + VacationRequestDay + VacationProcess (2)
-- ============================================================================
PRINT '>> 3. Solicitudes de Vacaciones';

-- Request 100: V-12345678, 2026-02-10 a 2026-02-24, 15 dias, PROCESADA
IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = 100)
BEGIN
    SET IDENTITY_INSERT hr.VacationRequest ON;
    INSERT INTO hr.VacationRequest (
        RequestId, CompanyId, BranchId, EmployeeCode, RequestDate,
        StartDate, EndDate, TotalDays, IsPartial, Status,
        ApprovedBy, ApprovalDate, Notes
    )
    VALUES (
        100, 1, 1, N'V-12345678', '2026-01-20',
        '2026-02-10', '2026-02-24', 15, 0, N'PROCESADA',
        N'V-18234567', '2026-01-25', N'Vacaciones anuales periodo 2025-2026'
    );
    SET IDENTITY_INSERT hr.VacationRequest OFF;
END;

-- Request 101: V-14567890, 2026-03-01 a 2026-03-08, 8 dias, APROBADA
IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = 101)
BEGIN
    SET IDENTITY_INSERT hr.VacationRequest ON;
    INSERT INTO hr.VacationRequest (
        RequestId, CompanyId, BranchId, EmployeeCode, RequestDate,
        StartDate, EndDate, TotalDays, IsPartial, Status,
        ApprovedBy, ApprovalDate, Notes
    )
    VALUES (
        101, 1, 1, N'V-14567890', '2026-02-15',
        '2026-03-01', '2026-03-08', 8, 0, N'APROBADA',
        N'V-18234567', '2026-02-20', N'Dias pendientes periodo anterior'
    );
    SET IDENTITY_INSERT hr.VacationRequest OFF;
END;

-- Request 102: V-16789012, 2026-04-01 a 2026-04-15, 15 dias, PENDIENTE
IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = 102)
BEGIN
    SET IDENTITY_INSERT hr.VacationRequest ON;
    INSERT INTO hr.VacationRequest (
        RequestId, CompanyId, BranchId, EmployeeCode, RequestDate,
        StartDate, EndDate, TotalDays, IsPartial, Status,
        Notes
    )
    VALUES (
        102, 1, 1, N'V-16789012', '2026-03-10',
        '2026-04-01', '2026-04-15', 15, 0, N'PENDIENTE',
        N'Vacaciones anuales completas'
    );
    SET IDENTITY_INSERT hr.VacationRequest OFF;
END;

-- Request 103: V-18234567, 2026-01-15 a 2026-01-22, 8 dias, PROCESADA
IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = 103)
BEGIN
    SET IDENTITY_INSERT hr.VacationRequest ON;
    INSERT INTO hr.VacationRequest (
        RequestId, CompanyId, BranchId, EmployeeCode, RequestDate,
        StartDate, EndDate, TotalDays, IsPartial, Status,
        ApprovedBy, ApprovalDate, Notes
    )
    VALUES (
        103, 1, 1, N'V-18234567', '2025-12-20',
        '2026-01-15', '2026-01-22', 8, 0, N'PROCESADA',
        N'V-25678901', '2025-12-28', N'Vacaciones parciales inicio de anno'
    );
    SET IDENTITY_INSERT hr.VacationRequest OFF;
END;

-- Request 104: V-20456789, 2026-05-01 a 2026-05-10, 10 dias, RECHAZADA
IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = 104)
BEGIN
    SET IDENTITY_INSERT hr.VacationRequest ON;
    INSERT INTO hr.VacationRequest (
        RequestId, CompanyId, BranchId, EmployeeCode, RequestDate,
        StartDate, EndDate, TotalDays, IsPartial, Status,
        RejectionReason, Notes
    )
    VALUES (
        104, 1, 1, N'V-20456789', '2026-03-05',
        '2026-05-01', '2026-05-10', 10, 0, N'RECHAZADA',
        N'Periodo de alta demanda', N'Solicitud rechazada por carga laboral'
    );
    SET IDENTITY_INSERT hr.VacationRequest OFF;
END;

PRINT '   5 solicitudes de vacaciones insertadas.';

-- ---------------------------------------------------------------
-- VacationRequestDay — dias individuales para cada solicitud
-- ---------------------------------------------------------------
PRINT '>> 3b. Dias de vacaciones';

-- Request 100: 15 dias (2026-02-10 al 2026-02-24)
DECLARE @d100 DATE;
SET @d100 = '2026-02-10';
WHILE @d100 <= '2026-02-24'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequestDay WHERE RequestId = 100 AND SelectedDate = @d100)
        INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType) VALUES (100, @d100, N'COMPLETO');
    SET @d100 = DATEADD(DAY, 1, @d100);
END;

-- Request 101: 8 dias (2026-03-01 al 2026-03-08)
DECLARE @d101 DATE;
SET @d101 = '2026-03-01';
WHILE @d101 <= '2026-03-08'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequestDay WHERE RequestId = 101 AND SelectedDate = @d101)
        INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType) VALUES (101, @d101, N'COMPLETO');
    SET @d101 = DATEADD(DAY, 1, @d101);
END;

-- Request 102: 15 dias (2026-04-01 al 2026-04-15)
DECLARE @d102 DATE;
SET @d102 = '2026-04-01';
WHILE @d102 <= '2026-04-15'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequestDay WHERE RequestId = 102 AND SelectedDate = @d102)
        INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType) VALUES (102, @d102, N'COMPLETO');
    SET @d102 = DATEADD(DAY, 1, @d102);
END;

-- Request 103: 8 dias (2026-01-15 al 2026-01-22)
DECLARE @d103 DATE;
SET @d103 = '2026-01-15';
WHILE @d103 <= '2026-01-22'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequestDay WHERE RequestId = 103 AND SelectedDate = @d103)
        INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType) VALUES (103, @d103, N'COMPLETO');
    SET @d103 = DATEADD(DAY, 1, @d103);
END;

-- Request 104: 10 dias (2026-05-01 al 2026-05-10)
DECLARE @d104 DATE;
SET @d104 = '2026-05-01';
WHILE @d104 <= '2026-05-10'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequestDay WHERE RequestId = 104 AND SelectedDate = @d104)
        INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType) VALUES (104, @d104, N'COMPLETO');
    SET @d104 = DATEADD(DAY, 1, @d104);
END;

PRINT '   Dias de vacaciones insertados.';
GO

-- ---------------------------------------------------------------
-- VacationProcess (2 procesados: Request 100 y 103)
-- ---------------------------------------------------------------
PRINT '>> 3c. VacationProcess';

DECLARE @EmpId100 BIGINT;
DECLARE @EmpId103 BIGINT;
SELECT @EmpId100 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678';
SELECT @EmpId103 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567';

-- VacationProcess para Request 100: V-12345678, salario 4200, 15 dias
-- Total = 4200/30 * 15 = 2100 (pago) + 4200/30 * 15 = 2100 (bono) = 4200
IF NOT EXISTS (SELECT 1 FROM hr.VacationProcess WHERE CompanyId = 1 AND VacationCode = N'VAC-2026-100')
BEGIN
    INSERT INTO hr.VacationProcess (
        CompanyId, BranchId, VacationCode, EmployeeId, EmployeeCode, EmployeeName,
        StartDate, EndDate, ReintegrationDate, ProcessDate,
        TotalAmount, CalculatedAmount
    )
    VALUES (
        1, 1, N'VAC-2026-100', @EmpId100, N'V-12345678', N'Maria Elena Gonzalez Perez',
        '2026-02-10', '2026-02-24', '2026-02-25', '2026-02-08',
        4200.00, 4200.00
    );
END;

-- VacationProcess para Request 103: V-18234567, salario 5000, 8 dias
-- Total = 5000/30 * 8 = 1333.33 (pago) + 5000/30 * 8 = 1333.33 (bono) = 2666.66
IF NOT EXISTS (SELECT 1 FROM hr.VacationProcess WHERE CompanyId = 1 AND VacationCode = N'VAC-2026-103')
BEGIN
    INSERT INTO hr.VacationProcess (
        CompanyId, BranchId, VacationCode, EmployeeId, EmployeeCode, EmployeeName,
        StartDate, EndDate, ReintegrationDate, ProcessDate,
        TotalAmount, CalculatedAmount
    )
    VALUES (
        1, 1, N'VAC-2026-103', @EmpId103, N'V-18234567', N'Jose Manuel Herrera Torres',
        '2026-01-15', '2026-01-22', '2026-01-23', '2026-01-13',
        2666.66, 2666.66
    );
END;

-- VacationProcessLine para Request 100
DECLARE @VPId100 BIGINT;
SELECT @VPId100 = VacationProcessId FROM hr.VacationProcess WHERE CompanyId = 1 AND VacationCode = N'VAC-2026-100';

IF @VPId100 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.VacationProcessLine WHERE VacationProcessId = @VPId100 AND ConceptCode = N'VAC_PAGO')
    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@VPId100, N'VAC_PAGO', N'Pago vacaciones', 2100.00);

IF @VPId100 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.VacationProcessLine WHERE VacationProcessId = @VPId100 AND ConceptCode = N'VAC_BONO')
    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@VPId100, N'VAC_BONO', N'Bono vacacional', 2100.00);

-- VacationProcessLine para Request 103
DECLARE @VPId103 BIGINT;
SELECT @VPId103 = VacationProcessId FROM hr.VacationProcess WHERE CompanyId = 1 AND VacationCode = N'VAC-2026-103';

IF @VPId103 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.VacationProcessLine WHERE VacationProcessId = @VPId103 AND ConceptCode = N'VAC_PAGO')
    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@VPId103, N'VAC_PAGO', N'Pago vacaciones', 1333.33);

IF @VPId103 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.VacationProcessLine WHERE VacationProcessId = @VPId103 AND ConceptCode = N'VAC_BONO')
    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@VPId103, N'VAC_BONO', N'Bono vacacional', 1333.33);

-- Vincular VacationId en las requests procesadas
UPDATE hr.VacationRequest SET VacationId = @VPId100 WHERE RequestId = 100 AND VacationId IS NULL;
UPDATE hr.VacationRequest SET VacationId = @VPId103 WHERE RequestId = 103 AND VacationId IS NULL;

PRINT '   VacationProcess y lineas insertadas.';
GO

-- ============================================================================
-- SECCION 4: SETTLEMENT PROCESS (liquidacion Roberto Jose Flores Guzman)
-- V-26012345, retirado 2025-12-31, salario 3200, ingreso 2020-07-25
-- Antiguedad: ~5.4 annos => 5 annos
-- Prestaciones: 5 * (3200/30) * 30 = 5 * 3200 = 16000
-- Vacaciones pendientes: (3200/30) * 15 = 1600
-- Utilidades fraccionadas: (3200/30) * 30 * (6/12) = 1600 (6 meses trabajados en 2025)
-- Total = 16000 + 1600 + 1600 = 19200
-- ============================================================================
PRINT '>> 4. Liquidacion (Settlement)';

DECLARE @EmpIdRetired BIGINT;
SELECT @EmpIdRetired = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-26012345';

IF NOT EXISTS (SELECT 1 FROM hr.SettlementProcess WHERE CompanyId = 1 AND SettlementCode = N'LIQ-2025-001')
BEGIN
    INSERT INTO hr.SettlementProcess (
        CompanyId, BranchId, SettlementCode, EmployeeId, EmployeeCode, EmployeeName,
        RetirementDate, RetirementCause, TotalAmount
    )
    VALUES (
        1, 1, N'LIQ-2025-001', @EmpIdRetired, N'V-26012345', N'Roberto Jose Flores Guzman',
        '2025-12-31', N'RENUNCIA', 19200.00
    );
END;

DECLARE @SPId BIGINT;
SELECT @SPId = SettlementProcessId FROM hr.SettlementProcess WHERE CompanyId = 1 AND SettlementCode = N'LIQ-2025-001';

IF @SPId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.SettlementProcessLine WHERE SettlementProcessId = @SPId AND ConceptCode = N'PREST_SOCIAL')
    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@SPId, N'PREST_SOCIAL', N'Prestaciones sociales (5 annos x 30 dias)', 16000.00);

IF @SPId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.SettlementProcessLine WHERE SettlementProcessId = @SPId AND ConceptCode = N'VAC_PAGO')
    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@SPId, N'VAC_PAGO', N'Vacaciones pendientes (15 dias)', 1600.00);

IF @SPId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM hr.SettlementProcessLine WHERE SettlementProcessId = @SPId AND ConceptCode = N'UTIL_FRAC')
    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@SPId, N'UTIL_FRAC', N'Utilidades fraccionadas (6 meses)', 1600.00);

PRINT '   Liquidacion V-26012345 insertada.';
GO

-- ============================================================================
-- SECCION 5: OCCUPATIONAL HEALTH (5 registros)
-- ============================================================================
PRINT '>> 5. Salud Ocupacional';

-- 1. ACCIDENT: V-22678901, 2025-11-10, LEVE, MANO_DERECHA, 3 dias, CERRADO
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901' AND OccurrenceDate = '2025-11-10')
BEGIN
    DECLARE @EmpOH1 BIGINT;
    SELECT @EmpOH1 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901';
    INSERT INTO hr.OccupationalHealth (
        CompanyId, CountryCode, RecordType, EmployeeId, EmployeeCode, EmployeeName,
        OccurrenceDate, ReportedDate, Severity, BodyPartAffected, DaysLost,
        Location, Description, RootCause, CorrectiveAction, Status
    )
    VALUES (
        1, N'VE', N'ACCIDENT', @EmpOH1, N'V-22678901', N'Pedro Antonio Morales Rivas',
        '2025-11-10', '2025-11-10', N'LEVE', N'MANO_DERECHA', 3,
        N'Almacen principal', N'Corte superficial en mano derecha al manipular cajas',
        N'Falta de guantes de proteccion', N'Dotacion de guantes de corte obligatorios', N'CERRADO'
    );
END;

-- 2. ACCIDENT: V-18234567, 2026-01-20, MODERADO, ESPALDA, 8 dias, EN_INVESTIGACION
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567' AND OccurrenceDate = '2026-01-20')
BEGIN
    DECLARE @EmpOH2 BIGINT;
    SELECT @EmpOH2 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567';
    INSERT INTO hr.OccupationalHealth (
        CompanyId, CountryCode, RecordType, EmployeeId, EmployeeCode, EmployeeName,
        OccurrenceDate, ReportedDate, Severity, BodyPartAffected, DaysLost,
        Location, Description, RootCause, Status, InvestigationDueDate
    )
    VALUES (
        1, N'VE', N'ACCIDENT', @EmpOH2, N'V-18234567', N'Jose Manuel Herrera Torres',
        '2026-01-20', '2026-01-20', N'MODERADO', N'ESPALDA', 8,
        N'Oficina administrativa', N'Lesion lumbar al levantar equipos de computo pesados',
        NULL, N'EN_INVESTIGACION', '2026-02-20'
    );
END;

-- 3. NEAR_MISS: V-14567890, 2026-02-05, LEVE, CERRADO
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890' AND OccurrenceDate = '2026-02-05')
BEGIN
    DECLARE @EmpOH3 BIGINT;
    SELECT @EmpOH3 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890';
    INSERT INTO hr.OccupationalHealth (
        CompanyId, CountryCode, RecordType, EmployeeId, EmployeeCode, EmployeeName,
        OccurrenceDate, ReportedDate, Severity, DaysLost,
        Location, Description, CorrectiveAction, Status
    )
    VALUES (
        1, N'VE', N'NEAR_MISS', @EmpOH3, N'V-14567890', N'Carlos Alberto Rodriguez Silva',
        '2026-02-05', '2026-02-05', N'LEVE', 0,
        N'Pasillo principal planta baja', N'Casi-accidente por piso mojado sin senalizacion',
        N'Colocar conos de senalizacion inmediatamente despues de trapear', N'CERRADO'
    );
END;

-- 4. INSPECTION: sin empleado, 2026-01-15, inspeccion almacen, CERRADO
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE CompanyId = 1 AND RecordType = N'INSPECTION' AND OccurrenceDate = '2026-01-15')
BEGIN
    INSERT INTO hr.OccupationalHealth (
        CompanyId, CountryCode, RecordType, EmployeeId, EmployeeCode, EmployeeName,
        OccurrenceDate, ReportedDate, Severity, DaysLost,
        Location, Description, Status, InstitutionReference
    )
    VALUES (
        1, N'VE', N'INSPECTION', NULL, N'N/A', N'N/A',
        '2026-01-15', '2026-01-15', NULL, 0,
        N'Almacen y deposito general', N'Inspeccion trimestral de condiciones de almacenamiento segun LOPCYMAT',
        N'CERRADO', N'INPSASEL-2026-INS-0042'
    );
END;

-- 5. RISK_NOTIFICATION: V-20456789, 2026-02-28, riesgo ergonomico, ABIERTO
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789' AND OccurrenceDate = '2026-02-28')
BEGIN
    DECLARE @EmpOH5 BIGINT;
    SELECT @EmpOH5 = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789';
    INSERT INTO hr.OccupationalHealth (
        CompanyId, CountryCode, RecordType, EmployeeId, EmployeeCode, EmployeeName,
        OccurrenceDate, ReportedDate, Severity, DaysLost,
        Location, Description, Status
    )
    VALUES (
        1, N'VE', N'RISK_NOTIFICATION', @EmpOH5, N'V-20456789', N'Luisa Fernanda Castro Diaz',
        '2026-02-28', '2026-02-28', NULL, 0,
        N'Estacion de trabajo contabilidad', N'Notificacion de riesgo ergonomico por silla inadecuada y monitor a altura incorrecta. Requiere evaluacion de puesto de trabajo.',
        N'ABIERTO'
    );
END;

PRINT '   5 registros de salud ocupacional insertados.';
GO

-- ============================================================================
-- SECCION 6: MEDICAL EXAMS (8 registros)
-- ============================================================================
PRINT '>> 6. Examenes Medicos';

DECLARE @MExEmpId BIGINT;

-- 1. V-12345678 - PERIODIC (2025-06-15) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678' AND ExamDate = '2025-06-15')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-12345678', N'Maria Elena Gonzalez Perez', N'PERIODIC', '2025-06-15', '2026-06-15', N'FIT', N'Dr. Rafael Mendoza', N'Clinica Santa Maria');

-- 2. V-14567890 - PERIODIC (2025-08-20) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890' AND ExamDate = '2025-08-20')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'PERIODIC', '2025-08-20', '2026-08-20', N'FIT', N'Dra. Carmen Olivares', N'Centro Medico El Avila');

-- 3. V-16789012 - PERIODIC (2025-09-10) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012' AND ExamDate = '2025-09-10')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-16789012', N'Ana Isabel Martinez Lopez', N'PERIODIC', '2025-09-10', '2026-09-10', N'FIT', N'Dr. Rafael Mendoza', N'Clinica Santa Maria');

-- 4. V-18234567 - PERIODIC (2025-07-05) - FIT_WITH_RESTRICTIONS (espalda)
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567' AND ExamDate = '2025-07-05')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, Restrictions, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-18234567', N'Jose Manuel Herrera Torres', N'PERIODIC', '2025-07-05', '2026-07-05', N'FIT_WITH_RESTRICTIONS', N'Evitar levantamiento de cargas superiores a 10 kg. Control lumbar cada 6 meses.', N'Dr. Luis Paredes', N'Centro Medico El Avila');

-- 5. V-20456789 - PRE_EMPLOYMENT (2022-01-20) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-20456789' AND ExamDate = '2022-01-20')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-20456789', N'Luisa Fernanda Castro Diaz', N'PRE_EMPLOYMENT', '2022-01-20', '2023-01-20', N'FIT', N'Dra. Carmen Olivares', N'Centro Medico El Avila');

-- 6. V-22678901 - PERIODIC (2025-11-25) - FIT (post-accidente)
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901' AND ExamDate = '2025-11-25')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName, Notes)
    VALUES (1, @MExEmpId, N'V-22678901', N'Pedro Antonio Morales Rivas', N'PERIODIC', '2025-11-25', '2026-11-25', N'FIT', N'Dr. Rafael Mendoza', N'Clinica Santa Maria', N'Evaluacion post-accidente mano derecha. Recuperacion completa.');

-- 7. V-24890123 - PRE_EMPLOYMENT (2022-12-20) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-24890123';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-24890123' AND ExamDate = '2022-12-20')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-24890123', N'Carmen Rosa Navarro Mendoza', N'PRE_EMPLOYMENT', '2022-12-20', '2023-12-20', N'FIT', N'Dr. Luis Paredes', N'Policlinica Metropolitana');

-- 8. V-25678901 - PERIODIC (2025-05-10) - FIT
SELECT @MExEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-25678901';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE CompanyId = 1 AND EmployeeCode = N'V-25678901' AND ExamDate = '2025-05-10')
    INSERT INTO hr.MedicalExam (CompanyId, EmployeeId, EmployeeCode, EmployeeName, ExamType, ExamDate, NextDueDate, Result, PhysicianName, ClinicName)
    VALUES (1, @MExEmpId, N'V-25678901', N'Empleado V-25678901', N'PERIODIC', '2025-05-10', '2026-05-10', N'FIT', N'Dra. Carmen Olivares', N'Centro Medico El Avila');

PRINT '   8 examenes medicos insertados.';
GO

-- ============================================================================
-- SECCION 7: MEDICAL ORDERS (5 registros)
-- ============================================================================
PRINT '>> 7. Ordenes Medicas';

DECLARE @MOEmpId BIGINT;

-- 1. V-18234567 - MEDICAL, lesion espalda, APROBADA, 150
SELECT @MOEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE CompanyId = 1 AND EmployeeCode = N'V-18234567' AND OrderDate = '2026-01-22')
    INSERT INTO hr.MedicalOrder (CompanyId, EmployeeId, EmployeeCode, EmployeeName, OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions, EstimatedCost, ApprovedAmount, Status)
    VALUES (1, @MOEmpId, N'V-18234567', N'Jose Manuel Herrera Torres', N'MEDICAL', '2026-01-22', N'Lumbalgia mecanica aguda', N'Dr. Luis Paredes', N'Diclofenac 75mg c/12h x 7 dias. Reposo relativo. Control en 2 semanas.', 150.00, 150.00, N'APROBADA');

-- 2. V-22678901 - PHARMACY, ENTREGADA, 80
SELECT @MOEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE CompanyId = 1 AND EmployeeCode = N'V-22678901' AND OrderDate = '2025-11-12')
    INSERT INTO hr.MedicalOrder (CompanyId, EmployeeId, EmployeeCode, EmployeeName, OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions, EstimatedCost, ApprovedAmount, Status)
    VALUES (1, @MOEmpId, N'V-22678901', N'Pedro Antonio Morales Rivas', N'PHARMACY', '2025-11-12', N'Herida cortante mano derecha', N'Dr. Rafael Mendoza', N'Amoxicilina 500mg c/8h x 5 dias. Curas locales diarias.', 80.00, 80.00, N'PROCESADA');

-- 3. V-12345678 - LAB, chequeo anual, PENDIENTE, 200
SELECT @MOEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE CompanyId = 1 AND EmployeeCode = N'V-12345678' AND OrderDate = '2026-03-01')
    INSERT INTO hr.MedicalOrder (CompanyId, EmployeeId, EmployeeCode, EmployeeName, OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions, EstimatedCost, Status)
    VALUES (1, @MOEmpId, N'V-12345678', N'Maria Elena Gonzalez Perez', N'LAB', '2026-03-01', N'Chequeo anual de rutina', N'Dra. Carmen Olivares', N'Hematologia completa, glicemia, perfil lipidico, urea, creatinina.', 200.00, N'PENDIENTE');

-- 4. V-14567890 - REFERRAL, especialista, APROBADA, 350
SELECT @MOEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE CompanyId = 1 AND EmployeeCode = N'V-14567890' AND OrderDate = '2026-02-10')
    INSERT INTO hr.MedicalOrder (CompanyId, EmployeeId, EmployeeCode, EmployeeName, OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions, EstimatedCost, ApprovedAmount, Status)
    VALUES (1, @MOEmpId, N'V-14567890', N'Carlos Alberto Rodriguez Silva', N'REFERRAL', '2026-02-10', N'Sindrome de tunel carpiano bilateral', N'Dr. Luis Paredes', N'Referencia a traumatologia para evaluacion quirurgica.', 350.00, 350.00, N'APROBADA');

-- 5. V-16789012 - MEDICAL, PROCESADA, 120
SELECT @MOEmpId = EmployeeId FROM [master].Employee WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012';
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE CompanyId = 1 AND EmployeeCode = N'V-16789012' AND OrderDate = '2026-01-28')
    INSERT INTO hr.MedicalOrder (CompanyId, EmployeeId, EmployeeCode, EmployeeName, OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions, EstimatedCost, ApprovedAmount, Status)
    VALUES (1, @MOEmpId, N'V-16789012', N'Ana Isabel Martinez Lopez', N'MEDICAL', '2026-01-28', N'Cefalea tensional recurrente', N'Dra. Carmen Olivares', N'Ibuprofeno 400mg condicional. Evaluacion de estres laboral.', 120.00, 120.00, N'PROCESADA');

PRINT '   5 ordenes medicas insertadas.';
GO

-- ============================================================================
-- FIN PRIMERA MITAD — Secciones 1 a 7
-- Secciones pendientes (segunda mitad): 8-Training, 9-SafetyCommittees,
-- 10-LegalObligations, 11-EmployeeObligations, 12-ObligationFilings,
-- 13-SavingsFund, 14-ProfitSharing, 15-SocialBenefitsTrust, 16-DocTemplates
-- ============================================================================
PRINT '=== SEED NOMINA COMPLETO — Primera mitad completada ===';
GO
