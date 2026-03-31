-- usp_Sec_UserRole_List
-- Lists all active roles assigned to a user.
-- Compatible SQL Server 2012+

IF OBJECT_ID('dbo.usp_Sec_UserRole_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sec_UserRole_List;
GO

CREATE PROCEDURE dbo.usp_Sec_UserRole_List
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ur.UserRoleId,
           r.RoleId,
           r.RoleCode,
           r.RoleName,
           r.IsSystem,
           ur.CreatedAt AS AssignedAt
      FROM sec.UserRole ur
      JOIN sec.[Role] r ON r.RoleId = ur.RoleId
     WHERE ur.UserId = @UserId
       AND r.IsActive = 1
     ORDER BY r.RoleId;
END
GO
