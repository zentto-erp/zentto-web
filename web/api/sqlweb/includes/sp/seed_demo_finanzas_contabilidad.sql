-- ============================================================================
-- SEED: Demo data para Finanzas, Contabilidad y Pagos
-- Idempotente, SQL Server 2012+
-- Fecha: 2026-03-16
-- ============================================================================
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
GO

PRINT N'=== SEED DEMO FINANZAS / CONTABILIDAD / PAGOS ===';
GO

-- ============================================================================
-- 1. fin.Bank — 9 bancos adicionales (total 10)
--    VE: Mercantil, Banesco, Provincial, BDV, Banca Amiga
--    ES: CaixaBank, BBVA, Santander, Sabadell
-- ============================================================================
IF OBJECT_ID('fin.Bank', 'U') IS NOT NULL
BEGIN
    MERGE fin.Bank AS tgt
    USING (VALUES
        (1, 'MERCANTIL',   N'Banco Mercantil',             N'Centro de Atención', N'Av. Andrés Bello, Caracas',           N'+58-212-6001111'),
        (1, 'BANESCO',     N'Banesco Banco Universal',      N'Banca Digital',      N'Calle Lincoln, Caracas',             N'+58-212-5011111'),
        (1, 'PROVINCIAL',  N'BBVA Provincial',              N'Banca Corporativa',  N'Av. Este 0, Caracas',                N'+58-212-5081111'),
        (1, 'BDV',         N'Banco de Venezuela',           N'Atención al Cliente',N'Esq. de Sociedad a Gradillas, CCS',  N'+58-212-8017300'),
        (1, 'BANCA_AMIGA', N'Banca Amiga Banco Universal',  N'Soporte',            N'Av. Fco. de Miranda, Caracas',       N'+58-212-2053000'),
        (1, 'CAIXABANK',   N'CaixaBank S.A.',               N'Banca de Empresas',  N'C/ Pintor Sorolla 2-4, Valencia',    N'+34-900-404040'),
        (1, 'BBVA_ES',     N'BBVA España',                  N'Banca Empresas',     N'C/ Gran Vía 1, Bilbao',              N'+34-900-102801'),
        (1, 'SANTANDER',   N'Banco Santander España',       N'Banca Corporativa',  N'Paseo de Pereda 9-12, Santander',    N'+34-900-110011'),
        (1, 'SABADELL',    N'Banco Sabadell',               N'Negocios',           N'Av. Óscar Esplá 37, Alicante',       N'+34-900-500050')
    ) AS src (CompanyId, BankCode, BankName, ContactName, AddressLine, Phones)
    ON tgt.CompanyId = src.CompanyId AND tgt.BankCode = src.BankCode
    WHEN NOT MATCHED THEN
        INSERT (CompanyId, BankCode, BankName, ContactName, AddressLine, Phones, IsActive)
        VALUES (src.CompanyId, src.BankCode, src.BankName, src.ContactName, src.AddressLine, src.Phones, 1);
    PRINT N'  fin.Bank: 9 bancos verificados/insertados.';
END
ELSE
    PRINT N'  [SKIP] Tabla fin.Bank no existe.';
GO

