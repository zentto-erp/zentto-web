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

  IF OBJECT_ID(N'dbo.Inventario', N'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH(N'dbo.Inventario', N'Id') IS NULL
    BEGIN
      EXEC(N'ALTER TABLE dbo.Inventario ADD Id INT NULL;');
      EXEC(N'
        ;WITH ordered AS (
          SELECT
            CODIGO,
            ROW_NUMBER() OVER (ORDER BY CODIGO) AS rn
          FROM dbo.Inventario
        )
        UPDATE i
        SET Id = o.rn
        FROM dbo.Inventario i
        INNER JOIN ordered o
          ON o.CODIGO = i.CODIGO;
      ');
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.sequences s
      INNER JOIN sys.schemas sc ON sc.schema_id = s.schema_id
      WHERE sc.name = N'dbo'
        AND s.name = N'Seq_Inventario_Id'
    )
    BEGIN
      DECLARE @nextId INT;
      EXEC sp_executesql
        N'SELECT @n = ISNULL(MAX(Id) + 1, 1) FROM dbo.Inventario;',
        N'@n INT OUTPUT',
        @n = @nextId OUTPUT;
      DECLARE @sql NVARCHAR(400) = N'CREATE SEQUENCE dbo.Seq_Inventario_Id AS INT START WITH ' + CAST(@nextId AS NVARCHAR(20)) + N' INCREMENT BY 1;';
      EXEC (@sql);
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM sys.default_constraints dc
      INNER JOIN sys.columns c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
      WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Inventario')
        AND c.name = N'Id'
    )
    BEGIN
      EXEC(N'
        ALTER TABLE dbo.Inventario
        ADD CONSTRAINT DF_Inventario_Id
        DEFAULT (NEXT VALUE FOR dbo.Seq_Inventario_Id) FOR Id;
      ');
    END;

    EXEC(N'
      UPDATE dbo.Inventario
      SET Id = NEXT VALUE FOR dbo.Seq_Inventario_Id
      WHERE Id IS NULL;
    ');

    IF NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE object_id = OBJECT_ID(N'dbo.Inventario')
        AND name = N'IX_Inventario_Id'
    )
    BEGIN
      EXEC(N'CREATE INDEX IX_Inventario_Id ON dbo.Inventario (Id);');
    END;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO
