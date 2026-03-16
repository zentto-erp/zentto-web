USE DatqBoxWeb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- SEED RRHH COMPLETO — Datos realistas para Venezuela
-- Idempotente: usa IF NOT EXISTS en cada INSERT
-- Fecha: 2026-03-15
-- ============================================================================

PRINT '=== SEED RRHH COMPLETO — Inicio ===';

-- ============================================================================
-- 1. UTILIDADES 2025 (ProfitSharing + ProfitSharingLine)
-- ============================================================================
PRINT '>> 1. Utilidades 2025';

-- Empleado 1: Salario mensual 3500, diario = 3500/30 = 116.6667
-- Empleado 2: Salario mensual 2800, diario = 2800/30 = 93.3333
-- DaysWorked=365, DaysEntitled=30
-- GrossAmount = DailySalary * DaysEntitled = 116.6667*30 = 3500.00 / 93.3333*30 = 2800.00
-- InceDeduction = GrossAmount * 0.005
-- NetAmount = GrossAmount - InceDeduction

IF NOT EXISTS (
    SELECT 1 FROM hr.ProfitSharing
    WHERE CompanyId = 1 AND FiscalYear = 2025
)
BEGIN
    SET IDENTITY_INSERT hr.ProfitSharing ON;
    INSERT INTO hr.ProfitSharing (
        ProfitSharingId, CompanyId, BranchId, FiscalYear, DaysGranted,
        TotalCompanyProfits, Status, CreatedBy, CreatedAt, UpdatedAt
    )
    VALUES (
        1, 1, 1, 2025, 30,
        500000.00, N'CALCULADA', 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
    SET IDENTITY_INSERT hr.ProfitSharing OFF;
    PRINT '   ProfitSharing 2025 insertado.';
END;

-- Línea empleado 1
IF NOT EXISTS (
    SELECT 1 FROM hr.ProfitSharingLine
    WHERE ProfitSharingId = 1 AND EmployeeId = 1
)
BEGIN
    SET IDENTITY_INSERT hr.ProfitSharingLine ON;
    INSERT INTO hr.ProfitSharingLine (
        LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
        MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
        GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
    )
    VALUES (
        1, 1, 1, N'V-25678901', N'Empleado V-25678901',
        3500.00, 116.6667, 365, 30,
        3500.00, 17.50, 3482.50, 0, NULL
    );
    SET IDENTITY_INSERT hr.ProfitSharingLine OFF;
    PRINT '   ProfitSharingLine empleado 1 insertado.';
END;

-- Línea empleado 2
IF NOT EXISTS (
    SELECT 1 FROM hr.ProfitSharingLine
    WHERE ProfitSharingId = 1 AND EmployeeId = 2
)
BEGIN
    SET IDENTITY_INSERT hr.ProfitSharingLine ON;
    INSERT INTO hr.ProfitSharingLine (
        LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
        MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
        GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
    )
    VALUES (
        2, 1, 2, N'V-18901234', N'Empleado V-18901234',
        2800.00, 93.3333, 365, 30,
        2800.00, 14.00, 2786.00, 0, NULL
    );
    SET IDENTITY_INSERT hr.ProfitSharingLine OFF;
    PRINT '   ProfitSharingLine empleado 2 insertado.';
END;

-- ============================================================================
-- 2. FIDEICOMISO (SocialBenefitsTrust) — 4 trimestres 2025, ambos empleados
-- ============================================================================
PRINT '>> 2. Fideicomiso de Prestaciones Sociales 2025';

-- Empleado 1: DailySalary=116.6667, 15 dias/trimestre, InterestRate=15.3%
-- DepositAmount = DailySalary * DaysDeposited
-- Q1: Deposit=1750.00, Interest=0 (primer trimestre), Accumulated=1750.00
-- Q2: Deposit=1750.00, Interest=1750*0.153/4=66.94, Accumulated=3566.94
-- Q3: Deposit=1750.00, Interest=3566.94*0.153/4=136.44, Accumulated=5453.38
-- Q4: Deposit=1750.00, Interest=5453.38*0.153/4=208.59, Accumulated=7411.97

-- Empleado 2: DailySalary=93.3333, 15 dias/trimestre
-- Q1: Deposit=1400.00, Interest=0, Accumulated=1400.00
-- Q2: Deposit=1400.00, Interest=1400*0.153/4=53.55, Accumulated=2853.55
-- Q3: Deposit=1400.00, Interest=2853.55*0.153/4=109.15, Accumulated=4362.70
-- Q4: Deposit=1400.00, Interest=4362.70*0.153/4=166.87, Accumulated=5929.57

SET IDENTITY_INSERT hr.SocialBenefitsTrust ON;

-- Empleado 1: Q1
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 1)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    1, 1, 1, N'V-25678901', N'Empleado V-25678901',
    2025, 1, 116.6667, 15, 0,
    1750.00, 15.30, 0.00, 1750.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 1: Q2
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 2)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    2, 1, 1, N'V-25678901', N'Empleado V-25678901',
    2025, 2, 116.6667, 15, 0,
    1750.00, 15.30, 66.94, 3566.94,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 1: Q3
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 3)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    3, 1, 1, N'V-25678901', N'Empleado V-25678901',
    2025, 3, 116.6667, 15, 0,
    1750.00, 15.30, 136.44, 5453.38,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 1: Q4
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 4)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    4, 1, 1, N'V-25678901', N'Empleado V-25678901',
    2025, 4, 116.6667, 15, 0,
    1750.00, 15.30, 208.59, 7411.97,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 2: Q1
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 5)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    5, 1, 2, N'V-18901234', N'Empleado V-18901234',
    2025, 1, 93.3333, 15, 0,
    1400.00, 15.30, 0.00, 1400.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 2: Q2
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 6)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    6, 1, 2, N'V-18901234', N'Empleado V-18901234',
    2025, 2, 93.3333, 15, 0,
    1400.00, 15.30, 53.55, 2853.55,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 2: Q3
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 7)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    7, 1, 2, N'V-18901234', N'Empleado V-18901234',
    2025, 3, 93.3333, 15, 0,
    1400.00, 15.30, 109.15, 4362.70,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Empleado 2: Q4
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 8)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    8, 1, 2, N'V-18901234', N'Empleado V-18901234',
    2025, 4, 93.3333, 15, 0,
    1400.00, 15.30, 166.87, 5929.57,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SocialBenefitsTrust OFF;
