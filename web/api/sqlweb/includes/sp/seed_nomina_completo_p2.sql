USE DatqBoxWeb;
GO
SET NOCOUNT ON;
GO

-- ============================================================================
-- SEED NÓMINA COMPLETO — PARTE 2
-- Continúa seed_rrhh_completo.sql (Part 1)
-- Empleados Id 1-10 ya existen en master.Employee
-- Idempotente: usa IF NOT EXISTS en cada INSERT
-- SQL Server 2012: NO CREATE OR ALTER, NO OPENJSON, NO DECLARE=value inline
-- Fecha: 2026-03-16
-- ============================================================================

PRINT '=== SEED NÓMINA COMPLETO P2 — Inicio ===';

-- ============================================================================
-- 1. TRAINING RECORDS (8 registros)
-- ============================================================================
PRINT '>> 1. Capacitación (8 registros nuevos)';

-- IDs 5-12 (1-4 ya existen en Part 1)
SET IDENTITY_INSERT hr.TrainingRecord ON;

-- 5: SEGURIDAD — Prevención de Riesgos LOPCYMAT, 3 asistentes (emp 3,4,5)
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 5)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    5, 1, N'VE', N'SEGURIDAD', N'Prevención de Riesgos Laborales LOPCYMAT', N'Instituto Seguridad Laboral',
    '2025-06-09', '2025-06-10', 16,
    3, N'V-12345678', N'Carlos Mendoza',
    N'ISL-PRL-2025-0103', NULL, N'APROBADO', 1,
    N'Capacitación obligatoria LOPCYMAT. Identificación de riesgos, uso de EPP, notificación de riesgos.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 6)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    6, 1, N'VE', N'SEGURIDAD', N'Prevención de Riesgos Laborales LOPCYMAT', N'Instituto Seguridad Laboral',
    '2025-06-09', '2025-06-10', 16,
    4, N'V-14567890', N'Ana Rodríguez',
    N'ISL-PRL-2025-0104', NULL, N'APROBADO', 1,
    N'Capacitación obligatoria LOPCYMAT. Identificación de riesgos, uso de EPP, notificación de riesgos.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 7)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    7, 1, N'VE', N'SEGURIDAD', N'Prevención de Riesgos Laborales LOPCYMAT', N'Instituto Seguridad Laboral',
    '2025-06-09', '2025-06-10', 16,
    5, N'V-16789012', N'María López',
    N'ISL-PRL-2025-0105', NULL, N'APROBADO', 1,
    N'Capacitación obligatoria LOPCYMAT. Identificación de riesgos, uso de EPP, notificación de riesgos.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- 8-9: REGULATORIO — Manejo Sustancias Peligrosas, 2 asistentes (emp 3,6)
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 8)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    8, 1, N'VE', N'SEGURIDAD', N'Manejo de Sustancias Peligrosas', N'Instituto Seguridad Laboral',
    '2025-09-22', '2025-09-23', 16,
    3, N'V-12345678', N'Carlos Mendoza',
    N'ISL-MSP-2025-0088', NULL, N'APROBADO', 1,
    N'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias químicas.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 9)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    9, 1, N'VE', N'SEGURIDAD', N'Manejo de Sustancias Peligrosas', N'Instituto Seguridad Laboral',
    '2025-09-22', '2025-09-23', 16,
    6, N'V-18234567', N'Pedro García',
    N'ISL-MSP-2025-0089', NULL, N'APROBADO', 1,
    N'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias químicas.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- 10-11: TÉCNICO — Excel Avanzado, 2 asistentes (emp 5,7)
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 10)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    10, 1, N'VE', N'DESARROLLO', N'Excel Avanzado', N'AcademiaVE',
    '2026-01-13', '2026-01-31', 24,
    5, N'V-16789012', N'María López',
    N'AVE-EXC-2026-0045', NULL, N'APROBADO', 0,
    N'Tablas dinámicas, Power Query, macros VBA, dashboards. Formación de desarrollo profesional.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 11)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    11, 1, N'VE', N'DESARROLLO', N'Excel Avanzado', N'AcademiaVE',
    '2026-01-13', '2026-01-31', 24,
    7, N'V-20456789', N'Luisa Martínez',
    N'AVE-EXC-2026-0046', NULL, N'APROBADO', 0,
    N'Tablas dinámicas, Power Query, macros VBA, dashboards. Formación de desarrollo profesional.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- 12: INDUCCIÓN — Inducción DatqBox, empleado nuevo V-24890123, 40 hrs
IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord WHERE TrainingRecordId = 12)
INSERT INTO hr.TrainingRecord (
    TrainingRecordId, CompanyId, CountryCode, TrainingType, Title, Provider,
    StartDate, EndDate, DurationHours,
    EmployeeId, EmployeeCode, EmployeeName,
    CertificateNumber, CertificateUrl, Result, IsRegulatory,
    Notes, CreatedAt, UpdatedAt
) VALUES (
    12, 1, N'VE', N'INDUCCION', N'Inducción DatqBox', N'INCES',
    '2025-11-03', '2025-11-07', 40,
    9, N'V-24890123', N'Roberto Hernández',
    N'INCES-IND-2025-1201', NULL, N'APROBADO', 1,
    N'Inducción integral: cultura organizacional, procesos, LOPCYMAT, seguridad informática, herramientas internas.',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.TrainingRecord OFF;
PRINT '   8 registros de capacitación insertados (IDs 5-12).';

-- ============================================================================
-- 2. COMITÉS DE SEGURIDAD (2) + Miembros + Reuniones
-- ============================================================================
PRINT '>> 2. Comités de Seguridad';

SET IDENTITY_INSERT hr.SafetyCommittee ON;

-- Comité 100: Comité de Seguridad y Salud Laboral
IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee WHERE SafetyCommitteeId = 100)
INSERT INTO hr.SafetyCommittee (
    SafetyCommitteeId, CompanyId, CountryCode, CommitteeName,
    FormationDate, MeetingFrequency, IsActive, CreatedAt
) VALUES (
    100, 1, N'VE', N'Comité de Seguridad y Salud Laboral',
    '2024-01-15', N'MENSUAL', 1, SYSUTCDATETIME()
);

