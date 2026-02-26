SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Compatibilidad API legacy (objetos faltantes detectados en web/api):
  - Asientos
  - Asientos_Detalle
  - DtllAsiento
  - sp_CxC_Documentos_List
  - sp_CxP_Documentos_List
  - TasasDiarias

  Nota:
  - Se crea AsientoContableDetalle si fue eliminado, porque es tabla canonica
    usada por contabilidad moderna y por el puente de compatibilidad de asientos.
*/

BEGIN TRY
  BEGIN TRAN;

  /* -------------------------------------------------------------------------- */
  /* Canonico contable detalle (si no existe)                                   */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.AsientoContableDetalle', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AsientoContableDetalle (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AsientoId BIGINT NOT NULL,
      Renglon INT NOT NULL CONSTRAINT DF_AsientoContableDetalle_Renglon DEFAULT(1),
      CodCuenta NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(400) NULL,
      CentroCosto NVARCHAR(20) NULL,
      AuxiliarTipo NVARCHAR(30) NULL,
      AuxiliarCodigo NVARCHAR(120) NULL,
      Documento NVARCHAR(120) NULL,
      Debe DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientoContableDetalle_Debe DEFAULT(0),
      Haber DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientoContableDetalle_Haber DEFAULT(0),
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_AsientoContableDetalle_FechaCreacion DEFAULT(GETDATE())
    );
  END;

  IF OBJECT_ID('dbo.FK_AsientoContableDetalle_Asiento', 'F') IS NULL
  BEGIN
    ALTER TABLE dbo.AsientoContableDetalle WITH CHECK
      ADD CONSTRAINT FK_AsientoContableDetalle_Asiento
      FOREIGN KEY (AsientoId) REFERENCES dbo.AsientoContable(Id);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.AsientoContableDetalle')
      AND name = 'IX_AsientoContableDetalle_AsientoId'
  )
  BEGIN
    CREATE INDEX IX_AsientoContableDetalle_AsientoId
      ON dbo.AsientoContableDetalle (AsientoId, Renglon);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.AsientoContableDetalle')
      AND name = 'IX_AsientoContableDetalle_CodCuenta'
  )
  BEGIN
    CREATE INDEX IX_AsientoContableDetalle_CodCuenta
      ON dbo.AsientoContableDetalle (CodCuenta);
  END;

  /* -------------------------------------------------------------------------- */
  /* Compatibilidad Asientos / Asientos_Detalle                                 */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.Asientos', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Asientos (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Fecha DATE NOT NULL CONSTRAINT DF_Asientos_Fecha DEFAULT(CAST(GETDATE() AS DATE)),
      Tipo_Asiento NVARCHAR(20) NOT NULL,
      Concepto NVARCHAR(400) NOT NULL,
      Referencia NVARCHAR(120) NULL,
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Asientos_Estado DEFAULT('APROBADO'),
      Total_Debe DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asientos_TotalDebe DEFAULT(0),
      Total_Haber DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asientos_TotalHaber DEFAULT(0),
      Origen_Modulo NVARCHAR(40) NULL,
      Cod_Usuario NVARCHAR(120) NULL,
      AsientoContableId BIGINT NULL,
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_Asientos_FechaCreacion DEFAULT(GETDATE())
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Asientos')
      AND name = 'IX_Asientos_AsientoContableId'
  )
  BEGIN
    CREATE INDEX IX_Asientos_AsientoContableId
      ON dbo.Asientos (AsientoContableId);
  END;

  IF OBJECT_ID('dbo.Asientos_Detalle', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Asientos_Detalle (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Id_Asiento INT NOT NULL,
      Cod_Cuenta NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(400) NULL,
      Debe DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientosDetalle_Debe DEFAULT(0),
      Haber DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientosDetalle_Haber DEFAULT(0),
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_AsientosDetalle_FechaCreacion DEFAULT(GETDATE())
    );
  END;

  IF OBJECT_ID('dbo.FK_AsientosDetalle_Asientos', 'F') IS NULL
  BEGIN
    ALTER TABLE dbo.Asientos_Detalle WITH CHECK
      ADD CONSTRAINT FK_AsientosDetalle_Asientos
      FOREIGN KEY (Id_Asiento) REFERENCES dbo.Asientos(Id);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Asientos_Detalle')
      AND name = 'IX_AsientosDetalle_IdAsiento'
  )
  BEGIN
    CREATE INDEX IX_AsientosDetalle_IdAsiento
      ON dbo.Asientos_Detalle (Id_Asiento);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Asientos_Detalle')
      AND name = 'IX_AsientosDetalle_CodCuenta'
  )
  BEGIN
    CREATE INDEX IX_AsientosDetalle_CodCuenta
      ON dbo.Asientos_Detalle (Cod_Cuenta);
  END;

  /* -------------------------------------------------------------------------- */
  /* TasasDiarias (compatibilidad modulo config/tasas)                          */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.TasasDiarias', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.TasasDiarias (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Moneda NVARCHAR(10) NOT NULL,
      Tasa DECIMAL(18,6) NOT NULL,
      Fecha DATETIME NOT NULL CONSTRAINT DF_TasasDiarias_Fecha DEFAULT(GETDATE()),
      Origen NVARCHAR(120) NULL,
      CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_TasasDiarias_CreatedAt DEFAULT(SYSUTCDATETIME())
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.TasasDiarias')
      AND name = 'IX_TasasDiarias_Moneda_Fecha'
  )
  BEGIN
    CREATE INDEX IX_TasasDiarias_Moneda_Fecha
      ON dbo.TasasDiarias (Moneda, Fecha DESC);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 44_api_compat_missing_objects.sql (fase tablas): %s', 16, 1, @Err);