PRINT '   8 registros de fideicomiso insertados.';

-- ============================================================================
-- 3. CAJA DE AHORRO (SavingsFund + SavingsFundTransaction + SavingsLoan)
-- ============================================================================
PRINT '>> 3. Caja de Ahorro';

-- Inscripción de empleados
SET IDENTITY_INSERT hr.SavingsFund ON;

IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 1)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    1, 1, 1, N'V-25678901', N'Empleado V-25678901',
    5.00, 5.00, '2025-01-15', N'ACTIVO', SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 2)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    2, 1, 2, N'V-18901234', N'Empleado V-18901234',
    5.00, 5.00, '2025-01-15', N'ACTIVO', SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsFund OFF;
PRINT '   2 inscripciones de caja de ahorro insertadas.';

-- Transacciones: 3 meses (ene, feb, mar 2025) x 2 tipos x 2 empleados = 12 transacciones
-- Empleado 1: 5% de 3500 = 175.00 por tipo por mes
-- Empleado 2: 5% de 2800 = 140.00 por tipo por mes

SET IDENTITY_INSERT hr.SavingsFundTransaction ON;

-- Empleado 1, Enero: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 1)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    1, 1, '2025-01-31', N'APORTE_EMPLEADO',
    175.00, 175.00, N'NOM-2025-01', NULL, N'Aporte enero 2025', SYSUTCDATETIME()
);

-- Empleado 1, Enero: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 2)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    2, 1, '2025-01-31', N'APORTE_PATRONAL',
    175.00, 350.00, N'NOM-2025-01', NULL, N'Aporte patronal enero 2025', SYSUTCDATETIME()
);

-- Empleado 1, Febrero: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 3)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    3, 1, '2025-02-28', N'APORTE_EMPLEADO',
    175.00, 525.00, N'NOM-2025-02', NULL, N'Aporte febrero 2025', SYSUTCDATETIME()
);

-- Empleado 1, Febrero: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 4)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    4, 1, '2025-02-28', N'APORTE_PATRONAL',
    175.00, 700.00, N'NOM-2025-02', NULL, N'Aporte patronal febrero 2025', SYSUTCDATETIME()
);

