SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Fase 1 de integridad referencial basada en uso real de API.
  Estrategia:
  1) Normalizar y backfill minimo de catalogos referenciados (Usuarios/Inventario/Restaurante/Fiscal config)
  2) Crear FKs WITH CHECK en dominios operativos (POS, Restaurante, Contabilidad, Fiscal, Nomina)
*/

BEGIN TRY
  BEGIN TRAN;

  /* -------------------------------------------------------------------------- */
  /* 0) Normalizacion de longitudes para permitir FKs entre columnas legacy      */
  /* -------------------------------------------------------------------------- */
  IF COL_LENGTH('dbo.Usuarios', 'Cod_Usuario') <> 240
    ALTER TABLE dbo.Usuarios ALTER COLUMN Cod_Usuario NVARCHAR(120) NOT NULL;

  IF COL_LENGTH('dbo.AsientoContable', 'CodUsuario') <> 240
    ALTER TABLE dbo.AsientoContable ALTER COLUMN CodUsuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.AsientoContable', 'UsuarioAprobacion') <> 240
    ALTER TABLE dbo.AsientoContable ALTER COLUMN UsuarioAprobacion NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.AsientoContable', 'UsuarioAnulacion') <> 240
    ALTER TABLE dbo.AsientoContable ALTER COLUMN UsuarioAnulacion NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.Compras', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.Compras ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.Cotizacion', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.Cotizacion ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.Facturas', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.Facturas ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.NOTACREDITO', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.NOTACREDITO ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.DocumentosVenta', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.DocumentosVenta ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.pagos', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.pagos ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.Pagosc', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.Pagosc ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.p_cobrar', 'COD_USUARIO') <> 240
    ALTER TABLE dbo.p_cobrar ALTER COLUMN COD_USUARIO NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.P_Pagar', 'Cod_usuario') <> 240
    ALTER TABLE dbo.P_Pagar ALTER COLUMN Cod_usuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.MovInvent', 'Co_Usuario') <> 240
    ALTER TABLE dbo.MovInvent ALTER COLUMN Co_Usuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.MovCuentas', 'Co_Usuario') <> 240
    ALTER TABLE dbo.MovCuentas ALTER COLUMN Co_Usuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.PosVentas', 'CodUsuario') <> 240
    ALTER TABLE dbo.PosVentas ALTER COLUMN CodUsuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.PosVentasEnEspera', 'CodUsuario') <> 240
    ALTER TABLE dbo.PosVentasEnEspera ALTER COLUMN CodUsuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.RestaurantePedidos', 'CodUsuario') <> 240
    ALTER TABLE dbo.RestaurantePedidos ALTER COLUMN CodUsuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.RestauranteCompras', 'CodUsuario') <> 240
    ALTER TABLE dbo.RestauranteCompras ALTER COLUMN CodUsuario NVARCHAR(120) NULL;

  IF COL_LENGTH('dbo.RestauranteCompras', 'ProveedorId') <> 20
    ALTER TABLE dbo.RestauranteCompras ALTER COLUMN ProveedorId NVARCHAR(10) NULL;

  IF COL_LENGTH('dbo.PosVentasDetalle', 'ProductoId') <> 160
    ALTER TABLE dbo.PosVentasDetalle ALTER COLUMN ProductoId NVARCHAR(80) NOT NULL;

  IF COL_LENGTH('dbo.RestauranteComprasDetalle', 'InventarioId') <> 160
    ALTER TABLE dbo.RestauranteComprasDetalle ALTER COLUMN InventarioId NVARCHAR(80) NULL;

  IF COL_LENGTH('dbo.RestauranteRecetas', 'InventarioId') <> 160
    ALTER TABLE dbo.RestauranteRecetas ALTER COLUMN InventarioId NVARCHAR(80) NOT NULL;

  IF COL_LENGTH('dbo.RestauranteProductos', 'ArticuloInventarioId') <> 160
    ALTER TABLE dbo.RestauranteProductos ALTER COLUMN ArticuloInventarioId NVARCHAR(80) NULL;

  IF COL_LENGTH('dbo.RestaurantePedidoItems', 'ProductoId') <> 40
    ALTER TABLE dbo.RestaurantePedidoItems ALTER COLUMN ProductoId NVARCHAR(20) NOT NULL;

  /* Normaliza vacios a NULL en columnas FK nullable */
  UPDATE dbo.AsientoContable SET CodUsuario = NULL WHERE CodUsuario IS NOT NULL AND LTRIM(RTRIM(CodUsuario)) = N'';
  UPDATE dbo.AsientoContable SET UsuarioAprobacion = NULL WHERE UsuarioAprobacion IS NOT NULL AND LTRIM(RTRIM(UsuarioAprobacion)) = N'';
  UPDATE dbo.AsientoContable SET UsuarioAnulacion = NULL WHERE UsuarioAnulacion IS NOT NULL AND LTRIM(RTRIM(UsuarioAnulacion)) = N'';
  UPDATE dbo.Compras SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.Cotizacion SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.Facturas SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.NOTACREDITO SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.DocumentosVenta SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.pagos SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.Pagosc SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.p_cobrar SET COD_USUARIO = NULL WHERE COD_USUARIO IS NOT NULL AND LTRIM(RTRIM(COD_USUARIO)) = N'';
  UPDATE dbo.P_Pagar SET Cod_usuario = NULL WHERE Cod_usuario IS NOT NULL AND LTRIM(RTRIM(Cod_usuario)) = N'';
  UPDATE dbo.MovInvent SET Co_Usuario = NULL WHERE Co_Usuario IS NOT NULL AND LTRIM(RTRIM(Co_Usuario)) = N'';
  UPDATE dbo.MovCuentas SET Co_Usuario = NULL WHERE Co_Usuario IS NOT NULL AND LTRIM(RTRIM(Co_Usuario)) = N'';
  UPDATE dbo.PosVentas SET CodUsuario = NULL WHERE CodUsuario IS NOT NULL AND LTRIM(RTRIM(CodUsuario)) = N'';
  UPDATE dbo.PosVentasEnEspera SET CodUsuario = NULL WHERE CodUsuario IS NOT NULL AND LTRIM(RTRIM(CodUsuario)) = N'';
  UPDATE dbo.RestaurantePedidos SET CodUsuario = NULL WHERE CodUsuario IS NOT NULL AND LTRIM(RTRIM(CodUsuario)) = N'';
  UPDATE dbo.RestauranteCompras SET CodUsuario = NULL WHERE CodUsuario IS NOT NULL AND LTRIM(RTRIM(CodUsuario)) = N'';

  /* -------------------------------------------------------------------------- */
  /* 1) Backfill de Usuarios faltantes referenciados por tablas transaccionales */
  /* -------------------------------------------------------------------------- */
  ;WITH UserRefs AS (
    SELECT NULLIF(LTRIM(RTRIM(CodUsuario)), N'') AS CodUsuario FROM dbo.PosVentas
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(CodUsuario)), N'') FROM dbo.PosVentasEnEspera
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(CodUsuario)), N'') FROM dbo.RestaurantePedidos
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(CodUsuario)), N'') FROM dbo.RestauranteCompras
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.DocumentosVenta
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.Compras
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.Facturas
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.Cotizacion
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.NOTACREDITO
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.p_cobrar
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(Cod_usuario)), N'') FROM dbo.P_Pagar
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.pagos
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(COD_USUARIO)), N'') FROM dbo.Pagosc
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(Co_Usuario)), N'') FROM dbo.MovInvent
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(CodUsuario)), N'') FROM dbo.AsientoContable
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(UsuarioAprobacion)), N'') FROM dbo.AsientoContable
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(UsuarioAnulacion)), N'') FROM dbo.AsientoContable
  )
  INSERT INTO dbo.Usuarios
  (
    Cod_Usuario,
    Nombre,
    Tipo,
    IsAdmin,
    Updates,
    Addnews,
    Deletes,
    Cambiar,
    PrecioMinimo,
    Credito,
    CreatedBy,
    UpdatedBy
  )
  SELECT DISTINCT
    ur.CodUsuario,
    N'[AUTO] Usuario legado',
    N'SYSTEM',
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    N'governance-fk',
    N'governance-fk'
  FROM UserRefs ur
  LEFT JOIN dbo.Usuarios u ON u.Cod_Usuario = ur.CodUsuario
  WHERE ur.CodUsuario IS NOT NULL
    AND u.Cod_Usuario IS NULL;

  /* -------------------------------------------------------------------------- */
  /* 2) Normalizacion de referencias ProductoId en restaurante (id -> codigo)   */
  /* -------------------------------------------------------------------------- */
  UPDATE i
  SET i.ProductoId = rp.Codigo
  FROM dbo.RestaurantePedidoItems i
  INNER JOIN dbo.RestauranteProductos rp
    ON rp.Id = CONVERT(INT, LTRIM(RTRIM(i.ProductoId)))
  WHERE i.ProductoId IS NOT NULL
    AND LTRIM(RTRIM(i.ProductoId)) <> N''
    AND LTRIM(RTRIM(i.ProductoId)) NOT LIKE N'%[^0-9]%'
    AND NOT EXISTS (
      SELECT 1
      FROM dbo.RestauranteProductos rp2
      WHERE rp2.Codigo = i.ProductoId
    );

  /* -------------------------------------------------------------------------- */
  /* 3) Backfill de productos restaurante faltantes por codigo referenciado      */
  /* -------------------------------------------------------------------------- */
  ;WITH MissingRestProducts AS (
    SELECT DISTINCT NULLIF(LTRIM(RTRIM(i.ProductoId)), N'') AS Codigo
    FROM dbo.RestaurantePedidoItems i
    LEFT JOIN dbo.RestauranteProductos rp ON rp.Codigo = i.ProductoId
    WHERE i.ProductoId IS NOT NULL
      AND LTRIM(RTRIM(i.ProductoId)) <> N''
      AND rp.Codigo IS NULL
  )
  INSERT INTO dbo.RestauranteProductos
  (
    Codigo,
    Nombre,
    Descripcion,
    Precio,
    IVA,
    EsCompuesto,
    TiempoPreparacion,
    EsSugerenciaDelDia,
    Disponible,
    Activo,
    CreatedBy,
    UpdatedBy
  )
  SELECT
    mrp.Codigo,
    N'[AUTO] Producto legado ' + mrp.Codigo,
    N'Auto-creado por gobernanza para integridad referencial',
    0,
    16,
    0,
    0,
    0,
    0,
    1,
    N'governance-fk',
    N'governance-fk'
  FROM MissingRestProducts mrp
  WHERE mrp.Codigo IS NOT NULL;

  /* -------------------------------------------------------------------------- */
  /* 4) Backfill de articulos inventario faltantes por referencias de negocio    */
  /* -------------------------------------------------------------------------- */
  ;WITH InvRefs AS (
    SELECT NULLIF(LTRIM(RTRIM(ProductoId)), N'') AS Codigo FROM dbo.PosVentasDetalle
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(InventarioId)), N'') FROM dbo.RestauranteComprasDetalle
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(InventarioId)), N'') FROM dbo.RestauranteRecetas
    UNION ALL SELECT NULLIF(LTRIM(RTRIM(ArticuloInventarioId)), N'') FROM dbo.RestauranteProductos
  ),
  MissingInventario AS (
    SELECT DISTINCT ir.Codigo
    FROM InvRefs ir
    LEFT JOIN dbo.Inventario i ON i.CODIGO = ir.Codigo
    WHERE ir.Codigo IS NOT NULL
      AND i.CODIGO IS NULL
  )
  INSERT INTO dbo.Inventario
  (
    CODIGO,
    DESCRIPCION,
    Tipo,
    Servicio,
    Alicuota,
    CreatedBy,
    UpdatedBy
  )
  SELECT
    mi.Codigo,
    N'[AUTO] Articulo legado ' + mi.Codigo,
    N'AUTO',
    1,
    0,
    N'governance-fk',
    N'governance-fk'
  FROM MissingInventario mi;

  /* -------------------------------------------------------------------------- */
  /* 5) Backfill de FiscalCountryConfig faltante para contextos en FiscalRecords */
  /* -------------------------------------------------------------------------- */
  ;WITH MissingFiscalContext AS (
    SELECT DISTINCT
      r.EmpresaId,
      r.SucursalId,
      r.CountryCode
    FROM dbo.FiscalRecords r
    LEFT JOIN dbo.FiscalCountryConfig c
      ON c.EmpresaId = r.EmpresaId
     AND c.SucursalId = r.SucursalId
     AND c.CountryCode = r.CountryCode
    WHERE c.Id IS NULL
  )
  INSERT INTO dbo.FiscalCountryConfig
  (
    EmpresaId,
    SucursalId,
    CountryCode,
    Currency,
    TaxRegime,
    DefaultTaxCode,
    DefaultTaxRate,
    FiscalPrinterEnabled,
    VerifactuEnabled,
    VerifactuMode,
    PosEnabled,
    RestaurantEnabled,
    IsActive,
    CreatedBy,
    UpdatedBy
  )
  SELECT
    m.EmpresaId,
    m.SucursalId,
    m.CountryCode,
    CASE
      WHEN m.CountryCode = 'ES' THEN 'EUR'
      WHEN m.CountryCode = 'VE' THEN 'VES'
      ELSE 'USD'
    END AS Currency,
    'GENERAL',
    'IVA_GENERAL',
    CASE
      WHEN m.CountryCode = 'ES' THEN CAST(0.21 AS DECIMAL(5,4))
      WHEN m.CountryCode = 'VE' THEN CAST(0.16 AS DECIMAL(5,4))
      ELSE CAST(0 AS DECIMAL(5,4))
    END AS DefaultTaxRate,
    CASE WHEN m.CountryCode = 'VE' THEN 1 ELSE 0 END AS FiscalPrinterEnabled,
    CASE WHEN m.CountryCode = 'ES' THEN 1 ELSE 0 END AS VerifactuEnabled,
    CASE WHEN m.CountryCode = 'ES' THEN 'manual' ELSE NULL END AS VerifactuMode,
    1,
    1,
    1,
    N'governance-fk',
    N'governance-fk'
  FROM MissingFiscalContext m;

  /* -------------------------------------------------------------------------- */
  /* 6) Unicidad de hash fiscal para encadenamiento autoreferenciado             */
  /* -------------------------------------------------------------------------- */
  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.FiscalRecords')
      AND name = 'UQ_FiscalRecords_RecordHash'
  )
  BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_FiscalRecords_RecordHash
      ON dbo.FiscalRecords (RecordHash);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.DocumentosVenta')
      AND name = 'UQ_DocumentosVenta_NumFact'
  )
  BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_DocumentosVenta_NumFact
      ON dbo.DocumentosVenta (NUM_FACT);
  END;

  /* -------------------------------------------------------------------------- */
  /* 7) FKs nuevas por dominio                                                   */
  /* -------------------------------------------------------------------------- */
  IF OBJECT_ID('dbo.FK_AsientoContable_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.AsientoContable WITH CHECK
      ADD CONSTRAINT FK_AsientoContable_CodUsuario_Usuarios
      FOREIGN KEY (CodUsuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_AsientoContable_UsuarioAprobacion_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.AsientoContable WITH CHECK
      ADD CONSTRAINT FK_AsientoContable_UsuarioAprobacion_Usuarios
      FOREIGN KEY (UsuarioAprobacion) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_AsientoContable_UsuarioAnulacion_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.AsientoContable WITH CHECK
      ADD CONSTRAINT FK_AsientoContable_UsuarioAnulacion_Usuarios
      FOREIGN KEY (UsuarioAnulacion) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_Compras_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.Compras WITH CHECK
      ADD CONSTRAINT FK_Compras_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_Cotizacion_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.Cotizacion WITH CHECK
      ADD CONSTRAINT FK_Cotizacion_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_Facturas_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.Facturas WITH CHECK
      ADD CONSTRAINT FK_Facturas_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_NOTACREDITO_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.NOTACREDITO WITH CHECK
      ADD CONSTRAINT FK_NOTACREDITO_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_DocumentosVenta_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.DocumentosVenta WITH CHECK
      ADD CONSTRAINT FK_DocumentosVenta_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_DocumentosVenta_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.DocumentosVenta WITH CHECK
      ADD CONSTRAINT FK_DocumentosVenta_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_DocumentosVentaPago_DocumentosVenta', 'F') IS NULL
    ALTER TABLE dbo.DocumentosVentaPago WITH CHECK
      ADD CONSTRAINT FK_DocumentosVentaPago_DocumentosVenta
      FOREIGN KEY (NUM_DOC) REFERENCES dbo.DocumentosVenta (NUM_FACT);

  IF OBJECT_ID('dbo.FK_Abonos_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.Abonos WITH CHECK
      ADD CONSTRAINT FK_Abonos_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_pagos_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.pagos WITH CHECK
      ADD CONSTRAINT FK_pagos_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_pagosc_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.Pagosc WITH CHECK
      ADD CONSTRAINT FK_pagosc_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_pagos_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.pagos WITH CHECK
      ADD CONSTRAINT FK_pagos_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_pagosc_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.Pagosc WITH CHECK
      ADD CONSTRAINT FK_pagosc_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_p_cobrar_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.p_cobrar WITH CHECK
      ADD CONSTRAINT FK_p_cobrar_CodUsuario_Usuarios
      FOREIGN KEY (COD_USUARIO) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_p_cobrar_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.p_cobrar WITH CHECK
      ADD CONSTRAINT FK_p_cobrar_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_P_Pagar_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.P_Pagar WITH CHECK
      ADD CONSTRAINT FK_P_Pagar_CodUsuario_Usuarios
      FOREIGN KEY (Cod_usuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_P_Pagar_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.P_Pagar WITH CHECK
      ADD CONSTRAINT FK_P_Pagar_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_MovInvent_CoUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.MovInvent WITH CHECK
      ADD CONSTRAINT FK_MovInvent_CoUsuario_Usuarios
      FOREIGN KEY (Co_Usuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_MovInvent_AsientoContable', 'F') IS NULL
    ALTER TABLE dbo.MovInvent WITH CHECK
      ADD CONSTRAINT FK_MovInvent_AsientoContable
      FOREIGN KEY (Asiento_Id) REFERENCES dbo.AsientoContable (Id);

  IF OBJECT_ID('dbo.FK_MovCuentas_CoUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.MovCuentas WITH CHECK
      ADD CONSTRAINT FK_MovCuentas_CoUsuario_Usuarios
      FOREIGN KEY (Co_Usuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_PosVentas_ClienteId_Clientes', 'F') IS NULL
    ALTER TABLE dbo.PosVentas WITH CHECK
      ADD CONSTRAINT FK_PosVentas_ClienteId_Clientes
      FOREIGN KEY (ClienteId) REFERENCES dbo.Clientes (CODIGO);

  IF OBJECT_ID('dbo.FK_PosVentas_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.PosVentas WITH CHECK
      ADD CONSTRAINT FK_PosVentas_CodUsuario_Usuarios
      FOREIGN KEY (CodUsuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_PosVentas_EsperaOrigen', 'F') IS NULL
    ALTER TABLE dbo.PosVentas WITH CHECK
      ADD CONSTRAINT FK_PosVentas_EsperaOrigen
      FOREIGN KEY (EsperaOrigenId) REFERENCES dbo.PosVentasEnEspera (Id);

  IF OBJECT_ID('dbo.FK_PosVentasEnEspera_ClienteId_Clientes', 'F') IS NULL
    ALTER TABLE dbo.PosVentasEnEspera WITH CHECK
      ADD CONSTRAINT FK_PosVentasEnEspera_ClienteId_Clientes
      FOREIGN KEY (ClienteId) REFERENCES dbo.Clientes (CODIGO);

  IF OBJECT_ID('dbo.FK_PosVentasEnEspera_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.PosVentasEnEspera WITH CHECK
      ADD CONSTRAINT FK_PosVentasEnEspera_CodUsuario_Usuarios
      FOREIGN KEY (CodUsuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_PosVentasDetalle_ProductoId_Inventario', 'F') IS NULL
    ALTER TABLE dbo.PosVentasDetalle WITH CHECK
      ADD CONSTRAINT FK_PosVentasDetalle_ProductoId_Inventario
      FOREIGN KEY (ProductoId) REFERENCES dbo.Inventario (CODIGO);

  IF OBJECT_ID('dbo.FK_RestaurantePedidos_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.RestaurantePedidos WITH CHECK
      ADD CONSTRAINT FK_RestaurantePedidos_CodUsuario_Usuarios
      FOREIGN KEY (CodUsuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_RestauranteCompras_CodUsuario_Usuarios', 'F') IS NULL
    ALTER TABLE dbo.RestauranteCompras WITH CHECK
      ADD CONSTRAINT FK_RestauranteCompras_CodUsuario_Usuarios
      FOREIGN KEY (CodUsuario) REFERENCES dbo.Usuarios (Cod_Usuario);

  IF OBJECT_ID('dbo.FK_RestauranteCompras_Proveedor_Proveedores', 'F') IS NULL
    ALTER TABLE dbo.RestauranteCompras WITH CHECK
      ADD CONSTRAINT FK_RestauranteCompras_Proveedor_Proveedores
      FOREIGN KEY (ProveedorId) REFERENCES dbo.Proveedores (CODIGO);

  IF OBJECT_ID('dbo.FK_RestauranteComprasDetalle_Inventario', 'F') IS NULL
    ALTER TABLE dbo.RestauranteComprasDetalle WITH CHECK
      ADD CONSTRAINT FK_RestauranteComprasDetalle_Inventario
      FOREIGN KEY (InventarioId) REFERENCES dbo.Inventario (CODIGO);

  IF OBJECT_ID('dbo.FK_RestaurantePedidoItems_ProductoCodigo', 'F') IS NULL
    ALTER TABLE dbo.RestaurantePedidoItems WITH CHECK
      ADD CONSTRAINT FK_RestaurantePedidoItems_ProductoCodigo
      FOREIGN KEY (ProductoId) REFERENCES dbo.RestauranteProductos (Codigo);

  IF OBJECT_ID('dbo.FK_RestauranteProductos_ArticuloInventario', 'F') IS NULL
    ALTER TABLE dbo.RestauranteProductos WITH CHECK
      ADD CONSTRAINT FK_RestauranteProductos_ArticuloInventario
      FOREIGN KEY (ArticuloInventarioId) REFERENCES dbo.Inventario (CODIGO);

  IF OBJECT_ID('dbo.FK_RestauranteRecetas_Inventario', 'F') IS NULL
    ALTER TABLE dbo.RestauranteRecetas WITH CHECK
      ADD CONSTRAINT FK_RestauranteRecetas_Inventario
      FOREIGN KEY (InventarioId) REFERENCES dbo.Inventario (CODIGO);

  IF OBJECT_ID('dbo.FK_NominaRun_Cedula_Empleado', 'F') IS NULL
    ALTER TABLE dbo.NominaRun WITH CHECK
      ADD CONSTRAINT FK_NominaRun_Cedula_Empleado
      FOREIGN KEY (Cedula) REFERENCES dbo.NominaEmpleado (Cedula);

  IF OBJECT_ID('dbo.FK_NominaVacacion_Cedula_Empleado', 'F') IS NULL
    ALTER TABLE dbo.NominaVacacion WITH CHECK
      ADD CONSTRAINT FK_NominaVacacion_Cedula_Empleado
      FOREIGN KEY (Cedula) REFERENCES dbo.NominaEmpleado (Cedula);

  IF OBJECT_ID('dbo.FK_NominaLiquidacion_Cedula_Empleado', 'F') IS NULL
    ALTER TABLE dbo.NominaLiquidacion WITH CHECK
      ADD CONSTRAINT FK_NominaLiquidacion_Cedula_Empleado
      FOREIGN KEY (Cedula) REFERENCES dbo.NominaEmpleado (Cedula);

  IF OBJECT_ID('dbo.FK_FiscalRecords_ConfigContext', 'F') IS NULL
    ALTER TABLE dbo.FiscalRecords WITH CHECK
      ADD CONSTRAINT FK_FiscalRecords_ConfigContext
      FOREIGN KEY (EmpresaId, SucursalId, CountryCode)
      REFERENCES dbo.FiscalCountryConfig (EmpresaId, SucursalId, CountryCode);

  IF OBJECT_ID('dbo.FK_FiscalRecords_PreviousHash', 'F') IS NULL
    ALTER TABLE dbo.FiscalRecords WITH CHECK
      ADD CONSTRAINT FK_FiscalRecords_PreviousHash
      FOREIGN KEY (PreviousRecordHash) REFERENCES dbo.FiscalRecords (RecordHash);

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 43_api_referential_integrity_phase1.sql: %s', 16, 1, @Err);
END CATCH;
GO
