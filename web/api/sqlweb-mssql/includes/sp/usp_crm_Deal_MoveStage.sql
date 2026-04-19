-- usp_crm_Deal_MoveStage — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_MoveStage', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_MoveStage;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_MoveStage
    @CompanyId  INT,
    @DealId     BIGINT,
    @NewStageId BIGINT,
    @Notes      NVARCHAR(MAX) = NULL,
    @UserId     INT           = NULL,
    @Resultado  BIT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT,
    @Id         BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStage BIGINT;
    SELECT @OldStage = StageId
      FROM crm.[Deal]
     WHERE DealId    = @DealId
       AND CompanyId = @CompanyId
       AND IsDeleted = 0;

    IF @OldStage IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Deal no encontrado';
        SET @Id        = NULL;
        RETURN;
    END

    UPDATE crm.[Deal]
       SET StageId         = @NewStageId,
           UpdatedAt       = SYSUTCDATETIME(),
           UpdatedByUserId = @UserId
     WHERE DealId    = @DealId
       AND CompanyId = @CompanyId;

    INSERT INTO crm.[DealHistory] (DealId, ChangeType, Notes, UserId)
    VALUES (@DealId, 'STAGE_CHANGE', @Notes, @UserId);

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
    SET @Id        = @DealId;
END
GO
