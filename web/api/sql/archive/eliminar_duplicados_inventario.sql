-- =============================================
-- Eliminar filas duplicadas de master.Product (las que se renombraron a ProductCode_Id)
-- Se borran solo las filas cuyo ProductCode termina en '_' + Id (las que eran duplicados).
-- La fila que conservó el ProductCode original se mantiene.
-- Antes operaba sobre dbo.Inventario.CODIGO; ahora opera sobre master.Product.ProductCode.
-- Base: Sanjose.
-- =============================================

USE [Sanjose]
GO

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('master.Product'))
BEGIN
    PRINT N'No existe master.Product.';
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('master.Product') AND name = N'Id')
BEGIN
    PRINT N'master.Product no tiene columna Id; no se pueden identificar duplicados renombrados.';
    RETURN;
END

-- Borrar filas donde ProductCode = algo_Id (el Id de la fila): son las que renombramos como duplicados
-- Antes: DELETE FROM dbo.Inventario WHERE CODIGO LIKE N'%[_]' + CAST(Id AS NVARCHAR(20))
DELETE FROM master.Product
WHERE ProductCode IS NOT NULL
  AND ProductCode LIKE N'%[_]' + CAST(Id AS NVARCHAR(20));    -- ProductCode = CODIGO (canónico)

PRINT N'Eliminadas ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' filas duplicadas de master.Product (ProductCode_Id).';
PRINT N'--- Fin eliminar_duplicados_inventario.sql ---';