-- Comité 101: Comité de Bienestar Social
IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee WHERE SafetyCommitteeId = 101)
INSERT INTO hr.SafetyCommittee (
    SafetyCommitteeId, CompanyId, CountryCode, CommitteeName,
    FormationDate, MeetingFrequency, IsActive, CreatedAt
) VALUES (
    101, 1, N'VE', N'Comité de Bienestar Social',
    '2024-06-01', N'TRIMESTRAL', 1, SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SafetyCommittee OFF;

-- Miembros Comité 100
SET IDENTITY_INSERT hr.SafetyCommitteeMember ON;

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 100)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    100, 100, 8, N'V-22678901', N'Fernando Díaz',
    N'PRESIDENTE', '2024-01-15', NULL
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 101)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    101, 100, 3, N'V-12345678', N'Carlos Mendoza',
    N'SECRETARIO', '2024-01-15', NULL
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 102)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    102, 100, 4, N'V-14567890', N'Ana Rodríguez',
    N'VOCAL', '2024-01-15', NULL
);

-- Miembros Comité 101
IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 103)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    103, 101, 5, N'V-16789012', N'María López',
    N'PRESIDENTA', '2024-06-01', NULL
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember WHERE MemberId = 104)
INSERT INTO hr.SafetyCommitteeMember (
    MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
    Role, StartDate, EndDate
) VALUES (
    104, 101, 7, N'V-20456789', N'Luisa Martínez',
    N'SECRETARIA', '2024-06-01', NULL
);

SET IDENTITY_INSERT hr.SafetyCommitteeMember OFF;

-- Reuniones Comité 100: Ene/Feb/Mar 2026
SET IDENTITY_INSERT hr.SafetyCommitteeMeeting ON;

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 100)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    100, 100, '2026-01-20', NULL,
    N'1. Revisión accidentes Q4 2025. 2. Plan de capacitación SST 2026. 3. Auditoría de extintores y señalización.',
    N'- Programar inspección de extintores antes del 31/01. - Actualizar mapa de riesgos del almacén. - Coordinar charla de primeros auxilios con Cruz Roja.',
    SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 101)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    101, 100, '2026-02-17', NULL,
    N'1. Resultado inspección extintores. 2. Estadísticas accidentalidad enero. 3. Dotación EPP primer trimestre.',
    N'- Reemplazar 3 extintores vencidos en planta baja. - Solicitar cotización EPP nuevos ingresos. - Fijar fecha simulacro evacuación marzo.',
    SYSUTCDATETIME()
);

IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 102)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    102, 100, '2026-03-16', NULL,
    N'1. Simulacro de evacuación realizado (3 min 20 seg). 2. Revisión plan de emergencia. 3. Informe trimestral INPSASEL.',
    N'- Documentar resultados simulacro para informe INPSASEL. - Corregir ruta evacuación piso 2. - Entregar informe trimestral antes del 10/04.',
    SYSUTCDATETIME()
);

-- Reunión Comité 101: Ene 2026
IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMeeting WHERE MeetingId = 103)
INSERT INTO hr.SafetyCommitteeMeeting (
    MeetingId, SafetyCommitteeId, MeetingDate, MinutesUrl, TopicsSummary,
    ActionItems, CreatedAt
) VALUES (
    103, 101, '2026-01-28', NULL,
    N'1. Planificación actividades recreativas Q1 2026. 2. Fondo de ayuda social: balance y solicitudes pendientes. 3. Convenio farmacia.',
    N'- Organizar jornada deportiva para febrero. - Evaluar 2 solicitudes de ayuda económica. - Renovar convenio farmacia antes del 15/02.',
    SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SafetyCommitteeMeeting OFF;
PRINT '   2 comités, 5 miembros, 4 reuniones insertados.';

-- ============================================================================
-- 3. OBLIGACIONES LEGALES (4 para VE) — Verificar que existan
-- ============================================================================
PRINT '>> 3. Obligaciones Legales VE (verificar/crear 4)';

-- VE_SSO ya existe en sp_rrhh_obligaciones_legales.sql seed.
-- VE_FAOV ya existe.
-- VE_LRPE ya existe.
-- VE_INCE ya existe.
-- Solo verificamos que existan; si por algún motivo no, los creamos.

IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_SSO')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    ) VALUES (
        'VE', 'VE_SSO', N'Seguro Social Obligatorio', N'IVSS', 'CONTRIBUTION',
        'GROSS_PAYROLL', 10.00000, 4.00000,
        1, 'MONTHLY', N'Primeros 5 días hábiles del mes siguiente',
        '2012-01-01', 1, N'SSO clase I. Tasa variable según nivel de riesgo.'
    );
END

IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_FAOV')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    ) VALUES (
        'VE', 'VE_FAOV', N'Ley de Vivienda y Hábitat', N'BANAVIH', 'CONTRIBUTION',
        'GROSS_PAYROLL', 2.00000, 1.00000,
        0, 'MONTHLY', N'Primeros 5 días hábiles del mes siguiente',
        '2012-01-01', 1, N'Fondo de Ahorro Obligatorio para la Vivienda.'
    );
END

IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_LRPE')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    ) VALUES (
        'VE', 'VE_LRPE', N'Régimen Prestacional de Empleo', N'INPSASEL', 'CONTRIBUTION',
        'GROSS_PAYROLL', 2.00000, 0.50000,
        0, 'MONTHLY', N'Primeros 5 días hábiles del mes siguiente',
        '2012-01-01', 1, N'Paro forzoso - Ley del Régimen Prestacional de Empleo.'
    );
END

IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_INCE')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    ) VALUES (
        'VE', 'VE_INCE', N'Capacitación y Educación', N'INCES', 'CONTRIBUTION',
        'GROSS_PAYROLL', 2.00000, 0.00000,
        0, 'QUARTERLY', N'Dentro de los 5 días hábiles después del cierre del trimestre',
        '2012-01-01', 1, N'INCES: 2% patronal sobre nómina. Empleado 0.5% sobre utilidades (separado).'
    );
END

PRINT '   4 obligaciones legales VE verificadas.';
GO

