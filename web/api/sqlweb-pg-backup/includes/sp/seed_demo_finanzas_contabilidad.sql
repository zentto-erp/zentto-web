-- ============================================================================
-- SEED: Demo data para Finanzas, Contabilidad y Pagos
-- Idempotente, PostgreSQL
-- Fecha: 2026-03-16
-- ============================================================================

DO $seed_finanzas$
DECLARE
    v_bank_merc   BIGINT;
    v_bank_ban    BIGINT;
    v_bank_prov   BIGINT;
    v_bank_caixa  BIGINT;
    v_bank_bbva   BIGINT;
    v_acct_merc   BIGINT;
    v_acct_ban    BIGINT;
    v_acct_prov   BIGINT;
    v_acct_caixa  BIGINT;
    v_acct_bbva   BIGINT;
    v_budget_id   INT;
    v_re_id       INT;
    v_pm_efectivo INT;
    v_pm_tdd      INT;
    v_pm_tdc      INT;
    v_pm_transfer INT;
    v_pm_c2p      INT;
    v_pm_zelle    INT;
    v_prov_merc   INT;
    v_prov_binance INT;
    v_prov_stripe  INT;
BEGIN

RAISE NOTICE '=== SEED DEMO FINANZAS / CONTABILIDAD / PAGOS ===';

-- ============================================================================
-- 1. fin.Bank — 9 bancos adicionales
--    VE: Mercantil, Banesco, Provincial, BDV, Banca Amiga
--    ES: CaixaBank, BBVA, Santander, Sabadell
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'fin' AND table_name = 'Bank') THEN
    INSERT INTO fin."Bank" ("CompanyId", "BankCode", "BankName", "ContactName", "AddressLine", "Phones", "IsActive")
    VALUES
        (1, 'MERCANTIL',   'Banco Mercantil',             'Centro de Atención', 'Av. Andrés Bello, Caracas',           '+58-212-6001111', TRUE),
        (1, 'BANESCO',     'Banesco Banco Universal',      'Banca Digital',      'Calle Lincoln, Caracas',              '+58-212-5011111', TRUE),
        (1, 'PROVINCIAL',  'BBVA Provincial',              'Banca Corporativa',  'Av. Este 0, Caracas',                 '+58-212-5081111', TRUE),
        (1, 'BDV',         'Banco de Venezuela',           'Atención al Cliente','Esq. de Sociedad a Gradillas, CCS',   '+58-212-8017300', TRUE),
        (1, 'BANCA_AMIGA', 'Banca Amiga Banco Universal',  'Soporte',            'Av. Fco. de Miranda, Caracas',        '+58-212-2053000', TRUE),
        (1, 'CAIXABANK',   'CaixaBank S.A.',               'Banca de Empresas',  'C/ Pintor Sorolla 2-4, Valencia',     '+34-900-404040',  TRUE),
        (1, 'BBVA_ES',     'BBVA España',                  'Banca Empresas',     'C/ Gran Vía 1, Bilbao',               '+34-900-102801',  TRUE),
        (1, 'SANTANDER',   'Banco Santander España',       'Banca Corporativa',  'Paseo de Pereda 9-12, Santander',     '+34-900-110011',  TRUE),
        (1, 'SABADELL',    'Banco Sabadell',               'Negocios',           'Av. Óscar Esplá 37, Alicante',        '+34-900-500050',  TRUE)
    ON CONFLICT ("CompanyId", "BankCode") DO NOTHING;
    RAISE NOTICE '  fin.Bank: 9 bancos verificados/insertados.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla fin.Bank no existe.';
END IF;

