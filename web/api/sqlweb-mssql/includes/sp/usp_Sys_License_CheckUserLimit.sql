-- usp_Sys_License_CheckUserLimit
-- Validates maxUsers license limit for a given company.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sys_License_CheckUserLimit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sys_License_CheckUserLimit;
GO

CREATE PROCEDURE dbo.usp_Sys_License_CheckUserLimit
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @currentUsers INT, @maxUsers INT, @plan VARCHAR(30);

    SELECT @currentUsers = COUNT(*)
      FROM sec.[User]
     WHERE CompanyId = @CompanyId
       AND IsActive = 1
       AND IsDeleted = 0;

    SELECT TOP 1
           @maxUsers = COALESCE(l.MaxUsers, pd.MaxUsers),
           @plan     = COALESCE(l.[Plan], 'FREE')
      FROM zsys.License l
      LEFT JOIN cfg.PlanDefinition pd ON pd.PlanCode = l.[Plan]
     WHERE l.CompanyId = @CompanyId
       AND l.[Status] = 'ACTIVE'
     ORDER BY l.ExpiresAt DESC;

    IF @plan IS NULL
    BEGIN
        SELECT @maxUsers = pd.MaxUsers, @plan = pd.PlanCode
          FROM cfg.PlanDefinition pd
         WHERE pd.PlanCode = 'FREE';
    END

    SELECT
        CASE
            WHEN @maxUsers IS NULL THEN CAST(1 AS BIT)
            WHEN @currentUsers < @maxUsers THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS [allowed],
        @currentUsers AS currentUsers,
        @maxUsers     AS maxUsers,
        @plan         AS [plan];
END
GO
