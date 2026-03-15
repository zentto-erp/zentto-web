-- =============================================
-- Stored Procedure: Listar Documentos de Compra
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosCompra_List')
    DROP PROCEDURE sp_DocumentosCompra_List
GO

CREATE PROCEDURE sp_DocumentosCompra_List
    @TipoOperacion NVARCHAR(20) = NULL,   -- ORDEN, COMPRA. NULL = todos
    @Search NVARCHAR(100) = NULL,         -- Buscar en NUM_DOC, NOMBRE, RIF
    @CodProveedor NVARCHAR(60) = NULL,    -- Filtrar por proveedor específico
    @Desde DATE = NULL,
    @Hasta DATE = NULL,
    @Anulada BIT = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    -- Contar total
    SELECT @TotalCount = COUNT(1)
    FROM DocumentosCompra
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_DOC LIKE '%' + @Search + '%' 
           OR NOMBRE LIKE '%' + @Search + '%' 
           OR RIF LIKE '%' + @Search + '%'
           OR COD_PROVEEDOR LIKE '%' + @Search + '%')
      AND (@CodProveedor IS NULL OR COD_PROVEEDOR = @CodProveedor)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada);
    
    -- Devolver resultados paginados
    SELECT 
        ID, NUM_DOC, SERIALTIPO, TIPO_OPERACION, COD_PROVEEDOR, NOMBRE, RIF,
        FECHA, FECHA_VENCE, FECHA_RECIBO, HORA,
        SUBTOTAL, MONTO_GRA, MONTO_EXE, EXENTO, IVA, ALICUOTA, TOTAL,
        ANULADA, CANCELADA, RECIBIDA,
        DOC_ORIGEN, NUM_CONTROL, LEGAL,
        CONCEPTO, OBSERV, ALMACEN,
        IVA_RETENIDO, ISLR, MONTO_ISLR,
        COD_USUARIO, FECHA_REPORTE,
        -- Campos calculados
        CASE 
            WHEN ANULADA = 1 THEN 'ANULADO'
            WHEN CANCELADA = 'S' THEN 'PAGADO'
            WHEN RECIBIDA = 'S' THEN 'RECIBIDO'
            ELSE 'PENDIENTE'
        END AS ESTADO
    FROM DocumentosCompra
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_DOC LIKE '%' + @Search + '%' 
           OR NOMBRE LIKE '%' + @Search + '%' 
           OR RIF LIKE '%' + @Search + '%'
           OR COD_PROVEEDOR LIKE '%' + @Search + '%')
      AND (@CodProveedor IS NULL OR COD_PROVEEDOR = @CodProveedor)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada)
    ORDER BY FECHA DESC, ID DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- SP para obtener un documento específico con su detalle
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosCompra_Get')
    DROP PROCEDURE sp_DocumentosCompra_Get
GO

CREATE PROCEDURE sp_DocumentosCompra_Get
    @NumDoc NVARCHAR(60),
    @TipoOperacion NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT * FROM DocumentosCompra
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;
    
    -- Detalle
    SELECT * FROM DocumentosCompraDetalle
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion
    ORDER BY RENGLON;
    
    -- Pagos
    SELECT * FROM DocumentosCompraPago
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'sp_DocumentosCompra_%';
