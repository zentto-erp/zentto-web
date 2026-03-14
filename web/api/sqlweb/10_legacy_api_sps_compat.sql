SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Instalacion de SPs legacy requeridos por API actual.
  Reusa scripts existentes en web/api/sql para mantener contrato operativo.
*/

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_documentos_unificado.sql

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_almacen.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_categorias.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_centro_costo.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_clases.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_clientes.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_compras.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_cotizacion.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_cuentas.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_empleados.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_empresa.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_facturas.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_grupos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_inventario.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_lineas.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_marcas.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_pedidos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_proveedores.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_tipos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_unidades.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_usuarios.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_vendedores.sql

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_compra_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_compra_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_cotizacion_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_presupuesto_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_presupuesto_tx.sql
GO

IF OBJECT_ID('dbo.usp_CxC_AplicarCobro', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_CxC_AplicarCobro AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_CxC_AplicarCobro
  @RequestId VARCHAR(100),
  @CodCliente VARCHAR(20),
  @Fecha VARCHAR(10),
  @MontoTotal DECIMAL(18,2),
  @CodUsuario VARCHAR(20),
  @Observaciones VARCHAR(500) = NULL,
  @DocumentosXml NVARCHAR(MAX),
  @FormasPagoXml NVARCHAR(MAX) = NULL,
  @NumRecibo VARCHAR(50) OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje = 'No se aplicaron documentos';
  SET @NumRecibo = ISNULL(NULLIF(@RequestId, ''), 'RCB-' + REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ':', ''));

  DECLARE @x XML = TRY_CAST(@DocumentosXml AS XML);
  IF @x IS NULL
  BEGIN
    SET @Mensaje = 'DocumentosXml invalido';
    RETURN;
  END;

  ;WITH Docs AS (
    SELECT
      T.r.value('@numDoc', 'NVARCHAR(60)') AS NumDoc,
      T.r.value('@montoAplicar', 'DECIMAL(18,2)') AS MontoAplicar
    FROM @x.nodes('/documentos/row') T(r)
  )
  UPDATE c
  SET
    PEND = CASE WHEN ISNULL(c.PEND, ISNULL(c.SALDO, 0)) - d.MontoAplicar < 0 THEN 0 ELSE ISNULL(c.PEND, ISNULL(c.SALDO, 0)) - d.MontoAplicar END,
    SALDO = CASE WHEN ISNULL(c.SALDO, ISNULL(c.PEND, 0)) - d.MontoAplicar < 0 THEN 0 ELSE ISNULL(c.SALDO, ISNULL(c.PEND, 0)) - d.MontoAplicar END,
    PAID = CASE WHEN ISNULL(c.PEND, ISNULL(c.SALDO, 0)) - d.MontoAplicar <= 0 THEN 1 ELSE 0 END,
    COD_USUARIO = @CodUsuario
  FROM dbo.P_Cobrar c
  INNER JOIN Docs d ON d.NumDoc = c.DOCUMENTO
  WHERE (@CodCliente IS NULL OR c.CODIGO = @CodCliente)
    AND ISNULL(d.MontoAplicar, 0) > 0;

  IF @@ROWCOUNT > 0
  BEGIN
    SET @Resultado = 1;
    SET @Mensaje = 'Cobro aplicado';
  END;
END;
GO

