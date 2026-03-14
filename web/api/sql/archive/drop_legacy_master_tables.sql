SET NOCOUNT ON;

-- FKs legacy conocidos
IF OBJECT_ID('dbo.FK_AsientosDetalle_Asientos', 'F') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Asientos_Detalle DROP CONSTRAINT FK_AsientosDetalle_Asientos;
    PRINT 'Dropped FK FK_AsientosDetalle_Asientos';
END

-- Detalles primero
IF OBJECT_ID('dbo.Asientos_Detalle', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Asientos_Detalle;
    PRINT 'Dropped dbo.Asientos_Detalle';
END

-- Maestros legacy principales
IF OBJECT_ID('dbo.Clientes', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Clientes; PRINT 'Dropped dbo.Clientes'; END
IF OBJECT_ID('dbo.Proveedores', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Proveedores; PRINT 'Dropped dbo.Proveedores'; END
IF OBJECT_ID('dbo.Inventario', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Inventario; PRINT 'Dropped dbo.Inventario'; END
IF OBJECT_ID('dbo.Empleados', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Empleados; PRINT 'Dropped dbo.Empleados'; END
IF OBJECT_ID('dbo.Asientos', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Asientos; PRINT 'Dropped dbo.Asientos'; END
IF OBJECT_ID('dbo.Cuentas', 'U') IS NOT NULL BEGIN DROP TABLE dbo.Cuentas; PRINT 'Dropped dbo.Cuentas'; END
IF OBJECT_ID('dbo.TasasDiarias', 'U') IS NOT NULL BEGIN DROP TABLE dbo.TasasDiarias; PRINT 'Dropped dbo.TasasDiarias'; END
IF OBJECT_ID('dbo.P_Cobrarc', 'U') IS NOT NULL BEGIN DROP TABLE dbo.P_Cobrarc; PRINT 'Dropped dbo.P_Cobrarc'; END
IF OBJECT_ID('dbo.P_Cobrar', 'U') IS NOT NULL BEGIN DROP TABLE dbo.P_Cobrar; PRINT 'Dropped dbo.P_Cobrar'; END
IF OBJECT_ID('dbo.P_Pagar', 'U') IS NOT NULL BEGIN DROP TABLE dbo.P_Pagar; PRINT 'Dropped dbo.P_Pagar'; END
