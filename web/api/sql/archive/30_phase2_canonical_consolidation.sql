SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Fase 2 - Consolidacion canónica por dominio
  - Registra decisiones de duplicidad
  - Consolida pares clave:
      Categoria/Categorias -> Categorias (canonica)
      Cliente/Clientes     -> Clientes (canonica)
      Inventarios/Inventario -> Inventario (canonica)
      Monedas -> MonedaDenominacion (separa dominio y mantiene compatibilidad)
  - Crea vistas de compatibilidad para objetos legacy
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('dbo.SchemaGovernanceDecision', 'U') IS NULL
  BEGIN
    RAISERROR('SchemaGovernanceDecision no existe. Ejecuta 00_governance_baseline.sql primero.', 16, 1);
  END

  ;WITH dup AS (
    SELECT
      CONCAT(table_a, '<->', table_b) AS object_name,
      CONCAT('Evaluar consolidacion por similitud (ratio>=0.95). Pair: ', table_a, ' / ', table_b) AS action_note
    FROM dbo.vw_Governance_TableSimilarityCandidates
    WHERE similarity_ratio >= 0.9500
  )
  MERGE dbo.SchemaGovernanceDecision AS tgt
  USING dup AS src
     ON tgt.DecisionGroup = 'DUPLICATE_TABLE'
    AND tgt.ObjectType = 'TABLE'
    AND tgt.ObjectName = src.object_name
  WHEN NOT MATCHED THEN
    INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
    VALUES ('DUPLICATE_TABLE', 'TABLE', src.object_name, 'PENDING', 'HIGH', 'Consolidar o eliminar duplicado', src.action_note, 'DBA', 'SYSTEM', 'SYSTEM');

  -- ===== Categoria -> Categorias =====
  IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.Categorias', 'LegacyCodigoInt') IS NULL
      ALTER TABLE dbo.Categorias ADD LegacyCodigoInt INT NULL;

    IF OBJECT_ID('dbo.Categoria', 'U') IS NOT NULL
    BEGIN
      EXEC('
        INSERT INTO dbo.Categorias (Codigo, Nombre, Tipo, Impuesto, Co_Usuario, LegacyCodigoInt)
        SELECT
          CAST(c.Codigo AS NVARCHAR(40)) AS Codigo,
          c.Nombre,
          NULL AS Tipo,
          NULL AS Impuesto,
          c.Co_Usuario,
          c.Codigo AS LegacyCodigoInt
        FROM dbo.Categoria c
        WHERE NOT EXISTS (
          SELECT 1
          FROM dbo.Categorias x
          WHERE x.Codigo = CAST(c.Codigo AS NVARCHAR(40))
             OR x.LegacyCodigoInt = c.Codigo
        );
      ');

      IF OBJECT_ID('dbo.Categoria__legacy_backup_phase2', 'U') IS NULL
        SELECT * INTO dbo.Categoria__legacy_backup_phase2 FROM dbo.Categoria;

      DROP TABLE dbo.Categoria;
    END

    IF OBJECT_ID('dbo.Categoria', 'V') IS NOT NULL
      DROP VIEW dbo.Categoria;

    EXEC('
      CREATE VIEW dbo.Categoria
      AS
      SELECT
        COALESCE(LegacyCodigoInt, TRY_CAST(Codigo AS INT)) AS Codigo,
        Nombre,
        Co_Usuario,
        upsize_ts
      FROM dbo.Categorias;
    ');

    IF OBJECT_ID('dbo.TR_Categoria_IOI', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Categoria_IOI;
    IF OBJECT_ID('dbo.TR_Categoria_IOU', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Categoria_IOU;
    IF OBJECT_ID('dbo.TR_Categoria_IOD', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Categoria_IOD;

    EXEC('
      CREATE TRIGGER dbo.TR_Categoria_IOI
      ON dbo.Categoria
      INSTEAD OF INSERT
      AS
      BEGIN
        SET NOCOUNT ON;
        INSERT INTO dbo.Categorias (Codigo, Nombre, Tipo, Impuesto, Co_Usuario, LegacyCodigoInt)
        SELECT
          CAST(i.Codigo AS NVARCHAR(40)),
          i.Nombre,
          NULL,
          NULL,
          i.Co_Usuario,
          i.Codigo
        FROM inserted i
        WHERE NOT EXISTS (
          SELECT 1
          FROM dbo.Categorias x
          WHERE x.Codigo = CAST(i.Codigo AS NVARCHAR(40))
             OR x.LegacyCodigoInt = i.Codigo
        );
      END;
    ');

    EXEC('
      CREATE TRIGGER dbo.TR_Categoria_IOU
      ON dbo.Categoria
      INSTEAD OF UPDATE
      AS
      BEGIN
        SET NOCOUNT ON;
        UPDATE c
          SET c.Nombre = i.Nombre,
              c.Co_Usuario = i.Co_Usuario,
              c.LegacyCodigoInt = i.Codigo
        FROM dbo.Categorias c
        INNER JOIN inserted i
          ON c.LegacyCodigoInt = i.Codigo
          OR TRY_CAST(c.Codigo AS INT) = i.Codigo;
      END;
    ');

    EXEC('
      CREATE TRIGGER dbo.TR_Categoria_IOD
      ON dbo.Categoria
      INSTEAD OF DELETE
      AS
      BEGIN
        SET NOCOUNT ON;
        DELETE c
        FROM dbo.Categorias c
        INNER JOIN deleted d
          ON c.LegacyCodigoInt = d.Codigo
          OR TRY_CAST(c.Codigo AS INT) = d.Codigo;
      END;
    ');
  END

  MERGE dbo.SchemaGovernanceDecision AS tgt
  USING (
    SELECT
      'Categoria<->Categorias' AS ObjectName,
      'Consolidar en Categorias y mantener Categoria como vista con triggers INSTEAD OF' AS ProposedAction
  ) AS src
  ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
  WHEN MATCHED THEN
    UPDATE SET DecisionStatus='DONE', RiskLevel='MEDIUM', ProposedAction=src.ProposedAction, UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
  WHEN NOT MATCHED THEN
    INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
    VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'DONE','MEDIUM',src.ProposedAction,'Consolidado en fase2','DBA','SYSTEM','SYSTEM');

  -- ===== Cliente -> Clientes =====
  IF OBJECT_ID('dbo.Clientes', 'U') IS NOT NULL
  BEGIN
    IF OBJECT_ID('dbo.Cliente', 'U') IS NOT NULL
    BEGIN
      ;WITH src AS (
        SELECT
          c.Rif,
          c.Nombre,
          c.Telefono,
          ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM dbo.Cliente c
      )
      INSERT INTO dbo.Clientes (CODIGO, NOMBRE, RIF, TELEFONO, COD_USUARIO)
      SELECT
        CONCAT('LGC', RIGHT('000000000' + CAST(s.rn AS NVARCHAR(9)), 9)) AS CODIGO,
        s.Nombre,
        s.Rif,
        s.Telefono,
        'MIGRA2'
      FROM src s
      WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Clientes x
        WHERE ISNULL(x.RIF, '') = ISNULL(s.Rif, '')
          AND ISNULL(x.NOMBRE, '') = ISNULL(s.Nombre, '')
          AND ISNULL(x.TELEFONO, '') = ISNULL(s.Telefono, '')
      )
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.Clientes y
        WHERE y.CODIGO = CONCAT('LGC', RIGHT('000000000' + CAST(s.rn AS NVARCHAR(9)), 9))
      );

      IF OBJECT_ID('dbo.Cliente__legacy_backup_phase2', 'U') IS NULL
        SELECT * INTO dbo.Cliente__legacy_backup_phase2 FROM dbo.Cliente;

      DROP TABLE dbo.Cliente;
    END

    IF OBJECT_ID('dbo.Cliente', 'V') IS NOT NULL
      DROP VIEW dbo.Cliente;

    EXEC('
      CREATE VIEW dbo.Cliente
      AS
      SELECT
        RIF AS Rif,
        NOMBRE AS Nombre,
        TELEFONO AS Telefono
      FROM dbo.Clientes;
    ');
  END

  MERGE dbo.SchemaGovernanceDecision AS tgt
  USING (
    SELECT
      'Cliente<->Clientes' AS ObjectName,
      'Consolidar en Clientes y mantener Cliente como vista de compatibilidad' AS ProposedAction
  ) AS src
  ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
  WHEN MATCHED THEN
    UPDATE SET DecisionStatus='DONE', RiskLevel='MEDIUM', ProposedAction=src.ProposedAction, UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
  WHEN NOT MATCHED THEN
    INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
    VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'DONE','MEDIUM',src.ProposedAction,'Consolidado en fase2','DBA','SYSTEM','SYSTEM');

  -- ===== Inventarios -> Inventario =====
  IF OBJECT_ID('dbo.Inventario', 'U') IS NOT NULL
  BEGIN
    IF OBJECT_ID('dbo.Inventarios', 'U') IS NOT NULL
    BEGIN
      INSERT INTO dbo.Inventario (
        CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXISTENCIA, VENTA,
        MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA, PORCENTAJE, PRECIO_VENTA1, PORCENTAJE1, PRECIO_VENTA2, PORCENTAJE2, PRECIO_VENTA3,
        PORCENTAJE3, Alicuota, FECHA, UBICACION, Co_Usuario, Linea, N_PARTE, OFERTA_DESDE, OFERTA_HASTA, oFERTA_PRECIO,
        OFERTA_CANTIDAD, OFERTA_PORCENTAJE, APLICABLE_CONTADO, APLICABLE_CREDITO, Servicio, COSTO_PROMEDIO, COSTO_REFERENCIA, Garantia, Pasa, Producto_Relacion,
        Cantidad_Granel, Barra, Tasa_Dolar, Descuento_Compras, Flete_Compras, UbicaFisica, FechaVence, Eliminado, Aceptada, Fecha_Inventario
      )
      SELECT
        i.CODIGO, i.Referencia, i.Categoria, i.Marca, i.Tipo, i.Unidad, i.Clase, i.DESCRIPCION, i.EXISTENCIA, i.VENTA,
        i.MINIMO, i.MAXIMO, i.PRECIO_COMPRA, i.PRECIO_VENTA, i.PORCENTAJE, i.PRECIO_VENTA1, i.PORCENTAJE1, i.PRECIO_VENTA2, i.PORCENTAJE2, i.PRECIO_VENTA3,
        i.PORCENTAJE3, i.Alicuota, i.FECHA, i.UBICACION, i.Co_Usuario, i.Linea, i.N_PARTE, i.OFERTA_DESDE, i.OFERTA_HASTA, i.oFERTA_PRECIO,
        i.OFERTA_CANTIDAD, i.OFERTA_PORCENTAJE, i.APLICABLE_CONTADO, i.APLICABLE_CREDITO, i.Servicio, i.COSTO_PROMEDIO, i.COSTO_REFERENCIA, i.Garantia, i.Pasa, i.Producto_Relacion,
        i.Cantidad_Granel, i.Barra, i.Tasa_Dolar, i.Descuento_Compras, i.Flete_Compras, i.UbicaFisica, i.FechaVence, i.Eliminado, i.Aceptada, i.Fecha_Inventarios
      FROM dbo.Inventarios i
      WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Inventario x WHERE ISNULL(x.CODIGO, '') = ISNULL(i.CODIGO, '')
      );

      IF OBJECT_ID('dbo.Inventarios__legacy_backup_phase2', 'U') IS NULL
        SELECT * INTO dbo.Inventarios__legacy_backup_phase2 FROM dbo.Inventarios;

      DROP TABLE dbo.Inventarios;
    END

    IF OBJECT_ID('dbo.Inventarios', 'V') IS NOT NULL
      DROP VIEW dbo.Inventarios;

    EXEC('
      CREATE VIEW dbo.Inventarios
      AS
      SELECT
        CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXISTENCIA, VENTA,
        MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA, PORCENTAJE, PRECIO_VENTA1, PORCENTAJE1, PRECIO_VENTA2, PORCENTAJE2, PRECIO_VENTA3,
        PORCENTAJE3, Alicuota, FECHA, UBICACION, Co_Usuario, Linea, N_PARTE, OFERTA_DESDE, OFERTA_HASTA, oFERTA_PRECIO,
        OFERTA_CANTIDAD, OFERTA_PORCENTAJE, APLICABLE_CONTADO, APLICABLE_CREDITO, Servicio, COSTO_PROMEDIO, COSTO_REFERENCIA, Garantia, Pasa, Producto_Relacion,
        Cantidad_Granel, Barra, Tasa_Dolar, Descuento_Compras, Flete_Compras, upsize_ts, UbicaFisica, FechaVence, Eliminado, Aceptada, Fecha_Inventario AS Fecha_Inventarios
      FROM dbo.Inventario;
    ');
  END

  MERGE dbo.SchemaGovernanceDecision AS tgt
  USING (
    SELECT
      'Inventario<->Inventarios' AS ObjectName,
      'Consolidar en Inventario y mantener Inventarios como vista de compatibilidad' AS ProposedAction
  ) AS src
  ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
  WHEN MATCHED THEN
    UPDATE SET DecisionStatus='DONE', RiskLevel='MEDIUM', ProposedAction=src.ProposedAction, UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
  WHEN NOT MATCHED THEN
    INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
    VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'DONE','MEDIUM',src.ProposedAction,'Consolidado en fase2','DBA','SYSTEM','SYSTEM');

  -- ===== Monedas -> MonedaDenominacion (separa dominio) =====
  IF OBJECT_ID('dbo.MonedaDenominacion', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.MonedaDenominacion (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Valor INT NOT NULL,
      Cantidad NVARCHAR(100) NULL,
      CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      UpdatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      CreatedBy NVARCHAR(40) NULL,
      UpdatedBy NVARCHAR(40) NULL,
      IsDeleted BIT NOT NULL DEFAULT(0),
      RowVer ROWVERSION
    );
    CREATE UNIQUE INDEX UX_MonedaDenominacion_Valor ON dbo.MonedaDenominacion(Valor);
  END

  IF OBJECT_ID('dbo.Monedas', 'U') IS NOT NULL
  BEGIN
    INSERT INTO dbo.MonedaDenominacion (Valor, Cantidad, CreatedBy, UpdatedBy)
    SELECT m.VALOR, m.CANTIDAD, 'MIGRA2', 'MIGRA2'
    FROM dbo.Monedas m
    WHERE NOT EXISTS (
      SELECT 1 FROM dbo.MonedaDenominacion d WHERE d.Valor = m.VALOR
    );

    IF OBJECT_ID('dbo.Monedas__legacy_backup_phase2', 'U') IS NULL
      SELECT * INTO dbo.Monedas__legacy_backup_phase2 FROM dbo.Monedas;

    DROP TABLE dbo.Monedas;
  END

  IF OBJECT_ID('dbo.Monedas', 'V') IS NOT NULL
    DROP VIEW dbo.Monedas;

  EXEC('
    CREATE VIEW dbo.Monedas
    AS
    SELECT
      Valor AS VALOR,
      Cantidad AS CANTIDAD,
      CAST(NULL AS VARBINARY(8)) AS upsize_ts
    FROM dbo.MonedaDenominacion
    WHERE IsDeleted = 0;
  ');

  IF OBJECT_ID('dbo.TR_Monedas_IOI', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Monedas_IOI;
  IF OBJECT_ID('dbo.TR_Monedas_IOU', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Monedas_IOU;
  IF OBJECT_ID('dbo.TR_Monedas_IOD', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Monedas_IOD;

  EXEC('
    CREATE TRIGGER dbo.TR_Monedas_IOI
    ON dbo.Monedas
    INSTEAD OF INSERT
    AS
    BEGIN
      SET NOCOUNT ON;
      MERGE dbo.MonedaDenominacion AS tgt
      USING (
        SELECT i.VALOR, i.CANTIDAD
        FROM inserted i
      ) AS src
      ON tgt.Valor = src.VALOR
      WHEN MATCHED THEN
        UPDATE SET tgt.Cantidad = src.CANTIDAD, tgt.UpdatedAt = SYSUTCDATETIME()
      WHEN NOT MATCHED THEN
        INSERT (Valor, Cantidad, CreatedBy, UpdatedBy)
        VALUES (src.VALOR, src.CANTIDAD, ''LEGACY'', ''LEGACY'');
    END;
  ');

  EXEC('
    CREATE TRIGGER dbo.TR_Monedas_IOU
    ON dbo.Monedas
    INSTEAD OF UPDATE
    AS
    BEGIN
      SET NOCOUNT ON;
      UPDATE d
        SET d.Cantidad = i.CANTIDAD,
            d.UpdatedAt = SYSUTCDATETIME()
      FROM dbo.MonedaDenominacion d
      INNER JOIN inserted i ON i.VALOR = d.Valor;
    END;
  ');

  EXEC('
    CREATE TRIGGER dbo.TR_Monedas_IOD
    ON dbo.Monedas
    INSTEAD OF DELETE
    AS
    BEGIN
      SET NOCOUNT ON;
      UPDATE d
        SET d.IsDeleted = 1,
            d.UpdatedAt = SYSUTCDATETIME()
      FROM dbo.MonedaDenominacion d
      INNER JOIN deleted x ON x.VALOR = d.Valor;
    END;
  ');

  MERGE dbo.SchemaGovernanceDecision AS tgt
  USING (
    SELECT
      'Moneda<->Monedas' AS ObjectName,
      'Separacion de dominio: Moneda (catalogo) y MonedaDenominacion; Monedas queda como vista legacy' AS ProposedAction
  ) AS src
  ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
  WHEN MATCHED THEN
    UPDATE SET DecisionStatus='DONE', RiskLevel='MEDIUM', ProposedAction=src.ProposedAction, UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
  WHEN NOT MATCHED THEN
    INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
    VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'DONE','MEDIUM',src.ProposedAction,'Consolidado en fase2','DBA','SYSTEM','SYSTEM');

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 30_phase2_canonical_consolidation.sql: %s', 16, 1, @Err);
END CATCH;
GO
