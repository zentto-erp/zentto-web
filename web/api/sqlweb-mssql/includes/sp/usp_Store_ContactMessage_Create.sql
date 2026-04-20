-- usp_Store_ContactMessage_Create
-- Inserta mensaje del formulario de contacto.

IF OBJECT_ID('dbo.usp_Store_ContactMessage_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_ContactMessage_Create;
GO

CREATE PROCEDURE dbo.usp_Store_ContactMessage_Create
    @CompanyId INT           = 1,
    @Name      NVARCHAR(160) = NULL,
    @Email     NVARCHAR(240) = NULL,
    @Phone     NVARCHAR(40)  = NULL,
    @Subject   NVARCHAR(240) = NULL,
    @Message   NVARCHAR(MAX) = NULL,
    @Source    NVARCHAR(60)  = N'contact',
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT,
    @OutId     BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = N''
    BEGIN SET @Resultado = 0; SET @Mensaje = N'name requerido';    SET @OutId = NULL; RETURN; END
    IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = N''
    BEGIN SET @Resultado = 0; SET @Mensaje = N'email requerido';   SET @OutId = NULL; RETURN; END
    IF @Message IS NULL OR LTRIM(RTRIM(@Message)) = N''
    BEGIN SET @Resultado = 0; SET @Mensaje = N'message requerido'; SET @OutId = NULL; RETURN; END

    INSERT INTO store.ContactMessage (CompanyId, Name, Email, Phone, Subject, Message, Source)
    VALUES (@CompanyId, @Name, @Email, @Phone, @Subject, @Message, ISNULL(@Source, N'contact'));

    SET @OutId     = CAST(SCOPE_IDENTITY() AS BIGINT);
    SET @Resultado = 1;
    SET @Mensaje   = N'creado';
END
GO
