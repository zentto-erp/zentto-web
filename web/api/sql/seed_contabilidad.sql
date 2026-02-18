-- ============================================
-- SEED DATA PARA CONTABILIDAD
-- Datos de prueba para demostrar funcionalidad
-- ============================================

-- Verificar si ya existen datos
IF NOT EXISTS (SELECT 1 FROM Cuentas WHERE Cod_Cuenta = '1')
BEGIN
    -- ============================================
    -- PLAN DE CUENTAS - Estructura básica
    -- ============================================
    
    -- NIVEL 1 - ACTIVO
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES ('1', 'ACTIVO', 'A', 1, NULL, 1, 0);
    
    -- NIVEL 2 - Activo Corriente y No Corriente
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('1.1', 'ACTIVO CORRIENTE', 'A', 2, '1', 1, 0),
        ('1.2', 'ACTIVO NO CORRIENTE', 'A', 2, '1', 1, 0);
    
    -- NIVEL 3 - Cuentas específicas de Activo Corriente
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('1.1.01', 'CAJA', 'A', 3, '1.1', 1, 1),
        ('1.1.02', 'BANCOS', 'A', 3, '1.1', 1, 1),
        ('1.1.03', 'INVERSIONES TEMPORALES', 'A', 3, '1.1', 1, 1),
        ('1.1.04', 'CLIENTES', 'A', 3, '1.1', 1, 1),
        ('1.1.05', 'DOCUMENTOS POR COBRAR', 'A', 3, '1.1', 1, 1),
        ('1.1.06', 'INVENTARIOS', 'A', 3, '1.1', 1, 1);
    
    -- NIVEL 3 - Cuentas específicas de Activo No Corriente
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('1.2.01', 'PROPIEDAD PLANTA Y EQUIPO', 'A', 3, '1.2', 1, 1),
        ('1.2.02', 'DEPRECIACION ACUMULADA', 'A', 3, '1.2', 1, 1),
        ('1.2.03', 'INVERSIONES PERMANENTES', 'A', 3, '1.2', 1, 1),
        ('1.2.04', 'INTANGIBLES', 'A', 3, '1.2', 1, 1);
    
    -- NIVEL 1 - PASIVO
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES ('2', 'PASIVO', 'P', 1, NULL, 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('2.1', 'PASIVO CORRIENTE', 'P', 2, '2', 1, 0),
        ('2.2', 'PASIVO NO CORRIENTE', 'P', 2, '2', 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('2.1.01', 'PROVEEDORES', 'P', 3, '2.1', 1, 1),
        ('2.1.02', 'DOCUMENTOS POR PAGAR', 'P', 3, '2.1', 1, 1),
        ('2.1.03', 'IMPUESTOS POR PAGAR', 'P', 3, '2.1', 1, 1),
        ('2.1.04', 'SUELDOS POR PAGAR', 'P', 3, '2.1', 1, 1),
        ('2.1.05', 'INTERESES POR PAGAR', 'P', 3, '2.1', 1, 1);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('2.2.01', 'BONOS POR PAGAR', 'P', 3, '2.2', 1, 1),
        ('2.2.02', 'HIPOTECAS POR PAGAR', 'P', 3, '2.2', 1, 1);
    
    -- NIVEL 1 - PATRIMONIO
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES ('3', 'PATRIMONIO', 'C', 1, NULL, 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('3.1', 'CAPITAL SOCIAL', 'C', 2, '3', 1, 0),
        ('3.2', 'RESERVAS', 'C', 2, '3', 1, 0),
        ('3.3', 'RESULTADOS ACUMULADOS', 'C', 2, '3', 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('3.1.01', 'CAPITAL SUSCRITO', 'C', 3, '3.1', 1, 1),
        ('3.2.01', 'RESERVA LEGAL', 'C', 3, '3.2', 1, 1),
        ('3.3.01', 'UTILIDADES ACUMULADAS', 'C', 3, '3.3', 1, 1);
    
    -- NIVEL 1 - INGRESOS
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES ('4', 'INGRESOS', 'I', 1, NULL, 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('4.1', 'INGRESOS OPERACIONALES', 'I', 2, '4', 1, 0),
        ('4.2', 'INGRESOS NO OPERACIONALES', 'I', 2, '4', 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('4.1.01', 'VENTAS', 'I', 3, '4.1', 1, 1),
        ('4.1.02', 'DESCUENTOS EN VENTAS', 'I', 3, '4.1', 1, 1),
        ('4.1.03', 'DEVOLUCIONES EN VENTAS', 'I', 3, '4.1', 1, 1),
        ('4.2.01', 'INTERESES GANADOS', 'I', 3, '4.2', 1, 1),
        ('4.2.02', 'COMISIONES GANADAS', 'I', 3, '4.2', 1, 1);
    
    -- NIVEL 1 - COSTOS Y GASTOS
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES ('5', 'COSTOS Y GASTOS', 'G', 1, NULL, 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('5.1', 'COSTO DE VENTAS', 'G', 2, '5', 1, 0),
        ('5.2', 'GASTOS OPERACIONALES', 'G', 2, '5', 1, 0),
        ('5.3', 'GASTOS NO OPERACIONALES', 'G', 2, '5', 1, 0);
    
    INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
    VALUES 
        ('5.1.01', 'COSTO DE MERCADERIA', 'G', 3, '5.1', 1, 1),
        ('5.2.01', 'SUELDOS Y SALARIOS', 'G', 3, '5.2', 1, 1),
        ('5.2.02', 'ALQUILERES', 'G', 3, '5.2', 1, 1),
        ('5.2.03', 'SERVICIOS PUBLICOS', 'G', 3, '5.2', 1, 1),
        ('5.2.04', 'DEPRECIACION', 'G', 3, '5.2', 1, 1),
        ('5.2.05', 'MATERIALES DE OFICINA', 'G', 3, '5.2', 1, 1),
        ('5.3.01', 'INTERESES PAGADOS', 'G', 3, '5.3', 1, 1),
        ('5.3.02', 'COMISIONES PAGADAS', 'G', 3, '5.3', 1, 1);
    
    PRINT 'Plan de cuentas creado exitosamente';
END
ELSE
BEGIN
    PRINT 'El plan de cuentas ya existe';
END
GO

-- ============================================
-- ASIENTOS DE EJEMPLO
-- ============================================
IF NOT EXISTS (SELECT 1 FROM Asientos WHERE Id > 0)
BEGIN
    DECLARE @FechaIni DATE = DATEADD(DAY, -30, GETDATE());
    
    -- ASIENTO 1: Registro de ventas al contado
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -25, @FechaIni), 'DIARIO', 'Registro de ventas al contado - Fact #001', 'VTA-001', 'APROBADO', 1000.00, 1000.00, 'VTA', 'SUP');
    
    DECLARE @Asiento1 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento1, '1.1.02', 'BANCOS', 1000.00, 0),
        (@Asiento1, '4.1.01', 'VENTAS', 0, 1000.00);
    
    -- ASIENTO 2: Compra de mercadería a crédito
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -20, @FechaIni), 'COMPRA', 'Compra de mercadería - Prov. Bicimoto', 'CMP-001', 'APROBADO', 500.00, 500.00, 'CMP', 'SUP');
    
    DECLARE @Asiento2 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento2, '5.1.01', 'COSTO DE MERCADERIA', 500.00, 0),
        (@Asiento2, '1.1.06', 'INVENTARIOS', 500.00, 0),
        (@Asiento2, '2.1.01', 'PROVEEDORES', 0, 1000.00),
        (@Asiento2, '1.1.06', 'INVENTARIOS', 0, 500.00);
    
    -- ASIENTO 3: Pago de sueldos
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -15, @FechaIni), 'NOMINA', 'Pago de sueldos quincenales', 'NOM-001', 'APROBADO', 3000.00, 3000.00, 'NOM', 'SUP');
    
    DECLARE @Asiento3 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento3, '5.2.01', 'SUELDOS Y SALARIOS', 3000.00, 0),
        (@Asiento3, '2.1.04', 'SUELDOS POR PAGAR', 0, 2500.00),
        (@Asiento3, '2.1.03', 'IMPUESTOS POR PAGAR', 0, 500.00);
    
    -- ASIENTO 4: Pago de alquiler
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -10, @FechaIni), 'DIARIO', 'Pago de alquiler de local comercial', 'GTO-001', 'APROBADO', 800.00, 800.00, 'GTO', 'SUP');
    
    DECLARE @Asiento4 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento4, '5.2.02', 'ALQUILERES', 800.00, 0),
        (@Asiento4, '1.1.02', 'BANCOS', 0, 800.00);
    
    -- ASIENTO 5: Depreciación mensual
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -5, @FechaIni), 'AJUSTE', 'Depreciación mensual de mobiliario', 'DEP-001', 'APROBADO', 150.00, 150.00, 'DEP', 'SUP');
    
    DECLARE @Asiento5 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento5, '5.2.04', 'DEPRECIACION', 150.00, 0),
        (@Asiento5, '1.2.02', 'DEPRECIACION ACUMULADA', 0, 150.00);
    
    -- ASIENTO 6: Cobro a clientes
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -3, @FechaIni), 'COBRO', 'Cobro de factura #001 a cliente', 'COB-001', 'APROBADO', 500.00, 500.00, 'COB', 'SUP');
    
    DECLARE @Asiento6 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento6, '1.1.02', 'BANCOS', 500.00, 0),
        (@Asiento6, '1.1.04', 'CLIENTES', 0, 500.00);
    
    -- ASIENTO 7: Pago a proveedor
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -2, @FechaIni), 'PAGO', 'Pago parcial a proveedor Bicimoto', 'PAG-001', 'APROBADO', 300.00, 300.00, 'PAG', 'SUP');
    
    DECLARE @Asiento7 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento7, '2.1.01', 'PROVEEDORES', 300.00, 0),
        (@Asiento7, '1.1.02', 'BANCOS', 0, 300.00);
    
    -- ASIENTO 8: Compra de mobiliario
    INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
    VALUES (DATEADD(DAY, -1, @FechaIni), 'ACTIVO', 'Compra de escritorios para oficina', 'ACT-001', 'PENDIENTE', 1200.00, 1200.00, 'GTO', 'SUP');
    
    DECLARE @Asiento8 INT = SCOPE_IDENTITY();
    
    INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
    VALUES 
        (@Asiento8, '1.2.01', 'PROPIEDAD PLANTA Y EQUIPO', 1200.00, 0),
        (@Asiento8, '1.1.02', 'BANCOS', 0, 1200.00);
    
    PRINT 'Asientos de ejemplo creados exitosamente';
