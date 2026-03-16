-- =============================================
-- Migracion idempotente: tablas legacy -> DocumentosVenta / DocumentosCompra
-- Si una tabla fuente no existe, se omite el bloque.
-- =============================================

SET NOCOUNT ON;

-- ---------- DocumentosVenta desde Facturas ----------
IF OBJECT_ID(N'dbo.Facturas', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL,
      COD_USUARIO, OBSERV, CANCELADA, Monto_Efect, Monto_Cheque, Monto_Tarjeta, Abono, Saldo,
      Tarjeta, Cta, BANCO_CHEQUE, Banco_Tarjeta, FECHA_REPORTE_FISCAL
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), ISNULL(Tipo_Orden, N'1'), N'FACT', CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL,
      COD_USUARIO, OBSERV, ISNULL(CANCELADA, N'N'), Monto_Efect, Monto_Cheque, Monto_Tarjeta, Abono, Saldo,
      Tarjeta, Cta, BANCO_CHEQUE, Banco_Tarjeta, FECHA_REPORTE
    FROM dbo.Facturas f
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = f.NUM_FACT
        AND d.SERIALTIPO = ISNULL(f.SERIALTIPO, N'')
        AND d.Tipo_Orden = ISNULL(f.Tipo_Orden, N'1')
        AND d.TIPO_OPERACION = N'FACT'
    );
    PRINT N'DocumentosVenta: insertados desde Facturas.';
END
ELSE
    PRINT N'Skip Facturas: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_facturas', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), ISNULL(d.Tipo_Orden, N'1'), d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, d.PRECIO_DESCUENTO, ISNULL(d.Relacionada, 0), d.Cod_Alterno
    FROM dbo.Detalle_facturas d
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = ISNULL(d.Tipo_Orden, N'1')
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_facturas.';
END
ELSE
    PRINT N'Skip Detalle_facturas: tabla no existe.';

-- ---------- DocumentosVenta desde Presupuestos ----------
IF OBJECT_ID(N'dbo.Presupuestos', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL,
      COD_USUARIO, OBSERV, CANCELADA, Monto_Efect, Monto_Cheque, Monto_Tarjeta, Abono, Saldo,
      Tarjeta, Cta, BANCO_CHEQUE, Banco_Tarjeta, FECHA_REPORTE_FISCAL
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), ISNULL(tipo_orden, N'1'), N'PRESUP', CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL,
      COD_USUARIO, OBSERV, ISNULL(CANCELADA, N'N'), Monto_Efect, Monto_Cheque, Monto_Tarjeta, Abono, Saldo,
      Tarjeta, Cta, BANCO_CHEQUE, Banco_Tarjeta, FECHA_REPORTE
    FROM dbo.Presupuestos p
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = p.NUM_FACT
        AND d.SERIALTIPO = ISNULL(p.SERIALTIPO, N'')
        AND d.Tipo_Orden = ISNULL(p.tipo_orden, N'1')
        AND d.TIPO_OPERACION = N'PRESUP'
    );
    PRINT N'DocumentosVenta: insertados desde Presupuestos.';
END
ELSE
    PRINT N'Skip Presupuestos: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_Presupuestos', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), N'1', d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, d.PRECIO_DESCUENTO, ISNULL(d.Relacionada, 0), d.Cod_Alterno
    FROM dbo.Detalle_Presupuestos d
    INNER JOIN dbo.DocumentosVenta v
      ON v.NUM_FACT = d.NUM_FACT
     AND v.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
     AND v.TIPO_OPERACION = N'PRESUP'
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = v.Tipo_Orden
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_Presupuestos.';
END
ELSE
    PRINT N'Skip Detalle_Presupuestos: tabla no existe.';

-- ---------- DocumentosVenta desde Pedidos ----------
IF OBJECT_ID(N'dbo.Pedidos', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), N'1', N'PEDIDO', CODIGO, FECHA, FECHA, PAGO, TOTAL, COD_USUARIO, OBSERV
    FROM dbo.Pedidos p
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = p.NUM_FACT
        AND d.SERIALTIPO = ISNULL(p.SERIALTIPO, N'')
        AND d.Tipo_Orden = N'1'
        AND d.TIPO_OPERACION = N'PEDIDO'
    );
    PRINT N'DocumentosVenta: insertados desde Pedidos.';
