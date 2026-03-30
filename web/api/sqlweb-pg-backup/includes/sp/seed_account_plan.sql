-- =============================================
-- seed_account_plan.sql (modelo canonico) - PostgreSQL
-- Tabla destino: acct."Account"
-- Idempotente por "CompanyId" + "AccountCode"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DO $$
DECLARE
    v_company_id INT;
    v_system_user_id INT;
    v_total INT;
BEGIN
    -- Verificar tabla
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'Account') THEN
        RAISE NOTICE 'ERROR: Tabla acct."Account" no existe. Ejecutar primero 03_accounting_core.sql';
        RETURN;
    END IF;

    SELECT "CompanyId" INTO v_company_id
      FROM cfg."Company"
     WHERE "IsDeleted" = FALSE
     ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
     LIMIT 1;

    IF v_company_id IS NULL THEN
        RAISE NOTICE 'ERROR: No se encontro una compania activa en cfg."Company"';
        RETURN;
    END IF;

    SELECT "UserId" INTO v_system_user_id
      FROM sec."User"
     WHERE "UserCode" = 'SYSTEM' AND "IsDeleted" = FALSE
     LIMIT 1;

    -- Crear tabla temporal con plan de cuentas
    CREATE TEMP TABLE tmp_plan_cuentas (
        account_code  VARCHAR(40) NOT NULL,
        parent_code   VARCHAR(40),
        account_name  VARCHAR(200) NOT NULL,
        account_type  CHAR(1) NOT NULL,
        account_level INT NOT NULL,
        allows_posting BOOLEAN NOT NULL,
        requires_auxiliary BOOLEAN NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO tmp_plan_cuentas (account_code, parent_code, account_name, account_type, account_level, allows_posting, requires_auxiliary)
    VALUES
    ('1',       NULL,    'ACTIVO',                            'A', 1, FALSE, FALSE),
    ('2',       NULL,    'PASIVO',                            'P', 1, FALSE, FALSE),
    ('3',       NULL,    'PATRIMONIO',                        'C', 1, FALSE, FALSE),
    ('4',       NULL,    'INGRESOS',                          'I', 1, FALSE, FALSE),
    ('5',       NULL,    'COSTOS Y GASTOS',                   'G', 1, FALSE, FALSE),

    ('1.1',     '1',    'ACTIVO CORRIENTE',                  'A', 2, FALSE, FALSE),
    ('1.2',     '1',    'ACTIVO NO CORRIENTE',               'A', 2, FALSE, FALSE),
    ('2.1',     '2',    'PASIVO CORRIENTE',                  'P', 2, FALSE, FALSE),
    ('2.2',     '2',    'PASIVO NO CORRIENTE',               'P', 2, FALSE, FALSE),
    ('3.1',     '3',    'CAPITAL SOCIAL',                    'C', 2, FALSE, FALSE),
    ('3.2',     '3',    'RESERVAS',                          'C', 2, FALSE, FALSE),
    ('3.3',     '3',    'RESULTADOS ACUMULADOS',             'C', 2, FALSE, FALSE),
    ('4.1',     '4',    'INGRESOS OPERACIONALES',            'I', 2, FALSE, FALSE),
    ('4.2',     '4',    'INGRESOS NO OPERACIONALES',         'I', 2, FALSE, FALSE),
    ('5.1',     '5',    'COSTO DE VENTAS',                   'G', 2, FALSE, FALSE),
    ('5.2',     '5',    'GASTOS OPERACIONALES',              'G', 2, FALSE, FALSE),
    ('5.3',     '5',    'GASTOS NO OPERACIONALES',           'G', 2, FALSE, FALSE),

    ('1.1.01',  '1.1',  'CAJA',                              'A', 3, TRUE, FALSE),
    ('1.1.02',  '1.1',  'BANCOS',                            'A', 3, TRUE, FALSE),
    ('1.1.03',  '1.1',  'INVERSIONES TEMPORALES',            'A', 3, TRUE, FALSE),
    ('1.1.04',  '1.1',  'CUENTAS POR COBRAR - CLIENTES',     'A', 3, TRUE, TRUE),
    ('1.1.05',  '1.1',  'DOCUMENTOS POR COBRAR',             'A', 3, TRUE, FALSE),
    ('1.1.06',  '1.1',  'INVENTARIOS',                       'A', 3, TRUE, FALSE),
    ('1.1.07',  '1.1',  'IVA CREDITO FISCAL',                'A', 3, TRUE, FALSE),
    ('1.1.08',  '1.1',  'ANTICIPOS A PROVEEDORES',           'A', 3, TRUE, FALSE),
    ('1.1.09',  '1.1',  'RETENCIONES DE IVA POR COBRAR',     'A', 3, TRUE, FALSE),
    ('1.2.01',  '1.2',  'PROPIEDAD PLANTA Y EQUIPO',         'A', 3, TRUE, FALSE),
    ('1.2.02',  '1.2',  'DEPRECIACION ACUMULADA',            'A', 3, TRUE, FALSE),
    ('1.2.03',  '1.2',  'INVERSIONES PERMANENTES',           'A', 3, TRUE, FALSE),
    ('1.2.04',  '1.2',  'INTANGIBLES',                       'A', 3, TRUE, FALSE),
    ('1.2.05',  '1.2',  'ACTIVOS DIFERIDOS',                 'A', 3, TRUE, FALSE),

    ('2.1.01',  '2.1',  'CUENTAS POR PAGAR - PROVEEDORES',   'P', 3, TRUE, TRUE),
    ('2.1.02',  '2.1',  'DOCUMENTOS POR PAGAR',              'P', 3, TRUE, FALSE),
    ('2.1.03',  '2.1',  'IVA DEBITO FISCAL',                 'P', 3, TRUE, FALSE),
    ('2.1.04',  '2.1',  'RETENCIONES DE IVA POR PAGAR',      'P', 3, TRUE, FALSE),
    ('2.1.05',  '2.1',  'SUELDOS Y SALARIOS POR PAGAR',      'P', 3, TRUE, FALSE),
    ('2.1.06',  '2.1',  'SSO POR PAGAR',                     'P', 3, TRUE, FALSE),
    ('2.1.07',  '2.1',  'FAOV POR PAGAR',                    'P', 3, TRUE, FALSE),
    ('2.1.08',  '2.1',  'ISLR RETENIDO POR PAGAR',           'P', 3, TRUE, FALSE),
    ('2.1.09',  '2.1',  'ANTICIPOS DE CLIENTES',             'P', 3, TRUE, FALSE),
    ('2.1.10',  '2.1',  'INTERESES POR PAGAR',               'P', 3, TRUE, FALSE),
    ('2.2.01',  '2.2',  'BONOS Y DEBENTURES',                'P', 3, TRUE, FALSE),
    ('2.2.02',  '2.2',  'HIPOTECAS POR PAGAR',               'P', 3, TRUE, FALSE),
    ('2.2.03',  '2.2',  'PRESTACIONES SOCIALES',             'P', 3, TRUE, FALSE),

    ('3.1.01',  '3.1',  'CAPITAL SUSCRITO Y PAGADO',         'C', 3, TRUE, FALSE),
    ('3.1.02',  '3.1',  'CAPITAL POR SUSCRIBIR',             'C', 3, TRUE, FALSE),
    ('3.2.01',  '3.2',  'RESERVA LEGAL',                     'C', 3, TRUE, FALSE),
    ('3.2.02',  '3.2',  'RESERVA ESTATUTARIA',               'C', 3, TRUE, FALSE),
    ('3.3.01',  '3.3',  'UTILIDADES ACUMULADAS',             'C', 3, TRUE, FALSE),
    ('3.3.02',  '3.3',  'PERDIDAS ACUMULADAS',               'C', 3, TRUE, FALSE),
    ('3.3.03',  '3.3',  'RESULTADO DEL EJERCICIO',           'C', 3, TRUE, FALSE),

    ('4.1.01',  '4.1',  'VENTAS DE BIENES Y SERVICIOS',      'I', 3, TRUE, FALSE),
    ('4.1.02',  '4.1',  'DESCUENTOS EN VENTAS',              'I', 3, TRUE, FALSE),
    ('4.1.03',  '4.1',  'DEVOLUCIONES EN VENTAS',            'I', 3, TRUE, FALSE),
    ('4.1.04',  '4.1',  'VENTAS EXENTAS',                    'I', 3, TRUE, FALSE),
    ('4.1.05',  '4.1',  'EXPORTACIONES',                     'I', 3, TRUE, FALSE),
    ('4.2.01',  '4.2',  'INTERESES GANADOS',                 'I', 3, TRUE, FALSE),
    ('4.2.02',  '4.2',  'COMISIONES GANADAS',                'I', 3, TRUE, FALSE),
    ('4.2.03',  '4.2',  'GANANCIAS EN CAMBIO',               'I', 3, TRUE, FALSE),
    ('4.2.04',  '4.2',  'OTROS INGRESOS',                    'I', 3, TRUE, FALSE),

    ('5.1.01',  '5.1',  'COSTO DE MERCADERIA VENDIDA',       'G', 3, TRUE, FALSE),
    ('5.1.02',  '5.1',  'FLETES Y ACARREOS',                 'G', 3, TRUE, FALSE),
    ('5.2.01',  '5.2',  'SUELDOS Y SALARIOS',                'G', 3, TRUE, FALSE),
    ('5.2.02',  '5.2',  'PRESTACIONES SOCIALES',             'G', 3, TRUE, FALSE),
    ('5.2.03',  '5.2',  'SSO PATRONAL',                      'G', 3, TRUE, FALSE),
    ('5.2.04',  '5.2',  'FAOV PATRONAL',                     'G', 3, TRUE, FALSE),
    ('5.2.05',  '5.2',  'UTILIDADES',                        'G', 3, TRUE, FALSE),
    ('5.2.06',  '5.2',  'VACACIONES',                        'G', 3, TRUE, FALSE),
    ('5.2.07',  '5.2',  'ALQUILERES',                        'G', 3, TRUE, FALSE),
    ('5.2.08',  '5.2',  'SERVICIOS PUBLICOS',                'G', 3, TRUE, FALSE),
    ('5.2.09',  '5.2',  'TELEFONIA Y COMUNICACIONES',        'G', 3, TRUE, FALSE),
    ('5.2.10',  '5.2',  'DEPRECIACION Y AMORTIZACION',       'G', 3, TRUE, FALSE),
    ('5.2.11',  '5.2',  'MATERIALES Y SUMINISTROS',          'G', 3, TRUE, FALSE),
    ('5.2.12',  '5.2',  'PUBLICIDAD Y MERCADEO',             'G', 3, TRUE, FALSE),
    ('5.2.13',  '5.2',  'MANTENIMIENTO Y REPARACIONES',      'G', 3, TRUE, FALSE),
    ('5.2.14',  '5.2',  'SEGUROS',                           'G', 3, TRUE, FALSE),
    ('5.2.15',  '5.2',  'GASTOS DE VIAJE Y REPRESENTACION',  'G', 3, TRUE, FALSE),
    ('5.3.01',  '5.3',  'INTERESES PAGADOS',                 'G', 3, TRUE, FALSE),
    ('5.3.02',  '5.3',  'COMISIONES BANCARIAS',              'G', 3, TRUE, FALSE),
    ('5.3.03',  '5.3',  'PERDIDAS EN CAMBIO',                'G', 3, TRUE, FALSE),
    ('5.3.04',  '5.3',  'OTROS GASTOS',                      'G', 3, TRUE, FALSE);

    -- INSERT ON CONFLICT (reemplaza MERGE)
    INSERT INTO acct."Account" (
        "CompanyId", "AccountCode", "AccountName", "AccountType", "AccountLevel",
        "ParentAccountId", "AllowsPosting", "RequiresAuxiliary",
        "IsActive", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId", "IsDeleted"
    )
    SELECT
        v_company_id, p.account_code, p.account_name, p.account_type, p.account_level,
        NULL, p.allows_posting, p.requires_auxiliary,
        TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_system_user_id, v_system_user_id, FALSE
    FROM tmp_plan_cuentas p
    ON CONFLICT ("CompanyId", "AccountCode") DO UPDATE SET
        "AccountName" = EXCLUDED."AccountName",
        "AccountType" = EXCLUDED."AccountType",
        "AccountLevel" = EXCLUDED."AccountLevel",
        "AllowsPosting" = EXCLUDED."AllowsPosting",
        "RequiresAuxiliary" = EXCLUDED."RequiresAuxiliary",
        "IsActive" = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = v_system_user_id,
        "IsDeleted" = FALSE,
        "DeletedAt" = NULL,
        "DeletedByUserId" = NULL;

    -- Actualizar ParentAccountId
    UPDATE acct."Account" child
       SET "ParentAccountId" = parent."AccountId",
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = v_system_user_id
      FROM tmp_plan_cuentas p
      LEFT JOIN acct."Account" parent
        ON parent."CompanyId" = v_company_id
       AND parent."AccountCode" = p.parent_code
     WHERE child."CompanyId" = v_company_id
       AND child."AccountCode" = p.account_code
       AND (
           (p.parent_code IS NULL AND child."ParentAccountId" IS NOT NULL)
           OR (p.parent_code IS NOT NULL AND (child."ParentAccountId" IS NULL OR child."ParentAccountId" <> parent."AccountId"))
       );

    SELECT COUNT(1) INTO v_total
      FROM acct."Account"
     WHERE "CompanyId" = v_company_id
       AND "AccountCode" IN (SELECT account_code FROM tmp_plan_cuentas);

    RAISE NOTICE 'seed_account_plan.sql: cuentas canonicas sincronizadas para CompanyId=%. Total=%', v_company_id, v_total;
END;
$$;
