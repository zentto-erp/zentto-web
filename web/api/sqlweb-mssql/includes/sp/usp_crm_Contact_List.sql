-- usp_crm_Contact_List — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Contact_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Contact_List;
GO

CREATE PROCEDURE dbo.usp_crm_Contact_List
    @CompanyId    INT,
    @CrmCompanyId BIGINT        = NULL,
    @Search       NVARCHAR(200) = NULL,
    @IsActive     BIT           = NULL,
    @Page         INT           = 1,
    @Limit        INT           = 50,
    @TotalCount   INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(@Page, 1) - 1) * ISNULL(@Limit, 50);
    IF @Offset < 0 SET @Offset = 0;

    SELECT @TotalCount = COUNT(*)
      FROM crm.[Contact] c
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND (@CrmCompanyId IS NULL OR c.CrmCompanyId = @CrmCompanyId)
       AND (@IsActive     IS NULL OR c.IsActive     = @IsActive)
       AND (@Search       IS NULL OR c.FirstName LIKE '%' + @Search + '%'
            OR ISNULL(c.LastName, '') LIKE '%' + @Search + '%'
            OR ISNULL(c.Email, '')    LIKE '%' + @Search + '%');

    SELECT c.ContactId,
           c.CrmCompanyId,
           cc.[Name] AS CompanyName,
           c.FirstName,
           c.LastName,
           c.Email,
           c.Phone,
           c.Mobile,
           c.Title,
           c.Department,
           c.PromotedCustomerId,
           c.IsActive,
           c.CreatedAt,
           c.UpdatedAt
      FROM crm.[Contact] c
      LEFT JOIN crm.[Company] cc ON cc.CrmCompanyId = c.CrmCompanyId
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND (@CrmCompanyId IS NULL OR c.CrmCompanyId = @CrmCompanyId)
       AND (@IsActive     IS NULL OR c.IsActive     = @IsActive)
       AND (@Search       IS NULL OR c.FirstName LIKE '%' + @Search + '%'
            OR ISNULL(c.LastName, '') LIKE '%' + @Search + '%'
            OR ISNULL(c.Email, '')    LIKE '%' + @Search + '%')
     ORDER BY c.FirstName, c.LastName
     OFFSET @Offset ROWS FETCH NEXT ISNULL(@Limit, 50) ROWS ONLY;
END
GO
