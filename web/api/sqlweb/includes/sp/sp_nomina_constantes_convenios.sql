-- =============================================
-- SEMILLA DE TIPOS DE NÓMINA Y CONCEPTOS POR CONVENIO (CANÓNICO)
-- Tablas objetivo: hr.PayrollType, hr.PayrollConcept
--
-- Contratos cubiertos:
--   LOT      Nómina LOTTT (General mensual)       Base legal: LOTTT 2012, RLOT
--   LOT_Q    Nómina LOTTT Quincenal               SEMANAS_PERIODO = 2.1739 (26/12)
--   LOT_S    Nómina LOTTT Semanal                 SEMANAS_PERIODO = 1 (52 sem/año)
--   PETRO    CCT Petrolero Venezuela              IV CCT PDVSA / contratistas
--   CONST    CCT Construcción Venezuela           CCT CAMARA/FETRACON vigente
--   ADMIN    Nómina Administrativa Venezuela      LOTTT art.105 + empleados de confianza
--   TRANSP   Nómina Transporte Venezuela          CCT transporte terrestre
--   ES_GENERAL Nómina España (General)            RDL 8/2015 LGSS, ET, LISOS
--   MX_GENERAL Nómina México (General)            LSS, LINFONAVIT, LISR, LFT
--   CO_GENERAL Nómina Colombia (General)          L.100/1993, L.789/2002, L.1607/2012
--
-- Notas de fórmulas:
--   SEMANAS_PERIODO  = calculado en runtime según frecuencia (mensual≈4.3478, quinc≈2.1739, sem=1)
--   TOPE_SSO_SEM     = SUELDO_MIN * TOPE_SSO / SEMANAS_ANO   (runtime)
--   TOPE_RPE_SEM     = SUELDO_MIN * TOPE_RPE / SEMANAS_ANO   (runtime)
--   HORAS_HE_D/N/V   = variables de entrada del usuario al procesar nómina
--   SUELDO           = salario base configurado en el contrato del empleado
-- =============================================
SET NOCOUNT ON;
GO

DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
  THROW 50012, 'No existe cfg.Company activa para sembrar conceptos nómina', 1;

-- =============================================
-- 1. TIPOS DE NÓMINA (hr.PayrollType)
-- =============================================
;WITH TypeSeed AS (
  SELECT N'LOT'        AS PayrollCode, N'Nómina LOTTT (General)'        AS PayrollName
  UNION ALL SELECT N'LOT_Q',      N'Nómina LOTTT Quincenal'
  UNION ALL SELECT N'LOT_S',      N'Nómina LOTTT Semanal'
  UNION ALL SELECT N'PETRO',      N'Nómina CCT Petrolero'
  UNION ALL SELECT N'CONST',      N'Nómina CCT Construcción'
  UNION ALL SELECT N'ADMIN',      N'Nómina Administrativa'
  UNION ALL SELECT N'TRANSP',     N'Nómina Transporte'
  UNION ALL SELECT N'ES_GENERAL', N'Nómina España (General)'
  UNION ALL SELECT N'MX_GENERAL', N'Nómina México (General)'
  UNION ALL SELECT N'CO_GENERAL', N'Nómina Colombia (General)'
)
MERGE hr.PayrollType AS target
USING TypeSeed AS src
ON target.CompanyId = @CompanyId
   AND target.PayrollCode = src.PayrollCode