-- ============================================================================
-- 2. fin.BankAccount — 5 cuentas bancarias
--    2 VE en VES, 1 VE en USD, 2 ES en EUR
-- ============================================================================
IF OBJECT_ID('fin.BankAccount', 'U') IS NOT NULL
BEGIN
    DECLARE @bankMerc BIGINT = (SELECT TOP 1 BankId FROM fin.Bank WHERE BankCode = 'MERCANTIL' AND CompanyId = 1);
    DECLARE @bankBan  BIGINT = (SELECT TOP 1 BankId FROM fin.Bank WHERE BankCode = 'BANESCO'   AND CompanyId = 1);
    DECLARE @bankProv BIGINT = (SELECT TOP 1 BankId FROM fin.Bank WHERE BankCode = 'PROVINCIAL' AND CompanyId = 1);
    DECLARE @bankCaixa BIGINT = (SELECT TOP 1 BankId FROM fin.Bank WHERE BankCode = 'CAIXABANK' AND CompanyId = 1);
    DECLARE @bankBBVA BIGINT = (SELECT TOP 1 BankId FROM fin.Bank WHERE BankCode = 'BBVA_ES'   AND CompanyId = 1);

    -- Solo insertar si tenemos los bancos
    IF @bankMerc IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM fin.BankAccount WHERE CompanyId = 1 AND AccountNumber = '01050012341234567890')
            INSERT INTO fin.BankAccount (CompanyId, BranchId, BankId, AccountNumber, AccountName, CurrencyCode, Balance, AvailableBalance, IsActive)
            VALUES (1, 1, @bankMerc, '01050012341234567890', N'Mercantil Corriente VES', 'VES', 125450.75, 125450.75, 1);
    END

    IF @bankBan IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM fin.BankAccount WHERE CompanyId = 1 AND AccountNumber = '01340056781234567890')
            INSERT INTO fin.BankAccount (CompanyId, BranchId, BankId, AccountNumber, AccountName, CurrencyCode, Balance, AvailableBalance, IsActive)
            VALUES (1, 1, @bankBan, '01340056781234567890', N'Banesco Ahorro VES', 'VES', 48320.00, 48320.00, 1);
    END

    IF @bankProv IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM fin.BankAccount WHERE CompanyId = 1 AND AccountNumber = '01080011002233445566')
            INSERT INTO fin.BankAccount (CompanyId, BranchId, BankId, AccountNumber, AccountName, CurrencyCode, Balance, AvailableBalance, IsActive)
            VALUES (1, 1, @bankProv, '01080011002233445566', N'Provincial Custodia USD', 'USD', 8750.50, 8750.50, 1);
    END

    IF @bankCaixa IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM fin.BankAccount WHERE CompanyId = 1 AND AccountNumber = 'ES7621000418401234567891')
            INSERT INTO fin.BankAccount (CompanyId, BranchId, BankId, AccountNumber, AccountName, CurrencyCode, Balance, AvailableBalance, IsActive)
            VALUES (1, 1, @bankCaixa, 'ES7621000418401234567891', N'CaixaBank Empresa EUR', 'EUR', 35200.00, 35200.00, 1);
    END

    IF @bankBBVA IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM fin.BankAccount WHERE CompanyId = 1 AND AccountNumber = 'ES9100490075032110152784')
            INSERT INTO fin.BankAccount (CompanyId, BranchId, BankId, AccountNumber, AccountName, CurrencyCode, Balance, AvailableBalance, IsActive)
            VALUES (1, 1, @bankBBVA, 'ES9100490075032110152784', N'BBVA Nomina EUR', 'EUR', 12680.30, 12680.30, 1);
    END

    PRINT N'  fin.BankAccount: 5 cuentas verificadas/insertadas.';
END
ELSE
    PRINT N'  [SKIP] Tabla fin.BankAccount no existe.';
GO