-- Empleado 1, Marzo: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 5)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    5, 1, '2025-03-31', N'APORTE_EMPLEADO',
    175.00, 875.00, N'NOM-2025-03', NULL, N'Aporte marzo 2025', SYSUTCDATETIME()
);

-- Empleado 1, Marzo: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 6)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    6, 1, '2025-03-31', N'APORTE_PATRONAL',
    175.00, 1050.00, N'NOM-2025-03', NULL, N'Aporte patronal marzo 2025', SYSUTCDATETIME()
);

-- Empleado 2, Enero: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 7)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    7, 2, '2025-01-31', N'APORTE_EMPLEADO',
    140.00, 140.00, N'NOM-2025-01', NULL, N'Aporte enero 2025', SYSUTCDATETIME()
);

-- Empleado 2, Enero: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 8)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    8, 2, '2025-01-31', N'APORTE_PATRONAL',
    140.00, 280.00, N'NOM-2025-01', NULL, N'Aporte patronal enero 2025', SYSUTCDATETIME()
);

-- Empleado 2, Febrero: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 9)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    9, 2, '2025-02-28', N'APORTE_EMPLEADO',
    140.00, 420.00, N'NOM-2025-02', NULL, N'Aporte febrero 2025', SYSUTCDATETIME()
);

-- Empleado 2, Febrero: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 10)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    10, 2, '2025-02-28', N'APORTE_PATRONAL',
    140.00, 560.00, N'NOM-2025-02', NULL, N'Aporte patronal febrero 2025', SYSUTCDATETIME()
);

-- Empleado 2, Marzo: APORTE_EMPLEADO
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 11)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    11, 2, '2025-03-31', N'APORTE_EMPLEADO',
    140.00, 700.00, N'NOM-2025-03', NULL, N'Aporte marzo 2025', SYSUTCDATETIME()
);

-- Empleado 2, Marzo: APORTE_PATRONAL
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 12)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    12, 2, '2025-03-31', N'APORTE_PATRONAL',
    140.00, 840.00, N'NOM-2025-03', NULL, N'Aporte patronal marzo 2025', SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsFundTransaction OFF;
PRINT '   12 transacciones de caja de ahorro insertadas.';

-- Préstamo para empleado 1
-- LoanAmount=5000, InterestRate=6%, 12 cuotas
-- TotalPayable = 5000 * 1.06 = 5300
-- MonthlyPayment = 5300 / 12 = 441.67
-- 3 cuotas pagadas: InstallmentsPaid=3, OutstandingBalance=5300-(441.67*3)=3975.01

SET IDENTITY_INSERT hr.SavingsLoan ON;

