-- usp_crm_Deal_Detail — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_Detail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_Detail;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_Detail
    @CompanyId INT,
    @DealId    BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT d.DealId,
           d.[Name],
           d.[Value],
           d.Currency,
           d.Probability,
           d.ExpectedCloseDate,
           d.ActualCloseDate,
           d.[Status],
           d.WonLostReason,
           d.Priority,
           d.Source,
           d.Notes,
           d.Tags,
           d.PipelineId,
           d.StageId,
           s.StageName,
           d.ContactId,
           LTRIM(RTRIM(ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, ''))) AS ContactName,
           d.CrmCompanyId,
           cc.[Name] AS CompanyName,
           d.OwnerAgentId,
           a.AgentName AS OwnerName,
           d.SourceLeadId,
           d.CreatedAt,
           d.UpdatedAt,
           d.ClosedAt
      FROM crm.[Deal] d
      LEFT JOIN crm.[PipelineStage] s ON s.StageId       = d.StageId
      LEFT JOIN crm.[Contact]       c ON c.ContactId     = d.ContactId
      LEFT JOIN crm.[Company]      cc ON cc.CrmCompanyId = d.CrmCompanyId
      LEFT JOIN crm.[Agent]         a ON a.AgentId       = d.OwnerAgentId
     WHERE d.CompanyId = @CompanyId
       AND d.DealId    = @DealId
       AND d.IsDeleted = 0;
END
GO