-- ============================================================================
-- 3. fin.BankMovement — 15 movimientos realistas
-- ============================================================================
IF OBJECT_ID('fin.BankMovement', 'U') IS NOT NULL
BEGIN
    -- Obtener IDs de cuentas
    DECLARE @acctMerc  BIGINT = (SELECT TOP 1 BankAccountId FROM fin.BankAccount WHERE AccountNumber = '01050012341234567890');
    DECLARE @acctBan   BIGINT = (SELECT TOP 1 BankAccountId FROM fin.BankAccount WHERE AccountNumber = '01340056781234567890');
    DECLARE @acctProv  BIGINT = (SELECT TOP 1 BankAccountId FROM fin.BankAccount WHERE AccountNumber = '01080011002233445566');
    DECLARE @acctCaixa BIGINT = (SELECT TOP 1 BankAccountId FROM fin.BankAccount WHERE AccountNumber = 'ES7621000418401234567891');
    DECLARE @acctBBVA  BIGINT = (SELECT TOP 1 BankAccountId FROM fin.BankAccount WHERE AccountNumber = 'ES9100490075032110152784');

    -- Solo si la tabla tiene menos de 10 movimientos (respetar los 4 existentes)
    IF (SELECT COUNT(*) FROM fin.BankMovement) < 10
    BEGIN
        -- Cuenta Mercantil VES — depositos y pagos
        IF @acctMerc IS NOT NULL
        BEGIN
            INSERT INTO fin.BankMovement (BankAccountId, MovementDate, MovementType, MovementSign, Amount, NetAmount, ReferenceNo, Beneficiary, Concept, CategoryCode, BalanceAfter)
            VALUES
            (@acctMerc, '2026-01-15T09:30:00', 'DEP',  1, 45000.00, 45000.00, 'TRF-20260115-001', N'Cobro Factura #1021',       N'Cobro cliente principal VTA',     'VENTAS',  80000.00),
            (@acctMerc, '2026-01-20T14:10:00', 'PCH', -1, 12500.00, 12500.00, 'CHQ-003421',       N'Proveedor Importaciones XY', N'Pago factura proveedor',          'COMPRAS', 67500.00),
            (@acctMerc, '2026-02-01T08:00:00', 'DEP',  1, 62000.00, 62000.00, 'TRF-20260201-001', N'Cobro Factura #1034',       N'Cobro mensual distribuidor',      'VENTAS', 129500.00),
            (@acctMerc, '2026-02-05T16:45:00', 'NDB', -1,  1200.00,  1200.00, 'NDB-20260205',     N'Banco Mercantil',            N'Comisiones bancarias febrero',    'GASTOS', 128300.00),
            (@acctMerc, '2026-02-15T10:00:00', 'PCH', -1,  8500.00,  8500.00, 'CHQ-003450',       N'SENIAT',                     N'Pago IVA enero 2026',             'IMPUESTOS', 119800.00);
        END

        -- Cuenta Banesco VES — ahorro
        IF @acctBan IS NOT NULL
        BEGIN
            INSERT INTO fin.BankMovement (BankAccountId, MovementDate, MovementType, MovementSign, Amount, NetAmount, ReferenceNo, Beneficiary, Concept, CategoryCode, BalanceAfter)
            VALUES
            (@acctBan, '2026-01-10T11:20:00', 'DEP',  1, 25000.00, 25000.00, 'TRF-20260110-001', N'Transferencia interna',      N'Traspaso desde Mercantil',        'TRASPASOS', 50000.00),
            (@acctBan, '2026-02-01T08:30:00', 'NCR',  1,   320.00,   320.00, 'INT-FEB-2026',     N'Banesco',                    N'Intereses ahorro enero',          'INTERESES', 50320.00),
            (@acctBan, '2026-02-10T09:00:00', 'IDB', -1,  2000.00,  2000.00, 'TRF-20260210-001', N'Caja chica',                 N'Reposicion caja chica',           'GASTOS', 48320.00);
        END

        -- Cuenta Provincial USD — custodia
        IF @acctProv IS NOT NULL
        BEGIN
            INSERT INTO fin.BankMovement (BankAccountId, MovementDate, MovementType, MovementSign, Amount, NetAmount, ReferenceNo, Beneficiary, Concept, CategoryCode, BalanceAfter)
            VALUES
            (@acctProv, '2026-01-22T15:00:00', 'DEP',  1, 3500.00, 3500.00, 'SWIFT-20260122', N'Cliente Exterior LLC',  N'Cobro exportacion servicio',  'VENTAS', 10250.00),
            (@acctProv, '2026-02-18T10:00:00', 'PCH', -1, 1500.00, 1500.00, 'WIRE-20260218',  N'Proveedor Cloud Inc',  N'Pago hosting anual',          'GASTOS',  8750.50);
        END

        -- Cuenta CaixaBank EUR — empresa
        IF @acctCaixa IS NOT NULL
        BEGIN
            INSERT INTO fin.BankMovement (BankAccountId, MovementDate, MovementType, MovementSign, Amount, NetAmount, ReferenceNo, Beneficiary, Concept, CategoryCode, BalanceAfter)
            VALUES
            (@acctCaixa, '2026-01-05T10:00:00', 'DEP',  1, 18500.00, 18500.00, 'SEPA-20260105',  N'Cliente Barcelona SL',   N'Cobro factura #ES-0042',   'VENTAS', 45000.00),
            (@acctCaixa, '2026-01-31T17:00:00', 'PCH', -1,  4800.00,  4800.00, 'SEPA-20260131',  N'Alquiler Oficina SL',    N'Alquiler enero oficina',   'ALQUILER', 40200.00),
            (@acctCaixa, '2026-02-15T09:30:00', 'PCH', -1,  5000.00,  5000.00, 'SEPA-20260215',  N'Agencia Hacienda',       N'Pago IVA trimestral 4T25', 'IMPUESTOS', 35200.00);
        END

        -- Cuenta BBVA EUR — nomina
        IF @acctBBVA IS NOT NULL
        BEGIN
            INSERT INTO fin.BankMovement (BankAccountId, MovementDate, MovementType, MovementSign, Amount, NetAmount, ReferenceNo, Beneficiary, Concept, CategoryCode, BalanceAfter)
            VALUES
            (@acctBBVA, '2026-01-28T08:00:00', 'PCH', -1, 9500.00, 9500.00, 'NOM-ENE-2026', N'Empleados',   N'Nomina enero 2026',    'NOMINA', 15180.30),
            (@acctBBVA, '2026-02-03T12:00:00', 'DEP',  1, 7000.00, 7000.00, 'TRF-INTERNA',  N'CaixaBank',   N'Provision nomina feb', 'TRASPASOS', 22180.30);
        END

        PRINT N'  fin.BankMovement: 15 movimientos insertados.';
    END
    ELSE
        PRINT N'  fin.BankMovement: ya existen 10+ movimientos, sin cambios.';
