-- usp_Cms_Contact_UpdateStatus
-- PATCH de Status de una ContactSubmission (pending → read → archived).
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Contact_UpdateStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Contact_UpdateStatus;
GO

CREATE PROCEDURE dbo.usp_Cms_Contact_UpdateStatus
    @SubmissionId INT,
    @CompanyId    INT,
    @Status       VARCHAR(20),
    @Resultado    INT            OUTPUT,
    @Mensaje      NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Status IS NULL OR @Status NOT IN ('pending', 'read', 'archived')
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'invalid_status';
            RETURN;
        END

        UPDATE cms.[ContactSubmission]
        SET Status = @Status
        WHERE ContactSubmissionId = @SubmissionId
          AND CompanyId = @CompanyId;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'submission_not_found';
            RETURN;
        END

        SET @Resultado = 1;
        SET @Mensaje = N'status_updated';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
