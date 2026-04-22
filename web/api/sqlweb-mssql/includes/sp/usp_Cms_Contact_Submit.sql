-- usp_Cms_Contact_Submit
-- INSERT desde endpoint público POST /v1/public/cms/contact/submit.
-- Valida name/email/message, normaliza email a lowercase.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Contact_Submit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Contact_Submit;
GO

CREATE PROCEDURE dbo.usp_Cms_Contact_Submit
    @CompanyId      INT            = 1,
    @Vertical       VARCHAR(50)    = 'corporate',
    @Slug           VARCHAR(100)   = 'contacto',
    @Name           NVARCHAR(200)  = N'',
    @Email          VARCHAR(200)   = '',
    @Subject        NVARCHAR(200)  = N'',
    @Message        NVARCHAR(MAX)  = N'',
    @IpAddress      VARCHAR(45)    = NULL,
    @UserAgent      NVARCHAR(MAX)  = NULL,
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT,
    @OutSubmissionId INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = N''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'name_required';
            SET @OutSubmissionId = NULL;
            RETURN;
        END

        IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = '' OR CHARINDEX('@', @Email) = 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'email_invalid';
            SET @OutSubmissionId = NULL;
            RETURN;
        END

        IF @Message IS NULL OR LTRIM(RTRIM(@Message)) = N''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'message_required';
            SET @OutSubmissionId = NULL;
            RETURN;
        END

        INSERT INTO cms.[ContactSubmission] (
            CompanyId, Vertical, Slug,
            Name, Email, Subject, Message,
            IpAddress, UserAgent
        ) VALUES (
            @CompanyId, @Vertical, @Slug,
            LTRIM(RTRIM(@Name)), LOWER(LTRIM(RTRIM(@Email))), COALESCE(@Subject, N''), @Message,
            @IpAddress, @UserAgent
        );

        SET @OutSubmissionId = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1;
        SET @Mensaje = N'submission_created';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
        SET @OutSubmissionId = NULL;
    END CATCH
END
GO
