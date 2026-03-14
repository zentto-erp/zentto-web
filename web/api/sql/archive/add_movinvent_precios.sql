-- =============================================
-- Añadir columnas de precio/costo a MovInvent si no existen
-- Necesarias para reporte SENIAT (costo y precio venta al momento de la operación).
-- =============================================

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'MovInvent')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MovInvent') AND name = 'PRECIO_COMPRA')
        ALTER TABLE MovInvent ADD PRECIO_COMPRA FLOAT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MovInvent') AND name = 'PRECIO_VENTA')
        ALTER TABLE MovInvent ADD PRECIO_VENTA FLOAT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MovInvent') AND name = 'ALICUOTA')
        ALTER TABLE MovInvent ADD ALICUOTA FLOAT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MovInvent') AND name = 'ANULADA')
        ALTER TABLE MovInvent ADD ANULADA BIT NULL DEFAULT 0;
    PRINT N'MovInvent: columnas PRECIO_COMPRA, PRECIO_VENTA, ALICUOTA, ANULADA verificadas.';
END
GO