-- ============================================================================
-- 4. EMPLOYEE OBLIGATIONS — Inscribir 9 empleados activos en 4 obligaciones
-- ============================================================================
PRINT '>> 4. Inscripción de empleados en obligaciones legales';

-- Empleados 1 y 2 ya inscritos en SSO, FAOV, INCE por Part 1.
-- Aquí inscribimos empleados 1-9 en las 4 obligaciones (VE_SSO, VE_FAOV, VE_LRPE, VE_INCE).
-- Empleado 10 (retirado) se excluye.
-- Usamos IF NOT EXISTS para idempotencia.

-- === VE_SSO ===
-- Emp 3
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 3 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 3, lo.LegalObligationId, N'SSO-012345', N'IVSS',
        NULL, '2019-03-15', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 4 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 4, lo.LegalObligationId, N'SSO-014567', N'IVSS',
        NULL, '2018-07-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 5 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 5, lo.LegalObligationId, N'SSO-016789', N'IVSS',
        NULL, '2020-01-10', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 6 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 6, lo.LegalObligationId, N'SSO-018234', N'IVSS',
        NULL, '2017-04-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 7 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 7, lo.LegalObligationId, N'SSO-020456', N'IVSS',
        NULL, '2022-06-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 8 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 8, lo.LegalObligationId, N'SSO-022678', N'IVSS',
        NULL, '2016-02-15', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 9 AND lo.Code = N'VE_SSO'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 9, lo.LegalObligationId, N'SSO-024890', N'IVSS',
        NULL, '2023-03-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';
END

PRINT '   Empleados 3-9 inscritos en VE_SSO.';

-- === VE_FAOV ===
IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 3 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 3, lo.LegalObligationId, N'FAOV-012345', N'BANAVIH',
        NULL, '2019-03-15', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 4 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 4, lo.LegalObligationId, N'FAOV-014567', N'BANAVIH',
        NULL, '2018-07-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 5 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 5, lo.LegalObligationId, N'FAOV-016789', N'BANAVIH',
        NULL, '2020-01-10', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 6 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 6, lo.LegalObligationId, N'FAOV-018234', N'BANAVIH',
        NULL, '2017-04-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 7 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 7, lo.LegalObligationId, N'FAOV-020456', N'BANAVIH',
        NULL, '2022-06-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 8 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 8, lo.LegalObligationId, N'FAOV-022678', N'BANAVIH',
        NULL, '2016-02-15', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

IF NOT EXISTS (
    SELECT 1 FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
    WHERE eo.EmployeeId = 9 AND lo.Code = N'VE_FAOV'
)
BEGIN
    INSERT INTO hr.EmployeeObligation (
        EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
        RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
        CreatedAt, UpdatedAt
    )
    SELECT 9, lo.LegalObligationId, N'FAOV-024890', N'BANAVIH',
        NULL, '2023-03-01', NULL, N'ACTIVO', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';
END

PRINT '   Empleados 3-9 inscritos en VE_FAOV.';

-- === VE_LRPE (empleados 1-9, todos nuevos para LRPE) ===
DECLARE @iLRPE INT;
SET @iLRPE = 1;
WHILE @iLRPE <= 9
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr.EmployeeObligation eo
        INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
        WHERE eo.EmployeeId = @iLRPE AND lo.Code = N'VE_LRPE'
    )
    BEGIN
        INSERT INTO hr.EmployeeObligation (
            EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
            RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
            CreatedAt, UpdatedAt
        )
        SELECT @iLRPE, lo.LegalObligationId,
            N'LRPE-0' + CAST(@iLRPE AS NVARCHAR(2)) + RIGHT('00000' + CAST(@iLRPE * 11111 AS NVARCHAR(6)), 5),
            N'INPSASEL',
            NULL,
            CASE @iLRPE
                WHEN 1 THEN '2024-03-01'
                WHEN 2 THEN '2024-06-01'
                WHEN 3 THEN '2019-03-15'
                WHEN 4 THEN '2018-07-01'
                WHEN 5 THEN '2020-01-10'
                WHEN 6 THEN '2017-04-01'
                WHEN 7 THEN '2022-06-01'
                WHEN 8 THEN '2016-02-15'
                WHEN 9 THEN '2023-03-01'
            END,
            NULL, N'ACTIVO', NULL,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM hr.LegalObligation lo WHERE lo.Code = N'VE_LRPE';
    END
    SET @iLRPE = @iLRPE + 1;
END

PRINT '   Empleados 1-9 inscritos en VE_LRPE.';

-- === VE_INCE (empleados 1-9, emp 1-2 ya inscritos por P1 en VE_INCE, rest new) ===
DECLARE @iINCE INT;
SET @iINCE = 3;
WHILE @iINCE <= 9
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr.EmployeeObligation eo
        INNER JOIN hr.LegalObligation lo ON eo.LegalObligationId = lo.LegalObligationId
        WHERE eo.EmployeeId = @iINCE AND lo.Code = N'VE_INCE'
    )
    BEGIN
        INSERT INTO hr.EmployeeObligation (
            EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
            RiskLevelId, EnrollmentDate, DisenrollmentDate, Status, CustomRate,
            CreatedAt, UpdatedAt
        )
        SELECT @iINCE, lo.LegalObligationId,
            N'INCE-0' + CAST(@iINCE AS NVARCHAR(2)) + RIGHT('00000' + CAST(@iINCE * 22222 AS NVARCHAR(6)), 5),
            N'INCE',
            NULL,
            CASE @iINCE
                WHEN 3 THEN '2019-03-15'
                WHEN 4 THEN '2018-07-01'
                WHEN 5 THEN '2020-01-10'
                WHEN 6 THEN '2017-04-01'
                WHEN 7 THEN '2022-06-01'
                WHEN 8 THEN '2016-02-15'
                WHEN 9 THEN '2023-03-01'
            END,
            NULL, N'ACTIVO', NULL,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM hr.LegalObligation lo WHERE lo.Code = N'VE_INCE';
    END
    SET @iINCE = @iINCE + 1;
END

PRINT '   Empleados 3-9 inscritos en VE_INCE.';
GO

-- ============================================================================
-- 5. OBLIGATION FILINGS — Ene/Feb/Mar 2026 para SSO y FAOV
-- ============================================================================
PRINT '>> 5. Declaraciones SSO y FAOV (Ene-Mar 2026)';

