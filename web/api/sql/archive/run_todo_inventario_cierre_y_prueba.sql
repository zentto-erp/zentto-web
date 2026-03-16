-- =============================================
-- Reemplaza todo (tabla + SPs) y prueba a nivel SP contra la base.
-- Ejecutar sobre la base Sanjose (o la que uses).
--
-- OPCIÓN A - sqlcmd (incluye los SPs automáticamente):
--   cd "web\api\sql"
--   sqlcmd -S . -d Sanjose -i run_todo_inventario_cierre_y_prueba.sql
--
-- OPCIÓN B - SSMS: ejecutar ANTES seed_data_inventario_prueba.sql y los 3 SPs en orden:
--   seed_data_inventario_prueba.sql, sp_CerrarMesInventario.sql, sp_MovUnidades.sql, sp_MovUnidadesMes.sql
--   Luego comentar o borrar las 4 líneas ":r ..." abajo y ejecutar este script.
-- =============================================

-- 1) Crear tabla de cierre si no existe
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CierreMensualInventario')
BEGIN
    CREATE TABLE dbo.CierreMensualInventario (
        Periodo       NVARCHAR(10) NOT NULL,
        Codigo        NVARCHAR(60) NOT NULL,
        Descripcion   NVARCHAR(255) NULL,
        CantidadFinal FLOAT NOT NULL DEFAULT 0,
        MontoFinal    FLOAT NOT NULL DEFAULT 0,
        CostoUnitario FLOAT NOT NULL DEFAULT 0,
        FechaCierre   DATETIME NULL DEFAULT GETDATE(),
        CONSTRAINT PK_CierreMensualInventario PRIMARY KEY (Periodo, Codigo)
    );
    CREATE INDEX IX_CierreMensualInventario_Periodo ON dbo.CierreMensualInventario(Periodo);
    PRINT N'Tabla CierreMensualInventario creada.';
END
ELSE
    PRINT N'Tabla CierreMensualInventario ya existe.';
GO

-- 2) Generar datos de prueba (movimientos iniciales, compras, ventas) si hace falta
:r seed_data_inventario_prueba.sql

-- 3) Resumen de información en la base (antes de ejecutar SPs)
PRINT N'--- Resumen de tablas (antes) ---';
SELECT N'MovInvent' AS Tabla, COUNT(*) AS Filas FROM dbo.MovInvent
UNION ALL
SELECT N'Inventario', COUNT(*) FROM dbo.Inventario
UNION ALL
SELECT N'MovInventMes', COUNT(*) FROM dbo.MovInventMes
UNION ALL
SELECT N'CierreMensualInventario', COUNT(*) FROM dbo.CierreMensualInventario;
GO

PRINT N'--- Rango de fechas en MovInvent ---';
SELECT MIN(CAST(Fecha AS DATE)) AS FechaMin, MAX(CAST(Fecha AS DATE)) AS FechaMax, COUNT(*) AS TotalFilas FROM dbo.MovInvent;
GO

-- 4) Reemplazar SPs (ejecutar los scripts en el mismo batch no es posible por GO; se hace por archivos o copiando)
-- Aquí se invoca por :r si usas sqlcmd desde esta carpeta:
-- sqlcmd -S SERVIDOR -d Sanjose -i run_todo_inventario_cierre_y_prueba.sql

:r sp_CerrarMesInventario.sql
:r sp_MovUnidades.sql
:r sp_MovUnidadesMes.sql

-- 4) Obtener período de prueba (un mes que tenga datos en MovInvent, o mes actual)
PRINT N'--- Período de prueba ---';
DECLARE @PeriodoPrueba NVARCHAR(10) = FORMAT(GETDATE(), 'MM/yyyy');
IF EXISTS (SELECT 1 FROM dbo.MovInvent)
    SELECT TOP 1 @PeriodoPrueba = FORMAT(Fecha, 'MM/yyyy') FROM dbo.MovInvent ORDER BY Fecha DESC;

PRINT N'Periodo de prueba: ' + @PeriodoPrueba;

-- 5) Ejecutar cierre del período de prueba
EXEC dbo.sp_CerrarMesInventario @Periodo = @PeriodoPrueba;

-- 6) Rellenar MovInventMes para ese período
EXEC dbo.sp_MovUnidades @Periodo = @PeriodoPrueba;

-- 7) Resumen después
PRINT N'--- Resumen después de SPs ---';
SELECT N'MovInventMes' AS Tabla, COUNT(*) AS Filas FROM dbo.MovInventMes WHERE Periodo = @PeriodoPrueba;
SELECT N'CierreMensualInventario' AS Tabla, COUNT(*) AS Filas FROM dbo.CierreMensualInventario WHERE Periodo = @PeriodoPrueba;

-- 8) Mostrar algunas filas de MovInventMes del período
SELECT TOP 25 Periodo, Codigo, Descripcion, Costo, Inicial, Entradas, Salidas, AutoConsumo, Retiros, Final, fecha
FROM dbo.MovInventMes
WHERE Periodo = @PeriodoPrueba
ORDER BY fecha, Codigo;

PRINT N'--- Fin run_todo_inventario_cierre_y_prueba.sql ---';
GO
