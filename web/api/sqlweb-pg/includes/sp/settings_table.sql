-- ============================================================
-- DatqBoxWeb PostgreSQL - settings_table.sql
-- Tabla cfg.AppSetting: configuracion clave-valor unificada
-- por empresa y modulo. Valores codificados en JSON.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS cfg;

CREATE TABLE IF NOT EXISTS cfg."AppSetting" (
    "SettingId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "Module"          VARCHAR(60)  NOT NULL,
    "SettingKey"      VARCHAR(120) NOT NULL,
    "SettingValue"    TEXT NOT NULL DEFAULT '',
    "ValueType"       VARCHAR(20)  NOT NULL DEFAULT 'string',
    "Description"     VARCHAR(500) NULL,
    "IsReadOnly"      BOOLEAN NOT NULL DEFAULT FALSE,
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedByUserId" INT NULL,
    CONSTRAINT "UQ_AppSetting_Company_Module_Key" UNIQUE ("CompanyId", "Module", "SettingKey")
);

-- Seed: General
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'general', 'pais',             'VE',                'string',  'Pais / regimen fiscal'),
    (1, 'general', 'nombreEmpresa',    'Mi Empresa, C.A.',  'string',  'Nombre comercial'),
    (1, 'general', 'monedaBase',       'VES',               'string',  'Moneda base ISO 4217'),
    (1, 'general', 'monedaReferencia', 'USD',               'string',  'Moneda de referencia')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'general' AND "SettingKey" = 'pais');

-- Seed: Contabilidad
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'contabilidad', 'formatoPlanCuentas',             'X.X.XX.XX.XX', 'string',  'Estructura del plan de cuentas'),
    (1, 'contabilidad', 'nombreImpuestoPrincipal',        'IVA',          'string',  'Nombre del impuesto principal'),
    (1, 'contabilidad', 'nombreIdentificacion',           'RIF',          'string',  'Tipo de identificacion fiscal'),
    (1, 'contabilidad', 'periodoFiscalStartMonth',        '1',            'number',  'Mes de inicio del periodo fiscal'),
    (1, 'contabilidad', 'periodoFiscalCloseYearBehavior', 'soft',         'string',  'Comportamiento de cierre anual'),
    (1, 'contabilidad', 'asientoAutomaticoVentas',        'true',         'boolean', 'Generar asiento automatico desde ventas'),
    (1, 'contabilidad', 'asientoAutomaticoCompras',       'true',         'boolean', 'Generar asiento automatico desde compras'),
    (1, 'contabilidad', 'integracionContable',            'true',         'boolean', 'Integracion contable activa')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'contabilidad' AND "SettingKey" = 'formatoPlanCuentas');

-- Seed: Nomina
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'nomina', 'periodoPago',         'quincenal', 'string',  'Frecuencia de pago'),
    (1, 'nomina', 'aplicaISR',           'true',      'boolean', 'Deducir ISLR/ISR'),
    (1, 'nomina', 'aplicaSeguroSocial',  'true',      'boolean', 'Deducir Seguro Social (IVSS)'),
    (1, 'nomina', 'aplicaParoForzoso',   'true',      'boolean', 'Deducir Paro Forzoso')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'nomina' AND "SettingKey" = 'periodoPago');

-- Seed: Bancos
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'bancos', 'precisionBancaria',   '2',    'number', 'Decimales en transito bancario'),
    (1, 'bancos', 'formatoExportacion',  'csv',  'string', 'Formato de conciliacion bancaria'),
    (1, 'bancos', 'defaultGateway',      '',     'string', 'Gateway de pago por defecto')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'bancos' AND "SettingKey" = 'precisionBancaria');

-- Seed: Inventario
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'inventario', 'metodoCosteo',              'PROMEDIO', 'string',  'Metodo de valoracion'),
    (1, 'inventario', 'permitirStockNegativo',     'false',    'boolean', 'Permitir facturar con stock negativo'),
    (1, 'inventario', 'manejarLotesYVencimiento',  'true',     'boolean', 'Validacion estricta de lotes y vto.')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'inventario' AND "SettingKey" = 'metodoCosteo');

-- Seed: Punto de Venta
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'pos', 'impresora.marca',                  'PNP',              'string',  'Marca impresora fiscal'),
    (1, 'pos', 'impresora.conexion',               'emulador',         'string',  'Tipo de conexion impresora'),
    (1, 'pos', 'impresora.puerto',                 'EMULADOR',         'string',  'Puerto impresora fiscal'),
    (1, 'pos', 'impresora.agentUrl',               'http://localhost:5059', 'string', 'URL del agente fiscal local'),
    (1, 'pos', 'caja.id',                          '1',                'string',  'ID de caja por defecto'),
    (1, 'pos', 'caja.nombre',                      'Caja Principal',   'string',  'Nombre de caja'),
    (1, 'pos', 'caja.serieFactura',                'A',                'string',  'Serie de factura'),
    (1, 'pos', 'caja.almacenId',                   '1',                'string',  'Almacen asignado'),
    (1, 'pos', 'localizacion.preciosIncluyenIva',  'true',             'boolean', 'Precios incluyen IVA'),
    (1, 'pos', 'localizacion.tasaIgtf',            '3',                'number',  'Tasa IGTF (%)'),
    (1, 'pos', 'localizacion.aplicarIgtf',         'true',             'boolean', 'Aplicar IGTF')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'pos' AND "SettingKey" = 'impresora.marca');

-- Seed: Restaurante
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'restaurante', 'habilitado',               'true',  'boolean', 'Modulo restaurante activo'),
    (1, 'restaurante', 'imprimirComandaCocina',    'true',  'boolean', 'Imprimir comanda automatica'),
    (1, 'restaurante', 'permitirPedidoSinMesa',    'false', 'boolean', 'Permitir pedido sin mesa asignada'),
    (1, 'restaurante', 'tiempoAlertaPreparacion',  '15',    'number',  'Minutos alerta de preparacion'),
    (1, 'restaurante', 'propinaSugeridaPct',       '10',    'number',  'Porcentaje propina sugerida')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'restaurante' AND "SettingKey" = 'habilitado');

-- Seed: Facturacion / Fiscal
INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
SELECT v.* FROM (VALUES
    (1, 'facturacion', 'correlativosAutomaticos',  'true',   'boolean', 'Numeracion automatica de documentos'),
    (1, 'facturacion', 'formatoImpresion',         'carta',  'string',  'Formato de impresion'),
    (1, 'facturacion', 'copiasPorDefecto',         '1',      'number',  'Copias al imprimir'),
    (1, 'facturacion', 'mostrarPrecioUnitarioUsd', 'true',   'boolean', 'Mostrar precio en USD en factura'),
    (1, 'facturacion', 'permitirDescuento',        'true',   'boolean', 'Permitir descuento en linea'),
    (1, 'facturacion', 'descuentoMaximoPct',       '20',     'number',  'Descuento maximo (%)')
) AS v("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "Description")
WHERE NOT EXISTS (SELECT 1 FROM cfg."AppSetting" WHERE "Module" = 'facturacion' AND "SettingKey" = 'correlativosAutomaticos');