-- ============================================================================
-- 2. fin.BankAccount — 5 cuentas bancarias
--    2 VE en VES, 1 VE en USD, 2 ES en EUR
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'fin' AND table_name = 'BankAccount') THEN
    SELECT "BankId" INTO v_bank_merc  FROM fin."Bank" WHERE "BankCode" = 'MERCANTIL'  AND "CompanyId" = 1 LIMIT 1;
    SELECT "BankId" INTO v_bank_ban   FROM fin."Bank" WHERE "BankCode" = 'BANESCO'    AND "CompanyId" = 1 LIMIT 1;
    SELECT "BankId" INTO v_bank_prov  FROM fin."Bank" WHERE "BankCode" = 'PROVINCIAL' AND "CompanyId" = 1 LIMIT 1;
    SELECT "BankId" INTO v_bank_caixa FROM fin."Bank" WHERE "BankCode" = 'CAIXABANK'  AND "CompanyId" = 1 LIMIT 1;
    SELECT "BankId" INTO v_bank_bbva  FROM fin."Bank" WHERE "BankCode" = 'BBVA_ES'    AND "CompanyId" = 1 LIMIT 1;

    IF v_bank_merc IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fin."BankAccount" WHERE "CompanyId" = 1 AND "AccountNumber" = '01050012341234567890') THEN
        INSERT INTO fin."BankAccount" ("CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName", "CurrencyCode", "Balance", "AvailableBalance", "IsActive")
        VALUES (1, 1, v_bank_merc, '01050012341234567890', 'Mercantil Corriente VES', 'VES', 125450.75, 125450.75, TRUE);
    END IF;

    IF v_bank_ban IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fin."BankAccount" WHERE "CompanyId" = 1 AND "AccountNumber" = '01340056781234567890') THEN
        INSERT INTO fin."BankAccount" ("CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName", "CurrencyCode", "Balance", "AvailableBalance", "IsActive")
        VALUES (1, 1, v_bank_ban, '01340056781234567890', 'Banesco Ahorro VES', 'VES', 48320.00, 48320.00, TRUE);
    END IF;

    IF v_bank_prov IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fin."BankAccount" WHERE "CompanyId" = 1 AND "AccountNumber" = '01080011002233445566') THEN
        INSERT INTO fin."BankAccount" ("CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName", "CurrencyCode", "Balance", "AvailableBalance", "IsActive")
        VALUES (1, 1, v_bank_prov, '01080011002233445566', 'Provincial Custodia USD', 'USD', 8750.50, 8750.50, TRUE);
    END IF;

    IF v_bank_caixa IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fin."BankAccount" WHERE "CompanyId" = 1 AND "AccountNumber" = 'ES7621000418401234567891') THEN
        INSERT INTO fin."BankAccount" ("CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName", "CurrencyCode", "Balance", "AvailableBalance", "IsActive")
        VALUES (1, 1, v_bank_caixa, 'ES7621000418401234567891', 'CaixaBank Empresa EUR', 'EUR', 35200.00, 35200.00, TRUE);
    END IF;

    IF v_bank_bbva IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fin."BankAccount" WHERE "CompanyId" = 1 AND "AccountNumber" = 'ES9100490075032110152784') THEN
        INSERT INTO fin."BankAccount" ("CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName", "CurrencyCode", "Balance", "AvailableBalance", "IsActive")
        VALUES (1, 1, v_bank_bbva, 'ES9100490075032110152784', 'BBVA Nomina EUR', 'EUR', 12680.30, 12680.30, TRUE);
    END IF;

    RAISE NOTICE '  fin.BankAccount: 5 cuentas verificadas/insertadas.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla fin.BankAccount no existe.';
END IF;

-- ============================================================================
-- 3. fin.BankMovement — 15 movimientos realistas
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'fin' AND table_name = 'BankMovement') THEN
    SELECT "BankAccountId" INTO v_acct_merc  FROM fin."BankAccount" WHERE "AccountNumber" = '01050012341234567890' LIMIT 1;
    SELECT "BankAccountId" INTO v_acct_ban   FROM fin."BankAccount" WHERE "AccountNumber" = '01340056781234567890' LIMIT 1;
    SELECT "BankAccountId" INTO v_acct_prov  FROM fin."BankAccount" WHERE "AccountNumber" = '01080011002233445566' LIMIT 1;
    SELECT "BankAccountId" INTO v_acct_caixa FROM fin."BankAccount" WHERE "AccountNumber" = 'ES7621000418401234567891' LIMIT 1;
    SELECT "BankAccountId" INTO v_acct_bbva  FROM fin."BankAccount" WHERE "AccountNumber" = 'ES9100490075032110152784' LIMIT 1;

    -- Solo si la tabla tiene menos de 10 movimientos
    IF (SELECT COUNT(*) FROM fin."BankMovement") < 10 THEN

        -- Cuenta Mercantil VES
        IF v_acct_merc IS NOT NULL THEN
            INSERT INTO fin."BankMovement" ("BankAccountId", "MovementDate", "MovementType", "MovementSign", "Amount", "NetAmount", "ReferenceNo", "Beneficiary", "Concept", "CategoryCode", "BalanceAfter")
            VALUES
            (v_acct_merc, '2026-01-15 09:30:00', 'DEP',  1, 45000.00, 45000.00, 'TRF-20260115-001', 'Cobro Factura #1021',       'Cobro cliente principal VTA',     'VENTAS',     80000.00),
            (v_acct_merc, '2026-01-20 14:10:00', 'PCH', -1, 12500.00, 12500.00, 'CHQ-003421',       'Proveedor Importaciones XY', 'Pago factura proveedor',          'COMPRAS',    67500.00),
            (v_acct_merc, '2026-02-01 08:00:00', 'DEP',  1, 62000.00, 62000.00, 'TRF-20260201-001', 'Cobro Factura #1034',       'Cobro mensual distribuidor',      'VENTAS',    129500.00),
            (v_acct_merc, '2026-02-05 16:45:00', 'NDB', -1,  1200.00,  1200.00, 'NDB-20260205',     'Banco Mercantil',            'Comisiones bancarias febrero',    'GASTOS',    128300.00),
            (v_acct_merc, '2026-02-15 10:00:00', 'PCH', -1,  8500.00,  8500.00, 'CHQ-003450',       'SENIAT',                     'Pago IVA enero 2026',             'IMPUESTOS', 119800.00);
        END IF;

        -- Cuenta Banesco VES
        IF v_acct_ban IS NOT NULL THEN
            INSERT INTO fin."BankMovement" ("BankAccountId", "MovementDate", "MovementType", "MovementSign", "Amount", "NetAmount", "ReferenceNo", "Beneficiary", "Concept", "CategoryCode", "BalanceAfter")
            VALUES
            (v_acct_ban, '2026-01-10 11:20:00', 'DEP',  1, 25000.00, 25000.00, 'TRF-20260110-001', 'Transferencia interna', 'Traspaso desde Mercantil',   'TRASPASOS', 50000.00),
            (v_acct_ban, '2026-02-01 08:30:00', 'NCR',  1,   320.00,   320.00, 'INT-FEB-2026',     'Banesco',               'Intereses ahorro enero',     'INTERESES', 50320.00),
            (v_acct_ban, '2026-02-10 09:00:00', 'IDB', -1,  2000.00,  2000.00, 'TRF-20260210-001', 'Caja chica',            'Reposicion caja chica',      'GASTOS',    48320.00);
        END IF;

        -- Cuenta Provincial USD
        IF v_acct_prov IS NOT NULL THEN
            INSERT INTO fin."BankMovement" ("BankAccountId", "MovementDate", "MovementType", "MovementSign", "Amount", "NetAmount", "ReferenceNo", "Beneficiary", "Concept", "CategoryCode", "BalanceAfter")
            VALUES
            (v_acct_prov, '2026-01-22 15:00:00', 'DEP',  1, 3500.00, 3500.00, 'SWIFT-20260122', 'Cliente Exterior LLC', 'Cobro exportacion servicio', 'VENTAS', 10250.00),
            (v_acct_prov, '2026-02-18 10:00:00', 'PCH', -1, 1500.00, 1500.00, 'WIRE-20260218',  'Proveedor Cloud Inc',  'Pago hosting anual',         'GASTOS',  8750.50);
        END IF;

        -- Cuenta CaixaBank EUR
        IF v_acct_caixa IS NOT NULL THEN
            INSERT INTO fin."BankMovement" ("BankAccountId", "MovementDate", "MovementType", "MovementSign", "Amount", "NetAmount", "ReferenceNo", "Beneficiary", "Concept", "CategoryCode", "BalanceAfter")
            VALUES
            (v_acct_caixa, '2026-01-05 10:00:00', 'DEP',  1, 18500.00, 18500.00, 'SEPA-20260105', 'Cliente Barcelona SL', 'Cobro factura #ES-0042',   'VENTAS',    45000.00),
            (v_acct_caixa, '2026-01-31 17:00:00', 'PCH', -1,  4800.00,  4800.00, 'SEPA-20260131', 'Alquiler Oficina SL',  'Alquiler enero oficina',   'ALQUILER',  40200.00),
            (v_acct_caixa, '2026-02-15 09:30:00', 'PCH', -1,  5000.00,  5000.00, 'SEPA-20260215', 'Agencia Hacienda',     'Pago IVA trimestral 4T25', 'IMPUESTOS', 35200.00);
        END IF;

        -- Cuenta BBVA EUR
        IF v_acct_bbva IS NOT NULL THEN
            INSERT INTO fin."BankMovement" ("BankAccountId", "MovementDate", "MovementType", "MovementSign", "Amount", "NetAmount", "ReferenceNo", "Beneficiary", "Concept", "CategoryCode", "BalanceAfter")
            VALUES
            (v_acct_bbva, '2026-01-28 08:00:00', 'PCH', -1, 9500.00, 9500.00, 'NOM-ENE-2026', 'Empleados', 'Nomina enero 2026',    'NOMINA',    15180.30),
            (v_acct_bbva, '2026-02-03 12:00:00', 'DEP',  1, 7000.00, 7000.00, 'TRF-INTERNA',  'CaixaBank', 'Provision nomina feb', 'TRASPASOS', 22180.30);
        END IF;

        RAISE NOTICE '  fin.BankMovement: 15 movimientos insertados.';
    ELSE
        RAISE NOTICE '  fin.BankMovement: ya existen 10+ movimientos, sin cambios.';
    END IF;