-- Salarios mensuales (para cálculos):
-- Emp1=3500, Emp2=2800, Emp3=3500, Emp4=4200, Emp5=3200,
-- Emp6=3800, Emp7=2800, Emp8=4500, Emp9=2500
-- Total nómina 9 emp = 30800

-- SSO: Patronal ~10%, Empleado ~4%
-- Total patronal SSO = 30800 * 0.10 = 3080.00
-- Total empleado SSO = 30800 * 0.04 = 1232.00
-- Total SSO = 4312.00

-- FAOV: Patronal ~2%, Empleado ~1%
-- Total patronal FAOV = 30800 * 0.02 = 616.00
-- Total empleado FAOV = 30800 * 0.01 = 308.00
-- Total FAOV = 924.00

SET IDENTITY_INSERT hr.ObligationFiling ON;

-- ---- SSO Enero 2026 (FilingId 10) ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 10)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    10, 1, lo.LegalObligationId,
    '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-10',
    N'SSO-2026-01-0001', 3080.00, 1232.00, 4312.00,
    9, N'PAGADA', 1, NULL, N'Declaración SSO enero 2026 — 9 empleados activos',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';

-- ---- SSO Febrero 2026 (FilingId 11) ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 11)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    11, 1, lo.LegalObligationId,
    '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-08',
    N'SSO-2026-02-0001', 3080.00, 1232.00, 4312.00,
    9, N'PAGADA', 1, NULL, N'Declaración SSO febrero 2026 — 9 empleados activos',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';

-- ---- SSO Marzo 2026 (FilingId 12) — PENDIENTE ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 12)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    12, 1, lo.LegalObligationId,
    '2026-03-01', '2026-03-31', '2026-04-10', NULL,
    NULL, 3080.00, 1232.00, 4312.00,
    9, N'PENDIENTE', NULL, NULL, N'Declaración SSO marzo 2026 — pendiente de pago',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_SSO';

-- ---- FAOV Enero 2026 (FilingId 13) ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 13)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    13, 1, lo.LegalObligationId,
    '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-09',
    N'FAOV-2026-01-0001', 616.00, 308.00, 924.00,
    9, N'PAGADA', 1, NULL, N'Declaración FAOV enero 2026 — 9 empleados activos',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';

-- ---- FAOV Febrero 2026 (FilingId 14) ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 14)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    14, 1, lo.LegalObligationId,
    '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-07',
    N'FAOV-2026-02-0001', 616.00, 308.00, 924.00,
    9, N'PAGADA', 1, NULL, N'Declaración FAOV febrero 2026 — 9 empleados activos',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';

-- ---- FAOV Marzo 2026 (FilingId 15) — PENDIENTE ----
IF NOT EXISTS (SELECT 1 FROM hr.ObligationFiling WHERE ObligationFilingId = 15)
INSERT INTO hr.ObligationFiling (
    ObligationFilingId, CompanyId, LegalObligationId,
    FilingPeriodStart, FilingPeriodEnd, DueDate, FiledDate,
    ConfirmationNumber, TotalEmployerAmount, TotalEmployeeAmount, TotalAmount,
    EmployeeCount, Status, FiledByUserId, DocumentUrl, Notes,
    CreatedAt, UpdatedAt
)
SELECT
    15, 1, lo.LegalObligationId,
    '2026-03-01', '2026-03-31', '2026-04-10', NULL,
    NULL, 616.00, 308.00, 924.00,
    9, N'PENDIENTE', NULL, NULL, N'Declaración FAOV marzo 2026 — pendiente de pago',
    SYSUTCDATETIME(), SYSUTCDATETIME()
FROM hr.LegalObligation lo WHERE lo.Code = N'VE_FAOV';

SET IDENTITY_INSERT hr.ObligationFiling OFF;
PRINT '   6 filings (SSO+FAOV x 3 meses) insertados.';

-- ---- FILING DETAIL por empleado ----
-- SSO: Patronal=Salary*0.10, Empleado=Salary*0.04
-- FAOV: Patronal=Salary*0.02, Empleado=Salary*0.01
-- DaysWorked=30

-- Tabla temporal con salarios
DECLARE @EmpSalaries TABLE (EmpId INT, Salary DECIMAL(18,2));
INSERT INTO @EmpSalaries VALUES
    (1, 3500.00), (2, 2800.00), (3, 3500.00), (4, 4200.00), (5, 3200.00),
    (6, 3800.00), (7, 2800.00), (8, 4500.00), (9, 2500.00);

-- SSO Detalle: Filings 10, 11, 12
DECLARE @fSSO INT;
SET @fSSO = 10;
WHILE @fSSO <= 12
BEGIN
    INSERT INTO hr.ObligationFilingDetail (
        ObligationFilingId, EmployeeId, BaseSalary,
        EmployerAmount, EmployeeAmount, DaysWorked, NoveltyType
    )
    SELECT @fSSO, es.EmpId, es.Salary,
        CAST(es.Salary * 0.10 AS DECIMAL(18,2)),
        CAST(es.Salary * 0.04 AS DECIMAL(18,2)),
        30, NULL
    FROM @EmpSalaries es
    WHERE NOT EXISTS (
        SELECT 1 FROM hr.ObligationFilingDetail
        WHERE ObligationFilingId = @fSSO AND EmployeeId = es.EmpId
    );
    SET @fSSO = @fSSO + 1;
END

-- FAOV Detalle: Filings 13, 14, 15
DECLARE @fFAOV INT;
SET @fFAOV = 13;
WHILE @fFAOV <= 15
BEGIN
    INSERT INTO hr.ObligationFilingDetail (
        ObligationFilingId, EmployeeId, BaseSalary,
        EmployerAmount, EmployeeAmount, DaysWorked, NoveltyType
    )
    SELECT @fFAOV, es.EmpId, es.Salary,
        CAST(es.Salary * 0.02 AS DECIMAL(18,2)),
        CAST(es.Salary * 0.01 AS DECIMAL(18,2)),
        30, NULL
    FROM @EmpSalaries es
    WHERE NOT EXISTS (
        SELECT 1 FROM hr.ObligationFilingDetail
        WHERE ObligationFilingId = @fFAOV AND EmployeeId = es.EmpId
    );
    SET @fFAOV = @fFAOV + 1;
