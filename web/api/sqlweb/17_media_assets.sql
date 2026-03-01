SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('cfg.MediaAsset', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.MediaAsset(
      MediaAssetId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      StorageProvider     NVARCHAR(20) NOT NULL CONSTRAINT DF_cfg_MediaAsset_Provider DEFAULT(N'LOCAL'),
      StorageKey          NVARCHAR(400) NOT NULL,
      PublicUrl           NVARCHAR(700) NOT NULL,
      OriginalFileName    NVARCHAR(260) NULL,
      MimeType            NVARCHAR(120) NOT NULL,
      FileExtension       NVARCHAR(20) NULL,
      FileSizeBytes       BIGINT NOT NULL CONSTRAINT DF_cfg_MediaAsset_Size DEFAULT(0),
      ChecksumSha256      CHAR(64) NULL,
      AltText             NVARCHAR(200) NULL,
      WidthPx             INT NULL,
      HeightPx            INT NULL,
      IsActive            BIT NOT NULL CONSTRAINT DF_cfg_MediaAsset_IsActive DEFAULT(1),
      IsDeleted           BIT NOT NULL CONSTRAINT DF_cfg_MediaAsset_IsDeleted DEFAULT(0),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_MediaAsset_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_MediaAsset_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_cfg_MediaAsset_Storage UNIQUE (StorageProvider, StorageKey),
      CONSTRAINT FK_cfg_MediaAsset_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_cfg_MediaAsset_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_cfg_MediaAsset_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_cfg_MediaAsset_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_cfg_MediaAsset_Scope
      ON cfg.MediaAsset (CompanyId, BranchId, IsDeleted, IsActive, MediaAssetId DESC);
  END;

  IF OBJECT_ID('cfg.EntityImage', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.EntityImage(
      EntityImageId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      EntityType          NVARCHAR(80) NOT NULL,
      EntityId            BIGINT NOT NULL,
      MediaAssetId        BIGINT NOT NULL,
      RoleCode            NVARCHAR(30) NULL,
      SortOrder           INT NOT NULL CONSTRAINT DF_cfg_EntityImage_Sort DEFAULT(0),
      IsPrimary           BIT NOT NULL CONSTRAINT DF_cfg_EntityImage_IsPrimary DEFAULT(0),
      IsActive            BIT NOT NULL CONSTRAINT DF_cfg_EntityImage_IsActive DEFAULT(1),
      IsDeleted           BIT NOT NULL CONSTRAINT DF_cfg_EntityImage_IsDeleted DEFAULT(0),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_EntityImage_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_EntityImage_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_cfg_EntityImage_Link UNIQUE (CompanyId, BranchId, EntityType, EntityId, MediaAssetId),
      CONSTRAINT FK_cfg_EntityImage_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_cfg_EntityImage_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_cfg_EntityImage_MediaAsset FOREIGN KEY (MediaAssetId) REFERENCES cfg.MediaAsset(MediaAssetId),
      CONSTRAINT FK_cfg_EntityImage_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_cfg_EntityImage_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_cfg_EntityImage_Entity
      ON cfg.EntityImage (CompanyId, BranchId, EntityType, EntityId, IsDeleted, IsActive, SortOrder, EntityImageId);

    CREATE UNIQUE INDEX UX_cfg_EntityImage_Primary
      ON cfg.EntityImage (CompanyId, BranchId, EntityType, EntityId)
      WHERE IsPrimary = 1 AND IsDeleted = 0 AND IsActive = 1;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO
