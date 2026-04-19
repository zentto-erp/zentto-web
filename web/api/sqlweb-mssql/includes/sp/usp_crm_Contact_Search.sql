-- usp_crm_Contact_Search — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Contact_Search', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Contact_Search;
GO

CREATE PROCEDURE dbo.usp_crm_Contact_Search
    @CompanyId INT,
    @Term      NVARCHAR(200),
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (ISNULL(@Limit, 20))
           c.ContactId,
           c.FirstName,
           c.LastName,
           c.Email,
           c.Phone,
           cc.[Name] AS CompanyName
      FROM crm.[Contact] c
      LEFT JOIN crm.[Company] cc ON cc.CrmCompanyId = c.CrmCompanyId
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND c.IsActive  = 1
       AND (@Term IS NULL OR @Term = N''
            OR c.FirstName LIKE N'%' + @Term + N'%'
            OR ISNULL(c.LastName, '') LIKE N'%' + @Term + N'%'
            OR ISNULL(c.Email, '') LIKE N'%' + @Term + N'%')
     ORDER BY c.FirstName, c.LastName;
END
GO