IF OBJECT_ID('dbo.usp_CxP_AplicarPago', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.usp_CxP_AplicarPago AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_CxP_AplicarPago
  @RequestId VARCHAR(100),
  @CodProveedor VARCHAR(20),
  @Fecha VARCHAR(10),
  @MontoTotal DECIMAL(18,2),
  @CodUsuario VARCHAR(20),
  @Observaciones VARCHAR(500) = NULL,
  @DocumentosXml NVARCHAR(MAX),
  @FormasPagoXml NVARCHAR(MAX) = NULL,
  @NumPago VARCHAR(50) OUTPUT,
  @Resultado INT OUTPUT,
  @Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje = 'No se aplicaron documentos';
  SET @NumPago = ISNULL(NULLIF(@RequestId, ''), 'PAG-' + REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ':', ''));

  DECLARE @x XML = TRY_CAST(@DocumentosXml AS XML);
  IF @x IS NULL
  BEGIN
    SET @Mensaje = 'DocumentosXml invalido';
    RETURN;
  END;

  ;WITH Docs AS (
    SELECT
      T.r.value('@numDoc', 'NVARCHAR(60)') AS NumDoc,
      T.r.value('@montoAplicar', 'DECIMAL(18,2)') AS MontoAplicar
    FROM @x.nodes('/documentos/row') T(r)
  )
  UPDATE p
  SET
    PEND = CASE WHEN ISNULL(p.PEND, ISNULL(p.SALDO, 0)) - d.MontoAplicar < 0 THEN 0 ELSE ISNULL(p.PEND, ISNULL(p.SALDO, 0)) - d.MontoAplicar END,
    SALDO = CASE WHEN ISNULL(p.SALDO, ISNULL(p.PEND, 0)) - d.MontoAplicar < 0 THEN 0 ELSE ISNULL(p.SALDO, ISNULL(p.PEND, 0)) - d.MontoAplicar END,
    PAID = CASE WHEN ISNULL(p.PEND, ISNULL(p.SALDO, 0)) - d.MontoAplicar <= 0 THEN 1 ELSE 0 END,
    COD_USUARIO = @CodUsuario
  FROM dbo.P_Pagar p
  INNER JOIN Docs d ON d.NumDoc = p.DOCUMENTO
  WHERE (@CodProveedor IS NULL OR p.CODIGO = @CodProveedor)
    AND ISNULL(d.MontoAplicar, 0) > 0;

  IF @@ROWCOUNT > 0
  BEGIN
    SET @Resultado = 1;
    SET @Mensaje = 'Pago aplicado';
  END;
END;
GO

