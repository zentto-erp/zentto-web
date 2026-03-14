SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Compatibilidad amplia de tablas legacy para API.
  Base: definiciones extraidas de CrearDBDataQBox.sql (VB6 legacy).
  Se crean solo si no existen para preservar idempotencia en DatqBoxWeb.
*/

IF OBJECT_ID('dbo.Abonos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Abonos](
	[CODIGO] [nvarchar](15) NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[DOCUMENTO] [nvarchar](25) NULL,
	[PEND] [float] NULL,
	[APLICADO] [float] NULL,
	[SALDO] [float] NULL,
	[CANC] [bit] NULL,
	[PAGO] [nvarchar](10) NULL,
	[CHEQUE] [nvarchar](20) NULL,
	[BANCO] [nvarchar](50) NULL,
	[NOMBRE] [nvarchar](40) NULL,
	[TIPO] [nvarchar](50) NULL,
	[Legal] [bit] NULL,
	[obs] [nvarchar](50) NULL,
	[ANULADO] [bit] NULL,
	[NOTA] [nvarchar](50) NULL,
	[CONTROL] [nvarchar](50) NULL,
	[PorcentajeDescuento] [float] NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Foto] [image] NULL,
 CONSTRAINT [PK_Abonos] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Abonos_Detalle', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Abonos_Detalle](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[TIPO] [nvarchar](50) NULL,
	[BANCO] [nvarchar](50) NULL,
	[CUENTA] [nvarchar](50) NULL,
	[NUMERO] [nvarchar](40) NULL,
	[MONTO] [float] NULL,
	[ANULADO] [bit] NULL,
	[codigo] [nvarchar](15) NULL,
 CONSTRAINT [PK_Abonos_Detalle] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Almacen', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Almacen](
	[Codigo] [nvarchar](2) NOT NULL,
	[Descripcion] [nvarchar](50) NULL,
	[Tipo] [nvarchar](50) NULL,
 CONSTRAINT [aaaaaAlmacen_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Clases', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Clases](
	[Codigo] [int] IDENTITY(1,1) NOT NULL,
	[Descripcion] [nvarchar](25) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaClases_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Clientes', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Clientes](
	[CODIGO] [nvarchar](12) NOT NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[RIF] [nvarchar](20) NULL,
	[NIT] [nvarchar](20) NULL,
	[DIRECCION] [nvarchar](255) NULL,
	[DIRECCION1] [nvarchar](50) NULL,
	[SUCURSAL] [nvarchar](50) NULL,
	[TELEFONO] [nvarchar](60) NULL,
	[SALDO_30] [float] NULL,
	[SALDO_60] [float] NULL,
	[SALDO_90] [float] NULL,
	[SALDO_91] [float] NULL,
	[SALDO_TOT] [float] NULL,
	[ULT_PAGO] [datetime] NULL,
	[ULT_REL] [datetime] NULL,
	[SALDO_RELACIONAR] [float] NULL,
	[LISTA_PRECIO] [int] NULL,
	[RELACION] [nvarchar](1) NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[SALDO_30c] [float] NULL,
	[SALDO_60c] [float] NULL,
	[SALDO_90c] [float] NULL,
	[SALDO_91c] [float] NULL,
	[SALDO_TOTc] [float] NULL,
	[COBRAIVA] [nvarchar](1) NULL,
	[CAJA] [nvarchar](10) NULL,
	[LIMITE] [float] NULL,
	[CONTABLE] [nvarchar](10) NULL,
	[APARTADO] [nvarchar](5) NULL,
	[LISTA] [float] NULL,
	[ZONA] [nvarchar](2) NULL,
	[CONTACTO] [nvarchar](30) NULL,
	[VENDEDOR] [nvarchar](4) NULL,
	[CREDITO] [float] NULL,
	[ESTADO] [nvarchar](20) NULL,
	[CIUDAD] [nvarchar](20) NULL,
	[CPOSTAL] [nvarchar](10) NULL,
	[EMAIL] [nvarchar](50) NULL,
	[PAGINA_WWW] [nvarchar](50) NULL,
	[PPDIAS1] [nvarchar](50) NULL,
	[PPDIAS2] [nvarchar](50) NULL,
	[PPDIAS3] [nvarchar](50) NULL,
	[PPDESCUENTO1] [int] NULL,
	[PPDESCUENTO2] [int] NULL,
	[PPDESCUENTO3] [int] NULL,
	[PPDIAS1R] [nvarchar](50) NULL,
	[PPDIAS2R] [nvarchar](50) NULL,
	[PPDIAS3R] [nvarchar](50) NULL,
	[PPDESCUENTO1R] [int] NULL,
	[PPDESCUENTO2R] [int] NULL,
	[PPDESCUENTO3R] [int] NULL,
	[PP_VERFACTURA1] [bit] NOT NULL,
	[PP_VERFACTURA2] [bit] NOT NULL,
	[PP_VERFACTURA3] [bit] NOT NULL,
	[PP_RELACION1] [bit] NOT NULL,
	[PP_RELACION2] [bit] NOT NULL,
	[PP_RELACION3] [bit] NOT NULL,
	[Condicion] [bit] NOT NULL,
	[Limite_prepago] [float] NULL,
	[Saldo_prepago] [float] NULL,
	[Creditos] [bit] NOT NULL,
	[UltimaFechaCompra] [datetime] NULL,
	[Status] [nvarchar](1) NULL,
	[Cedula] [nvarchar](12) NULL,
	[upsize_ts] [timestamp] NULL,
	[Fecha_prox] [datetime] NULL,
	[Tip_Insc] [nvarchar](20) NULL,
	[fec_insc] [datetime] NULL,
	[Barra] [nvarchar](13) NULL,
	[EMP_TRAB] [nvarchar](50) NULL,
	[fch_nac] [datetime] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaClientes_PK] PRIMARY KEY NONCLUSTERED 
