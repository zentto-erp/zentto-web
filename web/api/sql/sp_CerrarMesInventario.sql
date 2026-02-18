-- =============================================
-- sp_CerrarMesInventario: calcula y guarda el cierre de inventario de un mes.
-- Ese cierre será el inventario inicial del mes siguiente.
-- Fuente: MovInvent (que se llena con cada operación de venta/compra/ajuste).
-- Ejecutar al cierre del mes: EXEC sp_CerrarMesInventario @Periodo = '01/2026';
-- =============================================

IF OBJECT_ID('dbo.sp_CerrarMesInventario', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CerrarMesInventario;
GO

CREATE PROCEDURE dbo.sp_CerrarMesInventario
    @Periodo NVARCHAR(10)   -- MM/YYYY (ej. 01/2026)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mes INT, @Anio INT, @Fin DATE, @FinDateTime DATETIME;
    SET @Mes = CAST(LEFT(@Periodo, 2) AS INT);
    SET @Anio = CAST(RIGHT(@Periodo, 4) AS INT);
    SET @Fin = EOMONTH(DATEFROMPARTS(@Anio, @Mes, 1));
    SET @FinDateTime = CAST(DATEADD(DAY, 1, @Fin) AS DATETIME);  -- Fecha < @FinDateTime equivale a Fecha <= @Fin

    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CierreMensualInventario')
    BEGIN
        RAISERROR('Crear antes la tabla CierreMensualInventario (create_cierre_mensual_inventario.sql).', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.CierreMensualInventario WHERE Periodo = @Periodo;

    -- Ultimo movimiento por producto hasta @Fin: rango Fecha < @FinDateTime para usar indice
    ;WITH UltimoMov AS (
        SELECT
            ISNULL(m.Codigo, m.Product) AS Codigo,
            m.cantidad_nueva AS CantidadFinal,
            ISNULL(m.Precio_Compra, 0) AS CostoUnitario,
            ROW_NUMBER() OVER (PARTITION BY ISNULL(m.Codigo, m.Product) ORDER BY m.Fecha DESC, m.id DESC) AS rn
        FROM dbo.MovInvent m
        WHERE m.Fecha < @FinDateTime
          AND ISNULL(m.Anulada, 0) = 0
          AND (m.Codigo IS NOT NULL AND LTRIM(RTRIM(m.Codigo)) <> '' OR m.Product IS NOT NULL AND LTRIM(RTRIM(m.Product)) <> '')
    )
    INSERT INTO dbo.CierreMensualInventario (Periodo, Codigo, Descripcion, CantidadFinal, MontoFinal, CostoUnitario, FechaCierre)
    SELECT
        @Periodo,
        u.Codigo,
        i.DESCRIPCION,
        u.CantidadFinal,
        u.CantidadFinal * u.CostoUnitario,
        u.CostoUnitario,
        GETDATE()
    FROM UltimoMov u
    LEFT JOIN dbo.Inventario i ON i.CODIGO = u.Codigo
    WHERE u.rn = 1 AND u.CantidadFinal <> 0;

    -- Productos con existencia en Inventario que no tengan ningún movimiento hasta @Fin (ej. nuevos o sin historial)
    INSERT INTO dbo.CierreMensualInventario (Periodo, Codigo, Descripcion, CantidadFinal, MontoFinal, CostoUnitario, FechaCierre)
    SELECT
        @Periodo,
        i.CODIGO,
        i.DESCRIPCION,
        ISNULL(i.EXISTENCIA, 0),
        ISNULL(i.EXISTENCIA, 0) * ISNULL(i.COSTO_REFERENCIA, i.COSTO_PROMEDIO),
        ISNULL(i.COSTO_REFERENCIA, i.COSTO_PROMEDIO),
        GETDATE()
    FROM dbo.Inventario i
    WHERE ISNULL(i.EXISTENCIA, 0) > 0
      AND i.CODIGO IS NOT NULL AND LTRIM(RTRIM(i.CODIGO)) <> ''
      AND NOT EXISTS (SELECT 1 FROM dbo.CierreMensualInventario c WHERE c.Periodo = @Periodo AND c.Codigo = i.CODIGO);

    DECLARE @Filas INT = @@ROWCOUNT;
    SELECT @Filas AS ProductosCerrados, @Periodo AS Periodo, @Fin AS FechaCierre;
END
GO