END

PRINT '   54 registros de detalle de filing insertados (9 emp x 6 filings).';
GO

-- ============================================================================
-- 6. CAJA DE AHORRO — Inscribir 6 empleados
-- ============================================================================
PRINT '>> 6. Caja de Ahorro (6 inscripciones)';

-- SavingsFundId 1-2 ya existen en Part 1. Usamos 3-8.
SET IDENTITY_INSERT hr.SavingsFund ON;

-- V-12345678 (Emp3): 10% empleado, 5% patronal, desde 2021-01-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 3)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    3, 1, 3, N'V-12345678', N'Carlos Mendoza',
    10.00, 5.00, '2021-01-01', N'ACTIVO', SYSUTCDATETIME()
);

-- V-14567890 (Emp4): 8% empleado, 5% patronal, desde 2020-01-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 4)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    4, 1, 4, N'V-14567890', N'Ana Rodríguez',
    8.00, 5.00, '2020-01-01', N'ACTIVO', SYSUTCDATETIME()
);

-- V-18234567 (Emp6): 5% empleado, 5% patronal, desde 2019-01-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 5)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    5, 1, 6, N'V-18234567', N'Pedro García',
    5.00, 5.00, '2019-01-01', N'ACTIVO', SYSUTCDATETIME()
);

-- V-22678901 (Emp8): 10% empleado, 5% patronal, desde 2018-01-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 6)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    6, 1, 8, N'V-22678901', N'Fernando Díaz',
    10.00, 5.00, '2018-01-01', N'ACTIVO', SYSUTCDATETIME()
);

-- V-20456789 (Emp7): 7% empleado, 5% patronal, desde 2022-06-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 7)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    7, 1, 7, N'V-20456789', N'Luisa Martínez',
    7.00, 5.00, '2022-06-01', N'ACTIVO', SYSUTCDATETIME()
);

-- V-24890123 (Emp9): 5% empleado, 5% patronal, desde 2023-03-01
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFund WHERE SavingsFundId = 8)
INSERT INTO hr.SavingsFund (
    SavingsFundId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    EmployeeContribution, EmployerMatch, EnrollmentDate, Status, CreatedAt
) VALUES (
    8, 1, 9, N'V-24890123', N'Roberto Hernández',
    5.00, 5.00, '2023-03-01', N'ACTIVO', SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsFund OFF;
PRINT '   6 inscripciones de caja de ahorro insertadas (IDs 3-8).';
GO

-- ============================================================================
-- 7. SAVINGS FUND TRANSACTIONS — 3 meses x 6 empleados x 2 tipos = 36 txns
-- ============================================================================
PRINT '>> 7. Transacciones Caja de Ahorro (Ene-Mar 2026)';

-- SavingsFundId | EmpCode      | Salary | Emp%  | EmpAmt | PatAmt(5%)
-- 3             | V-12345678   | 3500   | 10%   | 350    | 175
-- 4             | V-14567890   | 4200   | 8%    | 336    | 210
-- 5             | V-18234567   | 3800   | 5%    | 190    | 190
-- 6             | V-22678901   | 4500   | 10%   | 450    | 225
-- 7             | V-20456789   | 2800   | 7%    | 196    | 140
-- 8             | V-24890123   | 2500   | 5%    | 125    | 125

-- Part 1 usó TransactionIds 1-12. Continuamos desde 13.
SET IDENTITY_INSERT hr.SavingsFundTransaction ON;

-- ---- SavingsFundId=3 (V-12345678, Emp=350, Pat=175) ----
-- Enero Empleado
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 13)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    13, 3, '2026-01-31', N'APORTE_EMPLEADO',
    350.00, 350.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
-- Enero Patronal
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 14)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    14, 3, '2026-01-31', N'APORTE_PATRONAL',
    175.00, 525.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
-- Febrero Empleado
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 15)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    15, 3, '2026-02-28', N'APORTE_EMPLEADO',
    350.00, 875.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
-- Febrero Patronal
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 16)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    16, 3, '2026-02-28', N'APORTE_PATRONAL',
    175.00, 1050.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
-- Marzo Empleado
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 17)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    17, 3, '2026-03-31', N'APORTE_EMPLEADO',
    350.00, 1400.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
-- Marzo Patronal
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 18)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    18, 3, '2026-03-31', N'APORTE_PATRONAL',
    175.00, 1575.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

-- ---- SavingsFundId=4 (V-14567890, Emp=336, Pat=210) ----
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 19)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    19, 4, '2026-01-31', N'APORTE_EMPLEADO',
    336.00, 336.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 20)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    20, 4, '2026-01-31', N'APORTE_PATRONAL',
    210.00, 546.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 21)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    21, 4, '2026-02-28', N'APORTE_EMPLEADO',
    336.00, 882.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 22)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    22, 4, '2026-02-28', N'APORTE_PATRONAL',
    210.00, 1092.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 23)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    23, 4, '2026-03-31', N'APORTE_EMPLEADO',
    336.00, 1428.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 24)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    24, 4, '2026-03-31', N'APORTE_PATRONAL',
    210.00, 1638.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

-- ---- SavingsFundId=5 (V-18234567, Emp=190, Pat=190) ----
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 25)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    25, 5, '2026-01-31', N'APORTE_EMPLEADO',
    190.00, 190.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 26)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    26, 5, '2026-01-31', N'APORTE_PATRONAL',
    190.00, 380.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 27)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    27, 5, '2026-02-28', N'APORTE_EMPLEADO',
    190.00, 570.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 28)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    28, 5, '2026-02-28', N'APORTE_PATRONAL',
    190.00, 760.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 29)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    29, 5, '2026-03-31', N'APORTE_EMPLEADO',
    190.00, 950.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 30)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    30, 5, '2026-03-31', N'APORTE_PATRONAL',
    190.00, 1140.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