ELSE
    RAISE NOTICE '  [SKIP] Tabla fin.BankMovement no existe.';
END IF;

-- ============================================================================
-- 4. acct.FiscalPeriod — 12 periodos para 2026
--    Enero y Febrero CLOSED, resto OPEN
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'FiscalPeriod') THEN
    INSERT INTO acct."FiscalPeriod" ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate", "Status")
    SELECT
        1,
        TO_CHAR(DATE '2026-01-01' + (n-1 || ' months')::INTERVAL, 'YYYYMM'),
        'Periodo ' || TO_CHAR(DATE '2026-01-01' + (n-1 || ' months')::INTERVAL, 'TMMonth') || ' 2026',
        2026,
        n,
        DATE_TRUNC('month', DATE '2026-01-01' + (n-1 || ' months')::INTERVAL)::DATE,
        (DATE_TRUNC('month', DATE '2026-01-01' + (n-1 || ' months')::INTERVAL) + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        CASE WHEN n <= 2 THEN 'CLOSED' ELSE 'OPEN' END
    FROM generate_series(1, 12) AS t(n)
    ON CONFLICT ("CompanyId", "PeriodCode") DO NOTHING;
    RAISE NOTICE '  acct.FiscalPeriod: 12 periodos 2026 verificados/insertados.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla acct.FiscalPeriod no existe.';
END IF;

-- ============================================================================
-- 5. acct.CostCenter — 5 centros de costo
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'CostCenter') THEN
    INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level", "IsActive")
    VALUES
        (1, 'ADMIN',      'Administración General', NULL, 1, TRUE),
        (1, 'VENTAS',     'Departamento de Ventas', NULL, 1, TRUE),
        (1, 'PRODUCCION', 'Producción',             NULL, 1, TRUE),
        (1, 'ALMACEN',    'Almacén y Logística',    NULL, 1, TRUE),
        (1, 'GERENCIA',   'Gerencia General',       NULL, 1, TRUE)
    ON CONFLICT ("CompanyId", "CostCenterCode") DO NOTHING;
    RAISE NOTICE '  acct.CostCenter: 5 centros verificados/insertados.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla acct.CostCenter no existe.';
END IF;

