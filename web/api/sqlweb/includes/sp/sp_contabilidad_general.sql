SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  SPs contabilidad general (SQL Server 2012+)
  Todos los procesos críticos usan transacción y rollback.
*/

IF OBJECT_ID('dbo.usp_Contabilidad_Asientos_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Asientos_List;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Asientos_List
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @TipoAsiento NVARCHAR(20) = NULL,
  @Estado NVARCHAR(20) = NULL,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Offset INT = (CASE WHEN @Page IS NULL OR @Page < 1 THEN 1 ELSE @Page END - 1) * (CASE WHEN @Limit IS NULL OR @Limit < 1 THEN 50 ELSE @Limit END);
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  ;WITH base AS (
    SELECT *
    FROM dbo.AsientoContable a
    WHERE (@FechaDesde IS NULL OR a.Fecha >= @FechaDesde)
      AND (@FechaHasta IS NULL OR a.Fecha <= @FechaHasta)
      AND (@TipoAsiento IS NULL OR a.TipoAsiento = @TipoAsiento)
      AND (@Estado IS NULL OR a.Estado = @Estado)
      AND (@OrigenModulo IS NULL OR a.OrigenModulo = @OrigenModulo)
      AND (@OrigenDocumento IS NULL OR a.OrigenDocumento = @OrigenDocumento)
  )
  SELECT @TotalCount = COUNT(1) FROM base;

  ;WITH base AS (
    SELECT *
    FROM dbo.AsientoContable a
    WHERE (@FechaDesde IS NULL OR a.Fecha >= @FechaDesde)
      AND (@FechaHasta IS NULL OR a.Fecha <= @FechaHasta)
      AND (@TipoAsiento IS NULL OR a.TipoAsiento = @TipoAsiento)
      AND (@Estado IS NULL OR a.Estado = @Estado)
      AND (@OrigenModulo IS NULL OR a.OrigenModulo = @OrigenModulo)
      AND (@OrigenDocumento IS NULL OR a.OrigenDocumento = @OrigenDocumento)
  )
  SELECT *
  FROM base
  ORDER BY Id DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Asiento_Get;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Get
  @AsientoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT * FROM dbo.AsientoContable WHERE Id = @AsientoId;
  SELECT * FROM dbo.AsientoContableDetalle WHERE AsientoId = @AsientoId ORDER BY Renglon, Id;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Crear', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Asiento_Crear;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Crear
  @Fecha DATE,
  @TipoAsiento NVARCHAR(20),
  @Referencia NVARCHAR(120) = NULL,
  @Concepto NVARCHAR(400),
  @Moneda NVARCHAR(10) = 'VES',
  @Tasa DECIMAL(18,6) = 1,
  @OrigenModulo NVARCHAR(40) = NULL,
  @OrigenDocumento NVARCHAR(120) = NULL,
  @CodUsuario NVARCHAR(40) = NULL,
  @DetalleXml NVARCHAR(MAX),
  @AsientoId BIGINT OUTPUT,
  @NumeroAsiento NVARCHAR(40) OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';
  SET @AsientoId = NULL;
  SET @NumeroAsiento = NULL;

  DECLARE @xml XML;
  DECLARE @Periodo NVARCHAR(7) = CONVERT(NVARCHAR(7), @Fecha, 120);

  BEGIN TRY
    SET @xml = CAST(@DetalleXml AS XML);

    DECLARE @det TABLE (
      Renglon INT IDENTITY(1,1),
      CodCuenta NVARCHAR(40),
      Descripcion NVARCHAR(400),
      CentroCosto NVARCHAR(20),
      AuxiliarTipo NVARCHAR(30),
      AuxiliarCodigo NVARCHAR(120),
      Documento NVARCHAR(120),
      Debe DECIMAL(18,2),
      Haber DECIMAL(18,2)
    );

    INSERT INTO @det (CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber)
    SELECT
      NULLIF(N.X.value('@codCuenta','nvarchar(40)'), ''),
      NULLIF(N.X.value('@descripcion','nvarchar(400)'), ''),
      NULLIF(N.X.value('@centroCosto','nvarchar(20)'), ''),
      NULLIF(N.X.value('@auxiliarTipo','nvarchar(30)'), ''),
      NULLIF(N.X.value('@auxiliarCodigo','nvarchar(120)'), ''),
      NULLIF(N.X.value('@documento','nvarchar(120)'), ''),
      ISNULL(NULLIF(N.X.value('@debe','nvarchar(50)'),''), '0'),
      ISNULL(NULLIF(N.X.value('@haber','nvarchar(50)'),''), '0')
    FROM @xml.nodes('/rows/row') N(X);

    IF NOT EXISTS (SELECT 1 FROM @det)
    BEGIN
      SET @Resultado = -1;
      SET @Mensaje = N'Detalle requerido';
      RETURN;
    END

    IF EXISTS (SELECT 1 FROM @det WHERE CodCuenta IS NULL)
    BEGIN
      SET @Resultado = -2;
      SET @Mensaje = N'Existe detalle sin cuenta contable';
      RETURN;
    END

    IF EXISTS (
      SELECT 1
      FROM @det d
      LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
      WHERE c.COD_CUENTA IS NULL
    )
    BEGIN
      SET @Resultado = -3;
      SET @Mensaje = N'Existe detalle con cuenta no registrada en Cuentas';
      RETURN;
    END

    DECLARE @Debe DECIMAL(18,2) = (SELECT ISNULL(SUM(Debe),0) FROM @det);
    DECLARE @Haber DECIMAL(18,2) = (SELECT ISNULL(SUM(Haber),0) FROM @det);

    IF ABS(@Debe - @Haber) > 0.009
    BEGIN
      SET @Resultado = -4;
      SET @Mensaje = N'Asiento descuadrado: Debe y Haber no coinciden';
      RETURN;
    END

    BEGIN TRAN;

    DECLARE @next INT = ISNULL((
      SELECT MAX(CAST(RIGHT(NumeroAsiento, 8) AS INT))
      FROM dbo.AsientoContable
      WHERE ISNUMERIC(RIGHT(NumeroAsiento, 8)) = 1
    ), 0) + 1;
    SET @NumeroAsiento = 'AST-' + RIGHT('00000000' + CAST(@next AS NVARCHAR(10)), 8);

    INSERT INTO dbo.AsientoContable (
      NumeroAsiento, Fecha, Periodo, TipoAsiento, Referencia, Concepto, Moneda, Tasa,
      TotalDebe, TotalHaber, Estado, OrigenModulo, OrigenDocumento, CodUsuario, FechaCreacion
    )
    VALUES (
      @NumeroAsiento, @Fecha, @Periodo, @TipoAsiento, @Referencia, @Concepto, @Moneda, @Tasa,
      @Debe, @Haber, 'APROBADO', @OrigenModulo, @OrigenDocumento, @CodUsuario, SYSUTCDATETIME()
    );

    SET @AsientoId = SCOPE_IDENTITY();

    INSERT INTO dbo.AsientoContableDetalle (
      AsientoId, Renglon, CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber
    )
    SELECT
      @AsientoId, Renglon, CodCuenta, Descripcion, CentroCosto, AuxiliarTipo, AuxiliarCodigo, Documento, Debe, Haber
    FROM @det
    ORDER BY Renglon;

    IF @OrigenModulo IS NOT NULL AND @OrigenDocumento IS NOT NULL
    BEGIN
      INSERT INTO dbo.AsientoOrigenAuxiliar (
        OrigenModulo, TipoDocumento, NumeroDocumento, TablaOrigen, LlaveOrigen, AsientoId, Estado
      )
      VALUES (
        @OrigenModulo,
        @TipoAsiento,
        @OrigenDocumento,
        NULL,
        @OrigenDocumento,
        @AsientoId,
        'APLICADO'
      );
    END

    COMMIT TRAN;
    SET @Resultado = 1;
    SET @Mensaje = N'OK';
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    SET @Resultado = -99;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Asiento_Anular', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Asiento_Anular;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Asiento_Anular
  @AsientoId BIGINT,
  @Motivo NVARCHAR(400),
  @CodUsuario NVARCHAR(40),
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';

  BEGIN TRY
    BEGIN TRAN;

    IF NOT EXISTS (SELECT 1 FROM dbo.AsientoContable WHERE Id = @AsientoId)
    BEGIN
      SET @Resultado = -1;
      SET @Mensaje = N'Asiento no encontrado';
      ROLLBACK TRAN;
      RETURN;
    END

    UPDATE dbo.AsientoContable
    SET Estado = 'ANULADO',
        FechaAnulacion = SYSUTCDATETIME(),
        UsuarioAnulacion = @CodUsuario,
        MotivoAnulacion = @Motivo
    WHERE Id = @AsientoId;

    COMMIT TRAN;
    SET @Resultado = 1;
    SET @Mensaje = N'OK';
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    SET @Resultado = -99;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Ajuste_Crear', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Ajuste_Crear;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Ajuste_Crear
  @Fecha DATE,
  @TipoAjuste NVARCHAR(40),
  @Referencia NVARCHAR(120) = NULL,
  @Motivo NVARCHAR(500),
  @CodUsuario NVARCHAR(40),
  @DetalleXml NVARCHAR(MAX),
  @AsientoId BIGINT OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Numero NVARCHAR(40);

  EXEC dbo.usp_Contabilidad_Asiento_Crear
    @Fecha = @Fecha,
    @TipoAsiento = 'AJU',
    @Referencia = @Referencia,
    @Concepto = @Motivo,
    @Moneda = 'VES',
    @Tasa = 1,
    @OrigenModulo = 'CONTABILIDAD',
    @OrigenDocumento = @Referencia,
    @CodUsuario = @CodUsuario,
    @DetalleXml = @DetalleXml,
    @AsientoId = @AsientoId OUTPUT,
    @NumeroAsiento = @Numero OUTPUT,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

  IF @Resultado = 1
  BEGIN
    INSERT INTO dbo.AjusteContable (AsientoId, TipoAjuste, Motivo, Fecha, Estado, CodUsuario)
    VALUES (@AsientoId, @TipoAjuste, @Motivo, @Fecha, 'APROBADO', @CodUsuario);
  END
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Depreciacion_Generar', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Depreciacion_Generar;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Depreciacion_Generar
  @Periodo NVARCHAR(7), -- YYYY-MM
  @CodUsuario NVARCHAR(40),
  @CentroCosto NVARCHAR(20) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';

  BEGIN TRY
    DECLARE @Fecha DATE = CAST(@Periodo + '-01' AS DATE);
    DECLARE @UltimoDia DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @Fecha));

    DECLARE @tmp TABLE (
      ActivoId BIGINT,
      CuentaGasto NVARCHAR(40),
      CuentaDepAcum NVARCHAR(40),
      CentroCosto NVARCHAR(20),
      Monto DECIMAL(18,2)
    );

    INSERT INTO @tmp (ActivoId, CuentaGasto, CuentaDepAcum, CentroCosto, Monto)
    SELECT
      a.Id,
      a.CuentaGastoDepreciacion,
      a.CuentaDepreciacionAcum,
      COALESCE(@CentroCosto, a.CentroCosto),
      ROUND((a.CostoAdquisicion - a.ValorResidual) / NULLIF(a.VidaUtilMeses,0), 2)
    FROM dbo.ActivoFijoContable a
    WHERE a.Activo = 1
      AND a.VidaUtilMeses > 0
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DepreciacionContable d WHERE d.ActivoId = a.Id AND d.Periodo = @Periodo
      );

    IF NOT EXISTS (SELECT 1 FROM @tmp)
    BEGIN
      SET @Resultado = 1;
      SET @Mensaje = N'Sin activos pendientes para depreciar';
      RETURN;
    END

    DECLARE @DetalleXml NVARCHAR(MAX) = (
      SELECT
        x.CodCuenta AS [@codCuenta],
        x.Descripcion AS [@descripcion],
        x.CentroCosto AS [@centroCosto],
        x.Debe AS [@debe],
        x.Haber AS [@haber]
      FROM (
        SELECT
          t.CuentaGasto AS CodCuenta,
          'Depreciacion del periodo ' + @Periodo AS Descripcion,
          ISNULL(t.CentroCosto, 'ADM') AS CentroCosto,
          t.Monto AS Debe,
          CAST(0 AS DECIMAL(18,2)) AS Haber
        FROM @tmp t
        UNION ALL
        SELECT
          t.CuentaDepAcum AS CodCuenta,
          'Depreciacion acumulada del periodo ' + @Periodo AS Descripcion,
          ISNULL(t.CentroCosto, 'ADM') AS CentroCosto,
          CAST(0 AS DECIMAL(18,2)) AS Debe,
          t.Monto AS Haber
        FROM @tmp t
      ) x
      FOR XML PATH('row'), ROOT('rows'), TYPE
    ).value('.', 'nvarchar(max)');

    DECLARE @AsientoId BIGINT, @Numero NVARCHAR(40), @res INT, @msg NVARCHAR(500);
    DECLARE @ConceptoDep NVARCHAR(400) = 'Depreciacion contable ' + @Periodo;
    EXEC dbo.usp_Contabilidad_Asiento_Crear
      @Fecha = @UltimoDia,
      @TipoAsiento = 'DEP',
      @Referencia = @Periodo,
      @Concepto = @ConceptoDep,
      @Moneda = 'VES',
      @Tasa = 1,
      @OrigenModulo = 'ACTIVOS_FIJOS',
      @OrigenDocumento = @Periodo,
      @CodUsuario = @CodUsuario,
      @DetalleXml = @DetalleXml,
      @AsientoId = @AsientoId OUTPUT,
      @NumeroAsiento = @Numero OUTPUT,
      @Resultado = @res OUTPUT,
      @Mensaje = @msg OUTPUT;

    IF @res <> 1
    BEGIN
      SET @Resultado = @res;
      SET @Mensaje = @msg;
      RETURN;
    END

    INSERT INTO dbo.DepreciacionContable (ActivoId, Periodo, Fecha, Monto, AsientoId, Estado)
    SELECT ActivoId, @Periodo, @UltimoDia, Monto, @AsientoId, 'GENERADO'
    FROM @tmp;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
  END TRY
  BEGIN CATCH
    SET @Resultado = -99;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Mayor_Analitico', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Mayor_Analitico;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Mayor_Analitico
  @CodCuenta NVARCHAR(40),
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    a.Fecha,
    a.NumeroAsiento,
    a.Referencia,
    a.Concepto,
    d.Renglon,
    d.CodCuenta,
    c.DESCRIPCION AS CuentaDescripcion,
    d.CentroCosto,
    d.AuxiliarTipo,
    d.AuxiliarCodigo,
    d.Documento,
    d.Debe,
    d.Haber
  FROM dbo.AsientoContableDetalle d
  INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
  LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
  WHERE d.CodCuenta = @CodCuenta
    AND a.Estado <> 'ANULADO'
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
  ORDER BY a.Fecha, a.Id, d.Renglon;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Libro_Mayor', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Libro_Mayor;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Libro_Mayor
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    d.CodCuenta,
    c.DESCRIPCION AS CuentaDescripcion,
    SUM(d.Debe) AS Debe,
    SUM(d.Haber) AS Haber,
    SUM(d.Debe - d.Haber) AS Saldo
  FROM dbo.AsientoContableDetalle d
  INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
  LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
  WHERE a.Estado <> 'ANULADO'
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
  GROUP BY d.CodCuenta, c.DESCRIPCION
  ORDER BY d.CodCuenta;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Balance_Comprobacion', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Balance_Comprobacion;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Balance_Comprobacion
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    d.CodCuenta,
    c.DESCRIPCION AS CuentaDescripcion,
    SUM(d.Debe) AS TotalDebe,
    SUM(d.Haber) AS TotalHaber,
    CASE
      WHEN SUM(d.Debe - d.Haber) > 0 THEN SUM(d.Debe - d.Haber)
      ELSE 0
    END AS SaldoDeudor,
    CASE
      WHEN SUM(d.Debe - d.Haber) < 0 THEN ABS(SUM(d.Debe - d.Haber))
      ELSE 0
    END AS SaldoAcreedor
  FROM dbo.AsientoContableDetalle d
  INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
  LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
  WHERE a.Estado <> 'ANULADO'
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
  GROUP BY d.CodCuenta, c.DESCRIPCION
  ORDER BY d.CodCuenta;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Estado_Resultados', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Estado_Resultados;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Estado_Resultados
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH base AS (
    SELECT
      d.CodCuenta,
      c.DESCRIPCION AS CuentaDescripcion,
      SUM(d.Debe) AS Debe,
      SUM(d.Haber) AS Haber,
      SUM(d.Haber - d.Debe) AS Neto
    FROM dbo.AsientoContableDetalle d
    INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
    LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
    WHERE a.Estado <> 'ANULADO'
      AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta
      AND (d.CodCuenta LIKE '4%' OR d.CodCuenta LIKE '5%' OR d.CodCuenta LIKE '6%' OR d.CodCuenta LIKE '7%')
    GROUP BY d.CodCuenta, c.DESCRIPCION
  )
  SELECT
    CASE
      WHEN CodCuenta LIKE '4%' THEN 'INGRESOS'
      WHEN CodCuenta LIKE '5%' THEN 'COSTOS'
      WHEN CodCuenta LIKE '6%' THEN 'GASTOS'
      WHEN CodCuenta LIKE '7%' THEN 'CIERRE'
      ELSE 'OTROS'
    END AS Grupo,
    CodCuenta,
    CuentaDescripcion,
    Debe,
    Haber,
    Neto
  FROM base
  ORDER BY CodCuenta;

  SELECT
    SUM(CASE WHEN d.CodCuenta LIKE '4%' THEN (d.Haber - d.Debe) ELSE 0 END) AS TotalIngresos,
    SUM(CASE WHEN d.CodCuenta LIKE '5%' THEN (d.Debe - d.Haber) ELSE 0 END) AS TotalCostos,
    SUM(CASE WHEN d.CodCuenta LIKE '6%' THEN (d.Debe - d.Haber) ELSE 0 END) AS TotalGastos,
    SUM(CASE
      WHEN d.CodCuenta LIKE '4%' THEN (d.Haber - d.Debe)
      WHEN d.CodCuenta LIKE '5%' OR d.CodCuenta LIKE '6%' THEN -(d.Debe - d.Haber)
      ELSE 0
    END) AS ResultadoNeto
  FROM dbo.AsientoContableDetalle d
  INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
  WHERE a.Estado <> 'ANULADO'
    AND a.Fecha BETWEEN @FechaDesde AND @FechaHasta;
