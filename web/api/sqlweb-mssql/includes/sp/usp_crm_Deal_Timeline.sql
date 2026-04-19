-- usp_crm_Deal_Timeline — SQL Server 2012+
-- Une DealHistory + Activity + CallLog en una sola secuencia ordenada.

IF OBJECT_ID('dbo.usp_crm_Deal_Timeline', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_Timeline;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_Timeline
    @CompanyId INT,
    @DealId    BIGINT,
    @Limit     INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ContactId BIGINT, @LeadId BIGINT, @CustomerId BIGINT;
    SELECT @ContactId = ContactId, @LeadId = SourceLeadId
      FROM crm.[Deal]
     WHERE DealId = @DealId AND CompanyId = @CompanyId;

    IF @ContactId IS NOT NULL
        SELECT @CustomerId = PromotedCustomerId
          FROM crm.[Contact]
         WHERE ContactId = @ContactId;

    SELECT TOP (ISNULL(@Limit, 100)) *
      FROM (
            SELECT h.ChangedAt      AS EventAt,
                   'HISTORY:' + h.ChangeType AS Kind,
                   h.ChangeType     AS Title,
                   h.Notes          AS Description,
                   h.UserId         AS UserId
              FROM crm.[DealHistory] h
             WHERE h.DealId = @DealId
            UNION ALL
            SELECT a.CreatedAt      AS EventAt,
                   'ACTIVITY:' + a.ActivityType AS Kind,
                   a.Subject        AS Title,
                   a.Description    AS Description,
                   a.CreatedByUserId AS UserId
              FROM crm.[Activity] a
             WHERE a.CompanyId = @CompanyId
               AND (a.LeadId = @LeadId
                    OR (@CustomerId IS NOT NULL AND a.CustomerId = @CustomerId))
            UNION ALL
            SELECT cl.CallStartTime AS EventAt,
                   'CALL:' + cl.CallDirection AS Kind,
                   cl.ContactName   AS Title,
                   cl.Notes         AS Description,
                   cl.CreatedByUserId AS UserId
              FROM crm.[CallLog] cl
             WHERE cl.CompanyId = @CompanyId
               AND cl.LeadId    = @LeadId
           ) t
     ORDER BY t.EventAt DESC;
END
GO