IF NOT EXISTS (SELECT 1 FROM hr.SavingsLoan WHERE LoanId = 1)
INSERT INTO hr.SavingsLoan (
    LoanId, SavingsFundId, EmployeeCode, RequestDate, ApprovedDate,
    LoanAmount, InterestRate, TotalPayable, MonthlyPayment,
    InstallmentsTotal, InstallmentsPaid, OutstandingBalance,
    Status, ApprovedBy, Notes, CreatedAt, UpdatedAt
) VALUES (
    1, 1, N'V-25678901', '2025-04-01', '2025-04-05',
    5000.00, 6.00, 5300.00, 441.67,
    12, 3, 3975.01,
    N'APROBADO', 1, N'Préstamo ordinario caja de ahorro', SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsLoan OFF;
PRINT '   1 préstamo de caja de ahorro insertado.';

-- ============================================================================
-- 4. OBLIGACIONES LEGALES — Inscripción empleados + Filing SSO enero 2026
-- ============================================================================
PRINT '>> 4. Obligaciones Legales';

-- Buscar LegalObligationIds dinámicamente por código
-- VE_SSO, VE_FAOV, VE_INCE ya deben existir en hr.LegalObligation

-- Inscribir empleado 1 en SSO
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 1 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        1,
        lo.LegalObligationId,
        N'SSO-0125678901',
        N'IVSS',
        NULL,
        '2024-03-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_SSO';
    PRINT '   Empleado 1 inscrito en SSO.';
END;

-- Inscribir empleado 1 en FAOV
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 1 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        1,
        lo.LegalObligationId,
        N'FAOV-0125678901',
        N'BANAVIH',
        NULL,
        '2024-03-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_FAOV';
    PRINT '   Empleado 1 inscrito en FAOV.';
END;

-- Inscribir empleado 1 en INCE
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 1 AND lo.Code = N'VE_INCE'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        1,
        lo.LegalObligationId,
        N'INCE-0125678901',
        N'INCE',
        NULL,
        '2024-03-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_INCE';
    PRINT '   Empleado 1 inscrito en INCE.';
END;

-- Inscribir empleado 2 en SSO
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 2 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        2,
        lo.LegalObligationId,
        N'SSO-0218901234',
        N'IVSS',
        NULL,
        '2024-06-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_SSO';
    PRINT '   Empleado 2 inscrito en SSO.';
END;

-- Inscribir empleado 2 en FAOV
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 2 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        2,
        lo.LegalObligationId,
        N'FAOV-0218901234',
        N'BANAVIH',
        NULL,
        '2024-06-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_FAOV';
    PRINT '   Empleado 2 inscrito en FAOV.';
END;

-- Inscribir empleado 2 en INCE
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 2 AND lo.Code = N'VE_INCE'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT
        2,
        lo.LegalObligationId,
        N'INCE-0218901234',
        N'INCE',
        NULL,
        '2024-06-01',
        NULL,
        N'ACTIVO',
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM hr.LegalObligation lo
    WHERE lo.Code = N'VE_INCE';
    PRINT '   Empleado 2 inscrito en INCE.';
END;

-- Filing SSO enero 2026
-- Empleado 1: BaseSalary=3500, SSO patronal ~11%=385, SSO empleado ~4%=140
-- Empleado 2: BaseSalary=2800, SSO patronal ~11%=308, SSO empleado ~4%=112
-- TotalEmployer=693, TotalEmployee=252, TotalAmount=945

SET IDENTITY_INSERT hr.ObligationFiling ON;

IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 1)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    1, 1, lo.LegalObligationId,
    '2026-01-01', '2026-01-31', '2026-02-15', '2026-02-10',
    N'IVSS-2026-01-00458', 693.00, 252.00, 945.00,
    2, N'FILED', 1, NULL, N'Declaración SSO enero 2026',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo
WHERE lo.Code = N'VE_SSO';

SET IDENTITY_INSERT hr.ObligationFiling OFF;
PRINT '   Filing SSO enero 2026 insertado.';

-- Filing Detail: empleado 1
IF NOT EXISTS (
    SELECT 1 FROM hr.ObligationFilingDetail
    WHERE ObligationFilingId = 1 AND EmployeeId = 1
)
INSERT INTO hr.ObligationFilingDetail (
    ObligationFilingId, EmployeeId, BaseSalary,
    EmployerAmount, EmployeeAmount, DaysWorked, NoveltyType
) VALUES (
    1, 1, 3500.00,
    385.00, 140.00, 31, NULL
);

-- Filing Detail: empleado 2
IF NOT EXISTS (
    SELECT 1 FROM hr.ObligationFilingDetail
    WHERE ObligationFilingId = 1 AND EmployeeId = 2
)
INSERT INTO hr.ObligationFilingDetail (
    ObligationFilingId, EmployeeId, BaseSalary,
    EmployerAmount, EmployeeAmount, DaysWorked, NoveltyType
) VALUES (
    1, 2, 2800.00,
    308.00, 112.00, 31, NULL
);

PRINT '   2 detalles de filing SSO insertados.';

-- ============================================================================
-- 5. SALUD OCUPACIONAL (OccupationalHealth)
-- ============================================================================
PRINT '>> 5. Salud Ocupacional';

SET IDENTITY_INSERT hr.OccupationalHealth ON;

