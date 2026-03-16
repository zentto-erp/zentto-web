-- =============================================
-- Stored Procedures CRUD: Empleados
-- Compatible con: SQL Server 2012+
-- PK: CEDULA nvarchar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empleados_List')
    DROP PROCEDURE usp_Empleados_List
GO
CREATE PROCEDURE usp_Empleados_List
    @Search NVARCHAR(100) = NULL,
    @Grupo NVARCHAR(50) = NULL,
    @Status NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Grupo NVARCHAR(50), @Status NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CEDULA LIKE @Search OR NOMBRE LIKE @Search OR CARGO LIKE @Search)';
    IF @Grupo IS NOT NULL AND LTRIM(RTRIM(@Grupo)) <> N''
        SET @Where = @Where + N' AND GRUPO = @Grupo';
    IF @Status IS NOT NULL AND LTRIM(RTRIM(@Status)) <> N''
        SET @Where = @Where + N' AND STATUS = @Status';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Empleados] ' + @Where + N';
    SELECT * FROM [dbo].[Empleados] ' + @Where + N'
    ORDER BY NOMBRE
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Grupo = @Grupo,
        @Status = @Status,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Cedula ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empleados_GetByCedula')
    DROP PROCEDURE usp_Empleados_GetByCedula
GO
CREATE PROCEDURE usp_Empleados_GetByCedula
    @Cedula NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Empleados] WHERE CEDULA = @Cedula;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empleados_Insert')
    DROP PROCEDURE usp_Empleados_Insert
GO
CREATE PROCEDURE usp_Empleados_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @xml.value('(/row/@CEDULA)[1]', 'NVARCHAR(20)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Empleados] (
            CEDULA, GRUPO, NOMBRE, DIRECCION, TELEFONO, NACIMIENTO, CARGO, NOMINA,
            SUELDO, INGRESO, RETIRO, STATUS, COMISION, UTILIDAD, CO_Usuario,
            SEXO, NACIONALIDAD, Autoriza, Apodo
        )
        SELECT
            NULLIF(r.value('@CEDULA', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@GRUPO', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(100)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            CASE WHEN r.value('@NACIMIENTO', 'NVARCHAR(50)') IS NULL OR r.value('@NACIMIENTO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@NACIMIENTO', 'NVARCHAR(50)') AS DATETIME) END,
            NULLIF(r.value('@CARGO', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@NOMINA', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@SUELDO', 'NVARCHAR(50)') IS NULL OR r.value('@SUELDO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@SUELDO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@INGRESO', 'NVARCHAR(50)') IS NULL OR r.value('@INGRESO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@INGRESO', 'NVARCHAR(50)') AS DATETIME) END,
            CASE WHEN r.value('@RETIRO', 'NVARCHAR(50)') IS NULL OR r.value('@RETIRO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@RETIRO', 'NVARCHAR(50)') AS DATETIME) END,
            NULLIF(r.value('@STATUS', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@COMISION', 'NVARCHAR(50)') IS NULL OR r.value('@COMISION', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@COMISION', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@UTILIDAD', 'NVARCHAR(50)') IS NULL OR r.value('@UTILIDAD', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@UTILIDAD', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@CO_Usuario', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@SEXO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@NACIONALIDAD', 'NVARCHAR(50)'), N''),
            ISNULL(r.value('@Autoriza', 'BIT'), 0),
            NULLIF(r.value('@Apodo', 'NVARCHAR(50)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 4. Update ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empleados_Update')
    DROP PROCEDURE usp_Empleados_Update
GO
CREATE PROCEDURE usp_Empleados_Update
    @Cedula NVARCHAR(20),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @Cedula)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado no encontrado';
            RETURN;
        END

        UPDATE e SET
            GRUPO = COALESCE(NULLIF(r.value('@GRUPO', 'NVARCHAR(50)'), N''), e.GRUPO),
            NOMBRE = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(100)'), N''), e.NOMBRE),
            DIRECCION = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), e.DIRECCION),
            TELEFONO = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), e.TELEFONO),
            CARGO = COALESCE(NULLIF(r.value('@CARGO', 'NVARCHAR(50)'), N''), e.CARGO),
            NOMINA = COALESCE(NULLIF(r.value('@NOMINA', 'NVARCHAR(50)'), N''), e.NOMINA),
            SUELDO = CASE WHEN r.value('@SUELDO', 'NVARCHAR(50)') IS NULL OR r.value('@SUELDO', 'NVARCHAR(50)') = '' THEN e.SUELDO ELSE CAST(r.value('@SUELDO', 'NVARCHAR(50)') AS FLOAT) END,
            STATUS = COALESCE(NULLIF(r.value('@STATUS', 'NVARCHAR(50)'), N''), e.STATUS),
            COMISION = CASE WHEN r.value('@COMISION', 'NVARCHAR(50)') IS NULL OR r.value('@COMISION', 'NVARCHAR(50)') = '' THEN e.COMISION ELSE CAST(r.value('@COMISION', 'NVARCHAR(50)') AS FLOAT) END,
            SEXO = COALESCE(NULLIF(r.value('@SEXO', 'NVARCHAR(10)'), N''), e.SEXO),
            NACIONALIDAD = COALESCE(NULLIF(r.value('@NACIONALIDAD', 'NVARCHAR(50)'), N''), e.NACIONALIDAD),
            Autoriza = ISNULL(r.value('@Autoriza', 'BIT'), e.Autoriza)
        FROM [dbo].[Empleados] e
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE e.CEDULA = @Cedula;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 5. Delete ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empleados_Delete')
    DROP PROCEDURE usp_Empleados_Delete
GO
CREATE PROCEDURE usp_Empleados_Delete
    @Cedula NVARCHAR(20),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Empleados] WHERE CEDULA = @Cedula)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Empleado no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Empleados] WHERE CEDULA = @Cedula;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- Verificar
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Empleados_%';
