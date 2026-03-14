-- ============================================
-- cfg.AppSetting — Unified Key-Value Settings
-- Stores all configurable parameters per company,
-- scoped by module. Values are JSON-encoded.
-- ============================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'cfg' AND TABLE_NAME = 'AppSetting')
BEGIN
    CREATE TABLE cfg.AppSetting (
        SettingId       INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL DEFAULT 1,
        Module          NVARCHAR(60)  NOT NULL,   -- 'general','contabilidad','nomina','bancos','inventario','pos','restaurante','fiscal','pagos'
        SettingKey      NVARCHAR(120) NOT NULL,
        SettingValue    NVARCHAR(MAX) NOT NULL DEFAULT '',  -- JSON or plain value
        ValueType       NVARCHAR(20)  NOT NULL DEFAULT 'string', -- string | number | boolean | json
        Description     NVARCHAR(500) NULL,
        IsReadOnly      BIT NOT NULL DEFAULT 0,
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedByUserId INT NULL,

        CONSTRAINT UQ_AppSetting_Company_Module_Key UNIQUE (CompanyId, Module, SettingKey)
    );

    PRINT 'Table cfg.AppSetting created';
END
GO

-- ============================================
-- Seed default settings
-- ============================================
-- General
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'general' AND SettingKey = 'pais')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'general', 'pais',             'VE',                'string',  'País / régimen fiscal'),
    (1, 'general', 'nombreEmpresa',    'Mi Empresa, C.A.',  'string',  'Nombre comercial'),
    (1, 'general', 'monedaBase',       'VES',               'string',  'Moneda base ISO 4217'),
    (1, 'general', 'monedaReferencia', 'USD',               'string',  'Moneda de referencia');

    PRINT 'Seeded general settings';
END
GO

-- Contabilidad
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'contabilidad' AND SettingKey = 'formatoPlanCuentas')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'contabilidad', 'formatoPlanCuentas',        'X.X.XX.XX.XX', 'string',  'Estructura del plan de cuentas'),
    (1, 'contabilidad', 'nombreImpuestoPrincipal',   'IVA',          'string',  'Nombre del impuesto principal'),
    (1, 'contabilidad', 'nombreIdentificacion',      'RIF',          'string',  'Tipo de identificación fiscal'),
    (1, 'contabilidad', 'periodoFiscalStartMonth',   '1',            'number',  'Mes de inicio del período fiscal'),
    (1, 'contabilidad', 'periodoFiscalCloseYearBehavior', 'soft',    'string',  'Comportamiento de cierre anual'),
    (1, 'contabilidad', 'asientoAutomaticoVentas',   'true',         'boolean', 'Generar asiento automático desde ventas'),
    (1, 'contabilidad', 'asientoAutomaticoCompras',  'true',         'boolean', 'Generar asiento automático desde compras'),
    (1, 'contabilidad', 'integracionContable',       'true',         'boolean', 'Integración contable activa');

    PRINT 'Seeded contabilidad settings';
END
GO

-- Nómina
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'nomina' AND SettingKey = 'periodoPago')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'nomina', 'periodoPago',         'quincenal', 'string',  'Frecuencia de pago'),
    (1, 'nomina', 'aplicaISR',           'true',      'boolean', 'Deducir ISLR/ISR'),
    (1, 'nomina', 'aplicaSeguroSocial',  'true',      'boolean', 'Deducir Seguro Social (IVSS)'),
    (1, 'nomina', 'aplicaParoForzoso',   'true',      'boolean', 'Deducir Paro Forzoso');

    PRINT 'Seeded nomina settings';
END
GO

-- Bancos
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'bancos' AND SettingKey = 'precisionBancaria')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'bancos', 'precisionBancaria',   '2',    'number', 'Decimales en tránsito bancario'),
    (1, 'bancos', 'formatoExportacion',  'csv',  'string', 'Formato de conciliación bancaria'),
    (1, 'bancos', 'defaultGateway',      '',     'string', 'Gateway de pago por defecto');

    PRINT 'Seeded bancos settings';