END
ELSE
    PRINT N'  [SKIP] Tabla fin.BankMovement no existe.';
GO

-- ============================================================================
-- 4. acct.FiscalPeriod — 12 periodos para 2026
--    Enero y Febrero CLOSED, resto OPEN
-- ============================================================================
IF OBJECT_ID('acct.FiscalPeriod', 'U') IS NOT NULL
BEGIN
    ;WITH months AS (
        SELECT n,
               CAST('2026' + RIGHT('0' + CAST(n AS VARCHAR), 2) AS CHAR(6)) AS PeriodCode,
               2026 AS YearCode,
               n AS MonthCode,
               DATEFROMPARTS(2026, n, 1) AS StartDate,
               EOMONTH(DATEFROMPARTS(2026, n, 1)) AS EndDate,
               CASE WHEN n <= 2 THEN 'CLOSED' ELSE 'OPEN' END AS Status,
               N'Periodo ' + DATENAME(MONTH, DATEFROMPARTS(2026, n, 1)) + N' 2026' AS PeriodName
        FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)
    )
    MERGE acct.FiscalPeriod AS tgt
    USING months AS src
    ON tgt.CompanyId = 1 AND tgt.PeriodCode = src.PeriodCode
    WHEN NOT MATCHED THEN
        INSERT (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate, Status)
        VALUES (1, src.PeriodCode, src.PeriodName, src.YearCode, src.MonthCode, src.StartDate, src.EndDate, src.Status);
    PRINT N'  acct.FiscalPeriod: 12 periodos 2026 verificados/insertados.';
END
ELSE
    PRINT N'  [SKIP] Tabla acct.FiscalPeriod no existe.';
GO