-- ---- SavingsFundId=6 (V-22678901, Emp=450, Pat=225) ----
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 31)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    31, 6, '2026-01-31', N'APORTE_EMPLEADO',
    450.00, 450.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 32)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    32, 6, '2026-01-31', N'APORTE_PATRONAL',
    225.00, 675.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 33)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    33, 6, '2026-02-28', N'APORTE_EMPLEADO',
    450.00, 1125.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 34)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    34, 6, '2026-02-28', N'APORTE_PATRONAL',
    225.00, 1350.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 35)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    35, 6, '2026-03-31', N'APORTE_EMPLEADO',
    450.00, 1800.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 36)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    36, 6, '2026-03-31', N'APORTE_PATRONAL',
    225.00, 2025.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

-- ---- SavingsFundId=7 (V-20456789, Emp=196, Pat=140) ----
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 37)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    37, 7, '2026-01-31', N'APORTE_EMPLEADO',
    196.00, 196.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 38)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    38, 7, '2026-01-31', N'APORTE_PATRONAL',
    140.00, 336.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 39)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    39, 7, '2026-02-28', N'APORTE_EMPLEADO',
    196.00, 532.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 40)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    40, 7, '2026-02-28', N'APORTE_PATRONAL',
    140.00, 672.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 41)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    41, 7, '2026-03-31', N'APORTE_EMPLEADO',
    196.00, 868.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 42)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    42, 7, '2026-03-31', N'APORTE_PATRONAL',
    140.00, 1008.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

-- ---- SavingsFundId=8 (V-24890123, Emp=125, Pat=125) ----
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 43)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    43, 8, '2026-01-31', N'APORTE_EMPLEADO',
    125.00, 125.00, N'NOM-2026-01', NULL, N'Aporte empleado enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 44)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    44, 8, '2026-01-31', N'APORTE_PATRONAL',
    125.00, 250.00, N'NOM-2026-01', NULL, N'Aporte patronal enero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 45)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    45, 8, '2026-02-28', N'APORTE_EMPLEADO',
    125.00, 375.00, N'NOM-2026-02', NULL, N'Aporte empleado febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 46)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    46, 8, '2026-02-28', N'APORTE_PATRONAL',
    125.00, 500.00, N'NOM-2026-02', NULL, N'Aporte patronal febrero 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 47)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    47, 8, '2026-03-31', N'APORTE_EMPLEADO',
    125.00, 625.00, N'NOM-2026-03', NULL, N'Aporte empleado marzo 2026', SYSUTCDATETIME()
);
IF NOT EXISTS (SELECT 1 FROM hr.SavingsFundTransaction WHERE TransactionId = 48)
INSERT INTO hr.SavingsFundTransaction (
    TransactionId, SavingsFundId, TransactionDate, TransactionType,
    Amount, Balance, Reference, PayrollBatchId, Notes, CreatedAt
) VALUES (
    48, 8, '2026-03-31', N'APORTE_PATRONAL',
    125.00, 750.00, N'NOM-2026-03', NULL, N'Aporte patronal marzo 2026', SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsFundTransaction OFF;
PRINT '   36 transacciones de caja de ahorro insertadas (IDs 13-48).';
GO

-- ============================================================================
-- 8. PRÉSTAMO CAJA DE AHORRO — V-22678901 (SavingsFundId=6)
-- ============================================================================
PRINT '>> 8. Préstamo Caja de Ahorro';

SET IDENTITY_INSERT hr.SavingsLoan ON;

-- LoanId=2 (LoanId=1 ya existe en Part 1)
IF NOT EXISTS (SELECT 1 FROM hr.SavingsLoan WHERE LoanId = 2)
INSERT INTO hr.SavingsLoan (
    LoanId, SavingsFundId, EmployeeCode, RequestDate, ApprovedDate,
    LoanAmount, InterestRate, TotalPayable, MonthlyPayment,
    InstallmentsTotal, InstallmentsPaid, OutstandingBalance,
    Status, ApprovedBy, Notes, CreatedAt, UpdatedAt
) VALUES (
    2, 6, N'V-22678901', '2025-10-01', '2025-10-05',
    5000.00, 12.00, 5600.00, 443.21,
    12, 3, 3770.37,
    N'ACTIVO', 1,
    N'Préstamo ordinario caja de ahorro. 12 cuotas mensuales al 12% anual. 3 cuotas pagadas (nov, dic 2025, ene 2026).',
    SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SavingsLoan OFF;
PRINT '   1 préstamo de caja de ahorro insertado (LoanId=2).';
GO

-- ============================================================================
-- 9. UTILIDADES (ProfitSharingLine) — Empleados 3-9
-- ============================================================================
PRINT '>> 9. Utilidades 2025 — Líneas empleados 3-9';

-- ProfitSharingId=1, FiscalYear=2025, DaysGranted=30 (del header existente)
-- Salarios: Emp3=3500, Emp4=4200, Emp5=3200, Emp6=3800, Emp7=2800, Emp8=4500, Emp9=2500
-- DailySalary = Salary/30
-- GrossAmount = DailySalary * 30 = Salary
-- InceDeduction = GrossAmount * 0.005
-- NetAmount = GrossAmount - InceDeduction
-- LineIds 3-9 (1-2 ya existen en Part 1)

SET IDENTITY_INSERT hr.ProfitSharingLine ON;

-- Emp 3: V-12345678 — Salary 3500
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 3)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    3, 1, 3, N'V-12345678', N'Carlos Mendoza',
    3500.00, 116.6667, 365, 30,
    3500.00, 17.50, 3482.50, 0, NULL
);

-- Emp 4: V-14567890 — Salary 4200
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 4)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    4, 1, 4, N'V-14567890', N'Ana Rodríguez',
    4200.00, 140.0000, 365, 30,
    4200.00, 21.00, 4179.00, 0, NULL
);

-- Emp 5: V-16789012 — Salary 3200
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 5)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    5, 1, 5, N'V-16789012', N'María López',
    3200.00, 106.6667, 365, 30,
    3200.00, 16.00, 3184.00, 0, NULL
);

-- Emp 6: V-18234567 — Salary 3800
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 6)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    6, 1, 6, N'V-18234567', N'Pedro García',
    3800.00, 126.6667, 365, 30,
    3800.00, 19.00, 3781.00, 0, NULL
);

-- Emp 7: V-20456789 — Salary 2800
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 7)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    7, 1, 7, N'V-20456789', N'Luisa Martínez',
    2800.00, 93.3333, 365, 30,
    2800.00, 14.00, 2786.00, 0, NULL
);