IF OBJECT_ID('dbo.sp_emitir_factura_tx', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.sp_emitir_factura_tx AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_emitir_factura_tx
  @FacturaXml NVARCHAR(MAX),
  @DetalleXml NVARCHAR(MAX),
  @FormasPagoXml NVARCHAR(MAX) = NULL,
  @ActualizarInventario BIT = 1,
  @GenerarCxC BIT = 1,
  @CxcTable NVARCHAR(20) = N'P_Cobrar',
  @FormaPagoTable NVARCHAR(128) = N'Detalle_FormaPagoFacturas',
  @ActualizarSaldosCliente BIT = 1
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @fx XML = TRY_CAST(@FacturaXml AS XML);
  DECLARE @dx XML = TRY_CAST(@DetalleXml AS XML);
  DECLARE @px XML = TRY_CAST(@FormasPagoXml AS XML);
  IF @fx IS NULL OR @dx IS NULL
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, N'' AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  DECLARE @numFact NVARCHAR(60) = @fx.value('(/factura/@NUM_FACT)[1]', 'NVARCHAR(60)');
  DECLARE @codigo NVARCHAR(20) = @fx.value('(/factura/@CODIGO)[1]', 'NVARCHAR(20)');
  DECLARE @fecha DATETIME = ISNULL(TRY_CONVERT(DATETIME, @fx.value('(/factura/@FECHA)[1]', 'NVARCHAR(30)')), GETDATE());
  DECLARE @total FLOAT = ISNULL(TRY_CONVERT(FLOAT, @fx.value('(/factura/@TOTAL)[1]', 'NVARCHAR(50)')), 0);
  DECLARE @usuario NVARCHAR(20) = NULLIF(@fx.value('(/factura/@COD_USUARIO)[1]', 'NVARCHAR(20)'), N'');
  DECLARE @serial NVARCHAR(40) = NULLIF(@fx.value('(/factura/@SERIALTIPO)[1]', 'NVARCHAR(40)'), N'');
  DECLARE @tipoOrden NVARCHAR(6) = ISNULL(NULLIF(@fx.value('(/factura/@TIPO_ORDEN)[1]', 'NVARCHAR(6)'), N''), N'1');

  IF @numFact IS NULL OR LTRIM(RTRIM(@numFact)) = N''
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, N'' AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  IF EXISTS (SELECT 1 FROM dbo.Facturas WHERE NUM_FACT = @numFact)
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @numFact AS numFact, 0 AS detalleRows, 0 AS montoEfectivo, 0 AS montoCheque, 0 AS montoTarjeta, 0 AS saldoPendiente, 0 AS abono;
    RETURN;
  END;

  INSERT INTO dbo.Facturas (NUM_FACT, CODIGO, FECHA, TOTAL, COD_USUARIO, SERIALTIPO, Tipo_Orden, NOMBRE, RIF, PAGO, CANCELADA, ANULADA)
  VALUES (
    @numFact,
    @codigo,
    @fecha,
    @total,
    ISNULL(@usuario, N'API'),
    @serial,
    @tipoOrden,
    NULLIF(@fx.value('(/factura/@NOMBRE)[1]', 'NVARCHAR(255)'), N''),
    NULLIF(@fx.value('(/factura/@RIF)[1]', 'NVARCHAR(20)'), N''),
    NULLIF(@fx.value('(/factura/@PAGO)[1]', 'NVARCHAR(20)'), N''),
    N'N',
    0
  );

  INSERT INTO dbo.Detalle_facturas (NUM_FACT, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, RELACIONADA, COD_ALTERNO, SERIALTIPO)
  SELECT
    @numFact,
    NULLIF(T.r.value('@COD_SERV', 'NVARCHAR(80)'), N''),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@CANTIDAD', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@PRECIO', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@ALICUOTA', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@TOTAL', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(FLOAT, T.r.value('@PRECIO_DESCUENTO', 'NVARCHAR(50)')), 0),
    ISNULL(TRY_CONVERT(INT, T.r.value('@RELACIONADA', 'NVARCHAR(10)')), 0),
    NULLIF(T.r.value('@COD_ALTERNO', 'NVARCHAR(50)'), N''),
    ISNULL(NULLIF(T.r.value('@SERIALTIPO', 'NVARCHAR(40)'), N''), @serial)
  FROM @dx.nodes('/detalles/row') T(r);

  DECLARE @montoEfectivo FLOAT = 0, @montoCheque FLOAT = 0, @montoTarjeta FLOAT = 0, @saldoPendiente FLOAT = 0;
  IF @px IS NOT NULL
  BEGIN
    ;WITH FP AS (
      SELECT
        UPPER(ISNULL(NULLIF(T.r.value('@TIPO', 'NVARCHAR(30)'), N''), N'')) AS TIPO,
        ISNULL(TRY_CONVERT(FLOAT, T.r.value('@MONTO', 'NVARCHAR(50)')), 0) AS MONTO
      FROM @px.nodes('/formasPago/row') T(r)
    )
    SELECT
      @montoEfectivo = ISNULL(SUM(CASE WHEN TIPO = 'EFECTIVO' THEN MONTO ELSE 0 END),0),
      @montoCheque = ISNULL(SUM(CASE WHEN TIPO = 'CHEQUE' THEN MONTO ELSE 0 END),0),
      @montoTarjeta = ISNULL(SUM(CASE WHEN TIPO LIKE 'TARJETA%' OR TIPO LIKE 'TICKET%' THEN MONTO ELSE 0 END),0),
      @saldoPendiente = ISNULL(SUM(CASE WHEN TIPO = 'SALDO PENDIENTE' THEN MONTO ELSE 0 END),0)
    FROM FP;
  END;

  UPDATE dbo.Facturas
  SET MONTO_EFECT = @montoEfectivo,
      MONTO_CHEQUE = @montoCheque,
      MONTO_TARJETA = @montoTarjeta,
      ABONO = ISNULL(TOTAL,0) - @saldoPendiente,
      SALDO = @saldoPendiente,
      CANCELADA = CASE WHEN @saldoPendiente > 0 THEN 'N' ELSE 'S' END,
      FECHA_REPORTE = GETDATE()
  WHERE NUM_FACT = @numFact;

  IF @GenerarCxC = 1 AND @saldoPendiente > 0
  BEGIN
    INSERT INTO dbo.P_Cobrar (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, SERIALTIPO, Tipo_Orden)
    VALUES (@codigo, ISNULL(@usuario, N'API'), @fecha, @numFact, @saldoPendiente, @saldoPendiente, @saldoPendiente, N'FACT', @serial, @tipoOrden);
  END;

  IF @ActualizarInventario = 1
  BEGIN
    ;WITH X AS (
      SELECT COD_SERV, SUM(CANTIDAD) AS TotalCantidad
      FROM dbo.Detalle_facturas
      WHERE NUM_FACT = @numFact
      GROUP BY COD_SERV
    )
    UPDATE i
    SET i.EXISTENCIA = ISNULL(i.EXISTENCIA,0) - x.TotalCantidad
    FROM dbo.Inventario i
    INNER JOIN X x ON x.COD_SERV = i.CODIGO;
  END;

  SELECT
    CAST(1 AS BIT) AS ok,
    @numFact AS numFact,
    (SELECT COUNT(1) FROM dbo.Detalle_facturas WHERE NUM_FACT = @numFact) AS detalleRows,
    @montoEfectivo AS montoEfectivo,
    @montoCheque AS montoCheque,
    @montoTarjeta AS montoTarjeta,
    @saldoPendiente AS saldoPendiente,
    (ISNULL(@total,0) - @saldoPendiente) AS abono;
