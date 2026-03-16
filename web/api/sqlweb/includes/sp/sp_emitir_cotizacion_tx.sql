-- =============================================
-- Stored Procedure: Emitir Cotizacion (Transaccional)
-- Descripcion: Emite una cotizacion con detalle (sin inventario)
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_cotizacion_tx')
    DROP PROCEDURE sp_emitir_cotizacion_tx
GO

CREATE PROCEDURE sp_emitir_cotizacion_tx
    @CotizacionXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @CodUsuario NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @cx XML;
    DECLARE @dx XML;
    DECLARE @NumFact NVARCHAR(60);
    DECLARE @Codigo NVARCHAR(60);
    DECLARE @Fecha DATETIME;
    DECLARE @FechaStr NVARCHAR(50);
    DECLARE @Total DECIMAL(18,4);
    DECLARE @TotalStr NVARCHAR(50);
    DECLARE @Nombre NVARCHAR(200);
    DECLARE @SerialTipo NVARCHAR(60);
    
    BEGIN TRY
        SET @cx = CAST(@CotizacionXml AS XML);
        SET @dx = CAST(@DetalleXml AS XML);
        
        SET @NumFact = NULLIF(@cx.value('(/cotizacion/@NUM_FACT)[1]', 'nvarchar(60)'), '');
        SET @Codigo = NULLIF(@cx.value('(/cotizacion/@CODIGO)[1]', 'nvarchar(60)'), '');
        SET @FechaStr = NULLIF(@cx.value('(/cotizacion/@FECHA)[1]', 'nvarchar(50)'), '');
        SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE SYSUTCDATETIME() END;
        SET @TotalStr = NULLIF(@cx.value('(/cotizacion/@TOTAL)[1]', 'nvarchar(50)'), '');
        SET @Total = CASE WHEN @TotalStr IS NULL THEN 0 ELSE CAST(@TotalStr AS DECIMAL(18,4)) END;
        SET @Nombre = ISNULL(NULLIF(@cx.value('(/cotizacion/@NOMBRE)[1]', 'nvarchar(200)'), ''), '');
        SET @SerialTipo = ISNULL(NULLIF(@cx.value('(/cotizacion/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
        
        IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
        BEGIN
            RAISERROR('missing_num_fact', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Cotizacion WHERE NUM_FACT = @NumFact)
        BEGIN
            RAISERROR('cotizacion_already_exists', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- 1. Insertar cabecera
        INSERT INTO Cotizacion (
            NUM_FACT, SERIALTIPO, CODIGO, FECHA, NOMBRE, TOTAL,
            COD_USUARIO, ANULADA, FECHA_REPORTE, CANCELADA
        )
        SELECT 
            @NumFact, @SerialTipo, @Codigo, @Fecha, @Nombre, @Total,
            @CodUsuario, 0, @Fecha, 'N';
        
        -- 2. Insertar detalle
        INSERT INTO Detalle_Cotizacion (
            NUM_FACT, SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD,
            PRECIO, TOTAL, ANULADA, Co_Usuario, Alicuota, PRECIO_DESCUENTO,
            Relacionada, RENGLON, Vendedor, Cod_alterno
        )
        SELECT 
            @NumFact,
            COALESCE(NULLIF(T.X.value('@SERIALTIPO', 'nvarchar(60)'), ''), @SerialTipo),
            NULLIF(T.X.value('@COD_SERV', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@DESCRIPCION', 'nvarchar(255)'), ''),
            @Fecha,
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL THEN 
                (CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END *
                 CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END)
                ELSE CAST(T.X.value('@TOTAL', 'nvarchar(50)') AS FLOAT) END,
            0,
            @CodUsuario,
            CASE WHEN NULLIF(T.X.value('@Alicuota', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@Alicuota', 'nvarchar(50)') AS FLOAT) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN 
                CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END
                ELSE CAST(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS FLOAT) END,
            COALESCE(NULLIF(T.X.value('@Relacionada', 'nvarchar(10)'), ''), '0'),
            CASE WHEN NULLIF(T.X.value('@RENGLON', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@RENGLON', 'nvarchar(50)') AS FLOAT) END,
            NULLIF(T.X.value('@Vendedor', 'nvarchar(60)'), ''),
            NULLIF(T.X.value('@Cod_alterno', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);
        
        COMMIT TRANSACTION;
        
        SELECT 
            CAST(1 AS BIT) AS ok,
            @NumFact AS numFact,
            (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_cotizacion_tx';
