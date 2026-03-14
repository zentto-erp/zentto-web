-- =============================================
-- Creación de tablas unificadas para documentos
-- Variante 2: DocumentosVenta y DocumentosCompra
-- =============================================

-- =============================================
-- 1. TABLA: DocumentosVenta (Clientes)
-- TIPOS: FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVenta')
BEGIN
    CREATE TABLE DocumentosVenta (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,                    -- Número de documento
        SERIALTIPO NVARCHAR(60) NOT NULL DEFAULT '',      -- Serie/Tipo fiscal
        TIPO_OPERACION NVARCHAR(20) NOT NULL,             -- FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
        CODIGO NVARCHAR(60) NULL,                         -- Código del cliente
        NOMBRE NVARCHAR(255) NULL,                        -- Nombre del cliente
        RIF NVARCHAR(20) NULL,                            -- RIF del cliente
        FECHA DATETIME NULL DEFAULT GETDATE(),
        FECHA_VENCE DATETIME NULL,                        -- Fecha de vencimiento
        HORA NVARCHAR(20) NULL DEFAULT CONVERT(NVARCHAR(8), GETDATE(), 108),
        
        -- Montos
        SUBTOTAL FLOAT NULL DEFAULT 0,
        MONTO_GRA FLOAT NULL DEFAULT 0,                   -- Monto gravado
        MONTO_EXE FLOAT NULL DEFAULT 0,                   -- Monto exento
        IVA FLOAT NULL DEFAULT 0,
        ALICUOTA FLOAT NULL DEFAULT 0,                    -- % de alícuota IVA
        TOTAL FLOAT NULL DEFAULT 0,
        DESCUENTO FLOAT NULL DEFAULT 0,                   -- Descuento global
        
        -- Estados
        ANULADA BIT NULL DEFAULT 0,
        CANCELADA NVARCHAR(1) NULL DEFAULT 'N',           -- S/N si está cancelada (pagada)
        FACTURADA NVARCHAR(1) NULL DEFAULT 'N',           -- Para pedidos/presupuestos facturados
        ENTREGADA NVARCHAR(1) NULL DEFAULT 'N',           -- Para notas de entrega
        
        -- Documentos relacionados
        DOC_ORIGEN NVARCHAR(60) NULL,                     -- Documento origen (ej: pedido que genera factura)
        TIPO_DOC_ORIGEN NVARCHAR(20) NULL,                -- Tipo del doc origen
        
        -- Información fiscal
        NUM_CONTROL NVARCHAR(60) NULL,                    -- Número de control fiscal
        LEGAL BIT NULL DEFAULT 0,                         -- Es documento fiscal legal
        IMPRESA BIT NULL DEFAULT 0,                       -- Ya fue impresa fiscalmente
        
        -- Información adicional
        OBSERV NVARCHAR(500) NULL,
        CONCEPTO NVARCHAR(255) NULL,
        TERMINOS NVARCHAR(255) NULL,                      -- Términos de pago
        DESPACHAR NVARCHAR(255) NULL,                     -- Lugar de despacho
        
        -- Vendedor y ubicación
        VENDEDOR NVARCHAR(60) NULL,
        DEPARTAMENTO NVARCHAR(50) NULL,
        LOCACION NVARCHAR(100) NULL,
        
        -- Moneda
        MONEDA NVARCHAR(20) NULL DEFAULT 'BS',
        TASA_CAMBIO FLOAT NULL DEFAULT 1,
        
        -- Auditoría
        COD_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        FECHA_REPORTE DATETIME NULL DEFAULT GETDATE(),
        COMPUTER NVARCHAR(255) NULL DEFAULT HOST_NAME(),
        
        -- Campos específicos por tipo (nullable)
        PLACAS NVARCHAR(20) NULL,                         -- Cotizaciones/Pedidos (taller)
        KILOMETROS INT NULL,
        PEAJE FLOAT NULL DEFAULT 0,
        
        CONSTRAINT UQ_DocumentosVenta_NUM_DOC_TIPO UNIQUE (NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocumentosVenta_CODIGO ON DocumentosVenta(CODIGO);
    CREATE INDEX IX_DocumentosVenta_FECHA ON DocumentosVenta(FECHA);
    CREATE INDEX IX_DocumentosVenta_TIPO ON DocumentosVenta(TIPO_OPERACION);
    CREATE INDEX IX_DocumentosVenta_DOC_ORIGEN ON DocumentosVenta(DOC_ORIGEN);
END
GO

-- =============================================
-- 2. TABLA: DocumentosVentaDetalle
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVentaDetalle')
BEGIN
    CREATE TABLE DocumentosVentaDetalle (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,
        TIPO_OPERACION NVARCHAR(20) NOT NULL,
        RENGLON INT NULL DEFAULT 0,
        
        -- Producto
        COD_SERV NVARCHAR(60) NULL,                       -- Código del producto/servicio
        DESCRIPCION NVARCHAR(255) NULL,                   -- Descripción
        COD_ALTERNO NVARCHAR(60) NULL,                    -- Código alterno
        
        -- Cantidades y precios
        CANTIDAD FLOAT NULL DEFAULT 0,
        PRECIO FLOAT NULL DEFAULT 0,                      -- Precio unitario
        PRECIO_DESCUENTO FLOAT NULL DEFAULT 0,            -- Precio con descuento
        COSTO FLOAT NULL DEFAULT 0,                       -- Costo (para utilidad)
        
        -- Totales
        SUBTOTAL FLOAT NULL DEFAULT 0,
        DESCUENTO FLOAT NULL DEFAULT 0,                   -- % descuento línea
        TOTAL FLOAT NULL DEFAULT 0,
        
        -- IVA
        ALICUOTA FLOAT NULL DEFAULT 0,
        MONTO_IVA FLOAT NULL DEFAULT 0,
        
        -- Estados
        ANULADA BIT NULL DEFAULT 0,
        RELACIONADA NVARCHAR(10) NULL DEFAULT '0',        -- Ítem relacionado con otro doc
        
        -- Auditoría
        CO_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        FECHA DATETIME NULL DEFAULT GETDATE(),
        
        CONSTRAINT FK_DocVentaDet_DocVenta FOREIGN KEY (NUM_DOC, TIPO_OPERACION) 
            REFERENCES DocumentosVenta(NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocVentaDet_NUM_DOC ON DocumentosVentaDetalle(NUM_DOC, TIPO_OPERACION);
    CREATE INDEX IX_DocVentaDet_COD_SERV ON DocumentosVentaDetalle(COD_SERV);
END
GO

-- =============================================
-- 3. TABLA: DocumentosVentaPago (Formas de pago)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosVentaPago')
BEGIN
    CREATE TABLE DocumentosVentaPago (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,
        TIPO_OPERACION NVARCHAR(20) NOT NULL DEFAULT 'FACT',
        
        -- Forma de pago
        TIPO_PAGO NVARCHAR(30) NULL,                      -- EFECTIVO, CHEQUE, TARJETA, TRANSFERENCIA, etc.
        BANCO NVARCHAR(60) NULL,
        NUMERO NVARCHAR(60) NULL,                         -- Número de cheque/tarjeta
        
        -- Montos
        MONTO FLOAT NULL DEFAULT 0,
        MONTO_BS FLOAT NULL DEFAULT 0,                    -- En bolívares si es divisa
        TASA_CAMBIO FLOAT NULL DEFAULT 1,                 -- Tasa del día para este pago (tasa_moneda/tasa_dolar)
        
        -- Fechas
        FECHA DATETIME NULL DEFAULT GETDATE(),
        FECHA_VENCE DATETIME NULL,                        -- Para cheques
        
        -- Referencias
        REFERENCIA NVARCHAR(100) NULL,
        CO_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        
        CONSTRAINT FK_DocVentaPago_DocVenta FOREIGN KEY (NUM_DOC, TIPO_OPERACION) 
            REFERENCES DocumentosVenta(NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocVentaPago_NUM_DOC ON DocumentosVentaPago(NUM_DOC, TIPO_OPERACION);
END
GO

-- =============================================
-- 4. TABLA: DocumentosCompra (Proveedores)
-- TIPOS: ORDEN, COMPRA
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosCompra')
BEGIN
    CREATE TABLE DocumentosCompra (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,                    -- Número de documento
        SERIALTIPO NVARCHAR(60) NOT NULL DEFAULT '',      -- Serie
        TIPO_OPERACION NVARCHAR(20) NOT NULL DEFAULT 'COMPRA', -- ORDEN, COMPRA
        COD_PROVEEDOR NVARCHAR(60) NULL,                  -- Código del proveedor
        NOMBRE NVARCHAR(255) NULL,                        -- Nombre del proveedor
        RIF NVARCHAR(15) NULL,                            -- RIF del proveedor
        
        FECHA DATETIME NULL DEFAULT GETDATE(),
        FECHA_VENCE DATETIME NULL,                        -- Fecha de vencimiento
        FECHA_RECIBO DATETIME NULL,                       -- Fecha de recepción
        FECHA_PAGO DATETIME NULL,                         -- Fecha de pago
        HORA NVARCHAR(20) NULL DEFAULT CONVERT(NVARCHAR(8), GETDATE(), 108),
        
        -- Montos
        SUBTOTAL FLOAT NULL DEFAULT 0,
        MONTO_GRA FLOAT NULL DEFAULT 0,                   -- Monto gravado
        MONTO_EXE FLOAT NULL DEFAULT 0,                   -- Monto exento
        IVA FLOAT NULL DEFAULT 0,
        ALICUOTA FLOAT NULL DEFAULT 0,
        TOTAL FLOAT NULL DEFAULT 0,
        EXENTO FLOAT NULL DEFAULT 0,
        DESCUENTO FLOAT NULL DEFAULT 0,
        
        -- Estados
        ANULADA BIT NULL DEFAULT 0,
        CANCELADA NVARCHAR(1) NULL DEFAULT 'N',           -- S/N pagada
        RECIBIDA NVARCHAR(1) NULL DEFAULT 'N',            -- Para órdenes recibidas
        LEGAL BIT NULL DEFAULT 0,                         -- Es factura fiscal legal
        
        -- Documentos relacionados
        DOC_ORIGEN NVARCHAR(60) NULL,                     -- Orden que genera compra
        
        -- Información fiscal compra
        NUM_CONTROL NVARCHAR(60) NULL,
        NRO_COMPROBANTE NVARCHAR(50) NULL,                -- Número de comprobante
        FECHA_COMPROBANTE DATETIME NULL,
        
        -- Retenciones
        IVA_RETENIDO FLOAT NULL DEFAULT 0,
        ISLR NVARCHAR(50) NULL,
        MONTO_ISLR FLOAT NULL DEFAULT 0,
        CODIGO_ISLR NVARCHAR(50) NULL,
        SUJETO_ISLR FLOAT NULL DEFAULT 0,
        TASA_RETENCION FLOAT NULL DEFAULT 0,
        
        -- Importación
        IMPORTACION FLOAT NULL DEFAULT 0,
        IVA_IMPORT FLOAT NULL DEFAULT 0,
        BASE_IMPORT FLOAT NULL DEFAULT 0,
        FLETE FLOAT NULL DEFAULT 0,
        
        -- Información adicional
        CONCEPTO NVARCHAR(255) NULL,
        OBSERV NVARCHAR(500) NULL,
        PEDIDO NVARCHAR(20) NULL,
        RECIBIDO NVARCHAR(20) NULL,
        ALMACEN NVARCHAR(50) NULL,
        
        -- Moneda y tasa del día (valor de tasa_moneda/tasa_dolar al momento de la operación)
        MONEDA NVARCHAR(20) NULL DEFAULT 'BS',
        TASA_CAMBIO FLOAT NULL DEFAULT 1,                 -- Tasa de cambio del día (ej. dólar)
        PRECIO_DOLLAR FLOAT NULL DEFAULT 0,
        
        -- Auditoría
        COD_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        CO_USUARIO NVARCHAR(10) NULL,
        FECHA_REPORTE DATETIME NULL DEFAULT GETDATE(),
        COMPUTER NVARCHAR(255) NULL DEFAULT HOST_NAME(),
        
        CONSTRAINT UQ_DocumentosCompra_NUM_DOC_TIPO UNIQUE (NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocumentosCompra_PROV ON DocumentosCompra(COD_PROVEEDOR);
    CREATE INDEX IX_DocumentosCompra_FECHA ON DocumentosCompra(FECHA);
    CREATE INDEX IX_DocumentosCompra_TIPO ON DocumentosCompra(TIPO_OPERACION);
END
GO

-- =============================================
-- 5. TABLA: DocumentosCompraDetalle
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosCompraDetalle')
BEGIN
    CREATE TABLE DocumentosCompraDetalle (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,
        TIPO_OPERACION NVARCHAR(20) NOT NULL DEFAULT 'COMPRA',
        RENGLON INT NULL DEFAULT 0,
        
        -- Producto
        COD_SERV NVARCHAR(60) NULL,
        DESCRIPCION NVARCHAR(255) NULL,
        
        -- Cantidades y precios
        CANTIDAD FLOAT NULL DEFAULT 0,
        PRECIO FLOAT NULL DEFAULT 0,                      -- Precio de compra
        COSTO FLOAT NULL DEFAULT 0,                       -- Costo calculado
        
        -- Totales
        SUBTOTAL FLOAT NULL DEFAULT 0,
        DESCUENTO FLOAT NULL DEFAULT 0,
        TOTAL FLOAT NULL DEFAULT 0,
        
        -- IVA
        ALICUOTA FLOAT NULL DEFAULT 0,
        MONTO_IVA FLOAT NULL DEFAULT 0,
        
        -- Estados
        ANULADA BIT NULL DEFAULT 0,
        
        -- Auditoría
        CO_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        FECHA DATETIME NULL DEFAULT GETDATE(),
        
        CONSTRAINT FK_DocCompraDet_DocCompra FOREIGN KEY (NUM_DOC, TIPO_OPERACION) 
            REFERENCES DocumentosCompra(NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocCompraDet_NUM_DOC ON DocumentosCompraDetalle(NUM_DOC, TIPO_OPERACION);
    CREATE INDEX IX_DocCompraDet_COD_SERV ON DocumentosCompraDetalle(COD_SERV);
END
GO

-- =============================================
-- 6. TABLA: DocumentosCompraPago (Formas de pago)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentosCompraPago')
BEGIN
    CREATE TABLE DocumentosCompraPago (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NUM_DOC NVARCHAR(60) NOT NULL,
        TIPO_OPERACION NVARCHAR(20) NOT NULL DEFAULT 'COMPRA',
        
        TIPO_PAGO NVARCHAR(30) NULL,                      -- EFECTIVO, CHEQUE, TRANSFERENCIA
        BANCO NVARCHAR(60) NULL,
        NUMERO NVARCHAR(60) NULL,
        
        MONTO FLOAT NULL DEFAULT 0,
        FECHA DATETIME NULL DEFAULT GETDATE(),
        FECHA_VENCE DATETIME NULL,
        
        REFERENCIA NVARCHAR(100) NULL,
        CO_USUARIO NVARCHAR(60) NULL DEFAULT 'API',
        
        CONSTRAINT FK_DocCompraPago_DocCompra FOREIGN KEY (NUM_DOC, TIPO_OPERACION) 
            REFERENCES DocumentosCompra(NUM_DOC, TIPO_OPERACION)
    );
    
    CREATE INDEX IX_DocCompraPago_NUM_DOC ON DocumentosCompraPago(NUM_DOC, TIPO_OPERACION);
END
GO

SELECT 'Tablas unificadas creadas exitosamente' AS mensaje;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'Documentos%';
