-- ============================================
-- SEED DATA PARA CONTABILIDAD - PostgreSQL
-- Datos de prueba para demostrar funcionalidad
-- Traducido de SQL Server a PostgreSQL
-- ============================================

-- ============================================
-- PLAN DE CUENTAS - Estructura basica
-- ============================================
DO $$
DECLARE
    v_fecha_ini DATE;
    v_asiento_id INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "Cuentas" WHERE "Cod_Cuenta" = '1') THEN
        -- NIVEL 1 - ACTIVO
        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES ('1', 'ACTIVO', 'A', 1, NULL, TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('1.1', 'ACTIVO CORRIENTE', 'A', 2, '1', TRUE, FALSE),
            ('1.2', 'ACTIVO NO CORRIENTE', 'A', 2, '1', TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('1.1.01', 'CAJA', 'A', 3, '1.1', TRUE, TRUE),
            ('1.1.02', 'BANCOS', 'A', 3, '1.1', TRUE, TRUE),
            ('1.1.03', 'INVERSIONES TEMPORALES', 'A', 3, '1.1', TRUE, TRUE),
            ('1.1.04', 'CLIENTES', 'A', 3, '1.1', TRUE, TRUE),
            ('1.1.05', 'DOCUMENTOS POR COBRAR', 'A', 3, '1.1', TRUE, TRUE),
            ('1.1.06', 'INVENTARIOS', 'A', 3, '1.1', TRUE, TRUE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('1.2.01', 'PROPIEDAD PLANTA Y EQUIPO', 'A', 3, '1.2', TRUE, TRUE),
            ('1.2.02', 'DEPRECIACION ACUMULADA', 'A', 3, '1.2', TRUE, TRUE),
            ('1.2.03', 'INVERSIONES PERMANENTES', 'A', 3, '1.2', TRUE, TRUE),
            ('1.2.04', 'INTANGIBLES', 'A', 3, '1.2', TRUE, TRUE);

        -- NIVEL 1 - PASIVO
        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES ('2', 'PASIVO', 'P', 1, NULL, TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('2.1', 'PASIVO CORRIENTE', 'P', 2, '2', TRUE, FALSE),
            ('2.2', 'PASIVO NO CORRIENTE', 'P', 2, '2', TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('2.1.01', 'PROVEEDORES', 'P', 3, '2.1', TRUE, TRUE),
            ('2.1.02', 'DOCUMENTOS POR PAGAR', 'P', 3, '2.1', TRUE, TRUE),
            ('2.1.03', 'IMPUESTOS POR PAGAR', 'P', 3, '2.1', TRUE, TRUE),
            ('2.1.04', 'SUELDOS POR PAGAR', 'P', 3, '2.1', TRUE, TRUE),
            ('2.1.05', 'INTERESES POR PAGAR', 'P', 3, '2.1', TRUE, TRUE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('2.2.01', 'BONOS POR PAGAR', 'P', 3, '2.2', TRUE, TRUE),
            ('2.2.02', 'HIPOTECAS POR PAGAR', 'P', 3, '2.2', TRUE, TRUE);

        -- NIVEL 1 - PATRIMONIO
        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES ('3', 'PATRIMONIO', 'C', 1, NULL, TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('3.1', 'CAPITAL SOCIAL', 'C', 2, '3', TRUE, FALSE),
            ('3.2', 'RESERVAS', 'C', 2, '3', TRUE, FALSE),
            ('3.3', 'RESULTADOS ACUMULADOS', 'C', 2, '3', TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('3.1.01', 'CAPITAL SUSCRITO', 'C', 3, '3.1', TRUE, TRUE),
            ('3.2.01', 'RESERVA LEGAL', 'C', 3, '3.2', TRUE, TRUE),
            ('3.3.01', 'UTILIDADES ACUMULADAS', 'C', 3, '3.3', TRUE, TRUE);

        -- NIVEL 1 - INGRESOS
        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES ('4', 'INGRESOS', 'I', 1, NULL, TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('4.1', 'INGRESOS OPERACIONALES', 'I', 2, '4', TRUE, FALSE),
            ('4.2', 'INGRESOS NO OPERACIONALES', 'I', 2, '4', TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('4.1.01', 'VENTAS', 'I', 3, '4.1', TRUE, TRUE),
            ('4.1.02', 'DESCUENTOS EN VENTAS', 'I', 3, '4.1', TRUE, TRUE),
            ('4.1.03', 'DEVOLUCIONES EN VENTAS', 'I', 3, '4.1', TRUE, TRUE),
            ('4.2.01', 'INTERESES GANADOS', 'I', 3, '4.2', TRUE, TRUE),
            ('4.2.02', 'COMISIONES GANADAS', 'I', 3, '4.2', TRUE, TRUE);

        -- NIVEL 1 - COSTOS Y GASTOS
        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES ('5', 'COSTOS Y GASTOS', 'G', 1, NULL, TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('5.1', 'COSTO DE VENTAS', 'G', 2, '5', TRUE, FALSE),
            ('5.2', 'GASTOS OPERACIONALES', 'G', 2, '5', TRUE, FALSE),
            ('5.3', 'GASTOS NO OPERACIONALES', 'G', 2, '5', TRUE, FALSE);

        INSERT INTO "Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        VALUES
            ('5.1.01', 'COSTO DE MERCADERIA', 'G', 3, '5.1', TRUE, TRUE),
            ('5.2.01', 'SUELDOS Y SALARIOS', 'G', 3, '5.2', TRUE, TRUE),
            ('5.2.02', 'ALQUILERES', 'G', 3, '5.2', TRUE, TRUE),
            ('5.2.03', 'SERVICIOS PUBLICOS', 'G', 3, '5.2', TRUE, TRUE),
            ('5.2.04', 'DEPRECIACION', 'G', 3, '5.2', TRUE, TRUE),
            ('5.2.05', 'MATERIALES DE OFICINA', 'G', 3, '5.2', TRUE, TRUE),
            ('5.3.01', 'INTERESES PAGADOS', 'G', 3, '5.3', TRUE, TRUE),
            ('5.3.02', 'COMISIONES PAGADAS', 'G', 3, '5.3', TRUE, TRUE);

        RAISE NOTICE 'Plan de cuentas creado exitosamente';
    ELSE
        RAISE NOTICE 'El plan de cuentas ya existe';
    END IF;

    -- ============================================
    -- ASIENTOS DE EJEMPLO
    -- ============================================
    IF NOT EXISTS (SELECT 1 FROM "Asientos" WHERE "Id" > 0) THEN
        v_fecha_ini := (NOW() AT TIME ZONE 'UTC')::DATE - INTERVAL '30 days';

        -- ASIENTO 1: Registro de ventas al contado
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '25 days', 'DIARIO', 'Registro de ventas al contado - Fact #001', 'VTA-001', 'APROBADO', 1000.00, 1000.00, 'VTA', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '1.1.02', 'BANCOS', 1000.00, 0),
            (v_asiento_id, '4.1.01', 'VENTAS', 0, 1000.00);

        -- ASIENTO 2: Compra de mercaderia a credito
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '20 days', 'COMPRA', 'Compra de mercaderia - Prov. Bicimoto', 'CMP-001', 'APROBADO', 500.00, 500.00, 'CMP', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '5.1.01', 'COSTO DE MERCADERIA', 500.00, 0),
            (v_asiento_id, '1.1.06', 'INVENTARIOS', 500.00, 0),
            (v_asiento_id, '2.1.01', 'PROVEEDORES', 0, 1000.00),
            (v_asiento_id, '1.1.06', 'INVENTARIOS', 0, 500.00);

        -- ASIENTO 3: Pago de sueldos
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '15 days', 'NOMINA', 'Pago de sueldos quincenales', 'NOM-001', 'APROBADO', 3000.00, 3000.00, 'NOM', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '5.2.01', 'SUELDOS Y SALARIOS', 3000.00, 0),
            (v_asiento_id, '2.1.04', 'SUELDOS POR PAGAR', 0, 2500.00),
            (v_asiento_id, '2.1.03', 'IMPUESTOS POR PAGAR', 0, 500.00);

        -- ASIENTO 4: Pago de alquiler
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '10 days', 'DIARIO', 'Pago de alquiler de local comercial', 'GTO-001', 'APROBADO', 800.00, 800.00, 'GTO', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '5.2.02', 'ALQUILERES', 800.00, 0),
            (v_asiento_id, '1.1.02', 'BANCOS', 0, 800.00);

        -- ASIENTO 5: Depreciacion mensual
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '5 days', 'AJUSTE', 'Depreciacion mensual de mobiliario', 'DEP-001', 'APROBADO', 150.00, 150.00, 'DEP', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '5.2.04', 'DEPRECIACION', 150.00, 0),
            (v_asiento_id, '1.2.02', 'DEPRECIACION ACUMULADA', 0, 150.00);

        -- ASIENTO 6: Cobro a clientes
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '3 days', 'COBRO', 'Cobro de factura #001 a cliente', 'COB-001', 'APROBADO', 500.00, 500.00, 'COB', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '1.1.02', 'BANCOS', 500.00, 0),
            (v_asiento_id, '1.1.04', 'CLIENTES', 0, 500.00);

        -- ASIENTO 7: Pago a proveedor
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '2 days', 'PAGO', 'Pago parcial a proveedor Bicimoto', 'PAG-001', 'APROBADO', 300.00, 300.00, 'PAG', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '2.1.01', 'PROVEEDORES', 300.00, 0),
            (v_asiento_id, '1.1.02', 'BANCOS', 0, 300.00);

        -- ASIENTO 8: Compra de mobiliario
        INSERT INTO "Asientos" ("Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado", "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario")
        VALUES (v_fecha_ini - INTERVAL '1 day', 'ACTIVO', 'Compra de escritorios para oficina', 'ACT-001', 'PENDIENTE', 1200.00, 1200.00, 'GTO', 'SUP')
        RETURNING "Id" INTO v_asiento_id;

        INSERT INTO "Asientos_Detalle" ("Id_Asiento", "Cod_Cuenta", "Descripcion", "Debe", "Haber")
        VALUES
            (v_asiento_id, '1.2.01', 'PROPIEDAD PLANTA Y EQUIPO', 1200.00, 0),
            (v_asiento_id, '1.1.02', 'BANCOS', 0, 1200.00);

        RAISE NOTICE 'Asientos de ejemplo creados exitosamente';
    ELSE
        RAISE NOTICE 'Los asientos ya existen';
    END IF;

    -- ============================================
    -- CONFIGURACION DE PERIODO FISCAL
    -- ============================================
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Configuracion' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM "Configuracion" WHERE "Clave" = 'PERIODO_FISCAL_INICIO') THEN
            INSERT INTO "Configuracion" ("Clave", "Valor", "Descripcion", "Tipo", "Modificable")
            VALUES
                ('PERIODO_FISCAL_INICIO', TO_CHAR(DATE_TRUNC('year', NOW() AT TIME ZONE 'UTC'), 'YYYY-MM-DD HH24:MI:SS'), 'Fecha de inicio del periodo fiscal actual', 'FECHA', TRUE),
                ('PERIODO_FISCAL_CIERRE', TO_CHAR(DATE_TRUNC('year', NOW() AT TIME ZONE 'UTC') + INTERVAL '1 year' - INTERVAL '1 day', 'YYYY-MM-DD HH24:MI:SS'), 'Fecha de cierre del periodo fiscal actual', 'FECHA', TRUE),
                ('MONEDA_BASE', 'USD', 'Moneda base del sistema', 'TEXTO', FALSE),
                ('DECIMALES_MONEDA', '2', 'Cantidad de decimales para moneda', 'NUMERO', TRUE),
                ('ASIENTO_AUTOMATICO_VENTAS', '1', 'Generar asiento automatico desde ventas', 'BOOLEANO', TRUE),
                ('ASIENTO_AUTOMATICO_COMPRAS', '1', 'Generar asiento automatico desde compras', 'BOOLEANO', TRUE),
                ('INTEGRACION_CONTABLE', '1', 'Integracion contable activada', 'BOOLEANO', TRUE);

            RAISE NOTICE 'Configuracion de periodo fiscal creada';
        ELSE
            RAISE NOTICE 'La configuracion ya existe';
        END IF;
    ELSE
        RAISE NOTICE 'Tabla Configuracion no existe (legacy), omitida';
    END IF;

    -- ============================================
    -- CENTROS DE COSTO DE EJEMPLO
    -- ============================================
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Centro_Costo' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM "Centro_Costo" WHERE "Codigo" IN ('001', '002', '003')) THEN
            INSERT INTO "Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real", "Activo")
            VALUES
                ('001', 'ADMINISTRACION', 50000.00, 0, TRUE),
                ('002', 'VENTAS', 30000.00, 0, TRUE),
                ('003', 'PRODUCCION', 80000.00, 0, TRUE),
                ('004', 'ALMACEN', 20000.00, 0, TRUE);

            RAISE NOTICE 'Centros de costo creados';
        END IF;
    ELSE
        RAISE NOTICE 'Tabla Centro_Costo no existe (legacy), omitida';
    END IF;

    RAISE NOTICE 'SEED DE CONTABILIDAD COMPLETADO EXITOSAMENTE';
END;
$$;
