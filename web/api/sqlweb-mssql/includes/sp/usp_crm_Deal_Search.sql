-- usp_crm_Deal_Search — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Deal_Search', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Deal_Search;
GO

CREATE PROCEDURE dbo.usp_crm_Deal_Search
    @CompanyId INT,
    @Term      NVARCHAR(255),
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (ISNULL(@Limit, 20))
           d.DealId,
           d.[Name],
           d.[Value],
           d.Currency,
           d.[Status]
      FROM crm.[Deal] d
     WHERE d.CompanyId = @CompanyId
       AND d.IsDeleted = 0
       AND (@Term IS NULL OR @Term = N''
            OR d.[Name] LIKE N'%' + @Term + N'%')
     ORDER BY d.UpdatedAt DESC;
END
GO
