-- =============================================
-- SEMILLA DE CONSTANTES NÓMINA (CANÓNICO)
-- Cubre: Venezuela base, VE patronal, CCT Petrolero,
--        CCT Construcción, España (ES), México (MX),
--        Colombia (CO)
-- Base legal VE: LOTTT 2012 + RLOT, LSS/RLSS,
--   LRPE, LAOVSS, INCES Ley 1970; España: RDL 8/2015 LGSS;
--   México: LSS, LINFONAVIT, LISR; Colombia: L.100/1993,
--   L.789/2002, L.1607/2012 (parafiscales).
-- IMPORTANTE: Tasas de aporte patronal VE y retenciones
--   ES/MX/CO deben revisarse con cada decreto / BOE / DOF / Diario Oficial.
-- =============================================
SET NOCOUNT ON;
GO

DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
  THROW 50011, 'No existe cfg.Company activa para sembrar constantes nómina', 1;

;WITH SourceRows AS (

  -- =========================================================
  -- VE_BASE: Constantes base Venezuela (LOTTT / LOPCYMAT)
  -- =========================================================
  SELECT N'SALARIO_DIARIO'         AS ConstantCode, N'Salario diario base'                   AS ConstantName, CAST(0.00       AS DECIMAL(18,6)) AS ConstantValue, N'VE_BASE' AS SourceName
  UNION ALL SELECT N'HORAS_MES',          N'Horas laborales mensuales',            240.000000, N'VE_BASE'
  UNION ALL SELECT N'PCT_SSO',            N'Porcentaje SSO empleado',              0.040000,   N'VE_BASE'
  UNION ALL SELECT N'PCT_FAOV',           N'Porcentaje FAOV empleado',             0.010000,   N'VE_BASE'
  UNION ALL SELECT N'PCT_LRPE',           N'Porcentaje LRPE empleado',             0.005000,   N'VE_BASE'
  UNION ALL SELECT N'RECARGO_HE',         N'Recargo hora extra',                   1.500000,   N'VE_BASE'
  UNION ALL SELECT N'RECARGO_NOCTURNO',   N'Recargo nocturno',                     1.300000,   N'VE_BASE'
  UNION ALL SELECT N'RECARGO_DESCANSO',   N'Recargo descanso trabajado',           1.500000,   N'VE_BASE'
  UNION ALL SELECT N'RECARGO_FERIADO',    N'Recargo feriado trabajado',            2.000000,   N'VE_BASE'
  UNION ALL SELECT N'DIAS_VACACIONES_BASE',  N'Días vacaciones base',             15.000000,   N'VE_BASE'
  UNION ALL SELECT N'DIAS_BONO_VAC_BASE', N'Días bono vacacional base',           15.000000,   N'VE_BASE'
  UNION ALL SELECT N'DIAS_UTILIDADES_MIN',N'Días utilidades mínimo',              30.000000,   N'VE_BASE'
  UNION ALL SELECT N'DIAS_UTILIDADES_MAX',N'Días utilidades máximo',             120.000000,   N'VE_BASE'
  UNION ALL SELECT N'PREST_DIAS_ANIO',    N'Días prestaciones por año',           30.000000,   N'VE_BASE'
  UNION ALL SELECT N'PREST_INTERES_ANUAL',N'Interés anual prestaciones',           0.150000,   N'VE_BASE'

  -- =========================================================
  -- VE_PATRONAL: Aportes patronales SSO/RPE/FAOV/INCES
  -- Refs: RLSS art.62 (SSO 9-11 s/min), LRPE art.49,
  --       LAOVSS art.30 (FAOV 2%), INCES art.10 (2%)
  -- SUELDO_MIN: actualizar con cada decreto salarial del BCV/MPPPST
  -- TOPE_SSO: art.62 RLSS = 5 salarios mínimos
  -- TOPE_RPE: art.49 LRPE = 10 salarios mínimos
  -- =========================================================
  UNION ALL SELECT N'SUELDO_MIN',         N'Salario mínimo mensual (actualizar con decreto)',  0.000000, N'VE_PATRONAL'
  UNION ALL SELECT N'PCT_SSO_PATRONO',    N'Aporte patronal SSO (mín 9%, med 10%, máx 11%)',  0.110000, N'VE_PATRONAL'
  UNION ALL SELECT N'PCT_RPE_PATRONO',    N'Aporte patronal RPE/paro forzoso',                0.020000, N'VE_PATRONAL'
  UNION ALL SELECT N'PCT_FAOV_PATRONO',   N'Aporte patronal FAOV/vivienda',                   0.020000, N'VE_PATRONAL'
  UNION ALL SELECT N'PCT_INCES_PATRONO',  N'Aporte patronal INCES',                           0.020000, N'VE_PATRONAL'
  UNION ALL SELECT N'TOPE_SSO',           N'Tope SSO en salarios mínimos (art.62 RLSS)',       5.000000, N'VE_PATRONAL'
  UNION ALL SELECT N'TOPE_RPE',           N'Tope RPE en salarios mínimos (art.49 LRPE)',      10.000000, N'VE_PATRONAL'
  UNION ALL SELECT N'SEMANAS_ANO',        N'Semanas por año',                                 52.000000, N'VE_PATRONAL'

  -- =========================================================
  -- REGIMEN:LOT — Vacaciones y utilidades LOTTT
  -- =========================================================
  UNION ALL SELECT N'LOT_DIAS_VACACIONES_BASE', N'LOTTT: días vacaciones base',    15.000000, N'REGIMEN:LOT'
  UNION ALL SELECT N'LOT_DIAS_BONO_VAC_BASE',   N'LOTTT: días bono vacacional base', 15.000000, N'REGIMEN:LOT'
  UNION ALL SELECT N'LOT_DIAS_UTILIDADES',       N'LOTTT: días utilidades referencia', 30.000000, N'REGIMEN:LOT'

  -- =========================================================
  -- REGIMEN:PETRO_CCT — CCT Petrolero (PDVSA / IV CCT)
  -- Refs: Cláusulas 24 (vacaciones 34d), 25 (bono 55d),
  --       30 (utilidades 120d), 40 (comida), 54 (herramienta)
  -- Valores monetarios en 0 — configurar por empresa/acuerdo
  -- =========================================================
  UNION ALL SELECT N'PETRO_DIAS_VACACIONES_BASE', N'Petrolero: días vacaciones base',    34.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_DIAS_BONO_VAC_BASE',   N'Petrolero: bono vacacional base',    55.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_DIAS_UTILIDADES',       N'Petrolero: días utilidades (cl.30)', 120.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_IND_COMIDA',     N'Indemniz. diaria comida CCT petróleo (configurar)',  0.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_BONO_HERR',      N'Bono herramienta mensual CCT petróleo (configurar)', 0.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_TARIFA_KM',      N'Tarifa por km distancia obra/planta (configurar)',   0.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_HRS_VIAJE_DIA',  N'Horas de viaje reconocidas por día (configurar)',    0.000000, N'REGIMEN:PETRO_CCT'
  UNION ALL SELECT N'PETRO_DIAS_CAMPO',     N'Días de campo por período (configurar)',             0.000000, N'REGIMEN:PETRO_CCT'

  -- =========================================================
  -- REGIMEN:CONST_CCT — CCT Construcción (CAMARA/FETRACON)
  -- Refs: Cláusulas zona geográfica, bono material, distancia
  -- CONST_PCT_PELIGRO: varía por actividad (0% a ~25%)
  -- =========================================================
  UNION ALL SELECT N'CONST_DIAS_VACACIONES_BASE', N'Construcción: días vacaciones base',  20.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_DIAS_BONO_VAC_BASE',   N'Construcción: bono vacacional base',  30.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_DIAS_UTILIDADES',       N'Construcción: días utilidades (60d)', 60.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_FACTOR_ZONA',   N'Factor zona geográfica (1.0=ninguno, configurar)', 1.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_BONO_MATERIAL', N'Bono material mensual (configurar)',                0.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_TARIFA_DIST',   N'Tarifa distancia obra por km (configurar)',         0.000000, N'REGIMEN:CONST_CCT'
  UNION ALL SELECT N'CONST_PCT_PELIGRO',   N'% adicional trabajo peligroso (configurar)',        0.000000, N'REGIMEN:CONST_CCT'

  -- =========================================================
  -- REGIMEN:ES — España (RDL 8/2015 LGSS + LISOS)
  -- Bases 2024 referencia — verificar tabla cotización TGSS
  -- ES_PCT_SS_EMP = CC 4.70% + Desemp 1.55% + FP 0.10% = 6.35%
  -- ES_PCT_SS_PAT = CC 23.60% + Desemp 5.50% + FOGASA 0.20% + FP 0.60% = 29.90%
  -- ES_PCT_IRPF: retención de referencia; calcular por tramo AEAT
  -- =========================================================
  UNION ALL SELECT N'ES_PCT_SS_EMP',     N'SS empleado total (CC+Desemp+FP)',             0.063500, N'REGIMEN:ES'
  UNION ALL SELECT N'ES_PCT_CC_EMP',     N'SS empleado contingencias comunes (4.70%)',    0.047000, N'REGIMEN:ES'
  UNION ALL SELECT N'ES_PCT_DESEMP_EMP', N'SS empleado desempleo (1.55%)',                0.015500, N'REGIMEN:ES'
  UNION ALL SELECT N'ES_PCT_FP_EMP',     N'SS empleado formación profesional (0.10%)',    0.001000, N'REGIMEN:ES'
  UNION ALL SELECT N'ES_PCT_SS_PAT',     N'SS patrono total (CC+Desemp+FOGASA+FP)',       0.299000, N'REGIMEN:ES'
  UNION ALL SELECT N'ES_PCT_IRPF',       N'IRPF retención referencia (configur. por tramo)', 0.150000, N'REGIMEN:ES'

  -- =========================================================
  -- REGIMEN:MX — México (LSS 2024, LINFONAVIT, SAR)
  -- MX_PCT_IMSS_EMP ≈ Enf/Mat 0.40%+GMP 1.125%+Inv/Vid 0.625%≈2.04%
  -- MX_PCT_IMSS_PAT ≈ Enf/Mat 1.05%+GMP 7.35%+Ret/Ces 3.15%+RCCP...≈8.87%
  -- MX_FACTOR_INTEG: SDI = salario_diario × factor_integ
  -- MX_PCT_ISR = 0 base; calcular por tabla anual LISR art.96
  -- =========================================================
  UNION ALL SELECT N'MX_PCT_IMSS_EMP',   N'IMSS empleado Enf/Mat+Inv/Vid (~2.04%)',       0.020400, N'REGIMEN:MX'
  UNION ALL SELECT N'MX_PCT_IMSS_PAT',   N'IMSS patrono total (~8.87%)',                  0.088700, N'REGIMEN:MX'
  UNION ALL SELECT N'MX_PCT_INFONAVIT',  N'INFONAVIT patrono (5%)',                       0.050000, N'REGIMEN:MX'
  UNION ALL SELECT N'MX_PCT_SAR',        N'SAR patrono (2%)',                              0.020000, N'REGIMEN:MX'
  UNION ALL SELECT N'MX_PCT_ISR',        N'ISR empleado (varía por tramo, base 0)',        0.000000, N'REGIMEN:MX'
  UNION ALL SELECT N'MX_FACTOR_INTEG',   N'Factor integración SDI (1+prima_vac×bono/365)', 1.045200, N'REGIMEN:MX'

  -- =========================================================
  -- REGIMEN:CO — Colombia (L.100/1993, L.789/2002, L.1607/2012)
  -- CO_PCT_ARL: riesgo clase I 0.348% — ajustar por clase (I-V)
  -- Parafiscales: SENA 2% + ICBF 3% + Caja 4% = 9%
  --   (exonerados si salario < 10 SMLMV desde L.1607/2012 art.25
  --    salvo Caja que siempre aplica)
  -- =========================================================
  UNION ALL SELECT N'CO_PCT_SALUD_EMP',     N'Salud empleado (4%)',                      0.040000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_PENSION_EMP',   N'Pensión empleado (4%)',                    0.040000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_SALUD_PAT',     N'EPS patrono (8.5%)',                       0.085000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_PENSION_PAT',   N'AFP patrono (12%)',                        0.120000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_ARL',           N'ARL patrono riesgo clase I (0.348%)',      0.003480, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_CAJA',          N'Caja de compensación patrono (4%)',        0.040000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_SENA',          N'SENA patrono (2%)',                        0.020000, N'REGIMEN:CO'
  UNION ALL SELECT N'CO_PCT_ICBF',          N'ICBF patrono (3%)',                        0.030000, N'REGIMEN:CO'
)
MERGE hr.PayrollConstant AS target
USING SourceRows AS src
ON target.CompanyId = @CompanyId
   AND target.ConstantCode = src.ConstantCode
WHEN MATCHED THEN
  UPDATE SET
    ConstantName  = src.ConstantName,
    ConstantValue = src.ConstantValue,
    SourceName    = src.SourceName,
    IsActive      = 1,
    UpdatedAt     = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (CompanyId, ConstantCode, ConstantName, ConstantValue, SourceName, IsActive, CreatedAt, UpdatedAt)
  VALUES (@CompanyId, src.ConstantCode, src.ConstantName, src.ConstantValue, src.SourceName, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT 'Constantes de nómina (VE/ES/MX/CO) sembradas/actualizadas en hr.PayrollConstant';
GO
