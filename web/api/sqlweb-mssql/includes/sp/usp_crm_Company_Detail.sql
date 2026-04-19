-- usp_crm_Company_Detail (SQL Server 2012+)

IF OBJECT_ID('dbo.usp_crm_Company_Detail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Company_Detail;
GO

CREATE PROCEDURE dbo.usp_crm_Company_Detail
    @CompanyId    INT,
    @CrmCompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CrmCompanyId,
           c.[Name],
           c.LegalName,
           c.TaxId,
           c.Industry,
           c.[Size],
           c.Website,
           c.Phone,
           c.Email,
           c.BillingAddress,
           c.ShippingAddress,
           c.Notes,
           c.IsActive,
           c.CreatedAt,
           c.UpdatedAt
      FROM crm.[Company] c
     WHERE c.CompanyId    = @CompanyId
       AND c.CrmCompanyId = @CrmCompanyId
       AND c.IsDeleted    = 0;
END
GO
