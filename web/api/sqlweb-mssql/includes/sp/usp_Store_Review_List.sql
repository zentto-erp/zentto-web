-- usp_Store_Review_List
-- Lista reviews admin con filtro por status + search. Usa @TotalCount OUTPUT.

IF OBJECT_ID('dbo.usp_Store_Review_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Review_List;
GO

CREATE PROCEDURE dbo.usp_Store_Review_List
    @CompanyId   INT           = 1,
    @Status      NVARCHAR(20)  = NULL,
    @Search      NVARCHAR(200) = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 25,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (CASE WHEN @Page < 1 THEN 0 ELSE @Page - 1 END) * @Limit;
    DECLARE @pattern NVARCHAR(210) = CASE
        WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
            THEN '%' + LTRIM(RTRIM(@Search)) + '%'
        ELSE NULL END;

    SELECT @TotalCount = COUNT(*)
      FROM store.ProductReview r
     WHERE r.CompanyId = @CompanyId
       AND r.IsDeleted = 0
       AND (@Status IS NULL OR r.[Status] = @Status)
       AND (@pattern IS NULL
            OR r.ProductCode LIKE @pattern
            OR r.Title LIKE @pattern
            OR r.ReviewerName LIKE @pattern
            OR r.Comment LIKE @pattern);

    SELECT
        r.ReviewId      AS reviewId,
        r.ProductCode   AS productCode,
        p.ProductName   AS productName,
        r.Rating        AS rating,
        r.Title         AS title,
        r.Comment       AS comment,
        r.ReviewerName  AS reviewerName,
        r.ReviewerEmail AS reviewerEmail,
        r.[Status]      AS status,
        r.IsVerified    AS isVerified,
        r.CreatedAt     AS createdAt,
        r.ModeratedAt   AS moderatedAt,
        r.ModeratorUser AS moderatorUser
      FROM store.ProductReview r
      LEFT JOIN mstr.Product p
             ON p.CompanyId = r.CompanyId AND p.ProductCode = r.ProductCode
     WHERE r.CompanyId = @CompanyId
       AND r.IsDeleted = 0
       AND (@Status IS NULL OR r.[Status] = @Status)
       AND (@pattern IS NULL
            OR r.ProductCode LIKE @pattern
            OR r.Title LIKE @pattern
            OR r.ReviewerName LIKE @pattern
            OR r.Comment LIKE @pattern)
     ORDER BY r.CreatedAt DESC
     OFFSET @offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
