-- usp_Sys_License_CheckCompanyLimit
-- Validates maxCompanies license limit.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sys_License_CheckCompanyLimit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sys_License_CheckCompanyLimit;
GO

CREATE PROCEDURE dbo.usp_Sys_License_CheckCompanyLimit
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @currentCompanies INT, @maxCompanies INT,
            @multiEnabled BIT, @plan VARCHAR(30);

    SELECT @currentCompanies = COUNT(*)
      FROM cfg.Company
     WHERE IsActive = 1 AND IsDeleted = 0;

    SELECT TOP 1
           @maxCompanies = COALESCE(l.MaxCompanies, pd.MaxCompanies),
           @multiEnabled = COALESCE(l.MultiCompanyEnabled, pd.MultiCompanyEnabled, 0),
           @plan         = COALESCE(l.[Plan], 'FREE')
      FROM zsys.License l
      LEFT JOIN cfg.PlanDefinition pd ON pd.PlanCode = l.[Plan]
     WHERE l.CompanyId = @CompanyId
       AND l.[Status] = 'ACTIVE'
     ORDER BY l.ExpiresAt DESC;

    IF @plan IS NULL
    BEGIN
        SELECT @maxCompanies = pd.MaxCompanies,
               @multiEnabled = pd.MultiCompanyEnabled,
               @plan = pd.PlanCode
          FROM cfg.PlanDefinition pd
         WHERE pd.PlanCode = 'FREE';
    END

    SELECT
        CASE
            WHEN @multiEnabled = 0 AND @currentCompanies >= 1 THEN CAST(0 AS BIT)
            WHEN @maxCompanies IS NULL THEN CAST(1 AS BIT)
            WHEN @currentCompanies < @maxCompanies THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS [allowed],
        @currentCompanies AS currentCompanies,
        @maxCompanies     AS maxCompanies,
        @multiEnabled     AS multiCompanyEnabled,
        @plan             AS [plan];
END
GO
