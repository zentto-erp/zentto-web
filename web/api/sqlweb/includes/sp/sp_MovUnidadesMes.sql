-- =============================================
-- sp_MovUnidadesMes: rellena MovInventMes para un mes (Libro Auxiliar Art. 177 LISR)
-- El inventario inicial del mes = cierre del mes anterior (tabla CierreMensualInventario).
-- Si se indica @CerrarMesAnterior = 1, antes cierra el mes anterior para que ese cierre sea el inicio de este mes.
-- =============================================
-- Uso: EXEC sp_MovUnidadesMes @Periodo = '02/2026', @CerrarMesAnterior = 1;  -- cierra enero y rellena febrero
--      EXEC sp_MovUnidadesMes @Periodo = '01/2026';  -- primer mes: no hay cierre anterior, usa MovInvent/Inventario
-- =============================================

IF OBJECT_ID('dbo.sp_MovUnidadesMes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MovUnidadesMes;
GO

CREATE PROCEDURE dbo.sp_MovUnidadesMes
    @Periodo            NVARCHAR(10),   -- MM/YYYY (ej. 02/2026)
    @CerrarMesAnterior  BIT = 1,        -- 1 = ejecutar sp_CerrarMesInventario del mes anterior para que "inicio este mes = cierre mes anterior"
    @RefrescarSiguiente  BIT = 0        -- 1 = ademas refresca el mes siguiente
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mes INT = CAST(LEFT(@Periodo, 2) AS INT);
    DECLARE @Anio INT = CAST(RIGHT(@Periodo, 4) AS INT);
    DECLARE @PrevDate DATE;
    DECLARE @PrevPeriodo NVARCHAR(10);
    DECLARE @NextPeriodo NVARCHAR(10);

    IF @Periodo IS NULL OR LTRIM(RTRIM(@Periodo)) = ''
    BEGIN
        RAISERROR('@Periodo es requerido (formato MM/YYYY).', 16, 1);
        RETURN;
    END

    IF @CerrarMesAnterior = 1
    BEGIN
        SET @PrevDate = DATEADD(MONTH, -1, DATEFROMPARTS(@Anio, @Mes, 1));
        SET @PrevPeriodo = FORMAT(@PrevDate, 'MM/yyyy');
        IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CerrarMesInventario')
            EXEC dbo.sp_CerrarMesInventario @Periodo = @PrevPeriodo;
    END

    EXEC dbo.sp_MovUnidades @Periodo = @Periodo;

    IF @RefrescarSiguiente = 1
    BEGIN
        SET @NextPeriodo = FORMAT(DATEADD(MONTH, 1, DATEFROMPARTS(@Anio, @Mes, 1)), 'MM/yyyy');
        EXEC dbo.sp_MovUnidades @Periodo = @NextPeriodo;
    END
END
GO
