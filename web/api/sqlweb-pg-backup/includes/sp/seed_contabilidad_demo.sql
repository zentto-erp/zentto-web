/*
 * seed_contabilidad_demo.sql (PostgreSQL)
 * Datos de demostración completos para validar todos los flujos contables
 * Empresa: VE, CompanyId=1, BranchId=1, Moneda=VES, IVA=16%
 * Idempotente: ON CONFLICT DO NOTHING / IF NOT EXISTS antes de cada INSERT
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

DO $$
DECLARE
  v_company_id  INT := 1;
  v_branch_id   INT := 1;
  v_now         TIMESTAMP := (NOW() AT TIME ZONE 'UTC');
  v_entry_id    BIGINT;
  v_asset_id    BIGINT;
  v_budget_id   INT;
  v_rec_id      INT;
BEGIN

  RAISE NOTICE '=== SEED CONTABILIDAD DEMO ===';
  RAISE NOTICE '>> Iniciando...';

  -- ============================================================
  -- 1. PERÍODOS FISCALES 2026 (12 meses)
  -- ============================================================
  RAISE NOTICE '>> 1. Períodos fiscales 2026...';

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202601', 'Enero 2026',      2026, 1,  '2026-01-01', '2026-01-31', 'CLOSED', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202602', 'Febrero 2026',    2026, 2,  '2026-02-01', '2026-02-28', 'CLOSED', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202603', 'Marzo 2026',      2026, 3,  '2026-03-01', '2026-03-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202604', 'Abril 2026',      2026, 4,  '2026-04-01', '2026-04-30', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202605', 'Mayo 2026',       2026, 5,  '2026-05-01', '2026-05-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202606', 'Junio 2026',      2026, 6,  '2026-06-01', '2026-06-30', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202607', 'Julio 2026',      2026, 7,  '2026-07-01', '2026-07-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202608', 'Agosto 2026',     2026, 8,  '2026-08-01', '2026-08-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202609', 'Septiembre 2026', 2026, 9,  '2026-09-01', '2026-09-30', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202610', 'Octubre 2026',    2026, 10, '2026-10-01', '2026-10-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202611', 'Noviembre 2026',  2026, 11, '2026-11-01', '2026-11-30', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, '202612', 'Diciembre 2026',  2026, 12, '2026-12-01', '2026-12-31', 'OPEN', v_now, v_now) ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;

  RAISE NOTICE '   12 períodos fiscales OK.';

  -- ============================================================
  -- 2. CENTROS DE COSTO (5)
  -- ============================================================
  RAISE NOTICE '>> 2. Centros de costo...';

  INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ADM', 'Administración', NULL, 1, TRUE, FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;

  INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'VEN', 'Ventas', NULL, 1, TRUE, FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;

  INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'OPE', 'Operaciones', NULL, 1, TRUE, FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;

  INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'FIN', 'Finanzas', NULL, 1, TRUE, FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;

  INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ALM', 'Almacén', NULL, 1, TRUE, FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;

  RAISE NOTICE '   5 centros de costo OK.';

  -- ============================================================
  -- 3. CLIENTES (4)
  -- ============================================================
  RAISE NOTICE '>> 3. Clientes...';

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "TotalBalance", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
  VALUES (v_company_id, 'CLI-002', 'Distribuidora El Sol C.A.', 'J-12345679-0', 'contacto@elsol.com.ve', '0212-5551234', 'Av. Libertador, Caracas', 50000, 0, TRUE, v_now, v_now, FALSE)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "TotalBalance", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
  VALUES (v_company_id, 'CLI-003', 'Inversiones Orion S.A.', 'J-98765432-1', 'admin@orionsa.com', '0212-5559876', 'Calle 10, Valencia', 75000, 0, TRUE, v_now, v_now, FALSE)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "TotalBalance", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
  VALUES (v_company_id, 'CLI-004', 'Ferretería La Esquina', 'V-15678234-5', 'ventas@laesquina.com', '0241-8001234', 'Av. Bolívar, Maracay', 30000, 0, TRUE, v_now, v_now, FALSE)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "TotalBalance", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
  VALUES (v_company_id, 'CLI-005', 'Servicios Tecnológicos 360', 'J-40567890-3', 'info@st360.com', '0212-5554567', 'Torre Empresarial, Caracas', 100000, 0, TRUE, v_now, v_now, FALSE)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  RAISE NOTICE '   4 clientes OK.';

  -- ============================================================
  -- 4. ASIENTO DE APERTURA (775000 = 775000)
  -- ============================================================
  RAISE NOTICE '>> 4. Asiento de apertura...';

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-APE-001' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-APE-001', '2026-01-01', '202601', 'APE', 'Asiento de apertura ejercicio 2026', 'VES', 1, 775000.00, 775000.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;

    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
      VALUES
        (v_entry_id,  1,  6, '1.1.01', 'Saldo inicial Caja',            50000.00,       0, v_now, v_now),
        (v_entry_id,  2,  1, '1.1.02', 'Saldo inicial Bancos',         200000.00,       0, v_now, v_now),
        (v_entry_id,  3,  8, '1.1.04', 'Saldo inicial CxC',             75000.00,       0, v_now, v_now),
        (v_entry_id,  4, 10, '1.1.06', 'Saldo inicial Inventario',     150000.00,       0, v_now, v_now),
        (v_entry_id,  5, 15, '1.2.01', 'Saldo PPE',                    300000.00,       0, v_now, v_now),
        (v_entry_id,  6, 16, '1.2.02', 'Dep Acum PPE',                       0,  60000.00, v_now, v_now),
        (v_entry_id,  7, 22, '2.1.01', 'Saldo CxP',                          0,  80000.00, v_now, v_now),
        (v_entry_id,  8, 25, '2.1.05', 'Nómina por pagar',                   0,  35000.00, v_now, v_now),
        (v_entry_id,  9, 37, '3.1.01', 'Capital Social',                     0, 400000.00, v_now, v_now),
        (v_entry_id, 10, 43, '3.3.01', 'Utilidades Acumuladas',              0, 200000.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine SEED-APE-001 skip (cuenta no encontrada)';
    END;

    RAISE NOTICE '   Asiento apertura SEED-APE-001 insertado (775000/775000).';
  ELSE
    RAISE NOTICE '   Asiento apertura SEED-APE-001 ya existe, omitido.';
  END IF;

  -- ============================================================
  -- 5. ASIENTOS DE ENERO (8 asientos, periodo 202601)
  -- ============================================================
  RAISE NOTICE '>> 5. Asientos de enero...';

  -- SEED-ENE-001: Venta contado FAC-001 (29000/29000)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-001' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-001', '2026-01-05', '202601', 'DIA', 'FAC-001', 'Venta contado FAC-001 Distribuidora El Sol', 'VES', 1, 29000.00, 29000.00, 'APPROVED', 'AR', 'FAC-001', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
      VALUES
        (v_entry_id, 1,  1, '1.1.02', 'Cobro contado FAC-001',        29000.00,     0, v_now, v_now),
        (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta FAC-001',             0, 25000.00, v_now, v_now),
        (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal FAC-001',         0,  4000.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine SEED-ENE-001 skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-001 insertado (29000/29000).';
  ELSE RAISE NOTICE '   SEED-ENE-001 ya existe, omitido.'; END IF;

  -- SEED-ENE-002: Venta crédito FAC-002 (17400/17400)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-002' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-002', '2026-01-08', '202601', 'DIA', 'FAC-002', 'Venta crédito FAC-002 Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', 'FAC-002', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  8, '1.1.04', 'CxC FAC-002',                  17400.00,     0, v_now, v_now),
      (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta FAC-002',             0, 15000.00, v_now, v_now),
      (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal FAC-002',         0,  2400.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-002 insertado (17400/17400).';
  ELSE RAISE NOTICE '   SEED-ENE-002 ya existe, omitido.'; END IF;

  -- SEED-ENE-003: Compra crédito OC-001 (13920/13920)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-003' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-003', '2026-01-10', '202601', 'DIA', 'OC-001', 'Compra crédito OC-001 Proveedor 1', 'VES', 1, 13920.00, 13920.00, 'APPROVED', 'AP', 'OC-001', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 10, '1.1.06', 'Inventario OC-001',            12000.00,     0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal OC-001',     1920.00,     0, v_now, v_now),
      (v_entry_id, 3, 22, '2.1.01', 'CxP OC-001',                        0, 13920.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-003 insertado (13920/13920).';
  ELSE RAISE NOTICE '   SEED-ENE-003 ya existe, omitido.'; END IF;

  -- SEED-ENE-004: Venta contado FAC-003 (11600/11600)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-004' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-004', '2026-01-12', '202601', 'DIA', 'FAC-003', 'Venta contado FAC-003 Ferretería La Esquina', 'VES', 1, 11600.00, 11600.00, 'APPROVED', 'AR', 'FAC-003', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  6, '1.1.01', 'Cobro contado FAC-003',        11600.00,     0, v_now, v_now),
      (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta FAC-003',             0, 10000.00, v_now, v_now),
      (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal FAC-003',         0,  1600.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-004 insertado (11600/11600).';
  ELSE RAISE NOTICE '   SEED-ENE-004 ya existe, omitido.'; END IF;

  -- SEED-ENE-005: Compra crédito OC-002 (9280/9280)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-005' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-005', '2026-01-15', '202601', 'DIA', 'OC-002', 'Compra crédito OC-002 Proveedor 2', 'VES', 1, 9280.00, 9280.00, 'APPROVED', 'AP', 'OC-002', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 10, '1.1.06', 'Inventario OC-002',             8000.00,     0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal OC-002',     1280.00,     0, v_now, v_now),
      (v_entry_id, 3, 22, '2.1.01', 'CxP OC-002',                        0,  9280.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-005 insertado (9280/9280).';
  ELSE RAISE NOTICE '   SEED-ENE-005 ya existe, omitido.'; END IF;

  -- SEED-ENE-006: Pago nómina enero (45000/45000)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-006' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-006', '2026-01-31', '202601', 'DIA', 'Pago nómina enero 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 62, '5.2.01', 'Sueldos y salarios enero',     45000.00,     0, 'ADM', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco nómina enero',           0, 45000.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-006 insertado (45000/45000).';
  ELSE RAISE NOTICE '   SEED-ENE-006 ya existe, omitido.'; END IF;

  -- SEED-ENE-007: Pago alquiler enero (8000/8000)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-007' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-007', '2026-01-31', '202601', 'DIA', 'Pago alquiler oficina enero 2026', 'VES', 1, 8000.00, 8000.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 68, '5.2.07', 'Alquiler oficina enero',        8000.00,     0, 'ADM', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco alquiler enero',          0,  8000.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-007 insertado (8000/8000).';
  ELSE RAISE NOTICE '   SEED-ENE-007 ya existe, omitido.'; END IF;

  -- SEED-ENE-008: Compra suministros OC-003 (5800/5800)
  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-ENE-008' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-ENE-008', '2026-01-20', '202601', 'DIA', 'OC-003', 'Compra suministros OC-003 Proveedor 3', 'VES', 1, 5800.00, 5800.00, 'APPROVED', 'AP', 'OC-003', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 72, '5.2.11', 'Materiales y suministros OC-003', 5000.00,    0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal OC-003',        800.00,    0, v_now, v_now),
      (v_entry_id, 3, 22, '2.1.01', 'CxP OC-003',                           0, 5800.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-ENE-008 insertado (5800/5800).';
  ELSE RAISE NOTICE '   SEED-ENE-008 ya existe, omitido.'; END IF;

  RAISE NOTICE '   8 asientos enero OK.';

  -- ============================================================
  -- 6. ASIENTOS DE FEBRERO (8 asientos, periodo 202602)
  -- ============================================================
  RAISE NOTICE '>> 6. Asientos de febrero...';

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-001' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-001', '2026-02-03', '202602', 'DIA', 'FAC-004', 'Venta crédito FAC-004 Servicios Tec 360', 'VES', 1, 23200.00, 23200.00, 'APPROVED', 'AR', 'FAC-004', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  8, '1.1.04', 'CxC FAC-004',                  23200.00,     0, v_now, v_now),
      (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta FAC-004',             0, 20000.00, v_now, v_now),
      (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal FAC-004',         0,  3200.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-001 insertado (23200/23200).';
  ELSE RAISE NOTICE '   SEED-FEB-001 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-002' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-002', '2026-02-05', '202602', 'DIA', 'OC-004', 'Compra crédito OC-004 Proveedor 4', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AP', 'OC-004', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 10, '1.1.06', 'Inventario OC-004',            15000.00,     0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal OC-004',     2400.00,     0, v_now, v_now),
      (v_entry_id, 3, 22, '2.1.01', 'CxP OC-004',                        0, 17400.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-002 insertado (17400/17400).';
  ELSE RAISE NOTICE '   SEED-FEB-002 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-003' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-003', '2026-02-10', '202602', 'DIA', 'Cobro CxC parcial - Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  1, '1.1.02', 'Depósito cobro CxC',           17400.00,     0, v_now, v_now),
      (v_entry_id, 2,  8, '1.1.04', 'Abono CxC Inversiones Orion',       0, 17400.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-003 insertado (17400/17400).';
  ELSE RAISE NOTICE '   SEED-FEB-003 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-004' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-004', '2026-02-12', '202602', 'DIA', 'Pago proveedor OC-001', 'VES', 1, 13920.00, 13920.00, 'APPROVED', 'AP', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 22, '2.1.01', 'Pago CxP Proveedor 1',         13920.00,     0, v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Transferencia pago proveedor',       0, 13920.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-004 insertado (13920/13920).';
  ELSE RAISE NOTICE '   SEED-FEB-004 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-005' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-005', '2026-02-15', '202602', 'DIA', 'FAC-005', 'Venta contado FAC-005 Distribuidora El Sol', 'VES', 1, 34800.00, 34800.00, 'APPROVED', 'AR', 'FAC-005', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  1, '1.1.02', 'Cobro contado FAC-005',        34800.00,     0, v_now, v_now),
      (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta FAC-005',             0, 30000.00, v_now, v_now),
      (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal FAC-005',         0,  4800.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-005 insertado (34800/34800).';
  ELSE RAISE NOTICE '   SEED-FEB-005 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-006' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "SourceDocumentNo", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-006', '2026-02-18', '202602', 'DIA', 'OC-005', 'Compra crédito OC-005 Proveedor 5', 'VES', 1, 11600.00, 11600.00, 'APPROVED', 'AP', 'OC-005', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 10, '1.1.06', 'Inventario OC-005',            10000.00,     0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal OC-005',     1600.00,     0, v_now, v_now),
      (v_entry_id, 3, 22, '2.1.01', 'CxP OC-005',                        0, 11600.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-006 insertado (11600/11600).';
  ELSE RAISE NOTICE '   SEED-FEB-006 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-007' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-007', '2026-02-28', '202602', 'DIA', 'Pago nómina febrero 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 62, '5.2.01', 'Sueldos y salarios febrero',   45000.00,     0, 'ADM', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco nómina febrero',         0, 45000.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-007 insertado (45000/45000).';
  ELSE RAISE NOTICE '   SEED-FEB-007 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-FEB-008' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-FEB-008', '2026-02-28', '202602', 'DIA', 'Servicios públicos febrero 2026', 'VES', 1, 3500.00, 3500.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 69, '5.2.08', 'Servicios públicos febrero',    3500.00,     0, 'ADM', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco serv. públicos',          0,  3500.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-FEB-008 insertado (3500/3500).';
  ELSE RAISE NOTICE '   SEED-FEB-008 ya existe, omitido.'; END IF;

  RAISE NOTICE '   8 asientos febrero OK.';

  -- ============================================================
  -- 7. ASIENTOS DE MARZO (6 asientos, periodo 202603)
  -- ============================================================
  RAISE NOTICE '>> 7. Asientos de marzo...';

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-001' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-001', '2026-03-05', '202603', 'DIA', 'Venta crédito marzo - Inversiones Orion', 'VES', 1, 17400.00, 17400.00, 'APPROVED', 'AR', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1,  8, '1.1.04', 'CxC venta marzo',              17400.00,     0, v_now, v_now),
      (v_entry_id, 2,  2, '4.1.01', 'Ingreso venta marzo',               0, 15000.00, v_now, v_now),
      (v_entry_id, 3,  3, '2.1.03', 'IVA débito fiscal marzo',           0,  2400.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-001 insertado (17400/17400).';
  ELSE RAISE NOTICE '   SEED-MAR-001 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-002' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-002', '2026-03-08', '202603', 'DIA', 'Compra contado inventario marzo', 'VES', 1, 8120.00, 8120.00, 'APPROVED', 'AP', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 10, '1.1.06', 'Inventario compra contado',     7000.00,     0, v_now, v_now),
      (v_entry_id, 2, 11, '1.1.07', 'IVA crédito fiscal compra',     1120.00,     0, v_now, v_now),
      (v_entry_id, 3,  1, '1.1.02', 'Pago banco compra contado',          0,  8120.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-002 insertado (8120/8120).';
  ELSE RAISE NOTICE '   SEED-MAR-002 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-003' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-003', '2026-03-15', '202603', 'DIA', 'Pago nómina marzo 2026', 'VES', 1, 45000.00, 45000.00, 'APPROVED', 'HR', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 62, '5.2.01', 'Sueldos y salarios marzo',     45000.00,     0, 'ADM', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco nómina marzo',           0, 45000.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-003 insertado (45000/45000).';
  ELSE RAISE NOTICE '   SEED-MAR-003 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-004' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-004', '2026-03-10', '202603', 'DIA', 'Publicidad y mercadeo marzo 2026', 'VES', 1, 6000.00, 6000.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 73, '5.2.12', 'Publicidad y mercadeo marzo',   6000.00,     0, 'VEN', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Pago banco publicidad',              0,  6000.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-004 insertado (6000/6000).';
  ELSE RAISE NOTICE '   SEED-MAR-004 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-005' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-005', '2026-03-15', '202603', 'DIA', 'Comisiones bancarias marzo 2026', 'VES', 1, 1500.00, 1500.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CostCenterCode", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 79, '5.3.02', 'Comisiones bancarias marzo',    1500.00,     0, 'FIN', v_now, v_now),
      (v_entry_id, 2,  1, '1.1.02', 'Débito banco comisiones',            0,  1500.00, NULL,  v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-005 insertado (1500/1500).';
  ELSE RAISE NOTICE '   SEED-MAR-005 ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."JournalEntry" WHERE "EntryNumber" = 'SEED-MAR-006' AND "CompanyId" = v_company_id) THEN
    INSERT INTO acct."JournalEntry" ("CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType", "Concept", "CurrencyCode", "ExchangeRate", "TotalDebit", "TotalCredit", "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES (v_company_id, v_branch_id, 'SEED-MAR-006', '2026-03-31', '202603', 'DIA', 'Depreciación mensual marzo 2026', 'VES', 1, 5625.00, 5625.00, 'APPROVED', v_now, v_now, FALSE)
    RETURNING "JournalEntryId" INTO v_entry_id;
    BEGIN
      INSERT INTO acct."JournalEntryLine" ("JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot", "Description", "DebitAmount", "CreditAmount", "CreatedAt", "UpdatedAt")
    VALUES
      (v_entry_id, 1, 71, '5.2.10', 'Gasto depreciación marzo',      5625.00,     0, v_now, v_now),
      (v_entry_id, 2, 16, '1.2.02', 'Depreciación acumulada marzo',       0,  5625.00, v_now, v_now);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_contabilidad_demo: JournalEntryLine skip (cuenta no encontrada)';
    END;
    RAISE NOTICE '   SEED-MAR-006 insertado (5625/5625).';
  ELSE RAISE NOTICE '   SEED-MAR-006 ya existe, omitido.'; END IF;

  RAISE NOTICE '   6 asientos marzo OK.';

  -- ============================================================
  -- 8. DOCUMENTOS VENTA (5)
  -- ============================================================
  RAISE NOTICE '>> 8. Documentos de venta (ar."SalesDocument")...';

  INSERT INTO ar."SalesDocument" ("DocumentNumber", "SerialType", "OperationType", "CustomerCode", "CustomerName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('FAC-001', 'FAC', 'VEN', 'CLI-002', 'Distribuidora El Sol C.A.',   'J-12345679-0', '2026-01-05', 25000.00, 25000.00, 0, 4000.00, 16, 29000.00, 0, FALSE, '00-0000001')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ar."SalesDocument" ("DocumentNumber", "SerialType", "OperationType", "CustomerCode", "CustomerName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('FAC-002', 'FAC', 'VEN', 'CLI-003', 'Inversiones Orion S.A.',      'J-98765432-1', '2026-01-08', 15000.00, 15000.00, 0, 2400.00, 16, 17400.00, 0, FALSE, '00-0000002')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ar."SalesDocument" ("DocumentNumber", "SerialType", "OperationType", "CustomerCode", "CustomerName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('FAC-003', 'FAC', 'VEN', 'CLI-004', 'Ferretería La Esquina',       'V-15678234-5', '2026-01-12', 10000.00, 10000.00, 0, 1600.00, 16, 11600.00, 0, FALSE, '00-0000003')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ar."SalesDocument" ("DocumentNumber", "SerialType", "OperationType", "CustomerCode", "CustomerName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('FAC-004', 'FAC', 'VEN', 'CLI-005', 'Servicios Tecnológicos 360',  'J-40567890-3', '2026-02-03', 20000.00, 20000.00, 0, 3200.00, 16, 23200.00, 0, FALSE, '00-0000004')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ar."SalesDocument" ("DocumentNumber", "SerialType", "OperationType", "CustomerCode", "CustomerName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('FAC-005', 'FAC', 'VEN', 'CLI-002', 'Distribuidora El Sol C.A.',   'J-12345679-0', '2026-02-15', 30000.00, 30000.00, 0, 4800.00, 16, 34800.00, 0, FALSE, '00-0000005')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  RAISE NOTICE '   5 documentos venta OK.';

  -- ============================================================
  -- 9. DOCUMENTOS COMPRA (5)
  -- ============================================================
  RAISE NOTICE '>> 9. Documentos de compra (ap."PurchaseDocument")...';

  INSERT INTO ap."PurchaseDocument" ("DocumentNumber", "SerialType", "OperationType", "SupplierCode", "SupplierName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "ExemptTotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('OC-001', 'FAC', 'COM', 'PROV-001', 'Proveedor 1', 'J-11111111-1', '2026-01-10', 12000.00, 12000.00, 0, 1920.00, 16, 13920.00, 0, 0, FALSE, '00-0000001')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ap."PurchaseDocument" ("DocumentNumber", "SerialType", "OperationType", "SupplierCode", "SupplierName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "ExemptTotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('OC-002', 'FAC', 'COM', 'PROV-002', 'Proveedor 2', 'J-22222222-2', '2026-01-15', 8000.00, 8000.00, 0, 1280.00, 16, 9280.00, 0, 0, FALSE, '00-0000002')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ap."PurchaseDocument" ("DocumentNumber", "SerialType", "OperationType", "SupplierCode", "SupplierName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "ExemptTotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('OC-003', 'FAC', 'COM', 'PROV-003', 'Proveedor 3', 'J-33333333-3', '2026-01-20', 5000.00, 5000.00, 0, 800.00, 16, 5800.00, 0, 0, FALSE, '00-0000003')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ap."PurchaseDocument" ("DocumentNumber", "SerialType", "OperationType", "SupplierCode", "SupplierName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "ExemptTotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('OC-004', 'FAC', 'COM', 'PROV-004', 'Proveedor 4', 'J-44444444-4', '2026-02-05', 15000.00, 15000.00, 0, 2400.00, 16, 17400.00, 0, 0, FALSE, '00-0000004')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  INSERT INTO ap."PurchaseDocument" ("DocumentNumber", "SerialType", "OperationType", "SupplierCode", "SupplierName", "FiscalId", "DocumentDate", "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "ExemptTotalAmount", "DiscountAmount", "IsVoided", "ControlNumber")
  VALUES ('OC-005', 'FAC', 'COM', 'PROV-005', 'Proveedor 5', 'J-55555555-5', '2026-02-18', 10000.00, 10000.00, 0, 1600.00, 16, 11600.00, 0, 0, FALSE, '00-0000005')
  ON CONFLICT ("DocumentNumber", "OperationType") DO NOTHING;

  RAISE NOTICE '   5 documentos compra OK.';

  -- ============================================================
  -- 10. ACTIVOS FIJOS (5)
  -- ============================================================
  RAISE NOTICE '>> 10. Activos fijos...';

  INSERT INTO acct."FixedAsset" ("CompanyId", "BranchId", "AssetCode", "Description", "CategoryId", "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths", "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode", "CostCenterCode", "Status", "CurrencyCode", "IsDeleted", "CreatedAt", "UpdatedAt")
  SELECT v_company_id, v_branch_id, 'AF-001', 'Servidor Dell PowerEdge',
    (SELECT "CategoryId" FROM acct."FixedAssetCategory" WHERE "CategoryCode" = 'EQU' AND "CompanyId" = v_company_id AND "CountryCode" = 'VE' LIMIT 1),
    '2026-01-15', 15000.00, 1500.00, 36, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'OPE', 'ACTIVE', 'VES', FALSE, v_now, v_now
  WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-001');

  INSERT INTO acct."FixedAsset" ("CompanyId", "BranchId", "AssetCode", "Description", "CategoryId", "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths", "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode", "CostCenterCode", "Status", "CurrencyCode", "IsDeleted", "CreatedAt", "UpdatedAt")
  SELECT v_company_id, v_branch_id, 'AF-002', 'Vehículo Toyota Hilux',
    (SELECT "CategoryId" FROM acct."FixedAssetCategory" WHERE "CategoryCode" = 'VEH' AND "CompanyId" = v_company_id AND "CountryCode" = 'VE' LIMIT 1),
    '2026-01-20', 85000.00, 8500.00, 60, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'VEN', 'ACTIVE', 'VES', FALSE, v_now, v_now
  WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-002');

  INSERT INTO acct."FixedAsset" ("CompanyId", "BranchId", "AssetCode", "Description", "CategoryId", "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths", "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode", "CostCenterCode", "Status", "CurrencyCode", "IsDeleted", "CreatedAt", "UpdatedAt")
  SELECT v_company_id, v_branch_id, 'AF-003', 'Mobiliario oficina',
    (SELECT "CategoryId" FROM acct."FixedAssetCategory" WHERE "CategoryCode" = 'MOB' AND "CompanyId" = v_company_id AND "CountryCode" = 'VE' LIMIT 1),
    '2026-02-01', 12000.00, 0.00, 120, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'ADM', 'ACTIVE', 'VES', FALSE, v_now, v_now
  WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-003');

  INSERT INTO acct."FixedAsset" ("CompanyId", "BranchId", "AssetCode", "Description", "CategoryId", "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths", "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode", "CostCenterCode", "Status", "CurrencyCode", "IsDeleted", "CreatedAt", "UpdatedAt")
  SELECT v_company_id, v_branch_id, 'AF-004', 'Impresora industrial',
    (SELECT "CategoryId" FROM acct."FixedAssetCategory" WHERE "CategoryCode" = 'MAQ' AND "CompanyId" = v_company_id AND "CountryCode" = 'VE' LIMIT 1),
    '2026-02-15', 25000.00, 2500.00, 120, 'STRAIGHT_LINE', '1.2.01', '1.2.02', '5.2.10', 'OPE', 'ACTIVE', 'VES', FALSE, v_now, v_now
  WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-004');

  INSERT INTO acct."FixedAsset" ("CompanyId", "BranchId", "AssetCode", "Description", "CategoryId", "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths", "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode", "CostCenterCode", "Status", "CurrencyCode", "IsDeleted", "CreatedAt", "UpdatedAt")
  SELECT v_company_id, v_branch_id, 'AF-005', 'Software ERP licencia',
    (SELECT "CategoryId" FROM acct."FixedAssetCategory" WHERE "CategoryCode" = 'INT' AND "CompanyId" = v_company_id AND "CountryCode" = 'VE' LIMIT 1),
    '2026-03-01', 18000.00, 0.00, 60, 'STRAIGHT_LINE', '1.2.04', '1.2.04', '5.2.10', 'ADM', 'ACTIVE', 'VES', FALSE, v_now, v_now
  WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-005');

  RAISE NOTICE '   5 activos fijos OK.';

  -- ============================================================
  -- 11. DEPRECIACIONES (11 registros)
  -- ============================================================
  RAISE NOTICE '>> 11. Depreciaciones mensuales...';

  -- AF-001: 375/mes
  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-001';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-01', '2026-01-31', 375.00, 375.00, 14625.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-02', '2026-02-28', 375.00, 750.00, 14250.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-03', '2026-03-31', 375.00, 1125.00, 13875.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
  END IF;

  -- AF-002: 1275/mes
  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-002';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-01', '2026-01-31', 1275.00, 1275.00, 83725.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-02', '2026-02-28', 1275.00, 2550.00, 82450.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-03', '2026-03-31', 1275.00, 3825.00, 81175.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
  END IF;

  -- AF-003: 100/mes
  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-003';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-02', '2026-02-28', 100.00, 100.00, 11900.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-03', '2026-03-31', 100.00, 200.00, 11800.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
  END IF;

  -- AF-004: 187.50/mes
  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-004';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-02', '2026-02-28', 187.50, 187.50, 24812.50, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-03', '2026-03-31', 187.50, 375.00, 24625.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
  END IF;

  -- AF-005: 300/mes
  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-005';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetDepreciation" ("AssetId", "PeriodCode", "DepreciationDate", "Amount", "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt")
    VALUES (v_asset_id, '2026-03', '2026-03-31', 300.00, 300.00, 17700.00, 'POSTED', v_now)
    ON CONFLICT ("AssetId", "PeriodCode") DO NOTHING;
  END IF;

  RAISE NOTICE '   11 registros depreciación OK.';

  -- ============================================================
  -- 12. MEJORA A ACTIVO (AF-001)
  -- ============================================================
  RAISE NOTICE '>> 12. Mejora activo AF-001...';

  SELECT "AssetId" INTO v_asset_id FROM acct."FixedAsset" WHERE "CompanyId" = v_company_id AND "AssetCode" = 'AF-001';
  IF v_asset_id IS NOT NULL THEN
    INSERT INTO acct."FixedAssetImprovement" ("AssetId", "ImprovementDate", "Description", "Amount", "AdditionalLifeMonths", "CreatedBy", "CreatedAt")
    SELECT v_asset_id, '2026-02-20', 'Upgrade RAM 64GB - Servidor Dell PowerEdge', 2500.00, 6, 'SEED', v_now
    WHERE NOT EXISTS (SELECT 1 FROM acct."FixedAssetImprovement" WHERE "AssetId" = v_asset_id AND "ImprovementDate" = '2026-02-20');
    RAISE NOTICE '   Mejora AF-001 OK.';
  ELSE
    RAISE NOTICE '   AF-001 no encontrado, mejora omitida.';
  END IF;

  -- ============================================================
  -- 13. PRESUPUESTO (1 cabecera + 5 líneas)
  -- ============================================================
  RAISE NOTICE '>> 13. Presupuesto operativo 2026...';

  IF NOT EXISTS (SELECT 1 FROM acct."Budget" WHERE "CompanyId" = v_company_id AND "BudgetName" = 'Presupuesto Operativo 2026' AND "FiscalYear" = 2026) THEN
    INSERT INTO acct."Budget" ("CompanyId", "BudgetName", "FiscalYear", "CostCenterCode", "Status", "Notes", "IsDeleted", "CreatedAt", "UpdatedAt")
    VALUES (v_company_id, 'Presupuesto Operativo 2026', 2026, NULL, 'APPROVED', 'Presupuesto general de operaciones 2026', FALSE, v_now, v_now)
    RETURNING "BudgetId" INTO v_budget_id;

    INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode", "Month01", "Month02", "Month03", "Month04", "Month05", "Month06", "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
    VALUES (v_budget_id, '4.1.01', 25000, 25000, 25000, 30000, 30000, 30000, 35000, 35000, 35000, 40000, 40000, 40000, 'Proyección ventas escalonada');

    INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode", "Month01", "Month02", "Month03", "Month04", "Month05", "Month06", "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
    VALUES (v_budget_id, '5.1.01', 15000, 15000, 15000, 18000, 18000, 18000, 21000, 21000, 21000, 24000, 24000, 24000, 'Costo 60% de ventas');

    INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode", "Month01", "Month02", "Month03", "Month04", "Month05", "Month06", "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
    VALUES (v_budget_id, '5.2.01', 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 45000, 'Nómina fija mensual');

    INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode", "Month01", "Month02", "Month03", "Month04", "Month05", "Month06", "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
    VALUES (v_budget_id, '5.2.07', 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 'Alquiler oficina fijo');

    INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode", "Month01", "Month02", "Month03", "Month04", "Month05", "Month06", "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
    VALUES (v_budget_id, '5.2.10', 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 'Depreciación estimada mensual');

    RAISE NOTICE '   Presupuesto + 5 líneas OK.';
  ELSE
    RAISE NOTICE '   Presupuesto Operativo 2026 ya existe, omitido.';
  END IF;

  -- ============================================================
  -- 14. ASIENTOS RECURRENTES (3)
  -- ============================================================
  RAISE NOTICE '>> 14. Asientos recurrentes...';

  IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = v_company_id AND "TemplateName" = 'Alquiler Mensual') THEN
    INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "LastExecutedDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive", "IsDeleted", "CreatedAt")
    VALUES (v_company_id, 'Alquiler Mensual', 'MONTHLY', '2026-04-01', '2026-03-31', 3, NULL, 'DIA', 'Pago alquiler oficina', TRUE, FALSE, v_now)
    RETURNING "RecurringEntryId" INTO v_rec_id;
    INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
    VALUES
      (v_rec_id, '5.2.07', 'Alquiler oficina',     'ADM', 8000.00,    0),
      (v_rec_id, '1.1.02', 'Pago banco alquiler',  NULL,       0, 8000.00);
    RAISE NOTICE '   Recurrente: Alquiler Mensual OK.';
  ELSE RAISE NOTICE '   Recurrente: Alquiler Mensual ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = v_company_id AND "TemplateName" = 'Servicios Públicos') THEN
    INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "LastExecutedDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive", "IsDeleted", "CreatedAt")
    VALUES (v_company_id, 'Servicios Públicos', 'MONTHLY', '2026-04-01', '2026-02-28', 2, NULL, 'DIA', 'Pago servicios públicos', TRUE, FALSE, v_now)
    RETURNING "RecurringEntryId" INTO v_rec_id;
    INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
    VALUES
      (v_rec_id, '5.2.08', 'Servicios públicos',       'ADM', 3500.00,    0),
      (v_rec_id, '1.1.02', 'Pago banco serv. púb.',    NULL,       0, 3500.00);
    RAISE NOTICE '   Recurrente: Servicios Públicos OK.';
  ELSE RAISE NOTICE '   Recurrente: Servicios Públicos ya existe, omitido.'; END IF;

  IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = v_company_id AND "TemplateName" = 'Depreciación Mensual') THEN
    INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "LastExecutedDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive", "IsDeleted", "CreatedAt")
    VALUES (v_company_id, 'Depreciación Mensual', 'MONTHLY', '2026-04-01', '2026-03-31', 3, NULL, 'DIA', 'Depreciación mensual activos fijos', TRUE, FALSE, v_now)
    RETURNING "RecurringEntryId" INTO v_rec_id;
    INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
    VALUES
      (v_rec_id, '5.2.10', 'Gasto depreciación',          NULL, 5625.00,    0),
      (v_rec_id, '1.2.02', 'Depreciación acumulada',      NULL,      0, 5625.00);
    RAISE NOTICE '   Recurrente: Depreciación Mensual OK.';
  ELSE RAISE NOTICE '   Recurrente: Depreciación Mensual ya existe, omitido.'; END IF;

  RAISE NOTICE '   3 asientos recurrentes OK.';

  -- ============================================================
  -- 15. RETENCIONES IVA (3)
  -- ============================================================
  RAISE NOTICE '>> 15. Retenciones IVA...';

  INSERT INTO fiscal."WithholdingVoucher" ("CompanyId", "VoucherNumber", "VoucherDate", "WithholdingType", "ThirdPartyId", "ThirdPartyName", "DocumentNumber", "DocumentDate", "TaxableBase", "WithholdingRate", "WithholdingAmount", "PeriodCode", "Status", "CountryCode", "CreatedBy", "CreatedAt")
  VALUES (v_company_id, 'RET-IVA-202601-001', '2026-01-10', 'IVA', 'J-11111111-1', 'Proveedor 1', 'OC-001', '2026-01-10', 12000.00, 75.00, 1440.00, '202601', 'ACTIVE', 'VE', 'SEED', v_now)
  ON CONFLICT ("CompanyId", "VoucherNumber") DO NOTHING;

  INSERT INTO fiscal."WithholdingVoucher" ("CompanyId", "VoucherNumber", "VoucherDate", "WithholdingType", "ThirdPartyId", "ThirdPartyName", "DocumentNumber", "DocumentDate", "TaxableBase", "WithholdingRate", "WithholdingAmount", "PeriodCode", "Status", "CountryCode", "CreatedBy", "CreatedAt")
  VALUES (v_company_id, 'RET-IVA-202601-002', '2026-01-15', 'IVA', 'J-22222222-2', 'Proveedor 2', 'OC-002', '2026-01-15', 8000.00, 75.00, 960.00, '202601', 'ACTIVE', 'VE', 'SEED', v_now)
  ON CONFLICT ("CompanyId", "VoucherNumber") DO NOTHING;

  INSERT INTO fiscal."WithholdingVoucher" ("CompanyId", "VoucherNumber", "VoucherDate", "WithholdingType", "ThirdPartyId", "ThirdPartyName", "DocumentNumber", "DocumentDate", "TaxableBase", "WithholdingRate", "WithholdingAmount", "PeriodCode", "Status", "CountryCode", "CreatedBy", "CreatedAt")
  VALUES (v_company_id, 'RET-IVA-202602-001', '2026-02-05', 'IVA', 'J-44444444-4', 'Proveedor 4', 'OC-004', '2026-02-05', 15000.00, 75.00, 1800.00, '202602', 'ACTIVE', 'VE', 'SEED', v_now)
  ON CONFLICT ("CompanyId", "VoucherNumber") DO NOTHING;

  RAISE NOTICE '   3 retenciones IVA OK.';

  RAISE NOTICE '';
  RAISE NOTICE '>> Seed contabilidad demo completado exitosamente.';
  RAISE NOTICE '>> Resumen: 12 períodos, 5 centros costo, 4 clientes,';
  RAISE NOTICE '>>   23 asientos contables (1 apertura + 8 ene + 8 feb + 6 mar),';
  RAISE NOTICE '>>   5 doc venta, 5 doc compra, 5 activos fijos,';
  RAISE NOTICE '>>   11 depreciaciones, 1 mejora, 1 presupuesto (5 líneas),';
  RAISE NOTICE '>>   3 asientos recurrentes, 3 retenciones IVA.';
  RAISE NOTICE '=== FIN SEED CONTABILIDAD DEMO ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR en seed contabilidad demo: %', SQLERRM;
  RAISE;
END $$;