END CATCH;
GO

/* -------------------------------------------------------------------------- */
/* Trigger: sincroniza Asientos -> AsientoContable                             */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.TR_Asientos_AI_SyncAsientoContable', 'TR') IS NULL
EXEC('
CREATE TRIGGER dbo.TR_Asientos_AI_SyncAsientoContable
ON dbo.Asientos
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Map TABLE (
    AsientoLegacyId INT NOT NULL,
    AsientoContableId BIGINT NOT NULL
  );

  MERGE dbo.AsientoContable AS tgt
  USING (
    SELECT
      i.Id,
      i.Fecha,
      i.Tipo_Asiento,
      i.Referencia,
      i.Concepto,
      i.Estado,
      i.Total_Debe,
      i.Total_Haber,
      i.Origen_Modulo,
      i.Cod_Usuario
    FROM inserted i
  ) AS src
  ON 1 = 0
  WHEN NOT MATCHED THEN
    INSERT (
      NumeroAsiento,
      Fecha,
      Periodo,
      TipoAsiento,
      Referencia,
      Concepto,
      Moneda,
      Tasa,
      TotalDebe,
      TotalHaber,
      Estado,
      OrigenModulo,
      OrigenDocumento,
      CodUsuario
    )
    VALUES (
      ''LEG-'' + RIGHT(REPLICATE(''0'', 10) + CAST(src.Id AS VARCHAR(20)), 10),
      src.Fecha,
      CONVERT(NVARCHAR(7), src.Fecha, 120),
      src.Tipo_Asiento,
      src.Referencia,
      src.Concepto,
      ''VES'',
      1,
      src.Total_Debe,
      src.Total_Haber,
      src.Estado,
      src.Origen_Modulo,
      src.Referencia,
      src.Cod_Usuario
    )
    OUTPUT src.Id, inserted.Id INTO @Map (AsientoLegacyId, AsientoContableId);

  UPDATE a
  SET a.AsientoContableId = m.AsientoContableId
  FROM dbo.Asientos a
  INNER JOIN @Map m ON m.AsientoLegacyId = a.Id;
END
');
GO

/* -------------------------------------------------------------------------- */
/* Trigger: sincroniza Asientos_Detalle -> AsientoContableDetalle              */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.TR_AsientosDetalle_AI_SyncAsientoContableDetalle', 'TR') IS NULL
EXEC('
CREATE TRIGGER dbo.TR_AsientosDetalle_AI_SyncAsientoContableDetalle
ON dbo.Asientos_Detalle
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT
      i.Id,
      a.AsientoContableId,
      i.Cod_Cuenta,
      i.Descripcion,
      i.Debe,
      i.Haber,
      ROW_NUMBER() OVER (PARTITION BY a.AsientoContableId ORDER BY i.Id) AS rn
    FROM inserted i
    INNER JOIN dbo.Asientos a ON a.Id = i.Id_Asiento
    WHERE a.AsientoContableId IS NOT NULL
  )
  INSERT INTO dbo.AsientoContableDetalle (
    AsientoId,
    Renglon,
    CodCuenta,
    Descripcion,
    Debe,
    Haber
  )
  SELECT
    s.AsientoContableId,
    ISNULL(maxr.MaxRenglon, 0) + s.rn,
    s.Cod_Cuenta,
    s.Descripcion,
    s.Debe,
    s.Haber
  FROM src s
  OUTER APPLY (
    SELECT MAX(d.Renglon) AS MaxRenglon
    FROM dbo.AsientoContableDetalle d
    WHERE d.AsientoId = s.AsientoContableId
  ) maxr;
END
');
GO

/* -------------------------------------------------------------------------- */
/* Vista compatibilidad DtllAsiento                                            */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.DtllAsiento', 'V') IS NOT NULL
  DROP VIEW dbo.DtllAsiento;
GO

CREATE VIEW dbo.DtllAsiento
AS
  SELECT
    CAST(d.Id AS BIGINT) AS Id,
    CAST(d.Id_Asiento AS BIGINT) AS Id_Asiento,
    d.Cod_Cuenta,
    d.Descripcion,
    d.Debe,
    d.Haber
  FROM dbo.Asientos_Detalle d
  UNION ALL
  SELECT
    d.Id,
    d.AsientoId,
    d.CodCuenta AS Cod_Cuenta,
    d.Descripcion,
    d.Debe,
    d.Haber
  FROM dbo.AsientoContableDetalle d;
GO

/* -------------------------------------------------------------------------- */
/* SP compatibilidad CxC                                                       */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_CxC_Documentos_List', 'P') IS NULL
EXEC('CREATE PROCEDURE dbo.sp_CxC_Documentos_List AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_CxC_Documentos_List
  @CodCliente NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;

  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      p.CODIGO AS codCliente,
      p.TIPO AS tipoDoc,
      p.DOCUMENTO AS numDoc,
      p.FECHA AS fecha,
      ISNULL(p.DEBE, 0) AS total,
      ISNULL(p.PEND, ISNULL(p.SALDO, 0)) AS pendiente,
      CASE
        WHEN ISNULL(p.PAID, 0) = 1 OR ISNULL(p.PEND, ISNULL(p.SALDO, 0)) <= 0 THEN 'PAGADO'
        WHEN ISNULL(p.PEND, ISNULL(p.SALDO, 0)) < ISNULL(p.DEBE, 0) THEN 'PARCIAL'
        ELSE 'PENDIENTE'
      END AS estado,
      p.OBS AS observacion,
      p.COD_USUARIO AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY p.FECHA DESC, p.DOCUMENTO DESC, p.id DESC) AS rn
    FROM dbo.p_cobrar p
    WHERE (@CodCliente IS NULL OR p.CODIGO = @CodCliente)
      AND (@TipoDoc IS NULL OR p.TIPO = @TipoDoc)
      AND (@FechaDesde IS NULL OR CAST(p.FECHA AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(p.FECHA AS DATE) <= @FechaHasta)
  )
  SELECT
    codCliente,
    tipoDoc,
    numDoc,
    fecha,
    total,
    pendiente,
    estado,
    observacion,
    codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;
GO

/* -------------------------------------------------------------------------- */
/* SP compatibilidad CxP                                                       */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_CxP_Documentos_List', 'P') IS NULL
EXEC('CREATE PROCEDURE dbo.sp_CxP_Documentos_List AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_CxP_Documentos_List
  @CodProveedor NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;

  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      p.CODIGO AS codProveedor,
      p.TIPO AS tipoDoc,
      p.DOCUMENTO AS numDoc,
      p.FECHA AS fecha,
      ISNULL(p.HABER, 0) AS total,
      ISNULL(p.PEND, ISNULL(p.SALDO, 0)) AS pendiente,
      CASE
        WHEN ISNULL(p.PAID, 0) = 1 OR ISNULL(p.PEND, ISNULL(p.SALDO, 0)) <= 0 THEN 'PAGADO'
        WHEN ISNULL(p.PEND, ISNULL(p.SALDO, 0)) < ISNULL(p.HABER, 0) THEN 'PARCIAL'
        ELSE 'PENDIENTE'
      END AS estado,
      p.OBS AS observacion,
      p.Cod_usuario AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY p.FECHA DESC, p.DOCUMENTO DESC, p.id DESC) AS rn
    FROM dbo.P_Pagar p
    WHERE (@CodProveedor IS NULL OR p.CODIGO = @CodProveedor)
      AND (@TipoDoc IS NULL OR p.TIPO = @TipoDoc)
      AND (@FechaDesde IS NULL OR CAST(p.FECHA AS DATE) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CAST(p.FECHA AS DATE) <= @FechaHasta)
  )
  SELECT
    codProveedor,
    tipoDoc,
    numDoc,
    fecha,
    total,
    pendiente,
    estado,
    observacion,
    codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;
GO