(
	[CODIGO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Compras', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Compras](
	[NUM_FACT] [nvarchar](25) NOT NULL,
	[COD_PROVEEDOR] [nvarchar](10) NOT NULL,
	[CLASE] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](100) NULL,
	[FECHA] [datetime] NULL,
	[CANCELADO] [float] NULL,
	[HORA] [nvarchar](20) NULL,
	[COD_CTA] [nvarchar](20) NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[FECHARECIBO] [datetime] NULL,
	[FECHAVENCE] [datetime] NULL,
	[CONCEPTO] [nvarchar](50) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[ORDEN] [nvarchar](15) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[RECIBIDO] [nvarchar](20) NULL,
	[FECHA_PAGO] [datetime] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[TIPO] [nvarchar](50) NULL,
	[Co_usuario] [nvarchar](10) NULL,
	[PRONTOPAGO] [bit] NULL,
	[Original] [bit] NULL,
	[IMPORTACION] [float] NULL,
	[IVAIMPORT] [float] NULL,
	[BASEIMPORT] [float] NULL,
	[ALICUOTA] [float] NULL,
	[EXENTO] [float] NULL,
	[PRECIO_DOLLAR] [float] NULL,
	[Legal] [bit] NULL,
	[NUM_CONTROL] [nvarchar](25) NULL,
	[Fecha_Comprobante] [datetime] NULL,
	[Nro_Comprobante] [nvarchar](50) NULL,
	[IvaRetenido] [float] NULL,
	[ISRL] [nvarchar](50) NULL,
	[MontoISRL] [float] NULL,
	[CodigoISLR] [nvarchar](50) NULL,
	[TipoCompra] [nvarchar](50) NULL,
	[PorcentajeDescuento] [float] NULL,
	[Debito] [bit] NULL,
	[FactDebito] [nvarchar](50) NULL,
	[Ext] [float] NULL,
	[Flete] [float] NULL,
	[RIF] [nvarchar](15) NULL,
	[SujetoISLR] [float] NULL,
	[RECNUM] [nvarchar](20) NULL,
	[TasaRetencion] [float] NULL,
	[Foto] [image] NULL,
	[Computer] [nvarchar](255) NULL,
	[Almacen] [nvarchar](50) NULL,
 CONSTRAINT [aaaaaCompras_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[COD_PROVEEDOR] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Cotizacion', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Cotizacion](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_Orden] [nvarchar](3) NULL,
	[CODIGO] [nvarchar](10) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_veN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[MONTO_EXE] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ORDEN] [nvarchar](6) NULL,
	[CHEQUE] [float] NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[ANULADA] [bit] NOT NULL,
	[OBSERV] [nvarchar](68) NULL,
	[CARGO] [float] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Cta] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[RetencionIva] [float] NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[departamento] [nvarchar](50) NULL,
	[RIF] [nvarchar](20) NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[TIPO_RET] [nvarchar](50) NULL,
	[MONTO_GRABS] [float] NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[upsize_ts] [timestamp] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [PK_Cotizacion] PRIMARY KEY CLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Cuentas', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Cuentas](
	[COD_CUENTA] [nvarchar](20) NOT NULL,
	[DESCRIPCION] [nvarchar](50) NULL,
	[TIPO] [nvarchar](10) NULL,
	[PRESUPUESTO] [int] NULL,
	[SALDO] [int] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[grupo] [nvarchar](1) NULL,
	[LINEA] [nvarchar](50) NULL,
	[USO] [nvarchar](50) NULL,
	[Nivel] [int] NULL,
	[Porcentaje] [float] NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaCuentas_PK] PRIMARY KEY NONCLUSTERED 
