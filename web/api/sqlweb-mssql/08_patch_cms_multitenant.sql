-- 08_patch_cms_multitenant.sql
-- CMS Multi-tenant: añade CompanyId a todos los SPs del CMS.
-- Equivalente T-SQL de la migración goose 00159_cms_multitenant.sql.
-- Ejecutar sobre zentto_dev.
USE zentto_dev;
GO

-- ── Fix UNIQUE constraints ────────────────────────────────────────────────────
IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'uq_cms_post_slug_locale' AND parent_object_id = OBJECT_ID('cms.Post')
)
    ALTER TABLE cms.[Post] DROP CONSTRAINT uq_cms_post_slug_locale;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'uq_cms_post_slug_locale_company' AND parent_object_id = OBJECT_ID('cms.Post')
)
    ALTER TABLE cms.[Post] ADD CONSTRAINT uq_cms_post_slug_locale_company
        UNIQUE (CompanyId, Slug, Locale);
GO

IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'uq_cms_page_slug_vertical_locale' AND parent_object_id = OBJECT_ID('cms.Page')
)
    ALTER TABLE cms.[Page] DROP CONSTRAINT uq_cms_page_slug_vertical_locale;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'uq_cms_page_slug_vertical_locale_company' AND parent_object_id = OBJECT_ID('cms.Page')
)
    ALTER TABLE cms.[Page] ADD CONSTRAINT uq_cms_page_slug_vertical_locale_company
        UNIQUE (CompanyId, Slug, Vertical, Locale);
GO

-- ── usp_cms_Post_List ─────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Post_List
    @CompanyId  INT            = 1,
    @Vertical   NVARCHAR(50)   = NULL,
    @Category   NVARCHAR(50)   = NULL,
    @Locale     NVARCHAR(10)   = N'es',
    @Status     NVARCHAR(20)   = N'published',
    @Limit      INT            = 20,
    @Offset     INT            = 0,
    @TotalCount INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM cms.[Post] p
    WHERE p.CompanyId = @CompanyId
      AND (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND (@Category IS NULL OR p.Category = @Category)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.[Status] = @Status);

    SELECT
        p.PostId, p.CompanyId, p.Slug, p.Vertical, p.Category, p.Locale,
        p.Title, p.Excerpt, p.CoverUrl,
        p.AuthorName, p.AuthorSlug, p.AuthorAvatar,
        p.Tags, p.ReadingMin, p.[Status], p.PublishedAt,
        @TotalCount AS TotalCount
    FROM cms.[Post] p
    WHERE p.CompanyId = @CompanyId
      AND (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND (@Category IS NULL OR p.Category = @Category)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.[Status] = @Status)
    ORDER BY COALESCE(p.PublishedAt, p.CreatedAt) DESC, p.PostId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ── usp_cms_Post_Get ──────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Post_Get
    @Slug       NVARCHAR(200),
    @Locale     NVARCHAR(10)  = N'es',
    @CompanyId  INT           = 1
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        p.PostId, p.CompanyId, p.Slug, p.Vertical, p.Category, p.Locale,
        p.Title, p.Excerpt, p.Body, p.CoverUrl,
        p.AuthorName, p.AuthorSlug, p.AuthorAvatar,
        p.Tags, p.ReadingMin,
        p.SeoTitle, p.SeoDescription, p.SeoImageUrl,
        p.[Status], p.PublishedAt, p.CreatedAt, p.UpdatedAt
    FROM cms.[Post] p
    WHERE p.Slug = @Slug
      AND p.Locale = @Locale
      AND p.CompanyId = @CompanyId;
END;
GO

