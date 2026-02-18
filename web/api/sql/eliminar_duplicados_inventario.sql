-- =============================================
-- Eliminar filas duplicadas de Inventario (las que se renombraron a CODIGO_Id)
-- Se borran solo las filas cuyo CODIGO termina en '_' + Id (las que eran duplicados).
-- La fila que conservó el CODIGO original se mantiene.
-- Base: Sanjose.
-- =============================================

USE [Sanjose]
GO

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
BEGIN
    PRINT N'No existe tabla Inventario.';
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inventario') AND name = N'Id')
BEGIN
    PRINT N'Inventario no tiene columna Id; no se pueden identificar duplicados renombrados.';
    RETURN;
END

-- Borrar filas donde CODIGO = algo_Id (el Id de la fila): son las que renombramos como duplicados
DELETE FROM dbo.Inventario
WHERE CODIGO IS NOT NULL
  AND CODIGO LIKE N'%[_]' + CAST(Id AS NVARCHAR(20));

PRINT N'Eliminadas ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' filas duplicadas de Inventario (CODIGO_Id).';
PRINT N'--- Fin eliminar_duplicados_inventario.sql ---';
