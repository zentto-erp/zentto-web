SET NOCOUNT ON;
PRINT 'CerrarMesInventario 02/2026 inicio';
DECLARE @t0 DATETIME2 = SYSDATETIME();
EXEC dbo.sp_CerrarMesInventario @Periodo = '02/2026';
PRINT 'CerrarMesInventario: ' + CAST(DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS VARCHAR(20)) + ' ms';
