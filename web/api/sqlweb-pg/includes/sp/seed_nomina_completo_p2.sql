-- ============================================================================
-- SEED NOMINA COMPLETO — PARTE 2 (PostgreSQL)
-- Continua seed_nomina_completo.sql (Part 1)
-- Empleados Id 1-10 ya existen en master."Employee"
-- Idempotente: usa NOT EXISTS en cada INSERT
-- Convertido desde SQL Server
-- Fecha: 2026-03-16
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== SEED NOMINA COMPLETO P2 — Inicio ===';

  -- ============================================================================
  -- 1. TRAINING RECORDS (8 registros) — IDs 5-12
  -- ============================================================================
  RAISE NOTICE '>> 1. Capacitacion (8 registros nuevos)';

  -- 5: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp 3
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 5) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      5, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      3, 'V-12345678', 'Carlos Mendoza',
      'ISL-PRL-2025-0103', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 6: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp 4
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 6) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      6, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      4, 'V-14567890', 'Ana Rodriguez',
      'ISL-PRL-2025-0104', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 7: SEGURIDAD — Prevencion de Riesgos LOPCYMAT, emp 5
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 7) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      7, 1, 'VE', 'SEGURIDAD', 'Prevencion de Riesgos Laborales LOPCYMAT', 'Instituto Seguridad Laboral',
      '2025-06-09', '2025-06-10', 16,
      5, 'V-16789012', 'Maria Lopez',
      'ISL-PRL-2025-0105', NULL, 'APROBADO', true,
      'Capacitacion obligatoria LOPCYMAT. Identificacion de riesgos, uso de EPP, notificacion de riesgos.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 8: SEGURIDAD — Manejo Sustancias Peligrosas, emp 3
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 8) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      8, 1, 'VE', 'SEGURIDAD', 'Manejo de Sustancias Peligrosas', 'Instituto Seguridad Laboral',
      '2025-09-22', '2025-09-23', 16,
      3, 'V-12345678', 'Carlos Mendoza',
      'ISL-MSP-2025-0088', NULL, 'APROBADO', true,
      'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias quimicas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 9: SEGURIDAD — Manejo Sustancias Peligrosas, emp 6
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 9) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      9, 1, 'VE', 'SEGURIDAD', 'Manejo de Sustancias Peligrosas', 'Instituto Seguridad Laboral',
      '2025-09-22', '2025-09-23', 16,
      6, 'V-18234567', 'Pedro Garcia',
      'ISL-MSP-2025-0089', NULL, 'APROBADO', true,
      'Normativa LOPCYMAT y NT para manejo, almacenamiento y transporte de sustancias quimicas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 10: DESARROLLO — Excel Avanzado, emp 5
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 10) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      10, 1, 'VE', 'DESARROLLO', 'Excel Avanzado', 'AcademiaVE',
      '2026-01-13', '2026-01-31', 24,
      5, 'V-16789012', 'Maria Lopez',
      'AVE-EXC-2026-0045', NULL, 'APROBADO', false,
      'Tablas dinamicas, Power Query, macros VBA, dashboards. Formacion de desarrollo profesional.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 11: DESARROLLO — Excel Avanzado, emp 7
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 11) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      11, 1, 'VE', 'DESARROLLO', 'Excel Avanzado', 'AcademiaVE',
      '2026-01-13', '2026-01-31', 24,
      7, 'V-20456789', 'Luisa Martinez',
      'AVE-EXC-2026-0046', NULL, 'APROBADO', false,
      'Tablas dinamicas, Power Query, macros VBA, dashboards. Formacion de desarrollo profesional.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- 12: INDUCCION — Induccion DatqBox, emp 9
  IF NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "TrainingRecordId" = 12) THEN
    INSERT INTO hr."TrainingRecord" (
      "TrainingRecordId", "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
      "StartDate", "EndDate", "DurationHours",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "CertificateNumber", "CertificateUrl", "Result", "IsRegulatory",
      "Notes", "CreatedAt", "UpdatedAt"
    ) VALUES (
      12, 1, 'VE', 'INDUCCION', 'Induccion DatqBox', 'INCES',
      '2025-11-03', '2025-11-07', 40,
      9, 'V-24890123', 'Roberto Hernandez',
      'INCES-IND-2025-1201', NULL, 'APROBADO', true,
      'Induccion integral: cultura organizacional, procesos, LOPCYMAT, seguridad informatica, herramientas internas.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  RAISE NOTICE '   8 registros de capacitacion insertados (IDs 5-12).';

  -- ============================================================================
  -- 2. COMITES DE SEGURIDAD (2) + Miembros + Reuniones
  -- ============================================================================
  RAISE NOTICE '>> 2. Comites de Seguridad';

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommittee" WHERE "SafetyCommitteeId" = 100) THEN
    INSERT INTO hr."SafetyCommittee" (
      "SafetyCommitteeId", "CompanyId", "CountryCode", "CommitteeName",
      "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
    ) VALUES (
      100, 1, 'VE', 'Comite de Seguridad y Salud Laboral',
      '2024-01-15', 'MENSUAL', true, (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommittee" WHERE "SafetyCommitteeId" = 101) THEN
    INSERT INTO hr."SafetyCommittee" (
      "SafetyCommitteeId", "CompanyId", "CountryCode", "CommitteeName",
      "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
    ) VALUES (
      101, 1, 'VE', 'Comite de Bienestar Social',
      '2024-06-01', 'TRIMESTRAL', true, (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- Miembros Comite 100
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 100) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) VALUES (100, 100, 8, 'V-22678901', 'Fernando Diaz', 'PRESIDENTE', '2024-01-15', NULL);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 101) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) VALUES (101, 100, 3, 'V-12345678', 'Carlos Mendoza', 'SECRETARIO', '2024-01-15', NULL);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 102) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) VALUES (102, 100, 4, 'V-14567890', 'Ana Rodriguez', 'VOCAL', '2024-01-15', NULL);
  END IF;

  -- Miembros Comite 101
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 103) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) VALUES (103, 101, 5, 'V-16789012', 'Maria Lopez', 'PRESIDENTA', '2024-06-01', NULL);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "MemberId" = 104) THEN
    INSERT INTO hr."SafetyCommitteeMember" (
      "MemberId", "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "Role", "StartDate", "EndDate"
    ) VALUES (104, 101, 7, 'V-20456789', 'Luisa Martinez', 'SECRETARIA', '2024-06-01', NULL);
  END IF;

  -- Reuniones Comite 100
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 100) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) VALUES (
      100, 100, '2026-01-20', NULL,
      '1. Revision accidentes Q4 2025. 2. Plan de capacitacion SST 2026. 3. Auditoria de extintores y senalizacion.',
      '- Programar inspeccion de extintores antes del 31/01. - Actualizar mapa de riesgos del almacen. - Coordinar charla de primeros auxilios con Cruz Roja.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 101) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) VALUES (
      101, 100, '2026-02-17', NULL,
      '1. Resultado inspeccion extintores. 2. Estadisticas accidentalidad enero. 3. Dotacion EPP primer trimestre.',
      '- Reemplazar 3 extintores vencidos en planta baja. - Solicitar cotizacion EPP nuevos ingresos. - Fijar fecha simulacro evacuacion marzo.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 102) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) VALUES (
      102, 100, '2026-03-16', NULL,
      '1. Simulacro de evacuacion realizado (3 min 20 seg). 2. Revision plan de emergencia. 3. Informe trimestral INPSASEL.',
      '- Documentar resultados simulacro para informe INPSASEL. - Corregir ruta evacuacion piso 2. - Entregar informe trimestral antes del 10/04.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  -- Reunion Comite 101
  IF NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "MeetingId" = 103) THEN
    INSERT INTO hr."SafetyCommitteeMeeting" (
      "MeetingId", "SafetyCommitteeId", "MeetingDate", "MinutesUrl", "TopicsSummary",
      "ActionItems", "CreatedAt"
    ) VALUES (
      103, 101, '2026-01-28', NULL,
      '1. Planificacion actividades recreativas Q1 2026. 2. Fondo de ayuda social: balance y solicitudes pendientes. 3. Convenio farmacia.',
      '- Organizar jornada deportiva para febrero. - Evaluar 2 solicitudes de ayuda economica. - Renovar convenio farmacia antes del 15/02.',
      (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  RAISE NOTICE '   2 comites, 5 miembros, 4 reuniones insertados.';

  -- ============================================================================
  -- 3. OBLIGACIONES LEGALES (4 para VE) — Verificar/crear si no existen
  -- ============================================================================
  RAISE NOTICE '>> 3. Obligaciones Legales VE (verificar/crear 4)';

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_SSO', 'Seguro Social Obligatorio', 'IVSS', 'CONTRIBUTION',
      'GROSS_PAYROLL', 10.00000, 4.00000,
      true, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'SSO clase I. Tasa variable segun nivel de riesgo.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_FAOV') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_FAOV', 'Ley de Vivienda y Habitat', 'BANAVIH', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 1.00000,
      false, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'Fondo de Ahorro Obligatorio para la Vivienda.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_LRPE') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_LRPE', 'Regimen Prestacional de Empleo', 'INPSASEL', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 0.50000,
      false, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
      '2012-01-01', true, 'Paro forzoso - Ley del Regimen Prestacional de Empleo.'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_INCE') THEN
    INSERT INTO hr."LegalObligation" (
      "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
      "CalculationBasis", "EmployerRate", "EmployeeRate",
      "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
      "EffectiveFrom", "IsActive", "Notes"
    ) VALUES (
      'VE', 'VE_INCE', 'Capacitacion y Educacion', 'INCES', 'CONTRIBUTION',
      'GROSS_PAYROLL', 2.00000, 0.00000,
      false, 'QUARTERLY', 'Dentro de los 5 dias habiles despues del cierre del trimestre',
      '2012-01-01', true, 'INCES: 2% patronal sobre nomina. Empleado 0.5% sobre utilidades (separado).'
    );
  END IF;

  RAISE NOTICE '   4 obligaciones legales VE verificadas.';

  -- ============================================================================
  -- 4. EMPLOYEE OBLIGATIONS — Inscribir empleados 3-9 en VE_SSO, VE_FAOV, VE_LRPE, VE_INCE
  -- ============================================================================
  RAISE NOTICE '>> 4. Inscripcion de empleados en obligaciones legales';

  -- VE_SSO para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId", aff_num, 'IVSS',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, 'SSO-012345', '2019-03-15'::date),
    (4, 'SSO-014567', '2018-07-01'::date),
    (5, 'SSO-016789', '2020-01-10'::date),
    (6, 'SSO-018234', '2017-04-01'::date),
    (7, 'SSO-020456', '2022-06-01'::date),
    (8, 'SSO-022678', '2016-02-15'::date),
    (9, 'SSO-024890', '2023-03-01'::date)
  ) AS t(emp_id, aff_num, enroll_date)
  WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_SSO'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_SSO.';

  -- VE_FAOV para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId", aff_num, 'BANAVIH',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, 'FAOV-012345', '2019-03-15'::date),
    (4, 'FAOV-014567', '2018-07-01'::date),
    (5, 'FAOV-016789', '2020-01-10'::date),
    (6, 'FAOV-018234', '2017-04-01'::date),
    (7, 'FAOV-020456', '2022-06-01'::date),
    (8, 'FAOV-022678', '2016-02-15'::date),
    (9, 'FAOV-024890', '2023-03-01'::date)
  ) AS t(emp_id, aff_num, enroll_date)
  WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_FAOV'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_FAOV.';

  -- VE_LRPE para empleados 1-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId",
    'LRPE-0' || emp_id::text || lpad((emp_id * 11111)::text, 5, '0'),
    'INPSASEL',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (1, '2024-03-01'::date),
    (2, '2024-06-01'::date),
    (3, '2019-03-15'::date),
    (4, '2018-07-01'::date),
    (5, '2020-01-10'::date),
    (6, '2017-04-01'::date),
    (7, '2022-06-01'::date),
    (8, '2016-02-15'::date),
    (9, '2023-03-01'::date)
  ) AS t(emp_id, enroll_date)
  WHERE lo."Code" = 'VE_LRPE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_LRPE'
  );

  RAISE NOTICE '   Empleados 1-9 inscritos en VE_LRPE.';

  -- VE_INCE para empleados 3-9
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT emp_id, lo."LegalObligationId",
    'INCE-0' || emp_id::text || lpad((emp_id * 22222)::text, 5, '0'),
    'INCE',
    NULL, enroll_date, NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo,
  (VALUES
    (3, '2019-03-15'::date),
    (4, '2018-07-01'::date),
    (5, '2020-01-10'::date),
    (6, '2017-04-01'::date),
    (7, '2022-06-01'::date),
    (8, '2016-02-15'::date),
    (9, '2023-03-01'::date)
  ) AS t(emp_id, enroll_date)
  WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = t.emp_id AND lo2."Code" = 'VE_INCE'
  );

  RAISE NOTICE '   Empleados 3-9 inscritos en VE_INCE.';

  -- ============================================================================
  -- 5. OBLIGATION FILINGS — Ene/Feb/Mar 2026 para SSO y FAOV
  -- ============================================================================
  RAISE NOTICE '>> 5. Declaraciones SSO y FAOV (Ene-Mar 2026)';

  -- SSO Enero 2026 (FilingId 10)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 10) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 10, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-10',
      'SSO-2026-01-0001', 3080.00, 1232.00, 4312.00,
      9, 'PAGADA', 1, NULL, 'Declaracion SSO enero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- SSO Febrero 2026 (FilingId 11)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 11) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 11, 1, lo."LegalObligationId",
      '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-08',
      'SSO-2026-02-0001', 3080.00, 1232.00, 4312.00,
      9, 'PAGADA', 1, NULL, 'Declaracion SSO febrero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- SSO Marzo 2026 (FilingId 12) — PENDIENTE
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 12) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 12, 1, lo."LegalObligationId",
      '2026-03-01', '2026-03-31', '2026-04-10', NULL,
      NULL, 3080.00, 1232.00, 4312.00,
      9, 'PENDIENTE', NULL, NULL, 'Declaracion SSO marzo 2026 — pendiente de pago',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- FAOV Enero 2026 (FilingId 13)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 13) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 13, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-10', '2026-02-09',
      'FAOV-2026-01-0001', 616.00, 308.00, 924.00,
      9, 'PAGADA', 1, NULL, 'Declaracion FAOV enero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  -- FAOV Febrero 2026 (FilingId 14)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 14) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 14, 1, lo."LegalObligationId",
      '2026-02-01', '2026-02-28', '2026-03-10', '2026-03-07',
      'FAOV-2026-02-0001', 616.00, 308.00, 924.00,
      9, 'PAGADA', 1, NULL, 'Declaracion FAOV febrero 2026 — 9 empleados activos',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  -- FAOV Marzo 2026 (FilingId 15) — PENDIENTE
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 15) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    )
    SELECT 15, 1, lo."LegalObligationId",
      '2026-03-01', '2026-03-31', '2026-04-10', NULL,
      NULL, 616.00, 308.00, 924.00,
      9, 'PENDIENTE', NULL, NULL, 'Declaracion FAOV marzo 2026 — pendiente de pago',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV';
  END IF;

  RAISE NOTICE '   6 filings (SSO+FAOV x 3 meses) insertados.';

  -- Filing detail por empleado (SSO: 10-12, FAOV: 13-15)
  -- SSO: Patronal=Salary*0.10, Empleado=Salary*0.04
  -- FAOV: Patronal=Salary*0.02, Empleado=Salary*0.01
  INSERT INTO hr."ObligationFilingDetail" (
    "ObligationFilingId", "EmployeeId", "BaseSalary",
    "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
  )
  SELECT f_id, emp_id, salary,
    CAST(salary * 0.10 AS DECIMAL(18,2)),
    CAST(salary * 0.04 AS DECIMAL(18,2)),
    30, NULL
  FROM (VALUES (10), (11), (12)) AS filings(f_id),
  (VALUES
    (1, 3500.00), (2, 2800.00), (3, 3500.00), (4, 4200.00), (5, 3200.00),
    (6, 3800.00), (7, 2800.00), (8, 4500.00), (9, 2500.00)
  ) AS salaries(emp_id, salary)
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."ObligationFilingDetail"
    WHERE "ObligationFilingId" = f_id AND "EmployeeId" = emp_id
  );

  INSERT INTO hr."ObligationFilingDetail" (
    "ObligationFilingId", "EmployeeId", "BaseSalary",
    "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
  )
  SELECT f_id, emp_id, salary,
    CAST(salary * 0.02 AS DECIMAL(18,2)),
    CAST(salary * 0.01 AS DECIMAL(18,2)),
    30, NULL
  FROM (VALUES (13), (14), (15)) AS filings(f_id),
  (VALUES
    (1, 3500.00), (2, 2800.00), (3, 3500.00), (4, 4200.00), (5, 3200.00),
    (6, 3800.00), (7, 2800.00), (8, 4500.00), (9, 2500.00)
  ) AS salaries(emp_id, salary)
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."ObligationFilingDetail"
    WHERE "ObligationFilingId" = f_id AND "EmployeeId" = emp_id
  );

  RAISE NOTICE '   54 registros de detalle de filing insertados (9 emp x 6 filings).';

  -- ============================================================================
  -- 6. CAJA DE AHORRO — Inscribir 6 empleados (IDs 3-8)
  -- ============================================================================
  RAISE NOTICE '>> 6. Caja de Ahorro (6 inscripciones)';

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 3) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (3, 1, 3, 'V-12345678', 'Carlos Mendoza', 10.00, 5.00, '2021-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 4) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (4, 1, 4, 'V-14567890', 'Ana Rodriguez', 8.00, 5.00, '2020-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 5) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (5, 1, 6, 'V-18234567', 'Pedro Garcia', 5.00, 5.00, '2019-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 6) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (6, 1, 8, 'V-22678901', 'Fernando Diaz', 10.00, 5.00, '2018-01-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 7) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (7, 1, 7, 'V-20456789', 'Luisa Martinez', 7.00, 5.00, '2022-06-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 8) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) VALUES (8, 1, 9, 'V-24890123', 'Roberto Hernandez', 5.00, 5.00, '2023-03-01', 'ACTIVO', (NOW() AT TIME ZONE 'UTC'));
  END IF;

  RAISE NOTICE '   6 inscripciones de caja de ahorro insertadas (IDs 3-8).';

  -- ============================================================================
  -- 7. SAVINGS FUND TRANSACTIONS — Ene-Mar 2026 para 6 empleados (IDs 13-48)
  -- SavingsFundId | EmpCode    | Salary | Emp%  | EmpAmt | PatAmt(5%)
  --           3   | V-12345678 | 3500   | 10%   | 350    | 175
  --           4   | V-14567890 | 4200   | 8%    | 336    | 210
  --           5   | V-18234567 | 3800   | 5%    | 190    | 190
  --           6   | V-22678901 | 4500   | 10%   | 450    | 225
  --           7   | V-20456789 | 2800   | 7%    | 196    | 140
  --           8   | V-24890123 | 2500   | 5%    | 125    | 125
  -- ============================================================================
  RAISE NOTICE '>> 7. Transacciones Caja de Ahorro (Ene-Mar 2026)';

  INSERT INTO hr."SavingsFundTransaction" (
    "TransactionId", "SavingsFundId", "TransactionDate", "TransactionType",
    "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
  )
  SELECT txn_id, fund_id, txn_date::date, txn_type,
    amount, balance, ref, NULL, notes, (NOW() AT TIME ZONE 'UTC')
  FROM (VALUES
    -- SavingsFundId=3 (V-12345678, Emp=350, Pat=175)
    (13, 3, '2026-01-31', 'APORTE_EMPLEADO', 350.00, 350.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (14, 3, '2026-01-31', 'APORTE_PATRONAL', 175.00, 525.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (15, 3, '2026-02-28', 'APORTE_EMPLEADO', 350.00, 875.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (16, 3, '2026-02-28', 'APORTE_PATRONAL', 175.00, 1050.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (17, 3, '2026-03-31', 'APORTE_EMPLEADO', 350.00, 1400.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (18, 3, '2026-03-31', 'APORTE_PATRONAL', 175.00, 1575.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=4 (V-14567890, Emp=336, Pat=210)
    (19, 4, '2026-01-31', 'APORTE_EMPLEADO', 336.00, 336.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (20, 4, '2026-01-31', 'APORTE_PATRONAL', 210.00, 546.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (21, 4, '2026-02-28', 'APORTE_EMPLEADO', 336.00, 882.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (22, 4, '2026-02-28', 'APORTE_PATRONAL', 210.00, 1092.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (23, 4, '2026-03-31', 'APORTE_EMPLEADO', 336.00, 1428.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (24, 4, '2026-03-31', 'APORTE_PATRONAL', 210.00, 1638.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=5 (V-18234567, Emp=190, Pat=190)
    (25, 5, '2026-01-31', 'APORTE_EMPLEADO', 190.00, 190.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (26, 5, '2026-01-31', 'APORTE_PATRONAL', 190.00, 380.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (27, 5, '2026-02-28', 'APORTE_EMPLEADO', 190.00, 570.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (28, 5, '2026-02-28', 'APORTE_PATRONAL', 190.00, 760.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (29, 5, '2026-03-31', 'APORTE_EMPLEADO', 190.00, 950.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (30, 5, '2026-03-31', 'APORTE_PATRONAL', 190.00, 1140.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=6 (V-22678901, Emp=450, Pat=225)
    (31, 6, '2026-01-31', 'APORTE_EMPLEADO', 450.00, 450.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (32, 6, '2026-01-31', 'APORTE_PATRONAL', 225.00, 675.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (33, 6, '2026-02-28', 'APORTE_EMPLEADO', 450.00, 1125.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (34, 6, '2026-02-28', 'APORTE_PATRONAL', 225.00, 1350.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (35, 6, '2026-03-31', 'APORTE_EMPLEADO', 450.00, 1800.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (36, 6, '2026-03-31', 'APORTE_PATRONAL', 225.00, 2025.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=7 (V-20456789, Emp=196, Pat=140)
    (37, 7, '2026-01-31', 'APORTE_EMPLEADO', 196.00, 196.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (38, 7, '2026-01-31', 'APORTE_PATRONAL', 140.00, 336.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (39, 7, '2026-02-28', 'APORTE_EMPLEADO', 196.00, 532.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (40, 7, '2026-02-28', 'APORTE_PATRONAL', 140.00, 672.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (41, 7, '2026-03-31', 'APORTE_EMPLEADO', 196.00, 868.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (42, 7, '2026-03-31', 'APORTE_PATRONAL', 140.00, 1008.00, 'NOM-2026-03', 'Aporte patronal marzo 2026'),
    -- SavingsFundId=8 (V-24890123, Emp=125, Pat=125)
    (43, 8, '2026-01-31', 'APORTE_EMPLEADO', 125.00, 125.00, 'NOM-2026-01', 'Aporte empleado enero 2026'),
    (44, 8, '2026-01-31', 'APORTE_PATRONAL', 125.00, 250.00, 'NOM-2026-01', 'Aporte patronal enero 2026'),
    (45, 8, '2026-02-28', 'APORTE_EMPLEADO', 125.00, 375.00, 'NOM-2026-02', 'Aporte empleado febrero 2026'),
    (46, 8, '2026-02-28', 'APORTE_PATRONAL', 125.00, 500.00, 'NOM-2026-02', 'Aporte patronal febrero 2026'),
    (47, 8, '2026-03-31', 'APORTE_EMPLEADO', 125.00, 625.00, 'NOM-2026-03', 'Aporte empleado marzo 2026'),
    (48, 8, '2026-03-31', 'APORTE_PATRONAL', 125.00, 750.00, 'NOM-2026-03', 'Aporte patronal marzo 2026')
  ) AS t(txn_id, fund_id, txn_date, txn_type, amount, balance, ref, notes)
  WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "TransactionId" = t.txn_id);

  RAISE NOTICE '   36 transacciones de caja de ahorro insertadas (IDs 13-48).';

  RAISE NOTICE '=== SEED NOMINA COMPLETO P2 — Completado ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_nomina_completo_p2.sql: %', SQLERRM;
END $$;