-- ============================================================================
-- 5. acct.CostCenter — 5 centros de costo
-- ============================================================================
IF OBJECT_ID('acct.CostCenter', 'U') IS NOT NULL
BEGIN
    MERGE acct.CostCenter AS tgt
    USING (VALUES
        (1, 'ADMIN',       N'Administración General',  NULL, 1),
        (1, 'VENTAS',      N'Departamento de Ventas',  NULL, 1),
        (1, 'PRODUCCION',  N'Producción',              NULL, 1),
        (1, 'ALMACEN',     N'Almacén y Logística',     NULL, 1),
        (1, 'GERENCIA',    N'Gerencia General',        NULL, 1)
    ) AS src (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, [Level])
    ON tgt.CompanyId = src.CompanyId AND tgt.CostCenterCode = src.CostCenterCode
    WHEN NOT MATCHED THEN
        INSERT (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, [Level], IsActive)
        VALUES (src.CompanyId, src.CostCenterCode, src.CostCenterName, src.ParentCostCenterId, src.[Level], 1);
    PRINT N'  acct.CostCenter: 5 centros verificados/insertados.';
END
ELSE
    PRINT N'  [SKIP] Tabla acct.CostCenter no existe.';
GO

-- ============================================================================
-- 6. acct.Budget + acct.BudgetLine — Presupuesto anual 2026
--    3 cuentas: 6.1.02 Alquileres, 6.1.03 Servicios Basicos, 6.2.02 Publicidad
-- ============================================================================
IF OBJECT_ID('acct.Budget', 'U') IS NOT NULL AND OBJECT_ID('acct.BudgetLine', 'U') IS NOT NULL
BEGIN
    DECLARE @budgetId INT;

    IF NOT EXISTS (SELECT 1 FROM acct.Budget WHERE CompanyId = 1 AND FiscalYear = 2026 AND BudgetName = N'Presupuesto Operativo 2026')
    BEGIN
        INSERT INTO acct.Budget (CompanyId, BudgetName, FiscalYear, CostCenterCode, Status, Notes)
        VALUES (1, N'Presupuesto Operativo 2026', 2026, 'ADMIN', 'APPROVED', N'Presupuesto anual de gastos operativos sede principal');

        SET @budgetId = SCOPE_IDENTITY();

        -- Alquileres: 800 mensual, sube 5% en julio
        INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06,
                                     Month07, Month08, Month09, Month10, Month11, Month12, Notes)
        VALUES (@budgetId, '6.1.02',
                800.00, 800.00, 800.00, 800.00, 800.00, 800.00,
                840.00, 840.00, 840.00, 840.00, 840.00, 840.00,
                N'Alquiler local - ajuste julio +5%');

        -- Servicios basicos: estacional
        INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06,
                                     Month07, Month08, Month09, Month10, Month11, Month12, Notes)
        VALUES (@budgetId, '6.1.03',
                350.00, 320.00, 340.00, 380.00, 420.00, 500.00,
                550.00, 560.00, 480.00, 400.00, 370.00, 360.00,
                N'Servicios básicos - estacional por clima');

        -- Publicidad: campañas Q1 y Q4
        INSERT INTO acct.BudgetLine (BudgetId, AccountCode, Month01, Month02, Month03, Month04, Month05, Month06,
                                     Month07, Month08, Month09, Month10, Month11, Month12, Notes)
        VALUES (@budgetId, '6.2.02',
                1200.00, 1500.00, 1800.00, 600.00, 500.00, 500.00,
                500.00, 600.00, 800.00, 1200.00, 2000.00, 2500.00,
                N'Publicidad - fuerte en Q1 y Q4 (temporada alta)');

        PRINT N'  acct.Budget+BudgetLine: presupuesto 2026 con 3 líneas creado.';
    END
    ELSE
        PRINT N'  acct.Budget: presupuesto 2026 ya existe.';
END
ELSE
    PRINT N'  [SKIP] Tabla acct.Budget o acct.BudgetLine no existe.';
GO