WHEN MATCHED THEN
  UPDATE SET
    PayrollName = src.PayrollName,
    IsActive    = 1,
    UpdatedAt   = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (CompanyId, PayrollCode, PayrollName, IsActive, CreatedAt, UpdatedAt)
  VALUES (@CompanyId, src.PayrollCode, src.PayrollName, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

-- =============================================
-- 2. CONCEPTOS POR CONVENIO (hr.PayrollConcept)
--
-- Columnas CTE:
--   PayrollCode, ConventionCode, CalculationType,
--   ConceptCode, ConceptName, ConceptType,
--   DefaultValue, Formula, ConceptClass, SortOrder
--
-- IsBonifiable  = 1 para ASIGNACION, 0 para DEDUCCION y PATRONAL
-- UsageType     = 'T' (todos)
-- MERGE ON:     CompanyId + PayrollCode + ConceptCode
--             + ISNULL(ConventionCode,'') + ISNULL(CalculationType,'')
-- =============================================
;WITH SourceRows AS (

  -- ==========================================================
  -- LOT — LOTTT General (mensual)
  -- Base legal: LOTTT art.95 (jornada), art.131 (HE),
  --   art.190 (vacaciones), art.192 (bono vac.), art.131 (útils.)
  -- ==========================================================

  -- LOT · MENSUAL · Asignaciones
  SELECT N'LOT' AS PayrollCode, N'LOT' AS ConventionCode, N'MENSUAL' AS CalculationType,
         N'ASIG_BASE'     AS ConceptCode, N'Sueldo Base'              AS ConceptName, N'ASIGNACION' AS ConceptType,
         CAST(0.00 AS DECIMAL(18,6)) AS DefaultValue, N'SUELDO'  AS Formula, N'SALARIO'     AS ConceptClass, 10 AS SortOrder
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'BONO_ALIM',     N'Bono de Alimentación',              N'ASIGNACION',0.00,N'0',                                                               N'BONO',      20
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'BONO_TRANS',    N'Bono de Transporte',                N'ASIGNACION',0.00,N'0',                                                               N'BONO',      30
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'HE_DIURNAS',    N'Horas Extras Diurnas',              N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * RECARGO_HE',                          N'HORA_EXTRA',40
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'HE_NOCTURNAS',  N'Horas Extras Nocturnas',            N'ASIGNACION',0.00,N'HORAS_HE_N * SALARIO_HORA * RECARGO_HE * RECARGO_NOCTURNO',       N'HORA_EXTRA',41
  -- LOT · MENSUAL · Deducciones legales
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'DED_SSO',       N'Seguro Social (SSO)',               N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',                        N'LEGAL',     80
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'DED_RPE',       N'Régimen Prest. Empleo',             N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',                       N'LEGAL',     81
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'DED_FAOV',      N'Ley Vivienda (FAOV)',               N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                                   N'LEGAL',     82
  -- LOT · MENSUAL · Aportes patronales
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'CONTR_SSO',     N'Aporte Patronal SSO',              N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',                N'LEGAL',     96
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'CONTR_RPE',     N'Aporte Patronal RPE',              N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',                N'LEGAL',     97
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'CONTR_FAOV',    N'Aporte Patronal FAOV',             N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                           N'LEGAL',     98
  UNION ALL SELECT N'LOT',N'LOT',N'MENSUAL',N'CONTR_INCES',   N'Aporte Patronal INCES',            N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',                          N'LEGAL',     99
  -- LOT · VACACIONES
  UNION ALL SELECT N'LOT',N'LOT',N'VACACIONES',N'VAC_PAGO',   N'Pago Vacaciones',                  N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_VACACIONES',                                N'VACACION',  10
  UNION ALL SELECT N'LOT',N'LOT',N'VACACIONES',N'VAC_BONO',   N'Bono Vacacional',                  N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_BONO_VAC',                                  N'VACACION',  20
  -- LOT · LIQUIDACION
  UNION ALL SELECT N'LOT',N'LOT',N'LIQUIDACION',N'LIQ_PREST', N'Prestaciones Sociales',            N'ASIGNACION',0.00,N'SALARIO_DIARIO * PREST_DIAS_ANIO',                                N'LIQUIDACION',10
  UNION ALL SELECT N'LOT',N'LOT',N'LIQUIDACION',N'LIQ_VAC',   N'Vacaciones Pendientes',            N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_VACACIONES_BASE',                           N'LIQUIDACION',20
  UNION ALL SELECT N'LOT',N'LOT',N'LIQUIDACION',N'LIQ_UTIL',  N'Utilidades Pendientes',            N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_UTILIDADES_MIN',                            N'LIQUIDACION',30

  -- ==========================================================
  -- LOT_Q — LOTTT Quincenal
  -- SEMANAS_PERIODO runtime ≈ 2.1739 (26 períodos / año)
  -- Solo conceptos base (sin HE — se demuestran las frecuencias)
  -- ==========================================================
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'ASIG_BASE',  N'Sueldo Base',          N'ASIGNACION',0.00,N'SUELDO',                                               N'SALARIO',10
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'DED_SSO',    N'Seguro Social (SSO)',   N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',             N'LEGAL',  80
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'DED_RPE',    N'Régimen Prest. Empleo',N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',            N'LEGAL',  81
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'DED_FAOV',   N'Ley Vivienda (FAOV)',  N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                        N'LEGAL',  82
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'CONTR_SSO',  N'Aporte Patronal SSO',  N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',     N'LEGAL',  96
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'CONTR_RPE',  N'Aporte Patronal RPE',  N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',     N'LEGAL',  97
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'CONTR_FAOV', N'Aporte Patronal FAOV', N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                N'LEGAL',  98
  UNION ALL SELECT N'LOT_Q',N'LOT_Q',N'MENSUAL',N'CONTR_INCES',N'Aporte Patronal INCES',N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',               N'LEGAL',  99

  -- ==========================================================
  -- LOT_S — LOTTT Semanal
  -- SEMANAS_PERIODO runtime = 1 (52 períodos / año)
  -- ==========================================================
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'ASIG_BASE',  N'Sueldo Base',          N'ASIGNACION',0.00,N'SUELDO',                                               N'SALARIO',10
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'DED_SSO',    N'Seguro Social (SSO)',   N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',             N'LEGAL',  80
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'DED_RPE',    N'Régimen Prest. Empleo',N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',            N'LEGAL',  81
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'DED_FAOV',   N'Ley Vivienda (FAOV)',  N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                        N'LEGAL',  82
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'CONTR_SSO',  N'Aporte Patronal SSO',  N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',     N'LEGAL',  96
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'CONTR_RPE',  N'Aporte Patronal RPE',  N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',     N'LEGAL',  97
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'CONTR_FAOV', N'Aporte Patronal FAOV', N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                N'LEGAL',  98
  UNION ALL SELECT N'LOT_S',N'LOT_S',N'MENSUAL',N'CONTR_INCES',N'Aporte Patronal INCES',N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',               N'LEGAL',  99

  -- ==========================================================
  -- PETRO — CCT Petrolero Venezuela
  -- Base legal: IV Convenio Colectivo PDVSA / contratistas
  --   Cl.24 vacaciones (34d base), Cl.25 bono vac. (55d),
  --   Cl.30 utilidades (120d), Cl.40 alimentación campo,
  --   Cl.54 bono por herramienta, Cl.57 tiempo de viaje
  -- SEMANAS_PERIODO adaptado a frecuencia de pago configurada
  -- ==========================================================

  -- PETRO · MENSUAL · Asignaciones
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'ASIG_BASE',        N'Sueldo Base',                N'ASIGNACION',0.00,N'SUELDO',                                                             N'SALARIO',   10
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'BONO_PETRO',       N'Bono Especial Petróleo',     N'ASIGNACION',0.00,N'SALARIO_DIARIO * 10',                                                N'BONO',      20
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'BONO_AYUDA_CIUDAD',N'Ayuda de Ciudad',            N'ASIGNACION',0.00,N'SALARIO_DIARIO * 5',                                                 N'BONO',      21
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'IND_COMIDA',       N'Indemnización Comida',       N'ASIGNACION',0.00,N'PETRO_IND_COMIDA * DIAS_PERIODO',                                    N'BONO',      22
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'TIEMPO_VIAJE',     N'Tiempo de Viaje',            N'ASIGNACION',0.00,N'PETRO_HRS_VIAJE_DIA * DIAS_PERIODO * SALARIO_HORA',                  N'BONO',      23
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'BONO_HERRAMIENTA', N'Bono por Herramienta',       N'ASIGNACION',0.00,N'PETRO_BONO_HERR',                                                    N'BONO',      24
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'SOBRET_NOCTURNA',  N'Sobretiempo Nocturno',       N'ASIGNACION',0.00,N'HORAS_HE_N * SALARIO_HORA * RECARGO_HE * RECARGO_NOCTURNO',          N'HORA_EXTRA',40
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'HE_DIURNAS',       N'Horas Extras Diurnas',       N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * RECARGO_HE',                             N'HORA_EXTRA',41
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'DESC_TRABAJADO',   N'Descanso Trabajado',         N'ASIGNACION',0.00,N'DIAS_DESC * SALARIO_DIARIO * RECARGO_DESCANSO',                      N'HORA_EXTRA',42
  -- PETRO · MENSUAL · Deducciones
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'DED_SSO',          N'Seguro Social',              N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',                          N'LEGAL',     80
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'DED_RPE',          N'Paro Forzoso',               N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',                         N'LEGAL',     81
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'DED_FAOV',         N'Ley Vivienda',               N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                                     N'LEGAL',     82
  -- PETRO · MENSUAL · Aportes patronales
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'CONTR_SSO',        N'Aporte Patronal SSO',        N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     96
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'CONTR_RPE',        N'Aporte Patronal RPE',        N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     97
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'CONTR_FAOV',       N'Aporte Patronal FAOV',       N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                             N'LEGAL',     98
  UNION ALL SELECT N'PETRO',N'PETRO',N'MENSUAL',N'CONTR_INCES',      N'Aporte Patronal INCES',      N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',                            N'LEGAL',     99
  -- PETRO · VACACIONES (Cl.24: 34d base, Cl.25: bono 55d)
  UNION ALL SELECT N'PETRO',N'PETRO',N'VACACIONES',N'VAC_PAGO',      N'Pago Vacaciones (34d)',      N'ASIGNACION',0.00,N'SALARIO_DIARIO * PETRO_DIAS_VACACIONES_BASE',                       N'VACACION',  10
  UNION ALL SELECT N'PETRO',N'PETRO',N'VACACIONES',N'VAC_BONO',      N'Bono Vacacional (55d)',      N'ASIGNACION',0.00,N'SALARIO_DIARIO * PETRO_DIAS_BONO_VAC_BASE',                         N'VACACION',  20
  -- PETRO · LIQUIDACION
  UNION ALL SELECT N'PETRO',N'PETRO',N'LIQUIDACION',N'LIQ_PREST',    N'Prestaciones Sociales',      N'ASIGNACION',0.00,N'SALARIO_DIARIO * PREST_DIAS_ANIO',                                  N'LIQUIDACION',10
  UNION ALL SELECT N'PETRO',N'PETRO',N'LIQUIDACION',N'LIQ_VAC',      N'Vacaciones Pendientes',      N'ASIGNACION',0.00,N'SALARIO_DIARIO * PETRO_DIAS_VACACIONES_BASE',                       N'LIQUIDACION',20
  UNION ALL SELECT N'PETRO',N'PETRO',N'LIQUIDACION',N'LIQ_UTIL',     N'Utilidades (120d)',           N'ASIGNACION',0.00,N'SALARIO_DIARIO * PETRO_DIAS_UTILIDADES',                            N'LIQUIDACION',30

  -- ==========================================================
  -- CONST — CCT Construcción Venezuela
  -- Base legal: CCT CAMARA/FETRACON vigente
  --   Cl.zona: factor zona geográfica sobre salario base
  --   Cl.material: bono mensual herramienta/material
  --   Cl.distancia: tarifa km × días período × 2 (ida y vuelta)
  --   Cl.peligrosidad: % adicional configurable por actividad
  -- Vacaciones: 20d base (LOTTT + CCT); utilidades 60d
  -- ==========================================================

  -- CONST · MENSUAL · Asignaciones
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'ASIG_BASE',      N'Sueldo Base',                N'ASIGNACION',0.00,N'SUELDO',                                                             N'SALARIO',   10
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'BONO_ZONA',      N'Bono de Zona Geográfica',    N'ASIGNACION',0.00,N'SUELDO * CONST_FACTOR_ZONA - SUELDO',                                N'BONO',      20
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'BONO_MATERIAL',  N'Bono por Material',          N'ASIGNACION',0.00,N'CONST_BONO_MATERIAL',                                                N'BONO',      21
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'DIST_OBRA',      N'Distancia a Obra',           N'ASIGNACION',0.00,N'CONST_TARIFA_DIST * DIAS_PERIODO * 2',                               N'BONO',      22
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'TRAB_PELIGROSO', N'Trabajo Peligroso',          N'ASIGNACION',0.00,N'SUELDO * CONST_PCT_PELIGRO',                                         N'BONO',      23
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'HE_DIURNAS',     N'Horas Extras Diurnas',       N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * RECARGO_HE',                             N'HORA_EXTRA',40
  -- CONST · MENSUAL · Deducciones
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'DED_SSO',        N'Seguro Social',              N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',                          N'LEGAL',     80
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'DED_RPE',        N'Paro Forzoso',               N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',                         N'LEGAL',     81
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'DED_FAOV',       N'Ley Vivienda',               N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                                     N'LEGAL',     82
  -- CONST · MENSUAL · Aportes patronales
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'CONTR_SSO',      N'Aporte Patronal SSO',        N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     96
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'CONTR_RPE',      N'Aporte Patronal RPE',        N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     97
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'CONTR_FAOV',     N'Aporte Patronal FAOV',       N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                             N'LEGAL',     98
  UNION ALL SELECT N'CONST',N'CONST',N'MENSUAL',N'CONTR_INCES',    N'Aporte Patronal INCES',      N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',                            N'LEGAL',     99
  -- CONST · VACACIONES (20d base CCT)
  UNION ALL SELECT N'CONST',N'CONST',N'VACACIONES',N'VAC_PAGO',    N'Vacaciones (20d)',           N'ASIGNACION',0.00,N'SALARIO_DIARIO * CONST_DIAS_VACACIONES_BASE',                       N'VACACION',  10
  -- CONST · LIQUIDACION
  UNION ALL SELECT N'CONST',N'CONST',N'LIQUIDACION',N'LIQ_PREST',  N'Prestaciones Sociales',     N'ASIGNACION',0.00,N'SALARIO_DIARIO * PREST_DIAS_ANIO',                                  N'LIQUIDACION',10
  UNION ALL SELECT N'CONST',N'CONST',N'LIQUIDACION',N'LIQ_UTIL',   N'Utilidades (60d)',           N'ASIGNACION',0.00,N'SALARIO_DIARIO * CONST_DIAS_UTILIDADES',                            N'LIQUIDACION',30

  -- ==========================================================
  -- ADMIN — Nómina Administrativa Venezuela
  -- Base legal: LOTTT art.105 (empleados), reglamento LOTTT
  -- Conceptos esenciales; SSO/RPE/FAOV con topes idénticos a LOT
  -- ==========================================================

  -- ADMIN · MENSUAL · Asignaciones
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'ASIG_BASE',      N'Sueldo Base',                N'ASIGNACION',0.00,N'SUELDO',                                                             N'SALARIO',   10
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'BONO_ALIM',      N'Bono de Alimentación',       N'ASIGNACION',0.00,N'0',                                                                  N'BONO',      20
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'HE_DIURNAS',     N'Horas Extras Diurnas',       N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * RECARGO_HE',                             N'HORA_EXTRA',30
  -- ADMIN · MENSUAL · Deducciones
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'DED_SSO',        N'Seguro Social (SSO)',        N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',                          N'LEGAL',     80
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'DED_RPE',        N'Régimen Prest. Empleo',      N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',                         N'LEGAL',     81
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'DED_FAOV',       N'Ley Vivienda (FAOV)',        N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                                     N'LEGAL',     82
  -- ADMIN · MENSUAL · Aportes patronales
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'CONTR_SSO',      N'Aporte Patronal SSO',        N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     96
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'CONTR_RPE',      N'Aporte Patronal RPE',        N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     97
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'MENSUAL',N'CONTR_FAOV',     N'Aporte Patronal FAOV',       N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                             N'LEGAL',     98
  -- ADMIN · VACACIONES
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'VACACIONES',N'VAC_PAGO',    N'Pago Vacaciones',            N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_VACACIONES',                                  N'VACACION',  10
  -- ADMIN · LIQUIDACION
  UNION ALL SELECT N'ADMIN',N'ADMIN',N'LIQUIDACION',N'LIQ_PREST',  N'Prestaciones Sociales',     N'ASIGNACION',0.00,N'SALARIO_DIARIO * PREST_DIAS_ANIO',                                  N'LIQUIDACION',10

  -- ==========================================================
  -- TRANSP — Nómina Transporte Venezuela
  -- Base legal: CCT transporte terrestre / LOTTT
  -- Placeholder con conceptos básicos LOTTT; extensible con
  -- cláusulas específicas del contrato colectivo de transporte.
  -- ==========================================================

  -- TRANSP · MENSUAL · Asignaciones
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'ASIG_BASE',    N'Sueldo Base',                N'ASIGNACION',0.00,N'SUELDO',                                                             N'SALARIO',   10
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'BONO_ALIM',    N'Bono de Alimentación',       N'ASIGNACION',0.00,N'0',                                                                  N'BONO',      20
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'BONO_TRANS',   N'Bono de Transporte',         N'ASIGNACION',0.00,N'0',                                                                  N'BONO',      30
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'HE_DIURNAS',   N'Horas Extras Diurnas',       N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * RECARGO_HE',                             N'HORA_EXTRA',40
  -- TRANSP · MENSUAL · Deducciones
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'DED_SSO',      N'Seguro Social (SSO)',        N'DEDUCCION', 0.00,N'TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO',                          N'LEGAL',     80
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'DED_RPE',      N'Régimen Prest. Empleo',      N'DEDUCCION', 0.00,N'TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO',                         N'LEGAL',     81
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'DED_FAOV',     N'Ley Vivienda (FAOV)',        N'DEDUCCION', 0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV',                                     N'LEGAL',     82
  -- TRANSP · MENSUAL · Aportes patronales
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'CONTR_SSO',    N'Aporte Patronal SSO',        N'PATRONAL',  0.00,N'TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     96
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'CONTR_RPE',    N'Aporte Patronal RPE',        N'PATRONAL',  0.00,N'TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO',                  N'LEGAL',     97
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'CONTR_FAOV',   N'Aporte Patronal FAOV',       N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO',                             N'LEGAL',     98
  UNION ALL SELECT N'TRANSP',N'TRANSP',N'MENSUAL',N'CONTR_INCES',  N'Aporte Patronal INCES',      N'PATRONAL',  0.00,N'TOTAL_ASIGNACIONES * PCT_INCES_PATRONO',                            N'LEGAL',     99

  -- ==========================================================
  -- ES_GENERAL — España (General)
  -- Base legal: RDL 8/2015 LGSS, ET (RDL 2/2015), LIRPF L.35/2006
  -- Cotización 2024 referencia — verificar tabla TGSS cada año
  -- ES_PCT_SS_EMP = CC 4.70% + Desemp 1.55% + FP 0.10% = 6.35%
  -- ES_PCT_SS_PAT = CC 23.60% + Desemp 5.50% + FOGASA 0.20% + FP 0.60%
  -- HE fuerza mayor: ET art.47.2 bis (límite 80h/año)
  -- HE voluntarias:  ET art.35.2 (límite 80h/año)
  -- IRPF: retención referencia; calcular por tramo AEAT art.86 RIRPF
  -- ==========================================================

  -- ES_GENERAL · MENSUAL · Asignaciones
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'ASIG_BASE',         N'Sueldo Base Bruto',             N'ASIGNACION',0.00,N'SUELDO',                                            N'SALARIO',   10
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'PLUS_TRANSPORTE',    N'Plus Transporte',               N'ASIGNACION',0.00,N'0',                                                 N'BONO',      20
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'PLUS_COMIDA',        N'Plus Dietas',                   N'ASIGNACION',0.00,N'0',                                                 N'BONO',      21
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'HE_FUERZA_MAYOR',   N'HE Fuerza Mayor',               N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * 1.75',                 N'HORA_EXTRA',30
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'HE_VOLUNTARIAS',    N'HE Voluntarias',                N'ASIGNACION',0.00,N'HORAS_HE_V * SALARIO_HORA * 1.25',                 N'HORA_EXTRA',31
  -- ES_GENERAL · MENSUAL · Deducciones
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'DED_IRPF',          N'Retención IRPF',                N'DEDUCCION', 0.00,N'SUELDO * ES_PCT_IRPF',                             N'LEGAL',     80
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'DED_SS_CC',         N'SS Contingencias Comunes',      N'DEDUCCION', 0.00,N'SUELDO * ES_PCT_CC_EMP',                           N'LEGAL',     81
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'DED_SS_DESEMP',     N'SS Desempleo Empleado',         N'DEDUCCION', 0.00,N'SUELDO * ES_PCT_DESEMP_EMP',                       N'LEGAL',     82
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'DED_SS_FP',         N'SS Formación Profesional',      N'DEDUCCION', 0.00,N'SUELDO * ES_PCT_FP_EMP',                           N'LEGAL',     83
  -- ES_GENERAL · MENSUAL · Aportes patronales
  UNION ALL SELECT N'ES_GENERAL',N'ES_GENERAL',N'MENSUAL',N'CONTR_SS_PAT',      N'SS Patrono Total',              N'PATRONAL',  0.00,N'SUELDO * ES_PCT_SS_PAT',                           N'LEGAL',     96

  -- ==========================================================
  -- MX_GENERAL — México (General)
  -- Base legal: LSS arts.25-36 (IMSS), LINFONAVIT art.29 (5%),
  --   LISR art.96 (ISR), LFT art.80 (prima vac. 25%),
  --   SAR L.72-190 (2% patrono)
  -- SDI = salario_diario × MX_FACTOR_INTEG (usado en bases IMSS)
  -- HE diurnas: LFT art.67 (doble pago = ×2 salario hora)
  -- MX_PCT_ISR = 0 base; aplicar tabla LISR art.96 por tramo
  -- ==========================================================

  -- MX_GENERAL · MENSUAL · Asignaciones
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'ASIG_BASE',         N'Sueldo Base',                   N'ASIGNACION',0.00,N'SUELDO',                                            N'SALARIO',   10
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'HE_DIURNAS',        N'HE Diurnas',                    N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * 2',                    N'HORA_EXTRA',30
  -- MX_GENERAL · MENSUAL · Deducciones
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'DED_IMSS',          N'IMSS Empleado',                 N'DEDUCCION', 0.00,N'SUELDO * MX_PCT_IMSS_EMP',                        N'LEGAL',     80
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'DED_ISR',           N'Retención ISR',                 N'DEDUCCION', 0.00,N'SUELDO * MX_PCT_ISR',                             N'LEGAL',     81
  -- MX_GENERAL · MENSUAL · Aportes patronales
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'CONTR_IMSS_PAT',    N'IMSS Patrono',                  N'PATRONAL',  0.00,N'SUELDO * MX_PCT_IMSS_PAT',                        N'LEGAL',     96
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'CONTR_INFONAVIT',   N'INFONAVIT',                     N'PATRONAL',  0.00,N'SUELDO * MX_PCT_INFONAVIT',                       N'LEGAL',     97
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'MENSUAL',N'CONTR_SAR',         N'SAR',                           N'PATRONAL',  0.00,N'SUELDO * MX_PCT_SAR',                             N'LEGAL',     98
  -- MX_GENERAL · VACACIONES (LFT art.76: 12d base + prima 25%)
  UNION ALL SELECT N'MX_GENERAL',N'MX_GENERAL',N'VACACIONES',N'PRIMA_VAC',      N'Prima Vacacional (25%)',        N'ASIGNACION',0.00,N'SALARIO_DIARIO * DIAS_VACACIONES * 0.25',          N'VACACION',  20

  -- ==========================================================
  -- CO_GENERAL — Colombia (General)
  -- Base legal: L.100/1993 (salud 12.5% / pensión 16%),
  --   D.1295/1994 + L.1562/2012 (ARL), L.789/2002 (caja 4%),
  --   L.21/1982 (SENA 2%, ICBF 3%), L.1607/2012 art.25 exonera
  --   SENA+ICBF a empleadores con trabajadores < 10 SMLMV
  -- HE diurnas (L.789/2002): +25% sobre valor hora ordinaria
  -- HE nocturnas: +75% sobre valor hora ordinaria
  -- Parafiscales: SENA 2% + ICBF 3% + Caja 4% = 9%
  -- ==========================================================

  -- CO_GENERAL · MENSUAL · Asignaciones
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'ASIG_BASE',         N'Sueldo Base',                   N'ASIGNACION',0.00,N'SUELDO',                                            N'SALARIO',   10
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'AUXILIO_TRANS',      N'Auxilio de Transporte',         N'ASIGNACION',0.00,N'0',                                                 N'BONO',      20
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'HE_DIURNAS',         N'HE Diurnas',                    N'ASIGNACION',0.00,N'HORAS_HE_D * SALARIO_HORA * 1.25',                 N'HORA_EXTRA',30
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'HE_NOCTURNAS',       N'HE Nocturnas',                  N'ASIGNACION',0.00,N'HORAS_HE_N * SALARIO_HORA * 1.75',                 N'HORA_EXTRA',31
  -- CO_GENERAL · MENSUAL · Deducciones
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'DED_SALUD',          N'Salud Empleado (4%)',           N'DEDUCCION', 0.00,N'SUELDO * CO_PCT_SALUD_EMP',                       N'LEGAL',     80
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'DED_PENSION',        N'Pensión Empleado (4%)',         N'DEDUCCION', 0.00,N'SUELDO * CO_PCT_PENSION_EMP',                     N'LEGAL',     81
  -- CO_GENERAL · MENSUAL · Aportes patronales
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'CONTR_SALUD_PAT',    N'Salud Patrono (8.5%)',          N'PATRONAL',  0.00,N'SUELDO * CO_PCT_SALUD_PAT',                       N'LEGAL',     96
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'CONTR_PENSION_PAT',  N'Pensión Patrono (12%)',         N'PATRONAL',  0.00,N'SUELDO * CO_PCT_PENSION_PAT',                     N'LEGAL',     97
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'CONTR_ARL',          N'ARL (riesgo ocupacional)',      N'PATRONAL',  0.00,N'SUELDO * CO_PCT_ARL',                             N'LEGAL',     98
  UNION ALL SELECT N'CO_GENERAL',N'CO_GENERAL',N'MENSUAL',N'CONTR_PARAFISCALES', N'Parafiscales (SENA+ICBF+Caja)',N'PATRONAL',  0.00,N'SUELDO * (CO_PCT_SENA + CO_PCT_ICBF + CO_PCT_CAJA)',N'LEGAL',    99
)
MERGE hr.PayrollConcept AS target
USING SourceRows AS src
ON target.CompanyId    = @CompanyId
   AND target.PayrollCode   = src.PayrollCode
   AND target.ConceptCode   = src.ConceptCode
   AND ISNULL(target.ConventionCode,  N'') = ISNULL(src.ConventionCode,  N'')
   AND ISNULL(target.CalculationType, N'') = ISNULL(src.CalculationType, N'')
WHEN MATCHED THEN
  UPDATE SET
    ConceptName          = src.ConceptName,
    Formula              = src.Formula,
    BaseExpression       = NULL,
    ConceptClass         = src.ConceptClass,
    ConceptType          = src.ConceptType,
    UsageType            = N'T',
    IsBonifiable         = CASE WHEN src.ConceptType = N'ASIGNACION' THEN 1 ELSE 0 END,
    IsSeniority          = 0,
    AccountingAccountCode= NULL,
    AppliesFlag          = 1,
    DefaultValue         = src.DefaultValue,
    SortOrder            = src.SortOrder,
    IsActive             = 1,
    UpdatedAt            = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (
    CompanyId, PayrollCode, ConceptCode, ConceptName, Formula, BaseExpression,
    ConceptClass, ConceptType, UsageType, IsBonifiable, IsSeniority,
    AccountingAccountCode, AppliesFlag, DefaultValue, ConventionCode,
    CalculationType, LotttArticle, CcpClause, SortOrder, IsActive,
    CreatedAt, UpdatedAt
  )
  VALUES (
    @CompanyId, src.PayrollCode, src.ConceptCode, src.ConceptName, src.Formula, NULL,
    src.ConceptClass, src.ConceptType, N'T',
    CASE WHEN src.ConceptType = N'ASIGNACION' THEN 1 ELSE 0 END, 0,
    NULL, 1, src.DefaultValue, src.ConventionCode,
    src.CalculationType, NULL, NULL, src.SortOrder, 1,
    SYSUTCDATETIME(), SYSUTCDATETIME()
  );

PRINT 'Tipos de nómina y conceptos por convenio sembrados/actualizados en hr.PayrollType + hr.PayrollConcept';
GO
