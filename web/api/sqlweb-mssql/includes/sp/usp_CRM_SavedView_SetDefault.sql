-- usp_CRM_SavedView_SetDefault
-- Marca una vista como default y limpia el flag en las otras del mismo
-- user/entity atomicamente. Solo owner.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_CRM_SavedView_SetDefault', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CRM_SavedView_SetDefault;
GO

CREATE PROCEDURE dbo.usp_CRM_SavedView_SetDefault
    @CompanyId INT,
    @UserId    INT,
    @ViewId    BIGINT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ownerId INT;
    DECLARE @entity VARCHAR(50);

    BEGIN TRY
        SELECT @ownerId = UserId, @entity = Entity
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
            SET @Mensaje = N'Solo el propietario puede marcar default';
            RETURN;
        END

        BEGIN TRAN;

        UPDATE crm.SavedView
           SET IsDefault = 0,
               UpdatedAt = SYSUTCDATETIME()
         WHERE CompanyId = @CompanyId
           AND UserId    = @UserId
           AND Entity    = @entity
           AND IsDefault = 1
           AND ViewId   <> @ViewId;

        UPDATE crm.SavedView
           SET IsDefault = 1,
               UpdatedAt = SYSUTCDATETIME()
         WHERE ViewId = @ViewId AND CompanyId = @CompanyId;

        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje = N'Default actualizado';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