END
GO

-- Inventario
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'inventario' AND SettingKey = 'metodoCosteo')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'inventario', 'metodoCosteo',              'PROMEDIO', 'string',  'Método de valoración'),
    (1, 'inventario', 'permitirStockNegativo',     'false',    'boolean', 'Permitir facturar con stock negativo'),
    (1, 'inventario', 'manejarLotesYVencimiento',  'true',     'boolean', 'Validación estricta de lotes y vto.');

    PRINT 'Seeded inventario settings';
END
GO

-- Punto de Venta
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'pos' AND SettingKey = 'impresora.marca')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'pos', 'impresora.marca',           'PNP',      'string',  'Marca impresora fiscal'),
    (1, 'pos', 'impresora.conexion',        'emulador', 'string',  'Tipo de conexión impresora'),
    (1, 'pos', 'impresora.puerto',          'EMULADOR', 'string',  'Puerto impresora fiscal'),
    (1, 'pos', 'impresora.agentUrl',        'http://localhost:5059', 'string', 'URL del agente fiscal local'),
    (1, 'pos', 'caja.id',                   '1',              'string', 'ID de caja por defecto'),
    (1, 'pos', 'caja.nombre',               'Caja Principal', 'string', 'Nombre de caja'),
    (1, 'pos', 'caja.serieFactura',         'A',              'string', 'Serie de factura'),
    (1, 'pos', 'caja.almacenId',            '1',              'string', 'Almacén asignado'),
    (1, 'pos', 'localizacion.preciosIncluyenIva', 'true',     'boolean', 'Precios incluyen IVA'),
    (1, 'pos', 'localizacion.tasaIgtf',     '3',              'number',  'Tasa IGTF (%)'),
    (1, 'pos', 'localizacion.aplicarIgtf',  'true',           'boolean', 'Aplicar IGTF');

    PRINT 'Seeded pos settings';
END
GO

-- Restaurante
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'restaurante' AND SettingKey = 'habilitado')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'restaurante', 'habilitado',               'true',  'boolean', 'Módulo restaurante activo'),
    (1, 'restaurante', 'imprimirComandaCocina',    'true',  'boolean', 'Imprimir comanda automática'),
    (1, 'restaurante', 'permitirPedidoSinMesa',    'false', 'boolean', 'Permitir pedido sin mesa asignada'),
    (1, 'restaurante', 'tiempoAlertaPreparacion',  '15',    'number',  'Minutos alerta de preparación'),
    (1, 'restaurante', 'propinaSugeridaPct',       '10',    'number',  'Porcentaje propina sugerida');

    PRINT 'Seeded restaurante settings';
END
GO

-- Facturación / Fiscal
IF NOT EXISTS (SELECT 1 FROM cfg.AppSetting WHERE Module = 'facturacion' AND SettingKey = 'correlativosAutomaticos')
BEGIN
    INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, Description) VALUES
    (1, 'facturacion', 'correlativosAutomaticos',  'true',   'boolean', 'Numeración automática de documentos'),
    (1, 'facturacion', 'formatoImpresion',         'carta',  'string',  'Formato de impresión'),
    (1, 'facturacion', 'copiasPorDefecto',         '1',      'number',  'Copias al imprimir'),
    (1, 'facturacion', 'mostrarPrecioUnitarioUsd', 'true',   'boolean', 'Mostrar precio en USD en factura'),
    (1, 'facturacion', 'permitirDescuento',        'true',   'boolean', 'Permitir descuento en línea'),
    (1, 'facturacion', 'descuentoMaximoPct',       '20',     'number',  'Descuento máximo (%)');

    PRINT 'Seeded facturacion settings';
END
GO

PRINT '=== cfg.AppSetting setup complete ===';