END;
GO

IF OBJECT_ID('dbo.sp_anular_factura_tx', 'P') IS NULL
  EXEC('CREATE PROCEDURE dbo.sp_anular_factura_tx AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_anular_factura_tx
  @NumFact NVARCHAR(60),
  @CodUsuario NVARCHAR(60) = N'API',
  @Motivo NVARCHAR(500) = N''
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @codCliente NVARCHAR(20);
  SELECT TOP 1 @codCliente = CODIGO FROM dbo.Facturas WHERE NUM_FACT = @NumFact;

  IF @codCliente IS NULL
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @NumFact AS numFact, CAST(NULL AS NVARCHAR(20)) AS codCliente, N'Factura no existe' AS mensaje;
    RETURN;
  END;

  IF EXISTS (SELECT 1 FROM dbo.Facturas WHERE NUM_FACT = @NumFact AND ISNULL(ANULADA,0) = 1)
  BEGIN
    SELECT CAST(0 AS BIT) AS ok, @NumFact AS numFact, @codCliente AS codCliente, N'Factura ya anulada' AS mensaje;
    RETURN;
  END;

  UPDATE dbo.Facturas
  SET ANULADA = 1,
      CANCELADA = N'N',
      OBSERV = ISNULL(OBSERV, N'') + CASE WHEN LEN(ISNULL(OBSERV,N''))>0 THEN N' ' ELSE N'' END + N'[ANULADA] ' + ISNULL(@Motivo,N''),
      COD_USUARIO = @CodUsuario,
      FECHA_REPORTE = GETDATE()
  WHERE NUM_FACT = @NumFact;

  ;WITH X AS (
    SELECT COD_SERV, SUM(CANTIDAD) AS TotalCantidad
    FROM dbo.Detalle_facturas
    WHERE NUM_FACT = @NumFact
    GROUP BY COD_SERV
  )
  UPDATE i
  SET i.EXISTENCIA = ISNULL(i.EXISTENCIA,0) + x.TotalCantidad
  FROM dbo.Inventario i
  INNER JOIN X x ON x.COD_SERV = i.CODIGO;

  UPDATE dbo.P_Cobrar
  SET PEND = 0, SALDO = 0, PAID = 1, OBS = ISNULL(OBS, N'') + N' [ANULADO]'
  WHERE DOCUMENTO = @NumFact AND TIPO = 'FACT';

  SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @codCliente AS codCliente, N'Factura anulada' AS mensaje;
END;
GO

