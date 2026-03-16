-- Benchmark: tiempo de sp_CerrarMesInventario y sp_MovUnidades (periodo 02/2026)
-- Ejecutar despues de crear indices (add_indexes_inventario_cierre.sql) y los SPs (run_solo_crear_sps.sql)
SET NOCOUNT ON;
SET STATISTICS TIME ON;

PRINT '--- Inicio benchmark 02/2026 ---';
DECLARE @t0 DATETIME2 = SYSDATETIME();

EXEC dbo.sp_CerrarMesInventario @Periodo = '02/2026';

DECLARE @t1 DATETIME2 = SYSDATETIME();
PRINT 'CerrarMesInventario: ' + CAST(DATEDIFF(MILLISECOND, @t0, @t1) AS VARCHAR(20)) + ' ms';

EXEC dbo.sp_MovUnidades @Periodo = '02/2026';

DECLARE @t2 DATETIME2 = SYSDATETIME();
PRINT 'MovUnidades: ' + CAST(DATEDIFF(MILLISECOND, @t1, @t2) AS VARCHAR(20)) + ' ms';
PRINT 'Total: ' + CAST(DATEDIFF(MILLISECOND, @t0, @t2) AS VARCHAR(20)) + ' ms';

SET STATISTICS TIME OFF;
PRINT '--- Fin benchmark ---';