END
ELSE
    PRINT N'Skip Pedidos: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_Pedidos', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), N'1', d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, NULL, ISNULL(d.Relacionada, 0), d.Cod_Alterno
    FROM dbo.Detalle_Pedidos d
    INNER JOIN dbo.DocumentosVenta v
      ON v.NUM_FACT = d.NUM_FACT
     AND v.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
     AND v.TIPO_OPERACION = N'PEDIDO'
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = v.Tipo_Orden
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_Pedidos.';
END
ELSE
    PRINT N'Skip Detalle_Pedidos: tabla no existe.';

-- ---------- DocumentosVenta desde Cotizacion ----------
IF OBJECT_ID(N'dbo.Cotizacion', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), N'1', N'COTIZ', CODIGO, FECHA, FECHA, PAGO, TOTAL, COD_USUARIO, OBSERV
    FROM dbo.Cotizacion c
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = c.NUM_FACT
        AND d.SERIALTIPO = ISNULL(c.SERIALTIPO, N'')
        AND d.Tipo_Orden = N'1'
        AND d.TIPO_OPERACION = N'COTIZ'
    );
    PRINT N'DocumentosVenta: insertados desde Cotizacion.';
END
ELSE
    PRINT N'Skip Cotizacion: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_Cotizacion', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), N'1', d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, NULL, 0, d.Cod_Alterno
    FROM dbo.Detalle_Cotizacion d
    INNER JOIN dbo.DocumentosVenta v
      ON v.NUM_FACT = d.NUM_FACT
     AND v.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
     AND v.TIPO_OPERACION = N'COTIZ'
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = v.Tipo_Orden
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_Cotizacion.';
END
ELSE
    PRINT N'Skip Detalle_Cotizacion: tabla no existe.';

-- ---------- DocumentosVenta desde NOTACREDITO ----------
IF OBJECT_ID(N'dbo.NOTACREDITO', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), ISNULL(Tipo_Orden, N'1'), N'NOTACRED', CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    FROM dbo.NOTACREDITO n
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = n.NUM_FACT
        AND d.SERIALTIPO = ISNULL(n.SERIALTIPO, N'')
        AND d.Tipo_Orden = ISNULL(n.Tipo_Orden, N'1')
        AND d.TIPO_OPERACION = N'NOTACRED'
    );
    PRINT N'DocumentosVenta: insertados desde NOTACREDITO.';
END
ELSE
    PRINT N'Skip NOTACREDITO: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_notacredito', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), ISNULL(d.Tipo_Orden, N'1'), d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, d.PRECIO_DESCUENTO, ISNULL(d.Relacionada, 0), d.Cod_Alterno
    FROM dbo.Detalle_notacredito d
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = ISNULL(d.Tipo_Orden, N'1')
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_notacredito.';
END
ELSE
    PRINT N'Skip Detalle_notacredito: tabla no existe.';

-- ---------- DocumentosVenta desde NOTADEBITO ----------
IF OBJECT_ID(N'dbo.NOTADEBITO', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVenta (
      NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    )
    SELECT
      NUM_FACT, ISNULL(SERIALTIPO, N''), ISNULL(Tipo_Orden, N'1'), N'NOTADEB', CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, OBSERV
    FROM dbo.NOTADEBITO n
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVenta d
      WHERE d.NUM_FACT = n.NUM_FACT
        AND d.SERIALTIPO = ISNULL(n.SERIALTIPO, N'')
        AND d.Tipo_Orden = ISNULL(n.Tipo_Orden, N'1')
        AND d.TIPO_OPERACION = N'NOTADEB'
    );
    PRINT N'DocumentosVenta: insertados desde NOTADEBITO.';
END
ELSE
    PRINT N'Skip NOTADEBITO: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_notadebito', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosVentaDetalle (
      NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
    )
    SELECT
      d.NUM_FACT, ISNULL(d.SERIALTIPO, N''), ISNULL(d.Tipo_Orden, N'1'), d.COD_SERV, d.CANTIDAD, d.PRECIO,
      ISNULL(d.ALICUOTA, 0), d.TOTAL, d.PRECIO_DESCUENTO, ISNULL(d.Relacionada, 0), d.Cod_Alterno
    FROM dbo.Detalle_notadebito d
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosVentaDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.SERIALTIPO = ISNULL(d.SERIALTIPO, N'')
        AND dv.Tipo_Orden = ISNULL(d.Tipo_Orden, N'1')
    );
    PRINT N'DocumentosVentaDetalle: insertados desde Detalle_notadebito.';
END
ELSE
    PRINT N'Skip Detalle_notadebito: tabla no existe.';