-- ============================================================================
-- 6. acct.Budget + acct.BudgetLine — Presupuesto anual 2026
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'Budget')
   AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'BudgetLine') THEN

    IF NOT EXISTS (SELECT 1 FROM acct."Budget" WHERE "CompanyId" = 1 AND "FiscalYear" = 2026 AND "BudgetName" = 'Presupuesto Operativo 2026') THEN
        INSERT INTO acct."Budget" ("CompanyId", "BudgetName", "FiscalYear", "CostCenterCode", "Status", "Notes")
        VALUES (1, 'Presupuesto Operativo 2026', 2026, 'ADMIN', 'APPROVED', 'Presupuesto anual de gastos operativos sede principal')
        RETURNING "BudgetId" INTO v_budget_id;

        -- Alquileres: 800 mensual, sube 5% en julio
        INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
        VALUES (v_budget_id, '6.1.02',
            800.00, 800.00, 800.00, 800.00, 800.00, 800.00,
            840.00, 840.00, 840.00, 840.00, 840.00, 840.00,
            'Alquiler local - ajuste julio +5%');

        -- Servicios basicos: estacional
        INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
        VALUES (v_budget_id, '6.1.03',
            350.00, 320.00, 340.00, 380.00, 420.00, 500.00,
            550.00, 560.00, 480.00, 400.00, 370.00, 360.00,
            'Servicios básicos - estacional por clima');

        -- Publicidad: campañas Q1 y Q4
        INSERT INTO acct."BudgetLine" ("BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes")
        VALUES (v_budget_id, '6.2.02',
            1200.00, 1500.00, 1800.00, 600.00, 500.00, 500.00,
            500.00, 600.00, 800.00, 1200.00, 2000.00, 2500.00,
            'Publicidad - fuerte en Q1 y Q4 (temporada alta)');

        RAISE NOTICE '  acct.Budget+BudgetLine: presupuesto 2026 con 3 líneas creado.';
    ELSE
        RAISE NOTICE '  acct.Budget: presupuesto 2026 ya existe.';
    END IF;
ELSE
    RAISE NOTICE '  [SKIP] Tabla acct.Budget o acct.BudgetLine no existe.';
END IF;

-- ============================================================================
-- 7. acct.RecurringEntry + acct.RecurringEntryLine — 3 plantillas recurrentes
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'RecurringEntry')
   AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'RecurringEntryLine') THEN

    -- 7a. Alquiler mensual
    IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = 1 AND "TemplateName" = 'Alquiler mensual local comercial') THEN
        INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive")
        VALUES (1, 'Alquiler mensual local comercial', 'MONTHLY', '2026-04-01', 3, 12, 'DIARIO', 'Pago alquiler mensual local comercial principal', TRUE)
        RETURNING "RecurringEntryId" INTO v_re_id;

        INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
        VALUES
            (v_re_id, '6.1.02', 'Gasto alquiler',     'ADMIN', 800.00, 0),
            (v_re_id, '1.1.02', 'Pago banco alquiler', 'ADMIN', 0, 800.00);
    END IF;

    -- 7b. Depreciación mensual
    IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = 1 AND "TemplateName" = 'Depreciación mensual mobiliario') THEN
        INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive")
        VALUES (1, 'Depreciación mensual mobiliario', 'MONTHLY', '2026-04-01', 3, NULL, 'AJUSTE', 'Depreciación mensual activos fijos - mobiliario oficina', TRUE)
        RETURNING "RecurringEntryId" INTO v_re_id;

        INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
        VALUES
            (v_re_id, '6.1.04', 'Gasto depreciación',        'ADMIN', 150.00, 0),
            (v_re_id, '1.2.02', 'Depreciación acumulada PPE', 'ADMIN', 0, 150.00);
    END IF;

    -- 7c. Reposición caja chica semanal
    IF NOT EXISTS (SELECT 1 FROM acct."RecurringEntry" WHERE "CompanyId" = 1 AND "TemplateName" = 'Reposición caja chica semanal') THEN
        INSERT INTO acct."RecurringEntry" ("CompanyId", "TemplateName", "Frequency", "NextExecutionDate", "TimesExecuted", "MaxExecutions", "TipoAsiento", "Concepto", "IsActive")
        VALUES (1, 'Reposición caja chica semanal', 'WEEKLY', '2026-03-23', 10, 52, 'DIARIO', 'Reposición semanal de fondo de caja chica', TRUE)
        RETURNING "RecurringEntryId" INTO v_re_id;

        INSERT INTO acct."RecurringEntryLine" ("RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit")
        VALUES
            (v_re_id, '1.1.01', 'Caja chica',           'VENTAS', 500.00, 0),
            (v_re_id, '1.1.02', 'Banco reposición caja', 'VENTAS', 0, 500.00);
    END IF;

    RAISE NOTICE '  acct.RecurringEntry: 3 plantillas recurrentes verificadas/insertadas.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla acct.RecurringEntry o acct.RecurringEntryLine no existe.';
END IF;

