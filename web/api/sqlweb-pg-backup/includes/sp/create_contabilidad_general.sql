-- ============================================================
-- DatqBoxWeb PostgreSQL - create_contabilidad_general.sql
-- Contabilidad general base: estructura contable nuclear,
-- enlaces contables a tablas auxiliares, plan de cuentas base
-- y centros de costo iniciales.
-- ============================================================

DO $body$
BEGIN

    -- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
    -- Usar acct.JournalEntry, acct.Account, acct.JournalEntryLine, etc.
    -- Tablas eliminadas: PeriodoContable, AsientoContable, AsientoContableDetalle,
    --   AsientoOrigenAuxiliar, ConfiguracionContableAuxiliar, AjusteContable,
    --   ActivoFijoContable, DepreciacionContable (y sus indices asociados).

    -- Enlaces contables a auxiliares existentes (ADD COLUMN IF NOT EXISTS)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosVenta' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."DocumentosVenta" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosVenta" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosVentaDetalle' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVentaDetalle' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."DocumentosVentaDetalle" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVentaDetalle' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosVentaDetalle" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosCompra' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompra' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."DocumentosCompra" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompra' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosCompra" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosCompraDetalle' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompraDetalle' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."DocumentosCompraDetalle" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompraDetalle' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosCompraDetalle" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'p_cobrar' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'P_Pagar' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'MovInvent' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Abonos' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pagos' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Pagosc' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    -- Seed: Centros de Costo base
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Centro_Costo' AND table_schema = 'public') THEN
        INSERT INTO public."Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        SELECT v.* FROM (VALUES
            ('ADM', 'Administracion',     '0', '0'),
            ('VEN', 'Ventas',             '0', '0'),
            ('COM', 'Compras',            '0', '0'),
            ('ALM', 'Almacen',            '0', '0'),
            ('BAN', 'Bancos y Tesoreria', '0', '0')
        ) AS v("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        WHERE NOT EXISTS (SELECT 1 FROM public."Centro_Costo" cc WHERE cc."Codigo" = v."Codigo");
    END IF;

    -- Seed: Plan de Cuentas base
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Cuentas' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        INSERT INTO public."Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        SELECT s."COD_CUENTA", s."DESCRIPCION",
               (CASE s."grupo" WHEN '1' THEN 'A' WHEN '2' THEN 'P' WHEN '3' THEN 'C' WHEN '4' THEN 'I' WHEN '5' THEN 'G' WHEN '6' THEN 'G' WHEN '7' THEN 'C' ELSE 'A' END)::CHAR(1),
               s."Nivel",
               CASE WHEN s."Nivel" = 1 THEN NULL
                    ELSE REGEXP_REPLACE(s."COD_CUENTA", '\.[^.]+$',''::VARCHAR)
               END,
               TRUE,
               CASE WHEN s."USO" = 'MOV' THEN TRUE ELSE FALSE END
        FROM (VALUES
            ('1',      'ACTIVOS',                          'D', '1', 'GENERAL',       'HEADER', 1),
            ('1.1',    'ACTIVO CORRIENTE',                 'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.1.01', 'CAJA',                             'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.02', 'BANCOS',                           'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.03', 'CUENTAS POR COBRAR COMERCIALES',   'D', '1', 'CXC',           'MOV',    3),
            ('1.1.04', 'RETENCIONES POR RECUPERAR',        'D', '1', 'IMPUESTOS',     'MOV',    3),
            ('1.1.05', 'INVENTARIOS MERCANCIA',            'D', '1', 'INVENTARIO',    'MOV',    3),
            ('1.1.06', 'GASTOS PAGADOS POR ANTICIPADO',    'D', '1', 'GENERAL',       'MOV',    3),
            ('1.2',    'ACTIVO NO CORRIENTE',              'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.2.01', 'PROPIEDAD, PLANTA Y EQUIPO',       'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.02', 'DEPRECIACION ACUMULADA PPE',       'A', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.03', 'ACTIVOS INTANGIBLES',              'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('2',      'PASIVOS',                          'A', '2', 'GENERAL',       'HEADER', 1),
            ('2.1',    'PASIVO CORRIENTE',                 'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.1.01', 'CUENTAS POR PAGAR PROVEEDORES',    'A', '2', 'CXP',           'MOV',    3),
            ('2.1.02', 'RETENCIONES POR PAGAR',            'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.03', 'IMPUESTOS POR PAGAR',              'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.04', 'OBLIGACIONES LABORALES POR PAGAR', 'A', '2', 'NOMINA',        'MOV',    3),
            ('2.1.05', 'ANTICIPOS DE CLIENTES',            'A', '2', 'CXC',           'MOV',    3),
            ('2.2',    'PASIVO NO CORRIENTE',              'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.2.01', 'PRESTAMOS LARGO PLAZO',            'A', '2', 'FINANCIERO',    'MOV',    3),
            ('3',      'PATRIMONIO',                       'A', '3', 'GENERAL',       'HEADER', 1),
            ('3.1',    'CAPITAL SOCIAL',                   'A', '3', 'GENERAL',       'MOV',    2),
            ('3.2',    'RESERVAS',                         'A', '3', 'GENERAL',       'MOV',    2),
            ('3.3',    'RESULTADOS ACUMULADOS',            'A', '3', 'GENERAL',       'MOV',    2),
            ('3.4',    'UTILIDAD O PERDIDA DEL EJERCICIO', 'A', '3', 'GENERAL',       'MOV',    2),
            ('4',      'INGRESOS',                         'A', '4', 'GENERAL',       'HEADER', 1),
            ('4.1',    'INGRESOS OPERACIONALES',           'A', '4', 'VENTAS',        'HEADER', 2),
            ('4.1.01', 'VENTAS GRAVADAS',                  'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.02', 'VENTAS EXENTAS',                   'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.03', 'SERVICIOS PRESTADOS',              'A', '4', 'VENTAS',        'MOV',    3),
            ('4.2',    'INGRESOS NO OPERACIONALES',        'A', '4', 'GENERAL',       'HEADER', 2),
            ('4.2.01', 'OTROS INGRESOS',                   'A', '4', 'GENERAL',       'MOV',    3),
            ('5',      'COSTOS',                           'D', '5', 'GENERAL',       'HEADER', 1),
            ('5.1',    'COSTO DE VENTAS',                  'D', '5', 'INVENTARIO',    'MOV',    2),
            ('5.2',    'COSTO DE SERVICIOS',               'D', '5', 'SERVICIOS',     'MOV',    2),
            ('6',      'GASTOS OPERACIONALES',             'D', '6', 'GENERAL',       'HEADER', 1),
            ('6.1',    'GASTOS DE ADMINISTRACION',         'D', '6', 'ADMIN',         'HEADER', 2),
            ('6.1.01', 'SUELDOS Y SALARIOS ADMIN',         'D', '6', 'NOMINA',        'MOV',    3),
            ('6.1.02', 'ALQUILERES',                       'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.03', 'SERVICIOS BASICOS',                'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.04', 'DEPRECIACION DEL EJERCICIO',       'D', '6', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('6.2',    'GASTOS DE VENTAS',                 'D', '6', 'VENTAS',        'HEADER', 2),
            ('6.2.01', 'COMISIONES DE VENTAS',             'D', '6', 'VENTAS',        'MOV',    3),
            ('6.2.02', 'PUBLICIDAD Y MERCADEO',            'D', '6', 'VENTAS',        'MOV',    3),
            ('7',      'RESULTADO INTEGRAL Y CIERRE',      'A', '7', 'CIERRE',        'HEADER', 1),
            ('7.1',    'RESUMEN DE INGRESOS',              'A', '7', 'CIERRE',        'MOV',    2),
            ('7.2',    'RESUMEN DE COSTOS Y GASTOS',       'D', '7', 'CIERRE',        'MOV',    2)
        ) AS s("COD_CUENTA", "DESCRIPCION", "TIPO", "grupo", "LINEA", "USO", "Nivel")
        WHERE NOT EXISTS (SELECT 1 FROM public."Cuentas" c WHERE c."Cod_Cuenta" = s."COD_CUENTA");
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error create_contabilidad_general.sql: %', SQLERRM;
END;
$body$;
