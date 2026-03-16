SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CutoffDate DATE = '2026-01-01';
DECLARE @RunNote NVARCHAR(500) =
  N'Cleanup destructivo solicitado: tablas no usadas por web/api + SP con create/modify < 2026-01-01';

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID(N'dbo.SchemaCleanupRun', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.SchemaCleanupRun (
      RunId BIGINT IDENTITY(1,1) PRIMARY KEY,
      CutoffDate DATE NOT NULL,
      Notes NVARCHAR(500) NULL,
      StartedAt DATETIME2(0) NOT NULL CONSTRAINT DF_SchemaCleanupRun_StartedAt DEFAULT SYSUTCDATETIME(),
      FinishedAt DATETIME2(0) NULL
    );
  END;

  IF OBJECT_ID(N'dbo.SchemaCleanupDroppedObject', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.SchemaCleanupDroppedObject (
      Id BIGINT IDENTITY(1,1) PRIMARY KEY,
      RunId BIGINT NOT NULL,
      ObjectType VARCHAR(30) NOT NULL,
      SchemaName SYSNAME NOT NULL,
      ObjectName SYSNAME NOT NULL,
      DropReason NVARCHAR(300) NOT NULL,
      DropStatement NVARCHAR(MAX) NOT NULL,
      CreateDate DATETIME NULL,
      ModifyDate DATETIME NULL,
      DroppedAt DATETIME2(0) NOT NULL CONSTRAINT DF_SchemaCleanupDroppedObject_DroppedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT FK_SchemaCleanupDroppedObject_Run FOREIGN KEY (RunId) REFERENCES dbo.SchemaCleanupRun(RunId)
    );
  END;

  INSERT INTO dbo.SchemaCleanupRun (CutoffDate, Notes)
  VALUES (@CutoffDate, @RunNote);

  DECLARE @RunId BIGINT = SCOPE_IDENTITY();

  DECLARE @KeepTables TABLE (
    Name SYSNAME PRIMARY KEY
  );

  INSERT INTO @KeepTables (Name)
  VALUES
    (N'Abonos'),
    (N'Abonos_Detalle'),
    (N'AbonosPagos'),
    (N'AccesoUsuarios'),
    (N'AsientoContable'),
    (N'AsientoOrigenAuxiliar'),
    (N'Bancos'),
    (N'Categorias'),
    (N'Clientes'),
    (N'Compras'),
    (N'ConfiguracionContableAuxiliar'),
    (N'Correlativo'),
    (N'Cotizacion'),
    (N'Cuentas'),
    (N'CuentasBank'),
    (N'Detalle_Compras'),
    (N'Detalle_Cotizacion'),
    (N'Detalle_Deposito'),
    (N'Detalle_facturas'),
    (N'Detalle_notacredito'),
    (N'Detalle_Ordenes'),
    (N'Detalle_Pedidos'),
    (N'Detalle_Presupuestos'),
    (N'DocumentosVenta'),
    (N'DocumentosVentaDetalle'),
    (N'DocumentosVentaPago'),
    (N'Facturas'),
    (N'FiscalCountryConfig'),
    (N'FiscalRecords'),
    (N'Inventario'),
    (N'Inventario_Aux'),
    (N'LINEAS'),
    (N'Marcas'),
    (N'MovCuentas'),
    (N'MovInvent'),
    (N'MovInventMes'),
    (N'NominaConceptoLegal'),
    (N'NOTACREDITO'),
    (N'Ordenes'),
    (N'p_cobrar'),
    (N'P_Pagar'),
    (N'pagos'),
    (N'Pagos_Detalle'),
    (N'Pagosc'),
    (N'Pedidos'),
    (N'PosVentas'),
    (N'PosVentasDetalle'),
    (N'PosVentasEnEspera'),
    (N'Presupuestos'),
    (N'Proveedores'),
    (N'RestauranteAmbientes'),
    (N'RestauranteCategorias'),
    (N'RestauranteCompras'),
    (N'RestauranteComprasDetalle'),
    (N'RestauranteMesas'),
    (N'RestaurantePedidoItems'),
    (N'RestaurantePedidos'),
    (N'RestauranteProductos'),
    (N'RestauranteRecetas'),
    (N'Retenciones'),
    (N'SchemaGovernanceSnapshot'),
    (N'Sys_Mensajes'),
    (N'Sys_Notificaciones'),
    (N'Sys_Tareas'),
    (N'Unidades'),
    (N'Usuarios');

  INSERT INTO @KeepTables (Name)
  SELECT t.name
  FROM sys.tables t
  WHERE t.is_ms_shipped = 0
    AND (t.name LIKE N'SchemaGovernance%' OR t.name LIKE N'SchemaCleanup%')
    AND NOT EXISTS (SELECT 1 FROM @KeepTables k WHERE UPPER(k.Name) = UPPER(t.name));

  IF OBJECT_ID(N'tempdb..#DropTables', N'U') IS NOT NULL DROP TABLE #DropTables;
  SELECT
    t.object_id,
    SchemaName = s.name,
    TableName = t.name
  INTO #DropTables
  FROM sys.tables t
  INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
  WHERE t.is_ms_shipped = 0
    AND NOT EXISTS (SELECT 1 FROM @KeepTables k WHERE UPPER(k.Name) = UPPER(t.name));

  IF OBJECT_ID(N'tempdb..#DropFK', N'U') IS NOT NULL DROP TABLE #DropFK;
  SELECT DISTINCT
    fk.object_id AS ObjectId,
    ParentSchema = OBJECT_SCHEMA_NAME(fk.parent_object_id),
    ParentTable = OBJECT_NAME(fk.parent_object_id),
    ForeignKeyName = fk.name,
    DropStatement = N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
      + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
  INTO #DropFK
  FROM sys.foreign_keys fk
  WHERE fk.parent_object_id IN (SELECT object_id FROM #DropTables)
     OR fk.referenced_object_id IN (SELECT object_id FROM #DropTables);

  DECLARE @ObjectId INT;
  DECLARE @SchemaName SYSNAME;
  DECLARE @ObjectName SYSNAME;
  DECLARE @DropStatement NVARCHAR(MAX);
  DECLARE @CreateDate DATETIME;
  DECLARE @ModifyDate DATETIME;

  DECLARE fk_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ObjectId, ParentSchema, ForeignKeyName, DropStatement
    FROM #DropFK
    ORDER BY ParentSchema, ParentTable, ForeignKeyName;

  OPEN fk_cursor;
  FETCH NEXT FROM fk_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SELECT @CreateDate = o.create_date, @ModifyDate = o.modify_date
    FROM sys.objects o
    WHERE o.object_id = @ObjectId;

    EXEC sp_executesql @DropStatement;

    INSERT INTO dbo.SchemaCleanupDroppedObject
    (
      RunId, ObjectType, SchemaName, ObjectName, DropReason, DropStatement, CreateDate, ModifyDate
    )
    VALUES
    (
      @RunId, 'FOREIGN_KEY', @SchemaName, @ObjectName,
      N'FK eliminada por dependencia de tabla candidata a cleanup', @DropStatement, @CreateDate, @ModifyDate
    );

    FETCH NEXT FROM fk_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  END;
  CLOSE fk_cursor;
  DEALLOCATE fk_cursor;

  IF OBJECT_ID(N'tempdb..#DropViews', N'U') IS NOT NULL DROP TABLE #DropViews;
  SELECT DISTINCT
    v.object_id AS ObjectId,
    SchemaName = SCHEMA_NAME(v.schema_id),
    ViewName = v.name,
    DropStatement = N'DROP VIEW ' + QUOTENAME(SCHEMA_NAME(v.schema_id)) + N'.' + QUOTENAME(v.name) + N';'
  INTO #DropViews
  FROM sys.views v
  INNER JOIN sys.sql_expression_dependencies d ON d.referencing_id = v.object_id
  WHERE d.referenced_id IN (SELECT object_id FROM #DropTables);

  DECLARE view_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ObjectId, SchemaName, ViewName, DropStatement
    FROM #DropViews
    ORDER BY SchemaName, ViewName;

  OPEN view_cursor;
  FETCH NEXT FROM view_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SELECT @CreateDate = o.create_date, @ModifyDate = o.modify_date
    FROM sys.objects o
    WHERE o.object_id = @ObjectId;

    EXEC sp_executesql @DropStatement;

    INSERT INTO dbo.SchemaCleanupDroppedObject
    (
      RunId, ObjectType, SchemaName, ObjectName, DropReason, DropStatement, CreateDate, ModifyDate
    )
    VALUES
    (
      @RunId, 'VIEW', @SchemaName, @ObjectName,
      N'Vista eliminada por dependencia de tabla candidata a cleanup', @DropStatement, @CreateDate, @ModifyDate
    );

    FETCH NEXT FROM view_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  END;
  CLOSE view_cursor;
  DEALLOCATE view_cursor;

  DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_id, SchemaName, TableName,
      N'DROP TABLE ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N';' AS DropStatement
    FROM #DropTables
    ORDER BY SchemaName, TableName;

  OPEN table_cursor;
  FETCH NEXT FROM table_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SELECT @CreateDate = o.create_date, @ModifyDate = o.modify_date
    FROM sys.objects o
    WHERE o.object_id = @ObjectId;

    EXEC sp_executesql @DropStatement;

    INSERT INTO dbo.SchemaCleanupDroppedObject
    (
      RunId, ObjectType, SchemaName, ObjectName, DropReason, DropStatement, CreateDate, ModifyDate
    )
    VALUES
    (
      @RunId, 'TABLE', @SchemaName, @ObjectName,
      N'Tabla fuera del inventario de uso actual en web/api', @DropStatement, @CreateDate, @ModifyDate
    );

    FETCH NEXT FROM table_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement;
  END;
  CLOSE table_cursor;
  DEALLOCATE table_cursor;

  IF OBJECT_ID(N'tempdb..#DropProcs', N'U') IS NOT NULL DROP TABLE #DropProcs;
  SELECT
    p.object_id AS ObjectId,
    SchemaName = SCHEMA_NAME(p.schema_id),
    ProcName = p.name,
    p.create_date,
    p.modify_date,
    DropStatement = N'DROP PROCEDURE ' + QUOTENAME(SCHEMA_NAME(p.schema_id)) + N'.' + QUOTENAME(p.name) + N';'
  INTO #DropProcs
  FROM sys.procedures p
  WHERE p.is_ms_shipped = 0
    AND (p.create_date < @CutoffDate OR p.modify_date < @CutoffDate);

  DECLARE proc_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ObjectId, SchemaName, ProcName, DropStatement, create_date, modify_date
    FROM #DropProcs
    ORDER BY SchemaName, ProcName;

  OPEN proc_cursor;
  FETCH NEXT FROM proc_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement, @CreateDate, @ModifyDate;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC sp_executesql @DropStatement;

    INSERT INTO dbo.SchemaCleanupDroppedObject
    (
      RunId, ObjectType, SchemaName, ObjectName, DropReason, DropStatement, CreateDate, ModifyDate
    )
    VALUES
    (
      @RunId, 'PROCEDURE', @SchemaName, @ObjectName,
      N'Procedimiento con create/modify anterior a 2026-01-01', @DropStatement, @CreateDate, @ModifyDate
    );

    FETCH NEXT FROM proc_cursor INTO @ObjectId, @SchemaName, @ObjectName, @DropStatement, @CreateDate, @ModifyDate;
  END;
  CLOSE proc_cursor;
  DEALLOCATE proc_cursor;

  UPDATE dbo.SchemaCleanupRun
  SET FinishedAt = SYSUTCDATETIME()
  WHERE RunId = @RunId;

  COMMIT TRAN;

  SELECT
    RunId = @RunId,
    TablesDropped = SUM(CASE WHEN ObjectType = 'TABLE' THEN 1 ELSE 0 END),
    ViewsDropped = SUM(CASE WHEN ObjectType = 'VIEW' THEN 1 ELSE 0 END),
    ForeignKeysDropped = SUM(CASE WHEN ObjectType = 'FOREIGN_KEY' THEN 1 ELSE 0 END),
    ProceduresDropped = SUM(CASE WHEN ObjectType = 'PROCEDURE' THEN 1 ELSE 0 END)
  FROM dbo.SchemaCleanupDroppedObject
  WHERE RunId = @RunId;

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