-- Accidente leve
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE OccupationalHealthId = 1)
INSERT INTO hr.OccupationalHealth (
    OccupationalHealthId, CompanyId, CountryCode, RecordType,
    EmployeeId, EmployeeCode, EmployeeName,
    OccurrenceDate, ReportDeadline, ReportedDate,
    Severity, BodyPartAffected, DaysLost, Location,
    Description, RootCause, CorrectiveAction,
    InvestigationDueDate, InvestigationCompletedDate,
    InstitutionReference, Status, DocumentUrl, Notes,
    CreatedBy, CreatedAt, UpdatedAt
) VALUES (
    1, 1, N'VE', N'ACCIDENTE',
    1, N'V-25678901', N'Empleado V-25678901',
    '2025-09-15', '2025-09-19', '2025-09-16',
    N'LEVE', N'Mano derecha', 2, N'Almacén principal',
    N'Corte superficial en mano derecha al manipular cajas de inventario.',
    N'Ausencia de guantes de protección durante manipulación de cajas.',
    N'Dotación inmediata de guantes de seguridad. Charla de refuerzo sobre EPP.',
    '2025-09-22', '2025-09-20',
    N'INPSASEL-2025-09-004571', N'CLOSED', NULL,
    N'Caso cerrado. Empleado reincorporado el 2025-09-17.',
    1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Incidente sin días perdidos
IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth WHERE OccupationalHealthId = 2)
INSERT INTO hr.OccupationalHealth (
    OccupationalHealthId, CompanyId, CountryCode, RecordType,
    EmployeeId, EmployeeCode, EmployeeName,
    OccurrenceDate, ReportDeadline, ReportedDate,
    Severity, BodyPartAffected, DaysLost, Location,
    Description, RootCause, CorrectiveAction,
    InvestigationDueDate, InvestigationCompletedDate,
    InstitutionReference, Status, DocumentUrl, Notes,
    CreatedBy, CreatedAt, UpdatedAt
) VALUES (
    2, 1, N'VE', N'INCIDENTE',
    2, N'V-18901234', N'Empleado V-18901234',
    '2025-11-03', '2025-11-07', '2025-11-04',
    N'LEVE', NULL, 0, N'Oficina administrativa',
    N'Derrame de líquido en pasillo causó resbalón sin caída ni lesión.',
    N'Falta de señalización de piso mojado.',
    N'Instalación de porta avisos de piso húmedo en cada área. Protocolo de limpieza actualizado.',
    '2025-11-10', NULL,
    NULL, N'REPORTED', NULL,
    N'Incidente reportado. Sin lesión. Pendiente cierre de investigación.',
    1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.OccupationalHealth OFF;
PRINT '   2 registros de salud ocupacional insertados.';

-- ============================================================================
-- 6. EXÁMENES MÉDICOS (MedicalExam)
-- ============================================================================
PRINT '>> 6. Exámenes Médicos';

SET IDENTITY_INSERT hr.MedicalExam ON;

-- Preempleo empleado 1
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE MedicalExamId = 1)
INSERT INTO hr.MedicalExam (
    MedicalExamId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    ExamType, ExamDate, NextDueDate, Result, Restrictions,
    PhysicianName, ClinicName, DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    1, 1, 1, N'V-25678901', N'Empleado V-25678901',
    N'PREEMPLEO', '2024-02-20', NULL, N'APTO',
    NULL,
    N'Dra. María González', N'Centro Médico La Trinidad',
    NULL, N'Examen preempleo sin observaciones.', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Preempleo empleado 2
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE MedicalExamId = 2)
INSERT INTO hr.MedicalExam (
    MedicalExamId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    ExamType, ExamDate, NextDueDate, Result, Restrictions,
    PhysicianName, ClinicName, DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    2, 1, 2, N'V-18901234', N'Empleado V-18901234',
    N'PREEMPLEO', '2024-05-10', NULL, N'APTO',
    NULL,
    N'Dr. Carlos Ramírez', N'Clínica Santa Sofía',
    NULL, N'Examen preempleo sin restricciones.', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Periódico empleado 1
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE MedicalExamId = 3)
INSERT INTO hr.MedicalExam (
    MedicalExamId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    ExamType, ExamDate, NextDueDate, Result, Restrictions,
    PhysicianName, ClinicName, DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    3, 1, 1, N'V-25678901', N'Empleado V-25678901',
    N'PERIODICO', '2025-02-18', '2026-02-18', N'APTO',
    NULL,
    N'Dra. María González', N'Centro Médico La Trinidad',
    NULL, N'Control anual. Sin hallazgos relevantes.', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Periódico empleado 2 — NextDueDate VENCIDA para generar alerta
IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam WHERE MedicalExamId = 4)
INSERT INTO hr.MedicalExam (
    MedicalExamId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    ExamType, ExamDate, NextDueDate, Result, Restrictions,
    PhysicianName, ClinicName, DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    4, 1, 2, N'V-18901234', N'Empleado V-18901234',
    N'PERIODICO', '2025-01-10', '2026-01-10', N'APTO',
    N'Uso de lentes correctivos obligatorio',
    N'Dr. Carlos Ramírez', N'Clínica Santa Sofía',
    NULL, N'Control anual. Requiere lentes correctivos. VENCIDO — próximo examen pendiente.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.MedicalExam OFF;
PRINT '   4 exámenes médicos insertados.';

-- ============================================================================
-- 7. ÓRDENES MÉDICAS (MedicalOrder)
-- ============================================================================
PRINT '>> 7. Órdenes Médicas';

SET IDENTITY_INSERT hr.MedicalOrder ON;

-- Consulta aprobada
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE MedicalOrderId = 1)
INSERT INTO hr.MedicalOrder (
    MedicalOrderId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions,
    EstimatedCost, ApprovedAmount, Status, ApprovedBy, ApprovedAt,
    DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    1, 1, 1, N'V-25678901', N'Empleado V-25678901',
    N'CONSULTA', '2025-10-05', N'Lumbalgia mecánica',
    N'Dr. Pedro Martínez', N'Ibuprofeno 400mg c/8h x 5 días. Reposo relativo.',
    150.00, 150.00, N'APROBADA', 1, '2025-10-06',
    NULL, N'Consulta traumatología por dolor lumbar.', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Farmacia pendiente
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE MedicalOrderId = 2)
INSERT INTO hr.MedicalOrder (
    MedicalOrderId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions,
    EstimatedCost, ApprovedAmount, Status, ApprovedBy, ApprovedAt,
    DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    2, 1, 2, N'V-18901234', N'Empleado V-18901234',
    N'FARMACIA', '2026-02-20', N'Hipertensión arterial controlada',
    N'Dra. Ana Suárez', N'Losartán 50mg, Amlodipino 5mg — tratamiento mensual.',
    85.00, NULL, N'PENDIENTE', NULL, NULL,
    NULL, N'Solicitud de reembolso farmacia pendiente de aprobación.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Laboratorio aprobada
IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder WHERE MedicalOrderId = 3)
INSERT INTO hr.MedicalOrder (
    MedicalOrderId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    OrderType, OrderDate, Diagnosis, PhysicianName, Prescriptions,
    EstimatedCost, ApprovedAmount, Status, ApprovedBy, ApprovedAt,
    DocumentUrl, Notes, CreatedAt, UpdatedAt
) VALUES (
    3, 1, 1, N'V-25678901', N'Empleado V-25678901',
    N'LABORATORIO', '2025-11-12', N'Chequeo general anual',
    N'Dra. María González', N'Hematología completa, Glicemia, Perfil lipídico, Urea, Creatinina.',
    200.00, 200.00, N'APROBADA', 1, '2025-11-13',
    NULL, N'Exámenes de laboratorio anuales.', SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.MedicalOrder OFF;
PRINT '   3 órdenes médicas insertadas.';

-- ============================================================================
-- 8. CAPACITACIÓN (TrainingRecord)
-- ============================================================================
PRINT '>> 8. Capacitación';

SET IDENTITY_INSERT hr.TrainingRecord ON;

-- Inducción LOPCYMAT - Empleado 1
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 1)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    1, 1, N'VE', N'INDUCCION', N'Inducción LOPCYMAT', N'INPSASEL / Empresa Demo',
    '2024-03-05', '2024-03-06', 16,
    1, N'V-25678901', N'Empleado V-25678901',
    N'CERT-LOPCYMAT-2024-001', NULL, N'APROBADO', 1,
    N'Formación obligatoria según LOPCYMAT Art. 53. Incluye: riesgos laborales, EPP, plan de emergencia.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Inducción LOPCYMAT - Empleado 2
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 2)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    2, 1, N'VE', N'INDUCCION', N'Inducción LOPCYMAT', N'INPSASEL / Empresa Demo',
    '2024-06-10', '2024-06-11', 16,
    2, N'V-18901234', N'Empleado V-18901234',
    N'CERT-LOPCYMAT-2024-002', NULL, N'APROBADO', 1,
    N'Formación obligatoria según LOPCYMAT Art. 53. Incluye: riesgos laborales, EPP, plan de emergencia.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Primeros Auxilios - Empleado 1
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 3)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    3, 1, N'VE', N'SEGURIDAD', N'Primeros Auxilios', N'Cruz Roja Venezolana',
    '2025-04-14', '2025-04-14', 8,
    1, N'V-25678901', N'Empleado V-25678901',
    N'CRV-PA-2025-0891', NULL, N'APROBADO', 1,
    N'Curso obligatorio para brigada de emergencia. Incluye RCP y manejo de heridas.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Excel Avanzado - Empleado 2 (no regulatorio)
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 4)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    4, 1, N'VE', N'DESARROLLO', N'Excel Avanzado', N'Academia TechPro',
    '2025-05-05', '2025-05-23', 24,
    2, N'V-18901234', N'Empleado V-18901234',
    N'TP-EXCEL-2025-0234', NULL, N'APROBADO', 0,
    N'Tablas dinámicas, macros VBA, Power Query. Formación de desarrollo profesional.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.TrainingRecord OFF;
