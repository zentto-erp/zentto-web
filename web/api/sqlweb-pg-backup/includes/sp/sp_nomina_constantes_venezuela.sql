-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_nomina_constantes_venezuela.sql
-- Semilla de constantes nómina Venezuela (canónico).
-- Inserta o actualiza constantes en hr.PayrollConstant.
-- ============================================================

DO $$
DECLARE
    v_company_id INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'No existe cfg.Company activa para sembrar constantes nómina';
    END IF;

    -- Usar INSERT ... ON CONFLICT para simular MERGE
    -- Primero crear tabla temporal con los datos fuente
    CREATE TEMP TABLE tmp_constantes_ve (
        "ConstantCode"  VARCHAR(50),
        "ConstantName"  VARCHAR(120),
        "ConstantValue" NUMERIC(18,6),
        "SourceName"    VARCHAR(80)
    ) ON COMMIT DROP;

    INSERT INTO tmp_constantes_ve VALUES
        ('SALARIO_DIARIO',              'Salario diario base',                    0.000000,   'VE_BASE'),
        ('HORAS_MES',                   'Horas laborales mensuales',            240.000000,   'VE_BASE'),
        ('PCT_SSO',                     'Porcentaje SSO empleado',                0.040000,   'VE_BASE'),
        ('PCT_FAOV',                    'Porcentaje FAOV empleado',               0.010000,   'VE_BASE'),
        ('PCT_LRPE',                    'Porcentaje LRPE empleado',               0.005000,   'VE_BASE'),
        ('RECARGO_HE',                  'Recargo hora extra',                     1.500000,   'VE_BASE'),
        ('RECARGO_NOCTURNO',            'Recargo nocturno',                       1.300000,   'VE_BASE'),
        ('RECARGO_DESCANSO',            'Recargo descanso trabajado',             1.500000,   'VE_BASE'),
        ('RECARGO_FERIADO',             'Recargo feriado trabajado',              2.000000,   'VE_BASE'),
        ('DIAS_VACACIONES_BASE',        'Días vacaciones base',                  15.000000,   'VE_BASE'),
        ('DIAS_BONO_VAC_BASE',          'Días bono vacacional base',             15.000000,   'VE_BASE'),
        ('DIAS_UTILIDADES_MIN',         'Días utilidades mínimo',                30.000000,   'VE_BASE'),
        ('DIAS_UTILIDADES_MAX',         'Días utilidades máximo',               120.000000,   'VE_BASE'),
        ('PREST_DIAS_ANIO',             'Días prestaciones por año',             30.000000,   'VE_BASE'),
        ('PREST_INTERES_ANUAL',         'Interés anual prestaciones',             0.150000,   'VE_BASE'),

        ('LOT_DIAS_VACACIONES_BASE',    'LOTTT: días vacaciones base',           15.000000,   'REGIMEN:LOT'),
        ('LOT_DIAS_BONO_VAC_BASE',      'LOTTT: días bono vacacional base',      15.000000,   'REGIMEN:LOT'),
        ('LOT_DIAS_UTILIDADES',          'LOTTT: días utilidades referencia',     30.000000,   'REGIMEN:LOT'),

        ('PETRO_DIAS_VACACIONES_BASE',  'Petrolero: días vacaciones base',       34.000000,   'REGIMEN:PETRO'),
        ('PETRO_DIAS_BONO_VAC_BASE',    'Petrolero: bono vacacional base',       55.000000,   'REGIMEN:PETRO'),
        ('PETRO_DIAS_UTILIDADES',        'Petrolero: días utilidades',           120.000000,   'REGIMEN:PETRO'),

        ('CONST_DIAS_VACACIONES_BASE',  'Construcción: días vacaciones base',    20.000000,   'REGIMEN:CONST'),
        ('CONST_DIAS_BONO_VAC_BASE',    'Construcción: bono vacacional base',    30.000000,   'REGIMEN:CONST'),
        ('CONST_DIAS_UTILIDADES',        'Construcción: días utilidades',         60.000000,   'REGIMEN:CONST');

    -- Actualizar existentes
    UPDATE hr."PayrollConstant" pc
    SET "ConstantName"  = src."ConstantName",
        "ConstantValue" = src."ConstantValue",
        "SourceName"    = src."SourceName",
        "IsActive"      = TRUE,
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    FROM tmp_constantes_ve src
    WHERE pc."CompanyId"    = v_company_id
      AND pc."ConstantCode" = src."ConstantCode";

    -- Insertar nuevos
    INSERT INTO hr."PayrollConstant"
        ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName",
         "IsActive", "CreatedAt", "UpdatedAt")
    SELECT
        v_company_id,
        src."ConstantCode",
        src."ConstantName",
        src."ConstantValue",
        src."SourceName",
        TRUE,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM tmp_constantes_ve src
    WHERE NOT EXISTS (
        SELECT 1 FROM hr."PayrollConstant" pc
        WHERE pc."CompanyId" = v_company_id
          AND pc."ConstantCode" = src."ConstantCode"
    );

    RAISE NOTICE 'Constantes de nómina Venezuela sembradas/actualizadas en hr.PayrollConstant';
END;
$$;
