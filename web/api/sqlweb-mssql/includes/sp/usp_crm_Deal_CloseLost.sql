-- usp_crm_Deal_CloseLost — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_CloseLost', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_CloseLost;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_CloseLost
    @CompanyId INT,
    @DealId    BIGINT,
    @Reason    NVARCHAR(500) = NULL,
    @UserId    INT           = NULL,
    @Resultado BIT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT,
    @Id        BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE crm.[Deal]
       SET [Status]         = 'LOST',
           WonLostReason    = @Reason,
           ActualCloseDate  = CAST(SYSUTCDATETIME() AS DATE),
           ClosedAt         = SYSUTCDATETIME(),
           UpdatedAt        = SYSUTCDATETIME(),
           UpdatedByUserId  = @UserId
     WHERE DealId    = @DealId
       AND CompanyId = @CompanyId
       AND IsDeleted = 0
       AND [Status]  = 'OPEN';

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Deal no encontrado o ya cerrado';
        SET @Id        = NULL;
        RETURN;
    END

    INSERT INTO crm.[DealHistory] (DealId, ChangeType, Notes, UserId)
    VALUES (@DealId, 'LOST', @Reason, @UserId);

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
    SET @Id        = @DealId;
END
GO