-- ============================================================================
-- 7. acct.RecurringEntry + acct.RecurringEntryLine — 3 plantillas recurrentes
-- ============================================================================
IF OBJECT_ID('acct.RecurringEntry', 'U') IS NOT NULL AND OBJECT_ID('acct.RecurringEntryLine', 'U') IS NOT NULL
BEGIN
    DECLARE @reId INT;

    -- 7a. Alquiler mensual
    IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = 1 AND TemplateName = N'Alquiler mensual local comercial')
    BEGIN
        INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive)
        VALUES (1, N'Alquiler mensual local comercial', 'MONTHLY', '2026-04-01', 3, 12, 'DIARIO', N'Pago alquiler mensual local comercial principal', 1);
        SET @reId = SCOPE_IDENTITY();
        INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
        VALUES
            (@reId, '6.1.02', N'Gasto alquiler',    'ADMIN', 800.00, 0),
            (@reId, '1.1.02', N'Pago banco alquiler','ADMIN', 0, 800.00);
    END

    -- 7b. Depreciación mensual
    IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = 1 AND TemplateName = N'Depreciación mensual mobiliario')
    BEGIN
        INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive)
        VALUES (1, N'Depreciación mensual mobiliario', 'MONTHLY', '2026-04-01', 3, NULL, 'AJUSTE', N'Depreciación mensual activos fijos - mobiliario oficina', 1);
        SET @reId = SCOPE_IDENTITY();
        INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
        VALUES
            (@reId, '6.1.04', N'Gasto depreciación',         'ADMIN', 150.00, 0),
            (@reId, '1.2.02', N'Depreciación acumulada PPE',  'ADMIN', 0, 150.00);
    END

    -- 7c. Reposición caja chica semanal
    IF NOT EXISTS (SELECT 1 FROM acct.RecurringEntry WHERE CompanyId = 1 AND TemplateName = N'Reposición caja chica semanal')
    BEGIN
        INSERT INTO acct.RecurringEntry (CompanyId, TemplateName, Frequency, NextExecutionDate, TimesExecuted, MaxExecutions, TipoAsiento, Concepto, IsActive)
        VALUES (1, N'Reposición caja chica semanal', 'WEEKLY', '2026-03-23', 10, 52, 'DIARIO', N'Reposición semanal de fondo de caja chica', 1);
        SET @reId = SCOPE_IDENTITY();
        INSERT INTO acct.RecurringEntryLine (RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit)
        VALUES
            (@reId, '1.1.01', N'Caja chica',          'VENTAS', 500.00, 0),
            (@reId, '1.1.02', N'Banco reposición caja','VENTAS', 0, 500.00);
    END

    PRINT N'  acct.RecurringEntry: 3 plantillas recurrentes verificadas/insertadas.';
END
ELSE
    PRINT N'  [SKIP] Tabla acct.RecurringEntry o acct.RecurringEntryLine no existe.';
GO