-- ── usp_cms_Post_Upsert ───────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Post_Upsert
    @PostId         INT            = NULL,
    @CompanyId      INT            = 1,
    @Slug           NVARCHAR(200)  = N'',
    @Vertical       NVARCHAR(50)   = N'corporate',
    @Category       NVARCHAR(50)   = N'producto',
    @Locale         NVARCHAR(10)   = N'es',
    @Title          NVARCHAR(300)  = N'',
    @Excerpt        NVARCHAR(500)  = N'',
    @Body           NVARCHAR(MAX)  = N'',
    @CoverUrl       NVARCHAR(500)  = N'',
    @AuthorName     NVARCHAR(200)  = N'',
    @AuthorSlug     NVARCHAR(100)  = N'',
    @AuthorAvatar   NVARCHAR(500)  = N'',
    @Tags           NVARCHAR(500)  = N'',
    @ReadingMin     INT            = 5,
    @SeoTitle       NVARCHAR(300)  = N'',
    @SeoDescription NVARCHAR(500)  = N'',
    @SeoImageUrl    NVARCHAR(500)  = N'',
    @ok             BIT            OUTPUT,
    @mensaje        NVARCHAR(100)  OUTPUT,
    @post_id        INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Slug, N'') = N'' BEGIN
        SELECT @ok = 0, @mensaje = N'slug_required', @post_id = 0; RETURN;
    END
    IF ISNULL(@Title, N'') = N'' BEGIN
        SELECT @ok = 0, @mensaje = N'title_required', @post_id = 0; RETURN;
    END

    IF @PostId IS NULL OR @PostId = 0 BEGIN
        INSERT INTO cms.[Post] (
            CompanyId, Slug, Vertical, Category, Locale,
            Title, Excerpt, Body, CoverUrl,
            AuthorName, AuthorSlug, AuthorAvatar,
            Tags, ReadingMin, SeoTitle, SeoDescription, SeoImageUrl
        ) VALUES (
            @CompanyId, @Slug, @Vertical, @Category, @Locale,
            @Title, @Excerpt, @Body, @CoverUrl,
            @AuthorName, @AuthorSlug, @AuthorAvatar,
            @Tags, @ReadingMin, @SeoTitle, @SeoDescription, @SeoImageUrl
        );
        SELECT @ok = 1, @mensaje = N'post_created', @post_id = SCOPE_IDENTITY();
    END ELSE BEGIN
        UPDATE cms.[Post] SET
            Slug = @Slug, Vertical = @Vertical, Category = @Category, Locale = @Locale,
            Title = @Title, Excerpt = @Excerpt, Body = @Body, CoverUrl = @CoverUrl,
            AuthorName = @AuthorName, AuthorSlug = @AuthorSlug, AuthorAvatar = @AuthorAvatar,
            Tags = @Tags, ReadingMin = @ReadingMin,
            SeoTitle = @SeoTitle, SeoDescription = @SeoDescription, SeoImageUrl = @SeoImageUrl,
            UpdatedAt = GETUTCDATE()
        WHERE PostId = @PostId AND CompanyId = @CompanyId;

        IF @@ROWCOUNT = 0
            SELECT @ok = 0, @mensaje = N'post_not_found', @post_id = 0;
        ELSE
            SELECT @ok = 1, @mensaje = N'post_updated', @post_id = @PostId;
    END
END;
GO

-- ── usp_cms_Post_Publish ──────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Post_Publish
    @PostId     INT,
    @Publish    BIT = 1,
    @CompanyId  INT = 1,
    @ok         BIT           OUTPUT,
    @mensaje    NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE cms.[Post] SET
        [Status]    = CASE WHEN @Publish = 1 THEN N'published' ELSE N'draft' END,
        PublishedAt = CASE WHEN @Publish = 1 AND PublishedAt IS NULL THEN GETUTCDATE() ELSE PublishedAt END,
        UpdatedAt   = GETUTCDATE()
    WHERE PostId = @PostId AND CompanyId = @CompanyId;

    IF @@ROWCOUNT = 0
        SELECT @ok = 0, @mensaje = N'post_not_found';
    ELSE
        SELECT @ok = 1, @mensaje = CASE WHEN @Publish = 1 THEN N'post_published' ELSE N'post_unpublished' END;
END;
GO

-- ── usp_cms_Post_Delete ───────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Post_Delete
    @PostId     INT,
    @CompanyId  INT = 1,
    @ok         BIT           OUTPUT,
    @mensaje    NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM cms.[Post] WHERE PostId = @PostId AND CompanyId = @CompanyId;
    IF @@ROWCOUNT = 0
        SELECT @ok = 0, @mensaje = N'post_not_found';
    ELSE
        SELECT @ok = 1, @mensaje = N'post_deleted';
END;
GO

-- ── usp_cms_Page_List ─────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Page_List
    @CompanyId  INT           = 1,
    @Vertical   NVARCHAR(50)  = NULL,
    @Locale     NVARCHAR(10)  = N'es',
    @Status     NVARCHAR(20)  = N'published'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.PageId, p.CompanyId, p.Slug, p.Vertical, p.Locale,
        p.Title, p.[Status], p.PublishedAt, p.UpdatedAt
    FROM cms.[Page] p
    WHERE p.CompanyId = @CompanyId
      AND (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.[Status] = @Status)
    ORDER BY p.Slug;
