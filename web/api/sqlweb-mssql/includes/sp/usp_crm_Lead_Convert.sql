-- usp_crm_Lead_Convert — SQL Server 2012+
-- Convierte un Lead a Deal y marca Lead como CONVERTED.

IF OBJECT_ID('dbo.usp_crm_Lead_Convert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Lead_Convert;
GO

CREATE PROCEDURE dbo.usp_crm_Lead_Convert
    @CompanyId       INT,
    @LeadId          BIGINT,
    @DealName        NVARCHAR(255) = NULL,
    @PipelineId      BIGINT        = NULL,
    @StageId         BIGINT        = NULL,
    @CrmCompanyId    BIGINT        = NULL,
    @UserId          INT           = NULL,
    @Resultado       BIT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT,
    @Id              BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BranchId INT, @Pipeline BIGINT, @Stage BIGINT,
            @ContactName NVARCHAR(200), @Email VARCHAR(150), @Phone VARCHAR(40),
            @EstValue DECIMAL(18,2), @Curr VARCHAR(3), @ExpClose DATE,
            @Priority VARCHAR(10), @Source VARCHAR(20),
            @Converted BIGINT, @LeadIdVal BIGINT, @ContactId BIGINT, @DealId BIGINT;

    SELECT @BranchId    = BranchId,
           @Pipeline    = PipelineId,
           @Stage       = StageId,
           @ContactName = ContactName,
           @Email       = Email,
           @Phone       = Phone,
           @EstValue    = EstimatedValue,
           @Curr        = CurrencyCode,
           @ExpClose    = ExpectedCloseDate,
           @Priority    = Priority,
           @Source      = Source,
           @Converted   = ConvertedToDealId,
           @LeadIdVal   = LeadId
      FROM crm.[Lead]
     WHERE LeadId    = @LeadId
       AND CompanyId = @CompanyId
       AND IsDeleted = 0;

    IF @LeadIdVal IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Lead no encontrado';
        SET @Id        = NULL;
        RETURN;
    END

    IF @Converted IS NOT NULL
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje   = N'Lead ya convertido';
        SET @Id        = @Converted;
        RETURN;
    END

    SET @Pipeline = ISNULL(@PipelineId, @Pipeline);
    SET @Stage    = ISNULL(@StageId,    @Stage);

    IF ISNULL(@ContactName, N'') <> N''
    BEGIN
        INSERT INTO crm.[Contact] (
            CompanyId, CrmCompanyId, FirstName, Email, Phone,
            CreatedByUserId, UpdatedByUserId
        ) VALUES (
            @CompanyId, @CrmCompanyId, @ContactName, @Email, @Phone,
            @UserId, @UserId
        );
        SET @ContactId = SCOPE_IDENTITY();
    END

    INSERT INTO crm.[Deal] (
        CompanyId, BranchId, [Name], PipelineId, StageId, ContactId, CrmCompanyId,
        [Value], Currency, ExpectedCloseDate, SourceLeadId, Priority, Source,
        CreatedByUserId, UpdatedByUserId
    ) VALUES (
        @CompanyId, @BranchId,
        ISNULL(@DealName, ISNULL(@ContactName, 'Deal-' + CAST(@LeadIdVal AS VARCHAR(20)))),
        @Pipeline, @Stage, @ContactId, @CrmCompanyId,
        ISNULL(@EstValue, 0), ISNULL(@Curr, 'USD'), @ExpClose, @LeadIdVal,
        ISNULL(@Priority, 'MEDIUM'), @Source, @UserId, @UserId
    );
    SET @DealId = SCOPE_IDENTITY();

    UPDATE crm.[Lead]
       SET [Status]           = 'CONVERTED',
           ConvertedToDealId  = @DealId,
           UpdatedAt          = SYSUTCDATETIME(),
           UpdatedByUserId    = @UserId
     WHERE LeadId    = @LeadId
       AND CompanyId = @CompanyId;

    INSERT INTO crm.[DealHistory] (DealId, ChangeType, Notes, UserId)
    VALUES (@DealId, 'CREATED',
            N'Convertido desde Lead ' + CAST(@LeadIdVal AS NVARCHAR(20)),
            @UserId);

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
    SET @Id        = @DealId;
END
GO
