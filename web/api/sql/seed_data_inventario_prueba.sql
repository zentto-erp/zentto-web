-- =============================================
-- Datos de prueba: productos en Inventario y movimientos (entradas/salidas) en MovInvent.
-- Para probar sp_CerrarMesInventario y sp_MovUnidades cuando las tablas están vacías.
-- Códigos: PRUEBA01, PRUEBA02, PRUEBA03. Fechas: mes actual.
-- =============================================

SET NOCOUNT ON;

DECLARE @IniMes DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @Dia1 DATE = @IniMes;
DECLARE @Dia5 DATE = DATEADD(DAY, 4, @IniMes);
DECLARE @Dia10 DATE = DATEADD(DAY, 9, @IniMes);

-- 1) Productos en Inventario (insertar solo si no existen)
IF NOT EXISTS (SELECT 1 FROM dbo.Inventario WHERE CODIGO = 'PRUEBA01')
BEGIN
    INSERT INTO dbo.Inventario (CODIGO, DESCRIPCION, EXISTENCIA, COSTO_REFERENCIA, COSTO_PROMEDIO, PRECIO_COMPRA, PRECIO_VENTA, Alicuota)
    VALUES
        ('PRUEBA01', N'Producto prueba 1', 55, 10.50, 10.50, 10.50, 18.00, 16),
        ('PRUEBA02', N'Producto prueba 2', 35, 25.00, 25.00, 25.00, 42.00, 16),
        ('PRUEBA03', N'Producto prueba 3', 25, 8.00, 8.00, 8.00, 14.00, 16);
    PRINT N'Inventario: 3 productos de prueba insertados (PRUEBA01, PRUEBA02, PRUEBA03).';
END
ELSE
    PRINT N'Inventario: productos PRUEBA01/02/03 ya existen, se omiten.';

-- 2) Movimientos iniciales (entradas) - solo si MovInvent no tiene datos del mes actual
IF NOT EXISTS (SELECT 1 FROM dbo.MovInvent WHERE CAST(Fecha AS DATE) >= @IniMes)
BEGIN
    -- Ajuste inicial / entrada día 1
    INSERT INTO dbo.MovInvent (Codigo, Product, Documento, Fecha, Motivo, Tipo, Cantidad_Actual, Cantidad, cantidad_nueva, Co_Usuario, Precio_Compra, Alicuota, Precio_venta, Anulada)
    VALUES
        ('PRUEBA01', 'PRUEBA01', 'INI-001', @Dia1, N'Ajuste inicial', N'Ingreso', 0, 50, 50, 'SISTEMA', 10.50, 16, 18.00, 0),
        ('PRUEBA02', 'PRUEBA02', 'INI-001', @Dia1, N'Ajuste inicial', N'Ingreso', 0, 30, 30, 'SISTEMA', 25.00, 16, 42.00, 0),
        ('PRUEBA03', 'PRUEBA03', 'INI-001', @Dia1, N'Ajuste inicial', N'Ingreso', 0, 20, 20, 'SISTEMA', 8.00, 16, 14.00, 0);

    -- Compra día 5 (entradas)
    INSERT INTO dbo.MovInvent (Codigo, Product, Documento, Fecha, Motivo, Tipo, Cantidad_Actual, Cantidad, cantidad_nueva, Co_Usuario, Precio_Compra, Alicuota, Precio_venta, Anulada)
    VALUES
        ('PRUEBA01', 'PRUEBA01', 'COMP-PRU-001', @Dia5, N'COMPRA:COMP-PRU-001', N'Ingreso', 50, 10, 60, 'SISTEMA', 10.50, 16, 18.00, 0),
        ('PRUEBA02', 'PRUEBA02', 'COMP-PRU-001', @Dia5, N'COMPRA:COMP-PRU-001', N'Ingreso', 30, 10, 40, 'SISTEMA', 25.00, 16, 42.00, 0),
        ('PRUEBA03', 'PRUEBA03', 'COMP-PRU-001', @Dia5, N'COMPRA:COMP-PRU-001', N'Ingreso', 20, 10, 30, 'SISTEMA', 8.00, 16, 14.00, 0);

    -- Venta día 10 (salidas) - Motivo con "Factura" para que sp_MovUnidades clasifique como Salidas
    INSERT INTO dbo.MovInvent (Codigo, Product, Documento, Fecha, Motivo, Tipo, Cantidad_Actual, Cantidad, cantidad_nueva, Co_Usuario, Precio_Compra, Alicuota, Precio_venta, Anulada)
    VALUES
        ('PRUEBA01', 'PRUEBA01', 'F-PRU-001', @Dia10, N'Factura F-PRU-001', N'Egreso', 60, 5, 55, 'SISTEMA', 10.50, 16, 18.00, 0),
        ('PRUEBA02', 'PRUEBA02', 'F-PRU-001', @Dia10, N'Factura F-PRU-001', N'Egreso', 40, 5, 35, 'SISTEMA', 25.00, 16, 42.00, 0),
        ('PRUEBA03', 'PRUEBA03', 'F-PRU-001', @Dia10, N'Factura F-PRU-001', N'Egreso', 30, 5, 25, 'SISTEMA', 8.00, 16, 14.00, 0);

    PRINT N'MovInvent: 9 movimientos de prueba insertados (3 iniciales + 3 compras + 3 ventas).';

    -- Sincronizar existencias en Inventario con el saldo final de MovInvent
    UPDATE i SET i.EXISTENCIA = 55 FROM dbo.Inventario i WHERE i.CODIGO = 'PRUEBA01';
    UPDATE i SET i.EXISTENCIA = 35 FROM dbo.Inventario i WHERE i.CODIGO = 'PRUEBA02';
    UPDATE i SET i.EXISTENCIA = 25 FROM dbo.Inventario i WHERE i.CODIGO = 'PRUEBA03';
END
ELSE
    PRINT N'MovInvent: ya hay movimientos en el mes actual, no se insertan datos de prueba.';

GO