-- ---------- DocumentosCompra desde Compras ----------
IF OBJECT_ID(N'dbo.Compras', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosCompra (
      NUM_FACT, COD_PROVEEDOR, TIPO_OPERACION, FECHA, NOMBRE, RIF, TOTAL, TIPO, CONCEPTO, COD_USUARIO, ANULADA, FECHARECIBO
    )
    SELECT
      NUM_FACT, COD_PROVEEDOR, N'COMPRA', FECHA, NOMBRE, RIF, TOTAL, TIPO, CONCEPTO, COD_USUARIO, ISNULL(ANULADA, 0), FECHARECIBO
    FROM dbo.Compras c
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosCompra d
      WHERE d.NUM_FACT = c.NUM_FACT
        AND d.COD_PROVEEDOR = c.COD_PROVEEDOR
        AND d.TIPO_OPERACION = N'COMPRA'
    );
    PRINT N'DocumentosCompra: insertados desde Compras.';
END
ELSE
    PRINT N'Skip Compras: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_Compras', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.Compras', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosCompraDetalle (
      NUM_FACT, COD_PROVEEDOR, CODIGO, Referencia, DESCRIPCION, FECHA, CANTIDAD, PRECIO_COSTO, Alicuota, Co_Usuario
    )
    SELECT
      d.NUM_FACT, c.COD_PROVEEDOR, d.CODIGO, d.Referencia, d.DESCRIPCION, d.FECHA, d.CANTIDAD, d.PRECIO_COSTO, ISNULL(d.Alicuota, 0), d.Co_Usuario
    FROM dbo.Detalle_Compras d
    INNER JOIN dbo.Compras c ON c.NUM_FACT = d.NUM_FACT
    WHERE EXISTS (
      SELECT 1
      FROM dbo.DocumentosCompra dc
      WHERE dc.NUM_FACT = c.NUM_FACT
        AND dc.COD_PROVEEDOR = c.COD_PROVEEDOR
    )
      AND NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosCompraDetalle dc
      WHERE dc.NUM_FACT = c.NUM_FACT
        AND dc.COD_PROVEEDOR = c.COD_PROVEEDOR
    );
    PRINT N'DocumentosCompraDetalle: insertados desde Detalle_Compras.';
END
ELSE
    PRINT N'Skip Detalle_Compras: tabla no existe.';

-- ---------- DocumentosCompra desde Ordenes ----------
IF OBJECT_ID(N'dbo.Ordenes', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosCompra (
      NUM_FACT, COD_PROVEEDOR, TIPO_OPERACION, FECHA, SERIALTIPO, Tipo_Orden, TOTAL, COD_USUARIO
    )
    SELECT
      NUM_FACT, CODIGO, N'ORDEN', FECHA, ISNULL(SERIALTIPO, N''), N'1', TOTAL, COD_USUARIO
    FROM dbo.Ordenes o
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosCompra d
      WHERE d.NUM_FACT = o.NUM_FACT
        AND d.COD_PROVEEDOR = o.CODIGO
        AND d.TIPO_OPERACION = N'ORDEN'
    );
    PRINT N'DocumentosCompra: insertados desde Ordenes.';
END
ELSE
    PRINT N'Skip Ordenes: tabla no existe.';

IF OBJECT_ID(N'dbo.Detalle_Ordenes', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.Ordenes', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.DocumentosCompraDetalle (
      NUM_FACT, COD_PROVEEDOR, CODIGO, FECHA, CANTIDAD, PRECIO_COSTO, Co_Usuario
    )
    SELECT
      d.NUM_FACT, o.CODIGO, d.COD_SERV, d.FECHA, d.CANTIDAD, d.PRECIO_COSTO, d.Co_Usuario
    FROM dbo.Detalle_Ordenes d
    INNER JOIN dbo.Ordenes o
      ON o.NUM_FACT = d.NUM_FACT
     AND o.SERIALTIPO = d.SERIALTIPO
    INNER JOIN dbo.DocumentosCompra dc
      ON dc.NUM_FACT = o.NUM_FACT
     AND dc.COD_PROVEEDOR = o.CODIGO
     AND dc.TIPO_OPERACION = N'ORDEN'
    WHERE NOT EXISTS (
      SELECT 1
      FROM dbo.DocumentosCompraDetalle dv
      WHERE dv.NUM_FACT = d.NUM_FACT
        AND dv.COD_PROVEEDOR = o.CODIGO
    );
    PRINT N'DocumentosCompraDetalle: insertados desde Detalle_Ordenes.';
END
ELSE
    PRINT N'Skip Detalle_Ordenes: tabla no existe.';

PRINT N'--- Fin migrate_to_documentos_unificado.sql ---';