PRINT '   4 registros de capacitación insertados.';

-- ============================================================================
-- 9. COMITÉ DE SEGURIDAD (SafetyCommittee + Members + Meetings)
-- ============================================================================
PRINT '>> 9. Comité de Seguridad y Salud Laboral';

SET IDENTITY_INSERT hr.SafetyCommittee ON;

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee WHERE SafetyCommitteeId = 1)
INSERT INTO hr.SafetyCommittee (
    SafetyCommitteeId, CompanyId, CountryCode, CommitteeName,
    FormationDate, MeetingFrequency, IsActive, CreatedAt
) VALUES (
    1, 1, N'VE', N'Comité SSL Empresa Demo',
    '2024-04-01', N'MENSUAL', 1, SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SafetyCommittee OFF;

-- Miembros
SET IDENTITY_INSERT hr.SafetyCommitteeMember ON;

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 1)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    1, 1, 1, N'V-25678901', N'Empleado V-25678901',
    N'DELEGADO_PATRONAL', '2024-04-01', NULL
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 2)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    2, 1, 2, N'V-18901234', N'Empleado V-18901234',
    N'DELEGADO_TRABAJADOR', '2024-06-15', NULL
);

SET IDENTITY_INSERT hr.SafetyCommitteeMember OFF;

-- Reuniones
SET IDENTITY_INSERT hr.SafetyCommitteeMeeting ON;

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 1)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    1, 1, '2025-11-05', NULL,
    N'1. Revisión de incidentes octubre. 2. Estado de dotación EPP. 3. Simulacro de evacuación programado.',
    N'- Completar dotación de guantes para almacén antes del 15/11. - Programar simulacro para diciembre. - Actualizar mapa de riesgos del área administrativa.',
    SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 2)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    2, 1, '2025-12-03', NULL,
    N'1. Resultado simulacro evacuación. 2. Cierre caso accidente sept. 3. Plan de capacitación 2026.',
    N'- Documentar resultados del simulacro (tiempo evacuación: 3min 45seg). - Solicitar presupuesto capacitación primeros auxilios 2026. - Revisar vencimiento exámenes médicos periódicos.',
    SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SafetyCommitteeMeeting OFF;
