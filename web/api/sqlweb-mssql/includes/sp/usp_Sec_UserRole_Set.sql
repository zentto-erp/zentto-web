-- usp_Sec_UserRole_Set
-- Replaces user roles (delete old, insert new from JSON array).
-- Compatible SQL Server 2012+ (uses OPENXML instead of OPENJSON)

IF OBJECT_ID('dbo.usp_Sec_UserRole_Set', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_UserRole_Set;
GO

CREATE PROCEDURE dbo.usp_Sec_UserRole_Set
    @UserId     INT,
    @RoleIdsJson NVARCHAR(MAX),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Delete existing roles
    DELETE FROM sec.UserRole WHERE UserId = @UserId;

    -- Parse JSON array using XML (SQL Server 2012 compatible)
    DECLARE @xml XML;
    SET @xml = '<r>' + REPLACE(REPLACE(REPLACE(@RoleIdsJson, '[', ''), ']', ''), ',', '</r><r>') + '</r>';

    INSERT INTO sec.UserRole (UserId, RoleId)
    SELECT @UserId, t.v.value('.', 'INT')
      FROM @xml.nodes('/r') t(v)
     WHERE t.v.value('.', 'NVARCHAR(20)') <> '';

    SET @Resultado = 1;
    SET @Mensaje = N'Roles asignados al usuario ' + CAST(@UserId AS NVARCHAR(20));
END
GO