(
	[COD_CUENTA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_Compras', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_Compras](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](25) NULL,
	[CODIGO] [nvarchar](50) NULL,
	[Referencia] [nvarchar](50) NULL,
	[COD_PROVEEDOR] [nvarchar](30) NULL,
	[DESCRIPCION] [nvarchar](100) NULL,
	[Und] [nvarchar](10) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO_COSTO] [float] NULL,
	[PRECIO_VENTA] [float] NULL,
	[PRECIO_VENTA1] [float] NULL,
	[PRECIO_VENTA2] [float] NULL,
	[PRECIO_VENTA3] [float] NULL,
	[PORCENTAJE] [float] NULL,
	[PORCENTAJE1] [float] NULL,
	[PORCENTAJE2] [float] NULL,
	[PORCENTAJE3] [float] NULL,
	[ANULADA] [bit] NULL,
	[Co_Usuario] [nvarchar](40) NULL,
	[PRECIO_COSTOREAL] [float] NULL,
	[Alicuota] [float] NULL,
	[Flete] [float] NULL,
	[Descuento] [float] NULL,
	[Tasa_Dolar] [float] NULL,
	[CostoInventario] [float] NULL,
	[Fecha_Recibida] [datetime] NULL,
 CONSTRAINT [PK_Detalle_Compras] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_Cotizacion', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_Cotizacion](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[HORA] [nvarchar](20) NULL,
	[NOTA] [int] NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[RENGLON] [float] NULL,
	[SERVICIO] [float] NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[CantidadLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Comision] [float] NULL,
	[TasaCambio] [float] NULL,
	[Fechas1] [varchar](20) NULL,
 CONSTRAINT [PK_Detalle_Cotizacion] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_facturas', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_facturas](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[Tipo_Orden] [nvarchar](3) NULL CONSTRAINT DF_DetFacturas_TipoOrden DEFAULT (N'1'),
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[HORA] [nvarchar](20) NULL,
	[NOTA] [int] NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[RENGLON] [float] NULL,
	[SERVICIO] [float] NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[FECHAANULADA] [datetime] NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Cantidadlote] [float] NULL,
	[Comision] [float] NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [PK_Detalle_facturas] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_notacredito', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_notacredito](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[HORA] [nvarchar](20) NULL,
	[NOTA] [int] NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[RENGLON] [float] NULL,
	[SERVICIO] [float] NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Cantidadlote] [float] NULL,
	[Comision] [float] NULL,
	[Tasacambio] [float] NULL,
 CONSTRAINT [PK_Detalle_notacredito] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_notadebito', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_notadebito](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[HORA] [nvarchar](20) NULL,
	[NOTA] [int] NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[RENGLON] [float] NULL,
	[SERVICIO] [float] NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Cantidadlote] [float] NULL,
	[Comision] [float] NULL,
	[Tasacambio] [float] NULL,
 CONSTRAINT [PK_Detalle_notadebito] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_Ordenes', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_Ordenes](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](250) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[NOTA] [int] NULL,
	[Alicuota] [float] NULL,
	[Unidad] [nvarchar](50) NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[hora] [nvarchar](20) NULL,
	[Renglon] [float] NULL,
	[Servicio] [bit] NOT NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[CantidadLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Comision] [float] NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [PK_Detalle_Ordenes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_Pedidos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_Pedidos](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[HORA] [nvarchar](20) NULL,
	[NOTA] [int] NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[RENGLON] [float] NULL,
	[SERVICIO] [float] NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[CantidadLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Comision] [float] NULL,
	[Tipo_orden] [nvarchar](20) NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [PK_Detalle_Pedidos] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_Presupuestos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_Presupuestos](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NUM_FACT] [nvarchar](20) NULL,
	[SERIALTIPO] [nvarchar](20) NULL,
	[COD_SERV] [nvarchar](15) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[CANTIDAD] [float] NULL,
	[PRECIO] [float] NULL,
	[TOTAL] [float] NULL,
	[ANULADA] [bit] NOT NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[NOTA] [int] NULL,
	[marca] [nvarchar](50) NULL,
	[unidad] [nvarchar](50) NULL,
	[Alicuota] [float] NULL,
	[PRECIO_DESCUENTO] [float] NULL,
	[DESCUENTO] [float] NULL,
	[Relacionada] [bit] NOT NULL,
	[hora] [nvarchar](20) NULL,
	[Renglon] [float] NULL,
	[Servicio] [bit] NOT NULL,
	[Vendedor] [nvarchar](50) NULL,
	[Autoriza] [nvarchar](20) NULL,
	[Cod_Alterno] [nvarchar](15) NULL,
	[PlacaSerial] [nvarchar](15) NULL,
	[Rif_Propietario] [nvarchar](20) NULL,
	[Nombre_Propietario] [nvarchar](255) NULL,
	[Marca_Vehiculo] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Fabricacion] [nchar](10) NULL,
	[Almacen] [nvarchar](20) NULL,
	[Lote] [nvarchar](20) NULL,
	[CostoLote] [float] NULL,
	[fechalote] [datetime] NULL,
	[facturalote] [nvarchar](20) NULL,
	[Cantidadlote] [float] NULL,
	[Comision] [float] NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [PK_Detalle_Presupuestos] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Empleados', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Empleados](
	[CEDULA] [nvarchar](12) NOT NULL,
	[GRUPO] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](50) NULL,
	[DIRECCION] [nvarchar](255) NULL,
	[TELEFONO] [nvarchar](30) NULL,
	[NACIMIENTO] [datetime] NULL,
	[CARGO] [nvarchar](30) NULL,
	[NOMINA] [nvarchar](15) NULL,
	[SUELDO] [float] NULL,
	[INGRESO] [datetime] NULL,
	[RETIRO] [datetime] NULL,
	[STATUS] [nvarchar](1) NULL,
	[COMISION] [float] NULL,
	[UTILIDAD] [float] NULL,
	[CO_Usuario] [nvarchar](10) NULL,
	[Saldo_prestamo] [float] NULL,
	[nro_cta] [nvarchar](50) NULL,
	[SEXO] [nvarchar](1) NULL,
	[NACIONALIDAD] [nvarchar](1) NULL,
	[Autoriza] [bit] NOT NULL,
	[STATUS_LPH] [nvarchar](1) NULL,
	[UNIDAD] [nvarchar](8) NULL,
	[LPH] [bit] NOT NULL,
	[Fecha] [datetime] NULL,
	[Numero] [int] NULL,
	[Apodo] [nvarchar](50) NULL,
	[expresado] [nvarchar](50) NULL,
	[distrito] [nvarchar](50) NULL,
	[acumulado] [float] NULL,
	[ISLR] [float] NULL,
	[CODIGOGARGO] [nvarchar](10) NULL,
	[SubGrupo] [nvarchar](50) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaEmpleados_PK] PRIMARY KEY NONCLUSTERED 
