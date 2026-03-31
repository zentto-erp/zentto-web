-- usp_Sec_Role_List
-- Lists active roles with user counts.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_Role_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_Role_List;
GO

CREATE PROCEDURE dbo.usp_Sec_Role_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.RoleId,
           r.RoleCode,
           r.RoleName,
           r.IsSystem,
           r.IsActive,
           ISNULL(uc.cnt, 0) AS UserCount
      FROM sec.[Role] r
      LEFT JOIN (
          SELECT ur.RoleId, COUNT(*) AS cnt
            FROM sec.UserRole ur
            JOIN sec.[User] u ON u.UserId = ur.UserId
           WHERE u.CompanyId = @CompanyId
             AND u.IsActive = 1 AND u.IsDeleted = 0
           GROUP BY ur.RoleId
      ) uc ON uc.RoleId = r.RoleId
     WHERE r.IsActive = 1
     ORDER BY r.RoleId;
END
GO
