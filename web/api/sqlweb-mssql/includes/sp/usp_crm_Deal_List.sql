-- usp_crm_Deal_List — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_List;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_List
    @CompanyId      INT,
    @PipelineId     BIGINT        = NULL,
    @StageId        BIGINT        = NULL,
    @Status         VARCHAR(20)   = NULL,
    @OwnerAgentId   BIGINT        = NULL,
    @ContactId      BIGINT        = NULL,
    @CrmCompanyId   BIGINT        = NULL,
    @Search         NVARCHAR(255) = NULL,
    @Page           INT           = 1,
    @Limit          INT           = 50,
    @TotalCount     INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(@Page, 1) - 1) * ISNULL(@Limit, 50);
    IF @Offset < 0 SET @Offset = 0;

    SELECT @TotalCount = COUNT(*)
      FROM crm.[Deal] d
     WHERE d.CompanyId = @CompanyId
       AND d.IsDeleted = 0
       AND (@PipelineId   IS NULL OR d.PipelineId   = @PipelineId)
       AND (@StageId      IS NULL OR d.StageId      = @StageId)
       AND (@Status       IS NULL OR d.[Status]     = @Status)
       AND (@OwnerAgentId IS NULL OR d.OwnerAgentId = @OwnerAgentId)
       AND (@ContactId    IS NULL OR d.ContactId    = @ContactId)
       AND (@CrmCompanyId IS NULL OR d.CrmCompanyId = @CrmCompanyId)
       AND (@Search IS NULL OR d.[Name] LIKE '%' + @Search + '%');

    SELECT d.DealId,
           d.[Name],
           d.[Value],
           d.Currency,
           d.Probability,
           d.ExpectedCloseDate,
           d.[Status],
           d.Priority,
           d.StageId,
           s.StageName,
           d.PipelineId,
           d.ContactId,
           LTRIM(RTRIM(ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, ''))) AS ContactName,
           d.CrmCompanyId,
           cc.[Name] AS CompanyName,
           d.OwnerAgentId,
           a.AgentName AS OwnerName,
           d.CreatedAt,
           d.UpdatedAt
      FROM crm.[Deal] d
      LEFT JOIN crm.[PipelineStage] s ON s.StageId     = d.StageId
      LEFT JOIN crm.[Contact]       c ON c.ContactId   = d.ContactId
      LEFT JOIN crm.[Company]      cc ON cc.CrmCompanyId = d.CrmCompanyId
      LEFT JOIN crm.[Agent]         a ON a.AgentId     = d.OwnerAgentId
     WHERE d.CompanyId = @CompanyId
       AND d.IsDeleted = 0
       AND (@PipelineId   IS NULL OR d.PipelineId   = @PipelineId)
       AND (@StageId      IS NULL OR d.StageId      = @StageId)
       AND (@Status       IS NULL OR d.[Status]     = @Status)
       AND (@OwnerAgentId IS NULL OR d.OwnerAgentId = @OwnerAgentId)
       AND (@ContactId    IS NULL OR d.ContactId    = @ContactId)
       AND (@CrmCompanyId IS NULL OR d.CrmCompanyId = @CrmCompanyId)
       AND (@Search IS NULL OR d.[Name] LIKE '%' + @Search + '%')
     ORDER BY d.UpdatedAt DESC
     OFFSET @Offset ROWS FETCH NEXT ISNULL(@Limit, 50) ROWS ONLY;
END
GO
