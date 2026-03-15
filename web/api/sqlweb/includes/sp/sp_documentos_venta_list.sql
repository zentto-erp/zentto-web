-- =============================================
-- Stored Procedure: Listar Documentos de Venta
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosVenta_List')
    DROP PROCEDURE sp_DocumentosVenta_List
GO

CREATE PROCEDURE sp_DocumentosVenta_List
    @TipoOperacion NVARCHAR(20) = NULL,   -- FILTRAR por tipo: FACT, PRESUP, PEDIDO, etc. NULL = todos
    @Search NVARCHAR(100) = NULL,         -- Buscar en NUM_DOC, NOMBRE, RIF, CODIGO
    @Codigo NVARCHAR(60) = NULL,          -- Filtrar por cliente específico
    @Desde DATE = NULL,                   -- Fecha desde
    @Hasta DATE = NULL,                   -- Fecha hasta
    @Anulada BIT = NULL,                  -- Filtrar por estado anulado (NULL = todos)
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    -- Contar total
    SELECT @TotalCount = COUNT(1)
    FROM DocumentosVenta
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_DOC LIKE '%' + @Search + '%' 
           OR NOMBRE LIKE '%' + @Search + '%' 
           OR RIF LIKE '%' + @Search + '%'
           OR CODIGO LIKE '%' + @Search + '%')
      AND (@Codigo IS NULL OR CODIGO = @Codigo)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada);
    
    -- Devolver resultados paginados
    SELECT 
        ID, NUM_DOC, SERIALTIPO, TIPO_OPERACION, CODIGO, NOMBRE, RIF,
        FECHA, FECHA_VENCE, HORA,
        SUBTOTAL, MONTO_GRA, MONTO_EXE, IVA, ALICUOTA, TOTAL, DESCUENTO,
        ANULADA, CANCELADA, FACTURADA, ENTREGADA,
        DOC_ORIGEN, TIPO_DOC_ORIGEN, NUM_CONTROL, LEGAL,
        OBSERV, VENDEDOR, MONEDA, TASA_CAMBIO,
        COD_USUARIO, FECHA_REPORTE,
        -- Campos calculados
        CASE 
            WHEN ANULADA = 1 THEN 'ANULADO'
            WHEN CANCELADA = 'S' THEN 'PAGADO'
            WHEN FACTURADA = 'S' THEN 'FACTURADO'
            ELSE 'PENDIENTE'
        END AS ESTADO
    FROM DocumentosVenta
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_DOC LIKE '%' + @Search + '%' 
           OR NOMBRE LIKE '%' + @Search + '%' 
           OR RIF LIKE '%' + @Search + '%'
           OR CODIGO LIKE '%' + @Search + '%')
      AND (@Codigo IS NULL OR CODIGO = @Codigo)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada)
    ORDER BY FECHA DESC, ID DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- SP para obtener un documento específico con su detalle
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosVenta_Get')
    DROP PROCEDURE sp_DocumentosVenta_Get
GO

CREATE PROCEDURE sp_DocumentosVenta_Get
    @NumDoc NVARCHAR(60),
    @TipoOperacion NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT * FROM DocumentosVenta
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;
    
    -- Detalle
    SELECT * FROM DocumentosVentaDetalle
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion
    ORDER BY RENGLON;
    
    -- Pagos
    SELECT * FROM DocumentosVentaPago
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;
END
GO

-- SP para obtener tipos de operación disponibles
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosVenta_Tipos')
    DROP PROCEDURE sp_DocumentosVenta_Tipos
GO

CREATE PROCEDURE sp_DocumentosVenta_Tipos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        TIPO_OPERACION AS codigo,
        CASE TIPO_OPERACION
            WHEN 'FACT' THEN 'Factura'
            WHEN 'PRESUP' THEN 'Presupuesto'
            WHEN 'PEDIDO' THEN 'Pedido'
            WHEN 'COTIZ' THEN 'Cotización'
            WHEN 'NOTACRED' THEN 'Nota de Crédito'
            WHEN 'NOTADEB' THEN 'Nota de Débito'
            WHEN 'NOTA_ENTREGA' THEN 'Nota de Entrega'
            ELSE TIPO_OPERACION
        END AS nombre,
        COUNT(*) AS cantidad
    FROM DocumentosVenta
    WHERE ANULADA = 0
    GROUP BY TIPO_OPERACION
    ORDER BY TIPO_OPERACION;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'sp_DocumentosVenta_%';