END;
GO

-- ── usp_cms_Page_Get ──────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Page_Get
    @Slug       NVARCHAR(100),
    @Vertical   NVARCHAR(50)  = N'corporate',
    @Locale     NVARCHAR(10)  = N'es',
    @CompanyId  INT           = 1
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        p.PageId, p.CompanyId, p.Slug, p.Vertical, p.Locale,
        p.Title, p.Body, p.Meta,
        p.SeoTitle, p.SeoDescription,
        p.[Status], p.PublishedAt, p.CreatedAt, p.UpdatedAt
    FROM cms.[Page] p
    WHERE p.Slug = @Slug AND p.Vertical = @Vertical
      AND p.Locale = @Locale AND p.CompanyId = @CompanyId;
END;
GO

-- ── usp_cms_Page_Upsert ───────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Page_Upsert
    @PageId         INT            = NULL,
    @CompanyId      INT            = 1,
    @Slug           NVARCHAR(100)  = N'',
    @Vertical       NVARCHAR(50)   = N'corporate',
    @Locale         NVARCHAR(10)   = N'es',
    @Title          NVARCHAR(300)  = N'',
    @Body           NVARCHAR(MAX)  = N'',
    @Meta           NVARCHAR(MAX)  = N'{}',
    @SeoTitle       NVARCHAR(300)  = N'',
    @SeoDescription NVARCHAR(500)  = N'',
    @ok             BIT            OUTPUT,
    @mensaje        NVARCHAR(100)  OUTPUT,
    @page_id        INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Slug, N'') = N'' BEGIN
        SELECT @ok = 0, @mensaje = N'slug_required', @page_id = 0; RETURN;
    END
    IF ISNULL(@Title, N'') = N'' BEGIN
        SELECT @ok = 0, @mensaje = N'title_required', @page_id = 0; RETURN;
    END

    IF @PageId IS NULL OR @PageId = 0 BEGIN
        INSERT INTO cms.[Page] (
            CompanyId, Slug, Vertical, Locale,
            Title, Body, Meta, SeoTitle, SeoDescription
        ) VALUES (
            @CompanyId, @Slug, @Vertical, @Locale,
            @Title, @Body, @Meta, @SeoTitle, @SeoDescription
        );
        SELECT @ok = 1, @mensaje = N'page_created', @page_id = SCOPE_IDENTITY();
    END ELSE BEGIN
        UPDATE cms.[Page] SET
            Slug = @Slug, Vertical = @Vertical, Locale = @Locale,
            Title = @Title, Body = @Body, Meta = @Meta,
            SeoTitle = @SeoTitle, SeoDescription = @SeoDescription,
            UpdatedAt = GETUTCDATE()
        WHERE PageId = @PageId AND CompanyId = @CompanyId;

        IF @@ROWCOUNT = 0
            SELECT @ok = 0, @mensaje = N'page_not_found', @page_id = 0;
        ELSE
            SELECT @ok = 1, @mensaje = N'page_updated', @page_id = @PageId;
    END
END;
GO

-- ── usp_cms_Page_Publish ──────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Page_Publish
    @PageId     INT,
    @Publish    BIT = 1,
    @CompanyId  INT = 1,
    @ok         BIT           OUTPUT,
    @mensaje    NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE cms.[Page] SET
        [Status]    = CASE WHEN @Publish = 1 THEN N'published' ELSE N'draft' END,
        PublishedAt = CASE WHEN @Publish = 1 AND PublishedAt IS NULL THEN GETUTCDATE() ELSE PublishedAt END,
        UpdatedAt   = GETUTCDATE()
    WHERE PageId = @PageId AND CompanyId = @CompanyId;

    IF @@ROWCOUNT = 0
        SELECT @ok = 0, @mensaje = N'page_not_found';
    ELSE
        SELECT @ok = 1, @mensaje = CASE WHEN @Publish = 1 THEN N'page_published' ELSE N'page_unpublished' END;
END;
GO

-- ── usp_cms_Page_Delete ───────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE cms.usp_cms_Page_Delete
    @PageId     INT,
    @CompanyId  INT = 1,
    @ok         BIT           OUTPUT,
    @mensaje    NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM cms.[Page] WHERE PageId = @PageId AND CompanyId = @CompanyId;
    IF @@ROWCOUNT = 0
        SELECT @ok = 0, @mensaje = N'page_not_found';
    ELSE
        SELECT @ok = 1, @mensaje = N'page_deleted';
END;
GO
