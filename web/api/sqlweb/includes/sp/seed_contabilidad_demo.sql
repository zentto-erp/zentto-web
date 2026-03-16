SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

/*
 * seed_contabilidad_demo.sql
 * Datos de demostración completos para validar todos los flujos contables
 * Empresa: VE, CompanyId=1, BranchId=1, Moneda=VES, IVA=16%
 * Idempotente: IF NOT EXISTS antes de cada INSERT
 *
 * Contenido:
 *   1. Períodos Fiscales (12 meses 2026)
 *   2. Centros de Costo (5)
 *   3. Clientes (4)
 *   4. Asiento de Apertura
 *   5. Asientos Enero (8)
 *   6. Asientos Febrero (8)
 *   7. Asientos Marzo (6)
 *   8. Documentos Venta (5)
 *   9. Documentos Compra (5)
 *  10. Activos Fijos (5)
 *  11. Depreciaciones (11)
 *  12. Mejora a activo (1)
 *  13. Presupuesto (1 + 5 líneas)
 *  14. Asientos Recurrentes (3)
 *  15. Retenciones IVA (3)
 */

PRINT '=== SEED CONTABILIDAD DEMO ===';
PRINT '>> Iniciando...';

BEGIN TRY
  BEGIN TRAN;

  SET DATEFORMAT ymd;
  DECLARE @CompanyId INT = 1;
  DECLARE @BranchId  INT = 1;
  DECLARE @Now       DATETIME = SYSUTCDATETIME();

  -- ============================================================
  -- 1. PERÍODOS FISCALES 2026 (12 meses)
  -- ============================================================
  PRINT '>> 1. Períodos fiscales 2026...';

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202601')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202601', N'Enero 2026',      2026, 1,  '2026-01-01', '2026-01-31', 'CLOSED', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202602')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202602', N'Febrero 2026',    2026, 2,  '2026-02-01', '2026-02-28', 'CLOSED', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202603')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202603', N'Marzo 2026',      2026, 3,  '2026-03-01', '2026-03-31', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202604')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202604', N'Abril 2026',      2026, 4,  '2026-04-01', '2026-04-30', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202605')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202605', N'Mayo 2026',       2026, 5,  '2026-05-01', '2026-05-31', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202606')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202606', N'Junio 2026',      2026, 6,  '2026-06-01', '2026-06-30', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202607')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202607', N'Julio 2026',      2026, 7,  '2026-07-01', '2026-07-31', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202608')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202608', N'Agosto 2026',     2026, 8,  '2026-08-01', '2026-08-31', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202609')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202609', N'Septiembre 2026', 2026, 9,  '2026-09-01', '2026-09-30', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202610')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202610', N'Octubre 2026',    2026, 10, '2026-10-01', '2026-10-31', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202611')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202611', N'Noviembre 2026',  2026, 11, '2026-11-01', '2026-11-30', 'OPEN', @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FiscalPeriod WHERE CompanyId = @CompanyId AND PeriodCode = '202612')
    INSERT INTO acct.FiscalPeriod (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, '202612', N'Diciembre 2026',  2026, 12, '2026-12-01', '2026-12-31', 'OPEN', @Now, @Now);

  PRINT '   12 períodos fiscales OK.';

  -- ============================================================
  -- 2. CENTROS DE COSTO (5)
  -- ============================================================
  PRINT '>> 2. Centros de costo...';

  IF NOT EXISTS (SELECT 1 FROM acct.CostCenter WHERE CompanyId = @CompanyId AND CostCenterCode = 'ADM')
    INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, 'ADM', N'Administración', NULL, 1, 1, 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.CostCenter WHERE CompanyId = @CompanyId AND CostCenterCode = 'VEN')
    INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, 'VEN', N'Ventas', NULL, 1, 1, 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.CostCenter WHERE CompanyId = @CompanyId AND CostCenterCode = 'OPE')
    INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, 'OPE', N'Operaciones', NULL, 1, 1, 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.CostCenter WHERE CompanyId = @CompanyId AND CostCenterCode = 'FIN')
    INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, 'FIN', N'Finanzas', NULL, 1, 1, 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.CostCenter WHERE CompanyId = @CompanyId AND CostCenterCode = 'ALM')
    INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, 'ALM', N'Almacén', NULL, 1, 1, 0, @Now, @Now);

  PRINT '   5 centros de costo OK.';

  -- ============================================================
  -- 3. CLIENTES (4)
  -- ============================================================
  PRINT '>> 3. Clientes...';

  IF NOT EXISTS (SELECT 1 FROM master.Customer WHERE CompanyId = @CompanyId AND CustomerCode = 'CLI-002')
    INSERT INTO master.Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, 'CLI-002', N'Distribuidora El Sol C.A.', 'J-12345679-0', 'contacto@elsol.com.ve', '0212-5551234', N'Av. Libertador, Caracas', 50000, 0, 1, @Now, @Now, 0);

  IF NOT EXISTS (SELECT 1 FROM master.Customer WHERE CompanyId = @CompanyId AND CustomerCode = 'CLI-003')
    INSERT INTO master.Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, 'CLI-003', N'Inversiones Orion S.A.', 'J-98765432-1', 'admin@orionsa.com', '0212-5559876', N'Calle 10, Valencia', 75000, 0, 1, @Now, @Now, 0);

  IF NOT EXISTS (SELECT 1 FROM master.Customer WHERE CompanyId = @CompanyId AND CustomerCode = 'CLI-004')
    INSERT INTO master.Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, 'CLI-004', N'Ferretería La Esquina', 'V-15678234-5', 'ventas@laesquina.com', '0241-8001234', N'Av. Bolívar, Maracay', 30000, 0, 1, @Now, @Now, 0);

  IF NOT EXISTS (SELECT 1 FROM master.Customer WHERE CompanyId = @CompanyId AND CustomerCode = 'CLI-005')
    INSERT INTO master.Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, TotalBalance, IsActive, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, 'CLI-005', N'Servicios Tecnológicos 360', 'J-40567890-3', 'info@st360.com', '0212-5554567', N'Torre Empresarial, Caracas', 100000, 0, 1, @Now, @Now, 0);

  PRINT '   4 clientes OK.';

  -- ============================================================
  -- 4. ASIENTO DE APERTURA (775000 = 775000)
  -- ============================================================
  PRINT '>> 4. Asiento de apertura...';

  DECLARE @EntryId BIGINT;

  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-APE-001' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-APE-001', '2026-01-01', '202601', 'APE', N'Asiento de apertura ejercicio 2026', 'VES', 1, 775000.00, 775000.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId,  1,  6, '1.1.01', N'Saldo inicial Caja',            50000.00,       0, @Now, @Now),
      (@EntryId,  2,  1, '1.1.02', N'Saldo inicial Bancos',         200000.00,       0, @Now, @Now),
      (@EntryId,  3,  8, '1.1.04', N'Saldo inicial CxC',             75000.00,       0, @Now, @Now),
      (@EntryId,  4, 10, '1.1.06', N'Saldo inicial Inventario',     150000.00,       0, @Now, @Now),
      (@EntryId,  5, 15, '1.2.01', N'Saldo PPE',                    300000.00,       0, @Now, @Now),
      (@EntryId,  6, 16, '1.2.02', N'Dep Acum PPE',                       0,  60000.00, @Now, @Now),
      (@EntryId,  7, 22, '2.1.01', N'Saldo CxP',                          0,  80000.00, @Now, @Now),
      (@EntryId,  8, 25, '2.1.05', N'Nómina por pagar',                   0,  35000.00, @Now, @Now),
      (@EntryId,  9, 37, '3.1.01', N'Capital Social',                     0, 400000.00, @Now, @Now),
      (@EntryId, 10, 43, '3.3.01', N'Utilidades Acumuladas',              0, 200000.00, @Now, @Now);

    PRINT '   Asiento apertura SEED-APE-001 insertado (775000/775000).';
  END
  ELSE
    PRINT '   Asiento apertura SEED-APE-001 ya existe, omitido.';

  -- ============================================================
  -- 5. ASIENTOS DE ENERO (8 asientos, periodo 202601)
  -- ============================================================
  PRINT '>> 5. Asientos de enero...';

  -- SEED-ENE-001: Venta contado FAC-001 (29000/29000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-001' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-001', '2026-01-05', '202601', 'DIA', 'FAC-001', N'Venta contado FAC-001 Distribuidora El Sol', 'VES', 1, 29000.00, 29000.00, 'APPROVED', 'AR', 'FAC-001', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  1, '1.1.02', N'Cobro contado FAC-001',        29000.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta FAC-001',             0, 25000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal FAC-001',         0,  4000.00, @Now, @Now);

    PRINT '   SEED-ENE-001 insertado (29000/29000).';
  END
  ELSE PRINT '   SEED-ENE-001 ya existe, omitido.';

  -- SEED-ENE-002: Venta crédito FAC-002 (17400/17400)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-002' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-002', '2026-01-08', '202601', 'DIA', 'FAC-002', N'Venta crédito FAC-002 Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', 'FAC-002', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  8, '1.1.04', N'CxC FAC-002',                  17400.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta FAC-002',             0, 15000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal FAC-002',         0,  2400.00, @Now, @Now);

    PRINT '   SEED-ENE-002 insertado (17400/17400).';
  END
  ELSE PRINT '   SEED-ENE-002 ya existe, omitido.';

  -- SEED-ENE-003: Compra crédito OC-001 (13920/13920)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-003' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-003', '2026-01-10', '202601', 'DIA', 'OC-001', N'Compra crédito OC-001 Proveedor 1', 'VES', 1, 13920.00, 13920.00, 'APPROVED', 'AP', 'OC-001', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 10, '1.1.06', N'Inventario OC-001',            12000.00,     0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal OC-001',     1920.00,     0, @Now, @Now),
      (@EntryId, 3, 22, '2.1.01', N'CxP OC-001',                        0, 13920.00, @Now, @Now);

    PRINT '   SEED-ENE-003 insertado (13920/13920).';
  END
  ELSE PRINT '   SEED-ENE-003 ya existe, omitido.';

  -- SEED-ENE-004: Venta contado FAC-003 (11600/11600)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-004' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-004', '2026-01-12', '202601', 'DIA', 'FAC-003', N'Venta contado FAC-003 Ferretería La Esquina', 'VES', 1, 11600.00, 11600.00, 'APPROVED', 'AR', 'FAC-003', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  6, '1.1.01', N'Cobro contado FAC-003',        11600.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta FAC-003',             0, 10000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal FAC-003',         0,  1600.00, @Now, @Now);

    PRINT '   SEED-ENE-004 insertado (11600/11600).';
  END
  ELSE PRINT '   SEED-ENE-004 ya existe, omitido.';

  -- SEED-ENE-005: Compra crédito OC-002 (9280/9280)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-005' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-005', '2026-01-15', '202601', 'DIA', 'OC-002', N'Compra crédito OC-002 Proveedor 2', 'VES', 1, 9280.00, 9280.00, 'APPROVED', 'AP', 'OC-002', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 10, '1.1.06', N'Inventario OC-002',             8000.00,     0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal OC-002',     1280.00,     0, @Now, @Now),
      (@EntryId, 3, 22, '2.1.01', N'CxP OC-002',                        0,  9280.00, @Now, @Now);

    PRINT '   SEED-ENE-005 insertado (9280/9280).';
  END
  ELSE PRINT '   SEED-ENE-005 ya existe, omitido.';

  -- SEED-ENE-006: Pago nómina enero (45000/45000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-006' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-006', '2026-01-31', '202601', 'DIA', N'Pago nómina enero 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 62, '5.2.01', N'Sueldos y salarios enero',     45000.00,     0, 'ADM', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco nómina enero',           0, 45000.00, NULL,  @Now, @Now);

    PRINT '   SEED-ENE-006 insertado (45000/45000).';
  END
  ELSE PRINT '   SEED-ENE-006 ya existe, omitido.';

  -- SEED-ENE-007: Pago alquiler enero (8000/8000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-007' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-007', '2026-01-31', '202601', 'DIA', N'Pago alquiler oficina enero 2026', 'VES', 1, 8000.00, 8000.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 68, '5.2.07', N'Alquiler oficina enero',        8000.00,     0, 'ADM', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco alquiler enero',          0,  8000.00, NULL,  @Now, @Now);

    PRINT '   SEED-ENE-007 insertado (8000/8000).';
  END
  ELSE PRINT '   SEED-ENE-007 ya existe, omitido.';

  -- SEED-ENE-008: Compra suministros OC-003 (5800/5800)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-ENE-008' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-ENE-008', '2026-01-20', '202601', 'DIA', 'OC-003', N'Compra suministros OC-003 Proveedor 3', 'VES', 1, 5800.00, 5800.00, 'APPROVED', 'AP', 'OC-003', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 72, '5.2.11', N'Materiales y suministros OC-003', 5000.00,    0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal OC-003',        800.00,    0, @Now, @Now),
      (@EntryId, 3, 22, '2.1.01', N'CxP OC-003',                           0, 5800.00, @Now, @Now);

    PRINT '   SEED-ENE-008 insertado (5800/5800).';
  END
  ELSE PRINT '   SEED-ENE-008 ya existe, omitido.';

  PRINT '   8 asientos enero OK.';

  -- ============================================================
  -- 6. ASIENTOS DE FEBRERO (8 asientos, periodo 202602)
  -- ============================================================
  PRINT '>> 6. Asientos de febrero...';

  -- SEED-FEB-001: Venta crédito FAC-004 (23200/23200)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-001' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-001', '2026-02-03', '202602', 'DIA', 'FAC-004', N'Venta crédito FAC-004 Servicios Tec 360', 'VES', 1, 23200.00, 23200.00, 'APPROVED', 'AR', 'FAC-004', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  8, '1.1.04', N'CxC FAC-004',                  23200.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta FAC-004',             0, 20000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal FAC-004',         0,  3200.00, @Now, @Now);

    PRINT '   SEED-FEB-001 insertado (23200/23200).';
  END
  ELSE PRINT '   SEED-FEB-001 ya existe, omitido.';

  -- SEED-FEB-002: Compra crédito OC-004 (17400/17400)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-002' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-002', '2026-02-05', '202602', 'DIA', 'OC-004', N'Compra crédito OC-004 Proveedor 4', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AP', 'OC-004', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 10, '1.1.06', N'Inventario OC-004',            15000.00,     0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal OC-004',     2400.00,     0, @Now, @Now),
      (@EntryId, 3, 22, '2.1.01', N'CxP OC-004',                        0, 17400.00, @Now, @Now);

    PRINT '   SEED-FEB-002 insertado (17400/17400).';
  END
  ELSE PRINT '   SEED-FEB-002 ya existe, omitido.';

  -- SEED-FEB-003: Cobro CxC parcial (17400/17400)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-003' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-003', '2026-02-10', '202602', 'DIA', N'Cobro CxC parcial - Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  1, '1.1.02', N'Depósito cobro CxC',           17400.00,     0, @Now, @Now),
      (@EntryId, 2,  8, '1.1.04', N'Abono CxC Inversiones Orion',       0, 17400.00, @Now, @Now);

    PRINT '   SEED-FEB-003 insertado (17400/17400).';
  END
  ELSE PRINT '   SEED-FEB-003 ya existe, omitido.';

  -- SEED-FEB-004: Pago proveedor (13920/13920)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-004' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-004', '2026-02-12', '202602', 'DIA', N'Pago proveedor OC-001', 'VES', 1, 13920.00, 13920.00, 'APPROVED', 'AP', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 22, '2.1.01', N'Pago CxP Proveedor 1',         13920.00,     0, @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Transferencia pago proveedor',       0, 13920.00, @Now, @Now);

    PRINT '   SEED-FEB-004 insertado (13920/13920).';
  END
  ELSE PRINT '   SEED-FEB-004 ya existe, omitido.';

  -- SEED-FEB-005: Venta contado FAC-005 (34800/34800)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-005' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-005', '2026-02-15', '202602', 'DIA', 'FAC-005', N'Venta contado FAC-005 Distribuidora El Sol', 'VES', 1, 34800.00, 34800.00, 'APPROVED', 'AR', 'FAC-005', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  1, '1.1.02', N'Cobro contado FAC-005',        34800.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta FAC-005',             0, 30000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal FAC-005',         0,  4800.00, @Now, @Now);

    PRINT '   SEED-FEB-005 insertado (34800/34800).';
  END
  ELSE PRINT '   SEED-FEB-005 ya existe, omitido.';

  -- SEED-FEB-006: Compra crédito OC-005 (11600/11600)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-006' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, SourceDocumentNo, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-006', '2026-02-18', '202602', 'DIA', 'OC-005', N'Compra crédito OC-005 Proveedor 5', 'VES', 1, 11600.00, 11600.00, 'APPROVED', 'AP', 'OC-005', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 10, '1.1.06', N'Inventario OC-005',            10000.00,     0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal OC-005',     1600.00,     0, @Now, @Now),
      (@EntryId, 3, 22, '2.1.01', N'CxP OC-005',                        0, 11600.00, @Now, @Now);

    PRINT '   SEED-FEB-006 insertado (11600/11600).';
  END
  ELSE PRINT '   SEED-FEB-006 ya existe, omitido.';

  -- SEED-FEB-007: Pago nómina febrero (45000/45000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-007' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-007', '2026-02-28', '202602', 'DIA', N'Pago nómina febrero 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 62, '5.2.01', N'Sueldos y salarios febrero',   45000.00,     0, 'ADM', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco nómina febrero',         0, 45000.00, NULL,  @Now, @Now);

    PRINT '   SEED-FEB-007 insertado (45000/45000).';
  END
  ELSE PRINT '   SEED-FEB-007 ya existe, omitido.';

  -- SEED-FEB-008: Servicios públicos (3500/3500)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-FEB-008' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-FEB-008', '2026-02-28', '202602', 'DIA', N'Servicios públicos febrero 2026', 'VES', 1, 3500.00, 3500.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 69, '5.2.08', N'Servicios públicos febrero',    3500.00,     0, 'ADM', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco serv. públicos',          0,  3500.00, NULL,  @Now, @Now);

    PRINT '   SEED-FEB-008 insertado (3500/3500).';
  END
  ELSE PRINT '   SEED-FEB-008 ya existe, omitido.';

  PRINT '   8 asientos febrero OK.';

  -- ============================================================
  -- 7. ASIENTOS DE MARZO (6 asientos, periodo 202603)
  -- ============================================================
  PRINT '>> 7. Asientos de marzo...';

  -- SEED-MAR-001: Venta crédito (17400/17400)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-001' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-001', '2026-03-05', '202603', 'DIA', N'Venta crédito marzo - Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1,  8, '1.1.04', N'CxC venta marzo',              17400.00,     0, @Now, @Now),
      (@EntryId, 2,  2, '4.1.01', N'Ingreso venta marzo',               0, 15000.00, @Now, @Now),
      (@EntryId, 3,  3, '2.1.03', N'IVA débito fiscal marzo',           0,  2400.00, @Now, @Now);

    PRINT '   SEED-MAR-001 insertado (17400/17400).';
  END
  ELSE PRINT '   SEED-MAR-001 ya existe, omitido.';

  -- SEED-MAR-002: Compra contado (8120/8120)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-002' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-002', '2026-03-08', '202603', 'DIA', N'Compra contado inventario marzo', 'VES', 1, 8120.00, 8120.00, 'APPROVED', 'AP', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 10, '1.1.06', N'Inventario compra contado',     7000.00,     0, @Now, @Now),
      (@EntryId, 2, 11, '1.1.07', N'IVA crédito fiscal compra',     1120.00,     0, @Now, @Now),
      (@EntryId, 3,  1, '1.1.02', N'Pago banco compra contado',          0,  8120.00, @Now, @Now);

    PRINT '   SEED-MAR-002 insertado (8120/8120).';
  END
  ELSE PRINT '   SEED-MAR-002 ya existe, omitido.';

  -- SEED-MAR-003: Pago nómina marzo (45000/45000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-003' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, SourceModule, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-003', '2026-03-15', '202603', 'DIA', N'Pago nómina marzo 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 62, '5.2.01', N'Sueldos y salarios marzo',     45000.00,     0, 'ADM', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco nómina marzo',           0, 45000.00, NULL,  @Now, @Now);

    PRINT '   SEED-MAR-003 insertado (45000/45000).';
  END
  ELSE PRINT '   SEED-MAR-003 ya existe, omitido.';

  -- SEED-MAR-004: Publicidad y mercadeo (6000/6000)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-004' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-004', '2026-03-10', '202603', 'DIA', N'Publicidad y mercadeo marzo 2026', 'VES', 1, 6000.00, 6000.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 73, '5.2.12', N'Publicidad y mercadeo marzo',   6000.00,     0, 'VEN', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Pago banco publicidad',              0,  6000.00, NULL,  @Now, @Now);

    PRINT '   SEED-MAR-004 insertado (6000/6000).';
  END
  ELSE PRINT '   SEED-MAR-004 ya existe, omitido.';

  -- SEED-MAR-005: Comisiones bancarias (1500/1500)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-005' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-005', '2026-03-15', '202603', 'DIA', N'Comisiones bancarias marzo 2026', 'VES', 1, 1500.00, 1500.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CostCenterCode, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 79, '5.3.02', N'Comisiones bancarias marzo',    1500.00,     0, 'FIN', @Now, @Now),
      (@EntryId, 2,  1, '1.1.02', N'Débito banco comisiones',            0,  1500.00, NULL,  @Now, @Now);

    PRINT '   SEED-MAR-005 insertado (1500/1500).';
  END
  ELSE PRINT '   SEED-MAR-005 ya existe, omitido.';

  -- SEED-MAR-006: Depreciación marzo (5625/5625)
  IF NOT EXISTS (SELECT 1 FROM acct.JournalEntry WHERE EntryNumber = 'SEED-MAR-006' AND CompanyId = @CompanyId)
  BEGIN
    INSERT INTO acct.JournalEntry (CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType, Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit, Status, CreatedAt, UpdatedAt, IsDeleted)
    VALUES (@CompanyId, @BranchId, 'SEED-MAR-006', '2026-03-31', '202603', 'DIA', N'Depreciación mensual marzo 2026', 'VES', 1, 5625.00, 5625.00, 'APPROVED', @Now, @Now, 0);

    SET @EntryId = SCOPE_IDENTITY();

    INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount, CreatedAt, UpdatedAt)
    VALUES
      (@EntryId, 1, 71, '5.2.10', N'Gasto depreciación marzo',      5625.00,     0, @Now, @Now),
      (@EntryId, 2, 16, '1.2.02', N'Depreciación acumulada marzo',       0,  5625.00, @Now, @Now);

    PRINT '   SEED-MAR-006 insertado (5625/5625).';
  END
  ELSE PRINT '   SEED-MAR-006 ya existe, omitido.';

  PRINT '   6 asientos marzo OK.';

  -- ============================================================
  -- 8. DOCUMENTOS VENTA (5) - Tabla real: ar.SalesDocument
  -- ============================================================
  PRINT '>> 8. Documentos de venta (ar.SalesDocument)...';

  IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = 'FAC-001')
    INSERT INTO ar.SalesDocument (DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('FAC-001', 'FAC', 'VEN', 'CLI-002', N'Distribuidora El Sol C.A.',   'J-12345679-0', '2026-01-05', 25000.00, 25000.00, 0, 4000.00, 16, 29000.00, 0, 0, '00-0000001');

  IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = 'FAC-002')
    INSERT INTO ar.SalesDocument (DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('FAC-002', 'FAC', 'VEN', 'CLI-003', N'Inversiones Orion S.A.',      'J-98765432-1', '2026-01-08', 15000.00, 15000.00, 0, 2400.00, 16, 17400.00, 0, 0, '00-0000002');

  IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = 'FAC-003')
    INSERT INTO ar.SalesDocument (DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('FAC-003', 'FAC', 'VEN', 'CLI-004', N'Ferretería La Esquina',      'V-15678234-5', '2026-01-12', 10000.00, 10000.00, 0, 1600.00, 16, 11600.00, 0, 0, '00-0000003');

  IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = 'FAC-004')
    INSERT INTO ar.SalesDocument (DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('FAC-004', 'FAC', 'VEN', 'CLI-005', N'Servicios Tecnológicos 360', 'J-40567890-3', '2026-02-03', 20000.00, 20000.00, 0, 3200.00, 16, 23200.00, 0, 0, '00-0000004');

  IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = 'FAC-005')
    INSERT INTO ar.SalesDocument (DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('FAC-005', 'FAC', 'VEN', 'CLI-002', N'Distribuidora El Sol C.A.',   'J-12345679-0', '2026-02-15', 30000.00, 30000.00, 0, 4800.00, 16, 34800.00, 0, 0, '00-0000005');

  PRINT '   5 documentos venta OK.';

  -- ============================================================
  -- 9. DOCUMENTOS COMPRA (5) - Tabla real: ap.PurchaseDocument
  -- ============================================================
  PRINT '>> 9. Documentos de compra (ap.PurchaseDocument)...';

  IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = 'OC-001')
    INSERT INTO ap.PurchaseDocument (DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, ExemptTotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('OC-001', 'FAC', 'COM', 'PROV-001', N'Proveedor 1', 'J-11111111-1', '2026-01-10', 12000.00, 12000.00, 0, 1920.00, 16, 13920.00, 0, 0, 0, '00-0000001');

  IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = 'OC-002')
    INSERT INTO ap.PurchaseDocument (DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, ExemptTotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('OC-002', 'FAC', 'COM', 'PROV-002', N'Proveedor 2', 'J-22222222-2', '2026-01-15', 8000.00, 8000.00, 0, 1280.00, 16, 9280.00, 0, 0, 0, '00-0000002');

  IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = 'OC-003')
    INSERT INTO ap.PurchaseDocument (DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, ExemptTotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('OC-003', 'FAC', 'COM', 'PROV-003', N'Proveedor 3', 'J-33333333-3', '2026-01-20', 5000.00, 5000.00, 0, 800.00, 16, 5800.00, 0, 0, 0, '00-0000003');

  IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = 'OC-004')
    INSERT INTO ap.PurchaseDocument (DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, ExemptTotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('OC-004', 'FAC', 'COM', 'PROV-004', N'Proveedor 4', 'J-44444444-4', '2026-02-05', 15000.00, 15000.00, 0, 2400.00, 16, 17400.00, 0, 0, 0, '00-0000004');

  IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = 'OC-005')
    INSERT INTO ap.PurchaseDocument (DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId, DocumentDate, SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, ExemptTotalAmount, DiscountAmount, IsVoided, ControlNumber)
    VALUES ('OC-005', 'FAC', 'COM', 'PROV-005', N'Proveedor 5', 'J-55555555-5', '2026-02-18', 10000.00, 10000.00, 0, 1600.00, 16, 11600.00, 0, 0, 0, '00-0000005');

  PRINT '   5 documentos compra OK.';

  -- ============================================================
  -- 10. ACTIVOS FIJOS (5)
  -- ============================================================
  PRINT '>> 10. Activos fijos...';

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-001')
    INSERT INTO acct.FixedAsset (CompanyId, BranchId, AssetCode, Description, CategoryId, AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths, DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode, CostCenterCode, Status, CurrencyCode, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, 'AF-001', N'Servidor Dell PowerEdge',
      (SELECT TOP 1 CategoryId FROM acct.FixedAssetCategory WHERE CategoryCode = 'EQU' AND CompanyId = @CompanyId AND CountryCode = 'VE'),
      '2026-01-15', 15000.00, 1500.00, 36, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'OPE', 'ACTIVE', 'VES', 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-002')
    INSERT INTO acct.FixedAsset (CompanyId, BranchId, AssetCode, Description, CategoryId, AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths, DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode, CostCenterCode, Status, CurrencyCode, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, 'AF-002', N'Vehículo Toyota Hilux',
      (SELECT TOP 1 CategoryId FROM acct.FixedAssetCategory WHERE CategoryCode = 'VEH' AND CompanyId = @CompanyId AND CountryCode = 'VE'),
      '2026-01-20', 85000.00, 8500.00, 60, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'VEN', 'ACTIVE', 'VES', 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-003')
    INSERT INTO acct.FixedAsset (CompanyId, BranchId, AssetCode, Description, CategoryId, AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths, DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode, CostCenterCode, Status, CurrencyCode, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, 'AF-003', N'Mobiliario oficina',
      (SELECT TOP 1 CategoryId FROM acct.FixedAssetCategory WHERE CategoryCode = 'MOB' AND CompanyId = @CompanyId AND CountryCode = 'VE'),
      '2026-02-01', 12000.00, 0.00, 120, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'ADM', 'ACTIVE', 'VES', 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-004')
    INSERT INTO acct.FixedAsset (CompanyId, BranchId, AssetCode, Description, CategoryId, AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths, DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode, CostCenterCode, Status, CurrencyCode, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, 'AF-004', N'Impresora industrial',
      (SELECT TOP 1 CategoryId FROM acct.FixedAssetCategory WHERE CategoryCode = 'MAQ' AND CompanyId = @CompanyId AND CountryCode = 'VE'),
      '2026-02-15', 25000.00, 2500.00, 120, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'OPE', 'ACTIVE', 'VES', 0, @Now, @Now);

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-005')
    INSERT INTO acct.FixedAsset (CompanyId, BranchId, AssetCode, Description, CategoryId, AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths, DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode, CostCenterCode, Status, CurrencyCode, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, 'AF-005', N'Software ERP licencia',
      (SELECT TOP 1 CategoryId FROM acct.FixedAssetCategory WHERE CategoryCode = 'INT' AND CompanyId = @CompanyId AND CountryCode = 'VE'),
      '2026-03-01', 18000.00, 0.00, 60, 'STRAIGHT_LINE', '1.2.04', '1.2.04', '5.2.10', 'ADM', 'ACTIVE', 'VES', 0, @Now, @Now);

  PRINT '   5 activos fijos OK.';

  -- ============================================================
  -- 11. DEPRECIACIONES (11 registros)
  -- ============================================================
  PRINT '>> 11. Depreciaciones mensuales...';

  DECLARE @AssetId BIGINT;

  -- AF-001: 375/mes = (15000-1500)/36
  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-001';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-01')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-01', '2026-01-31', 375.00, 375.00, 14625.00, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-02')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-02', '2026-02-28', 375.00, 750.00, 14250.00, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-03')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-03', '2026-03-31', 375.00, 1125.00, 13875.00, 'POSTED', @Now);
  END

  -- AF-002: 1275/mes = (85000-8500)/60
  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-002';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-01')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-01', '2026-01-31', 1275.00, 1275.00, 83725.00, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-02')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-02', '2026-02-28', 1275.00, 2550.00, 82450.00, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-03')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-03', '2026-03-31', 1275.00, 3825.00, 81175.00, 'POSTED', @Now);
  END

  -- AF-003: 100/mes = (12000-0)/120
  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-003';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-02')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-02', '2026-02-28', 100.00, 100.00, 11900.00, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-03')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-03', '2026-03-31', 100.00, 200.00, 11800.00, 'POSTED', @Now);
  END

  -- AF-004: 187.50/mes = (25000-2500)/120
  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-004';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-02')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-02', '2026-02-28', 187.50, 187.50, 24812.50, 'POSTED', @Now);

    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-03')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-03', '2026-03-31', 187.50, 375.00, 24625.00, 'POSTED', @Now);
  END

  -- AF-005: 300/mes = (18000-0)/60
  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-005';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetDepreciation WHERE AssetId = @AssetId AND PeriodCode = '2026-03')
      INSERT INTO acct.FixedAssetDepreciation (AssetId, PeriodCode, DepreciationDate, Amount, AccumulatedDepreciation, BookValue, Status, CreatedAt)
      VALUES (@AssetId, '2026-03', '2026-03-31', 300.00, 300.00, 17700.00, 'POSTED', @Now);
  END

  PRINT '   11 registros depreciación OK.';

  -- ============================================================
  -- 12. MEJORA A ACTIVO (AF-001 - RAM upgrade)
  -- ============================================================
  PRINT '>> 12. Mejora activo AF-001...';

  SELECT @AssetId = AssetId FROM acct.FixedAsset WHERE CompanyId = @CompanyId AND AssetCode = 'AF-001';
  IF @AssetId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetImprovement WHERE AssetId = @AssetId AND ImprovementDate = '2026-02-20')
      INSERT INTO acct.FixedAssetImprovement (AssetId, ImprovementDate, Description, Amount, AdditionalLifeMonths, CreatedBy, CreatedAt)
      VALUES (@AssetId, '2026-02-20', N'Upgrade RAM 64GB - Servidor Dell PowerEdge', 2500.00, 6, 'SEED', @Now);

    PRINT '   Mejora AF-001 OK.';
  END
  ELSE
    PRINT '   AF-001 no encontrado, mejora omitida.';

  -- ============================================================
  -- 13. PRESUPUESTO (1 cabecera + 5 líneas)
  -- ============================================================
  PRINT '>> 13. Presupuesto operativo 2026...';

  DECLARE @BudgetId INT;

  IF NOT EXISTS (SELECT 1 FROM acct.Budget WHERE CompanyId = @CompanyId AND BudgetName = N'Presupuesto Operativo 2026' AND FiscalYear = 2026)
  BEGIN
    INSERT INTO acct.Budget (CompanyId, BudgetName, FiscalYear, CostCenterCode, Status, Notes, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'Presupuesto Operativo 2026', 2026, NULL, 'APPROVED', N'Presupuesto general de operaciones 2026', 0, @Now, @Now);

    SET @BudgetId = SCOPE_IDENTITY();

    -- 4.1.01 Ventas: 25k(ene-mar), 30k(abr-jun), 35k(jul-sep), 40k(oct-dic)
    INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, Notes)
    VALUES (@BudgetId, '4.1.01', 25000, 25000, 25000, 30000, 30000, 30000, 35000, 35000, 35000, 40000, 40000, 40000, N'Proyección ventas escalonada');

    -- 5.1.01 Costo Ventas: 60% de ventas
    INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, Notes)
    VALUES (@BudgetId, '5.1.01', 15000, 15000, 15000, 18000, 18000, 18000, 21000, 21000, 21000, 24000, 24000, 24000, N'Costo 60% de ventas');

    -- 5.2.01 Sueldos: 45000 constante
    INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, Notes)
    VALUES (@BudgetId, '5.2.01', 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, N'Nómina fija mensual');

    -- 5.2.07 Alquileres: 8000 constante
    INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, Notes)
    VALUES (@BudgetId, '5.2.07', 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, N'Alquiler oficina fijo');

    -- 5.2.10 Depreciación: 5000 constante
    INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, Notes)
    VALUES (@BudgetId, '5.2.10', 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, N'Depreciación estimada mensual');

    PRINT '   Presupuesto + 5 líneas OK.';
  END
  ELSE
    PRINT '   Presupuesto Operativo 2026 ya existe, omitido.';

  -- ============================================================
  -- 14. ASIENTOS RECURRENTES (3)
  -- ============================================================
  PRINT '>> 14. Asientos recurrentes...';

  DECLARE @RecEntryId INT;

  -- Alquiler Mensual
  IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = @CompanyId AND TemplateName = N'Alquiler Mensual')
  BEGIN
    INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, LastExecutedDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive, IsDeleted, CreatedAt)
    VALUES (@CompanyId, N'Alquiler Mensual', 'MONTHLY', '2026-04-01', '2026-03-31', 3, NULL, 'DIA', N'Pago alquiler oficina', 1, 0, @Now);

    SET @RecEntryId = SCOPE_IDENTITY();

    INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
    VALUES
      (@RecEntryId, '5.2.07', N'Alquiler oficina',     'ADM', 8000.00,    0),
      (@RecEntryId, '1.1.02', N'Pago banco alquiler',  NULL,       0, 8000.00);

    PRINT '   Recurrente: Alquiler Mensual OK.';
  END
  ELSE PRINT '   Recurrente: Alquiler Mensual ya existe, omitido.';

  -- Servicios Públicos
  IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = @CompanyId AND TemplateName = N'Servicios Públicos')
  BEGIN
    INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, LastExecutedDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive, IsDeleted, CreatedAt)
    VALUES (@CompanyId, N'Servicios Públicos', 'MONTHLY', '2026-04-01', '2026-02-28', 2, NULL, 'DIA', N'Pago servicios públicos', 1, 0, @Now);

    SET @RecEntryId = SCOPE_IDENTITY();

    INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
    VALUES
      (@RecEntryId, '5.2.08', N'Servicios públicos',       'ADM', 3500.00,    0),
      (@RecEntryId, '1.1.02', N'Pago banco serv. púb.',    NULL,       0, 3500.00);

    PRINT '   Recurrente: Servicios Públicos OK.';
  END
  ELSE PRINT '   Recurrente: Servicios Públicos ya existe, omitido.';

  -- Depreciación Mensual
  IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = @CompanyId AND TemplateName = N'Depreciación Mensual')
  BEGIN
    INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, LastExecutedDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive, IsDeleted, CreatedAt)
    VALUES (@CompanyId, N'Depreciación Mensual', 'MONTHLY', '2026-04-01', '2026-03-31', 3, NULL, 'DIA', N'Depreciación mensual activos fijos', 1, 0, @Now);

    SET @RecEntryId = SCOPE_IDENTITY();

    INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
    VALUES
      (@RecEntryId, '5.2.10', N'Gasto depreciación',          NULL, 5625.00,    0),
      (@RecEntryId, '1.2.02', N'Depreciación acumulada',      NULL,      0, 5625.00);

    PRINT '   Recurrente: Depreciación Mensual OK.';
  END
  ELSE PRINT '   Recurrente: Depreciación Mensual ya existe, omitido.';

  PRINT '   3 asientos recurrentes OK.';

  -- ============================================================
  -- 15. RETENCIONES IVA (3)
  -- ============================================================
  PRINT '>> 15. Retenciones IVA...';

  -- RET-IVA-202601-001: OC-001, 75% de IVA 1920 = 1440
  IF NOT EXISTS (SELECT 1 FROM fiscal.WithholdingVoucher WHERE CompanyId = @CompanyId AND VoucherNumber = 'RET-IVA-202601-001')
    INSERT INTO fiscal.WithholdingVoucher (CompanyId, VoucherNumber, VoucherDate, WithholdingType, ThirdPartyId, ThirdPartyName, DocumentNumber, DocumentDate, TaxableBase, WithholdingRate, WithholdingAmount, PeriodCode, Status, CountryCode, CreatedBy, CreatedAt)
    VALUES (@CompanyId, 'RET-IVA-202601-001', '2026-01-10', 'IVA', 'J-11111111-1', N'Proveedor 1', 'OC-001', '2026-01-10', 12000.00, 75.00, 1440.00, '202601', 'ACTIVE', 'VE', 'SEED', @Now);

  -- RET-IVA-202601-002: OC-002, 75% de IVA 1280 = 960
  IF NOT EXISTS (SELECT 1 FROM fiscal.WithholdingVoucher WHERE CompanyId = @CompanyId AND VoucherNumber = 'RET-IVA-202601-002')
    INSERT INTO fiscal.WithholdingVoucher (CompanyId, VoucherNumber, VoucherDate, WithholdingType, ThirdPartyId, ThirdPartyName, DocumentNumber, DocumentDate, TaxableBase, WithholdingRate, WithholdingAmount, PeriodCode, Status, CountryCode, CreatedBy, CreatedAt)
    VALUES (@CompanyId, 'RET-IVA-202601-002', '2026-01-15', 'IVA', 'J-22222222-2', N'Proveedor 2', 'OC-002', '2026-01-15', 8000.00, 75.00, 960.00, '202601', 'ACTIVE', 'VE', 'SEED', @Now);

  -- RET-IVA-202602-001: OC-004, 75% de IVA 2400 = 1800
  IF NOT EXISTS (SELECT 1 FROM fiscal.WithholdingVoucher WHERE CompanyId = @CompanyId AND VoucherNumber = 'RET-IVA-202602-001')
    INSERT INTO fiscal.WithholdingVoucher (CompanyId, VoucherNumber, VoucherDate, WithholdingType, ThirdPartyId, ThirdPartyName, DocumentNumber, DocumentDate, TaxableBase, WithholdingRate, WithholdingAmount, PeriodCode, Status, CountryCode, CreatedBy, CreatedAt)
    VALUES (@CompanyId, 'RET-IVA-202602-001', '2026-02-05', 'IVA', 'J-44444444-4', N'Proveedor 4', 'OC-004', '2026-02-05', 15000.00, 75.00, 1800.00, '202602', 'ACTIVE', 'VE', 'SEED', @Now);

  PRINT '   3 retenciones IVA OK.';

  -- ============================================================
  -- COMMIT
  -- ============================================================
  COMMIT;
  PRINT '';
  PRINT '>> Seed contabilidad demo completado exitosamente.';
  PRINT '>> Resumen: 12 períodos, 5 centros costo, 4 clientes,';
  PRINT '>>   23 asientos contables (1 apertura + 8 ene + 8 feb + 6 mar),';
  PRINT '>>   5 doc venta, 5 doc compra, 5 activos fijos,';
  PRINT '>>   11 depreciaciones, 1 mejora, 1 presupuesto (5 líneas),';
  PRINT '>>   3 asientos recurrentes, 3 retenciones IVA.';
  PRINT '=== FIN SEED CONTABILIDAD DEMO ===';

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT '';
  PRINT '>> ERROR en seed contabilidad demo:';
  PRINT '>> Número: '  + CAST(ERROR_NUMBER() AS NVARCHAR(20));
  PRINT '>> Mensaje: ' + ERROR_MESSAGE();
  PRINT '>> Línea: '   + CAST(ERROR_LINE() AS NVARCHAR(20));
END CATCH
GO
