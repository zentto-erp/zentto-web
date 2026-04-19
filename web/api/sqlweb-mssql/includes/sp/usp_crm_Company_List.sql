-- usp_crm_Company_List (SQL Server 2012+)
-- Lista crm.Company con filtros y paginacion. Compatible con ADR-CRM-001.

IF OBJECT_ID('dbo.usp_crm_Company_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Company_List;
GO

CREATE PROCEDURE dbo.usp_crm_Company_List
    @CompanyId  INT,
    @Search     NVARCHAR(200) = NULL,
    @Industry   VARCHAR(100)  = NULL,
    @IsActive   BIT           = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 50,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(@Page, 1) - 1) * ISNULL(@Limit, 50);
    IF @Offset < 0 SET @Offset = 0;

    SELECT @TotalCount = COUNT(*)
      FROM crm.[Company] c
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND (@Search   IS NULL OR c.[Name] LIKE '%' + @Search + '%'
            OR ISNULL(c.LegalName, '') LIKE '%' + @Search + '%'
            OR ISNULL(c.TaxId, '')     LIKE '%' + @Search + '%')
       AND (@Industry IS NULL OR c.Industry = @Industry)
       AND (@IsActive IS NULL OR c.IsActive = @IsActive);

    SELECT c.CrmCompanyId,
           c.[Name],
           c.LegalName,
           c.TaxId,
           c.Industry,
           c.[Size],
           c.Website,
           c.Phone,
           c.Email,
           c.IsActive,
           c.CreatedAt,
           c.UpdatedAt
      FROM crm.[Company] c
     WHERE c.CompanyId = @CompanyId
       AND c.IsDeleted = 0
       AND (@Search   IS NULL OR c.[Name] LIKE '%' + @Search + '%'
            OR ISNULL(c.LegalName, '') LIKE '%' + @Search + '%'
            OR ISNULL(c.TaxId, '')     LIKE '%' + @Search + '%')
       AND (@Industry IS NULL OR c.Industry = @Industry)
       AND (@IsActive IS NULL OR c.IsActive = @IsActive)
     ORDER BY c.[Name]
     OFFSET @Offset ROWS FETCH NEXT ISNULL(@Limit, 50) ROWS ONLY;
END
GO
