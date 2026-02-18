-- =============================================
-- Stored Procedures CRUD para Tipos (Codigo es INT)
-- =============================================

-- DROP
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Tipos_List')
    DROP PROCEDURE usp_Tipos_List
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Tipos_GetByCodigo')
    DROP PROCEDURE usp_Tipos_GetByCodigo
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Tipos_Insert')
    DROP PROCEDURE usp_Tipos_Insert
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Tipos_Update')
    DROP PROCEDURE usp_Tipos_Update
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Tipos_Delete')
    DROP PROCEDURE usp_Tipos_Delete
GO

-- LIST
CREATE PROCEDURE usp_Tipos_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM Tipos 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Nombre LIKE '%' + @Search + '%' OR Categoria LIKE '%' + @Search + '%');
    
    SELECT * FROM Tipos 
    WHERE (@Search IS NULL OR CAST(Codigo AS NVARCHAR(20)) LIKE '%' + @Search + '%' OR Nombre LIKE '%' + @Search + '%' OR Categoria LIKE '%' + @Search + '%')
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- GET BY CODIGO
CREATE PROCEDURE usp_Tipos_GetByCodigo
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Tipos WHERE Codigo = @Codigo;
END
GO

-- INSERT
CREATE PROCEDURE usp_Tipos_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre NVARCHAR(50) = NULLIF(@x.value('(/row/@Nombre)[1]', 'nvarchar(50)'), '');
    DECLARE @Categoria NVARCHAR(50) = NULLIF(@x.value('(/row/@Categoria)[1]', 'nvarchar(50)'), '');
    DECLARE @Co_Usuario NVARCHAR(10) = NULLIF(@x.value('(/row/@Co_Usuario)[1]', 'nvarchar(10)'), '');
    
    BEGIN TRY
        INSERT INTO Tipos (Nombre, Categoria, Co_Usuario)
        VALUES (@Nombre, @Categoria, @Co_Usuario);
        
        SET @NuevoCodigo = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = 'Tipo creado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
        SET @NuevoCodigo = NULL;
    END CATCH
END
GO

-- UPDATE
CREATE PROCEDURE usp_Tipos_Update
    @Codigo INT,
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre NVARCHAR(50) = NULLIF(@x.value('(/row/@Nombre)[1]', 'nvarchar(50)'), '');
    DECLARE @Categoria NVARCHAR(50) = NULLIF(@x.value('(/row/@Categoria)[1]', 'nvarchar(50)'), '');
    DECLARE @Co_Usuario NVARCHAR(10) = NULLIF(@x.value('(/row/@Co_Usuario)[1]', 'nvarchar(10)'), '');
    
    IF NOT EXISTS (SELECT 1 FROM Tipos WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Tipo no encontrado';
        RETURN;
    END
    
    BEGIN TRY
        UPDATE Tipos SET Nombre = @Nombre, Categoria = @Categoria, Co_Usuario = @Co_Usuario WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Tipo actualizado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- DELETE
CREATE PROCEDURE usp_Tipos_Delete
    @Codigo INT,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Tipos WHERE Codigo = @Codigo)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Tipo no encontrado';
        RETURN;
    END
    
    BEGIN TRY
        DELETE FROM Tipos WHERE Codigo = @Codigo;
        SET @Resultado = 1;
        SET @Mensaje = 'Tipo eliminado exitosamente';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Tipos_%' ORDER BY name;
