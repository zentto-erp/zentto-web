-- =============================================
-- Stored Procedures CRUD para Grupos (Codigo es INT)
-- =============================================

-- DROP
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Grupos_List')
    DROP PROCEDURE usp_Grupos_List
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Grupos_GetByCodigo')
    DROP PROCEDURE usp_Grupos_GetByCodigo
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Grupos_Insert')
    DROP PROCEDURE usp_Grupos_Insert
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Grupos_Update')
    DROP PROCEDURE usp_Grupos_Update
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Grupos_Delete')
    DROP PROCEDURE usp_Grupos_Delete
GO

-- LIST
CREATE PROCEDURE usp_Grupos_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM Grupos 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Descripcion LIKE '%' + @Search + '%');
    
    SELECT * FROM Grupos 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Descripcion LIKE '%' + @Search + '%')
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- GET BY CODIGO
CREATE PROCEDURE usp_Grupos_GetByCodigo
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Grupos WHERE Codigo = @Codigo;
END
GO

-- INSERT
CREATE PROCEDURE usp_Grupos_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(50) = NULLIF(@x.value('(/row/@Descripcion)[1]', 'nvarchar(50)'), '');
    DECLARE @Co_Usuario NVARCHAR(10) = NULLIF(@x.value('(/row/@Co_Usuario)[1]', 'nvarchar(10)'), '');
    DECLARE @PorcentajeStr NVARCHAR(50) = NULLIF(@x.value('(/row/@Porcentaje)[1]', 'nvarchar(50)'), '');
    DECLARE @Porcentaje FLOAT = CASE WHEN ISNUMERIC(@PorcentajeStr) = 1 THEN CAST(@PorcentajeStr AS FLOAT) ELSE 0 END;
    
    BEGIN TRY
        INSERT INTO Grupos (Descripcion, Co_Usuario, Porcentaje)
        VALUES (@Descripcion, @Co_Usuario, @Porcentaje);
        
        SET @NuevoCodigo = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = 'Grupo creado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
        SET @NuevoCodigo = NULL;
    END CATCH
END
GO

-- UPDATE
CREATE PROCEDURE usp_Grupos_Update
    @Codigo INT,
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Descripcion NVARCHAR(50) = NULLIF(@x.value('(/row/@Descripcion)[1]', 'nvarchar(50)'), '');
    DECLARE @Co_Usuario NVARCHAR(10) = NULLIF(@x.value('(/row/@Co_Usuario)[1]', 'nvarchar(10)'), '');
    DECLARE @PorcentajeStr NVARCHAR(50) = NULLIF(@x.value('(/row/@Porcentaje)[1]', 'nvarchar(50)'), '');
    DECLARE @Porcentaje FLOAT = CASE WHEN ISNUMERIC(@PorcentajeStr) = 1 THEN CAST(@PorcentajeStr AS FLOAT) ELSE 0 END;
    
    IF NOT EXISTS (SELECT 1 FROM Grupos WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Grupo no encontrado';
        RETURN;
    END
    
    BEGIN TRY
        UPDATE Grupos SET Descripcion = @Descripcion, Co_Usuario = @Co_Usuario, Porcentaje = @Porcentaje WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Grupo actualizado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- DELETE
CREATE PROCEDURE usp_Grupos_Delete
    @Codigo INT,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Grupos WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Grupo no encontrado';
        RETURN;
    END
    
    BEGIN TRY
        DELETE FROM Grupos WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Grupo eliminado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Grupos_%' ORDER BY name;
