-- usp_crm_Deal_Upsert — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_Upsert;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_Upsert
    @CompanyId        INT,
    @DealId           BIGINT        = NULL,
    @Name             NVARCHAR(255),
    @PipelineId       BIGINT        = NULL,
    @StageId          BIGINT        = NULL,
    @ContactId        BIGINT        = NULL,
    @CrmCompanyId     BIGINT        = NULL,
    @OwnerAgentId     BIGINT        = NULL,
    @Value            DECIMAL(18,2) = 0,
    @Currency         VARCHAR(3)    = 'USD',
    @Probability      DECIMAL(5,2)  = NULL,
    @ExpectedClose    DATE          = NULL,
    @Priority         VARCHAR(10)   = 'MEDIUM',
    @Source           VARCHAR(50)   = NULL,
    @Notes            NVARCHAR(MAX) = NULL,
    @Tags             VARCHAR(500)  = NULL,
    @BranchId         INT           = 1,
    @UserId           INT           = NULL,
    @Resultado        BIT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT,
    @Id               BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Name, N'') = N''
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Nombre del deal requerido';
        SET @Id        = NULL;
        RETURN;
    END

    IF @DealId IS NULL AND (@PipelineId IS NULL OR @StageId IS NULL)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'PipelineId y StageId requeridos al crear';
        SET @Id        = NULL;
        RETURN;
    END

    IF @DealId IS NULL
    BEGIN
        INSERT INTO crm.[Deal] (
            CompanyId, BranchId, [Name], PipelineId, StageId, ContactId, CrmCompanyId,
            OwnerAgentId, [Value], Currency, Probability, ExpectedCloseDate,
            Priority, Source, Notes, Tags, CreatedByUserId, UpdatedByUserId
        ) VALUES (
            @CompanyId, ISNULL(@BranchId, 1), @Name, @PipelineId, @StageId,
            @ContactId, @CrmCompanyId, @OwnerAgentId,
            ISNULL(@Value, 0), ISNULL(@Currency, 'USD'), @Probability, @ExpectedClose,
            ISNULL(@Priority, 'MEDIUM'), @Source, @Notes, @Tags, @UserId, @UserId
        );

        SET @Id = SCOPE_IDENTITY();

        INSERT INTO crm.[DealHistory] (DealId, ChangeType, NewValue, UserId)
        VALUES (@Id, 'CREATED', NULL, @UserId);
    END
    ELSE
    BEGIN
        UPDATE crm.[Deal] SET
            [Name]             = ISNULL(@Name,          [Name]),
            PipelineId         = ISNULL(@PipelineId,    PipelineId),
            StageId            = ISNULL(@StageId,       StageId),
            ContactId          = ISNULL(@ContactId,     ContactId),
            CrmCompanyId       = ISNULL(@CrmCompanyId,  CrmCompanyId),
            OwnerAgentId       = ISNULL(@OwnerAgentId,  OwnerAgentId),
            [Value]            = ISNULL(@Value,         [Value]),
            Currency           = ISNULL(@Currency,      Currency),
            Probability        = ISNULL(@Probability,   Probability),
            ExpectedCloseDate  = ISNULL(@ExpectedClose, ExpectedCloseDate),
            Priority           = ISNULL(@Priority,      Priority),
            Source             = ISNULL(@Source,        Source),
            Notes              = ISNULL(@Notes,         Notes),
            Tags               = ISNULL(@Tags,          Tags),
            UpdatedByUserId    = @UserId,
            UpdatedAt          = SYSUTCDATETIME(),
            RowVer             = RowVer + 1
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

        SET @Id = @DealId;

        INSERT INTO crm.[DealHistory] (DealId, ChangeType, NewValue, UserId)
        VALUES (@DealId, 'VALUE_CHANGE', NULL, @UserId);
    END

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
END
GO
