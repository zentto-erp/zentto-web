-- =============================================
-- Stored Procedures CRUD: Empresa
-- Compatible con: SQL Server 2012+
-- PK: Empresa nvarchar (solo 1 registro usualmente)
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empresa_Get')
    DROP PROCEDURE usp_Empresa_Get
GO
CREATE PROCEDURE usp_Empresa_Get AS
BEGIN SET NOCOUNT ON; SELECT TOP 1 * FROM [dbo].[Empresa]; END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Empresa_Update')
    DROP PROCEDURE usp_Empresa_Update
GO
CREATE PROCEDURE usp_Empresa_Update @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Empresa]) BEGIN SET @Resultado = -1; SET @Mensaje = N'Empresa no encontrada'; RETURN; END
        UPDATE e SET Empresa = COALESCE(NULLIF(r.value('@Empresa', 'NVARCHAR(100)'), N''), e.Empresa),
                     RIF = COALESCE(NULLIF(r.value('@RIF', 'NVARCHAR(50)'), N''), e.RIF),
                     Nit = COALESCE(NULLIF(r.value('@Nit', 'NVARCHAR(50)'), N''), e.Nit),
                     Telefono = COALESCE(NULLIF(r.value('@Telefono', 'NVARCHAR(60)'), N''), e.Telefono),
                     Direccion = COALESCE(NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''), e.Direccion),
                     Rifs = COALESCE(NULLIF(r.value('@Rifs', 'NVARCHAR(50)'), N''), e.Rifs)
        FROM [dbo].[Empresa] e CROSS JOIN @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Empresa_%';
