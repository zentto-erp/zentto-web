-- =============================================
-- Indices para acelerar sp_CerrarMesInventario y sp_MovUnidades
-- Con ~60k articulos e Inventario y 450k+ filas en MovInvent.
-- Ejecutar una vez en la base (Sanjose o la que uses).
-- =============================================

SET NOCOUNT ON;

-- 1) MovInvent: filtros por Fecha y Anulada; orden por Codigo/Product, Fecha, id
-- Evita full scan en tablas de cientos de miles de filas.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.MovInvent') AND name = 'IX_MovInvent_Fecha_Anulada')
BEGIN
    CREATE NONCLUSTERED INDEX IX_MovInvent_Fecha_Anulada
    ON dbo.MovInvent (Fecha, Anulada)
    INCLUDE (Codigo, Product, Cantidad, cantidad_nueva, Precio_Compra, Tipo, Motivo, id);
    PRINT N'MovInvent: indice IX_MovInvent_Fecha_Anulada creado.';
END
ELSE
    PRINT N'MovInvent: IX_MovInvent_Fecha_Anulada ya existe.';

-- 2) MovInvent: (Codigo, Fecha DESC, id DESC) para ultimo movimiento por producto
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.MovInvent') AND name = 'IX_MovInvent_Codigo_Fecha_id')
BEGIN
    CREATE NONCLUSTERED INDEX IX_MovInvent_Codigo_Fecha_id
    ON dbo.MovInvent (Codigo, Fecha DESC, id DESC)
    INCLUDE (cantidad_nueva, Precio_Compra, Product, Anulada);
    PRINT N'MovInvent: indice IX_MovInvent_Codigo_Fecha_id creado.';
END
ELSE
    PRINT N'MovInvent: IX_MovInvent_Codigo_Fecha_id ya existe.';

-- 3) MovInventMes: filtro por Periodo (DELETE y SELECT por periodo)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.MovInventMes') AND name = 'IX_MovInventMes_Periodo_fecha')
BEGIN
    CREATE NONCLUSTERED INDEX IX_MovInventMes_Periodo_fecha
    ON dbo.MovInventMes (Periodo, fecha, Codigo);
    PRINT N'MovInventMes: indice IX_MovInventMes_Periodo_fecha creado.';
END
ELSE
    PRINT N'MovInventMes: IX_MovInventMes_Periodo_fecha ya existe.';

-- 4) CierreMensualInventario: ya tiene PK (Periodo, Codigo) e IX en Periodo; no hace falta mas.

-- 5) master.Product: indice por ProductCode solo si no hay ningun indice que use ProductCode
-- Antes: CREATE NONCLUSTERED INDEX IX_Inventario_CODIGO ON dbo.Inventario (CODIGO)
IF NOT EXISTS (
    SELECT 1 FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = OBJECT_ID('master.Product') AND c.name = 'ProductCode'
)
BEGIN
    -- Ahora se usa master.Product (antes dbo.Inventario); ProductCode = CODIGO, ProductName = DESCRIPCION, StockQty = EXISTENCIA
    CREATE NONCLUSTERED INDEX IX_Product_ProductCode ON master.Product (ProductCode) INCLUDE (ProductName, StockQty, COSTO_REFERENCIA, COSTO_PROMEDIO);
    PRINT N'master.Product: indice IX_Product_ProductCode creado.';
END
ELSE
    PRINT N'master.Product: ya existe indice con ProductCode (PK u otro).';

PRINT N'Fin add_indexes_inventario_cierre.sql — Inventario migrado a master.Product.';
GO
