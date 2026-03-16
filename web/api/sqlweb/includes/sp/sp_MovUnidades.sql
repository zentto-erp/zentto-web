-- =============================================
-- sp_MovUnidades: rellena MovInventMes desde MovInvent para un periodo
-- Clasifica cada movimiento en Entradas, Salidas, Autoconsumo, Retiros.
-- Para el reporte "Libro Auxiliar de Entradas y Salidas" (Art. 177 LISR / SENIAT).
-- Metodo PEPS: se usa Precio_Compra al momento del movimiento para el Monto.
-- =============================================
-- Inventario inicial del mes = cierre del mes anterior (tabla CierreMensualInventario).
-- Si no hay cierre guardado, se usa el ultimo movimiento en MovInvent antes del periodo
-- y, si hace falta, Inventario (integridad).
-- Flujo: operaciones (venta/compra/ajuste) -> MovInvent -> cierre mensual -> reporte.
-- =============================================
-- Uso: EXEC sp_MovUnidades @Periodo = '02/2026';  -- antes ejecutar sp_CerrarMesInventario '01/2026'
-- =============================================

IF OBJECT_ID('dbo.sp_MovUnidades', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MovUnidades;
GO

CREATE PROCEDURE dbo.sp_MovUnidades
    @Periodo     NVARCHAR(10) = NULL,   -- Formato MM/YYYY (ej. 01/2024)
    @FechaDesde  DATE         = NULL,
    @FechaHasta  DATE         = NULL,
    @SoloEstructura BIT        = 0      -- 1 = solo crea/limpia, no recalcula (para pruebas)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ini DATE, @Fin DATE, @IniDateTime DATETIME, @FinDateTime DATETIME;
    IF @Periodo IS NOT NULL
    BEGIN
        DECLARE @Mes INT = CAST(LEFT(@Periodo, 2) AS INT);
        DECLARE @Anio INT = CAST(RIGHT(@Periodo, 4) AS INT);
        SET @Ini = DATEFROMPARTS(@Anio, @Mes, 1);
        SET @Fin = EOMONTH(@Ini);
        SET @IniDateTime = CAST(@Ini AS DATETIME);
        SET @FinDateTime = CAST(DATEADD(DAY, 1, @Fin) AS DATETIME);
    END
    ELSE IF @FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL
    BEGIN
        SET @Ini = @FechaDesde;
        SET @Fin = @FechaHasta;
        SET @Periodo = FORMAT(@Ini, 'MM/yyyy');
        SET @IniDateTime = CAST(@Ini AS DATETIME);
        SET @FinDateTime = CAST(DATEADD(DAY, 1, @Fin) AS DATETIME);
    END
    ELSE
    BEGIN
        RAISERROR('Especificar @Periodo (MM/YYYY) o @FechaDesde y @FechaHasta.', 16, 1);
        RETURN;
    END

    -- Asegurar columnas en MovInvent (por si la base es antigua)
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MovInvent') AND name IN ('Precio_Compra','Precio_venta'))
    BEGIN
        RAISERROR('MovInvent debe tener Precio_Compra y Precio_venta para el reporte.', 16, 1);
        RETURN;
    END

    -- Eliminar datos del periodo en MovInventMes para refrescar
    DELETE FROM dbo.MovInventMes WHERE Periodo = @Periodo;

    IF @SoloEstructura = 1
    BEGIN
        SELECT 0 AS FilasInsertadas, @Periodo AS Periodo;
        RETURN;
    END

    -- Clasificacion: 1=Entradas, 2=Salidas, 3=AutoConsumo, 4=Retiros
    ;WITH MovClasificado AS (
        SELECT
            CAST(m.Fecha AS DATE) AS FechaDia,
            ISNULL(m.Codigo, m.Product) AS Codigo,
            m.Cantidad,
            ISNULL(m.Precio_Compra, 0) AS CostoUnit,
            m.Cantidad * ISNULL(m.Precio_Compra, 0) AS Monto,
            CASE
                WHEN UPPER(LTRIM(RTRIM(ISNULL(m.Tipo, '')))) = 'INGRESO' THEN 1
                WHEN UPPER(LTRIM(RTRIM(ISNULL(m.Tipo, '')))) = 'EGRESO' THEN
                    CASE
                        WHEN m.Motivo LIKE N'%Autoconsumo%' OR m.Motivo LIKE N'%autoconsumo%' THEN 3
                        WHEN m.Motivo LIKE N'%FACT%' OR m.Motivo LIKE N'%Doc:%' OR m.Motivo LIKE N'%PEDIDO%'
                             OR m.Motivo LIKE N'%NOTA_ENTREGA%' OR m.Motivo LIKE N'%Presup%'
                             OR m.Motivo LIKE N'%Factura%' OR m.Motivo LIKE N'%Pedido%' THEN 2
                        ELSE 4
                    END
                WHEN UPPER(LTRIM(RTRIM(ISNULL(m.Tipo, '')))) LIKE N'%ANULACION%INGRESO%' THEN 1
                WHEN UPPER(LTRIM(RTRIM(ISNULL(m.Tipo, '')))) LIKE N'%ANULACION%EGRESO%' THEN 1
                ELSE 4
            END AS Clase
        FROM dbo.MovInvent m
        WHERE m.Fecha >= @IniDateTime AND m.Fecha < @FinDateTime
          AND ISNULL(m.Anulada, 0) = 0
          AND (m.Codigo IS NOT NULL AND LTRIM(RTRIM(m.Codigo)) <> '' OR m.Product IS NOT NULL AND LTRIM(RTRIM(m.Product)) <> '')
    ),
    AgregadoDia AS (
        SELECT
            FechaDia,
            Codigo,
            SUM(CASE WHEN Clase = 1 THEN Cantidad ELSE 0 END) AS EntradasCant,
            SUM(CASE WHEN Clase = 1 THEN Monto ELSE 0 END) AS EntradasMonto,
            SUM(CASE WHEN Clase = 2 THEN Cantidad ELSE 0 END) AS SalidasCant,
            SUM(CASE WHEN Clase = 2 THEN Monto ELSE 0 END) AS SalidasMonto,
            SUM(CASE WHEN Clase = 3 THEN Cantidad ELSE 0 END) AS AutoConsumoCant,
            SUM(CASE WHEN Clase = 3 THEN Monto ELSE 0 END) AS AutoConsumoMonto,
            SUM(CASE WHEN Clase = 4 THEN Cantidad ELSE 0 END) AS RetirosCant,
            SUM(CASE WHEN Clase = 4 THEN Monto ELSE 0 END) AS RetirosMonto
        FROM MovClasificado
        GROUP BY FechaDia, Codigo
    ),
    -- Inventario inicial: (1) CierreMensualInventario mes anterior (2) MovInvent ultimo antes del periodo (3) Inventario si no hay historial
    PeriodoAnterior AS (
        SELECT FORMAT(DATEADD(MONTH, -1, @Ini), 'MM/yyyy') AS Periodo
    ),
    InicialDesdeCierre AS (
        SELECT c.Codigo, c.CantidadFinal AS InicialCant, c.CostoUnitario AS CostoUnit
        FROM dbo.CierreMensualInventario c
        INNER JOIN PeriodoAnterior p ON p.Periodo = c.Periodo
        WHERE c.CantidadFinal <> 0
    ),
    InicialMes AS (
        SELECT
            ISNULL(m.Codigo, m.Product) AS Codigo,
            m.cantidad_nueva AS InicialCant,
            ISNULL(m.Precio_Compra, 0) AS CostoUnit,
            ROW_NUMBER() OVER (PARTITION BY ISNULL(m.Codigo, m.Product) ORDER BY m.Fecha DESC, m.id DESC) AS rn
        FROM dbo.MovInvent m
        WHERE m.Fecha < @IniDateTime
          AND ISNULL(m.Anulada, 0) = 0
          AND (m.Codigo IS NOT NULL AND LTRIM(RTRIM(m.Codigo)) <> '' OR m.Product IS NOT NULL AND LTRIM(RTRIM(m.Product)) <> '')
    ),
    InicialDesdeMov AS (
        SELECT Codigo, InicialCant, CostoUnit
        FROM InicialMes
        WHERE rn = 1 AND InicialCant <> 0
          AND NOT EXISTS (SELECT 1 FROM InicialDesdeCierre c WHERE c.Codigo = InicialMes.Codigo)
    ),
    InicialDesdeInventario AS (
        SELECT
            i.ProductCode AS Codigo,                            -- ProductCode = CODIGO (master.Product)
            ISNULL(i.StockQty, 0) AS InicialCant,              -- StockQty = EXISTENCIA (master.Product)
            ISNULL(i.COSTO_REFERENCIA, i.COSTO_PROMEDIO) AS CostoUnit
        FROM master.Product i                                   -- antes dbo.Inventario
        WHERE ISNULL(i.IsDeleted, 0) = 0
          AND ISNULL(i.StockQty, 0) > 0
          AND i.ProductCode IS NOT NULL AND LTRIM(RTRIM(i.ProductCode)) <> ''
          AND NOT EXISTS (SELECT 1 FROM InicialDesdeCierre c WHERE c.Codigo = i.ProductCode)
          AND NOT EXISTS (SELECT 1 FROM InicialDesdeMov m WHERE m.Codigo = i.ProductCode)
    ),
    InicialPorProducto AS (
        SELECT Codigo, InicialCant, CostoUnit FROM InicialDesdeCierre
        UNION ALL
        SELECT Codigo, InicialCant, CostoUnit FROM InicialDesdeMov
        UNION ALL
        SELECT Codigo, InicialCant, CostoUnit FROM InicialDesdeInventario
    ),
    -- (fecha, codigo): movimientos del periodo + primer dia por producto con inicial
    DiasProducto AS (
        SELECT FechaDia, Codigo FROM AgregadoDia
        UNION
        SELECT @Ini, Codigo FROM InicialPorProducto
    ),
    ConInicial AS (
        SELECT
            d.FechaDia,
            d.Codigo,
            ISNULL(i.InicialCant, 0) AS InicialCantMes,
            ISNULL(i.CostoUnit, 0) AS CostoInicial,
            a.EntradasCant, a.EntradasMonto, a.SalidasCant, a.SalidasMonto,
            a.AutoConsumoCant, a.AutoConsumoMonto, a.RetirosCant, a.RetirosMonto
        FROM DiasProducto d
        LEFT JOIN InicialPorProducto i ON i.Codigo = d.Codigo
        LEFT JOIN AgregadoDia a ON a.FechaDia = d.FechaDia AND a.Codigo = d.Codigo
    ),
    ConAcum AS (
        SELECT
            FechaDia, Codigo, InicialCantMes, CostoInicial,
            EntradasCant, EntradasMonto, SalidasCant, SalidasMonto,
            AutoConsumoCant, AutoConsumoMonto, RetirosCant, RetirosMonto,
            SUM(ISNULL(EntradasCant, 0) - ISNULL(SalidasCant, 0) - ISNULL(AutoConsumoCant, 0) - ISNULL(RetirosCant, 0))
                OVER (PARTITION BY Codigo ORDER BY FechaDia ROWS UNBOUNDED PRECEDING) AS Acumulado
        FROM ConInicial
    ),
    -- Inicial del dia = cierre del dia anterior
    ConSaldo AS (
        SELECT
            FechaDia, Codigo, InicialCantMes, CostoInicial,
            EntradasCant, EntradasMonto, SalidasCant, SalidasMonto,
            AutoConsumoCant, AutoConsumoMonto, RetirosCant, RetirosMonto,
            InicialCantMes + Acumulado - (ISNULL(EntradasCant, 0) - ISNULL(SalidasCant, 0) - ISNULL(AutoConsumoCant, 0) - ISNULL(RetirosCant, 0)) AS InicialDelDia,
            InicialCantMes + Acumulado AS FinalDelDia
        FROM ConAcum
    )
    INSERT INTO dbo.MovInventMes (Periodo, Codigo, Descripcion, Costo, Inicial, Entradas, Salidas, AutoConsumo, Retiros, Inventario, Final, fecha)
    SELECT
        @Periodo,
        s.Codigo,
        ISNULL(inv.ProductName, s.Codigo),      -- ProductName = DESCRIPCION (master.Product)
        ISNULL(s.CostoInicial, 0),
        s.InicialDelDia,
        ISNULL(s.EntradasCant, 0),
        ISNULL(s.SalidasCant, 0),
        ISNULL(s.AutoConsumoCant, 0),
        ISNULL(s.RetirosCant, 0),
        s.FinalDelDia * ISNULL(s.CostoInicial, 0),
        s.FinalDelDia,
        s.FechaDia
    FROM ConSaldo s
    -- Ahora se usa master.Product (antes dbo.Inventario)
    LEFT JOIN master.Product inv ON inv.ProductCode = s.Codigo   -- ProductCode = CODIGO, ProductName = DESCRIPCION
    WHERE ISNULL(inv.IsDeleted, 0) = 0 OR inv.ProductCode IS NULL;

    -- Fila resumen INVENTARIO INICIAL MES ANTERIOR (suma Inicial*Costo al primer dia)
    DECLARE @InventarioInicialTotal FLOAT;
    SELECT @InventarioInicialTotal = SUM(Inicial * Costo)
    FROM dbo.MovInventMes
    WHERE Periodo = @Periodo AND fecha = @Ini AND Codigo <> N'0000000001';

    INSERT INTO dbo.MovInventMes (Periodo, Codigo, Descripcion, Costo, Inicial, Entradas, Salidas, AutoConsumo, Retiros, Inventario, Final, AjusteIncial, AjusteFinal, fecha)
    VALUES (
        @Periodo,
        N'0000000001',
        N'INVENTARIO INICIAL MES ANTERIOR',
        ISNULL(@InventarioInicialTotal, 0),
        1,
        0, 0, 0, 0,
        ISNULL(@InventarioInicialTotal, 0),
        1,
        NULL, NULL,
        @Ini
    );

    DECLARE @Filas INT = @@ROWCOUNT;
    SELECT @Filas AS FilasInsertadas, @Periodo AS Periodo;
END
GO
