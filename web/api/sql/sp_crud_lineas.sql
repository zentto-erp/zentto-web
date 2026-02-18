-- =============================================
-- Stored Procedures CRUD para Lineas (CODIGO es INT)
-- =============================================

-- DROP
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Lineas_List')
    DROP PROCEDURE usp_Lineas_List
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Lineas_GetByCodigo')
    DROP PROCEDURE usp_Lineas_GetByCodigo
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Lineas_Insert')
    DROP PROCEDURE usp_Lineas_Insert
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Lineas_Update')
    DROP PROCEDURE usp_Lineas_Update
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Lineas_Delete')
    DROP PROCEDURE usp_Lineas_Delete
GO

-- LIST
CREATE PROCEDURE usp_Lineas_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM Lineas 
    WHERE (@Search IS NULL OR CAST(CODIGO AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR DESCRIPCION LIKE '%' + @Search + '%');
    
    SELECT * FROM Lineas 
    WHERE (@Search IS NULL OR CAST(CODIGO AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR DESCRIPCION LIKE '%' + @Search + '%')
    ORDER BY CODIGO
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- GET BY CODIGO
CREATE PROCEDURE usp_Lineas_GetByCodigo
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Lineas WHERE CODIGO = @Codigo;
END
GO

-- INSERT
CREATE PROCEDURE usp_Lineas_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(50) = NULLIF(@x.value('(/row/@DESCRIPCION)[1]', 'nvarchar(50)'), '');
    
    BEGIN TRY
        INSERT INTO Lineas (DESCRIPCION)
        VALUES (@Descripcion);
        
        SET @NuevoCodigo = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = 'Linea creada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
        SET @NuevoCodigo = NULL;
    END CATCH
END
GO

-- UPDATE
CREATE PROCEDURE usp_Lineas_Update
    @Codigo INT,
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(50) = NULLIF(@x.value('(/row/@DESCRIPCION)[1]', 'nvarchar(50)'), '');
    
    IF NOT EXISTS (SELECT 1 FROM Lineas WHERE CODIGO = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Linea no encontrada';
        RETURN;
    END
    
    BEGIN TRY
        UPDATE Lineas SET DESCRIPCION = @Descripcion WHERE CODIGO = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Linea actualizada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- DELETE
CREATE PROCEDURE usp_Lineas_Delete
    @Codigo INT,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Lineas WHERE CODIGO = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Linea no encontrada';
        RETURN;
    END
    
    BEGIN TRY
        DELETE FROM Lineas WHERE CODIGO = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Linea eliminada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Lineas_%' ORDER BY name;
