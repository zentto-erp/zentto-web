-- usp_Store_PressRelease_Delete

IF OBJECT_ID('dbo.usp_Store_PressRelease_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_PressRelease_Delete;
GO

CREATE PROCEDURE dbo.usp_Store_PressRelease_Delete
    @CompanyId      INT           = 1,
    @PressReleaseId BIGINT        = NULL,
    @Resultado      INT           OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM store.PressRelease
     WHERE CompanyId = @CompanyId AND PressReleaseId = @PressReleaseId;

    IF @@ROWCOUNT = 0
    BEGIN SET @Resultado = 0; SET @Mensaje = N'no encontrado'; END
    ELSE
    BEGIN SET @Resultado = 1; SET @Mensaje = N'eliminado';     END
END
GO
