-- usp_crm_Company_Search — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Company_Search', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Company_Search;
GO

CREATE PROCEDURE dbo.usp_crm_Company_Search
    @CompanyId INT,
    @Term      NVARCHAR(200),
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (ISNULL(@Limit, 20))
           c.CrmCompanyId,
           c.[Name],
           c.TaxId,
           c.Industry
      FROM crm.[Company] c
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND c.IsActive  = 1
       AND (@Term IS NULL OR @Term = N''
            OR c.[Name] LIKE N'%' + @Term + N'%'
            OR ISNULL(c.TaxId, '') LIKE N'%' + @Term + N'%')
     ORDER BY c.[Name];
END
GO
