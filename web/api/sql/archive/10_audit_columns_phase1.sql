SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Fase 1 - Estandar de auditoria en tablas criticas (no destructivo)
  Columnas:
    CreatedAt, UpdatedAt, CreatedBy, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVer
  Incluye trigger por tabla para mantener UpdatedAt en UPDATE.
*/

BEGIN TRY
  BEGIN TRAN;

  DECLARE @TargetTables TABLE (TableName SYSNAME PRIMARY KEY);
  INSERT INTO @TargetTables (TableName)
  VALUES
    ('DocumentosVenta'),
    ('DocumentosVentaDetalle'),
    ('DocumentosVentaPago'),
    ('DocumentosCompra'),
    ('DocumentosCompraDetalle'),
    ('DocumentosCompraPago'),
    ('PosVentas'),
    ('PosVentasDetalle'),
    ('PosVentasEnEspera'),
    ('PosVentasEnEsperaDetalle'),
    ('RestaurantePedidos'),
    ('RestaurantePedidoItems'),
    ('AsientoContable'),
    ('AsientoContableDetalle'),
    ('AsientoOrigenAuxiliar'),
    ('FiscalCountryConfig'),
    ('FiscalTaxRates'),
    ('FiscalInvoiceTypes'),
    ('FiscalRecords');

  DECLARE @TableName SYSNAME;
  DECLARE @Sql NVARCHAR(MAX);
  DECLARE @JoinPk NVARCHAR(MAX);
  DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName FROM @TargetTables ORDER BY TableName;
  OPEN c;
  FETCH NEXT FROM c INTO @TableName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF OBJECT_ID('dbo.' + @TableName, 'U') IS NOT NULL
    BEGIN
      IF COL_LENGTH('dbo.' + @TableName, 'CreatedAt') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) +
                   N' ADD CreatedAt DATETIME2(0) NOT NULL CONSTRAINT ' +
                   QUOTENAME('DF_' + @TableName + '_CreatedAt') + N' DEFAULT SYSUTCDATETIME();';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'UpdatedAt') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) +
                   N' ADD UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT ' +
                   QUOTENAME('DF_' + @TableName + '_UpdatedAt') + N' DEFAULT SYSUTCDATETIME();';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'CreatedBy') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD CreatedBy NVARCHAR(40) NULL;';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'UpdatedBy') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD UpdatedBy NVARCHAR(40) NULL;';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'IsDeleted') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) +
                   N' ADD IsDeleted BIT NOT NULL CONSTRAINT ' +
                   QUOTENAME('DF_' + @TableName + '_IsDeleted') + N' DEFAULT(0);';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'DeletedAt') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD DeletedAt DATETIME2(0) NULL;';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'DeletedBy') IS NULL
      BEGIN
        SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD DeletedBy NVARCHAR(40) NULL;';
        EXEC(@Sql);
      END

      IF COL_LENGTH('dbo.' + @TableName, 'RowVer') IS NULL
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM sys.columns c
          WHERE c.object_id = OBJECT_ID('dbo.' + @TableName)
            AND c.system_type_id = 189
        )
        BEGIN
          SET @Sql = N'ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD RowVer ROWVERSION;';
          EXEC(@Sql);
        END
      END

      -- Backfill defensivo para filas previas
      SET @Sql = N'
        UPDATE dbo.' + QUOTENAME(@TableName) + '
        SET
          CreatedAt = ISNULL(CreatedAt, SYSUTCDATETIME()),
          UpdatedAt = ISNULL(UpdatedAt, ISNULL(CreatedAt, SYSUTCDATETIME())),
          IsDeleted = ISNULL(IsDeleted, 0)
        WHERE CreatedAt IS NULL OR UpdatedAt IS NULL OR IsDeleted IS NULL;
      ';
      EXEC(@Sql);

      -- Trigger UpdatedAt (solo si hay PK)
      SELECT @JoinPk =
        STUFF((
          SELECT ' AND tgt.' + QUOTENAME(cpk.name) + ' = ins.' + QUOTENAME(cpk.name)
          FROM sys.key_constraints kc
          INNER JOIN sys.index_columns ic
            ON ic.object_id = kc.parent_object_id
           AND ic.index_id = kc.unique_index_id
          INNER JOIN sys.columns cpk
            ON cpk.object_id = ic.object_id
           AND cpk.column_id = ic.column_id
          WHERE kc.parent_object_id = OBJECT_ID('dbo.' + @TableName)
            AND kc.type = 'PK'
          ORDER BY ic.key_ordinal
          FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 5, '');

      IF @JoinPk IS NOT NULL AND LEN(@JoinPk) > 0
      BEGIN
        SET @Sql = N'IF OBJECT_ID(''dbo.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + ''',''TR'') IS NOT NULL ' +
                   N'DROP TRIGGER dbo.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + N';';
        EXEC(@Sql);

        SET @Sql =
          N'CREATE TRIGGER dbo.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + N'
            ON dbo.' + QUOTENAME(@TableName) + N'
            AFTER UPDATE
          AS
          BEGIN
            SET NOCOUNT ON;
            IF UPDATE(UpdatedAt) RETURN;

            UPDATE tgt
              SET UpdatedAt = SYSUTCDATETIME()
            FROM dbo.' + QUOTENAME(@TableName) + N' AS tgt
            INNER JOIN inserted AS ins
              ON ' + @JoinPk + N';
          END;';
        EXEC(@Sql);
      END
    END

    FETCH NEXT FROM c INTO @TableName;
  END
  CLOSE c;
  DEALLOCATE c;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 10_audit_columns_phase1.sql: %s', 16, 1, @Err);
END CATCH;
GO
