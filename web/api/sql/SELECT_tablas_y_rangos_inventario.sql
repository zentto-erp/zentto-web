-- =============================================
-- SELECT de tablas de inventario y rangos donde deben estar los registros
-- =============================================

-- ---------------------------------------------------------------------------
-- 1) INVENTARIO
-- Rangos esperados:
--   CODIGO: no nulo, no vacio (LTRIM(RTRIM(CODIGO)) <> '')
--   EXISTENCIA: >= 0 (productos con stock o sin stock)
--   COSTO_REFERENCIA / COSTO_PROMEDIO: >= 0 (costos)
--   PRECIO_VENTA: >= 0
-- ---------------------------------------------------------------------------
SELECT
    CODIGO,
    DESCRIPCION,
    EXISTENCIA,           -- rango: >= 0
    COSTO_REFERENCIA,     -- rango: >= 0
    COSTO_PROMEDIO,       -- rango: >= 0
    PRECIO_COMPRA,
    PRECIO_VENTA,
    Alicuota
FROM dbo.Inventario
WHERE CODIGO IS NOT NULL AND LTRIM(RTRIM(CODIGO)) <> ''
  AND ISNULL(EXISTENCIA, 0) >= 0
ORDER BY CODIGO;

-- Resumen y rango de existencias
SELECT
    COUNT(*) AS TotalArticulos,
    MIN(ISNULL(EXISTENCIA, 0)) AS ExistenciaMin,
    MAX(ISNULL(EXISTENCIA, 0)) AS ExistenciaMax,
    SUM(ISNULL(EXISTENCIA, 0)) AS TotalUnidades
FROM dbo.Inventario
WHERE CODIGO IS NOT NULL AND LTRIM(RTRIM(CODIGO)) <> '';


-- ---------------------------------------------------------------------------
-- 2) MOVINVENT (movimientos de inventario: entradas/salidas)
-- Rangos esperados:
--   Fecha: desde la primera operacion hasta hoy (no futuro si es historico)
--   Tipo: 'Ingreso' | 'Egreso' (y variantes por anulacion)
--   Cantidad: valor del movimiento (positivo; el signo lo da Tipo)
--   cantidad_nueva: >= 0 (saldo despues del movimiento)
--   Codigo/Product: no nulos/vacios para reporte
-- ---------------------------------------------------------------------------
SELECT
    id,
    Codigo,
    Product,
    Fecha,                -- rango: desde primer movimiento hasta ultimo dia del mes a reportar
    Tipo,                 -- 'Ingreso' | 'Egreso'
    Motivo,
    Cantidad_Actual,      -- existencia antes del movimiento
    Cantidad,             -- unidades movidas (siempre positivo)
    cantidad_nueva,       -- rango: >= 0 (saldo despues)
    Precio_Compra,
    Precio_venta,
    Documento,
    ISNULL(Anulada, 0) AS Anulada
FROM dbo.MovInvent
WHERE (Codigo IS NOT NULL AND LTRIM(RTRIM(Codigo)) <> '' OR Product IS NOT NULL AND LTRIM(RTRIM(Product)) <> '')
  AND ISNULL(Anulada, 0) = 0
ORDER BY Fecha, id;

-- Rango de fechas y totales
SELECT
    MIN(CAST(Fecha AS DATE)) AS FechaMin,
    MAX(CAST(Fecha AS DATE)) AS FechaMax,
    COUNT(*) AS TotalMovimientos,
    COUNT(DISTINCT ISNULL(Codigo, Product)) AS ArticulosConMovimiento
FROM dbo.MovInvent
WHERE ISNULL(Anulada, 0) = 0
  AND (Codigo IS NOT NULL AND LTRIM(RTRIM(Codigo)) <> '' OR Product IS NOT NULL AND LTRIM(RTRIM(Product)) <> '');


-- ---------------------------------------------------------------------------
-- 3) CIERREMENSUALINVENTARIO (cierre por mes/producto; inicio del mes siguiente)
-- Rangos esperados:
--   Periodo: formato 'MM/yyyy' (ej. '01/2026' .. '12/2026')
--   CantidadFinal: >= 0 (existencia al cierre del mes)
--   MontoFinal: >= 0 (CantidadFinal * CostoUnitario)
--   CostoUnitario: >= 0
-- ---------------------------------------------------------------------------
SELECT
    Periodo,              -- rango: '01/yyyy' a '12/yyyy'
    Codigo,
    Descripcion,
    CantidadFinal,        -- rango: >= 0
    MontoFinal,           -- rango: >= 0
    CostoUnitario,
    FechaCierre
FROM dbo.CierreMensualInventario
WHERE CantidadFinal <> 0
ORDER BY Periodo, Codigo;

-- Rangos de periodos y totales
SELECT
    MIN(Periodo) AS PeriodoMin,
    MAX(Periodo) AS PeriodoMax,
    COUNT(*) AS FilasCierre,
    COUNT(DISTINCT Periodo) AS MesesCerrados
FROM dbo.CierreMensualInventario;


-- ---------------------------------------------------------------------------
-- 4) MOVINVENTMES (libro auxiliar por periodo/dia para reporte Art. 177 LISR)
-- Rangos esperados:
--   Periodo: 'MM/yyyy' (mes al que corresponde el reporte)
--   fecha: dentro del mes (entre dia 1 y ultimo dia del mes)
--   Inicial, Entradas, Salidas, AutoConsumo, Retiros, Final: >= 0
--   Codigo '0000000001' = fila resumen "INVENTARIO INICIAL MES ANTERIOR"
-- ---------------------------------------------------------------------------
SELECT
    Periodo,              -- rango: 'MM/yyyy'
    Codigo,
    Descripcion,
    Costo,
    Inicial,              -- rango: >= 0
    Entradas,
    Salidas,
    AutoConsumo,
    Retiros,
    Inventario,
    Final,                -- rango: >= 0
    fecha                 -- rango: dentro del mes (1 .. ultimo dia)
FROM dbo.MovInventMes
WHERE Periodo IS NOT NULL
ORDER BY Periodo, fecha, Codigo;

-- Rangos por periodo
SELECT
    Periodo,
    MIN(fecha) AS FechaMin,
    MAX(fecha) AS FechaMax,
    COUNT(*) AS Filas
FROM dbo.MovInventMes
GROUP BY Periodo
ORDER BY Periodo;


-- ---------------------------------------------------------------------------
-- 5) CONSULTAS POR RANGO DE FECHAS/PEROODO (ejemplo)
-- Sustituir @Periodo o @FechaDesde/@FechaHasta segun necesidad
-- ---------------------------------------------------------------------------
/*
DECLARE @Periodo NVARCHAR(10) = '02/2026';

-- MovInvent del mes
SELECT * FROM dbo.MovInvent
WHERE CAST(Fecha AS DATE) BETWEEN DATEFROMPARTS(CAST(RIGHT(@Periodo,4) AS INT), CAST(LEFT(@Periodo,2) AS INT), 1)
                              AND EOMONTH(DATEFROMPARTS(CAST(RIGHT(@Periodo,4) AS INT), CAST(LEFT(@Periodo,2) AS INT), 1))
  AND ISNULL(Anulada, 0) = 0
ORDER BY Fecha, id;

-- Cierre de ese mes
SELECT * FROM dbo.CierreMensualInventario WHERE Periodo = @Periodo ORDER BY Codigo;

-- Libro auxiliar de ese mes
SELECT * FROM dbo.MovInventMes WHERE Periodo = @Periodo ORDER BY fecha, Codigo;
*/