END
ELSE
BEGIN
    PRINT 'Los asientos ya existen';
END
GO

-- ============================================
-- CONFIGURACIÓN DE PERÍODO FISCAL
-- ============================================
IF NOT EXISTS (SELECT 1 FROM Configuracion WHERE Clave = 'PERIODO_FISCAL_INICIO')
BEGIN
    INSERT INTO Configuracion (Clave, Valor, Descripcion, Tipo, Modificable)
    VALUES 
        ('PERIODO_FISCAL_INICIO', CONVERT(VARCHAR, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0), 120), 'Fecha de inicio del período fiscal actual', 'FECHA', 1),
        ('PERIODO_FISCAL_CIERRE', CONVERT(VARCHAR, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, -1), 120), 'Fecha de cierre del período fiscal actual', 'FECHA', 1),
        ('MONEDA_BASE', 'USD', 'Moneda base del sistema', 'TEXTO', 0),
        ('DECIMALES_MONEDA', '2', 'Cantidad de decimales para moneda', 'NUMERO', 1),
        ('ASIENTO_AUTOMATICO_VENTAS', '1', 'Generar asiento automático desde ventas', 'BOOLEANO', 1),
        ('ASIENTO_AUTOMATICO_COMPRAS', '1', 'Generar asiento automático desde compras', 'BOOLEANO', 1),
        ('INTEGRACION_CONTABLE', '1', 'Integración contable activada', 'BOOLEANO', 1);
    
    PRINT 'Configuración de período fiscal creada';
END
ELSE
BEGIN
    PRINT 'La configuración ya existe';
END
GO

-- ============================================
-- CENTROS DE COSTO DE EJEMPLO
-- ============================================
IF NOT EXISTS (SELECT 1 FROM Centro_Costo WHERE Codigo IN ('001', '002', '003'))
BEGIN
    INSERT INTO Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real, Activo)
    VALUES 
        ('001', 'ADMINISTRACION', 50000.00, 0, 1),
        ('002', 'VENTAS', 30000.00, 0, 1),
        ('003', 'PRODUCCION', 80000.00, 0, 1),
        ('004', 'ALMACEN', 20000.00, 0, 1);
    
    PRINT 'Centros de costo creados';
END
GO

PRINT 'SEED DE CONTABILIDAD COMPLETADO EXITOSAMENTE';
GO
