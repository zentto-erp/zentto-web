-- ============================================================
-- usp_zsys_studio.sql — Studio Addons CRUD (SQL Server / T-SQL)
-- Schema: zsys | Naming: usp_zsys_StudioAddon_*
-- Compatible SQL Server 2012+ (compat level 110)
-- ============================================================

-- ── Tablas (IF NOT EXISTS via OBJECT_ID) ──

IF OBJECT_ID('zsys.StudioAddon', 'U') IS NULL
BEGIN
    CREATE TABLE zsys.StudioAddon (
        AddonId         VARCHAR(50)     NOT NULL PRIMARY KEY,
        CompanyId       INT             NOT NULL,
        Title           NVARCHAR(200)   NOT NULL,
        [Description]   NVARCHAR(500)   NULL,
        Icon            NVARCHAR(10)    NULL,
        Config          NVARCHAR(MAX)   NOT NULL,
        CreatedBy       INT             NOT NULL,
        CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
        IsActive        BIT             NOT NULL DEFAULT 1
    );

    CREATE NONCLUSTERED INDEX IX_StudioAddon_Company
        ON zsys.StudioAddon(CompanyId, IsActive);
END
GO

IF OBJECT_ID('zsys.StudioAddonModule', 'U') IS NULL
BEGIN
    CREATE TABLE zsys.StudioAddonModule (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        AddonId         VARCHAR(50)     NOT NULL,
        ModuleId        VARCHAR(50)     NOT NULL,
        CONSTRAINT UQ_StudioAddonModule UNIQUE (AddonId, ModuleId),
        CONSTRAINT FK_StudioAddonModule_Addon FOREIGN KEY (AddonId) REFERENCES zsys.StudioAddon(AddonId) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX IX_StudioAddonModule_Module
        ON zsys.StudioAddonModule(ModuleId);
END
GO

-- ── SP: List ──

IF OBJECT_ID('zsys.usp_zsys_StudioAddon_List', 'P') IS NOT NULL DROP PROCEDURE zsys.usp_zsys_StudioAddon_List;
GO
CREATE PROCEDURE zsys.usp_zsys_StudioAddon_List
    @CompanyId   INT,
    @ModuleId    VARCHAR(50) = NULL,
    @Page        INT = 1,
    @PageSize    INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(DISTINCT a.AddonId)
    FROM zsys.StudioAddon a
    LEFT JOIN zsys.StudioAddonModule m ON m.AddonId = a.AddonId
    WHERE a.CompanyId = @CompanyId
      AND a.IsActive = 1
      AND (@ModuleId IS NULL OR m.ModuleId = @ModuleId);

    SELECT
        a.AddonId,
        a.Title,
        a.[Description],
        a.Icon,
        (SELECT STUFF((SELECT ',' + sm.ModuleId FROM zsys.StudioAddonModule sm WHERE sm.AddonId = a.AddonId FOR XML PATH('')), 1, 1, '')) AS Modules,
        a.CreatedBy,
        a.CreatedAt,
        a.UpdatedAt
    FROM zsys.StudioAddon a
    LEFT JOIN zsys.StudioAddonModule m ON m.AddonId = a.AddonId
    WHERE a.CompanyId = @CompanyId
      AND a.IsActive = 1
      AND (@ModuleId IS NULL OR m.ModuleId = @ModuleId)
    GROUP BY a.AddonId, a.Title, a.[Description], a.Icon, a.CreatedBy, a.CreatedAt, a.UpdatedAt
    ORDER BY a.UpdatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ── SP: Get ──

IF OBJECT_ID('zsys.usp_zsys_StudioAddon_Get', 'P') IS NOT NULL DROP PROCEDURE zsys.usp_zsys_StudioAddon_Get;
GO
CREATE PROCEDURE zsys.usp_zsys_StudioAddon_Get
    @CompanyId   INT,
    @AddonId     VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AddonId,
        a.Title,
        a.[Description],
        a.Icon,
        a.Config,
        (SELECT STUFF((SELECT ',' + sm.ModuleId FROM zsys.StudioAddonModule sm WHERE sm.AddonId = a.AddonId FOR XML PATH('')), 1, 1, '')) AS Modules,
        a.CreatedBy,
        a.CreatedAt,
        a.UpdatedAt
    FROM zsys.StudioAddon a
    WHERE a.CompanyId = @CompanyId
      AND a.AddonId = @AddonId
      AND a.IsActive = 1;
END
GO

-- ── SP: Save (Upsert) ──

IF OBJECT_ID('zsys.usp_zsys_StudioAddon_Save', 'P') IS NOT NULL DROP PROCEDURE zsys.usp_zsys_StudioAddon_Save;
GO
CREATE PROCEDURE zsys.usp_zsys_StudioAddon_Save
    @CompanyId   INT,
    @AddonId     VARCHAR(50),
    @Title       NVARCHAR(200),
    @Description NVARCHAR(500) = NULL,
    @Icon        NVARCHAR(10) = NULL,
    @Config      NVARCHAR(MAX) = '{}',
    @CreatedBy   INT = 0,
    @Modules     VARCHAR(500) = NULL,  -- comma-separated
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM zsys.StudioAddon WHERE AddonId = @AddonId AND CompanyId = @CompanyId)
    BEGIN
        UPDATE zsys.StudioAddon SET
            Title = @Title,
            [Description] = @Description,
            Icon = @Icon,
            Config = @Config,
            UpdatedAt = SYSUTCDATETIME(),
            IsActive = 1
        WHERE AddonId = @AddonId AND CompanyId = @CompanyId;

        SET @Resultado = 1;
        SET @Mensaje = 'Addon actualizado';
    END
    ELSE
    BEGIN
        INSERT INTO zsys.StudioAddon (AddonId, CompanyId, Title, [Description], Icon, Config, CreatedBy)
        VALUES (@AddonId, @CompanyId, @Title, @Description, @Icon, @Config, @CreatedBy);

        SET @Resultado = 1;
        SET @Mensaje = 'Addon creado';
    END

    -- Reemplazar módulos
    DELETE FROM zsys.StudioAddonModule WHERE AddonId = @AddonId;
    IF @Modules IS NOT NULL AND @Modules <> ''
    BEGIN
        INSERT INTO zsys.StudioAddonModule (AddonId, ModuleId)
        SELECT @AddonId, LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@Modules, ',')
        WHERE LTRIM(RTRIM(value)) <> '';
    END
END
GO

-- ── SP: Delete (soft) ──

IF OBJECT_ID('zsys.usp_zsys_StudioAddon_Delete', 'P') IS NOT NULL DROP PROCEDURE zsys.usp_zsys_StudioAddon_Delete;
GO
CREATE PROCEDURE zsys.usp_zsys_StudioAddon_Delete
    @CompanyId   INT,
    @AddonId     VARCHAR(50),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM zsys.StudioAddon WHERE AddonId = @AddonId AND CompanyId = @CompanyId AND IsActive = 1)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = 'Addon no encontrado';
        RETURN;
    END

    UPDATE zsys.StudioAddon SET IsActive = 0, UpdatedAt = SYSUTCDATETIME()
    WHERE AddonId = @AddonId AND CompanyId = @CompanyId;

    DELETE FROM zsys.StudioAddonModule WHERE AddonId = @AddonId;

    SET @Resultado = 1;
    SET @Mensaje = 'Addon eliminado';
END
GO