-- Emp 8: V-22678901 — Salary 4500
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 8)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    8, 1, 8, N'V-22678901', N'Fernando Díaz',
    4500.00, 150.0000, 365, 30,
    4500.00, 22.50, 4477.50, 0, NULL
);

-- Emp 9: V-24890123 — Salary 2500
IF NOT EXISTS (SELECT 1 FROM hr.ProfitSharingLine WHERE ProfitSharingId = 1 AND EmployeeId = 9)
INSERT INTO hr.ProfitSharingLine (
    LineId, ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
    MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
    GrossAmount, InceDeduction, NetAmount, IsPaid, PaidAt
) VALUES (
    9, 1, 9, N'V-24890123', N'Roberto Hernández',
    2500.00, 83.3333, 365, 30,
    2500.00, 12.50, 2487.50, 0, NULL
);

SET IDENTITY_INSERT hr.ProfitSharingLine OFF;
PRINT '   7 líneas de utilidades insertadas (empleados 3-9).';
GO

-- ============================================================================
-- 10. FIDEICOMISO (SocialBenefitsTrust) — Q1 2026, Empleados 3-9
-- ============================================================================
PRINT '>> 10. Fideicomiso Q1 2026 — Empleados 3-9';

-- DailySalary = Salary/30, DaysDeposited=15, InterestRate=15.3%
-- DepositAmount = DailySalary * 15
-- Q1 2026 es primer trimestre para estos empleados en este seed → Interest=0, Accumulated=Deposit
-- (asumiendo que Part 1 no tiene datos para estos empleados en 2026)

-- TrustIds 9-15 (1-8 ya existen en Part 1)
SET IDENTITY_INSERT hr.SocialBenefitsTrust ON;

-- Emp 3: V-12345678 — Salary=3500, Daily=116.6667, Deposit=1750.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 9)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    9, 1, 3, N'V-12345678', N'Carlos Mendoza',
    2026, 1, 116.6667, 15, 0,
    1750.00, 15.30, 0.00, 1750.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 4: V-14567890 — Salary=4200, Daily=140.0000, Deposit=2100.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 10)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    10, 1, 4, N'V-14567890', N'Ana Rodríguez',
    2026, 1, 140.0000, 15, 0,
    2100.00, 15.30, 0.00, 2100.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 5: V-16789012 — Salary=3200, Daily=106.6667, Deposit=1600.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 11)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    11, 1, 5, N'V-16789012', N'María López',
    2026, 1, 106.6667, 15, 0,
    1600.00, 15.30, 0.00, 1600.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 6: V-18234567 — Salary=3800, Daily=126.6667, Deposit=1900.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 12)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    12, 1, 6, N'V-18234567', N'Pedro García',
    2026, 1, 126.6667, 15, 0,
    1900.00, 15.30, 0.00, 1900.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 7: V-20456789 — Salary=2800, Daily=93.3333, Deposit=1400.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 13)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    13, 1, 7, N'V-20456789', N'Luisa Martínez',
    2026, 1, 93.3333, 15, 0,
    1400.00, 15.30, 0.00, 1400.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 8: V-22678901 — Salary=4500, Daily=150.0000, Deposit=2250.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 14)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    14, 1, 8, N'V-22678901', N'Fernando Díaz',
    2026, 1, 150.0000, 15, 0,
    2250.00, 15.30, 0.00, 2250.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- Emp 9: V-24890123 — Salary=2500, Daily=83.3333, Deposit=1250.00
IF NOT EXISTS (SELECT 1 FROM hr.SocialBenefitsTrust WHERE TrustId = 15)
INSERT INTO hr.SocialBenefitsTrust (
    TrustId, CompanyId, EmployeeId, EmployeeCode, EmployeeName,
    FiscalYear, Quarter, DailySalary, DaysDeposited, BonusDays,
    DepositAmount, InterestRate, InterestAmount, AccumulatedBalance,
    Status, CreatedAt, UpdatedAt
) VALUES (
    15, 1, 9, N'V-24890123', N'Roberto Hernández',
    2026, 1, 83.3333, 15, 0,
    1250.00, 15.30, 0.00, 1250.00,
    N'DEPOSITADO', SYSUTCDATETIME(), SYSUTCDATETIME()
);

SET IDENTITY_INSERT hr.SocialBenefitsTrust OFF;
PRINT '   7 registros de fideicomiso Q1 2026 insertados (TrustIds 9-15).';
GO

-- ============================================================================
-- 11. PLANTILLAS DE DOCUMENTOS (6 templates)
-- ============================================================================
PRINT '>> 11. Plantillas de Documentos';

-- RECIBO_NOMINA
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'RECIBO_NOMINA')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'RECIBO_NOMINA', N'Recibo de Nómina', N'NOMINA', N'VE',
    NULL,
    N'# Recibo de Nómina

**Empresa:** {{CompanyName}}
**RIF:** {{CompanyRif}}
**Período:** {{PeriodStart}} al {{PeriodEnd}}

---

**Empleado:** {{EmployeeName}}
**Cédula:** {{EmployeeCode}}
**Cargo:** {{JobTitle}}
**Departamento:** {{DepartmentName}}
**Fecha de Ingreso:** {{HireDate}}

---

## Asignaciones

