-- =============================================
-- Eliminar tablas legacy de documentos ya cubiertas por las unificadas
-- DocumentosVenta / DocumentosCompra (y detalle / formas de pago).
--
-- Tablas que se eliminan:
--   Venta: Facturas, Detalle_facturas, Detalle_FormaPagoFacturas;
--          Presupuestos, Detalle_Presupuestos; Pedidos, Detalle_Pedidos;
--          Cotizacion, Detalle_Cotizacion, Detalle_FormaPagoCotizacion;
--          NOTACREDITO, Detalle_notacredito; NOTADEBITO, Detalle_notadebito;
--          Nota_Entrega/NOTA_ENTREGA, Detalle_notaentrega (si existen).
--   Compra: Compras, Detalle_Compras, Detalle_FormaPagoCompras;
--           Ordenes, Detalle_Ordenes.
--
-- IMPORTANTE:
-- 1. Ejecutar migrate_to_documentos_unificado.sql antes y verificar datos.
-- 2. Hacer backup de la base antes de ejecutar este script.
-- 3. La aplicación debe usar solo las APIs que escriben en DocumentosVenta/DocumentosCompra.
-- 4. Si existen FKs desde otras tablas (ej. P_Cobrar, P_Pagar) a estas tablas, eliminarlas o ajustarlas antes.
-- =============================================

SET NOCOUNT ON;

-- Tablas a eliminar (orden: primero dependientes, luego cabeceras).
-- Se eliminan FKs que referencian cada tabla y luego la tabla.
DECLARE @TablasLegacy TABLE (Orden INT, NombreTabla NVARCHAR(128));
INSERT INTO @TablasLegacy (Orden, NombreTabla) VALUES
 (1, N'Detalle_FormaPagoFacturas'),
 (2, N'Detalle_facturas'),
 (3, N'Facturas'),
 (4, N'Detalle_FormaPagoCotizacion'),
 (5, N'Detalle_Presupuestos'),
 (6, N'Presupuestos'),
 (7, N'Detalle_Pedidos'),
 (8, N'Pedidos'),
 (9, N'Detalle_Cotizacion'),
 (10, N'Cotizacion'),
 (11, N'Detalle_notacredito'),
 (12, N'NOTACREDITO'),
 (13, N'Detalle_notadebito'),
 (14, N'NOTADEBITO'),
 (15, N'Detalle_FormaPagoCompras'),
 (16, N'Detalle_Compras'),
 (17, N'Compras'),
 (18, N'Detalle_Ordenes'),
 (19, N'Ordenes'),
 (20, N'Detalle_notaentrega'),
 (21, N'Nota_Entrega'),
 (22, N'NOTA_ENTREGA');

DECLARE @NombreTabla NVARCHAR(128);
DECLARE @Schema SYSNAME = N'dbo';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FkName NVARCHAR(256);
DECLARE @ParentTable NVARCHAR(256);
DECLARE @Dropped INT;
DECLARE @TotalDropped INT = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT NombreTabla FROM @TablasLegacy ORDER BY Orden;

OPEN cur;
FETCH NEXT FROM cur INTO @NombreTabla;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @NombreTabla AND schema_id = SCHEMA_ID(@Schema))
    BEGIN
        -- Eliminar todas las FKs que tiene esta tabla (para poder hacer DROP TABLE)
        DECLARE fk_cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT fk.name,
                   QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
            FROM sys.foreign_keys fk
            WHERE fk.parent_object_id = OBJECT_ID(@Schema + N'.' + @NombreTabla);

        OPEN fk_cur;
        FETCH NEXT FROM fk_cur INTO @FkName, @ParentTable;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Sql = N'ALTER TABLE ' + @ParentTable + N' DROP CONSTRAINT ' + QUOTENAME(@FkName) + N';';
            BEGIN TRY
                EXEC sp_executesql @Sql;
                PRINT N'  FK eliminada: ' + @FkName + N' en ' + @ParentTable;
            END TRY
            BEGIN CATCH
                PRINT N'  Error al eliminar FK ' + @FkName + N': ' + ERROR_MESSAGE();
            END CATCH
            FETCH NEXT FROM fk_cur INTO @FkName, @ParentTable;
        END
        CLOSE fk_cur;
        DEALLOCATE fk_cur;

        -- Eliminar la tabla
        SET @Sql = N'DROP TABLE ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@NombreTabla) + N';';
        BEGIN TRY
            EXEC sp_executesql @Sql;
            SET @TotalDropped = @TotalDropped + 1;
            PRINT N'Tabla eliminada: ' + @NombreTabla;
        END TRY
        BEGIN CATCH
            PRINT N'Error al eliminar tabla ' + @NombreTabla + N': ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
        PRINT N'(No existe) ' + @NombreTabla;

    FETCH NEXT FROM cur INTO @NombreTabla;
END

CLOSE cur;
DEALLOCATE cur;

PRINT N'--- Total tablas eliminadas: ' + CAST(@TotalDropped AS NVARCHAR(10)) + N' ---';
GO
