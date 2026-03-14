SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Fase 2 Auditoria - Batch Maestros
  - Crea helper dbo.usp_Governance_ApplyAuditColumns
  - Aplica auditoria estandar en tablas maestras/core
*/

IF OBJECT_ID('dbo.usp_Governance_ApplyAuditColumns', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Governance_ApplyAuditColumns;
GO
CREATE PROCEDURE dbo.usp_Governance_ApplyAuditColumns
  @SchemaName SYSNAME = 'dbo',
  @TableName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @FullName NVARCHAR(300) = QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
  DECLARE @ObjId INT = OBJECT_ID(@FullName, 'U');
  DECLARE @Sql NVARCHAR(MAX);
  DECLARE @JoinPk NVARCHAR(MAX);

  IF @ObjId IS NULL RETURN;

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'CreatedAt') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD CreatedAt DATETIME2(0) NOT NULL CONSTRAINT ' +
               QUOTENAME('DF_' + @TableName + '_CreatedAt') + N' DEFAULT SYSUTCDATETIME();';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'UpdatedAt') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT ' +
               QUOTENAME('DF_' + @TableName + '_UpdatedAt') + N' DEFAULT SYSUTCDATETIME();';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'CreatedBy') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD CreatedBy NVARCHAR(40) NULL;';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'UpdatedBy') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD UpdatedBy NVARCHAR(40) NULL;';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'IsDeleted') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD IsDeleted BIT NOT NULL CONSTRAINT ' +
               QUOTENAME('DF_' + @TableName + '_IsDeleted') + N' DEFAULT(0);';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'DeletedAt') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD DeletedAt DATETIME2(0) NULL;';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'DeletedBy') IS NULL
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD DeletedBy NVARCHAR(40) NULL;';
    EXEC(@Sql);
  END

  IF COL_LENGTH(@SchemaName + '.' + @TableName, 'RowVer') IS NULL
     AND NOT EXISTS (
       SELECT 1
       FROM sys.columns c
       WHERE c.object_id = @ObjId
         AND c.system_type_id = 189 -- timestamp/rowversion
     )
  BEGIN
    SET @Sql = N'ALTER TABLE ' + @FullName + N' ADD RowVer ROWVERSION;';
    EXEC(@Sql);
  END

  SET @Sql = N'
    UPDATE ' + @FullName + N'
    SET
      CreatedAt = ISNULL(CreatedAt, SYSUTCDATETIME()),
      UpdatedAt = ISNULL(UpdatedAt, ISNULL(CreatedAt, SYSUTCDATETIME())),
      IsDeleted = ISNULL(IsDeleted, 0)
    WHERE CreatedAt IS NULL OR UpdatedAt IS NULL OR IsDeleted IS NULL;
  ';
  EXEC(@Sql);

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
      WHERE kc.parent_object_id = @ObjId
        AND kc.type = 'PK'
      ORDER BY ic.key_ordinal
      FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 5, '');

  IF @JoinPk IS NOT NULL AND LEN(@JoinPk) > 0
  BEGIN
    SET @Sql = N'IF OBJECT_ID(''' + @SchemaName + '.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + ''',''TR'') IS NOT NULL ' +
               N'DROP TRIGGER ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + N';';
    EXEC(@Sql);

    SET @Sql =
      N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME('TR_Audit_' + @TableName + '_UpdatedAt') + N'
        ON ' + @FullName + N'
        AFTER UPDATE
      AS
      BEGIN
        SET NOCOUNT ON;
        IF UPDATE(UpdatedAt) RETURN;

        UPDATE tgt
          SET UpdatedAt = SYSUTCDATETIME()
        FROM ' + @FullName + N' AS tgt
        INNER JOIN inserted AS ins
          ON ' + @JoinPk + N';
      END;';
    EXEC(@Sql);
  END
END
GO

DECLARE @Masters TABLE (TableName SYSNAME PRIMARY KEY);
INSERT INTO @Masters (TableName)
VALUES
  ('Almacen'),
  ('Bancos'),
  ('Categoria'),
  ('Categorias'),
  ('Centro_Costo'),
  ('Clases'),
  ('Clientes'),
  ('Cuentas'),
  ('CuentasBank'),
  ('Empleados'),
  ('Empresa'),
  ('FiscalCountryConfig'),
  ('FiscalInvoiceTypes'),
  ('FiscalTaxRates'),
  ('Grupos'),
  ('Inventario'),
  ('LINEAS'),
  ('Linea_proveedores'),
  ('Marcas'),
  ('Moneda'),
  ('MonedaDenominacion'),
  ('Proveedores'),
  ('Retenciones'),
  ('Tipos'),
  ('Unidades'),
  ('Usuarios');

DECLARE @TableName SYSNAME;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @Masters ORDER BY TableName;
OPEN c;
FETCH NEXT FROM c INTO @TableName;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    EXEC dbo.usp_Governance_ApplyAuditColumns @SchemaName='dbo', @TableName=@TableName;

    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (SELECT @TableName AS ObjectName) AS src
    ON tgt.DecisionGroup='AUDIT' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='DONE', RiskLevel='LOW', ProposedAction='Auditoria aplicada (batch maestros)', UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('AUDIT','TABLE',src.ObjectName,'DONE','LOW','Auditoria aplicada (batch maestros)','Phase2 maestros','DBA','SYSTEM','SYSTEM');
  END TRY
  BEGIN CATCH
    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (SELECT @TableName AS ObjectName) AS src
    ON tgt.DecisionGroup='AUDIT' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='REJECTED', RiskLevel='HIGH', ProposedAction='Error aplicando auditoria (batch maestros)', Notes=ERROR_MESSAGE(), UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('AUDIT','TABLE',src.ObjectName,'REJECTED','HIGH','Error aplicando auditoria (batch maestros)',ERROR_MESSAGE(),'DBA','SYSTEM','SYSTEM');
  END CATCH;

  FETCH NEXT FROM c INTO @TableName;
END
CLOSE c;
DEALLOCATE c;
GO