PRINT '   Comité SSL con 2 miembros y 2 reuniones insertado.';

-- ============================================================================
-- 10. OBLIGACIONES LEGALES — Catálogo multi-país (ES, CO, MX, US)
-- ============================================================================
PRINT '>> 10. Obligaciones legales multi-país';

-- ---- ESPAÑA ----

-- ES_TGSS: Seguridad Social española
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'ES_TGSS')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'ES', N'ES_TGSS', N'Seguridad Social (Contingencias Comunes)',
    N'Tesorería General de la Seguridad Social', N'SEGURIDAD_SOCIAL',
    N'BASE_COTIZACION', 4720.50, N'MENSUAL', 29.90, 6.35,
    0, N'MENSUAL', N'Último día hábil del mes siguiente',
    '2024-01-01', NULL, 1,
    N'Incluye contingencias comunes. Bases mínima y máxima actualizadas anualmente por RD.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- ES_IRPF: Retención IRPF
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'ES_IRPF')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'ES', N'ES_IRPF', N'Retención IRPF',
    N'Agencia Estatal de Administración Tributaria', N'IMPUESTO_RENTA',
    N'SALARIO_BRUTO', NULL, NULL, 0.00, 0.00,
    0, N'TRIMESTRAL', N'Modelo 111 — primeros 20 días del mes siguiente al trimestre',
    '2024-01-01', NULL, 1,
    N'Tasa variable según tablas IRPF y situación personal del trabajador. Se calcula individualmente.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- ---- COLOMBIA ----

