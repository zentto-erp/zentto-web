-- =============================================
-- Añadir MONEDA y TASA_CAMBIO a tablas unificadas
-- Para bases que ya tienen DocumentosVenta/DocumentosCompra sin estos campos.
-- La tasa se rellena con el valor del día (tasa_moneda / tasa_dolar) al emitir.
-- =============================================

-- DocumentosVenta: MONEDA y TASA_CAMBIO (si no existen)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVenta')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosVenta') AND name = 'MONEDA')
        ALTER TABLE DocumentosVenta ADD MONEDA NVARCHAR(20) NULL DEFAULT 'BS';
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosVenta') AND name = 'TASA_CAMBIO')
        ALTER TABLE DocumentosVenta ADD TASA_CAMBIO FLOAT NULL DEFAULT 1;
END
GO

-- DocumentosCompra: MONEDA y TASA_CAMBIO (si no existen)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosCompra')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosCompra') AND name = 'MONEDA')
        ALTER TABLE DocumentosCompra ADD MONEDA NVARCHAR(20) NULL DEFAULT 'BS';
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosCompra') AND name = 'TASA_CAMBIO')
        ALTER TABLE DocumentosCompra ADD TASA_CAMBIO FLOAT NULL DEFAULT 1;
END
GO

-- DocumentosVentaPago / DocumentosVentaFormaPago: TASA_CAMBIO (si no existe)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVentaPago')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosVentaPago') AND name = 'TASA_CAMBIO')
        ALTER TABLE DocumentosVentaPago ADD TASA_CAMBIO FLOAT NULL DEFAULT 1;
END
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVentaFormaPago')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosVentaFormaPago') AND name = 'TASA_CAMBIO')
        ALTER TABLE DocumentosVentaFormaPago ADD TASA_CAMBIO FLOAT NULL DEFAULT 1;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DocumentosVentaFormaPago') AND name = 'tasacambio')
        ALTER TABLE DocumentosVentaFormaPago ADD tasacambio FLOAT NULL DEFAULT 1;
END
GO
