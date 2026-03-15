-- ============================================
-- cfg."AppSetting" — Unified Key-Value Settings - PostgreSQL
-- Stores all configurable parameters per company,
-- scoped by module. Values are JSON-encoded.
-- Traducido de SQL Server a PostgreSQL
-- ============================================

CREATE TABLE IF NOT EXISTS cfg."AppSetting" (
    "SettingId"       SERIAL PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "Module"          VARCHAR(60) NOT NULL,       -- 'general','contabilidad','nomina','bancos','inventario','pos','restaurante','fiscal','pagos'
    "SettingKey"      VARCHAR(120) NOT NULL,
    "SettingValue"    TEXT NOT NULL DEFAULT '',     -- JSON or plain value
    "ValueType"       VARCHAR(20) NOT NULL DEFAULT 'string', -- string | number | boolean | json
    "Description"     VARCHAR(500),
    "IsReadOnly"      BOOLEAN NOT NULL DEFAULT FALSE,
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedByUserId" INT,

    CONSTRAINT "UQ_AppSetting_Company_Module_Key" UNIQUE ("CompanyId", "Module", "SettingKey")
);

-- ============================================
-- Seed default settings
-- ============================================
-- General
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'general', 'pais',             'VE',                'string',  'Pais / regimen fiscal'),
    (1, 'general', 'nombreEmpresa',    'Mi Empresa, C.A.',  'string',  'Nombre comercial'),
    (1, 'general', 'monedaBase',       'VES',               'string',  'Moneda base ISO 4217'),
    (1, 'general', 'monedaReferencia', 'USD',               'string',  'Moneda de referencia')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Contabilidad
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'contabilidad', 'formatoPlanCuentas',        'X.X.XX.XX.XX', 'string',  'Estructura del plan de cuentas'),
    (1, 'contabilidad', 'nombreImpuestoPrincipal',   'IVA',          'string',  'Nombre del impuesto principal'),
    (1, 'contabilidad', 'nombreIdentificacion',      'RIF',          'string',  'Tipo de identificacion fiscal'),
    (1, 'contabilidad', 'periodoFiscalStartMonth',   '1',            'number',  'Mes de inicio del periodo fiscal'),
    (1, 'contabilidad', 'periodoFiscalCloseYearBehavior', 'soft',    'string',  'Comportamiento de cierre anual'),
    (1, 'contabilidad', 'asientoAutomaticoVentas',   'true',         'boolean', 'Generar asiento automatico desde ventas'),
    (1, 'contabilidad', 'asientoAutomaticoCompras',  'true',         'boolean', 'Generar asiento automatico desde compras'),
    (1, 'contabilidad', 'integracionContable',       'true',         'boolean', 'Integracion contable activa')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Nomina
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'nomina', 'periodoPago',         'quincenal', 'string',  'Frecuencia de pago'),
    (1, 'nomina', 'aplicaISR',           'true',      'boolean', 'Deducir ISLR/ISR'),
    (1, 'nomina', 'aplicaSeguroSocial',  'true',      'boolean', 'Deducir Seguro Social (IVSS)'),
    (1, 'nomina', 'aplicaParoForzoso',   'true',      'boolean', 'Deducir Paro Forzoso')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Bancos
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'bancos', 'precisionBancaria',   '2',    'number', 'Decimales en transito bancario'),
    (1, 'bancos', 'formatoExportacion',  'csv',  'string', 'Formato de conciliacion bancaria'),
    (1, 'bancos', 'defaultGateway',      '',     'string', 'Gateway de pago por defecto')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Inventario
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'inventario', 'metodoCosteo',              'PROMEDIO', 'string',  'Metodo de valoracion'),
    (1, 'inventario', 'permitirStockNegativo',     'false',    'boolean', 'Permitir facturar con stock negativo'),
    (1, 'inventario', 'manejarLotesYVencimiento',  'true',     'boolean', 'Validacion estricta de lotes y vto.')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Punto de Venta
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'pos', 'impresora.marca',           'PNP',      'string',  'Marca impresora fiscal'),
    (1, 'pos', 'impresora.conexion',        'emulador', 'string',  'Tipo de conexion impresora'),
    (1, 'pos', 'impresora.puerto',          'EMULADOR', 'string',  'Puerto impresora fiscal'),
    (1, 'pos', 'impresora.agentUrl',        'http://localhost:5059', 'string', 'URL del agente fiscal local'),
    (1, 'pos', 'caja.id',                   '1',              'string', 'ID de caja por defecto'),
    (1, 'pos', 'caja.nombre',               'Caja Principal', 'string', 'Nombre de caja'),
    (1, 'pos', 'caja.serieFactura',         'A',              'string', 'Serie de factura'),
    (1, 'pos', 'caja.almacenId',            '1',              'string', 'Almacen asignado'),
    (1, 'pos', 'localizacion.preciosIncluyenIva', 'true',     'boolean', 'Precios incluyen IVA'),
    (1, 'pos', 'localizacion.tasaIgtf',     '3',              'number',  'Tasa IGTF (%)'),
    (1, 'pos', 'localizacion.aplicarIgtf',  'true',           'boolean', 'Aplicar IGTF')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Restaurante
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'restaurante', 'habilitado',               'true',  'boolean', 'Modulo restaurante activo'),
    (1, 'restaurante', 'imprimirComandaCocina',    'true',  'boolean', 'Imprimir comanda automatica'),
    (1, 'restaurante', 'permitirPedidoSinMesa',    'false', 'boolean', 'Permitir pedido sin mesa asignada'),
    (1, 'restaurante', 'tiempoAlertaPreparacion',  '15',    'number',  'Minutos alerta de preparacion'),
    (1, 'restaurante', 'propinaSugeridaPct',       '10',    'number',  'Porcentaje propina sugerida')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;

-- Facturacion / Fiscal
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
VALUES
    (1, 'facturacion', 'correlativosAutomaticos',  'true',   'boolean', 'Numeracion automatica de documentos'),
    (1, 'facturacion', 'formatoImpresion',         'carta',  'string',  'Formato de impresion'),
    (1, 'facturacion', 'copiasPorDefecto',         '1',      'number',  'Copias al imprimir'),
    (1, 'facturacion', 'mostrarPrecioUnitarioUsd', 'true',   'boolean', 'Mostrar precio en USD en factura'),
    (1, 'facturacion', 'permitirDescuento',        'true',   'boolean', 'Permitir descuento en linea'),
    (1, 'facturacion', 'descuentoMaximoPct',       '20',     'number',  'Descuento maximo (%)')
ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;