-- CO_EPS: Salud
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'CO_EPS')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'CO', N'CO_EPS', N'Salud (EPS)',
    N'Entidad Promotora de Salud', N'SALUD',
    N'IBC', NULL, NULL, 8.50, 4.00,
    0, N'MENSUAL', N'Según último dígito NIT en calendario PILA',
    '2024-01-01', NULL, 1,
    N'Ingreso Base de Cotización (IBC). Total 12.5% del IBC.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- CO_AFP: Pensión
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'CO_AFP')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'CO', N'CO_AFP', N'Pensión (AFP)',
    N'Administradora de Fondos de Pensiones', N'PENSION',
    N'IBC', NULL, NULL, 12.00, 4.00,
    0, N'MENSUAL', N'Según último dígito NIT en calendario PILA',
    '2024-01-01', NULL, 1,
    N'Total 16% del IBC. Fondo de solidaridad pensional adicional para salarios >4 SMLMV.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- ---- MÉXICO ----

-- MX_IMSS: Seguro Social
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'MX_IMSS')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'MX', N'MX_IMSS', N'Seguro Social (IMSS)',
    N'Instituto Mexicano del Seguro Social', N'SEGURIDAD_SOCIAL',
    N'SBC', NULL, N'UMA', 0.00, 0.00,
    1, N'BIMESTRAL', N'Día 17 del mes siguiente al bimestre',
    '2024-01-01', NULL, 1,
    N'Tasas variables por ramo: Enfermedades y Maternidad, Invalidez y Vida, Retiro, Cesantía y Vejez, Riesgo de Trabajo (por prima de riesgo).',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- MX_INFONAVIT: Vivienda
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'MX_INFONAVIT')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'MX', N'MX_INFONAVIT', N'Vivienda (INFONAVIT)',
    N'Instituto del Fondo Nacional de la Vivienda para los Trabajadores', N'VIVIENDA',
    N'SBC', NULL, N'UMA', 5.00, 0.00,
    0, N'BIMESTRAL', N'Día 17 del mes siguiente al bimestre (junto con IMSS)',
    '2024-01-01', NULL, 1,
    N'5% patronal sobre Salario Base de Cotización. Se paga conjuntamente con cuotas IMSS vía SUA.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- ---- USA ----

-- US_FICA: Social Security + Medicare
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'US_FICA')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'US', N'US_FICA', N'FICA (Social Security + Medicare)',
    N'Internal Revenue Service (IRS)', N'SEGURIDAD_SOCIAL',
    N'GROSS_WAGES', 168600.00, N'ANUAL', 7.65, 7.65,
    0, N'QUINCENAL', N'Depositar según Schedule (semiweekly o monthly según monto)',
    '2024-01-01', NULL, 1,
    N'Social Security 6.20% + Medicare 1.45% = 7.65% cada parte. SS cap $168,600/año (2024). Medicare sin tope; 0.9% adicional empleado sobre $200K.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- US_FUTA: Federal Unemployment Tax
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE Code = N'US_FUTA')
INSERT INTO hr.LegalObligation (
    CountryCode, Code, Name, InstitutionName, ObligationType,
    CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
    RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
    EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
) VALUES (
    N'US', N'US_FUTA', N'FUTA (Federal Unemployment Tax)',
    N'Internal Revenue Service (IRS)', N'DESEMPLEO',
    N'GROSS_WAGES', 7000.00, N'ANUAL', 6.00, 0.00,
    0, N'TRIMESTRAL', N'Form 940 — último día del mes siguiente al trimestre',
    '2024-01-01', NULL, 1,
    N'6% sobre primeros $7,000 por empleado/año. Crédito hasta 5.4% si se paga SUTA estatal, tasa efectiva 0.6%.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

PRINT '   8 obligaciones legales multi-país insertadas (ES, CO, MX, US).';

-- ============================================================================
PRINT '=== SEED RRHH COMPLETO — Fin ===';
GO