| Concepto | Monto |
|----------|------:|
{{#Earnings}}
| {{ConceptName}} | {{Amount}} |
{{/Earnings}}
| **Total Asignaciones** | **{{TotalEarnings}}** |

## Deducciones

| Concepto | Monto |
|----------|------:|
{{#Deductions}}
| {{ConceptName}} | {{Amount}} |
{{/Deductions}}
| **Total Deducciones** | **{{TotalDeductions}}** |

---

**Neto a Pagar:** {{NetPay}}

Generado el {{GeneratedAt}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- CONSTANCIA_TRABAJO
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'CONSTANCIA_TRABAJO')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'CONSTANCIA_TRABAJO', N'Constancia de Trabajo', N'CONSTANCIA', N'VE',
    NULL,
    N'# Constancia de Trabajo

**{{CompanyName}}**
RIF: {{CompanyRif}}

---

Por medio de la presente se hace constar que el(la) ciudadano(a) **{{EmployeeName}}**, titular de la cédula de identidad **{{EmployeeCode}}**, presta sus servicios en esta empresa desde el **{{HireDate}}**, desempeñando el cargo de **{{JobTitle}}** en el departamento de **{{DepartmentName}}**.

Su salario mensual actual es de **{{MonthlySalary}}**.

Constancia que se expide a solicitud de la parte interesada en {{City}}, a los {{DayOfMonth}} días del mes de {{MonthName}} de {{Year}}.

---

_________________________
{{SignerName}}
{{SignerTitle}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- CARTA_VACACIONES
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'CARTA_VACACIONES')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'CARTA_VACACIONES', N'Carta de Vacaciones', N'VACACIONES', N'VE',
    NULL,
    N'# Carta de Vacaciones

**{{CompanyName}}**
RIF: {{CompanyRif}}

---

Se comunica al(a) trabajador(a) **{{EmployeeName}}**, cédula **{{EmployeeCode}}**, que le han sido concedidas vacaciones correspondientes al período **{{VacationPeriod}}**, por un total de **{{TotalDays}}** días hábiles.

**Fecha de salida:** {{StartDate}}
**Fecha de reincorporación:** {{ReturnDate}}

**Bono Vacacional:** {{VacationBonus}}
**Días de Bono:** {{BonusDays}}

---

_________________________
{{SignerName}}
{{SignerTitle}}

Fecha: {{GeneratedAt}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- LIQUIDACION
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'LIQUIDACION')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'LIQUIDACION', N'Liquidación de Prestaciones', N'LIQUIDACION', N'VE',
    NULL,
    N'# Liquidación de Prestaciones Sociales

**{{CompanyName}}**
RIF: {{CompanyRif}}

---

**Trabajador:** {{EmployeeName}}
**Cédula:** {{EmployeeCode}}
**Cargo:** {{JobTitle}}
**Fecha de Ingreso:** {{HireDate}}
**Fecha de Egreso:** {{TerminationDate}}
**Motivo:** {{TerminationReason}}
**Antigüedad:** {{YearsOfService}} años, {{MonthsOfService}} meses

---

## Conceptos

| Concepto | Monto |
|----------|------:|
| Prestaciones Sociales (Art. 142 LOTTT) | {{SocialBenefits}} |
| Intereses sobre Prestaciones | {{InterestAmount}} |
| Vacaciones Fraccionadas | {{FractionalVacation}} |
| Bono Vacacional Fraccionado | {{FractionalVacationBonus}} |
| Utilidades Fraccionadas | {{FractionalProfitSharing}} |
| Días Adicionales (Art. 142 lit. c) | {{AdditionalDays}} |
{{#OtherItems}}
| {{ConceptName}} | {{Amount}} |
{{/OtherItems}}
| **Total Bruto** | **{{GrossTotal}}** |
| Deducciones | {{TotalDeductions}} |
| **Neto a Pagar** | **{{NetTotal}}** |

---

Conforme:

_________________________
{{EmployeeName}} — C.I. {{EmployeeCode}}

_________________________
{{SignerName}} — {{SignerTitle}}

Fecha: {{GeneratedAt}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- ARC
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'ARC')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'ARC', N'Constancia de Retenciones ARC', N'FISCAL', N'VE',
    NULL,
    N'# Constancia de Retenciones de ISLR (ARC)

**Agente de Retención:** {{CompanyName}}
**RIF:** {{CompanyRif}}

---

**Beneficiario:** {{EmployeeName}}
**Cédula / RIF:** {{EmployeeCode}}
**Ejercicio Fiscal:** {{FiscalYear}}

---

## Resumen de Retenciones

| Mes | Remuneración Pagada | ISLR Retenido |
|-----|--------------------:|--------------:|
{{#MonthlyRetentions}}
| {{MonthName}} | {{GrossPay}} | {{TaxWithheld}} |
{{/MonthlyRetentions}}
| **TOTAL** | **{{TotalGrossPay}}** | **{{TotalTaxWithheld}}** |

---

**Total Remuneraciones Pagadas:** {{TotalGrossPay}}
**Total ISLR Retenido:** {{TotalTaxWithheld}}

Constancia emitida conforme al Art. 25 del Reglamento de la Ley de ISLR.

_________________________
{{SignerName}}
{{SignerTitle}}

Fecha: {{GeneratedAt}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

-- CONSTANCIA_INGRESOS
IF NOT EXISTS (SELECT 1 FROM hr.DocumentTemplate WHERE CompanyId = 1 AND TemplateCode = N'CONSTANCIA_INGRESOS')
INSERT INTO hr.DocumentTemplate (
    CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode,
    PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt
) VALUES (
    1, N'CONSTANCIA_INGRESOS', N'Constancia de Ingresos', N'CONSTANCIA', N'VE',
    NULL,
    N'# Constancia de Ingresos

**{{CompanyName}}**
RIF: {{CompanyRif}}

---

Por medio de la presente se hace constar que el(la) ciudadano(a) **{{EmployeeName}}**, titular de la cédula de identidad **{{EmployeeCode}}**, labora en esta empresa desde el **{{HireDate}}**, desempeñando el cargo de **{{JobTitle}}**.

Durante el período comprendido entre **{{PeriodStart}}** y **{{PeriodEnd}}**, el(la) trabajador(a) devengó los siguientes ingresos:

| Concepto | Monto Mensual | Monto Total |
|----------|-------------:|------------:|
| Salario Básico | {{MonthlySalary}} | {{TotalSalary}} |
| Otros Ingresos | {{MonthlyOtherIncome}} | {{TotalOtherIncome}} |
| **Total** | **{{MonthlyTotal}}** | **{{GrandTotal}}** |

Constancia que se expide a solicitud de la parte interesada en {{City}}, a los {{DayOfMonth}} días del mes de {{MonthName}} de {{Year}}.

---

_________________________
{{SignerName}}
{{SignerTitle}}',
    1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
);

PRINT '   6 plantillas de documentos insertadas.';
GO

-- ============================================================================
PRINT '=== SEED NÓMINA COMPLETO P2 — Fin ===';
GO
