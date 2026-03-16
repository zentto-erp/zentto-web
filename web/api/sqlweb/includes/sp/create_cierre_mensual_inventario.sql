-- =============================================
-- Tabla CierreMensualInventario: guarda el cierre de cada mes por producto.
-- El cierre de enero es el inventario inicial de febrero (y así cada mes).
-- Fuente: movimientos (MovInvent) que a su vez se alimentan del detalle de
-- operaciones de venta y compra (DocumentosVentaDetalle, DocumentosCompraDetalle / legacy).
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CierreMensualInventario')
BEGIN
    CREATE TABLE dbo.CierreMensualInventario (
        Periodo       NVARCHAR(10) NOT NULL,   -- MM/YYYY (ej. 01/2026)
        Codigo        NVARCHAR(60) NOT NULL,   -- Código del artículo
        Descripcion   NVARCHAR(255) NULL,
        CantidadFinal FLOAT NOT NULL DEFAULT 0, -- Existencia al cierre del mes
        MontoFinal    FLOAT NOT NULL DEFAULT 0, -- Valor (CantidadFinal * CostoUnitario)
        CostoUnitario FLOAT NOT NULL DEFAULT 0, -- Costo unitario al cierre (para reporte)
        FechaCierre   DATETIME NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_CierreMensualInventario PRIMARY KEY (Periodo, Codigo)
    );
    CREATE INDEX IX_CierreMensualInventario_Periodo ON dbo.CierreMensualInventario(Periodo);
    PRINT N'Tabla CierreMensualInventario creada.';
END
GO
