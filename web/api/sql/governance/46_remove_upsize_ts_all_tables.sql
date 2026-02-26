SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Elimina columna legacy [upsize_ts] en todas las tablas donde exista.
  Ajusta previamente vistas que la referencian para evitar dependencias.
*/

BEGIN TRY
  BEGIN TRAN;

  /* -------------------------------------------------------------------------- */
  /* Vistas dependientes                                                         */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.Categoria', 'V') IS NOT NULL
  BEGIN
    EXEC('
      ALTER VIEW dbo.Categoria
      AS
      SELECT
        COALESCE(LegacyCodigoInt, CASE WHEN ISNUMERIC(Codigo) = 1 THEN CONVERT(INT, Codigo) END) AS Codigo,
        Nombre,
        Co_Usuario
      FROM dbo.Categorias;
    ');
  END;

  IF OBJECT_ID('dbo.Inventarios', 'V') IS NOT NULL
  BEGIN
    EXEC('
      ALTER VIEW dbo.Inventarios
      AS
      SELECT
        CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXISTENCIA, VENTA,
        MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA, PORCENTAJE, PRECIO_VENTA1, PORCENTAJE1, PRECIO_VENTA2, PORCENTAJE2, PRECIO_VENTA3,
        PORCENTAJE3, Alicuota, FECHA, UBICACION, Co_Usuario, Linea, N_PARTE, OFERTA_DESDE, OFERTA_HASTA, oFERTA_PRECIO,
        OFERTA_CANTIDAD, OFERTA_PORCENTAJE, APLICABLE_CONTADO, APLICABLE_CREDITO, Servicio, COSTO_PROMEDIO, COSTO_REFERENCIA, Garantia, Pasa, Producto_Relacion,
        Cantidad_Granel, Barra, Tasa_Dolar, Descuento_Compras, Flete_Compras, UbicaFisica, FechaVence, Eliminado, Aceptada, Fecha_Inventario AS Fecha_Inventarios
      FROM dbo.Inventario;
    ');
  END;

  IF OBJECT_ID('dbo.NOTADEBITO', 'V') IS NOT NULL
  BEGIN
    EXEC('
      ALTER VIEW dbo.NOTADEBITO
      AS
      SELECT
        [NUM_FACT], [CODIGO], [FECHA], [FECHA_veN], [HORA], [NOMBRE], [MONTO_GRA], [IVA], [MONTO_EXE], [TOTAL], [PAGO], [ORDEN], [CHEQUE], [BANCO_CHEQUE], [NOTA],
        [ANULADA], [OBSERV], [CARGO], [PEDIDO], [FECHA_ORDEN], [MONTO_ORDEN], [LOCACION], [INSPECTOR], [REPORTE], [FECHA_REPORTE], [ALICUOTA], [CANCELADA], [Relacionada],
        [Monto_Efect], [Monto_Cheque], [Banco_Tarjeta], [Tarjeta], [Monto_Tarjeta], [COD_USUARIO], [Placas], [Kilometros], [Fecha_llamado], [Vino_30], [Vino_60], [Vino_90],
        [Saldo], [Abono], [Moneda], [Tasacambio], [Recibido], [Entregado], [Cta], [Vendedor], [Peaje], [tasa_dolar], [Num_Control], [RetencionIva], [Tipo_Orden], [Terminos],
        [Despachar], [FOB], [departamento], [RIF], [Nro_Retencion], [Monto_Retencion], [Fecha_Retencion], [Cancelado], [Vuelto], [TIPO_RET], [MONTO_GRABS], [TOTALPAGO],
        [FECHAANULADA], [SERIALTIPO], [Foto]
      FROM dbo.Cotizacion;
    ');
  END;

  IF OBJECT_ID('dbo.vArticulosNoConsidentes', 'V') IS NOT NULL
  BEGIN
    EXEC('
      ALTER VIEW dbo.vArticulosNoConsidentes
      AS
      SELECT
        B.CODIGO, B.Referencia, B.Categoria, B.Marca, B.Tipo, B.Unidad, B.Clase, B.DESCRIPCION, B.EXISTENCIA, B.VENTA, B.MINIMO, B.MAXIMO,
        B.PRECIO_COMPRA, B.PRECIO_VENTA, B.PORCENTAJE, B.PRECIO_VENTA1, B.PORCENTAJE1, B.PRECIO_VENTA2, B.PORCENTAJE2, B.PRECIO_VENTA3, B.PORCENTAJE3,
        B.Alicuota, B.FECHA, B.UBICACION, B.Co_Usuario, B.Linea, B.N_PARTE, B.OFERTA_DESDE, B.OFERTA_HASTA, B.oFERTA_PRECIO, B.OFERTA_CANTIDAD,
        B.OFERTA_PORCENTAJE, B.APLICABLE_CONTADO, B.APLICABLE_CREDITO, B.Servicio, B.COSTO_PROMEDIO, B.COSTO_REFERENCIA, B.Garantia, B.Pasa, B.Producto_Relacion,
        B.Cantidad_Granel, B.Barra, B.Tasa_Dolar, B.Descuento_Compras, B.Flete_Compras, B.UbicaFisica, B.FechaVence, B.Eliminado, B.Aceptada
      FROM dbo.Inventario AS B
      LEFT OUTER JOIN dbo.Detalle_Compras AS A ON B.CODIGO = A.CODIGO
      WHERE A.CODIGO IS NULL;
    ');
  END;

  /* -------------------------------------------------------------------------- */
  /* Drop de columna upsize_ts en todas las tablas                               */
  /* -------------------------------------------------------------------------- */
  DECLARE @sql NVARCHAR(MAX) = N'';

  SELECT @sql = @sql +
    N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' DROP COLUMN [upsize_ts];' + CHAR(10)
  FROM sys.tables t
  INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
  INNER JOIN sys.columns c ON c.object_id = t.object_id
  WHERE c.name = 'upsize_ts'
  ORDER BY s.name, t.name;

  IF LEN(@sql) > 0
    EXEC sp_executesql @sql;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 46_remove_upsize_ts_all_tables.sql: %s', 16, 1, @Err);
END CATCH;
GO
