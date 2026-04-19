-- usp_CRM_SavedView_Delete
-- Hard delete con tenant+owner guard.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_CRM_SavedView_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CRM_SavedView_Delete;
GO

CREATE PROCEDURE dbo.usp_CRM_SavedView_Delete
    @CompanyId INT,
    @UserId    INT,
    @ViewId    BIGINT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ownerId INT;

    BEGIN TRY
        SELECT @ownerId = UserId
        FROM crm.SavedView
        WHERE ViewId = @ViewId AND CompanyId = @CompanyId;

        IF @ownerId IS NULL
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'Vista no encontrada';
            RETURN;
        END

        IF @ownerId <> @UserId
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'Solo el propietario puede eliminar la vista';
            RETURN;
        END

        DELETE FROM crm.SavedView
        WHERE ViewId = @ViewId AND CompanyId = @CompanyId;

        SET @Resultado = 1;
        SET @Mensaje = N'Vista eliminada';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
