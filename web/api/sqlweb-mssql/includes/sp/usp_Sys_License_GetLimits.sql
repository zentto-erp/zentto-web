-- usp_Sys_License_GetLimits
-- Unified license limits query for UI.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sys_License_GetLimits', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sys_License_GetLimits;
GO

CREATE PROCEDURE dbo.usp_Sys_License_GetLimits
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @maxUsers INT, @maxCompanies INT, @maxBranches INT,
            @multiEnabled BIT, @plan VARCHAR(30),
            @currentUsers INT, @currentCompanies INT, @currentBranches INT;

    SELECT TOP 1
           @maxUsers     = COALESCE(l.MaxUsers, pd.MaxUsers),
           @maxCompanies = COALESCE(l.MaxCompanies, pd.MaxCompanies),
           @maxBranches  = COALESCE(l.MaxBranches, pd.MaxBranches),
           @multiEnabled = COALESCE(l.MultiCompanyEnabled, pd.MultiCompanyEnabled, 0),
           @plan         = COALESCE(l.[Plan], 'FREE')
      FROM zsys.License l
      LEFT JOIN cfg.PlanDefinition pd ON pd.PlanCode = l.[Plan]
     WHERE l.CompanyId = @CompanyId
       AND l.[Status] = 'ACTIVE'
     ORDER BY l.ExpiresAt DESC;

    IF @plan IS NULL
    BEGIN
        SELECT @maxUsers = pd.MaxUsers, @maxCompanies = pd.MaxCompanies,
               @maxBranches = pd.MaxBranches, @multiEnabled = pd.MultiCompanyEnabled,
               @plan = pd.PlanCode
          FROM cfg.PlanDefinition pd
         WHERE pd.PlanCode = 'FREE';
    END

    SELECT @currentUsers = COUNT(*)
      FROM sec.[User]
     WHERE CompanyId = @CompanyId AND IsActive = 1 AND IsDeleted = 0;

    SELECT @currentCompanies = COUNT(*)
      FROM cfg.Company
     WHERE IsActive = 1 AND IsDeleted = 0;

    SELECT @currentBranches = COUNT(*)
      FROM cfg.Branch
     WHERE CompanyId = @CompanyId AND IsActive = 1 AND IsDeleted = 0;

    SELECT @maxUsers        AS maxUsers,
           @currentUsers    AS currentUsers,
           @maxCompanies    AS maxCompanies,
           @currentCompanies AS currentCompanies,
           @maxBranches     AS maxBranches,
           @currentBranches AS currentBranches,
           @multiEnabled    AS multiCompanyEnabled,
           @plan            AS [plan];
END
GO