-- ============================================================================
-- 8. acct.InflationIndex — INPC Venezuela 2025-2026 (24 meses)
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'InflationIndex') THEN
    INSERT INTO acct."InflationIndex" ("CompanyId", "CountryCode", "IndexName", "PeriodCode", "IndexValue", "SourceReference")
    VALUES
        -- 2025: inflación acumulada ~180%
        (1, 'VE', 'INPC', '202501',   285400.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202502',   310280.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202503',   335100.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202504',   358860.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202505',   387570.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202506',   422450.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202507',   460870.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202508',   498140.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202509',   538000.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202510',   586820.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202511',   639630.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202512',   697200.000000, 'BCV Gaceta Oficial'),
        -- 2026: inflación se modera ligeramente
        (1, 'VE', 'INPC', '202601',   753980.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202602',   808020.000000, 'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202603',   864580.000000, 'BCV Gaceta Oficial (est.)'),
        (1, 'VE', 'INPC', '202604',   924100.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202605',   987790.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202606',  1056930.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202607',  1120350.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202608',  1187570.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202609',  1258830.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202610',  1334360.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202611',  1414420.000000, 'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202612',  1499290.000000, 'BCV Gaceta Oficial (proy.)')
    ON CONFLICT ("CompanyId", "CountryCode", "IndexName", "PeriodCode") DO NOTHING;
    RAISE NOTICE '  acct.InflationIndex: 24 meses INPC VE verificados/insertados.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla acct.InflationIndex no existe.';
END IF;

-- ============================================================================
-- 9. pay.AcceptedPaymentMethods — 6 métodos para CompanyId=1
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'pay' AND table_name = 'AcceptedPaymentMethods') THEN
    SELECT "Id" INTO v_pm_efectivo FROM pay."PaymentMethods" WHERE "Code" = 'EFECTIVO' AND "CountryCode" IS NULL LIMIT 1;
    SELECT "Id" INTO v_pm_tdd      FROM pay."PaymentMethods" WHERE "Code" = 'TDD'      AND "CountryCode" IS NULL LIMIT 1;
    SELECT "Id" INTO v_pm_tdc      FROM pay."PaymentMethods" WHERE "Code" = 'TDC'      AND "CountryCode" IS NULL LIMIT 1;
    SELECT "Id" INTO v_pm_transfer FROM pay."PaymentMethods" WHERE "Code" = 'TRANSFER' AND "CountryCode" IS NULL LIMIT 1;
    SELECT "Id" INTO v_pm_c2p      FROM pay."PaymentMethods" WHERE "Code" = 'C2P'      AND "CountryCode" = 'VE' LIMIT 1;
    SELECT "Id" INTO v_pm_zelle    FROM pay."PaymentMethods" WHERE "Code" = 'ZELLE'    AND "CountryCode" = 'US' LIMIT 1;
    SELECT "Id" INTO v_prov_merc   FROM pay."PaymentProviders" WHERE "Code" = 'MERCANTIL' LIMIT 1;

    IF v_pm_efectivo IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_efectivo AND "ProviderId" IS NULL
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_efectivo, NULL, TRUE, FALSE, TRUE, 0, 0, TRUE, 1);
    END IF;

    IF v_pm_tdd IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_tdd AND "ProviderId" = v_prov_merc
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_tdd, v_prov_merc, TRUE, TRUE, TRUE, 0.0200, 0, TRUE, 2);
    END IF;

    IF v_pm_tdc IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_tdc AND "ProviderId" = v_prov_merc
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_tdc, v_prov_merc, TRUE, TRUE, TRUE, 0.0350, 0, TRUE, 3);
    END IF;

    IF v_pm_transfer IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_transfer AND "ProviderId" IS NULL
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_transfer, NULL, TRUE, TRUE, TRUE, 0, 0, TRUE, 4);
    END IF;

    IF v_pm_c2p IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_c2p AND "ProviderId" = v_prov_merc
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_c2p, v_prov_merc, TRUE, TRUE, TRUE, 0.0100, 0, TRUE, 5);
    END IF;

    IF v_pm_zelle IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."AcceptedPaymentMethods"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "PaymentMethodId" = v_pm_zelle AND "ProviderId" IS NULL
    ) THEN
        INSERT INTO pay."AcceptedPaymentMethods" ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId", "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant", "MinAmount", "MaxAmount", "CommissionPct", "CommissionFixed", "IsActive", "SortOrder")
        VALUES (1, 1, v_pm_zelle, NULL, FALSE, TRUE, FALSE, 5.00, 2500.00, 0, 0, TRUE, 6);
    END IF;

    RAISE NOTICE '  pay.AcceptedPaymentMethods: 6 métodos verificados/insertados para EmpresaId=1.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla pay.AcceptedPaymentMethods no existe.';
