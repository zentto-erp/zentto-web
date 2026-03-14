-- =============================================
-- Crear UNIQUE en master.Product(ProductCode) y FKs DocumentosVentaDetalle/DocumentosCompraDetalle -> master.Product
-- Antes: se creaba el UNIQUE en dbo.Inventario(CODIGO) y las FKs referenciaban dbo.Inventario.
-- Ahora se usa master.Product (ProductCode = CODIGO canónico).
-- ar.SalesDocumentLine.ProductCode y ap.PurchaseDocumentLine.ProductCode son columnas canonicas.
-- =============================================

USE [Sanjose]
GO

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- ---------- 0. Verificar que master.Product existe ----------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('master.Product'))
BEGIN
    PRINT N'No existe master.Product. Ejecutar migracion antes de este script.';
    RETURN;
END
GO

SET NOCOUNT ON;

-- ---------- 1. Crear índice UNIQUE en master.Product(ProductCode) si no existe ----------
-- ProductCode es la columna canonica que reemplaza dbo.Inventario.CODIGO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Product_ProductCode' AND object_id = OBJECT_ID('master.Product') AND has_filter = 1)
BEGIN
    DROP INDEX UQ_Product_ProductCode ON master.Product;
    PRINT N'Índice UQ_Product_ProductCode (filtrado) eliminado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Product_ProductCode' AND object_id = OBJECT_ID('master.Product'))
BEGIN
    BEGIN TRY
        SET QUOTED_IDENTIFIER ON;
        SET ANSI_NULLS ON;
        CREATE UNIQUE NONCLUSTERED INDEX UQ_Product_ProductCode ON master.Product(ProductCode)
        WHERE ProductCode IS NOT NULL;
        PRINT N'Índice UQ_Product_ProductCode creado en master.Product.';
    END TRY
    BEGIN CATCH
        PRINT N'Error UQ_Product_ProductCode: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 2. Igualar longitud COD_SERV a 80 en DocumentosVentaDetalle ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosVentaDetalle')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'DocumentosVentaDetalle' AND COLUMN_NAME = N'COD_SERV' AND CHARACTER_MAXIMUM_LENGTH <> 80)
BEGIN
    ALTER TABLE dbo.DocumentosVentaDetalle ALTER COLUMN COD_SERV NVARCHAR(80) NULL;
    PRINT N'DocumentosVentaDetalle.COD_SERV ajustado a NVARCHAR(80).';
END

-- ---------- 3. Igualar longitud CODIGO a 80 en DocumentosCompraDetalle ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosCompraDetalle')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'DocumentosCompraDetalle' AND COLUMN_NAME = N'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 80)
BEGIN
    ALTER TABLE dbo.DocumentosCompraDetalle ALTER COLUMN CODIGO NVARCHAR(80) NULL;
    PRINT N'DocumentosCompraDetalle.CODIGO ajustado a NVARCHAR(80).';
END

-- ---------- 4. FK DocumentosVentaDetalle.COD_SERV -> master.Product(ProductCode) ----------
-- Antes: FK_DocumentosVentaDetalle_Inventario -> dbo.Inventario(CODIGO)
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- Eliminar FK legacy si aún existe (referenciaba dbo.Inventario)
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosVentaDetalle_Inventario')
BEGIN
    ALTER TABLE dbo.DocumentosVentaDetalle DROP CONSTRAINT FK_DocumentosVentaDetalle_Inventario;
    PRINT N'FK_DocumentosVentaDetalle_Inventario (legacy) eliminada.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosVentaDetalle')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Product_ProductCode' AND object_id = OBJECT_ID('master.Product'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosVentaDetalle_Product')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.DocumentosVentaDetalle ADD CONSTRAINT FK_DocumentosVentaDetalle_Product
            FOREIGN KEY (COD_SERV) REFERENCES master.Product(ProductCode);
        PRINT N'FK_DocumentosVentaDetalle_Product creada (COD_SERV -> master.Product.ProductCode).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_DocumentosVentaDetalle_Product: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- 5. FK DocumentosCompraDetalle.CODIGO -> master.Product(ProductCode) ----------
-- Antes: FK_DocumentosCompraDetalle_Inventario -> dbo.Inventario(CODIGO)

-- Eliminar FK legacy si aún existe (referenciaba dbo.Inventario)
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosCompraDetalle_Inventario')
BEGIN
    ALTER TABLE dbo.DocumentosCompraDetalle DROP CONSTRAINT FK_DocumentosCompraDetalle_Inventario;
    PRINT N'FK_DocumentosCompraDetalle_Inventario (legacy) eliminada.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosCompraDetalle')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Product_ProductCode' AND object_id = OBJECT_ID('master.Product'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosCompraDetalle_Product')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.DocumentosCompraDetalle ADD CONSTRAINT FK_DocumentosCompraDetalle_Product
            FOREIGN KEY (CODIGO) REFERENCES master.Product(ProductCode);
        PRINT N'FK_DocumentosCompraDetalle_Product creada (CODIGO -> master.Product.ProductCode).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_DocumentosCompraDetalle_Product: ' + ERROR_MESSAGE();
    END CATCH
END

PRINT N'--- Fin fix_fk_documentos_inventario.sql — FKs migradas a master.Product ---';
