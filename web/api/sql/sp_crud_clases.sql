-- =============================================
-- Stored Procedures CRUD para Clases (Codigo es INT)
-- =============================================

-- DROP
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clases_List')
    DROP PROCEDURE usp_Clases_List
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clases_GetByCodigo')
    DROP PROCEDURE usp_Clases_GetByCodigo
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clases_Insert')
    DROP PROCEDURE usp_Clases_Insert
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clases_Update')
    DROP PROCEDURE usp_Clases_Update
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clases_Delete')
    DROP PROCEDURE usp_Clases_Delete
GO

-- LIST
CREATE PROCEDURE usp_Clases_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM Clases 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Descripcion LIKE '%' + @Search + '%');
    
    SELECT * FROM Clases 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Descripcion LIKE '%' + @Search + '%')
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- GET BY CODIGO
CREATE PROCEDURE usp_Clases_GetByCodigo
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Clases WHERE Codigo = @Codigo;
END
GO

-- INSERT
CREATE PROCEDURE usp_Clases_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(25) = NULLIF(@x.value('(/row/@Descripcion)[1]', 'nvarchar(25)'), '');
    
    BEGIN TRY
        INSERT INTO Clases (Descripcion)
        VALUES (@Descripcion);
        
        SET @NuevoCodigo = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = 'Clase creada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
        SET @NuevoCodigo = NULL;
    END CATCH
END
GO

-- UPDATE
CREATE PROCEDURE usp_Clases_Update
    @Codigo INT,
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(25) = NULLIF(@x.value('(/row/@Descripcion)[1]', 'nvarchar(25)'), '');
    
    IF NOT EXISTS (SELECT 1 FROM Clases WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Clase no encontrada';
        RETURN;
    END
    
    BEGIN TRY
        UPDATE Clases SET Descripcion = @Descripcion WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Clase actualizada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- DELETE
CREATE PROCEDURE usp_Clases_Delete
    @Codigo INT,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Clases WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Clase no encontrada';
        RETURN;
    END
    
    BEGIN TRY
        DELETE FROM Clases WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Clase eliminada exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Clases_%' ORDER BY name;
