-- usp_crm_Deal_Delete (soft) — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_Delete;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_Delete
    @CompanyId INT,
    @DealId    BIGINT,
    @UserId    INT           = NULL,
    @Resultado BIT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT,
    @Id        BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE crm.[Deal]
       SET IsDeleted        = 1,
           DeletedAt        = SYSUTCDATETIME(),
           DeletedByUserId  = @UserId,
           UpdatedByUserId  = @UserId,
           UpdatedAt        = SYSUTCDATETIME()
     WHERE DealId    = @DealId
       AND CompanyId = @CompanyId
       AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Deal no encontrado';
        SET @Id        = NULL;
        RETURN;
    END

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
    SET @Id        = @DealId;
END
GO
