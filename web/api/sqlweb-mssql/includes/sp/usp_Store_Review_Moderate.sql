-- usp_Store_Review_Moderate
-- Cambia el status de una review: approved | rejected | pending.

IF OBJECT_ID('dbo.usp_Store_Review_Moderate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Review_Moderate;
GO

CREATE PROCEDURE dbo.usp_Store_Review_Moderate
    @CompanyId INT            = 1,
    @ReviewId  INT            = NULL,
    @Status    NVARCHAR(20)   = NULL,
    @Moderator NVARCHAR(60)   = NULL,
    @Resultado INT            OUTPUT,
    @Mensaje   NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

    BEGIN TRY
        IF @ReviewId IS NULL
        BEGIN SET @Resultado = 0; SET @Mensaje = N'ReviewId requerido'; RETURN; END
        IF @Status NOT IN ('approved', 'rejected', 'pending')
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Status inválido (approved | rejected | pending)'; RETURN; END

        UPDATE store.ProductReview SET
            [Status]        = @Status,
            IsApproved      = CASE WHEN @Status = 'approved' THEN 1 ELSE 0 END,
            ModeratedAt     = @now,
            ModeratorUser   = @Moderator
         WHERE CompanyId = @CompanyId AND ReviewId = @ReviewId;

        IF @@ROWCOUNT = 0
        BEGIN SET @Resultado = 0; SET @Mensaje = N'Review no encontrada'; RETURN; END

        SET @Resultado = 1; SET @Mensaje = N'Review moderada';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99; SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
    END CATCH
END
GO
