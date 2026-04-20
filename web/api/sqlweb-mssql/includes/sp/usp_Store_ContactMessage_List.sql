-- usp_Store_ContactMessage_List

IF OBJECT_ID('dbo.usp_Store_ContactMessage_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_ContactMessage_List;
GO

CREATE PROCEDURE dbo.usp_Store_ContactMessage_List
    @CompanyId  INT          = 1,
    @Status     NVARCHAR(20) = NULL,
    @Page       INT          = 1,
    @Limit      INT          = 50,
    @TotalCount INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (CASE WHEN @Page < 1 THEN 0 ELSE (@Page - 1) END) * (CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END);
    DECLARE @lim INT = CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END;

    SELECT @TotalCount = COUNT(*)
      FROM store.ContactMessage
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status);

    SELECT
        ContactMessageId,
        Name,
        Email,
        Phone,
        Subject,
        Message,
        Source,
        Status,
        CreatedAt
      FROM store.ContactMessage
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status)
     ORDER BY CreatedAt DESC
     OFFSET @offset ROWS FETCH NEXT @lim ROWS ONLY;
END
GO