END
GO

IF OBJECT_ID('dbo.usp_Contabilidad_Balance_General', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Contabilidad_Balance_General;
GO
CREATE PROCEDURE dbo.usp_Contabilidad_Balance_General
  @FechaCorte DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH base AS (
    SELECT
      d.CodCuenta,
      c.DESCRIPCION AS CuentaDescripcion,
      SUM(d.Debe - d.Haber) AS Saldo
    FROM dbo.AsientoContableDetalle d
    INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
    LEFT JOIN dbo.Cuentas c ON c.COD_CUENTA = d.CodCuenta
    WHERE a.Estado <> 'ANULADO'
      AND a.Fecha <= @FechaCorte
      AND (d.CodCuenta LIKE '1%' OR d.CodCuenta LIKE '2%' OR d.CodCuenta LIKE '3%')
    GROUP BY d.CodCuenta, c.DESCRIPCION
  )
  SELECT
    CASE
      WHEN CodCuenta LIKE '1%' THEN 'ACTIVOS'
      WHEN CodCuenta LIKE '2%' THEN 'PASIVOS'
      WHEN CodCuenta LIKE '3%' THEN 'PATRIMONIO'
      ELSE 'OTROS'
    END AS Grupo,
    CodCuenta,
    CuentaDescripcion,
    Saldo
  FROM base
  ORDER BY CodCuenta;

  SELECT
    SUM(CASE WHEN d.CodCuenta LIKE '1%' THEN (d.Debe - d.Haber) ELSE 0 END) AS TotalActivos,
    SUM(CASE WHEN d.CodCuenta LIKE '2%' THEN (d.Haber - d.Debe) ELSE 0 END) AS TotalPasivos,
    SUM(CASE WHEN d.CodCuenta LIKE '3%' THEN (d.Haber - d.Debe) ELSE 0 END) AS TotalPatrimonio
  FROM dbo.AsientoContableDetalle d
  INNER JOIN dbo.AsientoContable a ON a.Id = d.AsientoId
  WHERE a.Estado <> 'ANULADO'
    AND a.Fecha <= @FechaCorte;
END
GO
