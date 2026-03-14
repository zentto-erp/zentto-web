SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Integracion Contable POS + Restaurante
  - Vincula documentos origen con AsientoContableId
  - Carga configuracion contable base para ventas POS/Restaurante
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('dbo.PosVentas', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.PosVentas', 'AsientoContableId') IS NULL
      ALTER TABLE dbo.PosVentas ADD AsientoContableId BIGINT NULL;

    IF OBJECT_ID('dbo.AsientoContable', 'U') IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM sys.foreign_keys
         WHERE name = 'FK_PosVentas_AsientoContable'
       )
    BEGIN
      ALTER TABLE dbo.PosVentas
      ADD CONSTRAINT FK_PosVentas_AsientoContable
      FOREIGN KEY (AsientoContableId) REFERENCES dbo.AsientoContable(Id);
    END
  END

  IF OBJECT_ID('dbo.RestaurantePedidos', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.RestaurantePedidos', 'AsientoContableId') IS NULL
      ALTER TABLE dbo.RestaurantePedidos ADD AsientoContableId BIGINT NULL;

    IF OBJECT_ID('dbo.AsientoContable', 'U') IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM sys.foreign_keys
         WHERE name = 'FK_RestaurantePedidos_AsientoContable'
       )
    BEGIN
      ALTER TABLE dbo.RestaurantePedidos
      ADD CONSTRAINT FK_RestaurantePedidos_AsientoContable
      FOREIGN KEY (AsientoContableId) REFERENCES dbo.AsientoContable(Id);
    END
  END

  IF OBJECT_ID('dbo.PosVentas', 'U') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = 'IX_PosVentas_AsientoContableId'
         AND object_id = OBJECT_ID('dbo.PosVentas')
     )
  BEGIN
    CREATE INDEX IX_PosVentas_AsientoContableId ON dbo.PosVentas(AsientoContableId);
  END

  IF OBJECT_ID('dbo.RestaurantePedidos', 'U') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = 'IX_RestaurantePedidos_AsientoContableId'
         AND object_id = OBJECT_ID('dbo.RestaurantePedidos')
     )
  BEGIN
    CREATE INDEX IX_RestaurantePedidos_AsientoContableId ON dbo.RestaurantePedidos(AsientoContableId);
  END

  IF OBJECT_ID('dbo.ConfiguracionContableAuxiliar', 'U') IS NOT NULL
     AND OBJECT_ID('dbo.Cuentas', 'U') IS NOT NULL
  BEGIN
    ;WITH seed AS (
      SELECT * FROM (VALUES
        ('POS', 'VENTA_TOTAL_CAJA', 'DEBE',  '1.1.01', 'VEN', 'Cobro venta POS (caja)'),
        ('POS', 'VENTA_TOTAL_BANCO', 'DEBE', '1.1.02', 'VEN', 'Cobro venta POS (banco/tarjeta)'),
        ('POS', 'VENTA_TOTAL', 'DEBE',       '1.1.01', 'VEN', 'Cobro venta POS'),
        ('POS', 'VENTA_BASE', 'HABER',       '4.1.01', 'VEN', 'Ingreso base venta POS'),
        ('POS', 'VENTA_IVA', 'HABER',        '2.1.03', 'VEN', 'IVA por pagar venta POS'),

        ('RESTAURANTE', 'VENTA_TOTAL_CAJA', 'DEBE',  '1.1.01', 'VEN', 'Cobro venta restaurante (caja)'),
        ('RESTAURANTE', 'VENTA_TOTAL_BANCO', 'DEBE', '1.1.02', 'VEN', 'Cobro venta restaurante (banco/tarjeta)'),
        ('RESTAURANTE', 'VENTA_TOTAL', 'DEBE',       '1.1.01', 'VEN', 'Cobro venta restaurante'),
        ('RESTAURANTE', 'VENTA_BASE', 'HABER',       '4.1.03', 'VEN', 'Ingreso base venta restaurante'),
        ('RESTAURANTE', 'VENTA_IVA', 'HABER',        '2.1.03', 'VEN', 'IVA por pagar venta restaurante')
      ) v(Modulo, Proceso, Naturaleza, CuentaContable, CentroCostoDefault, Descripcion)
    )
    INSERT INTO dbo.ConfiguracionContableAuxiliar (
      Modulo, Proceso, Naturaleza, CuentaContable, CentroCostoDefault, Descripcion, Activo
    )
    SELECT
      s.Modulo,
      s.Proceso,
      s.Naturaleza,
      s.CuentaContable,
      s.CentroCostoDefault,
      s.Descripcion,
      1
    FROM seed s
    WHERE EXISTS (
      SELECT 1 FROM dbo.Cuentas c WHERE LTRIM(RTRIM(c.COD_CUENTA)) = LTRIM(RTRIM(s.CuentaContable))
    )
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.ConfiguracionContableAuxiliar x
        WHERE x.Modulo = s.Modulo
          AND x.Proceso = s.Proceso
          AND x.Naturaleza = s.Naturaleza
          AND x.CuentaContable = s.CuentaContable
      );
  END

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error alter_pos_restaurante_contabilidad_bridge.sql: %s', 16, 1, @Err);
END CATCH;
GO