-- ============================================================================
-- 8. acct.InflationIndex — INPC Venezuela 2025-2026 (24 meses)
--    Valores realistas en contexto hiperinflacionario venezolano
--    Base dic-2007 = 100 (serie BCV). Valores simulados pero plausibles.
-- ============================================================================
IF OBJECT_ID('acct.InflationIndex', 'U') IS NOT NULL
BEGIN
    MERGE acct.InflationIndex AS tgt
    USING (VALUES
        -- 2025: inflación acumulada ~180% (aprox 8-12% mensual promedio)
        (1, 'VE', 'INPC', '202501',  285400.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202502',  310280.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202503',  335100.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202504',  358860.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202505',  387570.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202506',  422450.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202507',  460870.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202508',  498140.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202509',  538000.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202510',  586820.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202511',  639630.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202512',  697200.000000, N'BCV Gaceta Oficial'),
        -- 2026: inflación se modera ligeramente (5-9% mensual)
        (1, 'VE', 'INPC', '202601',  753980.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202602',  808020.000000, N'BCV Gaceta Oficial'),
        (1, 'VE', 'INPC', '202603',  864580.000000, N'BCV Gaceta Oficial (est.)'),
        (1, 'VE', 'INPC', '202604',  924100.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202605',  987790.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202606', 1056930.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202607', 1120350.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202608', 1187570.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202609', 1258830.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202610', 1334360.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202611', 1414420.000000, N'BCV Gaceta Oficial (proy.)'),
        (1, 'VE', 'INPC', '202612', 1499290.000000, N'BCV Gaceta Oficial (proy.)')
    ) AS src (CompanyId, CountryCode, IndexName, PeriodCode, IndexValue, SourceReference)
    ON tgt.CompanyId = src.CompanyId AND tgt.CountryCode = src.CountryCode
       AND tgt.IndexName = src.IndexName AND tgt.PeriodCode = src.PeriodCode
    WHEN NOT MATCHED THEN
        INSERT (CompanyId, CountryCode, IndexName, PeriodCode, IndexValue, SourceReference)
        VALUES (src.CompanyId, src.CountryCode, src.IndexName, src.PeriodCode, src.IndexValue, src.SourceReference);
    PRINT N'  acct.InflationIndex: 24 meses INPC VE verificados/insertados.';
END
ELSE
    PRINT N'  [SKIP] Tabla acct.InflationIndex no existe.';
GO

-- ============================================================================
-- 9. pay.AcceptedPaymentMethods — 6 métodos para CompanyId=1
--    Efectivo, TDD, TDC, Transferencia, Pago Móvil (C2P), Zelle
-- ============================================================================
IF OBJECT_ID('pay.AcceptedPaymentMethods', 'U') IS NOT NULL
BEGIN
    DECLARE @pmEfectivo     INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'EFECTIVO'  AND CountryCode IS NULL);
    DECLARE @pmTDD          INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'TDD'       AND CountryCode IS NULL);
    DECLARE @pmTDC          INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'TDC'       AND CountryCode IS NULL);
    DECLARE @pmTransfer     INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'TRANSFER'  AND CountryCode IS NULL);
    DECLARE @pmC2P          INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'C2P'       AND CountryCode = 'VE');
    DECLARE @pmZelle        INT = (SELECT TOP 1 Id FROM pay.PaymentMethods WHERE Code = 'ZELLE'     AND CountryCode = 'US');

    -- Mercantil provider para C2P
    DECLARE @provMerc       INT = (SELECT TOP 1 Id FROM pay.PaymentProviders WHERE Code = 'MERCANTIL');

    IF @pmEfectivo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmEfectivo AND ProviderId IS NULL)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmEfectivo, NULL, 1, 0, 1, 0, 0, 1, 1);

    IF @pmTDD IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmTDD AND ProviderId = @provMerc)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmTDD, @provMerc, 1, 1, 1, 0.0200, 0, 1, 2);

    IF @pmTDC IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmTDC AND ProviderId = @provMerc)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmTDC, @provMerc, 1, 1, 1, 0.0350, 0, 1, 3);

    IF @pmTransfer IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmTransfer AND ProviderId IS NULL)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmTransfer, NULL, 1, 1, 1, 0, 0, 1, 4);

    IF @pmC2P IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmC2P AND ProviderId = @provMerc)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmC2P, @provMerc, 1, 1, 1, 0.0100, 0, 1, 5);

    IF @pmZelle IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.AcceptedPaymentMethods WHERE EmpresaId = 1 AND SucursalId = 1 AND PaymentMethodId = @pmZelle AND ProviderId IS NULL)
        INSERT INTO pay.AcceptedPaymentMethods (EmpresaId, SucursalId, PaymentMethodId, ProviderId, AppliesToPOS, AppliesToWeb, AppliesToRestaurant, MinAmount, MaxAmount, CommissionPct, CommissionFixed, IsActive, SortOrder)
        VALUES (1, 1, @pmZelle, NULL, 0, 1, 0, 5.00, 2500.00, 0, 0, 1, 6);

    PRINT N'  pay.AcceptedPaymentMethods: 6 métodos verificados/insertados para EmpresaId=1.';
