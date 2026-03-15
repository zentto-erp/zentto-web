-- ============================================
-- Contabilidad general base - PostgreSQL
-- Crea estructura contable nuclear
-- Agrega enlaces contables a tablas auxiliares existentes (si existen)
-- Carga plan de cuentas base y centros de costo iniciales
-- Traducido de SQL Server a PostgreSQL
-- ============================================

DO $$
BEGIN
    -- PeriodoContable
    CREATE TABLE IF NOT EXISTS "PeriodoContable" (
        "Id"            SERIAL PRIMARY KEY,
        "Periodo"       VARCHAR(7) NOT NULL,  -- YYYY-MM
        "FechaDesde"    DATE NOT NULL,
        "FechaHasta"    DATE NOT NULL,
        "Estado"        VARCHAR(20) NOT NULL DEFAULT 'ABIERTO',
        "CerradoPor"    VARCHAR(40),
        "CerradoEn"     TIMESTAMP,
        "FechaCreacion" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        CONSTRAINT "UQ_PeriodoContable_Periodo" UNIQUE ("Periodo")
    );

    -- AsientoContable
    CREATE TABLE IF NOT EXISTS "AsientoContable" (
        "Id"                  BIGSERIAL PRIMARY KEY,
        "NumeroAsiento"       VARCHAR(40) NOT NULL,
        "Fecha"               DATE NOT NULL,
        "Periodo"             VARCHAR(7) NOT NULL,
        "TipoAsiento"         VARCHAR(20) NOT NULL,
        "Referencia"          VARCHAR(120),
        "Concepto"            VARCHAR(400) NOT NULL,
        "Moneda"              VARCHAR(10) NOT NULL DEFAULT 'VES',
        "Tasa"                NUMERIC(18,6) NOT NULL DEFAULT 1,
        "TotalDebe"           NUMERIC(18,2) NOT NULL DEFAULT 0,
        "TotalHaber"          NUMERIC(18,2) NOT NULL DEFAULT 0,
        "Estado"              VARCHAR(20) NOT NULL DEFAULT 'BORRADOR',
        "OrigenModulo"        VARCHAR(40),
        "OrigenDocumento"     VARCHAR(120),
        "CodUsuario"          VARCHAR(40),
        "FechaCreacion"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "FechaAprobacion"     TIMESTAMP,
        "UsuarioAprobacion"   VARCHAR(40),
        "FechaAnulacion"      TIMESTAMP,
        "UsuarioAnulacion"    VARCHAR(40),
        "MotivoAnulacion"     VARCHAR(400),
        CONSTRAINT "UQ_AsientoContable_Numero" UNIQUE ("NumeroAsiento")
    );

    -- AsientoContableDetalle
    CREATE TABLE IF NOT EXISTS "AsientoContableDetalle" (
        "Id"              BIGSERIAL PRIMARY KEY,
        "AsientoId"       BIGINT NOT NULL,
        "Renglon"         INT NOT NULL,
        "CodCuenta"       VARCHAR(40) NOT NULL,
        "Descripcion"     VARCHAR(400),
        "CentroCosto"     VARCHAR(20),
        "AuxiliarTipo"    VARCHAR(30),
        "AuxiliarCodigo"  VARCHAR(120),
        "Documento"       VARCHAR(120),
        "Debe"            NUMERIC(18,2) NOT NULL DEFAULT 0,
        "Haber"           NUMERIC(18,2) NOT NULL DEFAULT 0,
        "FechaCreacion"   TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        CONSTRAINT "FK_AsientoDet_Asiento" FOREIGN KEY ("AsientoId") REFERENCES "AsientoContable"("Id")
    );

    -- AsientoOrigenAuxiliar
    CREATE TABLE IF NOT EXISTS "AsientoOrigenAuxiliar" (
        "Id"                BIGSERIAL PRIMARY KEY,
        "OrigenModulo"      VARCHAR(40) NOT NULL,
        "TipoDocumento"     VARCHAR(40) NOT NULL,
        "NumeroDocumento"   VARCHAR(120) NOT NULL,
        "TablaOrigen"       VARCHAR(120),
        "LlaveOrigen"       VARCHAR(400),
        "AsientoId"         BIGINT NOT NULL,
        "Estado"            VARCHAR(20) NOT NULL DEFAULT 'APLICADO',
        "FechaCreacion"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        CONSTRAINT "FK_AsientoOri_Asiento" FOREIGN KEY ("AsientoId") REFERENCES "AsientoContable"("Id"),
        CONSTRAINT "UQ_AsientoOri" UNIQUE ("OrigenModulo", "TipoDocumento", "NumeroDocumento", "AsientoId")
    );

    -- ConfiguracionContableAuxiliar
    CREATE TABLE IF NOT EXISTS "ConfiguracionContableAuxiliar" (
        "Id"                    SERIAL PRIMARY KEY,
        "Modulo"                VARCHAR(40) NOT NULL,
        "Proceso"               VARCHAR(60) NOT NULL,
        "Naturaleza"            VARCHAR(20) NOT NULL,
        "CuentaContable"        VARCHAR(40) NOT NULL,
        "CentroCostoDefault"    VARCHAR(20),
        "Descripcion"           VARCHAR(250),
        "Activo"                BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT "UQ_ConfigCont" UNIQUE ("Modulo", "Proceso", "Naturaleza", "CuentaContable")
    );

    -- AjusteContable
    CREATE TABLE IF NOT EXISTS "AjusteContable" (
        "Id"              BIGSERIAL PRIMARY KEY,
        "AsientoId"       BIGINT NOT NULL,
        "TipoAjuste"      VARCHAR(40) NOT NULL,
        "Motivo"           VARCHAR(500) NOT NULL,
        "Fecha"            DATE NOT NULL,
        "Estado"           VARCHAR(20) NOT NULL DEFAULT 'APROBADO',
        "CodUsuario"       VARCHAR(40),
        "FechaCreacion"    TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        CONSTRAINT "FK_AjusteCont_Asiento" FOREIGN KEY ("AsientoId") REFERENCES "AsientoContable"("Id")
    );

    -- ActivoFijoContable
    CREATE TABLE IF NOT EXISTS "ActivoFijoContable" (
        "Id"                        BIGSERIAL PRIMARY KEY,
        "CodigoActivo"              VARCHAR(40) NOT NULL,
        "Descripcion"               VARCHAR(250) NOT NULL,
        "FechaCompra"               DATE NOT NULL,
        "CostoAdquisicion"          NUMERIC(18,2) NOT NULL,
        "ValorResidual"             NUMERIC(18,2) NOT NULL DEFAULT 0,
        "VidaUtilMeses"             INT NOT NULL,
        "Metodo"                    VARCHAR(20) NOT NULL DEFAULT 'LINEAL',
        "CuentaActivo"              VARCHAR(40) NOT NULL,
        "CuentaDepreciacionAcum"    VARCHAR(40) NOT NULL,
        "CuentaGastoDepreciacion"   VARCHAR(40) NOT NULL,
        "CentroCosto"               VARCHAR(20),
        "Activo"                    BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT "UQ_ActivoFijo_Codigo" UNIQUE ("CodigoActivo")
    );

    -- DepreciacionContable
    CREATE TABLE IF NOT EXISTS "DepreciacionContable" (
        "Id"              BIGSERIAL PRIMARY KEY,
        "ActivoId"        BIGINT NOT NULL,
        "Periodo"         VARCHAR(7) NOT NULL,
        "Fecha"           DATE NOT NULL,
        "Monto"           NUMERIC(18,2) NOT NULL,
        "AsientoId"       BIGINT,
        "Estado"          VARCHAR(20) NOT NULL DEFAULT 'GENERADO',
        "FechaCreacion"   TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        CONSTRAINT "FK_DepCont_Activo" FOREIGN KEY ("ActivoId") REFERENCES "ActivoFijoContable"("Id"),
        CONSTRAINT "FK_DepCont_Asiento" FOREIGN KEY ("AsientoId") REFERENCES "AsientoContable"("Id"),
        CONSTRAINT "UQ_DepCont" UNIQUE ("ActivoId", "Periodo")
    );

    -- Indices
    CREATE INDEX IF NOT EXISTS "IX_AsientoContable_Fecha" ON "AsientoContable"("Fecha");
    CREATE INDEX IF NOT EXISTS "IX_AsientoContable_Periodo" ON "AsientoContable"("Periodo", "Estado");
    CREATE INDEX IF NOT EXISTS "IX_AsientoDetalle_Cuenta" ON "AsientoContableDetalle"("CodCuenta", "CentroCosto");
    CREATE INDEX IF NOT EXISTS "IX_AsientoOri_Doc" ON "AsientoOrigenAuxiliar"("OrigenModulo", "TipoDocumento", "NumeroDocumento");

    -- ============================================
    -- Enlaces contables a auxiliares existentes
    -- Se agregan columnas solo si la tabla existe y la columna no existe
    -- ============================================
    -- DocumentosVenta
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosVenta' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE "DocumentosVenta" ADD COLUMN "Asiento_Id" BIGINT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE "DocumentosVenta" ADD COLUMN "Centro_Costo" VARCHAR(20);
        END IF;
    END IF;

    -- MovInvent
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'MovInvent' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE "MovInvent" ADD COLUMN "Cod_Cuenta" VARCHAR(40);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE "MovInvent" ADD COLUMN "Centro_Costo" VARCHAR(20);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE "MovInvent" ADD COLUMN "Asiento_Id" BIGINT;
        END IF;
    END IF;

    -- ============================================
    -- Seed de centros de costo base
    -- ============================================
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Centro_Costo' AND table_type = 'BASE TABLE') THEN
        INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        VALUES ('ADM', 'Administracion', '0', '0')
        ON CONFLICT DO NOTHING;
        INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        VALUES ('VEN', 'Ventas', '0', '0')
        ON CONFLICT DO NOTHING;
        INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        VALUES ('COM', 'Compras', '0', '0')
        ON CONFLICT DO NOTHING;
        INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        VALUES ('ALM', 'Almacen', '0', '0')
        ON CONFLICT DO NOTHING;
        INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        VALUES ('BAN', 'Bancos y Tesoreria', '0', '0')
        ON CONFLICT DO NOTHING;
    END IF;

    -- ============================================
    -- Seed Plan de Cuentas base (estructura universal + Venezuela)
    -- ============================================
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Cuentas' AND table_type = 'BASE TABLE') THEN
        INSERT INTO "Cuentas" ("COD_CUENTA", "DESCRIPCION", "TIPO", "PRESUPUESTO", "SALDO", "COD_USUARIO", "grupo", "LINEA", "USO", "Nivel", "Porcentaje")
        SELECT s."COD_CUENTA", s."DESCRIPCION", s."TIPO", 0, 0, 'SYS', s.grupo, s."LINEA", s."USO", s."Nivel", 0
        FROM (VALUES
            ('1',      'ACTIVOS',                            'D', '1', 'GENERAL',       'HEADER', 1),
            ('1.1',    'ACTIVO CORRIENTE',                   'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.1.01', 'CAJA',                               'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.02', 'BANCOS',                             'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.03', 'CUENTAS POR COBRAR COMERCIALES',     'D', '1', 'CXC',           'MOV',    3),
            ('1.1.04', 'RETENCIONES POR RECUPERAR',          'D', '1', 'IMPUESTOS',     'MOV',    3),
            ('1.1.05', 'INVENTARIOS MERCANCIA',              'D', '1', 'INVENTARIO',    'MOV',    3),
            ('1.1.06', 'GASTOS PAGADOS POR ANTICIPADO',      'D', '1', 'GENERAL',       'MOV',    3),
            ('1.2',    'ACTIVO NO CORRIENTE',                'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.2.01', 'PROPIEDAD, PLANTA Y EQUIPO',         'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.02', 'DEPRECIACION ACUMULADA PPE',         'A', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.03', 'ACTIVOS INTANGIBLES',                'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('2',      'PASIVOS',                            'A', '2', 'GENERAL',       'HEADER', 1),
            ('2.1',    'PASIVO CORRIENTE',                   'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.1.01', 'CUENTAS POR PAGAR PROVEEDORES',      'A', '2', 'CXP',           'MOV',    3),
            ('2.1.02', 'RETENCIONES POR PAGAR',              'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.03', 'IMPUESTOS POR PAGAR',                'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.04', 'OBLIGACIONES LABORALES POR PAGAR',   'A', '2', 'NOMINA',        'MOV',    3),
            ('2.1.05', 'ANTICIPOS DE CLIENTES',              'A', '2', 'CXC',           'MOV',    3),
            ('2.2',    'PASIVO NO CORRIENTE',                'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.2.01', 'PRESTAMOS LARGO PLAZO',              'A', '2', 'FINANCIERO',    'MOV',    3),
            ('3',      'PATRIMONIO',                         'A', '3', 'GENERAL',       'HEADER', 1),
            ('3.1',    'CAPITAL SOCIAL',                     'A', '3', 'GENERAL',       'MOV',    2),
            ('3.2',    'RESERVAS',                           'A', '3', 'GENERAL',       'MOV',    2),
            ('3.3',    'RESULTADOS ACUMULADOS',              'A', '3', 'GENERAL',       'MOV',    2),
            ('3.4',    'UTILIDAD O PERDIDA DEL EJERCICIO',   'A', '3', 'GENERAL',       'MOV',    2),
            ('4',      'INGRESOS',                           'A', '4', 'GENERAL',       'HEADER', 1),
            ('4.1',    'INGRESOS OPERACIONALES',             'A', '4', 'VENTAS',        'HEADER', 2),
            ('4.1.01', 'VENTAS GRAVADAS',                    'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.02', 'VENTAS EXENTAS',                     'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.03', 'SERVICIOS PRESTADOS',                'A', '4', 'VENTAS',        'MOV',    3),
            ('4.2',    'INGRESOS NO OPERACIONALES',          'A', '4', 'GENERAL',       'HEADER', 2),
            ('4.2.01', 'OTROS INGRESOS',                     'A', '4', 'GENERAL',       'MOV',    3),
            ('5',      'COSTOS',                             'D', '5', 'GENERAL',       'HEADER', 1),
            ('5.1',    'COSTO DE VENTAS',                    'D', '5', 'INVENTARIO',    'MOV',    2),
            ('5.2',    'COSTO DE SERVICIOS',                 'D', '5', 'SERVICIOS',     'MOV',    2),
            ('6',      'GASTOS OPERACIONALES',               'D', '6', 'GENERAL',       'HEADER', 1),
            ('6.1',    'GASTOS DE ADMINISTRACION',           'D', '6', 'ADMIN',         'HEADER', 2),
            ('6.1.01', 'SUELDOS Y SALARIOS ADMIN',           'D', '6', 'NOMINA',        'MOV',    3),
            ('6.1.02', 'ALQUILERES',                         'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.03', 'SERVICIOS BASICOS',                  'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.04', 'DEPRECIACION DEL EJERCICIO',         'D', '6', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('6.2',    'GASTOS DE VENTAS',                   'D', '6', 'VENTAS',        'HEADER', 2),
            ('6.2.01', 'COMISIONES DE VENTAS',               'D', '6', 'VENTAS',        'MOV',    3),
            ('6.2.02', 'PUBLICIDAD Y MERCADEO',              'D', '6', 'VENTAS',        'MOV',    3),
            ('7',      'RESULTADO INTEGRAL Y CIERRE',        'A', '7', 'CIERRE',        'HEADER', 1),
            ('7.1',    'RESUMEN DE INGRESOS',                'A', '7', 'CIERRE',        'MOV',    2),
            ('7.2',    'RESUMEN DE COSTOS Y GASTOS',         'D', '7', 'CIERRE',        'MOV',    2)
        ) AS s("COD_CUENTA", "DESCRIPCION", "TIPO", grupo, "LINEA", "USO", "Nivel")
        WHERE NOT EXISTS (
            SELECT 1 FROM "Cuentas" c WHERE c."COD_CUENTA" = s."COD_CUENTA"
        );
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error create_contabilidad_general.sql: %', SQLERRM;
END;
$$;
