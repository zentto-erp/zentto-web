-- usp_crm_Contact_Detail — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Contact_Detail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Contact_Detail;
GO

CREATE PROCEDURE dbo.usp_crm_Contact_Detail
    @CompanyId INT,
    @ContactId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

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
           c.LinkedIn,
           c.Notes,
           c.PromotedCustomerId,
           c.IsActive,
           c.CreatedAt,
           c.UpdatedAt
      FROM crm.[Contact] c
      LEFT JOIN crm.[Company] cc ON cc.CrmCompanyId = c.CrmCompanyId
     WHERE c.CompanyId = @CompanyId
       AND c.ContactId = @ContactId
       AND c.IsDeleted = 0;
END
GO
