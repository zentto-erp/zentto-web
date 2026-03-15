-- =============================================
-- Indices para acelerar sp_CerrarMesInventario y sp_MovUnidades - PostgreSQL
-- Con ~60k articulos e Inventario y 450k+ filas en MovInvent.
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- 1) MovInvent: filtros por Fecha y Anulada
CREATE INDEX IF NOT EXISTS "IX_MovInvent_Fecha_Anulada"
    ON "MovInvent" ("Fecha", "Anulada");
-- NOTA: En PostgreSQL, INCLUDE no se soporta en versiones antiguas.
-- Si se usa PostgreSQL 11+, se puede usar:
-- CREATE INDEX IF NOT EXISTS "IX_MovInvent_Fecha_Anulada"
--     ON "MovInvent" ("Fecha", "Anulada")
--     INCLUDE ("Codigo", "Product", "Cantidad", "cantidad_nueva", "Precio_Compra", "Tipo", "Motivo", "id");

-- 2) MovInvent: (Codigo, Fecha DESC, id DESC) para ultimo movimiento por producto
CREATE INDEX IF NOT EXISTS "IX_MovInvent_Codigo_Fecha_id"
    ON "MovInvent" ("Codigo", "Fecha" DESC, "id" DESC);

-- 3) MovInventMes: filtro por Periodo
CREATE INDEX IF NOT EXISTS "IX_MovInventMes_Periodo_fecha"
    ON "MovInventMes" ("Periodo", "fecha", "Codigo");

-- 4) CierreMensualInventario: ya tiene PK (Periodo, Codigo) e IX en Periodo

-- 5) master."Product": indice por "ProductCode"
CREATE INDEX IF NOT EXISTS "IX_Product_ProductCode"
    ON master."Product" ("ProductCode");
-- NOTA: Para incluir columnas adicionales en PostgreSQL 11+:
-- CREATE INDEX IF NOT EXISTS "IX_Product_ProductCode"
--     ON master."Product" ("ProductCode")
--     INCLUDE ("ProductName", "StockQty", "COSTO_REFERENCIA", "COSTO_PROMEDIO");