(
	[CEDULA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Empresa', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Empresa](
	[Empresa] [nvarchar](50) NOT NULL,
	[Logo] [image] NULL,
	[RIF] [nvarchar](50) NULL,
	[Nit] [nvarchar](50) NULL,
	[Telefono] [nvarchar](50) NULL,
	[Direccion] [nvarchar](255) NULL,
	[Rifs] [nvarchar](50) NULL,
 CONSTRAINT [aaaaaEmpresa_PK] PRIMARY KEY NONCLUSTERED 
(
	[Empresa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Facturas', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Facturas](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_Orden] [nvarchar](3) NOT NULL,
	[CODIGO] [nvarchar](12) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_veN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[MONTO_EXE] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](10) NULL,
	[ORDEN] [nvarchar](30) NULL,
	[CHEQUE] [float] NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[ANULADA] [bit] NOT NULL,
	[OBSERV] [nvarchar](68) NULL,
	[CARGO] [float] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Cta] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[RetencionIva] [float] NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[departamento] [nvarchar](50) NULL,
	[RIF] [nvarchar](20) NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[TIPO_RET] [nvarchar](50) NULL,
	[MONTO_GRABS] [float] NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[upsize_ts] [timestamp] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaFactura_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC,
	[Tipo_Orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Grupos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Grupos](
	[Codigo] [int] IDENTITY(1,1) NOT NULL,
	[Descripcion] [nvarchar](50) NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[Porcentaje] [float] NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaGrupos_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Inventario', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Inventario](
	[CODIGO] [nvarchar](15) NOT NULL,
	[PLU] [int] NULL,
	[Referencia] [nvarchar](30) NULL,
	[Categoria] [nvarchar](50) NULL,
	[Marca] [nvarchar](50) NULL,
	[Tipo] [nvarchar](50) NULL,
	[Unidad] [nvarchar](30) NULL,
	[Clase] [nvarchar](25) NULL,
	[DESCRIPCION] [nvarchar](255) NULL,
	[EXISTENCIA] [float] NULL,
	[VENTA] [float] NULL,
	[MINIMO] [float] NULL,
	[MAXIMO] [float] NULL,
	[PRECIO_COMPRA] [float] NULL,
	[PRECIO_VENTA] [float] NULL,
	[PORCENTAJE] [float] NULL,
	[PRECIO_VENTA1] [float] NULL,
	[PORCENTAJE1] [float] NULL,
	[PRECIO_VENTA2] [float] NULL,
	[PORCENTAJE2] [float] NULL,
	[PRECIO_VENTA3] [float] NULL,
	[PORCENTAJE3] [float] NULL,
	[Alicuota] [float] NULL,
	[FECHA] [datetime] NULL,
	[UBICACION] [nvarchar](40) NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[Linea] [nvarchar](30) NULL,
	[N_PARTE] [nvarchar](18) NULL,
	[OFERTA_DESDE] [datetime] NULL,
	[OFERTA_HASTA] [datetime] NULL,
	[oFERTA_PRECIO] [float] NULL,
	[OFERTA_CANTIDAD] [float] NULL,
	[OFERTA_PORCENTAJE] [float] NULL,
	[APLICABLE_CONTADO] [bit] NULL,
	[APLICABLE_CREDITO] [bit] NULL,
	[Servicio] [bit] NULL,
	[COSTO_PROMEDIO] [float] NULL,
	[COSTO_REFERENCIA] [float] NULL,
	[Garantia] [nvarchar](50) NULL,
	[Pasa] [bit] NULL,
	[Producto_Relacion] [nvarchar](50) NULL,
	[Cantidad_Granel] [float] NULL,
	[Barra] [nvarchar](50) NULL,
	[Tasa_Dolar] [float] NULL,
	[Descuento_Compras] [float] NULL,
	[Flete_Compras] [float] NULL,
	[upsize_ts] [timestamp] NULL,
	[UbicaFisica] [nvarchar](50) NULL,
	[FechaVence] [datetime] NULL,
	[Eliminado] [bit] NULL,
	[Aceptada] [bit] NULL,
	[Fecha_Inventario] [datetime] NULL,
	[Foto] [image] NULL,
	[Destacado] [bit] NULL,
	[CuentaTiempo] [bit] NULL,
	[ComisionDirecta] [float] NULL,
	[ComisionDirecta1] [float] NULL,
	[ComisionDirecta2] [float] NULL,
	[ComisionDirecta3] [float] NULL,
 CONSTRAINT [PK_Inventario] PRIMARY KEY CLUSTERED 
(
	[CODIGO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Marcas', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Marcas](
	[Codigo] [int] IDENTITY(1,1) NOT NULL,
	[Descripcion] [nvarchar](50) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaMarcas_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.MovInvent', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[MovInvent](
	[Product] [nvarchar](15) NULL,
	[Fecha] [datetime] NULL,
	[Tipo] [nvarchar](10) NULL,
	[Motivo] [nvarchar](255) NULL,
	[Cantidad_Actual] [int] NULL,
	[Cantidad] [int] NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[Codigo] [nvarchar](15) NULL,
	[Precio_Compra] [float] NULL,
	[Precio_venta] [float] NULL,
	[cantidad_nueva] [float] NULL,
	[autoriza] [nvarchar](50) NULL,
	[Documento] [nvarchar](20) NULL,
	[Anulada] [bit] NULL,
	[Alicuota] [float] NULL,
	[id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_MovInvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.NOTACREDITO', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[NOTACREDITO](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_Orden] [nvarchar](3) NOT NULL,
	[CODIGO] [nvarchar](10) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_veN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[MONTO_EXE] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ORDEN] [nvarchar](6) NULL,
	[CHEQUE] [float] NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[ANULADA] [bit] NOT NULL,
	[OBSERV] [nvarchar](68) NULL,
	[CARGO] [float] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Cta] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[RetencionIva] [float] NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[departamento] [nvarchar](50) NULL,
	[RIF] [nvarchar](20) NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[TIPO_RET] [nvarchar](50) NULL,
	[MONTO_GRABS] [float] NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[upsize_ts] [timestamp] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaNOTACREDITO_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC,
	[Tipo_Orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.NOTADEBITO', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[NOTADEBITO](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_Orden] [nvarchar](3) NULL,
	[CODIGO] [nvarchar](10) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_veN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[MONTO_EXE] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ORDEN] [nvarchar](6) NULL,
	[CHEQUE] [float] NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[ANULADA] [bit] NOT NULL,
	[OBSERV] [nvarchar](68) NULL,
	[CARGO] [float] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Cta] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[RetencionIva] [float] NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[departamento] [nvarchar](50) NULL,
	[RIF] [nvarchar](20) NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[TIPO_RET] [nvarchar](50) NULL,
	[MONTO_GRABS] [float] NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[upsize_ts] [timestamp] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaNOTADEBITO_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Ordenes', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Ordenes](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_Orden] [nvarchar](3) NULL,
	[CODIGO] [nvarchar](10) NULL,
	[NOMBRE] [nvarchar](250) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_VEN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[COD_USUARIO] [nvarchar](50) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ANULADA] [bit] NOT NULL,
	[CARGO] [float] NULL,
	[OBSERV] [ntext] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[ORDEN] [nvarchar](30) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[CTA] [nvarchar](50) NULL,
	[monto_exe] [float] NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[departamento] [nvarchar](50) NULL,
	[condicion] [nvarchar](50) NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[Cheque] [float] NULL,
	[Banco_Cheque] [nvarchar](30) NULL,
	[Monto_efect] [float] NULL,
	[Banco_tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [float] NULL,
	[Monto_Tarjeta] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[RIF] [nvarchar](20) NULL,
	[nota] [nvarchar](50) NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[MONTO_GRABS] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[TOTALPAGO] [float] NULL,
	[vino_30] [bit] NOT NULL,
	[vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[upsize_ts] [timestamp] NULL,
	[fechaanulada] [datetime] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaOrdenes_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.P_Pagar', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[P_Pagar](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CODIGO] [nvarchar](15) NULL,
	[FECHA] [datetime] NULL,
	[DOCUMENTO] [nvarchar](25) NULL,
	[TIPO] [nvarchar](10) NULL,
	[DEBE] [float] NULL,
	[HABER] [float] NULL,
	[SALDO] [float] NULL,
	[PEND] [float] NULL,
	[PAID] [bit] NOT NULL,
	[PAGO] [nvarchar](10) NULL,
	[OBS] [ntext] NULL,
	[Cod_usuario] [nvarchar](10) NULL,
	[ISRL] [nvarchar](50) NULL,
	[PorcentajeDescuento] [float] NULL,
	[NUMREC] [nvarchar](20) NULL,
 CONSTRAINT [PK_P_Pagar] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.pagos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[pagos](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CODIGO] [nvarchar](15) NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[DOCUMENTO] [nvarchar](20) NULL,
	[PEND] [float] NULL,
	[APLICADO] [float] NULL,
	[SALDO] [float] NULL,
	[CANC] [bit] NULL,
	[PAGO] [nvarchar](20) NULL,
	[CHEQUE] [float] NULL,
	[BANCO] [nvarchar](50) NULL,
	[NOMBRE] [nvarchar](40) NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Tipo] [nvarchar](50) NULL,
	[Legal] [bit] NULL,
	[obs] [nvarchar](50) NULL,
	[ANULADO] [bit] NULL,
	[NOTA] [nchar](20) NULL,
	[CONTROL] [nchar](20) NULL,
	[PORCENTAJEDESCUENTO] [float] NULL,
	[foto] [image] NULL,
 CONSTRAINT [PK_pagos] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Pagos_Detalle', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Pagos_Detalle](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[TIPO] [nvarchar](50) NULL,
	[CUENTA] [nvarchar](50) NULL,
	[NUMERO] [nvarchar](40) NULL,
	[MONTO] [float] NULL,
	[ANULADO] [bit] NULL,
	[BANCO] [nvarchar](40) NULL,
	[CODIGO] [nvarchar](15) NULL,
 CONSTRAINT [PK_Pagos_Detalle] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Pagosc', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Pagosc](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CODIGO] [nvarchar](15) NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[DOCUMENTO] [nvarchar](20) NULL,
	[PEND] [float] NULL,
	[APLICADO] [float] NULL,
	[SALDO] [float] NULL,
	[CANC] [bit] NULL,
	[PAGO] [nvarchar](20) NULL,
	[CHEQUE] [float] NULL,
	[BANCO] [nvarchar](50) NULL,
	[NOMBRE] [nvarchar](40) NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Tipo] [nvarchar](50) NULL,
	[Legal] [bit] NULL,
	[obs] [nvarchar](50) NULL,
	[ANULADO] [bit] NULL,
	[nota] [nvarchar](20) NULL,
	[CONTROL] [nchar](20) NULL,
	[PORCENTAJEDESCUENTO] [float] NULL,
	[foto] [image] NULL,
 CONSTRAINT [PK_Pagosc] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.PagosC_Detalle', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[PagosC_Detalle](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RECNUM] [float] NULL,
	[FECHA] [datetime] NULL,
	[TIPO] [nvarchar](50) NULL,
	[CUENTA] [nvarchar](50) NULL,
	[NUMERO] [nvarchar](40) NULL,
	[MONTO] [float] NULL,
	[ANULADO] [bit] NULL,
	[BANCO] [nvarchar](40) NULL,
	[Codigo] [nchar](10) NULL,
 CONSTRAINT [PK_PagosC_Detalle] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Pedidos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Pedidos](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[CODIGO] [nvarchar](10) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_veN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[MONTO_EXE] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ORDEN] [nvarchar](6) NULL,
	[CHEQUE] [float] NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[ANULADA] [bit] NOT NULL,
	[OBSERV] [nvarchar](68) NULL,
	[CARGO] [float] NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Cta] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[Num_Control] [nvarchar](50) NULL,
	[RetencionIva] [float] NULL,
	[Tipo_Orden] [nvarchar](3) NULL,
	[Terminos] [nvarchar](255) NULL,
	[Despachar] [nvarchar](255) NULL,
	[FOB] [nvarchar](50) NULL,
	[departamento] [nvarchar](50) NULL,
	[RIF] [nvarchar](20) NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[TIPO_RET] [nvarchar](50) NULL,
	[MONTO_GRABS] [float] NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaPedidos_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Presupuestos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Presupuestos](
	[NUM_FACT] [nvarchar](20) NOT NULL,
	[SERIALTIPO] [nvarchar](20) NOT NULL,
	[Tipo_orden] [nvarchar](3) NULL,
	[CODIGO] [nvarchar](10) NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[FECHA] [datetime] NULL,
	[FECHA_VEN] [datetime] NULL,
	[HORA] [nvarchar](20) NULL,
	[COD_USUARIO] [nvarchar](50) NULL,
	[MONTO_GRA] [float] NULL,
	[IVA] [float] NULL,
	[TOTAL] [float] NULL,
	[PAGO] [nvarchar](8) NULL,
	[ANULADA] [bit] NOT NULL,
	[CARGO] [float] NULL,
	[OBSERV] [nvarchar](255) NULL,
	[PEDIDO] [nvarchar](20) NULL,
	[ORDEN] [nvarchar](30) NULL,
	[FECHA_ORDEN] [datetime] NULL,
	[MONTO_ORDEN] [float] NULL,
	[LOCACION] [nvarchar](30) NULL,
	[INSPECTOR] [nvarchar](20) NULL,
	[REPORTE] [nvarchar](30) NULL,
	[FECHA_REPORTE] [datetime] NULL,
	[ALICUOTA] [float] NULL,
	[CANCELADA] [nvarchar](1) NULL,
	[Relacionada] [bit] NOT NULL,
	[Monto_Efect] [float] NULL,
	[Monto_Cheque] [float] NULL,
	[Banco_Tarjeta] [nvarchar](30) NULL,
	[Tarjeta] [nvarchar](20) NULL,
	[Monto_Tarjeta] [float] NULL,
	[Placas] [nvarchar](15) NULL,
	[Kilometros] [int] NULL,
	[Fecha_llamado] [datetime] NULL,
	[Vino_30] [bit] NOT NULL,
	[Vino_60] [bit] NOT NULL,
	[Vino_90] [bit] NOT NULL,
	[Saldo] [float] NULL,
	[Abono] [float] NULL,
	[Cheque] [int] NULL,
	[Moneda] [nvarchar](20) NULL,
	[Tasacambio] [float] NULL,
	[Recibido] [nvarchar](50) NULL,
	[Entregado] [nvarchar](50) NULL,
	[Vendedor] [nvarchar](20) NULL,
	[monto_exe] [float] NULL,
	[Cta] [nvarchar](50) NULL,
	[BANCO_CHEQUE] [nvarchar](30) NULL,
	[NOTA] [nvarchar](50) NULL,
	[Peaje] [float] NULL,
	[tasa_dolar] [float] NULL,
	[RIF] [nvarchar](20) NULL,
	[Cancelado] [float] NULL,
	[Vuelto] [float] NULL,
	[Nro_Retencion] [nvarchar](50) NULL,
	[Monto_Retencion] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[MONTO_GRABS] [float] NULL,
	[DEPARTAMENTO] [nvarchar](50) NULL,
	[Fob] [nvarchar](50) NULL,
	[Despachar] [nvarchar](50) NULL,
	[Terminos] [nvarchar](50) NULL,
	[Num_Control] [nvarchar](50) NULL,
	[TOTALPAGO] [float] NULL,
	[FECHAANULADA] [datetime] NULL,
	[upsize_ts] [timestamp] NULL,
	[Foto] [image] NULL,
 CONSTRAINT [aaaaaPresupuestos_PK] PRIMARY KEY NONCLUSTERED 
(
	[NUM_FACT] ASC,
	[SERIALTIPO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Proveedores', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Proveedores](
	[CODIGO] [nvarchar](10) NOT NULL,
	[NOMBRE] [nvarchar](255) NULL,
	[RIF] [nvarchar](20) NULL,
	[NIT] [nvarchar](20) NULL,
	[DIRECCION] [nvarchar](255) NULL,
	[DIRECCION1] [nvarchar](255) NULL,
	[SUCURSAL] [nvarchar](50) NULL,
	[TELEFONO] [nvarchar](60) NULL,
	[FAX] [nvarchar](10) NULL,
	[SALDO_30] [float] NULL,
	[SALDO_60] [float] NULL,
	[SALDO_90] [float] NULL,
	[SALDO_91] [float] NULL,
	[SALDO_TOT] [float] NULL,
	[ULT_PAGO] [datetime] NULL,
	[NOTAS] [nvarchar](50) NULL,
	[LISTA_PRECIO] [int] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[relacion] [nvarchar](1) NULL,
	[cobraiva] [nvarchar](1) NULL,
	[VENDEDOR] [nvarchar](2) NULL,
	[CAJA] [nvarchar](10) NULL,
	[LIMITE] [float] NULL,
	[IVA] [float] NULL,
	[CREDITO] [float] NULL,
	[CONTABLE] [nvarchar](10) NULL,
	[ESTADO] [nvarchar](60) NULL,
	[APARTADO] [nvarchar](10) NULL,
	[CONTACTO] [nvarchar](30) NULL,
	[LISTA] [float] NULL,
	[ZONA] [nvarchar](2) NULL,
	[CIUDAD] [nvarchar](30) NULL,
	[CPOSTAL] [nvarchar](10) NULL,
	[EMAIL] [nvarchar](50) NULL,
	[PAGINA_WWW] [nvarchar](50) NULL,
	[ULT_REL] [datetime] NULL,
	[SALDO_RELACIONAR] [float] NULL,
	[SALDO_30c] [float] NULL,
	[SALDO_60c] [float] NULL,
	[SALDO_90c] [float] NULL,
	[SALDO_91c] [float] NULL,
	[SALDO_TOTc] [float] NULL,
	[PPDIAS1] [nvarchar](50) NULL,
	[PPDIAS2] [nvarchar](50) NULL,
	[PPDIAS3] [nvarchar](50) NULL,
	[PPDESCUENTO1] [int] NULL,
	[PPDESCUENTO2] [int] NULL,
	[PPDESCUENTO3] [int] NULL,
	[PPDIAS1R] [nvarchar](50) NULL,
	[PPDIAS2R] [nvarchar](50) NULL,
	[PPDIAS3R] [nvarchar](50) NULL,
	[PPDESCUENTO1R] [int] NULL,
	[PPDESCUENTO2R] [int] NULL,
	[PPDESCUENTO3R] [int] NULL,
	[PP_VERFACTURA1] [bit] NOT NULL,
	[PP_VERFACTURA2] [bit] NOT NULL,
	[PP_VERFACTURA3] [bit] NOT NULL,
	[PP_RELACION1] [bit] NOT NULL,
	[PP_RELACION2] [bit] NOT NULL,
	[PP_RELACION3] [bit] NOT NULL,
	[condicion] [nvarchar](50) NULL,
	[Saldo_prepago] [float] NULL,
	[upsize_ts] [timestamp] NULL,
	[Status] [nvarchar](3) NULL,
 CONSTRAINT [aaaaaProveedores_PK] PRIMARY KEY NONCLUSTERED 
(
	[CODIGO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Tipos', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Tipos](
	[Codigo] [int] IDENTITY(1,1) NOT NULL,
	[Categoria] [nvarchar](50) NULL,
	[Nombre] [nvarchar](50) NULL,
	[Co_Usuario] [nvarchar](10) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [PK_Tipos] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Unidades', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Unidades](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Unidad] [nvarchar](50) NOT NULL,
	[Cantidad] [float] NULL,
 CONSTRAINT [PK_Unidades] PRIMARY KEY CLUSTERED 
(
	[Unidad] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Usuarios', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Usuarios](
	[Cod_Usuario] [nvarchar](10) NOT NULL,
	[Password] [nvarchar](10) NULL,
	[Nombre] [nvarchar](50) NULL,
	[Tipo] [nvarchar](10) NULL,
	[Updates] [bit] NULL,
	[Addnews] [bit] NULL,
	[Deletes] [bit] NULL,
	[Creador] [bit] NULL,
	[Cambiar] [bit] NULL,
	[PrecioMinimo] [bit] NULL,
	[upsize_ts] [timestamp] NULL,
	[Credito] [bit] NULL,
 CONSTRAINT [aaaaaUsuarios_PK] PRIMARY KEY NONCLUSTERED 
(
	[Cod_Usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.P_Cobrarc', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[P_Cobrarc](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CODIGO] [nvarchar](15) NULL,
	[FECHA] [datetime] NULL,
	[DOCUMENTO] [nvarchar](20) NULL,
	[DEBE] [float] NULL,
	[HABER] [float] NULL,
	[SALDO] [float] NULL,
	[PEND] [float] NULL,
	[PAID] [bit] NULL,
	[TIPO] [nvarchar](30) NULL,
	[PAGO] [float] NULL,
	[OBS] [ntext] NULL,
	[COD_USUARIO] [nvarchar](10) NULL,
	[ISRL] [nvarchar](20) NULL,
	[NUMREC] [nvarchar](20) NULL,
 CONSTRAINT [PK_P_Cobrarc] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Vendedor', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Vendedor](
	[Codigo] [nvarchar](2) NOT NULL,
	[Nombre] [nvarchar](20) NULL,
	[Comision] [float] NULL,
	[Direccion] [nvarchar](50) NULL,
	[Telefonos] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Rango_ventas_Uno] [float] NULL,
	[Comision_ ventas_Uno] [float] NULL,
	[Rango_ventas_dos] [float] NULL,
	[Comision_ ventas_dos] [float] NULL,
	[Rango_ventas_tres] [float] NULL,
	[Comision_ ventas_tres] [float] NULL,
	[Rango_ventas_Cuatro] [float] NULL,
	[Comision_ ventas_Cuatro] [float] NULL,
	[Status] [bit] NULL,
	[Tipo] [nvarchar](50) NULL,
	[clave] [nvarchar](50) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaVendedor_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_FormaPagoFacturas', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_FormaPagoFacturas](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Num_fact] [nvarchar](20) NOT NULL,
	[Tipo] [nvarchar](25) NOT NULL,
	[Memoria] [nvarchar](3) NULL,
	[Cuenta] [nvarchar](20) NULL,
	[Banco] [nvarchar](50) NULL,
	[upsize_ts] [timestamp] NULL,
	[Numero] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Monto] [float] NULL,
	[SerialFiscal] [nvarchar](20) NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [aaaaaDetalle_FormaPagoFacturas_PK] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC,
	[Num_fact] ASC,
	[Tipo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Detalle_FormaPagoCotizacion', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Detalle_FormaPagoCotizacion](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Num_fact] [nvarchar](20) NOT NULL,
	[Tipo] [nvarchar](25) NOT NULL,
	[Memoria] [nvarchar](3) NULL,
	[Cuenta] [nvarchar](20) NULL,
	[Banco] [nvarchar](50) NULL,
	[Numero] [float] NULL,
	[Fecha_Retencion] [datetime] NULL,
	[Monto] [float] NULL,
	[upsize_ts] [timestamp] NULL,
	[SerialFiscal] [nvarchar](20) NULL,
	[TasaCambio] [float] NULL,
 CONSTRAINT [aaaaaDetalle_FormaPagoCotizacion_PK] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC,
	[Num_fact] ASC,
	[Tipo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Centro_Costo', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[Centro_Costo](
	[Codigo] [nvarchar](10) NOT NULL,
	[Descripcion] [nvarchar](50) NULL,
	[Presupuestado] [nvarchar](50) NULL,
	[Saldo_Real] [nvarchar](50) NULL,
	[upsize_ts] [timestamp] NULL,
 CONSTRAINT [aaaaaCentro_Costo_PK] PRIMARY KEY NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END;
GO

IF OBJECT_ID('dbo.Lineas', 'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[Lineas](
    [Codigo] [int] IDENTITY(1,1) NOT NULL,
    [Descripcion] [nvarchar](100) NULL,
    CONSTRAINT [PK_Lineas] PRIMARY KEY CLUSTERED ([Codigo] ASC)
  );
END;
GO

IF OBJECT_ID('dbo.Categoria', 'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[Categoria](
    [Codigo] [int] IDENTITY(1,1) NOT NULL,
    [Nombre] [nvarchar](100) NULL,
    [Co_Usuario] [nvarchar](10) NULL,
    CONSTRAINT [PK_Categoria] PRIMARY KEY CLUSTERED ([Codigo] ASC)
  );
END;
GO

IF OBJECT_ID('dbo.P_Cobrar', 'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[P_Cobrar](
    [id] [bigint] IDENTITY(1,1) NOT NULL,
    [CODIGO] [nvarchar](12) NULL,
    [COD_USUARIO] [nvarchar](20) NULL,
    [FECHA] [datetime] NULL,
    [DOCUMENTO] [nvarchar](60) NULL,
    [DEBE] [float] NULL,
    [HABER] [float] NULL,
    [PEND] [float] NULL,
    [SALDO] [float] NULL,
    [TIPO] [nvarchar](20) NULL,
    [OBS] [nvarchar](500) NULL,
    [PAID] [bit] NULL,
    [SERIALTIPO] [nvarchar](40) NULL,
    [Tipo_Orden] [nvarchar](6) NULL,
    CONSTRAINT [PK_P_Cobrar] PRIMARY KEY CLUSTERED ([id] ASC)
  );
  CREATE INDEX IX_P_Cobrar_CODIGO ON [dbo].[P_Cobrar]([CODIGO]);
  CREATE INDEX IX_P_Cobrar_DOC ON [dbo].[P_Cobrar]([DOCUMENTO]);
END;
GO

IF OBJECT_ID('dbo.Inventario_Aux', 'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[Inventario_Aux](
    [id] [bigint] IDENTITY(1,1) NOT NULL,
    [CODIGO] [nvarchar](15) NULL,
    [CANTIDAD] [float] NULL,
    [DESCRIPCION] [nvarchar](255) NULL,
    CONSTRAINT [PK_Inventario_Aux] PRIMARY KEY CLUSTERED ([id] ASC)
  );
  CREATE INDEX IX_InventarioAux_Codigo ON [dbo].[Inventario_Aux]([CODIGO]);
END;
GO

IF OBJECT_ID('dbo.DETALLE_DEPOSITO', 'SN') IS NOT NULL
  DROP SYNONYM dbo.DETALLE_DEPOSITO;
GO

IF OBJECT_ID('dbo.DETALLE_DEPOSITO', 'U') IS NULL
BEGIN
  IF OBJECT_ID('dbo.Detalle_Deposito', 'U') IS NOT NULL
  BEGIN
    EXEC('CREATE SYNONYM dbo.DETALLE_DEPOSITO FOR dbo.Detalle_Deposito;');
  END
  ELSE
  BEGIN
    CREATE TABLE [dbo].[DETALLE_DEPOSITO](
      [id] [bigint] IDENTITY(1,1) NOT NULL,
      [TOTAL] [float] NULL,
      [CHEQUE] [nvarchar](60) NULL,
      [CTA_BANCO] [nvarchar](50) NULL,
      [CLIENTE] [nvarchar](12) NULL,
      [RELACIONADA] [int] NULL,
      [BANCO] [nvarchar](100) NULL,
      CONSTRAINT [PK_DETALLE_DEPOSITO] PRIMARY KEY CLUSTERED ([id] ASC)
    );
    CREATE INDEX IX_DETALLE_DEPOSITO_CHEQUE ON [dbo].[DETALLE_DEPOSITO]([CHEQUE]);
  END
END;
GO

IF OBJECT_ID('dbo.Cuentas', 'U') IS NOT NULL
BEGIN
  IF COL_LENGTH('dbo.Cuentas', 'DESCRIPCION') IS NULL ALTER TABLE dbo.Cuentas ADD DESCRIPCION NVARCHAR(200) NULL;
  IF COL_LENGTH('dbo.Cuentas', 'PRESUPUESTO') IS NULL ALTER TABLE dbo.Cuentas ADD PRESUPUESTO FLOAT NULL;
  IF COL_LENGTH('dbo.Cuentas', 'SALDO') IS NULL ALTER TABLE dbo.Cuentas ADD SALDO FLOAT NULL;
  IF COL_LENGTH('dbo.Cuentas', 'COD_USUARIO') IS NULL ALTER TABLE dbo.Cuentas ADD COD_USUARIO NVARCHAR(20) NULL;
  IF COL_LENGTH('dbo.Cuentas', 'grupo') IS NULL ALTER TABLE dbo.Cuentas ADD [grupo] NVARCHAR(50) NULL;
  IF COL_LENGTH('dbo.Cuentas', 'LINEA') IS NULL ALTER TABLE dbo.Cuentas ADD LINEA NVARCHAR(50) NULL;
  IF COL_LENGTH('dbo.Cuentas', 'USO') IS NULL ALTER TABLE dbo.Cuentas ADD USO NVARCHAR(50) NULL;
  IF COL_LENGTH('dbo.Cuentas', 'Porcentaje') IS NULL ALTER TABLE dbo.Cuentas ADD Porcentaje FLOAT NULL;
END;
GO

IF OBJECT_ID('dbo.Usuarios', 'U') IS NOT NULL
BEGIN
  IF COL_LENGTH('dbo.Usuarios', 'IsAdmin') IS NULL ALTER TABLE dbo.Usuarios ADD IsAdmin BIT NULL;
END;
GO