END IF;

-- ============================================================================
-- 10. pay.CompanyPaymentConfig — 3 configuraciones de proveedor
--     Mercantil C2P, Binance Pay, Stripe
-- ============================================================================
IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'pay' AND table_name = 'CompanyPaymentConfig') THEN
    SELECT "Id" INTO v_prov_merc    FROM pay."PaymentProviders" WHERE "Code" = 'MERCANTIL' LIMIT 1;
    SELECT "Id" INTO v_prov_binance FROM pay."PaymentProviders" WHERE "Code" = 'BINANCE'   LIMIT 1;
    SELECT "Id" INTO v_prov_stripe  FROM pay."PaymentProviders" WHERE "Code" = 'STRIPE'    LIMIT 1;

    -- Mercantil C2P
    IF v_prov_merc IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."CompanyPaymentConfig"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 1 AND "ProviderId" = v_prov_merc
    ) THEN
        INSERT INTO pay."CompanyPaymentConfig" (
            "EmpresaId", "SucursalId", "CountryCode", "ProviderId", "Environment",
            "ClientId", "ClientSecret", "MerchantId", "TerminalId", "IntegratorId", "ExtraConfig",
            "AutoCapture", "AllowRefunds", "MaxRefundDays", "IsActive")
        VALUES (1, 1, 'VE', v_prov_merc, 'sandbox',
            'PLACEHOLDER_CLIENT_ID_MERCANTIL',
            'PLACEHOLDER_CLIENT_SECRET_MERCANTIL',
            'MERCH-001', 'TERM-001', 'INTEG-001',
            '{"phoneC2P":"04141234567","bankCode":"0105","identificationType":"V","identificationNumber":"12345678"}',
            TRUE, TRUE, 30, TRUE);
    END IF;

    -- Binance Pay
    IF v_prov_binance IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."CompanyPaymentConfig"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 0 AND "ProviderId" = v_prov_binance
    ) THEN
        INSERT INTO pay."CompanyPaymentConfig" (
            "EmpresaId", "SucursalId", "CountryCode", "ProviderId", "Environment",
            "ClientId", "ClientSecret", "MerchantId", "ExtraConfig",
            "AutoCapture", "AllowRefunds", "MaxRefundDays", "IsActive")
        VALUES (1, 0, 'VE', v_prov_binance, 'sandbox',
            'PLACEHOLDER_BINANCE_API_KEY',
            'PLACEHOLDER_BINANCE_SECRET_KEY',
            'BINANCE-MERCH-001',
            '{"defaultCurrency":"USDT","returnUrl":"https://app.datqbox.com/payment/callback","cancelUrl":"https://app.datqbox.com/payment/cancel"}',
            TRUE, TRUE, 15, TRUE);
    END IF;

    -- Stripe
    IF v_prov_stripe IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pay."CompanyPaymentConfig"
        WHERE "EmpresaId" = 1 AND "SucursalId" = 0 AND "ProviderId" = v_prov_stripe
    ) THEN
        INSERT INTO pay."CompanyPaymentConfig" (
            "EmpresaId", "SucursalId", "CountryCode", "ProviderId", "Environment",
            "ClientId", "ClientSecret", "MerchantId", "ExtraConfig",
            "AutoCapture", "AllowRefunds", "MaxRefundDays", "IsActive")
        VALUES (1, 0, 'ES', v_prov_stripe, 'sandbox',
            'PLACEHOLDER_STRIPE_PK_TEST',
            'PLACEHOLDER_STRIPE_SK_TEST',
            'acct_placeholder_stripe',
            '{"webhookSecret":"whsec_placeholder","defaultCurrency":"EUR","statementDescriptor":"DATQBOX"}',
            TRUE, TRUE, 60, TRUE);
    END IF;

    RAISE NOTICE '  pay.CompanyPaymentConfig: 3 configs de proveedor verificadas/insertadas.';
ELSE
    RAISE NOTICE '  [SKIP] Tabla pay.CompanyPaymentConfig no existe.';
END IF;

RAISE NOTICE '=== SEED DEMO FINANZAS / CONTABILIDAD / PAGOS — COMPLETADO ===';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR en seed_demo_finanzas_contabilidad: % %', SQLERRM, SQLSTATE;
END
$seed_finanzas$;