END
ELSE
    PRINT N'  [SKIP] Tabla pay.AcceptedPaymentMethods no existe.';
GO

-- ============================================================================
-- 10. pay.CompanyPaymentConfig — 3 configuraciones de proveedor
--     Mercantil C2P, Binance Pay, Stripe
-- ============================================================================
IF OBJECT_ID('pay.CompanyPaymentConfig', 'U') IS NOT NULL
BEGIN
    DECLARE @provMercPay    INT = (SELECT TOP 1 Id FROM pay.PaymentProviders WHERE Code = 'MERCANTIL');
    DECLARE @provBinance    INT = (SELECT TOP 1 Id FROM pay.PaymentProviders WHERE Code = 'BINANCE');
    DECLARE @provStripe     INT = (SELECT TOP 1 Id FROM pay.PaymentProviders WHERE Code = 'STRIPE');

    -- Mercantil C2P
    IF @provMercPay IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.CompanyPaymentConfig WHERE EmpresaId = 1 AND SucursalId = 1 AND ProviderId = @provMercPay)
        INSERT INTO pay.CompanyPaymentConfig (EmpresaId, SucursalId, CountryCode, ProviderId, Environment,
            ClientId, ClientSecret, MerchantId, TerminalId, IntegratorId, ExtraConfig,
            AutoCapture, AllowRefunds, MaxRefundDays, IsActive)
        VALUES (1, 1, 'VE', @provMercPay, 'sandbox',
            'PLACEHOLDER_CLIENT_ID_MERCANTIL',
            'PLACEHOLDER_CLIENT_SECRET_MERCANTIL',
            'MERCH-001',
            'TERM-001',
            'INTEG-001',
            '{"phoneC2P":"04141234567","bankCode":"0105","identificationType":"V","identificationNumber":"12345678"}',
            1, 1, 30, 1);

    -- Binance Pay
    IF @provBinance IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.CompanyPaymentConfig WHERE EmpresaId = 1 AND SucursalId = 0 AND ProviderId = @provBinance)
        INSERT INTO pay.CompanyPaymentConfig (EmpresaId, SucursalId, CountryCode, ProviderId, Environment,
            ClientId, ClientSecret, MerchantId, ExtraConfig,
            AutoCapture, AllowRefunds, MaxRefundDays, IsActive)
        VALUES (1, 0, 'VE', @provBinance, 'sandbox',
            'PLACEHOLDER_BINANCE_API_KEY',
            'PLACEHOLDER_BINANCE_SECRET_KEY',
            'BINANCE-MERCH-001',
            '{"defaultCurrency":"USDT","returnUrl":"https://app.datqbox.com/payment/callback","cancelUrl":"https://app.datqbox.com/payment/cancel"}',
            1, 1, 15, 1);

    -- Stripe
    IF @provStripe IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pay.CompanyPaymentConfig WHERE EmpresaId = 1 AND SucursalId = 0 AND ProviderId = @provStripe)
        INSERT INTO pay.CompanyPaymentConfig (EmpresaId, SucursalId, CountryCode, ProviderId, Environment,
            ClientId, ClientSecret, MerchantId, ExtraConfig,
            AutoCapture, AllowRefunds, MaxRefundDays, IsActive)
        VALUES (1, 0, 'ES', @provStripe, 'sandbox',
            'PLACEHOLDER_STRIPE_PK_TEST',
            'PLACEHOLDER_STRIPE_SK_TEST',
            'acct_placeholder_stripe',
            '{"webhookSecret":"whsec_placeholder","defaultCurrency":"EUR","statementDescriptor":"DATQBOX"}',
            1, 1, 60, 1);

    PRINT N'  pay.CompanyPaymentConfig: 3 configs de proveedor verificadas/insertadas.';
END
ELSE
    PRINT N'  [SKIP] Tabla pay.CompanyPaymentConfig no existe.';
GO

-- ============================================================================
PRINT N'=== SEED DEMO FINANZAS / CONTABILIDAD / PAGOS — COMPLETADO ===';
GO
