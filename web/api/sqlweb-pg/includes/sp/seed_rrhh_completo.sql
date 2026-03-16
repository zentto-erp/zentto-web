-- ============================================================================
-- SEED RRHH COMPLETO (PostgreSQL) — Datos realistas para Venezuela
-- Idempotente: usa IF NOT EXISTS en cada INSERT
-- Convertido desde SQL Server
-- Fecha: 2026-03-15
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== SEED RRHH COMPLETO — Inicio ===';

  -- ============================================================================
  -- 1. UTILIDADES 2025 (ProfitSharing + ProfitSharingLine)
  -- Empleado 1: Salario mensual 3500, diario = 116.6667
  -- Empleado 2: Salario mensual 2800, diario = 93.3333
  -- DaysWorked=365, DaysEntitled=30
  -- GrossAmount = DailySalary * DaysEntitled
  -- InceDeduction = GrossAmount * 0.005
  -- ============================================================================
  RAISE NOTICE '>> 1. Utilidades 2025';

  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharing" WHERE "CompanyId" = 1 AND "FiscalYear" = 2025) THEN
    INSERT INTO hr."ProfitSharing" (
      "ProfitSharingId", "CompanyId", "BranchId", "FiscalYear", "DaysGranted",
      "TotalCompanyProfits", "Status", "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      1, 1, 1, 2025, 30,
      500000.00, 'CALCULADA', 1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   ProfitSharing 2025 insertado.';
  END IF;

  -- Linea empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = 1 AND "EmployeeCode" = 'V-25678901') THEN
    INSERT INTO hr."ProfitSharingLine" (
      "LineId", "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
      "GrossAmount", "InceDeduction", "NetAmount", "IsPaid", "PaidAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      3500.00, 116.6667, 365, 30,
      3500.00, 17.50, 3482.50, false, NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
    RAISE NOTICE '   ProfitSharingLine empleado V-25678901 insertado.';
  END IF;

  -- Linea empleado V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = 1 AND "EmployeeCode" = 'V-18901234') THEN
    INSERT INTO hr."ProfitSharingLine" (
      "LineId", "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
      "GrossAmount", "InceDeduction", "NetAmount", "IsPaid", "PaidAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      2800.00, 93.3333, 365, 30,
      2800.00, 14.00, 2786.00, false, NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
    RAISE NOTICE '   ProfitSharingLine empleado V-18901234 insertado.';
  END IF;

  -- ============================================================================
  -- 2. FIDEICOMISO (SocialBenefitsTrust) — 4 trimestres 2025, ambos empleados
  -- Empleado 1: DailySalary=116.6667, 15 dias/trimestre, InterestRate=15.3%
  -- Empleado 2: DailySalary=93.3333, 15 dias/trimestre
  -- ============================================================================
  RAISE NOTICE '>> 2. Fideicomiso de Prestaciones Sociales 2025';

  -- Empleado V-25678901: Q1
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 1) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 1, 116.6667, 15, 0, 1750.00, 15.30, 0.00, 1750.00, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q2
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 2) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 2, 116.6667, 15, 0, 1750.00, 15.30, 66.94, 3566.94, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q3
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 3) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 3, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 3, 116.6667, 15, 0, 1750.00, 15.30, 136.44, 5453.38, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q4
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 4) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 4, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 4, 116.6667, 15, 0, 1750.00, 15.30, 208.59, 7411.97, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-18901234: Q1
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 5) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 5, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 1, 93.3333, 15, 0, 1400.00, 15.30, 0.00, 1400.00, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q2
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 6) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 6, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 2, 93.3333, 15, 0, 1400.00, 15.30, 53.55, 2853.55, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q3
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 7) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 7, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 3, 93.3333, 15, 0, 1400.00, 15.30, 109.15, 4362.70, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q4
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 8) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 8, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 4, 93.3333, 15, 0, 1400.00, 15.30, 166.87, 5929.57, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   8 registros de fideicomiso insertados.';

  -- ============================================================================
  -- 3. CAJA DE AHORRO (SavingsFund + SavingsFundTransaction + SavingsLoan)
  -- Empleado 1: 5% de 3500 = 175.00 por tipo por mes
  -- Empleado 2: 5% de 2800 = 140.00 por tipo por mes
  -- ============================================================================
  RAISE NOTICE '>> 3. Caja de Ahorro';

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 1) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 5.00, 5.00, '2025-01-15', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 2) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 5.00, 5.00, '2025-01-15', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 inscripciones de caja de ahorro insertadas.';

  -- Transacciones: 3 meses x 2 tipos x 2 empleados = 12 transacciones
  INSERT INTO hr."SavingsFundTransaction" (
    "TransactionId", "SavingsFundId", "TransactionDate", "TransactionType",
    "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
  ) OVERRIDING SYSTEM VALUE
  SELECT txn_id, fund_id, txn_date::date, txn_type, amount, balance, ref, NULL, notes, (NOW() AT TIME ZONE 'UTC')
  FROM (VALUES
    (1,  1, '2025-01-31', 'APORTE_EMPLEADO', 175.00, 175.00,  'NOM-2025-01', 'Aporte enero 2025'),
    (2,  1, '2025-01-31', 'APORTE_PATRONAL', 175.00, 350.00,  'NOM-2025-01', 'Aporte patronal enero 2025'),
    (3,  1, '2025-02-28', 'APORTE_EMPLEADO', 175.00, 525.00,  'NOM-2025-02', 'Aporte febrero 2025'),
    (4,  1, '2025-02-28', 'APORTE_PATRONAL', 175.00, 700.00,  'NOM-2025-02', 'Aporte patronal febrero 2025'),
    (5,  1, '2025-03-31', 'APORTE_EMPLEADO', 175.00, 875.00,  'NOM-2025-03', 'Aporte marzo 2025'),
    (6,  1, '2025-03-31', 'APORTE_PATRONAL', 175.00, 1050.00, 'NOM-2025-03', 'Aporte patronal marzo 2025'),
    (7,  2, '2025-01-31', 'APORTE_EMPLEADO', 140.00, 140.00,  'NOM-2025-01', 'Aporte enero 2025'),
    (8,  2, '2025-01-31', 'APORTE_PATRONAL', 140.00, 280.00,  'NOM-2025-01', 'Aporte patronal enero 2025'),
    (9,  2, '2025-02-28', 'APORTE_EMPLEADO', 140.00, 420.00,  'NOM-2025-02', 'Aporte febrero 2025'),
    (10, 2, '2025-02-28', 'APORTE_PATRONAL', 140.00, 560.00,  'NOM-2025-02', 'Aporte patronal febrero 2025'),
    (11, 2, '2025-03-31', 'APORTE_EMPLEADO', 140.00, 700.00,  'NOM-2025-03', 'Aporte marzo 2025'),
    (12, 2, '2025-03-31', 'APORTE_PATRONAL', 140.00, 840.00,  'NOM-2025-03', 'Aporte patronal marzo 2025')
  ) AS t(txn_id, fund_id, txn_date, txn_type, amount, balance, ref, notes)
  WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "TransactionId" = t.txn_id);

  RAISE NOTICE '   12 transacciones de caja de ahorro insertadas.';

  -- Prestamo para empleado 1
  IF NOT EXISTS (SELECT 1 FROM hr."SavingsLoan" WHERE "LoanId" = 1) THEN
    INSERT INTO hr."SavingsLoan" (
      "LoanId", "SavingsFundId", "EmployeeCode", "RequestDate", "ApprovedDate",
      "LoanAmount", "InterestRate", "TotalPayable", "MonthlyPayment",
      "InstallmentsTotal", "InstallmentsPaid", "OutstandingBalance",
      "Status", "ApprovedBy", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      1, 1, 'V-25678901', '2025-04-01', '2025-04-05',
      5000.00, 6.00, 5300.00, 441.67,
      12, 3, 3975.01,
      'APROBADO', 1, 'Prestamo ordinario caja de ahorro', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  RAISE NOTICE '   1 prestamo de caja de ahorro insertado.';

  -- ============================================================================
  -- 4. OBLIGACIONES LEGALES — Inscripcion empleados 1 y 2 + Filing SSO enero 2026
  -- ============================================================================
  RAISE NOTICE '>> 4. Obligaciones Legales';

  -- Inscribir empleado 1 en SSO
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'SSO-0125678901', 'IVSS',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_SSO'
  );

  -- Inscribir empleado 1 en FAOV
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'FAOV-0125678901', 'BANAVIH',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_FAOV'
  );

  -- Inscribir empleado 1 en INCE
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'INCE-0125678901', 'INCE',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_INCE'
  );

  -- Inscribir empleado 2 en SSO
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'SSO-0218901234', 'IVSS',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_SSO'
  );

  -- Inscribir empleado 2 en FAOV
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'FAOV-0218901234', 'BANAVIH',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_FAOV'
  );

  -- Inscribir empleado 2 en INCE
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'INCE-0218901234', 'INCE',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_INCE'
  );

  -- Filing SSO enero 2026 (FilingId 1)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 1) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-15', '2026-02-10',
      'IVSS-2026-01-00458', 693.00, 252.00, 945.00,
      2, 'FILED', 1, NULL, 'Declaracion SSO enero 2026',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- Filing Detail: empleado V-25678901
  INSERT INTO hr."ObligationFilingDetail" ("ObligationFilingId", "EmployeeId", "BaseSalary", "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType")
  SELECT 1, e."EmployeeId", 3500.00, 385.00, 140.00, 31, 'NONE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."ObligationFilingDetail" WHERE "ObligationFilingId" = 1 AND "EmployeeId" = e."EmployeeId");

  -- Filing Detail: empleado V-18901234
  INSERT INTO hr."ObligationFilingDetail" ("ObligationFilingId", "EmployeeId", "BaseSalary", "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType")
  SELECT 1, e."EmployeeId", 2800.00, 308.00, 112.00, 31, 'NONE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."ObligationFilingDetail" WHERE "ObligationFilingId" = 1 AND "EmployeeId" = e."EmployeeId");

  RAISE NOTICE '   Filing SSO enero 2026 + 2 detalles insertados.';

  -- ============================================================================
  -- 5. SALUD OCUPACIONAL (OccupationalHealth)
  -- ============================================================================
  RAISE NOTICE '>> 5. Salud Ocupacional';

  -- Accidente leve emp V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "OccupationalHealthId" = 1) THEN
    INSERT INTO hr."OccupationalHealth" (
      "OccupationalHealthId", "CompanyId", "CountryCode", "RecordType",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "OccurrenceDate", "ReportDeadline", "ReportedDate",
      "Severity", "BodyPartAffected", "DaysLost", "Location",
      "Description", "RootCause", "CorrectiveAction",
      "InvestigationDueDate", "InvestigationCompletedDate",
      "InstitutionReference", "Status", "DocumentUrl", "Notes",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT
      1, 1, 'VE', 'ACCIDENTE',
      e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      '2025-09-15', '2025-09-19', '2025-09-16',
      'LEVE', 'Mano derecha', 2, 'Almacen principal',
      'Corte superficial en mano derecha al manipular cajas de inventario.',
      'Ausencia de guantes de proteccion durante manipulacion de cajas.',
      'Dotacion inmediata de guantes de seguridad. Charla de refuerzo sobre EPP.',
      '2025-09-22', '2025-09-20',
      'INPSASEL-2025-09-004571', 'CLOSED', NULL,
      'Caso cerrado. Empleado reincorporado el 2025-09-17.',
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Incidente sin dias perdidos emp V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "OccupationalHealthId" = 2) THEN
    INSERT INTO hr."OccupationalHealth" (
      "OccupationalHealthId", "CompanyId", "CountryCode", "RecordType",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "OccurrenceDate", "ReportDeadline", "ReportedDate",
      "Severity", "BodyPartAffected", "DaysLost", "Location",
      "Description", "RootCause", "CorrectiveAction",
      "InvestigationDueDate", "InvestigationCompletedDate",
      "InstitutionReference", "Status", "DocumentUrl", "Notes",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT
      2, 1, 'VE', 'INCIDENTE',
      e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      '2025-11-03', '2025-11-07', '2025-11-04',
      'LEVE', NULL, 0, 'Oficina administrativa',
      'Derrame de liquido en pasillo causo resbalo sin caida ni lesion.',
      'Falta de senalizacion de piso mojado.',
      'Instalacion de porta avisos de piso humedo en cada area. Protocolo de limpieza actualizado.',
      '2025-11-10', NULL,
      NULL, 'REPORTED', NULL,
      'Incidente reportado. Sin lesion. Pendiente cierre de investigacion.',
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 registros de salud ocupacional insertados.';

  -- ============================================================================
  -- 6. EXAMENES MEDICOS (MedicalExam)
  -- ============================================================================
  RAISE NOTICE '>> 6. Examenes Medicos';

  -- Preempleo empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 1) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'PREEMPLEO', '2024-02-20', NULL, 'APTO', NULL,
      'Dra. Maria Gonzalez', 'Centro Medico La Trinidad',
      NULL, 'Examen preempleo sin observaciones.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Preempleo empleado V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 2) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'PREEMPLEO', '2024-05-10', NULL, 'APTO', NULL,
      'Dr. Carlos Ramirez', 'Clinica Santa Sofia',
      NULL, 'Examen preempleo sin restricciones.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Periodico empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 3) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 3, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'PERIODICO', '2025-02-18', '2026-02-18', 'APTO', NULL,
      'Dra. Maria Gonzalez', 'Centro Medico La Trinidad',
      NULL, 'Control anual. Sin hallazgos relevantes.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Periodico empleado V-18901234 — NextDueDate VENCIDA para generar alerta
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 4) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 4, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'PERIODICO', '2025-01-10', '2026-01-10', 'APTO',
      'Uso de lentes correctivos obligatorio',
      'Dr. Carlos Ramirez', 'Clinica Santa Sofia',
      NULL, 'Control anual. Requiere lentes correctivos. VENCIDO — proximo examen pendiente.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   4 examenes medicos insertados.';

  -- ============================================================================
  -- 7. ORDENES MEDICAS (MedicalOrder)
  -- ============================================================================
  RAISE NOTICE '>> 7. Ordenes Medicas';

  -- Consulta aprobada emp V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "MedicalOrderId" = 1) THEN
    INSERT INTO hr."MedicalOrder" (
      "MedicalOrderId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions",
      "EstimatedCost", "ApprovedAmount", "Status", "ApprovedBy", "ApprovedAt",
      "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'CONSULTA', '2025-10-05', 'Lumbalgia mecanica',
      'Dr. Pedro Martinez', 'Ibuprofeno 400mg c/8h x 5 dias. Reposo relativo.',
      150.00, 150.00, 'APROBADA', 1, '2025-10-06',
      NULL, 'Consulta traumatologia por dolor lumbar.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Farmacia pendiente emp V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "MedicalOrderId" = 2) THEN
    INSERT INTO hr."MedicalOrder" (
      "MedicalOrderId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions",
      "EstimatedCost", "ApprovedAmount", "Status", "ApprovedBy", "ApprovedAt",
      "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'FARMACIA', '2026-01-15', 'Infeccion respiratoria aguda',
      'Dra. Ana Suarez', 'Amoxicilina 500mg c/8h x 7 dias. Reposo 2 dias.',
      80.00, 80.00, 'PENDIENTE', NULL, NULL,
      NULL, 'Pendiente aprobacion farmacia.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 ordenes medicas insertadas.';
  RAISE NOTICE '=== SEED RRHH COMPLETO — Completado ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_rrhh_completo.sql: %', SQLERRM;
END $$;
