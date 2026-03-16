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

  IF OBJECT_ID('cfg.MediaAsset', 'U') IS NOT NULL
  BEGIN
    IF EXISTS (
      SELECT 1
      FROM sys.key_constraints
      WHERE [name] = N'UQ_cfg_MediaAsset_Storage'
        AND [parent_object_id] = OBJECT_ID(N'cfg.MediaAsset')
    )
    BEGIN
      ALTER TABLE cfg.MediaAsset DROP CONSTRAINT UQ_cfg_MediaAsset_Storage;
    END;

    ALTER TABLE cfg.MediaAsset ALTER COLUMN StorageKey NVARCHAR(400) NOT NULL;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.key_constraints
      WHERE [name] = N'UQ_cfg_MediaAsset_Storage'
        AND [parent_object_id] = OBJECT_ID(N'cfg.MediaAsset')
    )
    BEGIN
      ALTER TABLE cfg.MediaAsset
      ADD CONSTRAINT UQ_cfg_MediaAsset_Storage UNIQUE (StorageProvider, StorageKey);
    END;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO
